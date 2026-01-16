import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';

function sendError(reply: FastifyReply, status: number, message: string) {
  return reply.status(status).send({ error: message });
}

const ListNotificationsSchema = z.object({
  workspaceId: z.string().uuid(),
  status: z.enum(['queued', 'delivered', 'read', 'failed']).optional(),
  limit: z.coerce.number().min(1).max(100).optional(),
  offset: z.coerce.number().min(0).optional(),
});

export const notificationsRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/',
    {
      schema: {
        description: 'List notifications for current user',
        tags: ['notifications'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            status: { type: 'string', enum: ['queued', 'delivered', 'read', 'failed'] },
            limit: { type: 'integer', minimum: 1, maximum: 100 },
            offset: { type: 'integer', minimum: 0 },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                type: { type: 'string' },
                title: { type: 'string' },
                body: { type: 'string' },
                status: { type: 'string' },
                createdAt: { type: 'string' },
                deliverAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId, status, limit = 50, offset = 0 } = ListNotificationsSchema.parse(
        request.query
      );

      const values: unknown[] = [workspaceId, userId, limit, offset];
      let sql = `
        SELECT id, type, title, body, status, created_at, deliver_at
        FROM homeos.notifications
        WHERE workspace_id = $1 AND (user_id = $2 OR user_id IS NULL)
      `;

      if (status) {
        sql += ` AND status = $5`;
        values.push(status);
      }

      sql += ` ORDER BY created_at DESC LIMIT $3 OFFSET $4`;

      const result = await pool.query(sql, values);
      return result.rows.map((row) => ({
        id: row.id,
        type: row.type,
        title: row.title,
        body: row.body,
        status: row.status,
        createdAt: row.created_at,
        deliverAt: row.deliver_at,
      }));
    }
  );

  app.post(
    '/:id/read',
    {
      schema: {
        description: 'Mark a notification as read',
        tags: ['notifications'],
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
      const userId = (request.user as { sub: string }).sub;
      const { id } = request.params as { id: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `UPDATE homeos.notifications
         SET status = 'read', updated_at = NOW()
         WHERE id = $1 AND workspace_id = $2 AND (user_id = $3 OR user_id IS NULL)`,
        [id, workspaceId, userId]
      );

      if (result.rowCount === 0) {
        return sendError(reply, 404, 'Notification not found');
      }

      return { success: true };
    }
  );
};
