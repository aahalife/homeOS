import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { getPool } from '../db.js';
import { SecretsService } from '../services/secrets.js';

const SERVICE_TOKEN = process.env['CONTROL_PLANE_SERVICE_TOKEN'];

const NotificationPrefsSchema = z.object({
  workspaceId: z.string().uuid(),
  userId: z.string().uuid().optional(),
});

const DEFAULT_NOTIFICATIONS = {
  calls: true,
  tasks: true,
  approvals: true,
  dailyDigest: true,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',
};

const CreateNotificationSchema = z.object({
  workspaceId: z.string().uuid(),
  userId: z.string().uuid().optional(),
  type: z.string().min(1),
  title: z.string().min(1),
  body: z.string().min(1),
  status: z.enum(['queued', 'delivered', 'read', 'failed']).optional(),
  deliverAt: z.string().datetime().optional(),
  metadata: z.record(z.unknown()).optional(),
});

const WorkflowRunUpsertSchema = z.object({
  workspaceId: z.string().uuid(),
  workflowId: z.string().min(1),
  runId: z.string().min(1).optional().nullable(),
  workflowType: z.string().min(1),
  triggerType: z.string().min(1).optional().nullable(),
  triggeredBy: z.string().uuid().optional().nullable(),
  status: z.enum(['queued', 'running', 'retrying', 'succeeded', 'failed', 'canceled']).optional(),
  attempts: z.number().int().positive().optional(),
  maxAttempts: z.number().int().positive().optional().nullable(),
  input: z.record(z.unknown()).optional(),
  result: z.record(z.unknown()).optional(),
  error: z.string().optional().nullable(),
  startedAt: z.string().datetime().optional(),
  completedAt: z.string().datetime().optional().nullable(),
});

const ApprovalEnvelopeSchema = z.object({
  envelopeId: z.string().uuid(),
  workspaceId: z.string().uuid(),
  intent: z.string().min(1),
  toolName: z.string().min(1),
  inputs: z.record(z.unknown()),
  expectedOutputs: z.union([z.record(z.unknown()), z.string()]),
  riskLevel: z.string().min(1),
  piiFields: z.array(z.string()),
  rollbackPlan: z.string(),
  auditHash: z.string().min(1),
  createdAt: z.string().datetime(),
});

const ApprovalCreateSchema = z.object({
  envelope: ApprovalEnvelopeSchema,
  userId: z.string().uuid(),
  taskId: z.string().uuid().optional(),
  workflowId: z.string().optional(),
  signalName: z.string().optional(),
  expiresAt: z.string().datetime().optional(),
});

const ApprovalDecisionSchema = z.object({
  approved: z.boolean(),
  userId: z.string().uuid(),
  reason: z.string().max(500).optional(),
});

