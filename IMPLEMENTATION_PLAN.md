# OiMyAI Implementation Plan

## Executive Summary

Transform Osaurus (a Swift-based macOS AI edge runtime) into **Oi My AI** with Skills capability, Rube MCP integration, Family features, and Telegram gateway - using gastown for multi-agent orchestration and feature-dev/ralph-wiggum plugins for structured development.

---

## Phase 0: Environment Setup

### 0.1 Prerequisites Installation

| Tool | Purpose | Status |
|------|---------|--------|
| Go 1.23+ | Required for gastown | Needs install |
| Git 2.25+ | Worktree support for gastown | ✅ Installed (2.43.0) |
| Node.js 22+ | Claude Code CLI | ✅ Installed (v24.2.0) |
| Claude Code | Development environment | ✅ Installed |
| Xcode 16.4+ | Swift development | Needs verification |

### 0.2 Tool Installation Commands

```bash
# Install Go via Homebrew
brew install go

# Install gastown
go install github.com/steveyegge/gastown/cmd/gt@latest

# Verify installation
gt --version
```

### 0.3 Gastown Configuration for OiMyAI

```bash
# Initialize gastown workspace
gt install ~/gt --git

# Add OiMyAI as a rig (after cloning osaurus)
gt rig add oimyai /Users/bharathsudharsan/OiMyAI

# Create crew for development
gt crew add bharath --rig oimyai

# Attach to workspace
gt mayor attach
```

### 0.4 Plugin Installation

**feature-dev plugin:**
```bash
# Clone from claude-code plugins
git clone --sparse https://github.com/anthropics/claude-code.git /tmp/claude-code-plugins
cd /tmp/claude-code-plugins
git sparse-checkout set plugins/feature-dev plugins/ralph-wiggum

# Copy to project
cp -r /tmp/claude-code-plugins/plugins/feature-dev /Users/bharathsudharsan/OiMyAI/.claude/plugins/
cp -r /tmp/claude-code-plugins/plugins/ralph-wiggum /Users/bharathsudharsan/OiMyAI/.claude/plugins/
```

**Configure in settings.json:**
```json
{
  "plugins": [
    { "path": ".claude/plugins/feature-dev" },
    { "path": ".claude/plugins/ralph-wiggum" }
  ]
}
```

### 0.5 SuperDesign Setup

```bash
# Install SuperDesign extension (Cursor/VS Code)
# Or configure for Claude Code via custom rules

# Create .superdesign directory for project assets
mkdir -p /Users/bharathsudharsan/OiMyAI/.superdesign
```

---

## Phase 1: Foundation Setup

### 1.1 Clone Osaurus as Base

```bash
cd /Users/bharathsudharsan/OiMyAI
git clone https://github.com/dinoki-ai/osaurus.git .
```

### 1.2 Initial Project Structure

```
OiMyAI/
├── App/                    # Osaurus app code (minimal changes)
├── Packages/               # Swift packages
│   └── SkillsKit/          # NEW: Skills module
├── OimyaiGateway/          # NEW: Telegram gateway service
├── .claude/
│   ├── settings.json
│   └── plugins/
│       ├── feature-dev/
│       └── ralph-wiggum/
├── .superdesign/           # SuperDesign assets
├── docs/
├── assets/
│   └── AppIcon.appiconset/ # NEW: Oi My AI icons
└── HomeSkills/             # NEW: Bundled skills
```

---

## Phase 2: Implementation Milestones

### Milestone 1: Rebrand & Bundle ID
**Using:** `/feature-dev` workflow

| Task | Details |
|------|---------|
| Replace visible "Osaurus" → "Oi My AI" | UI strings, About dialog, menu items |
| Set bundle ID | `com.fantasticapp.oimyai` |
| New app icon | Design via SuperDesign, update assets |
| Keep internal identifiers | `osaurus.*` tool IDs remain unchanged |

**Acceptance Criteria:**
- App launches with new branding
- Chat works
- Existing tools functional
- No feature changes

---

### Milestone 2: Skills Manager UI Scaffold
**Using:** `/feature-dev` + SuperDesign for mockups

| Component | Description |
|-----------|-------------|
| Left nav item | "Skills Manager" menu entry |
| Tile view | Grid of skill cards showing: name, description, badges, status |
| Detail view | Full description, triggers, tools/MCPs used, "Run test" button |
| Badges | "Bundled", "Network", "Requires Setup", "Family", "Proactive" |

**SuperDesign Workflow:**
1. Generate mockups for tile view layout
2. Generate detail screen design
3. Export to Swift code

---

### Milestone 3: SkillsKit Module + HomeSkills Ingestion
**Using:** `/ralph-wiggum` loop for iterative development

**Reference Document:** See `SKILLS_GAP_ANALYSIS.md` for complete tool mappings

