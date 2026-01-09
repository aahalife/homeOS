---
name: mental-load
description: Reduce cognitive burden on families through proactive reminders, decision simplification, morning briefings, evening wind-downs, and weekly planning. Use when the user feels overwhelmed, needs help organizing, wants automated planning, asks for daily summaries, or needs decision support.
---

# Mental Load Skill

Automate the invisible labor of running a household - so families can focus on being present with each other.

## Philosophy

This skill reduces cognitive load by:
- **Anticipating** needs before you ask
- **Simplifying** decisions (propose, don't ask)
- **Remembering** so you don't have to
- **Coordinating** across family members
- **Proactively** handling routine tasks

## When to Use

- User says "I'm overwhelmed" or "too much to track"
- User wants automated daily/weekly planning
- User needs decision help ("what should we..."
- User requests morning briefings or evening summaries
- User wants proactive household management

## Core Functions

| Function | Timing | Purpose |
|----------|--------|----------|
| Morning Briefing | 7:00 AM | Start day organized |
| Proactive Reminders | Ongoing | Never forget |
| Decision Simplification | On-demand | Reduce choice fatigue |
| Evening Wind-Down | 8:00 PM | Prep for tomorrow |
| Weekly Planning | Sunday 6 PM | Week ahead overview |
| Household Coordination | Continuous | Avoid conflicts |

## Morning Briefing

**Automatic daily briefing:**
```
☕ GOOD MORNING!

📅 [Day], [Date]
☁️ [Weather] - [Temp]°F

━━━ TODAY'S PRIORITIES ━━━

1. 🚨 [Most important thing]
2. 📅 [Second priority]
3. ⏰ [Third priority]

━━━ FAMILY SCHEDULE ━━━

👨 Dad: [Key events]
👩 Mom: [Key events]
👧 Emma: [School + activities]
👦 Jack: [School + activities]

━━━ REMINDERS ━━━

💊 Medications: [Who needs what]
🧹 Chores due: [List]
📦 Deliveries: [Expected packages]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 TIP: [Contextual suggestion for the day]

Have a great day! 👋
```

**Configure briefing:**
```bash
cat > ~/clawd/homeos/memory/preferences/morning_briefing.json << 'EOF'
{
  "enabled": true,
  "time": "07:00",
  "recipients": ["member-dad", "member-mom"],
  "include": {
    "weather": true,
    "calendar": true,
    "medications": true,
    "chores": true,
    "school": true,
    "tips": true
  }
}
EOF
```

## Proactive Reminders

**Event prep reminders:**
```
⏰ PREP REMINDER

📅 [Event Name] is in 45 minutes

Things to prepare:
• [Item 1]
• [Item 2]
• [Item 3]

📍 [Location / Link]
⏱️ Leave in [X] minutes to arrive on time.
```

**Anticipation reminders (before you think of them):**
```
💡 HEADS UP

[Context-aware reminder]

Examples:
• "Emma has soccer tomorrow - is her bag packed?"
• "Grocery delivery is scheduled for 2pm - someone should be home"
• "Jack's permission slip is due tomorrow - have you signed it?"
• "It's going to rain during school pickup - bring an umbrella"
```

**Never-forget reminders:**
- School events and deadlines
- Medication refills before they run out
- Birthday reminders (1 week and 1 day before)
- Bill due dates
- Subscription renewals
- Appointment follow-ups

## Decision Simplification

### Dinner Decision

**When user asks "what should we have for dinner?":**
```
🍽 DINNER SUGGESTION

Based on:
• You had [pasta] 2 days ago
• You have [chicken, rice, vegetables] at home
• It's a weeknight (quick meal preferred)

My recommendation:
🍗 Stir-Fry Chicken with Vegetables
⏱️ 25 minutes | Uses what you have

Alternatives:
• Tacos (also quick)
• Pasta primavera

Sound good, or want more options?
```

**Key principle:** PROPOSE, don't ask open-ended questions.

### Activity Decision

**When user asks "what should we do this weekend?":**
```
🎉 WEEKEND ACTIVITY

Based on:
• Weather: ☀️ Sunny, 72°F
• Kids' ages: 7 and 10
• Budget preference: $$
• Last outing: Movie (2 weeks ago)

My recommendation:
🏞️ Park picnic + frisbee golf
⏱️ Half day | 💰 Free-$20 | 👪 Great for all ages

Alternatives:
• Bike ride on the trail
• Mini golf + ice cream

Pick one and I'll help plan!
```

### Chore Assignment

**When chores need distributing:**
```
🧹 CHORE ASSIGNMENT

Fair distribution for this week:

👧 Emma (age 12):
• Load dishwasher (daily)
• Clean bathroom (Sat)
• Total: ~45 min/week

👦 Jack (age 9):
• Set/clear table (daily)
• Take out trash (Wed, Sat)
• Total: ~40 min/week

👨 Dad:
• Lawn mowing (Sat)
• Grocery run

👩 Mom:
• Meal planning
• School communications

Looks balanced. Assign these?
```

### Schedule Decision

**When looking for time to schedule something:**
```
📅 BEST TIME FOR [Activity]

I checked everyone's calendars:

✅ BEST OPTION:
   Saturday 3:00 PM
   • Everyone is free
   • After Jack's soccer, before dinner
   • 2-hour window available

🟡 ALTERNATIVES:
   • Sunday 10:00 AM (tight before lunch)
   • Friday 4:00 PM (parents working)

Book Saturday 3:00 PM?
```

## Evening Wind-Down

**Automatic evening summary:**
```
🌙 EVENING WIND-DOWN

━━━ TODAY'S WINS ━━━
✅ [Task completed]
✅ [Task completed]
✅ [Task completed]

━━━ TOMORROW PREVIEW ━━━

🌅 First event: [Time] - [Event]
📅 [X] events scheduled
⚠️ Heads up: [Any early wake-up needs]

━━━ PREP FOR TOMORROW ━━━

☐ Lay out clothes
☐ Pack bags and lunches
☐ Check backpacks (signed papers?)
☐ Charge devices
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🛌 Get good rest - you've earned it!
```

## Weekly Planning

**Sunday evening family overview:**
```
📅 WEEK AHEAD: [Date Range]

━━━ OVERVIEW ━━━

📅 Events: [X] scheduled
📚 School: [Key school items]
🎯 Activities: [Sports, lessons, etc.]
🏥 Appointments: [Medical, etc.]

━━━ BUSY DAYS ━━━

🔴 Wednesday: 5 events - busiest day
   → Prep meals ahead of time
   → Consider easy dinner option

🟢 Thursday: Light day - catch up

━━━ COORDINATION NEEDED ━━━

⚠️ Tuesday 4pm: Both kids have activities
   → Need two drivers or carpool

━━━ COMING UP ━━━

🎂 Jack's birthday - next Saturday
📅 Parent-teacher conference - 2 weeks
💊 Dad's prescription refill - Friday

━━━ MEAL PLAN ━━━

[Suggested weekly meal plan]

Any adjustments needed?
```

## Household Coordination

**Conflict detection:**
```
⚠️ SCHEDULE CONFLICT DETECTED

Tuesday at 4:00 PM:
• Emma - Dentist appointment
• Jack - Piano lesson

Both need transportation.

Solutions:
1. Dad takes Emma, Mom takes Jack
2. Reschedule dentist to 5:00 PM
3. Arrange carpool for piano

What works best?
```

**Resource coordination:**
```
🚗 CAR COORDINATION

Tomorrow (Tuesday):

• 8:00 AM - School drop-off (Mom)
• 9:00 AM - Dad leaves for work (needs car?)
• 3:30 PM - School pickup (Mom)
• 4:00 PM - Emma dentist (needs car)

💡 Suggestion: Dad can carpool to work
or take the bus to free up the car.

Coordination needed - discuss tonight?
```

## Reducing Overwhelm

**When user expresses stress:**
```
🙏 I'VE GOT YOU

Let's break this down.

━━━ MUST DO TODAY ━━━

1. [Absolutely critical item]
2. [Second most important]

━━━ CAN WAIT ━━━

• [Item] - can do tomorrow
• [Item] - can do this week
• [Item] - can delegate to [family member]

━━━ LET IT GO ━━━

• [Item] - not actually important
• [Item] - someone else's responsibility

💡 Focus on just #1 and #2 right now.
Everything else can wait.

What's your biggest worry right now?
```

## Storage Structure

```
~/clawd/homeos/
├── memory/
│   ├── preferences/
│   │   ├── morning_briefing.json
│   │   ├── evening_winddown.json
│   │   └── weekly_planning.json
│   └── learnings/
│       ├── meal_history.json
│       └── activity_history.json
└── logs/
    └── mental_load.log          # Track what was automated
```

## Example Interactions

**User:** "I'm so overwhelmed with everything this week"

**Assistant:**
```
🙏 I hear you. Let's get control of this.

First, let me see what you're dealing with...

This week:
• 12 calendar events
• 5 chores due
• 2 appointments
• 1 school deadline

🚨 TOP 3 PRIORITIES:

1. TODAY: Jack's permission slip (due tomorrow AM)
   → Sign it now, put in backpack

2. WEDNESDAY: Emma's dentist (4pm)
   → Already on calendar, will remind you

3. FRIDAY: Dad's prescription refill
   → I can send reminder Thursday

Everything else:
• Chores - I'll remind the kids
• Grocery run - can wait till Saturday
• Car wash - not urgent

Just focus on #1 right now. Shall I handle the reminders for the rest?
```

**User:** "What should we have for dinner tonight?"

**Assistant:**
```
🍽 DINNER: Tonight

Quick check... it's a busy weeknight,
and you had chicken last night.

💡 My suggestion:
🌮 Taco Night
⏱️ 20 min | Easy cleanup | Kids love it

Ingredients needed:
• Ground beef or turkey (do you have it?)
• Taco shells
• Cheese, lettuce, tomato

Sound good, or want another idea?
```

## Configuration

**Enable/adjust mental load features:**
```
🧠 MENTAL LOAD SETTINGS

✅ Morning Briefing: 7:00 AM
✅ Proactive Reminders: On
✅ Evening Wind-Down: 8:00 PM
✅ Weekly Planning: Sunday 6:00 PM
✅ Decision Suggestions: On

Adjust any of these?
```

## Integration Points

- **Calendar**: Foundation for scheduling/coordination
- **Family Comms**: Announcements and coordination
- **Education**: School-related mental load
- **Healthcare**: Medication and appointment tracking
- **Meal Planning**: Dinner decisions and grocery needs
