import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { DeviceService } from '../services/device.js';

const RegisterDeviceSchema = z.object({
  workspaceId: z.string().uuid(),
  name: z.string().min(1).max(255),
  platform: z.enum(['ios', 'macos', 'web']),
  apnsToken: z.string().optional(),
});

export const devicesRoutes: FastifyPluginAsync = async (app) => {
  const deviceService = new DeviceService();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/register',
    {
      schema: {
        description: 'Register a device for push notifications',
        tags: ['devices'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'name', 'platform'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            name: { type: 'string', minLength: 1, maxLength: 255 },
            platform: { type: 'string', enum: ['ios', 'macos', 'web'] },
            apnsToken: { type: 'string' },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              platform: { type: 'string' },
              createdAt: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const body = RegisterDeviceSchema.parse(request.body);

      const device = await deviceService.register({
        userId,
        workspaceId: body.workspaceId,
        name: body.name,
        platform: body.platform,
        apnsToken: body.apnsToken,
      });

      return reply.status(201).send({
        id: device.id,
        name: device.name,
        platform: device.platform,
        createdAt: device.createdAt,
      });
    }
  );

  app.get(
    '/',
    {
      schema: {
        description: 'List devices for current user',
        tags: ['devices'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
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
                name: { type: 'string' },
                platform: { type: 'string' },
                lastSeenAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId } = request.query as { workspaceId?: string };

      const devices = await deviceService.listForUser(userId, workspaceId);
      return devices;
    }
  );

  app.put(
    '/:id/token',
    {
      schema: {
        description: 'Update APNS token for a device',
        tags: ['devices'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          required: ['apnsToken'],
          properties: {
            apnsToken: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
          404: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { id } = request.params as { id: string };
      const { apnsToken } = request.body as { apnsToken: string };

      const success = await deviceService.updateToken(id, userId, apnsToken);
      if (!success) {
        return reply.status(404).send({ error: 'Device not found' });
      }

      return { success: true };
    }
  );

  app.delete(
    '/:id',
    {
      schema: {
        description: 'Unregister a device',
        tags: ['devices'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['id'],
          properties: {
            id: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
          404: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { id } = request.params as { id: string };

      const success = await deviceService.unregister(id, userId);
      if (!success) {
        return reply.status(404).send({ error: 'Device not found' });
      }

      return { success: true };
    }
  );
};
