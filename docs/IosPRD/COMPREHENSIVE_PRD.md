# HomeOS iOS Platform - Comprehensive Product Requirements Document

**Version:** 2.0  
**Date:** January 2025  
**Status:** Active Development  
**Branch:** HomeOS-IOS

---

## Executive Summary

HomeOS is a turnkey, family-ready AI assistant platform that extends Clawdbot into a comprehensive household coordination system spanning iOS, web, Telegram, voice, and telephony. It wraps Clawdbot, HomeOS skills, and ClawdHub integrations with automated provisioning, contextual consent, and progressive-disclosure UX so busy households can benefit without technical setup.

### Vision Statement

Transform Clawdbot from a technical CLI-based assistant into a consumer-ready family platform that:
- **Just works** on day one with opinionated automation packs
- Provides a **native iOS experience** with Apple-quality design
- Supports **two deployment modes**: Home Hub (local) or Managed Cloud (AWS)
- Implements **guardrails + consent** for risky actions, silent automation for low-risk tasks
- Targets **real household pains** with workflow packs (scheduling, school, elder care, etc.)

### Key Problems Solved

1. **Technical Barrier** - Clawdbot requires CLI setup, Telegram bot registration, gateway configuration
2. **Mental Load Crisis** - Parents spend 2+ hours daily on household coordination
3. **Fragmented Tools** - Families use 5+ disconnected apps for coordination
4. **Elder Care Gap** - No simple, AI-powered check-in solution for aging parents
5. **Decision Fatigue** - Constant small decisions drain cognitive resources

---

## Success Metrics

| Goal | Metric | Target |
| --- | --- | --- |
| Fast onboarding | Median time from signup to first completed workflow | < 15 minutes |
| Automation coverage | % of core workflows enabled by default | 80% |
| Trust & safety | % of high-risk actions with explicit consent | 100% |
| Reliability | Automation success rate without human retry | 95% |
| Adoption | Weekly active family members (per household) | ≥3 |
| Satisfaction | NPS from beta families | ≥ +40 |
| Daily active usage | Menu bar/app interaction | 80% of days |
| Mental load reduction | Hours saved per week per family | 5+ hours |

---

## Target Users & Personas

### 1. Primary Organizer Parent (Primary User)
**Demographics:** Parent (often mom), ages 30-50, Mac/iPhone user  
**Pain Points:**
- Coordinates all family schedules and logistics
- Manages children's education and activities
- Worries about aging parents
- Feels overwhelmed by the "invisible labor"

**Needs:**
- Proactive coordination without manual input
- Single dashboard for family status
- Morning/evening briefings
- Delegated channel for tasks

### 2. Partner/Co-parent
**Demographics:** Working parent, needs visibility  
**Needs:**
- Updates on family status
- Easy task delegation acceptance
- Mobile-first notifications
- Quick actions without full app engagement

### 3. Teens (13-17)
**Demographics:** Digital natives, value independence  
**Needs:**
- Homework and schedule reminders
- iMessage integration (not another app)
- Independence with guardrails
- Quick answers without parent oversight

### 4. Children (6-12)
**Demographics:** Learning responsibility  
**Needs:**
- Simple task lists and chore tracking
- Fun, encouraging interactions
- Age-appropriate privacy
- Homework help

### 5. Grandparents/Caregivers
**Demographics:** Ages 65+, varying tech comfort  
**Needs:**
- Voice/telephony channel (phone calls)
- Simple check-in conversations
- Medication reminders during calls
- Engagement without apps

### 6. Remote Power User
**Demographics:** Tech-comfortable family member  
**Needs:**
- Advanced automation customization
- Observability and debugging tools
- Workflow editing capabilities
- Integration management

---

## Deployment Modes

### Mode 1: Managed Cloud (Primary)
**Description:** Fully automated AWS deployment via clawdinators  
**Components:**
- Dedicated AWS account or isolated namespace per family
- ECS/Kubernetes running Clawdinator images + HomeOS sidecars
- RDS Postgres (tenant DB), Redis (cache/session), S3 (files/memory)
- Secrets Manager for API keys, Telegram/Twilio tokens
- Pre-configured Telegram bot, Twilio numbers, webhook endpoints

