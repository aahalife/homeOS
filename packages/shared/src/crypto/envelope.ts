import { createHash, createHmac, randomUUID } from 'node:crypto';
import type { ActionEnvelope, ApprovalToken, ApprovalTokenPayload, CreateEnvelopeInput } from '../types/approval.js';

export function canonicalizeJson(obj: unknown): string {
  if (obj === null || obj === undefined) {
    return 'null';
  }

  if (typeof obj !== 'object') {
    return JSON.stringify(obj);
  }

  if (Array.isArray(obj)) {
    return '[' + obj.map(canonicalizeJson).join(',') + ']';
  }

  const sortedKeys = Object.keys(obj as Record<string, unknown>).sort();
  const pairs = sortedKeys.map((key) => {
    const value = (obj as Record<string, unknown>)[key];
    return JSON.stringify(key) + ':' + canonicalizeJson(value);
  });

  return '{' + pairs.join(',') + '}';
}

export function computeEnvelopeHash(envelope: Omit<ActionEnvelope, 'auditHash' | 'envelopeId' | 'createdAt'>): string {
  const canonical = canonicalizeJson({
    workspaceId: envelope.workspaceId,
    intent: envelope.intent,
    toolName: envelope.toolName,
    inputs: envelope.inputs,
    expectedOutputs: envelope.expectedOutputs,
    riskLevel: envelope.riskLevel,
    piiFields: envelope.piiFields,
    rollbackPlan: envelope.rollbackPlan,
  });

  return createHash('sha256').update(canonical).digest('hex');
}

export function createActionEnvelope(input: CreateEnvelopeInput): ActionEnvelope {
  const envelopeId = randomUUID();
  const createdAt = new Date().toISOString();

  const partialEnvelope = {
    workspaceId: input.workspaceId,
    intent: input.intent,
    toolName: input.toolName,
    inputs: input.inputs,
    expectedOutputs: input.expectedOutputs,
    riskLevel: input.riskLevel,
    piiFields: input.piiFields ?? [],
    rollbackPlan: input.rollbackPlan ?? '',
  };

  const auditHash = computeEnvelopeHash(partialEnvelope);

  return {
    ...partialEnvelope,
    envelopeId,
    auditHash,
    createdAt,
  };
}

export function verifyEnvelopeHash(envelope: ActionEnvelope): boolean {
  const computed = computeEnvelopeHash(envelope);
  return computed === envelope.auditHash;
}
