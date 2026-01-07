/**
 * Healthcare Workflows for homeOS
 *
 * Family health management workflows:
 * - Doctor appointment booking
 * - Medication reminders
 * - Health summaries and alerts
 */

import {
  proxyActivities,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  searchDoctors,
  bookAppointment,
  getAppointments,
  getMedications,
  checkMedicationReminders,
  getHealthSummary,
  requestPrescriptionRefill,
  emitTaskEvent,
  storeMemory,
  requestApproval,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// BOOK DOCTOR APPOINTMENT WORKFLOW
// ============================================================================

export interface BookDoctorAppointmentInput {
  workspaceId: string;
  userId: string;
  memberId: string;
  specialty: string;
  reason: string;
  preferredDateTime?: string;
  type?: 'in-person' | 'telemedicine';
}

export async function BookDoctorAppointmentWorkflow(input: BookDoctorAppointmentInput): Promise<{
  success: boolean;
  appointment?: unknown;
  error?: string;
}> {
  const { workspaceId, userId, memberId, specialty, reason, preferredDateTime, type = 'in-person' } = input;

  await emitTaskEvent(workspaceId, 'healthcare.booking.start', { specialty, memberId });

  // Step 1: Search for doctors
  const doctors = await searchDoctors({
    workspaceId,
    specialty,
    acceptingNewPatients: true,
  });

  if (doctors.length === 0) {
    return { success: false, error: 'No doctors found for this specialty' };
  }

  // Step 2: Book with first available doctor
  const doctor = doctors[0];
  const dateTime = preferredDateTime || doctor.nextAvailable || new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();

  const result = await bookAppointment({
    workspaceId,
    memberId,
    doctorId: doctor.id,
    preferredDateTime: dateTime,
    reason,
    type,
  });

  if (result.success && result.appointment) {
    // Store in memory
    await storeMemory({
      workspaceId,
      type: 'episodic',
      content: JSON.stringify({
        type: 'doctor_appointment',
        memberId,
        doctor: doctor.name,
        specialty,
        dateTime,
        appointmentType: type,
      }),
      salience: 0.8,
      tags: ['healthcare', 'appointment', memberId],
    });

    await emitTaskEvent(workspaceId, 'healthcare.booking.complete', {
      appointmentId: result.appointment.id,
    });
  }

  return result;
}

// ============================================================================
// MEDICATION REMINDER WORKFLOW
// ============================================================================

export interface MedicationReminderInput {
  workspaceId: string;
  memberId: string;
  checkInterval?: number; // hours between checks (default: 6)
}

export async function MedicationReminderWorkflow(input: MedicationReminderInput): Promise<{
  remindersGenerated: number;
}> {
  const { workspaceId, memberId, checkInterval = 6 } = input;

  let remindersGenerated = 0;

  // Check medications for each time of day
  const timesOfDay: Array<'morning' | 'afternoon' | 'evening' | 'night'> = [
    'morning', 'afternoon', 'evening', 'night'
  ];

  const currentHour = new Date().getHours();
  let currentTimeOfDay: typeof timesOfDay[number];

  if (currentHour >= 5 && currentHour < 12) currentTimeOfDay = 'morning';
  else if (currentHour >= 12 && currentHour < 17) currentTimeOfDay = 'afternoon';
  else if (currentHour >= 17 && currentHour < 21) currentTimeOfDay = 'evening';
  else currentTimeOfDay = 'night';

  const reminder = await checkMedicationReminders({
    workspaceId,
    memberId,
    timeOfDay: currentTimeOfDay,
  });

  if (reminder.medications.length > 0) {
    await emitTaskEvent(workspaceId, 'healthcare.medication.reminder', {
      memberId,
      timeOfDay: currentTimeOfDay,
      medications: reminder.medications.map((m) => m.name),
      message: reminder.message,
    });
    remindersGenerated++;
  }

  // Check for refills needed
  const allMeds = await getMedications({ workspaceId, memberId });
  const now = new Date();
  const twoWeeksFromNow = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

  for (const med of allMeds) {
    if (med.refillDate && new Date(med.refillDate) <= twoWeeksFromNow) {
      await emitTaskEvent(workspaceId, 'healthcare.medication.refill_needed', {
        memberId,
        medication: med.name,
        refillDate: med.refillDate,
      });
    }
  }

  return { remindersGenerated };
}

// ============================================================================
// HEALTH SUMMARY WORKFLOW
// ============================================================================

export interface HealthSummaryInput {
  workspaceId: string;
  memberIds: string[];
}

export async function HealthSummaryWorkflow(input: HealthSummaryInput): Promise<{
  summaries: Record<string, unknown>;
  alerts: string[];
}> {
  const { workspaceId, memberIds } = input;

  const summaries: Record<string, unknown> = {};
  const alerts: string[] = [];

  await emitTaskEvent(workspaceId, 'healthcare.summary.start', { members: memberIds.length });

  for (const memberId of memberIds) {
    const summary = await getHealthSummary({ workspaceId, memberId });
    summaries[memberId] = summary;

    // Generate alerts
    if (summary.refillsNeeded.length > 0) {
      const meds = summary.refillsNeeded.map((m) => m.name).join(', ');
      alerts.push(`${memberId}: Refills needed for ${meds}`);
    }

    if (summary.upcomingAppointments.length === 0) {
      alerts.push(`${memberId}: No upcoming appointments scheduled`);
    }

    for (const rec of summary.recommendations) {
      alerts.push(`${memberId}: ${rec}`);
    }
  }

  await emitTaskEvent(workspaceId, 'healthcare.summary.complete', {
    alertCount: alerts.length,
  });

  return { summaries, alerts };
}
