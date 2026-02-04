---
name: family-bonding
description: >
  Plan family activities, outings, date nights, and quality time. Triggers: what should we do,
  family activity, weekend plans, things to do, family outing, day trip, date night, kids activities,
  rainy day ideas, bored, fun ideas, local events, game night, movie night, adventure, family fun
---

# Family Bonding Skill (Small-Model Edition)

Suggest and plan family activities, outings, and quality time experiences.

## STORAGE PATHS

- Activity history: ~/clawd/homeos/memory/activity_history.json
- Family preferences: ~/clawd/homeos/data/family.json
- Calendar: ~/clawd/homeos/data/calendar.json

## STEP 1: DETECT INTENT

IF user mentions "date night" OR "parents night" OR "just us" → DATE_NIGHT
IF user mentions "rainy" OR "indoor" OR "stuck inside" → INDOOR_IDEAS
IF user mentions "outside" OR "outdoor" OR "park" OR "hike" → OUTDOOR_IDEAS
IF user mentions "what should we do" OR "bored" OR "weekend" OR "activity" → GENERAL_IDEAS
IF user mentions "plan" OR "let's do" OR picks an activity → PLAN_ACTIVITY
IF user mentions "local events" OR "what's happening" → LOCAL_EVENTS
IF none match → ask: "Looking for activity ideas, date night plans, or help planning something specific?"

## STEP 2: GATHER CONTEXT

Load family info:
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{}'
```

Ask ONLY what's missing from these (skip if already known):
- Who's participating? (ages matter)
- When? (today, this weekend, specific date)
- Time available? (default: 2-3 hours)
- Indoor or outdoor? (default: either)
- Budget? (default: $ moderate)

DEFAULT ASSUMPTIONS (use these, don't ask):
- Time: 2-3 hours
- Budget: $ (under $50)
- Vibe: fun and relaxed
- Location: within 30 min drive

## ACTION: GENERAL_IDEAS

Risk: LOW

ALWAYS suggest exactly 3 options in this format:

```
🌟 ACTIVITY IDEAS

Based on: [CONTEXT_SUMMARY]

1. [EMOJI] [ACTIVITY_NAME]
   - Time: [DURATION]
   - Cost: [Free / $ / $$ / $$$]
   - Best for ages: [RANGE]
   - Why: [ONE_SENTENCE]

2. [EMOJI] [ACTIVITY_NAME]
   - Time: [DURATION]
   - Cost: [Free / $ / $$ / $$$]
   - Best for ages: [RANGE]
   - Why: [ONE_SENTENCE]

3. [EMOJI] [ACTIVITY_NAME]
   - Time: [DURATION]
   - Cost: [Free / $ / $$ / $$$]
   - Best for ages: [RANGE]
   - Why: [ONE_SENTENCE]

Pick one and I'll help plan it! Or want different ideas?
```

## ACTIVITY DATABASE BY AGE

Toddlers (1-3): sensory bins, bubble play, playground, splash pad, dance party, library story time
Preschool (3-5): crafts, baking cookies, scavenger hunts, children's museum, building forts, bug hunting
School age (6-10): board games, science experiments, bike rides, cooking together, mini golf, bowling, camping
Tweens (11-13): escape rooms, laser tag, rock climbing, cooking competitions, DIY projects, volunteer work
Teens (14-17): escape rooms, hiking, cooking challenges, game tournaments, creative projects, outdoor adventures
All ages: game night, picnics, movie night, cooking together, stargazing, photo walks, karaoke

IF ages span wide range (e.g., toddler + teen):
  → Pick activities from "All ages" list
  → Note: "Wide age range—these work for everyone."

## ACTIVITY DATABASE BY WEATHER

Indoor (rainy/cold):
- Fort building + movie marathon (Free, all ages)
- Board game tournament (Free/$, ages 5+)
- Baking project ($ , all ages)
- Indoor scavenger hunt (Free, all ages)
- Trampoline park ($$ , ages 3+)
- Bowling ($$ , ages 4+)
- Children's museum ($$ , ages 2-12)

Outdoor (nice weather):
- Park + picnic (Free, all ages)
- Nature hike (Free, ages 3+)
- Bike ride (Free, ages 5+)
- Backyard camping (Free/$, ages 4+)
- Mini golf ($, ages 4+)
- Zoo or wildlife park ($$, all ages)
- Beach or lake day (Free/$, all ages)

## ACTIVITY DATABASE BY BUDGET

Free: parks, hiking, library events, backyard activities, game night, dance party, stargazing
$ (under $25): baking at home, bowling deals, matinee movies, picnic supplies, craft supplies
$$ ($25-75): mini golf + ice cream, trampoline park, children's museum, bowling + food, skating
$$$ ($75+): theme parks, escape rooms, sports events, special shows, day trips, resort passes

## ACTION: DATE_NIGHT

Risk: LOW

```
💑 DATE NIGHT IDEAS