export const internalRoutes: FastifyPluginAsync = async (app) => {
  const pool = getPool();
  const secretsService = new SecretsService();

  app.addHook('onRequest', async (request, reply) => {
    if (!SERVICE_TOKEN) {
      return reply.status(503).send({ error: 'Service token not configured' });
    }
    const token = request.headers['x-service-token'];
    if (!token || token !== SERVICE_TOKEN) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.get(
    '/preferences/notifications',
    {
      schema: {
        description: 'Internal: get notification preferences for a workspace',
        tags: ['internal'],
        querystring: {
          type: 'object',
          required: ['workspaceId'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
          },
        },
        response: {
          200: {
            type: 'object',
            additionalProperties: true,
          },
        },
      },
    },
    async (request) => {
      const { workspaceId, userId } = NotificationPrefsSchema.parse(request.query);

      const result = userId
        ? await pool.query(
            `SELECT preferences FROM homeos.user_preferences
             WHERE workspace_id = $1 AND user_id = $2 AND category = 'notifications'
             LIMIT 1`,
            [workspaceId, userId]
          )
        : await pool.query(
            `SELECT preferences FROM homeos.user_preferences
             WHERE workspace_id = $1 AND category = 'notifications'
             ORDER BY updated_at DESC
             LIMIT 1`,
            [workspaceId]
          );

      const stored = result.rows[0]?.preferences ?? {};
      return { ...DEFAULT_NOTIFICATIONS, ...stored };
    }
  );

  app.post(
    '/notifications',
    {
      schema: {
        description: 'Internal: create a notification record',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'type', 'title', 'body'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
            type: { type: 'string' },
            title: { type: 'string' },
            body: { type: 'string' },
            status: { type: 'string', enum: ['queued', 'delivered', 'read', 'failed'] },
            deliverAt: { type: 'string' },
            metadata: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = CreateNotificationSchema.parse(request.body);

      const result = await pool.query(
        `INSERT INTO homeos.notifications
          (workspace_id, user_id, type, title, body, status, deliver_at, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, status`,
        [
          body.workspaceId,
          body.userId ?? null,
          body.type,
          body.title,
          body.body,
          body.status ?? 'queued',
          body.deliverAt ?? null,
          JSON.stringify(body.metadata ?? {}),
        ]
      );

      return reply.status(201).send({
        id: result.rows[0].id,
        status: result.rows[0].status,
      });
    }
  );

  app.get(
    '/llm-config',
    {
      schema: {
        description: 'Internal: resolve LLM config for a workspace',
        tags: ['internal'],
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
              provider: { type: 'string' },
              apiKey: { type: 'string' },
              model: { type: 'string' },
              baseUrl: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const { workspaceId } = request.query as { workspaceId: string };
      const defaults = {
        provider: (process.env['DEFAULT_LLM_PROVIDER'] ?? 'modal').toLowerCase(),
        model: process.env['DEFAULT_LLM_MODEL'] ?? null,
        endpoint: process.env['MODAL_LLM_URL'] ?? null,
      };

      const result = await pool.query(
        `SELECT preferences
         FROM homeos.user_preferences
         WHERE workspace_id = $1 AND category = 'ai'
         ORDER BY updated_at DESC
         LIMIT 1`,
        [workspaceId]
      );

      const preferences = (result.rows[0]?.preferences ?? {}) as {
        llmProvider?: string;
        llmModel?: string | null;
        llmEndpoint?: string | null;
      };

      const preferred = (preferences.llmProvider ?? defaults.provider ?? 'modal').toLowerCase();
      const candidates = preferred === 'auto'
        ? ['modal', 'anthropic', 'openai']
        : [preferred];

      for (const provider of candidates) {
        if (provider === 'modal') {
          const endpoint = preferences.llmEndpoint ?? defaults.endpoint;
          if (!endpoint) {
            continue;
          }
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'modal')) ??
            process.env['MODAL_LLM_TOKEN'] ??
            '';
          return reply.send({
            provider: 'modal',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'openai-compatible',
            baseUrl: endpoint,
          });
        }

        if (provider === 'anthropic') {
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'anthropic')) ??
            process.env['ANTHROPIC_API_KEY'];
          if (!apiKey) {
            continue;
          }
          return reply.send({
            provider: 'anthropic',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'claude-sonnet-4-20250514',
            baseUrl: null,
          });
        }

        if (provider === 'openai') {
          const apiKey =
            (await secretsService.getDecryptedSecret(workspaceId, 'openai')) ??
            process.env['OPENAI_API_KEY'];
          if (!apiKey) {
            continue;
          }
          return reply.send({
            provider: 'openai',
            apiKey,
            model: preferences.llmModel ?? defaults.model ?? 'gpt-4o',
            baseUrl: null,
          });
        }
      }

      return reply.status(404).send({ error: 'No LLM config available' });
    }
  );

  app.post(
    '/llm-usage',
    {
      schema: {
        description: 'Internal: record LLM usage',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'provider', 'model'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            userId: { type: 'string', format: 'uuid' },
            provider: { type: 'string' },
            model: { type: 'string' },
            inputTokens: { type: 'number' },
            outputTokens: { type: 'number' },
            totalTokens: { type: 'number' },
            estimatedCostUsd: { type: 'number' },
            metadata: { type: 'object', additionalProperties: true },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = request.body as {
        workspaceId: string;
        userId?: string;
        provider: string;
        model: string;
        inputTokens?: number;
        outputTokens?: number;
        totalTokens?: number;
        estimatedCostUsd?: number;
        metadata?: Record<string, unknown>;
      };

      await pool.query(
        `INSERT INTO homeos.llm_usage
          (workspace_id, user_id, provider, model, input_tokens, output_tokens, total_tokens, estimated_cost_usd, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          body.workspaceId,
          body.userId ?? null,
          body.provider,
          body.model,
          body.inputTokens ?? null,
          body.outputTokens ?? null,
          body.totalTokens ?? null,
          body.estimatedCostUsd ?? null,
          JSON.stringify(body.metadata ?? {}),
        ]
      );

      return reply.status(201).send({ success: true });
    }
  );

  app.post(
    '/workflow-runs',
    {
      schema: {
        description: 'Internal: upsert workflow run status',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['workspaceId', 'workflowId', 'workflowType'],
          properties: {
            workspaceId: { type: 'string', format: 'uuid' },
            workflowId: { type: 'string' },
            runId: { type: 'string' },
            workflowType: { type: 'string' },
            triggerType: { type: 'string' },
            triggeredBy: { type: 'string', format: 'uuid' },
            status: { type: 'string' },
            attempts: { type: 'integer' },
            maxAttempts: { type: 'integer' },
            input: { type: 'object', additionalProperties: true },
            result: { type: 'object', additionalProperties: true },
            error: { type: 'string' },
            startedAt: { type: 'string' },
            completedAt: { type: 'string' },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              workflowId: { type: 'string' },
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = WorkflowRunUpsertSchema.parse(request.body);

      const inputPayload = body.input ? JSON.stringify(body.input) : null;
      const resultPayload = body.result ? JSON.stringify(body.result) : null;

      const result = await pool.query(
        `INSERT INTO homeos.workflow_runs
          (workflow_id, run_id, workspace_id, workflow_type, trigger_type, triggered_by, status,
           attempts, max_attempts, input, result, error, started_at, completed_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7,
           $8, $9, $10, $11, $12, $13, $14)
         ON CONFLICT (workflow_id) DO UPDATE SET
           run_id = COALESCE(EXCLUDED.run_id, homeos.workflow_runs.run_id),
           workspace_id = EXCLUDED.workspace_id,
           workflow_type = COALESCE(EXCLUDED.workflow_type, homeos.workflow_runs.workflow_type),
           trigger_type = COALESCE(EXCLUDED.trigger_type, homeos.workflow_runs.trigger_type),
           triggered_by = COALESCE(EXCLUDED.triggered_by, homeos.workflow_runs.triggered_by),
           status = COALESCE(EXCLUDED.status, homeos.workflow_runs.status),
           attempts = COALESCE(EXCLUDED.attempts, homeos.workflow_runs.attempts),
           max_attempts = COALESCE(EXCLUDED.max_attempts, homeos.workflow_runs.max_attempts),
           input = COALESCE(EXCLUDED.input, homeos.workflow_runs.input),
           result = COALESCE(EXCLUDED.result, homeos.workflow_runs.result),
           error = COALESCE(EXCLUDED.error, homeos.workflow_runs.error),
           started_at = COALESCE(EXCLUDED.started_at, homeos.workflow_runs.started_at),
           completed_at = COALESCE(EXCLUDED.completed_at, homeos.workflow_runs.completed_at),
           updated_at = NOW()
         RETURNING workflow_id, status`,
        [
          body.workflowId,
          body.runId ?? null,
          body.workspaceId,
          body.workflowType,
          body.triggerType ?? null,
          body.triggeredBy ?? null,
          body.status ?? 'running',
          body.attempts ?? null,
          body.maxAttempts ?? null,
          inputPayload,
          resultPayload,
          body.error ?? null,
          body.startedAt ?? null,
          body.completedAt ?? null,
        ]
      );

      return reply.status(201).send({
        workflowId: result.rows[0].workflow_id,
        status: result.rows[0].status,
      });
    }
  );

  app.post(
    '/approvals',
    {
      schema: {
        description: 'Internal: create approval envelope',
        tags: ['internal'],
        body: {
          type: 'object',
          required: ['envelope', 'userId'],
          properties: {
            envelope: { type: 'object' },
            userId: { type: 'string', format: 'uuid' },
            taskId: { type: 'string', format: 'uuid' },
            workflowId: { type: 'string' },
            signalName: { type: 'string' },
            expiresAt: { type: 'string' },
          },
        },
        response: {
          201: {
            type: 'object',
            properties: {
              envelopeId: { type: 'string' },
              status: { type: 'string' },
              expiresAt: { type: 'string' },
            },
          },
        },
      },
    },
    async (request, reply) => {
      const body = ApprovalCreateSchema.parse(request.body);
      const envelope = body.envelope;
      const expiresAt =
        body.expiresAt ?? new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

      const result = await pool.query(
        `INSERT INTO homeos.action_envelopes
          (id, workspace_id, task_id, workflow_id, signal_name, intent, tool_name, inputs,
           expected_outputs, risk_level, pii_fields, rollback_plan, audit_hash, status, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8,
           $9, $10, $11, $12, $13, 'pending', $14)
         RETURNING id, status, expires_at`,
        [
          envelope.envelopeId,
          envelope.workspaceId,
          body.taskId ?? null,
          body.workflowId ?? null,
          body.signalName ?? 'approval',
          envelope.intent,
          envelope.toolName,
          JSON.stringify(envelope.inputs),
          JSON.stringify(envelope.expectedOutputs),
          envelope.riskLevel,
          envelope.piiFields,
          envelope.rollbackPlan,
          envelope.auditHash,
          expiresAt,
        ]
      );

      return reply.status(201).send({
        envelopeId: result.rows[0].id,
        status: result.rows[0].status,
        expiresAt: result.rows[0].expires_at,
      });
    }
  );

  app.get(
    '/approvals/pending',
    {
      schema: {
        description: 'Internal: list pending approvals',
        tags: ['internal'],
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
                workflowId: { type: 'string' },
                intent: { type: 'string' },
                toolName: { type: 'string' },
                riskLevel: { type: 'string' },
                requestedAt: { type: 'string' },
                expiresAt: { type: 'string' },
                signalName: { type: 'string' },
              },
            },
          },
        },
      },
    },
    async (request) => {
      const { workspaceId } = request.query as { workspaceId: string };

      const result = await pool.query(
        `SELECT id, task_id, workflow_id, intent, tool_name, risk_level, created_at, expires_at, signal_name
         FROM homeos.action_envelopes
         WHERE workspace_id = $1 AND status = 'pending' AND expires_at > NOW()
         ORDER BY created_at DESC`,
        [workspaceId]
      );

      return result.rows.map((row) => ({
        envelopeId: row.id,
        taskId: row.task_id ?? undefined,
        workflowId: row.workflow_id ?? undefined,
        intent: row.intent,
        toolName: row.tool_name,
        riskLevel: row.risk_level,
        requestedAt: row.created_at,
        expiresAt: row.expires_at,
        signalName: row.signal_name ?? 'approval',
      }));
    }
  );

  app.get(
    '/approvals/:envelopeId',
    {
      schema: {
        description: 'Internal: get approval envelope',
        tags: ['internal'],
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
              taskId: { type: 'string' },
              workflowId: { type: 'string' },
              signalName: { type: 'string' },
              intent: { type: 'string' },
              toolName: { type: 'string' },
              inputs: { type: 'object' },
              expectedOutputs: {},
              riskLevel: { type: 'string' },
              piiFields: { type: 'array', items: { type: 'string' } },
              rollbackPlan: { type: 'string' },
              auditHash: { type: 'string' },
              status: { type: 'string' },
              requestedAt: { type: 'string' },
              expiresAt: { type: 'string' },
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

      const result = await pool.query(
        `SELECT id, workspace_id, task_id, workflow_id, signal_name, intent, tool_name,
                inputs, expected_outputs, risk_level, pii_fields, rollback_plan, audit_hash,
                status, created_at, expires_at
         FROM homeos.action_envelopes
         WHERE id = $1
         LIMIT 1`,
        [envelopeId]
      );

      const row = result.rows[0];
      if (!row) {
        return reply.status(404).send({ error: 'Envelope not found' });
      }

      return {
        envelopeId: row.id,
        workspaceId: row.workspace_id,
        taskId: row.task_id ?? undefined,
        workflowId: row.workflow_id ?? undefined,
        signalName: row.signal_name ?? 'approval',
        intent: row.intent,
        toolName: row.tool_name,
        inputs: row.inputs ?? {},
        expectedOutputs: row.expected_outputs ?? {},
        riskLevel: row.risk_level,
        piiFields: row.pii_fields ?? [],
        rollbackPlan: row.rollback_plan ?? '',
        auditHash: row.audit_hash,
        status: row.status,
        requestedAt: row.created_at,
        expiresAt: row.expires_at,
      };
    }
  );

  app.post(
    '/approvals/:envelopeId/decision',
    {
      schema: {
        description: 'Internal: record approval decision',
        tags: ['internal'],
        params: {
          type: 'object',
          required: ['envelopeId'],
          properties: {
            envelopeId: { type: 'string', format: 'uuid' },
          },
        },
        body: {
          type: 'object',
          required: ['approved', 'userId'],
          properties: {
            approved: { type: 'boolean' },
            userId: { type: 'string', format: 'uuid' },
            reason: { type: 'string' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              status: { type: 'string' },
            },
          },
        },
      },
    },
    async (request) => {
      const { envelopeId } = request.params as { envelopeId: string };
      const body = ApprovalDecisionSchema.parse(request.body);

      const status = body.approved ? 'approved' : 'denied';
      await pool.query(
        `UPDATE homeos.action_envelopes
         SET status = $1,
             approved_by = $2,
             approved_at = CASE WHEN $1 = 'approved' THEN NOW() ELSE NULL END,
             denied_reason = CASE WHEN $1 = 'denied' THEN $3 ELSE NULL END,
             updated_at = NOW()
         WHERE id = $4`,
        [status, body.userId, body.reason ?? null, envelopeId]
      );

      return { status };
    }
  );
};
