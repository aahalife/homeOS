# HomeOS Test Scenarios

## Table of Contents
1. [Infrastructure Tests](#1-infrastructure-tests)
2. [Control Plane Service Tests](#2-control-plane-service-tests)
3. [Runtime Service Tests](#3-runtime-service-tests)
4. [Workflow Tests](#4-workflow-tests)
5. [iOS App Tests](#5-ios-app-tests)
6. [End-to-End Integration Tests](#6-end-to-end-integration-tests)

---

## 1. Infrastructure Tests

### 1.1 PostgreSQL + pgvector
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| INFRA-PG-01 | Database connectivity | `psql -h localhost -U homeos -d homeos` | Connection successful | High - if credentials mismatch |
| INFRA-PG-02 | pgvector extension | `SELECT * FROM pg_extension WHERE extname='vector';` | Extension exists | High - image must include pgvector |
| INFRA-PG-03 | Schema creation | Check `homeos` schema exists | Schema with all tables | Medium - init script order |
| INFRA-PG-04 | Vector similarity search | Insert embedding, query with cosine similarity | Returns nearest neighbors | Medium - index creation |

### 1.2 Redis
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| INFRA-REDIS-01 | Connectivity | `redis-cli ping` | PONG | Low |
| INFRA-REDIS-02 | Persistence | Set key, restart, get key | Value persists | Medium - AOF config |

### 1.3 MinIO
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| INFRA-MINIO-01 | Console access | Navigate to localhost:9001 | Login page | Low |
| INFRA-MINIO-02 | Bucket creation | Create `homeos-storage` bucket | Bucket accessible | Low |
| INFRA-MINIO-03 | S3 compatibility | Use AWS SDK to put/get object | Object stored/retrieved | Medium - endpoint config |

### 1.4 Temporal
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| INFRA-TEMP-01 | Server startup | Check localhost:7233 | gRPC responding | High - DB connection |
| INFRA-TEMP-02 | UI access | Navigate to localhost:8080 | Temporal UI loads | Low |
| INFRA-TEMP-03 | Namespace | List namespaces via CLI | `default` namespace exists | Medium |
| INFRA-TEMP-04 | Worker registration | Start worker, check UI | Worker appears in task queue | High - connection config |

---

## 2. Control Plane Service Tests

### 2.1 Authentication (Apple Sign-In)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| AUTH-01 | Valid Apple token | POST /v1/auth/apple with valid token | 200 + JWT token | High - Apple verification |
| AUTH-02 | Invalid token | POST with malformed token | 401 Unauthorized | Low |
| AUTH-03 | New user creation | First sign-in | 201 + user created in DB | Medium |
| AUTH-04 | Existing user login | Subsequent sign-in | 200 + same user ID | Low |
| AUTH-05 | Token expiration | Use expired JWT | 401 Unauthorized | Medium - JWT config |
| AUTH-06 | Get current user | GET /v1/auth/me with valid token | User details | Low |

**Logic Breakpoints:**
- Apple token verification requires valid `APPLE_CLIENT_ID` environment variable
- In development mode, token expiration check is skipped - must test in production mode
- Name/email only provided on first sign-in from Apple

### 2.2 Workspaces
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WS-01 | Create workspace | POST /v1/workspaces with name | 201 + workspace ID | Low |
| WS-02 | List workspaces | GET /v1/workspaces | Array of workspaces | Low |
| WS-03 | Get workspace details | GET /v1/workspaces/:id | Workspace with members | Medium - permission check |
| WS-04 | Add member (owner) | POST /v1/workspaces/:id/members as owner | 201 Member added | Medium |
| WS-05 | Add member (non-owner) | POST as regular member | 403 Forbidden | Medium |
| WS-06 | Access other's workspace | GET workspace not a member of | 404 Not found | High - security |

**Logic Breakpoints:**
- Owner automatically added as member with 'owner' role
- Must verify workspace membership before any operation
- Email lookup for adding members may fail if user doesn't exist

### 2.3 Devices
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| DEV-01 | Register device | POST /v1/devices/register | 201 + device ID | Low |
| DEV-02 | List devices | GET /v1/devices | Array of devices | Low |
| DEV-03 | Update APNS token | PUT /v1/devices/:id/token | 200 Updated | Low |
| DEV-04 | Unregister device | DELETE /v1/devices/:id | 200 Deleted | Low |
| DEV-05 | Register with invalid workspace | POST with non-member workspace | 403 Forbidden | High |

### 2.4 Secrets (BYOK)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| SEC-01 | Store OpenAI key | POST /v1/workspaces/:id/secrets | 201 Stored | High - encryption |
| SEC-02 | Store Anthropic key | POST with provider=anthropic | 201 Stored | High - encryption |
| SEC-03 | Get status | GET /v1/workspaces/:id/secrets/status | Status array, NO keys | Critical - never leak |
| SEC-04 | Test OpenAI connection | POST /v1/workspaces/:id/secrets/test | Success/failure result | Medium - API call |
| SEC-05 | Test Anthropic connection | POST with provider=anthropic | Success/failure result | Medium - API call |
| SEC-06 | Delete secret | DELETE /v1/workspaces/:id/secrets/:provider | 200 Deleted | Low |
| SEC-07 | Non-admin set secret | POST as regular member | 403 Forbidden | High - security |

**Logic Breakpoints:**
- Master encryption key MUST be set in production
- Keys are envelope-encrypted with scrypt key derivation
- Test connection makes real API calls - may incur costs
- Never return decrypted keys in any response

### 2.5 Runtime Connection
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| CONN-01 | Get connection info | GET /v1/runtime/connection-info | baseUrl, wsUrl, token | Medium |
| CONN-02 | Runtime token validity | Use returned token to connect to runtime | Connection successful | High |

---

## 3. Runtime Service Tests

### 3.1 Gateway (Clawdbot-inspired)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| GW-01 | WS control plane | Connect to ws://127.0.0.1:18789 | Connection accepted | Medium |
| GW-02 | Session create | Send session.create message | Session ID returned | Low |
| GW-03 | Config get | Send config.get message | Current config returned | Low |
| GW-04 | Config reload | Send config.reload + SIGUSR1 | Config reloaded | Medium |
| GW-05 | Bridge TCP | Connect to tcp://0.0.0.0:18790 | Health endpoint responds | Low |
| GW-06 | Canvas HTTP | Navigate to http://localhost:18793/__homeos__/canvas/ | Canvas HTML | Low |

**Logic Breakpoints:**
- WS gateway bound to 127.0.0.1 only (loopback-first design)
- Config file watching requires valid path
- Hot reload applies safe changes only; critical changes need restart

### 3.2 WebSocket Stream
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WS-01 | Connect without token | WS /v1/stream without auth | 4001 Unauthorized | High - security |
| WS-02 | Connect with valid token | WS /v1/stream with Bearer token | Connected message | Medium |
| WS-03 | Subscribe to events | Send subscribe message | Subscribed confirmation | Low |
| WS-04 | Receive task event | Create task via API | task.created event received | Medium |
| WS-05 | Receive approval request | Trigger approval workflow | approval.requested event | Medium |
| WS-06 | Ping/pong | Send ping message | Pong response | Low |
| WS-07 | Cross-workspace isolation | Listen as workspace A, emit to B | No event received | Critical - security |

**Logic Breakpoints:**
- Token must have type='runtime' (from control plane)
- Events only sent to clients in same workspace
- Subscription filtering must work correctly

### 3.3 Chat API
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| CHAT-01 | Start chat turn | POST /v1/chat/turn | sessionId, taskId, workflowId | High - Temporal |
| CHAT-02 | Workspace mismatch | POST with different workspace than token | 403 Forbidden | High |
| CHAT-03 | List sessions | GET /v1/chat/sessions | Array of sessions | Low |
| CHAT-04 | Get messages | GET /v1/chat/sessions/:id/messages | Array of messages | Low |
| CHAT-05 | Empty message | POST with empty message | 400 Bad Request | Low |

**Logic Breakpoints:**
- Temporal client connection required
- Workflow must be registered on task queue
- Session creation if sessionId not provided

### 3.4 Tasks API
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| TASK-01 | List tasks | GET /v1/tasks?workspaceId=xxx | Array of tasks | Low |
| TASK-02 | Get task detail | GET /v1/tasks/:taskId | Task with details | Low |
| TASK-03 | Approve task | POST /v1/tasks/:taskId/approve | Task continues | High - Temporal signal |
| TASK-04 | Deny task | POST /v1/tasks/:taskId/deny | Task cancelled | High - Temporal signal |

### 3.5 Approvals API
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| APPR-01 | List pending | GET /v1/approvals/pending | Array of pending | Low |
| APPR-02 | Get envelope | GET /v1/approvals/:envelopeId | Envelope details | Low |
| APPR-03 | Approve envelope | POST /v1/approvals/:envelopeId/approve | Token + workflow signal | High |
| APPR-04 | Deny envelope | POST /v1/approvals/:envelopeId/deny | Workflow signaled | High |
| APPR-05 | Expired envelope | Approve after TTL | 410 Gone or error | Medium |

**Logic Breakpoints:**
- Approval token must be cryptographically signed
- Token has TTL (default 5 minutes)
- Workflow must be waiting for signal

### 3.6 Ingest API
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| ING-01 | Ingest note | POST /v1/ingest with content | taskId, extracted actions | Medium |
| ING-02 | Ingest URL | POST /v1/ingest/url | taskId after fetch | Medium |

---

## 4. Workflow Tests

### 4.1 ChatTurnWorkflow
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WF-CHAT-01 | Simple question | "What's the weather?" | Direct response, no actions | Low |
| WF-CHAT-02 | Action required | "Book a restaurant" | Plan created, approval requested | High |
| WF-CHAT-03 | Approval granted | Approve high-risk action | Action executed | High |
| WF-CHAT-04 | Approval denied | Deny action | Task marked skipped | Medium |
| WF-CHAT-05 | Multi-step plan | Complex request | Multiple steps executed in order | High |
| WF-CHAT-06 | Memory recall | Reference past conversation | Relevant memories retrieved | Medium |
| WF-CHAT-07 | LLM failure | API returns error | Graceful failure, retry | High |

**Workflow Phases:**
1. Understand → Extract intent/entities
2. Recall → Fetch relevant memories
3. Plan → Create execution plan
4. Execute → Run tools with approval gates
5. Reflect → Validate results
6. Writeback → Store memories, generate response

**Logic Breakpoints:**
- LLM API key must be configured (BYOK)
- JSON parsing of LLM responses can fail
- Approval signal wait can timeout (24h default)
- Activity retries may exhaust on transient failures

### 4.2 ReservationCallWorkflow
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WF-RES-01 | Search candidates | Request reservation | Top 3 restaurants returned | Medium |
| WF-RES-02 | User selects candidate | Send candidateSelection signal | Selected candidate stored | Medium |
| WF-RES-03 | Approval for call | Request approval | Envelope created, waiting | Medium |
| WF-RES-04 | Call placed | Approve, call made | Call SID returned | High - Twilio |
| WF-RES-05 | Voicemail handling | Restaurant voicemail | Next candidate tried OR user notified | High |
| WF-RES-06 | Deposit requested | Restaurant asks for deposit | Pause, ask user | Critical - HITL |
| WF-RES-07 | Success path | Reservation confirmed | Calendar event created | Medium |
| WF-RES-08 | No candidates | No restaurants found | Graceful failure | Low |
| WF-RES-09 | Selection timeout | User doesn't select within 1h | Workflow ends | Medium |

**Logic Breakpoints:**
- Twilio credentials required for real calls
- Places API integration for candidate search
- Calendar integration for event creation
- Negotiation bounds must be respected
- Sensitive info (payment/address) MUST trigger approval

### 4.3 MarketplaceSellWorkflow
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WF-MKT-01 | Item identification | Upload photos | Item info extracted | Medium - Vision |
| WF-MKT-02 | Price suggestion | Find comparables | Suggested price + floor | Medium |
| WF-MKT-03 | Draft listing | Generate listing | Title, description, photos | Low |
| WF-MKT-04 | Approval for post | Request approval | Envelope for HIGH risk | Medium |
| WF-MKT-05 | Listing posted | Approve | Listing URL returned | Medium |
| WF-MKT-06 | Buyer inquiry | Receive message | Response sent | Medium |
| WF-MKT-07 | Scam detection | Suspicious message | Message blocked, user notified | High |
| WF-MKT-08 | Address sharing | Buyer requests address | Approval required | Critical |
| WF-MKT-09 | Price negotiation | Offer below floor | Approval required | High |
| WF-MKT-10 | Pickup scheduled | Agree on time | Calendar event created | Medium |
| WF-MKT-11 | Sale completed | Buyer picks up | Listing marked sold | Low |
| WF-MKT-12 | Listing expiry | No buyers in 7 days | Workflow ends | Low |

**Logic Breakpoints:**
- Vision model required for item identification
- Marketplace API integration for posting
- Scam detection patterns must be comprehensive
- Address sharing is HIGH risk - always approval
- Below-floor offers require approval

### 4.4 HireHelperWorkflow
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WF-HELP-01 | Search helpers | Request helper | Candidates from multiple platforms | Medium |
| WF-HELP-02 | Ranking | Candidates ranked | Best matches first | Low |
| WF-HELP-03 | User selection | Select candidates | Selection stored | Low |
| WF-HELP-04 | Quote request | Request quotes | Quotes returned | Medium - API |
| WF-HELP-05 | Booking approval | Best quote selected | Approval for HIGH risk | Medium |
| WF-HELP-06 | Booking confirmed | Approve | Booking created | High |
| WF-HELP-07 | Coordination | Send messages | Helper notified | Medium |
| WF-HELP-08 | No helpers found | Empty search result | Graceful failure | Low |
| WF-HELP-09 | Quote expiry | Quote expires before approval | New quote requested | Medium |

**Logic Breakpoints:**
- TaskRabbit/Thumbtack API integrations required
- Booking is HIGH risk (spending money)
- Quote expiry must be tracked
- Location sharing may require approval

### 4.5 DynamicIntegrationWorkflow (Skill Factory)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| WF-DI-01 | Discover services | Request new capability | Candidate services found | Medium |
| WF-DI-02 | Evaluation | Assess services | Viability scores | Medium |
| WF-DI-03 | Code generation | Generate wrapper | Tool code created | High - LLM |
| WF-DI-04 | Contract tests | Run tests | All tests pass | High |
| WF-DI-05 | Security gates | Apply restrictions | Secured code | High |
| WF-DI-06 | Publish approval | Request approval | Approval required | Medium |
| WF-DI-07 | Tool published | Approve | Tool in registry | Medium |
| WF-DI-08 | No viable services | All evaluations fail | Graceful failure | Low |
| WF-DI-09 | Test failures | Contract tests fail | Workflow aborts | Medium |
| WF-DI-10 | Security issues | Security gate fails | Workflow aborts | High |

**Logic Breakpoints:**
- MCP registry/OpenAPI discovery required
- LLM code generation quality varies
- Tests must actually validate functionality
- Security analysis must catch vulnerabilities
- Canary rollout for safety

---

## 5. iOS App Tests

### 5.1 Onboarding & Auth
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-AUTH-01 | App launch (unauthenticated) | Open app | Onboarding view | Low |
| IOS-AUTH-02 | Sign in with Apple | Tap button, authenticate | Main view appears | High - Apple config |
| IOS-AUTH-03 | Token persistence | Kill app, reopen | Still authenticated | Medium - Keychain |
| IOS-AUTH-04 | Sign out | Tap sign out | Onboarding view | Low |
| IOS-AUTH-05 | Network error during auth | Sign in with no network | Error displayed | Medium |

### 5.2 Chat View
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-CHAT-01 | Send message | Type and send | Message appears, typing indicator | Medium |
| IOS-CHAT-02 | Receive response | Wait for response | Assistant bubble with ripple | Medium |
| IOS-CHAT-03 | Scroll behavior | Send multiple messages | Auto-scroll to latest | Low |
| IOS-CHAT-04 | Multiline input | Type long message | Input expands | Low |
| IOS-CHAT-05 | WebSocket disconnect | Kill server | Offline indicator | Medium |
| IOS-CHAT-06 | Reconnection | Restart server | Connection restored | Medium |

### 5.3 Tasks View
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-TASK-01 | View tasks | Navigate to Tasks tab | Task list loads | Low |
| IOS-TASK-02 | Filter tasks | Tap filter chips | List updates | Low |
| IOS-TASK-03 | Expand task | Tap task card | Details revealed with animation | Low |
| IOS-TASK-04 | Approve task | Tap Approve button | FaceID prompt, seal animation | High |
| IOS-TASK-05 | Deny task | Tap Deny button | Task updated | Low |
| IOS-TASK-06 | Pending badge | Have pending approvals | Badge shows count | Low |
| IOS-TASK-07 | Real-time update | Task status changes | List updates automatically | Medium - WS |

### 5.4 Actions View
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-ACT-01 | Quick actions | View Actions tab | Grid of actions | Low |
| IOS-ACT-02 | Tap action | Tap "Make a Call" | Action initiated | Medium |
| IOS-ACT-03 | Recent actions | View recent section | Recent items shown | Low |

### 5.5 Connections View (BYOK)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-CONN-01 | View connections | Navigate to Connections | Providers listed | Low |
| IOS-CONN-02 | Add OpenAI key | Enter key, save | Key stored (encrypted) | High |
| IOS-CONN-03 | Test connection | Tap Test | Success/failure shown | Medium |
| IOS-CONN-04 | Update key | Change existing key | Key updated | Medium |
| IOS-CONN-05 | Key not visible | After save | Only status shown, NOT key | Critical |

### 5.6 Settings View
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-SET-01 | View profile | Navigate to Settings | User info displayed | Low |
| IOS-SET-02 | Navigation | Tap settings rows | Navigate to sub-views | Low |
| IOS-SET-03 | Sign out | Tap Sign Out | Return to onboarding | Low |

### 5.7 Design System (Liquid Glass)
| Test ID | Scenario | Steps | Expected Result | Breakpoint Risk |
|---------|----------|-------|-----------------|-----------------|
| IOS-DS-01 | Glass surfaces | View any card | Translucent blur effect | Low |
| IOS-DS-02 | Ripple effect | New assistant message | Subtle ripple animation | Low |
| IOS-DS-03 | Status pills | View task status | Colored pills | Low |
| IOS-DS-04 | Approval animation | Approve high-risk action | Seal animation + haptic | Medium |
| IOS-DS-05 | Dark background | All views | Gradient backgrounds | Low |

---

## 6. End-to-End Integration Tests

### 6.1 Complete Chat Flow
| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| E2E-01 | Simple chat | iOS → Runtime → Workflow → LLM → Response | Message displayed in iOS |
| E2E-02 | Task creation | Chat with action → Task created | Task appears in Tasks tab |
| E2E-03 | Approval flow | High-risk action → Approval request → Approve | Action executed |

### 6.2 Reservation Flow
| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| E2E-RES-01 | Full reservation | "Book restaurant" → Select → Approve → Call | Calendar event created |

### 6.3 Marketplace Flow
| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| E2E-MKT-01 | Sell item | Photos → Approve listing → Post | Listing active |

### 6.4 BYOK Flow
| Test ID | Scenario | Steps | Expected Result |
|---------|----------|-------|-----------------|
| E2E-BYOK-01 | Configure and use | Add API key → Chat | LLM responds |

---

## Test Environment Setup

### Prerequisites
```bash
# Required
- Node.js 22+
- pnpm 9+
- Docker & Docker Compose
- Xcode 15+ (for iOS)

# Environment Variables
MASTER_ENCRYPTION_KEY=<32-byte-hex>
JWT_SECRET=<strong-secret>
APPLE_CLIENT_ID=com.homeos.app
TWILIO_ACCOUNT_SID=<optional>
TWILIO_AUTH_TOKEN=<optional>
```

### Running Tests
```bash
# Infrastructure
cd infra && docker compose up -d

# Backend services
pnpm install
pnpm dev

# Run test suites
pnpm test

# iOS
open apps/ios/HomeOS/HomeOS.xcodeproj
# Run on simulator
```

---

## Known Logic Breakpoints Summary

### Critical (Must Fix)
1. **Secret leakage** - API keys must NEVER appear in responses
2. **Cross-workspace access** - Events/data must be isolated
3. **Approval bypass** - High-risk actions MUST wait for approval
4. **Sensitive info disclosure** - Address/payment requires explicit approval

### High Risk
1. **Apple Sign-In config** - Requires valid Apple Developer setup
2. **Temporal connection** - Worker must connect to server
3. **LLM API keys** - Must be configured before chat works
4. **Twilio integration** - Real calls need valid credentials

### Medium Risk
1. **WebSocket reconnection** - Must handle network interruptions
2. **Token expiration** - JWT refresh flow needed for long sessions
3. **Workflow timeouts** - Long-running workflows may timeout
4. **Activity retries** - Must not duplicate side effects

### Low Risk
1. **UI animations** - May vary by device
2. **Empty states** - Should show appropriate messages
3. **Loading states** - Should indicate progress
