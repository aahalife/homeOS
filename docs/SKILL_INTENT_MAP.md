# Skill Intent Map — RAG Reference

## How This Document Works

This document is designed for **RAG (Retrieval-Augmented Generation) chunking**. Each skill section is a **self-contained chunk** that can be retrieved independently from a vector database.

**Architecture:**
1. The iOS app embeds this entire document into a local vector DB at build/install time
2. When a user sends a message, Gemma 3n generates an embedding of the message
3. The vector DB returns the top-K most relevant skill chunks
4. Gemma 3n uses the retrieved chunks to determine which skill(s) to invoke
5. The router dispatches to the matched skill with context

**Chunking strategy:** Each `### [Skill Name]` section under the Intent Routing Table is one chunk. The Ambiguity Resolution and Multi-Skill Flows sections are additional chunks. Headers are clear and unique to maximize retrieval precision.

**Why this matters:** Gemma 3n is a small on-device model. It cannot memorize all 21 skill definitions. RAG lets it "look up" the right skill at inference time with high accuracy and low latency, without sending data to the cloud.

---

## Skill Registry

| # | Skill ID | One-Line Description |
|---|----------|---------------------|
| 1 | `chat-turn` | Message router — classifies every user message and dispatches to the correct skill or handles general chat |
| 2 | `education` | Track homework, grades, and study plans for ONE student at a time |
| 3 | `elder-care` | Compassionate check-ins, medication tracking, and wellness monitoring for aging parents |
| 4 | `family-bonding` | Plan family activities, outings, date nights, and quality time experiences |
| 5 | `family-comms` | Family communication hub — announcements, calendar coordination, chores, check-ins, emergency contacts |
| 6 | `habits` | Build and track habits using behavioral science — stages of change, barriers, stress-aware nudging |
| 7 | `healthcare` | Family health triage, medication reminders, appointment booking, prescription refills (never diagnoses) |
| 8 | `hire-helper` | Find and hire household help — babysitters, housekeepers, tutors, pet sitters, caregivers |
| 9 | `home-maintenance` | Home repairs, emergency safety (gas/fire/flood), preventive maintenance schedules |
| 10 | `infrastructure` | Core conventions for all HomeOS skills — storage, approvals, errors, logging (internal, not user-facing) |
| 11 | `marketplace-sell` | Help sell items on Facebook Marketplace, eBay, Craigslist — listing creation, pricing, scam detection |
| 12 | `meal-planning` | Weekly meal plans, grocery lists, prep schedules, recipes — always cross-checks family allergies |
| 13 | `mental-load` | Reduce cognitive burden with briefings, reminders, decision help, and weekly planning |
| 14 | `note-to-actions` | Transform articles, videos, books, and ideas into concrete atomic habits using the 4 Laws of Behavior Change |
| 15 | `psy-rich` | Suggest concrete psychologically rich experiences — novel, perspective-shifting, aesthetically elevating activities |
| 16 | `restaurant-reservation` | Find and book restaurant reservations with dietary awareness |
| 17 | `school` | Orchestrate school life across ALL children — automated daily checks, weekly summaries, multi-child coordination |
| 18 | `telephony` | Make AI voice calls on behalf of the user — always HIGH risk, always requires explicit YES |
| 19 | `tools` | Core utilities — calendar, reminders, weather, notes, planning; powers other skills |
| 20 | `transportation` | Manage rides, commutes, carpools, parking, departure alerts for families |
| 21 | `wellness` | Track family wellness — hydration, steps, sleep, screen time, energy, posture breaks |

---

## Intent Routing Table

---

### Chat Turn (Router)

- **ID**: `chat-turn`
- **Triggers**: (this skill is the default fallback — it activates when NO other skill matches, or when the message is ambiguous general conversation)
- general question, chitchat, hello, hi, hey, what's up, good morning, good night, thanks, thank you, help, what can you do, who are you, tell me about, random question, how are you, talk to me, I have a question, just wondering, quick question, fun fact
- **Sample Utterances**:
  - "Hey, how's it going?"
  - "What can you help me with?"
  - "Tell me a joke"
  - "What's the meaning of life?"
  - "Thanks for your help"
  - "Good morning!"
  - "I have a random question"
  - "What do you know about black holes?"
  - "Can you help me with something?"
  - "Who are you?"
  - "What time is it in Tokyo?"
  - "Tell me something interesting"
- **Context Signals**: No specific context — this is the catch-all. If no other skill scores above threshold (0.3), chat-turn handles it.
- **Proactive Triggers**: None — this is reactive only.
- **Handoff Sources**: None — this IS the router. All messages enter here first.
- **Handoff Targets**: ALL other skills. Chat-turn routes TO every skill based on keyword and scoring.
- **Priority**: LOWEST — only handles messages when no other skill matches. Priority order: telephony > restaurant-reservation > marketplace-sell > hire-helper > general chat.
- **NOT This Skill**: Any message that contains skill-specific keywords should route to that skill, not stay here. "What should we have for dinner?" → meal-planning, NOT chat-turn.

---

### Education

- **ID**: `education`
- **Triggers**: homework, assignment, grades, test, exam, study, quiz, tutor, GPA, report card, school project, science fair, book report, essay, math homework, reading log, spelling test, final exam, midterm, extra credit, study guide, flashcards, study plan, tutoring, honor roll, failing, academic, subject, class grade, missing assignment, late homework, overdue assignment
- **Sample Utterances**:
  - "How's Emma's homework looking?"
  - "Check Jake's grades"
  - "Does anyone have a test this week?"
  - "Create a study plan for Sarah's math final"
  - "Emma has a missing assignment in science"
  - "What's Jake's GPA?"
  - "Help me draft an email to Emma's teacher about the late homework"
  - "Mark the reading log as done for Jake"
  - "When is the science fair project due?"
  - "Set a reminder for Emma's spelling test on Friday"
  - "Jake's math grade dropped — what happened?"
  - "How much homework does Sarah have tonight?"
  - "What assignments are overdue?"
