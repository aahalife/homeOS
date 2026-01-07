import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { SecretsService } from '../services/secrets.js';

const SetSecretSchema = z.object({
  provider: z.enum(['openai', 'anthropic']),
  apiKey: z.string().min(1),
});

export const secretsRoutes: FastifyPluginAsync = async (app) => {
  const secretsService = new SecretsService();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.post(
    '/:id/secrets',
    {
      schema: {
        description: 'Store an encrypted API key for a workspace (BYOK)',
        tags: ['secrets'],
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
          required: ['provider', 'apiKey'],
          properties: {
            provider: { type: 'string', enum: ['openai', 'anthropic'] },
            apiKey: { type: 'string', minLength: 1 },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              provider: { type: 'string' },
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
      const { id: workspaceId } = request.params as { id: string };
      const body = SetSecretSchema.parse(request.body);

      try {
        await secretsService.setSecret(workspaceId, userId, body.provider, body.apiKey);
        return reply.status(201).send({
          success: true,
          provider: body.provider,
        });
      } catch (error) {
        if (error instanceof Error && error.message === 'Not authorized') {
          return reply.status(403).send({ error: 'Not authorized' });
        }
        throw error;
      }
    }
  );

  app.get(
    '/:id/secrets/status',
    {
      schema: {
        description: 'Get status of configured secrets for a workspace (never returns actual keys)',
        tags: ['secrets'],
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
            type: 'array',
            items: {
              type: 'object',
              properties: {
                provider: { type: 'string' },
                configured: { type: 'boolean' },
                lastTestedAt: { type: 'string' },
                testSuccessful: { type: 'boolean' },
              },
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
      const { id: workspaceId } = request.params as { id: string };

      try {
        const status = await secretsService.getStatus(workspaceId, userId);
        return status;
      } catch (error) {
        if (error instanceof Error && error.message === 'Not authorized') {
          return reply.status(403).send({ error: 'Not authorized' });
        }
        throw error;
      }
    }
  );

  app.post(
    '/:id/secrets/test',
    {
      schema: {
        description: 'Test connection for a configured secret',
        tags: ['secrets'],
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
          required: ['provider'],
          properties: {
            provider: { type: 'string', enum: ['openai', 'anthropic'] },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              provider: { type: 'string' },
              error: { type: 'string' },
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
      const { id: workspaceId } = request.params as { id: string };
      const { provider } = request.body as { provider: 'openai' | 'anthropic' };

      try {
        const result = await secretsService.testConnection(workspaceId, userId, provider);
        return result;
      } catch (error) {
        if (error instanceof Error && error.message === 'Not authorized') {
          return reply.status(403).send({ error: 'Not authorized' });
        }
        throw error;
      }
    }
  );

  app.delete(
    '/:id/secrets/:provider',
    {
      schema: {
        description: 'Delete a secret for a workspace',
        tags: ['secrets'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['id', 'provider'],
          properties: {
            id: { type: 'string', format: 'uuid' },
            provider: { type: 'string', enum: ['openai', 'anthropic'] },
          },
        },
        response: {
          200: {
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
      const { id: workspaceId, provider } = request.params as {
        id: string;
        provider: 'openai' | 'anthropic';
      };

      try {
        await secretsService.deleteSecret(workspaceId, userId, provider);
        return { success: true };
      } catch (error) {
        if (error instanceof Error && error.message === 'Not authorized') {
          return reply.status(403).send({ error: 'Not authorized' });
        }
        throw error;
      }
    }
  );
};
