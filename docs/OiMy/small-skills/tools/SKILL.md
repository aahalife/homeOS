---
name: tools-small
description: Core utilities - calendar, reminders, weather, notes. Use when user asks about schedule, events, reminders, weather, notes, or planning. Powers other skills.
version: 1.0-small
risk_default: LOW
---

# Tools Skill (Small-Model)

## RISK RULES

IF action is calendar.view OR weather OR reminder.set OR notes.create OR notes.search:
  → RISK: LOW
  → No confirmation needed

IF action is calendar.create OR calendar.update:
  → RISK: MEDIUM
  → Show event details, ask "Add this?" before creating

IF action is calendar.delete:
  → RISK: HIGH
  → Show event details, ask "Are you sure? This cannot be undone."
  → REQUIRE explicit "yes" or "DELETE" from user

## STORAGE

Data path: ~/clawd/homeos/data/
Memory path: ~/clawd/homeos/memory/
Files: calendar.json, notes/, reminders/

## CALENDAR - VIEW (RISK: LOW)

IF user asks "what's on my calendar" OR "schedule for [DATE]":

Read ~/clawd/homeos/data/calendar.json
Filter by requested date range

Template:

📅 CALENDAR - [DATE_OR_RANGE]

[TIME] [EMOJI] [EVENT_TITLE] ([DURATION])
- Location: [LOCATION]
- Notes: [NOTES_IF_ANY]

[TIME] [EMOJI] [EVENT_TITLE] ([DURATION])
- Location: [LOCATION]

Total: [COUNT] events

Use emojis: 💼 work, 👶 kid, 🏥 medical, 🍽️ social, 📞 call, 🎹 class, 🔧 maintenance

IF events overlap: flag "⚠️ Conflict: [EVENT_1] and [EVENT_2] overlap at [TIME]"

## CALENDAR - CREATE (RISK: MEDIUM)

IF user says "add [EVENT] to calendar" OR "schedule [EVENT]":

STEP 1 - Parse event details. Extract:
- Title (required)
- Date (required)
- Time (required, default to 9:00 AM if not specified)
- Duration (default: 1 hour)
- Location (optional)
- Attendees (optional)
- Reminders (default: 30 min before)

STEP 2 - Confirm:

📅 ADD EVENT

Title: [TITLE]
Date: [DATE]
Time: [TIME]
Duration: [DURATION]
Location: [LOCATION]
Reminders: [REMINDER_TIMES]

Add this to your calendar? (yes/no)

STEP 3 - IF user confirms:
- Save to ~/clawd/homeos/data/calendar.json
- Respond: "✅ Added: [TITLE] on [DATE] at [TIME]"

IF conflict detected:
- "⚠️ You already have [EXISTING_EVENT] at that time. Still add?"

## CALENDAR - DELETE (RISK: HIGH)

IF user says "delete [EVENT]" OR "remove [EVENT] from calendar":

STEP 1 - Find the event. IF multiple matches, list them and ask which one.

STEP 2 - Confirm with warning:

⚠️ DELETE EVENT

You're about to delete:

📅 [TITLE]
📆 [DATE] at [TIME]
📍 [LOCATION]

This cannot be undone. Type "DELETE" to confirm.

STEP 3 - IF user types "DELETE" or "yes":
- Remove from calendar.json
- Respond: "✅ Deleted: [TITLE]"

IF event is recurring:
- Ask: "Delete just this one, or all future occurrences?"

## CALENDAR - FIND FREE TIME (RISK: LOW)

IF user asks "when am I free" OR "find time for [ACTIVITY]":

Template:

📅 FREE TIME - [DATE]

✅ [START] - [END] ([DURATION] available)
❌ [START] - [END] ([EVENT_NAME])
✅ [START] - [END] ([DURATION] available) ⭐ Best slot
❌ [START] - [END] ([EVENT_NAME])
✅ [START] - [END] ([DURATION] available)

Best slot for [REQUESTED_DURATION]: [SUGGESTED_TIME]

Want me to schedule something?

## WEATHER (RISK: LOW)

IF user asks "weather" OR "what's it like outside" OR "do I need an umbrella":

Template:

🌤️ WEATHER - [LOCATION]

Now: [TEMP]°F - [CONDITIONS]
Feels like: [FEELS_LIKE]°F
Humidity: [PERCENT]%
Wind: [SPEED] mph

Forecast:
- Today: High [HIGH]° / Low [LOW]° - [CONDITIONS]
- Tomorrow: High [HIGH]° / Low [LOW]° - [CONDITIONS]
- [DAY_3]: High [HIGH]° / Low [LOW]° - [CONDITIONS]

