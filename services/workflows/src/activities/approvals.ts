import { createActionEnvelope } from '@homeos/shared/crypto';
import type { RiskLevel } from '@homeos/shared';

export interface RequestApprovalInput {
  workspaceId: string;
  userId: string;
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

  // Store envelope in database
  const RUNTIME_URL = process.env['RUNTIME_URL'] ?? 'http://localhost:3002';

  try {
    await fetch(`${RUNTIME_URL}/internal/approvals`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        envelope,
        userId: input.userId,
      }),
    });
  } catch (error) {
    console.error('Failed to store approval envelope:', error);
  }

  return envelope.envelopeId;
}
