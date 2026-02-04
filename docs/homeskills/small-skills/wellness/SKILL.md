---
name: wellness
description: Track family wellness — hydration, steps, sleep, screen time, energy. Trigger on water, hydration, steps, walk, movement, sleep, bedtime, screen time, energy, tired, posture, break, wellness, health tracking.
---

# Wellness Skill (Small-Model)

Daily wellness nudges for the whole family. Propose defaults, don't interrogate.

## DEFAULTS

Adults: 64 oz water/day, 8,000 steps, 8h sleep (bed 10 PM, wake 6 AM), eye breaks every 20 min
Teens (13-17): 64 oz water, 8,000 steps, 9h sleep (bed 9:30 PM), 3h screen limit
Kids (6-12): 40 oz water, 10,000 steps, 10h sleep (bed 8:30 PM), 2h screen limit
Under 6: 32 oz water, 11h sleep (bed 7:30 PM), 1h screen limit
Aging parents (65+): 64 oz water, 6,000 steps, 7-8h sleep (bed 10 PM)
Sedentary alert: 60 min sitting. Posture break: every 45 min (work hours).

## RISK LEVELS

- LOW: Show progress, display tips, view logs
- MEDIUM: Set up reminders, change goals → CONFIRM before saving
- HIGH: Override child screen time limits, disable safety reminders → APPROVAL BLOCK, WAIT

## DECISION TREE

### Step 1: What component?

- IF "water" / "hydration" / "drink" / "thirsty" → Hydration
- IF "steps" / "walk" / "move" / "exercise" / "sedentary" → Movement
- IF "sleep" / "bed" / "tired" / "insomnia" / "wake" → Sleep
- IF "screen" / "iPad" / "phone" / "TV" / "gaming" → Screen Time
- IF "energy" / "fatigue" / "afternoon slump" → Energy
- IF "posture" / "break" / "stretch" → Posture
- IF "dashboard" / "overview" / "how's everyone" → Family Dashboard
- IF "setup" / "configure" → Setup
- IF unclear → ASK: "Hydration, movement, sleep, screen time, or something else?"

### Step 2: Who?

- IF user specifies name → USE that member
- IF "family" / "everyone" → Family Dashboard
- IF not specified → ASK: "For which family member?"

### Step 3: Age adjustment

- IF age < 6 → under-6 defaults
- IF age 6-12 → kid defaults
- IF age 13-17 → teen defaults
- IF age 18-64 → adult defaults
- IF age 65+ → aging-parent defaults

## HYDRATION

### Reminder (RISK: LOW)
```
💧 HYDRATION — [MEMBER_NAME]
Progress: [CURRENT_OZ]/[GOAL_OZ] oz ([PERCENT]%)
Remaining: [REMAINING_OZ] oz (~[GLASSES] glasses)
[IF weather_hot] 🌡️ Hot day — drink extra!
[IF member_sick] 🤒 Extra fluids while recovering.
💡 [RANDOM_TIP]
```

Tips (rotate): Keep bottle at desk / Glass before each meal / Add lemon for flavor / One glass when you wake up

### Log Water
- IF "drank water" / "had a glass" / "log water" → ADD 8 oz (default)
- IF user specifies amount → ADD that amount
- IF goal reached → "🎉 [MEMBER] hit [GOAL] oz today!"
- SAVE to `~/clawd/homeos/data/wellness/hydration_log.json`

### Summary
```
💧 SUMMARY — [MEMBER_NAME]
Today: [TOTAL]/[GOAL] oz
[IF >= 100%] ✅ Goal met! [IF >= 75%] 🟡 Almost [IF < 75%] ❌ Below target
Streak: [X] days meeting goal
```

## MOVEMENT

### Sedentary Alert (RISK: LOW)
```
🏃 MOVE — [MEMBER_NAME]
Sitting for [MINUTES] min. Quick options:
- 🚶 2-min walk
- 🧘 Desk stretch
- 💧 Refill water
```

### Step Progress
```
👣 STEPS — [MEMBER_NAME]
[CURRENT]/[GOAL] ([PERCENT]%)
[IF < 50%] 💡 15-min walk ≈ 1,500 steps
[IF >= 50%, < 100%] 💡 Almost there!
[IF >= 100%] ⭐ Goal smashed!
```

- IF "went for a walk" + no number → ASK duration, estimate 100 steps/min
- SAVE to `~/clawd/homeos/data/wellness/steps_log.json`

## SLEEP

### Wind-Down (30 min before bedtime, RISK: LOW)
```
🌙 WIND-DOWN — [MEMBER_NAME]
Bedtime in 30 min ([BEDTIME]).
- ☐ Dim lights, put away screens
[IF child] - ☐ Brush teeth, pajamas, bedtime story
Goal: [HOURS]h sleep | Wake: [WAKE_TIME]
```

