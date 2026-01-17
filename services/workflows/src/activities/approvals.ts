import { createActionEnvelope } from '@homeos/shared/crypto';
import type { RiskLevel } from '@homeos/shared';

export interface RequestApprovalInput {
  workspaceId: string;
  userId: string;
  workflowId?: string;
  signalName?: string;
  taskId?: string;
  intent: string;
  toolName: string;
  inputs: Record<string, unknown>;
  riskLevel: RiskLevel;
  piiFields?: string[];
}

export async function requestApproval(input: RequestApprovalInput): Promise<string> {
  const envelope = createActionEnvelope({
    workspaceId: input.workspaceId,
    intent: input.intent,
    toolName: input.toolName,
    inputs: input.inputs,
    expectedOutputs: {},
    riskLevel: input.riskLevel,
    piiFields: input.piiFields,
  });

  // Store envelope in control-plane
  const CONTROL_PLANE_URL = process.env['CONTROL_PLANE_URL'];
  const SERVICE_TOKEN = process.env['CONTROL_PLANE_SERVICE_TOKEN'];

  try {
    if (!CONTROL_PLANE_URL || !SERVICE_TOKEN) {
      throw new Error('CONTROL_PLANE_URL or CONTROL_PLANE_SERVICE_TOKEN not configured');
    }

    await fetch(`${CONTROL_PLANE_URL}/v1/internal/approvals`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-service-token': SERVICE_TOKEN,
      },
      body: JSON.stringify({
        envelope,
        userId: input.userId,
        taskId: input.taskId,
        workflowId: input.workflowId,
        signalName: input.signalName ?? 'approval',
      }),
    });
  } catch (error) {
    console.error('Failed to store approval envelope:', error);
  }

  return envelope.envelopeId;
}
