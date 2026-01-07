import { z } from 'zod';

export const MessageRoleSchema = z.enum(['user', 'assistant', 'system', 'tool']);

export const ToolCallSchema = z.object({
  id: z.string(),
  name: z.string().min(1).max(100),
  arguments: z.record(z.unknown()),
});

export const ToolResultSchema = z.object({
  toolCallId: z.string(),
  name: z.string(),
  result: z.unknown(),
  error: z.string().optional(),
});

export const ChatMessageSchema = z.object({
  id: z.string().uuid(),
  sessionId: z.string().uuid(),
  role: MessageRoleSchema,
  content: z.string(),
  toolCalls: z.array(ToolCallSchema).optional(),
  toolResults: z.array(ToolResultSchema).optional(),
  createdAt: z.string().datetime(),
});

export const ChatTurnInputSchema = z.object({
  sessionId: z.string().uuid().optional(),
  workspaceId: z.string().uuid(),
  userId: z.string().uuid(),
  message: z.string().min(1).max(32000),
});

export const ChatTurnResponseSchema = z.object({
  sessionId: z.string().uuid(),
  taskId: z.string().uuid(),
  workflowId: z.string(),
});

export const StreamEventTypeSchema = z.enum([
  'chat.message.delta',
  'chat.message.final',
  'task.created',
  'task.updated',
  'approval.requested',
  'approval.resolved',
]);

export const StreamEventSchema = z.object({
  type: StreamEventTypeSchema,
  payload: z.record(z.unknown()),
});
