---
name: habits
description: Track habits through conversational nudges while understanding behavioral factors like barriers, motivators, and stages of change. Use when the user wants to build habits, track progress, needs motivation, or asks for help with behavior change. Integrates stress awareness for adaptive support.
---

# Habits Skill

Track and nurture habits through understanding, not just tracking.

## Philosophy

Effective habit support requires:

1. **Understanding barriers** - What's actually stopping you?
2. **Identifying motivators** - What drives you?
3. **Meeting you where you are** - Stages of change model
4. **Stress-aware nudging** - Gentle when stressed, challenging when ready
5. **Conversational engagement** - Not just reminders, real support

## When to Use

- User wants to build or track habits
- User mentions struggling with consistency
- User asks for motivation or accountability
- User mentions wanting to change behavior
- User has active habits being tracked
- User mentions stress affecting habits

## Stages of Change Model

**Understanding where someone is:**

| Stage | Signs | Approach |
|-------|-------|----------|
| **Pre-contemplation** | "I don't need to change" | Raise awareness gently |
| **Contemplation** | "Maybe I should..." | Explore pros/cons |
| **Preparation** | "I'm going to start" | Plan concretely |
| **Action** | "I'm doing it" | Support & troubleshoot |
| **Maintenance** | "I've been doing it" | Prevent relapse |

### Stage Assessment

**Conversational assessment:**
```
🧠 UNDERSTANDING YOUR READINESS

You mentioned wanting to [habit].

Which best describes where you are?

1. 🤔 "I'm thinking about it but not sure"
   (Contemplation - let's explore)

2. 📋 "I've decided, I'm planning to start"
   (Preparation - let's plan)

3. 💪 "I've already started, need support"
   (Action - let's track & troubleshoot)

4. ✅ "I've been doing it, want to maintain"
   (Maintenance - let's solidify)

No judgment - just want to meet you where you are.
```

## Barrier Assessment

**Understanding what's in the way:**
```
🪨 BARRIER EXPLORATION

Let's understand what might get in the way of [habit].

Common barriers - which resonate?

⏰ TIME:
• "I don't have time"
• "My schedule is unpredictable"

💪 ENERGY:
• "I'm too tired"
• "I don't have motivation"

🧠 MENTAL:
• "I forget"
• "I don't know how to start"
• "It feels overwhelming"

🏠 ENVIRONMENT:
• "I don't have the right setup"
• "Others don't support it"

💔 EMOTIONAL:
• "I've failed before"
• "I don't believe I can do it"

Which barriers feel most real for you?
```

**Barrier-specific solutions:**
```
💡 OVERCOMING: [Barrier Type]

You mentioned: "[Their barrier]"

━━━ SOLUTIONS ━━━

For TIME barriers:
• Make habit smaller (2-minute rule)
• Attach to existing routine (habit stacking)
• Do it at non-negotiable time (morning)

For ENERGY barriers:
• Do it when energy is highest (morning?)
• Make it ridiculously easy to start
• Remove decision-making (automate choices)

For MENTAL barriers:
• Set up environmental cues
• Use implementation intentions (if-then)
• Start so small success is guaranteed

For ENVIRONMENT barriers:
• Redesign space for easy access
• Get support from key people
• Find accountability partner

For EMOTIONAL barriers:
• Start with identity shift ("I'm becoming someone who...")
• Focus on process, not outcomes
• Celebrate tiny wins immediately

Let's apply one of these. Which solution feels doable?
```

## Motivator Assessment

**Understanding what drives them:**
```
🔥 MOTIVATION EXPLORATION

Why does [habit] matter to you?

Deep motivators:

1. 👪 RELATIONSHIPS
   "I want to be there for my family"
   "I want to be a good role model"

2. 🏆 ACHIEVEMENT
   "I want to accomplish something"
   "I want to prove I can"

3. ❤️ SELF-CARE
   "I want to feel better"
   "I deserve this"

4. 🎯 PURPOSE
   "This aligns with who I want to be"
   "This connects to my values"

5. 🙏 GROWTH
   "I want to become better"
   "I want to learn and improve"

What's YOUR core reason?
```

**Use motivator in nudges:**
```
💬 MOTIVATOR-BASED NUDGE

[When nudging someone motivated by family]

"Remember, every time you [habit], you're showing 
[kids/spouse] what's possible. You're not just 
building a habit - you're building a legacy."

[When nudging someone motivated by achievement]

"Day [X] of your streak! You're in the top 10% 
of people who make it this far. Keep going."
```

