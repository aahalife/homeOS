/**
 * Daily Wellness Workflows for homeOS
 *
 * Practical, everyday wellness nudges that truly impact family life:
 * - Hydration reminders
 * - Movement/walking nudges
 * - Sleep hygiene
 * - Screen time management
 * - Posture and break reminders
 * - Energy optimization through meal timing
 *
 * Philosophy: Assume sensible defaults, confirm rather than ask.
 * Families are busy - these should be helpful, not intrusive.
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
  getPreferences,
  emitTaskEvent,
  storeMemory,
  recall,
  getWeather,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// HYDRATION REMINDER WORKFLOW
// ============================================================================

export interface HydrationReminderInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  dailyGoalOz?: number; // Default: 64oz for adults, adjusted for children
  reminderIntervalMinutes?: number;
}

export const hydrationLogSignal = defineSignal<[{ ozConsumed: number }]>('hydrationLog');

export async function HydrationReminderWorkflow(input: HydrationReminderInput): Promise<{
  totalConsumed: number;
  goalMet: boolean;
  remindersCount: number;
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    dailyGoalOz = 64,
    reminderIntervalMinutes = 90,
  } = input;

  let totalConsumed = 0;
  let remindersCount = 0;

  // Handle hydration logging from user
  setHandler(hydrationLogSignal, (data) => {
    totalConsumed += data.ozConsumed;
    storeMemory({
      workspaceId,
      type: 'episodic',
      content: JSON.stringify({
        type: 'hydration_log',
        member: memberName,
        oz: data.ozConsumed,
        total: totalConsumed,
      }),
      salience: 0.3,
      tags: ['wellness', 'hydration', memberId],
    });
  });

  await emitTaskEvent(workspaceId, 'wellness.hydration.started', { memberId, goal: dailyGoalOz });

  // Get weather to adjust recommendations
  let isHotDay = false;
  try {
    const weather = await getWeather({ workspaceId, location: 'current' });
    isHotDay = weather.temperature > 80;
  } catch {
    // Weather unavailable, use default
  }

  const adjustedGoal = isHotDay ? Math.round(dailyGoalOz * 1.25) : dailyGoalOz;

  // Check every interval during waking hours (7am-10pm = 15 hours)
  const maxReminders = Math.floor((15 * 60) / reminderIntervalMinutes);

  for (let i = 0; i < maxReminders && totalConsumed < adjustedGoal; i++) {
    await sleep(reminderIntervalMinutes * 60 * 1000);

    if (totalConsumed >= adjustedGoal) break;

    const remaining = adjustedGoal - totalConsumed;
    const percentComplete = Math.round((totalConsumed / adjustedGoal) * 100);

    // Friendly, non-intrusive nudge
    const messages = [
      `Quick hydration check! You're ${percentComplete}% there.`,
      `Time for water! ${remaining}oz to go today.`,
      `Stay hydrated! You've got this - ${remaining}oz left.`,
    ];

    await emitTaskEvent(workspaceId, 'wellness.hydration.reminder', {
      memberId,
      memberName,
      message: messages[i % messages.length],
      consumed: totalConsumed,
      remaining,
      percentComplete,
    });

    remindersCount++;
  }

  const goalMet = totalConsumed >= adjustedGoal;

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'hydration_daily_summary',
      member: memberName,
      consumed: totalConsumed,
      goal: adjustedGoal,
      goalMet,
      date: new Date().toISOString().split('T')[0],
    }),
    salience: goalMet ? 0.4 : 0.6,
    tags: ['wellness', 'hydration', 'daily-summary', memberId],
  });

  return { totalConsumed, goalMet, remindersCount };
}

// ============================================================================
// MOVEMENT / WALKING NUDGE WORKFLOW
// ============================================================================

export interface MovementNudgeInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  dailyStepGoal?: number;
  sedentaryThresholdMinutes?: number;
}

export const movementLogSignal = defineSignal<[{ steps?: number; minutes?: number }]>('movementLog');

export async function MovementNudgeWorkflow(input: MovementNudgeInput): Promise<{
  totalSteps: number;
  activeMinutes: number;
  nudgesCount: number;
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    dailyStepGoal = 8000,
    sedentaryThresholdMinutes = 60,
  } = input;

  let totalSteps = 0;
  let activeMinutes = 0;
  let nudgesCount = 0;
  let lastActivityTime = Date.now();

  setHandler(movementLogSignal, (data) => {
    if (data.steps) totalSteps += data.steps;
    if (data.minutes) activeMinutes += data.minutes;
    lastActivityTime = Date.now();
  });

  await emitTaskEvent(workspaceId, 'wellness.movement.started', { memberId, goal: dailyStepGoal });

  // Monitor throughout the day
  const checkIntervalMinutes = 30;
  const maxChecks = 32; // ~16 hours of monitoring

  for (let i = 0; i < maxChecks; i++) {
    await sleep(checkIntervalMinutes * 60 * 1000);

    const minutesSinceActivity = (Date.now() - lastActivityTime) / (1000 * 60);

    // Check if sedentary too long
    if (minutesSinceActivity >= sedentaryThresholdMinutes) {
      const suggestions = [
        'Time for a quick stretch! Even 2 minutes helps.',
        'How about a short walk? Fresh air does wonders.',
        'Quick break! Stand up and move around for a bit.',
        'Your body will thank you for a movement break!',
      ];

      await emitTaskEvent(workspaceId, 'wellness.movement.nudge', {
        memberId,
        memberName,
        message: suggestions[nudgesCount % suggestions.length],
        minutesSedentary: Math.round(minutesSinceActivity),
        currentSteps: totalSteps,
        stepGoal: dailyStepGoal,
      });

      nudgesCount++;
    }

    // Encouragement when making progress
    if (totalSteps >= dailyStepGoal * 0.5 && totalSteps < dailyStepGoal * 0.75) {
      await emitTaskEvent(workspaceId, 'wellness.movement.milestone', {
        memberId,
        message: `Halfway there! ${dailyStepGoal - totalSteps} steps to go.`,
      });
    }
  }

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'movement_daily_summary',
      member: memberName,
      steps: totalSteps,
      activeMinutes,
      goal: dailyStepGoal,
      goalMet: totalSteps >= dailyStepGoal,
    }),
    salience: 0.5,
    tags: ['wellness', 'movement', 'daily-summary', memberId],
  });

  return { totalSteps, activeMinutes, nudgesCount };
}

// ============================================================================
// SLEEP HYGIENE WORKFLOW
// ============================================================================

export interface SleepHygieneInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  targetBedtime?: string; // e.g., "22:00"
  targetWakeTime?: string; // e.g., "06:30"
  windDownMinutes?: number;
}

export async function SleepHygieneWorkflow(input: SleepHygieneInput): Promise<{
  remindersSent: string[];
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    targetBedtime = '22:00',
    targetWakeTime = '06:30',
    windDownMinutes = 30,
  } = input;

  const remindersSent: string[] = [];

  // Calculate times
  const [bedHour, bedMinute] = targetBedtime.split(':').map(Number);
  const windDownTime = new Date();
  windDownTime.setHours(bedHour, bedMinute - windDownMinutes, 0, 0);

  const now = new Date();
  const msUntilWindDown = windDownTime.getTime() - now.getTime();

  if (msUntilWindDown > 0) {
    await sleep(msUntilWindDown);
  }

  // Wind-down reminder
  await emitTaskEvent(workspaceId, 'wellness.sleep.winddown', {
    memberId,
    memberName,
    message: `Time to start winding down. Bedtime is in ${windDownMinutes} minutes.`,
    suggestions: [
      'Dim the lights',
      'Put away screens',
      'Light reading or relaxation',
      'Prepare for tomorrow',
    ],
  });
  remindersSent.push('wind-down');

  // 10 minutes before bed
  await sleep((windDownMinutes - 10) * 60 * 1000);

  await emitTaskEvent(workspaceId, 'wellness.sleep.almost', {
    memberId,
    memberName,
    message: '10 minutes to bedtime. Time to wrap up!',
  });
  remindersSent.push('10-min-warning');

  // Bedtime
  await sleep(10 * 60 * 1000);

  await emitTaskEvent(workspaceId, 'wellness.sleep.bedtime', {
    memberId,
    memberName,
    message: `Bedtime! Aim for ${targetWakeTime} wake-up. Sweet dreams!`,
  });
  remindersSent.push('bedtime');

  // Store sleep schedule adherence
  await storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({
      type: 'sleep_routine',
      member: memberName,
      targetBedtime,
      targetWakeTime,
      remindersSent: remindersSent.length,
    }),
    salience: 0.6,
    tags: ['wellness', 'sleep', 'routine', memberId],
  });

  return { remindersSent };
}

// ============================================================================
// SCREEN TIME MANAGEMENT WORKFLOW
// ============================================================================

export interface ScreenTimeInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  dailyLimitMinutes?: number;
  breakIntervalMinutes?: number;
  isChild?: boolean;
}

export const screenTimeLogSignal = defineSignal<[{ minutes: number; app?: string }]>('screenTimeLog');

export async function ScreenTimeWorkflow(input: ScreenTimeInput): Promise<{
  totalMinutes: number;
  breaksTaken: number;
  limitReached: boolean;
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    dailyLimitMinutes = 180, // 3 hours default
    breakIntervalMinutes = 20,
    isChild = false,
  } = input;

  let totalMinutes = 0;
  let breaksTaken = 0;
  let lastBreakTime = Date.now();

  // Adjust limits for children
  const limit = isChild ? Math.min(dailyLimitMinutes, 120) : dailyLimitMinutes;

  setHandler(screenTimeLogSignal, (data) => {
    totalMinutes += data.minutes;
  });

  await emitTaskEvent(workspaceId, 'wellness.screentime.started', {
    memberId,
    limit,
    isChild,
  });

  // Monitor throughout usage periods
  const checkIntervalMinutes = 15;
  const maxChecks = Math.ceil(limit / checkIntervalMinutes) + 5;

  for (let i = 0; i < maxChecks; i++) {
    await sleep(checkIntervalMinutes * 60 * 1000);

    const minutesSinceBreak = (Date.now() - lastBreakTime) / (1000 * 60);

    // Eye break reminder (20-20-20 rule inspired)
    if (minutesSinceBreak >= breakIntervalMinutes) {
      await emitTaskEvent(workspaceId, 'wellness.screentime.eyebreak', {
        memberId,
        memberName,
        message: 'Quick eye break! Look at something 20 feet away for 20 seconds.',
      });
      lastBreakTime = Date.now();
      breaksTaken++;
    }

    // Approaching limit
    if (totalMinutes >= limit * 0.75 && totalMinutes < limit * 0.9) {
      await emitTaskEvent(workspaceId, 'wellness.screentime.approaching', {
        memberId,
        memberName,
        message: `${limit - totalMinutes} minutes of screen time remaining today.`,
        remaining: limit - totalMinutes,
      });
    }

    // Limit reached
    if (totalMinutes >= limit) {
      await emitTaskEvent(workspaceId, 'wellness.screentime.limit', {
        memberId,
        memberName,
        message: isChild
          ? 'Screen time is done for today! Time for other activities.'
          : 'You\'ve hit your screen time goal. Consider taking a break!',
        isEnforced: isChild,
      });
      break;
    }
  }

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'screentime_daily',
      member: memberName,
      totalMinutes,
      limit,
      breaksTaken,
    }),
    salience: 0.4,
    tags: ['wellness', 'screentime', memberId],
  });

  return {
    totalMinutes,
    breaksTaken,
    limitReached: totalMinutes >= limit,
  };
}

// ============================================================================
// POSTURE & DESK BREAK WORKFLOW
// ============================================================================

export interface PostureBreakInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  breakIntervalMinutes?: number;
  workStartTime?: string;
  workEndTime?: string;
}

export async function PostureBreakWorkflow(input: PostureBreakInput): Promise<{
  breaksReminded: number;
  exercises: string[];
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    breakIntervalMinutes = 45,
    workStartTime = '09:00',
    workEndTime = '17:00',
  } = input;

  let breaksReminded = 0;
  const exercises: string[] = [];

  const exerciseOptions = [
    { name: 'Neck rolls', duration: '30 seconds each direction' },
    { name: 'Shoulder shrugs', duration: '10 reps' },
    { name: 'Wrist circles', duration: '30 seconds each direction' },
    { name: 'Stand and stretch', duration: '1 minute' },
    { name: 'Walk to get water', duration: '2 minutes' },
    { name: 'Look out window', duration: '1 minute - rest your eyes' },
    { name: 'Deep breathing', duration: '5 deep breaths' },
    { name: 'Desk push-ups', duration: '10 reps' },
  ];

  // Calculate work duration
  const [startHour] = workStartTime.split(':').map(Number);
  const [endHour] = workEndTime.split(':').map(Number);
  const workHours = endHour - startHour;
  const totalBreaks = Math.floor((workHours * 60) / breakIntervalMinutes);

  await emitTaskEvent(workspaceId, 'wellness.posture.started', {
    memberId,
    breakInterval: breakIntervalMinutes,
  });

  for (let i = 0; i < totalBreaks; i++) {
    await sleep(breakIntervalMinutes * 60 * 1000);

    const exercise = exerciseOptions[i % exerciseOptions.length];
    exercises.push(exercise.name);

    await emitTaskEvent(workspaceId, 'wellness.posture.break', {
      memberId,
      memberName,
      message: `Posture break! Try: ${exercise.name}`,
      exercise: exercise.name,
      duration: exercise.duration,
      breakNumber: i + 1,
      totalBreaks,
    });

    breaksReminded++;
  }

  return { breaksReminded, exercises };
}

// ============================================================================
// ENERGY OPTIMIZATION WORKFLOW
// ============================================================================

export interface EnergyOptimizationInput {
  workspaceId: string;
  memberId: string;
  memberName: string;
  wakeTime?: string;
  targetMealTimes?: { breakfast?: string; lunch?: string; dinner?: string };
}

export async function EnergyOptimizationWorkflow(input: EnergyOptimizationInput): Promise<{
  nudgesSent: string[];
}> {
  const {
    workspaceId,
    memberId,
    memberName,
    wakeTime = '07:00',
    targetMealTimes = {
      breakfast: '08:00',
      lunch: '12:30',
      dinner: '18:30',
    },
  } = input;

  const nudgesSent: string[] = [];

  // Morning energy nudges
  const morningNudges = [
    { time: wakeTime, message: 'Good morning! Start with a glass of water to kickstart your metabolism.' },
    {
      time: targetMealTimes.breakfast || '08:00',
      message: 'Breakfast time! Fuel up with protein for sustained energy.',
    },
  ];

  // Afternoon energy dip prevention
  const afternoonNudges = [
    {
      time: '14:00',
      message: 'Energy dip coming? A short walk or healthy snack can help.',
    },
    {
      time: '15:30',
      message: 'Stay energized! Consider a light stretch or some fresh air.',
    },
  ];

  // Evening wind-down for next-day energy
  const eveningNudges = [
    {
      time: '20:00',
      message: 'Preparing for tomorrow: Consider laying out clothes and packing bags.',
    },
    {
      time: '21:00',
      message: 'Winding down. Avoid heavy meals and caffeine for better sleep quality.',
    },
  ];

  const allNudges = [...morningNudges, ...afternoonNudges, ...eveningNudges];

  for (const nudge of allNudges) {
    const [hour, minute] = nudge.time.split(':').map(Number);
    const nudgeTime = new Date();
    nudgeTime.setHours(hour, minute, 0, 0);

    const now = new Date();
    const msUntilNudge = nudgeTime.getTime() - now.getTime();

    if (msUntilNudge > 0) {
      await sleep(msUntilNudge);

      await emitTaskEvent(workspaceId, 'wellness.energy.nudge', {
        memberId,
        memberName,
        message: nudge.message,
        time: nudge.time,
      });

      nudgesSent.push(nudge.message);
    }
  }

  await storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({
      type: 'energy_optimization_routine',
      member: memberName,
      nudgesSent: nudgesSent.length,
      date: new Date().toISOString().split('T')[0],
    }),
    salience: 0.4,
    tags: ['wellness', 'energy', memberId],
  });

  return { nudgesSent };
}

// ============================================================================
// COMPREHENSIVE DAILY WELLNESS CHECK WORKFLOW
// ============================================================================

export interface DailyWellnessCheckInput {
  workspaceId: string;
  familyMemberIds: string[];
}

export async function DailyWellnessCheckWorkflow(input: DailyWellnessCheckInput): Promise<{
  summaries: Record<string, unknown>;
  overallScore: number;
}> {
  const { workspaceId, familyMemberIds } = input;

  await emitTaskEvent(workspaceId, 'wellness.daily.started', {
    members: familyMemberIds.length,
  });

  const summaries: Record<string, unknown> = {};
  let totalScore = 0;

  for (const memberId of familyMemberIds) {
    // Recall today's wellness data
    const today = new Date().toISOString().split('T')[0];

    const memories = await recall({
      workspaceId,
      query: `wellness ${memberId} ${today}`,
      types: ['episodic'],
      limit: 20,
      tags: ['wellness', memberId],
    });

    // Calculate wellness score
    let memberScore = 50; // Base score

    for (const memory of memories) {
      try {
        const data = JSON.parse(memory.content);
        if (data.type === 'hydration_daily_summary' && data.goalMet) memberScore += 15;
        if (data.type === 'movement_daily_summary' && data.goalMet) memberScore += 20;
        if (data.type === 'screentime_daily' && !data.limitReached) memberScore += 10;
        if (data.type === 'sleep_routine') memberScore += 5;
      } catch {
        // Skip non-JSON memories
      }
    }

    memberScore = Math.min(100, memberScore);
    summaries[memberId] = { score: memberScore, memoriesProcessed: memories.length };
    totalScore += memberScore;
  }

  const overallScore = Math.round(totalScore / familyMemberIds.length);

  await emitTaskEvent(workspaceId, 'wellness.daily.complete', {
    overallScore,
    memberCount: familyMemberIds.length,
  });

  // Store family wellness summary
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_wellness_daily',
      date: new Date().toISOString().split('T')[0],
      overallScore,
      memberScores: summaries,
    }),
    salience: 0.7,
    tags: ['wellness', 'family', 'daily-summary'],
  });

  return { summaries, overallScore };
}
