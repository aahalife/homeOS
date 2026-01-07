/**
 * Mental Load Reduction Workflows for homeOS
 *
 * Workflows that reduce the cognitive burden on families:
 * - Automatic scheduling and conflict detection
 * - Proactive reminders (so you don't have to remember)
 * - Decision fatigue reduction
 * - Household coordination
 * - Weekly planning automation
 * - Morning routine optimization
 *
 * Philosophy: Take care of the invisible labor so families can focus
 * on being present with each other.
 */

import {
  proxyActivities,
  sleep,
  defineSignal,
  setHandler,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  getFamilyMembers,
  getFamilyCalendar,
  createFamilyEvent,
  getPreferences,
  getChores,
  getMaintenanceSchedule,
  getMedications,
  emitTaskEvent,
  storeMemory,
  recall,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// MORNING BRIEFING WORKFLOW
// ============================================================================

export interface MorningBriefingInput {
  workspaceId: string;
  familyId: string;
  briefingTime?: string; // Default: 07:00
}

export async function MorningBriefingWorkflow(input: MorningBriefingInput): Promise<{
  briefingSent: boolean;
  highlights: string[];
}> {
  const {
    workspaceId,
    familyId,
    briefingTime = '07:00',
  } = input;

  // Wait until briefing time
  const [hour, minute] = briefingTime.split(':').map(Number);
  const briefingDateTime = new Date();
  briefingDateTime.setHours(hour, minute, 0, 0);

  const now = new Date();
  if (briefingDateTime > now) {
    await sleep(briefingDateTime.getTime() - now.getTime());
  }

  const highlights: string[] = [];

  // Get today's calendar events
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const events = await getFamilyCalendar({
    workspaceId,
    startDate: todayStart.toISOString(),
    endDate: todayEnd.toISOString(),
  });

  if (events.length > 0) {
    const eventSummary = events.slice(0, 3).map((e) => {
      const time = new Date(e.startTime).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
      return `${time}: ${e.title}`;
    });
    highlights.push(`Today's events: ${eventSummary.join(', ')}`);
  }

  // Get chores due today
  const chores = await getChores({ workspaceId, dueWithin: 1 });
  if (chores.length > 0) {
    const choreList = chores.slice(0, 3).map((c) => `${c.name} (${c.assignedTo})`);
    highlights.push(`Chores today: ${choreList.join(', ')}`);
  }

  // Check medication reminders
  try {
    const members = await getFamilyMembers({ workspaceId });
    for (const member of members) {
      const meds = await getMedications({ workspaceId, memberId: member.id });
      const morningMeds = meds.filter((m) => m.schedule?.includes('morning'));
      if (morningMeds.length > 0) {
        highlights.push(`${member.name}: ${morningMeds.length} medication(s) this morning`);
      }
    }
  } catch {
    // Skip if medications not configured
  }

  // Check maintenance due
  try {
    const maintenance = await getMaintenanceSchedule({ workspaceId, dueWithin: 1 });
    if (maintenance.length > 0) {
      highlights.push(`Maintenance: ${maintenance[0].name} due today`);
    }
  } catch {
    // Skip if maintenance not configured
  }

  // Weather-based suggestions (would integrate with weather API)
  const dayOfWeek = new Date().toLocaleDateString('en-US', { weekday: 'long' });
  if (dayOfWeek === 'Monday') {
    highlights.push('Tip: Start the week strong! Tackle the hardest task first.');
  } else if (dayOfWeek === 'Friday') {
    highlights.push('Tip: Almost weekend! Consider wrapping up loose ends today.');
  }

  await emitTaskEvent(workspaceId, 'mentalload.morning.briefing', {
    message: 'Good morning! Here\'s your family briefing:',
    highlights,
    eventCount: events.length,
    choreCount: chores.length,
  });

  await storeMemory({
    workspaceId,
    type: 'working',
    content: JSON.stringify({
      type: 'morning_briefing',
      date: new Date().toISOString().split('T')[0],
      highlights,
    }),
    salience: 0.6,
    tags: ['briefing', 'morning'],
  });

  return { briefingSent: true, highlights };
}

// ============================================================================
// WEEKLY PLANNING WORKFLOW
// ============================================================================

export interface WeeklyPlanningInput {
  workspaceId: string;
  planningDay?: string; // Default: Sunday
  planningTime?: string; // Default: 18:00
}

export async function WeeklyPlanningWorkflow(input: WeeklyPlanningInput): Promise<{
  weekOverview: {
    events: number;
    chores: number;
    conflicts: string[];
    suggestions: string[];
  };
}> {
  const {
    workspaceId,
    planningDay = 'Sunday',
    planningTime = '18:00',
  } = input;

  // Calculate dates for the upcoming week
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() + 1); // Start from tomorrow
  const weekEnd = new Date(weekStart);
  weekEnd.setDate(weekStart.getDate() + 7);

  // Get all events for the week
  const events = await getFamilyCalendar({
    workspaceId,
    startDate: weekStart.toISOString(),
    endDate: weekEnd.toISOString(),
  });

  // Detect conflicts (overlapping events for same attendees)
  const conflicts: string[] = [];
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
      const currentAttendees = new Set(current.attendees?.map((a) => a.memberId) || []);
      const nextAttendees = next.attendees?.map((a) => a.memberId) || [];
      const overlap = nextAttendees.filter((id) => currentAttendees.has(id));

      if (overlap.length > 0) {
        conflicts.push(`${current.title} and ${next.title} overlap`);
      }
    }
  }

  // Get chores for the week
  const chores = await getChores({ workspaceId, dueWithin: 7 });

  // Generate suggestions
  const suggestions: string[] = [];

  // Check for busy days
  const eventsByDay: Record<string, number> = {};
  for (const event of events) {
    const day = new Date(event.startTime).toLocaleDateString('en-US', { weekday: 'long' });
    eventsByDay[day] = (eventsByDay[day] || 0) + 1;
  }

  for (const [day, count] of Object.entries(eventsByDay)) {
    if (count >= 4) {
      suggestions.push(`${day} looks busy (${count} events). Consider prep the night before.`);
    }
  }

  // Check for empty days
  const allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const emptyDays = allDays.filter((day) => !eventsByDay[day] || eventsByDay[day] === 0);
  if (emptyDays.length > 0) {
    suggestions.push(`${emptyDays[0]} is free - good day for errands or family time!`);
  }

  // Check if family time is scheduled
  const hasFamilyEvent = events.some((e) =>
    e.category === 'family' || e.title.toLowerCase().includes('family')
  );
  if (!hasFamilyEvent) {
    suggestions.push('No family time scheduled this week. Consider adding quality time!');
  }

  const weekOverview = {
    events: events.length,
    chores: chores.length,
    conflicts,
    suggestions,
  };

  await emitTaskEvent(workspaceId, 'mentalload.weekly.planning', {
    message: 'Your week ahead:',
    weekOverview,
    dateRange: `${weekStart.toLocaleDateString()} - ${weekEnd.toLocaleDateString()}`,
  });

  await storeMemory({
    workspaceId,
    type: 'working',
    content: JSON.stringify({
      type: 'weekly_planning',
      weekOf: weekStart.toISOString().split('T')[0],
      ...weekOverview,
    }),
    salience: 0.7,
    tags: ['planning', 'weekly'],
  });

  return { weekOverview };
}

