import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const IngestNoteSchema = z.object({
  workspaceId: z.string().uuid(),
  content: z.string().min(1).max(100000),
  source: z.enum(['share_extension', 'clipboard', 'voice', 'manual']).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export const ingestRoutes: FastifyPluginAsync = async (app) => {
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
        description: 'Ingest content (Note→Action intake)',
        tags: ['ingest'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'content'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            content: { type: 'string', minLength: 1, maxLength: 100000 },
            source: {
              type: 'string',
              enum: ['share_extension', 'clipboard', 'voice', 'manual'],
            },
            metadata: { type: 'object' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              taskId: { type: 'string' },
              workflowId: { type: 'string' },
              extractedActions: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    type: { type: 'string' },
                    description: { type: 'string' },
                  },
                },
              },
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
      const userId = (request.user as { sub: string }).sub;
      const body = IngestNoteSchema.parse(request.body);

      // TODO: Implement ingestion workflow
      // 1. Parse content to extract actions
      // 2. Create tasks for each action
      // 3. Start appropriate workflows

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );

  app.post(
    '/url',
    {
      schema: {
        description: 'Ingest content from URL',
        tags: ['ingest'],
        security: [{ bearerAuth: [] }],
        body: {
          type: 'object',
          required: ['workspaceId', 'url'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            url: { type: 'string', format: 'uri' },
            instructions: { type: 'string', maxLength: 1000 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              taskId: { type: 'string' },
              workflowId: { type: 'string' },
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
      const { workspaceId, url, instructions } = request.body as {
        workspaceId: string;
        url: string;
        instructions?: string;
      };

      // TODO: Implement URL ingestion
      // 1. Fetch URL content
      // 2. Summarize and extract actions
      // 3. Create task

      return reply.status(501).send({ error: 'Not implemented' });
    }
  );
};