### Bedtime
"🌙 Time to sleep, [MEMBER]! Target: [HOURS]h. Wake: [WAKE_TIME]. Tip: Keep room cool (65-68°F) and dark."

### Log Sleep
- IF "slept well" + no hours → LOG default hours
- IF "bad night" → LOG below target, ASK: "Trouble falling asleep, woke up early, or restless?"
- SAVE to `~/clawd/homeos/data/wellness/sleep_log.json`

### Summary
```
😴 SLEEP — [MEMBER_NAME]
Last night: [HOURS]h [IF >= target ✅] [IF target-1 to target 🟡] [IF < target-1 ❌]
Week avg: [AVG]h | Goal: [TARGET]h
```

## SCREEN TIME

### Check (RISK: LOW, for children)
```
📱 SCREEN — [CHILD_NAME]
Today: [USED] / [LIMIT] | Remaining: [LEFT]
[IF LEFT <= 15min] ⏰ Almost at limit!
[IF LEFT <= 0] 🛑 Limit reached.
```

### Limit Reached
"📱 Done for today, [CHILD]! Try: 📚 Book / 🎨 Art / 🎮 Board game / ⚽ Outside"

### Extend — HIGH RISK
```
🛑 APPROVAL REQUIRED
Extend [CHILD]'s screen time by [EXTRA]?
Type "APPROVE EXTEND [CHILD] [EXTRA]" to confirm.
```
WAIT for explicit approval. IF approved → UPDATE limit, LOG reason.

### Eye Break (every 20 min)
"👁️ 20-20-20: Look 20 feet away for 20 seconds."

## ENERGY

Morning: "☕ Start strong: 💧 Water first, 🍳 Protein breakfast. [IF has meds] 💊 Medication!"
- OUTPUT_HANDOFF: `{ next_skill: "healthcare", reason: "morning meds", context: "[MEMBER] morning routine" }`

Afternoon (2-3 PM): "⚡ Energy dip! Try: 💧 Water (not coffee), 🍎 Light snack, 🚶 5-min walk, 🌞 Natural light"

## POSTURE (every 45 min, work hours, RISK: LOW)

Exercises (rotate): Neck rolls 30s / Shoulder shrugs 10x / Wrist circles 30s / Stand & stretch 1 min / Walk for water / Deep breathing 5x

"🧘 BREAK #[N] — [EXERCISE_NAME]: [INSTRUCTIONS]"

## FAMILY DASHBOARD (RISK: LOW)

```
👪 FAMILY WELLNESS — [DATE]
[FOR EACH MEMBER]:
━━━ [NAME] ([ROLE]) ━━━
[IF hydration] 💧 [CURRENT]/[GOAL] oz ([PERCENT]%)
[IF steps] 👣 [CURRENT]/[GOAL] ([PERCENT]%)
[IF sleep] 😴 [HOURS]h [STATUS_EMOJI]
[IF child + screen] 📱 [USED]/[LIMIT]
🌟 Highlight: [BEST_TODAY]
```

Status: ≥100% → ✅ | ≥75% → 🟡 | <75% → ❌ | over goal → ⭐

## SETUP (RISK: MEDIUM — confirm before saving)

```
🌿 SETUP — [MEMBER_NAME] ([AGE] yrs)
Defaults: 💧 [OZ] oz/day | 👣 [STEPS]/day | 😴 [HOURS]h, bed [TIME]
[IF child] 📱 [LIMIT]/day
[IF desk worker] 🧘 Breaks every 45 min
Adjust anything, or enable these?
```
- IF "looks good" / "yes" → SAVE to `~/clawd/homeos/memory/preferences/wellness/`
- IF changes → UPDATE, confirm again

## CROSS-SKILL HANDOFFS

- IF user mentions feeling sick:
  - OUTPUT_HANDOFF: `{ next_skill: "healthcare", reason: "symptom", context: "[MEMBER] reported [SYMPTOM]" }`
- IF user wants wellness as a habit ("make hydration a habit"):
  - OUTPUT_HANDOFF: `{ next_skill: "habits", reason: "habit formation", context: "[MEMBER] wants [AREA] as habit" }`
- IF child consistently exceeds screen time:
  - OUTPUT_HANDOFF: `{ next_skill: "habits", reason: "behavior change", context: "[CHILD] exceeded screen [X] times this week" }`

## STORAGE

```
~/clawd/homeos/data/wellness/
  hydration_log.json, steps_log.json, sleep_log.json, screen_time_log.json
~/clawd/homeos/memory/preferences/wellness/
  [member_id]_hydration.json, [member_id]_movement.json
  [member_id]_sleep.json, [member_id]_screen_time.json
```
