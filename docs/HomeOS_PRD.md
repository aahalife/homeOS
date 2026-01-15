# HomeOS iOS Platform - Comprehensive Product Requirements Document

> A family AI assistant platform that extends Clawdbot into a turnkey, consumer-ready experience for busy households.

---

## Executive Summary

HomeOS is an iOS-first family AI assistant platform that wraps Clawdbot's powerful agentic capabilities with automated provisioning, contextual consent, and progressive-disclosure UX. The platform enables busy households to benefit from AI automation without technical setup, supporting multiple deployment modes (cloud and local home hub).

**Target Launch:** MVP in 12-16 weeks with core chat, workflows, and 3-5 workflow packs.

---

## 1. Vision & Mission

### Vision
Every family has access to a warm, capable AI assistant that anticipates their needs, handles life's logistics, and gives parents back the mental bandwidth to be present with their loved ones.

### Mission
Build a turnkey family assistant platform that:
1. **Just works** - Opinionated defaults with zero technical setup required
2. **Feels like family** - Warm, competent, never robotic (see SOUL document)
3. **Respects autonomy** - Contextual consent, transparent automation, human-in-the-loop for high-risk actions
4. **Scales seamlessly** - From single-family cloud tenants to local home hub deployments

---

## 2. Goals & Success Metrics

| Goal | Metric | MVP Target | V1.0 Target |
|------|--------|------------|-------------|
| Fast onboarding | Time from signup to first completed workflow | < 15 minutes | < 10 minutes |
| Automation coverage | % of core workflows enabled by default | 50% | 80% |
| Trust & safety | % of high-risk actions with explicit consent | 100% | 100% |
| Reliability | Automation success rate without human retry | 85% | 95% |
| Adoption | Weekly active family members per household | ≥2 | ≥3 |
| Satisfaction | NPS from beta families | ≥ +30 | ≥ +40 |
| Performance | Chat response latency (median) | < 3s | < 2s |

---

## 3. Personas & User Journeys

### Primary Personas

#### 1. Primary Organizer Parent (Sarah, 38)
- **Pain points:** Drowning in logistics, mental load, juggling school/activities/work
- **Goals:** Proactive coordination, delegation, peace of mind
- **Tech comfort:** Medium - uses iPhone daily, familiar with apps
- **Primary channel:** iOS app, morning push notifications

#### 2. Partner/Co-parent (Mike, 40)
- **Pain points:** Wants to help but doesn't know what needs doing
- **Goals:** Clear task delegation, updates without micromanagement
- **Tech comfort:** Medium-high - prefers minimal interaction
- **Primary channel:** Push notifications, quick Telegram messages

#### 3. Teen (Emma, 15)
- **Pain points:** School stress, forgetting assignments, schedule conflicts
- **Goals:** Homework help, schedule awareness, autonomy
- **Tech comfort:** High - lives on phone
- **Primary channel:** iOS app, iMessage

#### 4. Grandparent/Elder (Grandma Rose, 78)
- **Pain points:** Isolation, medication management, doctor appointments
- **Goals:** Feel connected, stay independent, family engagement
- **Tech comfort:** Low - voice-first
- **Primary channel:** Voice calls (Twilio), SMS

#### 5. Caregiver (Maria, 55)
- **Pain points:** Coordinating care, tracking medications, emergency contacts
- **Goals:** Clear instructions, family updates, escalation paths
- **Tech comfort:** Low-medium
- **Primary channel:** SMS, voice calls

### User Journey: First Week

```
Day 0: Discovery & Signup
├── Marketing site → Choose deployment (Cloud recommended for MVP)
├── Email + payment
├── Automated provisioning (~5-10 min)
└── Welcome email with TestFlight link

Day 1: Personal Setup
├── Download iOS app (TestFlight)
├── Sign in with Apple
├── Household basics wizard (5 min)
│   ├── Family name, location, timezone
│   ├── Add family members (names, roles)
│   ├── Permissions (notifications, location, HealthKit)
│   └── Channel linking (Telegram optional)
├── Integration setup (5 min)
│   ├── Google Calendar OAuth
│   ├── Optional: Home Assistant, Notion
│   └── Skip for later option
└── Enable first workflow pack (Morning Launch)

Day 2-3: Initial Value
├── Receive first morning brief (auto-generated)
├── Send first chat message
├── Complete one delegated task
└── Invite partner/family member

Day 4-7: Expanding Use
├── Enable additional workflow packs
├── Approve first medium-risk automation
├── Set up elder care check-in (if applicable)
└── Customize preferences (quiet hours, notification tier)
```

