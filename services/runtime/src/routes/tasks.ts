import type { FastifyPluginAsync } from 'fastify';
import { emitToWorkspace } from '../ws/stream.js';

export const tasksRoutes: FastifyPluginAsync = async (app) => {
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
        description: 'List tasks for workspace',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            status: {
              type: 'string',
              enum: ['queued', 'running', 'needs_approval', 'blocked', 'done', 'failed'],
            },
            limit: { type: 'integer', default: 20 },
            offset: { type: 'integer', default: 0 },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                taskId: { type: 'string' },
                title: { type: 'string' },
                category: { type: 'string' },
                status: { type: 'string' },
                riskLevel: { type: 'string' },
                summaryForUser: { type: 'string' },
                createdAt: { type: 'string' },
                updatedAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId, status, limit, offset } = request.query as {
        workspaceId: string;
        status?: string;
        limit: number;
        offset: number;
      };

      // TODO: Implement task listing from database
      return [];
    }
  );

  app.get(
    '/:taskId',
    {
      schema: {
        description: 'Get task details',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              taskId: { type: 'string' },
              workspaceId: { type: 'string' },
              title: { type: 'string' },
              category: { type: 'string' },
              status: { type: 'string' },
              riskLevel: { type: 'string' },
              requiresApproval: { type: 'boolean' },
              approvalState: { type: 'string' },
              summaryForUser: { type: 'string' },
              details: { type: 'object' },
              auditTrail: { type: 'array' },
              linkedWorkflowId: { type: 'string' },
              createdAt: { type: 'string' },
              updatedAt: { type: 'string' },
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
      const { taskId } = request.params as { taskId: string };

      // TODO: Implement task retrieval from database
      return reply.status(404).send({ error: 'Task not found' });
    }
  );

  app.post(
    '/:taskId/approve',
    {
      schema: {
        description: 'Approve a task that requires approval',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          required: ['envelopeId'],
          properties: {
            envelopeId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              taskId: { type: 'string' },
            },
          },
          501: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { taskId } = request.params as { taskId: string };
      const { envelopeId } = request.body as { envelopeId: string };
      const userId = (request.user as { sub: string }).sub;

      // TODO: Implement approval logic
      // 1. Verify envelope exists and matches task
      // 2. Generate approval token
      // 3. Signal workflow to continue
      // 4. Update task status

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );

  app.post(
    '/:taskId/deny',
    {
      schema: {
        description: 'Deny a task that requires approval',
        tags: ['tasks'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          properties: {
            reason: { type: 'string', maxLength: 500 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              taskId: { type: 'string' },
            },
          },
          501: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { taskId } = request.params as { taskId: string };
      const { reason } = request.body as { reason?: string };
      const userId = (request.user as { sub: string }).sub;

      // TODO: Implement denial logic

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );
};
