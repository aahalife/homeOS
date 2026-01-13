# HomeSkills Gap Analysis & Tool Resolution

## Purpose

This document provides a comprehensive analysis of each HomeSkill, identifying:
1. **Required capabilities** - What the skill needs to function
2. **Gaps identified** - Missing tools/APIs that would cause dead-ends
3. **Recommended tools** - Specific MCP servers/APIs to fill gaps
4. **Fallback strategies** - For when primary tools aren't available

This enables smaller LLMs to execute skills deterministically without needing to figure out tool selection.

---

## Gap Analysis by Skill

### 1. Tools (Core Utilities)

**Purpose:** Calendar, groceries, weather, reminders, notes, search, planning

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Calendar management | Need real calendar API | `google_calendar` | Rube/Composio | Local JSON calendar file |
| Grocery shopping | Need store integration | `instacart` or `amazon_fresh` | Rube/Composio | Manual shopping list export |
| Weather forecast | Need weather API | `openweathermap` or `weatherapi` | MCP Servers | Web search for weather |
| Web search | Need search engine | `exa` or `brave_search` | Official MCP | Osaurus browser tool |
| Reminders | Local storage sufficient | Built-in `osaurus.filesystem` | Osaurus | Local JSON |

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["google_calendar.list_events", "google_calendar.create_event"] },
    { "type": "mcp", "provider": "rube", "tools": ["instacart.search_products", "instacart.add_to_cart"] },
    { "type": "mcp", "provider": "standalone", "server": "openweathermap-mcp", "tools": ["weather.get_forecast"] },
    { "type": "mcp", "provider": "standalone", "server": "exa-mcp", "tools": ["search.web"] }
  ]
}
```

---

### 2. Healthcare

**Purpose:** Appointments, medications, symptom tracking

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Doctor appointment booking | No direct API | `zocdoc` (if available) or `calendly` | Rube/Composio | Telephony skill + manual |
| Medication reminders | Local storage OK | Built-in reminders | Osaurus | JSON + system notifications |
| Pharmacy refills | Limited API access | `cvs` or `walgreens` via Rube | Rube/Composio | SMS/email reminder to refill |
| Health record storage | Local file | `osaurus.filesystem` | Osaurus | Encrypted local JSON |
| Emergency detection | Keyword analysis | Built-in LLM | Osaurus | Hardcoded rules |

**Critical Safety Note:**
- NEVER provide medical diagnosis
- Always include: "Consult a healthcare provider for medical advice"
- Emergency keywords (chest pain, difficulty breathing) → immediate 911 prompt

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "builtin", "tools": ["osaurus.filesystem", "osaurus.time"] },
    { "type": "mcp", "provider": "rube", "tools": ["google_calendar.create_event"] },
    { "type": "optional", "provider": "rube", "tools": ["cvs.check_prescription", "cvs.request_refill"] }
  ],
  "fallbackBehavior": {
    "if_missing": ["cvs.*"],
    "action": "prompt_manual_refill"
  }
}
```

---

### 3. Meal Planning

**Purpose:** Weekly menus, grocery lists, recipes, prep schedules

**Primary Integration: Plan to Eat (plantoeat.com)**

Plan to Eat is a dedicated meal planning app with:
- Recipe collection from any URL
- Drag-and-drop meal calendar
- Auto-generated shopping lists (organized by aisle)
- Nutrition/macro tracking

**Note:** Plan to Eat does NOT have a public API. Integration requires web scraping or browser automation.

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Recipe storage | No Plan to Eat API | `firecrawl` to scrape user's Plan to Eat account | Official MCP | Local recipe JSON |
| Meal calendar sync | No API | `osaurus.browser` automation | Osaurus | Manual + local calendar |
| Shopping list export | No API | Scrape shopping list page | Firecrawl | Copy/paste export |
| Nutritional info | Plan to Eat has built-in | Scrape from Plan to Eat | Firecrawl | `spoonacular` API fallback |
| Recipe discovery | Need external source | `spoonacular` for new recipes | MCP Servers | Web search |
| Grocery ordering | Need store integration | `instacart` or `amazon_fresh` | Rube/Composio | Export list to app |

**Plan to Eat Integration Flow:**

```
1. User authenticates to Plan to Eat (one-time OAuth or stored credentials)
2. Skill uses Firecrawl/browser to:
   - Fetch user's recipe collection
   - Read current week's meal plan
   - Export shopping list
3. Local cache stores data for offline access
4. Sync back changes via browser automation (if user approves)
```

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    {
      "type": "mcp",
      "provider": "official",
      "server": "firecrawl-mcp",
      "tools": ["scrape_url", "crawl_site"],
      "config": {
        "baseUrl": "https://www.plantoeat.com",
        "authRequired": true,
        "credentialKey": "plantoeat_session"
      }
    },
    { "type": "builtin", "tools": ["osaurus.browser", "osaurus.filesystem"] },
    { "type": "mcp", "provider": "standalone", "server": "spoonacular-mcp", "tools": ["recipes.search"], "usage": "recipe_discovery_only" },
    { "type": "mcp", "provider": "rube", "tools": ["instacart.search_products", "instacart.add_to_cart"], "required": false }
  ]
}
```

---

### 4. Restaurant Reservation

**Purpose:** Search restaurants, book tables, manage reservations

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Restaurant search | Need search API | `yelp` + `google_maps` | Rube/Composio | Web search |
| Table booking | Need reservation API | `opentable` or `resy` | Rube/Composio | Telephony skill |
| Reviews/ratings | Need review API | `yelp.get_reviews` | Rube/Composio | Web search |
| Calendar sync | Existing tool | `google_calendar` | Rube/Composio | Local calendar |

**Critical Gap:** OpenTable and Resy have limited public APIs. Primary solution:

**Primary Path (if Rube has integration):**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["opentable.search_restaurants", "opentable.book_reservation"] }
  ]
}
```

