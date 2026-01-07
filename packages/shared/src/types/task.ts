export type TaskCategory =
  | 'chat'
  | 'planning'
  | 'telephony'
  | 'marketplace'
  | 'helpers'
  | 'calendar'
  | 'groceries'
  | 'integration'
  | 'other';

export type TaskStatus =
  | 'queued'
  | 'running'
  | 'needs_approval'
  | 'blocked'
  | 'done'
  | 'failed';

export type RiskLevel = 'low' | 'medium' | 'high';

export type ApprovalState = 'none' | 'pending' | 'approved' | 'denied' | 'expired';

export interface TaskEvent {
  eventId: string;
  timestamp: string;
  type: string;
  payload: Record<string, unknown>;
}

export interface TaskDetails {
  [key: string]: unknown;
}

export interface Task {
  taskId: string;
  workspaceId: string;
  title: string;
  category: TaskCategory;
  status: TaskStatus;
  riskLevel: RiskLevel;
  requiresApproval: boolean;
  approvalState: ApprovalState;
  summaryForUser: string;
  details: TaskDetails;
  auditTrail: TaskEvent[];
  linkedWorkflowId: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateTaskInput {
  workspaceId: string;
  title: string;
  category: TaskCategory;
  riskLevel: RiskLevel;
  requiresApproval: boolean;
  summaryForUser: string;
  details?: TaskDetails;
  linkedWorkflowId?: string;
}

export interface UpdateTaskInput {
  status?: TaskStatus;
  approvalState?: ApprovalState;
  summaryForUser?: string;
  details?: TaskDetails;
}
