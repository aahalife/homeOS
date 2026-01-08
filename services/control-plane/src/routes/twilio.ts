import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import Twilio from 'twilio';

// Helper to send error responses with proper typing
function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

const TWILIO_ACCOUNT_SID = process.env['TWILIO_ACCOUNT_SID'] ?? '';
const TWILIO_AUTH_TOKEN = process.env['TWILIO_AUTH_TOKEN'] ?? '';

const twilioClient = TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN
  ? Twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
  : null;

const SearchNumbersSchema = z.object({
  areaCode: z.string().optional(),
  country: z.string().default('US'),
  contains: z.string().optional(),
});

const PurchaseNumberSchema = z.object({
  phoneNumber: z.string(),
  friendlyName: z.string().optional(),
});

export const twilioRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  // Check if Twilio is configured
  app.get(
    '/status',
    {
      schema: {
        description: 'Check Twilio configuration status',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              configured: { type: 'boolean' },
              accountSid: { type: 'string' },
            },
          },
        },
      },
    },
    async () => {
      return {
        configured: !!twilioClient,
        accountSid: TWILIO_ACCOUNT_SID ? `${TWILIO_ACCOUNT_SID.slice(0, 8)}...` : null,
      };
    }
  );

  // Search available phone numbers
  app.get(
    '/numbers/available',
    {
      schema: {
        description: 'Search available phone numbers to purchase',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          properties: {
            areaCode: { type: 'string' },
            country: { type: 'string', default: 'US' },
            contains: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              numbers: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    phoneNumber: { type: 'string' },
                    friendlyName: { type: 'string' },
                    locality: { type: 'string' },
                    region: { type: 'string' },
                    capabilities: { type: 'object' },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!twilioClient) {
        return sendError(reply, 503, 'Twilio not configured');
      }

      const query = SearchNumbersSchema.parse(request.query);

      try {
        const searchParams: Record<string, unknown> = {
          voiceEnabled: true,
          smsEnabled: true,
        };

        if (query.areaCode) {
          searchParams.areaCode = query.areaCode;
        }
        if (query.contains) {
          searchParams.contains = query.contains;
        }

        const numbers = await twilioClient.availablePhoneNumbers(query.country)
          .local
          .list(searchParams);

        return {
          numbers: numbers.slice(0, 20).map((n) => ({
            phoneNumber: n.phoneNumber,
            friendlyName: n.friendlyName,
            locality: n.locality,
            region: n.region,
            capabilities: {
              voice: n.capabilities.voice,
              sms: n.capabilities.sms,
              mms: n.capabilities.mms,
            },
          })),
        };
      } catch (error) {
        app.log.error({ err: error }, 'Twilio search error');
        return sendError(reply, 500, 'Failed to search numbers');
      }
    }
  );

  // Purchase a phone number
  app.post(
    '/numbers/purchase',
    {
      schema: {
        description: 'Purchase a phone number from Twilio',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          required: ['phoneNumber'],
          properties: {
            phoneNumber: { type: 'string' },
            friendlyName: { type: 'string' },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              phoneNumber: { type: 'string' },
              friendlyName: { type: 'string' },
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!twilioClient) {
        return sendError(reply, 503, 'Twilio not configured');
      }

      const { workspaceId } = request.query as { workspaceId: string };
      const body = PurchaseNumberSchema.parse(request.body);

      try {
        // Purchase from Twilio
        const purchased = await twilioClient.incomingPhoneNumbers.create({
          phoneNumber: body.phoneNumber,
          friendlyName: body.friendlyName ?? `HomeOS - ${new Date().toISOString().split('T')[0]}`,
        });

        // Store in database
        const result = await pool.query(
          `INSERT INTO homeos.phone_numbers
           (workspace_id, phone_number, twilio_sid, friendly_name, capabilities, status)
           VALUES ($1, $2, $3, $4, $5, 'active')
           RETURNING id, phone_number, friendly_name, status`,
          [
            workspaceId,
            purchased.phoneNumber,
            purchased.sid,
            purchased.friendlyName,
            JSON.stringify({
              voice: purchased.capabilities.voice,
              sms: purchased.capabilities.sms,
            }),
          ]
        );

        return reply.status(201).send({
          id: result.rows[0].id,
          phoneNumber: result.rows[0].phone_number,
          friendlyName: result.rows[0].friendly_name,
          status: result.rows[0].status,
        });
      } catch (error) {
        app.log.error({ err: error }, 'Twilio purchase error');
        return sendError(reply, 500, 'Failed to purchase number');
      }
    }
  );

  // List workspace phone numbers
  app.get(
    '/numbers',
    {
      schema: {
        description: 'List phone numbers for a workspace',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                phoneNumber: { type: 'string' },
                friendlyName: { type: 'string' },
                capabilities: { type: 'object' },
                status: { type: 'string' },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `SELECT id, phone_number, friendly_name, capabilities, status, created_at
         FROM homeos.phone_numbers
         WHERE workspace_id = $1 AND status = 'active'
         ORDER BY created_at DESC`,
        [workspaceId]
      );

      return result.rows.map((row) => ({
        id: row.id,
        phoneNumber: row.phone_number,
        friendlyName: row.friendly_name,
        capabilities: row.capabilities,
        status: row.status,
        createdAt: row.created_at,
      }));
    }
  );

  // Release a phone number
  app.delete(
    '/numbers/:id',
    {
      schema: {
        description: 'Release a phone number',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      if (!twilioClient) {
        return sendError(reply, 503, 'Twilio not configured');
      }

      const { id } = request.params as { id: string };
      const { workspaceId } = request.query as { workspaceId: string };

      // Get the Twilio SID
      const result = await pool.query(
        `SELECT twilio_sid FROM homeos.phone_numbers
         WHERE id = $1 AND workspace_id = $2`,
        [id, workspaceId]
      );

      if (result.rows.length === 0) {
        return sendError(reply, 404, 'Phone number not found');
      }

      try {
        // Release from Twilio
        await twilioClient.incomingPhoneNumbers(result.rows[0].twilio_sid).remove();

        // Update database
        await pool.query(
          `UPDATE homeos.phone_numbers SET status = 'released' WHERE id = $1`,
          [id]
        );

        return { success: true };
      } catch (error) {
        app.log.error({ err: error }, 'Twilio release error');
        return sendError(reply, 500, 'Failed to release number');
      }
    }
  );

  // Get call history
  app.get(
    '/calls',
    {
      schema: {
        description: 'Get call history for a workspace',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            limit: { type: 'integer', default: 50 },
            offset: { type: 'integer', default: 0 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              calls: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    direction: { type: 'string' },
                    toNumber: { type: 'string' },
                    fromNumber: { type: 'string' },
                    status: { type: 'string' },
                    durationSeconds: { type: 'integer' },
                    outcome: { type: 'string' },
                    purpose: { type: 'string' },
                    businessName: { type: 'string' },
                    startedAt: { type: 'string' },
                    endedAt: { type: 'string' },
                  },
                },
              },
              total: { type: 'integer' },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId, limit, offset } = request.query as {
        workspaceId: string;
        limit: number;
        offset: number;
      };

      const [callsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT id, direction, to_number, from_number, status, duration_seconds,
                  outcome, purpose, business_name, started_at, ended_at
           FROM homeos.call_history
           WHERE workspace_id = $1
           ORDER BY created_at DESC
           LIMIT $2 OFFSET $3`,
          [workspaceId, limit ?? 50, offset ?? 0]
        ),
        pool.query(
          `SELECT COUNT(*) FROM homeos.call_history WHERE workspace_id = $1`,
          [workspaceId]
        ),
      ]);

      return {
        calls: callsResult.rows.map((row) => ({
          id: row.id,
          direction: row.direction,
          toNumber: row.to_number,
          fromNumber: row.from_number,
          status: row.status,
          durationSeconds: row.duration_seconds,
          outcome: row.outcome,
          purpose: row.purpose,
          businessName: row.business_name,
          startedAt: row.started_at,
          endedAt: row.ended_at,
        })),
        total: parseInt(countResult.rows[0].count, 10),
      };
    }
  );

  // Get call details with transcript
  app.get(
    '/calls/:id',
    {
      schema: {
        description: 'Get call details with transcript',
        tags: ['twilio'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              direction: { type: 'string' },
              toNumber: { type: 'string' },
              fromNumber: { type: 'string' },
              status: { type: 'string' },
              durationSeconds: { type: 'integer' },
              transcript: { type: 'string' },
              liveTranscript: { type: 'array' },
              recordingUrl: { type: 'string' },
              outcome: { type: 'string' },
              purpose: { type: 'string' },
              businessName: { type: 'string' },
              metadata: { type: 'object' },
              startedAt: { type: 'string' },
              endedAt: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { id } = request.params as { id: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `SELECT * FROM homeos.call_history
         WHERE id = $1 AND workspace_id = $2`,
        [id, workspaceId]
      );

      if (result.rows.length === 0) {
        return sendError(reply, 404, 'Call not found');
      }

      const row = result.rows[0];
      return {
        id: row.id,
        direction: row.direction,
        toNumber: row.to_number,
        fromNumber: row.from_number,
        status: row.status,
        durationSeconds: row.duration_seconds,
        transcript: row.transcript,
        liveTranscript: row.live_transcript,
        recordingUrl: row.recording_url,
        outcome: row.outcome,
        purpose: row.purpose,
        businessName: row.business_name,
        metadata: row.metadata,
        startedAt: row.started_at,
        endedAt: row.ended_at,
      };
    }
  );
};