**Fallback Path (use Telephony):**
```json
{
  "fallbackBehavior": {
    "if_missing": ["opentable.*", "resy.*"],
    "action": "invoke_skill",
    "skill": "telephony",
    "params": { "purpose": "restaurant_reservation" }
  }
}
```

---

### 5. Telephony (AI Voice Calls)

**Purpose:** Make and receive voice calls for reservations, appointments, customer service

#### 5.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TELEPHONY ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DEVELOPER SETUP (One-time)                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Developer creates Bland.ai/Vapi/Twilio account                     │   │
│  │ 2. Developer purchases pool of phone numbers ($15/mo each on Bland)   │   │
│  │ 3. Developer stores API key in app's secure backend config            │   │
│  │ 4. Numbers are registered in app's number pool database               │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    ↓                                         │
│  USER ASSIGNMENT (Per user)                                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ 1. User activates telephony feature in Oi My AI                       │   │
│  │ 2. App assigns an available number from pool to user's account        │   │
│  │ 3. Number stored in user's profile: { userId: "abc", phone: "+1..." } │   │
│  │ 4. User can now make/receive calls via their assigned number          │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 5.2 Phone Number Provisioning

**Provider Options (Priority Order):**

| Provider | Cost | Number Purchase | Features |
|----------|------|-----------------|----------|
| **Bland.ai** | $15/mo per number | `POST https://api.bland.ai/v1/inbound/purchase` | AI-native, transcripts, live actions |
| **Vapi.ai** | Free tier available | Dashboard or `POST /phone-number` | Free numbers, Twilio import |
| **Twilio** | ~$1/mo per number | `POST /2010-04-01/Accounts/{sid}/IncomingPhoneNumbers` | Most flexible, raw telephony |

**Recommended: Bland.ai** (simplest AI integration)

**Number Purchase API (Bland.ai):**
```bash
curl -X POST "https://api.bland.ai/v1/inbound/purchase" \
  -H "Authorization: Bearer {DEVELOPER_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "area_code": "415",
    "country_code": "US"
  }'

# Response:
{
  "phone_number": "+14155551234",
  "status": "active",
  "monthly_cost": 15.00
}
```

**Number Pool Schema (App Backend):**
```json
{
  "numberPool": [
    {
      "phoneNumber": "+14155551234",
      "provider": "bland_ai",
      "status": "assigned",
      "assignedTo": "user_abc123",
      "assignedAt": "2026-01-10T00:00:00Z"
    },
    {
      "phoneNumber": "+14155555678",
      "provider": "bland_ai",
      "status": "available",
      "assignedTo": null,
      "assignedAt": null
    }
  ]
}
```

#### 5.3 Outbound Call Flow (AI Makes Call)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OUTBOUND CALL FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. USER REQUEST                                                             │
│     User: "Call Giovanni's restaurant to book a table for 4 at 7pm"          │
│                                    ↓                                         │
│  2. SKILL PREPARATION                                                        │
│     ┌────────────────────────────────────────────────────────────────────┐  │
│     │ • Extract: restaurant name, party size, time                        │  │
│     │ • Look up restaurant phone number (Yelp/Google)                     │  │
│     │ • Build conversation script/pathway                                 │  │
│     │ • Get user's assigned outbound number                               │  │
│     └────────────────────────────────────────────────────────────────────┘  │
│                                    ↓                                         │
│  3. APPROVAL GATE (HIGH RISK)                                                │
│     "I will call Giovanni's at +1-415-555-0100 to book a table              │
│      for 4 people at 7pm tonight. Proceed? [Yes/No]"                         │
│                                    ↓                                         │
│  4. API CALL TO BLAND.AI                                                     │
│     POST https://api.bland.ai/v1/calls                                       │
│     {                                                                        │
│       "phone_number": "+14155550100",        // Restaurant                   │
│       "from": "+14155551234",                // User's assigned number       │
│       "task": "Book a dinner reservation",                                   │
│       "first_sentence": "Hi, I'd like to make a reservation please",        │
│       "wait_for_greeting": true,                                             │
│       "model": "enhanced",                                                   │
│       "voice": "maya",                                                       │
│       "max_duration": 5,                     // 5 minutes max                │
│       "request_data": {                                                      │
│         "user_id": "user_abc123",            // For billing/tracking         │
│         "skill": "restaurant-reservation",                                   │
│         "party_size": 4,                                                     │
│         "preferred_time": "19:00"                                            │
│       },                                                                     │
│       "webhook": "https://api.oimyai.app/webhooks/bland/call-complete"       │
│     }                                                                        │
│                                    ↓                                         │
│  5. LIVE CALL HANDLING (Bland.ai handles)                                    │
│     ┌────────────────────────────────────────────────────────────────────┐  │
│     │ • Bland's AI speaks to restaurant                                   │  │
│     │ • Real-time STT transcribes restaurant's responses                  │  │
│     │ • AI negotiates: "7pm is full? How about 7:30 or 8?"               │  │
│     │ • Confirms booking details before ending                            │  │
│     └────────────────────────────────────────────────────────────────────┘  │
│                                    ↓                                         │
│  6. WEBHOOK CALLBACK                                                         │
│     POST to app webhook with:                                                │
│     {                                                                        │
│       "call_id": "call_xyz789",                                              │
│       "status": "completed",                                                 │
│       "transcript": [...],                                                   │
│       "summary": "Reservation confirmed for 4 at 7:30pm",                    │
│       "request_data": { "user_id": "user_abc123", ... }                      │
│     }                                                                        │
│                                    ↓                                         │
│  7. USER NOTIFICATION                                                        │
│     "Done! Reservation confirmed at Giovanni's for 4 people at 7:30pm.      │
│      Confirmation added to your calendar."                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 5.4 Inbound Call Flow (User Receives Call)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INBOUND CALL FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. EXTERNAL CALLER DIALS USER'S ASSIGNED NUMBER                             │
│     +14155551234 (assigned to user_abc123)                                   │
│                                    ↓                                         │
│  2. BLAND.AI RECEIVES CALL                                                   │
│     Webhook: POST https://api.oimyai.app/webhooks/bland/inbound              │
│     {                                                                        │
│       "phone_number": "+14155551234",                                        │
│       "caller_id": "+14085559999",                                           │
│       "call_id": "inbound_abc123"                                            │
│     }                                                                        │
│                                    ↓                                         │
│  3. APP LOOKS UP USER                                                        │
│     Query: SELECT user_id FROM number_assignments                            │
│            WHERE phone_number = '+14155551234'                               │
│     Result: user_abc123                                                      │
│                                    ↓                                         │
│  4. LOAD USER'S AI PERSONA + CONTEXT                                         │
│     ┌────────────────────────────────────────────────────────────────────┐  │
│     │ • User's name, preferences                                          │  │
│     │ • Family context (if family member calling)                         │  │
│     │ • Calendar for today                                                │  │
│     │ • Active reminders/tasks                                            │  │
│     └────────────────────────────────────────────────────────────────────┘  │
│                                    ↓                                         │
│  5. RESPOND TO BLAND WITH AI INSTRUCTIONS                                    │
│     {                                                                        │
│       "task": "You are the AI assistant for [User Name]. Answer politely.",  │
│       "first_sentence": "Hello, this is [User]'s assistant. How can I help?",│
│       "model": "enhanced",                                                   │
│       "transfer_phone_number": "+14085551111"  // User's real phone if needed│
│     }                                                                        │
│                                    ↓                                         │
│  6. AI HANDLES CALL                                                          │
│     ┌────────────────────────────────────────────────────────────────────┐  │
│     │ Caller: "Is John available?"                                        │  │
│     │ AI: "John is not available right now. Can I take a message?"        │  │
│     │ Caller: "Tell him Dr. Smith's office called about his appointment"  │  │
│     │ AI: "Got it. I'll let John know Dr. Smith's office called.          │  │
│     │      Is there a callback number?"                                    │  │
│     └────────────────────────────────────────────────────────────────────┘  │
│                                    ↓                                         │
│  7. POST-CALL PROCESSING                                                     │
│     • Transcript saved to user's message log                                 │
│     • Notification sent: "Missed call from Dr. Smith's office"              │
│     • If urgent: Push notification + Telegram message                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 5.5 LLM + STT Integration Details

