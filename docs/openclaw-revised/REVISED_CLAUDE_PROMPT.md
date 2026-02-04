# Revised Claude Code Prompt for OpenClaw Implementation

## Purpose
This document provides an optimized prompt for Claude Code to implement the OpenClaw iOS app end-to-end. Use this prompt to start a fresh Claude Code session for implementation.

---

## THE PROMPT

```
I need you to implement OpenClaw, a production-ready Swift iOS app that transforms HomeOS skills into deterministic workflows powered by local AI models (Gemma 3n and FunctionGemma).

CONTEXT:
- You have full access to the homeOS repository at /Users/bharathsudharsan/homeOS
- Read the comprehensive PRD at docs/openclaw-revised/PRD.md
- Read the skill breakdowns in docs/openclaw-revised/skills/
- Read the API documentation at docs/openclaw-revised/apis/

YOUR TASK:
Implement a complete, tested, production-ready Xcode project with the following requirements:

## 1. PROJECT SETUP
Create a new Swift iOS app project:
- Project name: OpenClaw
- Minimum iOS version: 17.0
- Architecture: MVVM with Combine
- UI: SwiftUI
- Testing: XCTest + XCUITest

## 2. CORE ARCHITECTURE
Implement the layered architecture from the PRD:

**Layer 1: SwiftUI Views**
- ChatView (main interface)
- SkillCardsView (meal planning, healthcare, education, etc.)
- OnboardingFlow (5-step setup)
- SettingsView
- CalendarView
- TaskListView

**Layer 2: View Models**
- ChatViewModel
- MealPlanningViewModel
- HealthcareViewModel
- EducationViewModel
- ElderCareViewModel
- HomeMaintenanceViewModel
- FamilyCoordinationViewModel

**Layer 3: Business Logic**
- SkillOrchestrator: Routes intents to skill handlers
- WorkflowEngine: Executes deterministic decision trees
- DecisionEngine: Applies business rules
- Each skill has its own handler class (MealPlanningSkill, HealthcareSkill, etc.)

**Layer 4: AI Integration**
- ModelManager: Loads and manages Gemma 3n and FunctionGemma
- PromptBuilder: Constructs prompts with context
- ResponseParser: Extracts intents and parameters
- Use MLX framework for on-device inference

**Layer 5: Data Persistence**
- Core Data models matching the PRD schema
- KeychainManager for sensitive data
- FileManager for exports and logs

**Layer 6: External Integrations**
- APIClient protocol with concrete implementations
- SpoonacularAPI
- GoogleCalendarAPI
- GoogleClassroomAPI
- TwilioAPI
- OpenFDAAPI
- GooglePlacesAPI
- WeatherAPI

## 3. SKILL IMPLEMENTATIONS
Implement all skills as defined in docs/openclaw-revised/skills/:

1. **Meal Planning**
   - Weekly menu generation with protein rotation
   - Grocery list generation
   - Pantry inventory management
   - Recipe search with dietary filters
   - Cost estimation

2. **Healthcare**
   - Symptom triage with severity assessment
   - Appointment booking
   - Medication reminders
   - Provider search
   - Emergency protocols

3. **Education**
   - LMS sync (Google Classroom, Canvas)
   - Homework tracking
   - Grade monitoring with alerts
   - Study plan generation
   - Teacher communication drafts

4. **Elder Care**
   - Scheduled wellness check-ins via voice calls
   - Medication compliance tracking
   - Health observation logging
   - Red flag detection and family alerts
   - Weekly reports

5. **Home Maintenance**
   - Emergency assessment and safety protocols
   - Contractor search and coordination
   - Preventive maintenance scheduling
   - Repair history tracking

6. **Family Coordination**
   - Shared calendar with conflict detection
   - Announcements and broadcasts
   - Location tracking
   - Chore assignment with gamification

7. **Mental Load Automation**
   - Morning briefings
   - Evening wind-downs
   - Proactive reminders
   - Weekly planning

## 4. AI MODEL INTEGRATION
Implement local AI inference:

**Model Loading:**
- Download Gemma 3n (INT4 quantized) and FunctionGemma
- Use MLX Swift bindings for Apple Silicon
- Lazy loading on app launch
- KV cache for multi-turn conversations

**Gemma 3n Usage:**
- Parse user intents
- Generate conversational responses
- Clarify ambiguous requests
- Format skill outputs

**FunctionGemma Usage:**
- Extract structured tool calls from user messages
- Validate parameters with confidence thresholds
- Return JSON function calls

**Prompt Engineering:**
- System prompts include family context
- Few-shot examples for tool call extraction
- Conversation history (last 5 turns)

## 5. DATA MODELS
Implement Core Data entities:
- Family
- FamilyMember
- MealPlan, PlannedMeal, Recipe, GroceryList
- HealthRecord, Medication, Appointment, SymptomLog
- StudentProfile, Assignment, GradeEntry
- ElderCareProfile, CheckInLog
- HomeProfile, ServiceProvider, MaintenanceTask
- CalendarEvent, Announcement, ChoreAssignment

Use relationships and cascading deletes appropriately.

## 6. API INTEGRATIONS
Implement working API clients with real endpoints:

**Priority APIs to integrate:**
1. Spoonacular (recipe search) - Get free API key
2. USDA FoodData Central (nutrition) - Free, no key
3. Google Calendar API - OAuth 2.0
4. Google Classroom API - OAuth 2.0
5. OpenFDA (medication info) - Free, no key
6. Google Places API - API key
7. wttr.in (weather) - Free, no key
8. Twilio (voice calls) - Get API key

For each API:
- Create dedicated client class
- Implement error handling
- Add retry logic
- Mock for testing

## 7. ONBOARDING FLOW
Implement 7-step onboarding:
1. Welcome screen
2. Family member setup
3. Priority skill selection
4. Skill-specific preferences
5. Permission requests
6. Model download
7. Ready screen

Make it skippable for testing.

## 8. TESTING
Write comprehensive tests:

**Unit Tests (60% coverage):**
- Test decision logic (meal rotation, symptom triage, grade alerts)
- Test atomic functions
- Test data model validation

**Integration Tests:**
- Test API clients (with mocked responses)
- Test workflow state transitions
- Test Core Data operations

**Simulation Tests:**
- Create 3 synthetic family profiles
- Generate realistic user requests
- Simulate 1 week of family behavior
- Validate outcomes (meal variety, medication compliance, etc.)

**UI Tests:**
- Test onboarding flow
- Test chat interface
- Test skill card navigation

## 9. PERFORMANCE OPTIMIZATION
- Use INT4 quantized models
- Implement KV cache for chat
- Lazy load skills
- Batch API requests where possible
- Target <500ms AI response latency on iPhone 15 Pro

## 10. PRIVACY & SECURITY
- Store health data in Keychain with AES-256
- Implement Face ID/Touch ID for app lock
- No cloud sync for sensitive data
- Data deletion functionality

## IMPLEMENTATION STRATEGY:
1. Start by reading all documentation in docs/openclaw-revised/
2. Create Xcode project structure
3. Implement Core Data models
4. Implement API clients (start with Spoonacular, Google Calendar)
5. Implement SkillOrchestrator and WorkflowEngine
6. Implement one skill end-to-end (Meal Planning) to validate architecture
7. Implement remaining skills
8. Add AI model integration
9. Build SwiftUI interface
10. Write tests
11. Run simulations
12. Optimize and polish

## IMPORTANT CONSTRAINTS:
- This is for an AVERAGE AMERICAN FAMILY living in the US
- Make PRAGMATIC assumptions (families eat favorites multiple times/month)
- Workflows must be DETERMINISTIC (no unpredictable agentic behavior)
- INCREMENTAL information gathering (never block on missing data)
- Use WORKING APIs (verify with test requests)
- THOROUGH testing (100+ scenarios per skill)
- PRODUCTION-READY code (error handling, logging, documentation)

## DELIVERABLES:
1. Complete Xcode project that opens and builds successfully
2. All skills functional with working API integrations
3. Test suite with >60% unit test coverage
4. Simulation tests for realistic family scenarios
5. README with setup instructions
6. API key configuration guide

## QUALITY CHECKLIST:
Before marking complete, verify:
- [ ] Project builds without errors or warnings
- [ ] All API integrations tested with real requests
- [ ] Unit tests pass (>60% coverage)
- [ ] Integration tests pass
- [ ] Simulation tests pass (1 week for 3 family profiles)
- [ ] UI renders correctly on iPhone 15 Pro simulator
- [ ] Onboarding flow completes successfully
- [ ] Chat interface responds to test queries
- [ ] Core Data persistence works
- [ ] No memory leaks or crashes
- [ ] AI models load and generate responses (even if using stubs initially)

## PARALLEL EXECUTION:
Use sub-agents to work on independent tasks simultaneously:
- Agent 1: API client implementations
- Agent 2: Core Data models and persistence
- Agent 3: Skill logic implementations
- Agent 4: Test suite creation
- Agent 5: SwiftUI interface
- Agent 6: AI model integration

## OUTPUT:
Provide the complete Xcode project at: /Users/bharathsudharsan/homeOS/apps/ios/OpenClaw/
Provide GitHub links to all files so I can review them.

Begin implementation now.
```

