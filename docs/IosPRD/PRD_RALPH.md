 # HomeOS iOS Platform PRD (Ralph Format)
 
 This PRD is designed for Ralph-style execution. It breaks the platform into executable, testable user stories with clear acceptance criteria and dependencies.
 
 ---
 
 ## Vision
 Build a family-centric assistant with iOS/iPad as the primary client and cloud-heavy execution for reliability. The platform should deliver daily value (morning brief, school coordination, dinner planning) while requiring minimal setup.
 
 ---
 
 ## Goals (MVP)
 - Onboarding completed in under 5 minutes.
 - First value delivered by next morning (morning brief).
 - Core workflows run reliably with explicit consent for high-risk actions.
 - iOS app is clear, minimal, and fast.
 
 ## Goals (V1)
 - Delightful UX with motion, shaders, and audio polish.
 - Expanded workflow packs with richer personalization.
 - High trust and low friction for family coordination.
 
 ---
 
 ## Non-Goals
 - Rewriting Clawdbot core.
 - Running heavy automation solely on iOS (background limits).
 - Exposing raw skill editing to non-technical users in MVP.
 
 ---
 
 ## Deployment Mode
 - **Hybrid**: iOS client + cloud orchestration for workflows.
 - iOS handles UX, native integrations, approvals.
 - Cloud handles LLM/agents, telephony, workflow execution.
 
 ---
 
## Critical Decisions (Selected)
- iOS inference uses native data sources only; Gmail/school parsing happens in cloud via OAuth.
- Supported channels in MVP: Push, SMS, Email, Telegram. No iMessage/WhatsApp in MVP.
- Telegram uses **per-family** bots for privacy and isolation.
- Photos-based inference is **opt-in only** with explicit user consent.

---

 ## Key Deliverables
 - `docs/IosPRD/IOS_APP_DESIGN_SPEC.md`
 - `docs/IosPRD/prd.json`
 - `docs/IosPRD/PRD_RALPH.md`
 - `scripts/ralph/run.sh`
 - Ralph workflow described in `docs/IosPRD/README.md`
 
 ---
 
 ## User Stories (Ralph Execution)
 
 **US-001**: iOS permissions and inference data capture  
 **Priority**: 1  
 **Description**: As a new user, I grant permissions so the app can infer family context.  
 **Acceptance Criteria**:
 - App requests Contacts, Calendar, Location, Notifications permissions.
 - Permission rationale is shown for each permission.
 - App works with partial permissions (graceful degradation).
- Photos permission is optional and presented only as explicit opt-in.
 - iOS build succeeds.
 
 **US-002**: Device inference pipeline (local + cloud sync)  
 **Priority**: 1  
 **DependsOn**: US-001  
 **Acceptance Criteria**:
 - Extract family candidates from contacts and calendar.
 - Detect recurring events (school, activities).
 - Sync inferred data to control plane.
 - Data is scoped per household and encrypted at rest.
- If Photos is opted in, use face grouping to improve family inference.
 
 **US-003**: Family confirmation UI  
 **Priority**: 1  
 **DependsOn**: US-002  
 **Acceptance Criteria**:
 - List of inferred members with edit controls.
 - Add/remove members supported.
 - Roles and ages editable.
 
 **US-004**: Critical questions flow  
 **Priority**: 1  
 **DependsOn**: US-003  
 **Acceptance Criteria**:
 - 3-5 questions only (dietary, budget, brief time, quiet hours, emergency contact).
 - Defaults provided.
 - Answers stored in preferences.
 
 **US-005**: Control plane core data model  
 **Priority**: 1  
 **Acceptance Criteria**:
 - Tenant, household, member, preferences, approvals, workflow tables.
 - CRUD endpoints for each entity.
 - Data isolation between households enforced.
 
 **US-006**: Auth + device binding  
 **Priority**: 1  
 **DependsOn**: US-005  
 **Acceptance Criteria**:
 - Magic link or OAuth sign-in.
 - Device registration with APNs token.
 - Session expiry handling.
 
 **US-007**: Notification routing and quiet hours  
 **Priority**: 1  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - APNs push delivery.
 - Quiet hours respected.
 - Escalation rules configurable (push -> SMS -> voice).
 
 **US-008**: Home screen (Today view)  
 **Priority**: 1  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - Priorities card, schedule card, attention card.
 - Ask Clawd input.
 - Pull to refresh.
 
 **US-009**: Chat interface with rich cards  
 **Priority**: 1  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - Messages displayed with markdown.
 - Rich cards for recipes, approvals, schedules.
 - Voice input supported.
 
 **US-010**: Inbox approvals UI  
 **Priority**: 1  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - Approval cards with approve/deny.
 - Detail sheet with context.
 - Remember choice setting.
 
 **US-011**: Automations gallery and pack detail  
 **Priority**: 2  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - Active and available packs.
 - Toggle enable/disable.
 - Detail sheet with settings and run history.
 
 **US-012**: Settings and integrations management  
 **Priority**: 2  
 **DependsOn**: US-006  
 **Acceptance Criteria**:
 - Family members list and roles.
 - Integration setup for Google and Telegram.
 - Preferences editable (brief time, quiet hours).
 
 **US-013**: Workflow orchestration baseline  
 **Priority**: 1  
 **Acceptance Criteria**:
 - Temporal workflows running with retry and error status.
 - Workflow status persisted.
 - Manual run supported.
 
 **US-014**: Approval envelope service  
 **Priority**: 1  
 **DependsOn**: US-013  
 **Acceptance Criteria**:
 - Approval requests generated for high-risk actions.
 - Approval ledger persisted.
 - Audit trail available.
 
 **US-015**: Google OAuth integration  
 **Priority**: 1  
 **DependsOn**: US-005  
 **Acceptance Criteria**:
 - Calendar read/write.
 - Gmail read for school domains.
 - Token refresh handling.
 
