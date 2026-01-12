# Hearth: Skills Catalog

> Comprehensive catalog of all skills needed to support family life, organized by domain.

---

## Overview

This document catalogs 100+ skills organized using the MECE principle (Mutually Exclusive, Collectively Exhaustive) to ensure complete coverage of family needs.

### Skill Categories

1. **Financial Management** - Bills, payments, budgeting
2. **Home Operations** - Maintenance, cleaning, safety
3. **Family Logistics** - Calendar, transportation, events
4. **Health & Wellness** - Medical, fitness, mental health
5. **Education & Development** - School, learning, activities
6. **Elder Care** - Check-ins, medications, engagement
7. **Nutrition & Meals** - Planning, shopping, cooking
8. **Emotional Support** - Parenting, regulation, bonding
9. **Social & Relationships** - Birthdays, gifts, connections
10. **Administrative** - Documents, renewals, subscriptions
11. **Communication** - Multi-channel messaging, voice
12. **Automation & Intelligence** - Cross-skill orchestration

---

## 1. Financial Management Skills

### 1.1 `bill-scanner`
**Purpose:** Automatically detect and track bills from email/messages

**Triggers:**
- Email scan (Gmail Pub/Sub)
- SMS/message scan
- Manual bill entry

**Capabilities:**
- Extract bill amount, due date, payee
- Match against known billers
- Detect duplicate/spam bills
- Compare to historical payments
- Alert on unusual amounts

**Integrations:**
- Gmail API
- Bank statement parsing
- Plaid (optional)

**Automation Level:** Can run fully automated with allowlist

---

### 1.2 `payment-tracker`
**Purpose:** Track payment status and prevent missed payments

**Capabilities:**
- Track due dates across all bills
- Verify payments made
- Alert before due dates (configurable: 7/3/1 days)
- Detect auto-pay failures
- Reconcile with bank transactions

**Integrations:**
- Bank accounts (Plaid)
- Credit card statements
- Biller websites (browser automation)

---

### 1.3 `budget-monitor`
**Purpose:** Track spending against family budget

**Capabilities:**
- Categorize transactions
- Track against budget categories
- Alert on overspending
- Monthly summaries
- Trend analysis

---

### 1.4 `subscription-manager`
**Purpose:** Track and manage recurring subscriptions

**Capabilities:**
- Detect subscriptions from transactions
- Track renewal dates
- Alert before renewals
- Identify unused subscriptions
- Cancel subscriptions (with approval)

**Browser Automation:**
- Navigate to subscription pages
- Complete cancellation flows
- Capture confirmation

---

### 1.5 `tax-assistant`
**Purpose:** Organize tax-related documents year-round

**Capabilities:**
- Flag tax-relevant transactions
- Organize receipts by category
- Track deductible expenses
- Reminder for tax deadlines
- Export for tax software

---

## 2. Home Operations Skills

### 2.1 `maintenance-scheduler`
**Purpose:** Proactive home maintenance scheduling

**Scheduled Tasks:**
- HVAC filter replacement (monthly/quarterly)
- Smoke detector batteries (biannual)
- Gutter cleaning (seasonal)
- Water heater flush (annual)
- Dryer vent cleaning (annual)
- Refrigerator coil cleaning (annual)
- Garage door maintenance (annual)

**Capabilities:**
- Create maintenance calendar
- Send reminders with instructions
- Track completion
- Adjust based on home age/type

---

### 2.2 `contractor-finder`
**Purpose:** Find and vet service providers

**Capabilities:**
- Search local contractors
- Check reviews and ratings
- Verify licenses (where available)
- Get multiple quotes
- Schedule appointments
- Save provider contacts

**Integrations:**
- Yelp API
- Google Places
- Angi/HomeAdvisor
- Thumbtack

---

### 2.3 `emergency-response`
**Purpose:** Guide through home emergencies

**Emergency Types:**
- Water leak (shutoff location, steps)
- Gas smell (evacuation, contacts)
- Power outage (safety, reporting)
- Fire (evacuation, 911)
- Break-in (safety, police)
- Medical emergency (911, CPR guidance)

