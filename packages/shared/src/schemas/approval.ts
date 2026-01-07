import { z } from 'zod';
import { RiskLevelSchema } from './task.js';

export const ActionEnvelopeSchema = z.object({
  envelopeId: z.string().uuid(),
  workspaceId: z.string().uuid(),
  intent: z.string().min(1).max(1000),
  toolName: z.string().min(1).max(100),
  inputs: z.record(z.unknown()),
  expectedOutputs: z.union([z.record(z.unknown()), z.string()]),
  riskLevel: RiskLevelSchema,
  piiFields: z.array(z.string()),
  rollbackPlan: z.string().max(2000),
  auditHash: z.string(),
  createdAt: z.string().datetime(),
});

export const ApprovalTokenPayloadSchema = z.object({
  envelopeId: z.string().uuid(),
  workspaceId: z.string().uuid(),
  userId: z.string().uuid(),
  ttlSeconds: z.number().int().positive().max(3600),
  issuedAt: z.string().datetime(),
});

export const ApprovalTokenSchema = ApprovalTokenPayloadSchema.extend({
  signature: z.string(),
});

export const CreateEnvelopeInputSchema = z.object({
  workspaceId: z.string().uuid(),
  intent: z.string().min(1).max(1000),
  toolName: z.string().min(1).max(100),
  inputs: z.record(z.unknown()),
  expectedOutputs: z.union([z.record(z.unknown()), z.string()]),
  riskLevel: RiskLevelSchema,
  piiFields: z.array(z.string()).optional().default([]),
  rollbackPlan: z.string().max(2000).optional().default(''),
});

export const ApprovalRequestSchema = z.object({
  envelopeId: z.string().uuid(),
  taskId: z.string().uuid(),
  envelope: ActionEnvelopeSchema,
  requestedAt: z.string().datetime(),
  expiresAt: z.string().datetime(),
});

export const ApprovalResponseSchema = z.object({
  envelopeId: z.string().uuid(),
  approved: z.boolean(),
  token: ApprovalTokenSchema.optional(),
  denialReason: z.string().max(500).optional(),
  respondedAt: z.string().datetime(),
  respondedBy: z.string().uuid(),
});
