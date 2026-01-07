# HomeOS Architecture

HomeOS is an iOS-first family AI assistant with agentic capabilities and Temporal durable execution. This document describes the system architecture, services, workflows, and tools.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (Swift)                          │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐    │
│  │   Chat    │  │   Tasks   │  │  Actions  │  │ Settings  │    │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘    │
└────────┼──────────────┼──────────────┼──────────────┼───────────┘
         │              │              │              │
         └──────────────┴──────────────┴──────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Control Plane   │ :3001
                    │  (Auth, Workspaces)│
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │     Runtime       │ :3002
                    │ (Chat, WebSocket) │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Temporal Worker │
                    │   (Workflows)     │
                    └─────────┬─────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    ┌────▼────┐         ┌─────▼─────┐        ┌────▼────┐
    │PostgreSQL│         │  Redis    │        │  MinIO  │
    │(pgvector)│         │ (Cache)   │        │(Storage)│
    └──────────┘         └───────────┘        └─────────┘
```

## Services

### Control Plane (`@homeos/control-plane`)
**Port:** 3001

Core API service for authentication and resource management.

**Endpoints:**
- `POST /v1/auth/signin-with-apple` - Apple Sign In authentication
- `GET /v1/auth/me` - Get current user profile
- `GET /v1/workspaces` - List user workspaces
- `POST /v1/workspaces` - Create workspace
- `GET /v1/devices` - List registered devices
- `POST /v1/devices` - Register device
- `POST /v1/workspaces/:id/secrets` - Store encrypted secrets (BYOK)
- `POST /v1/runtime/token` - Generate runtime token for workspace

**Dependencies:**
- Fastify (HTTP framework)
- PostgreSQL (user data, workspaces)
- JWT authentication

### Runtime (`@homeos/runtime`)
**Port:** 3002

Real-time API for chat, tasks, and streaming.

**Endpoints:**
- `POST /v1/chat/turn` - Submit chat message and start workflow
- `GET /v1/tasks` - List tasks for workspace
- `GET /v1/tasks/:id` - Get task details with execution history
- `GET /v1/approvals` - List pending approvals
- `POST /v1/approvals/:id` - Approve or deny action
- `POST /v1/ingest/email` - Ingest email events
- `WS /v1/stream` - Real-time WebSocket stream

**Gateway Ports (Desktop Integration):**
- `18789` - WebSocket gateway
- `18790` - Bridge TCP
- `18793` - Canvas

**Dependencies:**
- Fastify with WebSocket
- Temporal (workflow client)
- PostgreSQL (task data)
- Redis (caching, rate limiting)

### Workflows (`@homeos/workflows`)
**Worker:** Connects to Temporal at :7233

Temporal worker executing durable workflows for all agentic tasks.

**Dependencies:**
- Temporal SDK
- Anthropic Claude API
- OpenAI API
- Twilio (telephony)
- Various external service integrations

---

## Workflows

### Core Workflows

| Workflow | Description | Activities Used |
|----------|-------------|-----------------|
| `ChatTurnWorkflow` | Main conversational AI loop with tool use | llm, tools, memory, events |
| `ReservationCallWorkflow` | Automated phone calls for reservations | telephony, llm, approvals |
| `MarketplaceSellWorkflow` | Sell items on eBay/FB Marketplace | marketplace, approvals |
| `HireHelperWorkflow` | Find and hire service providers | helpers, approvals |
| `DynamicIntegrationWorkflow` | Connect new services dynamically | integration, tools |

### School & Education

| Workflow | Description |
|----------|-------------|
| `DailyHomeworkCheckWorkflow` | Daily check of assignments due |
| `GradeMonitoringWorkflow` | Alert on grade changes |
| `CreateStudyPlanWorkflow` | AI-generated study plans |
| `SchoolEventsSyncWorkflow` | Sync school calendar events |

### Healthcare

| Workflow | Description |
|----------|-------------|
| `BookDoctorAppointmentWorkflow` | Find availability and book appointments |
| `MedicationReminderWorkflow` | Scheduled medication reminders |
| `HealthSummaryWorkflow` | Family health overview |

### Transportation

| Workflow | Description |
|----------|-------------|
| `BookRideWorkflow` | Book rides via Uber/Lyft |
| `TrackFamilyLocationWorkflow` | Family member location tracking |
| `CommuteAlertWorkflow` | Traffic and commute alerts |

### Meal Planning

| Workflow | Description |
|----------|-------------|
| `MealPlanWorkflow` | Weekly meal planning |
| `GroceryListWorkflow` | Generate grocery lists |
| `RecipeSuggestionWorkflow` | AI recipe suggestions |

### Home Maintenance

| Workflow | Description |
|----------|-------------|
| `ScheduleMaintenanceWorkflow` | Schedule routine maintenance |
| `MaintenanceReminderWorkflow` | Reminder for upcoming tasks |
| `EmergencyRepairWorkflow` | Handle emergency repairs |

### Family Communication

| Workflow | Description |
|----------|-------------|
| `FamilyAnnouncementWorkflow` | Broadcast announcements |
| `SharedCalendarSyncWorkflow` | Sync family calendars |
| `FamilyCheckInWorkflow` | Family member check-ins |
| `DailyFamilyDigestWorkflow` | Daily family summary |
| `FamilyEmergencyAlertWorkflow` | Emergency notifications |

### Wellness

| Workflow | Description |
|----------|-------------|
| `HydrationReminderWorkflow` | Water intake reminders |
| `MovementNudgeWorkflow` | Activity break reminders |
| `SleepHygieneWorkflow` | Bedtime routine prompts |
| `ScreenTimeWorkflow` | Screen time management |
| `PostureBreakWorkflow` | Posture break reminders |
| `EnergyOptimizationWorkflow` | Energy level optimization |
| `DailyWellnessCheckWorkflow` | Daily wellness check-in |

### Family Bonding

| Workflow | Description |
|----------|-------------|
| `FamilyDinnerWorkflow` | Coordinate family dinners |
| `GameNightWorkflow` | Plan game nights |
| `WeekendActivityWorkflow` | Weekend activity planning |
| `GratitudeMomentWorkflow` | Gratitude sharing |
| `OneOnOneTimeWorkflow` | Schedule one-on-one time |
| `FamilyTraditionWorkflow` | Maintain family traditions |

### Mental Load Reduction

| Workflow | Description |
|----------|-------------|
| `MorningBriefingWorkflow` | Daily morning briefing |
| `WeeklyPlanningWorkflow` | Weekly planning session |
| `ProactiveReminderWorkflow` | Proactive task reminders |
| `DecisionSimplificationWorkflow` | Simplify decisions |
| `EveningWindDownWorkflow` | Evening routine |
| `HouseholdCoordinationWorkflow` | Coordinate household tasks |

---

## Activities

Activities are the building blocks of workflows - atomic operations that interact with external services.

### LLM (`llm.ts`)
- `generateResponse` - Generate AI response with Claude/GPT
- `extractIntent` - Extract user intent from message
- `generateSummary` - Summarize content

### Tools (`tools.ts`)
Main tool router supporting:
- **Calendar** - Google Calendar (create, list, update, delete events, find free time)
- **Groceries** - Instacart Connect (search, add to cart, checkout)
- **Content** - Web fetching and summarization
- **Planning** - Task breakdown and prioritization
- **Weather** - Current conditions and forecast
- **Reminders** - Create, list, delete reminders
- **Notes** - Create and search notes
- **Search** - Web search via SerpAPI

### Memory (`memory.ts`)
- `storeMemory` - Store memories with embeddings (pgvector)
- `recall` - Semantic search over memories
- `getConversationContext` - Retrieve conversation history

### Telephony (`telephony.ts`)
- `makeCall` - Initiate outbound call via Twilio
- `sendSMS` - Send text message
- `transcribeCall` - Transcribe call recording

### Marketplace (`marketplace.ts`)
- `listItem` - List item for sale
- `getPriceEstimate` - Get market price estimate
- `getComparables` - Find comparable sold items

### Helpers (`helpers.ts`)
- `searchHelpers` - Search for service providers
- `requestQuotes` - Request quotes from providers
- `bookHelper` - Book a helper service

### Integration (`integration.ts`)
- `discoverServices` - Find compatible services (MCP, OpenAPI)
- `generateToolWrapper` - Generate code for new integrations
- `validateIntegration` - Test integration compatibility

### Education (`education.ts`)
- `listCourses` - Get student courses (Google Classroom, Canvas)
- `getAssignments` - Get upcoming/missing assignments
- `getGrades` - Get current grades
- `getHomeworkSummary` - AI-powered homework summary
- `generateStudyPlan` - Create study plans

### Healthcare (`healthcare.ts`)
- `searchDoctors` - Find doctors by specialty
- `getAvailableSlots` - Check appointment availability
- `bookAppointment` - Book medical appointment
- `getMedicationSchedule` - Get medication reminders

### Transportation (`transportation.ts`)
- `getRideEstimates` - Get Uber/Lyft estimates
- `bookRide` - Book a ride
- `getTrafficConditions` - Current traffic data
- `trackLocation` - Family location tracking

### Meal Planning (`mealplanning.ts`)
- `generateMealPlan` - Create weekly meal plan
- `getRecipeSuggestions` - Recipe ideas
- `generateGroceryList` - Create shopping list
- `checkPantry` - Check pantry inventory

### Home Maintenance (`homemaintenance.ts`)
- `getMaintenanceSchedule` - Upcoming maintenance tasks
- `searchServiceProviders` - Find contractors
- `scheduleService` - Book maintenance service
- `reportEmergency` - Emergency response info

### Family Comms (`familycomms.ts`)
- `sendFamilyMessage` - Broadcast to family
- `getFamilyCalendar` - Shared calendar events
- `getCheckIns` - Family check-in status
- `getFamilySummary` - Daily family digest

### Events (`events.ts`)
- `emitEvent` - Emit workflow event for streaming
- `logActivity` - Log activity for audit trail

### Approvals (`approvals.ts`)
- `requestApproval` - Request human approval
- `checkApproval` - Check approval status

### Composio (`composio.ts`)
- `executeComposioAction` - Execute Composio integrations
- `listAvailableActions` - List available Composio actions

---

## Infrastructure

### PostgreSQL (pgvector)
- **Port:** 5432
- **Purpose:** Primary data store with vector embeddings
- **Tables:** users, workspaces, devices, tasks, memories, secrets

### Redis
- **Port:** 6379
- **Purpose:** Caching, rate limiting, session storage, pub/sub

### MinIO
- **Ports:** 9000 (API), 9001 (Console)
- **Purpose:** Object storage (S3-compatible) for files, media

### Temporal
- **Ports:** 7233 (Server), 8080 (UI)
- **Purpose:** Durable workflow execution, task scheduling

### OpenTelemetry Collector
- **Ports:** 4317 (gRPC), 4318 (HTTP), 8888 (metrics)
- **Purpose:** Distributed tracing and metrics collection

---

## Shared Package (`@homeos/shared`)

Common types, schemas, and utilities shared across services.

### Types
- `Task` - Task state and execution
- `Approval` - Human-in-the-loop approval
- `Memory` - Memory storage format
- `Workspace` - Family workspace
- `Chat` - Chat messages and turns
- `Tools` - Tool definitions

### Schemas (Zod)
- Validation schemas for all API requests
- Type-safe request/response handling

### Crypto
- `envelope` - Envelope encryption for secrets
- `token` - JWT token utilities
- `secrets` - Secret management helpers

### Redaction
- PII redaction utilities
- Safe logging helpers

---

## iOS App (`apps/ios/HomeOS`)

SwiftUI-based iOS application.

### Features
- **Chat** - Conversational interface
- **Tasks** - View and manage tasks
- **Actions** - Quick actions and approvals
- **Settings** - App configuration

### Components
- `GlassSurface` - Glassmorphic UI components
- `TaskCard` - Task display card
- `ChatBubble` - Chat message bubble

### Networking
- `AuthManager` - Apple Sign In and JWT handling
- `NetworkManager` - API client
- `Configuration` - Environment configuration

### Storage
- `KeychainHelper` - Secure token storage

---

## Configuration

### Environment Variables

**Control Plane:**
```
PORT=3001
HOST=0.0.0.0
JWT_SECRET=<secret>
DATABASE_URL=postgres://...
```

**Runtime:**
```
PORT=3002
HOST=0.0.0.0
JWT_SECRET=<secret>
DATABASE_URL=postgres://...
REDIS_URL=redis://...
TEMPORAL_ADDRESS=localhost:7233
```

**Workflows:**
```
TEMPORAL_ADDRESS=localhost:7233
DATABASE_URL=postgres://...
REDIS_URL=redis://...
ANTHROPIC_API_KEY=<key>
OPENAI_API_KEY=<key>
TWILIO_ACCOUNT_SID=<sid>
TWILIO_AUTH_TOKEN=<token>
```

### Optional Integrations
- `GOOGLE_CALENDAR_CLIENT_ID/SECRET/REFRESH_TOKEN`
- `GOOGLE_CLASSROOM_CLIENT_ID/SECRET/REFRESH_TOKEN`
- `CANVAS_ACCESS_TOKEN/DOMAIN`
- `INSTACART_CLIENT_ID/SECRET`
- `OPENWEATHER_API_KEY`
- `SERPAPI_KEY`

---

## Development

### Prerequisites
- Node.js >= 22.0.0
- pnpm 9.15.0
- Docker & Docker Compose
- Xcode (for iOS development)

### Quick Start
```bash
# Install dependencies
pnpm install

# Start infrastructure
cd infra && docker compose up -d

# Start services (development mode)
pnpm run dev:services

# Type check
pnpm run typecheck

# Run tests
pnpm run test
```

### Project Structure
```
homeOS/
├── apps/
│   └── ios/                 # iOS SwiftUI app
├── docs/                    # Documentation
├── infra/                   # Docker Compose & config
├── packages/
│   └── shared/              # Shared types & utilities
└── services/
    ├── control-plane/       # Auth & workspaces API
    ├── runtime/             # Chat & real-time API
    ├── workflows/           # Temporal worker
    └── skill-factory/       # (planned) Skill generation
```

---

## Security

- **Authentication:** Apple Sign In with JWT tokens
- **Encryption:** BYOK envelope encryption for secrets
- **Approvals:** Human-in-the-loop for high-risk actions
- **Redaction:** PII redaction in logs
- **Transport:** HTTPS/WSS for all communications