**Capabilities:**
- Store home-specific info (shutoff locations)
- Step-by-step guidance
- Emergency contact quick-dial
- Insurance claim initiation

---

### 2.4 `inventory-manager`
**Purpose:** Track household inventory and supplies

**Tracks:**
- Pantry items
- Cleaning supplies
- Toiletries
- Medications
- Batteries
- Light bulbs

**Capabilities:**
- Low stock alerts
- Auto-add to shopping list
- Track expiration dates
- Barcode scanning (mobile)

---

### 2.5 `seasonal-tasks`
**Purpose:** Seasonal home preparation

**Spring:**
- AC servicing
- Window cleaning
- Lawn prep
- Patio furniture

**Summer:**
- Pool maintenance
- Pest control
- Garden care

**Fall:**
- Heating check
- Gutter cleaning
- Winterization prep
- Outdoor furniture storage

**Winter:**
- Pipe insulation check
- Ice dam prevention
- Snow removal prep
- Holiday decoration safety

---

### 2.6 `cleaning-coordinator`
**Purpose:** Manage cleaning schedules and services

**Capabilities:**
- Daily/weekly/monthly task lists
- Assign to family members
- Track completion
- Coordinate with cleaning service
- Supply inventory

---

## 3. Family Logistics Skills

### 3.1 `calendar-sync`
**Purpose:** Unified family calendar

**Integrations:**
- Apple Calendar (EventKit)
- Google Calendar
- Outlook
- School calendars
- Sports team calendars

**Capabilities:**
- Aggregate all calendars
- Conflict detection
- Family member views
- Shared event creation

---

### 3.2 `transportation-coordinator`
**Purpose:** Manage family transportation

**Capabilities:**
- Carpool coordination
- Pickup/dropoff assignment
- Route optimization
- Traffic-aware timing
- Ride service booking (Uber/Lyft)

**Integrations:**
- Google Maps
- Apple Maps
- Uber API
- Lyft API

---

### 3.3 `activity-manager`
**Purpose:** Track children's activities and commitments

**Tracks:**
- Sports teams and schedules
- Music lessons
- Tutoring
- Clubs and organizations
- Camps and programs

**Capabilities:**
- Schedule coordination
- Equipment checklists
- Fee tracking
- Registration reminders

---

### 3.4 `travel-planner`
**Purpose:** Plan and manage family travel

**Capabilities:**
- Trip planning assistance
- Packing list generation
- Reservation tracking
- Document management (passports, etc.)
- Pet care coordination
- Mail/package hold
- Home security prep

**Integrations:**
- TripIt
- Airline APIs
- Hotel booking sites

---

### 3.5 `event-planner`
**Purpose:** Plan family events and parties

**Event Types:**
- Birthday parties
- Holiday gatherings
- Playdates
- Family reunions

**Capabilities:**
- Guest list management
- Invitation sending
- RSVP tracking
- Menu planning
- Activity ideas
- Vendor coordination

---

## 4. Health & Wellness Skills

### 4.1 `appointment-manager`
**Purpose:** Track and schedule medical appointments

**Tracks:**
- Doctor visits
- Dental checkups
- Vision exams
- Specialist appointments
- Vaccinations

**Capabilities:**
- Due date tracking
- Appointment scheduling
- Reminder system
- Insurance verification
- Pre-visit prep (forms, questions)

---

### 4.2 `medication-manager`
**Purpose:** Track family medications

**Capabilities:**
- Medication schedules
- Refill reminders
- Interaction checking
- Side effect tracking
- Pharmacy coordination

**Integrations:**
- Pharmacy APIs (CVS, Walgreens)
- GoodRx for pricing

---

### 4.3 `symptom-tracker`
**Purpose:** Track and log symptoms for doctor visits

**Capabilities:**
- Log symptoms with timestamp
- Pattern detection
- Export for doctor
- Severity tracking
- Correlation analysis

---

### 4.4 `fitness-tracker`
**Purpose:** Family fitness and activity tracking

