---
name: family-comms
description: Coordinate family communication including announcements, shared calendars, chore assignments, check-ins, and emergency contacts. Use when the user wants to send family messages, coordinate schedules, assign tasks, track family member locations, check in on kids, or manage emergency contacts.
---

# Family Communications Skill

Coordinate family activities, share announcements, manage chores, and keep everyone connected and informed.

## When to Use

- User wants to send a message to family members
- User needs to coordinate schedules across family
- User wants to assign or check on chores
- User asks about family member locations
- User wants to set up check-in reminders
- User needs emergency contact information
- User wants family calendar overview

## Workflow Overview

```
1. Identify Communication Need → 2. Select Recipients
→ 3. Compose/Execute → 4. Confirm Delivery → 5. Track Responses
```

## Step 1: Load Family Profile

**Get family members:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members'
```

**Expected structure:**
```json
{
  "members": [
    {
      "id": "member-dad",
      "name": "Dad",
      "role": "parent",
      "phone": "+15551234567",
      "email": "dad@family.com",
      "notifications": "push",
      "quiet_hours": null
    },
    {
      "id": "member-emma",
      "name": "Emma",
      "role": "child",
      "age": 14,
      "notifications": "push",
      "quiet_hours": {"start": "21:00", "end": "07:00"}
    }
  ]
}
```

## Announcements

### Creating an Announcement

**Gather announcement details:**
```
📢 FAMILY ANNOUNCEMENT

What's the announcement about?

Priority levels:
• 🟢 Normal - Regular update
• 🟡 Important - Needs attention today
• 🔴 Urgent - Immediate attention required

Who should receive this?
• Everyone
• Parents only
• Kids only
• Specific: [select names]
```

**Announcement format:**
```
📢 FAMILY ANNOUNCEMENT

From: [Sender]
To: [Recipients]
Priority: [🟢/🟡/🔴]

──────────────────────────────
[TITLE]

[Message content]
──────────────────────────────

Please acknowledge: [Yes/No required]

⚠️ APPROVAL REQUIRED: Send this announcement?
```

**Save announcement:**
```bash
cat >> ~/clawd/homeos/data/announcements.json << 'EOF'
{
  "id": "announce-TIMESTAMP",
  "title": "TITLE",
  "message": "MESSAGE",
  "priority": "normal|important|urgent",
  "from": "SENDER_ID",
  "to": ["member-ids"],
  "created": "TIMESTAMP",
  "acknowledged_by": []
}
EOF
```

### Tracking Acknowledgments

```
📢 ANNOUNCEMENT STATUS: [Title]

Sent: [Time ago]

✅ Acknowledged:
• Dad - 5 min ago
• Mom - 10 min ago

⏳ Pending:
• Emma - not yet seen
• Jack - not yet seen

Want me to send a reminder to those who haven't acknowledged?
```

## Family Calendar

### Viewing Family Schedule

**Combined calendar format:**
```
📅 FAMILY CALENDAR - This Week

━━━ MONDAY [Date] ━━━
07:30  🚌 School drop-off (Mom)
15:30  ⚽ Emma - Soccer practice (Dad)
18:00  🍽 Family dinner

━━━ TUESDAY [Date] ━━━
09:00  💼 Dad - Work meeting
14:00  🎵 Jack - Piano lesson (Mom)
16:00  🏥 Emma - Dentist

━━━ WEDNESDAY [Date] ━━━
... [continues]

🚨 CONFLICTS DETECTED:
• Tuesday 4pm: Emma dentist overlaps with pickup time
  → Suggestion: Confirm who's taking Emma

Need to add something or resolve a conflict?
```

### Adding Family Events

**⚠️ MEDIUM RISK - Confirm before adding:**
```
📅 ADD FAMILY EVENT

Event: [Title]
When: [Date] at [Time]
Where: [Location]
Who: [Attendees]
Reminders: 1 hour before, day before

Add this to the family calendar?
```

**Conflict detection:**
```
⚠️ SCHEDULING CONFLICT

You're trying to add:
📅 [New Event] at [Time]

But [Family Member] already has:
📅 [Existing Event] at [Overlapping Time]

