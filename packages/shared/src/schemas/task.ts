import { z } from 'zod';

export const TaskCategorySchema = z.enum([
  'chat',
  'planning',
  'telephony',
  'marketplace',
  'helpers',
  'calendar',
  'groceries',
  'integration',
  'other',
]);

export const TaskStatusSchema = z.enum([
  'queued',
  'running',
  'needs_approval',
  'blocked',
  'done',
  'failed',
]);

export const RiskLevelSchema = z.enum(['low', 'medium', 'high']);

export const ApprovalStateSchema = z.enum([
  'none',
  'pending',
  'approved',
  'denied',
  'expired',
]);

export const TaskEventSchema = z.object({
  eventId: z.string().uuid(),
  timestamp: z.string().datetime(),
  type: z.string(),
  payload: z.record(z.unknown()),
});

export const TaskSchema = z.object({
  taskId: z.string().uuid(),
  workspaceId: z.string().uuid(),
  title: z.string().min(1).max(500),
  category: TaskCategorySchema,
  status: TaskStatusSchema,
  riskLevel: RiskLevelSchema,
  requiresApproval: z.boolean(),
  approvalState: ApprovalStateSchema,
  summaryForUser: z.string().max(2000),
  details: z.record(z.unknown()),
  auditTrail: z.array(TaskEventSchema),
  linkedWorkflowId: z.string(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const CreateTaskInputSchema = z.object({
  workspaceId: z.string().uuid(),
  title: z.string().min(1).max(500),
  category: TaskCategorySchema,
  riskLevel: RiskLevelSchema,
  requiresApproval: z.boolean(),
  summaryForUser: z.string().max(2000),
  details: z.record(z.unknown()).optional(),
  linkedWorkflowId: z.string().optional(),
});

export const UpdateTaskInputSchema = z.object({
  status: TaskStatusSchema.optional(),
  approvalState: ApprovalStateSchema.optional(),
  summaryForUser: z.string().max(2000).optional(),
  details: z.record(z.unknown()).optional(),
});