**Integrations:**
- Apple Health
- Fitbit
- Garmin
- Peloton

**Capabilities:**
- Activity summaries
- Goal tracking
- Family challenges
- Movement reminders

---

### 4.5 `sleep-monitor`
**Purpose:** Track and improve family sleep

**Capabilities:**
- Bedtime reminders
- Sleep schedule tracking
- Sleep quality patterns
- Wind-down routines
- Screen time cutoffs

---

### 4.6 `hydration-tracker`
**Purpose:** Encourage adequate hydration

**Capabilities:**
- Personalized goals
- Regular reminders
- Progress tracking
- Weather-adjusted goals

---

## 5. Education & Development Skills

### 5.1 `homework-tracker` (enhanced)
**Purpose:** Comprehensive homework management

**Integrations:**
- Google Classroom
- Canvas
- Schoology
- PowerSchool
- Infinite Campus

**Capabilities:**
- Assignment aggregation
- Due date tracking
- Progress monitoring
- Missing work alerts
- Study schedule creation

---

### 5.2 `grade-monitor`
**Purpose:** Track academic progress

**Capabilities:**
- Real-time grade tracking
- Trend analysis
- Drop alerts
- GPA calculation
- Progress reports

---

### 5.3 `study-coach`
**Purpose:** AI-powered study assistance

**Capabilities:**
- Study plan generation
- Pomodoro timer
- Flashcard creation
- Practice problems
- Concept explanation
- Test prep strategies

---

### 5.4 `school-comm-monitor`
**Purpose:** Never miss school communications

**Monitors:**
- School emails
- App notifications (ClassDojo, Remind, etc.)
- School website updates
- Teacher messages

**Capabilities:**
- Extract action items
- Calendar event creation
- Permission slip tracking
- Fee payment reminders

---

### 5.5 `tutor-finder`
**Purpose:** Find and manage tutoring

**Capabilities:**
- Tutor search
- Subject matching
- Schedule coordination
- Progress tracking
- Payment management

**Integrations:**
- Wyzant
- Varsity Tutors
- Local tutor databases

---

### 5.6 `college-prep`
**Purpose:** College preparation tracking

**Capabilities:**
- Standardized test tracking
- Application deadlines
- Essay assistance
- Financial aid reminders
- Campus visit planning

---

## 6. Elder Care Skills

### 6.1 `elder-checkin` (enhanced)
**Purpose:** Daily wellness check-ins

**Capabilities:**
- Scheduled voice calls
- Wellness assessment
- Medication reminders
- Mood tracking
- Social engagement
- Music therapy
- Memory conversations

---

### 6.2 `medication-adherence`
**Purpose:** Elder medication management

**Capabilities:**
- Multi-dose scheduling
- Reminder calls/messages
- Adherence tracking
- Refill coordination
- Side effect monitoring

---

### 6.3 `elder-engagement`
**Purpose:** Cognitive and social engagement

**Activities:**
- Nostalgic music playing
- Memory conversations
- News discussions
- Trivia and games
- Photo sharing
- Video calls with family

---

### 6.4 `fall-detection` (integration)
**Purpose:** Safety monitoring integration

**Integrations:**
- Apple Watch fall detection
- Medical alert systems
- Smart home sensors

---

### 6.5 `elder-appointment-assist`
**Purpose:** Medical appointment support

**Capabilities:**
- Appointment scheduling
- Transportation coordination
- Pre-visit prep
- Post-visit summary
- Family notification

---

## 7. Nutrition & Meals Skills

### 7.1 `meal-planner` (enhanced)
**Purpose:** AI-powered meal planning

**Capabilities:**
- Weekly menu generation
- Dietary restriction handling
- Nutritional balance
- Preference learning
- Leftover integration
- Batch cooking suggestions

---

### 7.2 `recipe-manager`
**Purpose:** Family recipe collection

**Capabilities:**
- Recipe storage
- Web recipe import
- Scaling calculations
- Substitution suggestions
- Family favorites tracking

---

### 7.3 `grocery-assistant`
**Purpose:** Smart grocery management