**US-025**: Telegram per-family bot provisioning  
**Priority**: 2  
**DependsOn**: US-005  
**Acceptance Criteria**:
- Bot created per household with unique token.
- Webhook configured to tenant runtime endpoint.
- Bot token stored in secrets manager with rotation support.
- Invite flow generates per-family QR or deep link.

 **US-016**: Morning Launch workflow pack  
 **Priority**: 1  
 **DependsOn**: US-013, US-015  
 **Acceptance Criteria**:
 - Daily briefing at configured time.
 - Includes schedule, weather, top priorities.
 - Push notification delivered to selected members.
 
 **US-017**: School Ops workflow pack  
 **Priority**: 1  
 **DependsOn**: US-013, US-015  
 **Acceptance Criteria**:
 - Parses school emails.
 - Extracts action items and creates tasks.
 - Adds events to calendar.
 
 **US-018**: Dinner and Groceries workflow pack  
 **Priority**: 2  
 **DependsOn**: US-013  
 **Acceptance Criteria**:
 - Generates weekly meal plan.
 - Produces grocery list.
 - Supports dietary preferences.
 
 **US-019**: Activity Coordinator workflow pack  
 **Priority**: 2  
 **DependsOn**: US-013, US-015  
 **Acceptance Criteria**:
 - Detects recurring activities.
 - Coordinates pickup/dropoff.
 - Sends reminders to parents.
 
 **US-020**: Clawdbot skill format and manifest  
 **Priority**: 1  
 **Acceptance Criteria**:
 - Skill files follow Clawdbot frontmatter format.
 - `skills_manifest.json` created with dependencies.
 - `clawd skills install -m` flow documented.
 
 **US-021**: Convert homeskills into executable skills  
 **Priority**: 1  
 **DependsOn**: US-020  
 **Acceptance Criteria**:
 - Core skills: family-comms, mental-load, school, meal-planning, transportation, healthcare, elder-care.
 - Each skill includes deterministic steps and tool calls.
 
 **US-022**: Port skills catalog to Clawdbot  
 **Priority**: 2  
 **DependsOn**: US-020  
 **Acceptance Criteria**:
 - Catalog skills translated into executable Clawdbot skill files.
 - Domain grouping and dependencies defined.
 - Example flows for multiple family scenarios.
 
 **US-023**: Observability and health checks  
 **Priority**: 2  
 **DependsOn**: US-013  
 **Acceptance Criteria**:
 - Health endpoints for control plane, runtime, workflows.
 - Logs centralized with redaction.
 - Alerts for failures >5 min.
 
 **US-024**: Security and privacy controls  
 **Priority**: 1  
 **Acceptance Criteria**:
 - Encryption at rest and in transit.
 - Tenant isolation enforced.
 - Data deletion/export flows documented.
 
 ---
 
 ## Ralph Execution Notes
 - Track story completion in `docs/IosPRD/prd.json` (`passes: true` when verified).
 - Use `scripts/ralph/run.sh` to pick the next runnable story.
 - Log progress in `docs/IosPRD/progress.txt`.
