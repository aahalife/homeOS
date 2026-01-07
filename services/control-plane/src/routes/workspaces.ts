import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { WorkspaceService } from '../services/workspace.js';

const CreateWorkspaceSchema = z.object({
  name: z.string().min(1).max(255),
});

export const workspacesRoutes: FastifyPluginAsync = async (app) => {
  const workspaceService = new WorkspaceService();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/',
    {
      schema: {
        description: 'Create a new workspace',
        tags: ['workspaces'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['name'],
          properties: {
            name: { type: 'string', minLength: 1, maxLength: 255 },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              name: { type: 'string' },
              ownerId: { type: 'string' },
              createdAt: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const body = CreateWorkspaceSchema.parse(request.body);

      const workspace = await workspaceService.create(body.name, userId);
      return reply.status(201).send(workspace);
    }
  );

  app.get(
    '/',
    {
      schema: {
        description: 'List workspaces for current user',
        tags: ['workspaces'],
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                name: { type: 'string' },
                role: { type: 'string' },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const workspaces = await workspaceService.listForUser(userId);
      return workspaces;
    }
  );

  app.get(
    '/:id',
    {
      schema: {
        description: 'Get workspace by ID',
        tags: ['workspaces'],
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
              id: { type: 'string' },
              name: { type: 'string' },
              ownerId: { type: 'string' },
              members: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    userId: { type: 'string' },
                    role: { type: 'string' },
                    name: { type: 'string' },
                  },
                },
              },
              createdAt: { type: 'string' },
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

      const workspace = await workspaceService.findById(id, userId);
      if (!workspace) {
        return reply.status(404).send({ error: 'Workspace not found' });
      }

      return workspace;
    }
  );

  app.post(
    '/:id/members',
    {
      schema: {
        description: 'Add a member to workspace',
        tags: ['workspaces'],
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
          required: ['email', 'role'],
          properties: {
            email: { type: 'string', format: 'email' },
            role: { type: 'string', enum: ['admin', 'member'] },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
          403: {
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
      const { email, role } = request.body as { email: string; role: 'admin' | 'member' };

      try {
        await workspaceService.addMember(id, userId, email, role);
        return reply.status(201).send({ success: true });
      } catch (error) {
        if (error instanceof Error && error.message === 'Not authorized') {
          return reply.status(403).send({ error: 'Not authorized' });
        }
        throw error;
      }
    }
  );
};