| Component | Description |
|-----------|-------------|
| SkillDefinition | JSON schema for skill definitions |
| SkillIngestor | Load from bundled, ClawdHub, user-created |
| SkillLint | Validate no dead ends, missing tools |
| HomeSkills | Bundle default skills (20+ skills from homeOS) |

#### 3.1 HomeSkills Gap Analysis (Pre-completed)

All 20+ HomeSkills have been analyzed and tool requirements documented in `SKILLS_GAP_ANALYSIS.md`:

| Skill Category | Skills | Primary Tools Required |
|----------------|--------|------------------------|
| Core Utilities | tools | google_calendar, instacart, openweathermap, exa |
| Healthcare | healthcare | google_calendar, telephony API (optional) |
| Meal & Food | meal-planning, restaurant-reservation | spoonacular, yelp, opentable/telephony |
| Family | family-comms, elder-care, family-bonding | telegram gateway, google_calendar, spotify |
| Home | home-maintenance, transportation | yelp, google_maps, app deep links |
| Education | education, school | google_classroom, canvas (optional) |
| Wellness | wellness, habits | HealthKit (optional), local storage |
| Services | hire-helper, marketplace-sell, telephony | exa search, ebay, bland_ai |
| Personal | psy-rich, note-to-actions, mental-load | eventbrite, firecrawl, orchestration |

#### 3.2 Tool Resolution for Small LLMs

**Design Principle:** Skills must specify EXACT tool sequences to enable deterministic execution by smaller models (7B-70B parameter range) without requiring tool discovery at runtime.

Each skill includes:
```json
{
  "toolSequence": [
    { "step": 1, "tool": "specific.tool.name", "params": ["list", "of", "params"] },
    { "step": 2, "tool": "next.tool", "requiresApproval": true }
  ],
  "fallbackSequence": [
    { "step": 1, "tool": "alternative.tool", "params": [...] }
  ],
  "approvalGates": {
    "HIGH_RISK": ["make_call", "send_money"],
    "validResponses": ["yes", "approved", "go ahead"]
  }
}
```

#### 3.3 MCP Server Requirements (Prioritized)

**P0 - Must Have (Core Functionality):**
- `google_calendar` - Calendar management (via Rube)
- `openweathermap-mcp` - Weather forecasts
- `exa-mcp` - Web search (Official MCP)
- `firecrawl-mcp` - Web content extraction (Official MCP)

**P1 - Should Have (Enhanced Experience):**
- `yelp` via Rube - Local business search
- `google_maps` via Rube - Directions, traffic
- `instacart` via Rube - Grocery shopping
- `spoonacular-mcp` - Recipes and nutrition
- `pushover-mcp` - Push notifications

**P2 - Nice to Have (Premium Features):**
- `bland_ai` API - AI voice calls
- `spotify` via Rube - Music playback
- `eventbrite` via Rube - Event discovery
- `google_classroom` - LMS integration

#### 3.4 Fallback Strategy

Every skill defines what happens when primary tools aren't available:

| Primary Tool | Fallback | User Experience |
|--------------|----------|-----------------|
| Calendar API | Local JSON | Manual sync needed |
| Telephony API | Call script | User makes call |
| Ride booking | App deep links | Opens Uber/Lyft app |
| LMS API | Manual entry | Parent inputs data |

**Skill Definition Schema:**
```json
{
  "id": "home.morning_routine.v1",
  "name": "Morning Routine",
  "version": "1.0.0",
  "author": "HomeOS",
  "source": { "kind": "bundled", "uri": "homeskills/morning_routine.md" },
  "triggers": [...],
  "requiredCapabilities": [...],
  "steps": [...],
  "toolSequence": [...],
  "fallbackSequence": [...],
  "privacy": { "dataClasses": [...], "consentRequired": true }
}
```

**SkillLint Rules:**
- Fail if no `requiredCapabilities` AND no `steps.toolCalls`
- Fail if referenced tool not resolvable to:
  - Built-in Osaurus tools (`osaurus.*`)
  - Enabled MCP servers (Rube)
  - Configured external MCP servers
- Validate `fallbackSequence` exists for critical tools
- UI shows "Needs setup" state for failed validation

---

### Milestone 4: Rube MCP Integration
**Using:** `/feature-dev` for architecture, `/ralph-wiggum` for implementation

| Component | Description |
|-----------|-------------|
| MCPServerProfile | Predefined "Rube (Composio)" entry |
| Feature flag | `rubeIntegration` (default: off) |
| Dev Mode | Hidden token entry field |
| Test Connection | List tools, show status |

**Dev Mode Activation:**
- Keyboard chord: `⌥⌘D` on Settings screen, OR
- Click app version label 7 times

**Token Storage:**
- Keychain (never UserDefaults)