// ============================================================================
// PROACTIVE REMINDER WORKFLOW
// ============================================================================

export interface ProactiveReminderInput {
  workspaceId: string;
  checkIntervalMinutes?: number;
}

export async function ProactiveReminderWorkflow(input: ProactiveReminderInput): Promise<{
  remindersSent: number;
}> {
  const {
    workspaceId,
    checkIntervalMinutes = 60,
  } = input;

  let remindersSent = 0;

  // Run throughout the day
  const maxChecks = 16; // ~16 hours

  for (let i = 0; i < maxChecks; i++) {
    const now = new Date();
    const lookAheadMinutes = 60; // 1 hour ahead

    // Check for upcoming events
    const upcomingEnd = new Date(now.getTime() + lookAheadMinutes * 60 * 1000);
    const events = await getFamilyCalendar({
      workspaceId,
      startDate: now.toISOString(),
      endDate: upcomingEnd.toISOString(),
    });

    for (const event of events) {
      const eventTime = new Date(event.startTime);
      const minutesUntil = Math.round((eventTime.getTime() - now.getTime()) / (60 * 1000));

      // Remind at 30 min and 10 min before
      if (minutesUntil === 30 || minutesUntil === 10) {
        await emitTaskEvent(workspaceId, 'mentalload.reminder.event', {
          eventTitle: event.title,
          minutesUntil,
          message: `${event.title} in ${minutesUntil} minutes`,
          attendees: event.attendees?.map((a) => a.memberId) || [],
        });
        remindersSent++;
      }
    }

    // Check for items that need prep time
    const prepEvents = events.filter((e) => {
      // Events that typically need preparation
      const needsPrep = ['doctor', 'appointment', 'meeting', 'interview', 'presentation'];
      return needsPrep.some((keyword) => e.title.toLowerCase().includes(keyword));
    });

    for (const event of prepEvents) {
      const eventTime = new Date(event.startTime);
      const minutesUntil = Math.round((eventTime.getTime() - now.getTime()) / (60 * 1000));

      if (minutesUntil === 45) {
        await emitTaskEvent(workspaceId, 'mentalload.reminder.prep', {
          eventTitle: event.title,
          message: `Prep time! ${event.title} is in 45 minutes. Gather what you need.`,
        });
        remindersSent++;
      }
    }

    await sleep(checkIntervalMinutes * 60 * 1000);
  }

  return { remindersSent };
}

