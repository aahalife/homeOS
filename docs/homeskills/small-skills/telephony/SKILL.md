---
name: telephony
description: Make AI voice calls on behalf of the user. ALL CALLS ARE HIGH RISK. Never call without explicit YES.
risk: HIGH — ALWAYS
---

# Telephony Skill

## ⚠️ ABSOLUTE RULE: ALL CALLS ARE HIGH RISK

Never, under any circumstances, place a call without the user saying YES.
Not "maybe". Not "I guess". Not silence. Only YES / APPROVED / GO AHEAD / DO IT / CALL.

If unsure whether the user approved → DO NOT CALL. Ask again.

## When to Use

- User wants to call a business (restaurant, doctor, service)
- A skill hands off a phone task via OUTPUT_HANDOFF
- Online booking is unavailable and phone is the only option

## Step 1: Gather Call Details

Required before ANY call:
- **Business name** (REQUIRED)
- **Phone number** (REQUIRED — look it up if not provided)
- **Purpose** (REQUIRED — reservation, appointment, inquiry, complaint)
- **Key details** (date, time, party size, name, etc.)

Template:
```
📞 Phone call setup. I need:
1. 🏢 Business name
2. 📞 Phone number (or I'll look it up)
3. 📝 Purpose of call
4. 📅 Key details (date, time, etc.)
5. 👤 Name to use
6. ⏰ Time flexibility (e.g., ±30 min OK?)
```

If receiving OUTPUT_HANDOFF from another skill, extract these from handoff data.

## Step 2: Prepare Script

Show the user exactly what you will say:

```
📝 CALL SCRIPT:
"Hi, I'm calling on behalf of [NAME] to [PURPOSE].
[SPECIFIC REQUEST with date, time, details].
[FLEXIBILITY if any]."

I WILL:
✅ State details clearly
✅ Negotiate time within approved flexibility
✅ Confirm all details before hanging up
✅ Wait on hold up to 5 minutes

I WILL NOT:
❌ Give credit card or payment info
❌ Agree to charges without asking you
❌ Share sensitive personal information
❌ Make promises beyond what you approved
```

## Step 3: Get Approval

⚠️ THIS STEP IS MANDATORY. NEVER SKIP IT.

```
⚠️ PHONE CALL — APPROVAL REQUIRED

📞 Calling: [Business Name]
📞 Number: [Phone Number]
📝 Purpose: [Purpose]
📋 Details:
- [Detail 1]
- [Detail 2]
- [Detail 3]

I will speak using an AI voice on your behalf.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reply YES to call. Reply NO to cancel.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**APPROVED responses (proceed with call):**
- "yes", "YES", "yep", "yeah"
- "call", "call them", "make the call"
- "go ahead", "do it", "approved", "proceed"

**NOT APPROVED (do NOT call):**
- "no", "cancel", "stop", "wait", "nevermind"
- "maybe", "I guess", "sure" (ambiguous → ask again: "Just to confirm — should I place the call? YES or NO?")
- No response → do NOT call
- Anything not clearly affirmative → do NOT call

## Step 4: Make the Call

Show live status:
```
📞 CALLING [Business]...
⏳ Ringing...
🔗 Connected — speaking with [role]
⏸️ On hold (X min)
✅ Call complete
```

## Step 5: Report Outcome

**If successful:**
```
✅ CALL SUCCESSFUL
📋 Result: [what was confirmed]
- [Detail 1]
- [Detail 2]
- Confirmation: [# if given]
```

**If alternative offered:**
```
📞 [Business] offered alternatives:
1. [Option A]
2. [Option B]
3. [Option C]
Which one? Or "none" to try elsewhere.
```

**If failed:**
```
❌ CALL FAILED
Reason: [no answer / closed / fully booked / voicemail]
Options:
1. Try again in 30 min
2. Try different time/date
3. Try different business
4. Leave voicemail
5. You call them yourself
```

**If they ask for payment:**
```
⚠️ PAYMENT REQUESTED
They require: [credit card / deposit of $X]
I declined. Options:
1. Call them yourself to provide payment
2. Find alternative (no deposit)
3. Cancel
```

**If they ask something I can't answer:**
```
⚠️ NEED YOUR INPUT
They asked: "[question]"
Options:
1. I'll say I'll call back with that info
2. You tell me the answer now
3. End the call
```

## Step 6: Save and Handoff

Log every call:
```bash
echo '{"id":"call-'$(date +%s)'","business":"NAME","phone":"NUM","purpose":"X","outcome":"success|failed|voicemail","result":"DETAILS","ts":"NOW"}' >> ~/clawd/homeos/logs/calls.json
```

If call was for another skill (e.g., restaurant-reservation), hand back:
```
OUTPUT_HANDOFF:
  to: [originating-skill]
  reason: Call completed
  data:
    outcome: success|failed
    confirmed_time: [TIME]
    confirmation_number: [NUM]
    notes: [anything relevant]
```

## Voicemail Script

If voicemail reached and user approves leaving a message:
```
"Hi, this is a call on behalf of [NAME].
I'm calling to [PURPOSE] for [DATE/TIME/DETAILS].
Please call back at [CALLBACK NUMBER].
Thank you."
```

## Defaults

- Max hold time: 5 minutes (then report back)
- Time flexibility: ±30 minutes unless user specifies
- Retry: suggest retry after 30 minutes if no answer
- Voicemail: ask before leaving one