- **Context Signals**: Time of day (after school 3-6 PM → homework focus), specific child mentioned, school schedule, upcoming test dates in education data files, grade trends
- **Proactive Triggers**: Daily homework check at 4:00 PM, grade drop alerts when any subject falls below 80% or drops 5+ points, assignment due date reminders (1 day and morning-of)
- **Handoff Sources**: `school` (when school skill needs individual assignment details for one child), `note-to-actions` (when content relates to study techniques)
- **Handoff Targets**: `school` (when user asks about ALL kids or weekly overview), `psy-rich` (when child is stressed/burned out from studying), `habits` (when building a study habit)
- **Priority**: Wins over `school` when ONE specific child + specific assignment/grade is mentioned. Loses to `school` when multiple children or overview is requested.
- **NOT This Skill**: "How's school going for everyone?" → `school` (multi-child). "I need help with my own homework" → depends on context, may stay in `chat-turn`. "Find a tutor" → `hire-helper`. "I want to learn Spanish" → `chat-turn` or `psy-rich` (adult self-improvement, not child's schoolwork).

---

### Elder Care

- **ID**: `elder-care`
- **Triggers**: check on mom, check on dad, elderly parent, senior care, aging parent, medication reminder, how is mom, how is dad, grandparent, call mom, call dad, parent wellness, elder check-in, play music for mom, play music for dad, parent report, grandma, grandpa, nursing home, assisted living, caregiver, aging, dementia, Alzheimer's, fall risk, pills, parent medication, mom's health, dad's health, senior, elder, old parent, parent alone, check in on, weekly report for mom, mom fell, dad confused
- **Sample Utterances**:
  - "How's mom doing today?"
  - "Has dad taken his medication?"
  - "Set up daily check-ins for my mother"
  - "Play some music for mom"
  - "Show me the weekly report on dad"
  - "Mom hasn't checked in today"
  - "Dad says he's having chest pain"
  - "Set up medication tracking for my father"
  - "What's mom's mood been like this week?"
  - "Can you call my mom and check on her?"
  - "Dad missed his evening pills again"
  - "Tell me a story my mom shared"
  - "Schedule an extra check-in with dad today"
  - "Mom fell — what do I do?"
- **Context Signals**: Time of day (morning/evening check-in windows), elder profile data (health conditions, medication schedule), check-in history (missed check-ins trigger concern), family member role ("mom", "dad", "grandma")
- **Proactive Triggers**: Scheduled check-in times (default 9 AM and 7 PM), missed check-in alerts after 24+ hours, medication adherence drops below 80%, low mood for 3+ consecutive check-ins, missed medications 2+ times in a row
- **Handoff Sources**: `family-comms` (when elderly parent check-in requested), `family-bonding` (when grandparent joining an activity), `mental-load` (when elder care tasks are part of overwhelm triage)
- **Handoff Targets**: `family-comms` (schedule coordination for grandparent visits), `family-bonding` (intergenerational activities), `mental-load` (when caregiving overwhelm detected), `telephony` (when call needs to be placed to elder), `healthcare` (when health emergency detected)
- **Priority**: Wins over `healthcare` when the subject is specifically an aging parent AND the context is check-in/monitoring (not acute symptoms). Wins over `family-comms` when subject is elderly parent wellness. EMERGENCY alerts (fall, chest pain, confusion, unresponsive) override all other skills.
- **NOT This Skill**: "My kid is sick" → `healthcare`. "Book a doctor appointment for me" → `healthcare`. "I need a caregiver" → `hire-helper`. "Mom wants to come visit" → `family-comms` or `family-bonding`. General medication tracking for non-elder family → `healthcare`.

---

### Family Bonding

- **ID**: `family-bonding`
- **Triggers**: what should we do, family activity, weekend plans, things to do, family outing, day trip, date night, kids activities, rainy day ideas, bored, fun ideas, local events, game night, movie night, adventure, family fun, something to do, stuck inside, park, hike, outdoor, indoor activity, quality time, family time, bonding, what to do this weekend, we're bored, fun with kids, activity ideas, couple time, parents night out, entertain the kids
- **Sample Utterances**:
  - "What should we do this weekend?"
  - "It's raining — any ideas for the kids?"
  - "Plan a date night for us"
  - "We need something fun for the whole family"
  - "What can we do with a toddler today?"
  - "Suggest an outdoor activity for Saturday"
  - "We're so bored — help!"
  - "Need ideas that work for ages 3 and 13"
  - "What's happening locally this weekend?"
  - "Plan a game night"
  - "Free family activities nearby"
  - "I want to do something fun with the kids after school"
  - "We need a cheap weekend activity"
  - "Can you plan a movie night?"
- **Context Signals**: Weather (rainy → indoor, sunny → outdoor), day of week (weekend → more time available), family ages (determines age-appropriate activities), budget from family profile, season, energy level, recent activity history (avoid repeats)
- **Proactive Triggers**: Weekend approaching (Friday afternoon) with no plans on calendar, consecutive weekends with no logged activities, rainy day detected with no indoor plans
- **Handoff Sources**: `mental-load` (when user needs activity ideas), `psy-rich` (experiential activities that become bonding activities), `school` (when suggesting weekend balance after heavy school week)
- **Handoff Targets**: `family-comms` (schedule coordination for activity), `elder-care` (grandparent joining activity — accessibility needs), `mental-load` (if planning overwhelm detected), `hire-helper` (if childcare needed for date night), `tools` (calendar event for planned activity)
- **Priority**: Wins over `psy-rich` when the focus is on family/group activities rather than enrichment-for-its-own-sake. Wins over `mental-load` when user explicitly asks "what to do" vs. "I'm overwhelmed." Loses to `restaurant-reservation` when user specifically wants to dine out.
- **NOT This Skill**: "Book a restaurant" → `restaurant-reservation`. "I need to eat healthier" → `wellness` or `habits`. "Plan my week" → `mental-load`. "Find a babysitter for date night" → `hire-helper`. "What should we have for dinner?" → `meal-planning`. "I need something meaningful to do" → `psy-rich`.

---

### Family Communications

- **ID**: `family-comms`
- **Triggers**: family message, tell everyone, announce, family calendar, schedule, chore, chores, check-in, where is, emergency contact, family update, dinner time, school pickup, carpool, permission slip, who is picking up, family announcement, tell the kids, notify family, assign chores, chore chart, who's doing what, coordinate, family schedule, where is everyone, send a message, let everyone know, family meeting, clean up, dishes, trash, take out the garbage
- **Sample Utterances**:
  - "Tell everyone dinner is at 6"
  - "What does the family schedule look like this week?"
  - "Assign Emma dishes tonight"
  - "Has Jake checked in?"
  - "Show me the emergency contacts"
  - "Send an urgent message to the whole family"
  - "Who's picking up Emma from soccer?"
  - "What chores are due today?"
  - "Let the kids know we're leaving in 30 minutes"
  - "Add a family event to the calendar"
  - "Mark Jake's chores as done"
  - "Who has the most chores this week?"
  - "Emma hasn't responded in 30 minutes"
  - "Set up a chore rotation"
- **Context Signals**: Time of day (morning = school logistics, evening = dinner/chore coordination), family member locations (check-ins), quiet hours configuration, message priority level, number of family members, chore balance across members
- **Proactive Triggers**: Chore due date reminders, check-in overdue alerts (15 min → reminder, 30 min → escalation options), unbalanced chore distribution detected, upcoming carpool coordination needed
- **Handoff Sources**: `family-bonding` (schedule coordination for activities), `elder-care` (grandparent visit coordination), `school` (school-related schedule items), `mental-load` (communication tasks from overwhelm triage)
- **Handoff Targets**: `family-bonding` (when schedule view reveals free time → "what should we do?"), `mental-load` (when schedule overwhelm detected), `elder-care` (when elderly parent check-in requested)
- **Priority**: Wins over `tools` calendar when the context is explicitly family coordination (not personal scheduling). Wins over `mental-load` when the request is to send/manage a specific family message. Loses to `elder-care` when the check-in is about an aging parent.
- **NOT This Skill**: "Check on mom" (aging parent) → `elder-care`. "What should we do this weekend?" → `family-bonding`. "Plan the week" → `mental-load`. "Set a personal reminder" → `tools`. "I need a babysitter" → `hire-helper`.

---

### Habits

- **ID**: `habits`
- **Triggers**: habit, routine, streak, consistency, motivation, struggling, accountability, behavior change, start doing, stop doing, build habit, track habit, I want to start, I've been trying to, how do I stick to, daily routine, morning routine, evening routine, commitment, discipline, willpower, 21 days, 66 days, habit tracker, never miss twice, atomic habit, tiny habit, cue, reward, temptation, relapse, fell off, gave up, keep going, how to be consistent
- **Sample Utterances**:
  - "I want to start meditating every day"
  - "Help me build a reading habit"
  - "I broke my streak — I feel terrible"
  - "How do I stick to my workout routine?"
  - "Track my morning routine"
  - "I keep forgetting to take my vitamins"
  - "I've been trying to drink more water but I can't stick with it"
  - "Set up a habit for journaling"
  - "How are my habits going?"
  - "I'm struggling with my exercise habit"
  - "I haven't been consistent with anything"
  - "I want to stop scrolling before bed"
  - "Show me my habit streaks"
  - "I missed two days — should I start over?"
- **Context Signals**: Stress level detected from language (affects nudging intensity), time of day (morning check-in vs evening reflection), current streak data, stage of change (pre-contemplation through maintenance), barrier history, number of active habits (cap at 3)
- **Proactive Triggers**: Morning habit check-in, evening habit completion check, streak milestone celebrations (7, 21, 30, 66, 100 days), Sunday weekly reflection, stress-aware nudge adjustment
- **Handoff Sources**: `healthcare` (medication adherence → habit formation), `wellness` (when user wants wellness tracking as a habit), `note-to-actions` (when content is turned into a habit), `education` (study habits)
- **Handoff Targets**: `healthcare` (when habit is health-related like medication), `wellness` (when habit is wellness-related like hydration/sleep/steps), `mental-load` (when too many habits cause overwhelm)
- **Priority**: Wins over `wellness` when user explicitly uses habit/streak/consistency language. Loses to `wellness` when user asks about specific metrics (steps, water oz, sleep hours). Loses to `healthcare` when the topic is medication compliance specifically.
- **NOT This Skill**: "How many steps did I take?" → `wellness`. "Track my calories" → `wellness`. "I need to take my medication" → `healthcare`. "Remind me to do X at 3pm" → `tools` (one-time reminder ≠ habit). "I want to eat healthier" → could be `meal-planning` or `wellness`, not habits unless they say "build a habit."

---

### Healthcare

- **ID**: `healthcare`
- **Triggers**: doctor, appointment, medication, prescription, symptom, sick, fever, refill, pharmacy, checkup, insurance, telemedicine, health, pain, hurt, ache, allergy, allergic reaction, rash, cough, cold, flu, nausea, vomiting, headache, sore throat, earache, infection, antibiotic, specialist, urgent care, ER, emergency room, copay, deductible, medical, clinic, nurse, pediatrician, dentist, vision, blood pressure, diabetes, asthma, inhaler
- **Sample Utterances**:
  - "I think Jake has a fever"
  - "Schedule a doctor appointment for Emma"
  - "I need to refill my blood pressure medication"
  - "What's my insurance copay for a specialist?"
  - "Emma has a sore throat and cough"
  - "When is Jake's next checkup?"
  - "I'm having chest pains" ← EMERGENCY
  - "Show me everyone's medication schedule"
  - "The doctor said I should exercise more"
  - "I need to find a new pediatrician"
  - "What should I do about this rash?"
  - "Emma threw up at school"
  - "How do I stop taking this medication safely?"
  - "My kid can't breathe" ← EMERGENCY
- **Context Signals**: Family health profiles (allergies, conditions, doctors), medication schedules, symptom severity (mild/moderate/severe/emergency), time since symptom onset, age of patient (children have different thresholds), insurance information
- **Proactive Triggers**: Medication reminders (daily at configured times), refill reminders (7 days before run-out), appointment reminders (1 day + 2 hours before), preventive checkup scheduling (annual well visits)
- **Handoff Sources**: `elder-care` (when elder has health concern), `habits` (medication adherence habit), `wellness` (when symptom detected during wellness tracking), `chat-turn` (emergency keyword detection)
- **Handoff Targets**: `wellness` (recovery tracking — hydration, rest monitoring), `habits` (building medication adherence habit), `telephony` (calling doctor's office), `tools` (appointment on calendar), `elder-care` (when health concern is about aging parent)
- **Priority**: Wins over ALL skills for medical emergencies (chest pain, breathing difficulty, severe allergic reaction, high fever in young children, seizure, loss of consciousness). Wins over `wellness` for symptoms, medication, and appointments. Wins over `elder-care` for acute health issues even in elderly. Loses to `elder-care` for routine check-ins and monitoring.
- **NOT This Skill**: "I want to eat healthier" → `meal-planning` or `wellness`. "I need to build an exercise habit" → `habits`. "How many steps did I walk?" → `wellness`. "Check on mom's mood" → `elder-care`. "Find a caregiver for dad" → `hire-helper`. "I feel overwhelmed" → `mental-load`.

---

### Hire Helper

- **ID**: `hire-helper`
- **Triggers**: babysitter, nanny, housekeeper, cleaner, tutor, dog walker, pet sitter, caregiver, hire, find someone to, need help with, au pair, cleaning lady, cleaning service, house cleaner, maid, childcare, daycare, after-school care, lawn service, handyman, personal assistant, errand runner, elderly caregiver, home aide, sitter, someone to watch the kids, need a hand, find a tutor, music teacher, private lessons
- **Sample Utterances**:
  - "I need a babysitter for Saturday night"
  - "Find me a housekeeper"
  - "We need a tutor for Jake's math"
  - "Looking for a dog walker"
  - "How do I find a good nanny?"
  - "I need someone to clean the house weekly"
  - "Can you help me post a babysitter job?"
  - "What should I pay a tutor?"
  - "I need a caregiver for my dad"
  - "Screen this babysitter candidate for me"
  - "What questions should I ask a nanny?"
  - "Help me write a job posting for a cleaner"
  - "Is this person a scam? They want to text off the app"
  - "Set up a trial session with the new sitter"
- **Context Signals**: Type of help needed (childcare vs household vs pet vs elder), urgency (tonight vs ongoing), family member ages (childcare complexity), budget preferences, location, whether background check is needed
- **Proactive Triggers**: Date night planned but no sitter arranged (48 hours before), regular helper's scheduled absence, new school year approaching (tutor needs)
- **Handoff Sources**: `family-bonding` (date night needs sitter), `elder-care` (need professional caregiver), `education` (need a tutor — but education handles study plans, hire-helper handles finding the person), `chat-turn` (keyword routing)
- **Handoff Targets**: `telephony` (when calling a candidate or agency), `tools` (calendar for trial sessions), `family-comms` (sharing sitter details with family)
- **Priority**: Wins over `education` when user wants to FIND/HIRE a tutor (not manage study plans). Wins over `elder-care` when user is looking for professional caregiving services (not doing personal check-ins). Loses to `education` for "help with homework" (education manages the learning, not hiring someone).
- **NOT This Skill**: "Help me with homework" → `education`. "I need help planning the week" → `mental-load`. "Fix my sink" → `home-maintenance`. "I need a plumber" → `home-maintenance`. "Help me sell my couch" → `marketplace-sell`. "Check on my mom" → `elder-care`.

---

### Home Maintenance

- **ID**: `home-maintenance`
- **Triggers**: repair, fix, broken, plumber, electrician, hvac, maintenance, leak, gas smell, fire, smoke, flood, burst pipe, no heat, no AC, air conditioning, furnace, water heater, toilet, clogged, drain, roof, gutter, appliance, dishwasher, washer, dryer, refrigerator, oven, stove, filter, air filter, squeaky, door, window, mold, pest, exterminator, power outage, breaker, circuit, fuse, thermostat, insulation, foundation, basement, attic, garage door, sprinkler, irrigation, sump pump
- **Sample Utterances**:
  - "I smell gas in the kitchen" ← EMERGENCY
  - "The toilet won't stop running"
  - "We have no heat and it's freezing"
  - "There's water coming through the ceiling"
  - "The AC isn't working"
  - "How often should I change the air filter?"
  - "The garbage disposal is jammed"
  - "Find me a good plumber"
  - "Set up a home maintenance schedule"
  - "The dryer isn't drying"
  - "There's a spark coming from the outlet" ← EMERGENCY
  - "I need the gutters cleaned"
  - "My garage door won't open"
  - "What maintenance should I do this spring?"
- **Context Signals**: Urgency level (emergency > urgent > routine), home type (rent vs own — affects who to call), weather conditions (extreme cold → pipe freeze risk, heat → AC urgency), saved provider list, home setup data (shutoff locations), season (spring/fall maintenance cycles)
- **Proactive Triggers**: Monthly air filter reminder, seasonal maintenance checklists (spring AC, fall furnace), smoke detector test reminders, weather alerts triggering home protection advice
- **Handoff Sources**: `tools` (extreme weather alert triggers home check), `chat-turn` (emergency keyword detection — highest priority), `meal-planning` (broken kitchen appliance affects cooking)
- **Handoff Targets**: `tools` (schedule maintenance appointments on calendar), `meal-planning` (broken stove/oven affects meal plans), `transportation` (need ride to hardware store), `hire-helper` (when professional needed — overlaps with finding contractors), `telephony` (calling contractors)
- **Priority**: HIGHEST priority for emergencies (gas leak, fire, electrical sparks, flooding, burst pipe). These override ALL other skills. For routine maintenance, wins over `hire-helper` when the request is about the repair itself (not finding a person). Loses to `hire-helper` for general "find a handyman" without specific repair context.
- **NOT This Skill**: "Find a cleaner" → `hire-helper`. "I need a handyman to come regularly" → `hire-helper`. "My car broke down" → `transportation`. "Book a repairman" without specifying what's broken → clarify, might be `hire-helper`.

---

### Infrastructure

- **ID**: `infrastructure`
- **Triggers**: (NOT user-facing — this is an internal skill that defines conventions for all other skills)
- **Sample Utterances**: None — users never directly invoke this skill.
- **Context Signals**: N/A
- **Proactive Triggers**: N/A
- **Handoff Sources**: All skills reference infrastructure for storage conventions, risk levels, and error handling.
- **Handoff Targets**: N/A
- **Priority**: N/A — internal system skill, not routable.
- **NOT This Skill**: Everything. Users never interact with this directly. If a user says "storage" or "logging" or "system settings," handle in `chat-turn` or `tools`.

---

### Marketplace Sell

- **ID**: `marketplace-sell`
- **Triggers**: sell, list for sale, post on marketplace, sell on facebook, sell on ebay, sell on craigslist, how much is my, what's my X worth, get rid of, declutter, garage sale, yard sale, secondhand, used, resell, flip, list it, post it, marketplace, facebook marketplace, ebay, craigslist, offerup, poshmark, sell my, price check, worth anything, is this valuable, sell this, how to sell, cash for, make money selling, downsizing
- **Sample Utterances**:
  - "I want to sell my old couch"
  - "How much is this bike worth?"
  - "Help me list my kids' old toys"
  - "Post this on Facebook Marketplace"
  - "What's the best way to sell a TV?"
  - "Write a listing for my dining table"
  - "Someone offered $50 — should I take it?"
  - "Is this buyer a scam?"
  - "My listing hasn't sold in a week — what should I do?"
  - "I want to declutter and sell some stuff"
  - "Help me price this stroller"
  - "Where should I sell designer clothes?"
  - "Someone wants to pay by check — is that safe?"
  - "Where should I meet the buyer?"
- **Context Signals**: Item type (determines platform and pricing strategy), item condition (affects price), how long listed (determines strategy adjustment), buyer communication patterns (scam detection), local market conditions
- **Proactive Triggers**: Listing over 7 days old with low interest → suggest price reduction or repost, buyer scam patterns detected → immediate warning
- **Handoff Sources**: `chat-turn` (keyword routing when user mentions selling a physical item)
- **Handoff Targets**: `telephony` (if calling a buyer or service is needed), `transportation` (getting item to meetup location), `tools` (reminder for meetup)
- **Priority**: Wins when user mentions selling/listing a specific physical item. Loses to `hire-helper` if user says "sell my services" (that's hiring context). Loses to `restaurant-reservation` for anything dining-related.
- **NOT This Skill**: "Sell my car" → might be `marketplace-sell` for listing, but could need `transportation` context. "I need to make money" → too vague, stays in `chat-turn`. "Buy something" → not this skill (this is sell only). "Return an item to a store" → `chat-turn`.

---

### Meal Planning

- **ID**: `meal-planning`
- **Triggers**: dinner, meal plan, grocery, recipe, cook, eat, lunch, what to eat, meal prep, shopping list, pantry, ingredients, what should I make, hungry, food, breakfast, snack, weekly menu, what to cook, supper, feeding the family, what's for dinner, grocery store, cooking, baking, kitchen, freezer meal, slow cooker, instant pot, crockpot, leftovers, what can I make with, budget meals, cheap dinner, quick dinner, easy recipe, weeknight meal, healthy meal, vegetarian meal, picky eater
- **Sample Utterances**:
  - "What should we have for dinner?"
  - "Make me a meal plan for the week"
  - "I need a grocery list"
  - "What can I make with chicken and rice?"
  - "Plan meals around Sarah's nut allergy"
  - "We're out of ideas for lunch"
  - "Quick weeknight recipe"
  - "I have leftover pasta — what can I do?"
  - "Plan Thanksgiving dinner"
  - "Budget meals for the week under $100"
  - "What's in the pantry that's about to expire?"
  - "Give me a recipe for tacos"
  - "I need easy meals — it's a crazy week"
  - "The kids are picky — what will they actually eat?"
  - "Sunday meal prep plan"
- **Context Signals**: Time of day (4-6 PM → dinner focus, morning → breakfast), dietary restrictions and allergies from family.json (CRITICAL — never violate), pantry inventory if available, meal history (avoid repeats), number of family members, budget level, cooking skill/time available, kids' ages (picky eater awareness), season (comfort food in winter, fresh in summer)
- **Proactive Triggers**: 4:30 PM daily if no dinner plan exists, grocery day reminder (configurable), pantry items expiring soon, weekly meal plan generation reminder (Sunday)
- **Handoff Sources**: `mental-load` (dinner decision help), `tools` (calendar shows dinner party), `home-maintenance` (broken kitchen appliance adjusts meal options)
- **Handoff Targets**: `tools` (schedule meal prep session on calendar, grocery ordering), `home-maintenance` (broken appliance needs repair), `transportation` (ride to grocery store), `healthcare` (allergy information cross-reference)
- **Priority**: Wins over `mental-load` when user specifically asks about meals/food/dinner. Wins over `restaurant-reservation` when user wants to cook at home (not eat out). Loses to `restaurant-reservation` when user wants to dine out.
- **NOT This Skill**: "I need to eat healthier" → `wellness` or `habits`. "Book a restaurant" → `restaurant-reservation`. "I want to lose weight" → `wellness`. "Find a cooking class" → `psy-rich` or `family-bonding`. "Order takeout" → `chat-turn` or `tools`.

---

### Mental Load

- **ID**: `mental-load`
- **Triggers**: overwhelmed, too much, stressed, morning briefing, evening summary, what's today, weekly plan, remind me, don't forget, organize, help me plan, prioritize, busy week, schedule help, decision help, what should I do first, can't keep track, drowning, so much to do, falling behind, behind on everything, need to get organized, I forgot, too many things, brain dump, cognitive overload, juggling, spinning plates, dropping balls, burning out, exhausted from planning, invisible labor, mental load, emotional labor, who does what, unfair split
- **Sample Utterances**:
  - "I'm so overwhelmed this week"
  - "What's on the agenda today?"
  - "Help me plan this week"
  - "I can't keep track of everything"
  - "Give me a morning briefing"
  - "What should I do first?"
  - "I have too much on my plate"
  - "Evening wind-down summary"
  - "Help me prioritize today"
  - "Brain dump — here's everything I need to do"
  - "Who should do what this week?"
  - "I feel like I'm dropping balls"
  - "How do I split the household work more fairly?"
  - "Can you help me decide what to do tonight?"
  - "What's the most important thing right now?"
- **Context Signals**: Calendar load (number of events), time of day (morning → briefing, evening → wind-down), stress language intensity, family structure (single parent → consolidated view), day of week (Sunday → weekly planning), current overwhelm level, chore distribution data
- **Proactive Triggers**: Morning briefing (configurable time, default 7 AM), evening wind-down (configurable, default 9 PM), Sunday weekly planning prompt, high-event-density day detected, multiple deadlines clustering
- **Handoff Sources**: `family-bonding` (when planning overwhelm detected), `family-comms` (when schedule overwhelm detected), `elder-care` (caregiver overwhelm), `school` (school logistics overwhelm)
- **Handoff Targets**: `family-comms` (when communication task identified), `family-bonding` (when activity ideas needed), `elder-care` (when elder care tasks identified), `meal-planning` (dinner decision delegation), `tools` (reminders and calendar events)
- **Priority**: Wins over `tools` when user expresses overwhelm/stress (not just "set a reminder"). Wins over `family-comms` when user is asking for help managing everything (not sending a specific message). Loses to specific skills when user has a concrete request ("What's for dinner?" → `meal-planning`).
- **NOT This Skill**: "Remind me to buy milk" → `tools` (simple reminder). "What should we have for dinner?" → `meal-planning`. "Tell the kids dinner is ready" → `family-comms`. "I'm stressed about my health" → `healthcare` or `wellness`. "I feel anxious" → `chat-turn` (emotional support, not task management).

---

### Note to Actions

- **ID**: `note-to-actions`
- **Triggers**: article, video, podcast, how do I apply, how do I start, turn this into action, I want to start, I read, I watched, I heard, book summary, implementation, actionable, atomic habit, 4 laws, behavior change, make it obvious, make it easy, habit stacking, cue, reward, temptation bundling, 2-minute rule, how do I actually do this, apply this, put into practice, turn into habit, I learned, takeaway, key insights, book notes
- **Sample Utterances**:
  - "I just read this article — how do I apply it?" (+ URL)
  - "Turn this into actionable habits"
  - "I watched a video about morning routines — help me start one"
  - "How do I actually do this thing I read about?"
  - "I heard a podcast about deep work — how do I implement it?"
  - "Give me the key takeaways from this article"
  - "I want to start doing what this book says"
  - "Make this into a 2-minute habit"
  - "Help me habit-stack this into my morning"
  - "I read about the 4 Laws of Behavior Change — apply it to exercise"
  - "Here's an article — what should I actually do?"
  - "Turn this book's advice into daily actions"
- **Context Signals**: Source type (URL, text, idea), current active habits (cap at 3), existing habit cues and routines, family context (adapting habits to family schedule), content topic
- **Proactive Triggers**: Daily habit check-in for active habits created through this skill, weekly habit report (Sunday), streak milestone celebrations
- **Handoff Sources**: Any skill can send content/ideas here for habit creation. `psy-rich` (when experiential habit wanted), `education` (study technique content), `wellness` (when wellness tracking becomes a habit), `healthcare` (lifestyle change from doctor)
- **Handoff Targets**: `education` (when content is about study techniques for a child), `psy-rich` (when habit is experiential), `habits` (overlaps heavily — note-to-actions focuses on content→habit extraction, habits focuses on tracking/maintenance)
- **Priority**: Wins over `habits` when user provides content (URL, article, book) to convert into actions. Loses to `habits` when user is tracking/managing existing habits. Loses to `education` when content is specifically about a child's study methods.
- **NOT This Skill**: "Track my meditation habit" → `habits`. "Show my streaks" → `habits`. "Remind me to read" → `tools`. "What book should I read?" → `chat-turn` or `psy-rich`. "Save this note" → `tools`.

---

### Psychologically Rich Experiences (Psy-Rich)

- **ID**: `psy-rich`
- **Triggers**: what should we do, bored, activity ideas, weekend plans, something fun, family activity, date night, something different, in a rut, meaningful, enriching, experience, novel, new experience, try something new, step out of comfort zone, bucket list, adventure, explore, unique, unusual, creative, interesting, stimulating, perspective, wonder, awe, cultural, arts, museum, gallery, nature, mindful, intentional living
- **Sample Utterances**:
  - "We're in a rut — suggest something we've never done"
  - "I want to try something completely new this weekend"
  - "Suggest a meaningful family experience"
  - "What's something unique to do in our area?"
  - "I want to do something that changes my perspective"
  - "Plan something enriching for the kids"
  - "Give me an experience that's not just entertainment"
  - "We need more variety in our lives"
  - "Something creative to do as a family"
  - "I feel stuck — help me break the routine"
  - "What's an affordable adventure nearby?"
  - "Suggest something culturally interesting"
  - "I want to do something meaningful, not just fun"
- **Context Signals**: Family energy level (high/low), ages of participants, budget, location, time of day (evening → aesthetic/calm, weekend → novel/active), mood (stressed → aesthetic, bored → novel, lonely → social, curious → complex, stuck → perspective), recent activity history
- **Proactive Triggers**: Consecutive weekends with no logged enrichment activities, family mood data showing stagnation, seasonal experience opportunities (festivals, outdoor events)
- **Handoff Sources**: `education` (child burned out from studying), `school` (suggesting balance after heavy school week), `habits` (when building an enrichment habit)
- **Handoff Targets**: `note-to-actions` (when user wants to make enrichment a regular habit), `education` (when activity has educational value for children), `school` (schedule check for free time windows), `tools` (calendar event for planned experience), `family-bonding` (overlaps — psy-rich provides the "what," bonding may help plan the "how")
- **Priority**: Wins over `family-bonding` when user emphasizes novelty, meaning, enrichment, or perspective-change. Loses to `family-bonding` for straightforward "what should we do" without enrichment emphasis. Loses to `restaurant-reservation` for dining-specific requests.
- **NOT This Skill**: "What should we have for dinner?" → `meal-planning`. "Plan a game night" → `family-bonding`. "Book a restaurant" → `restaurant-reservation`. "I'm overwhelmed" → `mental-load`. "I want to build a habit" → `habits` or `note-to-actions`.

---

### Restaurant Reservation

- **ID**: `restaurant-reservation`
- **Triggers**: reservation, book a table, book a restaurant, dinner reservation, lunch reservation, table for, reserve a table, book dinner, book lunch, restaurant, dine out, eat out, dinner out, nice restaurant, good restaurant, where to eat, restaurant recommendation, celebrate dinner, anniversary dinner, birthday dinner, brunch, fine dining, casual dining, sushi place, Italian restaurant, Thai food, steakhouse, book OpenTable, Resy
- **Sample Utterances**:
  - "Book a table for 4 on Saturday at 7pm"
  - "Find a good Italian restaurant nearby"
  - "Make a dinner reservation for our anniversary"
  - "Where should we go for date night dinner?"
  - "I need a restaurant that's good for kids"
  - "Book dinner somewhere nice for 6 people"
  - "Find a restaurant with good vegetarian options"
  - "We want to try Thai food — any recommendations?"
  - "Cancel our reservation at Luigi's"
  - "What's a good steakhouse within 20 minutes?"
  - "I need a restaurant for a birthday dinner — party of 10"
  - "Book brunch for Sunday"
  - "Find somewhere quiet for a business dinner"
- **Context Signals**: Date/time requested, party size, occasion (anniversary, birthday — affects formality), dietary restrictions from family.json, cuisine preference, budget level ($-$$$$), location/distance preference, previous restaurant history and ratings, time flexibility
- **Proactive Triggers**: Day-before reservation reminder with address + directions, day-after "how was it?" follow-up for feedback, anniversary/birthday approaching with no dinner planned
- **Handoff Sources**: `chat-turn` (Priority 2 routing for reservation keywords), `family-bonding` (date night dining component), `mental-load` (dinner decision → eating out)
- **Handoff Targets**: `telephony` (phone booking when online not available), `tools` (calendar event for confirmed reservation), `transportation` (getting to the restaurant)
- **Priority**: Wins over `meal-planning` when user wants to eat OUT (not cook). Wins over `family-bonding` for dining-specific requests. Wins over `tools` calendar — the reservation IS the event. Loses to `telephony` only for the call execution portion.
- **NOT This Skill**: "What should I cook for dinner?" → `meal-planning`. "I need a grocery list" → `meal-planning`. "Find a cooking class" → `psy-rich` or `family-bonding`. "Call the restaurant" → starts here, then handoff to `telephony` for the actual call. "Order delivery" → `chat-turn` or `tools`.

---

### School

- **ID**: `school`
- **Triggers**: both kids, all kids, school overview, weekly summary, set up monitoring, school week, parent-teacher, coordination, school schedule, all children, how are the kids doing in school, school monitoring, school setup, weekly school report, school coordination, school events, school calendar, back to school, school year, PTA, field trip, school supplies, report cards, progress reports, school conference, school overview, multi-child, absence notification
- **Sample Utterances**:
  - "How are all the kids doing in school?"
  - "Give me the weekly school report"
  - "Set up automated school monitoring"
  - "What's the school week look like?"
  - "Any conflicts in the kids' schedules?"
  - "Draft an email to Emma's teacher"
  - "Both kids have tests this week — help me plan"
  - "What school events are coming up?"
  - "Jake is absent today — notify the school"
  - "Show me the week ahead for all students"
  - "Set up daily homework check notifications"
  - "Which kid needs the most attention this week?"
  - "Coordinate pickup for both kids on Tuesday"
- **Context Signals**: Number of children in family, each child's grade level and school, monitoring configuration (daily check time, weekly report day), grade alert thresholds, upcoming school events and tests across all children, schedule conflicts
- **Proactive Triggers**: Daily school check at 4:00 PM (configurable), weekly school report Sunday at 6:00 PM, school event sync daily at 7:00 AM, test prep reminders 2 days before, project deadline reminders 3 days before
- **Handoff Sources**: `education` (when education skill detects multi-child need), `family-comms` (school-related schedule coordination)
- **Handoff Targets**: `education` (when drilled into one child's specific homework/grades), `psy-rich` (weekend family activities to balance school stress), `family-comms` (absence notifications, schedule coordination), `tools` (calendar events for school activities)
- **Priority**: Wins over `education` when request involves MULTIPLE children or school-wide overview. Wins over `family-comms` for school-specific scheduling. Loses to `education` for single-child specific homework or grade requests.
- **NOT This Skill**: "Help Emma with her math homework" → `education`. "Find a tutor" → `hire-helper`. "What activity should we do this weekend?" → `family-bonding`. "I'm overwhelmed with school logistics" → `mental-load` (then may hand off here).

---

### Telephony

- **ID**: `telephony`
- **Triggers**: call, phone, dial, ring, phone call, call the, make a call, place a call, call them, give them a call, phone number, call this number, voice call, AI call, call on my behalf, call the restaurant, call the doctor, call the school, call the plumber
- **Sample Utterances**:
  - "Call the restaurant to book a table"
  - "Phone the doctor's office for an appointment"
  - "Call this number: 555-0123"
  - "Make a call to the dentist"
  - "Call the plumber about the leak"
  - "Can you phone the school about Jake's absence?"
  - "Call the pharmacy to check on my refill"
  - "Dial the insurance company"
  - "Call them back"
  - "I need you to make a phone call for me"
  - "Place a call to that restaurant we found"
  - "Ring the babysitter and confirm Saturday"
- **Context Signals**: Business type (determines script), handoff origin (restaurant-reservation, healthcare, etc. provide details), phone number (required — look up if not provided), purpose of call, user's name for booking, time flexibility for appointments/reservations
- **Proactive Triggers**: None — telephony is always triggered by user request or handoff. ALL calls require explicit YES approval.
- **Handoff Sources**: `restaurant-reservation` (phone booking required), `healthcare` (calling doctor's office), `home-maintenance` (calling contractors), `hire-helper` (calling candidates/agencies), `elder-care` (calling to check on parent), any skill that needs a phone call
- **Handoff Targets**: Back to originating skill with call results (confirmation number, alternative times offered, failure reason)
- **Priority**: Wins when user explicitly says "call" + a business/person/number. Loses to the originating skill for the overall workflow (telephony handles just the call portion). Note: "call" is ambiguous — "call the doctor" = telephony, "call it a day" = chat-turn.
- **NOT This Skill**: "Text the babysitter" → `family-comms`. "Email the teacher" → `education` or `school`. "FaceTime mom" → `elder-care` or `family-comms`. "What's the phone number for..." → `chat-turn` (lookup, not calling). "Call 911" → `home-maintenance` (emergency) or `healthcare` (medical emergency), with telephony handoff for the actual call.

---

### Tools

- **ID**: `tools`
- **Triggers**: calendar, reminder, weather, note, search, timer, schedule, event, what's on, free time, plan, when am I free, add to calendar, delete event, set reminder, remind me, what's the weather, forecast, temperature, rain, umbrella, save this, note to self, find my note, to-do, task list, agenda, planner, what's happening today, when is, look up, countdown
- **Sample Utterances**:
  - "What's on my calendar today?"
  - "Add a dentist appointment to the calendar for Tuesday at 2pm"
  - "Remind me to call mom at 3pm"
  - "What's the weather tomorrow?"
  - "Do I need an umbrella today?"
  - "When am I free this week?"
  - "Delete the meeting on Thursday"
  - "Save a note: Jake's locker combo is 12-34-56"
  - "Find my note about the WiFi password"
  - "Set a reminder to pick up dry cleaning"
  - "What does this week look like?"
  - "How much free time do I have on Saturday?"
  - "Note to self: return the library books"
  - "What's the forecast for the weekend?"
- **Context Signals**: Date/time references in message, existing calendar events (for conflict detection), weather conditions (trigger cross-skill handoffs), location (for weather), reminder urgency
- **Proactive Triggers**: Weather alerts for extreme conditions (triggers home-maintenance handoff), upcoming calendar events within 2 hours (triggers transportation handoff), calendar dinner events (triggers meal-planning handoff)
- **Handoff Sources**: ALL skills hand off to tools for calendar events, reminders, and scheduling. `home-maintenance` (maintenance appointments), `meal-planning` (prep day scheduling, grocery ordering), `transportation` (departure reminders), `healthcare` (appointment on calendar), `restaurant-reservation` (reservation on calendar)
- **Handoff Targets**: `home-maintenance` (extreme weather → home check), `transportation` (upcoming event with location → commute check), `meal-planning` (dinner event on calendar → meal planning)
- **Priority**: Lowest priority among specific skills — tools is the utility layer. Loses to `family-comms` for family calendar coordination. Loses to `mental-load` for "plan my week" overwhelm. Loses to any skill with specific expertise. Wins only for pure calendar/reminder/weather/notes requests with no other skill context.
- **NOT This Skill**: "Plan my week" → `mental-load`. "What's the family schedule?" → `family-comms`. "Book a dinner reservation" → `restaurant-reservation`. "I'm overwhelmed" → `mental-load`. "Track my habits" → `habits`. Anything with emotional or domain-specific context goes to the specialized skill.

---

### Transportation

- **ID**: `transportation`
- **Triggers**: uber, lyft, ride, commute, traffic, carpool, parking, drive, driving, how long to get to, directions, route, GPS, map, pickup, drop off, airport, flight, car service, taxi, cab, bus, train, public transit, school bus, carpool lane, road trip, road conditions, gas station, EV charging, car trouble, flat tire, tow truck, rental car, how far is, distance to, leave by, departure time, when should I leave
- **Sample Utterances**:
  - "How long will it take to get to the airport?"
  - "Get me an Uber to downtown"
  - "Set up a carpool for soccer practice"
  - "What's traffic like right now?"
  - "Find parking near the concert venue"
  - "When should I leave for my 3pm meeting?"
  - "Book a Lyft for Saturday night"
  - "What's the best route to avoid traffic?"
  - "I need a ride to the grocery store"
  - "Set up a departure alert for tomorrow's appointment"
  - "How far is the museum from here?"
  - "Coordinate pickup for the kids"
  - "My car won't start — what do I do?"
  - "Find the cheapest parking at the airport"
- **Context Signals**: Calendar events with locations (auto-generate departure alerts), current traffic conditions, weather (affects driving time), number of passengers (affects ride type), destination type (airport → extra buffer), family member locations, carpool schedules
- **Proactive Triggers**: Departure alerts before calendar events with locations (event time minus drive time minus buffer), carpool day reminders, airport trip reminders (3 hours before flight for domestic), traffic surge warnings for commute routes
- **Handoff Sources**: `tools` (upcoming calendar event with location → commute check), `meal-planning` (ride to grocery store), `home-maintenance` (ride to hardware store), `restaurant-reservation` (getting to the restaurant)
- **Handoff Targets**: `tools` (departure reminders on calendar, carpool recurring events), `home-maintenance` (car trouble or vehicle maintenance), `meal-planning` (grocery trip planning)
- **Priority**: Wins for all ride-booking, commute, traffic, parking, and carpool requests. Loses to `home-maintenance` for car repairs (mechanical issues). Loses to specific activity skills for the activity itself (transportation handles getting there, not the activity).
- **NOT This Skill**: "Fix my car" → `home-maintenance`. "Book a rental car for vacation" → could be `chat-turn` or `tools`. "Find a mechanic" → `home-maintenance` or `hire-helper`. "Plan a road trip" → `family-bonding` (with transportation handoff for logistics).

---

### Wellness

- **ID**: `wellness`
- **Triggers**: water, hydration, steps, walk, movement, sleep, bedtime, screen time, energy, tired, posture, break, wellness, health tracking, drink water, how much water, step count, fitbit, apple watch, sleep quality, insomnia, rest, nap, eye strain, sitting too long, sedentary, stretch, yoga, meditation, mindfulness, self-care, wellbeing, vitals, blood pressure tracking, weight, BMI, calories, nutrition tracking, sunlight, vitamin D, fresh air, deep breathing, wind down, wake up
- **Sample Utterances**:
  - "How much water have I had today?"
  - "How many steps have I walked?"
  - "I slept terribly last night"
  - "How much screen time have the kids had?"
  - "I'm so tired this afternoon"
  - "Remind me to drink water"
  - "Time for a posture break"
  - "Show me the family wellness dashboard"
  - "Extend Jake's screen time by 30 minutes"
  - "Set up wellness tracking for the family"
  - "I've been sitting too long"
  - "What time should the kids go to bed?"
  - "How's everyone's sleep this week?"
  - "I need an energy boost"
  - "Log that I walked 3,000 steps"
- **Context Signals**: Time of day (morning → energy/hydration, afternoon → energy dip/posture, evening → wind-down/sleep), family member ages (different defaults for kids/teens/adults/seniors), current wellness data (streaks, goals, logs), weather (hot → extra hydration), work hours (posture breaks during desk time), stress level
- **Proactive Triggers**: Hydration reminders throughout the day, sedentary alerts every 60 minutes, posture breaks every 45 minutes (work hours), wind-down reminder 30 minutes before bedtime, morning wellness nudge, screen time limit warnings for children, eye break reminders every 20 minutes
- **Handoff Sources**: `healthcare` (recovery tracking after illness — hydration, rest), `habits` (when wellness tracking becomes a habit), `elder-care` (elder wellness monitoring overlaps)
- **Handoff Targets**: `healthcare` (when symptom detected during wellness tracking), `habits` (when user wants to make wellness into a habit, e.g., "make hydration a habit"), `family-comms` (screen time announcements to kids)
- **Priority**: Wins over `habits` for specific metric tracking (steps, water oz, sleep hours, screen time). Wins over `healthcare` for day-to-day wellness monitoring (not symptoms or appointments). Loses to `healthcare` for anything medical (symptoms, medication, appointments). Loses to `habits` when user uses habit/streak/consistency language.
- **NOT This Skill**: "I feel sick" → `healthcare`. "Book a doctor appointment" → `healthcare`. "I want to build an exercise habit" → `habits`. "Track my medication" → `healthcare`. "I want to eat healthier" → `meal-planning`. "I'm stressed and overwhelmed" → `mental-load`.

---

## Ambiguity Resolution Rules

When a user message could match multiple skills, use these explicit rules to resolve:

### Dining & Food
- **"book a table"** / **"make a reservation"** → `restaurant-reservation` (NOT `tools` calendar)
- **"what should we have for dinner?"** → `meal-planning` (NOT `mental-load`, NOT `restaurant-reservation`)
- **"where should we eat?"** → `restaurant-reservation` (implies dining out)
- **"I'm hungry"** → `meal-planning` (default to cooking, suggest restaurant if context supports it)
- **"plan dinner"** → `meal-planning` if cooking at home; `restaurant-reservation` if "dinner out" or "dinner reservation" follows
- **"order food"** / **"order delivery"** → `chat-turn` (not a dedicated skill)

### Calls & Communication
- **"call the doctor"** → `telephony` (with `healthcare` as handoff source providing context)
- **"call the restaurant"** → `telephony` (with `restaurant-reservation` as handoff source)
- **"call mom"** → `elder-care` if mom is an aging parent in the system; otherwise `telephony`
- **"text the kids"** → `family-comms` (NOT `telephony` — texting ≠ calling)
- **"email the teacher"** → `education` or `school` (NOT `telephony`)
- **"call it a day"** → `chat-turn` (idiomatic, not a phone call)
- **"call 911"** → `home-maintenance` (emergency) or `healthcare` (medical emergency) — NOT standalone telephony

### Help & Hiring
- **"I need help with homework"** → `education` (NOT `hire-helper`)
- **"find a tutor"** → `hire-helper` (finding the person, NOT managing study plans)
- **"help me plan"** → `mental-load` (NOT `hire-helper`)
- **"I need a plumber"** → `home-maintenance` (repair context, NOT just hiring)
- **"find a cleaner"** → `hire-helper` (finding the person)
- **"hire someone to fix the sink"** → `home-maintenance` (problem-first), with handoff to `hire-helper` if needed

### Health & Wellness
- **"I feel sick"** → `healthcare` (NOT `wellness`)
- **"I want to drink more water"** → `wellness` if tracking; `habits` if building a habit
- **"take my medication"** → `healthcare` (NOT `habits`, NOT `wellness`)
- **"I want to be healthier"** → `wellness` for tracking, `habits` if habit language used, `meal-planning` if food-specific
- **"check on mom's health"** → `elder-care` (NOT `healthcare` — elder is the subject)
- **"I'm tired"** → `wellness` (energy/sleep tracking) unless followed by overwhelm language → `mental-load`

### Planning & Organization
- **"plan the week"** → `mental-load` (NOT `tools` calendar)
- **"add to calendar"** → `tools` (simple calendar action)
- **"what's on today?"** → `mental-load` (briefing) if general; `tools` (calendar view) if asking specifically about events
- **"remind me to X"** → `tools` (one-time reminder, NOT `habits`)
- **"I want to start doing X every day"** → `habits` (recurring behavior, NOT `tools` reminder)
- **"what should we do?"** → `family-bonding` (activity ideas, NOT `mental-load`)
- **"set a reminder"** → `tools` (NOT `mental-load`)

### Activities & Experiences
- **"plan date night"** → `family-bonding` for ideas, `restaurant-reservation` if dining implied, could be multi-skill
- **"something meaningful to do"** → `psy-rich` (NOT `family-bonding`)
- **"we're bored"** → `family-bonding` (straightforward activities) or `psy-rich` (if "in a rut" / "something new")
- **"I want to try something new"** → `psy-rich` (novelty emphasis)
- **"plan a game night"** → `family-bonding` (NOT `psy-rich`)

### Selling & Shopping
- **"sell my couch"** → `marketplace-sell`
- **"buy a new couch"** → `chat-turn` (no dedicated buying skill)
- **"get rid of old stuff"** → `marketplace-sell`
- **"how much is this worth?"** → `marketplace-sell` (pricing an item to sell)

### School & Education
- **"how are the kids doing in school?"** → `school` (multi-child overview)
- **"how's Emma's math grade?"** → `education` (single child, specific subject)
- **"set up school monitoring"** → `school` (automated multi-child)
- **"help with Emma's homework"** → `education` (single child, specific task)

### Home
- **"I smell gas"** → `home-maintenance` EMERGENCY (override everything)
- **"the toilet is running"** → `home-maintenance` (routine repair)
- **"find a handyman"** → `hire-helper` (finding the person) or `home-maintenance` (if repair context exists)
- **"what maintenance should I do?"** → `home-maintenance` (preventive schedule)

---

## Multi-Skill Flows

These are common user scenarios that naturally involve multiple skills in sequence. When the first skill is activated, it should be aware of likely follow-on skills.

---

### "Plan date night"
1. **`family-bonding`** — Generate date night ideas (activity suggestions)
2. **`restaurant-reservation`** — Find and book a restaurant
3. **`hire-helper`** — Find a babysitter if kids need watching
4. **`tools`** — Add everything to the calendar
5. **`transportation`** — Plan how to get there

---

### "Kid is sick"
1. **`healthcare`** — Symptom triage, severity assessment, self-care or doctor recommendation
2. **`wellness`** — Recovery tracking (hydration, rest, sleep monitoring)
3. **`school`** — Absence notification to school
4. **`education`** — Track missed assignments during absence
5. **`meal-planning`** — Adjust meals for sick child (soup, bland foods, hydration)
6. **`family-comms`** — Notify family members

---

### "I'm overwhelmed"
1. **`mental-load`** — Triage everything, sort by urgency, identify delegatable tasks
2. **`family-comms`** — Delegate chores, coordinate family help
3. **`meal-planning`** — Quick dinner decision to remove one thing from the plate
4. **`tools`** — Set specific reminders for prioritized tasks
5. **`habits`** — If overwhelm is chronic, build organizational habits

---

### "Plan the week ahead"
1. **`mental-load`** — Weekly planning overview, identify busy days and conflicts
2. **`school`** — School events, tests, and deadlines for all kids
3. **`meal-planning`** — Weekly meal plan based on available cooking time
4. **`family-comms`** — Chore assignments, carpool coordination
5. **`tools`** — Calendar view and reminders
6. **`transportation`** — Carpool schedule setup

---

### "Set up for a new baby / new school year / new home"
1. **`family-comms`** — Update family profile with new member or school info
2. **`healthcare`** — Set up pediatrician, vaccines, medication tracking
3. **`education`** / **`school`** — Configure school monitoring
4. **`wellness`** — Set age-appropriate wellness defaults
5. **`meal-planning`** — Adjust meal plans for family size or dietary needs
6. **`hire-helper`** — Find childcare, tutor, or other help
7. **`home-maintenance`** — Childproofing or home setup tasks

---

### "Mom isn't doing well"
1. **`elder-care`** — Initiate check-in, assess wellness status
2. **`healthcare`** — If health symptoms reported, triage severity
3. **`telephony`** — Call mom or her doctor
4. **`family-comms`** — Notify family members of concerns
5. **`mental-load`** — Help manage caregiver burden
6. **`hire-helper`** — If professional caregiver needed

---

### "Selling and decluttering the house"
1. **`marketplace-sell`** — Price, photograph, and list items
2. **`hire-helper`** — Find a cleaning/organizing service if needed
3. **`tools`** — Schedule meetups on calendar, set reminders
4. **`telephony`** — Call buyers or donation centers
5. **`transportation`** — Logistics for item delivery or meetup

---

### "Back to school prep"
1. **`school`** — Set up monitoring for all students
2. **`education`** — Configure individual student profiles
3. **`family-comms`** — Set up carpool, chore rotation, school-day routines
4. **`meal-planning`** — Weeknight-friendly meal plans, lunch prep
5. **`transportation`** — School commute and carpool coordination
6. **`wellness`** — Set school-year bedtimes and screen time limits
7. **`hire-helper`** — Find after-school sitter or tutor if needed
8. **`tools`** — Calendar with all school events

---

### "I read this article and want to change my life"
1. **`note-to-actions`** — Extract insights, identify atomic habit, build implementation plan
2. **`habits`** — Track the new habit with streaks and check-ins
3. **`wellness`** — If habit is wellness-related (sleep, hydration, exercise)
4. **`tools`** — Set daily reminders for habit cue
5. **`healthcare`** — If habit is health-related (medication, lifestyle change)

---

### "Plan Thanksgiving / holiday dinner"
1. **`meal-planning`** — Plan the menu, generate shopping list, prep schedule
2. **`family-comms`** — Coordinate who's bringing what, announce timing
3. **`elder-care`** — Accommodate aging parents' dietary/mobility needs
4. **`restaurant-reservation`** — If dining out instead of cooking
5. **`tools`** — Calendar events, cooking timeline reminders
6. **`transportation`** — Airport pickups for traveling family

---

### "Regular weekday evening flow"
1. **`mental-load`** — Evening wind-down summary (what's done, what's tomorrow)
2. **`education`** — Homework check for kids (4 PM)
3. **`meal-planning`** — Dinner suggestion (4:30 PM if no plan)
4. **`wellness`** — Screen time check for kids, bedtime reminders
5. **`family-comms`** — Chore completion tracking
6. **`elder-care`** — Evening check-in with aging parent (7 PM)

---

*End of Skill Intent Map. Each section above is designed as an independent, self-contained RAG chunk. For optimal vector DB performance, split on `### ` headers under the Intent Routing Table, and treat Ambiguity Resolution Rules and each Multi-Skill Flow as separate chunks.*