**User Experience:**
1. Sign up on marketing site
2. Receive welcome email with TestFlight link
3. Open iOS app, sign in with Apple
4. Complete onboarding wizard
5. Everything works

### Mode 2: Home Hub (Advanced)
**Description:** Local installation on user's Mac/Linux/Windows  
**Components:**
- Docker Compose or native binaries
- Local Clawdbot Gateway, Workflow Orchestrator, Postgres/SQLite
- Optional secure tunnel (Tailscale/ZeroTier) for remote access
- Auto-update agent with rollback

**User Experience:**
1. Download installer from website
2. Run GUI wizard (configures Clawdbot)
3. Optional: Configure remote relay
4. Use iOS app connected to local gateway

### Mode 3: Hybrid
**Description:** Home hub for LAN devices, cloud for heavy workloads  
**Components:**
- Local hub handles smart home, local files
- Cloud handles telephony, heavy AI processing
- Secure message bus links local + cloud

---

## Platform Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         iOS App (SwiftUI)                        │
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

### Service Components

| Component | Port | Responsibilities |
| --- | --- | --- |
| **Control Plane** | 3001 | Authentication, workspaces, member management, secrets |
| **Runtime** | 3002 | Chat API, WebSocket streaming, task management, approvals |
| **Workflows Worker** | Temporal | Durable workflow execution, scheduling, retries |
| **Notification Router** | Internal | Push/SMS/Telegram fan-out, quiet hours, escalation |

### Data Stores

| Store | Purpose | Usage |
| --- | --- | --- |
| **PostgreSQL** | Primary data | Users, workspaces, tasks, memories (pgvector) |
| **Redis** | Caching | Sessions, rate limiting, pub/sub |
| **S3/MinIO** | Files | Attachments, media, exports |
| **Secrets Manager** | Credentials | API keys, tokens (encrypted) |

---

## iOS App Specification

### Information Architecture

| Surface | Description | Components |
| --- | --- | --- |
| **Home** | Today view + key alerts | Morning brief, upcoming events, quick actions |
| **Chat** | Conversational interface | Thread list, message bubbles, voice input |
| **Tasks** | Workflow status | Active tasks, pending approvals, completed |
| **Actions** | Quick actions | Approval sheets, one-tap commands |
| **Connections** | Integrations | Connected services, OAuth flows |
| **Settings** | Configuration | Family, members, preferences, advanced |

### Design System

**Typography:**
- SF Pro Display (titles) - 24/32pt
- SF Pro Text (body) - 17pt
- Caption - 13pt

**Color Palette:**
- Background: #F5F5F7 (soft neutral)
- Primary: System Blue
- Domain colors: Family (blue), School (purple), Health (teal), Home (orange)

**Components:**
- `GlassSurface` - Glassmorphic containers
- `TaskCard` - Task display with status
- `ChatBubble` - Message bubbles with markdown support
- `ApprovalSheet` - Action confirmation with risk badge

### Key Screens

#### 1. Home Screen
```
┌─────────────────────────────────────┐
│  Good morning, Sarah!               │
│  ☀️ 72°F  Sunny                     │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ TODAY                           ││
│  │ 8:00  School dropoff            ││
│  │ 3:30  Emma → Soccer             ││
│  │ 5:00  Jack → Piano              ││
│  │ 6:30  Family dinner             ││
│  └─────────────────────────────────┘│
│                                     │
│  ⚠️ 2 items need attention          │
│                                     │
│  ╔═════════════════════════════════╗│
│  ║     Ask HomeOS...         🎤    ║│
│  ╚═════════════════════════════════╝│
└─────────────────────────────────────┘
```

#### 2. Chat Screen
- Thread list showing conversations
- Message bubbles with agent responses
- Inline tool results (calendar events, task cards)
- Voice input button
- Approval cards inline

