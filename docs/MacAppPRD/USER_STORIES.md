# Hearth: User Stories

This document contains detailed user stories organized by epic, with acceptance criteria and priority levels.

## Priority Levels

- **P0** - Must have for MVP
- **P1** - Should have for launch
- **P2** - Nice to have
- **P3** - Future consideration

---

## Epic 1: Menu Bar Foundation

### US-1.1: Menu Bar Presence
**Priority:** P0

> As a parent, I want Hearth to live in my menu bar so I can quickly access family information without opening a full app.

**Acceptance Criteria:**
- [ ] App icon appears in macOS menu bar on launch
- [ ] Icon has three states: normal (🏠), attention (🟠), urgent (🔴)
- [ ] Single click opens dropdown panel
- [ ] Cmd+click opens full window
- [ ] Right-click shows context menu (Quit, Settings)
- [ ] App launches at login (configurable)

### US-1.2: Today Dashboard
**Priority:** P0

> As a parent, I want to see today's family schedule at a glance so I know what's happening.

**Acceptance Criteria:**
- [ ] Shows current weather
- [ ] Lists today's events by time
- [ ] Color-codes events by family member
- [ ] Shows items needing attention
- [ ] Updates in real-time

### US-1.3: Quick Actions
**Priority:** P0

> As a parent, I want quick action buttons so I can perform common tasks instantly.

**Acceptance Criteria:**
- [ ] "What's for dinner?" button triggers meal suggestion
- [ ] "Call [Elder]" button initiates check-in
- [ ] "Send announcement" opens quick compose
- [ ] Actions execute within 2 seconds

---

## Epic 2: Family Setup

### US-2.1: Family Profile Creation
**Priority:** P0

> As a new user, I want to add my family members so Hearth knows who we are.

**Acceptance Criteria:**
- [ ] Can add family member with name, role, and photo
- [ ] Roles: Parent, Child (with age), Elder
- [ ] Optional: phone number, email
- [ ] Can edit or remove members anytime
- [ ] Data stored locally only

### US-2.2: Calendar Integration
**Priority:** P0

> As a parent, I want to connect our family calendar so Hearth knows our schedule.

**Acceptance Criteria:**
- [ ] Supports Apple Calendar (EventKit)
- [ ] Can select which calendars to include
- [ ] Read-only access (no modifications)
- [ ] Syncs automatically every 15 minutes
- [ ] Manual refresh available

### US-2.3: Google Calendar Support
**Priority:** P1

> As a parent who uses Google Calendar, I want to connect it so all events are visible.

**Acceptance Criteria:**
- [ ] OAuth flow for Google Calendar
- [ ] Can select specific calendars
- [ ] Events merge with Apple Calendar view
- [ ] Can disconnect anytime

---

## Epic 3: Morning Briefing

### US-3.1: Automated Morning Summary
**Priority:** P0

> As a parent, I want a morning briefing so I start the day organized.

**Acceptance Criteria:**
- [ ] Configurable delivery time (default 7am)
- [ ] Includes weather forecast
- [ ] Lists day's schedule for all family members
- [ ] Highlights items needing attention
- [ ] Delivers via macOS notification

### US-3.2: Voice Morning Briefing
**Priority:** P2

> As a parent getting ready in the morning, I want to hear my briefing so I don't have to look at a screen.

**Acceptance Criteria:**
- [ ] Text-to-speech reads briefing content
- [ ] Works with AirPods and other audio devices
- [ ] Can be triggered manually or automatically
- [ ] Interruptible

---

## Epic 4: Elder Care

### US-4.1: Elder Profile Setup
**Priority:** P0

> As an adult child, I want to set up profiles for my parents so Hearth can help care for them.

**Acceptance Criteria:**
- [ ] Add elder with name, phone, relationship
- [ ] Set preferred check-in times
- [ ] Add medications with schedule
- [ ] Add interests/preferences for conversation
- [ ] Add emergency contacts

### US-4.2: Scheduled Check-In Calls
**Priority:** P0

> As an adult child, I want Hearth to call my parents daily so they stay connected.

**Acceptance Criteria:**
- [ ] AI-powered phone call at scheduled time
- [ ] Warm, conversational greeting
- [ ] Asks about wellness naturally
- [ ] Reminds about medications during call
- [ ] Can play favorite music on request
- [ ] Requires explicit user approval before each call day

### US-4.3: Check-In Summary
**Priority:** P0

> As an adult child, I want to see how my parent's check-in went so I know they're okay.

**Acceptance Criteria:**
- [ ] Summary appears after call completes
- [ ] Shows: mood, sleep, medications taken
- [ ] Flags any concerning responses
- [ ] Notification sent to designated family

### US-4.4: Wellness Trends
**Priority:** P1

> As an adult child, I want to see wellness trends over time so I can spot changes.

**Acceptance Criteria:**
- [ ] 7-day and 30-day trend views
- [ ] Tracks: mood, sleep, medication adherence
- [ ] Visual indicators for declining trends
- [ ] Exportable for doctor visits

### US-4.5: Manual Call
**Priority:** P0

> As an adult child, I want to trigger a check-in call immediately if I'm worried.

**Acceptance Criteria:**
- [ ] One-click "Call Now" button
- [ ] Uses same check-in flow
- [ ] Summary delivered after

---

## Epic 5: Education

### US-5.1: Google Classroom Connection
**Priority:** P1

> As a parent, I want to connect to Google Classroom so I can see my kids' homework.

**Acceptance Criteria:**
- [ ] OAuth flow for Google Classroom
- [ ] Select which children/classes to monitor
- [ ] Syncs assignments and grades
- [ ] Shows due dates clearly

