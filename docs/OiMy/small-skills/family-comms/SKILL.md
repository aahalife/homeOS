---
name: family-comms
description: >
  Family communication hub. Send announcements, coordinate schedules, assign chores,
  track check-ins, manage emergency contacts. Triggers: family message, tell everyone,
  announce, family calendar, schedule, chore, chores, check-in, where is, emergency contact,
  family update, dinner time, school pickup, carpool, permission slip, who is picking up
---

# Family Communications Skill (Small-Model Edition)

Send messages, coordinate schedules, assign chores, and track family check-ins.

## STORAGE PATHS

- Family profile: ~/clawd/homeos/data/family.json
- Announcements: ~/clawd/homeos/data/announcements.json
- Chores: ~/clawd/homeos/data/chores.json
- Check-ins: ~/clawd/homeos/data/check_ins.json
- Emergency contacts: ~/clawd/homeos/data/emergency_contacts.json
- Calendar: ~/clawd/homeos/data/calendar.json
- Logs: ~/clawd/homeos/memory/family_comms_log.json

## STEP 1: DETECT INTENT

IF user mentions "tell everyone" OR "announce" OR "let the family know" → ANNOUNCEMENT
IF user mentions "calendar" OR "schedule" OR "what's on" OR "this week" → CALENDAR
IF user mentions "chore" OR "chores" OR "clean" OR "dishes" OR "trash" → CHORES
IF user mentions "check in" OR "where is" OR "heard from" → CHECK_IN
IF user mentions "emergency contact" OR "911" OR "emergency" → EMERGENCY
IF none match → ask: "Do you need help with: announcements, calendar, chores, check-ins, or emergency contacts?"

## STEP 2: LOAD FAMILY

```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{"members":[]}'
```

IF family.json is empty or missing → ask user to set up family members first:
"I need to know your family. Who are the members? (names, ages, roles like parent/child)"

DEFAULT family structure if not configured:
- Assume 2 parents, 1-2 kids
- Default quiet hours for kids: 21:00-07:00
- Default notification method: push

## ACTION: ANNOUNCEMENT

Risk: MEDIUM

TEMPLATE:
```
📢 ANNOUNCEMENT READY

- To: [RECIPIENTS - default: everyone]
- Priority: [🟢 Normal / 🟡 Important / 🔴 Urgent]
- Message: "[MESSAGE_TEXT]"

Send this announcement? (yes/no)
```

IF priority is 🔴 Urgent:
  Risk: HIGH
  ```
  ⚠️ APPROVAL REQUIRED
  This is an URGENT announcement. It will interrupt quiet hours and send push + SMS.
  Type YES to confirm, or no to cancel.
  ```
  WAIT for YES before sending.

IF recipient has quiet hours AND current time is within quiet hours AND priority is NOT 🔴:
  → Queue message for delivery after quiet hours end
  → Tell user: "📝 [NAME] is in quiet hours. Message will deliver at [END_TIME]."

After sending, save to ~/clawd/homeos/data/announcements.json with timestamp.

## ACTION: CALENDAR

Risk: LOW (viewing), MEDIUM (adding/changing)

VIEW template:
```
📅 FAMILY CALENDAR - [TIME_RANGE]

[DAY_NAME] [DATE]:
- [TIME] [EMOJI] [EVENT] ([WHO])

[DAY_NAME] [DATE]:
- [TIME] [EMOJI] [EVENT] ([WHO])

⚠️ Conflicts: [LIST_ANY or "None detected"]
```

ADD template (MEDIUM risk):
```
📅 ADD EVENT

- Event: [TITLE]
- When: [DATE] at [TIME]
- Who: [ATTENDEES - default: whole family]
- Reminder: [1 hour before - default]

Add to calendar? (yes/no)
```

IF new event overlaps existing event for same person:
  → Show conflict: "[PERSON] already has [EXISTING] at [TIME]"
  → Ask: "Add anyway, pick different time, or cancel?"

## ACTION: CHORES

Risk: LOW (viewing), MEDIUM (assigning)

