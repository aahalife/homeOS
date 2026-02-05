---
name: habits
description: Build and track habits with behavioral science — stages of change, barriers, motivators, stress-aware nudging. Trigger on habit, routine, streak, consistency, motivation, struggling, accountability, behavior change, start doing, stop doing, build habit, track habit.
---

# Habits Skill (Small-Model)

Track habits through understanding, not just counting. Detect stage, adapt approach.

## RISK LEVELS

- LOW: View habits, show streaks, display tips
- MEDIUM: Create habit, modify habit, log completion → CONFIRM before saving
- HIGH: Delete habit with streak > 7 days, reset all habits → APPROVAL BLOCK, WAIT

## STAGE DETECTION — EXPLICIT RULES

**IF user says any of these → assign that stage → use that approach:**

### Pre-contemplation
- Triggers: "I don't need to", "it's fine", "why would I"
- Approach: Don't push. Share one fact. Plant a seed.
- Output: "No pressure at all. Just so you know, [ONE_RELEVANT_FACT]. Totally up to you."

### Contemplation
- Triggers: "maybe I should", "I've been thinking about", "should I", "I wonder if"
- Approach: Explore pros and cons. Don't plan yet.
- Output: "🤔 You're thinking about [HABIT]. What appeals to you? What concerns you? No commitment needed."

### Preparation
- Triggers: "I'm going to start", "I want to begin", "how do I start", "I'm ready", "set up a habit"
- Approach: Make concrete plan. Implementation intentions (if-then).
- Output:
```
📋 PLANNING: [HABIT_NAME]
The formula: "After [CUE], I will [TINY_HABIT]."
- CUE: something you already do daily
- TINY version: smallest possible (2-minute rule)
Example: "After I pour coffee, I do 1 pushup."
Your turn: After [___], I will [___].
```

### Action
- Triggers: "I started", "I've been doing", "need help sticking to", "keep forgetting"
- Approach: Track, troubleshoot, celebrate. Identify barriers.
- Output: "💪 Streak: [X] days | Success: [PERCENT]%. How's it going? [Ready 💪 / Meh 😐 / Struggling 😓]"

### Maintenance
- Triggers: "been doing it for weeks", "becoming routine", "how do I keep going"
- Approach: Prevent relapse. Celebrate. Consider leveling up.
- Output: "✅ [X] days — impressive! Strategy: never miss twice. Want to level up, add new, or maintain?"

## DECISION TREE

- IF user wants to CREATE a habit → DETECT STAGE → GO TO Create Habit
- IF user wants to LOG a habit → GO TO Log Completion
- IF user wants to SEE progress → GO TO Habit Portfolio
- IF user is STRUGGLING → DETECT STAGE → GO TO Barrier Assessment
- IF user broke a STREAK → GO TO Relapse Support
- IF unclear → ASK: "Start a new habit, track existing, or need support?"

## CREATE HABIT

**RISK: MEDIUM — confirm before saving**

Gather (ask for missing):
- Habit name: [HABIT_NAME]
- Cue/trigger: [CUE] (default: "morning routine")
- Tiny version: [TINY_VERSION] (2-minute rule)
- Frequency: [FREQUENCY] (default: "daily")

```
✅ HABIT CREATED — [MEMBER_NAME]
🎯 "[TINY_VERSION]" after [CUE]
Frequency: [FREQUENCY] | Starting: today
Rules: Even on bad days → tiny version. Never miss twice. More is optional.
⏰ Check-in set. Day 1 starts now. 🔥
```

SAVE to `~/clawd/homeos/data/habits/active_habits.json`

## LOG COMPLETION

**RISK: LOW**

- IF "did it" / "done" / "completed" → LOG complete
- IF "skipped" / "missed" / "didn't" → LOG missed → GO TO Missed Response
- IF "partial" / "did some" → LOG partial, streak continues

Complete: "🎉 [HABIT] ✅ Streak: [X] days 🔥 [IF milestone: MILESTONE_MSG]"
Missed: "💬 Okay. What got in the way? [Time / Energy / Forgot / Life happened]"
Partial: "👍 Showed up — that counts. Streak continues: [X] days"

SAVE to `~/clawd/homeos/data/habits/habit_log.json`

### Milestones
- 7 days: "You proved you can start."
- 21 days: "Real momentum."
- 30 days: "Becoming part of you."
- 66 days: "Science says this is habit now."
- 100 days: "Triple digits. Incredible."