// ============================================================================
// DECISION SIMPLIFICATION WORKFLOW
// ============================================================================

export interface DecisionSimplificationInput {
  workspaceId: string;
  decisionType: 'dinner' | 'activity' | 'chore-assignment' | 'schedule';
  context?: Record<string, unknown>;
}

export async function DecisionSimplificationWorkflow(input: DecisionSimplificationInput): Promise<{
  recommendation: string;
  alternatives: string[];
  reasoning: string;
}> {
  const {
    workspaceId,
    decisionType,
    context = {},
  } = input;

  let recommendation = '';
  let alternatives: string[] = [];
  let reasoning = '';

  switch (decisionType) {
    case 'dinner': {
      // Get recent meal history to avoid repetition
      const recentMeals = await recall({
        workspaceId,
        query: 'dinner meal',
        types: ['episodic'],
        limit: 7,
        tags: ['meal'],
      });

      const recentMealNames = recentMeals.map((m) => {
        try {
          return JSON.parse(m.content).meal;
        } catch {
          return '';
        }
      }).filter(Boolean);

      const dinnerOptions = [
        'Pasta night',
        'Taco Tuesday',
        'Stir-fry',
        'Pizza (homemade or takeout)',
        'Soup and sandwiches',
        'Breakfast for dinner',
        'Grilled chicken and veggies',
        'Slow cooker meal',
      ];

      // Filter out recent meals
      const freshOptions = dinnerOptions.filter((d) =>
        !recentMealNames.some((m) => m.toLowerCase().includes(d.toLowerCase()))
      );

      recommendation = freshOptions[0] || dinnerOptions[0];
      alternatives = freshOptions.slice(1, 3);
      reasoning = 'Based on avoiding recent meals and simplicity';
      break;
    }

    case 'activity': {
      // Get day of week and weather considerations
      const dayOfWeek = new Date().getDay();
      const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;

      if (isWeekend) {
        recommendation = 'Family park visit';
        alternatives = ['Board games at home', 'Bike ride', 'Movie afternoon'];
        reasoning = 'Weekend activity that gets everyone outside';
      } else {
        recommendation = 'Quick card game after dinner';
        alternatives = ['20-minute family walk', 'Reading time together'];
        reasoning = 'Weekday-appropriate, manageable time commitment';
      }
      break;
    }

    case 'chore-assignment': {
      const members = await getFamilyMembers({ workspaceId });
      const chores = await getChores({ workspaceId, status: 'pending' });

      // Simple round-robin assignment
      const assignments: Record<string, string[]> = {};
      for (let i = 0; i < chores.length; i++) {
        const member = members[i % members.length];
        if (!assignments[member.name]) assignments[member.name] = [];
        assignments[member.name].push(chores[i].name);
      }

      recommendation = Object.entries(assignments)
        .map(([name, tasks]) => `${name}: ${tasks.join(', ')}`)
        .join(' | ');
      alternatives = ['Rotate assignments', 'Let family choose'];
      reasoning = 'Even distribution across family members';
      break;
    }

    case 'schedule': {
      // Find best time for a family activity
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);
      const tomorrowEnd = new Date(tomorrow);
      tomorrowEnd.setHours(23, 59, 59, 999);

      const events = await getFamilyCalendar({
        workspaceId,
        startDate: tomorrow.toISOString(),
        endDate: tomorrowEnd.toISOString(),
      });

      // Find gaps in schedule
      const busyHours = new Set<number>();
      for (const event of events) {
        const start = new Date(event.startTime).getHours();
        const end = event.endTime ? new Date(event.endTime).getHours() : start + 1;
        for (let h = start; h < end; h++) {
          busyHours.add(h);
        }
      }

      // Find free slots
      const preferredHours = [10, 14, 16, 18]; // Good activity times
      const freeHours = preferredHours.filter((h) => !busyHours.has(h));

      if (freeHours.length > 0) {
        recommendation = `${freeHours[0]}:00 tomorrow`;
        alternatives = freeHours.slice(1, 3).map((h) => `${h}:00`);
        reasoning = 'Free time slot that works for everyone';
      } else {
        recommendation = 'Consider rescheduling - tomorrow is busy';
        alternatives = ['Check Sunday', 'Early morning option'];
        reasoning = 'No ideal slots available tomorrow';
      }
      break;
    }
  }

  await emitTaskEvent(workspaceId, 'mentalload.decision.simplified', {
    decisionType,
    recommendation,
    alternatives,
    reasoning,
    message: `Recommendation: ${recommendation}`,
  });

  return { recommendation, alternatives, reasoning };
}