VIEW template:
```
🧹 CHORE STATUS

[MEMBER_NAME]:
- ✅ [CHORE] - Done [DATE]
- ⏳ [CHORE] - Due [DATE]
- ❌ [CHORE] - Overdue!
- Points: [EARNED]/[GOAL] this week

[Repeat per member]
```

ASSIGN template:
```
🧹 ASSIGN CHORE

- Chore: [NAME]
- To: [MEMBER]
- Due: [WHEN - default: end of day]
- Recurring: [daily/weekly/one-time - default: one-time]
- Points: [VALUE - default: 5]

Assign? (yes/no)
```

COMPLETE template:
```
✅ [CHORE] marked done by [MEMBER]!
- Points: +[VALUE]
- Weekly total: [TOTAL]/[GOAL]
- [ENCOURAGEMENT - rotate: "Great job!", "Keep it up!", "Nice work!"]
```

IF assigning → check balance: count each member's weekly chores.
IF difference > 2 chores between members → suggest: "💡 [LESS_BUSY_MEMBER] has fewer chores. Consider assigning to them."

## ACTION: CHECK_IN

Risk: LOW (viewing), MEDIUM (requesting), HIGH (escalating)

REQUEST template:
```
📍 CHECK-IN REQUEST sent to [MEMBER]
- Reason: [REASON - default: "Just checking in"]
- Auto-reminder: 15 minutes if no response
- Escalation: 30 minutes → notify parent/emergency contact
```

RECEIVED template:
```
📍 CHECK-IN from [MEMBER]
- Message: "[MESSAGE]"
- Time: [TIME]
- ✅ Acknowledged
```

OVERDUE flow:
IF no response after 15 min → send reminder (MEDIUM risk)
IF no response after 30 min → show:
```
⚠️ APPROVAL REQUIRED
[MEMBER] hasn't responded in 30 minutes.
Options:
1. Send another reminder
2. Call their phone
3. Contact emergency contacts
Type 1, 2, or 3 (or wait).
```
IF user picks 3 → Risk: HIGH → require YES confirmation before contacting.

## ACTION: EMERGENCY

Risk: HIGH — always show approval block.

```
🚨 EMERGENCY ALERT

⚠️ APPROVAL REQUIRED

This will:
- Send immediate push + SMS to ALL family members
- Send SMS to emergency contacts
- Share location if available

Alert type: [Medical / Safety / Location / General]
Message: "[MESSAGE]"

Type YES to confirm, or no to cancel.
```

WAIT for YES. Do NOT send without explicit YES.

Emergency contacts display (Risk: LOW):
```
🚨 EMERGENCY CONTACTS
- Priority 1: [NAME] - [PHONE]
- Priority 2: [NAME] - [PHONE]
- Medical: [DR_NAME] - [PHONE]
- Poison Control: 1-800-222-1222
- Emergency: 911
```

## CROSS-SKILL HANDOFFS

IF user asks about activities or "what should we do" during calendar view:
  OUTPUT_HANDOFF: { next_skill: "family-bonding", reason: "activity planning request", context: { available_times: "[FREE_SLOTS]", family_members: "[MEMBERS]" } }

IF user mentions feeling overwhelmed by schedule:
  OUTPUT_HANDOFF: { next_skill: "mental-load", reason: "overwhelm detected", context: { event_count: "[COUNT]", busiest_day: "[DAY]" } }

IF user asks about elderly parent check-in:
  OUTPUT_HANDOFF: { next_skill: "elder-care", reason: "elder check-in request", context: { parent_name: "[NAME]" } }

## SCENARIO EXAMPLES

Scenario: Single parent, 2 kids (ages 5, 10), busy weeknight
- User: "Tell the kids dinner is at 6"
- Action: ANNOUNCEMENT to kids only, 🟢 Normal priority
- IF age 5 kid can't read messages → note: "💡 [CHILD] is young—consider telling them in person too."

Scenario: Dual parents, teen (14) hasn't checked in
- User: "Emma hasn't texted since school"
- Action: CHECK_IN → request to Emma → follow overdue flow if needed

Scenario: Blended family, 3 kids, complex schedule
- User: "What does this week look like?"
- Action: CALENDAR view → flag any conflicts → note carpool needs