---

## 4. Deployment Architecture

### 4.1 Managed Cloud (MVP Focus)

Primary deployment for consumer launch:

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS / Fly.io                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │Control    │  │ Runtime   │  │ Workflows │  │ Echo-TTS  │   │
│  │Plane:3001 │  │ :3002     │  │ (Temporal)│  │           │   │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └───────────┘   │
│        │              │              │                          │
│        └──────────────┴──────────────┘                          │
│                       │                                          │
│  ┌────────────────────┼────────────────────┐                    │
│  │     PostgreSQL     │      Redis         │    MinIO           │
│  │     (pgvector)     │    (Cache)         │  (Storage)         │
│  └────────────────────┴────────────────────┘                    │
│                       │                                          │
│             ┌─────────┴─────────┐                               │
│             │  Temporal Server  │                               │
│             └───────────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │ iOS App │    │Telegram │    │ Twilio  │
   │(SwiftUI)│    │   Bot   │    │Voice/SMS│
   └─────────┘    └─────────┘    └─────────┘
```

### 4.2 Home Hub (Phase 2)

Local deployment for power users and privacy-focused families:
- Installer package (macOS DMG, Windows EXE, Linux)
- Docker Compose for all services
- Tailscale for secure remote access
- Hybrid mode: local for LAN devices, cloud for heavy compute

---

## 5. Functional Requirements

### 5.1 Core Platform

#### 5.1.1 Authentication & Identity
- **Apple Sign In** (primary, mandatory for iOS)
- **Email magic link** (web fallback)
- **JWT tokens** with workspace-scoped claims
- **Family workspace** model with member roles:
  - `admin` - Full control, billing, member management
  - `adult` - Approve actions, edit preferences
  - `teen` - Limited autonomy, parent approval for some actions
  - `child` - View only, no direct automation
  - `caregiver` - Task-specific access, escalation rights
  - `guest` - Temporary, limited access

#### 5.1.2 Workspaces
- One workspace per family/household
- Workspace contains: members, devices, secrets, preferences, memories
- Multi-device support per member
- Data isolation between workspaces

#### 5.1.3 Secrets Management (BYOK)
- Envelope encryption with per-workspace keys
- Store integration tokens (Google, Twilio, etc.)
- Secret rotation reminders
- Audit log for secret access

### 5.2 iOS Application

#### 5.2.1 Information Architecture

| Tab | Purpose | Priority |
|-----|---------|----------|
| **Chat** | Conversational AI interface | P0 |
| **Tasks** | View/manage pending tasks and workflows | P0 |
| **Actions** | Quick actions, pending approvals | P1 |
| **Connections** | Integration status, family members | P1 |
| **Settings** | Preferences, account, support | P0 |

#### 5.2.2 Chat Interface (P0)
- Real-time messaging with streaming responses
- Voice input with transcription
- Voice output (TTS) option
- Message history with search
- Rich message types:
  - Text with markdown
  - Cards (tasks, approvals, summaries)
  - Quick action buttons
  - Attachments (images, files)

#### 5.2.3 Tasks View (P0)
- List of active workflows/tasks
- Status indicators (pending, running, needs approval, completed, failed)
- Tap to view details and execution history
- Swipe actions (complete, snooze, cancel)

#### 5.2.4 Actions View (P1)
- Pending approvals with context
- Quick action templates (e.g., "Morning brief now", "Check on Grandma")
- Workflow pack activation toggles
- Emergency SOS button

#### 5.2.5 Settings (P0)
- Profile & account management
- Family member management
- Integration connections (OAuth flows)
- Notification preferences
- Quiet hours
- Data & privacy controls

### 5.3 Backend Services

#### 5.3.1 Control Plane (`/v1/*`)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/signin-with-apple` | POST | Apple Sign In flow |
| `/auth/me` | GET | Current user profile |
| `/workspaces` | GET/POST | List/create workspaces |
| `/workspaces/:id` | GET/PUT/DELETE | Workspace CRUD |
| `/workspaces/:id/members` | GET/POST | Member management |
| `/workspaces/:id/secrets` | POST | Store encrypted secret |
| `/devices` | GET/POST | Device registration |
| `/runtime/token` | POST | Generate runtime JWT |
| `/preferences` | GET/PUT | User preferences |
| `/integrations` | GET/POST | Integration management |

#### 5.3.2 Runtime (`/v1/*`)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat/turn` | POST | Submit chat message, start workflow |
| `/chat/history` | GET | Conversation history |
| `/tasks` | GET | List tasks for workspace |
| `/tasks/:id` | GET/PUT | Task details, update |
| `/approvals` | GET | List pending approvals |
| `/approvals/:id` | POST | Approve/deny action |
| `/stream` | WS | Real-time event stream |
| `/voice/transcribe` | POST | Audio transcription |
| `/voice/synthesize` | POST | Text-to-speech |
| `/ingest/email` | POST | Email webhook |
| `/telegram/webhook` | POST | Telegram updates |
| `/whatsapp/webhook` | POST | WhatsApp updates |

### 5.4 Workflow Engine

#### 5.4.1 Core Workflows (P0)
- `ChatTurnWorkflow` - Main conversational AI loop with tool use
- `ApprovalWorkflow` - Human-in-the-loop approval handling
- `NotificationWorkflow` - Multi-channel notification delivery

#### 5.4.2 Domain Workflows (P1-P2)
| Domain | Workflows | Priority |
|--------|-----------|----------|
| **Morning/Evening** | MorningBriefingWorkflow, EveningWindDownWorkflow | P1 |
| **School** | DailyHomeworkCheckWorkflow, GradeMonitoringWorkflow | P1 |
| **Family Comms** | FamilyAnnouncementWorkflow, FamilyCheckInWorkflow | P1 |
| **Elder Care** | ElderCheckInWorkflow, MedicationReminderWorkflow | P2 |
| **Meal Planning** | MealPlanWorkflow, GroceryListWorkflow | P2 |
| **Home Maintenance** | ScheduleMaintenanceWorkflow, EmergencyRepairWorkflow | P2 |
| **Transportation** | BookRideWorkflow, CommuteAlertWorkflow | P2 |
| **Healthcare** | BookDoctorAppointmentWorkflow, MedicationReminderWorkflow | P2 |

### 5.5 Integrations

#### 5.5.1 Communication Channels
| Channel | Purpose | Priority |
|---------|---------|----------|
| **APNs** | iOS push notifications | P0 |
| **Telegram** | Chat channel, commands | P1 |
| **Twilio SMS** | Text notifications, 2FA | P1 |
| **Twilio Voice** | Elder check-ins, reservations | P2 |
| **WhatsApp** | International families | P3 |

#### 5.5.2 Calendar & Productivity
| Integration | Purpose | Priority |
|-------------|---------|----------|
| **Google Calendar** | Family scheduling | P0 |
| **iCloud Calendar** | Apple-native scheduling | P2 |
| **Notion** | Notes, knowledge base | P2 |
| **Google Classroom** | School assignments | P2 |

#### 5.5.3 Home & IoT
| Integration | Purpose | Priority |
|-------------|---------|----------|
| **Home Assistant** | Device control, sensors | P2 |
| **Tesla/EV** | Vehicle status, charging | P3 |
| **Smart Locks** | Access control (high-risk) | P3 |

---

## 6. Non-Functional Requirements

### 6.1 Performance
- Chat response latency: < 2s median, < 5s P95
- Workflow scheduling jitter: < 1 minute
- iOS app launch: < 2s cold start
- WebSocket reconnection: < 3s

### 6.2 Availability
- Cloud service uptime: 99.5% SLA
- Graceful degradation: offline mode with cached data
- Health monitoring with auto-restart

### 6.3 Security
- All traffic over HTTPS/WSS
- Per-workspace KMS encryption
- Device binding with biometric unlock
- Audit logs for sensitive operations
- PII redaction in logs

### 6.4 Privacy
- GDPR-compliant data handling
- Data residency options (US, EU)
- Granular consent management
- Right to deletion with 30-day retention

### 6.5 Scalability
- 20 concurrent members per family
- 1000+ workflows/day per workspace
- Horizontal scaling for runtime/workflows

---

## 7. Risk Framework

### Risk Tiers

| Tier | Description | Behavior | Examples |
|------|-------------|----------|----------|
| **Low** | Safe, reversible | Auto-execute silently | Read calendar, send notification, add reminder |
| **Medium** | Moderate impact | Execute with preference check | Order groceries under $75, send family text |
| **High** | Significant impact | Always require approval | Make phone call, unlock door, pay bill |
| **Critical** | Safety/financial | Multi-factor approval | Emergency contact, large payment |

### Approval Flow
1. Workflow identifies risk tier from action metadata
2. Low → Execute immediately
3. Medium → Check stored preferences; execute or request approval
4. High/Critical → Send approval envelope (push notification)
5. User reviews context, approves/denies
6. Audit log records decision
7. Optional: "Remember for future" preference storage

---

## 8. Workflow Packs

Pre-configured automation bundles for specific use cases:

### Pack 1: Morning Launch (P0)
- Daily briefing at configured time
- Weather, calendar, tasks, anomalies
- Personalized per family member
- **Skills:** `mental-load`, `family-comms`, `tools`

### Pack 2: School Ops (P1)
- Parse school emails
- Track assignments, deadlines
- Parent reminders
- **Skills:** `school`, `education`, `note-to-actions`

### Pack 3: Family Communications (P1)
- Broadcast announcements
- Chore tracking
- Shared calendar sync
- **Skills:** `family-comms`, `family-bonding`

### Pack 4: Elder Care Guardian (P2)
- Daily voice check-ins
- Medication reminders
- Caregiver escalation
- **Skills:** `elder-care`, `telephony`, `healthcare`

### Pack 5: Meal & Grocery (P2)
- Weekly meal planning
- Grocery list generation
- Instacart ordering
- **Skills:** `meal-planning`, `tools`

---

## 9. Development Phases

### Phase 1: Core Infrastructure (Weeks 1-4)
- [ ] Backend services deployed (Control Plane, Runtime)
- [ ] PostgreSQL + Redis + MinIO + Temporal running
- [ ] Apple Sign In flow working
- [ ] Basic workspace/member CRUD
- [ ] JWT authentication chain

### Phase 2: iOS App MVP (Weeks 3-6)
- [ ] Chat interface with streaming
- [ ] Voice input/output
- [ ] Tasks view
- [ ] Settings with profile/preferences
- [ ] Push notifications

### Phase 3: Workflow Engine (Weeks 5-8)
- [ ] ChatTurnWorkflow with tool use
- [ ] Approval flow end-to-end
- [ ] Memory storage/retrieval
- [ ] Notification router (push + multi-channel)

### Phase 4: Integrations (Weeks 7-10)
- [ ] Google Calendar OAuth
- [ ] Telegram bot setup
- [ ] Twilio SMS/Voice
- [ ] Integration health monitoring

### Phase 5: Workflow Packs (Weeks 9-12)
- [ ] Morning Launch pack
- [ ] School Ops pack
- [ ] Family Communications pack

### Phase 6: Polish & Beta (Weeks 11-14)
- [ ] Onboarding flow refinement
- [ ] Error handling & recovery
- [ ] Performance optimization
- [ ] Beta family onboarding

---

## 10. Open Questions & Decisions

| Question | Options | Decision | Rationale |
|----------|---------|----------|-----------|
| Telegram bot model | Shared vs. per-family | Per-family | Privacy, customization |
| Payment processing | Stripe vs. Apple IAP | Stripe | Web + app flexibility |
| Elder care voice | Twilio vs. native | Twilio | Reliability, reach |
| Calendar primary | Google vs. iCloud | Google | Wider adoption |
| Home automation | Home Assistant vs. native | Home Assistant | Ecosystem breadth |

---

## 11. Dependencies

### External Services
- **Anthropic Claude** - Primary LLM for chat/reasoning
- **OpenAI** - Embeddings, fallback LLM
- **Twilio** - Voice, SMS
- **Telegram Bot API** - Chat channel
- **Google APIs** - Calendar, Classroom, Drive
- **Apple** - Sign In, Push Notifications

### Internal Dependencies
- **Clawdbot** - Core agentic framework (treated as upstream dependency)
- **HomeOS Skills** - Domain-specific capabilities

---

## 12. Appendices

### A. API Schema Reference
See OpenAPI specs at `/docs` endpoint of each service.

### B. Database Schema
See `/infra/init-scripts/*.sql`

### C. Soul Document
See `/docs/MacAppPRD/SOUL.md` for personality/voice guidelines.

### D. Existing Documentation
- `/docs/ARCHITECTURE.md` - System architecture
- `/docs/IosPRD/` - Original PRD documents
- `/docs/homeskills/` - Skill specifications
