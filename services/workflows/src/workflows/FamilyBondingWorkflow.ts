/**
 * Family Bonding Workflows for homeOS
 *
 * Workflows that encourage family connection and quality time:
 * - Family dinner coordination
 * - Game night planning
 * - Weekend activity suggestions
 * - Quality conversation starters
 * - Gratitude and appreciation moments
 * - Family traditions and rituals
 *
 * Philosophy: Strengthen family bonds through intentional moments.
 * These are gentle suggestions, not obligations.
 */

import {
  proxyActivities,
  sleep,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  getFamilyMembers,
  getFamilyCalendar,
  getPreferences,
  createFamilyEvent,
  emitTaskEvent,
  storeMemory,
  recall,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// FAMILY DINNER COORDINATION WORKFLOW
// ============================================================================

export interface FamilyDinnerInput {
  workspaceId: string;
  targetTime?: string; // Default: 18:30
  notifyMinutesBefore?: number;
}

export async function FamilyDinnerWorkflow(input: FamilyDinnerInput): Promise<{
  membersNotified: string[];
  suggestedTopics: string[];
}> {
  const {
    workspaceId,
    targetTime = '18:30',
    notifyMinutesBefore = 30,
  } = input;

  const members = await getFamilyMembers({ workspaceId });
  const membersNotified: string[] = [];

  // Calculate notification time
  const [hour, minute] = targetTime.split(':').map(Number);
  const dinnerTime = new Date();
  dinnerTime.setHours(hour, minute, 0, 0);

  const notifyTime = new Date(dinnerTime.getTime() - notifyMinutesBefore * 60 * 1000);
  const now = new Date();
  const msUntilNotify = notifyTime.getTime() - now.getTime();

  if (msUntilNotify > 0) {
    await sleep(msUntilNotify);
  }

  // Generate conversation starters based on day/family
  const dayOfWeek = new Date().getDay();
  const topicsByDay = {
    0: ['What are you looking forward to this week?', 'Share a highlight from the weekend!'],
    1: ['How did Monday treat you?', 'Any fun plans for this week?'],
    2: ['What made you laugh today?', 'Learn anything new today?'],
    3: ['If you could travel anywhere, where would you go?', 'What\'s your favorite family memory?'],
    4: ['Almost Friday! What are weekend plans?', 'Share something you\'re grateful for.'],
    5: ['It\'s Friday! Best part of the week?', 'What sounds fun for the weekend?'],
    6: ['What adventure should we have today?', 'Share a dream you had recently.'],
  };

  const suggestedTopics = topicsByDay[dayOfWeek as keyof typeof topicsByDay] || topicsByDay[3];

  // Notify each family member
  for (const member of members) {
    await emitTaskEvent(workspaceId, 'family.dinner.reminder', {
      memberId: member.id,
      memberName: member.name,
      message: `Family dinner in ${notifyMinutesBefore} minutes! Time to wrap up and head to the table.`,
      dinnerTime: targetTime,
    });
    membersNotified.push(member.id);
  }

  // Send conversation topics
  await emitTaskEvent(workspaceId, 'family.dinner.topics', {
    message: 'Tonight\'s conversation starters:',
    topics: suggestedTopics,
  });

  // Store the dinner event
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_dinner',
      date: new Date().toISOString().split('T')[0],
      attendees: membersNotified.length,
      topics: suggestedTopics,
    }),
    salience: 0.6,
    tags: ['family', 'dinner', 'bonding'],
  });

  return { membersNotified, suggestedTopics };
}

// ============================================================================
// GAME NIGHT PLANNING WORKFLOW
// ============================================================================

export interface GameNightInput {
  workspaceId: string;
  preferredDay?: string; // e.g., 'Friday', 'Saturday'
  preferredTime?: string;
  duration?: number; // minutes
}