### US-5.2: Homework Dashboard
**Priority:** P1

> As a parent, I want to see all homework in one place so nothing falls through the cracks.

**Acceptance Criteria:**
- [ ] Per-child view of assignments
- [ ] Sorted by due date
- [ ] Status: Not started, In progress, Completed, Missing
- [ ] Overdue items highlighted

### US-5.3: Grade Monitoring
**Priority:** P1

> As a parent, I want to track my children's grades so I can help if they're struggling.

**Acceptance Criteria:**
- [ ] Current grades by subject
- [ ] Trend indicators (up, down, stable)
- [ ] Alert when grade drops below threshold
- [ ] Missing assignment impact shown

### US-5.4: Study Plan Generation
**Priority:** P2

> As a parent, I want Hearth to create study plans so my kids know how to prepare.

**Acceptance Criteria:**
- [ ] Generate plan for upcoming test/exam
- [ ] Break into daily sessions
- [ ] Consider existing schedule
- [ ] Set reminders for study time

---

## Epic 6: Meal Planning

### US-6.1: Dinner Suggestion
**Priority:** P1

> As a parent, I want quick dinner suggestions when I ask "what's for dinner?"

**Acceptance Criteria:**
- [ ] Responds within 3 seconds
- [ ] Considers dietary restrictions
- [ ] Offers 2-3 specific options
- [ ] Includes prep time estimate

### US-6.2: Weekly Meal Plan
**Priority:** P2

> As a parent, I want to generate a weekly meal plan so I don't have to think about dinner every day.

**Acceptance Criteria:**
- [ ] 5-7 day plan generation
- [ ] Respects family preferences
- [ ] Balances variety and nutrition
- [ ] Can swap individual meals

### US-6.3: Grocery List
**Priority:** P2

> As a parent, I want a grocery list from my meal plan so shopping is easy.

**Acceptance Criteria:**
- [ ] Auto-generates from meal plan
- [ ] Organized by store section
- [ ] Shareable to Apple Reminders
- [ ] Can add manual items

---

## Epic 7: Family Coordination

### US-7.1: Family Announcement
**Priority:** P1

> As a parent, I want to send announcements to the family so everyone knows important information.

**Acceptance Criteria:**
- [ ] Compose message with priority level
- [ ] Select recipients
- [ ] Deliver via preferred channel (iMessage, notification)
- [ ] Track acknowledgments

### US-7.2: Chore Assignment
**Priority:** P2

> As a parent, I want to assign chores so household work is distributed fairly.

**Acceptance Criteria:**
- [ ] Create chore list with frequency
- [ ] Assign to family members
- [ ] Set reminders
- [ ] Track completion

---

## Epic 8: Proactive Intelligence

### US-8.1: Anticipatory Reminders
**Priority:** P1

> As a parent, I want Hearth to remind me of things before I think of them.

**Acceptance Criteria:**
- [ ] "Soccer tomorrow - is Emma's bag packed?"
- [ ] "Prescription refill due in 3 days"
- [ ] "Dad's birthday next week"
- [ ] Based on calendar and learned patterns

### US-8.2: Decision Simplification
**Priority:** P1

> As a parent, I want Hearth to propose specific options instead of asking open questions.

**Acceptance Criteria:**
- [ ] Always offers 2-3 concrete options
- [ ] Remembers preferences
- [ ] Gets smarter over time

### US-8.3: Evening Summary
**Priority:** P2

> As a parent, I want an evening summary so I can wind down and prepare for tomorrow.

**Acceptance Criteria:**
- [ ] Delivered at configurable time
- [ ] Summarizes what was accomplished
- [ ] Previews tomorrow
- [ ] Suggests prep for morning

---

## Epic 9: Settings & Privacy

### US-9.1: Settings Panel
**Priority:** P0

> As a user, I want a settings panel to configure Hearth to my preferences.

**Acceptance Criteria:**
- [ ] Family member management
- [ ] Notification preferences
- [ ] Connected services management
- [ ] Data export/deletion options

### US-9.2: Data Export
**Priority:** P1

> As a user, I want to export my data so I maintain control over my information.

**Acceptance Criteria:**
- [ ] Export all data as JSON/CSV
- [ ] Export elder care logs for doctor
- [ ] Clear and complete data package

### US-9.3: Data Deletion
**Priority:** P1

> As a user, I want to delete my data if I stop using Hearth.

**Acceptance Criteria:**
- [ ] Clear all local data option
- [ ] Confirmation required
- [ ] Verification data is gone
- [ ] Instructions for connected service cleanup

---

## Story Dependencies

```
US-1.1 (Menu Bar) → US-1.2 (Dashboard) → US-1.3 (Quick Actions)
       ↓
US-2.1 (Family) → US-4.1 (Elder) → US-4.2 (Calls)
       ↓
US-2.2 (Calendar) → US-3.1 (Briefing)
       ↓
US-5.1 (Classroom) → US-5.2 (Homework)
```

---

## MVP Story Set (Phase 1)

| ID | Story | Priority |
|----|-------|----------|
| US-1.1 | Menu Bar Presence | P0 |
| US-1.2 | Today Dashboard | P0 |
| US-1.3 | Quick Actions | P0 |
| US-2.1 | Family Profile Creation | P0 |
| US-2.2 | Calendar Integration | P0 |
| US-3.1 | Morning Briefing | P0 |
| US-9.1 | Settings Panel | P0 |

---

*Stories will be refined and estimated during sprint planning.*
