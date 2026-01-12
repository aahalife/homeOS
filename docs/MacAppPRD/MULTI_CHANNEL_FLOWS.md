# Hearth: Multi-Channel Flows

> How Hearth interacts with family members across different channels and devices.

---

## Channel Overview

| Channel | Primary Users | Best For | Limitations |
|---------|---------------|----------|-------------|
| **Mac App** | Parents (primary) | Full dashboard, complex tasks | Desktop only |
| **iMessage** | All family | Quick updates, reminders | Text-based |
| **WhatsApp** | Extended family | Group coordination | Requires app |
| **Phone Call** | Elders | Check-ins, emergencies | Requires answer |
| **Voice (Siri/AirPods)** | Parents on-the-go | Hands-free queries | Limited context |
| **Notifications** | All | Alerts, reminders | Easy to miss |

---

## 1. Parent Flows (Mac App Primary)

### Morning Routine

```
7:00 AM - Mac notification appears:
┌───────────────────────────────┐
│ 🏠 Hearth                      │
│ Good morning! Your briefing   │
│ is ready. [View]              │
└───────────────────────────────┘

Click → Menu bar dropdown shows full briefing

Alternatively, with AirPods:
"Hey Siri, what's my Hearth briefing?"
→ Voice reads summary
```

### Quick Action: "What's for dinner?"

```
Option A: Menu Bar Click
┌───────────────────────────────┐
│ 🍽 Tonight's suggestion:       │
│                               │
│ Chicken Stir-Fry              │
│ ⏱ 25 min | Uses pantry items  │
│                               │
│ [This one] [Other ideas]      │
└───────────────────────────────┘

Option B: Voice
"Hey Siri, ask Hearth what's for dinner"
→ "Based on what you have, I'd suggest chicken 
   stir-fry. It's quick and the kids like it. 
   Sound good?"

Option C: iMessage to Hearth
"What should we have for dinner?"
→ "Chicken stir-fry? You have everything 
   except snow peas. Or tacos - always a hit."
```

### Elder Check-In Approval

```
8:55 AM - Approval request:
┌───────────────────────────────────┐
│ 📞 Elder Check-In                  │
│                                   │
│ Ready to call Grandma Rose        │
│ Morning check-in scheduled 9:00am │
│                                   │
│ [ ] Always allow (9am weekdays)   │
│                                   │
│ [Skip Today]    [Call Now]        │
└───────────────────────────────────┘

After call completes:
┌───────────────────────────────────┐
│ ✅ Grandma Rose - Doing well        │
│                                   │
│ "Slept great, having lunch with   │
│  Dorothy. Took medications."      │
│                                   │
│ Mood: 😊 Good                      │
│ Next: 7:00 PM                     │
│                                   │
│ [View Details]  [Call Now]        │
└───────────────────────────────────┘
```

---

## 2. Elder Flows (Phone Primary)

### Daily Check-In Call Script

```
[Phone rings - Caller ID shows family number]

Rose: "Hello?"

Hearth: "Good morning, Rose! It's your morning 
        check-in. How are you doing today?"

Rose: "Oh, hello dear! I'm doing well, thank you."

Hearth: "That's wonderful to hear! Did you sleep 
        well last night?"

Rose: "Yes, I slept very well actually."

Hearth: "Great! And have you had a chance to take 
        your morning medications? That's your 
        blood pressure pill and the vitamin D."

Rose: "Oh yes, I took them with my breakfast."

Hearth: "Perfect! Sarah wanted me to tell you that 
        Emma scored a goal at soccer yesterday. 
        She was so excited!"

Rose: "Oh how wonderful! Tell her grandma is 
      proud of her!"

Hearth: "I will! Would you like to listen to some 
        music? I have some Frank Sinatra ready."

Rose: "That would be lovely."

Hearth: "Here's 'Fly Me to the Moon' - one of your 
        favorites."

[Music plays for 3 minutes]

Hearth: "I hope you enjoyed that, Rose. Is there 
        anything you need today?"

Rose: "No, I'm all set. Thank you for calling."

Hearth: "You're welcome! I'll call again this evening 
        around 7. Have a wonderful day, and Sarah 
        sends her love!"

Rose: "Thank you, dear. Goodbye!"

[Call ends - summary sent to Sarah]
```

### Emergency Detection During Call

```
Hearth: "How are you feeling today, Rose?"

Rose: "I... I'm not sure. I feel a bit confused. 
      What day is it?"

[Hearth detects potential concern]

Hearth: "It's Tuesday, January 14th. Are you feeling 
        okay? Any dizziness or discomfort?"

Rose: "I just feel a bit off today..."

[Hearth flags for family notification]

Hearth: "That's okay, Rose. Let's take it easy. 
        Did you eat breakfast this morning?"

[Continues conversation while alerting Sarah]

--- Parallel notification to Sarah ---
┌───────────────────────────────────┐
│ ⚠️ Check-In Alert                   │
│                                   │
│ Grandma Rose seems confused       │
│ during check-in. Currently on     │
│ the call with her.                │
│                                   │
│ She reported:                     │
│ - Confusion about the day         │
│ - "Feeling a bit off"             │
│                                   │
│ [Join Call]  [I'll Call Her]      │
└───────────────────────────────────┘
```

---

## 3. Children Flows (Parent-Mediated + iMessage)

### Homework Reminder (to Emma, 12)

```
iMessage to Emma:
┌───────────────────────────────┐
│ 📚 Hey Emma!                    │
│                               │
│ Math homework is due tomorrow │
│ (Chapter 5 problems).         │
│                               │
│ Need any help?                │
└───────────────────────────────┘

Emma: "I know, I'm doing it now"

Hearth: "Great! 👍"

[Status updated in parent dashboard]
```