**Test Connection Response:**
- Connected/Not connected status
- Tool count
- Last error string
- Never crash on misconfiguration

---

### Milestone 5: Skill Execution Engine v1
**Using:** `/ralph-wiggum` loop

| Component | Description |
|-----------|-------------|
| Intent matching | Map user chat to skill triggers |
| Requirement check | SkillLint validation |
| Step execution | Execute toolcalls sequentially |
| Response | Consolidated response + audit trail |

**Reactive Only** (no proactive scheduling in v1)

---

### Milestone 6: Family Model v1
**Using:** `/feature-dev` workflow

| Component | Description |
|-----------|-------------|
| FamilyID | Local identifier |
| Primary user | Profile on main Mac |
| Members list | name, role, Telegram handle |
| Join flow | 6-digit code, 10 min TTL |
| Approval | Primary sees request, approves in app |

**Per-member permissions:**
- Allowed skills
- Data access scope (e.g., calendar read-only)
- Quiet hours for proactive messages

---

### Milestone 7: Telegram Gateway v1
**Using:** `/feature-dev` for architecture

| Component | Description |
|-----------|-------------|
| OimyaiGateway | Separate service target (LaunchAgent) |
| Mode | Polling (simplest, no public URL needed) |
| IPC | Local HTTP (127.0.0.1) + Keychain token |

**Message Flow:**
```
Incoming:  Telegram → Gateway → App → LLM/Skills → App → Gateway → Telegram
Proactive: App scheduler → Gateway → Telegram
```

**Safety:**
- Rate-limit tool calls
- Confirmation prompts for side-effectful skills

---

### Milestone 8: Hardening
**Using:** `/ralph-wiggum` loop

- Logging infrastructure
- Consent prompts for sensitive operations
- Rate limiting
- Error handling refinement
- Performance optimization

---

## Phase 3: Feature Flags Configuration

### Settings → Feature Flags UI

| Flag | Default | Description |
|------|---------|-------------|
| Skills Manager | ON | Skills tile view |
| Rube Integration | OFF | Composio MCP |
| ClawdHub Network | OFF | Fetch skills from network |
| Family Mode | OFF | Multi-user support |
| Telegram Gateway | OFF | External messaging |
| Proactive Automations | OFF | Scheduled skills |

### Hidden (Dev-only)

| Flag | Description |
|------|-------------|
| Developer Mode | Unlocks advanced settings |
| Rube Token Entry | Token configuration field |
| Verbose Tool Logs | Debug output |

---

## Phase 4: Testing Strategy

### Regression Suite ("Don't break Osaurus")