1. [EMOJI] [IDEA]
   - Cost: [RANGE]
   - Time: [DURATION]
   - Vibe: [relaxed / adventurous / romantic / fun]

2. [EMOJI] [IDEA]
   - Cost: [RANGE]
   - Time: [DURATION]
   - Vibe: [relaxed / adventurous / romantic / fun]

3. [EMOJI] [IDEA]
   - Cost: [RANGE]
   - Time: [DURATION]
   - Vibe: [relaxed / adventurous / romantic / fun]

🏠 At-home option (after kids sleep): [SIMPLE_IDEA]

Need childcare help? I can look into that.
```

IF user mentions needing a sitter:
  OUTPUT_HANDOFF: { next_skill: "family-comms", reason: "childcare coordination needed", context: { date: "[DATE]", duration: "[HOURS]" } }

## ACTION: INDOOR_IDEAS

Risk: LOW

Use "Indoor (rainy/cold)" database. Present 3 options in GENERAL_IDEAS format.
Lead with: "☔ Rainy day? No problem!"

## ACTION: OUTDOOR_IDEAS

Risk: LOW

Use "Outdoor (nice weather)" database. Present 3 options in GENERAL_IDEAS format.
Lead with: "☀️ Great day to get outside!"

## ACTION: PLAN_ACTIVITY

Risk: MEDIUM (adds to calendar)

TEMPLATE:
```
🎯 PLAN: [ACTIVITY_NAME]

- When: [DATE] at [TIME]
- Where: [LOCATION - default: TBD]
- Cost: [ESTIMATE]
- Who: [PARTICIPANTS - default: whole family]

📝 Prep list:
- [ITEM_1]
- [ITEM_2]
- [ITEM_3]

⏰ Timeline:
- [TIME]: [STEP_1]
- [TIME]: [STEP_2]
- [TIME]: [STEP_3]

🌧️ Backup plan: [INDOOR_ALTERNATIVE if outdoor activity]

Add to family calendar? (yes/no)
```

IF user says yes → save to ~/clawd/homeos/data/calendar.json
IF activity is outdoor → ALWAYS include a backup plan

## ACTION: LOCAL_EVENTS

Risk: LOW

```
📅 To find local events, check:
- Facebook Events → filter "family-friendly" + your city
- Eventbrite → search "kids" or "family" + your city
- Your city's Parks & Recreation website
- Local library website (free events!)

What type of event? (festivals, sports, classes, shows)
```

## SAVE ACTIVITY FEEDBACK

After any completed activity, IF user mentions how it went:

```bash
# Save to activity history
cat >> ~/clawd/homeos/memory/activity_history.json << 'EOF'
{"activity":"[NAME]","date":"[DATE]","rating":"[liked/loved/meh]","ages":"[AGES]","notes":"[BRIEF_NOTE]"}
EOF
```

IF activity history exists → reference it:
"Last time you did [ACTIVITY] and [loved/liked] it. Want to try that again or something new?"

## CROSS-SKILL HANDOFFS

IF user mentions feeling overwhelmed by planning:
  OUTPUT_HANDOFF: { next_skill: "mental-load", reason: "planning overwhelm", context: { task: "activity planning" } }

IF user wants to coordinate schedule for activity:
  OUTPUT_HANDOFF: { next_skill: "family-comms", reason: "schedule coordination", context: { activity: "[NAME]", proposed_time: "[TIME]" } }

IF user mentions grandparent joining:
  OUTPUT_HANDOFF: { next_skill: "elder-care", reason: "grandparent participation", context: { activity: "[NAME]", accessibility_needs: true } }

## SCENARIO EXAMPLES

Scenario: Single parent, toddler (2), rainy Saturday
- User: "What can I do with my kid today? It's raining."
- Context: 1 child, age 2, indoor only
- Suggest from toddler + indoor lists: sensory bins, dance party, fort building
- Note: "Solo parent tip: These are low-prep so you can enjoy them too!"

Scenario: Dual parents, kids (7, 11), nice weekend, $50 budget
- User: "What should we do this weekend?"
- Context: 2 kids school-age/tween, outdoor OK, $ budget
- Suggest: park picnic + frisbee, bike ride, backyard camping
- Mix ages: pick from overlap of 6-10 and 11-13 lists

Scenario: Blended family, 3 kids (4, 9, 15), need everyone engaged
- User: "Need something all three kids will enjoy"
- Context: wide age range, use "All ages" list
- Suggest: cooking together (assign age-appropriate tasks), movie marathon (everyone picks one), scavenger hunt
- Note: "Wide age range—let the teen help lead for the younger ones!"