### Activity Prep Reminder (to Emma)

```
iMessage to Emma:
┌───────────────────────────────┐
│ ⚽ Soccer tomorrow!             │
│                               │
│ Checklist:                    │
│ ▢ Cleats                      │
│ ▢ Shin guards                 │
│ ▢ Water bottle               │
│ ▢ Snack                      │
│                               │
│ Packed?                       │
└───────────────────────────────┘

Emma: "Yep all packed!"

Hearth: "✅"

[Parent notified: "Emma's soccer bag is packed"]
```

### Chore Reminder (to Jack, 8 - via parent)

```
To Parent (Sarah):
┌───────────────────────────────┐
│ Jack's chores for today:      │
│                               │
│ ▢ Set dinner table           │
│ ▢ Feed the dog               │
│                               │
│ Want me to remind him?        │
│                               │
│ [Yes, send reminder]  [I'll tell him] │
└───────────────────────────────┘
```

---

## 4. Co-Parent Flows (iMessage/Notification)

### Schedule Change Alert

```
iMessage to Mike:
┌───────────────────────────────┐
│ 📅 Schedule change:            │
│                               │
│ Emma's soccer moved to 4pm    │
│ (was 3:30pm)                  │
│                               │
│ You're on pickup - still work?│
│                               │
│ [Yes] [No, need to swap]      │
└───────────────────────────────┘

Mike: "No, need to swap"

[Hearth notifies Sarah]:
"Mike can't do Emma pickup at 4pm. Can you swap?"
```

### Elder Update

```
iMessage to Mike:
┌───────────────────────────────┐
│ 👵 Your mom check-in:          │
│                               │
│ She's doing great today!      │
│ Good sleep, took meds,        │
│ having lunch with Dorothy.    │
│                               │
│ She asked about Emma's game.  │
└───────────────────────────────┘
```

---

## 5. Family Group Flows (iMessage/WhatsApp)

### Family Announcement

```
iMessage to "Family" group:
┌───────────────────────────────┐
│ 🏠 From Mom:                   │
│                               │
│ Family dinner at 6:30 tonight!│
│ We're having tacos.           │
│                               │
│ Please be home on time!       │
└───────────────────────────────┘

Emma: "👍"
Mike: "On my way"
Jack: [via parent relay] "🌮"

[Hearth tracks acknowledgments]
```

### Weekend Planning (Family Poll)

```
iMessage to "Family" group:
┌───────────────────────────────┐
│ 🌟 Saturday activity?          │
│                               │
│ A. Bike ride at the park      │
│ B. Movie afternoon            │
│ C. Mini golf                  │
│                               │
│ Reply with your pick!         │
└───────────────────────────────┘

Emma: "C!"
Mike: "A or C"
Jack: "B!!!"

[Hearth tallies and reports]:
"Looks like Mini Golf wins! Want me to 
check for tee times?"
```

---

## 6. Voice Interaction Flows

### Via Siri/AirPods

```
"Hey Siri, ask Hearth about today's schedule"

Hearth: "Today you have: School drop-off at 8,
        a 10am meeting, Emma's soccer at 3:30
        with Dad on pickup, and family dinner
        at 6:30. Grandma's check-in is at 9
        and 7. Anything else?"

User: "What's for dinner?"

Hearth: "I'm thinking chicken stir-fry - it's 
        quick and you have the ingredients.
        Sound good?"

User: "Sure"

Hearth: "Great, I'll remind you to start at 5:45."
```

### Hands-Free Kitchen Mode

```
"Hey Hearth, start cooking mode"

Hearth: "Cooking mode active. What are we making?"

"Chicken stir-fry"

Hearth: "Got it. I'll walk you through it.
        First, gather: chicken breast, soy sauce,
        vegetables, garlic, and ginger. Ready?"

"Ready"

Hearth: "Great. Step 1: Cut the chicken into
        bite-sized pieces. Let me know when done."

[Continues hands-free through recipe]
```

---

## 7. Emergency Flows

### Medical Emergency

```
User: "Hearth, Jack fell and hit his head"

[EMERGENCY MODE ACTIVATED]

Hearth: "Is Jack conscious and breathing?"

User: "Yes, he's crying but awake"

Hearth: "Okay, that's good. Check for:
        - Bleeding
        - Swelling
        - Can he move his neck?
        
        If you see any of these, call 911:
        - Won't stop crying
        - Vomiting
        - Won't wake up
        - Unequal pupils
        
        What do you see?"

[Parallel: Prepares to call Mike, looks up nearest ER]

User: "Small bump, no blood, he's calming down"

Hearth: "Good signs. Keep him calm, apply a cold
        pack to the bump. Watch him for the next
        few hours for any changes.
        
        Want me to let Mike know what happened?"
```

---

## Channel Selection Matrix

| Urgency | Time | Recipient | Primary Channel | Fallback |
|---------|------|-----------|-----------------|----------|
| Low | Daytime | Parent (primary) | Mac notification | - |
| Low | Daytime | Parent (secondary) | iMessage | - |
| Low | Daytime | Teen | iMessage | - |
| Low | Daytime | Child | Parent relay | - |
| Medium | Daytime | Parent | Mac + iMessage | - |
| Medium | Daytime | Teen | iMessage | Parent |
| High | Any | Parent | All channels | Phone call |
| High | Any | Elder | Phone call | Emergency contact |
| Emergency | Any | All | Phone + all channels | 911 |

---

*The right message, to the right person, at the right time, on the right channel.*
