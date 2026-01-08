export type MessageRole = 'user' | 'assistant' | 'system' | 'tool';

export interface ChatMessage {
  id: string;
  sessionId: string;
  role: MessageRole;
  content: string;
  toolCalls?: ToolCall[];
  toolResults?: ToolResult[];
  createdAt: string;
}

export interface ToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
}

export interface ToolResult {
  toolCallId: string;
  name: string;
  result: unknown;
  error?: string;
}

export interface ChatSession {
  id: string;
  workspaceId: string;
  userId: string;
  title?: string;
  createdAt: string;
  updatedAt: string;
}

export interface ChatTurnInput {
  sessionId?: string;
  workspaceId: string;
  userId: string;
  message: string;
}

export interface ChatTurnResponse {
  sessionId: string;
  taskId: string;
  workflowId: string;
}

export interface StreamEvent {
  type:
    | 'chat.message.delta'
    | 'chat.message.final'
    | 'task.created'
    | 'task.updated'
    | 'task.approved'
    | 'task.denied'
    | 'approval.requested'
    | 'approval.resolved';
  payload: Record<string, unknown>;
}
