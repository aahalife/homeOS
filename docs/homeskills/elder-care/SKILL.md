---
name: elder-care
description: Engage and care for elderly parents through friendly check-in conversations, medication tracking, symptom monitoring, nostalgic song playing, memory sharing, and keeping adult children informed. Use when the user mentions parents, elderly family, checking in on mom/dad, senior care, or wants help monitoring an aging parent's wellbeing.
---

# Elder Care Skill

Provide compassionate, consistent care for aging parents through AI-powered engagement while keeping adult children informed.

## Philosophy

- **Dignified engagement** - Treat elders as the wise individuals they are
- **Conversation, not surveillance** - Build genuine connection
- **Proactive but gentle** - Regular touch points without being intrusive
- **Comprehensive reporting** - Keep family informed with actionable insights

## When to Use

- User wants to set up regular check-ins with parents
- User asks about their parent's medication adherence
- User wants to monitor elderly parent's wellbeing
- User asks to play music or engage their parent
- User wants to keep track of their parent's health patterns
- User mentions aging parents living alone

## Core Capabilities

| Feature | Purpose | Frequency |
|---------|---------|------------|
| Daily Check-In Call | Wellness & engagement | 1-2x daily |
| Medication Reminders | Adherence tracking | Per schedule |
| Symptom Monitoring | Health tracking | During check-ins |
| Nostalgic Music | Emotional wellness | On-demand/daily |
| Memory Conversations | Cognitive engagement | Weekly |
| Opinion Discussions | Mental stimulation | During calls |
| Family Updates | Keep children informed | Daily/weekly |

## Initial Setup

**Onboarding for elder care:**
```
👵 ELDER CARE SETUP

Let's set up caring check-ins for [Parent Name].

1. 👤 BASIC INFO
   • Name: [Preferred name]
   • Relationship: [Mom/Dad/Grandparent]
   • Phone: [Their number]
   • Best times to call: [Morning/Afternoon/Evening]

2. 💊 MEDICATIONS
   [List their medications and schedules]

3. 🎵 PREFERENCES
   • Favorite music era: [1950s, 1960s, etc.]
   • Favorite artists: [Names]
   • Hobbies/interests: [Gardening, cooking, etc.]
   • Topics they enjoy: [Grandkids, sports, news, etc.]

4. ⚠️ HEALTH CONCERNS
   • Conditions to monitor: [Diabetes, heart, memory, etc.]
   • Warning signs to watch: [Confusion, pain, etc.]

5. 👨‍👩‍👧 FAMILY CONTACTS
   • Who should receive updates? [You, siblings]
   • Emergency contacts: [List]

This helps me have meaningful conversations with [Parent].
```

**Save elder profile:**
```bash
cat > ~/clawd/homeos/data/elder_care/[parent_id].json << 'EOF'
{
  "id": "parent-mom",
  "name": "Rose",
  "preferred_name": "Mom",
  "phone": "+15551234567",
  "relationship": "mother",
  "call_times": ["09:00", "19:00"],
  "medications": [
    {
      "name": "Metformin",
      "dosage": "500mg",
      "times": ["08:00", "20:00"],
      "purpose": "diabetes"
    }
  ],
  "music_preferences": {
    "era": "1960s",
    "artists": ["Frank Sinatra", "Ella Fitzgerald"],
    "genres": ["jazz", "big band"]
  },
  "interests": ["gardening", "cooking", "grandchildren", "old movies"],
  "health_monitoring": {
    "conditions": ["diabetes", "mild arthritis"],
    "watch_for": ["blood sugar symptoms", "joint pain level"]
  },
  "family_contacts": [
    {"name": "John", "relationship": "son", "phone": "+15559876543", "notify": true}
  ]
}
EOF
```

## Daily Check-In Conversations

### Morning Check-In