**Speech-to-Text (STT) - What the other person says:**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AUDIO FROM CALLER                                                           │
│  "Hi, I'm calling about the reservation for tomorrow"                        │
│                           ↓                                                  │
│  BLAND.AI's BUILT-IN STT (Deepgram/Whisper)                                  │
│  Real-time transcription → streaming text                                    │
│                           ↓                                                  │
│  LLM PROCESSES TEXT                                                          │
│  Model understands: caller asking about existing reservation                 │
│                           ↓                                                  │
│  LLM GENERATES RESPONSE                                                      │
│  "Yes, I see the reservation. It's for 4 people at 7pm. Is that correct?"   │
│                           ↓                                                  │
│  TEXT-TO-SPEECH (TTS)                                                        │
│  Bland's voice synthesis speaks response                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Conversation Memory During Call:**
```json
{
  "callContext": {
    "purpose": "restaurant_reservation",
    "gathered_info": {
      "restaurant_name": "Giovanni's",
      "date": "2026-01-13",
      "time": null,
      "party_size": 4,
      "special_requests": null
    },
    "conversation_state": "negotiating_time",
    "attempts": [
      { "time": "19:00", "response": "fully booked" },
      { "time": "19:30", "response": "available" }
    ]
  }
}
```

#### 5.6 User Isolation (Multi-tenant)

**Critical Requirement:** All API calls include user identifier to prevent cross-user data mixing.

```json
{
  "apiRequest": {
    "headers": {
      "Authorization": "Bearer {DEVELOPER_SHARED_API_KEY}",
      "X-User-ID": "user_abc123",
      "X-Request-ID": "req_xyz789"
    },
    "body": {
      "request_data": {
        "user_id": "user_abc123",
        "app_instance": "oimyai_v1"
      }
    }
  }
}
```

**Webhook User Identification:**
```json
{
  "webhookPayload": {
    "call_id": "call_xyz789",
    "phone_number": "+14155551234",
    "request_data": {
      "user_id": "user_abc123"
    }
  },
  "processing": {
    "step1": "Extract user_id from request_data",
    "step2": "Verify phone_number belongs to user_id",
    "step3": "Route transcript/notification to correct user"
  }
}
```

#### 5.7 Tool Configuration