// ============================================================================
// EVENING WIND-DOWN WORKFLOW
// ============================================================================

export interface EveningWindDownInput {
  workspaceId: string;
  windDownTime?: string; // Default: 20:00
}

export async function EveningWindDownWorkflow(input: EveningWindDownInput): Promise<{
  tasksReviewed: number;
  tomorrowPrepped: boolean;
}> {
  const {
    workspaceId,
    windDownTime = '20:00',
  } = input;

  // Wait until wind-down time
  const [hour, minute] = windDownTime.split(':').map(Number);
  const windDownDateTime = new Date();
  windDownDateTime.setHours(hour, minute, 0, 0);

  const now = new Date();
  if (windDownDateTime > now) {
    await sleep(windDownDateTime.getTime() - now.getTime());
  }

  // Review what got done today
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todaysActivities = await recall({
    workspaceId,
    query: 'completed done finished',
    types: ['episodic'],
    limit: 10,
  });

  // Check tomorrow's calendar
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  const tomorrowEnd = new Date(tomorrow);
  tomorrowEnd.setHours(23, 59, 59, 999);

  const tomorrowEvents = await getFamilyCalendar({
    workspaceId,
    startDate: tomorrow.toISOString(),
    endDate: tomorrowEnd.toISOString(),
  });

  // Prep reminders
  const prepTasks: string[] = [];

  if (tomorrowEvents.length > 0) {
    const firstEvent = tomorrowEvents[0];
    const firstEventTime = new Date(firstEvent.startTime).toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    });
    prepTasks.push(`First event tomorrow: ${firstEvent.title} at ${firstEventTime}`);
  }

  // Check if it's a school night
  const tomorrow_day = tomorrow.getDay();
  if (tomorrow_day >= 1 && tomorrow_day <= 5) {
    prepTasks.push('School night - check backpacks and lunches');
  }

  await emitTaskEvent(workspaceId, 'mentalload.evening.winddown', {
    message: 'Evening wind-down time',
    accomplished: todaysActivities.length,
    tomorrowEvents: tomorrowEvents.length,
    prepTasks,
    suggestions: [
      'Lay out tomorrow\'s clothes',
      'Check weather for tomorrow',
      'Set any needed alarms',
      'Charge devices',
    ],
  });

  await storeMemory({
    workspaceId,
    type: 'working',
    content: JSON.stringify({
      type: 'evening_winddown',
      date: new Date().toISOString().split('T')[0],
      tasksReviewed: todaysActivities.length,
      tomorrowEvents: tomorrowEvents.length,
    }),
    salience: 0.5,
    tags: ['winddown', 'evening'],
  });

  return {
    tasksReviewed: todaysActivities.length,
    tomorrowPrepped: prepTasks.length > 0,
  };
}

