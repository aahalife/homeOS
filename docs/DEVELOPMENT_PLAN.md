# HomeOS iOS Platform - Development Plan

This document provides a detailed execution plan for building HomeOS end-to-end, organized by phase with dependencies, acceptance criteria, and implementation guidance.

---

## Overview

HomeOS is a family AI assistant platform that wraps Clawdbot with:
- Native iOS app (SwiftUI)
- Cloud backend (Fastify + Temporal)
- Multi-channel communication (Push, Telegram, Twilio)
- Workflow packs for family automation

**Target:** MVP in 12-16 weeks with core chat, workflows, and 3-5 automation packs.

---

## Phase 1: Core Infrastructure (Weeks 1-4)

### Goal
Establish backend foundation with authentication, data persistence, and workspace management.

### Prerequisites
- Node.js 22+
- Docker & Docker Compose
- PostgreSQL 16 with pgvector
- Redis 7
- Xcode 15+ (for iOS)

### User Stories

| ID | Story | Estimate | Dependencies |
|----|-------|----------|--------------|
| US-001 | Initialize database schema | 2h | Docker setup |
| US-002 | Apple Sign In endpoint | 4h | US-001 |
| US-003 | Workspace CRUD | 3h | US-001 |
| US-004 | Member management | 3h | US-003 |
| US-005 | BYOK secrets storage | 4h | US-003 |
| US-006 | Runtime token generation | 2h | US-002 |

### Implementation Notes

#### Database Schema (US-001)

Existing migrations in `/infra/init-scripts/`:
- `01-init-extensions.sql` - Enable pgvector, uuid-ossp
- `02-create-tables.sql` - Core tables
- `03-feature-tables.sql` - Feature-specific tables

Verify all tables are created:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

#### Apple Sign In (US-002)

Backend flow:
1. iOS sends `identityToken` from ASAuthorizationAppleIDCredential
2. Backend validates JWT signature with Apple's public keys
3. Extract `sub` (user ID), `email` from token
4. Create/update user record
5. Return HomeOS JWT

Key file: `services/control-plane/src/routes/auth.ts`

Apple JWKS endpoint: `https://appleid.apple.com/auth/keys`

#### Secrets Encryption (US-005)

Use envelope encryption pattern:
1. Generate data encryption key (DEK) per secret
2. Encrypt DEK with workspace master key (KEK)
3. Store encrypted DEK + encrypted data

Key file: `packages/shared/src/crypto/envelope.ts`

### Deliverables
- [ ] `docker compose up` starts all infrastructure
- [ ] Control plane responds on `:3001/health`
- [ ] Apple Sign In returns JWT
- [ ] Workspace CRUD works via API
- [ ] Member roles enforced

---

## Phase 2: iOS App MVP (Weeks 3-6)

### Goal
Functional iOS app with chat, tasks, and settings that connects to backend.

### User Stories

| ID | Story | Estimate | Dependencies |
|----|-------|----------|--------------|
| US-007 | iOS auth integration | 4h | US-002 |
| US-008 | Chat message sending | 4h | US-007 |
| US-009 | WebSocket streaming | 6h | US-008 |
| US-010 | Voice transcription | 4h | US-008 |
| US-011 | Tasks list view | 3h | US-007 |
| US-012 | Push notifications | 4h | US-007 |
| US-013 | Settings/preferences | 3h | US-007 |

### Implementation Notes

#### Auth Integration (US-007)

Current state in `AuthManager.swift`:
- Has Apple Sign In button
- Needs to send token to backend
- Store JWT in Keychain

```swift
// After ASAuthorizationController success:
guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
      let identityToken = appleIDCredential.identityToken,
      let tokenString = String(data: identityToken, encoding: .utf8) else { return }

// Send to backend
let response = try await networkManager.post("/v1/auth/signin-with-apple", body: ["identityToken": tokenString])
KeychainHelper.shared.save(response.token, for: "accessToken")
```

#### WebSocket Streaming (US-009)

iOS needs URLSessionWebSocketTask:

```swift
class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect(token: String) {
        var request = URLRequest(url: URL(string: "wss://api.homeos.app/v1/stream")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                // Handle chat:chunk, chat:complete events
                self?.receiveMessage()
            case .failure(let error):
                // Reconnect logic
            }
        }
    }
}
```

#### Voice Input (US-010)

Current `AudioManager.swift` handles recording.
Add transcription:

```swift
func transcribeRecording() async throws -> String {
    guard let data = getRecordingData() else { throw AudioError.noRecording }
    let response = try await networkManager.upload("/v1/voice/transcribe", data: data)
    return response.text
}
```

### Deliverables
- [ ] Sign in with Apple works end-to-end
- [ ] Can send message and see response
- [ ] Response streams in real-time
- [ ] Voice input transcribes and sends
- [ ] Tasks list shows mock/real tasks
- [ ] Push notifications arrive

---

## Phase 3: Workflow Engine (Weeks 5-8)

### Goal
Durable workflows with Temporal, LLM integration, and approval system.

