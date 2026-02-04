---
name: healthcare
description: Family health triage, medication reminders, appointment booking, prescription refills. Trigger on doctor, appointment, medication, prescription, symptom, sick, fever, refill, pharmacy, checkup, insurance, telemedicine.
---

# Healthcare Skill (Small-Model)

Triage family health needs. NEVER diagnose. ALWAYS disclaim.

## MEDICAL DISCLAIMER — ALWAYS SHOW

```
⚠️ I am NOT a doctor. This is informational only, NOT medical advice.
Always consult a healthcare provider for health concerns.
For emergencies, call 911.
```

## RISK LEVELS

- LOW: View records, show info, display reminders
- MEDIUM: Book appointment, add medication reminder → CONFIRM before acting
- HIGH: Change medication, stop medication, refill controlled substance → APPROVAL BLOCK, WAIT

## DECISION TREE

### Step 1: What does the user need?

- IF user mentions "symptom" OR "sick" OR "fever" OR "hurt" OR "pain" → GO TO Symptom Triage
- IF user mentions "appointment" OR "doctor" OR "book" OR "schedule" → GO TO Appointment Flow
- IF user mentions "medication" OR "medicine" OR "pill" OR "refill" → GO TO Medication Flow
- IF user mentions "insurance" OR "copay" OR "coverage" → GO TO Insurance Info
- IF user mentions "health summary" OR "overview" → GO TO Health Summary
- IF unclear → ASK: "Are you looking for help with symptoms, appointments, medications, or something else?"

### Step 2: Who is this for?

- IF user specifies a name → USE that family member
- IF not specified → ASK: "Which family member is this for?"
- LOAD profile: `~/clawd/homeos/data/health/family_health.json`

## SYMPTOM TRIAGE

**RISK: MEDIUM**

ALWAYS show medical disclaimer FIRST.

### Emergency Check — ALWAYS DO THIS FIRST

- IF any of these → OUTPUT emergency block, STOP:
  - difficulty breathing
  - chest pain
  - severe allergic reaction (swelling, hives + breathing)
  - high fever: adults 103°F+, kids 102°F+ under age 3
  - seizure, loss of consciousness
  - severe bleeding

Emergency output:
```
🚨 SEEK IMMEDIATE MEDICAL CARE

Based on what you described, please:
- Call 911 or go to the nearest ER
- Do NOT wait

⚠️ I am NOT a doctor. This is informational only.
```

### Non-Emergency Triage

- IF symptoms are MILD (cold, minor headache, small scrape) AND duration < 3 days:
  - OUTPUT self-care suggestions
  - OUTPUT: "See a doctor if symptoms worsen or last more than 3 days."

- IF symptoms are MODERATE (persistent pain, fever 100-102°F, vomiting) OR duration >= 3 days:
  - OUTPUT: "I recommend scheduling an appointment soon."
  - OFFER to book appointment
  - OUTPUT_HANDOFF: `{ next_skill: "wellness", reason: "track recovery", context: "[MEMBER] feeling unwell, monitor hydration and rest" }`

- IF symptoms are SEVERE but not emergency:
  - OUTPUT: "Please visit urgent care today."
  - PROVIDE nearest urgent care info if available

Self-care template:
```
🏠 SELF-CARE — [MEMBER_NAME]

Symptoms: [SYMPTOM_LIST]

Suggestions:
- Rest and stay hydrated (aim for [WATER_OZ] oz water today)
- [SPECIFIC_SUGGESTION_1]
- [SPECIFIC_SUGGESTION_2]

⚠️ See a doctor if:
- Symptoms get worse
- No improvement in 3 days
- New symptoms appear

⚠️ I am NOT a doctor. This is informational only.
```

## APPOINTMENT FLOW

**RISK: MEDIUM — confirm before booking**

### Gather Info

- IF user provides doctor name, date, time → GO TO Confirm
- IF missing doctor → ASK: "Which doctor? Or should I suggest one?"
- IF missing date/time → ASK: "When would you like to go?"
- IF missing reason → ASK: "What's the visit for? (Just a brief description)"

### Confirm Booking

```
📅 APPOINTMENT — Please Confirm

- Doctor: [DOCTOR_NAME]
- For: [MEMBER_NAME]
- Date: [DATE]
- Time: [TIME]
- Type: [in-person / telemedicine]
- Reason: [REASON]

📝 Bring: Insurance card, photo ID, medication list
💰 Estimated copay: $[COPAY_AMOUNT] (default: check your plan)

Confirm? [Yes / No / Change something]
```

- IF confirmed → SAVE to `~/clawd/homeos/data/health/appointments.json`
- SET reminders: 1 day before, 2 hours before
- ADD to `~/clawd/homeos/data/calendar.json`

## MEDICATION FLOW

### What action?

