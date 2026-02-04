# LLM Integration Guide — Gemma 3n + HomeOS Skills

> **Audience:** Coding agents, Claude Code, or any developer integrating on-device LLM into the HomeOS iOS app.
> **Last Updated:** 2025-07-11

---

## 1. Model Selection & Architecture

### Gemma 3n

| Property | Detail |
|----------|--------|
| **What** | Google's on-device model optimized for mobile (1B–4B params) |
| **Why** | Runs on iPhone (A16+/M1+), no cloud needed, privacy-first |
| **Capabilities** | Conversation, classification, JSON generation, summarization |
| **Limitations** | ~2K–4K context window, less nuanced reasoning than cloud models, occasional JSON formatting errors |
| **Integration** | [MediaPipe LLM Inference API](https://developers.google.com/mediapipe/solutions/genai/llm_inference) (Swift) |
| **Model File** | `gemma-3n-E2B-it.task` bundled in app (or downloaded on first launch) |
| **Size** | ~1.5 GB (E2B variant) |
| **Target Latency** | <500ms classification, <2s generation |

### FunctionGemma (Optional Co-Processor)

| Property | Detail |
|----------|--------|
| **What** | A fine-tuned Gemma variant specialized for function/tool calling |
| **When to use** | For structured intent parsing and function parameter extraction **ONLY** |
| **Architecture** | Gemma 3n handles conversation + response generation; FunctionGemma handles intent→function mapping when confidence is low |

**Decision Rule:** Use FunctionGemma **ONLY** if Gemma 3n's keyword-based routing (via `ChatTurnRouter`) proves insufficient in testing. The Swift skills already have robust `canHandle()` keyword matching and a 4-step routing cascade (keywords → scoring → LLM classify → fallback). FunctionGemma is a fallback for ambiguous intents that slip through all four layers.

---

## 2. Integration Architecture

### Two-Layer Approach

```
User Message
    ↓
┌──────────────────────────────────────────────────┐
│ Layer 1: Intent Classification                    │
│                                                    │
│  Step 1: Keyword match (ChatTurnRouter)           │
│  Step 2: Skill scoring (canHandle() > 0.3)        │
│  Step 3: LLM classify (Gemma 3n)                  │
│  Step 4: FunctionGemma (only if Step 3 fails)     │
└──────────────────────────────────────────────────┘
    ↓
ChatTurnRouter dispatches to correct skill
    ↓
┌──────────────────────────────────────────────────┐
│ Layer 2: Skill Execution                          │
│                                                    │
│  Gemma 3n for: generate / classify / summarize    │
│  Pure logic for: data lookups, schedules, rules   │
└──────────────────────────────────────────────────┘
    ↓
SkillResult → Response / ApprovalRequest / Handoff / Error
```

### How It Maps to Existing Code

The existing `ChatTurnRouter` already implements the 4-step cascade:

```swift
// Step 1: Keyword match — fast, deterministic
let keywordMatch = matchByKeywords(intent: context.intent)
if let skill = keywordMatch, skill.canHandle(intent: context.intent) > 0.5 {
    return try await skill.execute(context: context)
}

// Step 2: Score all skills, pick best
let scored = skills.map { ($0, $0.canHandle(intent: context.intent)) }
    .sorted { $0.1 > $1.1 }
if let best = scored.first, best.1 > 0.3 {
    return try await best.0.execute(context: context)
}

// Step 3: LLM classification via LLMBridge
let classified = try await context.llm.classify(input: ..., categories: ...)

// Step 4: Fallback message
return .response("I'm not sure how to help with that...")
```

The `LLMBridge` protocol is already defined. Your job is to provide a **real implementation** backed by MediaPipe + Gemma 3n.

### LLMBridge Protocol (Existing)

```swift
public protocol LLMBridge: Sendable {
    func generate(prompt: String) async throws -> String
    func generateJSON(prompt: String, schema: JSONSchema) async throws -> String
    func classify(input: String, categories: [ClassificationCategory]) async throws -> String
    func summarize(text: String, maxWords: Int) async throws -> String
}
```

### GemmaLLMBridge Implementation (MediaPipe)

```swift
import MediaPipeTasksGenAI
import Foundation

/// Production LLM bridge using Gemma 3n via MediaPipe LLM Inference API.
/// This replaces MediaPipeGemmaBridge's closure-based approach with direct MediaPipe integration.
public final class GemmaLLMBridge: LLMBridge, @unchecked Sendable {
    
    private let inference: LlmInference
    private let inferenceQueue = DispatchQueue(label: "com.homeos.gemma", qos: .userInitiated)
    
    /// Initialize with bundled model.
    /// Call this ONCE at app launch and keep the instance alive.
    public init() throws {
        guard let modelPath = Bundle.main.path(forResource: "gemma-3n-E2B-it", ofType: "task") else {
            throw GemmaError.modelNotFound
        }
        
        var options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = 2048
        options.topK = 40
        options.temperature = 0.7
        options.randomSeed = 0  // Deterministic for testing; remove in prod
        
        self.inference = try LlmInference(options: options)
    }
    
    /// Initialize with a custom model path (for testing or downloaded models).
    public init(modelPath: String, maxTokens: Int = 2048, temperature: Float = 0.7) throws {
        var options = LlmInference.Options(modelPath: modelPath)
        options.maxTokens = maxTokens
        options.temperature = temperature
        options.topK = 40
        
        self.inference = try LlmInference(options: options)
    }
    
    // MARK: - LLMBridge Conformance
    
    public func generate(prompt: String) async throws -> String {
        let fullPrompt = """
        \(SystemPrompts.base)
        
        User: \(prompt)
        Assistant:
        """
        return try await runInference(fullPrompt)
    }
    
    public func generateJSON(prompt: String, schema: JSONSchema) async throws -> String {
        let fullPrompt = """
        \(prompt)
        
        IMPORTANT: Respond with ONLY valid JSON matching this schema. No explanation, no markdown fences, no text before or after the JSON.
        
        Schema:
        \(schema.schemaString)
        
        JSON:
        """
        
        let response = try await runInference(fullPrompt)
        return extractJSON(from: response)
    }
    
    public func classify(input: String, categories: [ClassificationCategory]) async throws -> String {
        let categoryList = categories.map { cat in
            var entry = "- \(cat.name): \(cat.description)"
            if !cat.examples.isEmpty {
                entry += " (e.g., \(cat.examples.prefix(3).joined(separator: ", ")))"
            }
            return entry
        }.joined(separator: "\n")
        
        let prompt = """
        Classify the following user message into exactly ONE category.
        
        User message: "\(input)"
        
        Categories:
        \(categoryList)
        
        Reply with ONLY the category name. Nothing else.
        """
        
        let response = try await runInference(prompt)
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ".", with: "")
        
        // Exact match
        if let match = categories.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return match.name
        }
        // Contains match
        if let match = categories.first(where: { trimmed.lowercased().contains($0.name.lowercased()) }) {
            return match.name
        }
        // Default to first category
        return categories.first?.name ?? trimmed
    }
    
    public func summarize(text: String, maxWords: Int) async throws -> String {
        let prompt = """
        Summarize the following text in \(maxWords) words or fewer. Be concise. Capture key points only.
        
        Text:
        \(text)
        
        Summary:
        """
        return try await runInference(prompt)
    }
    
    // MARK: - Private
    
    private func runInference(_ prompt: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: GemmaError.deallocated)
                    return
                }
                do {
                    let result = try self.inference.generateResponse(inputText: prompt)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: GemmaError.inferenceError(error))
                }
            }
        }
    }
    
    /// Extract JSON from a response that may contain extra text.
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip markdown code fences if present
        let stripped = trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object
        if let start = stripped.firstIndex(of: "{"),
           let end = stripped.lastIndex(of: "}") {
            return String(stripped[start...end])
        }
        // Find JSON array
        if let start = stripped.firstIndex(of: "["),
           let end = stripped.lastIndex(of: "]") {
            return String(stripped[start...end])
        }
        return stripped
    }
}

// MARK: - Errors

public enum GemmaError: Error, LocalizedError {
    case modelNotFound
    case deallocated
    case inferenceError(Error)
    case jsonParsingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound: return "Gemma model file not found in app bundle"
        case .deallocated: return "GemmaLLMBridge was deallocated during inference"
        case .inferenceError(let e): return "Gemma inference failed: \(e.localizedDescription)"
        case .jsonParsingFailed(let raw): return "Failed to parse JSON from LLM: \(raw.prefix(100))"
        }
    }
}
```

### App Initialization

```swift
// In your AppDelegate or App struct — load ONCE, share everywhere

@MainActor
final class HomeOSApp {
    static let shared = HomeOSApp()
    
    let llmBridge: LLMBridge
    let router: ChatTurnRouter
    
    private init() {
        // Load LLM — this takes 2-5 seconds, do it at launch
        do {
            self.llmBridge = try GemmaLLMBridge()
        } catch {
            // Fall back to mock for development/testing
            print("⚠️ Gemma model not available, using mock: \(error)")
            self.llmBridge = MockLLMBridge()
        }
        
        // Register all skills
        let skills: [any SkillProtocol] = [
            MealPlanningSkill(),
            // HealthcareSkill(),
            // EducationSkill(),
            // ... all other skills
        ]
        
        self.router = ChatTurnRouter(skills: skills)
    }
    
    func handleMessage(_ text: String, family: Family, storage: StorageProvider) async -> SkillResult {
        let intent = UserIntent(rawMessage: text)
        let context = SkillContext(
            family: family,
            storage: storage,
            llm: llmBridge,
            intent: intent
        )
        
        do {
            return try await router.handle(context: context)
        } catch {
            return .error("Something went wrong: \(error.localizedDescription)")
        }
    }
}
```

### Swift Package Dependencies

Add to your `Package.swift` or Xcode project:

```swift
// MediaPipe LLM Inference — via CocoaPods or SPM
// CocoaPods:
// pod 'MediaPipeTasksGenAI', '~> 0.10.21'

// SPM (when available):
// .package(url: "https://github.com/google/mediapipe.git", from: "0.10.21")
```

---

## 3. Prompt Engineering for Small Models

### Key Principles

1. **Be explicit, not implicit** — Small models don't infer well. Say exactly what you want.
2. **Structured output** — Always request JSON when you need structured data.
3. **Few-shot examples IN the prompt** — Show the model what good output looks like.
4. **Keep prompts under 500 tokens** — Faster inference, better results.
5. **Classification > generation** — "Pick from this list" beats "come up with something" for reliability.
6. **Repeat critical constraints** — Put safety rules (allergies, medical disclaimers) in CAPS.
7. **One task per prompt** — Don't ask for classification AND generation in one call.

### System Prompt Template

```swift
struct SystemPrompts {
    
    static let base = """
    You are HomeOS, a family household assistant. You help with daily family life — meals, \
    health, school, activities, home maintenance, and more.
    
    RULES:
    1. Be warm, concise, and practical. Families are busy.
    2. For health topics: ALWAYS add "This is not medical advice. Consult a doctor for \
       serious concerns." NEVER diagnose conditions.
    3. For high-risk actions (spending money, unlocking doors, contacting emergency services): \
       ALWAYS ask for explicit user approval before proceeding.
    4. Respect quiet hours and family preferences stored in context.
    5. When unsure what the user wants, ask ONE clarifying question.
    6. Keep responses under 200 words unless the user asks for detail.
    7. For allergies: treat as CRITICAL safety constraints. NEVER suggest foods containing \
       known allergens.
    8. Use emoji sparingly for section headers (🍽, ⏱️, 🛒) but don't overdo it.
    9. When listing options, provide 3 choices max unless asked for more.
    10. If a request is outside your capabilities, say so honestly.
    """
    
    static let intentClassification = """
    You are a message classifier for a family assistant app. Your job is to determine which \
    skill should handle a user's message.
    
    Reply with ONLY the skill name. No explanation. No punctuation. Just the skill name.
    """
    
    static let jsonExtraction = """
    You extract structured data from natural language. Output ONLY valid JSON matching the \
    provided schema. No markdown fences. No explanation. Just the JSON object.
    """
}
```

### Few-Shot Examples for Intent Classification

These examples should be injected into the classification prompt when the keyword-based router (Steps 1–2) fails and we fall back to LLM classification (Step 3).

```swift
struct IntentExamples {
    
    static let fewShot = """
    Examples:
    
    User: "What should we have for dinner?"
    Skill: meal-planning
    
    User: "Can you make a meal plan for the week?"
    Skill: meal-planning
    
    User: "We need groceries"
    Skill: meal-planning
    
    User: "What's a good recipe for salmon?"
    Skill: meal-planning
    
    User: "Book a table at an Italian place for Saturday"
    Skill: restaurant-reservation
    
    User: "Find a restaurant near us for date night"
    Skill: restaurant-reservation
    
    User: "My kid has a fever of 101"
    Skill: healthcare
    
    User: "When is Mom's next doctor appointment?"
    Skill: healthcare
    
    User: "Remind me to refill the Advil prescription"
    Skill: healthcare
    
    User: "Is it safe to give Tylenol with ibuprofen?"
    Skill: healthcare
    
    User: "How's Grandma doing today?"
    Skill: elder-care
    
    User: "Can you check in on my dad?"
    Skill: elder-care
    
    User: "Set up the weekly call with Mom"
    Skill: elder-care
    
    User: "Does Jake have homework tonight?"
    Skill: education
    
    User: "What's Emma's grade in math?"
    Skill: education
    
    User: "Find a tutor for science"
    Skill: education
    
    User: "Help me study for the history test"
    Skill: education
    
    User: "The dishwasher is leaking"
    Skill: home-maintenance
    
    User: "Find a plumber"
    Skill: home-maintenance
    
    User: "When should I change the HVAC filter?"
    Skill: home-maintenance
    
    User: "I smell gas in the kitchen"
    Skill: home-maintenance
    
    User: "I need a ride to work tomorrow"
    Skill: transportation
    
    User: "What's the traffic like right now?"
    Skill: transportation
    
    User: "Order an Uber to the airport"
    Skill: transportation
    
    User: "What should we do this weekend?"
    Skill: family-bonding
    
    User: "Plan a date night for Friday"
    Skill: family-bonding
    
    User: "The kids are bored, any activity ideas?"
    Skill: family-bonding
    
    User: "I'm feeling overwhelmed with everything"
    Skill: mental-load
    
    User: "Give me my morning briefing"
    Skill: mental-load
    
    User: "What's on the agenda today?"
    Skill: mental-load
    
    User: "I need to organize all our tasks"
    Skill: mental-load
    
    User: "Have I been drinking enough water today?"
    Skill: wellness
    
    User: "How many steps have I walked?"
    Skill: wellness
    
    User: "I haven't been sleeping well"
    Skill: wellness
    
    User: "I want to start meditating daily"
    Skill: habits
    
    User: "How's my reading streak going?"
    Skill: habits
    
    User: "I keep forgetting to exercise"
    Skill: habits
    
    User: "Tell the family dinner is at 7"
    Skill: family-comms
    
    User: "Assign chores for the week"
    Skill: family-comms
    
    User: "We need a babysitter for Saturday night"
    Skill: hire-helper
    
    User: "Find a house cleaner"
    Skill: hire-helper
    
    User: "I want to sell our old couch"
    Skill: marketplace-sell
    
    User: "List the kids' outgrown clothes on Facebook Marketplace"
    Skill: marketplace-sell
    
    User: "Call the dentist office"
    Skill: telephony
    
    User: "I found this interesting article about sourdough"
    Skill: note-to-actions
    
    User: "Turn this video into a weekend project"
    Skill: note-to-actions
    
    User: "We need more interesting experiences as a family"
    Skill: psy-rich
    
    User: "I feel like we're in a rut"
    Skill: psy-rich
    
    User: "Set a reminder for 3pm"
    Skill: tools
    
    User: "What's the weather tomorrow?"
    Skill: tools
    
    User: "Add a note about the school fundraiser"
    Skill: tools
    """
}
```

---

## 4. Skill Execution Patterns

Each skill uses the `LLMBridge` differently (or not at all). Here are the four patterns:

### Pattern A: Direct Response (No LLM)

For deterministic lookups where LLM adds no value.

```swift
/// Pattern A: Pure data retrieval — no LLM needed
func executeDirectLookup(context: SkillContext) async throws -> SkillResult {
    // Example: "What medications is Mom taking?"
    let healthData = try await context.storage.read(
        path: "data/health/medications.json",
        type: [Medication].self
    )
    
    let member = context.family.members.first { 
        context.intent.rawMessage.lowercased().contains($0.name.lowercased()) 
    }
    
    let meds = healthData?.filter { $0.memberId == member?.id } ?? []
    
    if meds.isEmpty {
        return .response("No medications on file for \(member?.name ?? "that person").")
    }
    
    let list = meds.map { "• \($0.name) — \($0.dosage), \($0.frequency)" }
        .joined(separator: "\n")
    
    return .response("💊 Medications for \(member?.name ?? ""):\n\n\(list)")
}
```

**Use for:** Medication schedule lookup, calendar checks, scam checklists, preference retrieval, habit streak counts.

### Pattern B: LLM Classification

For decisions that require judgment but have a finite set of outcomes.

```swift
/// Pattern B: LLM classifies into a known set of outcomes
func classifySymptomUrgency(context: SkillContext) async throws -> SkillResult {
    let categories = [
        ClassificationCategory(
            name: "emergency",
            description: "Life-threatening: chest pain, severe bleeding, breathing difficulty, loss of consciousness",
            examples: ["chest pain", "can't breathe", "severe allergic reaction"]
        ),
        ClassificationCategory(
            name: "urgent",
            description: "Needs medical attention within 24h: high fever, persistent vomiting, deep cuts",
            examples: ["fever over 103", "won't stop vomiting", "deep cut"]
        ),
        ClassificationCategory(
            name: "monitor",
            description: "Watch and wait: mild fever, cold symptoms, minor aches",
            examples: ["runny nose", "slight headache", "mild fever"]
        ),
        ClassificationCategory(
            name: "informational",
            description: "General health question, not about current symptoms",
            examples: ["how much sleep do kids need", "is this food healthy"]
        ),
    ]
    
    let severity = try await context.llm.classify(
        input: context.intent.rawMessage,
        categories: categories
    )
    
    switch severity {
    case "emergency":
        return .response("""
        🚨 This sounds like it could be a medical emergency.
        
        **Call 911 or go to the nearest ER immediately.**
        
        While waiting:
        • Stay calm
        • Don't move the person unnecessarily
        • Keep airways clear
        
        ⚠️ I am not a doctor. This is not medical advice.
        """)
    case "urgent":
        return .response("""
        ⚠️ This may need medical attention soon.
        
        I'd recommend calling your doctor's office or visiting urgent care today.
        
        Would you like me to:
        • Look up your doctor's number?
        • Find the nearest urgent care?
        
        ⚠️ This is not medical advice. When in doubt, seek professional care.
        """)
    case "monitor":
        // Generate monitoring advice via LLM (Pattern C)
        return try await generateMonitoringAdvice(context: context)
    default:
        return try await context.llm.generate(prompt: context.intent.rawMessage)
            .map { .response($0 + "\n\n⚠️ This is not medical advice.") }
    }
}
```

**Use for:** Symptom triage severity, home maintenance urgency, transportation mode selection, expense approval level.

### Pattern C: LLM Generation

For open-ended responses that need creativity or personalization.

```swift
/// Pattern C: LLM generates a natural language response
func suggestDinner(context: SkillContext) async throws -> SkillResult {
    // Gather context from storage and family
    let dietary = context.family.members
        .compactMap { $0.preferences?.dietary }
        .flatMap { $0 }
    let allergies = context.family.members
        .compactMap { $0.allergies }
        .flatMap { $0 }
    let recentMeals = try? await context.storage.read(
        path: "data/meal_history.json",
        type: [MealRecord].self
    )
    
    let prompt = """
    Suggest ONE dinner for tonight.
    Family size: \(context.family.members.count)
    Dietary restrictions: \(dietary.isEmpty ? "none" : dietary.joined(separator: ", "))
    Allergies (MUST AVOID): \(allergies.isEmpty ? "none" : allergies.joined(separator: ", "))
    Recent meals (avoid repeats): \(recentMeals?.suffix(3).map(\.name).joined(separator: ", ") ?? "none")
    Weeknight = quick (under 30 min preferred).
    
    Respond with JSON:
    """
    
    let schema = JSONSchema.object(properties: [
        "name": "string",
        "cuisine": "string",
        "prepMinutes": "integer",
        "description": "string",
    ])
    
    let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
    // Parse JSON and format into user-friendly response...
    return .response(formatDinnerSuggestion(json))
}
```

**Use for:** Meal suggestions, activity recommendations, morning briefings, conversation responses, personalized advice.

### Pattern D: LLM JSON Extraction

For parsing unstructured user input into structured data.

```swift
/// Pattern D: LLM extracts structured data from free-form text
func extractReservationDetails(context: SkillContext) async throws -> SkillResult {
    let prompt = """
    Extract restaurant reservation details from this message.
    If a field is not mentioned, use null.
    
    Message: "\(context.intent.rawMessage)"
    
    Extract:
    """
    
    let schema = JSONSchema("""
    {
        "type": "object",
        "properties": {
            "cuisine": { "type": ["string", "null"] },
            "date": { "type": ["string", "null"], "description": "ISO 8601 date" },
            "time": { "type": ["string", "null"], "description": "HH:MM format" },
            "partySize": { "type": ["integer", "null"] },
            "location": { "type": ["string", "null"] },
            "specialRequests": { "type": ["string", "null"] }
        },
        "required": ["cuisine", "date", "time", "partySize", "location", "specialRequests"],
        "additionalProperties": false
    }
    """)
    
    let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
    
    guard let data = json.data(using: .utf8),
          let details = try? JSONDecoder().decode(ReservationDetails.self, from: data) else {
        return .response("I'd love to help book a restaurant! Could you tell me:\n• Cuisine preference?\n• Date and time?\n• How many people?")
    }
    
    // Check what's missing and ask follow-up
    var missing: [String] = []
    if details.date == nil { missing.append("date") }
    if details.time == nil { missing.append("time") }
    if details.partySize == nil { missing.append("party size") }
    
    if !missing.isEmpty {
        return .response("Got it! I just need a few more details:\n" +
            missing.map { "• \($0.capitalized)?" }.joined(separator: "\n"))
    }
    
    // All details present — proceed with booking
    return .needsApproval(ApprovalRequest(
        description: "Book a \(details.cuisine ?? "") restaurant for \(details.partySize ?? 0) on \(details.date ?? "")",
        details: ["Cuisine: \(details.cuisine ?? "any")", "Party: \(details.partySize ?? 0)"],
        riskLevel: .medium,
        onDecision: { approved in
            approved ? .response("✅ Reservation booked!") : .response("No problem, cancelled.")
        }
    ))
}
```

**Use for:** Parsing user input into structured fields, extracting entities (dates, names, amounts), generating structured plans.

---

## 5. Context Management

### What to Inject into Context

Every LLM call should include relevant context. Here's what to inject and when:

| Context Data | Source | When to Include |
|-------------|--------|----------------|
| Family member profiles | `family.json` via `SkillContext.family` | Always (names, ages, roles) |
| Dietary restrictions & allergies | `Family.members[].preferences`, `Family.members[].allergies` | Meal, restaurant, wellness skills |
| Time of day, day of week | `SkillContext.currentDate`, `SkillContext.timeZone` | Always (affects tone, suggestions) |
| Recent conversation (last 5 turns) | Conversation storage | Chat and ambiguous intents |
| Active reminders/tasks | `data/reminders.json` | Tools, mental-load skills |
| Calendar events (next 48h) | `SkillContext.calendar` | Scheduling, briefings, conflicts |
| Health data | `data/health/` directory | Healthcare, wellness, habits |
| Meal history | `data/meal_history.json` | Meal-planning (avoid repeats) |
| Habit streaks | `data/habits/` directory | Habits, wellness skills |

### Context Injection Pattern

```swift
func buildContextualPrompt(
    basePrompt: String,
    context: SkillContext,
    includeHistory: Bool = false,
    includeCalendar: Bool = false
) -> String {
    var sections: [String] = []
    
    // Always include time context
    let formatter = DateFormatter()
    formatter.timeZone = context.timeZone
    formatter.dateFormat = "EEEE, MMM d, yyyy 'at' h:mm a"
    sections.append("Current time: \(formatter.string(from: context.currentDate))")
    
    // Family context (compact)
    let members = context.family.members.map { m in
        "\(m.name) (\(m.role), age \(m.age))"
    }.joined(separator: "; ")
    sections.append("Family: \(members)")
    
    // Calendar (if relevant)
    if includeCalendar && !context.calendar.isEmpty {
        let upcoming = context.calendar.prefix(5).map { e in
            "\(e.title) — \(e.startTime)"
        }.joined(separator: "; ")
        sections.append("Upcoming events: \(upcoming)")
    }
    
    // Build final prompt
    return """
    Context:
    \(sections.joined(separator: "\n"))
    
    \(basePrompt)
    """
}
```

### Context Window Budget

Gemma 3n E2B supports ~2048 tokens. Budget them carefully:

```
┌─────────────────────────────────┬────────┐
│ Component                        │ Tokens │
├─────────────────────────────────┼────────┤
│ System prompt                    │ ~200   │
│ Few-shot examples (if classify)  │ ~300   │
│ Family context (compact)         │ ~150   │
│ Calendar / health data           │ ~150   │
│ Conversation history (5 turns)   │ ~400   │
│ User message + skill prompt      │ ~300   │
│ ─── Output budget ───            │ ~500   │
├─────────────────────────────────┼────────┤
│ TOTAL                            │ ~2000  │
└─────────────────────────────────┴────────┘
```

**Rules:**
- Never include ALL few-shot examples — pick the 5 most relevant to the current skill
- Truncate conversation history to last 3 turns if prompt is getting long
- For JSON generation, the schema itself costs tokens — keep schemas minimal
- If total prompt exceeds 1500 tokens, drop conversation history first

---

## 6. Proactive Skill Activation

### Scheduled Skills

Skills that run on a schedule WITHOUT user asking:

| Skill | Schedule | What It Does | iOS Mechanism |
|-------|----------|-------------|---------------|
| mental-load | 7:00 AM daily | Morning briefing (calendar, tasks, weather) | `BGAppRefreshTask` + local notification |
| mental-load | 8:00 PM daily | Evening wind-down (tomorrow prep, reflection) | `BGAppRefreshTask` + local notification |
| wellness | Every 2 hours, 8AM–8PM | Hydration/step nudges | `BGAppRefreshTask` + HealthKit background delivery |
| healthcare | Per medication schedule | Medication reminders | `UNNotificationRequest` with exact time |
| school | 7:30 AM school days | Homework/schedule check | `BGAppRefreshTask` (Mon–Fri only) |
| habits | Per habit schedule | Check-in nudges | `UNNotificationRequest` per habit |
| elder-care | Per configured schedule | Check-in calls/messages | `BGProcessingTask` (may need Twilio) |

### Event-Driven Skills

Skills triggered by system events, not user messages:

| Trigger | Skill | Action | iOS Mechanism |
|---------|-------|--------|---------------|
| Calendar event in 2h | tools | Reminder notification | `EKEventStore` observer + local notification |
| HealthKit step count low at 6PM | wellness | Movement nudge | `HKObserverQuery` background delivery |
| School grade posted (if API) | education | Alert if below threshold | Background fetch + API polling |
| Medication refill date −7 days | healthcare | Refill reminder | Calendar computation + notification |
| Location arrives home | family-comms | "Welcome home" context switch | `CLLocationManager` region monitoring |

### Implementation

```swift
import BackgroundTasks
import UserNotifications

/// Manages all proactive skill scheduling for HomeOS.
final class SkillScheduler {
    
    static let shared = SkillScheduler()
    
    // MARK: - Background Task Registration
    
    /// Call this in application(_:didFinishLaunchingWithOptions:)
    func registerBackgroundTasks() {
        // Morning briefing
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.homeos.morningBrief",
            using: nil
        ) { task in
            self.handleMorningBrief(task: task as! BGAppRefreshTask)
        }
        
        // Wellness check
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.homeos.wellnessCheck",
            using: nil
        ) { task in
            self.handleWellnessCheck(task: task as! BGAppRefreshTask)
        }
        
        // Evening wind-down
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.homeos.eveningWindDown",
            using: nil
        ) { task in
            self.handleEveningWindDown(task: task as! BGAppRefreshTask)
        }
        
        // Schedule the first round
        scheduleMorningBrief()
        scheduleWellnessChecks()
        scheduleEveningWindDown()
    }
    
    // MARK: - Scheduling
    
    func scheduleMorningBrief() {
        let request = BGAppRefreshTaskRequest(identifier: "com.homeos.morningBrief")
        // Schedule for 7:00 AM tomorrow
        request.earliestBeginDate = nextOccurrence(hour: 7, minute: 0)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func scheduleWellnessChecks() {
        let request = BGAppRefreshTaskRequest(identifier: "com.homeos.wellnessCheck")
        // Every 2 hours during waking hours
        request.earliestBeginDate = Date().addingTimeInterval(2 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func scheduleEveningWindDown() {
        let request = BGAppRefreshTaskRequest(identifier: "com.homeos.eveningWindDown")
        request.earliestBeginDate = nextOccurrence(hour: 20, minute: 0)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    // MARK: - Task Handlers
    
    private func handleMorningBrief(task: BGAppRefreshTask) {
        // Re-schedule for tomorrow
        scheduleMorningBrief()
        
        let operation = Task {
            let briefing = try await generateMorningBriefing()
            await sendLocalNotification(
                title: "☀️ Good Morning!",
                body: briefing,
                categoryIdentifier: "MORNING_BRIEF"
            )
        }
        
        task.expirationHandler = { operation.cancel() }
        
        Task {
            _ = await operation.result
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleWellnessCheck(task: BGAppRefreshTask) {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Only during waking hours (8AM–8PM)
        guard hour >= 8 && hour <= 20 else {
            task.setTaskCompleted(success: true)
            return
        }
        
        // Re-schedule
        scheduleWellnessChecks()
        
        Task {
            // Check HealthKit data
            let steps = await getStepCount()
            let waterIntake = await getWaterIntake()
            
            if steps < 3000 && hour >= 14 {
                await sendLocalNotification(
                    title: "🚶 Time to Move!",
                    body: "You've walked \(steps) steps today. A quick 10-minute walk could help!",
                    categoryIdentifier: "WELLNESS_NUDGE"
                )
            }
            
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleEveningWindDown(task: BGAppRefreshTask) {
        scheduleEveningWindDown()
        
        Task {
            let summary = try await generateEveningSummary()
            await sendLocalNotification(
                title: "🌙 Evening Wind-Down",
                body: summary,
                categoryIdentifier: "EVENING_SUMMARY"
            )
            task.setTaskCompleted(success: true)
        }
    }
    
    // MARK: - Medication Reminders (Exact Time)
    
    /// Schedule exact-time medication reminders using UNNotificationRequest
    func scheduleMedicationReminders(medications: [Medication]) {
        let center = UNUserNotificationCenter.current()
        
        for med in medications {
            for time in med.times {
                let content = UNMutableNotificationContent()
                content.title = "💊 Medication Reminder"
                content.body = "\(med.name) — \(med.dosage)"
                content.categoryIdentifier = "MEDICATION"
                content.sound = .default
                
                var dateComponents = DateComponents()
                dateComponents.hour = time.hour
                dateComponents.minute = time.minute
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "med-\(med.id)-\(time.hour)\(time.minute)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func nextOccurrence(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        
        var date = calendar.date(from: components)!
        if date <= Date() {
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return date
    }
    
    private func sendLocalNotification(title: String, body: String, categoryIdentifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // Stub methods — implement with actual data sources
    private func generateMorningBriefing() async throws -> String { "" }
    private func generateEveningSummary() async throws -> String { "" }
    private func getStepCount() async -> Int { 0 }
    private func getWaterIntake() async -> Double { 0 }
}
```

### Info.plist Requirements

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.homeos.morningBrief</string>
    <string>com.homeos.wellnessCheck</string>
    <string>com.homeos.eveningWindDown</string>
</array>
```

---

## 7. Cross-Skill Data Flow

### Shared Data Model

All skills share data through `StorageProvider`. Here's the data map:

```
data/
├── family.json                 ← Read by ALL skills
├── calendar.json               ← tools, school, healthcare, restaurant-reservation
├── reminders.json              ← tools, mental-load
├── conversation_history.json   ← ChatTurnRouter (for context)
├── current_meal_plan.json      ← meal-planning (write), wellness (read)
├── meal_history.json           ← meal-planning (read/write), wellness (read)
├── health/
│   ├── medications.json        ← healthcare (read/write), elder-care (read)
│   ├── symptoms_log.json       ← healthcare (write), wellness (read)
│   └── vitals.json             ← healthcare, wellness, habits
├── habits/
│   ├── active_habits.json      ← habits (read/write), wellness (read)
│   └── streaks.json            ← habits (read/write), mental-load (read for briefing)
├── school/
│   ├── schedule.json           ← school, education (read/write)
│   └── grades.json             ← education (read/write), mental-load (read)
├── home/
│   ├── maintenance_log.json    ← home-maintenance (read/write)
│   └── appliances.json         ← home-maintenance (read)
└── preferences/
    ├── quiet_hours.json        ← ALL skills (respect quiet hours)
    └── notification_prefs.json ← SkillScheduler (check before notifying)
```

### Data Access via StorageProvider

```swift
// StorageProvider protocol (already defined in HomeOSCore)
public protocol StorageProvider: Sendable {
    func read<T: Codable>(path: String, type: T.Type) async throws -> T?
    func write<T: Codable>(path: String, value: T) async throws
    func exists(path: String) async throws -> Bool
    func delete(path: String) async throws
}

// Usage in skills:
let meds = try await context.storage.read(
    path: "data/health/medications.json",
    type: [Medication].self
)
```

### Handoff Protocol

When one skill needs another skill to continue processing:

```swift
// Skill returns a handoff request
return .handoff(HandoffRequest(
    targetSkill: "healthcare",
    reason: "Meal plan detected potential allergen conflict with medication",
    context: [
        "allergen": "grapefruit",
        "medication": "atorvastatin",
        "originalRequest": context.intent.rawMessage
    ]
))

// ChatTurnRouter handles the handoff:
public func handle(context: SkillContext) async throws -> SkillResult {
    let result = try await routeToSkill(context: context)
    
    switch result {
    case .handoff(let request):
        // Find the target skill
        guard let targetSkill = skills.first(where: { $0.name == request.targetSkill }) else {
            return .error("Handoff target '\(request.targetSkill)' not found")
        }
        
        // Build new context with handoff info
        let handoffMessage = request.context["originalRequest"] ?? context.intent.rawMessage
        let newIntent = UserIntent(
            rawMessage: handoffMessage,
            entities: context.intent.entities,
            urgency: context.intent.urgency
        )
        let newContext = SkillContext(
            family: context.family,
            calendar: context.calendar,
            storage: context.storage,
            llm: context.llm,
            intent: newIntent,
            currentDate: context.currentDate,
            timeZone: context.timeZone
        )
        
        // Execute the target skill
        return try await targetSkill.execute(context: newContext)
        
    default:
        return result
    }
}
```

### Common Handoff Scenarios

| From Skill | To Skill | Trigger |
|-----------|----------|---------|
| meal-planning | healthcare | Allergen/medication interaction detected |
| healthcare | telephony | User needs to call doctor |
| mental-load | meal-planning | Morning briefing includes "no dinner planned" |
| education | family-comms | Grade alert → notify parent |
| family-bonding | restaurant-reservation | Activity suggestion includes dining out |
| elder-care | telephony | Check-in requires phone call |
| wellness | habits | Step goal → suggest walking habit |

---

## 8. Testing & Validation

### Unit Tests with MockLLMBridge

```swift
import XCTest
@testable import HomeOSCore

final class MealPlanningTests: XCTestCase {
    
    func testSuggestDinnerReturnsFormattedResponse() async throws {
        let mockLLM = MockLLMBridge()
        mockLLM.generateResponses["Suggest ONE dinner"] = """
        {"name":"Chicken Stir-Fry","cuisine":"Asian","prepMinutes":20,"description":"Quick weeknight stir-fry","keyIngredients":["chicken","broccoli","soy sauce"]}
        """
        
        let context = SkillContext(
            family: TestData.family,
            storage: InMemoryStorage(),
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What should we have for dinner?")
        )
        
        let skill = MealPlanningSkill()
        let result = try await skill.execute(context: context)
        
        guard case .response(let text) = result else {
            XCTFail("Expected response, got \(result)")
            return
        }
        
        XCTAssertTrue(text.contains("Chicken Stir-Fry"))
        XCTAssertTrue(text.contains("20 min"))
    }
    
    func testAllergyRespected() async throws {
        let mockLLM = MockLLMBridge()
        // Mock should receive prompt containing "MUST AVOID: peanuts"
        mockLLM.generateResponses["MUST AVOID"] = """
        {"name":"Pasta Primavera","cuisine":"Italian","prepMinutes":25,"description":"Allergen-free pasta","keyIngredients":["pasta","vegetables","olive oil"]}
        """
        
        let familyWithAllergy = Family(members: [
            FamilyMember(name: "Test", role: .parent, age: 35, allergies: ["peanuts"])
        ])
        
        let context = SkillContext(
            family: familyWithAllergy,
            storage: InMemoryStorage(),
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What's for dinner?")
        )
        
        let skill = MealPlanningSkill()
        let result = try await skill.execute(context: context)
        
        guard case .response(let text) = result else {
            XCTFail("Expected response")
            return
        }
        
        // Response should NOT contain peanuts
        XCTAssertFalse(text.lowercased().contains("peanut"))
    }
}
```

### Prompt Regression Tests

Save known-good input/output pairs and verify the LLM still produces acceptable results:

```swift
struct PromptRegressionTest: Codable {
    let name: String
    let prompt: String
    let expectedContains: [String]      // Response must contain these
    let expectedNotContains: [String]   // Response must NOT contain these
    let maxLatencyMs: Int
}

final class PromptRegressionRunner {
    let llm: LLMBridge
    let tests: [PromptRegressionTest]
    
    func runAll() async -> [TestResult] {
        var results: [TestResult] = []
        
        for test in tests {
            let start = CFAbsoluteTimeGetCurrent()
            
            do {
                let response = try await llm.generate(prompt: test.prompt)
                let latencyMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
                
                let containsPass = test.expectedContains.allSatisfy { 
                    response.lowercased().contains($0.lowercased()) 
                }
                let notContainsPass = test.expectedNotContains.allSatisfy { 
                    !response.lowercased().contains($0.lowercased()) 
                }
                let latencyPass = latencyMs <= test.maxLatencyMs
                
                results.append(TestResult(
                    name: test.name,
                    passed: containsPass && notContainsPass && latencyPass,
                    latencyMs: latencyMs,
                    response: response,
                    failures: [] // collect specific failures
                ))
            } catch {
                results.append(TestResult(
                    name: test.name,
                    passed: false,
                    latencyMs: 0,
                    response: "",
                    failures: ["Error: \(error)"]
                ))
            }
        }
        
        return results
    }
}
```

### Latency Benchmarks

| Operation | Target | Measurement Point |
|-----------|--------|-------------------|
| Model load (cold start) | <5s | App launch to first inference ready |
| Classification | <500ms | `classify()` call to return |
| Short generation (<50 words) | <1s | `generate()` for brief responses |
| Long generation (>100 words) | <2s | `generate()` for detailed responses |
| JSON extraction | <1.5s | `generateJSON()` call to parsed result |
| Full routing cycle | <3s | User message → SkillResult displayed |

### Integration Test Checklist

- [ ] Model loads successfully on target device (A16+)
- [ ] All 4 LLMBridge methods return valid output
- [ ] JSON extraction handles malformed LLM output gracefully
- [ ] Classification returns valid category names (not hallucinated ones)
- [ ] Memory usage stays under 2GB with model loaded
- [ ] Background inference completes within BGTask time limits (30s for refresh, 5min for processing)
- [ ] Concurrent inference requests don't crash (queue serialization works)
- [ ] MockLLMBridge tests pass without model present

---

## 9. Fallback Strategy

### When Gemma 3n Fails

```swift
/// Wrapper that implements retry + fallback logic around any LLMBridge
final class ResilientLLMBridge: LLMBridge, @unchecked Sendable {
    
    private let primary: LLMBridge
    private let fallbackResponses: [String: String]
    
    init(primary: LLMBridge) {
        self.primary = primary
        self.fallbackResponses = Self.loadHardcodedResponses()
    }
    
    func generate(prompt: String) async throws -> String {
        // Attempt 1: Normal inference
        do {
            return try await primary.generate(prompt: prompt)
        } catch {
            // Attempt 2: Retry with simplified prompt
            let simplified = simplifyPrompt(prompt)
            do {
                return try await primary.generate(prompt: simplified)
            } catch {
                // Attempt 3: Hardcoded fallback
                return hardcodedFallback(for: prompt)
            }
        }
    }
    
    func generateJSON(prompt: String, schema: JSONSchema) async throws -> String {
        do {
            let result = try await primary.generateJSON(prompt: prompt, schema: schema)
            // Validate JSON is actually parseable
            guard let _ = try? JSONSerialization.jsonObject(
                with: result.data(using: .utf8) ?? Data()
            ) else {
                throw GemmaError.jsonParsingFailed(result)
            }
            return result
        } catch {
            // Retry once
            do {
                return try await primary.generateJSON(prompt: prompt, schema: schema)
            } catch {
                // Return empty valid JSON matching schema type
                return schema.schemaString.contains("\"array\"") ? "[]" : "{}"
            }
        }
    }
    
    // ... classify and summarize follow same pattern
    
    private func simplifyPrompt(_ prompt: String) -> String {
        // Remove few-shot examples, trim context, keep core instruction
        let lines = prompt.components(separatedBy: "\n")
        let essential = lines.filter { line in
            !line.starts(with: "Example") &&
            !line.starts(with: "User:") &&  // few-shot examples
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return essential.prefix(10).joined(separator: "\n")
    }
    
    private func hardcodedFallback(for prompt: String) -> String {
        let lower = prompt.lowercased()
        if lower.contains("dinner") || lower.contains("meal") {
            return "I'd suggest something quick tonight — tacos, stir-fry, or pasta are always solid options. What sounds good?"
        }
        if lower.contains("symptom") || lower.contains("health") {
            return "I'm having trouble processing that right now. For health concerns, please contact your doctor or call 911 if it's an emergency. ⚠️ This is not medical advice."
        }
        return "I'm having a bit of trouble right now. Could you try rephrasing that, or ask me something specific?"
    }
    
    private static func loadHardcodedResponses() -> [String: String] {
        // Load from a bundled JSON file of fallback responses per skill
        return [:]
    }
}
```

### Fallback Cascade

```
Attempt 1: Full prompt → Gemma 3n
    ↓ (fails)
Attempt 2: Simplified prompt → Gemma 3n  
    ↓ (fails)  
Attempt 3: Hardcoded response per skill
    ↓ (if user opts in to cloud)
Attempt 4: Gemini API (cloud fallback, requires explicit permission)
```

### Cloud Fallback (Optional — User Opt-In Only)

```swift
/// Cloud fallback using Gemini API — ONLY with explicit user permission
final class GeminiCloudBridge: LLMBridge, @unchecked Sendable {
    
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    func generate(prompt: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "contents": [["parts": [["text": prompt]]]]
        ])
        
        let (data, _) = try await session.data(for: request)
        // Parse Gemini response...
        return parseGeminiResponse(data)
    }
    
    // ... other methods follow same pattern
}