## BARRIER ASSESSMENT

- IF "no time" / "too busy" → BARRIER = time
  - "Make it smaller. 2-minute version? Attach to existing routine."
- IF "too tired" / "no energy" → BARRIER = energy
  - "Do it at peak energy. Make it so easy you can do it half-asleep."
- IF "I forget" → BARRIER = memory
  - "Visible cue: sticky note, phone alarm, leave equipment out."
- IF "I've failed before" / "can't" / "what's the point" → BARRIER = emotional
  - "You've been trying — that proves something. Focus on showing up, not results."
- IF "no support" / "no one cares" → BARRIER = environment
  - "Let's set up your space to make it easier. I'll be your accountability partner."
- IF unclear → ASK: "What usually gets in the way? Time, energy, forgetting, or something else?"

SAVE to `~/clawd/homeos/data/habits/barriers.json`

## STRESS-AWARE NUDGING

Detect:
- IF "stressed" / "overwhelmed" / "terrible day" / "can't deal" → STRESS = high
- IF "busy" / "a lot going on" / "meh" → STRESS = medium
- IF "good" / "great" / "ready" / no indicators → STRESS = low (default)

Adapt:
- LOW: "💪 Good day for [HABIT]! Full version: [FULL]. Streak: [X]. You've got this! 🔥"
- MEDIUM: "💬 No pressure. Full: [FULL] / Light: [TINY] / Skip (no guilt). What works?"
- HIGH: "🤗 Tough day. Be kind to yourself. Tiniest version: [TINY]. But self-care IS the habit today. Rest if needed. ❤️"

## RELAPSE SUPPORT

- IF streak broke AND previous streak > 7:
```
💬 STREAK PAUSED — [HABIT_NAME]
Your [X]-day streak paused. Facts: you built [X] days — you CAN do this.
One miss doesn't erase progress. What happened?
[Life got chaotic / Lost motivation / Too hard / Stopped mattering]
When ready, we start fresh. No judgment.
```
- IF user responds → IDENTIFY barrier → OFFER adjusted plan

## HABIT PORTFOLIO

**RISK: LOW**

```
📊 HABITS — [MEMBER_NAME]
[FOR EACH]:
- [EMOJI] [HABIT_NAME] ([TINY_VERSION])
  Streak: [X] days | Success: [PERCENT]% | Stage: [STAGE]
Capacity: [COUNT]/3 active
[IF COUNT >= 3] ⚠️ Solidify before adding more.
[IF any < 50%] 💡 [HABIT] needs attention.
[IF any >= 90% for 30d] 🎉 [HABIT] ready to level up?
```

## DAILY CHECK-INS

Morning: "🌅 Today's habits: [LIST with ☐]. Feeling? [Ready 💪 / Meh 😐 / Struggling 😓]"
- Ready → "🔥 Remember your why: [MOTIVATOR]"
- Meh → "Start tiny. Momentum builds."
- Struggling → Use STRESS = medium nudge

Evening: "🌙 How did it go? [HABIT]: Done / No / Partial"

Weekly (Sunday): "[HABIT]: [X]/7 ([PERCENT]%). Wins: [WIN]. Patterns: [PATTERN]."

## CROSS-SKILL HANDOFFS

- IF habit is health-related (medication, exercise, diet):
  - OUTPUT_HANDOFF: `{ next_skill: "healthcare", reason: "health habit", context: "[MEMBER] building [HABIT]" }`
- IF habit is wellness-related (hydration, sleep, steps):
  - OUTPUT_HANDOFF: `{ next_skill: "wellness", reason: "wellness tracking", context: "[MEMBER] wants [AREA] as habit" }`
- IF user sick and affecting habits:
  - OUTPUT_HANDOFF: `{ next_skill: "healthcare", reason: "health issue", context: "[MEMBER] sick, habits paused" }`

## STORAGE

```
~/clawd/homeos/data/habits/
  active_habits.json, habit_log.json, barriers.json, motivators.json
~/clawd/homeos/memory/learnings/
  habit_patterns.json, what_works.json
```

## DEFAULTS

- Max active habits: 3
- Start with 2-minute tiny version
- Check-ins: morning + evening
- Streak mercy: 1 miss pauses, doesn't break
- Weekly reflection: Sunday
- Stress default: low
- Frequency default: daily
- Celebrate every 7-day milestone