- IF user says "refill" OR "running out" OR "need more" → GO TO Refill
- IF user says "add" OR "new medication" OR "started taking" → GO TO Add Medication
- IF user says "stop" OR "discontinue" → **RISK: HIGH** → APPROVAL BLOCK
- IF user says "schedule" OR "remind" OR "when do I take" → GO TO Show Schedule
- IF unclear → ASK: "Do you need a refill, want to add a medication, or check your schedule?"

### Refill

**RISK: MEDIUM**

```
💊 REFILL — [MEMBER_NAME]

- Medication: [MED_NAME] [DOSAGE]
- Pharmacy: [PHARMACY_NAME] (default: see profile)
- Phone: [PHARMACY_PHONE]
- Rx Number: [RX_NUMBER] (if known)

To refill:
- Call: [PHARMACY_PHONE] — say "Refill Rx [RX_NUMBER] for [MEMBER_NAME]"
- Online: [PHARMACY_WEBSITE]

Want me to set a reminder to pick it up? [Yes / No]
```

SAVE refill request to `~/clawd/homeos/data/health/medications.json`

### Add Medication

**RISK: MEDIUM — confirm details**

Gather these (ask for any missing):
- Medication name: [MED_NAME]
- Dosage: [DOSAGE] (default: "as prescribed")
- Frequency: [FREQUENCY] (default: "once daily")
- Time of day: [TIME] (default: "morning")
- Take with food: [YES_NO] (default: "check label")
- Prescribed by: [DOCTOR] (default: "not specified")

After confirming → SAVE to `~/clawd/homeos/data/health/medications.json`
SET daily reminders at [TIME]
SET refill reminder 7 days before [REFILL_DATE]

### Show Schedule

**RISK: LOW**

```
💊 TODAY'S MEDICATIONS — [MEMBER_NAME]

Morning:
- [MED_NAME] [DOSAGE] — [INSTRUCTIONS]

Evening:
- [MED_NAME] [DOSAGE] — [INSTRUCTIONS]

✅ = taken, ☐ = upcoming, ❌ = missed
Streak: [X] days
```

### Stop Medication — HIGH RISK

```
🛑 APPROVAL REQUIRED

You want to stop [MED_NAME] for [MEMBER_NAME].

⚠️ Stopping medication should be discussed with your doctor.
I cannot make this change without your explicit approval.

Type "APPROVE STOP [MED_NAME]" to confirm.
Otherwise, please consult [DOCTOR_NAME] first.

⚠️ I am NOT a doctor. This is informational only.
```

- WAIT for explicit approval text
- IF approved → mark as discontinued in `~/clawd/homeos/data/health/medications.json`
- LOG the change with timestamp

## INSURANCE INFO

**RISK: LOW**

```
💳 INSURANCE — [MEMBER_NAME]

- Provider: [INSURANCE_PROVIDER]
- Plan: [PLAN_NAME]
- Member ID: [MEMBER_ID]
- Group: [GROUP_NUMBER]
- Phone: [CUSTOMER_SERVICE_PHONE]

Copays:
- Primary care: $[AMOUNT] (default: "check plan")
- Specialist: $[AMOUNT]
- Urgent care: $[AMOUNT]
- ER: $[AMOUNT]
```

## HEALTH SUMMARY

**RISK: LOW**

```
📊 HEALTH OVERVIEW — [MEMBER_NAME]

Medications: [COUNT] active
- [MED_1] — [STATUS: on track / refill soon / overdue]

Next appointment: [DATE] — [DOCTOR] ([REASON])
- OR "None scheduled"

Action items:
- [ACTION_1]
- [ACTION_2]

⚠️ I am NOT a doctor. This is informational only.
```

## CROSS-SKILL HANDOFFS

- IF user is sick AND needs hydration/rest tracking:
  - OUTPUT_HANDOFF: `{ next_skill: "wellness", reason: "recovery tracking", context: "[MEMBER] sick — monitor hydration, sleep, rest" }`

- IF user wants to build a medication habit:
  - OUTPUT_HANDOFF: `{ next_skill: "habits", reason: "medication adherence", context: "[MEMBER] wants to consistently take [MED_NAME]" }`

- IF appointment reveals need for lifestyle change:
  - OUTPUT_HANDOFF: `{ next_skill: "wellness", reason: "lifestyle adjustment", context: "Doctor recommended [CHANGE] for [MEMBER]" }`

## STORAGE

```
~/clawd/homeos/data/health/
  family_health.json      # member profiles, allergies, doctors
  medications.json        # active medications, schedules, refill dates
  appointments.json       # past and upcoming appointments

~/clawd/homeos/memory/
  preferences/health_prefs.json   # notification preferences, pharmacy choices

~/clawd/homeos/data/calendar.json # medical appointments
```

## DEFAULTS

- Copay: "check your plan"
- Pharmacy: "your usual pharmacy"
- Refill reminder: 7 days before run-out
- Appointment reminders: 1 day + 2 hours before
- Medication time if unspecified: "morning"
- Frequency if unspecified: "once daily"
