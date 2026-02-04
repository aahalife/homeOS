# Mental Load Automation Skill: Atomic Function Breakdown

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Production-Ready Implementation Guide
**Target Platform:** iOS 17.0+, Swift 5.10+

---

## Table of Contents

1. [Skill Overview](#1-skill-overview)
2. [User Stories](#2-user-stories)
3. [Atomic Functions](#3-atomic-functions)
4. [Deterministic Decision Tree](#4-deterministic-decision-tree)
5. [State Machine](#5-state-machine)
6. [Data Structures](#6-data-structures)
7. [Example Scenarios](#7-example-scenarios)
8. [API Integrations](#8-api-integrations)
9. [Test Cases](#9-test-cases)
10. [Error Handling](#10-error-handling)

---

## 1. Skill Overview

### Purpose
The Mental Load Automation skill reduces the invisible burden of household coordination by proactively managing daily briefings, reminders, weekly planning, and decision simplification. It acts as a "second brain" for busy families, tracking tasks so parents don't have to carry them mentally.

### Core Capabilities
- **Morning Briefings**: Daily 7am overview with weather, schedule, priorities
- **Evening Wind-Downs**: 8pm task review, tomorrow prep, reflection
- **Proactive Reminders**: Context-aware nudges for upcoming events and tasks
- **Weekly Planning**: Sunday 6pm comprehensive week-ahead planning
- **Decision Simplification**: Reduces choice paralysis with smart suggestions
- **Task Tracking**: Monitors all family responsibilities across skills

### Design Principles
1. **Anticipatory, Not Reactive**: Propose solutions before being asked
2. **Context-Aware Timing**: Deliver information when it's most useful
3. **Concise Communication**: Respect cognitive bandwidth with brief summaries
4. **Actionable Insights**: Always include next steps, not just information
5. **Gentle Persistence**: Remind without nagging

---

## 2. User Stories

### Primary User: Sarah, 38-year-old coordinating parent

**Story 1: Morning Briefing**
```
As a parent starting my day
I want a quick overview of what's happening today
So that I can mentally prepare and prioritize

Acceptance Criteria:
- Delivered at 7:00 AM (configurable)
- Shows weather, calendar highlights, urgent tasks
- Takes < 30 seconds to read
- Includes actionable suggestions
```

**Story 2: Proactive Reminder**
```
As a parent juggling many tasks
I want to be reminded before things become urgent
So that I don't forget important deadlines

Acceptance Criteria:
- Reminds 24h before events (configurable)
- Includes context (who, what, when, where)
- Suggests preparation steps
- Shows related tasks
```

**Story 3: Evening Wind-Down**
```
As a parent ending a busy day
I want to review what happened and prep for tomorrow
So that I can sleep without mental clutter

Acceptance Criteria:
- Delivered at 8:00 PM (configurable)
- Shows completed tasks (positive reinforcement)
- Lists tomorrow's priorities
- Suggests evening tasks (pack lunches, set out clothes)
```

**Story 4: Weekly Planning**
```
As a parent planning the week ahead
I want a comprehensive overview every Sunday
So that I can coordinate family activities

Acceptance Criteria:
- Delivered Sunday at 6:00 PM
- Shows week's calendar, meals, chores
- Identifies potential conflicts
- Suggests planning actions (grocery shop, schedule appointments)
```

**Story 5: Decision Simplification**
```
As a parent overwhelmed by choices
I want the app to suggest the best option
So that I don't waste mental energy deciding

Acceptance Criteria:
- Analyzes past preferences
- Suggests 1 primary recommendation
- Provides 1-2 alternatives
- Explains reasoning briefly
```

---

## 3. Atomic Functions

All functions are pure, testable, and composable. Each has a single responsibility.

### 3.1 Morning Briefings

#### `generateMorningBriefing(familyId: UUID, date: Date) async throws -> MorningBriefing`
Creates comprehensive morning briefing for the day.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date for briefing (typically today)

**Returns:** `MorningBriefing` object with all components

**Decision Logic:**
1. Fetch weather forecast
2. Load today's calendar events for all family members
3. Identify urgent tasks (due today or overdue)
4. Check for special occasions (birthdays, school events)
5. Suggest morning preparations
6. Format into concise summary

**Swift Signature:**
```swift
func generateMorningBriefing(
    familyId: UUID,
    date: Date
) async throws -> MorningBriefing
```

---

#### `getWeatherSummary(location: CLLocation, date: Date) async throws -> WeatherSummary`
Retrieves weather forecast for location and date.

**Parameters:**
- `location`: Family's location
- `date`: Date for forecast

**Returns:** `WeatherSummary` with temperature, conditions, alerts

**External API:** OpenWeatherMap or Apple WeatherKit

**Swift Signature:**
```swift
func getWeatherSummary(
    location: CLLocation,
    date: Date
) async throws -> WeatherSummary
```

---

#### `getTodaysCalendarHighlights(familyId: UUID, date: Date) async throws -> [CalendarHighlight]`
Extracts key calendar events for the day.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date to check

**Returns:** Array of important calendar events

**Decision Logic:**
- Include all-day events
- Include time-bound events (exclude all-day recurring)
- Prioritize: appointments > school events > social
- Maximum 5 events to avoid overwhelm

**Swift Signature:**
```swift
func getTodaysCalendarHighlights(
    familyId: UUID,
    date: Date
) async throws -> [CalendarHighlight]
```

---

#### `getUrgentTasks(familyId: UUID, date: Date) async throws -> [Task]`
Retrieves tasks requiring immediate attention.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date to check against

**Returns:** Array of urgent tasks

**Criteria for Urgency:**
- Due today
- Overdue
- High priority and due within 24 hours
- Requires preparation time (e.g., packing for trip tomorrow)

**Swift Signature:**
```swift
func getUrgentTasks(
    familyId: UUID,
    date: Date
) async throws -> [Task]
```

---

#### `suggestMorningPreparations(familyId: UUID, todaysEvents: [CalendarEvent]) -> [Suggestion]`
Proposes morning preparation actions based on day's schedule (pure function).

**Parameters:**
- `familyId`: Unique identifier for family
- `todaysEvents`: Calendar events for the day

**Returns:** Array of actionable suggestions

**Examples:**
- "Soccer practice at 4pm → Pack Emma's gear"
- "Rain expected → Bring umbrellas"
- "Parent-teacher conference → Review Emma's recent grades"

**Swift Signature:**
```swift
func suggestMorningPreparations(
    familyId: UUID,
    todaysEvents: [CalendarEvent]
) -> [Suggestion]
```

---

#### `formatMorningBriefing(briefing: MorningBriefing) -> String`
Formats briefing into human-readable text (pure function).

**Parameters:**
- `briefing`: Morning briefing object

**Returns:** Formatted string suitable for display/notification

**Swift Signature:**
```swift
func formatMorningBriefing(briefing: MorningBriefing) -> String
```

---

#### `deliverMorningBriefing(familyId: UUID, briefing: MorningBriefing) async throws -> Bool`
Sends morning briefing via notification or in-app message.

**Parameters:**
- `familyId`: Unique identifier for family
- `briefing`: Briefing to deliver

**Returns:** `true` if successfully delivered

**Delivery Methods:**
- Push notification (summary)
- In-app full briefing
- Optional: voice announcement (if Siri integration enabled)

**Swift Signature:**
```swift
func deliverMorningBriefing(
    familyId: UUID,
    briefing: MorningBriefing
) async throws -> Bool
```

---

### 3.2 Evening Wind-Downs

#### `generateEveningWindDown(familyId: UUID, date: Date) async throws -> EveningWindDown`
Creates comprehensive evening wind-down summary.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date being reviewed (typically today)

**Returns:** `EveningWindDown` object with all components

**Decision Logic:**
1. Review today's completed tasks (positive reinforcement)
2. Identify incomplete tasks (without judgment)
3. Preview tomorrow's schedule
4. Suggest evening preparations
5. Calculate "productivity score" (optional gamification)

**Swift Signature:**
```swift
func generateEveningWindDown(
    familyId: UUID,
    date: Date
) async throws -> EveningWindDown
```

---

#### `getCompletedTasksToday(familyId: UUID, date: Date) async throws -> [Task]`
Retrieves tasks completed today for positive reinforcement.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date to check

**Returns:** Array of completed tasks

**Swift Signature:**
```swift
func getCompletedTasksToday(
    familyId: UUID,
    date: Date
) async throws -> [Task]
```

---

#### `getIncompleteTasksToday(familyId: UUID, date: Date) async throws -> [Task]`
Retrieves tasks that were due today but not completed.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date to check

**Returns:** Array of incomplete tasks

**Swift Signature:**
```swift
func getIncompleteTasksToday(
    familyId: UUID,
    date: Date
) async throws -> [Task]
```

---

#### `getTomorrowsPriorities(familyId: UUID, date: Date) async throws -> [Priority]`
Identifies top priorities for tomorrow.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Tomorrow's date

**Returns:** Array of priorities (max 5)

**Prioritization Logic:**
- Urgent deadlines (appointments, assignments due)
- Meal planning (if no plan exists)
- Chore reminders (if assigned)
- Health tasks (medication refills, checkups)

**Swift Signature:**
```swift
func getTomorrowsPriorities(
    familyId: UUID,
    date: Date
) async throws -> [Priority]
```

---

#### `suggestEveningPreparations(familyId: UUID, tomorrowsEvents: [CalendarEvent]) -> [Suggestion]`
Proposes evening preparation actions (pure function).

**Parameters:**
- `familyId`: Unique identifier for family
- `tomorrowsEvents`: Tomorrow's calendar events

**Returns:** Array of actionable suggestions

**Examples:**
- "Early meeting tomorrow → Lay out clothes tonight"
- "Field trip tomorrow → Pack lunch and permission slip"
- "Soccer practice → Wash uniform"

**Swift Signature:**
```swift
func suggestEveningPreparations(
    familyId: UUID,
    tomorrowsEvents: [CalendarEvent]
) -> [Suggestion]
```

---

#### `calculateProductivityScore(completed: [Task], total: [Task]) -> ProductivityScore`
Calculates optional productivity metric (pure function).

**Parameters:**
- `completed`: Tasks completed today
- `total`: All tasks for today

**Returns:** `ProductivityScore` with percentage and message

**Scoring:**
- 90-100%: "Amazing day! 🎉"
- 70-89%: "Great progress! 💪"
- 50-69%: "Solid work! 👍"
- 0-49%: "Tomorrow's a new day! ☀️"

**Swift Signature:**
```swift
func calculateProductivityScore(
    completed: [Task],
    total: [Task]
) -> ProductivityScore
```

---

### 3.3 Proactive Reminders

#### `generateProactiveReminders(familyId: UUID, currentTime: Date) async throws -> [Reminder]`
Creates context-aware reminders based on upcoming events and tasks.

**Parameters:**
- `familyId`: Unique identifier for family
- `currentTime`: Current timestamp

**Returns:** Array of reminders to deliver now

**Decision Logic:**
1. Check calendar events in next 24-48 hours
2. Check task deadlines
3. Check routine patterns (e.g., weekly meal planning)
4. Filter by user preferences (reminder frequency)
5. Format with actionable context

**Swift Signature:**
```swift
func generateProactiveReminders(
    familyId: UUID,
    currentTime: Date
) async throws -> [Reminder]
```

---

#### `getUpcomingEvents(familyId: UUID, startTime: Date, endTime: Date) async throws -> [CalendarEvent]`
Retrieves calendar events within time window.

**Parameters:**
- `familyId`: Unique identifier for family
- `startTime`: Window start
- `endTime`: Window end

**Returns:** Array of calendar events

**Swift Signature:**
```swift
func getUpcomingEvents(
    familyId: UUID,
    startTime: Date,
    endTime: Date
) async throws -> [CalendarEvent]
```

---

#### `getApproachingDeadlines(familyId: UUID, withinHours: Int) async throws -> [Task]`
Retrieves tasks with deadlines approaching.

**Parameters:**
- `familyId`: Unique identifier for family
- `withinHours`: Time window (e.g., 24, 48)

**Returns:** Array of tasks with approaching deadlines

**Swift Signature:**
```swift
func getApproachingDeadlines(
    familyId: UUID,
    withinHours: Int
) async throws -> [Task]
```

---

#### `createReminderFromEvent(event: CalendarEvent, leadTime: Int) -> Reminder`
Creates reminder from calendar event (pure function).

**Parameters:**
- `event`: Calendar event
- `leadTime`: Hours before event to remind

**Returns:** `Reminder` object

**Swift Signature:**
```swift
func createReminderFromEvent(
    event: CalendarEvent,
    leadTime: Int
) -> Reminder
```

---

#### `shouldSendReminder(reminder: Reminder, familyPreferences: ReminderPreferences) -> Bool`
Determines if reminder should be sent based on preferences (pure function).

**Parameters:**
- `reminder`: Reminder to evaluate
- `familyPreferences`: User's reminder settings

**Returns:** `true` if should send

**Checks:**
- Not in "Do Not Disturb" hours
- Frequency limit not exceeded (max 5 reminders/day)
- Type is enabled (calendar, tasks, meals, etc.)
- Not recently dismissed

**Swift Signature:**
```swift
func shouldSendReminder(
    reminder: Reminder,
    familyPreferences: ReminderPreferences
) -> Bool
```

---

#### `deliverReminder(familyId: UUID, reminder: Reminder) async throws -> Bool`
Sends reminder via notification.

**Parameters:**
- `familyId`: Unique identifier for family
- `reminder`: Reminder to deliver

**Returns:** `true` if successfully delivered

**Swift Signature:**
```swift
func deliverReminder(
    familyId: UUID,
    reminder: Reminder
) async throws -> Bool
```

---

### 3.4 Weekly Planning

#### `generateWeeklyPlan(familyId: UUID, weekStartDate: Date) async throws -> WeeklyPlan`
Creates comprehensive week-ahead plan.

**Parameters:**
- `familyId`: Unique identifier for family
- `weekStartDate`: Monday of target week

**Returns:** `WeeklyPlan` object with all components

**Decision Logic:**
1. Load week's calendar events for all members
2. Check meal plan status (exists or needs creation)
3. Review chore assignments
4. Identify scheduling conflicts
5. Suggest planning actions (grocery shop, schedule appointments)
6. Highlight special events (birthdays, holidays)

**Swift Signature:**
```swift
func generateWeeklyPlan(
    familyId: UUID,
    weekStartDate: Date
) async throws -> WeeklyPlan
```

---

#### `getWeeksCalendar(familyId: UUID, weekStartDate: Date) async throws -> [CalendarEvent]`
Retrieves all calendar events for the week.

**Parameters:**
- `familyId`: Unique identifier for family
- `weekStartDate`: Monday of target week

**Returns:** Array of calendar events (Monday-Sunday)

**Swift Signature:**
```swift
func getWeeksCalendar(
    familyId: UUID,
    weekStartDate: Date
) async throws -> [CalendarEvent]
```

---

#### `checkWeeklyMealPlan(familyId: UUID, weekStartDate: Date) async throws -> MealPlanStatus`
Checks if meal plan exists for the week.

**Parameters:**
- `familyId`: Unique identifier for family
- `weekStartDate`: Monday of target week

**Returns:** `MealPlanStatus` (exists, partial, missing)

**Swift Signature:**
```swift
func checkWeeklyMealPlan(
    familyId: UUID,
    weekStartDate: Date
) async throws -> MealPlanStatus
```

---

#### `identifySchedulingConflicts(events: [CalendarEvent]) -> [SchedulingConflict]`
Detects potential conflicts in week's schedule (pure function).

**Parameters:**
- `events`: Week's calendar events

**Returns:** Array of identified conflicts

**Conflict Types:**
- Overlapping events for same person
- Back-to-back events at distant locations
- Overcommitment (too many events per day)

**Swift Signature:**
```swift
func identifySchedulingConflicts(
    events: [CalendarEvent]
) -> [SchedulingConflict]
```

---

#### `suggestWeeklyActions(familyId: UUID, weekPlan: WeeklyPlan) async -> [Suggestion]`
Proposes planning actions for the week.

**Parameters:**
- `familyId`: Unique identifier for family
- `weekPlan`: Week plan object

**Returns:** Array of actionable suggestions

**Examples:**
- "No meal plan for this week → Plan meals"
- "Grocery list ready → Schedule shopping trip"
- "3 doctor appointments → Verify insurance coverage"

**Swift Signature:**
```swift
func suggestWeeklyActions(
    familyId: UUID,
    weekPlan: WeeklyPlan
) async -> [Suggestion]
```

---

#### `formatWeeklyPlan(plan: WeeklyPlan) -> String`
Formats weekly plan into readable summary (pure function).

**Parameters:**
- `plan`: Weekly plan object

**Returns:** Formatted string

**Swift Signature:**
```swift
func formatWeeklyPlan(plan: WeeklyPlan) -> String
```

---

### 3.5 Decision Simplification

#### `suggestBestOption<T>(options: [T], criteria: DecisionCriteria, history: [T]) -> DecisionRecommendation<T>`
Analyzes options and recommends best choice (pure function, generic).

**Parameters:**
- `options`: Array of available choices
- `criteria`: Decision criteria (cost, time, preference, etc.)
- `history`: Past choices for pattern detection

**Returns:** `DecisionRecommendation` with primary + alternatives

**Decision Algorithm:**
1. Score each option against criteria
2. Apply preference learning from history
3. Rank by total score
4. Return top option + 1-2 runner-ups

**Swift Signature:**
```swift
func suggestBestOption<T>(
    options: [T],
    criteria: DecisionCriteria,
    history: [T]
) -> DecisionRecommendation<T>
```

---

#### `analyzePastChoices<T>(history: [T]) -> PreferencePattern<T>`
Detects patterns in historical choices (pure function).

**Parameters:**
- `history`: Array of past choices

**Returns:** `PreferencePattern` with insights

**Pattern Detection:**
- Frequency (most common choices)
- Timing (preferred days/times)
- Sequencing (rotation patterns)
- Rejection (avoided choices)

**Swift Signature:**
```swift
func analyzePastChoices<T>(history: [T]) -> PreferencePattern<T>
```

---

#### `simplifyMealDecision(familyId: UUID, date: Date) async throws -> MealRecommendation`
Specific decision simplifier for meal planning.

**Parameters:**
- `familyId`: Unique identifier for family
- `date`: Date for meal

**Returns:** `MealRecommendation` with primary suggestion + alternatives

**Decision Logic:**
1. Check meal history (avoid recent repeats)
2. Check pantry inventory (prefer using existing ingredients)
3. Check time constraints (weekday = quick meals)
4. Apply dietary restrictions
5. Rank by preference score

**Swift Signature:**
```swift
func simplifyMealDecision(
    familyId: UUID,
    date: Date
) async throws -> MealRecommendation
```

---

#### `simplifyServiceProviderDecision(familyId: UUID, serviceType: ServiceType) async throws -> ProviderRecommendation`
Specific decision simplifier for choosing contractors.

**Parameters:**
- `familyId`: Unique identifier for family
- `serviceType`: Type of service needed (plumber, electrician, etc.)

**Returns:** `ProviderRecommendation` with primary suggestion + alternatives

**Decision Logic:**
1. Check past providers (prefer known good experiences)
2. Load ratings and reviews
3. Check availability
4. Estimate cost
5. Rank by reliability + cost balance

**Swift Signature:**
```swift
func simplifyServiceProviderDecision(
    familyId: UUID,
    serviceType: ServiceType
) async throws -> ProviderRecommendation
```

---

### 3.6 Task Tracking

#### `getAllActiveTasks(familyId: UUID) async throws -> [Task]`
Retrieves all active tasks across all skills.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** Array of active tasks

**Sources:**
- Chores (family coordination)
- Homework assignments (education)
- Medication reminders (healthcare)
- Meal planning (meals)
- Home maintenance (repairs)

**Swift Signature:**
```swift
func getAllActiveTasks(familyId: UUID) async throws -> [Task]
```

---

#### `categorizeTasksByUrgency(tasks: [Task], currentDate: Date) -> TaskUrgencyBreakdown`
Organizes tasks by urgency level (pure function).

**Parameters:**
- `tasks`: Array of tasks
- `currentDate`: Reference date

**Returns:** `TaskUrgencyBreakdown` with tasks grouped by urgency

**Categories:**
- Overdue (past due date)
- Due today
- Due this week
- Due later
- No deadline

**Swift Signature:**
```swift
func categorizeTasksByUrgency(
    tasks: [Task],
    currentDate: Date
) -> TaskUrgencyBreakdown
```

---

#### `prioritizeTasks(tasks: [Task]) -> [Task]`
Ranks tasks by importance and urgency (pure function).

**Parameters:**
- `tasks`: Array of tasks to prioritize

**Returns:** Sorted array (highest priority first)

**Eisenhower Matrix:**
- Urgent + Important = Do first
- Important + Not urgent = Schedule
- Urgent + Not important = Delegate
- Not urgent + Not important = Eliminate

**Swift Signature:**
```swift
func prioritizeTasks(tasks: [Task]) -> [Task]
```

---

#### `trackTaskCompletion(taskId: UUID, completedAt: Date) async throws -> Bool`
Records task completion.

**Parameters:**
- `taskId`: Task being completed
- `completedAt`: Completion timestamp

**Returns:** `true` if successfully tracked

**Swift Signature:**
```swift
func trackTaskCompletion(
    taskId: UUID,
    completedAt: Date
) async throws -> Bool
```

---

#### `generateTaskInsights(familyId: UUID, timeframe: Timeframe) async throws -> TaskInsights`
Analyzes task completion patterns over time.

**Parameters:**
- `familyId`: Unique identifier for family
- `timeframe`: Period to analyze (week, month, year)

**Returns:** `TaskInsights` with completion rates, trends, bottlenecks

**Swift Signature:**
```swift
func generateTaskInsights(
    familyId: UUID,
    timeframe: Timeframe
) async throws -> TaskInsights
```

---

### 3.7 Utility Functions

#### `getOptimalDeliveryTime(briefingType: BriefingType, preferences: UserPreferences) -> Date`
Determines best time to deliver briefing (pure function).

**Parameters:**
- `briefingType`: Type of briefing (morning, evening, weekly)
- `preferences`: User's timing preferences

**Returns:** Optimal delivery timestamp

**Defaults:**
- Morning: 7:00 AM
- Evening: 8:00 PM
- Weekly: Sunday 6:00 PM

**Swift Signature:**
```swift
func getOptimalDeliveryTime(
    briefingType: BriefingType,
    preferences: UserPreferences
) -> Date
```

---

#### `formatTaskList(tasks: [Task], maxItems: Int) -> String`
Formats task list for display (pure function).

**Parameters:**
- `tasks`: Array of tasks
- `maxItems`: Maximum tasks to show

**Returns:** Formatted string

**Swift Signature:**
```swift
func formatTaskList(tasks: [Task], maxItems: Int) -> String
```

---

#### `generateEncouragingMessage(completionRate: Double) -> String`
Creates positive reinforcement message (pure function).

**Parameters:**
- `completionRate`: Task completion percentage (0-1)

**Returns:** Encouraging message

**Swift Signature:**
```swift
func generateEncouragingMessage(completionRate: Double) -> String
```

---

## 4. Deterministic Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│          Automated Mental Load Management System            │
│                   (Background Service)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │ Scheduled Trigger      │
            │ - 7:00 AM (morning)    │
            │ - 8:00 PM (evening)    │
            │ - Sun 6PM (weekly)     │
            │ - Hourly (reminders)   │
            └────────┬───────────────┘
                     │
        ┌────────────┼────────────┬────────────┐
        │            │            │            │
        ▼            ▼            ▼            ▼
    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
    │Morning │  │Evening │  │Weekly  │  │Remind  │
    │Brief   │  │Wind    │  │Plan    │  │Check   │
    └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘
        │           │           │           │
        ▼           ▼           ▼           ▼

┌──────────────────────────────────────────────────────────────┐
│                 MORNING BRIEFING FLOW                        │
│                    (7:00 AM Daily)                           │
│                                                              │
│ Step 1: Check if briefing enabled for family                │
│   IF disabled: SKIP                                          │
│                                                              │
│ Step 2: Load family profile and location                    │
│                                                              │
│ Step 3: Fetch weather forecast                              │
│   API call: getWeatherSummary(location, today)              │
│   Extract: temperature, conditions, precipitation           │
│   IF severe weather alert: FLAG as high priority            │
│                                                              │
│ Step 4: Load today's calendar for all members               │
│   Get calendar events for today (12:00 AM - 11:59 PM)       │
│   Filter to highlights:                                      │
│     - All appointments                                       │
│     - School events                                          │
│     - Important meetings                                     │
│     - Social commitments                                     │
│   Limit to top 5 events                                      │
│                                                              │
│ Step 5: Identify urgent tasks                               │
│   Query all active tasks across skills:                      │
│     - Chores due today                                       │
│     - Homework due today                                     │
│     - Medication reminders for today                         │
│     - Overdue tasks                                          │
│   Prioritize by urgency score                                │
│                                                              │
│ Step 6: Check for special occasions                         │
│   - Birthdays today                                          │
│   - School picture day                                       │
│   - Field trips                                              │
│   - Holidays                                                 │
│                                                              │
│ Step 7: Generate preparation suggestions                    │
│   Algorithm:                                                 │
│   FOR each calendar event today:                             │
│     IF event.type == "soccer practice":                      │
│       suggestions.add("Pack Emma's soccer gear")             │
│     IF event.type == "doctor":                               │
│       suggestions.add("Bring insurance card")                │
│     IF event.location != home AND travel_time > 20min:       │
│       suggestions.add("Leave early for traffic")             │
│   IF weather.rain:                                           │
│     suggestions.add("Bring umbrellas")                       │
│   IF weather.temp < 40:                                      │
│     suggestions.add("Bundle up kids")                        │
│                                                              │
│ Step 8: Format briefing                                     │
│   Template:                                                  │
│   "Good morning! Here's your day:                            │
│                                                              │
│   🌤️ Weather: [condition], [temp]                           │
│   [weather alert if any]                                     │
│                                                              │
│   📅 Today's Schedule:                                       │
│   • [time] - [event] ([who])                                │
│   • [time] - [event] ([who])                                │
│   [... up to 5 events]                                       │
│                                                              │
│   ✅ Priorities:                                             │
│   • [urgent task 1]                                          │
│   • [urgent task 2]                                          │
│   [... up to 3 tasks]                                        │
│                                                              │
│   💡 Suggestions:                                            │
│   • [suggestion 1]                                           │
│   • [suggestion 2]                                           │
│   "                                                          │
│                                                              │
│ Step 9: Deliver briefing                                    │
│   - Send push notification (summary)                         │
│   - Store full briefing in app                               │
│   - Optional: TTS voice announcement                         │
│                                                              │
│ Step 10: Log delivery                                       │
│   - Track engagement metrics                                 │
│   - Update last briefing timestamp                           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 EVENING WIND-DOWN FLOW                       │
│                    (8:00 PM Daily)                           │
│                                                              │
│ Step 1: Check if wind-down enabled for family               │
│   IF disabled: SKIP                                          │
│                                                              │
│ Step 2: Review today's accomplishments                      │
│   Query completed tasks from today:                          │
│     - Completed chores                                       │
│     - Finished homework                                      │
│     - Attended appointments                                  │
│     - Meals cooked                                           │
│   Sort by completion time                                    │
│                                                              │
│ Step 3: Identify incomplete tasks                           │
│   Query tasks that were due today but not completed:         │
│     - Missed chores                                          │
│     - Overdue homework                                       │
│     - Skipped medication                                     │
│   Calculate completion rate                                  │
│                                                              │
│ Step 4: Load tomorrow's schedule                            │
│   Get calendar events for tomorrow                           │
│   Identify top 3 priorities:                                 │
│     - Early morning events (before 9am)                      │
│     - Appointments                                           │
│     - Deadlines                                              │
│                                                              │
│ Step 5: Generate evening prep suggestions                   │
│   Algorithm:                                                 │
│   FOR each tomorrow event:                                   │
│     IF event.time < 9:00 AM:                                 │
│       suggestions.add("Lay out clothes tonight")             │
│     IF event.type == "field trip":                           │
│       suggestions.add("Pack lunch tonight")                  │
│     IF event.type == "test":                                 │
│       suggestions.add("Review study materials")              │
│   IF no meal plan for tomorrow:                              │
│     suggestions.add("Decide tomorrow's dinner")              │
│                                                              │
│ Step 6: Calculate productivity score (optional)             │
│   score = completed_tasks / total_tasks_due                  │
│   IF score >= 0.9: message = "Amazing day! 🎉"              │
│   ELIF score >= 0.7: message = "Great progress! 💪"         │
│   ELIF score >= 0.5: message = "Solid work! 👍"             │
│   ELSE: message = "Tomorrow's a new day! ☀️"                 │
│                                                              │
│ Step 7: Format wind-down                                    │
│   Template:                                                  │
│   "Good evening! Here's how today went:                      │
│                                                              │
│   ✅ Completed ([score]%):                                   │
│   • [completed task 1]                                       │
│   • [completed task 2]                                       │
│   [... up to 5 tasks]                                        │
│                                                              │
│   ⏰ Tomorrow's Priorities:                                  │
│   • [time] - [event/task]                                    │
│   • [time] - [event/task]                                    │
│   [... up to 3 items]                                        │
│                                                              │
│   💡 Tonight:                                                │
│   • [evening prep suggestion 1]                              │
│   • [evening prep suggestion 2]                              │
│                                                              │
│   [encouraging message]                                      │
│   "                                                          │
│                                                              │
│ Step 8: Deliver wind-down                                   │
│   - Send push notification                                   │
│   - Store in app                                             │
│   - Log delivery                                             │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 WEEKLY PLANNING FLOW                         │
│                  (Sunday 6:00 PM)                            │
│                                                              │
│ Step 1: Determine week range                                │
│   week_start = next Monday                                   │
│   week_end = following Sunday                                │
│                                                              │
│ Step 2: Load week's calendar for all members                │
│   Get all events from week_start to week_end                 │
│   Group by day                                               │
│   Count events per member per day                            │
│                                                              │
│ Step 3: Identify scheduling conflicts                       │
│   FOR each member:                                           │
│     FOR each day:                                            │
│       Check for overlapping events                           │
│       Check for back-to-back distant locations               │
│       Flag if > 3 events in one day (overcommitment)        │
│                                                              │
│ Step 4: Check meal plan status                              │
│   Query: does meal plan exist for this week?                 │
│   IF yes: status = "✅ Meal plan ready"                      │
│   IF partial: status = "⚠️ Only X days planned"             │
│   IF no: status = "❌ No meal plan - create one"            │
│                                                              │
│ Step 5: Review chore assignments                            │
│   Get all chores due this week                               │
│   Group by assignee                                          │
│   Check if evenly distributed                                │
│                                                              │
│ Step 6: Identify special events                             │
│   - Birthdays this week                                      │
│   - School holidays                                          │
│   - Travel/vacations                                         │
│   - Recurring appointments                                   │
│                                                              │
│ Step 7: Generate planning suggestions                       │
│   Algorithm:                                                 │
│   IF no meal plan:                                           │
│     suggestions.add("Plan this week's meals")                │
│   IF meal plan AND no grocery trip scheduled:                │
│     suggestions.add("Schedule grocery shopping")             │
│   IF > 2 doctor appointments:                                │
│     suggestions.add("Verify insurance coverage")             │
│   IF birthday coming:                                        │
│     suggestions.add("Buy gift for [name]")                   │
│   IF conflicts detected:                                     │
│     suggestions.add("Resolve scheduling conflicts")          │
│                                                              │
│ Step 8: Format weekly plan                                  │
│   Template:                                                  │
│   "Your week ahead (Mon-Sun):                                │
│                                                              │
│   📅 This Week:                                              │
│   Monday: [X events]                                         │
│     • [event 1]                                              │
│     • [event 2]                                              │
│   Tuesday: [X events]                                        │
│   ... [for each day]                                         │
│                                                              │
│   🍽️ Meals: [status]                                        │
│                                                              │
│   🧹 Chores: [X assigned]                                    │
│                                                              │
│   ⚠️ Conflicts: [X detected]                                │
│   [list conflicts if any]                                    │
│                                                              │
│   📝 Action Items:                                           │
│   • [suggestion 1]                                           │
│   • [suggestion 2]                                           │
│   • [suggestion 3]                                           │
│   "                                                          │
│                                                              │
│ Step 9: Deliver weekly plan                                 │
│   - Send push notification                                   │
│   - Store full plan in app                                   │
│   - Create interactive checklist                             │
│                                                              │
│ Step 10: Set up week-long monitoring                        │
│   - Schedule daily check-ins                                 │
│   - Enable proactive reminders                               │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 PROACTIVE REMINDER FLOW                      │
│                   (Hourly Check)                             │
│                                                              │
│ Step 1: Get current timestamp                               │
│   now = Date()                                               │
│                                                              │
│ Step 2: Load reminder preferences                           │
│   - Enabled reminder types (calendar, tasks, meals)          │
│   - Do Not Disturb hours (default: 10pm-7am)                │
│   - Max reminders per day (default: 5)                       │
│   - Lead time preferences (24h for appointments, etc.)       │
│                                                              │
│ Step 3: Check if in Do Not Disturb window                   │
│   IF now.hour < 7 OR now.hour >= 22:                        │
│     SKIP (don't send reminders during sleep)                 │
│                                                              │
│ Step 4: Query upcoming events (next 24-48h)                 │
│   events = getUpcomingEvents(                                │
│     startTime: now,                                          │
│     endTime: now + 48 hours                                  │
│   )                                                          │
│                                                              │
│ Step 5: Create reminders from events                        │
│   reminders = []                                             │
│   FOR each event in events:                                  │
│     time_until_event = event.startTime - now                 │
│                                                              │
│     # 24-hour reminder for appointments                      │
│     IF event.type IN [doctor, dentist] AND                   │
│        time_until_event ~= 24 hours:                         │
│       reminders.add(Reminder(                                │
│         type: .appointment,                                  │
│         message: "[Who] has [event] tomorrow at [time]",     │
│         action: "Verify insurance and location"              │
│       ))                                                     │
│                                                              │
│     # 2-hour reminder for time-sensitive events              │
│     IF time_until_event ~= 2 hours:                          │
│       reminders.add(Reminder(                                │
│         type: .upcoming,                                     │
│         message: "[Event] starts at [time]",                 │
│         action: "Leave in [X] minutes"                       │
│       ))                                                     │
│                                                              │
│ Step 6: Query approaching task deadlines                    │
│   deadlines = getApproachingDeadlines(withinHours: 24)       │
│   FOR each task in deadlines:                                │
│     reminders.add(Reminder(                                  │
│       type: .deadline,                                       │
│       message: "[Task] due [when]",                          │
│       action: "Complete now to avoid late penalty"           │
│     ))                                                       │
│                                                              │
│ Step 7: Check routine patterns                              │
│   # Meal planning reminder (if no plan for this week)        │
│   IF today == Sunday AND no_meal_plan_for_week:              │
│     reminders.add(Reminder(                                  │
│       type: .routine,                                        │
│       message: "No meal plan for this week yet",             │
│       action: "Plan now for stress-free week"                │
│     ))                                                       │
│                                                              │
│   # Grocery shopping reminder (if list ready but no trip)    │
│   IF grocery_list_exists AND no_shopping_scheduled:          │
│     reminders.add(Reminder(                                  │
│       type: .routine,                                        │
│       message: "Grocery list is ready",                      │
│       action: "Schedule shopping trip"                       │
│     ))                                                       │
│                                                              │
│ Step 8: Filter and prioritize reminders                     │
│   # Check daily limit                                        │
│   reminders_sent_today = countRemindersSentToday()           │
│   IF reminders_sent_today >= 5:                              │
│     SKIP (max limit reached)                                 │
│                                                              │
│   # Remove recently dismissed reminders                      │
│   reminders = reminders.filter(not_dismissed_in_last_hour)   │
│                                                              │
│   # Prioritize by urgency                                    │
│   reminders.sort_by_urgency()                                │
│                                                              │
│ Step 9: Deliver reminders                                   │
│   FOR each reminder in reminders.take(remaining_daily_limit):│
│     deliverReminder(familyId, reminder)                      │
│     logReminderDelivery(reminder)                            │
│                                                              │
│ Step 10: Schedule next check                                │
│   - Set timer for next hourly check                          │
│   - Update monitoring state                                  │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                 DECISION SIMPLIFICATION                      │
│                (On-Demand, User Triggered)                   │
│                                                              │
│ User: "What should we have for dinner tonight?"              │
│                                                              │
│ Step 1: Parse decision request                              │
│   Type: meal_decision                                        │
│   Context: tonight, dinner                                   │
│                                                              │
│ Step 2: Load relevant data                                  │
│   - Recent meal history (last 14 days)                       │
│   - Pantry inventory                                         │
│   - Dietary restrictions                                     │
│   - Today's schedule (check if busy evening)                │
│   - Weather (comfort food if cold/rainy)                     │
│                                                              │
│ Step 3: Determine decision criteria                         │
│   criteria = DecisionCriteria(                               │
│     time_available: 30 min (default weekday),                │
│     prefer_pantry_items: true,                               │
│     avoid_recent: last 7 days,                               │
│     dietary: family.restrictions,                            │
│     weather_appropriate: true                                │
│   )                                                          │
│                                                              │
│ Step 4: Search candidate meals                              │
│   candidates = searchRecipes(                                │
│     maxPrepTime: 30,                                         │
│     dietaryRestrictions: criteria.dietary,                   │
│     excludeRecipeIds: recent_meals.ids                       │
│   )                                                          │
│                                                              │
│ Step 5: Score each candidate                                │
│   FOR each recipe in candidates:                             │
│     score = 0                                                │
│                                                              │
│     # Pantry ingredient match                                │
│     pantry_match = checkPantryForRecipe(recipe)              │
│     IF pantry_match >= 60%:                                  │
│       score += 10                                            │
│                                                              │
│     # Past preference                                        │
│     past_rating = getRecipeRating(recipe)                    │
│     IF past_rating >= 4:                                     │
│       score += 8                                             │
│                                                              │
│     # Prep time bonus (faster = better on busy nights)       │
│     IF recipe.prepTime <= 20:                                │
│       score += 5                                             │
│                                                              │
│     # Weather appropriateness                                │
│     IF weather.temp < 50 AND recipe.isComfortFood:           │
│       score += 3                                             │
│                                                              │
│     # Protein rotation                                       │
│     yesterday_protein = meal_history.yesterday.protein       │
│     IF recipe.protein != yesterday_protein:                  │
│       score += 5                                             │
│                                                              │
│     recipe.score = score                                     │
│                                                              │
│ Step 6: Select top options                                  │
│   candidates.sort_by_score(descending)                       │
│   primary = candidates[0]                                    │
│   alternatives = candidates[1..2]                            │
│                                                              │
│ Step 7: Format recommendation                               │
│   response = "I recommend: [primary.name]                    │
│                                                              │
│   Why: [reasoning]                                           │
│   - Uses ingredients you have ([pantry_match]%)              │
│   - Quick to make ([prep_time] min)                          │
│   - Family rated it [rating] stars                           │
│                                                              │
│   Alternatives:                                              │
│   • [alt1.name] - [alt1.reason]                              │
│   • [alt2.name] - [alt2.reason]                              │
│   "                                                          │
│                                                              │
│ Step 8: Present with action buttons                         │
│   - [Cook This] → Start recipe instructions                  │
│   - [Show Alternatives] → Display full list                  │
│   - [Something Else] → Re-search with different criteria     │
│                                                              │
│ Step 9: Track choice                                        │
│   IF user selects primary:                                   │
│     logDecision(type: meal, choice: primary, accepted: true) │
│     # Reinforces recommendation algorithm                    │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. State Machine

### States

```
┌─────────────┐
│    IDLE     │ ◄─────────────────────┐
└──────┬──────┘                       │
       │                              │
       │ Scheduled trigger            │
       ▼                              │
┌─────────────────────┐               │
│ LOADING_CONTEXT     │               │
│ - Load family data  │               │
│ - Check preferences │               │
│ - Determine type    │               │
└──────┬──────────────┘               │
       │                              │
       ├──┬──┬──┬──┐                  │
       │  │  │  │  │                  │
       ▼  ▼  ▼  ▼  ▼                  │
    ┌──┐┌──┐┌──┐┌──┐┌──┐             │
    │Mo││Ev││We││Re││De│             │
    │rn││en││ek││mi││ci│             │
    │  ││  ││ly││nd││sn│             │
    └┬─┘└┬─┘└┬─┘└┬─┘└┬─┘             │
     │   │   │   │   │               │
     ▼   ▼   ▼   ▼   ▼               │
┌─────────────────────┐               │
│ GATHERING_DATA      │               │
│ - Fetch calendar    │               │
│ - Get tasks         │               │
│ - Check weather     │               │
│ - Load history      │               │
└──────┬──────────────┘               │
       │                              │
       ▼                              │
┌─────────────────────┐               │
│ ANALYZING           │               │
│ - Detect patterns   │               │
│ - Identify urgency  │               │
│ - Generate insights │               │
└──────┬──────────────┘               │
       │                              │
       ▼                              │
┌─────────────────────┐               │
│ GENERATING_CONTENT  │               │
│ - Format briefing   │               │
│ - Create suggestions│               │
│ - Prepare reminders │               │
└──────┬──────────────┘               │
       │                              │
       ▼                              │
┌─────────────────────┐               │
│ DELIVERING          │               │
│ - Send notification │               │
│ - Store in app      │               │
│ - Log delivery      │               │
└──────┬──────────────┘               │
       │                              │
       │ [Complete]                   │
       ▼                              │
┌─────────────────────┐               │
│ MONITORING_RESPONSE │               │
│ - Track engagement  │               │
│ - Log interactions  │               │
└──────┬──────────────┘               │
       │                              │
       └──────────────────────────────┘
```

### State Transitions (Swift Enum)

```swift
enum MentalLoadState: Equatable {
    case idle
    case loadingContext(familyId: UUID, triggerType: TriggerType)
    case gatheringData(dataTypes: [DataType])
    case analyzing(context: AnalysisContext)
    case generatingContent(briefingType: BriefingType)
    case delivering(content: DeliverableContent)
    case monitoringResponse(deliveryId: UUID)
    case error(MentalLoadError)
}

enum TriggerType {
    case scheduledMorning
    case scheduledEvening
    case scheduledWeekly
    case hourlyReminderCheck
    case userRequest
}

enum DataType {
    case calendar
    case tasks
    case weather
    case mealPlan
    case history
}

enum BriefingType {
    case morning
    case evening
    case weekly
    case reminder
    case decision
}
```

---

## 6. Data Structures

### Core Models

```swift
// MARK: - Morning Briefing

struct MorningBriefing: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var date: Date
    var weather: WeatherSummary
    var calendarHighlights: [CalendarHighlight]
    var urgentTasks: [Task]
    var specialOccasions: [SpecialOccasion]
    var suggestions: [Suggestion]
    var createdAt: Date
    var deliveredAt: Date?
}

struct WeatherSummary: Codable {
    var location: String
    var temperature: Int // Fahrenheit
    var feelsLike: Int
    var condition: WeatherCondition
    var precipitation: Int // Percent chance
    var alerts: [WeatherAlert]
    var highTemp: Int
    var lowTemp: Int
}

enum WeatherCondition: String, Codable {
    case sunny, cloudy, rainy, snowy, stormy, foggy
}

struct WeatherAlert: Codable, Identifiable {
    let id: UUID
    var type: AlertType
    var severity: AlertSeverity
    var message: String
}

enum AlertType: String, Codable {
    case severeThunderstorm, tornado, flood, winter, heat, wind
}

enum AlertSeverity: String, Codable {
    case warning, watch, advisory
}

struct CalendarHighlight: Codable, Identifiable {
    let id: UUID
    var event: CalendarEvent
    var importance: ImportanceLevel
    var timeUntil: TimeInterval
}

enum ImportanceLevel: String, Codable {
    case low, medium, high, critical
}

struct SpecialOccasion: Codable, Identifiable {
    let id: UUID
    var type: OccasionType
    var title: String
    var date: Date
    var relatedMember: UUID?
}

enum OccasionType: String, Codable {
    case birthday, holiday, schoolEvent, anniversary, fieldTrip
}

struct Suggestion: Codable, Identifiable {
    let id: UUID
    var category: SuggestionCategory
    var text: String
    var priority: Int
    var isActionable: Bool
    var relatedEvent: UUID?
}

enum SuggestionCategory: String, Codable {
    case preparation, reminder, warning, recommendation
}

// MARK: - Evening Wind-Down

struct EveningWindDown: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var date: Date
    var completedTasks: [Task]
    var incompleteTasks: [Task]
    var tomorrowsPriorities: [Priority]
    var eveningSuggestions: [Suggestion]
    var productivityScore: ProductivityScore?
    var encouragingMessage: String
    var createdAt: Date
    var deliveredAt: Date?
}

struct ProductivityScore: Codable {
    var percentage: Double
    var completedCount: Int
    var totalCount: Int
    var message: String
    var emoji: String
}

struct Priority: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var dueTime: Date?
    var category: PriorityCategory
    var urgency: UrgencyLevel
}

enum PriorityCategory: String, Codable {
    case appointment, deadline, preparation, routine
}

enum UrgencyLevel: String, Codable {
    case low, medium, high, critical
}

// MARK: - Weekly Plan

struct WeeklyPlan: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var dailySummaries: [DailySummary]
    var mealPlanStatus: MealPlanStatus
    var choresSummary: ChoresSummary
    var schedulingConflicts: [SchedulingConflict]
    var actionItems: [Suggestion]
    var createdAt: Date
    var deliveredAt: Date?
}

struct DailySummary: Codable, Identifiable {
    let id: UUID
    var date: Date
    var dayOfWeek: String
    var events: [CalendarEvent]
    var eventCount: Int
    var hasConflicts: Bool
}

enum MealPlanStatus: String, Codable {
    case complete
    case partial
    case missing

    var emoji: String {
        switch self {
        case .complete: return "✅"
        case .partial: return "⚠️"
        case .missing: return "❌"
        }
    }
}

struct ChoresSummary: Codable {
    var totalAssigned: Int
    var byMember: [UUID: Int]
    var upcomingDue: [ChoreTask]
}

struct SchedulingConflict: Codable, Identifiable {
    let id: UUID
    var type: ConflictType
    var events: [CalendarEvent]
    var affectedMembers: [UUID]
    var severity: ConflictSeverity
    var suggestedResolution: String?
}

enum ConflictType: String, Codable {
    case overlap, travelTime, overcommitment
}

enum ConflictSeverity: String, Codable {
    case low, medium, high
}

// MARK: - Reminders

struct Reminder: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var type: ReminderType
    var title: String
    var message: String
    var actionSuggestion: String?
    var priority: ReminderPriority
    var triggerTime: Date
    var relatedEvent: UUID?
    var relatedTask: UUID?
    var delivered: Bool
    var dismissed: Bool
    var dismissedAt: Date?
}

enum ReminderType: String, Codable {
    case appointment, deadline, routine, preparation, custom
}

enum ReminderPriority: String, Codable {
    case low, normal, high, urgent
}

struct ReminderPreferences: Codable {
    var enabled: Bool
    var doNotDisturbStart: Int // Hour (24-hour format)
    var doNotDisturbEnd: Int // Hour
    var maxPerDay: Int
    var enabledTypes: [ReminderType]
    var leadTimes: [ReminderType: Int] // Hours before event
}

// MARK: - Tasks

struct Task: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var assignedTo: UUID?
    var category: TaskCategory
    var priority: TaskPriority
    var status: TaskStatus
    var source: TaskSource
    var estimatedDuration: Int? // Minutes
    var completedAt: Date?
    var createdAt: Date
}

enum TaskCategory: String, Codable {
    case chore, homework, appointment, medication, meal, maintenance, personal
}

enum TaskPriority: String, Codable {
    case low, medium, high, urgent
}

enum TaskStatus: String, Codable {
    case pending, inProgress, completed, overdue, cancelled
}

enum TaskSource: String, Codable {
    case choreSystem, educationHub, healthcareManager, mealPlanning, manual
}

struct TaskUrgencyBreakdown: Codable {
    var overdue: [Task]
    var dueToday: [Task]
    var dueThisWeek: [Task]
    var dueLater: [Task]
    var noDeadline: [Task]
}

struct TaskInsights: Codable {
    var timeframe: Timeframe
    var totalTasks: Int
    var completedTasks: Int
    var completionRate: Double
    var averageCompletionTime: TimeInterval
    var mostProductiveDay: String
    var bottleneckCategory: TaskCategory?
    var trends: [TrendData]
}

enum Timeframe: String, Codable {
    case week, month, quarter, year
}

struct TrendData: Codable {
    var period: String
    var completionRate: Double
}

// MARK: - Decision Support

struct DecisionRecommendation<T: Codable>: Codable {
    var primary: T
    var alternatives: [T]
    var reasoning: String
    var confidence: Double
}

struct DecisionCriteria: Codable {
    var factors: [DecisionFactor]
    var weights: [DecisionFactor: Double]
}

enum DecisionFactor: String, Codable, Hashable {
    case cost, time, preference, convenience, health, variety
}

struct PreferencePattern<T: Codable>: Codable {
    var frequentChoices: [T]
    var avoidedChoices: [T]
    var rotationPattern: [T]?
    var timingPreferences: [String: T] // Day/time -> preferred choice
}

struct MealRecommendation: Codable {
    var primary: Recipe
    var alternatives: [Recipe]
    var reasoning: String
    var pantryMatch: Double // Percentage
    var prepTimeMinutes: Int
    var estimatedCost: Decimal?
}

struct ProviderRecommendation: Codable {
    var primary: ServiceProvider
    var alternatives: [ServiceProvider]
    var reasoning: String
    var reliabilityScore: Double
    var estimatedCost: Decimal?
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    var morningBriefingTime: Date // Time of day
    var eveningWindDownTime: Date // Time of day
    var weeklyPlanningTime: Date // Day and time
    var enableMorningBriefing: Bool
    var enableEveningWindDown: Bool
    var enableWeeklyPlanning: Bool
    var enableProactiveReminders: Bool
    var reminderPreferences: ReminderPreferences
    var notificationSound: String
    var useVoiceAnnouncements: Bool
}

// MARK: - Deliverable Content

struct DeliverableContent: Codable {
    var type: BriefingType
    var title: String
    var body: String
    var actionButtons: [ActionButton]?
    var priority: Int
}

struct ActionButton: Codable {
    var label: String
    var action: String
    var style: ButtonStyle
}

enum ButtonStyle: String, Codable {
    case primary, secondary, destructive
}

// MARK: - Errors

enum MentalLoadError: Error, LocalizedError {
    case familyNotFound
    case preferencesNotSet
    case weatherAPIFailed
    case calendarAccessDenied
    case taskLoadFailed
    case deliveryFailed
    case invalidTimeframe
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .familyNotFound:
            return "Family profile not found"
        case .preferencesNotSet:
            return "User preferences not configured"
        case .weatherAPIFailed:
            return "Failed to fetch weather data"
        case .calendarAccessDenied:
            return "Calendar access denied. Please enable in Settings."
        case .taskLoadFailed:
            return "Failed to load tasks"
        case .deliveryFailed:
            return "Failed to deliver briefing"
        case .invalidTimeframe:
            return "Invalid timeframe specified"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}
```

---

## 7. Example Scenarios

### Scenario 1: Morning Briefing - Busy School Day

**Context:**
- Family: Sarah (parent), Mike (parent), Emma (10), Jake (7)
- Tuesday, February 6, 2026, 7:00 AM
- Emma has early soccer practice, Jake has school picture day
- Cold and rainy weather

**Execution Flow:**

**Step 1: Scheduled Trigger**
```swift
// Background scheduler triggers at 7:00 AM
let briefing = try await generateMorningBriefing(
    familyId: family.id,
    date: Date()
)
```

**Step 2: Fetch Weather**
```swift
let weather = try await getWeatherSummary(
    location: family.homeLocation,
    date: today
)
// Result: {
//   temperature: 42°F,
//   condition: .rainy,
//   precipitation: 80%,
//   highTemp: 48°F,
//   lowTemp: 38°F
// }
```

**Step 3: Load Calendar**
```swift
let highlights = try await getTodaysCalendarHighlights(
    familyId: family.id,
    date: today
)
// Result: [
//   CalendarHighlight(event: "Emma - Soccer practice", time: 7:30 AM),
//   CalendarHighlight(event: "Jake - School picture day", time: 8:00 AM),
//   CalendarHighlight(event: "Sarah - Team meeting", time: 10:00 AM)
// ]
```

**Step 4: Check Urgent Tasks**
```swift
let urgentTasks = try await getUrgentTasks(
    familyId: family.id,
    date: today
)
// Result: [
//   Task(title: "Return library books", dueDate: today),
//   Task(title: "Emma - Math homework", dueDate: today)
// ]
```

**Step 5: Generate Suggestions**
```swift
let suggestions = suggestMorningPreparations(
    familyId: family.id,
    todaysEvents: highlights.map { $0.event }
)
// Result: [
//   "Pack Emma's soccer gear (practice at 7:30am)",
//   "Bring umbrellas and rain jackets",
//   "Have Jake wear nice clothes for pictures",
//   "Return library books on way to school"
// ]
```

**Step 6: Format and Deliver**
```
Assistant (7:00 AM notification):

Good morning! Here's your Tuesday:

🌧️ Weather: Rainy, 42°F (high 48°F)
80% chance of rain all day

📅 Today's Schedule:
• 7:30 AM - Emma's soccer practice
• 8:00 AM - Jake has school pictures
• 10:00 AM - Sarah's team meeting

✅ Priorities:
• Return library books (due today)
• Emma - Complete math homework

💡 Suggestions:
• Pack Emma's soccer gear and rain jacket
• Have Jake wear nice clothes for pictures
• Bring umbrellas for everyone
• Return library books on way to school

Have a great day!
```

---

### Scenario 2: Evening Wind-Down - Productive Day

**Context:**
- Same family
- Tuesday evening, 8:00 PM
- Completed most tasks
- Tomorrow is early morning meeting for Sarah

**Execution Flow:**

**Step 1: Review Completed Tasks**
```swift
let completed = try await getCompletedTasksToday(
    familyId: family.id,
    date: today
)
// Result: [
//   Task(title: "Emma - Math homework", completedAt: 4:30 PM),
//   Task(title: "Jake - Reading practice", completedAt: 5:00 PM),
//   Task(title: "Return library books", completedAt: 3:45 PM),
//   Task(title: "Cook dinner", completedAt: 6:30 PM)
// ]
```

**Step 2: Check Incomplete**
```swift
let incomplete = try await getIncompleteTasksToday(
    familyId: family.id,
    date: today
)
// Result: [
//   Task(title: "Jake - Clean room", dueDate: today)
// ]
```

**Step 3: Preview Tomorrow**
```swift
let tomorrowsPriorities = try await getTomorrowsPriorities(
    familyId: family.id,
    date: tomorrow
)
// Result: [
//   Priority(title: "Sarah - 8:00 AM client meeting", urgency: .high),
//   Priority(title: "Emma - Science test", urgency: .high),
//   Priority(title: "Jake - Soccer practice", urgency: .medium)
// ]
```

**Step 4: Evening Prep Suggestions**
```swift
let suggestions = suggestEveningPreparations(
    familyId: family.id,
    tomorrowsEvents: tomorrowsEvents
)
// Result: [
//   "Lay out clothes for early meeting",
//   "Emma - Review science notes for test",
//   "Pack Jake's soccer gear tonight"
// ]
```

**Step 5: Calculate Score**
```swift
let score = calculateProductivityScore(
    completed: completed,
    total: completed + incomplete
)
// Result: ProductivityScore(
//   percentage: 80%,
//   message: "Great progress! 💪"
// )
```

**Step 6: Deliver Wind-Down**
```
Assistant (8:00 PM notification):

Good evening! Here's how today went:

✅ Completed (80%):
• Emma finished math homework
• Jake completed reading practice
• Returned library books
• Dinner cooked and eaten

⏰ Tomorrow's Priorities:
• 8:00 AM - Sarah's client meeting
• Emma has science test
• 4:00 PM - Jake's soccer practice

💡 Tonight:
• Lay out clothes for early meeting tomorrow
• Emma - Review science notes one more time
• Pack Jake's soccer gear now

Great progress! 💪
```

---

### Scenario 3: Weekly Planning - Busy Week Ahead

**Context:**
- Sunday evening, 6:00 PM
- Week ahead has multiple doctor appointments
- No meal plan created yet
- Emma's birthday on Thursday

**Execution Flow:**

**Step 1: Load Week's Calendar**
```swift
let weekCalendar = try await getWeeksCalendar(
    familyId: family.id,
    weekStartDate: nextMonday
)
// Result: 23 events across 7 days
```

**Step 2: Check Meal Plan**
```swift
let mealPlanStatus = try await checkWeeklyMealPlan(
    familyId: family.id,
    weekStartDate: nextMonday
)
// Result: .missing
```

**Step 3: Identify Conflicts**
```swift
let conflicts = identifySchedulingConflicts(events: weekCalendar)
// Result: [
//   SchedulingConflict(
//     type: .overlap,
//     events: [emmasDentist, jakesCheckup],
//     severity: .high
//   )
// ]
```

**Step 4: Generate Suggestions**
```swift
let suggestions = await suggestWeeklyActions(
    familyId: family.id,
    weekPlan: weekPlan
)
// Result: [
//   "Plan this week's meals (none scheduled)",
//   "Reschedule Emma's dentist (conflicts with Jake's checkup)",
//   "Buy birthday gift for Emma (Thursday)",
//   "Schedule grocery shopping trip"
// ]
```

**Step 5: Deliver Weekly Plan**
```
Assistant (Sunday 6:00 PM):

Your week ahead (Feb 12-18):

📅 This Week:
Monday: 3 events
  • 8:00 AM - Jake school
  • 3:00 PM - Emma soccer practice
  • 7:00 PM - Family dinner

Tuesday: 4 events
  • Doctor appointments for both kids
  • Sarah - Work presentation

Wednesday: 2 events
Thursday: 5 events (Emma's Birthday! 🎂)
Friday: 3 events
Saturday: Family outing
Sunday: Meal prep day

🍽️ Meals: ❌ No meal plan - create one

🧹 Chores: 12 assigned this week

⚠️ Conflicts: 1 detected
  • Tuesday 2pm: Emma's dentist overlaps with Jake's checkup

📝 Action Items:
• Plan this week's meals
• Reschedule Emma's dentist to avoid conflict
• Buy birthday gift for Emma (Thursday)
• Schedule grocery shopping trip
• Verify insurance for doctor appointments

Let's make it a great week!
```

---

### Scenario 4: Proactive Reminder - Appointment Tomorrow

**Context:**
- Monday, 3:00 PM
- Emma has dentist appointment tomorrow at 2:00 PM
- 23-hour lead time triggers reminder

**Execution Flow:**

**Step 1: Hourly Reminder Check**
```swift
let reminders = try await generateProactiveReminders(
    familyId: family.id,
    currentTime: Date()
)
```

**Step 2: Check Upcoming Events**
```swift
let upcomingEvents = try await getUpcomingEvents(
    familyId: family.id,
    startTime: now,
    endTime: now + 48.hours
)
// Result: [
//   CalendarEvent(
//     title: "Emma - Dentist",
//     startTime: tomorrow_2pm,
//     type: .dentistAppointment
//   )
// ]
```

**Step 3: Create Reminder**
```swift
let reminder = createReminderFromEvent(
    event: emmasDentist,
    leadTime: 24
)
// Result: Reminder(
//   type: .appointment,
//   title: "Emma's dentist tomorrow",
//   message: "Emma has dentist appointment tomorrow at 2:00 PM",
//   actionSuggestion: "Verify insurance card and location"
// )
```

**Step 4: Check Preferences**
```swift
let shouldSend = shouldSendReminder(
    reminder: reminder,
    familyPreferences: family.reminderPreferences
)
// Result: true (within allowed hours, under daily limit)
```

**Step 5: Deliver Reminder**
```
Assistant (3:00 PM notification):

📅 Tomorrow at 2:00 PM:
Emma has a dentist appointment

📍 Location: Dr. Smith's Office
123 Main Street

💡 Don't forget:
• Bring insurance card
• Arrive 10 minutes early
• Emma should brush teeth before leaving

Set a reminder? [Yes] [Dismiss]
```

---

### Scenario 5: Decision Simplification - Dinner Choice

**Context:**
- Parent overwhelmed, 5:30 PM on Wednesday
- No dinner plan
- Busy evening with activities at 7pm

**User Input:**
```
"What should we have for dinner tonight?"
```

**Execution Flow:**

**Step 1: Load Context**
```swift
let mealHistory = try await getMealHistory(
    familyId: family.id,
    startDate: Date().daysAgo(14),
    endDate: Date()
)

let pantry = try await getPantryInventory(familyId: family.id)

let todaysSchedule = try await getTodaysCalendarHighlights(
    familyId: family.id,
    date: today
)
// Result: Busy evening, need quick meal
```

**Step 2: Search Candidates**
```swift
let candidates = try await searchRecipes(
    criteria: RecipeSearchCriteria(
        maxPrepTime: 25, // Need fast meal
        dietaryRestrictions: family.restrictions,
        excludeRecipeIds: mealHistory.last7Days.ids
    )
)
```

**Step 3: Score Options**
```swift
// Scoring algorithm runs for each candidate:
// - Pasta primavera: Score 23
//   * Pantry match 80% (+10)
//   * Past rating 5 stars (+8)
//   * Prep time 20 min (+5)
//
// - Chicken stir-fry: Score 18
//   * Pantry match 60% (+0)
//   * Past rating 4 stars (+8)
//   * Prep time 25 min (+5)
//   * Different protein (+5)
```

**Step 4: Format Recommendation**
```
Assistant:

I recommend: Pasta Primavera

Why:
✅ Uses ingredients you have (80% match)
⚡ Quick to make (20 minutes)
⭐ Family rated it 5 stars last time
🕒 Perfect for busy evening (activity at 7pm)

Alternatives:
• Chicken Stir-Fry - Different protein, also quick
• Grilled Cheese & Soup - Ultra-fast comfort food

[Cook This] [Show Alternatives] [Something Else]
```

---

## 8. API Integrations

### 8.1 OpenWeatherMap API

**Purpose:** Weather forecasts for morning briefings

**Authentication:** API Key

**Endpoints:**
- `GET /data/2.5/weather` - Current weather
- `GET /data/2.5/forecast` - 5-day forecast
- `GET /data/2.5/alerts` - Weather alerts

**Sample Request:**
```swift
class WeatherAPI {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"

    func getWeatherSummary(
        location: CLLocation,
        date: Date
    ) async throws -> WeatherSummary {
        var components = URLComponents(string: "\(baseURL)/forecast")!

        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]

        let request = APIRequest<WeatherResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )

        let response = try await request.execute()

        return WeatherSummary(
            location: response.city.name,
            temperature: Int(response.list.first!.main.temp),
            feelsLike: Int(response.list.first!.main.feels_like),
            condition: mapCondition(response.list.first!.weather.first!.main),
            precipitation: Int(response.list.first!.pop * 100),
            alerts: [],
            highTemp: Int(response.list.max { $0.main.temp_max < $1.main.temp_max }!.main.temp_max),
            lowTemp: Int(response.list.min { $0.main.temp_min < $1.main.temp_min }!.main.temp_min)
        )
    }

    private func mapCondition(_ apiCondition: String) -> WeatherCondition {
        switch apiCondition.lowercased() {
        case "clear": return .sunny
        case "clouds": return .cloudy
        case "rain": return .rainy
        case "snow": return .snowy
        case "thunderstorm": return .stormy
        default: return .cloudy
        }
    }
}
```

---

### 8.2 Apple Push Notification Service (APNs)

**Purpose:** Deliver briefings and reminders

**Sample Implementation:**
```swift
class NotificationManager {
    func deliverBriefing(
        familyId: UUID,
        briefing: MorningBriefing
    ) async throws -> Bool {
        let deviceTokens = try await getDeviceTokens(familyId: familyId)

        for token in deviceTokens {
            let payload: [String: Any] = [
                "aps": [
                    "alert": [
                        "title": "Good morning! ☀️",
                        "body": formatBriefingSummary(briefing),
                        "sound": "default"
                    ],
                    "badge": 1,
                    "content-available": 1
                ],
                "briefingId": briefing.id.uuidString,
                "type": "morning_briefing"
            ]

            try await APNsClient.shared.send(
                payload: payload,
                to: token
            )
        }

        return true
    }

    private func formatBriefingSummary(_ briefing: MorningBriefing) -> String {
        let eventCount = briefing.calendarHighlights.count
        let taskCount = briefing.urgentTasks.count

        return "\(briefing.weather.condition.rawValue.capitalized), \(briefing.weather.temperature)°F. \(eventCount) events, \(taskCount) priorities today."
    }
}
```

---

## 9. Test Cases

### Morning Briefing Tests

**Test 1: Generate Basic Morning Briefing**
```swift
func testGenerateMorningBriefing() async throws {
    let briefing = try await generateMorningBriefing(
        familyId: family.id,
        date: Date()
    )

    XCTAssertNotNil(briefing.weather)
    XCTAssertNotNil(briefing.calendarHighlights)
    XCTAssertNotNil(briefing.suggestions)
}
```

**Test 2: Weather Alert in Briefing**
```swift
func testWeatherAlertInBriefing() async throws {
    // Mock severe weather
    mockWeatherAPI.setAlert(type: .severeThunderstorm, severity: .warning)

    let briefing = try await generateMorningBriefing(
        familyId: family.id,
        date: Date()
    )

    XCTAssertGreaterThan(briefing.weather.alerts.count, 0)
    XCTAssertEqual(briefing.weather.alerts.first?.type, .severeThunderstorm)
}
```

**Test 3: Urgent Tasks Prioritization**
```swift
func testUrgentTasksPrioritization() async throws {
    // Create tasks with different due dates
    let overdueTask = createTestTask(dueDate: Date().daysAgo(1))
    let todayTask = createTestTask(dueDate: Date())
    let futureTask = createTestTask(dueDate: Date().daysAhead(3))

    let urgentTasks = try await getUrgentTasks(
        familyId: family.id,
        date: Date()
    )

    XCTAssertTrue(urgentTasks.contains(where: { $0.id == overdueTask.id }))
    XCTAssertTrue(urgentTasks.contains(where: { $0.id == todayTask.id }))
    XCTAssertFalse(urgentTasks.contains(where: { $0.id == futureTask.id }))
}
```

**Test 4: Preparation Suggestions Based on Events**
```swift
func testPreparationSuggestions() {
    let soccerPractice = CalendarEvent(
        title: "Soccer practice",
        startTime: Date().hoursAhead(2),
        type: .soccerPractice
    )

    let suggestions = suggestMorningPreparations(
        familyId: family.id,
        todaysEvents: [soccerPractice]
    )

    XCTAssertTrue(suggestions.contains(where: {
        $0.text.lowercased().contains("soccer gear")
    }))
}
```

**Test 5: No Briefing During Do Not Disturb**
```swift
func testNoDeliveryDuringDND() async throws {
    var preferences = family.preferences
    preferences.doNotDisturbStart = 22 // 10 PM
    preferences.doNotDisturbEnd = 7 // 7 AM

    // Try to deliver at 6:30 AM (during DND)
    let shouldDeliver = shouldDeliverBriefing(
        time: Date().settingHour(6, minute: 30),
        preferences: preferences
    )

    XCTAssertFalse(shouldDeliver)
}
```

### Evening Wind-Down Tests

**Test 6: Calculate Productivity Score**
```swift
func testCalculateProductivityScore() {
    let completed = [
        createTestTask(),
        createTestTask(),
        createTestTask(),
        createTestTask()
    ]

    let total = completed + [createTestTask()] // 5 total, 4 completed

    let score = calculateProductivityScore(
        completed: completed,
        total: total
    )

    XCTAssertEqual(score.percentage, 0.8)
    XCTAssertEqual(score.completedCount, 4)
    XCTAssertEqual(score.totalCount, 5)
    XCTAssertEqual(score.message, "Great progress! 💪")
}
```

**Test 7: Tomorrow's Priorities**
```swift
func testTomorrowsPriorities() async throws {
    // Create various tasks for tomorrow
    let earlyMeeting = CalendarEvent(
        title: "Client meeting",
        startTime: tomorrow_8am
    )

    let priorities = try await getTomorrowsPriorities(
        familyId: family.id,
        date: tomorrow
    )

    XCTAssertGreaterThan(priorities.count, 0)
    XCTAssertTrue(priorities.contains(where: {
        $0.title.contains("Client meeting")
    }))
}
```

**Test 8: Evening Prep Suggestions**
```swift
func testEveningPrepSuggestions() {
    let earlyEvent = CalendarEvent(
        title: "Breakfast meeting",
        startTime: tomorrow_7am
    )

    let suggestions = suggestEveningPreparations(
        familyId: family.id,
        tomorrowsEvents: [earlyEvent]
    )

    XCTAssertTrue(suggestions.contains(where: {
        $0.text.lowercased().contains("lay out clothes")
    }))
}
```

### Weekly Planning Tests

**Test 9: Identify Scheduling Conflicts**
```swift
func testIdentifySchedulingConflicts() {
    let event1 = CalendarEvent(
        title: "Doctor",
        startTime: "2:00 PM",
        endTime: "3:00 PM",
        attendees: [emma.id]
    )

    let event2 = CalendarEvent(
        title: "Dentist",
        startTime: "2:30 PM",
        endTime: "3:30 PM",
        attendees: [emma.id]
    )

    let conflicts = identifySchedulingConflicts(events: [event1, event2])

    XCTAssertEqual(conflicts.count, 1)
    XCTAssertEqual(conflicts.first?.type, .overlap)
}
```

**Test 10: Meal Plan Status Check**
```swift
func testMealPlanStatusCheck() async throws {
    // No meal plan exists
    let status = try await checkWeeklyMealPlan(
        familyId: family.id,
        weekStartDate: nextMonday
    )

    XCTAssertEqual(status, .missing)
}
```

**Test 11: Weekly Action Suggestions**
```swift
func testWeeklyActionSuggestions() async {
    let weekPlan = WeeklyPlan(
        familyId: family.id,
        weekStartDate: nextMonday,
        weekEndDate: nextSunday,
        dailySummaries: [],
        mealPlanStatus: .missing,
        choresSummary: ChoresSummary(totalAssigned: 0, byMember: [:], upcomingDue: []),
        schedulingConflicts: [],
        actionItems: [],
        createdAt: Date()
    )

    let suggestions = await suggestWeeklyActions(
        familyId: family.id,
        weekPlan: weekPlan
    )

    XCTAssertTrue(suggestions.contains(where: {
        $0.text.lowercased().contains("meal")
    }))
}
```

### Proactive Reminder Tests

**Test 12: Create Reminder from Event**
```swift
func testCreateReminderFromEvent() {
    let appointment = CalendarEvent(
        title: "Dentist",
        startTime: tomorrow_2pm,
        type: .dentistAppointment
    )

    let reminder = createReminderFromEvent(
        event: appointment,
        leadTime: 24
    )

    XCTAssertEqual(reminder.type, .appointment)
    XCTAssertNotNil(reminder.actionSuggestion)
}
```

**Test 13: Reminder Frequency Limit**
```swift
func testReminderFrequencyLimit() {
    var preferences = ReminderPreferences.default
    preferences.maxPerDay = 5

    // Already sent 5 reminders today
    mockReminderLog.setSentToday(count: 5)

    let shouldSend = shouldSendReminder(
        reminder: testReminder,
        familyPreferences: preferences
    )

    XCTAssertFalse(shouldSend)
}
```

**Test 14: Approaching Deadline Detection**
```swift
func testApproachingDeadlines() async throws {
    let soonTask = createTestTask(dueDate: Date().hoursAhead(12))
    let laterTask = createTestTask(dueDate: Date().daysAhead(5))

    let deadlines = try await getApproachingDeadlines(
        familyId: family.id,
        withinHours: 24
    )

    XCTAssertTrue(deadlines.contains(where: { $0.id == soonTask.id }))
    XCTAssertFalse(deadlines.contains(where: { $0.id == laterTask.id }))
}
```

### Decision Simplification Tests

**Test 15: Meal Decision with Pantry Match**
```swift
func testMealDecisionPantryMatch() async throws {
    // Pantry has pasta and sauce
    mockPantry.add(items: ["pasta", "tomato sauce", "garlic", "olive oil"])

    let recommendation = try await simplifyMealDecision(
        familyId: family.id,
        date: Date()
    )

    // Should recommend recipe using pantry items
    XCTAssertGreaterThan(recommendation.pantryMatch, 0.6)
}
```

**Test 16: Preference Pattern Detection**
```swift
func testPreferencePatternDetection() {
    let history: [Recipe] = [
        pastaRecipe, // Chosen 5 times
        pastaRecipe,
        pastaRecipe,
        pastaRecipe,
        pastaRecipe,
        stirFryRecipe, // Chosen 2 times
        stirFryRecipe,
        saladRecipe // Chosen 1 time
    ]

    let pattern = analyzePastChoices(history: history)

    XCTAssertEqual(pattern.frequentChoices.first?.title, "Pasta")
}
```

**Test 17: Decision Criteria Weighting**
```swift
func testDecisionCriteriaWeighting() {
    let criteria = DecisionCriteria(
        factors: [.time, .cost, .preference],
        weights: [
            .time: 0.5,
            .cost: 0.3,
            .preference: 0.2
        ]
    )

    // Time should be weighted highest
    XCTAssertEqual(criteria.weights[.time], 0.5)
}
```

### Task Tracking Tests

**Test 18: Categorize Tasks by Urgency**
```swift
func testCategorizeTasksByUrgency() {
    let tasks = [
        createTestTask(dueDate: Date().daysAgo(1)), // Overdue
        createTestTask(dueDate: Date()), // Due today
        createTestTask(dueDate: Date().daysAhead(3)), // Due this week
        createTestTask(dueDate: nil) // No deadline
    ]

    let breakdown = categorizeTasksByUrgency(
        tasks: tasks,
        currentDate: Date()
    )

    XCTAssertEqual(breakdown.overdue.count, 1)
    XCTAssertEqual(breakdown.dueToday.count, 1)
    XCTAssertEqual(breakdown.dueThisWeek.count, 1)
    XCTAssertEqual(breakdown.noDeadline.count, 1)
}
```

**Test 19: Task Prioritization (Eisenhower Matrix)**
```swift
func testTaskPrioritization() {
    let urgentImportant = createTestTask(
        priority: .urgent,
        dueDate: Date()
    )

    let importantNotUrgent = createTestTask(
        priority: .high,
        dueDate: Date().daysAhead(7)
    )

    let urgentNotImportant = createTestTask(
        priority: .low,
        dueDate: Date()
    )

    let tasks = [urgentNotImportant, importantNotUrgent, urgentImportant]

    let prioritized = prioritizeTasks(tasks: tasks)

    XCTAssertEqual(prioritized.first?.id, urgentImportant.id)
}
```

**Test 20: Track Task Completion**
```swift
func testTrackTaskCompletion() async throws {
    let task = createTestTask()

    let success = try await trackTaskCompletion(
        taskId: task.id,
        completedAt: Date()
    )

    XCTAssertTrue(success)

    let updatedTask = try await getTask(taskId: task.id)
    XCTAssertEqual(updatedTask.status, .completed)
    XCTAssertNotNil(updatedTask.completedAt)
}
```

**Test 21: Task Insights Generation**
```swift
func testTaskInsightsGeneration() async throws {
    // Create 10 tasks, 8 completed
    let insights = try await generateTaskInsights(
        familyId: family.id,
        timeframe: .week
    )

    XCTAssertEqual(insights.totalTasks, 10)
    XCTAssertEqual(insights.completedTasks, 8)
    XCTAssertEqual(insights.completionRate, 0.8)
}
```

**Test 22: Encouraging Message Generation**
```swift
func testEncouragingMessageGeneration() {
    let highScore = generateEncouragingMessage(completionRate: 0.95)
    XCTAssertTrue(highScore.contains("Amazing") || highScore.contains("🎉"))

    let lowScore = generateEncouragingMessage(completionRate: 0.4)
    XCTAssertTrue(lowScore.contains("new day") || lowScore.contains("☀️"))
}
```

**Test 23: Optimal Delivery Time**
```swift
func testOptimalDeliveryTime() {
    var preferences = UserPreferences.default
    preferences.morningBriefingTime = Date().settingHour(7, minute: 0)

    let deliveryTime = getOptimalDeliveryTime(
        briefingType: .morning,
        preferences: preferences
    )

    let hour = Calendar.current.component(.hour, from: deliveryTime)
    XCTAssertEqual(hour, 7)
}
```

---

## 10. Error Handling

### Error Types and Recovery Strategies

```swift
enum MentalLoadError: Error, LocalizedError {
    case familyNotFound
    case preferencesNotSet
    case weatherAPIFailed
    case calendarAccessDenied
    case taskLoadFailed
    case deliveryFailed
    case invalidTimeframe
    case databaseError(String)
}
```

### Recovery Strategies

**Weather API Failed:**
```swift
do {
    let weather = try await getWeatherSummary(location: location, date: today)
} catch MentalLoadError.weatherAPIFailed {
    // Use cached weather or generic message
    let fallbackWeather = WeatherSummary(
        location: "Unknown",
        temperature: 70,
        condition: .cloudy,
        precipitation: 0,
        alerts: []
    )

    // Log error for monitoring
    await logError("Weather API failed, using fallback")

    // Continue with briefing using fallback data
}
```

**Calendar Access Denied:**
```swift
do {
    let highlights = try await getTodaysCalendarHighlights(familyId: family.id, date: today)
} catch MentalLoadError.calendarAccessDenied {
    // Prompt user to enable calendar access
    await showAlert(
        title: "Calendar Access Needed",
        message: "Enable calendar access in Settings to see today's events in your briefings.",
        actions: [.settings, .cancel]
    )

    // Continue with briefing without calendar data
    return MorningBriefing(
        calendarHighlights: [],
        // ... other components
    )
}
```

**Delivery Failed:**
```swift
do {
    try await deliverMorningBriefing(familyId: family.id, briefing: briefing)
} catch MentalLoadError.deliveryFailed {
    // Store briefing for in-app viewing
    try await storeBriefingLocally(briefing)

    // Retry delivery after 5 minutes
    Task {
        try await Task.sleep(nanoseconds: 300_000_000_000)
        try await deliverMorningBriefing(familyId: family.id, briefing: briefing)
    }
}
```

**Task Load Failed:**
```swift
do {
    let tasks = try await getAllActiveTasks(familyId: family.id)
} catch MentalLoadError.taskLoadFailed {
    // Log error
    await logError("Failed to load tasks for briefing")

    // Continue with empty task list
    return []
}
```

---

**End of Mental Load Automation Skill Breakdown**