```json
{
  "requiredCapabilities": [
    {
      "type": "api",
      "provider": "bland_ai",
      "required": true,
      "endpoints": {
        "outbound": "POST https://api.bland.ai/v1/calls",
        "inbound_config": "POST https://api.bland.ai/v1/inbound",
        "get_call": "GET https://api.bland.ai/v1/calls/{call_id}",
        "list_numbers": "GET https://api.bland.ai/v1/inbound"
      },
      "auth": {
        "type": "bearer",
        "keySource": "developer_config",
        "keyPath": "services.bland_ai.api_key"
      },
      "userIsolation": {
        "includeUserId": true,
        "userIdField": "request_data.user_id",
        "phoneAssignment": "number_pool"
      }
    }
  ],
  "fallbackBehavior": {
    "if_missing": ["bland_ai.*"],
    "alternatives": [
      {
        "provider": "vapi",
        "priority": 2
      },
      {
        "provider": "twilio_voice",
        "priority": 3,
        "note": "Requires custom LLM integration"
      }
    ],
    "ultimateFallback": {
      "action": "generate_call_script",
      "output": "Formatted script for user to make call manually"
    }
  }
}

---

### 6. Family Communications

**Purpose:** Announcements, calendar coordination, chores, check-ins

**Native macOS Integration:** Since Oi My AI is a native Mac app, it has direct access to Apple frameworks.

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Family messaging | Multiple options | **iMessage** (native) or `telegram` | EventKit/Gateway | In-app notifications |
| Calendar sharing | Multiple options | **Apple Calendar** (native) or `google_calendar` | EventKit/Rube | Local family calendar |
| Push notifications | Native available | **macOS Notifications** or `pushover` | UserNotifications | Email fallback |
| Location check-ins | Native available | **Find My** (limited) or user-reported | CoreLocation | Manual check-in prompts |

#### 6.1 Native Apple Integration (Preferred for Mac Users)

**Apple Calendar (EventKit Framework):**
```swift
// Native Swift integration - no API key needed
import EventKit

let eventStore = EKEventStore()

// Request access (one-time user approval)
eventStore.requestAccess(to: .event) { granted, error in
    if granted {
        // Full read/write access to user's calendars
        let calendars = eventStore.calendars(for: .event)
        // Create family events, read shared calendars
    }
}
```

**iMessage (Messages Framework):**
```swift
// Native Swift integration for sending messages
import Messages

// Note: Direct iMessage sending requires user interaction via share sheet
// For automated messaging, use AppleScript bridge or Shortcuts integration

// AppleScript approach (automated):
let script = """
tell application "Messages"
    set targetService to 1st account whose service type = iMessage
    set targetBuddy to participant "[phone/email]" of targetService
    send "Family dinner at 6pm tonight!" to targetBuddy
end tell
"""
```

**Advantages of Native Integration:**
- No API keys needed
- Works offline
- Deeper OS integration (Siri, widgets, Focus modes)
- Family Sharing built-in
- Privacy-preserving (data stays on device)

#### 6.2 Tool Configuration

```json
{
  "requiredCapabilities": [
    {
      "type": "native",
      "framework": "EventKit",
      "tools": ["calendar.list_events", "calendar.create_event", "calendar.update_event"],
      "permissions": ["NSCalendarsUsageDescription"],
      "note": "Preferred for Apple ecosystem families"
    },
    {
      "type": "native",
      "framework": "Messages",
      "tools": ["imessage.send", "imessage.send_group"],
      "permissions": ["NSAppleEventsUsageDescription"],
      "implementation": "AppleScript bridge",
      "note": "Requires Automation permission in System Settings"
    },
    {
      "type": "gateway",
      "provider": "telegram",
      "tools": ["send_message", "send_group_message", "get_responses"],
      "note": "For cross-platform families or external gateway access"
    },
    {
      "type": "mcp",
      "provider": "rube",
      "tools": ["google_calendar.create_event", "google_calendar.list_events"],
      "note": "For families using Google Calendar"
    }
  ],
  "calendarPriority": [
    { "provider": "apple_calendar", "condition": "default_for_mac_users" },
    { "provider": "google_calendar", "condition": "if_configured" },
    { "provider": "local_json", "condition": "fallback" }
  ],
  "messagingPriority": [
    { "provider": "imessage", "condition": "family_on_apple_devices" },
    { "provider": "telegram", "condition": "cross_platform_or_gateway" },
    { "provider": "push_notification", "condition": "in_app_only" }
  ]
}
```

**Notification Fallback:**
```json
{
  "fallbackBehavior": {
    "if_missing": ["imessage.*", "telegram.*"],
    "action": "use_alternative",
    "alternatives": [
      { "type": "native", "framework": "UserNotifications", "tools": ["notification.send"] },
      { "type": "mcp", "provider": "standalone", "server": "pushover-mcp", "tools": ["notification.send"] },
      { "type": "mcp", "provider": "rube", "tools": ["email.send"] }
    ]
  }
}
```

---

### 7. Elder Care

**Purpose:** Daily check-ins, medication tracking, wellness monitoring, family updates

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Voice calls | Need telephony | `bland_ai` or `vapi` | API Integration | Telegram voice messages |
| Medication reminders | See Healthcare skill | Same as Healthcare | - | - |
| Family notifications | Gateway integration | `telegram` | OimyaiGateway | Email/SMS |
| Wellness tracking | Local storage | `osaurus.filesystem` | Osaurus | JSON logs |
| Music playback | Need music API | `spotify` via Rube | Rube/Composio | YouTube links |

**Special Considerations:**
- Simpler interaction patterns for elderly users
- Larger text prompts via Telegram
- Voice-first approach when possible

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "api", "provider": "bland_ai", "tools": ["calls.initiate"], "required": false },
    { "type": "gateway", "provider": "telegram", "tools": ["send_message", "send_voice_message"] },
    { "type": "mcp", "provider": "rube", "tools": ["spotify.play_track", "spotify.search"], "required": false },
    { "type": "builtin", "tools": ["osaurus.filesystem"] }
  ]
}
```

---

### 8. Hire Helper

**Purpose:** Find babysitters, cleaners, tutors, pet care, handymen, movers

#### 8.1 Platform Integrations

