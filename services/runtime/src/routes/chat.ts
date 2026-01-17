import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { ChatTurnInputSchema } from '@homeos/shared/schemas';
import { emitToWorkspace } from '../ws/stream.js';
import { startWorkflowRun } from '../services/temporal.js';

export const chatRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/turn',
    {
      schema: {
        description: 'Start a new chat turn, creating a ChatTurnWorkflow',
        tags: ['chat'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'message'],
          properties: {
            sessionId: { type: 'string', format: 'uuid' },
            workspaceId: { type: 'string', format: 'uuid' },
            message: { type: 'string', minLength: 1, maxLength: 32000 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              sessionId: { type: 'string' },
              taskId: { type: 'string' },
              workflowId: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
          500: {
            type: 'object',
            properties: {
              error: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const user = request.user as { sub: string; workspaceId?: string };
      const body = ChatTurnInputSchema.parse({
        ...request.body as Record<string, unknown>,
        userId: user.sub,
      });

      // Verify user has access to workspace
      const tokenWorkspaceId = user.workspaceId;
      if (tokenWorkspaceId && tokenWorkspaceId !== body.workspaceId) {
        return reply.status(403).send({ error: 'Workspace mismatch' });
      }

      try {
        const { workflowId } = await startWorkflowRun({
          workspaceId: body.workspaceId,
          userId: body.userId,
          workflowType: 'ChatTurnWorkflow',
          triggerType: 'chat',
          input: {
            sessionId: body.sessionId,
            workspaceId: body.workspaceId,
            userId: body.userId,
            message: body.message,
          },
        });

        // Emit task created event
        emitToWorkspace(body.workspaceId, {
          type: 'task.created',
          payload: {
            taskId: workflowId,
            workflowId,
            title: 'Processing chat message',
            status: 'running',
          },
        });

        return {
          sessionId: body.sessionId ?? workflowId,
          taskId: workflowId,
          workflowId,
        };
      } catch (error) {
        app.log.error(error, 'Failed to start ChatTurnWorkflow');
        return reply.status(500).send({ error: 'Failed to process chat turn' });
      }
    }
  );

  app.get(
    '/sessions',
    {
      schema: {
        description: 'List chat sessions for workspace',
        tags: ['chat'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
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
                id: { type: 'string' },
                title: { type: 'string' },
                createdAt: { type: 'string' },
                updatedAt: { type: 'string' },
              },
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

      // TODO: Implement session listing from database
      return [];
    }
  );

  app.get(
    '/sessions/:sessionId/messages',
    {
      schema: {
        description: 'Get messages for a chat session',
        tags: ['chat'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['sessionId'],
          properties: {
            sessionId: { type: 'string', format: 'uuid' },
          },
        },
        querystring: {
          type: 'object',
          properties: {
            limit: { type: 'integer', default: 50 },
            before: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                role: { type: 'string' },
                content: { type: 'string' },
                createdAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { sessionId } = request.params as { sessionId: string };

      // TODO: Implement message retrieval from database
      return [];
    }
  );
};
