# Family Bonding Skill

Plan and organize family activities, outings, and quality time experiences.

## Purpose

Help families discover, plan, and execute memorable activities that strengthen family bonds.

## Prerequisites

- LLM API key
- Google Places API (for venue discovery)
- Event APIs (Eventbrite, local events)
- Calendar integration
- Weather API

## Input Parameters

```typescript
interface FamilyBondingInput {
  workspaceId: string;
  action: 'suggest_activities' | 'plan_outing' | 'find_events' | 'schedule_family_time';
  familyProfile: {
    adultCount: number;
    childAges: number[];
    interests: string[];
    mobility?: string;         // Any mobility considerations
    budget?: number;
  };
  preferences?: {
    indoorOutdoor?: 'indoor' | 'outdoor' | 'either';
    duration?: string;         // "2 hours", "half day", "full day"
    distance?: number;         // Max miles from home
    activityLevel?: 'low' | 'medium' | 'high';
  };
  date?: string;
}
```

## Activity Suggestions Sub-Skill

### Suggest Activities

**Risk Level: LOW**

Generate personalized activity suggestions based on family profile.

```typescript
const suggestActivities = async (input: FamilyBondingInput) => {
  // Get weather forecast if date specified
  let weather = null;
  if (input.date) {
    weather = await getWeatherForecast(input.location, input.date);
  }

  const suggestionPrompt = `Suggest 5 family activities for:

Family:
- Adults: ${input.familyProfile.adultCount}
- Children ages: ${input.familyProfile.childAges.join(', ')}
- Interests: ${input.familyProfile.interests.join(', ')}
${input.familyProfile.mobility ? `- Mobility needs: ${input.familyProfile.mobility}` : ''}

Preferences:
- Setting: ${input.preferences?.indoorOutdoor || 'either'}
- Duration: ${input.preferences?.duration || 'flexible'}
- Activity level: ${input.preferences?.activityLevel || 'medium'}
- Budget: ${input.familyProfile.budget ? `$${input.familyProfile.budget}` : 'flexible'}

${weather ? `Weather forecast: ${weather.summary}` : ''}

For each activity, provide:
{
  "activities": [
    {
      "name": "Activity name",
      "description": "What you'll do",
      "ageAppropriate": "Why this works for the kids' ages",
      "estimatedCost": 0,
      "duration": "2 hours",
      "whatToBring": ["items"],
      "tips": ["helpful tips"],
      "weatherDependent": boolean
    }
  ]
}`;

  const suggestions = await llm.complete({ system: suggestionPrompt });

  // Enrich with local venues if applicable
  const enrichedSuggestions = await Promise.all(
    suggestions.activities.map(async activity => {
      const venues = await findVenuesForActivity(activity.name, input.location);
      return { ...activity, nearbyVenues: venues.slice(0, 3) };
    })
  );

  return enrichedSuggestions;
};
```

### Activity Ideas by Age Group

```typescript
const activityIdeasByAge = {
  toddler: [
    { name: "Playground visit", indoor: false, cost: 0 },
    { name: "Children's museum", indoor: true, cost: 15 },
    { name: "Library storytime", indoor: true, cost: 0 },
    { name: "Sensory play at home", indoor: true, cost: 0 }
  ],
  preschool: [
    { name: "Zoo visit", indoor: false, cost: 25 },
    { name: "Arts and crafts", indoor: true, cost: 10 },
    { name: "Nature walk/scavenger hunt", indoor: false, cost: 0 },
    { name: "Baking together", indoor: true, cost: 10 }
  ],
  elementary: [
    { name: "Bowling", indoor: true, cost: 30 },
    { name: "Mini golf", indoor: false, cost: 25 },
    { name: "Board game night", indoor: true, cost: 0 },
    { name: "Bike riding", indoor: false, cost: 0 }
  ],
  preteen: [
    { name: "Escape room", indoor: true, cost: 100 },
    { name: "Hiking", indoor: false, cost: 0 },
    { name: "Movie theater", indoor: true, cost: 50 },
    { name: "Cooking class", indoor: true, cost: 75 }
  ],
  teen: [
    { name: "Laser tag", indoor: true, cost: 60 },
    { name: "Rock climbing", indoor: true, cost: 50 },
    { name: "Concert/show", indoor: true, cost: 100 },
    { name: "Volunteer activity", indoor: false, cost: 0 }
  ]
};
```

## Plan Outing Sub-Skill

### Plan Complete Outing

**Risk Level: LOW**

Create a detailed plan for a family outing.

```typescript
const planOuting = async (input: {
  workspaceId: string;
  activity: Activity;
  venue?: Venue;
  date: string;
  familyProfile: FamilyProfile;
}) => {
  const planPrompt = `Create a detailed outing plan:

Activity: ${input.activity.name}
${input.venue ? `Venue: ${input.venue.name} at ${input.venue.address}` : ''}
Date: ${input.date}
Family: ${input.familyProfile.adultCount} adults, kids ages ${input.familyProfile.childAges.join(', ')}

Generate a comprehensive plan:
{
  "overview": "Brief description",
  "timeline": [
    { "time": "10:00 AM", "activity": "Depart home", "notes": "" }
  ],
  "packingList": {
    "essential": ["items everyone needs"],
    "forKids": ["kid-specific items"],
    "optional": ["nice to have"]
  },
  "meals": {
    "snacks": ["pack these snacks"],
    "lunch": "lunch plan"
  },
  "contingencyPlan": {
    "ifRains": "alternative plan",
    "ifCrowded": "backup venue",
    "emergencyContacts": ["relevant numbers"]
  },
  "budgetBreakdown": {
    "admission": 0,
    "food": 0,
    "parking": 0,
    "extras": 0,
    "total": 0
  },
  "tips": ["helpful tips for this activity"]
}`;

  const plan = await llm.complete({ system: planPrompt });

  // Get venue details if specified
  if (input.venue) {
    plan.venueDetails = {
      hours: input.venue.hours,
      parking: input.venue.parkingInfo,
      accessibility: input.venue.accessibilityInfo,
      website: input.venue.website
    };
  }

  return plan;
};
```