💡 [CONTEXTUAL_TIP]

Contextual tips:
- IF rain: "Bring an umbrella!"
- IF temp below 32: "Bundle up, below freezing!"
- IF temp above 95: "Stay hydrated, extreme heat!"
- IF snow: "Check road conditions before driving"

IF weather affects other skills:
- Extreme cold + home-maintenance: check pipes, heating
- Rain + transportation: add extra commute time
- Extreme heat + home-maintenance: check AC

## REMINDERS (RISK: LOW)

IF user says "remind me to [TASK]" OR "set reminder for [TASK]":

Parse:
- Task description (required)
- Time/date (required - IF not given, ask)
- Recurring? (optional, default: no)

Template:

⏰ REMINDER SET

Task: [TASK_DESCRIPTION]
When: [DATE_AND_TIME]
Recurring: [NO / PATTERN]

🔔 I'll notify you at that time.

Save to ~/clawd/homeos/data/reminders/reminder-[TIMESTAMP].json

Format:
```json
{
  "type": "reminder",
  "message": "[TASK]",
  "trigger_time": "[ISO_TIMESTAMP]",
  "recurring": "[null/daily/weekly/monthly]",
  "status": "pending",
  "created": "[ISO_TIMESTAMP]"
}
```

IF user asks "list my reminders" OR "what reminders do I have":

Template:

⏰ YOUR REMINDERS

Upcoming:
- [DATE_TIME] - [TASK]
- [DATE_TIME] - [TASK]

Recurring:
- Every [PATTERN] - [TASK]

Total: [COUNT] active reminders

## NOTES (RISK: LOW)

IF user says "note:" OR "remember:" OR "save this:":

Save to ~/clawd/homeos/memory/notes/note-[TIMESTAMP].md

Template response:

📝 NOTE SAVED

"[NOTE_CONTENT]"

Tags: [AUTO_DETECTED_TAGS]
Saved: [TIMESTAMP]

IF user says "find my note about [TOPIC]" OR "what did I save about [TOPIC]":

Search ~/clawd/homeos/memory/notes/ for matching content

Template:

📝 FOUND [COUNT] NOTES for "[QUERY]"

1. [DATE] - "[NOTE_EXCERPT]"
   Tags: [TAGS]

2. [DATE] - "[NOTE_EXCERPT]"
   Tags: [TAGS]

Want to see the full note?

## PLANNING / TASK BREAKDOWN (RISK: LOW)

IF user says "help me plan [GOAL]" OR "break down [TASK]":

Template:

📝 PLAN: [GOAL]

Step 1: [TASK_NAME] - [DURATION] - [SPECIFICS]
Step 2: [TASK_NAME] - [DURATION] - [SPECIFICS]
Step 3: [TASK_NAME] - [DURATION] - [SPECIFICS]

Total: [TOTAL_TIME]. Want me to schedule these or set reminders?

## ERROR HANDLING

IF file not found: create it with empty defaults, tell user.
IF tool fails: offer retry, manual workaround, or skip.

## CROSS-SKILL HANDOFFS (INCOMING)

This skill receives handoffs from all other home skills.

IF handoff from home-maintenance requesting calendar event:
- Create maintenance appointment event
- Set reminder for day before AND morning of

IF handoff from meal-planning requesting grocery order:
- Search for items at preferred store
- Add to cart (MEDIUM risk, confirm)

IF handoff from transportation requesting departure reminder:
- Calculate departure time from event time minus drive time
- Set reminder at departure time

IF handoff from meal-planning requesting prep day scheduling:
- Create "Meal Prep" calendar block
- Set reminder morning of

## CROSS-SKILL HANDOFFS (OUTGOING)

IF weather shows extreme conditions:
```
OUTPUT_HANDOFF: { "next_skill": "home-maintenance", "reason": "weather alert for home", "context": { "condition": "[EXTREME_WEATHER]", "action_needed": "[CHECK_PIPES/CHECK_AC/etc]" } }
```

IF calendar event has a location and is within 2 hours:
```
OUTPUT_HANDOFF: { "next_skill": "transportation", "reason": "upcoming event needs commute check", "context": { "event": "[EVENT_NAME]", "location": "[ADDRESS]", "time": "[EVENT_TIME]" } }
```

IF calendar shows dinner party or meal event:
```
OUTPUT_HANDOFF: { "next_skill": "meal-planning", "reason": "meal event on calendar", "context": { "event": "[EVENT_NAME]", "date": "[DATE]", "guest_count": "[COUNT_IF_KNOWN]" } }
```