#### 3. Approval Flow
- Push notification with action summary
- In-app sheet: intent, context, risk badge, rollback plan
- Buttons: Approve, Deny, Ask HomeOS
- "Remember for future" option for medium risk

### Onboarding Flow

1. **Sign-In** - Apple Sign In (passwordless)
2. **Household Basics** - Family name, location, timezone, members
3. **Permissions** - Notifications, location (optional), HealthKit (optional)
4. **Channel Linking** - Telegram QR, SMS verification
5. **Integration Setup** - Google, Microsoft, Home Assistant cards
6. **Workflow Pack Selection** - Morning Launch, School Ops, Elder Care
7. **Consent & Guardrails** - Risk tiers, auto-approve rules
8. **Final Checklist** - Briefing time, quiet hours, emergency contacts

---

## Workflow Packs (20 Total)

### Core Packs (Enabled by Default)

#### 1. Morning Launch
**Goal:** Start each day aligned with weather, schedules, reminders  
**Trigger:** Daily at configured time per member  
**Skills:** `mental-load`, `family-comms`, `tools`, `transportation`, `healthcare`  
**Steps:**
1. Gather calendar, weather, tasks, chore board
2. Detect anomalies/conflicts
3. Assemble personalized summary
4. Deliver via push/Telegram/email

#### 2. School Ops
**Goal:** Handle school logistics, forms, events, assignments  
**Trigger:** New school emails, calendar events, manual commands  
**Skills:** `school`, `education`, `note-to-actions`, `telephony`, `family-comms`  
**Steps:**
1. Parse email → classify (form, payment, event)
2. Auto-fill forms where possible
3. Add to calendar
4. Remind responsible parent/child
5. Queue telephony if portal login needed

#### 3. Elder Care Guardian
**Goal:** Ensure seniors are engaged and safe  
**Trigger:** Daily check-in schedule, medication times  
**Skills:** `elder-care`, `telephony`, `healthcare`, `mental-load`  
**Steps:**
1. Twilio voice call with warm conversational tone
2. Capture response, wellness questions
3. Handle medication reminders during call
4. Escalate if no answer (SMS/call caregivers)
5. Log mood/notes for family dashboard

#### 4. Household Communications & Chores
**Goal:** Keep everyone aligned  
**Trigger:** Daily/weekly schedule, manual commands  
**Skills:** `family-comms`, `family-bonding`, `mental-load`, `tools`  
**Steps:**
1. Send announcements with priority levels
2. Track acknowledgments
3. Rotate chores by schedule
4. Escalate overdue tasks

### Additional Packs (20 total - see WORKFLOW_PACKS.md)
- Activity Logistics
- Home Maintenance & Safety
- Meal & Grocery Ops
- Health & Wellness Steward
- Travel Concierge
- Financial & Bills Sentinel
- Mental Load Relief
- Marketplace & Errands Runner
- Hospitality / Guest Prep
- Emergency & Crisis Playbook
- Home Energy & Climate Manager
- Transportation & Carpool Coordinator
- Memory Keeper & Family Archivist
- Habit Builder & Wellness Coach
- Teen Success Pack
- Little Kids Routine Pack

---

## Integration Matrix

### Messaging & Communication
| Integration | Purpose | Automation | User Inputs |
| --- | --- | --- | --- |
| **Telegram Bot** | Primary chat channel | Auto-created per tenant | Usernames for allowlist |
| **Twilio Voice/SMS** | Calls + SMS | Provisioned number | Phone numbers, emergency contacts |
| **APNs** | iOS push | Auto-configured | Device registration (auto) |

### Calendars & Productivity
| Integration | Purpose | Auth Method |
| --- | --- | --- |
| **Google Calendar** | Schedule sync | OAuth |
| **iCloud Calendar** | Apple ecosystem | App-specific password |
| **Outlook/M365** | Enterprise users | MS Graph OAuth |
| **Notion** | Shared knowledge base | API token |