| Platform | API Available | Capability | Source |
|----------|---------------|------------|--------|
| **TaskRabbit** | Yes (REST API) | Full booking flow | https://developer.taskrabbit.com |
| **Nextdoor** | Yes (OAuth2 + REST) | Search local posts | https://developer.nextdoor.com |
| **Patch.com** | No (scraping needed) | Local community posts | Firecrawl/Exa |
| Care.com | No | Manual search | Web links only |
| Rover | No | Manual search | Web links only |

#### 8.2 TaskRabbit API Integration

**API Overview (from developer.taskrabbit.com):**
- **Delivery by Dolly**: On-demand local delivery
- **Home Services**: Skilled taskers for cleaning, handyman, moving, etc.

**Authentication:**
```json
{
  "auth": {
    "type": "oauth2",
    "clientId": "{DEVELOPER_CLIENT_ID}",
    "clientSecret": "{DEVELOPER_CLIENT_SECRET}",
    "tokenUrl": "https://api.taskrabbit.com/oauth/token",
    "scopes": ["tasks:read", "tasks:write", "users:read"]
  }
}
```

**Key Endpoints:**
```
POST /api/v1/tasks                    # Create a new task
GET  /api/v1/tasks/{id}               # Get task details
GET  /api/v1/tasks/{id}/offers        # Get tasker offers
POST /api/v1/tasks/{id}/assign        # Assign a tasker
GET  /api/v1/categories               # List available task types
```

**Booking Flow:**
```
1. User: "I need help moving furniture this Saturday"

2. Skill extracts:
   - Category: "moving"
   - Date: "Saturday 2026-01-18"
   - Description: "furniture moving"

3. API Call: POST /api/v1/tasks
   {
     "category_id": "moving",
     "description": "Help moving furniture within apartment",
     "scheduled_at": "2026-01-18T10:00:00Z",
     "location": { "address": "123 Main St, San Francisco, CA" },
     "request_data": { "user_id": "user_abc123" }
   }

4. Receive tasker offers with profiles, ratings, prices

5. Present to user: "Found 3 taskers available. John ($45/hr, 4.9★),
                     Maria ($38/hr, 4.8★), or Mike ($52/hr, 5.0★)?"

6. User approves → POST /api/v1/tasks/{id}/assign
```

#### 8.3 Nextdoor API Integration

**API Overview (from developer.nextdoor.com):**
- Search posts by keyword + location
- Only posts from last 7 days available
- OAuth2 Bearer token authentication

**Search Posts Endpoint:**
```
GET https://nextdoor.com/content_api/v2/search_post
  ?query=babysitter
  &lat=37.7749
  &lon=-122.4194
  &radius=5

Headers:
  Authorization: Bearer {DEVELOPER_ACCESS_TOKEN}
  X-User-ID: user_abc123
```

**Response Example:**
```json
{
  "posts": [
    {
      "id": "post_123",
      "content": "Experienced babysitter available weekends. 5 years experience, CPR certified.",
      "author": { "display_name": "Sarah M.", "neighborhood": "Mission District" },
      "created_at": "2026-01-10T14:30:00Z",
      "type": "for_sale_and_free"
    }
  ]
}
```

**Use Case Flow:**
```
1. User: "Find a babysitter in my area"

2. Skill gets user's location from profile

3. API Call to Nextdoor:
   GET /content_api/v2/search_post?query=babysitter&lat={lat}&lon={lon}&radius=5

4. Present results: "Found 3 neighbors offering babysitting:
   - Sarah M. (Mission District): 'Experienced, CPR certified'
   - Tom K. (Castro): 'College student, available evenings'
   - Lisa R. (Noe Valley): 'Retired teacher, references available'"

5. User can request contact info (Nextdoor handles messaging)
```

#### 8.4 Patch.com Local Posts (Web Scraping)

**No API Available** - Use Firecrawl or Exa to search/scrape

**Patch.com Structure:**
- Local news and community posts by neighborhood
- URL pattern: `https://patch.com/{city-state}/`
- Classifieds section with local services

**Scraping Flow with Firecrawl:**
```json
{
  "tool": "firecrawl.scrape_url",
  "params": {
    "url": "https://patch.com/california/sanfrancisco/classifieds/services",
    "selectors": {
      "posts": ".classified-listing",
      "title": ".listing-title",
      "description": ".listing-description",
      "contact": ".listing-contact"
    }
  }
}
```

**Alternative with Exa Search:**
```json
{
  "tool": "exa.search",
  "params": {
    "query": "site:patch.com house cleaning services San Francisco",
    "num_results": 10
  }
}
```

#### 8.5 Capability Matrix

| Capability | TaskRabbit | Nextdoor | Patch.com | Fallback |
|------------|------------|----------|-----------|----------|
| Search helpers | API | API | Scrape | Web search |
| View profiles | API | Limited | No | Manual link |
| Background check | TaskRabbit verified | No | No | Checkr API |
| Book directly | API | No (messaging) | No | Manual |
| Payment | API | No | No | Manual |
| Reviews | API | No | No | Manual |

#### 8.6 Tool Configuration

