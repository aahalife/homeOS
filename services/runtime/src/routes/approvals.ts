import type { FastifyPluginAsync } from 'fastify';
import { createApprovalToken } from '@homeos/shared/crypto';
import {
  getApprovalEnvelope,
  listPendingApprovals,
  recordApprovalDecision,
} from '../services/controlPlane.js';
import { getTemporalClient } from '../services/temporal.js';

const APPROVAL_TOKEN_SECRET =
  process.env['APPROVAL_TOKEN_SECRET'] ??
  process.env['JWT_SECRET'] ??
  'dev-approval-secret-change-in-production';

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
      const user = request.user as { workspaceId?: string };
      if (user.workspaceId && user.workspaceId !== workspaceId) {
        return [];
      }

      return (await listPendingApprovals(workspaceId)) ?? [];
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
      const user = request.user as { workspaceId?: string };
      const envelope = await getApprovalEnvelope(envelopeId);
      if (!envelope) {
        return reply.status(404).send({ error: 'Envelope not found' });
      }
      if (user.workspaceId && user.workspaceId !== envelope.workspaceId) {
        return reply.status(403).send({ error: 'Forbidden' });
      }

      return {
        envelopeId: envelope.envelopeId,
        workspaceId: envelope.workspaceId,
        intent: envelope.intent,
        toolName: envelope.toolName,
        inputs: envelope.inputs,
        expectedOutputs: envelope.expectedOutputs,
        riskLevel: envelope.riskLevel,
        piiFields: envelope.piiFields,
        rollbackPlan: envelope.rollbackPlan,
        auditHash: envelope.auditHash,
        createdAt: envelope.requestedAt,
      };
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
      const user = request.user as { workspaceId?: string };
      const envelope = await getApprovalEnvelope(envelopeId);
      if (!envelope) {
        return reply.status(404).send({ error: 'Envelope not found' });
      }
      if (user.workspaceId && user.workspaceId !== envelope.workspaceId) {
        return reply.status(403).send({ error: 'Forbidden' });
      }

      const token = createApprovalToken(
        envelope.envelopeId,
        envelope.workspaceId,
        userId,
        APPROVAL_TOKEN_SECRET
      );

      await recordApprovalDecision({
        envelopeId,
        approved: true,
        userId,
      });

      if (envelope.workflowId) {
        try {
          const client = await getTemporalClient();
          const handle = client.workflow.getHandle(envelope.workflowId);
          await handle.signal(envelope.signalName ?? 'approval', {
            envelopeId: envelope.envelopeId,
            approved: true,
            token,
          });
        } catch (error) {
          app.log.error(error, 'Failed to signal workflow approval');
        }
      }

      return {
        success: true,
        token,
      };
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
      const user = request.user as { workspaceId?: string };
      const envelope = await getApprovalEnvelope(envelopeId);
      if (!envelope) {
        return reply.status(404).send({ error: 'Envelope not found' });
      }
      if (user.workspaceId && user.workspaceId !== envelope.workspaceId) {
        return reply.status(403).send({ error: 'Forbidden' });
      }

      await recordApprovalDecision({
        envelopeId,
        approved: false,
        userId,
        reason,
      });

      if (envelope.workflowId) {
        try {
          const client = await getTemporalClient();
          const handle = client.workflow.getHandle(envelope.workflowId);
          await handle.signal(envelope.signalName ?? 'approval', {
            envelopeId: envelope.envelopeId,
            approved: false,
            reason: reason || 'Denied by user',
          });
        } catch (error) {
          app.log.error(error, 'Failed to signal workflow denial');
        }
      }

      return {
        success: true,
      };
    }
  );
};
