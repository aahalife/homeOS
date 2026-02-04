---
name: note-to-actions
version: small-model
description: Transform articles, videos, books, ideas into atomic habits using the 4 Laws of Behavior Change. Use when user shares a URL, article, book idea, or says "how do I actually do this?"
risk: low
---

# Note-to-Actions Skill (Small-Model)

Turn content and ideas into concrete atomic habits.

**SCOPE: URL/text → insights → one actionable habit with implementation plan.**
**METHOD: James Clear's 4 Laws — Obvious, Attractive, Easy, Satisfying.**

## TRIGGERS

IF message contains: URL, "I read", "I watched", "I heard", "how do I apply", "how do I start", "turn this into action", "I want to start", article, book, podcast, video
THEN activate this skill.

## STORAGE

- Active habits: ~/clawd/homeos/data/habits/active.json
- Habit log: ~/clawd/homeos/data/habits/log.json
- Content library: ~/clawd/homeos/data/habits/content.json
- Patterns: ~/clawd/homeos/memory/habit-patterns.json

## STEP 1: INTAKE

IF input is a URL → fetch content, then extract insights.
IF input is text/idea → extract insights directly.
IF input is vague ("I want to be healthier") → ask ONE clarifying question:
"What specific thing prompted this? An article, a thought, a conversation?"

## STEP 2: EXTRACT INSIGHTS

Produce exactly 3 key insights from the content.

```
📝 [Title or Topic]

Key Insights:
1. [Insight] — [one-line why it matters]
2. [Insight] — [one-line why it matters]
3. [Insight] — [one-line why it matters]

Core takeaway: "[Single sentence]"
```

Save to content library:
```bash
cat >> ~/clawd/homeos/data/habits/content.json << 'EOF'
{"date":"DATE","source":"URL_OR_TOPIC","insights":["1","2","3"],"takeaway":"SENTENCE"}
EOF
```

## STEP 3: IDENTIFY HABITS

From insights, extract 1-3 possible habits. For each:

```
🎯 HABITS FROM THIS CONTENT

1. [Habit name]
   Behavior: "[Specific observable action]"
   Difficulty: [Easy / Medium / Hard]
   Time: [X min]
   Impact: [High / Medium / Low]

2. [Habit name]
   Behavior: "[Specific observable action]"
   Difficulty: [Easy / Medium / Hard]
   Time: [X min]
   Impact: [High / Medium / Low]

💡 Start with: #[X] — [reason: easiest, highest impact, or best fit]

Pick one, or want my recommendation?
```

DEFAULTS:
- Always recommend the EASIEST habit first, not the highest impact
- IF equal difficulty → recommend highest impact
- Never recommend more than one habit to start

## STEP 4: MAKE IT ATOMIC (2-Minute Rule)

Take the chosen habit and shrink it.

```
⚛️ ATOMIC VERSION

Full habit: "[Full version]"
↓
Atomic version: "[2-minute or less version]"

The idea: so easy you can't say no.
Once you start, momentum carries you.
```

RULES for atomic versions:
- Must take under 2 minutes
- Must be a single physical action
- Must not require willpower
- Examples: "Put on running shoes" not "Run 5K". "Open the book" not "Read 30 pages". "Write one sentence" not "Journal for 10 minutes".

## STEP 5: APPLY THE 4 LAWS

Build the full implementation plan.

