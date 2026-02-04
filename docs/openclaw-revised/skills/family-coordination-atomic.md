# Family Coordination Skill: Atomic Function Breakdown

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Production-Ready Implementation Guide
**Target Platform:** iOS 17.0+, Swift 5.10+

---

## Table of Contents

1. [Skill Overview](#1-skill-overview)
2. [User Stories](#2-user-stories)
3. [Atomic Functions](#3-atomic-functions)
4. [Deterministic Decision Tree](#4-deterministic-decision-tree)
5. [State Machine](#5-state-machine)
6. [Data Structures](#6-data-structures)
7. [Example Scenarios](#7-example-scenarios)
8. [API Integrations](#8-api-integrations)
9. [Test Cases](#9-test-cases)
10. [Error Handling](#10-error-handling)

---

## 1. Skill Overview

### Purpose
The Family Coordination skill provides shared calendar management, location awareness, broadcast messaging, chore assignment, and family check-ins. It reduces coordination friction by centralizing family scheduling and communication.

### Core Capabilities
- **Shared Calendar**: Unified view of all family member schedules with conflict detection
- **Announcements & Broadcasts**: Send messages to entire family or specific members
- **Location Tracking**: Real-time whereabouts with battery-aware updates
- **Chore Assignment**: Task delegation with gamification and point tracking
- **Check-ins & Whereabouts**: "Where is everyone?" status updates
- **Schedule Optimization**: Find common free time for family activities

### Design Principles
1. **Privacy First**: Location sharing opt-in per family member
2. **Battery Aware**: Intelligent location update intervals
3. **Conflict Prevention**: Proactive alerts before double-booking
4. **Positive Reinforcement**: Gamification for chores, not punishment
5. **Age-Appropriate**: Different UI/permissions for adults vs. children

---

## 2. User Stories

### Primary User: Lisa, 42-year-old coordinating parent

**Story 1: Calendar Conflict Detection**
```
As a parent managing multiple schedules
I want to know immediately if I create a conflict
So that I don't double-book family members

Acceptance Criteria:
- Alert shows before confirming new event
- Suggests alternative times
- Shows conflicting event details
- Allows override with confirmation
```

**Story 2: Broadcast Message**
```
As a parent at the grocery store
I want to ask "does anyone need anything?"
So that I don't forget items

Acceptance Criteria:
- Message delivers to all family members
- Shows delivery/read status
- Replies collected in thread
- Optional notification sound
```

**Story 3: Location Check**
```
As a parent wondering where everyone is
I want to ask "where is everyone?"
So that I know my family is safe

Acceptance Criteria:
- Shows last known location for each member
- Shows battery level
- Shows timestamp of last update
- Respects privacy settings
```

**Story 4: Chore Assignment**
```
As a parent managing household tasks
I want to assign chores with point rewards
So that kids are motivated to complete them

Acceptance Criteria:
- Assigns task to specific family member
- Sets due date and point value
- Sends notification
- Tracks completion status
```

**Story 5: Find Common Free Time**
```
As a parent planning a family outing
I want to find when everyone is free
So that we can schedule together time

Acceptance Criteria:
- Analyzes all family calendars
- Suggests 3-5 time slots
- Accounts for minimum duration
- Excludes sleep/work hours
```

---

## 3. Atomic Functions

All functions are pure, testable, and composable. Each has a single responsibility.

### 3.1 Calendar Management

#### `getFamilyCalendar(familyId: UUID, startDate: Date, endDate: Date) async throws -> [CalendarEvent]`
Retrieves all calendar events for family members within date range.

**Parameters:**
- `familyId`: Unique identifier for family
- `startDate`: Start of date range
- `endDate`: End of date range

**Returns:** Array of calendar events across all family members

**Errors:**
- `FamilyCoordinationError.familyNotFound`
- `FamilyCoordinationError.calendarAccessDenied`

**Swift Signature:**
```swift
func getFamilyCalendar(
    familyId: UUID,
    startDate: Date,
    endDate: Date
) async throws -> [CalendarEvent]
```

---

#### `getMemberCalendar(memberId: UUID, startDate: Date, endDate: Date) async throws -> [CalendarEvent]`
Retrieves calendar events for specific family member.

**Parameters:**
- `memberId`: Unique identifier for family member
- `startDate`: Start of date range
- `endDate`: End of date range

**Returns:** Array of calendar events for member

**Swift Signature:**
```swift
func getMemberCalendar(
    memberId: UUID,
    startDate: Date,
    endDate: Date
) async throws -> [CalendarEvent]
```

---

#### `detectCalendarConflicts(newEvent: CalendarEvent, existingEvents: [CalendarEvent]) -> [CalendarConflict]`
Detects scheduling conflicts for a proposed event (pure function).

**Parameters:**
- `newEvent`: Proposed calendar event
- `existingEvents`: Current calendar events

**Returns:** Array of detected conflicts

**Decision Logic:**
- Conflicts if events overlap by any time period
- Same-member conflicts are high priority
- Travel time conflicts (back-to-back with different locations)
- Family event conflicts (multiple members needed)

**Swift Signature:**
```swift
func detectCalendarConflicts(
    newEvent: CalendarEvent,
    existingEvents: [CalendarEvent]
) -> [CalendarConflict]
```

---

#### `createCalendarEvent(familyId: UUID, event: CalendarEvent) async throws -> CalendarEvent`
Creates new calendar event with conflict checking.

**Parameters:**
- `familyId`: Unique identifier for family
- `event`: Event to create

**Returns:** Created event with assigned ID

**Errors:**
- `FamilyCoordinationError.conflictDetected`
- `FamilyCoordinationError.invalidEvent`

**Swift Signature:**
```swift
func createCalendarEvent(
    familyId: UUID,
    event: CalendarEvent
) async throws -> CalendarEvent
```

---

#### `updateCalendarEvent(familyId: UUID, eventId: UUID, updates: CalendarEventUpdate) async throws -> CalendarEvent`
Updates existing calendar event.

**Parameters:**
- `familyId`: Unique identifier for family
- `eventId`: Event to update
- `updates`: Changes to apply

**Returns:** Updated event

**Swift Signature:**
```swift
func updateCalendarEvent(
    familyId: UUID,
    eventId: UUID,
    updates: CalendarEventUpdate
) async throws -> CalendarEvent
```

---

#### `deleteCalendarEvent(familyId: UUID, eventId: UUID) async throws -> Bool`
Deletes calendar event.

**Parameters:**
- `familyId`: Unique identifier for family
- `eventId`: Event to delete

**Returns:** `true` if successful

**Swift Signature:**
```swift
func deleteCalendarEvent(
    familyId: UUID,
    eventId: UUID
) async throws -> Bool
```

---

#### `findCommonFreeTime(familyId: UUID, memberIds: [UUID], minDuration: Int, searchWindow: DateInterval) async throws -> [TimeSlot]`
Finds time slots when specified family members are all free.

**Parameters:**
- `familyId`: Unique identifier for family
- `memberIds`: Members who must be available
- `minDuration`: Minimum duration in minutes
- `searchWindow`: Date range to search within

**Returns:** Array of available time slots, ranked by desirability

**Decision Logic:**
1. Load calendars for all specified members
2. Find gaps between events
3. Filter gaps >= minDuration
4. Exclude sleep hours (10pm-7am)
5. Exclude work hours for adults (9am-5pm weekdays)
6. Rank: weekends > evenings > mornings

**Swift Signature:**
```swift
func findCommonFreeTime(
    familyId: UUID,
    memberIds: [UUID],
    minDuration: Int,
    searchWindow: DateInterval
) async throws -> [TimeSlot]
```

---

#### `syncWithGoogleCalendar(memberId: UUID) async throws -> SyncResult`
Syncs family member calendar with Google Calendar.

**Parameters:**
- `memberId`: Family member to sync

**Returns:** Sync result with added/updated/deleted counts

**External API:** Google Calendar API

**Swift Signature:**
```swift
func syncWithGoogleCalendar(memberId: UUID) async throws -> SyncResult
```

---

### 3.2 Announcements & Broadcasting

#### `sendBroadcast(familyId: UUID, message: BroadcastMessage) async throws -> BroadcastResult`
Sends message to all or selected family members.

**Parameters:**
- `familyId`: Unique identifier for family
- `message`: Message to broadcast

**Returns:** Broadcast result with delivery status per recipient

**Swift Signature:**
```swift
func sendBroadcast(
    familyId: UUID,
    message: BroadcastMessage
) async throws -> BroadcastResult
```

---

#### `sendDirectMessage(fromMemberId: UUID, toMemberId: UUID, message: String) async throws -> Message`
Sends direct message between family members.

**Parameters:**
- `fromMemberId`: Sender
- `toMemberId`: Recipient
- `message`: Message text

**Returns:** Created message object

**Swift Signature:**
```swift
func sendDirectMessage(
    fromMemberId: UUID,
    toMemberId: UUID,
    message: String
) async throws -> Message
```

---

#### `getBroadcastHistory(familyId: UUID, limit: Int) async throws -> [BroadcastMessage]`
Retrieves recent broadcast messages.

**Parameters:**
- `familyId`: Unique identifier for family
- `limit`: Maximum number of messages to retrieve

**Returns:** Array of recent broadcasts

**Swift Signature:**
```swift
func getBroadcastHistory(
    familyId: UUID,
    limit: Int
) async throws -> [BroadcastMessage]
```

---

#### `markMessageRead(messageId: UUID, memberId: UUID) async throws -> Bool`
Marks message as read by member.

**Parameters:**
- `messageId`: Message to mark
- `memberId`: Member who read it

**Returns:** `true` if successful

**Swift Signature:**
```swift
func markMessageRead(
    messageId: UUID,
    memberId: UUID
) async throws -> Bool
```

---

### 3.3 Location Tracking

#### `getMemberLocation(memberId: UUID) async throws -> MemberLocation?`
Retrieves last known location for family member.

**Parameters:**
- `memberId`: Family member to locate

**Returns:** Location data or nil if unavailable

**Privacy:** Returns nil if member has disabled location sharing

**Swift Signature:**
```swift
func getMemberLocation(memberId: UUID) async throws -> MemberLocation?
```

---

#### `getAllMemberLocations(familyId: UUID) async throws -> [UUID: MemberLocation]`
Retrieves locations for all family members.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** Dictionary mapping member IDs to locations

**Swift Signature:**
```swift
func getAllMemberLocations(
    familyId: UUID
) async throws -> [UUID: MemberLocation]
```

---

#### `updateMemberLocation(memberId: UUID, location: CLLocation) async throws -> Bool`
Updates location for family member.

**Parameters:**
- `memberId`: Family member
- `location`: New location

**Returns:** `true` if successful

**Decision Logic:**
- Only update if > 100m from last location OR > 15 minutes elapsed
- Don't update if battery < 20% (preserve battery)
- Store timestamp and battery level with location

**Swift Signature:**
```swift
func updateMemberLocation(
    memberId: UUID,
    location: CLLocation
) async throws -> Bool
```

---

#### `setLocationSharingPreference(memberId: UUID, enabled: Bool, visibleTo: [UUID]) async throws -> Bool`
Configures location sharing settings.

**Parameters:**
- `memberId`: Family member
- `enabled`: Whether to share location
- `visibleTo`: Array of member IDs who can see location (empty = all family)

**Returns:** `true` if successful

**Swift Signature:**
```swift
func setLocationSharingPreference(
    memberId: UUID,
    enabled: Bool,
    visibleTo: [UUID]
) async throws -> Bool
```

---

#### `checkIfMemberAtLocation(memberId: UUID, targetLocation: SavedLocation, radiusMeters: Double) async throws -> Bool`
Checks if member is currently at a saved location.

**Parameters:**
- `memberId`: Family member
- `targetLocation`: Saved location (home, school, work, etc.)
- `radiusMeters`: Geofence radius

**Returns:** `true` if member is within radius

**Swift Signature:**
```swift
func checkIfMemberAtLocation(
    memberId: UUID,
    targetLocation: SavedLocation,
    radiusMeters: Double
) async throws -> Bool
```

---

### 3.4 Chore Management

#### `createChore(familyId: UUID, chore: ChoreTask) async throws -> ChoreTask`
Creates new chore assignment.

**Parameters:**
- `familyId`: Unique identifier for family
- `chore`: Chore details

**Returns:** Created chore with ID

**Swift Signature:**
```swift
func createChore(
    familyId: UUID,
    chore: ChoreTask
) async throws -> ChoreTask
```

---

#### `assignChore(choreId: UUID, assignedTo: UUID) async throws -> Bool`
Assigns chore to family member.

**Parameters:**
- `choreId`: Chore to assign
- `assignedTo`: Family member ID

**Returns:** `true` if successful

**Side Effects:**
- Sends push notification to assignee
- Adds to member's task list

**Swift Signature:**
```swift
func assignChore(
    choreId: UUID,
    assignedTo: UUID
) async throws -> Bool
```

---

#### `completeChore(choreId: UUID, completedBy: UUID, verificationPhoto: UIImage?) async throws -> ChoreCompletion`
Marks chore as completed.

**Parameters:**
- `choreId`: Chore being completed
- `completedBy`: Family member who completed it
- `verificationPhoto`: Optional photo proof

**Returns:** Completion record with points awarded

**Decision Logic:**
- Award full points if completed by due date
- Award 50% points if completed within 24 hours late
- No points if > 24 hours late
- Optional: require parent verification for high-value chores

**Swift Signature:**
```swift
func completeChore(
    choreId: UUID,
    completedBy: UUID,
    verificationPhoto: UIImage?
) async throws -> ChoreCompletion
```

---

#### `verifyChoreCompletion(choreId: UUID, verifiedBy: UUID, approved: Bool) async throws -> Bool`
Parent verifies child's chore completion.

**Parameters:**
- `choreId`: Chore to verify
- `verifiedBy`: Parent member ID
- `approved`: Whether completion is approved

**Returns:** `true` if successful

**Swift Signature:**
```swift
func verifyChoreCompletion(
    choreId: UUID,
    verifiedBy: UUID,
    approved: Bool
) async throws -> Bool
```

---

#### `getChoreList(familyId: UUID, filters: ChoreFilters?) async throws -> [ChoreTask]`
Retrieves chore list with optional filters.

**Parameters:**
- `familyId`: Unique identifier for family
- `filters`: Optional filters (assignedTo, status, dueDate)

**Returns:** Array of matching chores

**Swift Signature:**
```swift
func getChoreList(
    familyId: UUID,
    filters: ChoreFilters?
) async throws -> [ChoreTask]
```

---

#### `getMemberPoints(memberId: UUID) async throws -> PointsSummary`
Gets gamification points for member.

**Parameters:**
- `memberId`: Family member

**Returns:** Points summary with total, weekly, and achievements

**Swift Signature:**
```swift
func getMemberPoints(memberId: UUID) async throws -> PointsSummary
```

---

#### `redeemPoints(memberId: UUID, reward: ChoreReward, pointsSpent: Int) async throws -> RedemptionResult`
Allows member to redeem points for rewards.

**Parameters:**
- `memberId`: Family member redeeming
- `reward`: Reward being claimed
- `pointsSpent`: Points to deduct

**Returns:** Redemption result

**Errors:**
- `FamilyCoordinationError.insufficientPoints`

**Swift Signature:**
```swift
func redeemPoints(
    memberId: UUID,
    reward: ChoreReward,
    pointsSpent: Int
) async throws -> RedemptionResult
```

---

#### `createChoreTemplate(familyId: UUID, template: ChoreTemplate) async throws -> ChoreTemplate`
Creates reusable chore template.

**Parameters:**
- `familyId`: Unique identifier for family
- `template`: Template details

**Returns:** Created template

**Examples:**
- "Take out trash" (weekly, 10 points)
- "Clean room" (weekly, 15 points)
- "Do dishes" (daily, 5 points)

**Swift Signature:**
```swift
func createChoreTemplate(
    familyId: UUID,
    template: ChoreTemplate
) async throws -> ChoreTemplate
```

---

### 3.5 Check-ins & Whereabouts

#### `getFamilyStatus(familyId: UUID) async throws -> FamilyStatus`
Gets real-time status of all family members.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** Family status with location, activity, battery for each member

**Swift Signature:**
```swift
func getFamilyStatus(familyId: UUID) async throws -> FamilyStatus
```

---

#### `requestCheckIn(fromMemberId: UUID, toMemberId: UUID, message: String?) async throws -> CheckInRequest`
Sends check-in request to family member.

**Parameters:**
- `fromMemberId`: Requester
- `toMemberId`: Member to check in
- `message`: Optional custom message

**Returns:** Check-in request record

**Example:** "Where are you?" "On my way home?"

**Swift Signature:**
```swift
func requestCheckIn(
    fromMemberId: UUID,
    toMemberId: UUID,
    message: String?
) async throws -> CheckInRequest
```

---

#### `respondToCheckIn(requestId: UUID, response: CheckInResponse) async throws -> Bool`
Responds to check-in request.

**Parameters:**
- `requestId`: Check-in request
- `response`: Response data (location, status, ETA)

**Returns:** `true` if successful

**Swift Signature:**
```swift
func respondToCheckIn(
    requestId: UUID,
    response: CheckInResponse
) async throws -> Bool
```

---

#### `setMemberStatus(memberId: UUID, status: MemberStatus) async throws -> Bool`
Updates member's current activity status.

**Parameters:**
- `memberId`: Family member
- `status`: Current status (at work, at school, driving, etc.)

**Returns:** `true` if successful

**Swift Signature:**
```swift
func setMemberStatus(
    memberId: UUID,
    status: MemberStatus
) async throws -> Bool
```

---

#### `enableAutomaticCheckIns(memberId: UUID, triggers: [CheckInTrigger]) async throws -> Bool`
Configures automatic check-ins based on location/time triggers.

**Parameters:**
- `memberId`: Family member
- `triggers`: Array of automatic check-in triggers

**Returns:** `true` if successful

**Examples:**
- "Check in when I arrive at school"
- "Check in when I leave work"
- "Check in at 10pm if not home"

**Swift Signature:**
```swift
func enableAutomaticCheckIns(
    memberId: UUID,
    triggers: [CheckInTrigger]
) async throws -> Bool
```

---

### 3.6 Utility Functions

#### `calculateTravelTime(from: CLLocation, to: CLLocation, mode: TravelMode) async throws -> TravelTimeEstimate`
Estimates travel time between locations.

**Parameters:**
- `from`: Starting location
- `to`: Destination
- `mode`: Travel mode (driving, walking, transit)

**Returns:** Travel time estimate with traffic

**External API:** Apple Maps / Google Maps

**Swift Signature:**
```swift
func calculateTravelTime(
    from: CLLocation,
    to: CLLocation,
    mode: TravelMode
) async throws -> TravelTimeEstimate
```

---

#### `formatTimeSlot(slot: TimeSlot) -> String`
Formats time slot for display (pure function).

**Parameters:**
- `slot`: Time slot to format

**Returns:** Human-readable string

**Example Output:**
- "Saturday, Feb 3 from 2:00 PM to 4:00 PM"
- "Tomorrow evening (7-9 PM)"

**Swift Signature:**
```swift
func formatTimeSlot(slot: TimeSlot) -> String
```

---

#### `suggestEventDuration(eventType: EventType) -> Int`
Suggests typical duration for event type (pure function).

**Parameters:**
- `eventType`: Type of event

**Returns:** Suggested duration in minutes

**Examples:**
- Doctor appointment: 60 minutes
- Soccer practice: 90 minutes
- Parent-teacher conference: 30 minutes

**Swift Signature:**
```swift
func suggestEventDuration(eventType: EventType) -> Int
```

---

## 4. Deterministic Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│     User Request: Family Coordination Intent Detected       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │ Parse Intent & Extract │
            │ Parameters             │
            └────────┬───────────────┘
                     │
        ┌────────────┼────────────┬────────────┬────────────┐
        │            │            │            │            │
        ▼            ▼            ▼            ▼            ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│Calendar  │ │Broadcast │ │Location  │ │Chores    │ │Check-in  │
│Intent    │ │Intent    │ │Intent    │ │Intent    │ │Intent    │
└─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘
      │            │            │            │            │
      ▼            ▼            ▼            ▼            ▼

┌──────────────────────────────────────────────────────────────┐
│                    CALENDAR FLOW                             │
│                                                              │
│ Check Intent Type:                                           │
│   ├─ "Add event" → CREATE_EVENT_FLOW                        │
│   ├─ "Find free time" → FIND_FREE_TIME_FLOW                 │
│   ├─ "Show calendar" → DISPLAY_CALENDAR_FLOW                │
│   └─ "Check conflicts" → CONFLICT_CHECK_FLOW                │
│                                                              │
│ CREATE_EVENT_FLOW:                                           │
│   1. Extract event details (title, date, time, attendees)   │
│   2. Load family calendars for specified members             │
│   3. Run conflict detection algorithm                        │
│   4. IF conflicts detected:                                  │
│      - Show conflict details                                 │
│      - Suggest alternative times                             │
│      - Ask: "Proceed anyway?" or "Choose new time?"         │
│   5. IF no conflicts OR user approves:                       │
│      - Create event                                          │
│      - Sync to Google Calendar (if enabled)                  │
│      - Send notifications to attendees                       │
│   6. Return confirmation                                     │
│                                                              │
│ FIND_FREE_TIME_FLOW:                                         │
│   1. Extract: who needs to attend, min duration              │
│   2. Default search window: next 14 days                     │
│   3. Load calendars for all attendees                        │
│   4. Algorithm: findCommonFreeTime()                         │
│      - Merge all calendars into timeline                     │
│      - Identify gaps between events                          │
│      - Filter: gap >= minDuration                            │
│      - Exclude: sleep hours (10pm-7am)                       │
│      - Exclude: work hours for adults (9am-5pm weekdays)    │
│      - Rank slots by desirability:                           │
│        * Score +10: Weekend                                  │
│        * Score +5: Evening (6-9pm)                           │
│        * Score +3: Weekend morning (9am-12pm)                │
│        * Score +0: Weekday evening                           │
│   5. Return top 5 time slots with scores                     │
│   6. Allow user to select or search different window         │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    BROADCAST FLOW                            │
│                                                              │
│ Check Broadcast Type:                                        │
│   ├─ General announcement → ALL_MEMBERS                      │
│   ├─ Specific question → REQUIRES_RESPONSE                   │
│   └─ Direct message → SINGLE_RECIPIENT                       │
│                                                              │
│ BROADCAST_ALGORITHM:                                         │
│   1. Validate sender has permission                          │
│   2. Determine recipient list:                               │
│      - "Everyone" → all family members except sender         │
│      - "Kids" → members with role=child                      │
│      - "Adults" → members with role=adult                    │
│      - Named members → specific IDs                          │
│   3. Create broadcast message record                         │
│   4. FOR each recipient:                                     │
│      - Create notification                                   │
│      - Send push notification                                │
│      - Mark as "delivered"                                   │
│   5. Track delivery status                                   │
│   6. IF requires_response:                                   │
│      - Set response deadline (default: 1 hour)               │
│      - Collect responses as they arrive                      │
│      - Notify sender of responses                            │
│   7. Return broadcast ID and delivery status                 │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    LOCATION FLOW                             │
│                                                              │
│ Check Location Intent:                                       │
│   ├─ "Where is [member]?" → GET_SINGLE_LOCATION             │
│   ├─ "Where is everyone?" → GET_ALL_LOCATIONS               │
│   └─ "Is [member] at [place]?" → CHECK_AT_LOCATION          │
│                                                              │
│ GET_ALL_LOCATIONS_FLOW:                                      │
│   1. Load family members                                     │
│   2. FOR each member:                                        │
│      - Check location sharing enabled                        │
│      - Check requester has permission to view                │
│      - IF permitted:                                         │
│        * Retrieve last known location                        │
│        * Calculate time since last update                    │
│        * Retrieve battery level                              │
│        * Determine current status (at home, at work, etc.)   │
│      - ELSE:                                                 │
│        * Return "Location sharing disabled"                  │
│   3. Format results:                                         │
│      - At home: "Sarah is at home (updated 5 min ago)"      │
│      - At saved location: "Emma is at school"                │
│      - Unknown location: "Mike at 123 Main St (2 hours ago)" │
│      - Privacy: "Location sharing disabled"                  │
│   4. Return formatted status for all members                 │
│                                                              │
│ LOCATION_UPDATE_ALGORITHM (Background):                      │
│   1. Device monitors location changes                        │
│   2. Trigger update IF:                                      │
│      - Distance from last update > 100 meters                │
│      - Time since last update > 15 minutes                   │
│      - Entered/exited geofence (home, school, work)         │
│   3. Battery preservation:                                   │
│      - IF battery < 20%: increase interval to 30 min         │
│      - IF battery < 10%: stop automatic updates              │
│   4. Update server with new location + timestamp + battery   │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    CHORE FLOW                                │
│                                                              │
│ Check Chore Intent:                                          │
│   ├─ "Assign chore" → CREATE_AND_ASSIGN                     │
│   ├─ "Mark complete" → COMPLETE_CHORE                       │
│   ├─ "My chores" → LIST_CHORES                              │
│   └─ "Points balance" → GET_POINTS                          │
│                                                              │
│ CREATE_AND_ASSIGN_FLOW:                                      │
│   1. Extract chore details:                                  │
│      - Task name                                             │
│      - Assigned to (member)                                  │
│      - Due date                                              │
│      - Point value (default by difficulty)                   │
│   2. Check if chore template exists:                         │
│      - "Take out trash" → 10 points, weekly                  │
│      - "Clean room" → 15 points, weekly                      │
│      - "Do dishes" → 5 points, daily                         │
│   3. Create chore task record                                │
│   4. Assign to member                                        │
│   5. Send notification to assignee                           │
│   6. Add to family chore board                               │
│   7. Return confirmation                                     │
│                                                              │
│ COMPLETE_CHORE_FLOW:                                         │
│   1. Verify assignee is completing their own chore           │
│   2. Optional: request verification photo                    │
│   3. Calculate points:                                       │
│      - IF completed by due date: full points                 │
│      - IF completed within 24h late: 50% points              │
│      - IF > 24h late: no points                              │
│   4. IF chore requires verification:                         │
│      - Mark as "pending verification"                        │
│      - Notify parent                                         │
│      - WAIT for parent approval                              │
│   5. ELSE:                                                   │
│      - Mark as completed                                     │
│      - Award points                                          │
│      - Update member's point balance                         │
│      - Send congratulations notification                     │
│   6. Return completion record                                │
│                                                              │
│ POINTS_ALGORITHM:                                            │
│   Task Difficulty → Point Value:                             │
│   - Easy (5-10 min): 5 points                                │
│   - Medium (10-30 min): 10-15 points                         │
│   - Hard (30+ min): 20-30 points                             │
│                                                              │
│   Bonus multipliers:                                         │
│   - Completed early: +25%                                    │
│   - Perfect week (all chores): +50 bonus                     │
│   - First completion: +10 bonus                              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    CHECK-IN FLOW                             │
│                                                              │
│ Check Check-in Type:                                         │
│   ├─ Automatic (geofence trigger)                           │
│   ├─ Manual request from parent                              │
│   └─ Scheduled check-in                                      │
│                                                              │
│ AUTOMATIC_CHECK_IN:                                          │
│   1. Geofence trigger detected (arrived/departed location)   │
│   2. Create automatic check-in:                              │
│      - "Emma arrived at school" (7:45 AM)                    │
│      - "Mike left work" (5:30 PM)                            │
│   3. Notify family members (based on preferences)            │
│   4. Log check-in event                                      │
│                                                              │
│ MANUAL_CHECK_IN_REQUEST:                                     │
│   1. Parent sends check-in request to child                  │
│   2. Child receives notification                             │
│   3. Child can respond with:                                 │
│      - Quick reply ("I'm fine", "On my way", etc.)          │
│      - Current location share                                │
│      - ETA estimate                                          │
│   4. Parent receives response                                │
│   5. IF no response after 15 minutes:                        │
│      - Send reminder notification                            │
│      - Escalate urgency indicator                            │
│                                                              │
│ SAFETY_CHECK_ALGORITHM:                                      │
│   1. IF member is child AND not at home:                     │
│   2. IF time > 9:00 PM AND school night:                     │
│      - Send automatic check-in request                       │
│      - IF no response after 30 minutes:                      │
│        * Alert parents                                       │
│        * Show last known location                            │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. State Machine

### States

```
┌─────────────┐
│    IDLE     │ ◄─────────────────────┐
└──────┬──────┘                       │
       │                              │
       │ User: Coordination request   │
       ▼                              │
┌─────────────────────┐               │
│ PARSING_INTENT      │               │
│ - Determine action  │               │
│ - Extract params    │               │
└──────┬──────────────┘               │
       │                              │
       ├─────┬─────┬─────┬─────┐     │
       │     │     │     │     │     │
       ▼     ▼     ▼     ▼     ▼     │
    ┌────┐┌────┐┌────┐┌────┐┌────┐  │
    │Cal ││Msg ││Loc ││Chr ││Chk │  │
    │    ││    ││    ││    ││    │  │
    └─┬──┘└─┬──┘└─┬──┘└─┬──┘└─┬──┘  │
      │     │     │     │     │     │
      ▼     ▼     ▼     ▼     ▼     │
┌─────────────────────┐              │
│ LOADING_CONTEXT     │              │
│ - Load family data  │              │
│ - Check permissions │              │
│ - Validate access   │              │
└──────┬──────────────┘              │
       │                             │
       ▼                             │
┌─────────────────────┐              │
│ EXECUTING_ACTION    │              │
│ - Run workflow      │              │
│ - Call APIs         │              │
│ - Update database   │              │
└──────┬──────────────┘              │
       │                             │
       │ [Needs Confirmation]        │
       ▼                             │
┌─────────────────────┐              │
│ AWAITING_APPROVAL   │              │
│ - Show conflict     │              │
│ - Request decision  │              │
└──────┬──────┬───────┘              │
       │      │                      │
  [OK] │      │ [Cancel]             │
       │      └──────────────────────┤
       ▼                             │
┌─────────────────────┐              │
│ FINALIZING          │              │
│ - Commit changes    │              │
│ - Send notifications│              │
│ - Sync external APIs│              │
└──────┬──────────────┘              │
       │                             │
       │ [Complete]                  │
       ▼                             │
┌─────────────────────┐              │
│ RESULT_READY        │              │
│ - Return response   │              │
│ - Update UI         │              │
└──────┬──────────────┘              │
       │                             │
       └─────────────────────────────┘
```

### State Transitions (Swift Enum)

```swift
enum CoordinationState: Equatable {
    case idle
    case parsingIntent(userMessage: String)
    case loadingContext(familyId: UUID, action: CoordinationAction)
    case executingAction(action: CoordinationAction)
    case awaitingApproval(decision: PendingDecision)
    case finalizing(action: CoordinationAction)
    case resultReady(result: CoordinationResult)
    case error(FamilyCoordinationError)
}

enum CoordinationAction {
    case calendarCreate(event: CalendarEvent)
    case calendarFindFreeTime(memberIds: [UUID], minDuration: Int)
    case sendBroadcast(message: BroadcastMessage)
    case getLocations(familyId: UUID)
    case assignChore(chore: ChoreTask, assignedTo: UUID)
    case completeChore(choreId: UUID, memberId: UUID)
    case requestCheckIn(fromMemberId: UUID, toMemberId: UUID)
}

struct PendingDecision {
    let type: DecisionType
    let context: [String: Any]
    let options: [DecisionOption]
}

enum DecisionType {
    case calendarConflict
    case locationPermission
    case choreVerification
}
```

---

## 6. Data Structures

### Core Models

```swift
// MARK: - Calendar

struct CalendarEvent: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var location: String?
    var attendees: [UUID] // Family member IDs
    var organizer: UUID
    var isAllDay: Bool
    var recurrence: RecurrenceRule?
    var reminders: [EventReminder]
    var color: EventColor
    var source: CalendarSource
    var externalId: String? // Google Calendar ID
    var createdAt: Date
    var updatedAt: Date

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

enum CalendarSource: String, Codable {
    case openClaw
    case googleCalendar
    case appleCalendar
    case manual
}

enum EventColor: String, Codable {
    case red, blue, green, yellow, purple, orange, pink
}

struct RecurrenceRule: Codable {
    var frequency: RecurrenceFrequency
    var interval: Int // e.g., every 2 weeks
    var endDate: Date?
    var occurrences: Int?
}

enum RecurrenceFrequency: String, Codable {
    case daily, weekly, monthly, yearly
}

struct EventReminder: Codable, Identifiable {
    let id: UUID
    var minutesBefore: Int
    var method: ReminderMethod
}

enum ReminderMethod: String, Codable {
    case notification, email, sms
}

struct CalendarConflict: Codable, Identifiable {
    let id: UUID
    var newEvent: CalendarEvent
    var conflictingEvent: CalendarEvent
    var conflictType: ConflictType
    var affectedMembers: [UUID]
    var severity: ConflictSeverity
    var suggestedAlternatives: [TimeSlot]
}

enum ConflictType: String, Codable {
    case directOverlap // Same member, overlapping times
    case travelTime // Back-to-back events at different locations
    case familyEvent // Multiple members needed
}

enum ConflictSeverity: String, Codable {
    case low, medium, high, critical
}

struct TimeSlot: Codable, Identifiable {
    let id: UUID
    var startTime: Date
    var endTime: Date
    var score: Int // Desirability score
    var reason: String // Why this slot is good

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

struct CalendarEventUpdate: Codable {
    var title: String?
    var description: String?
    var startTime: Date?
    var endTime: Date?
    var location: String?
    var attendees: [UUID]?
}

struct SyncResult: Codable {
    var added: Int
    var updated: Int
    var deleted: Int
    var errors: [SyncError]
    var lastSyncTime: Date
}

struct SyncError: Codable {
    var eventId: String
    var errorMessage: String
}

// MARK: - Messaging

struct BroadcastMessage: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var senderId: UUID
    var recipients: [UUID] // Empty = all family
    var subject: String?
    var body: String
    var requiresResponse: Bool
    var responseDeadline: Date?
    var priority: MessagePriority
    var sentAt: Date
    var deliveryStatus: [UUID: DeliveryStatus]
    var responses: [MessageResponse]
}

enum MessagePriority: String, Codable {
    case low, normal, high, urgent
}

enum DeliveryStatus: String, Codable {
    case pending, delivered, read, failed
}

struct MessageResponse: Codable, Identifiable {
    let id: UUID
    var responderId: UUID
    var responseText: String
    var respondedAt: Date
}

struct Message: Codable, Identifiable {
    let id: UUID
    var fromMemberId: UUID
    var toMemberId: UUID
    var text: String
    var sentAt: Date
    var readAt: Date?
    var isRead: Bool {
        readAt != nil
    }
}

struct BroadcastResult: Codable {
    var messageId: UUID
    var deliveryStatus: [UUID: DeliveryStatus]
    var failedRecipients: [UUID]
    var successCount: Int
    var failureCount: Int
}

// MARK: - Location

struct MemberLocation: Codable {
    var memberId: UUID
    var coordinate: Coordinate
    var accuracy: Double // meters
    var timestamp: Date
    var batteryLevel: Int? // 0-100
    var status: MemberStatus
    var nearestSavedLocation: SavedLocation?
    var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour
    }
}

struct Coordinate: Codable {
    var latitude: Double
    var longitude: Double
}

struct SavedLocation: Codable, Identifiable {
    let id: UUID
    var name: String
    var address: String?
    var coordinate: Coordinate
    var radius: Double // meters
    var category: LocationCategory
    var associatedMembers: [UUID]
}

enum LocationCategory: String, Codable {
    case home, work, school, other
}

enum MemberStatus: String, Codable {
    case atHome = "At home"
    case atWork = "At work"
    case atSchool = "At school"
    case driving = "Driving"
    case unknown = "Unknown"
}

struct LocationSharingPreference: Codable {
    var memberId: UUID
    var enabled: Bool
    var visibleTo: [UUID] // Empty = all family
    var shareMode: LocationShareMode
}

enum LocationShareMode: String, Codable {
    case always
    case whileUsingApp
    case never
}

// MARK: - Chores

struct ChoreTask: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var title: String
    var description: String?
    var assignedTo: UUID?
    var createdBy: UUID
    var dueDate: Date
    var pointValue: Int
    var difficulty: ChoreDifficulty
    var status: ChoreStatus
    var requiresVerification: Bool
    var verifiedBy: UUID?
    var verifiedAt: Date?
    var completedBy: UUID?
    var completedAt: Date?
    var verificationPhoto: String? // URL
    var recurrence: RecurrenceRule?
    var category: ChoreCategory
    var createdAt: Date
}

enum ChoreStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case verified
    case rejected
    case overdue
}

enum ChoreDifficulty: String, Codable {
    case easy, medium, hard

    var defaultPoints: Int {
        switch self {
        case .easy: return 5
        case .medium: return 10
        case .hard: return 20
        }
    }
}

enum ChoreCategory: String, Codable {
    case cleaning, dishes, laundry, trash, yard, pets, other
}

struct ChoreCompletion: Codable {
    var choreId: UUID
    var completedBy: UUID
    var completedAt: Date
    var pointsAwarded: Int
    var wasOnTime: Bool
    var verificationRequired: Bool
}

struct ChoreFilters: Codable {
    var assignedTo: UUID?
    var status: ChoreStatus?
    var dueBefore: Date?
    var dueAfter: Date?
    var category: ChoreCategory?
}

struct PointsSummary: Codable {
    var memberId: UUID
    var totalPoints: Int
    var weeklyPoints: Int
    var monthlyPoints: Int
    var achievements: [Achievement]
    var rank: Int // Among family members
}

struct Achievement: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var unlockedAt: Date
}

struct ChoreReward: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var pointCost: Int
    var category: RewardCategory
    var isActive: Bool
}

enum RewardCategory: String, Codable {
    case screenTime = "Extra Screen Time"
    case money = "Cash Reward"
    case privilege = "Special Privilege"
    case treat = "Treat"
}

struct RedemptionResult: Codable {
    var rewardId: UUID
    var memberId: UUID
    var pointsSpent: Int
    var remainingPoints: Int
    var redeemedAt: Date
}

struct ChoreTemplate: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var pointValue: Int
    var difficulty: ChoreDifficulty
    var category: ChoreCategory
    var estimatedMinutes: Int
    var recurrence: RecurrenceRule?
}

// MARK: - Check-ins

struct FamilyStatus: Codable {
    var familyId: UUID
    var members: [MemberStatusDetail]
    var lastUpdated: Date
}

struct MemberStatusDetail: Codable {
    var memberId: UUID
    var name: String
    var location: MemberLocation?
    var status: MemberStatus
    var batteryLevel: Int?
    var lastCheckIn: Date?
}

struct CheckInRequest: Codable, Identifiable {
    let id: UUID
    var fromMemberId: UUID
    var toMemberId: UUID
    var message: String?
    var requestedAt: Date
    var respondedAt: Date?
    var response: CheckInResponse?
    var status: CheckInStatus
}

enum CheckInStatus: String, Codable {
    case pending, responded, expired, cancelled
}

struct CheckInResponse: Codable {
    var location: MemberLocation?
    var statusMessage: String
    var eta: Date?
}

struct CheckInTrigger: Codable, Identifiable {
    let id: UUID
    var memberId: UUID
    var triggerType: TriggerType
    var location: SavedLocation?
    var time: Date?
    var isActive: Bool
}

enum TriggerType: String, Codable {
    case arriveAt, departFrom, scheduledTime, batteryLow
}

// MARK: - Travel

enum TravelMode: String, Codable {
    case driving, walking, transit, cycling
}

struct TravelTimeEstimate: Codable {
    var duration: TimeInterval
    var durationInTraffic: TimeInterval?
    var distance: Double // meters
    var route: String?
}

// MARK: - Event Types

enum EventType: String, Codable {
    case doctorAppointment
    case soccerPractice
    case parentTeacherConference
    case dentistAppointment
    case musicLesson
    case playdate
    case familyDinner
    case other

    var defaultDuration: Int {
        switch self {
        case .doctorAppointment: return 60
        case .soccerPractice: return 90
        case .parentTeacherConference: return 30
        case .dentistAppointment: return 60
        case .musicLesson: return 60
        case .playdate: return 120
        case .familyDinner: return 90
        case .other: return 60
        }
    }
}

// MARK: - Errors

enum FamilyCoordinationError: Error, LocalizedError {
    case familyNotFound
    case memberNotFound
    case calendarAccessDenied
    case conflictDetected([CalendarConflict])
    case invalidEvent
    case locationSharingDisabled
    case insufficientPermissions
    case choreNotFound
    case insufficientPoints
    case invalidChoreStatus
    case databaseError(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .familyNotFound:
            return "Family profile not found"
        case .memberNotFound:
            return "Family member not found"
        case .calendarAccessDenied:
            return "Calendar access denied. Please enable in Settings."
        case .conflictDetected(let conflicts):
            return "Scheduling conflict detected with \(conflicts.count) event(s)"
        case .invalidEvent:
            return "Invalid event details provided"
        case .locationSharingDisabled:
            return "Location sharing is disabled for this member"
        case .insufficientPermissions:
            return "Insufficient permissions for this action"
        case .choreNotFound:
            return "Chore not found"
        case .insufficientPoints:
            return "Insufficient points for this reward"
        case .invalidChoreStatus:
            return "Invalid chore status for this operation"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .apiError(let message):
            return "External API error: \(message)"
        }
    }
}
```

---

## 7. Example Scenarios

### Scenario 1: Calendar Conflict Detection

**Context:**
- Family: Lisa (parent), Tom (parent), Emma (10), Jake (7)
- Lisa trying to add Emma to dentist appointment
- Emma already has soccer practice at same time

**User Input:**
```
"Schedule Emma for dentist on Thursday at 4pm"
```

**Execution Flow:**

**Step 1: Intent Detection**
```swift
let intent = await gemma3n.parseIntent("Schedule Emma for dentist on Thursday at 4pm")
// Result: { skill: "family_coordination", action: "create_calendar_event" }
```

**Step 2: Extract Event Details**
```swift
let eventDetails = await functionGemma.extractParameters(intent)
// Result: {
//   attendees: ["Emma"],
//   eventType: "dentist",
//   date: "Thursday, Feb 8",
//   time: "4:00 PM",
//   duration: 60 (default for dentist)
// }
```

**Step 3: Load Emma's Calendar**
```swift
let emmaCalendar = try await getMemberCalendar(
    memberId: emma.id,
    startDate: feb8_4pm,
    endDate: feb8_5pm
)
// Result: [Event: "Soccer practice", 3:30-5:00 PM]
```

**Step 4: Detect Conflicts**
```swift
let conflicts = detectCalendarConflicts(
    newEvent: dentistAppointment,
    existingEvents: emmaCalendar
)
// Result: [Conflict {
//   type: .directOverlap,
//   conflictingEvent: soccerPractice,
//   severity: .high
// }]
```

**Step 5: Present Conflict to User**
```
Assistant: "I found a conflict: Emma has soccer practice from 3:30-5:00 PM on Thursday.

Would you like to:
1. Schedule dentist at different time (I found these open slots: 2:30 PM, Friday 10 AM)
2. Proceed anyway and I'll mark soccer as cancelled?
3. Cancel this request?"
```

**User Response:**
```
"Show me Friday slots"
```

**Step 6: Find Alternative Times**
```swift
let alternatives = try await findCommonFreeTime(
    familyId: family.id,
    memberIds: [emma.id, lisa.id], // Both need to attend
    minDuration: 60,
    searchWindow: DateInterval(
        start: friday_8am,
        end: friday_6pm
    )
)
// Result: [
//   TimeSlot(10:00-11:00 AM, score: 8),
//   TimeSlot(2:00-3:00 PM, score: 7),
//   TimeSlot(3:30-4:30 PM, score: 6)
// ]
```

**Step 7: User Selects Time**
```
User: "10am Friday works"
```

**Step 8: Create Event**
```swift
let event = try await createCalendarEvent(
    familyId: family.id,
    event: CalendarEvent(
        title: "Emma - Dentist Appointment",
        startTime: friday_10am,
        endTime: friday_11am,
        attendees: [emma.id, lisa.id],
        location: "Dr. Smith's Office"
    )
)

// Sync to Google Calendar
try await syncWithGoogleCalendar(memberId: lisa.id)

// Send notifications
await sendNotification(
    to: [emma.id, lisa.id],
    message: "Dentist appointment scheduled for Friday at 10 AM"
)
```

**Response:**
```
Assistant: "Done! I've scheduled Emma's dentist appointment for Friday, Feb 9 at 10:00 AM. Both you and Emma will receive a reminder 1 day before and 1 hour before."
```

---

### Scenario 2: Broadcast Message with Responses

**Context:**
- Parent Lisa at grocery store
- Wants to check if family needs anything

**User Input:**
```
"Ask everyone if they need anything from the store"
```

**Execution Flow:**

**Step 1: Create Broadcast**
```swift
let broadcast = BroadcastMessage(
    familyId: family.id,
    senderId: lisa.id,
    recipients: [], // Empty = all family
    subject: "Grocery Store",
    body: "I'm at the store. Does anyone need anything?",
    requiresResponse: true,
    responseDeadline: Date().addingTimeInterval(900), // 15 min
    priority: .normal,
    sentAt: Date()
)
```

**Step 2: Send to All Members**
```swift
let result = try await sendBroadcast(
    familyId: family.id,
    message: broadcast
)
// Result: {
//   deliveryStatus: {
//     tom: .delivered,
//     emma: .delivered,
//     jake: .delivered
//   },
//   successCount: 3
// }
```

**Step 3: Family Members Respond**

Tom (5 minutes later):
```
"Can you grab milk? We're almost out."
```

Emma (7 minutes later):
```
"Granola bars please!"
```

Jake (no response)

**Step 4: Collect Responses**
```swift
let responses = broadcast.responses
// Result: [
//   MessageResponse(
//     responderId: tom.id,
//     responseText: "Can you grab milk? We're almost out.",
//     respondedAt: 5:05 PM
//   ),
//   MessageResponse(
//     responderId: emma.id,
//     responseText: "Granola bars please!",
//     respondedAt: 5:07 PM
//   )
// ]
```

**Step 5: Notify Lisa**
```
Assistant: "I got 2 responses:
• Tom: Can you grab milk? We're almost out.
• Emma: Granola bars please!

Jake hasn't responded yet."
```

---

### Scenario 3: Location Check

**Context:**
- Parent wants to know where everyone is
- 8:30 PM on Tuesday evening

**User Input:**
```
"Where is everyone?"
```

**Execution Flow:**

**Step 1: Get All Locations**
```swift
let locations = try await getAllMemberLocations(familyId: family.id)
```

**Step 2: Process Each Member**

**Tom:**
```swift
let tomLocation = locations[tom.id]
// Result: {
//   coordinate: (40.7589, -73.9851),
//   timestamp: 8:28 PM (2 min ago),
//   batteryLevel: 65,
//   nearestSavedLocation: "Work"
// }
```

**Emma:**
```swift
let emmaLocation = locations[emma.id]
// Result: {
//   coordinate: (40.7128, -74.0060),
//   timestamp: 8:25 PM (5 min ago),
//   batteryLevel: 45,
//   nearestSavedLocation: "Home"
// }
```

**Jake:**
```swift
let jakeLocation = locations[jake.id]
// Result: {
//   coordinate: (40.7128, -74.0060),
//   timestamp: 8:20 PM (10 min ago),
//   batteryLevel: 80,
//   nearestSavedLocation: "Home"
// }
```

**Step 3: Format Response**
```
Assistant: "Here's where everyone is:

🏢 Tom is at work (updated 2 minutes ago, battery 65%)

🏠 Emma is at home (updated 5 minutes ago, battery 45%)

🏠 Jake is at home (updated 10 minutes ago, battery 80%)"
```

---

### Scenario 4: Chore Assignment and Completion

**Context:**
- Parent wants to assign taking out trash to Jake
- Weekly recurring chore worth 10 points

**User Input:**
```
"Assign trash duty to Jake for this week"
```

**Execution Flow:**

**Step 1: Check for Template**
```swift
let template = try await getChoreTemplate(
    familyId: family.id,
    title: "Take out trash"
)
// Result: ChoreTemplate {
//   title: "Take out trash",
//   pointValue: 10,
//   difficulty: .easy,
//   recurrence: RecurrenceRule(frequency: .weekly)
// }
```

**Step 2: Create Chore from Template**
```swift
let chore = try await createChore(
    familyId: family.id,
    chore: ChoreTask(
        title: "Take out trash",
        assignedTo: jake.id,
        createdBy: lisa.id,
        dueDate: Date().nextThursday(at: 18, 00), // 6 PM
        pointValue: 10,
        difficulty: .easy,
        status: .pending,
        requiresVerification: false,
        category: .trash
    )
)
```

**Step 3: Notify Jake**
```swift
await sendNotification(
    to: jake.id,
    message: "New chore assigned: Take out trash by Thursday 6 PM. Earn 10 points!"
)
```

**Response:**
```
Assistant: "Done! I've assigned 'Take out trash' to Jake, due Thursday at 6 PM for 10 points. Jake has been notified."
```

**Later: Jake Completes Chore**

**User Input (Jake):**
```
"I took out the trash"
```

**Step 4: Complete Chore**
```swift
let completion = try await completeChore(
    choreId: chore.id,
    completedBy: jake.id,
    verificationPhoto: nil
)
// Result: ChoreCompletion {
//   choreId: chore.id,
//   completedBy: jake.id,
//   pointsAwarded: 10,
//   wasOnTime: true
// }
```

**Step 5: Update Points**
```swift
let points = try await getMemberPoints(memberId: jake.id)
// Result: PointsSummary {
//   totalPoints: 85,
//   weeklyPoints: 25,
//   monthlyPoints: 120
// }
```

**Response:**
```
Assistant: "Great job, Jake! 🎉 You earned 10 points. Your new balance is 85 points!"
```

---

## 8. API Integrations

### 8.1 Google Calendar API

**Purpose:** Sync family calendars with Google Calendar

**Authentication:** OAuth 2.0

**Endpoints Used:**
- `GET /calendars/primary/events` - List events
- `POST /calendars/primary/events` - Create event
- `PATCH /calendars/primary/events/{eventId}` - Update event
- `DELETE /calendars/primary/events/{eventId}` - Delete event

**Rate Limits:** 1,000,000 queries/day

**Sample Request:**
```swift
class GoogleCalendarAPI {
    func listEvents(
        calendarId: String = "primary",
        timeMin: Date,
        timeMax: Date,
        accessToken: String
    ) async throws -> [CalendarEvent] {
        var components = URLComponents(
            string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events"
        )!

        components.queryItems = [
            URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: timeMin)),
            URLQueryItem(name: "timeMax", value: ISO8601DateFormatter().string(from: timeMax)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        let request = APIRequest<EventListResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: ["Authorization": "Bearer \(accessToken)"],
            body: nil
        )

        let response = try await request.execute()
        return response.items.map { convertToCalendarEvent($0) }
    }
}
```

---

### 8.2 Apple Maps / Google Maps API

**Purpose:** Calculate travel time between locations

**Endpoints:**
- Apple: `MKDirections` (native iOS)
- Google: `https://maps.googleapis.com/maps/api/directions/json`

**Sample Request:**
```swift
func calculateTravelTime(
    from: CLLocation,
    to: CLLocation,
    mode: TravelMode
) async throws -> TravelTimeEstimate {
    let request = MKDirections.Request()

    let sourcePlacemark = MKPlacemark(coordinate: from.coordinate)
    let destPlacemark = MKPlacemark(coordinate: to.coordinate)

    request.source = MKMapItem(placemark: sourcePlacemark)
    request.destination = MKMapItem(placemark: destPlacemark)

    switch mode {
    case .driving:
        request.transportType = .automobile
    case .walking:
        request.transportType = .walking
    case .transit:
        request.transportType = .transit
    default:
        request.transportType = .automobile
    }

    request.requestsAlternateRoutes = false

    let directions = MKDirections(request: request)
    let response = try await directions.calculate()

    guard let route = response.routes.first else {
        throw FamilyCoordinationError.apiError("No route found")
    }

    return TravelTimeEstimate(
        duration: route.expectedTravelTime,
        durationInTraffic: route.expectedTravelTime, // Apple doesn't separate
        distance: route.distance,
        route: route.name
    )
}
```

---

### 8.3 Push Notifications (APNs)

**Purpose:** Send notifications for broadcasts, check-ins, chore assignments

**Implementation:**
```swift
class NotificationManager {
    func sendPushNotification(
        to memberId: UUID,
        title: String,
        body: String,
        data: [String: Any]?
    ) async throws {
        guard let deviceToken = try await getDeviceToken(memberId: memberId) else {
            throw FamilyCoordinationError.apiError("No device token")
        }

        let payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "sound": "default",
                "badge": 1
            ],
            "custom": data ?? [:]
        ]

        // Send via APNs
        try await APNsClient.shared.send(
            payload: payload,
            to: deviceToken
        )
    }
}
```

---

## 9. Test Cases

### Calendar Tests

**Test 1: Detect Direct Overlap Conflict**
```swift
func testDetectDirectOverlapConflict() {
    let existing = CalendarEvent(
        title: "Soccer practice",
        startTime: Date(timeString: "4:00 PM"),
        endTime: Date(timeString: "5:30 PM"),
        attendees: [emma.id]
    )

    let new = CalendarEvent(
        title: "Dentist",
        startTime: Date(timeString: "4:30 PM"),
        endTime: Date(timeString: "5:30 PM"),
        attendees: [emma.id]
    )

    let conflicts = detectCalendarConflicts(
        newEvent: new,
        existingEvents: [existing]
    )

    XCTAssertEqual(conflicts.count, 1)
    XCTAssertEqual(conflicts.first?.conflictType, .directOverlap)
    XCTAssertEqual(conflicts.first?.severity, .high)
}
```

**Test 2: No Conflict - Different Members**
```swift
func testNoConflictDifferentMembers() {
    let existing = CalendarEvent(
        title: "Emma - Soccer",
        startTime: Date(timeString: "4:00 PM"),
        endTime: Date(timeString: "5:30 PM"),
        attendees: [emma.id]
    )

    let new = CalendarEvent(
        title: "Jake - Piano",
        startTime: Date(timeString: "4:00 PM"),
        endTime: Date(timeString: "5:00 PM"),
        attendees: [jake.id]
    )

    let conflicts = detectCalendarConflicts(
        newEvent: new,
        existingEvents: [existing]
    )

    XCTAssertEqual(conflicts.count, 0)
}
```

**Test 3: Find Common Free Time**
```swift
func testFindCommonFreeTime() async throws {
    let emmaEvents = [
        CalendarEvent(title: "School", startTime: "8:00 AM", endTime: "3:00 PM")
    ]

    let jakeEvents = [
        CalendarEvent(title: "School", startTime: "8:00 AM", endTime: "3:00 PM")
    ]

    let slots = try await findCommonFreeTime(
        familyId: family.id,
        memberIds: [emma.id, jake.id],
        minDuration: 60,
        searchWindow: DateInterval(start: today_8am, end: today_8pm)
    )

    // Should find slots after school
    XCTAssertGreaterThan(slots.count, 0)
    XCTAssertTrue(slots.contains(where: {
        $0.startTime >= today_3pm
    }))
}
```

**Test 4: Travel Time Conflict**
```swift
func testTravelTimeConflict() {
    let event1 = CalendarEvent(
        title: "Meeting downtown",
        startTime: "2:00 PM",
        endTime: "3:00 PM",
        location: "123 Main St",
        attendees: [lisa.id]
    )

    let event2 = CalendarEvent(
        title: "Pickup Emma",
        startTime: "3:15 PM",
        endTime: "3:30 PM",
        location: "456 School Rd", // 30 min drive
        attendees: [lisa.id, emma.id]
    )

    let conflicts = detectCalendarConflicts(
        newEvent: event2,
        existingEvents: [event1]
    )

    XCTAssertEqual(conflicts.count, 1)
    XCTAssertEqual(conflicts.first?.conflictType, .travelTime)
}
```

**Test 5: All-Day Event**
```swift
func testAllDayEvent() {
    let allDay = CalendarEvent(
        title: "Family vacation",
        startTime: Date(dateString: "2026-07-01"),
        endTime: Date(dateString: "2026-07-08"),
        isAllDay: true,
        attendees: [lisa.id, tom.id, emma.id, jake.id]
    )

    let regular = CalendarEvent(
        title: "Doctor appointment",
        startTime: Date(timeString: "2026-07-03 10:00 AM"),
        endTime: Date(timeString: "2026-07-03 11:00 AM"),
        attendees: [emma.id]
    )

    let conflicts = detectCalendarConflicts(
        newEvent: regular,
        existingEvents: [allDay]
    )

    XCTAssertEqual(conflicts.count, 1)
    XCTAssertEqual(conflicts.first?.severity, .medium)
}
```

### Broadcast Tests

**Test 6: Broadcast to All Members**
```swift
func testBroadcastToAllMembers() async throws {
    let broadcast = BroadcastMessage(
        familyId: family.id,
        senderId: lisa.id,
        recipients: [],
        body: "Dinner is ready!",
        requiresResponse: false,
        priority: .normal,
        sentAt: Date()
    )

    let result = try await sendBroadcast(
        familyId: family.id,
        message: broadcast
    )

    XCTAssertEqual(result.successCount, 3) // Tom, Emma, Jake
    XCTAssertEqual(result.failureCount, 0)
}
```

**Test 7: Broadcast with Response Requirement**
```swift
func testBroadcastRequiringResponse() async throws {
    let broadcast = BroadcastMessage(
        familyId: family.id,
        senderId: lisa.id,
        recipients: [],
        body: "Does anyone need anything from the store?",
        requiresResponse: true,
        responseDeadline: Date().addingTimeInterval(900),
        priority: .normal,
        sentAt: Date()
    )

    let result = try await sendBroadcast(
        familyId: family.id,
        message: broadcast
    )

    XCTAssertEqual(result.successCount, 3)
    XCTAssertNotNil(broadcast.responseDeadline)
}
```

**Test 8: Selective Recipients**
```swift
func testBroadcastToSpecificMembers() async throws {
    let broadcast = BroadcastMessage(
        familyId: family.id,
        senderId: lisa.id,
        recipients: [emma.id, jake.id], // Only kids
        body: "Homework time!",
        requiresResponse: false,
        priority: .high,
        sentAt: Date()
    )

    let result = try await sendBroadcast(
        familyId: family.id,
        message: broadcast
    )

    XCTAssertEqual(result.successCount, 2) // Only Emma and Jake
}
```

### Location Tests

**Test 9: Get Member Location**
```swift
func testGetMemberLocation() async throws {
    let location = try await getMemberLocation(memberId: emma.id)

    XCTAssertNotNil(location)
    XCTAssertEqual(location?.memberId, emma.id)
    XCTAssertNotNil(location?.coordinate)
    XCTAssertNotNil(location?.timestamp)
}
```

**Test 10: Location Sharing Disabled**
```swift
func testLocationSharingDisabled() async throws {
    try await setLocationSharingPreference(
        memberId: tom.id,
        enabled: false,
        visibleTo: []
    )

    let location = try await getMemberLocation(memberId: tom.id)

    XCTAssertNil(location)
}
```

**Test 11: Check Member at Saved Location**
```swift
func testCheckMemberAtHome() async throws {
    let homeLocation = SavedLocation(
        name: "Home",
        coordinate: Coordinate(latitude: 40.7128, longitude: -74.0060),
        radius: 100,
        category: .home
    )

    let isAtHome = try await checkIfMemberAtLocation(
        memberId: emma.id,
        targetLocation: homeLocation,
        radiusMeters: 100
    )

    XCTAssertTrue(isAtHome)
}
```

**Test 12: Battery-Based Location Update**
```swift
func testBatteryBasedLocationUpdate() async throws {
    // Simulate low battery
    let lowBatteryLocation = MemberLocation(
        memberId: jake.id,
        coordinate: Coordinate(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10.0,
        timestamp: Date(),
        batteryLevel: 15
    )

    // Should not update frequently when battery < 20%
    let shouldUpdate = shouldUpdateLocation(
        lastUpdate: Date().addingTimeInterval(-600), // 10 min ago
        batteryLevel: 15
    )

    XCTAssertFalse(shouldUpdate)
}
```

### Chore Tests

**Test 13: Create and Assign Chore**
```swift
func testCreateAndAssignChore() async throws {
    let chore = try await createChore(
        familyId: family.id,
        chore: ChoreTask(
            title: "Clean room",
            assignedTo: emma.id,
            createdBy: lisa.id,
            dueDate: Date().addingDays(7),
            pointValue: 15,
            difficulty: .medium,
            status: .pending,
            category: .cleaning
        )
    )

    XCTAssertNotNil(chore.id)
    XCTAssertEqual(chore.assignedTo, emma.id)
    XCTAssertEqual(chore.pointValue, 15)
}
```

**Test 14: Complete Chore On Time**
```swift
func testCompleteChoreOnTime() async throws {
    let chore = createTestChore(dueDate: Date().addingDays(1))

    let completion = try await completeChore(
        choreId: chore.id,
        completedBy: emma.id,
        verificationPhoto: nil
    )

    XCTAssertEqual(completion.pointsAwarded, chore.pointValue)
    XCTAssertTrue(completion.wasOnTime)
}
```

**Test 15: Complete Chore Late**
```swift
func testCompleteChoreLate() async throws {
    let chore = createTestChore(dueDate: Date().addingHours(-5)) // 5 hours overdue

    let completion = try await completeChore(
        choreId: chore.id,
        completedBy: emma.id,
        verificationPhoto: nil
    )

    // Late but within 24h = 50% points
    XCTAssertEqual(completion.pointsAwarded, chore.pointValue / 2)
    XCTAssertFalse(completion.wasOnTime)
}
```

**Test 16: Complete Chore Very Late**
```swift
func testCompleteChoreVeryLate() async throws {
    let chore = createTestChore(dueDate: Date().addingHours(-30)) // 30 hours overdue

    let completion = try await completeChore(
        choreId: chore.id,
        completedBy: emma.id,
        verificationPhoto: nil
    )

    // > 24h late = no points
    XCTAssertEqual(completion.pointsAwarded, 0)
    XCTAssertFalse(completion.wasOnTime)
}
```

**Test 17: Chore Verification Required**
```swift
func testChoreRequiringVerification() async throws {
    let chore = createTestChore(requiresVerification: true)

    let completion = try await completeChore(
        choreId: chore.id,
        completedBy: emma.id,
        verificationPhoto: testImage
    )

    XCTAssertTrue(completion.verificationRequired)
    XCTAssertEqual(chore.status, .completed) // Pending parent verification
}
```

**Test 18: Points Redemption**
```swift
func testRedeemPoints() async throws {
    // Give Emma 100 points
    var points = try await getMemberPoints(memberId: emma.id)
    XCTAssertGreaterThanOrEqual(points.totalPoints, 50)

    let reward = ChoreReward(
        title: "30 min extra screen time",
        pointCost: 50,
        category: .screenTime
    )

    let redemption = try await redeemPoints(
        memberId: emma.id,
        reward: reward,
        pointsSpent: 50
    )

    XCTAssertEqual(redemption.pointsSpent, 50)
    XCTAssertEqual(redemption.remainingPoints, points.totalPoints - 50)
}
```

**Test 19: Insufficient Points for Reward**
```swift
func testInsufficientPoints() async throws {
    let reward = ChoreReward(
        title: "New toy",
        pointCost: 500,
        category: .privilege
    )

    do {
        _ = try await redeemPoints(
            memberId: emma.id,
            reward: reward,
            pointsSpent: 500
        )
        XCTFail("Should throw insufficient points error")
    } catch FamilyCoordinationError.insufficientPoints {
        // Expected
    }
}
```

### Check-in Tests

**Test 20: Get Family Status**
```swift
func testGetFamilyStatus() async throws {
    let status = try await getFamilyStatus(familyId: family.id)

    XCTAssertEqual(status.members.count, 4)
    XCTAssertNotNil(status.lastUpdated)

    for member in status.members {
        XCTAssertNotNil(member.name)
    }
}
```

**Test 21: Request Check-in**
```swift
func testRequestCheckIn() async throws {
    let request = try await requestCheckIn(
        fromMemberId: lisa.id,
        toMemberId: emma.id,
        message: "Where are you?"
    )

    XCTAssertEqual(request.fromMemberId, lisa.id)
    XCTAssertEqual(request.toMemberId, emma.id)
    XCTAssertEqual(request.status, .pending)
}
```

**Test 22: Respond to Check-in**
```swift
func testRespondToCheckIn() async throws {
    let request = try await requestCheckIn(
        fromMemberId: lisa.id,
        toMemberId: emma.id,
        message: nil
    )

    let response = CheckInResponse(
        location: MemberLocation(
            memberId: emma.id,
            coordinate: Coordinate(latitude: 40.7128, longitude: -74.0060),
            accuracy: 10.0,
            timestamp: Date(),
            batteryLevel: 75,
            status: .atSchool
        ),
        statusMessage: "At school, heading home soon",
        eta: Date().addingTimeInterval(1800) // 30 min
    )

    let success = try await respondToCheckIn(
        requestId: request.id,
        response: response
    )

    XCTAssertTrue(success)
}
```

**Test 23: Automatic Check-in on Geofence**
```swift
func testAutomaticCheckInGeofence() async throws {
    let trigger = CheckInTrigger(
        memberId: emma.id,
        triggerType: .arriveAt,
        location: schoolLocation,
        time: nil,
        isActive: true
    )

    try await enableAutomaticCheckIns(
        memberId: emma.id,
        triggers: [trigger]
    )

    // Simulate arrival at school
    try await updateMemberLocation(
        memberId: emma.id,
        location: schoolLocation.coordinate.toCLLocation()
    )

    // Should auto-create check-in
    let recentCheckIns = try await getRecentCheckIns(memberId: emma.id)
    XCTAssertGreaterThan(recentCheckIns.count, 0)
}
```

---

## 10. Error Handling

### Error Types and Recovery Strategies

```swift
enum FamilyCoordinationError: Error, LocalizedError {
    case familyNotFound
    case memberNotFound
    case calendarAccessDenied
    case conflictDetected([CalendarConflict])
    case invalidEvent
    case locationSharingDisabled
    case insufficientPermissions
    case choreNotFound
    case insufficientPoints
    case invalidChoreStatus
    case databaseError(String)
    case apiError(String)
}
```

### Recovery Strategies

**Calendar Access Denied:**
```swift
do {
    let events = try await getMemberCalendar(memberId: emma.id)
} catch FamilyCoordinationError.calendarAccessDenied {
    // Show settings prompt
    await showAlert(
        title: "Calendar Access Required",
        message: "Please enable calendar access in Settings to use this feature.",
        actions: [
            .settings,
            .cancel
        ]
    )
}
```

**Conflict Detected:**
```swift
do {
    let event = try await createCalendarEvent(familyId: family.id, event: newEvent)
} catch FamilyCoordinationError.conflictDetected(let conflicts) {
    // Present conflict resolution UI
    let alternatives = try await findCommonFreeTime(
        familyId: family.id,
        memberIds: newEvent.attendees,
        minDuration: newEvent.durationMinutes,
        searchWindow: DateInterval(start: today, end: oneWeekFromToday)
    )

    await showConflictResolution(
        conflicts: conflicts,
        alternatives: alternatives
    )
}
```

**Location Sharing Disabled:**
```swift
do {
    let location = try await getMemberLocation(memberId: tom.id)
} catch FamilyCoordinationError.locationSharingDisabled {
    return "Location sharing is disabled for this family member. You can ask them to enable it in Settings."
}
```

**Insufficient Points:**
```swift
do {
    let redemption = try await redeemPoints(
        memberId: emma.id,
        reward: reward,
        pointsSpent: 100
    )
} catch FamilyCoordinationError.insufficientPoints {
    let points = try await getMemberPoints(memberId: emma.id)
    return "You need \(100 - points.totalPoints) more points to redeem this reward. Complete more chores to earn points!"
}
```

**API Errors:**
```swift
do {
    try await syncWithGoogleCalendar(memberId: lisa.id)
} catch FamilyCoordinationError.apiError(let message) {
    // Log error and retry with backoff
    await logError("Google Calendar sync failed: \(message)")

    // Retry after 5 seconds
    try await Task.sleep(nanoseconds: 5_000_000_000)
    try await syncWithGoogleCalendar(memberId: lisa.id)
}
```

---

**End of Family Coordination Skill Breakdown**
