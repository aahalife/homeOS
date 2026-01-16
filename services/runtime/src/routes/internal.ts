import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { emitToWorkspace } from '../ws/stream.js';
import { queueNotificationForEvent } from '../services/notifications.js';

const SERVICE_TOKEN = process.env['RUNTIME_SERVICE_TOKEN'];

const EventSchema = z.object({
  workspaceId: z.string().uuid(),
  type: z.string().min(1),
  payload: z.record(z.unknown()),
  userId: z.string().uuid().optional(),
  notification: z
    .object({
      title: z.string().min(1),
      body: z.string().min(1),
      priority: z.enum(['normal', 'urgent']).optional(),
    })
    .optional(),
});

export const internalRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    if (!SERVICE_TOKEN) {
      return reply.status(503).send({ error: 'Service token not configured' });
    }
    const token = request.headers['x-service-token'];
    if (!token || token !== SERVICE_TOKEN) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/events',
    {
      schema: {
        description: 'Internal: emit event and queue notifications',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'type', 'payload'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            type: { type: 'string' },
            payload: { type: 'object', additionalProperties: true },
            userId: { type: 'string', format: 'uuid' },
            notification: {
              type: 'object',
              properties: {
                title: { type: 'string' },
                body: { type: 'string' },
                priority: { type: 'string', enum: ['normal', 'urgent'] },
              },
            },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              notificationQueued: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request) => {
      const event = EventSchema.parse(request.body);

      emitToWorkspace(event.workspaceId, {
        type: event.type,
        payload: event.payload,
      });

      const queued = await queueNotificationForEvent({
        workspaceId: event.workspaceId,
        userId: event.userId,
        eventType: event.type,
        payload: event.payload,
        notification: event.notification,
      });

      return {
        success: true,
        notificationQueued: Boolean(queued),
      };
    }
  );
};