**Conversation flow:**
```
🌅 MORNING CHECK-IN CALL

Calling: [Parent Name]
Scheduled: 9:00 AM

━━━ CONVERSATION SCRIPT ━━━

1. GREETING (warm, personal)
   "Good morning, [Name]! It's your daily 
    check-in. How are you feeling today?"

2. WELLNESS CHECK (conversational, not clinical)
   "Did you sleep well last night?"
   "How's your energy this morning?"
   "Any aches or pains bothering you?"

3. MEDICATION REMINDER (gentle)
   "Have you taken your morning medications?
    That's your [Medication] - did you get it?"

4. PLANS FOR TODAY (engagement)
   "What are you up to today?"
   "Any visitors coming by?"

5. POSITIVE CLOSE
   "Wonderful! Have a great day. I'll check 
    in again this evening. Love you!"

━━━ THINGS TO LISTEN FOR ━━━

⚠️ FLAGS TO REPORT:
• Confusion about day/time
• Unusual fatigue or pain
• Missed medications
• Mentions of falls or accidents
• Mood changes (sadness, anxiety)
• Appetite changes
```

### Evening Check-In

```
🌙 EVENING CHECK-IN CALL

Calling: [Parent Name]
Scheduled: 7:00 PM

━━━ CONVERSATION SCRIPT ━━━

1. GREETING
   "Hi [Name]! How was your day?"

2. DAY RECAP (engagement)
   "Did you do anything nice today?"
   "Did you eat well?"
   "Any visitors or calls?"

3. EVENING MEDICATION
   "Time for your evening medications.
    Let me keep you company while you take them."

4. TOMORROW PREVIEW
   "Any plans for tomorrow?"
   "Need anything from anyone?"

5. RELAXATION
   "Would you like me to play some music 
    while you relax?"
   [Play favorite music]

6. CLOSE
   "Sleep well! I'll talk to you in the morning."
```

## Medication Tracking

### Medication Reminders

**During calls:**
```
💊 MEDICATION CHECK

"[Name], it's time for your medications.

You should take:
• Metformin 500mg (for diabetes)
• Lisinopril 10mg (for blood pressure)

I'll wait while you take them. Let me know when you're done!"

[After confirmation]

"Great job! I've noted that down. You're all set 
until tonight."
```

**Tracking medication adherence:**
```
💊 MEDICATION LOG - [Parent Name]

This Week:

Mon AM: ✅ Taken | PM: ✅ Taken
Tue AM: ✅ Taken | PM: ✅ Taken
Wed AM: 🟡 Late  | PM: ✅ Taken
Thu AM: ✅ Taken | PM: ⏳ Pending

Adherence: 92%

⚠️ ALERTS FOR FAMILY:
• Wednesday AM was 2 hours late
• May need extra reminder call on Wed
```

## Symptom & Wellness Monitoring

### Conversational Health Tracking

**Questions woven into natural conversation:**
```
🩺 WELLNESS TRACKING

During calls, I naturally ask about:

😴 SLEEP:
"How did you sleep last night?"
"Did you wake up during the night?"

💪 ENERGY:
"How's your energy today?"
"Feeling rested?"

🍽 APPETITE:
"What did you have for breakfast/lunch/dinner?"
"Is your appetite good?"

❤️ PAIN/COMFORT:
"Any aches or pains today?"
"How are your joints feeling?"

🧠 MOOD:
"How are you feeling emotionally?"
"Missing anyone today?"

👣 MOBILITY:
"Did you get out of the house today?"
"Any trouble getting around?"
```

### Health Summary for Family

