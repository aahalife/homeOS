---
name: telephony
description: Make AI-powered voice calls on behalf of the user including restaurant reservations, appointment scheduling, and customer service calls. Use when the user wants to call a restaurant, book an appointment by phone, make a customer service call, or needs phone-based tasks handled. HIGH RISK - always requires explicit approval.
---

# Telephony Skill

Make AI-powered voice calls to accomplish tasks like restaurant reservations, appointment booking, and customer service inquiries.

## ⚠️ HIGH RISK SKILL

**All phone calls require EXPLICIT user approval before dialing.**

This skill can:
- Make outbound phone calls using AI voice
- Speak on behalf of the user
- Negotiate and confirm bookings
- Handle common call scenarios

## When to Use

- User wants to make a restaurant reservation by phone
- User needs to book an appointment at a place requiring phone calls
- User wants help with a customer service call
- User asks to "call" any business
- Online booking isn't available or preferred

## Workflow Overview

```
1. Gather Call Details → 2. Prepare Script → 3. GET EXPLICIT APPROVAL
→ 4. Make Call → 5. Report Outcome → 6. Save Results
```

## Step 1: Gather Call Details

**For restaurant reservations:**
```
📞 PHONE RESERVATION SETUP

I can call to make a reservation. I need:

1. 🍽 Restaurant name: [Name]
2. 📞 Phone number: [Number if known, or I'll look it up]
3. 📅 Date: [When]
4. ⏰ Time: [Preferred time]
5. 👥 Party size: [Number of people]
6. 🗒️ Name for reservation: [Name]
7. 🎉 Special occasion? [Birthday, anniversary, etc.]
8. 🍽 Dietary needs? [Allergies, preferences]

Time flexibility: [e.g., +/- 30 min OK?]
```

**For appointment booking:**
```
📞 APPOINTMENT CALL SETUP

I can call to book an appointment. I need:

1. 🏢 Business name: [Name]
2. 📞 Phone number: [Number]
3. 📅 Preferred date: [When]
4. ⏰ Preferred time: [Time range]
5. 📝 Reason for visit: [Brief description]
6. 👤 Whose name: [Name]
7. 📞 Callback number: [Your phone]
```

## Step 2: Prepare Call Script

**Restaurant reservation script:**
```
📝 CALL SCRIPT PREVIEW

I'll say something like:

"Hi! I'm calling to make a reservation for [NAME]
on [DATE] at [TIME] for [X] people.

If that time isn't available, [TIME FLEXIBILITY].

[If special occasion]: It's for a [OCCASION].
[If dietary needs]: We have [NEEDS] to accommodate."

I'll handle:
✅ Time negotiation within your bounds
✅ Being put on hold
✅ Getting transferred
✅ Confirming all details
❌ I won't provide credit card info
❌ I'll decline any deposits without asking you first
```

## Step 3: Request Approval

**⚠️ APPROVAL REQUEST (REQUIRED):**
```
⚠️ PHONE CALL APPROVAL REQUIRED

I'm about to call:

📞 [Business Name]
📞 [Phone Number]

Purpose: [Reservation/Appointment/Inquiry]

Details:
• [Key detail 1]
• [Key detail 2]
• [Key detail 3]

I will speak using an AI voice on your behalf.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reply "CALL" or "YES" to proceed.
Reply "NO" or "CANCEL" to abort.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Valid approval responses:**
- "yes", "CALL", "call them", "go ahead", "do it", "make the call"

**Invalid/abort responses:**
- "no", "cancel", "stop", "nevermind", "wait"
- Any response that isn't clearly affirmative

## Step 4: Make the Call

**During call status:**
```
📞 CALL IN PROGRESS...

Calling: [Business Name]
Status: [Ringing / Connected / On Hold / Complete]

Live updates:
• [10:30:15] Dialing...
• [10:30:22] Connected - speaking with host
• [10:30:45] Checking availability...
• [10:31:10] Time confirmed!
• [10:31:30] Call complete

Please wait...
```

## Step 5: Report Outcome

**Successful reservation:**
```
✅ CALL SUCCESSFUL!

🍽 RESERVATION CONFIRMED