## Stress-Aware Nudging

### Stress Level Integration

**How stress affects approach:**

| Stress Level | Nudge Style | Expectation |
|--------------|-------------|-------------|
| Low (1-3) | Encouraging, challenging | Full habit |
| Medium (4-6) | Supportive, flexible | Scaled habit |
| High (7-10) | Compassionate, minimal | Tiny version |

### Adaptive Nudges

**Low stress nudge:**
```
💪 HABIT CHECK-IN

Hey! You're having a good day (stress: low).
Perfect time to crush your [habit].

Full version: [Complete habit]
Streak: [X] days

You've got this! 🔥
```

**Medium stress nudge:**
```
💬 HABIT CHECK-IN

I know you've got some stuff going on (stress: medium).
No pressure - just checking in about [habit].

Options:
• Full version: [Complete habit]
• Lighter version: [Scaled down]
• Skip today (no guilt)

What works for you right now?
```

**High stress nudge:**
```
🤗 GENTLE CHECK-IN

I see things are tough right now (stress: high).

Your only job: Be kind to yourself.

If you want, here's the tiniest version:
"🪨 [Absolute minimum action]"

But honestly? Self-care IS the habit today.
Rest if you need to. We'll be here tomorrow.

[Skip without guilt] [Do tiny version]
```

## Conversational Habit Tracking

### Daily Check-In (AI Chat Style)

**Morning prompt:**
```
🌅 Good morning!

Your habits for today:

☐ [Habit 1] - [when/cue]
☐ [Habit 2] - [when/cue]

How are you feeling about today?

[Ready 💪] [Meh 😐] [Struggling 😓]
```

**Response to "Ready":**
```
🔥 Let's go!

Remember your why: "[Their motivator]"

I'll check in later. You've got this!
```

**Response to "Struggling":**
```
🤗 I hear you.

What's making it hard today?

• Low energy
• Too busy
• Not feeling it
• Something else

[Let's talk through it]
```

### Evening Reflection

**End of day check:**
```
🌙 End of Day Check-In

How did it go?

🎯 [Habit 1]: [Did it? Yes/No/Partial]
🎯 [Habit 2]: [Did it? Yes/No/Partial]

[Quick update] [Tell me more]
```

**If completed:**
```
🎉 Amazing!

[Habit] ✅ Done!
🔥 Streak: [X] days

What made it work today?
(This helps me help you)

[Easy day] [Good setup] [Felt motivated] [Other]
```

**If missed:**
```
💬 No worries.

Missing one day is normal. The key is:
• Never miss twice in a row
• Understand what happened
• Adjust and move forward

Quick check - what got in the way?

[Time] [Energy] [Forgot] [Life happened] [Other]
```

**If "Life happened":**
```
🤗 Life does that.

Some days, just surviving IS the win.
Your habit isn't going anywhere.

Let's focus on tomorrow:
• Same plan, or
• Adjust something?

[Keep same plan] [Let's adjust]
```

## Habit Conversation Flows

### Weekly Reflection

**Sunday conversation:**
```
📊 WEEKLY REFLECTION

Hey! Let's look at your week.

[Habit 1]: [X]/7 days (83%)
[Habit 2]: [X]/7 days (71%)

🌟 WINS:
• [Specific win observed]
• [Another win]

🤔 PATTERNS I NOTICED:
• You tend to miss on [day] - busy day?
• Morning habits stronger than evening

💬 Let's chat:

1. What worked well this week?
2. What was hardest?
3. Any adjustments for next week?
```

### Streak Celebrations

**Milestone celebrations:**
```
🎉 MILESTONE: [X] DAY STREAK!

🔥 You've done [habit] for [X] days straight!

That's:
• [X] times you showed up for yourself
• [X] times you overcame inertia
• [X] steps toward who you're becoming

🌟 What this means:

7 days: "You've proven you can start."
21 days: "You're building real momentum."
30 days: "This is becoming part of you."
66 days: "Science says this is habit now."
100 days: "You're in rare company. Wow."

Keep going - you're becoming someone new.
```

### Relapse Support