export async function GameNightWorkflow(input: GameNightInput): Promise<{
  scheduledFor: string;
  gameSuggestions: string[];
  snackIdeas: string[];
}> {
  const {
    workspaceId,
    preferredDay = 'Friday',
    preferredTime = '19:00',
    duration = 120,
  } = input;

  const members = await getFamilyMembers({ workspaceId });

  // Get preferences for games
  const prefs = await getPreferences({ workspaceId, category: 'games' });

  // Default game suggestions based on family size
  const familySize = members.length;
  let gameSuggestions: string[];

  if (familySize <= 3) {
    gameSuggestions = [
      'Catan (strategy)',
      'Ticket to Ride (accessible)',
      'Codenames Duet (cooperative)',
      'Uno (quick rounds)',
    ];
  } else if (familySize <= 5) {
    gameSuggestions = [
      'Codenames (teams)',
      'Telestrations (drawing/guessing)',
      'Exploding Kittens (fast-paced)',
      'The Resistance (social deduction)',
    ];
  } else {
    gameSuggestions = [
      'Werewolf (large group)',
      'Two Rooms and a Boom',
      'Codenames (big teams)',
      'Charades (classic)',
    ];
  }

  // Check if any kids
  const hasKids = members.some((m) => m.role === 'child');
  if (hasKids) {
    gameSuggestions = [
      'Spot It! (ages 6+)',
      'Zingo (ages 4+)',
      'Guess Who? (classic)',
      'Sorry! (family favorite)',
      'Uno (simple rules)',
    ];
  }

  const snackIdeas = [
    'Popcorn (classic game night snack)',
    'Veggie platter with hummus',
    'Mini sandwiches',
    'Fruit skewers',
    'Nachos with toppings',
  ];

  // Calculate next occurrence
  const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const targetDayIndex = daysOfWeek.indexOf(preferredDay);
  const today = new Date();
  let daysUntil = targetDayIndex - today.getDay();
  if (daysUntil <= 0) daysUntil += 7;

  const gameNightDate = new Date(today);
  gameNightDate.setDate(today.getDate() + daysUntil);
  const [hour, minute] = preferredTime.split(':').map(Number);
  gameNightDate.setHours(hour, minute, 0, 0);

  // Create calendar event
  await createFamilyEvent({
    workspaceId,
    title: 'Family Game Night',
    startTime: gameNightDate.toISOString(),
    endTime: new Date(gameNightDate.getTime() + duration * 60 * 1000).toISOString(),
    organizer: members[0]?.id || 'family',
    invitees: members.map((m) => m.id),
    category: 'family',
  });

  // Notify family
  await emitTaskEvent(workspaceId, 'family.gamenight.scheduled', {
    date: gameNightDate.toISOString(),
    gameSuggestions,
    snackIdeas,
    message: `Game night is ${preferredDay} at ${preferredTime}! Who's bringing the snacks?`,
  });

  // Store in memory
  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'game_night_planned',
      scheduledFor: gameNightDate.toISOString(),
      games: gameSuggestions,
    }),
    salience: 0.6,
    tags: ['family', 'gamenight', 'bonding'],
  });

  return {
    scheduledFor: gameNightDate.toISOString(),
    gameSuggestions,
    snackIdeas,
  };
}

// ============================================================================
// WEEKEND ACTIVITY SUGGESTIONS WORKFLOW
// ============================================================================

export interface WeekendActivityInput {
  workspaceId: string;
  budget?: 'free' | 'low' | 'medium' | 'flexible';
  preferIndoor?: boolean;
  weatherDependent?: boolean;
}