## Find Events Sub-Skill

### Discover Local Events

**Risk Level: LOW**

Find family-friendly events in the area.

```typescript
const findLocalEvents = async (input: {
  workspaceId: string;
  location: string;
  dateRange: { start: string; end: string };
  categories?: string[];
  familyProfile: FamilyProfile;
}) => {
  // Search multiple event sources
  const [eventbriteEvents, localEvents] = await Promise.all([
    eventbrite.search({
      location: input.location,
      startDate: input.dateRange.start,
      endDate: input.dateRange.end,
      categories: ['family', 'kids', ...input.categories || []]
    }),
    localEventService.search({
      location: input.location,
      dateRange: input.dateRange,
      familyFriendly: true
    })
  ]);

  // Combine and filter
  const allEvents = [...eventbriteEvents, ...localEvents];

  // Filter by age appropriateness
  const ageAppropriate = allEvents.filter(event => {
    const minAge = Math.min(...input.familyProfile.childAges);
    const maxAge = Math.max(...input.familyProfile.childAges);
    return (!event.minAge || event.minAge <= minAge) &&
           (!event.maxAge || event.maxAge >= maxAge);
  });

  // Score and rank
  const scoredEvents = ageAppropriate.map(event => ({
    ...event,
    score: calculateEventScore(event, input.familyProfile)
  }));

  return scoredEvents.sort((a, b) => b.score - a.score);
};
```

## Schedule Family Time Sub-Skill

### Block Family Time

**Risk Level: LOW**

Schedule recurring family time on the calendar.

```typescript
const scheduleFamilyTime = async (input: {
  workspaceId: string;
  userId: string;
  type: 'weekly_activity' | 'monthly_outing' | 'daily_dinner';
  schedule: {
    dayOfWeek?: string;
    time: string;
    duration: number;
  };
  activityRotation?: string[];
}) => {
  // Create recurring calendar events
  const recurrence = {
    weekly_activity: 'FREQ=WEEKLY',
    monthly_outing: 'FREQ=MONTHLY',
    daily_dinner: 'FREQ=DAILY'
  };

  const events = [];

  // Create events for next 3 months
  const endDate = new Date();
  endDate.setMonth(endDate.getMonth() + 3);

  await calendar.createRecurringEvent({
    workspaceId: input.workspaceId,
    userId: input.userId,
    title: `Family Time: ${input.type.replace('_', ' ')}`,
    dayOfWeek: input.schedule.dayOfWeek,
    time: input.schedule.time,
    duration: input.schedule.duration,
    recurrence: recurrence[input.type],
    endDate: endDate.toISOString(),
    notes: input.activityRotation ?
      `Activity rotation: ${input.activityRotation.join(', ')}` : undefined
  });

  // Store family time preference in memory
  await memory.store({
    workspaceId: input.workspaceId,
    type: 'procedural',
    content: JSON.stringify({
      type: 'family_time_schedule',
      schedule: input.schedule,
      activityRotation: input.activityRotation
    }),
    tags: ['family', 'schedule', 'recurring']
  });

  return {
    success: true,
    eventsCreated: 12,  // Approximate for 3 months
    nextOccurrence: calculateNextOccurrence(input.schedule)
  };
};
```

## Activity Tracking Sub-Skill

### Log Family Activity

**Risk Level: LOW**

Record completed family activities for memory.

```typescript
const logFamilyActivity = async (input: {
  workspaceId: string;
  activity: string;
  date: string;
  participants: string[];
  highlights?: string;
  photos?: string[];
  rating?: number;
}) => {
  // Store in episodic memory
  await memory.store({
    workspaceId: input.workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'family_activity',
      ...input
    }),
    salience: 0.8,
    tags: ['family', 'activity', 'memory']
  });

  // Update activity preferences based on rating
  if (input.rating) {
    await updateActivityPreferences(input.workspaceId, input.activity, input.rating);
  }

  return { success: true };
};
```

## Output

```typescript
interface FamilyBondingOutput {
  activities?: Activity[];
  plan?: OutingPlan;
  events?: Event[];
  scheduled?: ScheduleResult;
}
```

## Seasonal Activity Ideas

```typescript
const seasonalActivities = {
  spring: [
    "Cherry blossom viewing",
    "Kite flying",
    "Garden planting",
    "Easter egg hunt",
    "Bike ride"
  ],
  summer: [
    "Beach day",
    "Water park",
    "Camping",
    "Outdoor movie",
    "Ice cream tour"
  ],
  fall: [
    "Apple picking",
    "Pumpkin patch",
    "Leaf collecting",
    "Corn maze",
    "Fall festival"
  ],
  winter: [
    "Ice skating",
    "Sledding",
    "Hot cocoa and movie",
    "Indoor trampoline park",
    "Holiday craft making"
  ]
};
```

## Error Handling

| Error | Recovery |
|-------|----------|
| No venues found | Suggest at-home alternatives |
| Event sold out | Add to waitlist, suggest similar |
| Weather forecast bad | Suggest indoor alternatives |
| Budget exceeded | Offer free alternatives |
