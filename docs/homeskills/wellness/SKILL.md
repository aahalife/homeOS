---
name: wellness
description: Track and encourage family wellness including hydration, movement, sleep, screen time, and energy optimization. Use when the user wants health tracking, needs wellness reminders, asks about healthy habits, or wants to set up wellness routines for family members.
---

# Wellness Skill

Practical, everyday wellness nudges that truly impact family life.

## Philosophy

- **Assume sensible defaults** - Don't ask, propose
- **Non-intrusive** - Helpful, not annoying
- **Family-aware** - Different needs for adults vs kids
- **Progress-focused** - Celebrate wins, don't shame

## When to Use

- User wants hydration reminders
- User asks about movement/exercise tracking
- User wants help with sleep schedules
- User needs screen time management
- User asks about healthy habits
- User wants wellness routines set up

## Wellness Components

| Component | Default Goal | Reminder Frequency |
|-----------|--------------|-------------------|
| Hydration | 64 oz/day | Every 90 min |
| Movement | 8,000 steps | After 60 min sedentary |
| Sleep | 8 hours | Wind-down + bedtime |
| Screen Time | 3 hours | Every 20 min (breaks) |
| Posture | N/A | Every 45 min |
| Energy | N/A | Key meal/activity times |

## Hydration Tracking

### Daily Hydration

**Hydration reminder:**
```
💧 HYDRATION CHECK

[Name], time for water!

🌡️ Today: Hot day (85°F) - extra hydration needed!

📊 Progress:
███████▓░░ 70% (45/64 oz)

19 oz to go - about 2.5 glasses 🥃

💡 Tip: Keep a water bottle at your desk!

[Log water] [Snooze 30 min] [Done for today]
```

**End of day summary:**
```
💧 HYDRATION SUMMARY - [Name]

Today: 58/64 oz (91%) 🌟
Streak: 7 days meeting goal!

📊 This Week:
Mon: 64 oz ✅
Tue: 60 oz 🟡
Wed: 64 oz ✅
Thu: 72 oz ✅ (hot day!)
Fri: 58 oz 🟡

Keep it up! 👍
```

**Configure hydration:**
```bash
cat > ~/clawd/homeos/memory/preferences/hydration.json << 'EOF'
{
  "member_id": "member-dad",
  "daily_goal_oz": 64,
  "reminder_interval_min": 90,
  "active_hours": {"start": "07:00", "end": "21:00"},
  "adjust_for_weather": true
}
EOF
```

## Movement & Activity

### Sedentary Alerts

**Movement nudge:**
```
🏃 MOVEMENT BREAK

Hey [Name]! You've been sitting for 65 minutes.

Quick options:
• 🚶 2-minute walk
• 🧘 Quick stretch at desk
• 🎯 Walk to refill water

Even 2 minutes helps!

[Log activity] [Snooze 15 min]
```

**Step tracking:**
```
👣 DAILY STEPS - [Name]

Current: 5,234 steps
Goal: 8,000 steps

██████░░░░ 65%

2,766 steps to go!
💡 A 15-minute walk = ~1,500 steps

Milestones:
✅ 5,000 steps - Halfway!
⏳ 7,000 steps - Almost there
⏳ 8,000 steps - Goal!
🌟 10,000 steps - Bonus!
```

### Activity Summary

```
🏃 WEEKLY ACTIVITY - [Name]

━━━ STEPS ━━━
Mon: 8,234 ✅
Tue: 6,123 🟡
Wed: 9,456 ✅
Thu: 4,567 ❌
Fri: 7,890 ✅
Sat: 12,345 ⭐
Sun: 5,678 🟡

Weekly Total: 54,293 steps
Daily Average: 7,756 steps

━━━ ACTIVE MINUTES ━━━
This week: 245 min (goal: 150 min) ✅

🎉 Great week! You exceeded your goal!
```

## Sleep Hygiene

### Wind-Down Reminder

**30 minutes before bedtime:**
```
🌙 WIND-DOWN TIME

Bedtime is in 30 minutes (10:00 PM).

Wind-down suggestions:
☐ Dim the lights
☐ Put away screens
☐ Light reading or relaxation
☐ Prep for tomorrow

😴 Goal: 7-8 hours of sleep
Wake time: 6:30 AM

Sweet dreams ahead! 🌟
```

### Bedtime Reminder

**At bedtime:**
```
🌙 BEDTIME - [Name]

Time to sleep!

🛌 Target sleep: 8 hours
⏰ Wake up: 6:30 AM

💡 Tonight's tip:
Your room should be cool (65-68°F) and dark.

Goodnight! 👤
```

### Sleep Tracking

```
😴 SLEEP SUMMARY - [Name]

━━━ LAST NIGHT ━━━
Bedtime: 10:15 PM
Wake: 6:30 AM
Sleep: 8h 15min ✅

━━━ THIS WEEK ━━━
Mon: 7h 30min ✅
Tue: 6h 45min 🟡
Wed: 8h 00min ✅
Thu: 5h 30min ❌ (late night)
Fri: 7h 15min ✅

Average: 7h 00min
Goal: 7-8 hours

💡 Sleep improved after Thursday's dip!
```

## Screen Time

### Screen Time Tracking

**For children:**
```
📱 SCREEN TIME - [Child Name]

Today: 1h 45min / 2h limit

████████▓░ 88%

15 minutes remaining today.

Breakdown:
• Educational: 45 min ✅
• Entertainment: 60 min

⏰ Limit reached notification in 15 min.

[Add time] [Pause tracking]
```

**Limit reached:**
```
📱 SCREEN TIME LIMIT

[Child Name], screen time is done for today!

You used your 2 hours - nice job staying within limit! ✅

Alternative activities:
• 📚 Read a book
• 🎨 Draw or craft
• 🎮 Board game with family
• ⚽ Go outside and play

What sounds fun?
```