// Usage: Only activate cloud fallback after user grants permission
func requestCloudFallback() -> Bool {
    // Show UI: "I'm having trouble answering locally. 
    // Can I send this to Google's cloud AI for a better answer? 
    // Your message will be sent to Google's servers."
    // Return user's choice
    return false  // Default: deny
}
```

---

## 10. Performance Optimization

### Model Loading

```swift
/// Singleton model manager — loads once, keeps in memory
final class GemmaModelManager {
    static let shared = GemmaModelManager()
    
    private var bridge: GemmaLLMBridge?
    private let loadLock = NSLock()
    private var isLoading = false
    
    /// Pre-load model at app launch. Call from applicationDidFinishLaunching.
    func preload() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadLock.lock()
            defer { self.loadLock.unlock() }
            
            guard self.bridge == nil, !self.isLoading else { return }
            self.isLoading = true
            
            let start = CFAbsoluteTimeGetCurrent()
            do {
                self.bridge = try GemmaLLMBridge()
                let elapsed = CFAbsoluteTimeGetCurrent() - start
                print("✅ Gemma loaded in \(String(format: "%.1f", elapsed))s")
            } catch {
                print("❌ Gemma load failed: \(error)")
            }
            self.isLoading = false
        }
    }
    
    /// Get the bridge, waiting for load if necessary
    func getBridge() async throws -> LLMBridge {
        // Spin until loaded (with timeout)
        let deadline = Date().addingTimeInterval(10)
        while bridge == nil && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        guard let bridge else {
            throw GemmaError.modelNotFound
        }
        return bridge
    }
    
    /// Release model from memory (e.g., on memory warning)
    func unload() {
        loadLock.lock()
        bridge = nil
        loadLock.unlock()
    }
}
```

### Prompt Caching

```swift
/// Cache compiled prompts to avoid reconstructing them every call
final class PromptCache {
    static let shared = PromptCache()
    
