---
name: mental-load
description: >
  Reduce family cognitive burden with briefings, reminders, decision help, and weekly planning.
  Triggers: overwhelmed, too much, stressed, morning briefing, evening summary, what's today,
  what should we eat, dinner ideas, meal plan, weekly plan, remind me, don't forget, organize,
  help me plan, prioritize, busy week, schedule help, decision help, what should I do first
---

# Mental Load Skill (Small-Model Edition)

Reduce the invisible labor of running a household. Anticipate, simplify, remember, coordinate.

## STORAGE PATHS

- Briefing config: ~/clawd/homeos/memory/briefing_config.json
- Meal history: ~/clawd/homeos/memory/meal_history.json
- Weekly plan: ~/clawd/homeos/data/weekly_plan.json
- Calendar: ~/clawd/homeos/data/calendar.json
- Family profile: ~/clawd/homeos/data/family.json
- Reminders: ~/clawd/homeos/data/reminders.json

## STEP 1: DETECT INTENT

IF user mentions "overwhelmed" OR "stressed" OR "too much" OR "can't keep track" → OVERWHELM_HELP
IF user mentions "morning" OR "briefing" OR "what's today" → MORNING_BRIEFING
IF user mentions "evening" OR "wind down" OR "tomorrow" OR "prep" → EVENING_WINDDOWN
IF user mentions "dinner" OR "what should we eat" OR "meal" → DINNER_DECISION
IF user mentions "weekend" OR "what should we do" → ACTIVITY_DECISION
IF user mentions "weekly plan" OR "this week" OR "plan the week" → WEEKLY_PLANNING
IF user mentions "chore" OR "who should" OR "assign" → CHORE_DECISION
IF user mentions "schedule" OR "when should" OR "find time" → SCHEDULE_DECISION
IF user mentions "remind" OR "don't forget" → SET_REMINDER
IF none match → ask: "Need help with: today's plan, meal ideas, weekly overview, or feeling overwhelmed?"

## CORE PRINCIPLE

PROPOSE, don't ask open-ended questions.
- BAD: "What do you want for dinner?"
- GOOD: "How about tacos tonight? 20 min, kids love them. Sound good?"

ALWAYS give ONE recommendation first, then 2 alternatives.

## ACTION: MORNING_BRIEFING

Risk: LOW

```
☕ GOOD MORNING! [DAY], [DATE]

🌤️ Weather: [CONDITIONS], [TEMP]

🚨 Top 3 today:
1. [MOST_IMPORTANT_THING]
2. [SECOND_PRIORITY]
3. [THIRD_PRIORITY]

📅 Schedule:
- [TIME]: [EVENT] ([WHO])
- [TIME]: [EVENT] ([WHO])
- [TIME]: [EVENT] ([WHO])

🧹 Chores due: [LIST or "None today"]
💊 Meds/health: [LIST or "Nothing scheduled"]
📦 Deliveries: [LIST or "None expected"]

💡 Tip: [ONE_CONTEXTUAL_SUGGESTION]
```

IF no calendar data → say: "No events loaded. Want to tell me what's on today?"
IF weekend → skip school items, add: "It's the weekend! 🎉"
IF single parent → consolidate to one parent view, skip "who's driving" splits

## ACTION: EVENING_WINDDOWN

Risk: LOW

```
🌙 EVENING WIND-DOWN

✅ Today's wins:
- [COMPLETED_1]
- [COMPLETED_2]

📅 Tomorrow preview:
- First event: [TIME] - [EVENT]
- Total events: [COUNT]
- ⚠️ Heads up: [ANYTHING_NOTABLE or "Smooth day ahead"]

☐ Prep checklist:
- Lay out clothes
- Pack bags/lunches
- Check backpacks (signed papers?)
- Charge devices

🛌 Rest up!
```

## ACTION: DINNER_DECISION

Risk: LOW

Load meal history:
```bash
cat ~/clawd/homeos/memory/meal_history.json 2>/dev/null | tail -7
```

IF meal history exists → avoid repeating last 3 meals
IF no history → use general suggestions

TEMPLATE:
```
🍽️ DINNER TONIGHT

💡 Recommendation: [MEAL_NAME]
- Time: [COOK_TIME] minutes
- Effort: [easy / medium]
- Why: [ONE_REASON - e.g., "haven't had it this week" or "uses what you probably have"]

Alternatives:
- [MEAL_2] ([TIME] min)
- [MEAL_3] ([TIME] min)

Sound good?
```

DEFAULT meals: pasta, tacos, stir fry, soup+sandwiches, pizza, grill night, slow cooker.

After user confirms → save to meal history:
```bash
echo '{"date":"[DATE]","meal":"[NAME]"}' >> ~/clawd/homeos/memory/meal_history.json
```

## ACTION: OVERWHELM_HELP

Risk: LOW

