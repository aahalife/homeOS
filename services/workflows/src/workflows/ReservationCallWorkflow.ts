import {
  proxyActivities,
  defineSignal,
  setHandler,
  condition,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  searchCandidates,
  placeCall,
  handleCallOutcome,
  createCalendarEvent,
  emitTaskEvent,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

export interface ReservationInput {
  workspaceId: string;
  userId: string;
  restaurantType: string;
  dateTime: string;
  partySize: number;
  specialRequests: string[];
  location: string;
  negotiationBounds: {
    timeFlexibility: string;
    priceRange?: { min: number; max: number };
  };
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  token?: string;
  reason?: string;
}

export interface CandidateSelectionSignal {
  selectedCandidateId: string;
}

export const approvalSignal = defineSignal<[ApprovalSignal]>('approval');
export const candidateSelectionSignal = defineSignal<[CandidateSelectionSignal]>('candidateSelection');

export async function ReservationCallWorkflow(input: ReservationInput): Promise<{
  success: boolean;
  reservation?: {
    restaurantName: string;
    dateTime: string;
    confirmationNumber?: string;
  };
  transcript?: string;
}> {
  const { workspaceId, userId } = input;
  let pendingApproval: ApprovalSignal | null = null;
  let selectedCandidate: CandidateSelectionSignal | null = null;

  setHandler(approvalSignal, (signal) => {
    pendingApproval = signal;
  });

  setHandler(candidateSelectionSignal, (signal) => {
    selectedCandidate = signal;
  });

  // Step 1: Search for candidates
  await emitTaskEvent(workspaceId, 'reservation.phase', { phase: 'searching' });
  const candidates = await searchCandidates({
    workspaceId,
    type: 'restaurant',
    query: input.restaurantType,
    location: input.location,
    dateTime: input.dateTime,
  });

  if (candidates.length === 0) {
    return {
      success: false,
    };
  }

  // Step 2: Ask user to select candidate
  await emitTaskEvent(workspaceId, 'reservation.candidates', {
    candidates: candidates.slice(0, 3),
  });

  // Wait for candidate selection
  const candidateSelected = await condition(
    () => selectedCandidate !== null,
    '1 hour'
  );

  const currentSelection = selectedCandidate as CandidateSelectionSignal | null;
  if (!candidateSelected || !currentSelection) {
    return { success: false };
  }

  const chosen = candidates.find((c) => c.id === currentSelection.selectedCandidateId);
  if (!chosen) {
    return { success: false };
  }

  // Step 3: Request approval for the call (HIGH risk)
  await emitTaskEvent(workspaceId, 'reservation.phase', { phase: 'awaiting_approval' });

  const envelopeId = await requestApproval({
    workspaceId,
    userId,
    intent: `Call ${chosen.name} to make a reservation`,
    toolName: 'telephony.place_call',
    inputs: {
      phoneNumber: chosen.phoneNumber,
      restaurantName: chosen.name,
      dateTime: input.dateTime,
      partySize: input.partySize,
      specialRequests: input.specialRequests,
      negotiationBounds: input.negotiationBounds,
    },
    riskLevel: 'high',
  });

  const approved = await condition(
    () => pendingApproval?.envelopeId === envelopeId,
    '24 hours'
  );

  const approvalState = pendingApproval as ApprovalSignal | null;
  if (!approved || !approvalState?.approved) {
    return { success: false };
  }

  // Step 4: Place the call
  await emitTaskEvent(workspaceId, 'reservation.phase', { phase: 'calling' });

  const callResult = await placeCall({
    workspaceId,
    phoneNumber: chosen.phoneNumber,
    purpose: 'restaurant_reservation',
    script: {
      greeting: `Hi, I'm calling to make a reservation for ${input.partySize} people.`,
      request: `I'd like to book for ${input.dateTime}.`,
      specialRequests: input.specialRequests,
      negotiationBounds: input.negotiationBounds,
    },
    idempotencyKey: `reservation-${workspaceId}-${Date.now()}`,
  });

  // Step 5: Handle outcome
  await emitTaskEvent(workspaceId, 'reservation.phase', { phase: 'processing_outcome' });

  const outcome = await handleCallOutcome({
    workspaceId,
    callResult,
  });

  if (!outcome.success) {
    // Could retry with next candidate
    return {
      success: false,
      transcript: callResult.transcript,
    };
  }

  // Step 6: Create calendar event
  await emitTaskEvent(workspaceId, 'reservation.phase', { phase: 'creating_calendar' });

  await createCalendarEvent({
    workspaceId,
    userId,
    title: `Reservation at ${chosen.name}`,
    dateTime: outcome.confirmedDateTime ?? input.dateTime,
    location: chosen.address,
    notes: `Party of ${input.partySize}. Confirmation: ${outcome.confirmationNumber ?? 'N/A'}`,
  });

  await emitTaskEvent(workspaceId, 'reservation.complete', {
    success: true,
    restaurant: chosen.name,
  });

  return {
    success: true,
    reservation: {
      restaurantName: chosen.name,
      dateTime: outcome.confirmedDateTime ?? input.dateTime,
      confirmationNumber: outcome.confirmationNumber,
    },
    transcript: callResult.transcript,
  };
}