    /// Pre-built system prompt (constant across calls)
    let systemPrompt: String = SystemPrompts.base
    
    /// Pre-built few-shot examples for classification (constant)
    let classificationExamples: String = IntentExamples.fewShot
    
    /// Family context — rebuild when family data changes
    private var cachedFamilyContext: String?
    private var familyHash: Int?
    
    func familyContext(for family: Family) -> String {
        let hash = family.members.map(\.name).joined().hashValue
        if hash == familyHash, let cached = cachedFamilyContext {
            return cached
        }
        
        let context = family.members.map { m in
            "\(m.name) (\(m.role), age \(m.age))"
        }.joined(separator: "; ")
        
        cachedFamilyContext = context
        familyHash = hash
        return context
    }
}
```

### Batch Operations

```swift
/// Morning briefing: gather ALL data first, then make ONE LLM call
func generateMorningBriefing(context: SkillContext) async throws -> String {
    // 1. Gather all data in parallel
    async let calendar = context.storage.read(path: "data/calendar.json", type: [CalendarEvent].self)
    async let reminders = context.storage.read(path: "data/reminders.json", type: [Reminder].self)
    async let mealPlan = context.storage.read(path: "data/current_meal_plan.json", type: [MealPlanDay].self)
    async let habits = context.storage.read(path: "data/habits/streaks.json", type: [HabitStreak].self)
    async let medications = context.storage.read(path: "data/health/medications.json", type: [Medication].self)
    
    // 2. Await all
    let cal = (try? await calendar) ?? []
    let rem = (try? await reminders) ?? []
    let meals = (try? await mealPlan) ?? []
    let hab = (try? await habits) ?? []
    let meds = (try? await medications) ?? []
    
    // 3. Build ONE comprehensive prompt
    let dayOfWeek = DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: context.currentDate) - 1]
    
    let prompt = """
    Create a brief, warm morning briefing for \(context.family.members.first?.name ?? "the family").
    Today is \(dayOfWeek).
    
    Today's events: \(cal.isEmpty ? "Nothing scheduled" : cal.prefix(5).map(\.title).joined(separator: ", "))
    Pending reminders: \(rem.isEmpty ? "None" : rem.prefix(3).map(\.title).joined(separator: ", "))
    Tonight's dinner: \(meals.first(where: { $0.day.lowercased().contains(dayOfWeek.lowercased()) })?.name ?? "Not planned yet")
    Active habit streaks: \(hab.filter { $0.currentStreak > 0 }.map { "\($0.name): \($0.currentStreak) days" }.joined(separator: ", "))
    Medications due today: \(meds.isEmpty ? "None" : meds.map(\.name).joined(separator: ", "))
    
    Keep it under 100 words. Be warm and encouraging. Use emoji headers.
    """
    
    // 4. ONE LLM call
    return try await context.llm.generate(prompt: prompt)
}
```

### Memory Management

```swift
// In AppDelegate
func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    // Unload model on memory pressure — it will reload on next use
    GemmaModelManager.shared.unload()
}