### Eye Break Reminders

**Every 20 minutes of screen time:**
```
👁️ EYE BREAK

20-20-20 Rule:

Look at something 20 feet away
for 20 seconds.

Your eyes will thank you! 👀

[Done] [Snooze 5 min]
```

## Posture & Desk Breaks

### Posture Reminder

**Every 45 minutes during work hours:**
```
🧘 POSTURE CHECK

Time for a quick break!

Today's exercise:
💪 Shoulder Rolls
• 10 forward
• 10 backward
• 30 seconds total

Break #3 of 8 today.

[Done] [Skip]
```

### Desk Break Exercises

Rotating exercises:
```
💆 EXERCISE OPTIONS

1. Neck rolls (30 sec each direction)
2. Shoulder shrugs (10 reps)
3. Wrist circles (30 sec each direction)
4. Stand and stretch (1 min)
5. Walk to get water (2 min)
6. Look out window (1 min - rest eyes)
7. Deep breathing (5 breaths)
8. Desk push-ups (10 reps)
```

## Energy Optimization

### Meal Timing Nudges

**Morning:**
```
☕ MORNING ENERGY

Good morning! Start with:

💧 Glass of water - kickstarts metabolism
🍳 Breakfast with protein - sustained energy

☑️ Hydration logged?
☑️ Breakfast eaten?
```

**Afternoon dip prevention:**
```
⚡ AFTERNOON ENERGY

It's 2:00 PM - energy dip time!

To stay energized:
• 💧 Drink water (not coffee!)
• 🍎 Light healthy snack
• 🚶 Quick 5-min walk
• 🌞 Get some natural light

Avoid: Heavy snacks, more caffeine
```

**Evening wind-down:**
```
🌙 EVENING ENERGY

Preparing for tomorrow:

• Avoid heavy meals after 7 PM
• Limit caffeine after 2 PM
• Begin winding down screen use

Good sleep = good energy tomorrow!
```

## Family Wellness Dashboard

**Daily family overview:**
```
👪 FAMILY WELLNESS - [Date]

━━━ DAD ━━━
💧 Hydration: 50/64 oz (78%)
👣 Steps: 6,234/8,000 (78%)
😴 Sleep: 7h (last night)
Score: 🟢 Good

━━━ MOM ━━━
💧 Hydration: 56/64 oz (88%)
👣 Steps: 8,456/8,000 (106%) ⭐
😴 Sleep: 6.5h (last night) 🟡
Score: 🟢 Good

━━━ EMMA ━━━
💧 Hydration: Not tracked
📱 Screen time: 1.5h/2h
😴 Sleep: 9h (last night) ✅
Score: 🟢 Good

━━━ JACK ━━━
📱 Screen time: 2h/2h (limit reached)
😴 Sleep: 10h (last night) ✅
Score: 🟢 Good

🌟 FAMILY SCORE: 85/100
💡 Tip: Great day! Mom crushed her step goal!
```

## Wellness Setup

**Initial configuration:**
```
🌿 WELLNESS SETUP

Let's personalize wellness tracking for [Name].

1. 💧 HYDRATION
   Daily goal: [64 oz / custom]
   Remind every: [90 min / custom]

2. 🏃 MOVEMENT
   Step goal: [8,000 / custom]
   Sedentary alert: [60 min / custom]

3. 😴 SLEEP
   Bedtime: [10:00 PM / custom]
   Wake time: [6:30 AM / custom]
   Wind-down: [30 min before]

4. 📱 SCREEN TIME (kids)
   Daily limit: [2 hours / custom]
   Eye break: [Every 20 min]

5. 🧘 POSTURE (if working at desk)
   Break reminder: [Every 45 min]

Which would you like to enable?
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   └── wellness/
│       ├── hydration_log.json
│       ├── steps_log.json
│       ├── sleep_log.json
│       └── screen_time_log.json
├── memory/
│   └── preferences/
│       └── wellness/
│           ├── hydration.json
│           ├── movement.json
│           ├── sleep.json
│           └── screen_time.json
└── logs/
    └── wellness_reminders.log
```

## Example Interactions

**User:** "Set up hydration reminders for me"

**Assistant:**
```
💧 HYDRATION TRACKING SETUP

I'll set you up with smart hydration reminders!

Defaults (you can adjust):
• Daily goal: 64 oz (8 glasses)
• Reminders: Every 90 minutes
• Active hours: 7 AM - 9 PM
• ☑️ Adjust for hot weather

Looks good?
```

**User:** "Yeah, but make it 80 oz"

**Assistant:**
```
✅ HYDRATION TRACKING ENABLED

💧 Your settings:
• Daily goal: 80 oz
• Reminders: Every 90 minutes
• 7 AM - 9 PM
• Weather-adjusted

I'll send friendly reminders throughout the day.
Log your water intake by telling me:
"I drank a glass of water"
or "Log 16 oz water"

Let's stay hydrated! 💧
```

**User:** "Emma has been on her iPad too long"

**Assistant:**
```
📱 CHECKING SCREEN TIME - Emma

Today: 2h 15min
Limit: 2h

⚠️ She's 15 minutes over today's limit.

Options:
1. 🔔 Send "time's up" notification
2. 🔒 Request she put it away
3. ⏰ Set a 5-minute warning
4. ➕ Grant extra time (special occasion)

What would you like to do?
```

## Integration Points

- **Mental Load**: Wellness in morning/evening briefings
- **Family Comms**: Share wellness wins
- **Healthcare**: Connect to medication tracking
- **Calendar**: Block time for exercise/wellness