// ============================================================================
// HOUSEHOLD COORDINATION WORKFLOW
// ============================================================================

export interface HouseholdCoordinationInput {
  workspaceId: string;
}

export async function HouseholdCoordinationWorkflow(input: HouseholdCoordinationInput): Promise<{
  coordinationItems: string[];
  conflictsResolved: number;
}> {
  const { workspaceId } = input;

  const coordinationItems: string[] = [];
  let conflictsResolved = 0;

  // Get all family members
  const members = await getFamilyMembers({ workspaceId });

  // Check for transportation conflicts (multiple people needing car)
  // This would integrate with real calendar/transportation data
  const today = new Date();
  const todayEnd = new Date(today);
  todayEnd.setHours(23, 59, 59, 999);

  const events = await getFamilyCalendar({
    workspaceId,
    startDate: today.toISOString(),
    endDate: todayEnd.toISOString(),
  });

  // Group events by time to find potential conflicts
  const eventsByHour: Record<number, typeof events> = {};
  for (const event of events) {
    const hour = new Date(event.startTime).getHours();
    if (!eventsByHour[hour]) eventsByHour[hour] = [];
    eventsByHour[hour].push(event);
  }

  for (const [hour, hourEvents] of Object.entries(eventsByHour)) {
    if (hourEvents.length > 1) {
      coordinationItems.push(
        `${hour}:00 - Multiple events: ${hourEvents.map((e) => e.title).join(', ')}. ` +
        'May need to coordinate transportation.'
      );
    }
  }

  // Check shared resources (would integrate with home systems)
  // For now, provide general coordination tips based on family size
  if (members.length >= 4) {
    coordinationItems.push('Large family tip: Consider a shared family calendar visible to all');
  }

  // Check if anyone is working from home
  const wfhEvents = events.filter((e) =>
    e.title.toLowerCase().includes('wfh') ||
    e.title.toLowerCase().includes('work from home') ||
    e.title.toLowerCase().includes('remote')
  );

  if (wfhEvents.length > 0) {
    coordinationItems.push('Someone working from home - consider noise levels during meetings');
  }

  await emitTaskEvent(workspaceId, 'mentalload.coordination.update', {
    coordinationItems,
    memberCount: members.length,
    eventCount: events.length,
  });

  return { coordinationItems, conflictsResolved };
}
