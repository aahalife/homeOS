---
name: elder-care
description: >
  Care for aging parents with check-ins, medication tracking, wellness monitoring, music,
  and family updates. Triggers: check on mom, check on dad, elderly parent, senior care,
  aging parent, medication reminder, how is mom, how is dad, grandparent, call mom, call dad,
  parent wellness, elder check-in, play music for mom, play music for dad, parent report
---

# Elder Care Skill (Small-Model Edition)

Compassionate check-ins, medication tracking, and wellness monitoring for aging parents.

## STORAGE PATHS

- Elder profiles: ~/clawd/homeos/data/elder_care/[parent_id].json
- Check-in logs: ~/clawd/homeos/data/elder_care/check_ins/
- Medication logs: ~/clawd/homeos/data/elder_care/medications/
- Health tracking: ~/clawd/homeos/data/elder_care/health_log.json
- Stories/wisdom: ~/clawd/homeos/memory/elder_stories.json
- Alerts: ~/clawd/homeos/memory/elder_alerts.json

## STEP 1: DETECT INTENT

IF user mentions "set up" OR "configure" AND "check-in" OR "elder" OR "parent" → SETUP
IF user mentions "check on" OR "how is" AND parent reference → STATUS_CHECK
IF user mentions "medication" OR "meds" OR "pills" OR "prescription" → MEDICATION
IF user mentions "call" OR "check-in" AND parent reference → INITIATE_CHECKIN
IF user mentions "music" OR "play" OR "song" AND parent reference → PLAY_MUSIC
IF user mentions "report" OR "summary" OR "how has" → WEEKLY_REPORT
IF user mentions "story" OR "memory" OR "wisdom" OR "tell me about" → MEMORY_CONVERSATION
IF none match → ask: "Need help with: check-in status, medications, music, or weekly report?"

## STEP 2: LOAD ELDER PROFILE

```bash
ls ~/clawd/homeos/data/elder_care/*.json 2>/dev/null
cat ~/clawd/homeos/data/elder_care/[parent_id].json 2>/dev/null || echo '{}'
```

IF no profile exists → go to SETUP
IF multiple profiles → ask: "Which parent? [LIST_NAMES]"
IF only one profile → use it automatically

## ACTION: SETUP

Risk: HIGH — setting up care for a vulnerable person requires explicit confirmation.

Gather info in 2-3 rounds (ask 3 questions at a time):
- Round 1: Name, relationship, phone
- Round 2: Call times (default: 9am+7pm), medications, health conditions
- Round 3: Music prefs (default: 1950s-60s), hobbies, who gets updates

After gathering:
```
⚠️ APPROVAL REQUIRED

Elder care profile for [NAME]:
- Check-in times: [TIMES]
- Medications: [COUNT] tracked
- Health monitoring: [CONDITIONS]
- Updates sent to: [RECIPIENTS]

This will set up regular wellness check-ins.
Type YES to confirm.
```

WAIT for YES. Save to ~/clawd/homeos/data/elder_care/[parent_id].json

DEFAULT VALUES:
- Call times: 9:00 AM and 7:00 PM
- Music: 1950s-60s jazz and standards
- Interests: grandchildren, weather, cooking
- Alert threshold: 2 missed check-ins = notify family

## ACTION: STATUS_CHECK

Risk: LOW

Load latest check-in log:
```bash
cat ~/clawd/homeos/data/elder_care/check_ins/latest.json 2>/dev/null
```

TEMPLATE:
```
👵 [NAME] STATUS

Last check-in: [DATE] at [TIME]

- Mood: [EMOJI] [DESCRIPTION]
- Sleep: [GOOD/FAIR/POOR]
- Medications: [✅ Taken / ⚠️ Missed / ⏳ Pending]
- Energy: [GOOD/LOW/NORMAL]
- Pain: [NONE/MILD/MODERATE - location if any]
- Appetite: [GOOD/FAIR/POOR]

[IF_ANY_CONCERNS]:
⚠️ Note: [CONCERN_DETAIL]

Would you like to:
1. Call [NAME] now
2. Play music for [NAME]
3. See the weekly report
4. Schedule an extra check-in
```

IF last check-in was more than 24 hours ago:
  → Flag: "⚠️ No check-in in [HOURS] hours. Want me to initiate one?"

## ACTION: INITIATE_CHECKIN

Risk: MEDIUM

```
📞 CHECK-IN: [NAME]
Calling [NAME] at [PHONE]... Type: [morning/evening/extra]
Plan: greeting → feelings → sleep/energy → meds → plans → positive close
Start the call? (yes/no)
```

After check-in, save to ~/clawd/homeos/data/elder_care/check_ins/[DATE].json with fields: date, time, type, mood, sleep, meds_taken, energy, pain, appetite, social, notes, concerns.

ALERT RULES after check-in:
IF mood = "low" for 3+ consecutive check-ins → ALERT: MEDIUM
IF meds_taken = false for 2+ consecutive → ALERT: MEDIUM
IF pain = "severe" → ALERT: HIGH
IF concern includes "fall" OR "chest pain" OR "confusion" → ALERT: HIGH
IF concern includes "unresponsive" → ALERT: EMERGENCY

## ACTION: MEDICATION

Risk: LOW (viewing), HIGH (changing medication schedule)

