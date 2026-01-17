import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import { SecretsService } from '../services/secrets.js';

const SERVICE_TOKEN = process.env['CONTROL_PLANE_SERVICE_TOKEN'];

const NotificationPrefsSchema = z.object({
  workspaceId: z.string().uuid(),
  userId: z.string().uuid().optional(),
});

const DEFAULT_NOTIFICATIONS = {
  calls: true,
  tasks: true,
  approvals: true,
  dailyDigest: true,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
};

const CreateNotificationSchema = z.object({
  workspaceId: z.string().uuid(),
  userId: z.string().uuid().optional(),
  type: z.string().min(1),
  title: z.string().min(1),
  body: z.string().min(1),
  status: z.enum(['queued', 'delivered', 'read', 'failed']).optional(),
  deliverAt: z.string().datetime().optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const internalRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();
  const secretsService = new SecretsService();

  app.addHook('onRequest', async (request, reply) => {
    if (!SERVICE_TOKEN) {
      return reply.status(503).send({ error: 'Service token not configured' });
    }
    const token = request.headers['x-service-token'];
    if (!token || token !== SERVICE_TOKEN) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/preferences/notifications',
    {
      schema: {
        description: 'Internal: get notification preferences for a workspace',
        tags: ['internal'],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            additionalProperties: true,
          },
        },
      },
    },
    async (request) => {
      const { workspaceId, userId } = NotificationPrefsSchema.parse(request.query);

      const result = userId
        ? await pool.query(
            `SELECT preferences FROM homeos.user_preferences
             WHERE workspace_id = $1 AND user_id = $2 AND category = 'notifications'
             LIMIT 1`,
            [workspaceId, userId]
          )
        : await pool.query(
            `SELECT preferences FROM homeos.user_preferences
             WHERE workspace_id = $1 AND category = 'notifications'
             ORDER BY updated_at DESC
             LIMIT 1`,
            [workspaceId]
          );

      const stored = result.rows[0]?.preferences ?? {};
      return { ...DEFAULT_NOTIFICATIONS, ...stored };
    }
  );

  app.post(
    '/notifications',
    {
      schema: {
        description: 'Internal: create a notification record',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'type', 'title', 'body'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
            type: { type: 'string' },
            title: { type: 'string' },
            body: { type: 'string' },
            status: { type: 'string', enum: ['queued', 'delivered', 'read', 'failed'] },
            deliverAt: { type: 'string' },
            metadata: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = CreateNotificationSchema.parse(request.body);

      const result = await pool.query(
        `INSERT INTO homeos.notifications
          (workspace_id, user_id, type, title, body, status, deliver_at, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, status`,
        [
          body.workspaceId,
          body.userId ?? null,
          body.type,
          body.title,
          body.body,
          body.status ?? 'queued',
          body.deliverAt ?? null,
          JSON.stringify(body.metadata ?? {}),
        ]
      );

      return reply.status(201).send({
        id: result.rows[0].id,
        status: result.rows[0].status,
      });
    }
  );

  app.get(
    '/llm-config',
    {
      schema: {
        description: 'Internal: resolve LLM config for a workspace',
        tags: ['internal'],
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
              provider: { type: 'string' },
              apiKey: { type: 'string' },
              model: { type: 'string' },
              baseUrl: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { workspaceId } = request.query as { workspaceId: string };
      const defaults = {
        provider: (process.env['DEFAULT_LLM_PROVIDER'] ?? 'modal').toLowerCase(),
        model: process.env['DEFAULT_LLM_MODEL'] ?? null,
        endpoint: process.env['MODAL_LLM_URL'] ?? null,
      };

      const result = await pool.query(
        `SELECT preferences
         FROM homeos.user_preferences
         WHERE workspace_id = $1 AND category = 'ai'
         ORDER BY updated_at DESC
         LIMIT 1`,
        [workspaceId]
      );

      const preferences = (result.rows[0]?.preferences ?? {}) as {
        llmProvider?: string;
        llmModel?: string | null;
        llmEndpoint?: string | null;
      };

      const preferred = (preferences.llmProvider ?? defaults.provider ?? 'modal').toLowerCase();
      const candidates = preferred === 'auto'
        ? ['modal', 'anthropic', 'openai']
        : [preferred];

      for (const provider of candidates) {
        if (provider === 'modal') {
          const endpoint = preferences.llmEndpoint ?? defaults.endpoint;
          if (!endpoint) {
            continue;
          }
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'modal')) ??
            process.env['MODAL_LLM_TOKEN'] ??
            '';
          return reply.send({
            provider: 'modal',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'openai-compatible',
            baseUrl: endpoint,
          });
        }

        if (provider === 'anthropic') {
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'anthropic')) ??
            process.env['ANTHROPIC_API_KEY'];
          if (!apiKey) {
            continue;
          }
          return reply.send({
            provider: 'anthropic',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'claude-sonnet-4-20250514',
            baseUrl: null,
          });
        }

        if (provider === 'openai') {
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'openai')) ??
            process.env['OPENAI_API_KEY'];
          if (!apiKey) {
            continue;
          }
          return reply.send({
            provider: 'openai',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'gpt-4o',
            baseUrl: null,
          });
        }
      }

      return reply.status(404).send({ error: 'No LLM config available' });
    }
  );

  app.post(
    '/llm-usage',
    {
      schema: {
        description: 'Internal: record LLM usage',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'provider', 'model'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
            provider: { type: 'string' },
            model: { type: 'string' },
            inputTokens: { type: 'number' },
            outputTokens: { type: 'number' },
            totalTokens: { type: 'number' },
            estimatedCostUsd: { type: 'number' },
            metadata: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = request.body as {
        workspaceId: string;
        userId?: string;
        provider: string;
        model: string;
        inputTokens?: number;
        outputTokens?: number;
        totalTokens?: number;
        estimatedCostUsd?: number;
        metadata?: Record<string, unknown>;
      };

      await pool.query(
        `INSERT INTO homeos.llm_usage
          (workspace_id, user_id, provider, model, input_tokens, output_tokens, total_tokens, estimated_cost_usd, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          body.workspaceId,
          body.userId ?? null,
          body.provider,
          body.model,
          body.inputTokens ?? null,
          body.outputTokens ?? null,
          body.totalTokens ?? null,
          body.estimatedCostUsd ?? null,
          JSON.stringify(body.metadata ?? {}),
        ]
      );

      return reply.status(201).send({ success: true });
    }
  );
};
