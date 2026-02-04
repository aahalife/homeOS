# OpenClaw: Product Requirements Document
## AI-Powered Family Assistant iOS App

**Version:** 1.0
**Date:** February 2, 2026
**Author:** OpenClaw Team
**Status:** Implementation Ready

---

## Executive Summary

OpenClaw is a production-ready iOS application that transforms high-level HomeOS skills into deterministic, atomic workflows powered by local AI models (Gemma 3n for chat, FunctionGemma for tool calls). The app reduces cognitive load for American families by intelligently managing meal planning, healthcare, education, elder care, home maintenance, and daily coordination.

### Key Differentiators
- **100% On-Device AI**: Privacy-first architecture with Gemma 3n (3B parameters) and FunctionGemma
- **Deterministic Workflows**: Reliable, tested execution paths vs. unpredictable agentic behavior
- **Incremental Information Gathering**: Learns as you use it, never blocks on missing data
- **Family-Aware Intelligence**: Multi-profile support with shared context
- **Pragmatic Assumptions**: Mimics human assistant reasoning about real family behavior

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Target Users](#2-target-users)
3. [Core Features](#3-core-features)
4. [Technical Architecture](#4-technical-architecture)
5. [AI Model Integration](#5-ai-model-integration)
6. [Data Models](#6-data-models)
7. [Skill Decomposition](#7-skill-decomposition)
8. [User Onboarding Flow](#8-user-onboarding-flow)
9. [API Integrations](#9-api-integrations)
10. [Testing Strategy](#10-testing-strategy)
11. [Privacy & Security](#11-privacy--security)
12. [Success Metrics](#12-success-metrics)
13. [Implementation Roadmap](#13-implementation-roadmap)

---

## 1. Problem Statement

### Current Pain Points
- **Mental Load Overload**: Parents track 100+ family tasks mentally (appointments, homework, meals, medications)
- **Fragmented Tools**: Separate apps for calendar, health, education, household management
- **Generic AI Assistants**: Cloud-based solutions lack family context and privacy guarantees
- **Unpredictable Behavior**: Large language models make creative but unreliable decisions

### Our Solution
OpenClaw provides a **deterministic, privacy-first family OS** that:
- Automates routine decisions with intelligent defaults
- Learns family preferences incrementally without upfront questionnaires
- Makes pragmatic assumptions based on typical American family patterns
- Keeps all sensitive data on-device

---

## 2. Target Users

### Primary Persona: "Coordinating Parent"
- **Age**: 32-48
- **Household**: 2-4 people (partner, 1-3 children, possibly aging parents)
- **Tech Comfort**: Moderate (uses iPhone, standard apps)
- **Pain Point**: "I'm the family's operating system and it's exhausting"

### Secondary Persona: "Sandwich Generation Caregiver"
- **Age**: 45-60
- **Household**: Multi-generational (own family + aging parent nearby)
- **Pain Point**: "I'm managing two households and can't keep up"

### User Demographics (US-Focused)
- **Location**: United States (time zones, cuisine, healthcare system)
- **Dietary Patterns**: 60% omnivore, 30% flexitarian, 10% vegetarian/vegan
- **Healthcare**: Familiar with insurance, copays, telemedicine
- **Education**: K-12 school system, LMS platforms (Google Classroom, Canvas)

---

## 3. Core Features

### 3.1 Intelligent Meal Planning
**What It Does:**
- Generates realistic weekly meal plans with grocery lists
- Accounts for leftovers, busy weeknights, weekend cooking
- Pragmatic repetition (families eat favorites multiple times/month)

**Key Workflows:**
1. New user: Proposes sample week based on family size + dietary preferences
2. Existing user: Rotates past favorites with 2-3 new recipes
3. Last-minute: "What should I make tonight?" uses pantry inventory
4. Shopping: Auto-generates categorized lists with cost estimates

**Smart Defaults:**
- Monday-Thursday: 30-min meals
- Friday: Takeout or easy comfort food
- Weekend: 60-90 min cooking projects
- Protein rotation: Chicken → Beef → Vegetarian → Seafood

### 3.2 Healthcare Management
**What It Does:**
- Tracks medications, appointments, immunizations per family member
- Symptom checker with severity assessment (always disclaims non-professional advice)
- Insurance-aware provider search

**Key Workflows:**
1. Medication reminders with visual confirmation
2. Appointment booking with calendar sync
3. Symptom assessment → triage (self-care / doctor visit / ER)
4. Preventive care nudges (annual checkup due)

**Safety Features:**
- Never diagnoses
- Always recommends ER for severe symptoms
- Requires confirmation before booking appointments

### 3.3 Education Hub
**What It Does:**
- Syncs with Google Classroom / Canvas LMS
- Tracks homework, tests, grades across multiple children
- Proactive alerts for missing work or grade drops

**Key Workflows:**
1. Daily 4pm homework review
2. Weekly grade monitoring with trend analysis
3. Study plan generation for tests
4. Teacher communication drafts

**Smart Alerts:**
- Grade < 70%: Urgent parent notification
- 5+ point drop: Suggest intervention (tutoring, study plan)
- Overdue work: Prioritized task list

### 3.4 Elder Care Check-Ins
**What It Does:**
- Dignified daily wellness calls to aging parents
- Medication adherence tracking
- Health symptom monitoring
- Weekly reports to adult children

**Key Workflows:**
1. Morning/evening voice check-ins with conversational warmth
2. Medication confirmation (gentle, not surveillance-like)
3. Symptom logging through natural conversation
4. Music playback (era-appropriate: 1950s-1970s)
5. Urgent alerts to family for concerning observations

**Conversation Framework:**
- Greeting → Wellness question → Medication reminder → Activity (music/memory) → Positive close

### 3.5 Home Maintenance
**What It Does:**
- Emergency triage with safety-first protocols
- Service provider search and coordination
- Preventive maintenance scheduling

**Key Workflows:**
1. Emergency assessment (gas leak / flood / electrical)
2. Safety protocol guidance (evacuate, shut off utilities)
3. Contractor search with ratings
4. Appointment scheduling
5. Maintenance calendar (filter changes, inspections)

**Critical Emergency Protocols:**
- Gas leak: Evacuate → Call 911 from outside
- Major water leak: Shut main valve → Document for insurance
- Electrical hazard: Shut breaker → Call electrician

### 3.6 Family Coordination
**What It Does:**
- Shared calendar with conflict detection
- Announcements and check-ins
- Chore assignment with gamification

**Key Workflows:**
1. Broadcast messages ("Dinner at 6pm")
2. Location tracking with battery status
3. Task delegation with point system
4. Schedule optimization for family meetings

### 3.7 Mental Load Automation
**What It Does:**
- Morning briefings (7am): Day overview, weather, priorities
- Evening wind-down (8pm): Task review, tomorrow prep
- Proactive reminders (school picture day, birthdays)

**Philosophy:**
- Propose specific suggestions, don't ask open questions
- Anticipate needs before they're expressed
- Track tasks so families don't mentally carry them

---

## 4. Technical Architecture

### 4.1 System Overview

```
┌─────────────────────────────────────────────────────────┐
│                     iOS App (Swift)                     │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           SwiftUI Views Layer                    │  │
│  │  - Chat Interface                                │  │
│  │  - Skill Cards (Meals, Health, Education, etc)  │  │
│  │  - Calendar & Task Views                        │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │      View Models (Combine + Async/Await)        │  │
│  │  - ChatViewModel                                 │  │
│  │  - SkillViewModels (MealVM, HealthVM, etc)     │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │          Business Logic Layer                    │  │
│  │  - SkillOrchestrator                            │  │
│  │  - WorkflowEngine                               │  │
│  │  - DecisionEngine                               │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │         AI Integration Layer                     │  │
│  │                                                  │  │
│  │  ┌────────────────┐    ┌────────────────────┐  │  │
│  │  │  Gemma 3n      │    │  FunctionGemma     │  │  │
│  │  │  (Chat Model)  │    │  (Tool Calls)      │  │  │
│  │  │  MLX/CoreML    │    │  MLX/CoreML        │  │  │
│  │  └────────────────┘    └────────────────────┘  │  │
│  │                                                  │  │
│  │  - ModelLoader                                   │  │
│  │  - PromptBuilder                                 │  │
│  │  - ResponseParser                                │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │         Data Persistence Layer                   │  │
│  │  - Core Data (structured data)                   │  │
│  │  - SwiftData (preferences, cache)               │  │
│  │  - Keychain (sensitive data)                     │  │
│  │  - FileManager (exports, logs)                   │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 │                                       │
│  ┌──────────────▼───────────────────────────────────┐  │
│  │         External Integrations                    │  │
│  │  - RESTful API Client                            │  │
│  │  - Authentication Manager                        │  │
│  │  - Network Monitor                               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
         ┌──────────────────────────────┐
         │   External APIs (Network)    │
         │  - OpenFDA (medication)      │
         │  - USDA FoodData (nutrition) │
         │  - Google Calendar API       │
         │  - Twilio (calls/SMS)        │
         │  - OpenStreetMap             │
         └──────────────────────────────┘
```

### 4.2 Core Components

#### **SkillOrchestrator**
- Routes user intents to appropriate skill handlers
- Manages cross-skill dependencies (e.g., meal planning → calendar)
- Handles state transitions in multi-turn workflows

#### **WorkflowEngine**
- Executes deterministic decision trees for each skill
- Manages context across conversation turns
- Implements fallback strategies for missing data

#### **DecisionEngine**
- Applies business logic rules (meal variety, grade alerts, emergency triage)
- Makes intelligent assumptions based on family patterns
- Prioritizes actions by urgency/importance

#### **AI Integration Layer**
- **Gemma 3n**: Natural language understanding, conversational responses
- **FunctionGemma**: Structured tool call generation and parameter extraction
- Runs on-device using MLX framework (Apple Silicon optimized)

#### **Data Persistence**
- **Core Data**: Family profiles, schedules, health records, meal history
- **SwiftData**: Cached responses, user preferences
- **Keychain**: API keys, encrypted health data
- **File System**: Logs, exports, backups

---

## 5. AI Model Integration

### 5.1 Model Selection

| Model | Purpose | Size | Latency | Accuracy Requirement |
|-------|---------|------|---------|---------------------|
| **Gemma 3n** | Chat, NLU, responses | 3B params | <500ms | High (user-facing) |
| **FunctionGemma** | Tool call extraction | Tuned variant | <300ms | Very High (critical) |

### 5.2 Gemma 3n Integration (Chat Model)

**Use Cases:**
- Understanding user intent from natural language
- Generating conversational responses
- Clarifying ambiguous requests
- Providing explanations for recommendations

**Prompt Structure:**
```
<SYSTEM>
You are OpenClaw, a family assistant helping {family_name}. Current context:
- Family members: {member_list}
- Active skills: {skill_context}
- User preferences: {preferences}

Guidelines:
- Be concise and actionable
- Ask clarifying questions when needed
- Make intelligent assumptions based on typical family behavior
- Always respect dietary restrictions and health conditions
</SYSTEM>

<USER>
{user_message}
</USER>

<ASSISTANT>
```

**Response Handling:**
- Parse intent (skill + action + parameters)
- Extract entities (family members, dates, times, quantities)
- Identify missing required information
- Route to appropriate skill handler

**Example Flow:**
```swift
// User: "Plan dinners for this week"
let intent = await gemma3n.parseIntent(userMessage)
// Intent: { skill: "meal_planning", action: "generate_weekly_plan", params: {} }

let missingInfo = workflowEngine.checkRequiredParams(intent)
// missingInfo: ["dietary_preferences", "family_size"] if new user

if !missingInfo.isEmpty {
    let response = await gemma3n.generateClarification(missingInfo)
    // "I'd love to help! How many people are you cooking for, and are there any dietary restrictions?"
} else {
    let plan = await mealPlanningSkill.generatePlan(intent.params)
    let response = await gemma3n.formatResponse(plan)
}
```

### 5.3 FunctionGemma Integration (Tool Calls)

**Use Cases:**
- Extracting structured parameters from user requests
- Determining which API calls to make
- Parsing multi-step workflows into atomic actions

**Tool Call Schema:**
```json
{
  "function_name": "create_meal_plan",
  "parameters": {
    "num_days": 7,
    "family_size": 4,
    "dietary_restrictions": ["vegetarian"],
    "max_prep_time_weekday": 30,
    "budget": 150
  },
  "confidence": 0.92
}
```

**Example Tools:**
- `create_meal_plan()`
- `book_appointment()`
- `set_medication_reminder()`
- `search_recipes()`
- `calculate_grocery_list()`
- `assess_symptom_severity()`
- `find_contractor()`

**Prompt Structure:**
```
<TOOLS>
{tool_definitions_json}
</TOOLS>

<USER_REQUEST>
{user_message}
</USER_REQUEST>

<CONTEXT>
{family_profile, recent_history, current_state}
</CONTEXT>

Generate the appropriate tool call(s) in JSON format.
```

**Validation Layer:**
- Confidence threshold: 0.85 (below = ask for clarification)
- Required parameter check (fail gracefully if missing)
- Type validation (dates, numbers, enums)
- Safety checks for high-risk actions (bookings, calls, purchases)

### 5.4 MLX Framework Integration

**Why MLX?**
- Apple Silicon optimized (M1/M2/M3 chips)
- Unified memory architecture (efficient GPU access)
- Swift-friendly C++ API
- Low power consumption

**Model Loading:**
```swift
class ModelManager {
    private var chatModel: MLXModel?
    private var functionModel: MLXModel?

    func loadModels() async throws {
        // Load quantized INT4 models for efficiency
        chatModel = try await MLXModel.load(
            path: Bundle.main.path(forResource: "gemma-3n-int4", ofType: "mlx")
        )

        functionModel = try await MLXModel.load(
            path: Bundle.main.path(forResource: "function-gemma-int4", ofType: "mlx")
        )
    }

    func generateChatResponse(prompt: String, maxTokens: Int = 512) async -> String {
        guard let model = chatModel else { return "Model not loaded" }
        return await model.generate(prompt: prompt, maxTokens: maxTokens)
    }

    func extractFunctionCall(prompt: String) async -> FunctionCall? {
        guard let model = functionModel else { return nil }
        let output = await model.generate(prompt: prompt, maxTokens: 256)
        return try? JSONDecoder().decode(FunctionCall.self, from: output.data(using: .utf8)!)
    }
}
```

### 5.5 On-Device Inference Performance

**Target Benchmarks:**
| Device | Chat Response | Tool Call Extraction |
|--------|--------------|---------------------|
| iPhone 15 Pro (A17) | <500ms | <300ms |
| iPhone 14 Pro (A16) | <700ms | <400ms |
| iPhone 13 (A15) | <1000ms | <600ms |

**Optimization Strategies:**
- INT4 quantization (4x smaller models)
- KV cache for multi-turn conversations
- Batch processing for multiple tool calls
- Preload models on app launch

---

## 6. Data Models

### 6.1 Core Data Schema

#### **Family**
```swift
@Model
class Family {
    var id: UUID
    var name: String
    var members: [FamilyMember]
    var preferences: FamilyPreferences
    var createdAt: Date
    var updatedAt: Date
}
```

#### **FamilyMember**
```swift
@Model
class FamilyMember {
    var id: UUID
    var name: String
    var role: MemberRole // adult, child, elder
    var birthDate: Date?
    var dietaryRestrictions: [String]
    var allergies: [String]
    var medications: [Medication]
    var healthConditions: [String]
    var schoolInfo: SchoolInfo?
    var preferences: MemberPreferences
}

enum MemberRole: String, Codable {
    case adult, child, elder
}
```

#### **MealPlan**
```swift
@Model
class MealPlan {
    var id: UUID
    var weekStartDate: Date
    var meals: [PlannedMeal]
    var groceryList: GroceryList
    var estimatedCost: Decimal
    var status: PlanStatus // draft, active, completed
}

@Model
class PlannedMeal {
    var id: UUID
    var date: Date
    var mealType: MealType // breakfast, lunch, dinner, snack
    var recipe: Recipe
    var servings: Int
    var prepTime: Int // minutes
    var notes: String?
}

enum MealType: String, Codable {
    case breakfast, lunch, dinner, snack
}
```

#### **HealthRecord**
```swift
@Model
class HealthRecord {
    var id: UUID
    var memberId: UUID
    var appointments: [Appointment]
    var medications: [Medication]
    var immunizations: [Immunization]
    var symptomLogs: [SymptomLog]
    var insuranceInfo: InsuranceInfo?
}

@Model
class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: String // "twice daily", "as needed"
    var prescribedBy: String?
    var refillDate: Date?
    var reminders: [MedicationReminder]
}

@Model
class Appointment {
    var id: UUID
    var memberId: UUID
    var provider: HealthcareProvider
    var appointmentDate: Date
    var reason: String
    var status: AppointmentStatus // scheduled, completed, cancelled
    var notes: String?
}
```

#### **Education**
```swift
@Model
class StudentProfile {
    var id: UUID
    var memberId: UUID
    var gradeLevel: Int
    var schoolName: String
    var lmsConnection: LMSConnection? // Google Classroom, Canvas
    var assignments: [Assignment]
    var grades: [GradeEntry]
    var teachers: [Teacher]
}

@Model
class Assignment {
    var id: UUID
    var title: String
    var subject: String
    var dueDate: Date
    var status: AssignmentStatus // pending, completed, overdue
    var estimatedTime: Int // minutes
    var priority: Priority
}
```

#### **ElderCare**
```swift
@Model
class ElderCareProfile {
    var id: UUID
    var memberId: UUID
    var checkInSchedule: CheckInSchedule
    var checkInHistory: [CheckInLog]
    var medicationCompliance: [ComplianceRecord]
    var healthObservations: [Observation]
    var emergencyContacts: [EmergencyContact]
    var musicPreferences: MusicPreferences
}

@Model
class CheckInLog {
    var id: UUID
    var timestamp: Date
    var conversationSummary: String
    var wellnessScore: Int // 1-10
    var redFlags: [String]
    var medicationTaken: Bool
    var mood: MoodRating
}
```

#### **HomeMainten­ance**
```swift
@Model
class HomeProfile {
    var id: UUID
    var address: String
    var shutoffLocations: ShutoffInfo
    var hvacSpecs: HVACInfo?
    var contractors: [ServiceProvider]
    var maintenanceSchedule: [MaintenanceTask]
    var repairHistory: [RepairRecord]
}

@Model
class ServiceProvider {
    var id: UUID
    var name: String
    var serviceType: ServiceType // plumber, electrician, hvac, etc
    var phone: String
    var rating: Decimal?
    var lastUsed: Date?
    var notes: String?
}
```

### 6.2 Enums and Supporting Types

```swift
enum Priority: String, Codable {
    case low, medium, high, urgent
}

enum PlanStatus: String, Codable {
    case draft, active, completed, archived
}

enum AppointmentStatus: String, Codable {
    case scheduled, completed, cancelled, noShow
}

enum AssignmentStatus: String, Codable {
    case pending, inProgress, completed, overdue
}

enum ServiceType: String, Codable {
    case plumber, electrician, hvac, appliance, roofing, general, landscaping, pest
}

enum EmergencyLevel: String, Codable {
    case routine, urgent, critical, emergency
}
```

---

## 7. Skill Decomposition

Each skill is broken into:
1. **Intent Recognition**: What is the user asking for?
2. **Context Retrieval**: What data do we need?
3. **Decision Logic**: What should we do?
4. **Execution**: Make API calls, update state
5. **Response Generation**: Communicate results

### 7.1 Meal Planning Skill

**Workflow State Machine:**
```
[User Request]
    → Check if new user (no meal history)
        → YES: Run onboarding flow (family size, dietary prefs, budget)
        → NO: Load preferences
    → Check request type:
        → "Plan this week" → GenerateWeeklyPlan
        → "What for tonight?" → SuggestSingleMeal
        → "Shopping list" → GenerateGroceryList
        → "Add to pantry" → UpdatePantryInventory
    → Execute selected workflow
    → Update meal history
    → Return response
```

**Atomic Functions:**
1. `getDietaryPreferences(familyId: UUID) -> DietaryPreferences`
2. `getPantryInventory(familyId: UUID) -> [PantryItem]`
3. `searchRecipes(cuisine: String, maxPrepTime: Int, dietary: [String]) -> [Recipe]`
4. `generateWeeklyMenu(constraints: MenuConstraints) -> [PlannedMeal]`
5. `calculateGroceryList(meals: [PlannedMeal], pantry: [PantryItem]) -> GroceryList`
6. `estimateCost(groceryList: GroceryList) -> Decimal`
7. `saveMealPlan(plan: MealPlan) -> Bool`

**Decision Logic:**
- **Protein rotation**: Track last 7 days, avoid repeating same protein 2 days in a row
- **Cuisine variety**: Aim for 3-4 different cuisines per week
- **Prep time**: Weekday avg 30min, weekend allow 60-90min
- **Leftovers**: Plan intentional leftovers for 1-2 meals/week
- **Favorites**: Include 2-3 family-rated meals per week

**API Integrations:**
- USDA FoodData Central (nutrition info)
- Spoonacular API (recipe search)
- Local grocery store APIs (price estimation)

### 7.2 Healthcare Skill

**Workflow State Machine:**
```
[User Request]
    → Parse intent:
        → "Book appointment" → AppointmentBookingFlow
        → "Symptom check" → SymptomAssessmentFlow
        → "Medication reminder" → SetMedicationAlert
        → "Refill prescription" → PrescriptionRefillFlow
    → Execute workflow with safety checks
    → Update health records
    → Set calendar reminders
    → Return response with disclaimers
```

**Atomic Functions:**
1. `getMemberHealthProfile(memberId: UUID) -> HealthProfile`
2. `assessSymptomSeverity(symptoms: [Symptom]) -> SeverityLevel`
3. `searchProviders(specialty: String, insurance: String, location: CLLocation) -> [Provider]`
4. `checkAppointmentAvailability(providerId: UUID, date: Date) -> [TimeSlot]`
5. `bookAppointment(providerId: UUID, slot: TimeSlot, reason: String) -> Appointment`
6. `setMedicationReminder(medication: Medication, schedule: Schedule) -> Bool`
7. `checkMedicationInteractions(medications: [Medication]) -> [Interaction]`

**Decision Logic - Symptom Triage:**
```swift
func triageSymptom(_ symptom: Symptom) -> TriageAction {
    // Emergency (call 911)
    if symptom.isEmergency { return .call911 }

    // Urgent care (same day)
    if symptom.severity == .high && symptom.duration > hours(4) {
        return .urgentCare
    }

    // Schedule doctor visit (1-3 days)
    if symptom.severity == .medium || symptom.duration > days(3) {
        return .scheduleDoctorVisit
    }

    // Self-care with monitoring
    return .selfCareWithMonitoring
}
```

**Emergency Triggers:**
- Chest pain, difficulty breathing, severe bleeding, loss of consciousness, severe allergic reaction, stroke symptoms

**API Integrations:**
- Zocdoc / HealthGrades (provider search)
- Telemedicine APIs (Teladoc, Amwell)
- Pharmacy APIs (CVS, Walgreens refill)
- Insurance verification APIs

### 7.3 Education Skill

**Workflow State Machine:**
```
[Daily 4pm Check OR User Request]
    → For each student in family:
        → Sync with LMS (Google Classroom/Canvas)
        → Fetch assignments due in next 7 days
        → Fetch recent grades
        → Detect issues:
            → Overdue assignments → URGENT alert
            → Grade drop > 5 points → WARNING alert
            → Upcoming test → STUDY PLAN suggestion
        → Generate student summary
    → Aggregate family education status
    → Send notifications if issues detected
    → Return summary
```

**Atomic Functions:**
1. `syncLMS(studentId: UUID) -> SyncResult`
2. `getAssignments(studentId: UUID, dueWithin: Int) -> [Assignment]`
3. `getGrades(studentId: UUID, subject: String?) -> [GradeEntry]`
4. `detectGradeTrends(history: [GradeEntry]) -> TrendAnalysis`
5. `prioritizeAssignments(assignments: [Assignment]) -> [Assignment]`
6. `generateStudyPlan(exam: Assignment, availableTime: Int) -> StudyPlan`
7. `draftTeacherEmail(context: EmailContext) -> EmailDraft`

**Decision Logic - Alert Thresholds:**
```swift
struct AlertThreshold {
    static let urgentGrade: Double = 70.0
    static let warningGrade: Double = 80.0
    static let gradeDrop: Double = 5.0
    static let overdueAssignments: Int = 2
    static let upcomingTestDays: Int = 3
}
```

**Study Plan Generation:**
- Pomodoro technique (25min study, 5min break)
- Spaced repetition for memorization
- Practice problems for math/science
- Essay outlining for English/history

**API Integrations:**
- Google Classroom API
- Canvas LMS API
- Khan Academy (supplemental learning)
- Quizlet (flashcards)

### 7.4 Elder Care Skill

**Workflow State Machine:**
```
[Scheduled Check-In OR User Request]
    → Load elder profile (medications, health history, preferences)
    → Initiate voice call (Twilio)
    → Conversational flow:
        1. Warm greeting
        2. Wellness question ("How are you feeling today?")
        3. Medication confirmation ("Did you take your morning pills?")
        4. Activity suggestion (music, memory sharing, news discussion)
        5. Positive closing
    → Parse conversation for:
        → Red flags (confusion, pain, falls)
        → Medication compliance
        → Mood assessment
    → Log check-in summary
    → If red flags detected → Alert adult children
    → Schedule next check-in
```

**Atomic Functions:**
1. `initiateCheckInCall(elderId: UUID) -> CallSession`
2. `conductWellnessConversation(session: CallSession) -> ConversationLog`
3. `detectRedFlags(conversation: ConversationLog) -> [RedFlag]`
4. `logMedicationCompliance(elderId: UUID, taken: Bool, timestamp: Date)`
5. `playMusic(preferences: MusicPreferences) -> Bool`
6. `sendFamilyAlert(alert: Alert, recipients: [UUID]) -> Bool`
7. `generateWeeklyReport(elderId: UUID) -> ElderCareReport`

**Red Flag Detection:**
```swift
enum RedFlag {
    case confusion               // Disoriented, memory gaps
    case unusualFatigue         // Extreme tiredness
    case pain(severity: Int)    // Physical discomfort
    case fall                   // Recent fall or injury
    case missedMedication       // Forgot to take meds
    case moodChange             // Depression, anxiety
    case appetiteLoss           // Not eating
    case sleepDisturbance       // Insomnia or excessive sleep
}
```

**Alert Escalation:**
- 1 red flag → Daily notification to family
- 2+ red flags → Immediate phone call
- Emergency keywords ("fell", "chest pain") → Call 911 + notify family

**API Integrations:**
- Twilio (voice calls)
- Spotify/Apple Music (music playback)
- HealthKit (if elder has Apple Watch)

### 7.5 Home Maintenance Skill

**Workflow State Machine:**
```
[User Reports Issue]
    → Assess severity:
        → EMERGENCY (gas, flood, electrical fire) → Emergency Protocol
        → URGENT (no AC in summer, broken heat in winter) → Same-Day Service
        → ROUTINE (filter change, inspection) → Schedule Maintenance
    → Provide safety guidance
    → Search for service providers:
        → Check saved contractors first
        → Search online (Google, Yelp, Angi)
    → Present options with ratings
    → User selects → Contact provider
    → Schedule appointment → Add to calendar
    → Set follow-up reminder
```

**Atomic Functions:**
1. `assessEmergencyLevel(issue: String, details: [String: Any]) -> EmergencyLevel`
2. `getEmergencyProtocol(issueType: EmergencyType) -> SafetyProtocol`
3. `searchContractors(serviceType: ServiceType, location: CLLocation) -> [ServiceProvider]`
4. `callContractor(provider: ServiceProvider, script: String) -> CallResult`
5. `scheduleService(provider: ServiceProvider, date: Date, issue: String) -> Appointment`
6. `getMaintenanceSchedule(homeId: UUID) -> [MaintenanceTask]`
7. `logRepair(homeId: UUID, repair: RepairRecord) -> Bool`

**Emergency Decision Tree:**
```swift
func assessEmergency(_ issue: MaintenanceIssue) -> EmergencyProtocol {
    switch issue.type {
    case .gasLeak:
        return .evacuateAndCall911
    case .majorWaterLeak:
        return .shutMainValve
    case .electricalFire:
        return .call911DoNotUseWater
    case .sewageBackup where issue.severity == .severe:
        return .evacuateAndCallPlumber
    case .noHeatInWinter where outsideTempF < 32:
        return .urgentServiceSameDay
    case .noACInSummer where outsideTempF > 95:
        return .urgentServiceSameDay
    default:
        return .routineService
    }
}
```

**Preventive Maintenance Calendar:**
- Monthly: HVAC filter check, smoke detector test
- Quarterly: Dryer vent cleaning, garage door safety
- Semi-Annual: AC tune-up (spring), furnace check (fall)
- Annual: Chimney inspection, water heater flush

**API Integrations:**
- Google Places API (contractor search)
- Yelp Fusion API (ratings/reviews)
- Angi (formerly Angie's List)
- Twilio (automated contractor calls)

---

## 8. User Onboarding Flow

### 8.1 First Launch Experience

**Goal:** Collect essential information without overwhelming the user.

**Step 1: Welcome Screen**
```
Welcome to OpenClaw! 🏡

I'm your AI family assistant. I'll help you manage:
• Meals and groceries
• Healthcare and medications
• School assignments
• Elder care check-ins
• Home maintenance
• Family coordination

Let's start with a few quick questions.

[Get Started]
```

**Step 2: Family Setup**
```
Who's in your family?

[Add Family Member]

For each member:
- Name
- Role (Adult / Child / Elder)
- Birth Year (optional)

[Continue]
```

**Step 3: Priority Skills**
```
Which features are most important to you?
(Select all that apply)

☐ Meal Planning
☐ Healthcare Management
☐ School & Homework
☐ Elder Care
☐ Home Maintenance
☐ Family Calendar

[Continue]
```

**Step 4: Quick Preferences**

*If Meal Planning selected:*
```
Meal Planning Setup

Family size: [Auto-filled from members]
Dietary preferences:
☐ Vegetarian
☐ Vegan
☐ Gluten-free
☐ Dairy-free
☐ No restrictions

Weekly grocery budget: $[150] (optional)

[Continue]
```

*If Healthcare selected:*
```
Healthcare Setup

Primary care provider: [Add Later]
Insurance: [Add Later]

For each member with health needs:
- Medications: [Add if applicable]
- Allergies: [Add if applicable]

[Continue]
```

*If School selected:*
```
Education Setup

For each child:
- Grade level: [Dropdown 1-12]
- School name: [Text]
- Connect to Google Classroom / Canvas: [Link Account]

[Continue]
```

**Step 5: Permissions**
```
OpenClaw needs these permissions:

✓ Notifications (for reminders & alerts)
✓ Calendar (to sync appointments & events)
✓ Contacts (to call providers & contractors)

[Grant Permissions]
```

**Step 6: AI Model Setup**
```
Downloading AI models...

• Gemma 3n Chat Model (750 MB)
• FunctionGemma Tool Model (450 MB)

This happens once. Models run entirely on your device for privacy.

[Download] [Download on Wi-Fi only]
```

**Step 7: Ready!**
```
You're all set! 🎉

Try asking:
• "Plan dinners for this week"
• "What homework does Emma have?"
• "Check in on Dad"
• "My dishwasher is leaking"

[Start Chatting]
```

### 8.2 Incremental Data Collection

**Philosophy:** Never block the user on missing data. Make intelligent assumptions and refine over time.

**Example:**
```
User: "Plan dinners for this week"

[First time, no dietary data]
Response: "I'll create a balanced week with variety! I'm assuming no dietary restrictions—let me know if anyone is vegetarian, vegan, allergic, etc."

[Generates plan with mixed proteins]

User: "Actually, we're vegetarian"

Response: "Got it! I've updated your preferences. Let me revise that plan with vegetarian meals."

[Regenerates plan, saves preference]
```

---

## 9. API Integrations

### 9.1 Required APIs

| API | Purpose | Authentication | Cost |
|-----|---------|---------------|------|
| **USDA FoodData Central** | Nutrition data, ingredient info | API Key (free) | Free |
| **Spoonacular** | Recipe search, meal planning | API Key | Free tier: 150 req/day |
| **Google Calendar API** | Event sync, reminders | OAuth 2.0 | Free |
| **Google Classroom API** | Assignment/grade sync | OAuth 2.0 | Free |
| **OpenFDA** | Medication information | None | Free |
| **Twilio** | Voice calls (elder care), SMS | API Key | Pay-as-you-go |
| **Zocdoc API** | Doctor search/booking | API Key | Contact for pricing |
| **Google Places API** | Contractor search | API Key | $5/1000 requests |
| **OpenStreetMap** | Address geocoding | None | Free |
| **Weather API** | Weather forecasts | API Key (free tier) | Free tier available |

### 9.2 API Client Architecture

```swift
protocol APIClient {
    associatedtype Response: Decodable
    func execute() async throws -> Response
}

struct APIRequest<T: Decodable>: APIClient {
    typealias Response = T

    let endpoint: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?

    func execute() async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = method.rawValue
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}
```

### 9.3 API Wrappers

#### **SpoonacularAPI**
```swift
class SpoonacularAPI {
    private let apiKey: String
    private let baseURL = "https://api.spoonacular.com"

    func searchRecipes(
        query: String? = nil,
        cuisine: String? = nil,
        diet: String? = nil,
        maxReadyTime: Int? = nil,
        number: Int = 10
    ) async throws -> [Recipe] {
        var components = URLComponents(string: "\(baseURL)/recipes/complexSearch")!
        var queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]

        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        if let maxReadyTime = maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: "\(maxReadyTime)"))
        }
        queryItems.append(URLQueryItem(name: "number", value: "\(number)"))

        components.queryItems = queryItems

        let request = APIRequest<RecipeSearchResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )

        let response = try await request.execute()
        return response.results
    }

    func getRecipeInformation(id: Int) async throws -> RecipeDetail {
        let url = URL(string: "\(baseURL)/recipes/\(id)/information?apiKey=\(apiKey)")!
        let request = APIRequest<RecipeDetail>(
            endpoint: url,
            method: .GET,
            headers: [:],
            body: nil
        )
        return try await request.execute()
    }
}
```

#### **GoogleCalendarAPI**
```swift
class GoogleCalendarAPI {
    private let oauth: OAuthManager

    func listEvents(
        calendarId: String = "primary",
        timeMin: Date,
        timeMax: Date
    ) async throws -> [CalendarEvent] {
        let accessToken = try await oauth.getAccessToken()

        var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: timeMin)),
            URLQueryItem(name: "timeMax", value: ISO8601DateFormatter().string(from: timeMax)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]

        let request = APIRequest<EventListResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: ["Authorization": "Bearer \(accessToken)"],
            body: nil
        )

        let response = try await request.execute()
        return response.items
    }

    func createEvent(_ event: CalendarEvent, calendarId: String = "primary") async throws -> CalendarEvent {
        let accessToken = try await oauth.getAccessToken()
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!

        let eventData = try JSONEncoder().encode(event)

        let request = APIRequest<CalendarEvent>(
            endpoint: url,
            method: .POST,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ],
            body: eventData
        )

        return try await request.execute()
    }
}
```

#### **TwilioAPI**
```swift
class TwilioAPI {
    private let accountSid: String
    private let authToken: String
    private let phoneNumber: String

    func makeCall(to: String, script: String) async throws -> CallResult {
        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSid)/Calls.json")!

        let twimlURL = try await uploadTwiML(script)

        let parameters = [
            "To": to,
            "From": phoneNumber,
            "Url": twimlURL
        ]

        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()

        let request = APIRequest<CallResult>(
            endpoint: url,
            method: .POST,
            headers: [
                "Authorization": "Basic \(credentials)",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: body.data(using: .utf8)
        )

        return try await request.execute()
    }
}
```

---

## 10. Testing Strategy

### 10.1 Testing Pyramid

```
                    ┌──────────────┐
                    │  End-to-End  │  (10%)
                    │  UI Tests    │
                    └──────────────┘
                ┌──────────────────────┐
                │  Integration Tests   │  (30%)
                │  API + Workflow      │
                └──────────────────────┘
          ┌────────────────────────────────┐
          │    Unit Tests (Atomic Funcs)    │  (60%)
          │    Business Logic, Models       │
          └────────────────────────────────┘
```

### 10.2 Unit Tests (60% Coverage Goal)

**What to Test:**
- Atomic function correctness
- Decision engine logic (meal rotation, symptom triage, grade alerts)
- Data model validation
- Enum cases and switches

**Example: Meal Planning Decision Logic**
```swift
class MealPlanningTests: XCTestCase {
    func testProteinRotation() {
        let history = [
            PlannedMeal(date: today(), protein: .chicken),
            PlannedMeal(date: today() - 1, protein: .beef),
            PlannedMeal(date: today() - 2, protein: .chicken)
        ]

        let nextProtein = MealDecisionEngine.selectProtein(history: history)

        XCTAssertNotEqual(nextProtein, .chicken, "Should not repeat protein from today")
        XCTAssert([.vegetarian, .seafood, .pork].contains(nextProtein))
    }

    func testWeekdayPrepTimeConstraint() {
        let constraints = MenuConstraints(
            day: .monday,
            maxPrepTime: 30,
            dietary: []
        )

        let meal = MealGenerator.generateMeal(constraints: constraints)

        XCTAssertLessThanOrEqual(meal.prepTime, 30)
    }

    func testDietaryRestrictionFiltering() {
        let recipes = [
            Recipe(name: "Chicken Curry", dietary: []),
            Recipe(name: "Veggie Stir Fry", dietary: ["vegetarian"]),
            Recipe(name: "Tofu Tacos", dietary: ["vegetarian", "vegan"])
        ]

        let filtered = RecipeFilter.apply(recipes, dietary: ["vegetarian"])

        XCTAssertEqual(filtered.count, 2)
        XCTAssertFalse(filtered.contains { $0.name == "Chicken Curry" })
    }
}
```

**Example: Healthcare Triage Logic**
```swift
class HealthcareTests: XCTestCase {
    func testEmergencySymptomDetection() {
        let symptom = Symptom(
            type: .chestPain,
            severity: .high,
            duration: hours(1)
        )

        let action = SymptomTriageEngine.triage(symptom)

        XCTAssertEqual(action, .call911)
    }

    func testUrgentCareThreshold() {
        let symptom = Symptom(
            type: .fever,
            severity: .medium,
            duration: hours(6),
            temperature: 103.5
        )

        let action = SymptomTriageEngine.triage(symptom)

        XCTAssertEqual(action, .urgentCare)
    }

    func testSelfCareRecommendation() {
        let symptom = Symptom(
            type: .headache,
            severity: .low,
            duration: hours(2)
        )

        let action = SymptomTriageEngine.triage(symptom)

        XCTAssertEqual(action, .selfCareWithMonitoring)
    }
}
```

### 10.3 Integration Tests (30% Coverage)

**What to Test:**
- API client requests/responses
- Workflow state transitions
- Data persistence (Core Data)
- Model inference (Gemma 3n outputs)

**Example: API Integration**
```swift
class SpoonacularAPITests: XCTestCase {
    var api: SpoonacularAPI!

    override func setUp() {
        api = SpoonacularAPI(apiKey: TestConfig.spoonacularKey)
    }

    func testSearchRecipesWithDietaryFilter() async throws {
        let recipes = try await api.searchRecipes(
            cuisine: "italian",
            diet: "vegetarian",
            maxReadyTime: 30,
            number: 5
        )

        XCTAssertGreaterThan(recipes.count, 0)
        XCTAssertLessThanOrEqual(recipes.count, 5)

        for recipe in recipes {
            XCTAssertTrue(recipe.vegetarian)
            XCTAssertLessThanOrEqual(recipe.readyInMinutes, 30)
        }
    }
}
```

**Example: Workflow State Transitions**
```swift
class MealPlanningWorkflowTests: XCTestCase {
    func testNewUserOnboardingFlow() async throws {
        let workflow = MealPlanningWorkflow()
        let family = Family(name: "Test Family", members: [])

        // State 1: New user, no preferences
        let state1 = await workflow.handleRequest("Plan dinners for this week", family: family)
        XCTAssertEqual(state1, .awaitingDietaryPreferences)

        // State 2: User provides preferences
        let state2 = await workflow.handleRequest("We're vegetarian, family of 4", family: family)
        XCTAssertEqual(state2, .generatingPlan)

        // State 3: Plan generated
        let state3 = await workflow.getCurrentState()
        XCTAssertEqual(state3, .planReady)

        // Verify plan was saved
        let savedPlan = try await CoreDataManager.shared.fetchMealPlan(familyId: family.id)
        XCTAssertNotNil(savedPlan)
        XCTAssertEqual(savedPlan?.meals.count, 7)
    }
}
```

### 10.4 Simulated Family Behavior Testing

**Goal:** Test workflows against realistic family scenarios over time.

**Approach:**
1. Create synthetic family profiles representing common US demographics
2. Generate simulated user requests based on daily patterns
3. Execute workflows and validate outcomes
4. Track long-term state consistency (meal rotation, grade trends, medication compliance)

**Synthetic Family Profiles:**
```swift
struct SyntheticFamily {
    static let workingParentsWithTwoKids = Family(
        name: "Smith Family",
        members: [
            FamilyMember(name: "Sarah", role: .adult, age: 38, dietary: []),
            FamilyMember(name: "Mike", role: .adult, age: 40, dietary: []),
            FamilyMember(name: "Emma", role: .child, age: 10, dietary: ["dairy-free"]),
            FamilyMember(name: "Jake", role: .child, age: 7, dietary: [])
        ],
        preferences: FamilyPreferences(
            mealBudget: 180,
            cuisines: ["american", "italian", "mexican"],
            cookingTimeWeekday: 30,
            cookingTimeWeekend: 60
        )
    )

    static let sandwichGenerationFamily = Family(
        name: "Johnson Family",
        members: [
            FamilyMember(name: "Lisa", role: .adult, age: 52, dietary: []),
            FamilyMember(name: "Tom", role: .adult, age: 54, dietary: ["low-carb"]),
            FamilyMember(name: "Mary", role: .elder, age: 78, dietary: [], medications: [
                Medication(name: "Lisinopril", dosage: "10mg", frequency: "once daily"),
                Medication(name: "Metformin", dosage: "500mg", frequency: "twice daily")
            ])
        ]
    )

    static let vegetarianFamilyWithTeens = Family(
        name: "Patel Family",
        members: [
            FamilyMember(name: "Priya", role: .adult, age: 45, dietary: ["vegetarian"]),
            FamilyMember(name: "Raj", role: .adult, age: 47, dietary: ["vegetarian"]),
            FamilyMember(name: "Anika", role: .child, age: 15, dietary: ["vegetarian"]),
            FamilyMember(name: "Dev", role: .child, age: 13, dietary: ["vegetarian"])
        ]
    )
}
```

**Simulated Request Generator:**
```swift
class FamilyBehaviorSimulator {
    func generateDailyRequests(for family: Family, date: Date) -> [UserRequest] {
        var requests: [UserRequest] = []
        let dayOfWeek = Calendar.current.component(.weekday, from: date)

        // Morning requests (7-9am)
        if dayOfWeek >= 2 && dayOfWeek <= 6 { // Weekdays
            requests.append(UserRequest(
                time: date.addingHours(7),
                text: "What homework is due today?",
                expectedSkill: .education
            ))
        }

        // Afternoon requests (3-5pm)
        if family.members.contains(where: { $0.role == .elder }) {
            requests.append(UserRequest(
                time: date.addingHours(16),
                text: "Check in on \(family.members.first(where: { $0.role == .elder })!.name)",
                expectedSkill: .elderCare
            ))
        }

        // Evening requests (5-7pm)
        if dayOfWeek == 1 { // Sunday - weekly planning
            requests.append(UserRequest(
                time: date.addingHours(18),
                text: "Plan meals for this week",
                expectedSkill: .mealPlanning
            ))
        } else {
            // Random dinner decision
            if Bool.random() {
                requests.append(UserRequest(
                    time: date.addingHours(17),
                    text: "What should we have for dinner?",
                    expectedSkill: .mealPlanning
                ))
            }
        }

        return requests
    }

    func simulateWeek(family: Family, startDate: Date) async throws -> SimulationResult {
        var results = SimulationResult()

        for dayOffset in 0..<7 {
            let date = startDate.addingDays(dayOffset)
            let requests = generateDailyRequests(for: family, date: date)

            for request in requests {
                let response = try await SkillOrchestrator.shared.handleRequest(request, family: family)
                results.recordResponse(request: request, response: response)
            }
        }

        return results
    }
}
```

**Validation Checks:**
```swift
struct SimulationValidator {
    func validate(result: SimulationResult) throws {
        // Check meal variety
        let mealPlan = result.generatedMealPlan
        let proteins = mealPlan.meals.map { $0.recipe.primaryProtein }
        let uniqueProteins = Set(proteins)
        XCTAssertGreaterThanOrEqual(uniqueProteins.count, 3, "Insufficient protein variety")

        // Check no consecutive repeats
        for i in 0..<proteins.count-1 {
            XCTAssertNotEqual(proteins[i], proteins[i+1], "Consecutive protein repeat detected")
        }

        // Check grade monitoring triggered
        if result.family.members.contains(where: { $0.schoolInfo != nil }) {
            XCTAssertTrue(result.educationCheckOccurred, "Daily education check should have occurred")
        }

        // Check elder care compliance
        if let elderMember = result.family.members.first(where: { $0.role == .elder }) {
            let checkIns = result.elderCareCheckIns.filter { $0.elderId == elderMember.id }
            XCTAssertEqual(checkIns.count, 7, "Should have 7 daily check-ins for elder")

            let medicationCompliance = checkIns.filter { $0.medicationTaken }.count
            XCTAssertGreaterThan(medicationCompliance, 5, "Low medication compliance detected")
        }
    }
}
```

**Test Execution:**
```swift
class FamilySimulationTests: XCTestCase {
    func testWorkingFamilyWeeklyBehavior() async throws {
        let family = SyntheticFamily.workingParentsWithTwoKids
        let simulator = FamilyBehaviorSimulator()

        let result = try await simulator.simulateWeek(
            family: family,
            startDate: Date()
        )

        try SimulationValidator().validate(result: result)
    }

    func test100WeeksOfMealPlanning() async throws {
        let family = SyntheticFamily.workingParentsWithTwoKids
        var allPlans: [MealPlan] = []

        for week in 0..<100 {
            let startDate = Date().addingDays(week * 7)
            let plan = try await MealPlanningSkill().generateWeeklyPlan(
                family: family,
                startDate: startDate
            )
            allPlans.append(plan)
        }

        // Validate variety over 100 weeks
        let allRecipes = allPlans.flatMap { $0.meals.map { $0.recipe } }
        let uniqueRecipes = Set(allRecipes.map { $0.id })

        XCTAssertGreaterThan(uniqueRecipes.count, 50, "Should have significant recipe variety over 100 weeks")

        // Check for reasonable repetition (favorites should appear 4-8 times)
        let recipeCounts = allRecipes.reduce(into: [:]) { $0[$1.id, default: 0] += 1 }
        let favorites = recipeCounts.filter { $0.value >= 4 && $0.value <= 12 }

        XCTAssertGreaterThan(favorites.count, 10, "Should have 10+ favorite recipes with reasonable repetition")
    }
}
```

### 10.5 End-to-End UI Tests (10% Coverage)

**What to Test:**
- Critical user journeys (onboarding, first meal plan, first appointment booking)
- Chat interface responsiveness
- Model download and initialization

**Example: Onboarding Flow**
```swift
class OnboardingUITests: XCTestCase {
    func testCompleteOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to OpenClaw!"].exists)
        app.buttons["Get Started"].tap()

        // Family setup
        app.buttons["Add Family Member"].tap()
        app.textFields["Name"].tap()
        app.textFields["Name"].typeText("Emma")
        app.buttons["Child"].tap()
        app.buttons["Save"].tap()

        app.buttons["Continue"].tap()

        // Priority skills
        app.buttons["Meal Planning"].tap()
        app.buttons["School & Homework"].tap()
        app.buttons["Continue"].tap()

        // Meal planning preferences
        app.buttons["Vegetarian"].tap()
        app.buttons["Continue"].tap()

        // Permissions
        app.buttons["Grant Permissions"].tap()

        // Wait for model download
        let downloadComplete = app.staticTexts["You're all set!"].waitForExistence(timeout: 60)
        XCTAssertTrue(downloadComplete)

        app.buttons["Start Chatting"].tap()

        // Verify chat interface loaded
        XCTAssertTrue(app.textFields["Message"].exists)
    }
}
```

---

## 11. Privacy & Security

### 11.1 Privacy-First Architecture

**Core Principles:**
1. **On-Device AI**: All model inference happens locally (no data sent to cloud for AI processing)
2. **Encrypted Storage**: Health data, financial info stored in Keychain with AES-256
3. **Minimal API Usage**: Only call external APIs when absolutely necessary
4. **User Control**: Clear data deletion, export capabilities

**Data Categories:**

| Data Type | Storage | Encryption | Cloud Sync |
|-----------|---------|-----------|-----------|
| Family profiles | Core Data | At-rest (iOS) | Optional iCloud |
| Health records | Core Data + Keychain | AES-256 | No |
| Meal plans | Core Data | At-rest (iOS) | Optional iCloud |
| Chat history | Core Data | At-rest (iOS) | No |
| API keys | Keychain | AES-256 | No |
| Model weights | File system | None (public models) | No |

### 11.2 HIPAA Considerations

**OpenClaw is NOT HIPAA-compliant out-of-the-box** (would require Business Associate Agreement with Apple, dedicated encrypted cloud storage). However, we implement best practices:

- No unencrypted health data transmission
- User authentication (Face ID / Touch ID)
- Audit logging for sensitive actions
- Clear medical disclaimers ("not a substitute for professional advice")

### 11.3 API Key Management

**Secure Storage:**
```swift
class KeychainManager {
    func saveAPIKey(_ key: String, for service: String) throws {
        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary) // Delete if exists
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func getAPIKey(for service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.retrievalFailed(status)
        }

        return key
    }
}
```

### 11.4 User Data Deletion

**Complete Removal:**
```swift
class DataDeletionManager {
    func deleteAllUserData() async throws {
        // 1. Delete Core Data
        try await CoreDataManager.shared.deleteAllRecords()

        // 2. Delete Keychain items
        try KeychainManager.shared.deleteAll()

        // 3. Delete file system data
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        try fileManager.removeItem(at: appSupport)

        // 4. Revoke API OAuth tokens
        try await OAuthManager.shared.revokeAllTokens()

        // 5. Clear model cache
        ModelManager.shared.clearCache()

        print("All user data deleted successfully")
    }
}
```

---

## 12. Success Metrics

### 12.1 Product Metrics

**Engagement:**
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Average sessions per day
- Average session duration

**Feature Adoption:**
- % users with ≥1 meal plan created
- % users with LMS connected
- % users with elder care check-ins active
- % users with ≥5 calendar events synced

**Retention:**
- Day 1, 7, 30, 90 retention rates
- Churn rate by cohort

**Quality:**
- Crash-free session rate (target: >99.5%)
- AI response accuracy (manual eval)
- API call success rate (target: >98%)

### 12.2 AI Performance Metrics

**Gemma 3n (Chat Model):**
- Intent classification accuracy (target: >90%)
- Response relevance score (manual eval)
- Average inference latency (target: <500ms on iPhone 15 Pro)

**FunctionGemma (Tool Calls):**
- Tool call accuracy (correct function + params) (target: >95%)
- Parameter extraction precision (target: >92%)
- False positive rate for tool calls (target: <5%)

**Workflow Execution:**
- Workflow completion rate (target: >85%)
- Average turns to completion
- Fallback invocation rate

### 12.3 Business Impact Metrics

**Time Savings:**
- Estimated hours saved per family per week (survey)
- Tasks automated vs. manual (meal planning, appointment booking, etc.)

**User Satisfaction:**
- Net Promoter Score (NPS) (target: >50)
- App Store rating (target: ≥4.5 stars)
- Feature satisfaction scores (Likert scale surveys)

**Cost Efficiency:**
- API cost per active user per month
- Model inference cost (device battery impact)

---

## 13. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Goals:**
- Set up Xcode project with SwiftUI
- Integrate Gemma 3n and FunctionGemma via MLX
- Implement Core Data schema
- Build basic chat interface

**Deliverables:**
- Working chat UI with on-device AI responses
- Data persistence layer functional
- API client architecture

**Team:**
- 2 iOS engineers
- 1 ML engineer

### Phase 2: Core Skills (Weeks 5-10)

**Goals:**
- Implement 3 priority skills: Meal Planning, Healthcare, Education
- Build skill orchestration layer
- Create onboarding flow
- Write unit tests for decision logic

**Deliverables:**
- Functional meal planning (recipe search, grocery lists)
- Healthcare skill (symptom triage, appointment booking)
- Education skill (LMS sync, homework tracking)
- >60% unit test coverage

**Team:**
- 3 iOS engineers
- 1 backend engineer (API wrappers)
- 1 QA engineer

### Phase 3: Extended Skills (Weeks 11-14)

**Goals:**
- Implement Elder Care, Home Maintenance, Family Coordination
- Add calendar sync
- Build notification system
- Create simulated testing environment

**Deliverables:**
- Elder care check-ins with Twilio voice calls
- Home maintenance with emergency protocols
- Family coordination with announcements
- Simulated family behavior tests (100+ scenarios)

**Team:**
- 3 iOS engineers
- 1 QA engineer (test automation)

### Phase 4: Polish & Testing (Weeks 15-18)

**Goals:**
- Comprehensive testing (unit, integration, simulation, UI)
- Performance optimization (model quantization, memory)
- Security audit
- App Store submission prep

**Deliverables:**
- All tests passing (100+ simulated weeks)
- <500ms AI response latency
- Privacy policy, terms of service
- App Store assets (screenshots, description)

**Team:**
- 2 iOS engineers
- 1 QA engineer
- 1 product manager (App Store)

### Phase 5: Beta & Launch (Weeks 19-22)

**Goals:**
- TestFlight beta (100 users)
- Collect feedback, iterate
- App Store launch
- Monitor metrics

**Deliverables:**
- Beta feedback report
- Public App Store release
- Analytics dashboard
- Support documentation

**Team:**
- 2 iOS engineers
- 1 product manager
- 1 support specialist

---

## Appendix A: Technology Stack

**iOS App:**
- Language: Swift 5.10+
- UI: SwiftUI
- Minimum iOS: 17.0 (for SwiftData, MLX support)
- Architecture: MVVM with Combine

**AI Models:**
- Chat: Gemma 3n (3B parameters, INT4 quantized)
- Tool Calls: FunctionGemma (tuned variant)
- Framework: MLX (Apple Silicon optimized)

**Data Persistence:**
- Structured: Core Data / SwiftData
- Secure: Keychain Services
- Files: FileManager (logs, exports)

**Networking:**
- URLSession (async/await)
- OAuth 2.0 (Google APIs)
- REST APIs

**Testing:**
- Unit: XCTest
- UI: XCUITest
- Mocking: Custom protocols
- CI/CD: Xcode Cloud / GitHub Actions

**Third-Party Dependencies:**
- MLX Swift bindings
- Google Sign-In SDK (for Calendar/Classroom OAuth)
- Twilio SDK (voice calls)

---

## Appendix B: Open Questions & Future Enhancements

**Open Questions:**
1. Should we support multi-language (Spanish, Mandarin)?
2. Apple Watch companion app for quick check-ins?
3. Widget support for meal plans, homework, calendar?
4. Siri Shortcuts integration?

**Future Enhancements:**
- Voice input/output (whisper model)
- Photo-based meal logging
- Smart home integration (HomeKit for maintenance)
- Multi-family support (extended family networks)
- Collaborative meal planning (neighborhood swap)
- Recipe cost optimization (dynamic store pricing)

---

**Document Version History:**
- v1.0 (2026-02-02): Initial PRD

**Approval:**
- [ ] Product Lead
- [ ] Engineering Lead
- [ ] Design Lead

---

**End of PRD**