Restaurant: [Name]
Date: [Date]
Time: [Time]
Party: [X] people
Name: [Name]
Confirmation: [#Number if given]

Notes from the call:
• [Any special info mentioned]

📅 Added to your calendar with reminders.

Anything else you need?
```

**Alternative time offered:**
```
📞 CALL UPDATE

[Restaurant] doesn't have [requested time] available.

They offered:
1. [Alternative Time 1]
2. [Alternative Time 2]
3. [Alternative Time 3]

Which would you prefer?
(Or say "none" and I'll try another restaurant)
```

**Call failed:**
```
❌ CALL ISSUE

The call didn't go as planned.

What happened: [Reason]
• No answer after 60 seconds
• Voicemail reached
• Restaurant is closed
• Not taking reservations for that time

Options:
1. 📞 Try calling again in 30 min
2. 📅 Try a different time
3. 🍽 Try a different restaurant
4. 📝 Leave a voicemail message
5. ✋ I'll call them myself

What would you like to do?
```

## Call Handling Scenarios

### Put on Hold
```
📞 ON HOLD

[Business] put me on hold.
Waiting... (2 min 30 sec so far)

I'll keep waiting up to 5 minutes.
The call will continue automatically when they return.
```

### Transferred
```
📞 BEING TRANSFERRED

They're transferring me to [reservations/manager/etc.]
Please wait...
```

### Voicemail Reached
```
📞 VOICEMAIL

[Business] didn't answer - got voicemail.

Options:
1. 📝 Leave a message requesting callback
2. 📞 Try again later
3. ✋ Skip voicemail

What should I do?
```

### Voicemail Message Script
```
Message I'll leave:

"Hi, this is a call on behalf of [NAME].
I'm calling to make a reservation for [DATE] around [TIME]
for [X] people.

Please call back at [PHONE NUMBER].
Thank you!"

Leave this message?
```

### Unexpected Questions
```
📞 NEED YOUR INPUT

They asked: "[Question I can't answer]"

I can:
1. Tell them I'll call back with that info
2. Put them on hold while I ask you
3. Give a general answer

What should I say?
```

## Safety & Limitations

**I WILL:**
✅ State the reservation details clearly
✅ Negotiate time within approved flexibility
✅ Confirm all details before hanging up
✅ Be polite and professional
✅ Wait on hold patiently
✅ Handle transfers gracefully

**I WON'T:**
❌ Provide credit card information
❌ Agree to deposits without asking you first
❌ Share sensitive personal information
❌ Lie or misrepresent the situation
❌ Make promises I can't keep

**If they require payment:**
```
⚠️ PAYMENT REQUESTED

They require:
• Credit card to hold reservation
• $[X] deposit

I declined for now. Would you like to:
1. Call them yourself to provide payment
2. Find a different restaurant (no deposit)
3. Cancel this request
```

## Call Logging

**Save call record:**
```bash
cat >> ~/clawd/homeos/logs/calls.json << 'EOF'
{
  "id": "call-TIMESTAMP",
  "type": "restaurant_reservation",
  "business": "BUSINESS_NAME",
  "phone": "PHONE_NUMBER",
  "started": "TIMESTAMP",
  "duration_seconds": X,
  "outcome": "success|failed|voicemail|callback_needed",
  "result": {
    "confirmed_time": "TIME",
    "confirmation_number": "NUMBER",
    "notes": "NOTES"
  },
  "transcript": "FULL_TRANSCRIPT"
}
EOF
```

## Example Interactions

**User:** "Call Osteria Romana and book a table for Saturday at 7pm"

**Assistant:**
```
📞 I'll call to make a reservation.

Let me get a few more details:

1. 👥 How many people?
2. 🗒️ Name for the reservation?
3. ⏰ Flexible on time? (e.g., 6:30-7:30 OK?)
4. 🎉 Special occasion?
5. 🍽 Any dietary requirements?
```

**User:** "4 people, under Johnson, time is flexible by 30 min"

**Assistant:**
```
⚠️ PHONE CALL APPROVAL REQUIRED

I'm about to call:

📞 Osteria Romana
📞 (555) 123-4567

Request:
• Saturday, [Date]
• 7:00 PM (flexible 6:30-7:30)
• 4 people
• Under: Johnson

I'll speak using an AI voice on your behalf.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reply "CALL" to proceed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**User:** "CALL"

**Assistant:**
```
📞 CALLING...

Osteria Romana
Please wait...

• 10:30:15 - Dialing...
• 10:30:22 - Connected
• 10:30:35 - Speaking with host...
• 10:31:02 - 7pm is available!
• 10:31:15 - Confirming details...
• 10:31:28 - Call complete

✅ RESERVATION CONFIRMED!

🍽 Osteria Romana
📅 Saturday, January 20
⏰ 7:00 PM
👥 4 people
🗒️ Under: Johnson
📝 Confirmation: #4521

Notes: They said to check in at the host stand.

📅 Added to your calendar with reminders!
```

## Integration Points

- **Restaurant Reservation**: Primary use case for telephony
- **Calendar**: Auto-add confirmed reservations
- **Healthcare**: Book doctor appointments by phone
- **Home Maintenance**: Contact service providers
