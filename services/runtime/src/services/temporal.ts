import crypto from 'node:crypto';
import { Connection, Client, WorkflowFailedError } from '@temporalio/client';
import { upsertWorkflowRun } from './controlPlane.js';

const TEMPORAL_ADDRESS = process.env['TEMPORAL_ADDRESS'] ?? 'localhost:7233';
const TEMPORAL_NAMESPACE = process.env['TEMPORAL_NAMESPACE'] ?? 'default';
const TEMPORAL_API_KEY = process.env['TEMPORAL_API_KEY'];
const DEFAULT_TASK_QUEUE = process.env['TASK_QUEUE'] ?? 'homeos-workflows';

let temporalClient: Client | null = null;

export async function getTemporalClient(): Promise<Client> {
  if (!temporalClient) {
    const isTemporalCloud = TEMPORAL_ADDRESS.includes('temporal.io');
    const connectionOptions: Parameters<typeof Connection.connect>[0] = {
      address: TEMPORAL_ADDRESS,
    };
    if (isTemporalCloud && TEMPORAL_API_KEY) {
      connectionOptions.tls = true;
      connectionOptions.apiKey = TEMPORAL_API_KEY;
    }
    const connection = await Connection.connect(connectionOptions);
    temporalClient = new Client({ connection, namespace: TEMPORAL_NAMESPACE });
  }
  return temporalClient;
}

export interface StartWorkflowRunInput {
  workspaceId: string;
  userId?: string;
  workflowType: string;
  input: Record<string, unknown>;
  triggerType?: string;
  workflowId?: string;
  taskQueue?: string;
  maxAttempts?: number;
}

function normalizeResult(value: unknown): Record<string, unknown> | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (Array.isArray(value)) {
    return { items: value };
  }
  if (typeof value === 'object') {
    return value as Record<string, unknown>;
  }
  return { value };
}

function stringifyError(error: unknown): string {
  if (error instanceof Error) {
    return `${error.name}: ${error.message}`;
  }
  return String(error);
}

function extractRunId(handle: unknown, description: unknown): string | null {
  const desc = description as {
    executionInfo?: { execution?: { runId?: string } };
    workflowExecutionInfo?: { execution?: { runId?: string } };
  };
  const runId =
    desc?.executionInfo?.execution?.runId ??
    desc?.workflowExecutionInfo?.execution?.runId ??
    (handle as { runId?: string }).runId ??
    (handle as { firstExecutionRunId?: string }).firstExecutionRunId ??
    null;
  return runId;
}

export async function startWorkflowRun(input: StartWorkflowRunInput): Promise<{
  workflowId: string;
  runId?: string | null;
}> {
  const client = await getTemporalClient();
  const workflowId =
    input.workflowId ?? `${input.workflowType}-${input.workspaceId}-${crypto.randomUUID()}`;
  const maxAttempts = input.maxAttempts ?? 3;

  const handle = await client.workflow.start(input.workflowType, {
    taskQueue: input.taskQueue ?? DEFAULT_TASK_QUEUE,
    workflowId,
    args: [input.input],
    retry: { maximumAttempts: maxAttempts },
  });

  let runId: string | null = null;
  try {
    const description = await handle.describe();
    runId = extractRunId(handle, description);
  } catch {
    runId = extractRunId(handle, null);
  }

  await upsertWorkflowRun({
    workspaceId: input.workspaceId,
    workflowId,
    runId,
    workflowType: input.workflowType,
    triggerType: input.triggerType ?? 'manual',
    triggeredBy: input.userId ?? null,
    status: 'running',
    attempts: 1,
    maxAttempts,
    input: input.input,
    startedAt: new Date().toISOString(),
  });

  void handle
    .result()
    .then((result) =>
      upsertWorkflowRun({
        workspaceId: input.workspaceId,
        workflowId,
        runId,
        workflowType: input.workflowType,
        triggerType: input.triggerType ?? 'manual',
        triggeredBy: input.userId ?? null,
        status: 'succeeded',
        result: normalizeResult(result),
        completedAt: new Date().toISOString(),
      })
    )
    .catch((error: unknown) => {
      const status =
        error instanceof WorkflowFailedError && error.cause ? 'failed' : 'failed';
      void upsertWorkflowRun({
        workspaceId: input.workspaceId,
        workflowId,
        runId,
        workflowType: input.workflowType,
        triggerType: input.triggerType ?? 'manual',
        triggeredBy: input.userId ?? null,
        status,
        error: stringifyError(error),
        completedAt: new Date().toISOString(),
      });
    });

  return { workflowId, runId };
}
