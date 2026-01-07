/**
 * Family Communication Workflows for homeOS
 *
 * Family coordination and communication:
 * - Family announcements
 * - Shared calendar sync
 * - Family check-ins
 */

import {
  proxyActivities,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  getFamilyMembers,
  createAnnouncement,
  getAnnouncements,
  createFamilyEvent,
  getFamilyCalendar,
  getChores,
  createChore,
  completeChore,
  createCheckIn,
  getCheckIns,
  getFamilySummary,
  getEmergencyContacts,
  triggerEmergencyAlert,
  emitTaskEvent,
  storeMemory,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// FAMILY ANNOUNCEMENT WORKFLOW
// ============================================================================

export interface FamilyAnnouncementWorkflowInput {
  workspaceId: string;
  createdBy: string;
  title: string;
  message: string;
  priority?: 'low' | 'normal' | 'high' | 'urgent';
  recipients?: string[];
  requireAcknowledgement?: boolean;
  expiresIn?: number; // hours
}

export async function FamilyAnnouncementWorkflow(input: FamilyAnnouncementWorkflowInput): Promise<{
  announcement: unknown;
  notifiedMembers: string[];
}> {
  const {
    workspaceId,
    createdBy,
    title,
    message,
    priority = 'normal',
    recipients,
    requireAcknowledgement = false,
    expiresIn,
  } = input;

  await emitTaskEvent(workspaceId, 'family.announcement.creating', { priority });

  // Get family members if recipients not specified
  let targetRecipients = recipients;
  if (!targetRecipients || targetRecipients.length === 0) {
    const members = await getFamilyMembers({ workspaceId });
    targetRecipients = members.map((m) => m.id);
  }

  // Create the announcement
  const announcement = await createAnnouncement({
    workspaceId,
    title,
    message,
    priority,
    createdBy,
    recipients: targetRecipients,
    expiresIn,
  });

  // Store in memory for context
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_announcement',
      title,
      priority,
      createdBy,
      timestamp: new Date().toISOString(),
    }),
    salience: priority === 'urgent' ? 0.9 : priority === 'high' ? 0.7 : 0.5,
    tags: ['family', 'announcement', priority],
  });

  await emitTaskEvent(workspaceId, 'family.announcement.sent', {
    announcementId: announcement.id,
    recipients: targetRecipients.length,
    priority,
  });

  return {
    announcement,
    notifiedMembers: targetRecipients,
  };
}

// ============================================================================
// SHARED CALENDAR SYNC WORKFLOW
// ============================================================================

export interface SharedCalendarSyncWorkflowInput {
  workspaceId: string;
  syncPeriodDays?: number;
  categories?: string[];
  createReminders?: boolean;
}

export async function SharedCalendarSyncWorkflow(input: SharedCalendarSyncWorkflowInput): Promise<{
  eventsFound: number;
  conflicts: unknown[];
  upcomingHighlights: unknown[];
}> {
  const { workspaceId, syncPeriodDays = 14, categories, createReminders = true } = input;

  await emitTaskEvent(workspaceId, 'family.calendar.syncing', {});

  const now = new Date();
  const endDate = new Date(now.getTime() + syncPeriodDays * 24 * 60 * 60 * 1000);

  // Get all family events
  const events = await getFamilyCalendar({
    workspaceId,
    startDate: now.toISOString(),
    endDate: endDate.toISOString(),
    categories,
  });

  // Detect scheduling conflicts
  const conflicts: unknown[] = [];
  const sortedEvents = [...events].sort((a, b) =>
    new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
  );

  for (let i = 0; i < sortedEvents.length - 1; i++) {
    const current = sortedEvents[i];
    const next = sortedEvents[i + 1];

    const currentEnd = current.endTime
      ? new Date(current.endTime)
      : new Date(new Date(current.startTime).getTime() + 60 * 60 * 1000);

    if (currentEnd > new Date(next.startTime)) {
      // Check if same attendees
      const currentAttendees = new Set(current.attendees.map((a) => a.memberId));
      const nextAttendees = next.attendees.map((a) => a.memberId);
      const overlap = nextAttendees.filter((id) => currentAttendees.has(id));

      if (overlap.length > 0) {
        conflicts.push({
          event1: current.title,
          event2: next.title,
          conflictingMembers: overlap,
          time: current.startTime,
        });
      }
    }
  }

  // Identify highlights (important upcoming events)
  const highlights = events
    .filter((e) =>
      e.category === 'medical' ||
      e.category === 'school' ||
      e.attendees.length > 2
    )
    .slice(0, 5);

  // Emit conflict warnings
  if (conflicts.length > 0) {
    await emitTaskEvent(workspaceId, 'family.calendar.conflicts', {
      count: conflicts.length,
      conflicts,
    });
  }

  await emitTaskEvent(workspaceId, 'family.calendar.synced', {
    eventsFound: events.length,
    conflicts: conflicts.length,
    highlights: highlights.length,
  });

  return {
    eventsFound: events.length,
    conflicts,
    upcomingHighlights: highlights,
  };
}

// ============================================================================
// FAMILY CHECK-IN WORKFLOW
// ============================================================================

export interface FamilyCheckInWorkflowInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  checkInType: 'arrival' | 'departure' | 'safety' | 'custom';
  location?: string;
  message?: string;
  notifyParents?: boolean;
}