### Home Automation
| Integration | Mechanism | Risk Level |
| --- | --- | --- |
| **Home Assistant** | Long-lived token | Medium |
| **Philips Hue** | OpenHue skill | Low |
| **Smart Locks** | via Home Assistant | HIGH |
| **Sonos** | sonoscli skill | Low |
| **Tesla/EV** | tessie skill | Medium |

### Education
| Integration | Purpose |
| --- | --- |
| **Google Classroom** | Homework, grades |
| **Canvas LMS** | Assignments, grades |
| **School Portals** | Telephony automation |

---

## Risk & Approval Framework

### Risk Tiers

| Level | Description | Approval | Examples |
| --- | --- | --- | --- |
| **LOW** | Read-only, informational | None | Check calendar, weather lookup |
| **MEDIUM** | Limited impact, reversible | Ask once, remember | Create reminder, add calendar event |
| **HIGH** | Financial, external, irreversible | Always confirm | Make phone calls, send payments, unlock doors |

### HIGH Risk Actions (Always Require Approval)
- Making phone calls to external parties
- Financial transactions > $50
- Posting to social media or marketplaces
- Sending messages on user's behalf
- Modifying shared calendar events
- Purchasing items
- Sharing personal information externally
- Unlocking smart locks
- Medical advice or actions

### Approval Envelope Structure
```typescript
interface ApprovalEnvelope {
  id: string;
  action: string;
  riskLevel: 'low' | 'medium' | 'high';
  context: {
    who_requested: string;
    related_thread?: string;
    affected_members: string[];
  };
  rollback_plan?: string;
  expires_at: Date;
  status: 'pending' | 'approved' | 'denied' | 'expired';
  approved_by?: string;
  approved_at?: Date;
}
```

---

## Security & Privacy

### Data Principles
1. **Local by Default** - All family data stored on device/tenant
2. **Encrypted at Rest** - Using platform keychain and KMS
3. **Minimal Permissions** - Request only what's needed, when needed
4. **Transparent Processing** - Clear indicators when AI is processing
5. **User Control** - Easy export, deletion, visibility

### Security Controls
- **Authentication:** Apple Sign In with JWT tokens
- **Encryption:** BYOK envelope encryption for secrets
- **Network:** HTTPS/WSS, private subnets, zero public SSH
- **Audit:** Immutable logs, approval tracking
- **Device Trust:** Biometric for high-risk approvals

### Data Residency
- Default: US-West-2
- Option for EU families: EU-West-1
- Home Hub: All data local

---

## Non-Functional Requirements

| Category | Requirement | Target |
| --- | --- | --- |
| **Availability** | Cloud tenants uptime | ≥99.5% |
| **Availability** | Home Hub auto-restart | Offline-first caching |
| **Security** | Per-tenant isolation | KMS keys, namespace separation |
| **Privacy** | Data residency | Choice of region |
| **Performance** | Chat latency | <2s median |
| **Performance** | Automation scheduling jitter | <1 minute |
| **Scalability** | Members per family | Up to 20 |
| **Scalability** | Workflows per day | Thousands |

---

## Implementation Phases

### Phase 0: Foundation (Current State)
**Status:** Partially Complete  
**Deliverables:**
- ✅ Basic iOS app structure (SwiftUI)
- ✅ Control Plane service
- ✅ Runtime service with WebSocket
- ✅ Temporal workflows worker
- ✅ PostgreSQL with pgvector
- ✅ Basic authentication (Apple Sign In)
- ⬜ Full onboarding flow
- ⬜ Workflow pack activation UI

### Phase 1: iOS MVP
**Duration:** 6-8 weeks  
**Scope:**
- Complete onboarding wizard
- Home screen with morning brief
- Chat interface with streaming
- Basic task management
- Push notifications
- Settings and member management

**Success Criteria:**
- User can sign up and complete onboarding in <15 minutes
- Morning briefing delivers at configured time
- Chat responses stream in <2s

