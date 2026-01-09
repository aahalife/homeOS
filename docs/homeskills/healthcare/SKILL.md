---
name: healthcare
description: Manage family health including doctor appointments, medication reminders, prescription refills, and health records. Use when the user mentions doctors, appointments, medications, prescriptions, symptoms, health checkups, telemedicine, or medical needs.
---

# Healthcare Skill

Manage doctor appointments, medication schedules, prescription refills, and family health records.

## When to Use

- User needs to book a doctor appointment
- User asks about medication schedules
- User needs a prescription refill
- User has health questions or symptoms
- User wants to find a new doctor
- User asks about family health records

## Workflow Overview

```
1. Identify Health Need → 2. Check Member Profile → 3. Take Action
→ 4. Update Records → 5. Set Reminders
```

## Step 1: Load Health Profile

**Get family health info:**
```bash
cat ~/clawd/homeos/data/health/family_health.json 2>/dev/null
```

**Expected structure:**
```json
{
  "members": [
    {
      "id": "member-dad",
      "name": "Dad",
      "dob": "1985-03-15",
      "allergies": ["penicillin"],
      "medications": [
        {
          "name": "Lisinopril",
          "dosage": "10mg",
          "frequency": "daily",
          "time": "morning",
          "refill_date": "2024-02-01"
        }
      ],
      "primary_doctor": {
        "name": "Dr. Sarah Chen",
        "specialty": "Primary Care",
        "phone": "(555) 123-4567"
      },
      "insurance": {
        "provider": "Blue Cross",
        "member_id": "XYZ123456",
        "group": "ABC789"
      }
    }
  ]
}
```

## Doctor Appointments

### Finding a Doctor

**Search criteria gathering:**
```
🏥 FIND A DOCTOR

Let me help you find the right doctor:

1. What type of doctor?
   • Primary Care / Family Medicine
   • Pediatrician (kids)
   • Specialist: [type]

2. For which family member?

3. Preferences:
   • Near home or work?
   • Must accept [Insurance]?
   • Gender preference?
   • Languages needed?
```

**Doctor search results:**
```
🏥 DOCTORS FOUND: [Specialty] near [Location]

1. ⭐ Dr. Sarah Chen - 4.8★ (324 reviews)
   📍 0.5 mi | ✅ Accepts [Insurance]
   📅 Next available: Tomorrow 2:00 PM
   📞 (555) 123-4567
   💡 "Excellent with children, very thorough"

2. Dr. Michael Johnson - 4.6★ (189 reviews)
   📍 1.2 mi | ✅ Accepts [Insurance]
   📅 Next available: Friday 10:00 AM
   📞 (555) 234-5678

3. Dr. Emily Rodriguez - 4.9★ (256 reviews)
   📍 2.1 mi | ⚠️ Check insurance
   📅 Next available: Next Monday
   📞 (555) 345-6789

Which doctor would you like to book with?
```

### Booking an Appointment

**⚠️ MEDIUM RISK - Confirm details:**
```
📅 APPOINTMENT BOOKING

Doctor: Dr. Sarah Chen
For: [Family Member]
Type: [In-person / Telemedicine]
Date: [Date]
Time: [Time]
Reason: [Brief description]

📝 BRING TO APPOINTMENT:
• Insurance card
• Photo ID
• List of current medications
• Copay: ~$[XX]

Confirm this appointment?
```

**After booking:**
```
✅ APPOINTMENT CONFIRMED

🏥 Dr. Sarah Chen
📅 [Date] at [Time]
📍 [Address]
📞 [Phone]

⏰ REMINDERS SET:
• 1 day before: Prepare documents
• 2 hours before: Leave reminder

📅 Added to family calendar.

Need directions or anything else?
```

**Save appointment:**
```bash
cat >> ~/clawd/homeos/data/calendar.json << 'EOF'
{
  "id": "apt-TIMESTAMP",
  "type": "medical",
  "title": "Dr. [Name] - [Member]",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "location": "ADDRESS",
  "notes": "Bring: insurance, ID, med list. Copay: $XX",
  "reminders": ["1d", "2h"]
}
EOF
```

## Medication Management

### Daily Medication Reminders

**Morning reminder:**
```
💊 MORNING MEDICATIONS - [Date]

[Family Member]:
☐ Lisinopril 10mg - Take with water
☐ Vitamin D 2000 IU - Take with food

[Family Member 2]:
☐ Allergy pill - 1 tablet

Tap to mark as taken!
```

**Tracking format:**
```
💊 MEDICATION LOG - [Member]

Today's medications:
✅ 8:00 AM - Lisinopril 10mg - Taken
✅ 8:05 AM - Vitamin D 2000 IU - Taken
⏳ 8:00 PM - Fish Oil - Upcoming

Streak: 14 days 🌟
```

### Adding a Medication

**Gather medication details:**
```
💊 ADD MEDICATION

For: [Family Member]

1. Medication name: [Name]
2. Dosage: [e.g., 10mg, 500mg]
3. How often?
   • Once daily
   • Twice daily
   • Every [X] hours
   • As needed
4. Time of day: [Morning/Afternoon/Evening/Night]
5. Take with food? [Yes/No]
6. Prescribed by: [Doctor name]
7. Pharmacy: [Where to refill]
8. Refill date: [When to refill]

⚠️ Any interactions I should know about?
```

**Confirmation:**
```
✅ MEDICATION ADDED

💊 [Medication Name] [Dosage]
For: [Member]
Schedule: [Frequency] - [Time]
Refill by: [Date]

⏰ REMINDERS SET:
• Daily at [Time]
• 7 days before refill

I'll help you stay on track!
```

### Prescription Refills

