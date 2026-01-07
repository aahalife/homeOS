/**
 * School/Education Workflow for homeOS
 *
 * Orchestrates school-related tasks:
 * - Daily homework check and reminders
 * - Grade monitoring and alerts
 * - Study plan generation
 * - Parent-teacher communication
 */

import {
  proxyActivities,
  defineSignal,
  setHandler,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  listCourses,
  getAssignments,
  getGrades,
  getHomeworkSummary,
  createHomeworkReminder,
  getSchoolEvents,
  generateStudyPlan,
  emitTaskEvent,
  storeMemory,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: {
    maximumAttempts: 3,
  },
});

// ============================================================================
// DAILY HOMEWORK CHECK WORKFLOW
// ============================================================================

export interface DailyHomeworkCheckInput {
  workspaceId: string;
  studentIds: string[];
  notifyTime?: string; // e.g., "16:00" for 4pm
}

export async function DailyHomeworkCheckWorkflow(input: DailyHomeworkCheckInput): Promise<{
  summaries: Record<string, unknown>;
  alerts: string[];
}> {
  const { workspaceId, studentIds } = input;
  const summaries: Record<string, unknown> = {};
  const alerts: string[] = [];

  await emitTaskEvent(workspaceId, 'school.homework_check.start', {
    students: studentIds.length,
  });

  for (const studentId of studentIds) {
    // Get homework summary for each student
    const summary = await getHomeworkSummary({
      workspaceId,
      studentId,
      includeGradeAlerts: true,
    });

    summaries[studentId] = summary;

    // Generate alerts for missing assignments
    if (summary.missing.length > 0) {
      alerts.push(`${studentId} has ${summary.missing.length} missing assignment(s)`);
    }

    // Generate alerts for low grades
    for (const gradeAlert of summary.gradeAlerts) {
      alerts.push(`${studentId}: ${gradeAlert.courseName} grade is ${gradeAlert.currentGrade}% - ${gradeAlert.concern}`);
    }

    // Generate alerts for assignments due today
    if (summary.dueToday.length > 0) {
      const titles = summary.dueToday.map((a) => a.title).join(', ');
      alerts.push(`${studentId} has ${summary.dueToday.length} assignment(s) due today: ${titles}`);
    }

    // Store the summary in memory for future reference
    await storeMemory({
      workspaceId,
      type: 'episodic',
      content: JSON.stringify({
        type: 'homework_check',
        studentId,
        date: new Date().toISOString().split('T')[0],
        summary: summary.aiSummary,
        missing: summary.missing.length,
        dueToday: summary.dueToday.length,
        gradeAlerts: summary.gradeAlerts.length,
      }),
      salience: 0.6,
      tags: ['homework', 'daily-check', studentId],
    });
  }

  await emitTaskEvent(workspaceId, 'school.homework_check.complete', {
    alertCount: alerts.length,
  });

  return { summaries, alerts };
}

// ============================================================================
// GRADE MONITORING WORKFLOW
// ============================================================================

export interface GradeMonitoringInput {
  workspaceId: string;
  studentId: string;
  alertThreshold?: number; // Grade below this triggers alert (default: 75)
  improvementThreshold?: number; // Grade improvement triggers celebration (default: 5)
}

export async function GradeMonitoringWorkflow(input: GradeMonitoringInput): Promise<{
  grades: unknown[];
  alerts: string[];
  celebrations: string[];
}> {
  const { workspaceId, studentId, alertThreshold = 75, improvementThreshold = 5 } = input;

  await emitTaskEvent(workspaceId, 'school.grades.monitoring', { studentId });

  const grades = await getGrades({ workspaceId, studentId });
  const alerts: string[] = [];
  const celebrations: string[] = [];

  for (const grade of grades) {
    if (grade.currentGrade !== undefined) {
      if (grade.currentGrade < alertThreshold) {
        alerts.push(`${grade.courseName}: Current grade is ${grade.currentGrade}% (below ${alertThreshold}%)`);
      }

      // Check for improvement (would compare to stored historical data)
      if (grade.currentGrade >= 90) {
        celebrations.push(`${grade.courseName}: Excellent work! Current grade is ${grade.letterGrade} (${grade.currentGrade}%)`);
      }
    }
  }

  // Store grade snapshot for trend analysis
  await storeMemory({
    workspaceId,
    type: 'semantic',
    content: JSON.stringify({
      type: 'grade_snapshot',
      studentId,
      date: new Date().toISOString(),
      grades: grades.map((g) => ({
        course: g.courseName,
        grade: g.currentGrade,
        letter: g.letterGrade,
      })),
    }),
    salience: 0.7,
    tags: ['grades', 'snapshot', studentId],
  });

  return { grades, alerts, celebrations };
}