```
📋 IMPLEMENTATION PLAN: [Habit Name]

━━━ LAW 1: MAKE IT OBVIOUS (Cue) ━━━

Habit stack: "After I [EXISTING HABIT], I will [NEW HABIT]."
→ Your version: "After I _________, I will _________."

Environment change: [One specific physical change]
Example: "Put book on pillow so you see it at bedtime."

━━━ LAW 2: MAKE IT ATTRACTIVE (Craving) ━━━

Temptation bundle: "After I [NEW HABIT], I get to [REWARD HABIT]."
→ Your version: "After I _________, I get to _________."

[Suggest a specific bundle based on context]

━━━ LAW 3: MAKE IT EASY (Response) ━━━

2-minute version: "[Atomic version from Step 4]"

Reduce friction:
- [One prep step for tonight/today]
- [One thing to remove or set out]

Rule: Do ONLY the 2-minute version for the first 2 weeks. Do not expand.

━━━ LAW 4: MAKE IT SATISFYING (Reward) ━━━

Immediate reward: [Specific small reward right after]
Tracking: I'll ask you daily — "Did you [habit]?"
Streak goal: 7 days first, then 21, then 66.

Micro-celebration: [Specific action — fist pump, checkmark, say "done!"]
```

COMMON HABIT STACKS (suggest from these):
- Morning: "After I pour coffee..." / "After I brush teeth..." / "After I sit at desk..."
- Evening: "After I eat dinner..." / "After kids are in bed..." / "Before I get in bed..."
- Transition: "When I get home..." / "After I park the car..." / "When I pick up my phone..."

## STEP 6: ACTIVATE

```
✅ HABIT ACTIVATED

🎯 "[Full habit statement]"
⚛️ Atomic: "[2-min version]"
⏰ Cue: "After [trigger]"
📊 Tracking: daily check-in starts tomorrow

First check-in: [tomorrow's date]
I'll ask: "Did you [atomic habit] today?"
```

Save:
```bash
cat >> ~/clawd/homeos/data/habits/active.json << 'EOF'
{"habit":"NAME","atomic":"2MIN_VERSION","cue":"TRIGGER","reward":"REWARD","start":"DATE","streak":0,"status":"active"}
EOF
```

## DAILY CHECK-IN

When checking in on active habits:

IF user says yes:
```
✅ [Habit] done!
🔥 Streak: [X] days
[Encouraging one-liner based on streak length]
```

IF user says no:
```
No worries — never miss twice in a row.
What got in the way? [Wait for answer]
💡 Adjustment: [Suggest one specific change to make tomorrow easier]
```

IF user says partial:
```
Partial counts! You showed up.
🔥 Streak: [X] days (kept alive)
```

STREAK MILESTONES:
- 7 days → "🎉 One week! The habit is forming."
- 21 days → "🎉 Three weeks! This is becoming automatic."
- 66 days → "🎉 66 days! Research says this is habit territory."

## WEEKLY HABIT REPORT

```
📊 HABIT REPORT - Week of [Date]

[Habit Name]:
Mon: [✅/❌] Tue: [✅/❌] Wed: [✅/❌] Thu: [✅/❌] Fri: [✅/❌] Sat: [✅/❌] Sun: [✅/❌]

Success: [X]/7 ([percent]%)
Streak: [X] days
Best streak: [X] days

💡 Pattern: [observation, e.g. "You miss on Wednesdays — busy day?"]
🎯 Next week: [One adjustment suggestion]
```

## OUTPUT_HANDOFF

TO education skill:
- WHEN: content is about study techniques or learning methods for a child
- PASS: {"handoff":"education","reason":"study habit for child","child":"NAME","habit":"DESCRIPTION"}

TO psy-rich skill:
- WHEN: extracted habit is experiential (try new things, explore, etc.)
- PASS: {"handoff":"psy-rich","reason":"experiential habit","habit":"DESCRIPTION","member":"NAME"}

FROM any skill:
- WHEN: another skill identifies content to turn into habits
- EXPECT: {"handoff":"note-to-actions","content":"TEXT_OR_URL","context":"WHY"}

## ERROR HANDLING

IF URL fails to load → "I couldn't access that link. Can you paste the key points or a summary?"
IF content too vague to extract habits → "I see the idea but need more specifics. What part resonated most with you?"
IF user already has 3+ active habits → "You have [X] active habits already. Research shows focusing on one at a time works best. Want to review current habits first?"
IF habit is too big → auto-shrink it and explain: "That's great but too big to start. Let me make it atomic..."
