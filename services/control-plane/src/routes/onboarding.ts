import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';

const DeviceSchema = z.object({
  deviceId: z.string().nullable().optional(),
  model: z.string(),
  systemVersion: z.string(),
  appVersion: z.string(),
});

const ContactSchema = z.object({
  identifier: z.string(),
  displayName: z.string(),
  relationHints: z.array(z.string()),
  isFamilyCandidate: z.boolean(),
  phoneLast4: z.array(z.string()),
  emailDomains: z.array(z.string()),
});

const EventSchema = z.object({
  title: z.string(),
  startDate: z.string(),
  endDate: z.string(),
  isAllDay: z.boolean(),
  location: z.string().nullable().optional(),
  calendarName: z.string(),
  hasRecurrence: z.boolean(),
});

const LocationSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  accuracyMeters: z.number(),
  timestamp: z.string(),
});

const InferenceSchema = z.object({
  timestamp: z.string(),
  device: DeviceSchema,
  permissions: z.record(z.string()),
  contacts: z.array(ContactSchema),
  events: z.array(EventSchema),
  location: LocationSchema.nullable().optional(),
  photosOptIn: z.boolean(),
  workspaceId: z.string().uuid().optional(),
});

const FamilyMemberSchema = z.object({
  name: z.string().min(1),
  role: z.enum(['parent', 'teen', 'child', 'caregiver', 'other']),
  age: z.number().int().min(0).max(120).optional().nullable(),
});

const FamilyConfirmSchema = z.object({
  workspaceId: z.string().uuid(),
  members: z.array(FamilyMemberSchema),
});

function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

export const onboardingRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/inference',
    {
      schema: {
        description: 'Store onboarding inference snapshot',
        tags: ['onboarding'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['timestamp', 'device', 'permissions', 'contacts', 'events', 'photosOptIn'],
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const payload = InferenceSchema.parse(request.body);

      const result = await pool.query(
        `INSERT INTO homeos.onboarding_inference (workspace_id, user_id, payload)
         VALUES ($1, $2, $3)
         RETURNING id`,
        [payload.workspaceId ?? null, userId, JSON.stringify(payload)]
      );

      return reply.status(201).send({ id: result.rows[0].id });
    }
  );

  app.post(
    '/family',
    {
      schema: {
        description: 'Persist confirmed family members',
        tags: ['onboarding'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'members'],
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
      const userId = (request.user as { sub: string }).sub;
      const body = FamilyConfirmSchema.parse(request.body);

      // Ensure user has access to workspace
      const workspaceMembership = await pool.query(
        `SELECT 1 FROM homeos.workspace_members
         WHERE workspace_id = $1 AND user_id = $2`,
        [body.workspaceId, userId]
      );
      if (workspaceMembership.rowCount === 0) {
        return sendError(reply, 403, 'Not authorized for workspace');
      }

      await pool.query(
        `DELETE FROM homeos.family_members WHERE workspace_id = $1`,
        [body.workspaceId]
      );

      for (const member of body.members) {
        await pool.query(
          `INSERT INTO homeos.family_members (workspace_id, name, relationship, age)
           VALUES ($1, $2, $3, $4)`,
          [body.workspaceId, member.name, member.role, member.age ?? null]
        );
      }

      return { success: true };
    }
  );
};
