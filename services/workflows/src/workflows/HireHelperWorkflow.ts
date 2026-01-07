import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  searchHelpers,
  rankCandidates,
  requestQuote,
  bookHelper,
  coordinateHelper,
  emitTaskEvent,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

export interface HireHelperInput {
  workspaceId: string;
  userId: string;
  taskType: string;
  description: string;
  location: string;
  preferredDate: string;
  budget?: { min: number; max: number };
  requirements: string[];
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  token?: string;
  reason?: string;
}

export interface CandidateSelectionSignal {
  selectedCandidateIds: string[];
}

export const approvalSignal = defineSignal<[ApprovalSignal]>('approval');
export const candidateSelectionSignal = defineSignal<[CandidateSelectionSignal]>('candidateSelection');

export async function HireHelperWorkflow(input: HireHelperInput): Promise<{
  success: boolean;
  booking?: {
    helperId: string;
    helperName: string;
    scheduledDate: string;
    price: number;
  };
}> {
  const { workspaceId, userId } = input;
  let pendingApproval: ApprovalSignal | null = null;
  let selectedCandidates: CandidateSelectionSignal | null = null;

  setHandler(approvalSignal, (signal) => {
    pendingApproval = signal;
  });

  setHandler(candidateSelectionSignal, (signal) => {
    selectedCandidates = signal;
  });

  // Step 1: Search for helpers
  await emitTaskEvent(workspaceId, 'helpers.phase', { phase: 'searching' });
  const helpers = await searchHelpers({
    workspaceId,
    taskType: input.taskType,
    location: input.location,
    dateRange: { start: input.preferredDate, end: input.preferredDate },
    requirements: input.requirements,
  });

  if (helpers.length === 0) {
    return { success: false };
  }

  // Step 2: Rank candidates
  await emitTaskEvent(workspaceId, 'helpers.phase', { phase: 'ranking' });
  const ranked = await rankCandidates({
    workspaceId,
    candidates: helpers,
    requirements: input.requirements,
    budget: input.budget,
  });

  // Step 3: Present top candidates and wait for selection
  await emitTaskEvent(workspaceId, 'helpers.candidates', {
    candidates: ranked.slice(0, 5),
  });

  const selected = await condition(
    () => selectedCandidates !== null,
    '2 hours'
  );

  const currentSelection = selectedCandidates as CandidateSelectionSignal | null;
  if (!selected || !currentSelection || currentSelection.selectedCandidateIds.length === 0) {
    return { success: false };
  }

  // Step 4: Request quotes from selected candidates
  await emitTaskEvent(workspaceId, 'helpers.phase', { phase: 'requesting_quotes' });

  const quotes = await Promise.all(
    currentSelection.selectedCandidateIds.map((id: string) =>
      requestQuote({
        workspaceId,
        helperId: id,
        taskDescription: input.description,
        date: input.preferredDate,
      })
    )
  );

  // Step 5: Request approval to book (HIGH risk - spending money)
  const bestQuote = quotes.sort((a: { price: number }, b: { price: number }) => a.price - b.price)[0];

  if (!bestQuote) {
    return { success: false };
  }

  await emitTaskEvent(workspaceId, 'helpers.quote', { quote: bestQuote });

  const bookEnvelopeId = await requestApproval({
    workspaceId,
    userId,
    intent: `Book ${bestQuote.helperName} for $${bestQuote.price}`,
    toolName: 'helpers.book',
    inputs: bestQuote as unknown as Record<string, unknown>,
    riskLevel: 'high',
  });

  const bookApproved = await condition(
    () => pendingApproval?.envelopeId === bookEnvelopeId,
    '24 hours'
  );

  const bookApprovalState = pendingApproval as ApprovalSignal | null;
  if (!bookApproved || !bookApprovalState?.approved) {
    return { success: false };
  }

  // Step 6: Book the helper
  await emitTaskEvent(workspaceId, 'helpers.phase', { phase: 'booking' });

  const booking = await bookHelper({
    workspaceId,
    helperId: bestQuote.helperId,
    quoteId: bestQuote.quoteId,
    idempotencyKey: `booking-${workspaceId}-${bestQuote.quoteId}`,
  });

  // Step 7: Coordinate (send messages, reminders)
  await emitTaskEvent(workspaceId, 'helpers.phase', { phase: 'coordinating' });

  await coordinateHelper({
    workspaceId,
    userId,
    booking,
    location: input.location,
    date: input.preferredDate,
  });

  await emitTaskEvent(workspaceId, 'helpers.complete', { booking });

  return {
    success: true,
    booking: {
      helperId: booking.helperId,
      helperName: bestQuote.helperName,
      scheduledDate: input.preferredDate,
      price: bestQuote.price,
    },
  };
}