Options:
1. Add anyway (they'll need to choose)
2. Pick a different time
3. Cancel
```

## Chore Management

### Viewing Chores

```
🧹 CHORE STATUS

━━━ EMMA ━━━
✅ Feed the dog - Done today
⏳ Clean room - Due Saturday
❌ Take out recycling - Overdue!

Points earned this week: 15/30

━━━ JACK ━━━
✅ Set table - Done today
✅ Homework area tidy - Done
⏳ Trash duty - Due Thursday

Points earned this week: 20/30

🏆 WEEKLY LEADER: Jack!

Options:
1. Mark a chore complete
2. Assign new chore
3. View reward progress
```

### Assigning Chores

```
🧹 ASSIGN CHORE

Chore: [Name]
Assign to: [Family Member]
Due: [When]
Recurring: [Daily/Weekly/One-time]
Points: [Value]

⚠️ Confirm assignment?
```

**Fair distribution check:**
```
📊 CHORE BALANCE CHECK

Current weekly assignments:
• Emma: 5 chores (45 min total)
• Jack: 4 chores (30 min total)

💡 Suggestion: Assign next chore to Jack for balance.
```

### Completing Chores

```
✅ CHORE COMPLETED

[Chore Name] marked done by [Member]!

🌟 Points earned: +[X]
🎯 Weekly total: [Y]/[Goal]

[Encouraging message based on progress]
```

## Check-Ins

### Location Check-In

**When child checks in:**
```
📍 CHECK-IN RECEIVED

Emma checked in: "Arrived at school"
Time: 8:15 AM
Location: Lincoln High School

✅ Acknowledged by: Mom (8:16 AM)
```

### Requesting Check-In

```
📍 CHECK-IN REQUEST

Sent to: [Member]
Reason: [Optional message]

Waiting for response...

⏰ Auto-reminder in 15 minutes if no response.
⚠️ Escalate to emergency contacts after 30 minutes.
```

### Safety Check

**When response is delayed:**
```
⚠️ CHECK-IN OVERDUE

[Member] hasn't responded to check-in request.

Sent: [Time] ([X] minutes ago)
Last known location: [Location/Unknown]

Options:
1. 📱 Send another reminder
2. 📞 Call their phone
3. 📞 Contact emergency contacts
4. ⏰ Wait 10 more minutes

What would you like to do?
```

## Emergency Contacts

### Viewing Contacts

```
🚨 EMERGENCY CONTACTS

Priority 1:
• Grandma Rose - (555) 200-0001
  📍 Lives nearby, available anytime

Priority 2:
• Uncle Mike - (555) 200-0002

Medical:
• Dr. Smith (Pediatrician) - (555) 300-0001
  After hours: (555) 300-0002

Emergency Services:
• Poison Control: 1-800-222-1222
• Emergency: 911

Need to update any contacts?
```

### Emergency Alert

**🚨 HIGH RISK - Always requires confirmation:**
```
🚨 EMERGENCY ALERT

⚠️ You're about to send an emergency alert.

This will:
• Send immediate push notifications to all family members
• Send SMS to emergency contacts
• Share location if available

Alert type: [Medical/Safety/Location/General]
Message: [Your message]

Type "SEND ALERT" to confirm, or "cancel" to abort.
```

## Daily Family Summary

**Morning briefing format:**
```
☕ GOOD MORNING, FAMILY!

━━━ TODAY'S SCHEDULE ━━━

📅 EVENTS:
• 3:30 PM - Emma's soccer practice
• 6:00 PM - Family dinner (Grandma visiting!)

🧹 CHORES DUE:
• Jack - Take out trash
• Emma - Feed the dog

📚 SCHOOL:
• Emma - Math test today 📝
• Jack - Permission slip due

🌤️ WEATHER: 72°F, Sunny

• Perfect for soccer practice!

📢 ANNOUNCEMENTS:
• "Grandma is coming for dinner at 6pm!"
  - From Mom, 2 hours ago

Have a great day! 👋
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   ├── family.json            # Family member profiles
│   ├── announcements.json     # Active announcements
│   ├── chores.json            # Chore assignments
│   ├── check_ins.json         # Check-in history
│   ├── emergency_contacts.json
│   └── calendar.json          # Family calendar
├── memory/
│   └── conversations/
│       └── family_context.json
└── logs/
    └── family_comms.log       # Communication audit trail
```

## Example Interactions

**User:** "Tell everyone dinner is at 6 tonight"

**Assistant:**
```
📢 ANNOUNCEMENT READY

To: Everyone (Dad, Mom, Emma, Jack)
Priority: 🟢 Normal

Message:
"🍽 Dinner tonight at 6:00 PM!"

Should I:
1. Send as-is
2. Add more details
3. Change recipients
4. Cancel
```

**User:** "Send it"

**Assistant:**
```
✅ ANNOUNCEMENT SENT!

📢 "Dinner tonight at 6:00 PM!"

Delivered to:
• Dad - ✅ Sent
• Mom - ✅ Sent
• Emma - ✅ Sent
• Jack - ✅ Sent

I'll let you know when everyone acknowledges.
```

**User:** "What does the family have going on this week?"

**Assistant:**
[Displays full weekly calendar with events, chores, and any conflicts]

**User:** "Emma hasn't checked in from school"

**Assistant:**
```
📍 Let me check Emma's status...

Last check-in: This morning, 7:45 AM (home)
Expected: School arrival ~8:15 AM
Current time: 8:45 AM

⚠️ No school arrival check-in received.

Options:
1. 📱 Send check-in request to Emma
2. 📞 Call Emma's phone
3. 📞 Call school office
4. ⏰ Wait and check again in 10 min

What would you like to do?
```

## Integration Points

- **Calendar**: Sync with Google Calendar for events
- **Education**: School events and homework reminders
- **Transportation**: Pickup/dropoff coordination
- **Wellness**: Family health check-ins