// Monitor memory usage
func checkMemoryFootprint() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? info.resident_size : 0
}
```

### Performance Checklist

| Optimization | Implementation | Impact |
|-------------|----------------|--------|
| Model singleton | `GemmaModelManager.shared` | Avoid reload (~5s saved per session) |
| Prompt caching | `PromptCache.shared` | Avoid string reconstruction (~10ms saved per call) |
| Batch data fetch | `async let` parallel reads | Reduce I/O wait for briefings (~200ms saved) |
| Serial inference queue | `DispatchQueue` in bridge | Prevent concurrent model access (crash prevention) |
| JSON validation | `extractJSON()` with fallback | Handle malformed output (reliability) |
| Memory warning handler | Unload model on pressure | Prevent OOM kills |
| Background task limits | Respect 30s/5min BGTask budgets | Prevent task termination |

---

## Appendix A: Skill Registry

All skills and their LLM usage patterns:

| Skill | LLM Pattern | Primary LLMBridge Method |
|-------|-------------|-------------------------|
| meal-planning | C (Generate) + D (JSON) | `generateJSON()`, `generate()` |
| restaurant-reservation | D (JSON Extract) | `generateJSON()` |
| healthcare | B (Classify) + C (Generate) | `classify()`, `generate()` |
| education | B (Classify) + C (Generate) | `classify()`, `generate()` |
| school | A (Direct) + C (Generate) | `generate()` (briefings only) |
| home-maintenance | B (Classify) | `classify()` |
| transportation | B (Classify) | `classify()` |
| family-comms | A (Direct) | None (pure data) |
| family-bonding | C (Generate) | `generate()` |
| mental-load | C (Generate) | `generate()` (briefings) |
| habits | A (Direct) + C (Generate) | `generate()` (motivation) |
| wellness | A (Direct) + B (Classify) | `classify()` (urgency) |
| hire-helper | D (JSON Extract) | `generateJSON()` |
| marketplace-sell | D (JSON Extract) + C (Generate) | `generateJSON()`, `generate()` |
| telephony | A (Direct) | None (action only) |
| note-to-actions | D (JSON Extract) | `generateJSON()` |
| psy-rich | C (Generate) | `generate()` |
| elder-care | B (Classify) + C (Generate) | `classify()`, `generate()` |
| tools | A (Direct) | None (utilities) |

## Appendix B: Model File Setup

### Obtaining the Model

1. Download `gemma-3n-E2B-it` from [Kaggle](https://www.kaggle.com/models/google/gemma) or [HuggingFace](https://huggingface.co/google/gemma-3n)
2. Convert to MediaPipe `.task` format using the [MediaPipe Model Maker](https://developers.google.com/mediapipe/solutions/model_maker)
3. Add to Xcode project as a bundle resource (or download on first launch for smaller app size)

### First-Launch Download (Recommended)

```swift
/// Download model on first launch to keep app bundle small
final class ModelDownloader {
    