export async function FamilyCheckInWorkflow(input: FamilyCheckInWorkflowInput): Promise<{
  checkIn: unknown;
  notified: string[];
  summary?: unknown;
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    checkInType,
    location,
    message,
    notifyParents = true,
  } = input;

  await emitTaskEvent(workspaceId, 'family.checkin.received', {
    memberId,
    type: checkInType,
    location,
  });

  // Create the check-in
  const checkIn = await createCheckIn({
    workspaceId,
    memberId,
    memberName,
    type: checkInType,
    location,
    message,
  });

  // Get family members to notify
  const members = await getFamilyMembers({ workspaceId });
  const parentsToNotify = notifyParents
    ? members.filter((m) => m.role === 'parent' && m.id !== memberId).map((m) => m.id)
    : [];

  // Store check-in in memory
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_checkin',
      member: memberName,
      checkInType,
      location,
      timestamp: new Date().toISOString(),
    }),
    salience: checkInType === 'safety' ? 0.8 : 0.5,
    tags: ['family', 'checkin', memberId],
  });

  // Get today's family summary if this is an end-of-day check-in
  let summary;
  const hour = new Date().getHours();
  if (checkInType === 'arrival' && location?.toLowerCase().includes('home') && hour >= 17) {
    summary = await getFamilySummary({ workspaceId });
  }

  await emitTaskEvent(workspaceId, 'family.checkin.processed', {
    checkInId: checkIn.id,
    notified: parentsToNotify.length,
  });

  return {
    checkIn,
    notified: parentsToNotify,
    summary,
  };
}

// ============================================================================
// DAILY FAMILY DIGEST WORKFLOW
// ============================================================================

export interface DailyFamilyDigestInput {
  workspaceId: string;
  includeChores?: boolean;
  includeCalendar?: boolean;
  includeAnnouncements?: boolean;
}

export async function DailyFamilyDigestWorkflow(input: DailyFamilyDigestInput): Promise<{
  summary: unknown;
  todoItems: string[];
}> {
  const {
    workspaceId,
    includeChores = true,
    includeCalendar = true,
    includeAnnouncements = true,
  } = input;

  await emitTaskEvent(workspaceId, 'family.digest.generating', {});

  // Get comprehensive family summary
  const summary = await getFamilySummary({ workspaceId });

  const todoItems: string[] = [];

  // Add calendar items
  if (includeCalendar && summary.upcomingEvents.length > 0) {
    const todayEvents = summary.upcomingEvents.filter((e) => {
      const eventDate = new Date(e.startTime).toDateString();
      const today = new Date().toDateString();
      return eventDate === today;
    });

    for (const event of todayEvents) {
      const time = new Date(event.startTime).toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
      });
      todoItems.push(`${time}: ${event.title}`);
    }
  }

  // Add pending chores
  if (includeChores) {
    for (const chore of summary.pendingChores) {
      todoItems.push(`Chore: ${chore.name} (${chore.assignedTo})`);
    }
  }

  // Add announcement reminders
  if (includeAnnouncements) {
    for (const announcement of summary.activeAnnouncements) {
      if (announcement.priority === 'high' || announcement.priority === 'urgent') {
        todoItems.push(`📢 ${announcement.title}`);
      }
    }
  }

  // Store digest in memory
  await storeMemory({
    workspaceId,
    type: 'working',
    content: JSON.stringify({
      type: 'daily_digest',
      date: new Date().toISOString().split('T')[0],
      eventsCount: summary.upcomingEvents.length,
      choresCount: summary.pendingChores.length,
      announcementsCount: summary.activeAnnouncements.length,
    }),
    salience: 0.6,
    tags: ['family', 'digest', 'daily'],
  });

  await emitTaskEvent(workspaceId, 'family.digest.complete', {
    todoItems: todoItems.length,
  });

  return {
    summary,
    todoItems,
  };
}

// ============================================================================
// EMERGENCY ALERT WORKFLOW
// ============================================================================

export interface FamilyEmergencyAlertInput {
  workspaceId: string;
  triggeredBy: string;
  alertType: 'medical' | 'safety' | 'location' | 'general';
  message?: string;
  location?: string;
}

export async function FamilyEmergencyAlertWorkflow(input: FamilyEmergencyAlertInput): Promise<{
  alertId: string;
  contactsNotified: string[];
  membersNotified: string[];
  emergencyContacts: unknown[];
}> {
  const { workspaceId, triggeredBy, alertType, message, location } = input;

  await emitTaskEvent(workspaceId, 'family.emergency.triggered', {
    type: alertType,
    triggeredBy,
  });

  // Trigger the emergency alert
  const alertResult = await triggerEmergencyAlert({
    workspaceId,
    triggeredBy,
    alertType,
    message,
    location,
  });

  // Get emergency contacts for reference
  const emergencyContacts = await getEmergencyContacts({ workspaceId });

  // Store emergency in memory with highest salience
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_emergency_alert',
      alertType,
      triggeredBy,
      message,
      location,
      timestamp: new Date().toISOString(),
    }),
    salience: 1.0, // Maximum salience
    tags: ['emergency', 'family', alertType],
  });

  await emitTaskEvent(workspaceId, 'family.emergency.alerted', {
    alertId: alertResult.alertId,
    membersNotified: alertResult.notifiedMembers.length,
    contactsNotified: alertResult.notifiedContacts.length,
  });

  return {
    alertId: alertResult.alertId,
    contactsNotified: alertResult.notifiedContacts,
    membersNotified: alertResult.notifiedMembers,
    emergencyContacts,
  };
}