```json
{
  "requiredCapabilities": [
    {
      "type": "api",
      "provider": "taskrabbit",
      "endpoints": {
        "base": "https://api.taskrabbit.com",
        "tasks": "/api/v1/tasks",
        "categories": "/api/v1/categories",
        "offers": "/api/v1/tasks/{id}/offers"
      },
      "auth": {
        "type": "oauth2",
        "keySource": "developer_config",
        "keyPath": "services.taskrabbit"
      },
      "userIsolation": {
        "includeUserId": true,
        "userIdField": "request_data.user_id"
      }
    },
    {
      "type": "api",
      "provider": "nextdoor",
      "endpoints": {
        "search_posts": "https://nextdoor.com/content_api/v2/search_post"
      },
      "auth": {
        "type": "bearer",
        "keySource": "developer_config",
        "keyPath": "services.nextdoor.access_token"
      },
      "userIsolation": {
        "includeUserId": true,
        "headerField": "X-User-ID"
      },
      "limitations": {
        "postsAge": "7 days max",
        "requiresLocation": true
      }
    },
    {
      "type": "mcp",
      "provider": "official",
      "server": "firecrawl-mcp",
      "tools": ["scrape_url"],
      "usage": "patch.com and other non-API sources",
      "auth": {
        "keySource": "developer_config",
        "keyPath": "services.firecrawl.api_key"
      }
    },
    {
      "type": "mcp",
      "provider": "standalone",
      "server": "exa-mcp",
      "tools": ["search.web"],
      "usage": "General web search fallback"
    },
    {
      "type": "mcp",
      "provider": "rube",
      "tools": ["checkr.run_background_check"],
      "required": false,
      "usage": "Optional background check for any helper"
    },
    {
      "type": "native",
      "framework": "EventKit",
      "tools": ["calendar.create_event"],
      "usage": "Schedule helper appointments"
    }
  ],
  "searchPriority": [
    { "provider": "taskrabbit", "for": ["cleaning", "handyman", "moving", "delivery"] },
    { "provider": "nextdoor", "for": ["babysitter", "pet_care", "tutoring", "local_recommendations"] },
    { "provider": "patch_scrape", "for": ["local_services", "community_recommendations"] },
    { "provider": "web_search", "for": "fallback" }
  ]
}
```

---

### 9. Marketplace Sell

**Purpose:** Sell items on FB Marketplace, eBay, Craigslist

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Price research | Need sold listings data | `ebay.search_sold` | Rube/Composio | Web search |
| Photo analysis | Need vision API | Built-in LLM vision | Osaurus | User describes item |
| Listing creation | Limited platform APIs | Manual posting | N/A | Formatted text output |
| Message management | Platform-specific | Manual | N/A | Response templates |

**eBay Integration (Available):**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["ebay.search_sold_items", "ebay.create_listing"], "required": false },
    { "type": "mcp", "provider": "standalone", "server": "exa-mcp", "tools": ["search.web"] },
    { "type": "builtin", "tools": ["osaurus.filesystem"] }
  ]
}
```

**Facebook Marketplace:** No API - provide formatted listing text for manual posting.

---

### 10. Transportation

**Purpose:** Ride booking, commute, carpools, parking

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Ride estimates | Limited Uber/Lyft API | `google_maps.directions` | Rube/MCP | Web search for fares |
| Traffic conditions | Need maps API | `google_maps.traffic` | Rube/Composio | Web search |
| Ride booking | No public API | Manual app links | N/A | Deep links to apps |
| Parking search | Need parking API | `spothero` or `parkwhiz` | Rube/Composio | Web search |
| Carpool coordination | Calendar + messaging | `google_calendar` + `telegram` | Existing | Local coordination |

**Reality Check:** Uber/Lyft don't offer public booking APIs. Provide deep links instead.

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["google_maps.get_directions", "google_maps.get_traffic"] },
    { "type": "mcp", "provider": "rube", "tools": ["spothero.search_parking"], "required": false },
    { "type": "gateway", "provider": "telegram", "tools": ["send_message"] }
  ],
  "appDeepLinks": {
    "uber": "uber://?action=setPickup&pickup=my_location&dropoff[latitude]={lat}&dropoff[longitude]={lng}",
    "lyft": "lyft://ridetype?id=lyft&pickup[latitude]={lat}&pickup[longitude]={lng}"
  }
}
```

---

### 11. Home Maintenance

**Purpose:** Repairs, contractor search, emergencies

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Contractor search | Need local search | `yelp` + `google_maps` | Rube/Composio | Web search |
| Emergency guidance | Built-in knowledge | LLM + rules | Osaurus | Hardcoded emergency steps |
| Appointment scheduling | Telephony or calendar | `bland_ai` or `google_calendar` | API/Rube | Manual with script |
| Home inventory | Local storage | `osaurus.filesystem` | Osaurus | JSON file |

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["yelp.search_businesses", "yelp.get_reviews"] },
    { "type": "mcp", "provider": "rube", "tools": ["google_maps.search_nearby"] },
    { "type": "builtin", "tools": ["osaurus.filesystem"] }
  ],
  "emergencyProtocol": {
    "gas_leak": ["EXIT immediately", "Call 911 from outside", "Do NOT use electronics"],
    "water_emergency": ["Shut off main water valve", "Document with photos", "Call plumber"],
    "no_heat": ["Check thermostat", "Check pilot light", "Call HVAC if unresolved"],
    "electrical": ["Turn off breaker", "Do NOT touch exposed wires", "Call electrician"]
  }
}
```

---

### 12. Education & School

**Purpose:** Homework tracking, grades, LMS integration

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Google Classroom | Need API integration | `google_classroom` | Rube/Composio + MCP | Manual entry |
| Canvas LMS | Need API integration | `canvas_lms` | Custom MCP | Manual entry |
| Grade tracking | Local storage | `osaurus.filesystem` | Osaurus | JSON tracking |
| Assignment reminders | Existing tools | `osaurus.time` + notifications | Osaurus | Calendar events |

**Google Classroom MCP (Available):**
- Official Google MCP servers include Classroom integration
- https://github.com/punkpeye/awesome-mcp-servers (Google MCP Servers section)

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "google", "tools": ["classroom.list_courses", "classroom.list_assignments", "classroom.get_grades"] },
    { "type": "mcp", "provider": "standalone", "server": "canvas-mcp", "tools": ["canvas.list_assignments"], "required": false },
    { "type": "builtin", "tools": ["osaurus.filesystem", "osaurus.time"] }
  ]
}
```