### Phase 2: Core Workflows
**Duration:** 6 weeks  
**Scope:**
- Morning Launch workflow
- School Ops workflow
- Household Communications workflow
- Workflow pack activation UI
- Calendar integration (Google, Apple)

**Success Criteria:**
- 3+ workflow packs functional
- Calendar events sync correctly
- Notifications deliver reliably

### Phase 3: Elder Care
**Duration:** 6 weeks  
**Scope:**
- Elder profiles in app
- Twilio voice integration
- Scheduled check-in calls
- Wellness tracking dashboard
- Escalation to caregivers

**Success Criteria:**
- Successful AI phone calls
- Wellness data captured and displayed
- Alert system for missed check-ins

### Phase 4: Integrations & Polish
**Duration:** 6 weeks  
**Scope:**
- Google Classroom integration
- Home Assistant integration
- Meal planning workflow
- Approval UI improvements
- Performance optimization

**Success Criteria:**
- External integrations functional
- App feels fast and responsive
- NPS ≥ +40 from beta users

### Phase 5: Cloud Provisioning
**Duration:** 4 weeks  
**Scope:**
- Terraform modules for AWS
- Automated tenant provisioning
- Telegram bot auto-creation
- Twilio number provisioning
- Health checks and monitoring

**Success Criteria:**
- New tenant spins up in <10 minutes
- All smoke tests pass automatically
- Zero manual configuration required

---

## Open Questions

1. **Pricing Model** - How to price cloud vs home hub? (Meter by workflows? channels? flat fee?)
2. **Multi-Tenancy** - Should Telegram bot be shared multi-tenant or per family? (Default: per family for privacy)
3. **Financial Automation** - Depth allowed before licensing concerns? (Start read-only, manual confirm for payments)
4. **Data Residency** - How to handle EU families? (Region-specific AWS accounts)
5. **Home Hub Updates** - How to handle automatic updates safely? (Delta downloads, staged rollout)

---

## Appendix A: Existing Codebase

### iOS App Structure
```
apps/ios/HomeOS/HomeOS/
├── App/
│   ├── ContentView.swift       # Main tab navigation
│   ├── HomeOSApp.swift         # App entry point
│   ├── OnboardingView.swift    # Sign-in screen
│   └── SetupFlowView.swift     # Onboarding wizard
├── DesignSystem/
│   ├── Components/
│   │   ├── ChatBubble.swift
│   │   └── TaskCard.swift
│   └── Glass/
│       └── GlassSurface.swift
├── Features/
│   ├── Actions/
│   ├── Chat/
│   ├── Connections/
│   ├── Settings/
│   └── Tasks/
├── Networking/
│   ├── AuthManager.swift
│   ├── NetworkManager.swift
│   └── Configuration.swift
└── Storage/
    └── KeychainHelper.swift
```

### Backend Services
```
services/
├── control-plane/    # Auth, workspaces, secrets
├── runtime/          # Chat API, WebSocket, tasks
├── workflows/        # Temporal worker, activities
└── echo-tts/         # Text-to-speech service
```

### Shared Package
```
packages/shared/
└── src/
    ├── crypto/       # Envelope encryption
    ├── redaction/    # PII redaction
    ├── schemas/      # Zod validation
    └── types/        # TypeScript types
```

---

## Appendix B: Ralph-Style Execution

This project uses the Ralph pattern for autonomous AI-driven development:

1. **PRD to JSON** - Convert this document to `prd.json` with atomic user stories
2. **Iteration Loop** - Each AI iteration completes one story
3. **Progress Tracking** - `progress.txt` maintains learnings
4. **Quality Gates** - TypeScript check, linting, tests must pass
5. **Git Memory** - Commits preserve context between iterations

See `prd.json` for the structured user stories ready for autonomous execution.

---

## Document History

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| 1.0 | Jan 2025 | PRD Team | Initial draft (separate docs) |
| 2.0 | Jan 2025 | Consolidated | Merged all IosPRD documents |

---

*This PRD is the single source of truth for the HomeOS iOS platform. Updates should be tracked in version control.*
