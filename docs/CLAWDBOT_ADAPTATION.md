# Clawdbot Adaptation Analysis for homeOS

## Overview

homeOS adapts several key architectural patterns from [clawdbot](https://github.com/clawdbot/clawdbot) for its agentic AI capabilities. This document explains how clawdbot's design has been adapted for a family-focused iOS assistant with Temporal-based durable execution.

## Architecture Comparison

### Clawdbot Architecture
Clawdbot is designed as a cloud-based AI coding assistant with:
- **Gateway Pattern**: Multi-protocol control plane (WebSocket, TCP Bridge, Canvas HTTP)
- **Session Management**: Persistent sessions with state tracking
- **Tool Orchestration**: Dynamic tool execution with output streaming
- **Skill System**: Modular, pluggable capabilities

### homeOS Adaptation
homeOS adapts this architecture for family automation:
- **Gateway**: Adapted for iOS client connections with WebSocket streaming
- **Session Management**: Workspace-based sessions (family/household context)
- **Workflow Orchestration**: Temporal replaces ad-hoc orchestration for durability
- **Skill System**: Dynamic integrations via Skill Factory workflow

---

## Gateway Architecture

### Clawdbot Gateway (Original)
```
┌─────────────────────────────────────────┐
│              Gateway Manager            │
├─────────────────────────────────────────┤
│  WS Control (18789)  │  TCP Bridge      │
│  Canvas HTTP (18793) │  (18790)         │
└─────────────────────────────────────────┘
```

### homeOS Gateway (Adapted)
```
┌─────────────────────────────────────────┐
│           Runtime Gateway               │
├─────────────────────────────────────────┤
│  WebSocket (3002)    │  HTTP REST       │
│  Real-time events    │  API endpoints   │
├─────────────────────────────────────────┤
│           Control Plane (3001)          │
│  Auth │ Workspaces │ Devices │ Secrets  │
└─────────────────────────────────────────┘
```

**Key Adaptations:**
1. **Port consolidation**: Combined into runtime (3002) and control-plane (3001)
2. **iOS-focused**: WebSocket optimized for iOS client connections
3. **Workspace isolation**: Each family has isolated session state
4. **Event streaming**: `emitToWorkspace()` for real-time UI updates

**Implementation**: `services/runtime/src/gateway/manager.ts`

---

## Session Management

### Clawdbot Sessions
- Per-client sessions with tool state
- Session IDs track ongoing conversations
- State persisted for reconnection

### homeOS Sessions
- **Workspace-scoped**: Sessions belong to a family workspace
- **User context**: Each session knows the acting user within the workspace
- **Chat sessions**: Persistent conversation history with message retrieval
- **Task linking**: Sessions link to Temporal workflow executions

**Implementation**: `services/runtime/src/gateway/sessions.ts`

---

## Tool Execution → Temporal Workflows

### Clawdbot Tool Execution
```typescript
// Direct tool calls with streaming output
await executeTools(tools, {
  onOutput: (chunk) => stream(chunk)
});
```

### homeOS Workflow Execution
```typescript
// Durable execution via Temporal
const handle = await client.workflow.start('ChatTurnWorkflow', {
  taskQueue: 'homeos-workflows',
  workflowId: `chat-turn-${workspaceId}-${Date.now()}`,
  args: [{ sessionId, workspaceId, userId, message }],
});
```

**Key Differences:**
1. **Durability**: Temporal provides automatic retries and state recovery
2. **Human-in-the-Loop**: Built-in signal handlers for approval workflows
3. **Long-running**: Workflows can pause for days waiting for approvals
4. **Audit trail**: Full execution history persisted in Temporal

**Workflow Types** (adapted from clawdbot skills):

| Clawdbot Skill | homeOS Workflow | Adaptation |
|----------------|-----------------|------------|
| Code execution | ChatTurnWorkflow | 6-phase cognitive loop |
| Web browsing | DynamicIntegrationWorkflow | Skill Factory for new APIs |
| File operations | N/A (iOS-focused) | Device actions via WorkspaceService |

---

## Approval System (HITL)

### Clawdbot Approach
Clawdbot uses interactive confirmations during tool execution.

### homeOS Approach
homeOS implements a formal Human-in-the-Loop (HITL) system:

```typescript
// ActionEnvelope for approval requests
interface ActionEnvelope {
  envelopeId: string;
  intent: string;           // Human-readable intent
  toolName: string;         // Tool being invoked
  inputs: Record<string, unknown>;
  riskLevel: 'high' | 'medium' | 'low';
  piiFields: string[];      // Fields containing PII
  rollbackPlan?: string;    // How to undo if needed
  auditHash: string;        // SHA-256 for integrity
}

// ApprovalToken for verified approvals
interface ApprovalToken {
  envelopeId: string;
  approvedBy: string;
  approvedAt: Date;
  signature: string;        // HMAC signature
}
```

**Risk-Based Routing:**
- **HIGH risk**: Phone calls, financial transactions, address sharing → Always require approval
- **MEDIUM risk**: Posting content, booking services → Require approval
- **LOW risk**: Information retrieval, calendar viewing → Auto-approve with logging

**Implementation**:
- `packages/shared/src/crypto/envelope.ts` - Envelope creation/verification
- `packages/shared/src/crypto/token.ts` - Approval token signing

---

## Skill System → Dynamic Integrations

### Clawdbot Skills
Clawdbot has predefined skills for coding tasks.

### homeOS Dynamic Integrations
homeOS implements a "Skill Factory" workflow that can dynamically create new integrations:

```typescript
// DynamicIntegrationWorkflow phases:
1. discoverServices()      // Search API registries
2. evaluateService()       // Score candidates
3. generateToolWrapper()   // Auto-generate TypeScript wrapper
4. runContractTests()      // Verify API behavior
5. applySecurityGates()    // Security review
6. requestApproval()       // Human approval for new tool
7. publishTool()           // Deploy with canary rollout
```

**Example**: "I need to check flight prices"
1. Workflow discovers flight APIs (Amadeus, Skyscanner, etc.)
2. Evaluates based on cost, reliability, features
3. Generates typed wrapper with rate limiting
4. Tests against sample queries
5. Security review (no credential leaks, proper sandboxing)
6. User approves "Add flight search capability"
7. Tool available for future queries

---

## Memory System (Hexis-Inspired)

homeOS adapts memory concepts from the Hexis architecture:

```sql
-- Entities (people, places, things)
CREATE TABLE memory_entities (
  id UUID PRIMARY KEY,
  workspace_id UUID,
  name VARCHAR(255),
  entity_type VARCHAR(100),      -- 'person', 'place', 'item', etc.
  embedding vector(1536),        -- For semantic search
  metadata JSONB
);

-- Edges (relationships between entities)
CREATE TABLE memory_edges (
  source_id UUID,
  target_id UUID,
  relation VARCHAR(100),         -- 'lives_with', 'owns', 'prefers'
  strength FLOAT
);

-- Procedures (learned patterns)
CREATE TABLE memory_procedures (
  id UUID PRIMARY KEY,
  name VARCHAR(255),
  steps JSONB,
  success_count INTEGER          -- Reinforcement
);
```

**ChatTurnWorkflow Memory Phases:**
1. **Recall**: Query memory graph for relevant context
2. **Reflect**: After execution, evaluate what was learned
3. **Writeback**: Update memory graph with new knowledge

---

## WebSocket Streaming

### Clawdbot Output Streaming
```typescript
// Chunked output to client
gateway.send({ type: 'output', content: chunk });
```

### homeOS Event Streaming
```typescript
// Typed event emission per workspace
export function emitToWorkspace(workspaceId: string, event: StreamEvent): void {
  const sessions = getWorkspaceSessions(workspaceId);
  for (const session of sessions) {
    session.socket.send(JSON.stringify(event));
  }
}

// Event types
type StreamEvent =
  | { type: 'chat.streaming'; payload: { delta: string; phase: string } }
  | { type: 'chat.complete'; payload: { response: string } }
  | { type: 'task.created'; payload: { taskId: string; status: string } }
  | { type: 'task.updated'; payload: { taskId: string; status: string } }
  | { type: 'approval.required'; payload: ActionEnvelope }
  | { type: 'error'; payload: { code: string; message: string } };
```

**Implementation**: `services/runtime/src/ws/stream.ts`

---

## iOS Client (New)

While clawdbot targets CLI/web clients, homeOS adds native iOS support:

### Networking Layer
```swift
// WebSocket for real-time events
class WebSocketManager: ObservableObject {
  func connect(workspaceId: String, token: String)
  func send(_ message: WebSocketMessage)
  // Automatic reconnection with exponential backoff
}

// REST API for commands
class APIClient {
  func startChatTurn(workspaceId: String, message: String) async
  func approveTasks(taskId: String, envelopeId: String) async
}
```

### Liquid Glass Design System
iOS 26.1 "Liquid Glass" design language:
- Translucent surfaces with depth
- Refraction effects on overlapping elements
- Haptic feedback synchronized with visual transitions

---

## Summary of Adaptations

| Clawdbot Feature | homeOS Adaptation |
|------------------|-------------------|
| Gateway (3 protocols) | Unified WebSocket + REST |
| Direct tool execution | Temporal durable workflows |
| Interactive confirmations | Formal HITL with ActionEnvelope |
| Fixed skill set | Dynamic Skill Factory |
| CLI/Web clients | Native iOS (SwiftUI) |
| Per-session state | Workspace-scoped memory |
| Single-user | Multi-user family workspaces |

## Key Improvements

1. **Durability**: Temporal ensures workflows survive crashes/restarts
2. **Auditability**: Every action has cryptographic proof
3. **Family-safe**: Risk-based approval prevents accidents
4. **Extensible**: Skill Factory enables unbounded capabilities
5. **Native UX**: iOS app with platform-specific design patterns

---

## Files Referenced

- `services/runtime/src/gateway/manager.ts` - Gateway implementation
- `services/runtime/src/ws/stream.ts` - WebSocket streaming
- `services/workflows/src/workflows/ChatTurnWorkflow.ts` - Main cognitive workflow
- `services/workflows/src/workflows/DynamicIntegrationWorkflow.ts` - Skill Factory
- `packages/shared/src/crypto/envelope.ts` - Action envelope utilities
- `packages/shared/src/types/approval.ts` - HITL type definitions
- `apps/ios/HomeOS/` - iOS client implementation