**Proactive refill reminder:**
```
💊 REFILL REMINDER

[Member]'s [Medication] needs a refill!

Current supply runs out: [Date] (7 days)
Pharmacy: [Pharmacy Name]
Phone: [Phone]

Options:
1. 📱 Request refill online
2. 📞 Call pharmacy for refill
3. 📅 Set reminder for later
4. ❌ Mark as discontinued

Want me to help request the refill?
```

**Refill assistance:**
```
💊 REFILL REQUEST

⚠️ APPROVAL REQUIRED

I can help you request a refill:

Medication: [Name] [Dosage]
Rx Number: [If known]
Pharmacy: [Name]

For online refill, go to:
🔗 [Pharmacy website]

Or call:
📞 [Phone] - Say: "Refill for [Name], Rx [number]"

Would you like me to remind you to pick it up?
```

## Symptom Checker

**⚠️ DISCLAIMER ALWAYS SHOWN:**
```
⚠️ IMPORTANT: This is informational only, not medical advice.
Always consult a healthcare provider for health concerns.
```

**Symptom assessment:**
```
🩺 SYMPTOM CHECK

Who isn't feeling well? [Member]

Symptoms:
• [Symptom 1]
• [Symptom 2]

Duration: [How long]
Severity: [Mild / Moderate / Severe]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚑 SEEK IMMEDIATE CARE IF:
• Difficulty breathing
• Chest pain
• Severe headache with stiff neck
• Signs of allergic reaction
• High fever (103°F+) in children

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Recommendation based on severity:**

| Severity | Recommendation |
|----------|----------------|
| Mild | Self-care tips, monitor |
| Moderate | Schedule appointment soon |
| Severe | Urgent care or ER |

**Self-care guidance:**
```
🏠 SELF-CARE SUGGESTIONS

For [Symptom]:

• Rest and stay hydrated
• [Specific suggestion 1]
• [Specific suggestion 2]

📝 Monitor for:
• [Warning sign 1]
• [Warning sign 2]

See a doctor if:
• Symptoms worsen
• No improvement in [X] days
• [Specific concern]

Want me to schedule an appointment just in case?
```

## Health Summary

**Family health overview:**
```
📊 FAMILY HEALTH OVERVIEW

━━━ DAD ━━━
💊 Medications: 2 active
   • Lisinopril - Daily ✅
   • Vitamin D - Daily ✅
📅 Next appointment: Feb 15 - Annual checkup
⚠️ Refill needed: Lisinopril (Feb 1)

━━━ MOM ━━━
💊 Medications: None
📅 Next appointment: None scheduled
💡 Suggestion: Schedule annual checkup

━━━ EMMA ━━━
💊 Medications: Seasonal allergy (as needed)
📅 Next appointment: March 1 - Dental cleaning

━━━ JACK ━━━
💊 Medications: None
📅 Next appointment: None scheduled
💡 Suggestion: Due for well-child visit

🔔 ACTION ITEMS:
1. Request Lisinopril refill for Dad
2. Schedule Mom's annual checkup
3. Schedule Jack's well-child visit
```

## Insurance Information

**Quick access:**
```
💳 INSURANCE INFO - [Member]

Provider: [Insurance Company]
Plan: [Plan Name]
Member ID: [ID]
Group Number: [Group]

📞 Customer Service: [Phone]
🏥 Find in-network doctors: [Website]

Copays:
• Primary Care: $[XX]
• Specialist: $[XX]
• Urgent Care: $[XX]
• ER: $[XX]

Deductible: $[XX] of $[XX] met

Need to see the card? I can display it.
```

## Telemedicine

**Quick telemedicine options:**
```
📱 TELEMEDICINE OPTIONS

For [Symptom/Reason]:

1. 🩺 [Insurance Telemedicine]
   Cost: $[X] copay
   Wait: ~15 min
   🔗 [Link or app instructions]

2. 🏥 Doctor on Demand
   Cost: $[X]
   Wait: ~10 min

3. 📞 Your Doctor's Office
   [Dr. Name] may offer video visits
   Call: [Phone]

Want me to help you start a telemedicine visit?
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   ├── health/
│   │   ├── family_health.json     # Health profiles
│   │   ├── medications.json       # Medication list
│   │   ├── appointments.json      # Appointment history
│   │   └── providers.json         # Doctor information
│   └── calendar.json              # Medical appointments
├── memory/
│   └── preferences/
│       └── health_prefs.json      # Healthcare preferences
└── logs/
    └── medication_log.json        # Medication tracking
```

## Example Interactions

**User:** "Dad needs to refill his blood pressure medication"

**Assistant:**
```
💊 Let me check Dad's medications...

Found: Lisinopril 10mg
Pharmacy: CVS on Main Street
Last filled: January 1
Refill date: February 1 (in 5 days)
Rx Number: #1234567

📞 To refill, call CVS: (555) 456-7890
   Say: "Refill Rx 1234567 for [Dad's Name]"

📱 Or online: cvs.com/refill

Want me to:
1. Remind you to call now?
2. Set a reminder to pick it up?
3. Check if it's ready later?
```

**User:** "Emma has a headache and sore throat"

**Assistant:**
```
🩺 SYMPTOM CHECK: Emma

Symptoms: Headache, sore throat

⚠️ First, some important questions:

1. How long has she had these symptoms?
2. Does she have a fever? (If yes, how high?)
3. Any other symptoms? (fatigue, cough, rash?)

This helps me give better guidance.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚑 Go to ER immediately if:
• Difficulty breathing or swallowing
• Very high fever (103°F+)
• Severe neck stiffness
• Signs of dehydration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

[After user provides more details, provide appropriate guidance and offer to schedule appointment if needed]

## Integration Points

- **Calendar**: Medical appointments sync
- **Reminders**: Medication and appointment reminders
- **Family Comms**: Health alerts to family members
- **Telephony**: Doctor office calls if needed