VIEW template:
```
💊 MEDICATIONS: [NAME]

[MED_NAME] [DOSE]
- For: [PURPOSE]
- Schedule: [TIMES]
- Status today: [✅ Taken at TIME / ⚠️ Not yet / ❌ Missed]

[Repeat per medication]

Adherence this week: [PERCENT]%
IF adherence < 80%: "⚠️ Adherence is low. Consider extra reminders or pill organizer."
```

CHANGE template (Risk: HIGH):
```
⚠️ APPROVAL REQUIRED
Changing [MED_NAME] for [NAME]: [OLD_SCHEDULE] → [NEW_SCHEDULE]
⚠️ Confirm this was approved by their doctor. Type YES to update.
```
WAIT for YES before changing any medication data.

## ACTION: PLAY_MUSIC

Risk: LOW

Load music preferences from profile. Play 5-song playlist from their preferred era.

```
🎵 MUSIC FOR [NAME]
Playing: [ERA] [GENRE] playlist
1. [SONG] - [ARTIST] (repeat x5)
Enjoy the music! 🎶
```

DEFAULT artists by era: 1940s (Glenn Miller, Bing Crosby), 1950s (Sinatra, Nat King Cole, Ella), 1960s (Beatles, Elvis, Johnny Cash), 1970s (Carpenters, Bee Gees, Stevie Wonder)

## ACTION: WEEKLY_REPORT

Risk: LOW

```
📊 WEEKLY REPORT: [NAME] — Week of [DATE_RANGE]
Overall: [🟢 Good / 🟡 Fair / 🔴 Concerning]
- Check-ins: [COUNT]/[EXPECTED] | Meds: [PERCENT]% | Mood: [EMOJI]
- Sleep: [SUMMARY] | Energy: [SUMMARY] | Appetite: [SUMMARY] | Pain: [SUMMARY]
- Social: [VISITORS] visitors, [OUTINGS] outings, [CALLS] calls
- Notable: [HIGHLIGHTS]
- Concerns: [CONCERNS or "None"]
- Actions: [SUGGESTED_ACTIONS]
```

IF overall = 🔴 → add: "⚠️ Concerning patterns. Consider a visit or doctor appointment."

## ACTION: MEMORY_CONVERSATION

Risk: LOW

Rotate weekly topics: how they met spouse, favorite job, child as baby, childhood neighborhood, favorite holiday, best friend growing up.

```
💭 MEMORY TOPIC: "[TOPIC_QUESTION]"
```

Save stories: `echo '{"date":"[DATE]","topic":"[TOPIC]","summary":"[SUMMARY]"}' >> ~/clawd/homeos/memory/elder_stories.json`

## ALERT SYSTEM

Severity levels and actions:

🟢 LOW (note in log):
- One missed medication
- Mildly low mood (single occurrence)
- Slight appetite change

🟡 MEDIUM (include in daily update):
- 2+ missed medications in a row
- Low mood for 3+ days
- Unusual fatigue pattern
- Reduced appetite for 2+ days

🔴 HIGH (immediate family notification — triggers: fall, severe pain, confusion, chest pain, breathing difficulty):
Risk: HIGH
```
⚠️ APPROVAL REQUIRED
🚨 URGENT: [NAME] — [ISSUE]. Details: [SPECIFICS]. Action: [RECOMMENDATION].
Notify family? Type YES to send alert.
```
WAIT for YES.

🚨 EMERGENCY (call 911 + notify family — trigger: unresponsive, medical crisis):
Risk: HIGH
```
⚠️ APPROVAL REQUIRED
🚨🚨 EMERGENCY: [NAME] needs immediate medical help. [SITUATION].
Will call 911 + notify all family. Type YES to proceed.
```
WAIT for YES. EXCEPTION: IF user says "call 911 now" → proceed immediately, log after.

## CROSS-SKILL HANDOFFS

IF user asks about family schedule involving grandparent visit:
  OUTPUT_HANDOFF: { next_skill: "family-comms", reason: "family schedule coordination", context: { event: "grandparent visit", parent: "[NAME]" } }

IF user mentions grandparent joining family activity:
  OUTPUT_HANDOFF: { next_skill: "family-bonding", reason: "intergenerational activity", context: { elder: "[NAME]", mobility: "[LEVEL]", interests: "[LIST]" } }

IF user feels overwhelmed by caregiving:
  OUTPUT_HANDOFF: { next_skill: "mental-load", reason: "caregiver overwhelm", context: { tasks: "elder care coordination" } }

## SCENARIO EXAMPLES

Scenario: Adult child (40), mom (72) lives alone, diabetes
- User: "Set up check-ins for my mom"
- Action: SETUP → gather info in 3 rounds → confirm with HIGH risk approval
- Configure: 2x daily calls, medication tracking for Metformin, diabetes monitoring

Scenario: User between meetings, quick check
- User: "How's mom doing?"
- Action: STATUS_CHECK → show latest check-in summary
- IF all good: brief response, no alarm
- IF concern: flag it clearly with suggested action

Scenario: Mom missed evening meds twice this week
- Alert: MEDIUM → include in daily update
- Suggest: "Consider a pill organizer or extra reminder call at med time"

Scenario: Dad reports chest pain during check-in
- Alert: HIGH → immediate notification
- Show approval block → WAIT for YES
- After approval: notify all family contacts with details
