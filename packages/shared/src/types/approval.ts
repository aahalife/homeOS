import type { RiskLevel } from './task.js';

export interface ActionEnvelope {
  envelopeId: string;
  workspaceId: string;
  intent: string;
  toolName: string;
  inputs: Record<string, unknown>;
  expectedOutputs: Record<string, unknown> | string;
  riskLevel: RiskLevel;
  piiFields: string[];
  rollbackPlan: string;
  auditHash: string;
  createdAt: string;
}

export interface ApprovalTokenPayload {
  envelopeId: string;
  workspaceId: string;
  userId: string;
  ttlSeconds: number;
  issuedAt: string;
}

export interface ApprovalToken extends ApprovalTokenPayload {
  signature: string;
}

export interface ApprovalRequest {
  envelopeId: string;
  taskId: string;
  envelope: ActionEnvelope;
  requestedAt: string;
  expiresAt: string;
}

export interface ApprovalResponse {
  envelopeId: string;
  approved: boolean;
  token?: ApprovalToken;
  denialReason?: string;
  respondedAt: string;
  respondedBy: string;
}

export interface CreateEnvelopeInput {
  workspaceId: string;
  intent: string;
  toolName: string;
  inputs: Record<string, unknown>;
  expectedOutputs: Record<string, unknown> | string;
  riskLevel: RiskLevel;
  piiFields?: string[];
  rollbackPlan?: string;
}