---

### 13. Wellness

**Purpose:** Hydration, movement, sleep, screen time tracking

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Health metrics | Apple HealthKit access | `healthkit` (if available) | Custom MCP | Manual logging |
| Step tracking | Device integration | `healthkit.get_steps` | Custom MCP | User self-report |
| Sleep tracking | Device integration | `healthkit.get_sleep` | Custom MCP | User self-report |
| Screen time | System API | macOS Screen Time API | Native | User self-report |
| Reminders | Built-in | `osaurus.time` | Osaurus | System notifications |

**Apple HealthKit Integration:**
- Requires macOS/iOS HealthKit entitlement
- Can read aggregated health data with user permission
- Consider privacy implications

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "native", "framework": "HealthKit", "tools": ["get_steps", "get_sleep", "get_water_intake"], "required": false },
    { "type": "builtin", "tools": ["osaurus.filesystem", "osaurus.time"] }
  ],
  "fallbackBehavior": {
    "if_missing": ["HealthKit.*"],
    "action": "manual_logging",
    "prompt": "How many glasses of water have you had today?"
  }
}
```

---

### 14. Habits

**Purpose:** Habit tracking with behavioral science

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Habit storage | Local file | `osaurus.filesystem` | Osaurus | JSON |
| Streak tracking | Local calculation | Built-in logic | Osaurus | JSON |
| Reminders | Built-in | `osaurus.time` | Osaurus | Notifications |
| Analytics | Local processing | Built-in logic | Osaurus | JSON aggregation |

**No External Tools Required** - This skill is primarily conversational with local storage.

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "builtin", "tools": ["osaurus.filesystem", "osaurus.time"] }
  ],
  "dataSchema": {
    "habits": {
      "id": "string",
      "name": "string",
      "trigger": "string",
      "twoMinuteVersion": "string",
      "currentStreak": "number",
      "longestStreak": "number",
      "completions": ["date"]
    }
  }
}
```

---

### 15. Family Bonding

**Purpose:** Activity planning, outings, date nights

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Local events | Need event API | `eventbrite` or `ticketmaster` | Rube/Composio | Web search |
| Weather check | Existing tool | `openweathermap` | MCP Servers | Web search |
| Activity ideas | Built-in knowledge | LLM | Osaurus | Curated database |
| Calendar booking | Existing tool | `google_calendar` | Rube/Composio | Local calendar |

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["eventbrite.search_events"], "required": false },
    { "type": "mcp", "provider": "rube", "tools": ["ticketmaster.search_events"], "required": false },
    { "type": "mcp", "provider": "standalone", "server": "openweathermap-mcp", "tools": ["weather.get_forecast"] },
    { "type": "mcp", "provider": "standalone", "server": "exa-mcp", "tools": ["search.web"] },
    { "type": "mcp", "provider": "rube", "tools": ["google_calendar.create_event"] }
  ]
}
```

---

### 16. Mental Load

**Purpose:** Reduce cognitive burden through automation

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Orchestration | Meta-skill | Other skills | Osaurus | Built-in |
| Morning briefing | Aggregation | Multiple data sources | Various | Local data |
| Conflict detection | Calendar analysis | `google_calendar` | Rube/Composio | Local calendar |
| Proactive reminders | Scheduling | `osaurus.time` | Osaurus | System notifications |

**No New Tools Required** - This skill orchestrates other skills.

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "skill", "skills": ["tools", "family-comms", "transportation", "meal-planning"] },
    { "type": "mcp", "provider": "rube", "tools": ["google_calendar.list_events"] }
  ]
}
```

---

### 17. Psy-Rich (Psychologically Rich Experiences)

