import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';

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
};