**Capabilities:**
- Auto-list from meal plan
- Store organization
- Price comparison
- Coupon finding
- Delivery ordering

**Integrations:**
- Instacart
- Amazon Fresh
- Walmart Grocery
- Local store apps

---

### 7.4 `pantry-tracker`
**Purpose:** Track kitchen inventory

**Capabilities:**
- Item tracking
- Expiration alerts
- Low stock notifications
- Recipe suggestion based on inventory

---

### 7.5 `restaurant-booker`
**Purpose:** Restaurant reservations

**Capabilities:**
- Restaurant search
- Availability check
- Reservation booking
- Preference matching

**Integrations:**
- OpenTable
- Resy
- Yelp
- Direct restaurant booking

---

## 8. Emotional Support Skills

### 8.1 `meltdown-support`
**Purpose:** Real-time parenting support during difficult moments

**Capabilities:**
- Breathing exercises (guided)
- De-escalation phrases
- Age-appropriate strategies
- Calm-down techniques
- Post-incident reflection

---

### 8.2 `mindfulness-guide`
**Purpose:** Family mindfulness and regulation

**Techniques:**
- Box breathing (4-4-4-4)
- 5-4-3-2-1 grounding
- Body scan
- Progressive muscle relaxation
- Guided visualization

**Delivery:**
- Voice-guided exercises
- Visual breathing guides
- Ambient sounds
- Timer-based sessions

---

### 8.3 `screen-time-guardian`
**Purpose:** Healthy screen time management

**Capabilities:**
- Time limit setting
- Usage tracking
- Break reminders
- Content awareness
- Earned time rewards

**Integrations:**
- Apple Screen Time
- Google Family Link
- Router-level controls

---

### 8.4 `perspective-coach`
**Purpose:** Help parents gain perspective in difficult moments

**Capabilities:**
- "This too shall pass" reminders
- Developmental context
- Long-term vs. short-term framing
- Self-compassion prompts
- Connection vs. correction guidance

---

### 8.5 `gratitude-practice`
**Purpose:** Family gratitude cultivation

**Capabilities:**
- Daily gratitude prompts
- Family gratitude sharing
- Gratitude journaling
- Weekly reflection

---

### 8.6 `quality-time-ideas`
**Purpose:** Facilitate meaningful family connection

**Ideas by:**
- Time available (5 min, 30 min, half day)
- Location (home, outdoors, in car)
- Energy level
- Weather
- Age appropriateness

---

## 9. Social & Relationships Skills

### 9.1 `birthday-manager`
**Purpose:** Never miss a birthday

**Capabilities:**
- Birthday tracking
- Reminder escalation (1 month, 1 week, 3 days)
- Gift idea suggestions
- Card sending
- Party planning support

---

### 9.2 `gift-assistant`
**Purpose:** Thoughtful gift planning

**Capabilities:**
- Gift idea generation
- Preference tracking
- Past gift history
- Budget management
- Purchase coordination

---

### 9.3 `thank-you-tracker`
**Purpose:** Ensure thank-you notes are sent

**Capabilities:**
- Gift receipt logging
- Thank-you reminders
- Template suggestions
- Completion tracking

---

### 9.4 `social-calendar`
**Purpose:** Track social commitments

**Capabilities:**
- Event tracking
- RSVP management
- Host gift reminders
- Reciprocity tracking

---

## 10. Administrative Skills

### 10.1 `document-vault`
**Purpose:** Important document management

**Documents:**
- Birth certificates
- Social security cards
- Passports
- Insurance policies
- Wills and trusts
- Property deeds
- Vehicle titles
- Medical records

**Capabilities:**
- Secure storage
- Expiration tracking
- Renewal reminders
- Quick retrieval

---

### 10.2 `renewal-tracker`
**Purpose:** Track expiring documents and registrations

**Tracks:**
- Driver's licenses
- Passports
- Vehicle registration
- Professional licenses
- Memberships
- Domain names

---

### 10.3 `warranty-manager`
**Purpose:** Track product warranties

