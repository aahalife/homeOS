# Hearth: Family Assistant for Mac
## Product Requirements Document

**Version:** 1.0  
**Date:** January 2025  
**Status:** Draft  

---

## Executive Summary

Hearth is a native macOS application that transforms how families stay organized, connected, and cared for. Built on Clawdbot's powerful AI foundation, Hearth provides an Apple-quality interface that makes family management feel effortless and even delightful.

Unlike complex family organization tools, Hearth takes a "less is more" approach—anticipating needs, simplifying decisions, and fading into the background until genuinely helpful. It's designed for the cognitive reality of busy parents: minimal input, maximum support.

### Key Value Propositions

1. **Reduce Mental Load** - Proactive reminders and automated planning so parents don't have to remember everything
2. **Connect Generations** - Simple elder care check-ins that keep grandparents engaged and families informed
3. **Empower Children** - Age-appropriate task management and education support
4. **Simplify Decisions** - AI-powered suggestions that reduce decision fatigue
5. **Respect Privacy** - Local-first architecture with user control over all data

---

## Problem Statement

### The Mental Load Crisis

Modern families face an invisible burden: the "mental load" of managing household logistics. Research shows:

- Parents spend 2+ hours daily on household coordination
- 70% of "invisible labor" falls on one parent (usually mom)
- Juggling children's schedules, activities, and education creates chronic stress
- Caring for aging parents adds another layer of worry and coordination

### Current Solutions Fall Short

| Solution | Problem |
|----------|----------|
| Shared calendars | Require manual entry, no intelligence |
| Family apps | Cluttered, require everyone to adopt |
| Reminder apps | Reactive, not proactive |
| Elder care services | Expensive, impersonal |
| AI assistants | Generic, not family-aware |

### The Opportunity

Clawdbot provides a powerful AI assistant foundation. HomeOS skills offer family-specific capabilities. What's missing is a **beautifully simple interface** that brings these capabilities to families in an Apple-native experience.

---

## Target Users

### Primary User: The Family Manager

Typically a parent (often mom) who:
- Coordinates family schedules and logistics
- Manages children's education and activities  
- Worries about aging parents
- Feels overwhelmed by the mental load
- Values simplicity and reliability
- Uses a Mac daily for work or personal tasks

### Secondary Users

| User | Needs | Interaction |
|------|-------|-------------|
| **Co-parent** | Visibility, contribution | Mobile notifications, quick actions |
| **Children (6-12)** | Task lists, homework help | Simple companion interface |
| **Teenagers (13-17)** | Independence, reminders | iMessage integration |
| **Grandparents** | Connection, care | Phone calls, simple check-ins |

---

## Product Goals

### North Star Metric
**Hours of mental load reduced per week per family**

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Daily active usage | 80% of days | Menu bar interaction |
| Task automation rate | 60% of reminders proactive | System-initiated vs user-initiated |
| Elder check-in completion | 90% daily | Successful call connections |
| Family coordination time | -30% reduction | Self-reported survey |
| NPS Score | >60 | Quarterly survey |

---

## Core Features

### 1. Menu Bar Presence (Always Available)

Hearth lives in the macOS menu bar with a warm, friendly icon. One click reveals the family dashboard.

**States:**
- 🏠 Normal - All is well
- 🟠 Attention - Something needs review
- 🔴 Urgent - Immediate action needed

**Quick Actions:**
- Today's overview
- Send family announcement
- Quick check-in with grandparent
- What's for dinner?

### 2. Morning Briefing

Automated daily summary delivered at a configured time.

