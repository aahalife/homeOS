import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  discoverServices,
  evaluateService,
  generateToolWrapper,
  runContractTests,
  applySecurityGates,
  publishTool,
  emitTaskEvent,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '30 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

export interface DynamicIntegrationInput {
  workspaceId: string;
  userId: string;
  capabilityRequest: string;
  originalTaskContext?: Record<string, unknown>;
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  token?: string;
  reason?: string;
}

export const approvalSignal = defineSignal<[ApprovalSignal]>('approval');

export async function DynamicIntegrationWorkflow(input: DynamicIntegrationInput): Promise<{
  success: boolean;
  toolName?: string;
  toolVersion?: string;
}> {
  const { workspaceId, userId, capabilityRequest } = input;
  let pendingApproval: ApprovalSignal | null = null;

  setHandler(approvalSignal, (signal) => {
    pendingApproval = signal;
  });

  // Step 1: Discover candidate services
  await emitTaskEvent(workspaceId, 'integration.phase', { phase: 'discovering' });
  const candidates = await discoverServices({
    workspaceId,
    query: capabilityRequest,
  });

  if (candidates.length === 0) {
    await emitTaskEvent(workspaceId, 'integration.failed', {
      reason: 'No suitable services found',
    });
    return { success: false };
  }

  // Step 2: Evaluate candidates
  await emitTaskEvent(workspaceId, 'integration.phase', { phase: 'evaluating' });
  const evaluations = await Promise.all(
    candidates.map((candidate) =>
      evaluateService({
        workspaceId,
        service: candidate,
      })
    )
  );

  // Pick the best candidate
  const viable = evaluations
    .filter((e) => e.viable)
    .sort((a, b) => b.score - a.score);

  if (viable.length === 0) {
    await emitTaskEvent(workspaceId, 'integration.failed', {
      reason: 'No viable services after evaluation',
    });
    return { success: false };
  }

  const chosen = viable[0]!;

  // Step 3: Generate tool wrapper
  await emitTaskEvent(workspaceId, 'integration.phase', {
    phase: 'generating',
    service: chosen.service.name,
  });

  const toolCode = await generateToolWrapper({
    workspaceId,
    service: chosen.service,
    evaluationDetails: chosen,
  });

  // Step 4: Run contract tests
  await emitTaskEvent(workspaceId, 'integration.phase', { phase: 'testing' });
  const testResults = await runContractTests({
    workspaceId,
    toolCode,
    service: chosen.service,
  });

  if (!testResults.allPassed) {
    await emitTaskEvent(workspaceId, 'integration.failed', {
      reason: 'Contract tests failed',
      failures: testResults.failures,
    });
    return { success: false };
  }

  // Step 5: Apply security gates
  await emitTaskEvent(workspaceId, 'integration.phase', { phase: 'security_review' });
  const securityResult = await applySecurityGates({
    workspaceId,
    toolCode,
    service: chosen.service,
  });

  if (!securityResult.approved) {
    await emitTaskEvent(workspaceId, 'integration.failed', {
      reason: 'Security review failed',
      issues: securityResult.issues,
    });
    return { success: false };
  }

  // Step 6: Request user approval to publish
  const publishEnvelopeId = await requestApproval({
    workspaceId,
    userId,
    intent: `Publish new tool integration: ${chosen.service.name}`,
    toolName: 'integration.publish',
    inputs: {
      serviceName: chosen.service.name,
      capabilities: chosen.service.capabilities,
      endpoints: securityResult.restrictedEndpoints,
    },
    riskLevel: 'medium',
  });

  const publishApproved = await condition(
    () => pendingApproval?.envelopeId === publishEnvelopeId,
    '24 hours'
  );

  const publishApprovalState = pendingApproval as ApprovalSignal | null;
  if (!publishApproved || !publishApprovalState?.approved) {
    return { success: false };
  }

  // Step 7: Publish tool
  await emitTaskEvent(workspaceId, 'integration.phase', { phase: 'publishing' });
  const published = await publishTool({
    workspaceId,
    toolCode: securityResult.securedToolCode,
    metadata: {
      name: chosen.service.name,
      version: '1.0.0',
      source: chosen.service.type,
      capabilities: chosen.service.capabilities,
    },
    rolloutStrategy: 'canary',
  });

  await emitTaskEvent(workspaceId, 'integration.complete', {
    toolName: published.toolName,
    version: published.version,
  });

  return {
    success: true,
    toolName: published.toolName,
    toolVersion: published.version,
  };
}