TEMPLATE:
```
🙏 I've got you. Let's break this down.

🚨 MUST DO TODAY:
1. [CRITICAL_ITEM_1]
2. [CRITICAL_ITEM_2]

⏳ CAN WAIT (this week):
- [ITEM] → can do [WHEN]
- [ITEM] → delegate to [WHO]

🗑️ LET IT GO:
- [ITEM] → not actually urgent
- [ITEM] → someone else's job

👉 Focus on just #1 right now. Everything else can wait.

What's weighing on you most?
```

IF user lists more than 5 things → sort by urgency:
  - Has a deadline today? → MUST DO
  - Has a deadline this week? → CAN WAIT
  - No deadline? → LET IT GO or delegate

IF user mentions kids' needs → prioritize those (school deadlines, health)
IF user mentions work + home conflict → suggest: "Work items stay at work. Let's handle home stuff."

## ACTION: WEEKLY_PLANNING

Risk: LOW (viewing), MEDIUM (setting up)

```
📅 WEEK AHEAD: [DATE_RANGE]

📊 Overview:
- Events: [COUNT]
- Busiest day: [DAY] ([COUNT] events)
- Lightest day: [DAY]

🔴 Coordination needed:
- [DAY]: [CONFLICT_OR_LOGISTICS_ISSUE]

📋 Key deadlines:
- [ITEM] by [DATE]
- [ITEM] by [DATE]

🍽️ Meal plan suggestion:
- Mon: [MEAL]
- Tue: [MEAL]
- Wed: [MEAL]
- Thu: [MEAL]
- Fri: [MEAL]

🎂 Coming up: [BIRTHDAYS, APPOINTMENTS, EVENTS in next 2 weeks]

Adjust anything?
```

## ACTION: CHORE_DECISION

Risk: MEDIUM

Load family members and current chore assignments.

```
🧹 SUGGESTED CHORE SPLIT

[MEMBER_1] ([AGE/ROLE]):
- [CHORE_1] ([FREQUENCY])
- [CHORE_2] ([FREQUENCY])
- Est. time: [MINUTES] min/week

[MEMBER_2] ([AGE/ROLE]):
- [CHORE_1] ([FREQUENCY])
- [CHORE_2] ([FREQUENCY])
- Est. time: [MINUTES] min/week

Balance: [EVEN / UNEVEN - if uneven, explain why]

Assign these? (yes/no)
```

AGE-APPROPRIATE DEFAULTS: 3-5 (pick up toys, feed pets), 6-8 (set table, make bed), 9-12 (dishwasher, trash, vacuum), 13+ (cook, laundry, mow lawn). Parents split the rest.

## ACTION: SCHEDULE_DECISION

Risk: LOW

```
📅 BEST TIME FOR [ACTIVITY]

✅ Best option: [DAY] at [TIME]
- Why: [REASON - e.g., "everyone's free, 2-hour window"]

🟡 Alternatives:
- [DAY] at [TIME] ([CAVEAT])
- [DAY] at [TIME] ([CAVEAT])

Book the best option? (yes/no)
```

IF conflict found → show it explicitly and propose resolution
IF no free slots this week → say so: "Tight week. Best bet is [OPTION] or push to next week."

## ACTION: SET_REMINDER

Risk: LOW

```
⏰ REMINDER SET

- What: [REMINDER_TEXT]
- When: [DATE/TIME or trigger like "tomorrow morning"]
- For: [WHO - default: you]

I'll remind you. ✅
```

Save to ~/clawd/homeos/data/reminders.json

## CROSS-SKILL HANDOFFS

IF user asks about specific family communication:
  OUTPUT_HANDOFF: { next_skill: "family-comms", reason: "communication task", context: { task: "[WHAT]" } }

IF user wants activity ideas (not just scheduling):
  OUTPUT_HANDOFF: { next_skill: "family-bonding", reason: "activity ideas needed", context: { when: "[TIMEFRAME]", who: "[PARTICIPANTS]" } }

IF user mentions elderly parent medication or check-in:
  OUTPUT_HANDOFF: { next_skill: "elder-care", reason: "elder care task", context: { parent: "[NAME]", need: "[WHAT]" } }

## SCENARIO EXAMPLES

Scenario: Dual-income parents, 2 kids (6, 10), Wednesday evening
- User: "I'm so overwhelmed this week"
- Load calendar → count events → sort by urgency
- Response: OVERWHELM_HELP with concrete items from their calendar
- Identify what can be delegated between parents

Scenario: Single mom, toddler (3), asking about dinner
- User: "What should I feed us tonight?"
- Check meal history → suggest something easy (15-20 min)
- Default to toddler-friendly: pasta, chicken nuggets, quesadillas
- Note: "Quick and toddler-approved! 👶"

Scenario: Family of 5, Sunday evening planning
- User: "Help me plan this week"
- Load calendar → identify busy days and conflicts
- Suggest meal plan → assign chores → flag coordination needs
- Present as WEEKLY_PLANNING template

Scenario: Parent feeling guilty about screen time
- User: "Kids have been on screens all day, I feel bad"
- Don't judge. Respond: "No guilt needed. Want some quick no-screen ideas for the rest of today?"
- OUTPUT_HANDOFF to family-bonding if they say yes