    static let modelURL = URL(string: "https://your-cdn.com/models/gemma-3n-E2B-it.task")!
    static let localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("models/gemma-3n-E2B-it.task")
    
    static var isDownloaded: Bool {
        FileManager.default.fileExists(atPath: localPath.path)
    }
    
    static func downloadIfNeeded(progress: @escaping (Double) -> Void) async throws {
        guard !isDownloaded else { return }
        
        // Create directory
        try FileManager.default.createDirectory(
            at: localPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Download with progress
        let (tempURL, _) = try await URLSession.shared.download(from: modelURL)
        try FileManager.default.moveItem(at: tempURL, to: localPath)
    }
}
```

## Appendix C: Debugging Tips

1. **LLM returns garbage JSON:** Check `extractJSON()` — add logging for raw response before extraction
2. **Classification always returns first category:** Model may not understand the prompt — add more examples for the confused categories
3. **Slow inference (>3s):** Check if model is being reloaded — ensure singleton pattern is working
4. **Memory pressure crashes:** Monitor with `checkMemoryFootprint()` — model takes ~1.5GB RAM
5. **Background task killed by iOS:** Ensure total execution stays under 30s for `BGAppRefreshTask`
6. **Prompts too long:** Use `PromptCache` and limit conversation history to 3 turns
7. **Different results across runs:** Set `randomSeed = 0` in options for deterministic testing (remove for production)