### User Stories

| ID | Story | Estimate | Dependencies |
|----|-------|----------|--------------|
| US-014 | ChatTurnWorkflow | 6h | Phase 2 |
| US-015 | LLM activity (Claude) | 4h | US-014 |
| US-016 | Memory storage | 4h | US-014 |
| US-017 | Tools activity router | 6h | US-015 |
| US-018 | Approval workflow | 5h | US-017 |
| US-019 | Notification router | 4h | US-018 |

### Implementation Notes

#### ChatTurnWorkflow (US-014)

```typescript
// services/workflows/src/workflows/ChatTurnWorkflow.ts
import { proxyActivities, defineSignal, setHandler } from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const { generateResponse, storeMemory, recall, emitEvent } = proxyActivities<typeof activities>({
  startToCloseTimeout: '30s',
  retry: { maximumAttempts: 3 }
});

export interface ChatTurnInput {
  conversationId: string;
  workspaceId: string;
  memberId: string;
  message: string;
}

export async function ChatTurnWorkflow(input: ChatTurnInput): Promise<string> {
  // 1. Recall relevant context
  const memories = await recall(input.workspaceId, input.message);
  
  // 2. Generate response with Claude
  const response = await generateResponse({
    message: input.message,
    context: memories,
    stream: true,
    onChunk: async (chunk) => {
      await emitEvent(input.conversationId, 'chat:chunk', { text: chunk });
    }
  });
  
  // 3. Store conversation turn
  await storeMemory(input.workspaceId, {
    type: 'conversation',
    content: `User: ${input.message}\nAssistant: ${response}`
  });
  
  // 4. Signal completion
  await emitEvent(input.conversationId, 'chat:complete', { text: response });
  
  return response;
}
```

#### Tool Use Pattern (US-017)

When Claude requests a tool call:

```typescript
// In LLM activity
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-20250514',
  messages: [...],
  tools: toolDefinitions,
});

if (response.stop_reason === 'tool_use') {
  const toolCall = response.content.find(c => c.type === 'tool_use');
  // Execute tool via separate activity
  const toolResult = await executeTool(toolCall.name, toolCall.input);
  // Continue conversation with result
}
```

#### Approval Flow (US-018)

Use Temporal signals for human-in-the-loop:

```typescript
export const approvalSignal = defineSignal<[{ approved: boolean; approver: string }]>('approval');

export async function ApprovalWorkflow(input: ApprovalInput): Promise<boolean> {
  let approval: { approved: boolean } | undefined;
  
  setHandler(approvalSignal, (result) => {
    approval = result;
  });
  
  // Send push notification
  await sendApprovalNotification(input);
  
  // Wait for signal (with timeout)
  await condition(() => approval !== undefined, '24h');
  
  return approval?.approved ?? false;
}
```

### Deliverables
- [ ] ChatTurnWorkflow executes successfully
- [ ] Claude generates contextual responses
- [ ] Memory persists and recalls
- [ ] Basic tools work (reminders, weather)
- [ ] High-risk actions wait for approval
- [ ] Notifications sent via multiple channels

---

## Phase 4: Integrations (Weeks 7-10)

### Goal
Connect third-party services: Google Calendar, Telegram, Twilio.

### User Stories

| ID | Story | Estimate | Dependencies |
|----|-------|----------|--------------|
| US-020 | Google Calendar OAuth | 5h | Phase 1 |
| US-021 | Calendar tools | 4h | US-020 |
| US-022 | Telegram bot | 5h | Phase 3 |
| US-023 | Twilio SMS | 4h | Phase 3 |

### Implementation Notes

#### Google Calendar OAuth (US-020)

OAuth 2.0 flow:
1. Generate auth URL with scopes: `calendar.readonly`, `calendar.events`
2. User authorizes in browser
3. Receive auth code at callback
4. Exchange for refresh token
5. Store encrypted in workspace secrets

```typescript
// services/control-plane/src/routes/integrations.ts
app.get('/v1/integrations/google/auth', async (req, reply) => {
  const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    `${process.env.BASE_URL}/v1/integrations/google/callback`
  );
  
  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: ['https://www.googleapis.com/auth/calendar.readonly'],
    state: req.workspaceId // Pass workspace context
  });
  
  return { url: authUrl };
});
```

#### Telegram Bot (US-022)

1. Create bot via BotFather
2. Set webhook to `/v1/telegram/webhook`
3. Handle updates:

```typescript
// services/runtime/src/routes/telegram.ts
app.post('/v1/telegram/webhook', async (req, reply) => {
  const update = req.body;
  
  if (update.message?.text) {
    const { chat, text } = update.message;
    
    // Find workspace by Telegram chat ID
    const workspace = await findWorkspaceByTelegramChat(chat.id);
    
    // Start chat workflow
    await temporalClient.workflow.start(ChatTurnWorkflow, {
      taskQueue: 'homeos',
      args: [{
        workspaceId: workspace.id,
        message: text,
        channel: 'telegram',
        telegramChatId: chat.id
      }]
    });
  }
  
  return { ok: true };
});
```