**Purpose:** Discover meaningful, novel activities

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Event discovery | Need local search | `eventbrite` + `meetup` | Rube/Composio | Web search |
| Cultural venues | Need POI search | `google_maps` | Rube/Composio | Web search |
| Experience tracking | Local storage | `osaurus.filesystem` | Osaurus | JSON journal |
| Personalization | Local preferences | `osaurus.filesystem` | Osaurus | JSON profile |

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "rube", "tools": ["eventbrite.search_events", "meetup.find_events"], "required": false },
    { "type": "mcp", "provider": "rube", "tools": ["google_maps.search_nearby"] },
    { "type": "mcp", "provider": "standalone", "server": "exa-mcp", "tools": ["search.web"] },
    { "type": "builtin", "tools": ["osaurus.filesystem"] }
  ]
}
```

---

### 18. Note-to-Actions

**Purpose:** Transform content into atomic habits

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| URL content extraction | Need web scraping | `firecrawl` | Official MCP | Osaurus browser |
| YouTube transcripts | Need transcript API | `youtube_transcript` | MCP Servers | Manual summary |
| Podcast parsing | Need audio transcription | `assemblyai` or local Whisper | MCP/Osaurus | Manual notes |
| Action storage | Local file | `osaurus.filesystem` | Osaurus | JSON |

**Firecrawl MCP (Official):**
- Web scraping and content extraction
- Converts pages to clean markdown
- Perfect for article/blog content

**Tool Configuration:**
```json
{
  "requiredCapabilities": [
    { "type": "mcp", "provider": "official", "server": "firecrawl-mcp", "tools": ["scrape_url", "crawl_site"] },
    { "type": "mcp", "provider": "standalone", "server": "youtube-transcript-mcp", "tools": ["get_transcript"], "required": false },
    { "type": "native", "framework": "WhisperKit", "tools": ["transcribe_audio"], "required": false },
    { "type": "builtin", "tools": ["osaurus.filesystem"] }
  ]
}
```

---

### 19. Chat-Turn (Conversation Processing)

**Purpose:** 6-phase conversation framework

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| Intent classification | Built-in LLM | Osaurus | N/A | Rule-based |
| Context recall | Local storage | `osaurus.filesystem` | Osaurus | JSON memory |
| Skill routing | Meta-skill | Skill registry | Osaurus | Hardcoded routing |
| Approval gates | Built-in logic | Osaurus | N/A | Confirmation prompts |

**No External Tools Required** - Core orchestration skill.

---

### 20. Infrastructure

**Purpose:** Storage, approvals, error handling

| Capability | Gap | Recommended Tool | Source | Fallback |
|------------|-----|------------------|--------|----------|
| File storage | Built-in | `osaurus.filesystem` | Osaurus | N/A |
| JSON processing | Built-in | Local processing | Osaurus | jq fallback |
| Approval workflow | Built-in logic | Osaurus | N/A | Confirmation prompts |
| Audit logging | Local files | `osaurus.filesystem` | Osaurus | JSON logs |

**No External Tools Required** - Foundation infrastructure.

---

## MCP Servers Required (Summary)

### Must-Have (Core Functionality)

| Server | Purpose | Source | Priority |
|--------|---------|--------|----------|
| google_calendar | Calendar management | Rube/Composio | P0 |
| openweathermap-mcp | Weather forecasts | MCP Servers | P0 |
| exa-mcp | Web search | Official MCP | P0 |
| firecrawl-mcp | Web content extraction | Official MCP | P0 |

### Should-Have (Enhanced Experience)

| Server | Purpose | Source | Priority |
|--------|---------|--------|----------|
| yelp via Rube | Local business search | Rube/Composio | P1 |
| google_maps via Rube | Directions, traffic, POI | Rube/Composio | P1 |
| instacart via Rube | Grocery shopping | Rube/Composio | P1 |
| spoonacular-mcp | Recipes and nutrition | MCP Servers | P1 |
| pushover-mcp or ntfy | Push notifications | MCP Servers | P1 |

### Nice-to-Have (Premium Features)

| Server | Purpose | Source | Priority |
|--------|---------|--------|----------|
| bland_ai API | AI voice calls | Direct API | P2 |
| spotify via Rube | Music playback | Rube/Composio | P2 |
| eventbrite via Rube | Event discovery | Rube/Composio | P2 |
| google_classroom | LMS integration | Google MCP | P2 |
| ebay via Rube | Marketplace selling | Rube/Composio | P2 |

---

## Fallback Strategy Matrix

| When This Fails | Use This Instead | User Experience |
|-----------------|------------------|-----------------|
| Calendar API | Local JSON calendar | Manual sync needed |
| Weather API | Web search | Less accurate, slower |
| Grocery API | Shopping list export | Copy to app manually |
| Telephony API | Call script generation | User makes call |
| Ride booking API | App deep links | Opens Uber/Lyft app |
| Restaurant booking | Telephony or manual | Call or website |
| LMS integration | Manual homework entry | Parent/student inputs |
| Health tracking | Self-reported data | Daily prompts |

---

## Skill Execution Guidelines for Small LLMs

### Deterministic Tool Selection

For each user intent, the skill should specify **exactly** which tools to use:

```json
{
  "intent": "book_restaurant",
  "toolSequence": [
    { "step": 1, "tool": "yelp.search_restaurants", "params": ["cuisine", "location", "party_size"] },
    { "step": 2, "tool": "opentable.check_availability", "params": ["restaurant_id", "date", "time", "party_size"] },
    { "step": 3, "tool": "opentable.book_reservation", "params": ["slot_id"], "requiresApproval": true },
    { "step": 4, "tool": "google_calendar.create_event", "params": ["reservation_details"] }
  ],
  "fallbackSequence": [
    { "step": 1, "tool": "exa.search", "params": ["restaurant {cuisine} {location}"] },
    { "step": 2, "tool": "telephony.call", "params": ["restaurant_phone", "reservation_script"] }
  ]
}
```

### Error Handling Rules

```json
{
  "errorHandling": {
    "tool_not_available": "Use fallback sequence",
    "api_rate_limit": "Retry after 60 seconds, max 3 attempts",
    "auth_failure": "Prompt user to re-authenticate in Settings",
    "network_error": "Use cached data if available, else inform user",
    "invalid_params": "Ask user to clarify missing information"
  }
}
```

### Approval Gate Enforcement

```json
{
  "approvalGates": {
    "HIGH_RISK": {
      "actions": ["make_call", "send_money", "post_public", "delete_data", "share_location"],
      "required": "EXPLICIT_YES",
      "validResponses": ["yes", "approved", "go ahead", "do it", "confirm"],
      "invalidResponses": ["maybe", "sure", "ok", "whatever"]
    },
    "MEDIUM_RISK": {
      "actions": ["save_preference", "send_notification", "create_reminder"],
      "required": "FIRST_TIME_ONLY",
      "cacheDecision": true
    },
    "LOW_RISK": {
      "actions": ["search", "read_file", "get_weather", "list_items"],
      "required": "NONE"
    }
  }
}
```

---

## Next Steps for Implementation

1. **Clone HomeSkills repository** and add tool configurations to each SKILL.md
2. **Create SkillDefinition JSON** files with exact tool requirements
3. **Implement SkillLint** to validate tools are available before execution
4. **Build fallback registry** mapping primary tools to alternatives
5. **Test each skill** with tools disabled to verify fallback paths work

---

## Document Version

- **Created:** 2026-01-12
- **Purpose:** Gap analysis for OiMyAI HomeSkills integration
- **Author:** Claude (Planning Phase)
- **Status:** Ready for implementation