export async function WeekendActivityWorkflow(input: WeekendActivityInput): Promise<{
  suggestions: Array<{ activity: string; description: string; effort: string }>;
}> {
  const {
    workspaceId,
    budget = 'flexible',
    preferIndoor = false,
    weatherDependent = true,
  } = input;

  const members = await getFamilyMembers({ workspaceId });
  const hasKids = members.some((m) => m.role === 'child');
  const familySize = members.length;

  // Activity database
  const activities = {
    outdoor_free: [
      { activity: 'Park picnic', description: 'Pack lunch and enjoy nature together', effort: 'low' },
      { activity: 'Neighborhood walk', description: 'Explore new streets in your area', effort: 'low' },
      { activity: 'Backyard camping', description: 'Set up tent and tell stories', effort: 'medium' },
      { activity: 'Nature scavenger hunt', description: 'Create a list and find items together', effort: 'low' },
    ],
    outdoor_paid: [
      { activity: 'Zoo visit', description: 'Educational and fun for all ages', effort: 'medium' },
      { activity: 'Mini golf', description: 'Friendly competition', effort: 'low' },
      { activity: 'Farmers market', description: 'Browse, sample, and shop local', effort: 'low' },
      { activity: 'Bowling', description: 'Indoor/outdoor fun for all skill levels', effort: 'low' },
    ],
    indoor_free: [
      { activity: 'Movie marathon', description: 'Pick a theme and make popcorn', effort: 'low' },
      { activity: 'Cooking together', description: 'Make a family recipe or try something new', effort: 'medium' },
      { activity: 'Board game day', description: 'Tournament-style with prizes', effort: 'low' },
      { activity: 'Arts and crafts', description: 'Use materials you have at home', effort: 'medium' },
      { activity: 'Indoor fort building', description: 'Blankets, pillows, and imagination', effort: 'low' },
    ],
    indoor_paid: [
      { activity: 'Escape room', description: 'Work together to solve puzzles', effort: 'medium' },
      { activity: 'Indoor trampoline park', description: 'Active fun for kids and adults', effort: 'medium' },
      { activity: 'Cooking class', description: 'Learn new skills as a family', effort: 'medium' },
      { activity: 'Movie theater', description: 'Big screen experience', effort: 'low' },
    ],
  };

  let suggestions: Array<{ activity: string; description: string; effort: string }> = [];

  // Select based on preferences
  if (preferIndoor) {
    suggestions = budget === 'free' || budget === 'low'
      ? activities.indoor_free
      : [...activities.indoor_free, ...activities.indoor_paid];
  } else {
    suggestions = budget === 'free' || budget === 'low'
      ? [...activities.outdoor_free, ...activities.indoor_free]
      : [...activities.outdoor_free, ...activities.outdoor_paid, ...activities.indoor_free.slice(0, 2)];
  }

  // Filter for families with young kids
  if (hasKids) {
    suggestions = suggestions.filter((s) =>
      !s.activity.includes('Escape room') // Age-dependent activities
    );
  }

  // Limit to 4 suggestions
  suggestions = suggestions.slice(0, 4);

  await emitTaskEvent(workspaceId, 'family.weekend.suggestions', {
    message: 'Weekend activity ideas for the family:',
    suggestions,
    familySize,
    hasKids,
  });

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'weekend_suggestions',
      date: new Date().toISOString().split('T')[0],
      suggestions: suggestions.map((s) => s.activity),
    }),
    salience: 0.4,
    tags: ['family', 'weekend', 'activities'],
  });

  return { suggestions };
}

// ============================================================================
// GRATITUDE MOMENT WORKFLOW
// ============================================================================

export interface GratitudeMomentInput {
  workspaceId: string;
  frequency?: 'daily' | 'weekly';
  preferredTime?: string;
}

export async function GratitudeMomentWorkflow(input: GratitudeMomentInput): Promise<{
  prompted: boolean;
  prompt: string;
}> {
  const {
    workspaceId,
    frequency = 'daily',
    preferredTime = '19:00',
  } = input;

  const prompts = [
    'What made you smile today?',
    'Who helped you this week? Consider thanking them.',
    'What\'s something you\'re looking forward to?',
    'Share one thing you appreciate about each family member.',
    'What challenge did you overcome recently?',
    'What\'s a simple pleasure you enjoyed today?',
    'Who made a positive difference in your day?',
    'What skill are you proud of developing?',
    'What moment would you want to relive?',
    'What family tradition do you cherish most?',
  ];

  const dayOfYear = Math.floor((Date.now() - new Date(new Date().getFullYear(), 0, 0).getTime()) / 86400000);
  const prompt = prompts[dayOfYear % prompts.length];

  // Calculate when to send
  const [hour, minute] = preferredTime.split(':').map(Number);
  const promptTime = new Date();
  promptTime.setHours(hour, minute, 0, 0);

  const now = new Date();
  const msUntilPrompt = promptTime.getTime() - now.getTime();

  if (msUntilPrompt > 0) {
    await sleep(msUntilPrompt);
  }

  await emitTaskEvent(workspaceId, 'family.gratitude.prompt', {
    message: 'Gratitude moment',
    prompt,
    frequency,
  });

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'gratitude_moment',
      date: new Date().toISOString(),
      prompt,
    }),
    salience: 0.5,
    tags: ['family', 'gratitude', 'wellbeing'],
  });

  return { prompted: true, prompt };
}

// ============================================================================
// ONE-ON-ONE TIME SUGGESTION WORKFLOW
// ============================================================================

export interface OneOnOneTimeInput {
  workspaceId: string;
  parentId: string;
  childId: string;
  durationMinutes?: number;
}