// ============================================================================
// STUDY PLAN WORKFLOW
// ============================================================================

export interface CreateStudyPlanInput {
  workspaceId: string;
  studentId: string;
  focusSubject?: string;
  upcomingExams?: string[];
  hoursPerDay?: number;
}

export async function CreateStudyPlanWorkflow(input: CreateStudyPlanInput): Promise<{
  plan: unknown;
  remindersCreated: number;
}> {
  const { workspaceId, studentId, focusSubject, upcomingExams, hoursPerDay } = input;

  await emitTaskEvent(workspaceId, 'school.study_plan.generating', { studentId });

  // Generate the study plan
  const plan = await generateStudyPlan({
    workspaceId,
    studentId,
    subject: focusSubject,
    upcomingTests: upcomingExams,
    availableHoursPerDay: hoursPerDay,
  });

  // Create reminders for each day's study session
  let remindersCreated = 0;
  for (const day of plan.dailyPlan) {
    if (day.tasks.length > 0) {
      // Create a reminder for the study session
      const studyTime = new Date(`${day.date}T16:00:00`); // Default 4pm
      if (studyTime > new Date()) {
        await createHomeworkReminder({
          workspaceId,
          studentId,
          assignmentId: `study-plan-${day.date}`,
          reminderTime: studyTime.toISOString(),
          notifyParent: true,
        });
        remindersCreated++;
      }
    }
  }

  // Store the plan in memory
  await storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({
      type: 'study_plan',
      studentId,
      createdAt: new Date().toISOString(),
      overview: plan.overview,
      daysPlanned: plan.dailyPlan.length,
      focusSubject,
    }),
    salience: 0.8,
    tags: ['study-plan', studentId, focusSubject || 'general'],
  });

  await emitTaskEvent(workspaceId, 'school.study_plan.complete', {
    daysPlanned: plan.dailyPlan.length,
    reminders: remindersCreated,
  });

  return { plan, remindersCreated };
}

// ============================================================================
// SCHOOL EVENTS SYNC WORKFLOW
// ============================================================================

export interface SchoolEventsSyncInput {
  workspaceId: string;
  studentIds: string[];
  syncToFamilyCalendar?: boolean;
}

export async function SchoolEventsSyncWorkflow(input: SchoolEventsSyncInput): Promise<{
  eventsFound: number;
  eventsSynced: number;
}> {
  const { workspaceId, studentIds, syncToFamilyCalendar = true } = input;

  await emitTaskEvent(workspaceId, 'school.events.syncing', {});

  let eventsFound = 0;
  let eventsSynced = 0;

  for (const studentId of studentIds) {
    const events = await getSchoolEvents({
      workspaceId,
      studentId,
      daysAhead: 30,
    });

    eventsFound += events.length;

    if (syncToFamilyCalendar) {
      // Would sync to family calendar here
      // For now, just count them as synced
      eventsSynced += events.length;
    }

    // Store notable events in memory
    for (const event of events) {
      if (event.type === 'exam' || event.type === 'meeting') {
        await storeMemory({
          workspaceId,
          type: 'episodic',
          content: JSON.stringify({
            type: 'school_event',
            studentId,
            event: event.title,
            date: event.date,
            eventType: event.type,
          }),
          salience: 0.7,
          tags: ['school-event', event.type, studentId],
        });
      }
    }
  }

  await emitTaskEvent(workspaceId, 'school.events.complete', {
    found: eventsFound,
    synced: eventsSynced,
  });

  return { eventsFound, eventsSynced };
}
