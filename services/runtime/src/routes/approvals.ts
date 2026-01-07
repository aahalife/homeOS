import type { FastifyPluginAsync } from 'fastify';

export const approvalsRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/pending',
    {
      schema: {
        description: 'List pending approvals for workspace',
        tags: ['approvals'],
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
            type: 'array',
            items: {
              type: 'object',
              properties: {
                envelopeId: { type: 'string' },
                taskId: { type: 'string' },
                intent: { type: 'string' },
                toolName: { type: 'string' },
                riskLevel: { type: 'string' },
                requestedAt: { type: 'string' },
                expiresAt: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId } = request.query as { workspaceId: string };

      // TODO: Implement pending approvals listing
      return [];
    }
  );

  app.get(
    '/:envelopeId',
    {
      schema: {
        description: 'Get approval envelope details',
        tags: ['approvals'],
        security: [{ bearerAuth: [] }],
        params: {
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
              envelopeId: { type: 'string' },
              workspaceId: { type: 'string' },
              intent: { type: 'string' },
              toolName: { type: 'string' },
              inputs: { type: 'object' },
              expectedOutputs: {},
              riskLevel: { type: 'string' },
              piiFields: { type: 'array', items: { type: 'string' } },
              rollbackPlan: { type: 'string' },
              auditHash: { type: 'string' },
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
      const { envelopeId } = request.params as { envelopeId: string };

      // TODO: Implement envelope retrieval
      return reply.status(404).send({ error: 'Envelope not found' });
    }
  );

  app.post(
    '/:envelopeId/approve',
    {
      schema: {
        description: 'Approve an action envelope',
        tags: ['approvals'],
        security: [{ bearerAuth: [] }],
        params: {
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
              token: { type: 'string' },
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
      const { envelopeId } = request.params as { envelopeId: string };
      const userId = (request.user as { sub: string }).sub;

      // TODO: Implement approval
      // 1. Verify envelope exists and is pending
      // 2. Generate approval token with signature
      // 3. Signal the waiting workflow
      // 4. Update envelope status

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );

  app.post(
    '/:envelopeId/deny',
    {
      schema: {
        description: 'Deny an action envelope',
        tags: ['approvals'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['envelopeId'],
          properties: {
            envelopeId: { type: 'string', format: 'uuid' },
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
      const { envelopeId } = request.params as { envelopeId: string };
      const { reason } = request.body as { reason?: string };
      const userId = (request.user as { sub: string }).sub;

      // TODO: Implement denial

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );
};
