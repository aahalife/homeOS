import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import type { ApprovalToken, ApprovalTokenPayload } from '../types/approval.js';
import { canonicalizeJson } from './envelope.js';

const DEFAULT_TTL_SECONDS = 300; // 5 minutes

export function createApprovalToken(
  envelopeId: string,
  workspaceId: string,
  userId: string,
  secret: string,
  ttlSeconds: number = DEFAULT_TTL_SECONDS
): ApprovalToken {
  const payload: ApprovalTokenPayload = {
    envelopeId,
    workspaceId,
    userId,
    ttlSeconds,
    issuedAt: new Date().toISOString(),
  };

  const canonical = canonicalizeJson(payload);
  const signature = createHmac('sha256', secret).update(canonical).digest('hex');

  return {
    ...payload,
    signature,
  };
}

export function verifyApprovalToken(
  token: ApprovalToken,
  secret: string
): { valid: boolean; error?: string } {
  const { signature, ...payload } = token;

  const canonical = canonicalizeJson(payload);
  const expectedSignature = createHmac('sha256', secret).update(canonical).digest('hex');

  const signatureBuffer = Buffer.from(signature, 'hex');
  const expectedBuffer = Buffer.from(expectedSignature, 'hex');

  if (signatureBuffer.length !== expectedBuffer.length) {
    return { valid: false, error: 'Invalid signature format' };
  }

  if (!timingSafeEqual(signatureBuffer, expectedBuffer)) {
    return { valid: false, error: 'Invalid signature' };
  }

  const issuedAt = new Date(token.issuedAt).getTime();
  const now = Date.now();
  const expiresAt = issuedAt + token.ttlSeconds * 1000;

  if (now > expiresAt) {
    return { valid: false, error: 'Token expired' };
  }

  return { valid: true };
}

export function isTokenExpired(token: ApprovalToken): boolean {
  const issuedAt = new Date(token.issuedAt).getTime();
  const now = Date.now();
  const expiresAt = issuedAt + token.ttlSeconds * 1000;
  return now > expiresAt;
}