**After streak break:**
```
💬 STREAK PAUSE - Let's Talk

I noticed [habit] paused after [X] days.
That's okay. Really.

📝 The facts:
• You built a [X]-day streak before
• That proves you CAN do this
• Starting again is always an option

🤔 Let's understand:

What happened?

• Life got chaotic
• Lost motivation
• Habit felt too hard
• It stopped mattering
• Other

[Let's talk through it]

💪 When you're ready:

We can start fresh. No judgment.
Every expert was once a beginner who kept starting.
```

## Habit Portfolio

**Managing multiple habits:**
```
📊 YOUR HABIT PORTFOLIO

━━━ ACTIVE HABITS ━━━

1. 🧘 Morning meditation (2 min)
   Streak: 23 days | Success: 85%
   Stage: Maintenance ✅

2. 📚 Read before bed (10 min)
   Streak: 5 days | Success: 62%
   Stage: Action 🟡

3. 💪 Exercise (NEW)
   Streak: 0 days | Success: -
   Stage: Preparation 🟠

━━━ HABIT CAPACITY ━━━

Active: 3 | Recommended max: 3

⚠️ Note: Adding more habits reduces 
success rate. Solidify current before adding.

━━━ SUGGESTIONS ━━━

• Meditation is solid - celebrate!
• Reading needs attention - let's troubleshoot
• Exercise is new - keep it tiny
```

## AI Chat Integration

**For integration with AI chat endpoint:**

**Request format:**
```json
{
  "user_id": "user_123",
  "message": "How's my morning meditation going?",
  "stress_level": 4,
  "context": {
    "habits": [...],
    "recent_completions": [...],
    "barriers": [...],
    "motivators": [...]
  }
}
```

**Response format:**
```json
{
  "response": "Your meditation streak is at 23 days! 
               That's amazing consistency. 
               Yesterday you mentioned feeling calmer - 
               the practice is working!",
  "suggested_actions": [
    {"type": "celebration", "trigger": "milestone_30"},
    {"type": "nudge", "habit": "meditation", "time": "07:00"}
  ],
  "stress_adapted": true
}
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   └── habits/
│       ├── active_habits.json
│       ├── habit_log.json
│       ├── barriers.json
│       ├── motivators.json
│       └── conversations.json
├── memory/
│   └── learnings/
│       ├── habit_patterns.json
│       └── what_works.json
└── logs/
    └── habit_conversations.log
```

## Example Interactions

**User:** "I keep failing at exercising"

**Assistant:**
```
💬 Let's understand what's happening.

"Failing" means you've been trying - that counts.

🤔 Quick questions:

1. What exercise are you attempting?
   [Running / Gym / Home workout / Other]

2. When have you tried to do it?
   [Morning / Evening / Whenever]

3. What usually stops you?
   [Time / Energy / Motivation / Not sure]

Let's figure this out together.
```

**User:** "I don't have time and I'm tired after work"

**Assistant:**
```
⚛️ ATOMIC REDESIGN

Time + Energy = Classic combo barrier.

Here's the truth:
• You don't need an hour.
• You don't need to be energized.
• You need something so small you can't fail.

🎯 NEW APPROACH:

"After I get home, I do 1 pushup."

That's it. One pushup.

🤔 You're thinking: "That won't do anything."

But here's what it does:
• Breaks the "I don't exercise" identity
• Creates a foothold habit
• Often leads to "well, I'll do 5 more"
• Builds the showing-up muscle

After 2 weeks of 1 pushup, we can talk about more.

Can you commit to 1 pushup after walking in the door?
```

**User:** "Fine, I'll try"

**Assistant:**
```
✅ HABIT SET UP

🎯 Your habit:
"After I walk in the door, I do 1 pushup."

🔒 YOUR COMMITMENT:
• Just 1 pushup
• Right when you get home
• Before anything else

💰 The deal:
• Even exhausted: 1 pushup
• Even bad day: 1 pushup
• No exceptions: 1 pushup

But you're NEVER required to do more.
More is optional. One is mandatory.

⏰ I'll check in tomorrow evening.

🔥 Day 1 starts today.

You've got this. One pushup. Prove yourself right.
```

## Integration Points

- **Note to Actions**: Create habits from content
- **Wellness**: Health habit tracking
- **Mental Load**: Stress-aware habit management
- **Calendar**: Habit reminder scheduling
- **Family Comms**: Family habit challenges
