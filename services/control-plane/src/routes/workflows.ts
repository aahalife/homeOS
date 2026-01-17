import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import { WorkspaceService } from '../services/workspace.js';

const ListRunsSchema = z.object({
  workspaceId: z.string().uuid(),
  status: z.string().optional(),
  workflowType: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

export const workflowsRoutes: FastifyPluginAsync = async (app) => {
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
    '/runs',
    {
      schema: {
        description: 'List workflow runs for a workspace',
        tags: ['workflows'],
        security: [{ bearerAuth: [] }],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            status: { type: 'string' },
            workflowType: { type: 'string' },
            limit: { type: 'integer', default: 20 },
            offset: { type: 'integer', default: 0 },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              runs: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    workflowId: { type: 'string' },
                    runId: { type: 'string' },
                    workspaceId: { type: 'string' },
                    workflowType: { type: 'string' },
                    triggerType: { type: 'string' },
                    triggeredBy: { type: 'string' },
                    status: { type: 'string' },
                    attempts: { type: 'integer' },
                    maxAttempts: { type: 'integer' },
                    startedAt: { type: 'string' },
                    completedAt: { type: 'string' },
                    error: { type: 'string' },
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
      const { workspaceId, status, workflowType, limit = 20, offset = 0 } = ListRunsSchema.parse(
        request.query
      );

      const isMember = await workspaceService.isUserMember(workspaceId, userId);
      if (!isMember) {
        return reply.status(403).send({ error: 'Forbidden' });
      }

      const filters: string[] = ['workspace_id = $1'];
      const values: Array<string | number> = [workspaceId];
      let idx = values.length;

      if (status) {
        idx += 1;
        filters.push(`status = $${idx}`);
        values.push(status);
      }
      if (workflowType) {
        idx += 1;
        filters.push(`workflow_type = $${idx}`);
        values.push(workflowType);
      }

      idx += 1;
      values.push(limit);
      const limitIdx = idx;
      idx += 1;
      values.push(offset);
      const offsetIdx = idx;

      const result = await pool.query(
        `SELECT workflow_id, run_id, workspace_id, workflow_type, trigger_type,
                triggered_by, status, attempts, max_attempts, started_at, completed_at, error
         FROM homeos.workflow_runs
         WHERE ${filters.join(' AND ')}
         ORDER BY started_at DESC
         LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
        values
      );

      return {
        runs: result.rows.map((row) => ({
          workflowId: row.workflow_id,
          runId: row.run_id ?? undefined,
          workspaceId: row.workspace_id,
          workflowType: row.workflow_type,
          triggerType: row.trigger_type,
          triggeredBy: row.triggered_by ?? undefined,
          status: row.status,
          attempts: row.attempts,
          maxAttempts: row.max_attempts ?? undefined,
          startedAt: row.started_at,
          completedAt: row.completed_at ?? undefined,
          error: row.error ?? undefined,
        })),
      };
    }
  );

  app.get(
    '/runs/:workflowId',
    {
      schema: {
        description: 'Get workflow run details',
        tags: ['workflows'],
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          required: ['workflowId'],
          properties: {
            workflowId: { type: 'string' },
          },
        },
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
              workflowId: { type: 'string' },
              runId: { type: 'string' },
              workspaceId: { type: 'string' },
              workflowType: { type: 'string' },
              triggerType: { type: 'string' },
              triggeredBy: { type: 'string' },
              status: { type: 'string' },
              attempts: { type: 'integer' },
              maxAttempts: { type: 'integer' },
              startedAt: { type: 'string' },
              completedAt: { type: 'string' },
              error: { type: 'string' },
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
      const { workflowId } = request.params as { workflowId: string };
      const { workspaceId } = request.query as { workspaceId: string };

      const isMember = await workspaceService.isUserMember(workspaceId, userId);
      if (!isMember) {
        return reply.status(403).send({ error: 'Forbidden' });
      }

      const result = await pool.query(
        `SELECT workflow_id, run_id, workspace_id, workflow_type, trigger_type,
                triggered_by, status, attempts, max_attempts, started_at, completed_at, error
         FROM homeos.workflow_runs
         WHERE workflow_id = $1 AND workspace_id = $2
         LIMIT 1`,
        [workflowId, workspaceId]
      );

      const row = result.rows[0];
      if (!row) {
        return reply.status(404).send({ error: 'Workflow run not found' });
      }

      return {
        workflowId: row.workflow_id,
        runId: row.run_id ?? undefined,
        workspaceId: row.workspace_id,
        workflowType: row.workflow_type,
        triggerType: row.trigger_type,
        triggeredBy: row.triggered_by ?? undefined,
        status: row.status,
        attempts: row.attempts,
        maxAttempts: row.max_attempts ?? undefined,
        startedAt: row.started_at,
        completedAt: row.completed_at ?? undefined,
        error: row.error ?? undefined,
      };
    }
  );
};