**Capabilities:**
- Warranty registration
- Expiration tracking
- Claim assistance
- Receipt storage

---

### 10.4 `insurance-coordinator`
**Purpose:** Manage family insurance

**Types:**
- Health insurance
- Dental/vision
- Auto insurance
- Home/renters
- Life insurance
- Umbrella coverage

**Capabilities:**
- Policy tracking
- Premium reminders
- Claim filing assistance
- Coverage review reminders

---

## 11. Communication Skills

### 11.1 `multi-channel-messenger`
**Purpose:** Send messages across platforms

**Channels:**
- iMessage
- WhatsApp
- Telegram
- SMS
- Email
- Slack
- Discord

**Capabilities:**
- Recipient preference memory
- Message formatting per channel
- Delivery confirmation
- Read receipts (where available)

---

### 11.2 `voice-companion`
**Purpose:** Natural voice interaction

**Components:**
- ASR (Whisper, Deepgram)
- VAD (Silero)
- TTS (ElevenLabs, Azure)
- Wake word detection

**Capabilities:**
- Natural conversation
- Context awareness
- Multi-turn dialogue
- Voice identification

---

### 11.3 `announcement-broadcaster`
**Purpose:** Family-wide announcements

**Capabilities:**
- Multi-channel delivery
- Priority levels
- Acknowledgment tracking
- Reminder for non-responders

---

### 11.4 `telephony-agent`
**Purpose:** AI phone calls

**Use Cases:**
- Elder check-ins
- Appointment scheduling
- Restaurant reservations
- Customer service calls
- RSVP calls

**Capabilities:**
- Natural conversation
- Task completion
- Summary generation
- Recording (with consent)

---

## 12. Automation & Intelligence Skills

### 12.1 `automation-orchestrator`
**Purpose:** Cross-skill coordination and complex workflows

**Capabilities:**
- Multi-skill task sequences
- Conditional logic
- Error recovery (Ralph Wiggum loop)
- Progress tracking
- Rollback on failure

---

### 12.2 `preference-engine`
**Purpose:** Learn and apply family preferences

**Learns:**
- Communication preferences
- Timing preferences
- Decision patterns
- Approval patterns
- Food preferences
- Activity preferences

**Capabilities:**
- Preference inference
- Preference application
- Explicit preference storage
- Preference conflict resolution

---

### 12.3 `allowlist-manager`
**Purpose:** Manage automation permissions

**Patterns:**
- "Always allow" rules
- "Never allow" rules
- "Ask once" rules
- Time-based rules
- Amount-based rules

---

### 12.4 `browser-automator`
**Purpose:** Web automation for complex tasks

**Capabilities:**
- Form filling
- Account creation
- Data extraction
- Screenshot capture
- Multi-step workflows

**Use Cases:**
- Sign up for services
- Fill out school forms
- Submit applications
- Cancel subscriptions

---

### 12.5 `error-recovery`
**Purpose:** Handle failures gracefully

**Strategies:**
- Retry with backoff
- Alternative approaches
- Partial completion
- User escalation
- Context preservation

---

### 12.6 `cron-scheduler`
**Purpose:** Scheduled task execution

**Capabilities:**
- Recurring tasks
- One-time scheduled tasks
- Smart timing (avoid busy periods)
- Dependency awareness
- Failure notification

---

### 12.7 `context-manager`
**Purpose:** Maintain context across interactions

**Stores:**
- Recent conversations
- Active tasks
- Pending items
- Family state
- Temporal context

---

## Skill Dependencies

```
automation-orchestrator
    ├── preference-engine
    ├── allowlist-manager
    ├── browser-automator
    ├── error-recovery
    ├── cron-scheduler
    └── context-manager

multi-channel-messenger
    ├── iMessage (imsg skill)
    ├── WhatsApp (wacli skill)
    ├── Telegram (telegram skill)
    └── Email (himalaya skill)

voice-companion
    ├── ASR (whisper skill)
    ├── TTS (elevenlabs/echo-tts)
    └── VAD (silero)
```

---

*Skills are designed to be composable, allowing complex family workflows through orchestration.*
