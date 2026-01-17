import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import { WorkspaceService } from '../services/workspace.js';

const UsageQuerySchema = z.object({
  workspaceId: z.string().uuid(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
});

export const usageRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();
  const workspaceService = new WorkspaceService();

  app.addHook('onRequest', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/llm',
    {
      schema: {
        description: 'Get LLM usage summary for a workspace',
        tags: ['usage'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            from: { type: 'string' },
            to: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              totalTokens: { type: 'number' },
              totalCostUsd: { type: 'number' },
              byProvider: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    provider: { type: 'string' },
                    model: { type: 'string' },
                    tokens: { type: 'number' },
                    costUsd: { type: 'number' },
                  },
                },
              },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const userId = (request.user as { sub: string }).sub;
      const { workspaceId, from, to } = UsageQuerySchema.parse(request.query);

      const isMember = await workspaceService.isUserMember(workspaceId, userId);
      if (!isMember) {
        return reply.status(403).send({ error: 'Not authorized' });
      }

      const params: unknown[] = [workspaceId];
      let where = 'workspace_id = $1';

      if (from) {
        params.push(from);
        where += ` AND created_at >= $${params.length}`;
      }

      if (to) {
        params.push(to);
        where += ` AND created_at <= $${params.length}`;
      }

      const summary = await pool.query(
        `SELECT provider, model,
                COALESCE(SUM(total_tokens), 0) AS tokens,
                COALESCE(SUM(estimated_cost_usd), 0) AS cost_usd
         FROM homeos.llm_usage
         WHERE ${where}
         GROUP BY provider, model
         ORDER BY cost_usd DESC`,
        params
      );

      const totals = summary.rows.reduce(
        (acc, row) => {
          acc.totalTokens += Number(row.tokens ?? 0);
          acc.totalCostUsd += Number(row.cost_usd ?? 0);
          return acc;
        },
        { totalTokens: 0, totalCostUsd: 0 }
      );

      return {
        totalTokens: totals.totalTokens,
        totalCostUsd: totals.totalCostUsd,
        byProvider: summary.rows.map((row) => ({
          provider: row.provider,
          model: row.model,
          tokens: Number(row.tokens ?? 0),
          costUsd: Number(row.cost_usd ?? 0),
        })),
      };
    }
  );
};
