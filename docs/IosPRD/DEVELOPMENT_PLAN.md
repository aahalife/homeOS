# HomeOS iOS Platform - Development Plan

This document outlines the end-to-end development plan for building the HomeOS family AI assistant platform.

## Development Methodology

### Ralph Pattern for Autonomous Execution

This project uses the **Ralph pattern** from [snarktank/ralph](https://github.com/snarktank/ralph) for structured, autonomous AI-driven development:

1. **PRD to JSON** - User stories defined in `prd.json` with `passes: true/false` status
2. **Iteration Loop** - Each AI iteration completes ONE user story
3. **Progress Tracking** - `progress.txt` maintains learnings between iterations
4. **Quality Gates** - TypeScript/Swift compilation must pass before committing
5. **Git Memory** - Commits preserve context between iterations

### Key Files

| File | Purpose |
|------|---------|
| `prd.json` | User stories with pass/fail status |
| `prompt.md` | Instructions for AI agents |
| `progress.txt` | Append-only learnings log |
| `AGENTS.md` | Coding patterns and gotchas |

### Execution Command

To run autonomous development iterations:

```bash
# Manual iteration (review each change)
# 1. Read prd.json for next story
# 2. Implement the story
# 3. Run quality checks
# 4. Commit and update prd.json

# Or with a Ralph-compatible tool:
./scripts/ralph.sh [max_iterations]
```

---

## Phase Overview

| Phase | Name | Stories | Focus |
|-------|------|---------|-------|
| Phase 1 | iOS Foundation & Onboarding | US-001 to US-006, US-031, US-035 | Complete iOS app foundation |
| Phase 2 | Core Chat & Tasks | US-007 to US-014, US-032 | Chat interface and task management |
| Phase 3 | Workflows & Automation | US-015 to US-018, US-033 | Workflow packs and automation |
| Phase 4 | Integrations | US-019 to US-022, US-034 | External service connections |
| Phase 5 | Elder Care | US-023 to US-027 | Elder care features |
| Phase 6 | Cloud Provisioning | US-028 to US-030 | Automated deployment |

---

## Phase 1: iOS Foundation & Onboarding

**Goal:** Complete iOS app with full onboarding experience

### Stories

#### US-001: Create Home screen with Today view
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Home/HomeView.swift` (create)
- `apps/ios/HomeOS/HomeOS/App/ContentView.swift` (add Home tab)

**Implementation:**
1. Create HomeView with greeting header
2. Add weather widget (mock data initially)
3. Add Today's schedule section
4. Add pending items count
5. Add quick action buttons

#### US-002: Complete household setup wizard step
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/App/SetupFlowView.swift`

**Implementation:**
1. Add household basics form fields
2. Implement timezone picker
3. Add location/address input
4. Save to local storage or API

#### US-003: Add family member management to setup
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/App/SetupFlowView.swift`
- `apps/ios/HomeOS/HomeOS/Features/Settings/MemberRowView.swift` (create)

**Implementation:**
1. Create member add form
2. Implement role selector (Admin, Adult, Teen, Child)
3. Display member list with avatars
4. Enable member removal

#### US-004: Implement permissions request step
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/App/SetupFlowView.swift`

**Implementation:**
1. Create permission request cards
2. Trigger system permission dialogs
3. Track permission status
4. Handle optional permissions

#### US-005: Create workflow pack selection UI
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Workflows/WorkflowPackSelectionView.swift` (create)
- `apps/ios/HomeOS/HomeOS/App/SetupFlowView.swift`

**Implementation:**
1. Create pack grid/list view
2. Add toggle controls
3. Show pack descriptions
4. Pre-select recommended packs

#### US-006: Implement briefing time configuration
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/App/SetupFlowView.swift`
- `apps/ios/HomeOS/HomeOS/Features/Settings/PreferencesView.swift` (create)

**Implementation:**
1. Add time picker for morning briefing
2. Add quiet hours range picker
3. Show preview of briefing content
4. Save preferences

### Phase 1 Deliverables
- Complete onboarding wizard (6 steps)
- Home screen with day overview
- Settings with preferences
- Member management

---

## Phase 2: Core Chat & Tasks

**Goal:** Functional chat interface with streaming and task management

### Stories

#### US-007: Implement chat message sending
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Chat/ChatView.swift`
- `apps/ios/HomeOS/HomeOS/Features/Chat/ChatViewModel.swift`

**Implementation:**
1. Add text input field
2. Implement send button
3. Call /v1/chat/turn API
4. Show user message in chat
5. Add loading indicator

#### US-008: Implement streaming response display
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Chat/ChatViewModel.swift`
- `apps/ios/HomeOS/HomeOS/Networking/WebSocketManager.swift` (create)

**Implementation:**
1. Create WebSocket connection to /v1/stream
2. Handle streaming tokens
3. Update chat bubble in real-time
4. Handle connection errors

#### US-009: Add voice input to chat
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Chat/VoiceInputView.swift` (create)
- `apps/ios/HomeOS/HomeOS/Features/Chat/ChatView.swift`

**Implementation:**
1. Add microphone button
2. Implement Speech framework recording
3. Convert speech to text
4. Show transcription in input

#### US-010: Display inline tool results in chat
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/DesignSystem/Components/ToolResultCard.swift` (create)
- `apps/ios/HomeOS/HomeOS/Features/Chat/ChatBubble.swift`

**Implementation:**
1. Create card components for different tool types
2. Parse tool results from API response
3. Render inline in chat stream
4. Make cards interactive

### Phase 2 Deliverables
- Full chat interface with send/receive
- WebSocket streaming
- Voice input
- Inline tool results
- Task list and detail views
- Approval UI with push notifications

---

## Phase 3: Workflows & Automation

**Goal:** Enable and configure workflow packs

### Stories

#### US-015: Create workflow pack management screen
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Workflows/WorkflowPacksView.swift` (create)

**Implementation:**
1. List all 20 workflow packs
2. Add category filters
3. Show pack status indicators
4. Enable/disable toggles

#### US-017: Add Morning Launch workflow backend
**Files to modify:**
- `services/workflows/src/workflows/MorningLaunchWorkflow.ts` (create)
- `services/workflows/src/workflows/index.ts`

**Implementation:**
1. Create Temporal workflow
2. Fetch calendar events
3. Get weather data
4. Generate summary via LLM
5. Schedule notification delivery

### Phase 3 Deliverables
- Workflow pack management UI
- Pack configuration forms
- Morning Launch workflow
- School Ops workflow
- Notification delivery system

---

## Phase 4: Integrations

**Goal:** Connect external services (Google, Telegram, Home Assistant)

### Integration Architecture

```
┌─────────────────┐
│   iOS App       │
│ (Connections)   │
└────────┬────────┘
         │ OAuth / Token
         ▼
┌─────────────────┐
│ Control Plane   │
│ (Secrets API)   │
└────────┬────────┘
         │ Encrypted Storage
         ▼
┌─────────────────┐
│ Runtime/Workflows│
│ (Use Tokens)    │
└─────────────────┘
```

### Stories

#### US-019: Add Google Calendar OAuth flow
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Connections/GoogleCalendarConnector.swift` (create)
- `services/control-plane/src/routes/integrations.ts`

**Implementation:**
1. Implement ASWebAuthenticationSession OAuth
2. Exchange code for tokens
3. Store tokens via secrets API
4. Show connection status

#### US-021: Add Telegram channel linking
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/Connections/TelegramConnector.swift` (create)
- `services/control-plane/src/routes/telegram.ts`

**Implementation:**
1. Generate bot invite link
2. Display QR code
3. Send verification message
4. Store Telegram handle

### Phase 4 Deliverables
- Google Calendar sync
- Telegram bot linking
- Home Assistant connection
- Google Classroom integration

---

## Phase 5: Elder Care

**Goal:** Complete elder care feature with AI phone calls

### Elder Care Architecture

```
┌─────────────────┐
│   iOS App       │
│ (Elder Profile) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Temporal Worker │
│ (Check-In WF)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Twilio Voice    │
│ (AI Call)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Escalation      │
│ (SMS/Push)      │
└─────────────────┘
```

### Stories

#### US-023: Add elder profile management
**Files to modify:**
- `apps/ios/HomeOS/HomeOS/Features/ElderCare/ElderProfileView.swift` (create)
- `apps/ios/HomeOS/HomeOS/Features/ElderCare/ElderProfileViewModel.swift` (create)

**Implementation:**
1. Create profile form
2. Add medication list management
3. Add emergency contacts
4. Configure check-in preferences

#### US-025: Add Twilio voice call workflow
**Files to modify:**
- `services/workflows/src/workflows/ElderCheckInWorkflow.ts` (create)
- `services/workflows/src/activities/telephony.ts`

**Implementation:**
1. Create scheduled workflow
2. Initiate Twilio call
3. Run conversational AI
4. Capture wellness data
5. Escalate if needed

### Phase 5 Deliverables
- Elder profile management
- Check-in scheduling
- AI voice calls via Twilio
- Wellness dashboard
- Escalation alerts

---

## Phase 6: Cloud Provisioning

**Goal:** Automated tenant deployment on AWS

### Provisioning Architecture

```
┌─────────────────┐
│ tenant create   │
│ (CLI script)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Terraform       │
│ (AWS Resources) │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│Telegram│ │Twilio │
│BotFather││ API   │
└───────┘ └───────┘
         │
         ▼
┌─────────────────┐
│ Smoke Tests     │
│ (Verify Health) │
└─────────────────┘
```

### Stories

#### US-028: Create Terraform module for tenant infrastructure
**Files to create:**
- `infra/terraform/tenant/main.tf`
- `infra/terraform/tenant/variables.tf`
- `infra/terraform/tenant/outputs.tf`

**Implementation:**
1. VPC with private subnets
2. ECS cluster for services
3. RDS PostgreSQL
4. S3 bucket for files
5. Secrets Manager

#### US-029: Add tenant provisioning script
**Files to create:**
- `scripts/tenant-provision.sh`
- `scripts/lib/telegram-bot.sh`
- `scripts/lib/twilio-number.sh`

**Implementation:**
1. Create tenant record
2. Run Terraform
3. Provision Telegram bot
4. Provision Twilio number
5. Generate onboarding link

### Phase 6 Deliverables
- Terraform modules
- Provisioning script
- Telegram bot auto-creation
- Twilio number provisioning
- Smoke test suite

---

## Quality Checklist

Before marking any story as `passes: true`:

### iOS Stories
- [ ] Swift code compiles without errors
- [ ] SwiftUI previews work
- [ ] No SwiftLint warnings (if configured)
- [ ] UI matches design spec
- [ ] Accessibility labels present

### Backend Stories
- [ ] TypeScript compiles (`pnpm run typecheck`)
- [ ] No ESLint errors
- [ ] Tests pass (`pnpm test`)
- [ ] API endpoints documented
- [ ] Error handling in place

### Integration Stories
- [ ] OAuth flow tested end-to-end
- [ ] Tokens stored securely
- [ ] Connection status accurate
- [ ] Disconnect/revoke works

### Workflow Stories
- [ ] Workflow deterministic (no Date.now in workflow)
- [ ] Activities handle failures gracefully
- [ ] Temporal UI shows workflow
- [ ] Notifications deliver

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Apple Sign In issues in simulator | Test on real device, use dev passcode fallback |
| WebSocket connection drops | Implement reconnection logic with exponential backoff |
| Temporal workflow versioning | Use workflow versioning from start |
| OAuth token expiry | Implement automatic refresh in background |
| Twilio call quality | Test with real phones, have SMS fallback |

---

## Success Criteria

### MVP (Phase 1-2)
- User can complete onboarding in <15 minutes
- Chat interface works with streaming responses
- Morning briefing notification delivers
- Basic task management functional

### Beta (Phase 1-4)
- All core integrations working (Google, Telegram)
- 3+ workflow packs active
- Approval flow complete
- NPS from beta users ≥ +30

### Launch (Phase 1-6)
- Cloud provisioning automated
- Elder care feature complete
- All 35 user stories pass
- <2s chat latency
- 99.5% uptime

---

## Next Steps

1. **Start with US-001** - Create Home screen with Today view
2. Run quality checks after each story
3. Update `progress.txt` with learnings
4. Commit with `feat: [US-XXX] - [Title]` format
5. Set `passes: true` in `prd.json`
6. Proceed to next story

The Ralph pattern ensures consistent progress with quality gates at each step.