### Deliverables
- [ ] Google Calendar OAuth completes
- [ ] Can read/create calendar events
- [ ] Telegram messages route to chat workflow
- [ ] SMS notifications send successfully
- [ ] Integration status visible in app

---

## Phase 5: Workflow Packs (Weeks 9-12)

### Goal
Pre-built automations families can enable with one click.

### User Stories

| ID | Story | Estimate | Dependencies |
|----|-------|----------|--------------|
| US-024 | Morning briefing | 5h | Phase 4 |
| US-025 | Pack management API | 4h | US-024 |
| US-026 | Family communications | 5h | US-025 |
| US-027 | Onboarding flow | 4h | Phase 2 |
| US-028 | Integration health | 3h | Phase 4 |
| US-029 | Error handling | 4h | All |
| US-030 | Conversation history | 3h | Phase 3 |

### Implementation Notes

#### Morning Briefing (US-024)

Scheduled workflow:

```typescript
export async function MorningBriefingWorkflow(input: { workspaceId: string }) {
  // 1. Get member preferences
  const members = await getActiveMembers(input.workspaceId);
  
  for (const member of members) {
    if (!shouldSendBriefing(member)) continue;
    
    // 2. Gather data
    const [weather, calendar, tasks] = await Promise.all([
      getWeather(member.location),
      getCalendarEvents(member.id, 'today'),
      getPendingTasks(member.id)
    ]);
    
    // 3. Generate personalized summary
    const summary = await generateBriefing({
      member,
      weather,
      calendar,
      tasks
    });
    
    // 4. Send via preferred channel
    await sendNotification({
      recipient: member,
      title: `Good morning, ${member.name}!`,
      body: summary,
      channels: member.preferences.briefingChannels
    });
  }
}
```

Schedule with Temporal:
```typescript
await client.schedule.create({
  scheduleId: `morning-briefing-${workspaceId}`,
  spec: {
    calendars: [{ hour: 7, minute: 0 }] // 7 AM daily
  },
  action: {
    type: 'startWorkflow',
    workflowType: 'MorningBriefingWorkflow',
    args: [{ workspaceId }]
  }
});
```

#### Pack Management (US-025)

Pack manifest structure:
```json
{
  "id": "morning-launch",
  "name": "Morning Launch",
  "description": "Start each day with weather, calendar, and priorities",
  "workflows": ["MorningBriefingWorkflow"],
  "requiredIntegrations": ["google-calendar"],
  "settings": {
    "briefingTime": { "type": "time", "default": "07:00" },
    "includeWeather": { "type": "boolean", "default": true }
  }
}
```

### Deliverables
- [ ] Morning briefing sends at configured time
- [ ] Packs can be enabled/disabled from app
- [ ] Family announcements broadcast to all
- [ ] Onboarding guides new users through setup
- [ ] Integration health displayed
- [ ] Errors handled gracefully

---

## Testing Strategy

### Unit Tests
- Backend: Vitest for services and activities
- iOS: XCTest for ViewModels and managers

### Integration Tests
- API endpoints with test database
- Temporal workflows with test environment
- OAuth flows with mock providers

### End-to-End Tests
- iOS app on simulator
- Full flow: sign in → chat → receive response
- Workflow pack activation → scheduled execution

### Quality Gates
- `pnpm run typecheck` must pass
- `pnpm run test` must pass
- iOS builds without warnings
- No lint errors in changed files

---

## Deployment

### Local Development
```bash
# Start infrastructure
cd infra && docker compose up -d

# Start services
pnpm run dev:services

# Run iOS app
open apps/ios/HomeOS/HomeOS.xcodeproj
# Select simulator, run
```

### Staging (Fly.io)
```bash
# Deploy control plane
cd services/control-plane && fly deploy

# Deploy runtime
cd services/runtime && fly deploy

# Deploy workflows
cd services/workflows && fly deploy
```

### Production Checklist
- [ ] Environment secrets configured
- [ ] Database migrations applied
- [ ] Temporal namespace created
- [ ] APNs certificates uploaded
- [ ] Telegram webhook set
- [ ] Twilio numbers provisioned
- [ ] Monitoring/alerting enabled

---

## Success Criteria

### MVP (Week 12)
- [ ] 10 beta families onboarded
- [ ] Chat works reliably (< 3s response)
- [ ] Morning briefing delivers consistently
- [ ] 80% of user stories complete
- [ ] NPS ≥ +30 from beta users

### V1.0 (Week 16)
- [ ] 100 families on platform
- [ ] 5 workflow packs available
- [ ] Elder care check-ins working
- [ ] 95% workflow success rate
- [ ] App Store submission ready

---

## References

- [HomeOS PRD](/docs/HomeOS_PRD.md)
- [Architecture](/docs/ARCHITECTURE.md)
- [Soul Document](/docs/MacAppPRD/SOUL.md)
- [Ralph Methodology](https://github.com/snarktank/ralph)
