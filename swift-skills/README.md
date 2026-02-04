# HomeOS Swift Skills

Modular Swift code for running HomeOS family skills on iOS with on-device LLM (Gemma 3n via MediaPipe).

## Architecture

```
swift-skills/
├── Package.swift
├── Sources/
│   ├── HomeOSCore/              # Shared types, protocols, storage
│   │   ├── Models/              # Family, Member, Event, Task, etc.
│   │   ├── Storage/             # JSON file persistence
│   │   ├── Protocols/           # SkillProtocol, ToolCallable
│   │   └── LLMBridge/          # MediaPipe/Gemma 3n integration
│   ├── Skills/                  # One module per skill
│   │   ├── MealPlanning/
│   │   ├── Healthcare/
│   │   ├── FamilyComms/
│   │   ├── ElderCare/
│   │   ├── ... (all 21 skills)
│   │   └── ChatTurn/           # Orchestrator/router
│   └── HomeOSCLI/              # CLI interface for Lobster integration
└── Tests/
    ├── HomeOSCoreTests/
    └── SkillTests/
```

## Design Principles

### 1. Protocol-Driven
Every skill conforms to `SkillProtocol`:
```swift
protocol SkillProtocol {
    var name: String { get }
    var triggerKeywords: [String] { get }
    func canHandle(intent: UserIntent) -> Bool
    func execute(context: SkillContext) async throws -> SkillResult
}
```

### 2. Deterministic First, LLM Second
- Most logic is pure Swift (conditionals, lookups, date math)
- LLM is called only for: intent classification, content generation, summarization
- LLM calls use structured output (JSON schema) via `LLMBridge`

### 3. Tool Call Interface
For Gemma 3n integration, each skill exposes tool definitions:
```swift
struct ToolDefinition {
    let name: String
    let description: String
    let parameters: [ParameterDef]
    let execute: (ToolInput) async throws -> ToolOutput
}
```

### 4. SwiftUI-Agnostic Core
- All skill logic is in plain Swift (no UI imports)
- UI layer is separate — skills produce `SkillResult` which the app renders
- This means skills work in SwiftUI, UIKit, CLI, or tests

### 5. On-Device LLM via MediaPipe
```swift
protocol LLMBridge {
    func generate(prompt: String, schema: JSONSchema?) async throws -> String
    func classify(input: String, categories: [String]) async throws -> String
}

class MediaPipeLLMBridge: LLMBridge {
    // Uses MediaPipe LLM Inference API with Gemma 3n
}
```

## Shared Types

```swift
struct Family: Codable {
    var members: [FamilyMember]
}

struct FamilyMember: Codable {
    var id: String
    var name: String
    var role: MemberRole  // parent, child, elder
    var age: Int?
    var preferences: Preferences?
    var allergies: [String]?
}

enum MemberRole: String, Codable {
    case parent, child, elder
}

struct SkillContext {
    let family: Family
    let calendar: [CalendarEvent]
    let storage: StorageProvider
    let llm: LLMBridge
    let userMessage: String
    let currentDate: Date
}

enum SkillResult {
    case response(String)
    case needsApproval(ApprovalRequest)
    case handoff(skillName: String, context: [String: Any])
    case error(String)
}
```

## Testing Strategy

Every skill has:
1. **Unit tests** — Pure logic, mocked storage and LLM
2. **Integration tests** — Real storage, mocked LLM
3. **Scenario tests** — Full family scenarios with varied configurations

```swift
func testMealPlanningVegetarianFamily() async throws {
    let family = Family(members: [
        .init(id: "1", name: "Mom", role: .parent, preferences: .init(dietary: ["vegetarian"])),
        .init(id: "2", name: "Kid", role: .child, age: 7)
    ])
    let context = SkillContext(family: family, ...)
    let result = try await MealPlanningSkill().execute(context: context)
    // Assert no meat in suggestions
}
```
