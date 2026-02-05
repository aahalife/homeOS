---
name: infrastructure
description: Core conventions for all HomeOS skills. Storage, approvals, errors, logging.
---

# HomeOS Infrastructure

All skills follow these rules. No exceptions.

## Storage Layout

```
~/clawd/homeos/
├── memory/          # Preferences, learnings, entities
├── data/            # family.json, providers.json, calendar.json, home.json
├── tasks/           # active/, pending/, completed/
└── logs/            # actions.log
```

Initialize on first use:
```bash
mkdir -p ~/clawd/homeos/{memory,data,tasks/{active,pending,completed},logs}
```

## Storage Rules

- ALL persistent data → ~/clawd/homeos/data/
- ALL preferences → ~/clawd/homeos/memory/
- ALL task state → ~/clawd/homeos/tasks/
- ALL logs → ~/clawd/homeos/logs/actions.log
- Use JSON for structured data. Use jq to update.
- Log format: `YYYY-MM-DDTHH:MM:SS | LEVEL | skill | message`

## Risk Levels and Approval

THREE levels. No grey areas.

**LOW risk** → Do it. No approval needed.
- Read files, search web, generate suggestions, look up info

**MEDIUM risk** → Ask once, remember the answer.
- Save preferences, set reminders, update data files
- Store approval: `~/clawd/homeos/memory/approvals.json`

**HIGH risk** → ALWAYS ask. EVERY time. No memory.
- Phone calls, purchases, public posts, sending messages to others
- Requires explicit "yes", "approved", "go ahead", or "do it"
- "maybe", "I guess", no response → NOT approved. Ask again.

Approval template:
```
⚠️ APPROVAL REQUIRED
Action: [what you will do]
Details: [specifics]
Impact: [cost, visibility, permanence]
Reply YES to proceed or NO to cancel.
```

## Error Handling

1. Log the error:
```bash
echo "$(date -Iseconds) | ERROR | [skill] | [description]" >> ~/clawd/homeos/logs/actions.log
```

2. Tell the user. Never silently fail.
```
❌ Could not [action] because [reason].
Options:
1. [alternative]
2. [workaround]
3. Try again later
```

3. If a task was in progress, save state before failing:
```bash
echo '{"skill":"X","step":"Y","error":"Z","ts":"NOW"}' > ~/clawd/homeos/tasks/pending/recover-$(date +%s).json
```

## Cross-Skill Handoff

When one skill needs another, use OUTPUT_HANDOFF:
```
OUTPUT_HANDOFF:
  to: [target-skill-name]
  reason: [why]
  data:
    key1: value1
    key2: value2
```

The receiving skill picks up from its Step 1 with the provided data pre-filled.

## Calendar Events

Add events to ~/clawd/homeos/data/calendar.json:
```json
{"id":"evt-TIMESTAMP","title":"X","date":"YYYY-MM-DD","time":"HH:MM","location":"ADDR","notes":"N"}
```

## Task State

For multi-step tasks, save progress:
```bash
echo '{"skill":"X","step":2,"data":{...}}' > ~/clawd/homeos/tasks/active/taskname-$(date +%s).json
```

Move to completed/ when done. Move to pending/ if waiting on user.

## Cancel / Interrupt

If user says "cancel", "stop", "never mind":
1. Confirm: "Cancelling [task]. OK?"
2. Clean up task state
3. Log cancellation
