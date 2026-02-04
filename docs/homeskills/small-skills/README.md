# HomeOS Small Skills for Clawdbot

These skills are optimized for **smaller LLMs** (Haiku, Gemma 3, Gemma 3n) while maintaining the full capability of the original HomeOS skills.

## Design Principles

### 1. Explicit Over Implicit
- Every decision point is spelled out with if/then logic
- No "use your judgment" — instead: concrete criteria and thresholds
- Default values provided for every parameter

### 2. Structured Output Templates
- Every response uses a fixed template the model fills in
- Templates use simple placeholders: `[VALUE]`
- No free-form generation for critical data

### 3. One Skill, One Job
- Each skill handles exactly one domain
- Cross-skill coordination uses explicit handoff patterns
- No skill assumes knowledge from another skill

### 4. Fail-Safe Defaults
- If unsure → ask the user (never guess)
- If data missing → use sensible defaults and state assumptions
- If action risky → always require explicit approval

### 5. Small Context Window Friendly
- Skills are concise (under 300 lines each)
- Heavy reference data lives in separate files loaded on-demand
- No redundant explanations — trust the format, not prose

## Skill Interaction Map

```
                    ┌─────────────┐
                    │  chat-turn   │ (entry point)
                    └──────┬──────┘
                           │ routes to:
        ┌──────────┬───────┼───────┬──────────┐
        ▼          ▼       ▼       ▼          ▼
   ┌─────────┐ ┌──────┐ ┌─────┐ ┌──────┐ ┌──────┐
   │ family   │ │health│ │home │ │growth│ │serv- │
   │ cluster  │ │clstr │ │clstr│ │clstr │ │ices  │
   └─────────┘ └──────┘ └─────┘ └──────┘ └──────┘
```

### Clusters & Routing

| Cluster | Skills | Trigger Keywords |
|---------|--------|-----------------|
| **Family** | family-comms, family-bonding, mental-load, elder-care | family, kids, chores, parents, overwhelmed |
| **Health** | healthcare, wellness, habits | doctor, medication, hydration, exercise, habit |
| **Home** | home-maintenance, meal-planning, transportation, tools | repair, dinner, grocery, ride, calendar, weather |
| **Growth** | education, school, note-to-actions, psy-rich | homework, grades, school, article, experience |
| **Services** | restaurant-reservation, marketplace-sell, hire-helper, telephony | restaurant, book, sell, babysitter, call |

### Cross-Skill Handoff Pattern

When Skill A needs Skill B:
```
OUTPUT_HANDOFF:
  next_skill: "skill-name"
  reason: "why handing off"
  context: { key data to pass }
```

The orchestrator (chat-turn) reads this and routes accordingly.

## Storage Convention

All skills read/write to `~/clawd/homeos/` with this structure:
```
~/clawd/homeos/
├── data/          # Structured JSON data
├── memory/        # Preferences, learnings
├── tasks/         # Active/pending/completed tasks
└── logs/          # Action audit trail
```

## Risk Levels

| Level | Rule | Examples |
|-------|------|---------|
| LOW | Do it | Read data, search, suggest |
| MEDIUM | Confirm once | Save preferences, set reminders |
| HIGH | Always confirm | Calls, payments, external messages |

Every HIGH-risk action template includes:
```
⚠️ APPROVAL REQUIRED
[what will happen]
Reply YES to proceed or NO to cancel.
```

The model must WAIT for "yes/yeah/yep/approved/go ahead/do it" before proceeding.
Any other response = do NOT proceed.