```
🩺 HEALTH SUMMARY: [Parent Name]

Week of [Date]

━━━ OVERALL WELLNESS ━━━

Score: 8/10 (Good week)

✅ POSITIVES:
• Good energy levels all week
• Sleeping well (7-8 hours)
• Appetite normal
• Took all medications
• Had visitors Wednesday (neighbor Betty)

🟡 THINGS TO WATCH:
• Mentioned knee pain Tuesday (mild)
• Seemed tired Thursday (recovering from cold?)
⚠️ CONCERNS TO ADDRESS:
• None this week

━━━ MOOD TRACKING ━━━

Mon: 😊 Good - excited about grandkids visit
Tue: 😐 Neutral - quiet day
Wed: 😊 Good - enjoyed Betty's visit
Thu: 😴 Tired - "felt a bit off"
Fri: 😊 Good - back to normal

━━━ CONVERSATION HIGHLIGHTS ━━━

• Talked about grandkids' soccer game
• Reminisced about your father (anniversary week)
• Enjoyed Frank Sinatra music Friday evening

💬 SUGGESTED TOPICS FOR YOUR NEXT CALL:
• Ask about the grandkids visit
• Mention you remember the anniversary
• Tell her about [current event she'd enjoy]
```

## Nostalgic Music & Entertainment

### Playing Music

**Music session:**
```
🎵 MUSIC TIME

"[Name], how about some music? 
I have some Frank Sinatra ready for you."

🎶 Now Playing:
"Fly Me to the Moon" - Frank Sinatra

📀 Playlist:
1. Fly Me to the Moon
2. The Way You Look Tonight
3. New York, New York
4. My Way
5. Strangers in the Night

"Your favorite era - the good old days!
Enjoy, and I'll chat with you later."
```

### Memory Lane Conversations

**Weekly memory engagement:**
```
💭 MEMORY CONVERSATION

"[Name], I was thinking about old times.
Can you tell me about [topic]?"

TOPIC ROTATION:

Week 1: "Where did you and [spouse] meet?"
Week 2: "What was your favorite job?"
Week 3: "Tell me about [child's name] as a baby."
Week 4: "What was your neighborhood like growing up?"
Week 5: "What's your favorite holiday memory?"
Week 6: "Who was your best friend growing up?"

[Save their stories for family record]

📝 STORY SAVED:
"[Parent] shared a beautiful story about 
how they met [spouse] at a dance in 1965..."

👪 This story has been shared with family.
```

## Opinion & Discussion Topics

### Engaging Conversations

**Current events discussion:**
```
💬 OPINION TIME

"[Name], I'm curious what you think about this..."

TOPIC IDEAS (based on interests):

🏈 SPORTS: "Did you see the game last night?"
🌡️ WEATHER: "What do you think of this weather?"
🍳 COOKING: "What's your secret to good [dish]?"
🌿 GARDENING: "What should I plant this season?"
📺 TV/MOVIES: "Have you seen any good shows?"
👶 GRANDKIDS: "What advice would you give [grandchild]?"

"I love hearing your perspective. You've seen so much!"
```

### Wisdom Capture

**Recording life lessons:**
```
📜 WISDOM COLLECTION

"[Name], you've lived such a full life.
What's the best advice you'd give to young people today?"

[Record response]

📝 SAVED:
"[Parent] says: 'The most important thing 
is to be kind to everyone. You never know 
what someone is going through.'"

Date: [Date]
Topic: Life advice

👪 Shared with family for preservation.
```

## Family Updates

### Daily Update for Adult Children

**Push notification/summary:**
```
👵 DAILY UPDATE: Mom

☕ Morning Check-In: 9:15 AM
• Mood: 😊 Good
• Sleep: Slept well
• Meds: ✅ Taken on time
• Plans: Doctor appointment at 2pm

🌙 Evening Check-In: 7:30 PM
• Mood: 😊 Good, tired
• Doctor visit: Went well, no concerns
• Meds: ✅ Taken
• Ate: Good dinner

👬 Today's highlight:
"She talked about your childhood birthday 
parties. Really enjoyed the memory."

✅ All is well. No action needed.
```

### Urgent Alerts

**Immediate family notification:**
```
🚨 URGENT: Mom Concern

During today's check-in, I noticed:

⚠️ [Concern type]

Details:
• [Specific observation]
• [What she said]
• [Behavior noted]

Suggested Action:
• [Recommended next step]

This requires your attention.

[Call Mom] [Acknowledge] [More info]
```