**Includes:**
- Weather and how it affects today's plans
- Family schedule overview (who's where, when)
- Reminders and to-dos
- Children's school items (homework due, events)
- Medication reminders
- Proactive suggestions ("Emma has soccer - is her bag packed?")

**Delivery:**
- macOS notification
- Optional: iMessage to family members
- Optional: Voice summary via AirPods

### 3. Elder Care Hub

Dedicated interface for caring for aging parents.

**Daily Check-In Calls:**
- Scheduled AI-powered phone calls
- Warm, conversational tone
- Wellness questions woven naturally into chat
- Medication reminders during calls
- Play favorite music/songs on request

**Family Dashboard:**
- Today's check-in status (completed, scheduled, missed)
- Wellness trends over time
- Medication adherence tracking
- Flag unusual patterns (confusion, fatigue, missed calls)
- One-click "Call now" for immediate connection

**Alerts:**
- Missed check-in notification
- Concerning responses flagged
- Medication reminder failures

### 4. Education Command Center

Unified view of children's academic life.

**Per-Child Dashboard:**
- Current grades by subject
- Assignments due (today, this week)
- Missing work alerts
- Grade trend indicators (↑ improving, ↓ declining)

**Integrations:**
- Google Classroom sync
- Canvas LMS sync
- Manual entry fallback

**Actions:**
- Create study plan
- Set homework reminder
- Schedule tutor search
- Parent-teacher conference prep

### 5. Family Coordination

**Shared Calendar:**
- Aggregated family schedule
- Conflict detection and alerts
- Who's responsible for what (pickup, dropoff)
- Color-coded by family member

**Announcements:**
- Quick broadcast to all family members
- Priority levels (normal, important, urgent)
- Acknowledgment tracking
- Delivery via preferred channel (iMessage, notification)

**Chore Management:**
- Age-appropriate task assignment
- Rotation schedules
- Completion tracking
- Gentle reminders to kids

### 6. Meal Planning Assistant

**Weekly Planning:**
- AI-generated meal suggestions
- Based on family preferences and dietary needs
- Consider what's already in pantry
- Balance variety and nutrition

**Grocery Integration:**
- Auto-generated shopping list
- Organized by store section
- Share to Apple Reminders or preferred app
- Instacart/Amazon Fresh ordering option

**Quick Answers:**
- "What's for dinner tonight?"
- "What can I make with chicken and rice?"
- "We need a quick 20-minute meal"

### 7. Home Maintenance Tracker

**Scheduled Maintenance:**
- HVAC filter reminders
- Smoke detector battery checks
- Seasonal maintenance checklists
- Service provider contacts

**Emergency Guidance:**
- Water leak response steps
- Gas smell protocol
- Power outage checklist
- When to call 911 vs. plumber

### 8. Mental Load Reducer

**Proactive Intelligence:**
- Anticipate needs before asked
- "Soccer tomorrow - pack Emma's bag tonight"
- "Dad's birthday in 5 days - want gift ideas?"
- "Prescription refill due - want me to request it?"

**Decision Simplification:**
- Never ask open-ended questions
- Always propose specific options
- Remember preferences for faster decisions
- "For dinner: Tacos, pasta, or stir-fry? (Based on what you have)"

**Evening Wind-Down:**
- Tomorrow preview
- Prep suggestions for morning
- Acknowledge completed tasks
- Gentle transition to family time

---

## Technical Architecture

### Foundation: Clawdbot Backend

Hearth is a native macOS client that connects to a local Clawdbot Gateway.

```
┌─────────────────────┐
│   Hearth Mac App    │  ← Native SwiftUI Interface
│   (Menu Bar + UI)   │
└──────────┬──────────┘
           │ WebSocket
           ▼
┌─────────────────────┐
│  Clawdbot Gateway   │  ← Local AI Processing
│  (ws://localhost)   │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐ ┌─────────┐
│ HomeOS  │ │ Clawdbot│
│ Skills  │ │ Skills  │  ← Capability Modules
└─────────┘ └─────────┘
```

### Technology Stack

| Component | Technology | Rationale |
|-----------|------------|----------|
| **UI Framework** | SwiftUI | Native macOS, declarative, modern |
| **App Type** | Menu Bar + Window | Always accessible, non-intrusive |
| **Backend Comm** | WebSocket | Real-time, bidirectional with Clawdbot |
| **Local Storage** | SwiftData | Native, iCloud sync capable |
| **Notifications** | UserNotifications | Native macOS integration |
| **Voice** | AVFoundation + Speech | Voice input/output |
| **Telephony** | Clawdbot Telephony Skill | AI-powered calls |

### Data Flow

1. **User Input** → Hearth captures via UI or voice
2. **Processing** → Clawdbot Gateway routes to appropriate skill
3. **Execution** → Skill performs action (lookup, schedule, call, etc.)
4. **Response** → Gateway returns result via WebSocket
5. **Display** → Hearth renders in native UI

### Local-First Architecture

- All family data stored locally in `~/Library/Application Support/Hearth/`
- Clawdbot workspace at `~/clawd/homeos/`
- Optional iCloud sync for multi-device families
- No data sent to external servers without explicit consent

### Skill Integration

Hearth bundles and manages these HomeOS skills:

| Skill | Purpose |
|-------|---------|
| `family-comms` | Announcements, calendar, chores |
| `elder-care` | Check-ins, medications, engagement |
| `education` | Homework, grades, study plans |
| `mental-load` | Briefings, reminders, decisions |
| `meal-planning` | Menus, grocery lists, recipes |
| `healthcare` | Appointments, medications, records |
| `home-maintenance` | Repairs, schedules, emergencies |
| `wellness` | Habits, hydration, movement |
| `chat-turn` | Conversational processing |
| `_infrastructure` | Core storage, approvals, utilities |

---

## Design Principles

### 1. Invisible Until Helpful

Hearth should feel like a thoughtful family member who anticipates needs without being asked. It shouldn't demand attention; it should earn it by being genuinely useful.

**Do:**
- Proactively surface relevant information
- Fade into background when not needed
- Use subtle indicators (menu bar dot) for status

**Don't:**
- Interrupt with unnecessary notifications
- Require constant input or configuration
- Make the user feel like they're managing another app

### 2. Propose, Don't Ask

Reduce cognitive load by offering specific suggestions rather than open-ended questions.

**Do:**
- "Dinner tonight: Tacos, stir-fry, or pasta?"
- "Emma's homework is due tomorrow - remind her at 4pm?"

**Don't:**
- "What would you like for dinner?"
- "When should I remind Emma about homework?"

### 3. Warmth Without Cuteness

The personality should be warm, supportive, and reliable—like a trusted friend, not a cartoon character.

**Tone:**
- Conversational but not overly casual
- Encouraging without being patronizing
- Direct and clear, never verbose

**Voice:**
- "All set for tomorrow. Emma's bag is packed, lunches are prepped."
- Not: "Yay! Everything's ready for an AMAZING day tomorrow! 🎉"

### 4. Respect User Agency

Always give users control. Never take actions without appropriate confirmation.

**Risk Levels:**
- **Low** (read, suggest): No confirmation needed
- **Medium** (save, remind): Ask once, remember preference
- **High** (call, spend, send): Always confirm explicitly

### 5. Family-First Privacy

Families trust Hearth with intimate details. Honor that trust.

- All data local by default
- Clear explanation of any external connections
- Easy data export and deletion
- No monetization of family data, ever

---

## User Interface

### Menu Bar

```
┌─────────────────────────────────────┐
│  🏠 Hearth                        │
├─────────────────────────────────────┤
│  Good morning, Sarah!            │
│                                   │
│  ☉ 72°F  Sunny                    │
│                                   │
│  ┌─────────────────────────────┐ │
│  │ TODAY                       │ │
│  │ 8:00  School dropoff        │ │
│  │ 3:30  Emma → Soccer         │ │
│  │ 5:00  Jack → Piano          │ │
│  │ 6:30  Family dinner         │ │
│  └─────────────────────────────┘ │
│                                   │
│  ⚠️  2 items need attention        │
│     • Emma: Math homework due     │
│     • Grandma check-in at 10am   │
│                                   │
├─────────────────────────────────────┤
│  [What's for dinner?]  [Call Mom] │
└─────────────────────────────────────┘
```

### Full Window (Command + Click)

```
┌──────────────────────────────────────────────────────────┐
│  🏠 Hearth                    [Sarah]  [⚙]  │
├───────────┬──────────────────────────────────────────────┤
│           │                                              │
│  📅 Today │  FAMILY OVERVIEW                             │
│           │                                              │
│  👵 Elders │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│           │  │   👨 Dad    │ │   👩 Mom    │ │  👧 Emma   │ │
│  📚 School │  │  At work   │ │  Working   │ │  School    │ │
│           │  │  Until 5pm │ │  from home │ │  Soccer 3p │ │
│  🍽 Meals  │  └─────────────┘ └─────────────┘ └─────────────┘ │
│           │                                              │
│  🏠 Home   │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│           │  │  👦 Jack   │ │ 👵 Grandma │ │ 👴 Grandpa │ │
│  ⚙ Settings│  │  School    │ │  ✅ Called  │ │  ⏰ 10am   │ │
│           │  │  Piano 5pm │ │  Feeling   │ │  check-in  │ │
│           │  │           │ │  good!     │ │           │ │
│           │  └─────────────┘ └─────────────┘ └─────────────┘ │
│           │                                              │
└───────────┴──────────────────────────────────────────────┘
```

### Elder Care View

```
┌───────────────────────────────────────────────┐
│  👵 Grandma Rose                              │
├───────────────────────────────────────────────┤
│                                               │
│  TODAY'S CHECK-INS                            │
│  ┌─────────────────────────────────────────┐ │
│  │  ☉ 9:00 AM  Morning Check-in       ✅    │ │
│  │     "Slept well, had breakfast"         │ │
│  │     Medications: Taken ✅                │ │
│  │     Mood: Good 😊                        │ │
│  ├─────────────────────────────────────────┤ │
│  │  ☾ 7:00 PM  Evening Check-in      ⏳    │ │
│  │     Scheduled in 6 hours               │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  THIS WEEK                                    │
│  Mon ✅  Tue ✅  Wed ✅  Thu ⭕  Fri ⭕  Sat ⭕  │
│                                               │
│  WELLNESS TRENDS                              │
│  Sleep: ███████▓░░ Good                      │
│  Mood:  ████████▓░ Excellent                 │
│  Meds:  ██████████ 100%                      │
│                                               │
├───────────────────────────────────────────────┤
│  [📞 Call Now]  [🎵 Play Music]  [📝 Add Note] │
└───────────────────────────────────────────────┘
```

---

## Onboarding Experience

### First Launch Flow

1. **Welcome** - Warm introduction to Hearth's purpose
2. **Family Setup** - Add family members (name, role, photo)
3. **Calendar Connect** - Link to Apple/Google Calendar
4. **Elder Care** (optional) - Set up grandparent profiles
5. **School Connect** (optional) - Link Google Classroom/Canvas
6. **Preferences** - Morning briefing time, notification settings
7. **Ready** - First proactive suggestion based on calendar

### Progressive Disclosure

Hearth learns over time rather than requiring extensive upfront setup:

- Start with calendar and family members only
- Suggest elder care setup when user mentions parents
- Prompt for school integration when homework is mentioned
- Surface meal planning after a few "what's for dinner" questions

---

## Privacy & Security

### Data Principles

1. **Local by Default** - All family data stored on device
2. **Encrypted at Rest** - Using macOS Keychain and encrypted containers
3. **Minimal Permissions** - Only request what's needed, when needed
4. **Transparent Processing** - Clear indicators when AI is processing
5. **User Control** - Easy export, deletion, and visibility into stored data

### Data Categories

| Data Type | Storage | Sync | Deletion |
|-----------|---------|------|----------|
| Family profiles | Local | Optional iCloud | User-initiated |
| Calendar cache | Local | N/A (fetched) | Automatic |
| Elder care logs | Local | Optional iCloud | 90-day auto, manual |
| Conversation history | Local | Never | 30-day auto, manual |
| Preferences | Local | Optional iCloud | User-initiated |

### Third-Party Connections

| Service | Purpose | Data Shared | User Control |
|---------|---------|-------------|---------------|
| Google Classroom | Homework sync | OAuth token only | Disconnect anytime |
| Canvas LMS | Grade sync | OAuth token only | Disconnect anytime |
| Apple Calendar | Schedule sync | Read-only access | Revoke in System Prefs |
| AI Provider (Anthropic/OpenAI) | Processing | Conversation context | Clear history |
| Telephony (calls) | Elder check-ins | Phone number, script | Per-call approval |

### Audit Log

All high-risk actions logged locally:
- When actions occurred
- What data was accessed
- User approvals given
- External connections made

---

## Implementation Phases

### Phase 1: Foundation (MVP)
**Duration:** 8 weeks

**Scope:**
- Menu bar app with daily overview
- Family member profiles
- Calendar integration (Apple Calendar)
- Morning briefing notifications
- Basic Clawdbot Gateway connection

**Success Criteria:**
- Clean menu bar UI launches reliably
- Calendar events display correctly
- Morning briefing delivers at configured time

### Phase 2: Elder Care
**Duration:** 6 weeks

**Scope:**
- Elder profiles with preferences
- Scheduled check-in calls via telephony skill
- Check-in summaries and wellness tracking
- Family notification on completion
- One-click manual call initiation

**Success Criteria:**
- Successful AI phone calls to test number
- Wellness data captured and displayed
- Alert system functions on missed check-ins

### Phase 3: Education
**Duration:** 6 weeks

**Scope:**
- Google Classroom integration
- Canvas LMS integration
- Per-child homework dashboard
- Grade tracking and alerts
- Study plan generation

**Success Criteria:**
- Assignments sync correctly
- Grade alerts trigger appropriately
- Study plans generate useful schedules

### Phase 4: Home & Meals
**Duration:** 6 weeks

**Scope:**
- Meal planning with AI suggestions
- Grocery list generation
- Home maintenance scheduler
- Emergency guidance system
- Chore assignment and tracking

**Success Criteria:**
- Meal plans respect dietary preferences
- Grocery lists are accurate and shareable
- Maintenance reminders fire correctly

### Phase 5: Intelligence & Polish
**Duration:** 4 weeks

**Scope:**
- Proactive suggestion engine
- Decision simplification across all features
- Evening wind-down summaries
- Performance optimization
- Accessibility improvements

**Success Criteria:**
- Proactive suggestions are relevant 80%+ of time
- App feels fast and responsive
- VoiceOver fully supported

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Clawdbot API changes | High | Medium | Abstract gateway interface, version pinning |
| Elder call quality issues | High | Medium | Extensive testing, human fallback option |
| LMS integration breaks | Medium | High | Graceful degradation, manual entry fallback |
| Privacy concerns | High | Medium | Transparency, local-first architecture |
| Feature creep | Medium | High | Strict MVP focus, user research validation |
| User adoption | High | Medium | Focus on single killer feature (elder care) |

---

## Appendix A: Competitive Analysis

| Product | Strengths | Weaknesses | Hearth Differentiation |
|---------|-----------|------------|------------------------|
| **Cozi** | Popular, free | Cluttered, ads, no AI | Proactive intelligence, elder care |
| **OurHome** | Chores, rewards | Kid-focused only | Full family lifecycle |
| **Life360** | Location sharing | Privacy concerns | Privacy-first, local data |
| **FamilyWall** | Shared calendar | Manual, no intelligence | AI-powered suggestions |
| **Care.com** | Caregiver search | Transactional | Continuous care relationship |

---

## Appendix B: Research References

1. "The Mental Load" - Emma Clit (2017)
2. "Fair Play" - Eve Rodsky (2019)
3. "Invisible Women" - Caroline Criado Perez (2019)
4. Apple Human Interface Guidelines (2024)
5. Nielsen Norman Group: Notification Design (2023)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|----------|
| 1.0 | Jan 2025 | PRD Team | Initial draft |

---

*This PRD is a living document. Updates will be tracked in version control.*
