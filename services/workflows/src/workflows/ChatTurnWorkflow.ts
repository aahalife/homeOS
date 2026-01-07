import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  understand,
  recall,
  plan,
  executeToolCall,
  reflect,
  writeback,
  emitTaskEvent,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

export interface ChatTurnInput {
  sessionId?: string;
  workspaceId: string;
  userId: string;
  message: string;
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  token?: string;
  reason?: string;
}

export const approvalSignal = defineSignal<[ApprovalSignal]>('approval');

export async function ChatTurnWorkflow(input: ChatTurnInput): Promise<{
  response: string;
  actions: string[];
}> {
  const { workspaceId, userId, message, sessionId } = input;
  let pendingApproval: ApprovalSignal | null = null;

  // Set up approval signal handler
  setHandler(approvalSignal, (signal) => {
    pendingApproval = signal;
  });

  // Phase 1: Understand
  await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'understand' });
  const understanding = await understand({
    workspaceId,
    userId,
    message,
    sessionId,
  });

  // Phase 2: Recall (memory lookup)
  await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'recall' });
  const memories = await recall({
    workspaceId,
    query: message,
    context: understanding,
  });

  // Phase 3: Plan
  await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'plan' });
  const plan_result = await plan({
    workspaceId,
    userId,
    understanding,
    memories,
  });

  const executedActions: string[] = [];

  // Phase 4: Execute plan (with approval gates)
  for (const step of plan_result.steps) {
    if (step.requiresApproval) {
      // Request approval and wait
      await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'awaiting_approval' });

      const envelopeId = await requestApproval({
        workspaceId,
        userId,
        intent: step.intent,
        toolName: step.toolName,
        inputs: step.inputs,
        riskLevel: step.riskLevel,
      });

      // Wait for approval signal (with timeout)
      const approved = await condition(
        () => pendingApproval?.envelopeId === envelopeId,
        '24 hours' // Max wait time for approval
      );

      // Cast to capture the signal value (TypeScript can't track signal updates)
      const currentApproval = pendingApproval as ApprovalSignal | null;
      if (!approved || !currentApproval?.approved) {
        executedActions.push(`Skipped: ${step.intent} (${currentApproval?.reason ?? 'denied or timed out'})`);
        continue;
      }
    }

    // Execute the tool
    await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'executing', step: step.intent });

    try {
      const result = await executeToolCall({
        workspaceId,
        toolName: step.toolName,
        inputs: step.inputs,
        idempotencyKey: `${workspaceId}-${Date.now()}-${step.toolName}`,
      });

      executedActions.push(`Completed: ${step.intent}`);

      // Phase 5: Reflect on result
      await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'reflect' });
      await reflect({
        workspaceId,
        step,
        result,
      });
    } catch (error) {
      executedActions.push(`Failed: ${step.intent} - ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Phase 6: Writeback (update memory, generate response)
  await emitTaskEvent(workspaceId, 'chat.phase', { phase: 'writeback' });
  const response = await writeback({
    workspaceId,
    userId,
    sessionId,
    understanding,
    executedActions,
  });

  await emitTaskEvent(workspaceId, 'chat.complete', { response });

  return {
    response: response.content,
    actions: executedActions,
  };
}
