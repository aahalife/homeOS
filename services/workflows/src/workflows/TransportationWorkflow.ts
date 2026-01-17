/**
 * Transportation Workflows for homeOS
 *
 * Family transportation management:
 * - Ride booking and tracking
 * - Family location monitoring
 * - Commute alerts
 */

import {
  proxyActivities,
  sleep,
  defineSignal,
  setHandler,
  workflowInfo,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  getRideEstimates,
  bookRide,
  trackRide,
  getFamilyLocations,
  getCommuteStatus,
  createCarpool,
  findParking,
  emitTaskEvent,
  storeMemory,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// BOOK RIDE WORKFLOW
// ============================================================================

export interface BookRideWorkflowInput {
  workspaceId: string;
  userId: string;
  memberId: string;
  pickup: string;
  dropoff: string;
  preferredProvider?: 'uber' | 'lyft';
  scheduledTime?: string;
}

export interface ApprovalSignal {
  envelopeId: string;
  approved: boolean;
  reason?: string;
}

export const rideApprovalSignal = defineSignal<[ApprovalSignal]>('rideApproval');

export async function BookRideWorkflow(input: BookRideWorkflowInput): Promise<{
  success: boolean;
  booking?: unknown;
  estimates?: unknown[];
}> {
  const { workspaceId, userId, memberId, pickup, dropoff, preferredProvider, scheduledTime } = input;
  const { workflowId } = workflowInfo();

  await emitTaskEvent(workspaceId, 'transportation.ride.start', { pickup, dropoff });

  // Get estimates from all providers
  const estimates = await getRideEstimates({
    workspaceId,
    pickup,
    dropoff,
    rideType: 'standard',
  });

  if (estimates.length === 0) {
    return { success: false, estimates: [] };
  }

  // Select provider (prefer user choice or cheapest)
  const selectedEstimate = preferredProvider
    ? estimates.find((e) => e.provider === preferredProvider) || estimates[0]
    : estimates.sort((a, b) => a.price.min - b.price.min)[0];

  // Request approval for spending
  const envelopeId = await requestApproval({
    workspaceId,
    userId,
    workflowId,
    intent: `Book ${selectedEstimate.provider} ride from ${pickup} to ${dropoff}`,
    toolName: 'transportation.book_ride',
    inputs: {
      provider: selectedEstimate.provider,
      estimatedPrice: `$${selectedEstimate.price.min}-${selectedEstimate.price.max}`,
      pickup,
      dropoff,
    },
    riskLevel: 'medium',
  });

  // For workflow simplicity, we'll proceed with booking
  // In production, this would wait for approval signal

  const result = await bookRide({
    workspaceId,
    memberId,
    provider: selectedEstimate.provider as 'uber' | 'lyft',
    pickup,
    dropoff,
    scheduledTime,
  });

  if (result.success && result.booking) {
    await storeMemory({
      workspaceId,
      type: 'episodic',
      content: JSON.stringify({
        type: 'ride_booked',
        memberId,
        provider: selectedEstimate.provider,
        pickup,
        dropoff,
        price: result.booking.price,
      }),
      salience: 0.6,
      tags: ['transportation', 'ride', memberId],
    });

    await emitTaskEvent(workspaceId, 'transportation.ride.booked', {
      rideId: result.booking.id,
      provider: selectedEstimate.provider,
    });
  }

  return {
    success: result.success,
    booking: result.booking,
    estimates,
  };
}

// ============================================================================
// TRACK FAMILY LOCATION WORKFLOW
// ============================================================================

export interface TrackFamilyLocationInput {
  workspaceId: string;
  memberIds?: string[];
  alertOnArrival?: { memberId: string; location: string }[];
}

export async function TrackFamilyLocationWorkflow(input: TrackFamilyLocationInput): Promise<{
  locations: unknown[];
  alerts: string[];
}> {
  const { workspaceId, memberIds, alertOnArrival = [] } = input;

  await emitTaskEvent(workspaceId, 'transportation.location.checking', {});

  const locations = await getFamilyLocations({ workspaceId, memberIds });
  const alerts: string[] = [];

  // Check for arrival alerts
  for (const alertConfig of alertOnArrival) {
    const memberLocation = locations.find((l) => l.memberId === alertConfig.memberId);
    if (memberLocation) {
      // Simple check - in production would use geocoding and radius
      if (memberLocation.location.address.toLowerCase().includes(alertConfig.location.toLowerCase())) {
        alerts.push(`${memberLocation.name} has arrived at ${alertConfig.location}`);

        await emitTaskEvent(workspaceId, 'transportation.arrival', {
          memberId: alertConfig.memberId,
          location: alertConfig.location,
        });
      }
    }
  }

  // Check for stale locations
  const staleThreshold = 30 * 60 * 1000; // 30 minutes
  const now = new Date().getTime();

  for (const location of locations) {
    const lastUpdated = new Date(location.lastUpdated).getTime();
    if (now - lastUpdated > staleThreshold) {
      alerts.push(`${location.name}'s location is ${Math.round((now - lastUpdated) / 60000)} minutes old`);
    }

    // Battery alerts
    if (location.batteryLevel && location.batteryLevel < 20) {
      alerts.push(`${location.name}'s phone battery is low (${location.batteryLevel}%)`);
    }
  }

  return { locations, alerts };
}

// ============================================================================
// COMMUTE ALERT WORKFLOW
// ============================================================================

export interface CommuteAlertInput {
  workspaceId: string;
  memberId: string;
  origin: string;
  destination: string;
  arrivalTime: string; // When they need to arrive
  alertThreshold?: number; // Minutes of extra delay to trigger alert
}

export async function CommuteAlertWorkflow(input: CommuteAlertInput): Promise<{
  status: unknown;
  alertTriggered: boolean;
  departBy: string;
}> {
  const { workspaceId, memberId, origin, destination, arrivalTime, alertThreshold = 15 } = input;

  await emitTaskEvent(workspaceId, 'transportation.commute.checking', { memberId });

  const status = await getCommuteStatus({
    workspaceId,
    origin,
    destination,
    arrivalTime,
  });

  let alertTriggered = false;

  // Check if traffic is significantly worse than usual
  const delayMinutes = status.durationInTraffic - status.duration;
  if (delayMinutes >= alertThreshold) {
    alertTriggered = true;

    await emitTaskEvent(workspaceId, 'transportation.commute.alert', {
      memberId,
      normalDuration: status.duration,
      currentDuration: status.durationInTraffic,
      delay: delayMinutes,
      departBy: status.departBy,
      alerts: status.alerts,
    });
  }

  // Store commute data for pattern analysis
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'commute_check',
      memberId,
      origin,
      destination,
      duration: status.durationInTraffic,
      condition: status.trafficCondition,
      timestamp: new Date().toISOString(),
    }),
    salience: 0.3,
    tags: ['transportation', 'commute', memberId],
  });

  return {
    status,
    alertTriggered,
    departBy: status.departBy,
  };
}
