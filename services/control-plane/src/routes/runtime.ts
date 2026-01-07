import type { FastifyPluginAsync } from 'fastify';

const RUNTIME_URL = process.env['RUNTIME_URL'] ?? 'http://localhost:3002';
const RUNTIME_WS_URL = process.env['RUNTIME_WS_URL'] ?? 'ws://localhost:3002';

export const runtimeRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/connection-info',
    {
      schema: {
        description: 'Get runtime connection information',
        tags: ['runtime'],
        security: [{ bearerAuth: [] }],
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
              baseUrl: { type: 'string' },
              wsUrl: { type: 'string' },
              token: { type: 'string' },
            },
          },
        },
      },
    },
    async (request) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId } = request.query as { workspaceId: string };

      // Generate a runtime-specific token for this user/workspace
      const runtimeToken = app.jwt.sign(
        {
          sub: userId,
          workspaceId,
          type: 'runtime',
        },
        { expiresIn: '1h' }
      );

      return {
        baseUrl: RUNTIME_URL,
        wsUrl: `${RUNTIME_WS_URL}/v1/stream`,
        token: runtimeToken,
      };
    }
  );
};