export async function OneOnOneTimeWorkflow(input: OneOnOneTimeInput): Promise<{
  suggestions: string[];
  scheduledFor?: string;
}> {
  const {
    workspaceId,
    parentId,
    childId,
    durationMinutes = 30,
  } = input;

  // Get preferences for the child
  const childPrefs = await getPreferences({ workspaceId, memberId: childId });

  // Activity suggestions based on duration
  const quickActivities = [
    'Read a book together',
    'Play a quick card game',
    'Go for a short walk',
    'Make a snack together',
    'Do a puzzle',
    'Draw or color together',
  ];

  const longerActivities = [
    'Build with blocks/LEGO',
    'Bake cookies together',
    'Work on a craft project',
    'Play a board game',
    'Go to the park',
    'Have a tea party or picnic',
  ];

  const suggestions = durationMinutes <= 30 ? quickActivities : longerActivities;

  await emitTaskEvent(workspaceId, 'family.oneononetime.suggestion', {
    parentId,
    childId,
    message: `Special one-on-one time ideas (${durationMinutes} minutes):`,
    suggestions: suggestions.slice(0, 4),
    duration: durationMinutes,
  });

  await storeMemory({
    workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'one_on_one_suggested',
      parentId,
      childId,
      date: new Date().toISOString(),
    }),
    salience: 0.6,
    tags: ['family', 'bonding', parentId, childId],
  });

  return { suggestions: suggestions.slice(0, 4) };
}

// ============================================================================
// FAMILY TRADITION REMINDER WORKFLOW
// ============================================================================

export interface FamilyTraditionInput {
  workspaceId: string;
  tradition: string;
  frequency: 'weekly' | 'monthly' | 'yearly' | 'custom';
  dayOrDate?: string; // 'Sunday' for weekly, '15' for monthly, 'December 24' for yearly
  description?: string;
}

export async function FamilyTraditionWorkflow(input: FamilyTraditionInput): Promise<{
  reminded: boolean;
  nextOccurrence: string;
}> {
  const {
    workspaceId,
    tradition,
    frequency,
    dayOrDate,
    description,
  } = input;

  const now = new Date();
  let nextOccurrence: Date;

  switch (frequency) {
    case 'weekly': {
      const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const targetDay = daysOfWeek.indexOf(dayOrDate || 'Sunday');
      let daysUntil = targetDay - now.getDay();
      if (daysUntil <= 0) daysUntil += 7;
      nextOccurrence = new Date(now);
      nextOccurrence.setDate(now.getDate() + daysUntil);
      break;
    }
    case 'monthly': {
      const targetDate = parseInt(dayOrDate || '1', 10);
      nextOccurrence = new Date(now.getFullYear(), now.getMonth(), targetDate);
      if (nextOccurrence <= now) {
        nextOccurrence.setMonth(nextOccurrence.getMonth() + 1);
      }
      break;
    }
    case 'yearly': {
      // Parse 'Month Day' format
      const [month, day] = (dayOrDate || 'January 1').split(' ');
      const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
      const monthIndex = months.indexOf(month);
      nextOccurrence = new Date(now.getFullYear(), monthIndex, parseInt(day, 10));
      if (nextOccurrence <= now) {
        nextOccurrence.setFullYear(nextOccurrence.getFullYear() + 1);
      }
      break;
    }
    default:
      nextOccurrence = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // Default: 1 week
  }

  // Calculate days until
  const daysUntil = Math.ceil((nextOccurrence.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));

  // Remind if coming up soon (within 3 days)
  if (daysUntil <= 3) {
    await emitTaskEvent(workspaceId, 'family.tradition.reminder', {
      tradition,
      description: description || `Time for our ${tradition}!`,
      daysUntil,
      nextOccurrence: nextOccurrence.toISOString(),
      message: daysUntil === 0
        ? `Today is ${tradition}!`
        : `${tradition} is coming up in ${daysUntil} day${daysUntil === 1 ? '' : 's'}!`,
    });
  }

  // Store tradition in memory
  await storeMemory({
    workspaceId,
    type: 'semantic',
    content: JSON.stringify({
      type: 'family_tradition',
      tradition,
      frequency,
      dayOrDate,
      description,
    }),
    salience: 0.7,
    tags: ['family', 'tradition'],
  });

  return {
    reminded: daysUntil <= 3,
    nextOccurrence: nextOccurrence.toISOString(),
  };
}