1. App launches successfully
2. Open chat overlay
3. Run built-in tool (filesystem read/list)
4. Start MCP server (Osaurus's own MCP mode)

### New Feature Tests

1. Skills Manager loads bundled skills
2. SkillLint catches missing tools
3. Rube disabled: app behaves normally
4. Rube enabled but token missing: shows "setup required", no crash
5. Telegram enabled but not configured: shows "setup required", no crash

---

## Plugin Usage Strategy

### /feature-dev Usage

Use for milestones requiring:
- Architecture decisions
- Multiple file changes
- Integration with existing code
- Quality review

**Command format:**
```
/feature-dev [Milestone description]
```

### /ralph-wiggum Usage

Use for:
- Iterative implementation tasks
- Test-driven development
- Continuous refinement until completion

**Command format:**
```
/ralph-loop "[task]" --completion-promise "DONE" --max-iterations 10
```

### SuperDesign Usage

Use for:
- UI mockups before implementation
- Component design
- Visual iteration

---

## Gastown Multi-Agent Orchestration

### Parallel Agent Tasks

```bash
# Agent 1: SkillsKit development
gt spawn agent-skillskit --task "Implement SkillDefinition schema"

# Agent 2: UI development
gt spawn agent-ui --task "Skills Manager tile view"

# Agent 3: Gateway development
gt spawn agent-gateway --task "Telegram polling service"
```

### Coordination

- Use git worktrees for agent isolation
- Gastown persists state across restarts
- Mayor coordinates merge points

---

## Requirements Traceability (Ralph Wiggum Checklist)

| Requirement | Plan Section | Status |
|-------------|--------------|--------|
| Rename Osaurus → Oi My AI (visible only) | Milestone 1 | Planned |
| Bundle ID com.fantasticapp.oimyai | Milestone 1 | Planned |
| Rube MCP in code, feature-flagged | Milestone 4 | Planned |
| Secret dev mode for token | Milestone 4 | Planned |
| Skills Manager (tiles + details + tools) | Milestone 2, 3 | Planned |
| HomeSkills bundled by default | Milestone 3 | Planned |
| ClawdHub skills (network optional) | Milestone 3 + Flags | Planned |
| No dead-end skills (SkillLint) | Milestone 3 | Planned |
| Family model (join code + approval) | Milestone 6 | Planned |
| Telegram gateway (Option A) | Milestone 7 | Planned |
| Don't modify Clawdbot (inspiration only) | Architecture | Enforced |
| App functional after each milestone | Testing | Required |

---

## Execution Order

1. **Environment Setup** (Phase 0) - Install tools, configure gastown/plugins
2. **Clone Osaurus** (Phase 1.1)
3. **Rebrand** (Milestone 1) - `/feature-dev`
4. **Skills Manager UI** (Milestone 2) - `/feature-dev` + SuperDesign
5. **SkillsKit** (Milestone 3) - `/ralph-wiggum`
6. **Rube Integration** (Milestone 4) - `/feature-dev` + `/ralph-wiggum`
7. **Skill Execution** (Milestone 5) - `/ralph-wiggum`
8. **Family Model** (Milestone 6) - `/feature-dev`
9. **Telegram Gateway** (Milestone 7) - `/feature-dev`
10. **Hardening** (Milestone 8) - `/ralph-wiggum`

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking Osaurus core | Feature flags, regression tests after each milestone |
| Rube token security | Keychain storage only |
| Gateway security | Local-only IPC, rate limiting |
| Dead-end skills | SkillLint enforcement |
| Context loss | Gastown persistence |

---

## Small LLM Optimization Strategy

### Why This Matters

The gap analysis and skill refinement enables Oi My AI to work effectively with smaller, local models (7B-70B parameters) instead of requiring large frontier models like Claude Opus 4.5 for every interaction.

### How It Works

| Aspect | Large Model Approach | Small Model Approach (Our Design) |
|--------|---------------------|-----------------------------------|
| Tool selection | Model discovers tools at runtime | Skill specifies exact tool sequence |
| Error handling | Model reasons about failures | Predefined fallback sequences |
| Approval gates | Model decides risk level | Hardcoded risk classifications |
| Intent matching | Free-form understanding | Trigger phrase matching |

### Benefits

1. **Lower latency** - Local inference on Apple Silicon
2. **Lower cost** - No API calls for routine operations
3. **Privacy** - Sensitive data stays on device
4. **Reliability** - Deterministic tool execution
5. **Offline capability** - Core skills work without internet

### Model Routing Strategy

```
User Request
    ↓
Intent Classification (Local small model)
    ↓
Match to Skill? ──Yes──→ Execute Skill (deterministic toolSequence)
    │
    No
    ↓
Complex reasoning needed? ──Yes──→ Route to frontier model (Claude/GPT)
    │
    No
    ↓
Handle with local model (general chat)
```

### Recommended Local Models

| Model | Size | Use Case |
|-------|------|----------|
| Llama 3.2 3B | 3B | Intent classification, simple chat |
| Qwen 2.5 7B | 7B | Skill execution, moderate reasoning |
| Llama 3.1 70B | 70B | Complex tasks, fallback |

---

## Project Documents

| Document | Purpose |
|----------|---------|
| `IMPLEMENTATION_PLAN.md` | This document - overall plan |
| `SKILLS_GAP_ANALYSIS.md` | Tool requirements for all 20+ HomeSkills (with Plan to Eat, telephony flows, TaskRabbit, Nextdoor, Apple native integrations) |
| `DEVELOPER_SETUP_GUIDE.md` | **NEW:** Complete guide for setting up Bland.ai, TaskRabbit, Nextdoor, Firecrawl, and all other services with API key management |
| `requirements.docx` | Original requirements from user |

---

## API Key & User Isolation Strategy

### Developer-Managed Services

All external API keys are managed by the developer, not individual users:

| Service | Developer Setup | User Experience |
|---------|-----------------|-----------------|
| Bland.ai | Purchases numbers, stores API key | Gets assigned number automatically |
| TaskRabbit | Registers OAuth app | Authorizes via OAuth popup |
| Nextdoor | Gets developer access | Authorizes via OAuth popup |
| Firecrawl | Obtains API key | Transparent (no action needed) |
| Weather | Gets API key | Transparent |
| Spoonacular | Gets API key | Transparent |

### User Isolation

Every API request includes user identification to prevent cross-user data mixing:
- Header: `X-User-ID: user_abc123`
- Body: `request_data.user_id: "user_abc123"`
- Phone numbers: Assigned from developer's pool to specific users

See `DEVELOPER_SETUP_GUIDE.md` for complete setup instructions.

---

## Awaiting Approval

Please review this plan and confirm:
1. Environment setup approach
2. Milestone order and scope
3. Plugin usage strategy
4. **NEW:** Skills gap analysis and tool mappings
5. **NEW:** Small LLM optimization approach
6. Any modifications needed

Once approved, I will begin execution starting with Phase 0 (Environment Setup).