**Alert severity levels:**

| Level | Trigger | Action |
|-------|---------|--------|
| 🟢 Low | Missed medication once | Note in report |
| 🟡 Medium | Confused, unusual fatigue | Daily alert |
| 🔴 High | Fall, chest pain, severe confusion | Immediate call |
| 🚨 Emergency | Unresponsive, medical crisis | 911 + family |

## Weekly Family Report

```
📊 WEEKLY ELDER CARE REPORT

[Parent Name] - Week of [Date]

━━━ OVERALL STATUS: Good 🟢 ━━━

Check-ins completed: 14/14 ✅
Medications taken: 98%
Mood average: 8/10

━━━ HEALTH OBSERVATIONS ━━━

😴 Sleep: Good (avg 7.5 hours)
🍽 Appetite: Normal
💪 Energy: Good
🦕 Pain: Mild knee pain (2x)
🧠 Cognition: Clear, no concerns

━━━ SOCIAL ━━━

• Visitors: 2 (Betty, mail carrier)
• Outings: 1 (grocery store)
• Calls: 3 (you, sister, friend)

━━━ MEMORABLE MOMENTS ━━━

• Shared story about your first bicycle
• Gave advice: "Always eat breakfast"
• Enjoyed: Perry Como on Thursday

━━━ RECOMMENDATIONS ━━━

• Knee pain - consider mentioning at next doctor visit
• She mentioned missing gardening - spring planning?
• Next month is her birthday - start planning!

━━━ YOUR ACTION ITEMS ━━━

☐ Call to hear the bicycle story yourself
☐ Schedule next doctor appointment
☐ Consider visit next weekend
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   └── elder_care/
│       ├── [parent_id].json        # Elder profile
│       ├── check_ins/              # Daily check-in logs
│       ├── medications/            # Med tracking
│       ├── health_log.json         # Symptom tracking
│       └── stories/                # Memory recordings
├── memory/
│   └── elder_care/
│       ├── conversation_topics.json
│       └── preferences.json
└── logs/
    └── elder_care/
        ├── calls.log              # Call history
        └── alerts.log             # Alert history
```

## Example Interactions

**User:** "Can you check in on my mom?"

**Assistant:**
```
👵 CHECKING ON MOM

Last check-in: Today, 9:15 AM

Summary:
• Mood: 😊 Good
• Slept well last night
• Took morning medications ✅
• Plans: Watching her shows today

No concerns reported.

Would you like me to:
1. Call her now for a live check-in?
2. Play her some music?
3. Schedule an extra call today?
4. Show the weekly report?
```

**User:** "Set up daily calls with my dad"

**Assistant:**
```
👴 ELDER CARE SETUP: Dad

I'll set up caring daily check-ins. I need some info:

1. What's your dad's phone number?
2. Best times to call? (Morning and/or evening)
3. What medications does he take?
4. Any health conditions to monitor?
5. What does he enjoy? (music, topics, hobbies)
6. Your contact info for daily updates

I'll have friendly conversations with him, 
track his wellbeing, and keep you informed.

Let's get started - what's his phone number?
```

**User:** "Play some old music for my mom"

**Assistant:**
```
🎵 MUSIC FOR MOM

I'll call Mom and play her favorites!

Playing her preferred playlist:
🎶 "1960s Jazz & Standards"

1. Frank Sinatra - Fly Me to the Moon
2. Ella Fitzgerald - Summertime
3. Nat King Cole - Unforgettable
4. Dean Martin - That's Amore
5. Tony Bennett - I Left My Heart in San Francisco

⚠️ APPROVAL NEEDED

I'll call Mom now and play this music during our chat.

Call and play music?
```

## Integration Points

- **Telephony**: AI voice calls for check-ins
- **Healthcare**: Medication tracking integration
- **Family Comms**: Family update distribution
- **Calendar**: Doctor appointment reminders
- **Music Services**: Streaming integration for music