---

## Usage Instructions

### For Claude Code:

1. **Start a fresh Claude Code session**
2. **Copy the entire prompt above** (starting from "I need you to implement OpenClaw...")
3. **Paste into Claude Code**
4. **Let Claude Code orchestrate the implementation** using sub-agents

### Expected Behavior:

Claude Code will:
1. Read all documentation in `docs/openclaw-revised/`
2. Create Xcode project structure
3. Spawn multiple sub-agents to work in parallel:
   - API implementation agent
   - Core Data modeling agent
   - Skill logic agent
   - Test suite agent
   - UI implementation agent
4. Verify all APIs work with real test requests
5. Run comprehensive test suites
6. Provide GitHub links to completed files

### Timeline Estimate:

With parallel execution via sub-agents:
- Project setup: 30 minutes
- Core architecture: 2-3 hours
- API integrations: 2-3 hours
- Skill implementations: 4-6 hours
- Testing infrastructure: 2-3 hours
- UI implementation: 2-3 hours
- Testing and validation: 2-3 hours

**Total: 14-21 hours of agent time (much less wall-clock time with parallelization)**

---

## Success Criteria

The implementation is complete when:

1. ✅ Xcode project builds successfully
2. ✅ All 7 skills are functional
3. ✅ At least 3 API integrations work with real data
4. ✅ Unit tests achieve >60% coverage
5. ✅ Simulation tests validate realistic family scenarios
6. ✅ Chat interface accepts input and generates responses
7. ✅ Core Data persists family data correctly
8. ✅ Onboarding flow completes without errors
9. ✅ No critical bugs or crashes in basic usage

---

## Fallback Strategy

If full implementation is too complex for a single session:

### Phase 1 (Core Infrastructure):
- Xcode project + Core Data + API clients + 1 skill (Meal Planning)

### Phase 2 (Remaining Skills):
- Healthcare + Education + Elder Care

### Phase 3 (Polish):
- Home Maintenance + Family Coordination + Mental Load + Tests

Each phase can be done in separate Claude Code sessions by resuming with:
"Continue OpenClaw implementation. Complete Phase X as defined in docs/openclaw-revised/REVISED_CLAUDE_PROMPT.md"

---

## Monitoring Progress

While Claude Code is working, you can monitor progress by:

1. **Checking GitHub commits** (if using git integration)
2. **Reading log files** in `docs/openclaw-revised/logs/`
3. **Reviewing completed files** via provided GitHub links
4. **Running the Xcode project** periodically to test

---

**Document Version:** 1.0
**Last Updated:** 2026-02-02
