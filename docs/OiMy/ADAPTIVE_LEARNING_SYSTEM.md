# Adaptive Learning System — Self-Enriching Skills

> **Audience:** Coding agents, Claude Code, iOS developers implementing the learning loop.
> **Last Updated:** 2025-07-11

---

## Overview

OiMy starts with 20 built-in skills optimized for Gemma 3n (on-device). But families have unique needs. When the built-in skills fail or feel limiting, OiMy can:

1. **Escalate to cloud LLMs** (Sonnet 4.5 for standard, Opus 4.5 for complex)
2. **Learn from what the cloud LLM does** — capture successful solutions
3. **Distill new capabilities back to on-device skills** — self-improvement

This creates a **virtuous learning loop**: every cloud escalation is an opportunity to make the on-device model smarter.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER REQUEST                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     ON-DEVICE (Gemma 3n)                                 │
│                                                                          │
│   ChatTurnRouter → Skill Selection → execute(context:)                  │
│                                                                          │
│   Result: response / needsApproval / handoff / error                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                         User Feedback (👍/👎)
                                    │
              ┌─────────────────────┴─────────────────────┐
              │                                           │
         👍 SATISFIED                              👎 DISSATISFIED
              │                                           │
              ▼                                           ▼
    [Log for training]                    ┌───────────────────────────┐
                                          │   CLOUD ESCALATION         │
                                          │                            │
                                          │  Sonnet 4.5 (standard)    │
                                          │  Opus 4.5 (complex)       │
                                          └───────────────────────────┘
                                                        │
                                                        ▼
                                          ┌───────────────────────────┐
                                          │   LEARNING PIPELINE        │
                                          │                            │
                                          │  1. Capture solution       │
                                          │  2. Generalize to skill    │
                                          │  3. Validate               │
                                          │  4. Distill to small model │
                                          │  5. Deploy to on-device    │
                                          └───────────────────────────┘
                                                        │
                                                        ▼
                                          ┌───────────────────────────┐
                                          │   SKILL ENRICHED           │
                                          │                            │
                                          │  RAG updated               │
                                          │  Routing updated           │
                                          │  Training data collected   │
                                          └───────────────────────────┘
```

---

## User Feedback Loop

### Thumbs Down Signal (👎)

When a user gives thumbs down on any response:

```swift
// FeedbackManager.swift

public struct FeedbackEvent: Sendable, Codable {
    let exchangeId: String
    let userMessage: String
    let assistantResponse: String
    let feedbackType: FeedbackType
    let timestamp: Date
    let familyId: String
    let skillName: String?
}

public enum FeedbackType: String, Sendable, Codable {
    case thumbsUp = "👍"
    case thumbsDown = "👎"
    case rephrase = "rephrase"
    case abandon = "abandon"
    case dismissSuggestion = "dismiss"
}

public final class FeedbackManager: @unchecked Sendable {
    private let storage: any StorageProvider
    private let escalationService: EscalationService
    
    public init(storage: any StorageProvider, escalationService: EscalationService) {
        self.storage = storage
        self.escalationService = escalationService
    }
    
    /// Record explicit thumbs down from user
    public func recordThumbsDown(exchange: Exchange) async throws {
        // 1. Flag the exchange for potential escalation
        let event = FeedbackEvent(
            exchangeId: exchange.id,
            userMessage: exchange.userMessage,
            assistantResponse: exchange.assistantResponse,
            feedbackType: .thumbsDown,
            timestamp: Date(),
            familyId: exchange.familyId,
            skillName: exchange.skillName
        )
        
        try await storage.write(
            path: "learning/feedback/\(exchange.id).json",
            value: event
        )
        
        // 2. Check user's cloud opt-in preference
        let prefs = try? await storage.read(
            path: "preferences/learning.json",
            type: LearningPreferences.self
        )
        
        if prefs?.autoEscalateOnThumbsDown == true {
            // Auto-escalate without asking
            try await escalateToCloud(exchange: exchange)
        } else {
            // Prompt for opt-in
            // This returns to the skill orchestrator to display the prompt
        }
    }
    
    /// Generate the opt-in prompt for cloud escalation
    public func cloudOptInPrompt() -> String {
        """
        🤔 That didn't work for you. Want me to try a different approach?
        
        This will use cloud AI for a smarter answer. (Uses data, privacy policy applies)
        
        Reply: **Yes** to try again / **No** to skip
        """
    }
}
```

### Implicit Dissatisfaction Signals

Users don't always click thumbs down. Watch for these patterns:

```swift
// DissatisfactionDetector.swift

public struct DissatisfactionDetector: Sendable {
    
    /// Analyze conversation for implicit dissatisfaction
    public func detectDissatisfaction(
        conversation: [ConversationTurn],
        currentMessage: String
    ) -> DissatisfactionSignal? {
        
        // Signal 1: User rephrases the same request 2+ times
        if detectRephrase(conversation: conversation, currentMessage: currentMessage) {
            return .rephrase(count: countRephrases(conversation, currentMessage))
        }
        
        // Signal 2: Explicit rejection phrases
        let rejectionPhrases = [
            "no", "that's not what i meant", "try again",
            "wrong", "not helpful", "that's not right",
            "i said", "what i actually want", "let me clarify"
        ]
        let lowerMessage = currentMessage.lowercased()
        if rejectionPhrases.contains(where: { lowerMessage.contains($0) }) {
            return .explicitRejection(phrase: currentMessage)
        }
        
        // Signal 3: Multi-turn flow abandonment
        // (Detected in SkillOrchestrator when user switches topics mid-flow)
        
        // Signal 4: Dismissed proactive suggestions
        // (Tracked separately in ProactiveSuggestionManager)
        
        return nil
    }
    
    private func detectRephrase(conversation: [ConversationTurn], currentMessage: String) -> Bool {
        // Use semantic similarity or keyword overlap
        guard conversation.count >= 2 else { return false }
        
        let lastUserMessages = conversation
            .filter { $0.role == .user }
            .suffix(3)
            .map { $0.message.lowercased() }
        
        // Simple approach: keyword overlap > 60%
        let currentWords = Set(currentMessage.lowercased().split(separator: " ").map(String.init))
        
        for previousMessage in lastUserMessages {
            let previousWords = Set(previousMessage.split(separator: " ").map(String.init))
            let overlap = currentWords.intersection(previousWords)
            let similarity = Double(overlap.count) / Double(max(currentWords.count, previousWords.count))
            
            if similarity > 0.6 && currentMessage != previousMessage {
                return true // Rephrased, not identical
            }
        }
        return false
    }
    
    private func countRephrases(_ conversation: [ConversationTurn], _ current: String) -> Int {
        // Count how many times user has tried similar messages
        var count = 1 // Current attempt
        let currentWords = Set(current.lowercased().split(separator: " ").map(String.init))
        
        for turn in conversation where turn.role == .user {
            let turnWords = Set(turn.message.lowercased().split(separator: " ").map(String.init))
            let overlap = currentWords.intersection(turnWords)
            let similarity = Double(overlap.count) / Double(max(currentWords.count, turnWords.count))
            if similarity > 0.5 {
                count += 1
            }
        }
        return count
    }
}

public enum DissatisfactionSignal: Sendable {
    case rephrase(count: Int)
    case explicitRejection(phrase: String)
    case flowAbandonment(flowName: String, step: Int)
    case suggestionDismissed(suggestionType: String, consecutiveCount: Int)
}
```

### Conversation Monitoring Integration

The SkillOrchestrator checks for dissatisfaction after each turn:

```swift
// In SkillOrchestrator.swift

func handleMessage(_ raw: String, from member: FamilyMember) async throws -> String {
    // ... existing routing logic ...
    
    // After getting skill result, check for dissatisfaction
    let dissatisfaction = dissatisfactionDetector.detectDissatisfaction(
        conversation: recentConversation,
        currentMessage: raw
    )
    
    if let signal = dissatisfaction {
        switch signal {
        case .rephrase(let count) where count >= 2:
            // User has tried 2+ times — offer cloud escalation
            return await handleEscalationOffer(
                originalMessage: raw,
                reason: "Multiple rephrase attempts detected"
            )
            
        case .explicitRejection:
            // User explicitly said it's wrong
            return await handleEscalationOffer(
                originalMessage: raw,
                reason: "User indicated response was incorrect"
            )
            
        case .flowAbandonment(let flowName, _):
            // Log for learning, but don't interrupt
            try await logFlowAbandonment(flowName: flowName, conversation: recentConversation)
            
        case .suggestionDismissed(_, let count) where count >= 3:
            // User keeps dismissing suggestions — stop that suggestion type
            try await adjustSuggestionFrequency(decrease: true)
            
        default:
            break
        }
    }
    
    // ... rest of handling ...
}
```

---

## Cloud LLM Escalation

### Tier Selection

```swift
// EscalationService.swift

public enum CloudTier: String, Sendable, Codable {
    case sonnet = "anthropic/claude-sonnet-4-5-20251022"
    case opus = "anthropic/claude-opus-4-5-20251101"
}

public struct EscalationService: Sendable {
    private let anthropicClient: AnthropicClient
    private let storage: any StorageProvider
    
    /// Select appropriate cloud tier based on request complexity
    public func selectTier(for request: EscalationRequest) -> CloudTier {
        // Opus triggers:
        // 1. Multi-skill orchestration failures
        if request.involvedSkills.count > 1 {
            return .opus
        }
        
        // 2. Novel scenarios requiring reasoning
        if request.isNovelScenario {
            return .opus
        }
        
        // 3. Skill creation/modification tasks
        if request.requiresSkillCreation {
            return .opus
        }
        
        // 4. User explicitly requests deeper thinking
        let thinkHarder = ["think harder", "really think", "be smarter", "more detail", "complex"]
        if thinkHarder.contains(where: { request.userMessage.lowercased().contains($0) }) {
            return .opus
        }
        
        // Default: Sonnet (faster, cheaper)
        return .sonnet
    }
}
```

#### Tier Characteristics

| Tier | Model | Use Cases | Latency | Cost |
|------|-------|-----------|---------|------|
| **Sonnet 4.5** | `claude-sonnet-4-5-20251022` | Standard escalations, single-skill failures, better understanding needed | ~2-5s | Lower |
| **Opus 4.5** | `claude-opus-4-5-20251101` | Multi-skill orchestration, novel scenarios, skill creation, complex reasoning | ~5-15s | Higher |

### Escalation Context Package

Everything the cloud LLM needs to understand the situation:

```swift
// EscalationRequest.swift

public struct EscalationRequest: Sendable, Codable {
    // Original interaction
    let userMessage: String
    let onDeviceAttempt: OnDeviceAttempt
    
    // User feedback
    let feedbackType: FeedbackType
    let rephraseHistory: [String]?  // If user rephrased multiple times
    
    // Family context (privacy-filtered)
    let familyContext: FamilyContext
    
    // Skill information
    let availableSkills: [SkillSummary]
    let involvedSkills: [String]
    
    // Conversation history (last 10 turns)
    let conversationHistory: [ConversationTurn]
    
    // Metadata
    let timestamp: Date
    let isNovelScenario: Bool
    let requiresSkillCreation: Bool
}

public struct OnDeviceAttempt: Sendable, Codable {
    let skillName: String
    let response: String
    let confidence: Double
    let executionTimeMs: Int
    let errorIfAny: String?
}

public struct FamilyContext: Sendable, Codable {
    let memberNames: [String]           // Just names, not full profiles
    let dietaryRestrictions: [String]
    let allergies: [String]             // CRITICAL safety info
    let healthConditions: [String]      // Relevant to request
    let preferences: [String: String]   // Relevant preferences only
}

public struct SkillSummary: Sendable, Codable {
    let name: String
    let description: String
    let triggerKeywords: [String]
    let capabilities: [String]
}
```

#### Context Builder

```swift
// EscalationContextBuilder.swift

public struct EscalationContextBuilder: Sendable {
    
    public func build(
        exchange: Exchange,
        feedback: FeedbackEvent,
        context: SkillContext,
        conversation: [ConversationTurn]
    ) async throws -> EscalationRequest {
        
        // Filter family context for privacy
        let familyContext = buildFamilyContext(
            family: context.family,
            relevantTo: exchange.userMessage
        )
        
        // Summarize available skills
        let skillSummaries = context.availableSkills.map { skill in
            SkillSummary(
                name: skill.name,
                description: skill.description,
                triggerKeywords: Array(skill.triggerKeywords.prefix(5)),
                capabilities: extractCapabilities(skill)
            )
        }
        
        // Detect if this is a novel scenario
        let isNovel = await detectNovelScenario(
            message: exchange.userMessage,
            existingSkills: context.availableSkills
        )
        
        return EscalationRequest(
            userMessage: exchange.userMessage,
            onDeviceAttempt: OnDeviceAttempt(
                skillName: exchange.skillName ?? "unknown",
                response: exchange.assistantResponse,
                confidence: exchange.confidence ?? 0.0,
                executionTimeMs: exchange.executionTimeMs,
                errorIfAny: exchange.error
            ),
            feedbackType: feedback.feedbackType,
            rephraseHistory: extractRephrases(conversation),
            familyContext: familyContext,
            availableSkills: skillSummaries,
            involvedSkills: [exchange.skillName].compactMap { $0 },
            conversationHistory: Array(conversation.suffix(10)),
            timestamp: Date(),
            isNovelScenario: isNovel,
            requiresSkillCreation: isNovel && !hasPartialMatch(exchange.userMessage)
        )
    }
    
    private func buildFamilyContext(family: Family, relevantTo message: String) -> FamilyContext {
        // Only include context relevant to the request
        let memberNames = family.members.map { $0.name }
        
        // Always include safety-critical info
        let allergies = family.members.flatMap { $0.allergies ?? [] }
        
        // Include dietary only if request seems food-related
        let foodKeywords = ["eat", "dinner", "meal", "food", "recipe", "cook", "restaurant"]
        let dietary: [String]
        if foodKeywords.contains(where: { message.lowercased().contains($0) }) {
            dietary = family.members.compactMap { $0.preferences?.dietary }.flatMap { $0 }
        } else {
            dietary = []
        }
        
        // Include health conditions if health-related
        let healthKeywords = ["sick", "fever", "medicine", "medication", "doctor", "symptom"]
        let healthConditions: [String]
        if healthKeywords.contains(where: { message.lowercased().contains($0) }) {
            healthConditions = family.members.compactMap { $0.healthConditions }.flatMap { $0 }
        } else {
            healthConditions = []
        }
        
        return FamilyContext(
            memberNames: memberNames,
            dietaryRestrictions: dietary,
            allergies: allergies,
            healthConditions: healthConditions,
            preferences: [:] // Add relevant preferences as needed
        )
    }
}
```

### Cloud LLM System Prompt

```swift
// CloudSystemPrompts.swift

public struct CloudSystemPrompts {
    
    /// System prompt addition for cloud LLM during escalation
    public static func escalationPrompt(
        availableTools: [String],
        availableSkills: [SkillSummary]
    ) -> String {
        let toolList = availableTools.joined(separator: ", ")
        let skillList = availableSkills.map { "- \($0.name): \($0.description)" }.joined(separator: "\n")
        
        return """
        You are helping OiMy, an on-device family assistant. The on-device model (Gemma 3n) \
        couldn't satisfactorily handle this request.
        
        ## Your Job
        
        1. **Fulfill the user's request** as best you can using available tools and context
        2. **Note new patterns** — if you discover something that should become a skill, say so
        3. **Document tool usage** — if you call external APIs, explain exactly what you did
        4. **Explain your approach** — be clear so this can be distilled to simpler models
        
        ## Available Tools
        \(toolList)
        
        ## Available Skills (what on-device can already do)
        \(skillList)
        
        ## Constraints
        - Respect the same safety rules as the on-device model (see below)
        - For health topics: ALWAYS add medical disclaimer
        - For high-risk actions: ALWAYS require explicit approval
        - Respect family allergies as CRITICAL safety constraints
        
        ## Output Format
        
        If you solved the problem in a way that should become a new skill, append:
        
        ```
        [SKILL_CANDIDATE]
        Name: suggested-skill-name
        Trigger: example trigger phrases
        Pattern: brief description of the workflow you used
        Tools: which tools you called
        [/SKILL_CANDIDATE]
        ```
        
        If you just answered better without discovering a new pattern, that's fine — no annotation needed.
        """
    }
}
```

### Escalation Execution

```swift
// EscalationService.swift (continued)

public func escalateToCloud(request: EscalationRequest) async throws -> CloudResponse {
    let tier = selectTier(for: request)
    
    // Build the full prompt
    let systemPrompt = CloudSystemPrompts.escalationPrompt(
        availableTools: loadAvailableTools(),
        availableSkills: request.availableSkills
    )
    
    let userPrompt = buildUserPrompt(request: request)
    
    // Call Anthropic API
    let apiRequest = AnthropicRequest(
        model: tier.rawValue,
        system: systemPrompt,
        messages: [
            .init(role: "user", content: userPrompt)
        ],
        maxTokens: 4096,
        tools: loadToolDefinitions()
    )
    
    let startTime = CFAbsoluteTimeGetCurrent()
    let apiResponse = try await anthropicClient.complete(apiRequest)
    let latencyMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
    
    // Parse response for skill candidates
    let skillCandidate = extractSkillCandidate(from: apiResponse.content)
    
    // Log for learning
    let cloudResponse = CloudResponse(
        tier: tier,
        response: apiResponse.content,
        toolCalls: apiResponse.toolCalls ?? [],
        skillCandidate: skillCandidate,
        latencyMs: latencyMs,
        timestamp: Date()
    )
    
    try await logEscalation(request: request, response: cloudResponse)
    
    return cloudResponse
}

private func buildUserPrompt(request: EscalationRequest) -> String {
    var prompt = """
    ## Original Request
    User: "\(request.userMessage)"
    
    ## On-Device Attempt
    Skill: \(request.onDeviceAttempt.skillName)
    Response: "\(request.onDeviceAttempt.response)"
    Confidence: \(String(format: "%.2f", request.onDeviceAttempt.confidence))
    """
    
    if let error = request.onDeviceAttempt.errorIfAny {
        prompt += "\nError: \(error)"
    }
    
    prompt += """
    
    ## User Feedback
    Type: \(request.feedbackType.rawValue)
    """
    
    if let rephrases = request.rephraseHistory, !rephrases.isEmpty {
        prompt += "\nRephrase attempts: \(rephrases.joined(separator: " → "))"
    }
    
    prompt += """
    
    ## Family Context
    Members: \(request.familyContext.memberNames.joined(separator: ", "))
    """
    
    if !request.familyContext.allergies.isEmpty {
        prompt += "\n⚠️ ALLERGIES (MUST AVOID): \(request.familyContext.allergies.joined(separator: ", "))"
    }
    
    if !request.familyContext.dietaryRestrictions.isEmpty {
        prompt += "\nDietary: \(request.familyContext.dietaryRestrictions.joined(separator: ", "))"
    }
    
    if !request.familyContext.healthConditions.isEmpty {
        prompt += "\nHealth: \(request.familyContext.healthConditions.joined(separator: ", "))"
    }
    
    prompt += """
    
    ## Conversation History (last \(request.conversationHistory.count) turns)
    """
    
    for turn in request.conversationHistory {
        prompt += "\n\(turn.role == .user ? "User" : "Assistant"): \(turn.message)"
    }
    
    prompt += "\n\n## Task\nPlease help with this request. Be concise but thorough."
    
    return prompt
}

private func extractSkillCandidate(from content: String) -> SkillCandidate? {
    // Look for [SKILL_CANDIDATE] block
    guard let startRange = content.range(of: "[SKILL_CANDIDATE]"),
          let endRange = content.range(of: "[/SKILL_CANDIDATE]") else {
        return nil
    }
    
    let candidateBlock = String(content[startRange.upperBound..<endRange.lowerBound])
    
    // Parse the block
    var name: String?
    var triggers: [String] = []
    var pattern: String?
    var tools: [String] = []
    
    for line in candidateBlock.components(separatedBy: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("Name:") {
            name = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        } else if trimmed.hasPrefix("Trigger:") {
            let triggerStr = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            triggers = triggerStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else if trimmed.hasPrefix("Pattern:") {
            pattern = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
        } else if trimmed.hasPrefix("Tools:") {
            let toolStr = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            tools = toolStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }
    
    guard let skillName = name, let skillPattern = pattern else { return nil }
    
    return SkillCandidate(
        name: skillName,
        triggers: triggers,
        pattern: skillPattern,
        tools: tools,
        sourceEscalation: nil // Set later
    )
}
```

---

## Skill Creation Pipeline

When the cloud LLM solves something with:
- A tool combination not in existing skills
- A workflow not covered by existing flows
- An intent not in the routing table

...we trigger the Skill Creation Pipeline.

### Step 1: Capture the Solution

```swift
// LearnedSolution.swift

public struct LearnedSolution: Sendable, Codable, Identifiable {
    public let id: String
    public let originalRequest: String
    public let cloudTier: CloudTier
    public let cloudResponse: String
    public let toolCalls: [ToolCall]
    public let reasoning: String
    public let userSatisfaction: Bool
    public let timestamp: Date
    public let familyId: String
    public let skillCandidate: SkillCandidate?
    
    public init(
        id: String = UUID().uuidString,
        originalRequest: String,
        cloudTier: CloudTier,
        cloudResponse: String,
        toolCalls: [ToolCall],
        reasoning: String,
        userSatisfaction: Bool,
        timestamp: Date = Date(),
        familyId: String,
        skillCandidate: SkillCandidate?
    ) {
        self.id = id
        self.originalRequest = originalRequest
        self.cloudTier = cloudTier
        self.cloudResponse = cloudResponse
        self.toolCalls = toolCalls
        self.reasoning = reasoning
        self.userSatisfaction = userSatisfaction
        self.timestamp = timestamp
        self.familyId = familyId
        self.skillCandidate = skillCandidate
    }
}

public struct ToolCall: Sendable, Codable {
    public let functionName: String
    public let arguments: [String: AnyCodable]
    public let result: String?
}

public struct SkillCandidate: Sendable, Codable {
    public let name: String
    public let triggers: [String]
    public let pattern: String
    public let tools: [String]
    public var sourceEscalation: String?  // ID of the escalation that created this
}

// SolutionCapture.swift

public final class SolutionCaptureManager: @unchecked Sendable {
    private let storage: any StorageProvider
    
    public func capture(
        request: EscalationRequest,
        response: CloudResponse,
        userAccepted: Bool
    ) async throws -> LearnedSolution {
        
        // Extract reasoning from response
        let reasoning = extractReasoning(from: response.response)
        
        let solution = LearnedSolution(
            originalRequest: request.userMessage,
            cloudTier: response.tier,
            cloudResponse: response.response,
            toolCalls: response.toolCalls.map { call in
                ToolCall(
                    functionName: call.name,
                    arguments: call.arguments,
                    result: call.result
                )
            },
            reasoning: reasoning,
            userSatisfaction: userAccepted,
            timestamp: Date(),
            familyId: request.familyContext.familyId ?? "unknown",
            skillCandidate: response.skillCandidate
        )
        
        // Store in solutions log
        try await storage.write(
            path: "learning/solutions/\(solution.id).json",
            value: solution
        )
        
        // Append to JSONL for training
        let jsonlEntry = try JSONEncoder().encode(solution)
        try await appendToJSONL(
            path: "learning/solutions.jsonl",
            data: jsonlEntry
        )
        
        // If user accepted AND there's a skill candidate, trigger skill creation
        if userAccepted, let candidate = solution.skillCandidate {
            try await triggerSkillCreation(solution: solution, candidate: candidate)
        }
        
        return solution
    }
    
    private func extractReasoning(from response: String) -> String {
        // Look for explicit reasoning markers
        if let reasoningStart = response.range(of: "## Approach"),
           let reasoningEnd = response.range(of: "##", range: reasoningStart.upperBound..<response.endIndex) {
            return String(response[reasoningStart.upperBound..<reasoningEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback: first paragraph as reasoning
        let paragraphs = response.components(separatedBy: "\n\n")
        return paragraphs.first ?? response
    }
}
```

### Step 2: Generalize to a Skill Pattern

```swift
// SkillGenerationService.swift

public struct SkillGenerationService: Sendable {
    private let anthropicClient: AnthropicClient
    private let storage: any StorageProvider
    
    /// Ask Opus to generalize a successful solution into a reusable skill pattern
    public func generateSkillPattern(from solution: LearnedSolution) async throws -> GeneratedSkill {
        
        let prompt = """
        Given this successful solution that helped a family, create a reusable skill pattern.
        
        ## Original Request
        "\(solution.originalRequest)"
        
        ## Solution
        \(solution.cloudResponse)
        
        ## Tools Used
        \(solution.toolCalls.map { "- \($0.functionName)" }.joined(separator: "\n"))
        
        ## Reasoning
        \(solution.reasoning)
        
        ---
        
        Create a complete skill definition. Include:
        
        1. **Skill Name** — kebab-case, descriptive (e.g., "vehicle-maintenance")
        
        2. **Trigger Keywords and Sample Utterances** — at least 20 variations:
           - Direct requests
           - Indirect mentions
           - Questions
           - Partial phrases
        
        3. **Step-by-Step Flow** — in IF/THEN format for small models:
           ```
           IF user mentions [X] AND [Y]:
             1. Check [data source]
             2. IF [condition]: respond with [template]
             3. ELSE: ask for [missing info]
           ```
        
        4. **Required Data and Defaults**
           - What data does this skill need?
           - What are sensible defaults?
        
        5. **Risk Level for Each Action**
           - LOW: read-only, informational
           - MEDIUM: limited impact, ask once
           - HIGH: always require approval
        
        6. **Handoffs** — to/from which existing skills?
        
        7. **Few-Shot Examples** — at least 5 input/output pairs
        
        Format your response as a complete SKILL.md file.
        """
        
        let response = try await anthropicClient.complete(AnthropicRequest(
            model: CloudTier.opus.rawValue,  // Always use Opus for skill creation
            system: "You are an expert at designing deterministic skill patterns for small language models.",
            messages: [.init(role: "user", content: prompt)],
            maxTokens: 8192
        ))
        
        return try parseGeneratedSkill(from: response.content, solution: solution)
    }
    
    private func parseGeneratedSkill(from content: String, solution: LearnedSolution) throws -> GeneratedSkill {
        // Parse the markdown response into structured skill data
        var skill = GeneratedSkill(
            id: UUID().uuidString,
            name: "",
            description: "",
            triggerKeywords: [],
            sampleUtterances: [],
            flow: "",
            requiredData: [:],
            riskLevels: [:],
            handoffs: HandoffConfig(incoming: [], outgoing: []),
            fewShotExamples: [],
            fullMarkdown: content,
            sourceEscalationId: solution.id,
            status: .pending
        )
        
        // Extract skill name
        if let nameMatch = content.range(of: "# ") {
            let nameEnd = content[nameMatch.upperBound...].firstIndex(of: "\n") ?? content.endIndex
            skill.name = String(content[nameMatch.upperBound..<nameEnd])
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
        }
        
        // Extract trigger keywords (look for bullet list under "Triggers" or similar)
        if let triggersSection = extractSection(from: content, header: "Trigger") {
            skill.triggerKeywords = extractBulletItems(from: triggersSection)
        }
        
        // Extract flow (look for code block or IF/THEN section)
        if let flowSection = extractSection(from: content, header: "Flow") ?? 
                            extractSection(from: content, header: "Step-by-Step") {
            skill.flow = flowSection
        }
        
        // Extract examples
        if let examplesSection = extractSection(from: content, header: "Example") {
            skill.fewShotExamples = parseExamples(from: examplesSection)
        }
        
        return skill
    }
    
    private func extractSection(from content: String, header: String) -> String? {
        // Find section by header
        guard let headerRange = content.range(of: header, options: .caseInsensitive) else {
            return nil
        }
        
        // Find the start of content (after header line)
        let afterHeader = content[headerRange.upperBound...]
        guard let contentStart = afterHeader.firstIndex(of: "\n") else { return nil }
        
        // Find the next header (## or #)
        let sectionContent = afterHeader[contentStart...]
        if let nextHeader = sectionContent.range(of: "\n#") {
            return String(sectionContent[..<nextHeader.lowerBound])
        }
        
        return String(sectionContent)
    }
    
    private func extractBulletItems(from section: String) -> [String] {
        section.components(separatedBy: "\n")
            .filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("-") || 
                      $0.trimmingCharacters(in: .whitespaces).hasPrefix("*") }
            .map { line in
                line.trimmingCharacters(in: .whitespaces)
                    .dropFirst() // Remove bullet
                    .trimmingCharacters(in: .whitespaces)
            }
    }
    
    private func parseExamples(from section: String) -> [FewShotExample] {
        var examples: [FewShotExample] = []
        
        // Look for User:/Assistant: or Input:/Output: patterns
        let lines = section.components(separatedBy: "\n")
        var currentInput: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("user:") || trimmed.lowercased().hasPrefix("input:") {
                currentInput = String(trimmed.dropFirst(trimmed.lowercased().hasPrefix("user:") ? 5 : 6))
                    .trimmingCharacters(in: .whitespaces)
            } else if (trimmed.lowercased().hasPrefix("assistant:") || trimmed.lowercased().hasPrefix("output:")),
                      let input = currentInput {
                let output = String(trimmed.dropFirst(trimmed.lowercased().hasPrefix("assistant:") ? 10 : 7))
                    .trimmingCharacters(in: .whitespaces)
                examples.append(FewShotExample(input: input, output: output, intent: nil))
                currentInput = nil
            }
        }
        
        return examples
    }
}

public struct GeneratedSkill: Sendable, Codable, Identifiable {
    public var id: String
    public var name: String
    public var description: String
    public var triggerKeywords: [String]
    public var sampleUtterances: [String]
    public var flow: String
    public var requiredData: [String: String]
    public var riskLevels: [String: RiskLevel]
    public var handoffs: HandoffConfig
    public var fewShotExamples: [FewShotExample]
    public var fullMarkdown: String
    public var sourceEscalationId: String
    public var status: SkillStatus
}

public struct HandoffConfig: Sendable, Codable {
    public var incoming: [String]  // Skills that can hand off TO this one
    public var outgoing: [String]  // Skills this one can hand off TO
}

public struct FewShotExample: Sendable, Codable {
    public let input: String
    public let output: String
    public let intent: String?
}

public enum SkillStatus: String, Sendable, Codable {
    case pending = "pending"
    case validated = "validated"
    case approved = "approved"
    case deployed = "deployed"
    case rejected = "rejected"
}
```

### Step 3: Validate the New Skill

```swift
// SkillValidator.swift

public struct SkillValidator: Sendable {
    private let storage: any StorageProvider
    private let llm: any LLMBridge
    private let existingSkills: [any SkillProtocol]
    
    public struct ValidationResult: Sendable {
        public let passed: Bool
        public let score: Double
        public let issues: [ValidationIssue]
        public let requiresHumanReview: Bool
    }
    
    public struct ValidationIssue: Sendable {
        public let severity: IssueSeverity
        public let description: String
        public let suggestion: String?
    }
    
    public enum IssueSeverity: String, Sendable {
        case warning, error, critical
    }
    
    /// Validate a generated skill before deployment
    public func validate(skill: GeneratedSkill) async throws -> ValidationResult {
        var issues: [ValidationIssue] = []
        var score: Double = 1.0
        
        // Test 1: Run against synthetic variations of the original request
        let syntheticTests = generateSyntheticTests(for: skill)
        let testResults = await runSyntheticTests(skill: skill, tests: syntheticTests)
        
        if testResults.passRate < 0.8 {
            issues.append(ValidationIssue(
                severity: .error,
                description: "Only \(Int(testResults.passRate * 100))% of test scenarios passed",
                suggestion: "Review the flow logic and add more edge case handling"
            ))
            score -= 0.3
        }
        
        // Test 2: Check for conflicts with existing skills
        let conflicts = checkSkillConflicts(newSkill: skill)
        if !conflicts.isEmpty {
            for conflict in conflicts {
                issues.append(ValidationIssue(
                    severity: .warning,
                    description: "Keyword conflict with '\(conflict.skillName)': \(conflict.overlappingKeywords.joined(separator: ", "))",
                    suggestion: "Consider merging with existing skill or adjusting trigger keywords"
                ))
                score -= 0.1
            }
        }
        
        // Test 3: Verify risk levels are appropriate
        let riskIssues = validateRiskLevels(skill: skill)
        issues.append(contentsOf: riskIssues)
        
        // Test 4: Check for required safety guardrails
        let safetyIssues = validateSafetyGuardrails(skill: skill)
        issues.append(contentsOf: safetyIssues)
        if safetyIssues.contains(where: { $0.severity == .critical }) {
            score = 0  // Fail if safety issues
        }
        
        // Test 5: Validate few-shot examples are diverse enough
        if skill.fewShotExamples.count < 5 {
            issues.append(ValidationIssue(
                severity: .warning,
                description: "Only \(skill.fewShotExamples.count) few-shot examples provided",
                suggestion: "Add more diverse examples for better intent matching"
            ))
            score -= 0.1
        }
        
        // Determine if human review is needed
        let requiresHumanReview = issues.contains { $0.severity == .critical } ||
                                   skill.riskLevels.values.contains(.high) ||
                                   score < 0.7
        
        return ValidationResult(
            passed: score >= 0.6 && !issues.contains { $0.severity == .critical },
            score: max(0, score),
            issues: issues,
            requiresHumanReview: requiresHumanReview
        )
    }
    
    private func generateSyntheticTests(for skill: GeneratedSkill) -> [SyntheticTest] {
        var tests: [SyntheticTest] = []
        
        // Generate variations of each trigger keyword
        for keyword in skill.triggerKeywords.prefix(10) {
            tests.append(SyntheticTest(
                input: "Can you help me with \(keyword)?",
                expectedSkill: skill.name,
                expectedOutcome: .response
            ))
            
            tests.append(SyntheticTest(
                input: "I need to \(keyword)",
                expectedSkill: skill.name,
                expectedOutcome: .response
            ))
        }
        
        // Use existing few-shot examples as tests
        for example in skill.fewShotExamples {
            tests.append(SyntheticTest(
                input: example.input,
                expectedSkill: skill.name,
                expectedOutcome: .response
            ))
        }
        
        return tests
    }
    
    private func runSyntheticTests(skill: GeneratedSkill, tests: [SyntheticTest]) async -> TestResults {
        var passed = 0
        var failed = 0
        
        for test in tests {
            // Simulate intent matching
            let intent = UserIntent(rawMessage: test.input)
            let confidence = calculateConfidence(skill: skill, intent: intent)
            
            if confidence > 0.5 {
                passed += 1
            } else {
                failed += 1
            }
        }
        
        return TestResults(
            total: tests.count,
            passed: passed,
            failed: failed,
            passRate: Double(passed) / Double(tests.count)
        )
    }
    
    private func calculateConfidence(skill: GeneratedSkill, intent: UserIntent) -> Double {
        // Simple keyword matching (mirrors canHandle logic)
        let messageWords = Set(intent.rawMessage.lowercased().split(separator: " ").map(String.init))
        let keywordMatches = skill.triggerKeywords.filter { keyword in
            messageWords.contains(keyword.lowercased()) ||
            intent.rawMessage.lowercased().contains(keyword.lowercased())
        }
        
        if keywordMatches.isEmpty { return 0.0 }
        return min(1.0, Double(keywordMatches.count) * 0.2 + 0.3)
    }
    
    private func checkSkillConflicts(newSkill: GeneratedSkill) -> [SkillConflict] {
        var conflicts: [SkillConflict] = []
        let newKeywords = Set(newSkill.triggerKeywords.map { $0.lowercased() })
        
        for existingSkill in existingSkills {
            let existingKeywords = Set(existingSkill.triggerKeywords.map { $0.lowercased() })
            let overlap = newKeywords.intersection(existingKeywords)
            
            if overlap.count >= 3 {  // Significant overlap
                conflicts.append(SkillConflict(
                    skillName: existingSkill.name,
                    overlappingKeywords: Array(overlap)
                ))
            }
        }
        
        return conflicts
    }
    
    private func validateRiskLevels(skill: GeneratedSkill) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check that HIGH risk actions are appropriately flagged
        let highRiskKeywords = ["call", "send", "pay", "transfer", "book", "purchase", "order", "unlock"]
        
        for keyword in highRiskKeywords {
            if skill.flow.lowercased().contains(keyword) {
                if skill.riskLevels.values.allSatisfy({ $0 != .high }) {
                    issues.append(ValidationIssue(
                        severity: .warning,
                        description: "Skill contains '\(keyword)' action but no HIGH risk level defined",
                        suggestion: "Add risk level HIGH for actions involving \(keyword)"
                    ))
                }
            }
        }
        
        return issues
    }
    
    private func validateSafetyGuardrails(skill: GeneratedSkill) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let flow = skill.flow.lowercased()
        
        // Check for health-related skills
        let healthKeywords = ["health", "medical", "symptom", "medicine", "medication", "doctor"]
        if healthKeywords.contains(where: { flow.contains($0) }) {
            if !skill.fullMarkdown.contains("not medical advice") &&
               !skill.fullMarkdown.contains("consult a doctor") {
                issues.append(ValidationIssue(
                    severity: .critical,
                    description: "Health-related skill missing medical disclaimer",
                    suggestion: "Add 'This is not medical advice. Consult a doctor.' to responses"
                ))
            }
        }
        
        // Check for allergy awareness in food-related skills
        let foodKeywords = ["meal", "recipe", "food", "cook", "eat", "ingredient"]
        if foodKeywords.contains(where: { flow.contains($0) }) {
            if !flow.contains("allerg") {
                issues.append(ValidationIssue(
                    severity: .critical,
                    description: "Food-related skill must check for allergies",
                    suggestion: "Add allergy checking step: 'IF ingredient IN family.allergies: REJECT'"
                ))
            }
        }
        
        return issues
    }
}

struct SyntheticTest {
    let input: String
    let expectedSkill: String
    let expectedOutcome: ExpectedOutcome
}

enum ExpectedOutcome {
    case response, approval, handoff, error
}

struct TestResults {
    let total: Int
    let passed: Int
    let failed: Int
    let passRate: Double
}

struct SkillConflict {
    let skillName: String
    let overlappingKeywords: [String]
}
```

### Step 4: Distill to Small Model Format

```swift
// SkillDistiller.swift

public struct SkillDistiller: Sendable {
    
    /// Convert a validated GeneratedSkill into two versions:
    /// 1. Full version — for cloud LLM reference
    /// 2. Small-model version — explicit IF/THEN rules
    public func distill(skill: GeneratedSkill) -> DistilledSkill {
        
        // Full version is already in fullMarkdown
        let fullVersion = skill.fullMarkdown
        
        // Small-model version: convert natural language to explicit rules
        let smallModelVersion = generateSmallModelVersion(skill: skill)
        
        // Generate Swift stub for the skill
        let swiftStub = generateSwiftStub(skill: skill)
        
        return DistilledSkill(
            skill: skill,
            fullVersion: fullVersion,
            smallModelVersion: smallModelVersion,
            swiftImplementation: swiftStub,
            ragChunks: generateRAGChunks(skill: skill)
        )
    }
    
    private func generateSmallModelVersion(skill: GeneratedSkill) -> String {
        """
        # \(skill.name.capitalized.replacingOccurrences(of: "-", with: " ")) — Small Model Version
        
        ## Intent Detection
        
        KEYWORDS: \(skill.triggerKeywords.joined(separator: ", "))
        
        MATCH IF message contains ANY of: \(skill.triggerKeywords.prefix(5).joined(separator: " OR "))
        
        ## Flow Rules
        
        \(convertToExplicitRules(skill.flow))
        
        ## Response Templates
        
        \(generateResponseTemplates(skill: skill))
        
        ## Few-Shot Examples (for in-context learning)
        
        \(skill.fewShotExamples.map { example in
            """
            User: \(example.input)
            Assistant: \(example.output)
            """
        }.joined(separator: "\n\n"))
        
        ## Safety Checks (ALWAYS run before response)
        
        1. IF health-related: APPEND "⚠️ This is not medical advice."
        2. IF mentions family member allergies: REJECT any food containing allergen
        3. IF action is HIGH risk: REQUIRE explicit approval
        """
    }
    
    private func convertToExplicitRules(_ flow: String) -> String {
        // Convert natural language flow to explicit IF/THEN rules
        // This is a simplified version — real implementation would use NLP
        
        var rules: [String] = []
        let lines = flow.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.lowercased().hasPrefix("if ") ||
               trimmed.lowercased().hasPrefix("when ") {
                rules.append("RULE: " + trimmed)
            } else if trimmed.lowercased().hasPrefix("then ") ||
                      trimmed.lowercased().hasPrefix("respond ") {
                rules.append("  → " + trimmed)
            } else if trimmed.lowercased().hasPrefix("else") {
                rules.append("ELSE:")
            } else if trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                rules.append("  STEP: " + trimmed.dropFirst().trimmingCharacters(in: .whitespaces))
            }
        }
        
        if rules.isEmpty {
            // Fallback: wrap entire flow
            return """
            RULE: User asks about \(flow.prefix(50))...
              → Execute skill flow
              → Return response
            """
        }
        
        return rules.joined(separator: "\n")
    }
    
    private func generateResponseTemplates(skill: GeneratedSkill) -> String {
        var templates: [String] = []
        
        // Generate templates from few-shot examples
        for (index, example) in skill.fewShotExamples.enumerated() {
            templates.append("""
            TEMPLATE_\(index + 1):
              TRIGGER: "\(example.input.prefix(30))..."
              RESPONSE: "\(example.output.prefix(100))..."
            """)
        }
        
        // Add generic templates
        templates.append("""
        TEMPLATE_NEED_MORE_INFO:
          TRIGGER: Missing required data
          RESPONSE: "I need a bit more info. Could you tell me [MISSING_FIELD]?"
        """)
        
        templates.append("""
        TEMPLATE_CONFIRM_ACTION:
          TRIGGER: HIGH risk action
          RESPONSE: "⚠️ APPROVAL REQUIRED\\nAction: [ACTION]\\nReply YES to proceed or NO to cancel."
        """)
        
        return templates.joined(separator: "\n\n")
    }
    
    private func generateSwiftStub(skill: GeneratedSkill) -> String {
        let className = skill.name
            .split(separator: "-")
            .map { $0.capitalized }
            .joined() + "Skill"
        
        return """
        import Foundation
        
        /// Auto-generated skill from learning pipeline
        /// Source: Escalation \(skill.sourceEscalationId)
        /// Status: \(skill.status.rawValue)
        public struct \(className): SkillProtocol, Sendable {
            
            public let name = "\(skill.name)"
            public let description = "\(skill.description)"
            
            public let triggerKeywords: [String] = [
                \(skill.triggerKeywords.prefix(20).map { "\"\($0)\"" }.joined(separator: ",\n        "))
            ]
            
            public func canHandle(intent: UserIntent) -> Double {
                let message = intent.rawMessage.lowercased()
                var score: Double = 0.0
                
                for keyword in triggerKeywords {
                    if message.contains(keyword.lowercased()) {
                        score += 0.2
                    }
                }
                
                return min(1.0, score)
            }
            
            public func execute(context: SkillContext) async throws -> SkillResult {
                // TODO: Implement based on distilled flow
                // Flow:
                // \(skill.flow.prefix(200).replacingOccurrences(of: "\n", with: "\n        // "))
                
                return .response("[\(className)] Not yet fully implemented.")
            }
        }
        """
    }
    
    private func generateRAGChunks(skill: GeneratedSkill) -> [RAGChunk] {
        var chunks: [RAGChunk] = []
        
        // Chunk 1: Skill overview
        chunks.append(RAGChunk(
            id: "\(skill.name)-overview",
            content: """
            Skill: \(skill.name)
            Description: \(skill.description)
            Triggers: \(skill.triggerKeywords.prefix(10).joined(separator: ", "))
            """,
            metadata: ["type": "skill-overview", "skill": skill.name]
        ))
        
        // Chunk 2: Flow logic
        chunks.append(RAGChunk(
            id: "\(skill.name)-flow",
            content: skill.flow,
            metadata: ["type": "skill-flow", "skill": skill.name]
        ))
        
        // Chunk 3: Each few-shot example
        for (index, example) in skill.fewShotExamples.enumerated() {
            chunks.append(RAGChunk(
                id: "\(skill.name)-example-\(index)",
                content: "User: \(example.input)\nAssistant: \(example.output)",
                metadata: ["type": "skill-example", "skill": skill.name]
            ))
        }
        
        return chunks
    }
}

public struct DistilledSkill: Sendable, Codable {
    public let skill: GeneratedSkill
    public let fullVersion: String
    public let smallModelVersion: String
    public let swiftImplementation: String
    public let ragChunks: [RAGChunk]
}

public struct RAGChunk: Sendable, Codable {
    public let id: String
    public let content: String
    public let metadata: [String: String]
}
```

### Step 5: Add to RAG and Routing

```swift
// SkillDeployer.swift

public final class SkillDeployer: @unchecked Sendable {
    private let storage: any StorageProvider
    
    /// Deploy a validated and distilled skill
    public func deploy(distilled: DistilledSkill) async throws {
        let skill = distilled.skill
        
        // 1. Write skill markdown to small-skills directory
        try await storage.write(
            path: "docs/OiMy/small-skills/\(skill.name).md",
            value: distilled.smallModelVersion
        )
        
        // 2. Write full version for cloud reference
        try await storage.write(
            path: "docs/OiMy/skills-full/\(skill.name).md",
            value: distilled.fullVersion
        )
        
        // 3. Write Swift implementation stub
        try await storage.write(
            path: "swift-skills/Sources/GeneratedSkills/\(skill.name.pascalCase)Skill.swift",
            value: distilled.swiftImplementation
        )
        
        // 4. Update SKILL_INTENT_MAP.md
        try await updateIntentMap(skill: skill)
        
        // 5. Add few-shot examples to system prompt
        try await updateSystemPrompt(skill: skill)
        
        // 6. Index RAG chunks
        for chunk in distilled.ragChunks {
            try await storage.write(
                path: "learning/rag-index/\(chunk.id).json",
                value: chunk
            )
        }
        
        // 7. Update skill status
        var updatedSkill = skill
        updatedSkill.status = .deployed
        try await storage.write(
            path: "learning/deployed-skills/\(skill.id).json",
            value: updatedSkill
        )
        
        // 8. Log deployment
        try await logDeployment(skill: skill)
    }
    
    private func updateIntentMap(skill: GeneratedSkill) async throws {
        // Read existing map
        var intentMap = try await storage.read(
            path: "docs/OiMy/SKILL_INTENT_MAP.md",
            type: String.self
        ) ?? "# Skill Intent Map\n"
        
        // Append new skill
        let newEntry = """
        
        ## \(skill.name)
        
        **Keywords:** \(skill.triggerKeywords.joined(separator: ", "))
        
        **Sample Utterances:**
        \(skill.sampleUtterances.prefix(5).map { "- \($0)" }.joined(separator: "\n"))
        
        **Risk Level:** \(skill.riskLevels.values.max()?.rawValue ?? "low")
        
        **Handoffs:**
        - Incoming: \(skill.handoffs.incoming.joined(separator: ", "))
        - Outgoing: \(skill.handoffs.outgoing.joined(separator: ", "))
        
        ---
        """
        
        intentMap += newEntry
        
        try await storage.write(
            path: "docs/OiMy/SKILL_INTENT_MAP.md",
            value: intentMap
        )
    }
    
    private func updateSystemPrompt(skill: GeneratedSkill) async throws {
        // Read existing prompt
        var systemPrompt = try await storage.read(
            path: "docs/OiMy/GEMMA_SYSTEM_PROMPT.md",
            type: String.self
        ) ?? ""
        
        // Find the few-shot examples section
        guard let examplesMarker = systemPrompt.range(of: "## Few-Shot Examples") else {
            // Add section if doesn't exist
            systemPrompt += "\n\n## Few-Shot Examples (Learned Skills)\n"
        }
        
        // Append new examples
        let newExamples = skill.fewShotExamples.prefix(3).map { example in
            """
            
            User: \(example.input)
            Skill: \(skill.name)
            """
        }.joined()
        
        systemPrompt += newExamples
        
        try await storage.write(
            path: "docs/OiMy/GEMMA_SYSTEM_PROMPT.md",
            value: systemPrompt
        )
    }
    
    private func logDeployment(skill: GeneratedSkill) async throws {
        let log = DeploymentLog(
            skillId: skill.id,
            skillName: skill.name,
            deployedAt: Date(),
            sourceEscalation: skill.sourceEscalationId
        )
        
        try await storage.write(
            path: "learning/deployment-log/\(skill.id).json",
            value: log
        )
    }
}

struct DeploymentLog: Codable {
    let skillId: String
    let skillName: String
    let deployedAt: Date
    let sourceEscalation: String
}

extension String {
    var pascalCase: String {
        split(separator: "-")
            .map { $0.capitalized }
            .joined()
    }
}
```

---

## Fine-Tuning Data Collection

### What Gets Logged for Training

Every successful cloud escalation becomes training data:

```swift
// TrainingDataCollector.swift

public struct TrainingExample: Sendable, Codable {
    public let id: String
    public let input: String              // User message + context
    public let intent: String             // Classified intent
    public let skill: String              // Which skill should handle
    public let toolCalls: [ToolCallData]  // What tools were called
    public let response: String           // Final response to user
    public let userAccepted: Bool         // Did user give thumbs up?
    public let source: TrainingSource
    public let timestamp: Date
}

public struct ToolCallData: Sendable, Codable {
    public let function: String
    public let args: [String: AnyCodable]
}

public enum TrainingSource: String, Sendable, Codable {
    case sonnetEscalation = "sonnet-escalation"
    case opusEscalation = "opus-escalation"
    case userCorrection = "user-correction"
    case humanLabel = "human-label"
}

public final class TrainingDataCollector: @unchecked Sendable {
    private let storage: any StorageProvider
    
    /// Convert a learned solution to training format
    public func collectTrainingData(from solution: LearnedSolution) async throws {
        let example = TrainingExample(
            id: "learn-\(dateFormatter.string(from: solution.timestamp))-\(solution.id.prefix(6))",
            input: buildTrainingInput(solution: solution),
            intent: solution.skillCandidate?.name ?? "unknown",
            skill: solution.skillCandidate?.name ?? "general",
            toolCalls: solution.toolCalls.map { call in
                ToolCallData(function: call.functionName, args: call.arguments)
            },
            response: extractFinalResponse(from: solution.cloudResponse),
            userAccepted: solution.userSatisfaction,
            source: solution.cloudTier == .opus ? .opusEscalation : .sonnetEscalation,
            timestamp: solution.timestamp
        )
        
        // Write to JSONL file
        try await appendToJSONL(
            path: "docs/OiMy/training-data/escalations.jsonl",
            entry: example
        )
        
        // Also collect for intent classification training
        if solution.userSatisfaction {
            try await collectIntentExample(solution: solution, example: example)
        }
        
        // Collect for tool-calling training (FunctionGemma)
        if !solution.toolCalls.isEmpty && solution.userSatisfaction {
            try await collectToolCallExample(solution: solution, example: example)
        }
    }
    
    private func buildTrainingInput(solution: LearnedSolution) -> String {
        // Compact format for training
        "User: \(solution.originalRequest)"
    }
    
    private func extractFinalResponse(from cloudResponse: String) -> String {
        // Remove skill candidate block if present
        if let candidateStart = cloudResponse.range(of: "[SKILL_CANDIDATE]") {
            return String(cloudResponse[..<candidateStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cloudResponse
    }
    
    private func collectIntentExample(solution: LearnedSolution, example: TrainingExample) async throws {
        let intentExample = IntentTrainingExample(
            input: solution.originalRequest,
            intent: example.intent,
            confidence: 1.0  // Human-verified
        )
        
        try await appendToJSONL(
            path: "docs/OiMy/training-data/intent-classification.jsonl",
            entry: intentExample
        )
    }
    
    private func collectToolCallExample(solution: LearnedSolution, example: TrainingExample) async throws {
        let toolExample = ToolCallTrainingExample(
            input: solution.originalRequest,
            tools: solution.toolCalls.map { call in
                ToolCallSpec(
                    name: call.functionName,
                    arguments: call.arguments
                )
            }
        )
        
        try await appendToJSONL(
            path: "docs/OiMy/training-data/tool-calling.jsonl",
            entry: toolExample
        )
    }
    
    private func appendToJSONL<T: Encodable>(path: String, entry: T) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = []  // Compact, no pretty-print
        let jsonData = try encoder.encode(entry)
        let jsonString = String(data: jsonData, encoding: .utf8)! + "\n"
        
        // Append to file
        let existing = try? await storage.read(path: path, type: String.self)
        let updated = (existing ?? "") + jsonString
        try await storage.write(path: path, value: updated)
    }
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f
    }()
}

struct IntentTrainingExample: Codable {
    let input: String
    let intent: String
    let confidence: Double
}

struct ToolCallTrainingExample: Codable {
    let input: String
    let tools: [ToolCallSpec]
}

struct ToolCallSpec: Codable {
    let name: String
    let arguments: [String: AnyCodable]
}
```

### Dataset Location

```
~/clawd/homeos/learning/
├── training-data/
│   ├── escalations.jsonl           # All escalations (raw)
│   ├── intent-classification.jsonl  # For fine-tuning intent model
│   └── tool-calling.jsonl           # For fine-tuning FunctionGemma
```

### Periodic Fine-Tuning

```swift
// FineTuningManager.swift

public struct FineTuningManager: Sendable {
    private let storage: any StorageProvider
    
    /// Check if we have enough data for fine-tuning
    public func checkFineTuningReadiness() async throws -> FineTuningStatus {
        let escalations = try await countJSONLEntries(path: "docs/OiMy/training-data/escalations.jsonl")
        let intents = try await countJSONLEntries(path: "docs/OiMy/training-data/intent-classification.jsonl")
        let toolCalls = try await countJSONLEntries(path: "docs/OiMy/training-data/tool-calling.jsonl")
        
        return FineTuningStatus(
            escalationCount: escalations,
            intentExampleCount: intents,
            toolCallExampleCount: toolCalls,
            readyForIntentFineTuning: intents >= 100,
            readyForToolCallFineTuning: toolCalls >= 50,
            lastFineTuningDate: try await getLastFineTuningDate()
        )
    }
    
    /// Export training data for Google Colab fine-tuning
    public func exportForFineTuning() async throws -> ExportedDataset {
        // Read all JSONL files
        let escalations = try await readJSONL(path: "docs/OiMy/training-data/escalations.jsonl")
        let intents = try await readJSONL(path: "docs/OiMy/training-data/intent-classification.jsonl")
        let toolCalls = try await readJSONL(path: "docs/OiMy/training-data/tool-calling.jsonl")
        
        // Split into train/val/test (80/10/10)
        let intentSplit = splitDataset(intents, trainRatio: 0.8, valRatio: 0.1)
        let toolSplit = splitDataset(toolCalls, trainRatio: 0.8, valRatio: 0.1)
        
        // Write split datasets
        try await writeDataset(intentSplit.train, to: "exports/intent-train.jsonl")
        try await writeDataset(intentSplit.val, to: "exports/intent-val.jsonl")
        try await writeDataset(intentSplit.test, to: "exports/intent-test.jsonl")
        
        try await writeDataset(toolSplit.train, to: "exports/tool-train.jsonl")
        try await writeDataset(toolSplit.val, to: "exports/tool-val.jsonl")
        try await writeDataset(toolSplit.test, to: "exports/tool-test.jsonl")
        
        return ExportedDataset(
            intentTrain: intentSplit.train.count,
            intentVal: intentSplit.val.count,
            intentTest: intentSplit.test.count,
            toolTrain: toolSplit.train.count,
            toolVal: toolSplit.val.count,
            toolTest: toolSplit.test.count,
            exportPath: "exports/"
        )
    }
    
    private func splitDataset(_ data: [String], trainRatio: Double, valRatio: Double) 
        -> (train: [String], val: [String], test: [String]) {
        let shuffled = data.shuffled()
        let trainEnd = Int(Double(data.count) * trainRatio)
        let valEnd = trainEnd + Int(Double(data.count) * valRatio)
        
        return (
            train: Array(shuffled[..<trainEnd]),
            val: Array(shuffled[trainEnd..<valEnd]),
            test: Array(shuffled[valEnd...])
        )
    }
}

public struct FineTuningStatus: Sendable {
    public let escalationCount: Int
    public let intentExampleCount: Int
    public let toolCallExampleCount: Int
    public let readyForIntentFineTuning: Bool
    public let readyForToolCallFineTuning: Bool
    public let lastFineTuningDate: Date?
}

public struct ExportedDataset: Sendable {
    public let intentTrain: Int
    public let intentVal: Int
    public let intentTest: Int
    public let toolTrain: Int
    public let toolVal: Int
    public let toolTest: Int
    public let exportPath: String
}
```

#### Fine-Tuning Workflow (Manual Steps)

When 100+ new examples accumulate:

1. **Export to Google Colab notebook**
   ```bash
   # Export training data
   swift run HomeOSCLI export-training-data --output ./exports/
   ```

2. **Fine-tune FunctionGemma on tool-calling examples**
   - Use `exports/tool-train.jsonl` for training
   - Validate on `exports/tool-val.jsonl`

3. **Fine-tune Gemma 3n on intent classification examples**
   - Use `exports/intent-train.jsonl` for training
   - Validate on `exports/intent-val.jsonl`

4. **Validate on held-out test set**
   - Check accuracy on `exports/*-test.jsonl`
   - Compare to baseline model

5. **Deploy updated models if performance improves**
   - Replace model files in app bundle
   - Update model version in app config

---

## Feedback Dashboard (For Power Users)

### What Users Can See

```swift
// LearningDashboard.swift

public struct LearningDashboard: Sendable {
    private let storage: any StorageProvider
    
    /// Generate weekly learning summary for user
    public func weeklyLearning() async throws -> WeeklyLearningSummary {
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        // Count new skills learned
        let newSkills = try await storage.listFiles(path: "learning/deployed-skills/")
            .filter { try await isAfterDate($0, date: oneWeekAgo) }
        
        // Count successful escalations
        let solutions = try await storage.listFiles(path: "learning/solutions/")
            .filter { try await isAfterDate($0, date: oneWeekAgo) }
        
        // Get skill names
        let skillNames = try await loadSkillNames(from: newSkills)
        
        return WeeklyLearningSummary(
            newSkillsCount: newSkills.count,
            newSkillNames: skillNames,
            successfulEscalations: solutions.count,
            periodStart: oneWeekAgo,
            periodEnd: Date()
        )
    }
    
    /// List recently learned skills
    public func recentlyLearnedSkills(limit: Int = 10) async throws -> [LearnedSkillSummary] {
        let skills = try await storage.listFiles(path: "learning/deployed-skills/")
        var summaries: [LearnedSkillSummary] = []
        
        for skillPath in skills.suffix(limit) {
            if let skill = try? await storage.read(path: skillPath, type: GeneratedSkill.self) {
                summaries.append(LearnedSkillSummary(
                    name: skill.name,
                    description: skill.description,
                    learnedAt: Date(), // Parse from file metadata
                    exampleTrigger: skill.triggerKeywords.first ?? "",
                    isEnabled: true // Check preferences
                ))
            }
        }
        
        return summaries.reversed() // Most recent first
    }
    
    /// Generate user-friendly learning update message
    public func learningUpdateMessage() async throws -> String? {
        let summary = try await weeklyLearning()
        
        if summary.newSkillsCount == 0 {
            return nil
        }
        
        var message = "🧠 OiMy learned \(summary.newSkillsCount) new thing\(summary.newSkillsCount == 1 ? "" : "s") this week!\n\n"
        
        for name in summary.newSkillNames.prefix(3) {
            message += "• \(name.replacingOccurrences(of: "-", with: " ").capitalized)\n"
        }
        
        if summary.newSkillNames.count > 3 {
            message += "• ...and \(summary.newSkillNames.count - 3) more\n"
        }
        
        message += "\n💡 Tap to see details or disable any learned behavior."
        
        return message
    }
}

public struct WeeklyLearningSummary: Sendable {
    public let newSkillsCount: Int
    public let newSkillNames: [String]
    public let successfulEscalations: Int
    public let periodStart: Date
    public let periodEnd: Date
}

public struct LearnedSkillSummary: Sendable {
    public let name: String
    public let description: String
    public let learnedAt: Date
    public let exampleTrigger: String
    public let isEnabled: Bool
}
```

### "Teach OiMy" Mode

Allow users to explicitly add patterns:

```swift
// TeachMode.swift

public struct TeachModeManager: Sendable {
    private let storage: any StorageProvider
    private let skillGenerator: SkillGenerationService
    
    /// User explicitly teaches a new pattern
    public func teachNewPattern(
        trigger: String,
        expectedResponse: String,
        category: String?
    ) async throws -> TeachResult {
        
        // Create a manual training example
        let example = ManualTeachExample(
            id: UUID().uuidString,
            trigger: trigger,
            expectedResponse: expectedResponse,
            category: category,
            createdAt: Date(),
            userId: "user" // Could be family member ID
        )
        
        // Store for training
        try await storage.write(
            path: "learning/manual-teach/\(example.id).json",
            value: example
        )
        
        // Add to few-shot examples immediately (for quick learning)
        try await addToFewShotExamples(example: example)
        
        // If we have 5+ similar examples, consider creating a skill
        let similarExamples = try await findSimilarExamples(to: trigger)
        if similarExamples.count >= 5 {
            return .skillCandidate(name: suggestSkillName(from: similarExamples))
        }
        
        return .learned(message: "Got it! I'll remember that.")
    }
    
    /// Correct a wrong response
    public func correctResponse(
        originalMessage: String,
        wrongResponse: String,
        correctResponse: String
    ) async throws {
        let correction = ResponseCorrection(
            id: UUID().uuidString,
            originalMessage: originalMessage,
            wrongResponse: wrongResponse,
            correctResponse: correctResponse,
            createdAt: Date()
        )
        
        // Store for training
        try await storage.write(
            path: "learning/corrections/\(correction.id).json",
            value: correction
        )
        
        // Add to training data
        let example = TrainingExample(
            id: "correct-\(correction.id)",
            input: originalMessage,
            intent: "unknown",
            skill: "general",
            toolCalls: [],
            response: correctResponse,
            userAccepted: true,
            source: .userCorrection,
            timestamp: Date()
        )
        
        try await appendToJSONL(
            path: "docs/OiMy/training-data/escalations.jsonl",
            entry: example
        )
    }
}

public enum TeachResult: Sendable {
    case learned(message: String)
    case skillCandidate(name: String)
    case alreadyKnown
}

struct ManualTeachExample: Codable {
    let id: String
    let trigger: String
    let expectedResponse: String
    let category: String?
    let createdAt: Date
    let userId: String
}

struct ResponseCorrection: Codable {
    let id: String
    let originalMessage: String
    let wrongResponse: String
    let correctResponse: String
    let createdAt: Date
}
```

### Privacy Controls

```swift
// LearningPrivacy.swift

public struct LearningPreferences: Sendable, Codable {
    public var enableLearning: Bool = true
    public var autoEscalateOnThumbsDown: Bool = false
    public var shareAnonymizedLearnings: Bool = false
    public var enabledLearnedSkills: [String: Bool] = [:]  // skill name -> enabled
    public var cloudEscalationOptIn: Bool = true
}

public final class LearningPrivacyManager: @unchecked Sendable {
    private let storage: any StorageProvider
    
    /// Get current learning preferences
    public func getPreferences() async throws -> LearningPreferences {
        try await storage.read(
            path: "preferences/learning.json",
            type: LearningPreferences.self
        ) ?? LearningPreferences()
    }
    
    /// Update learning preferences
    public func updatePreferences(_ prefs: LearningPreferences) async throws {
        try await storage.write(
            path: "preferences/learning.json",
            value: prefs
        )
    }
    
    /// Disable a specific learned skill
    public func disableLearnedSkill(name: String) async throws {
        var prefs = try await getPreferences()
        prefs.enabledLearnedSkills[name] = false
        try await updatePreferences(prefs)
    }
    
    /// Delete all learning history
    public func clearLearningHistory() async throws {
        // Delete escalation logs
        try await storage.delete(path: "learning/escalations/")
        
        // Delete solutions
        try await storage.delete(path: "learning/solutions/")
        
        // Delete pending skills
        try await storage.delete(path: "learning/new-skills/")
        
        // Keep deployed skills but mark as "pre-installed"
        // (We don't want to break existing functionality)
        
        // Clear training data
        try await storage.delete(path: "learning/training-data/")
    }
    
    /// Export learning data for user review
    public func exportLearningData() async throws -> LearningExport {
        let escalations = try await storage.listFiles(path: "learning/escalations/")
        let solutions = try await storage.listFiles(path: "learning/solutions/")
        let skills = try await storage.listFiles(path: "learning/deployed-skills/")
        
        return LearningExport(
            escalationCount: escalations.count,
            solutionCount: solutions.count,
            learnedSkillCount: skills.count,
            dataSize: calculateDataSize()
        )
    }
}

public struct LearningExport: Sendable {
    public let escalationCount: Int
    public let solutionCount: Int
    public let learnedSkillCount: Int
    public let dataSize: String  // e.g., "2.3 MB"
}
```

---

## Implementation: Complete Swift Code

### FeedbackManager (Complete)

```swift
// FeedbackManager.swift

import Foundation

/// Manages user feedback and triggers learning pipelines
public final class FeedbackManager: @unchecked Sendable {
    private let storage: any StorageProvider
    private let escalationService: EscalationService
    private let solutionCapture: SolutionCaptureManager
    private let dissatisfactionDetector: DissatisfactionDetector
    private let learningPrefs: LearningPrivacyManager
    
    public init(
        storage: any StorageProvider,
        escalationService: EscalationService,
        solutionCapture: SolutionCaptureManager,
        dissatisfactionDetector: DissatisfactionDetector = DissatisfactionDetector(),
        learningPrefs: LearningPrivacyManager
    ) {
        self.storage = storage
        self.escalationService = escalationService
        self.solutionCapture = solutionCapture
        self.dissatisfactionDetector = dissatisfactionDetector
        self.learningPrefs = learningPrefs
    }
    
    // MARK: - Explicit Feedback
    
    /// Record thumbs down and potentially trigger escalation
    public func recordThumbsDown(exchange: Exchange) async throws -> FeedbackResponse {
        let prefs = try await learningPrefs.getPreferences()
        
        guard prefs.enableLearning else {
            return .acknowledged
        }
        
        // Log the feedback
        let event = FeedbackEvent(
            exchangeId: exchange.id,
            userMessage: exchange.userMessage,
            assistantResponse: exchange.assistantResponse,
            feedbackType: .thumbsDown,
            timestamp: Date(),
            familyId: exchange.familyId,
            skillName: exchange.skillName
        )
        
        try await storage.write(
            path: "learning/feedback/\(exchange.id).json",
            value: event
        )
        
        // Check if cloud escalation is enabled
        if prefs.cloudEscalationOptIn {
            if prefs.autoEscalateOnThumbsDown {
                return try await escalateToCloud(exchange: exchange)
            } else {
                return .offerEscalation(prompt: cloudOptInPrompt())
            }
        }
        
        return .acknowledged
    }
    
    /// Record thumbs up for positive reinforcement learning
    public func recordThumbsUp(exchange: Exchange) async throws {
        let prefs = try await learningPrefs.getPreferences()
        guard prefs.enableLearning else { return }
        
        let event = FeedbackEvent(
            exchangeId: exchange.id,
            userMessage: exchange.userMessage,
            assistantResponse: exchange.assistantResponse,
            feedbackType: .thumbsUp,
            timestamp: Date(),
            familyId: exchange.familyId,
            skillName: exchange.skillName
        )
        
        try await storage.write(
            path: "learning/feedback/\(exchange.id).json",
            value: event
        )
        
        // Add to positive training data
        let example = TrainingExample(
            id: "positive-\(exchange.id)",
            input: exchange.userMessage,
            intent: exchange.skillName ?? "general",
            skill: exchange.skillName ?? "general",
            toolCalls: [],
            response: exchange.assistantResponse,
            userAccepted: true,
            source: .humanLabel,
            timestamp: Date()
        )
        
        try await appendToJSONL(
            path: "docs/OiMy/training-data/escalations.jsonl",
            entry: example
        )
    }
    
    // MARK: - Implicit Feedback Detection
    
    /// Check for implicit dissatisfaction signals in conversation
    public func checkImplicitDissatisfaction(
        conversation: [ConversationTurn],
        currentMessage: String
    ) -> DissatisfactionSignal? {
        dissatisfactionDetector.detectDissatisfaction(
            conversation: conversation,
            currentMessage: currentMessage
        )
    }
    
    // MARK: - Cloud Escalation
    
    /// Escalate to cloud LLM with full context
    public func escalateToCloud(exchange: Exchange) async throws -> FeedbackResponse {
        // Build escalation request
        let context = try await buildEscalationContext(exchange: exchange)
        
        // Call cloud LLM
        let response = try await escalationService.escalateToCloud(request: context)
        
        // Return cloud response to user
        return .escalated(response: response.response, awaitingFeedback: true)
    }
    
    /// Handle user acceptance/rejection of cloud response
    public func handleEscalationFeedback(
        escalationId: String,
        accepted: Bool
    ) async throws {
        // Load the escalation
        guard let request = try await storage.read(
            path: "learning/escalations/\(escalationId).json",
            type: EscalationRequest.self
        ) else { return }
        
        guard let response = try await storage.read(
            path: "learning/escalation-responses/\(escalationId).json",
            type: CloudResponse.self
        ) else { return }
        
        // Capture the solution
        let solution = try await solutionCapture.capture(
            request: request,
            response: response,
            userAccepted: accepted
        )
        
        // If accepted and has skill candidate, trigger skill creation
        if accepted, solution.skillCandidate != nil {
            try await triggerSkillCreation(solution: solution)
        }
    }
    
    // MARK: - Skill Creation
    
    /// Trigger the skill creation pipeline
    public func triggerSkillCreation(solution: LearnedSolution) async throws {
        guard let candidate = solution.skillCandidate else { return }
        
        // Generate full skill pattern
        let skillGenerator = SkillGenerationService(
            anthropicClient: escalationService.anthropicClient,
            storage: storage
        )
        
        let generatedSkill = try await skillGenerator.generateSkillPattern(from: solution)
        
        // Validate
        let validator = SkillValidator(
            storage: storage,
            llm: escalationService.llmBridge,
            existingSkills: [] // Load from registry
        )
        
        let validation = try await validator.validate(skill: generatedSkill)
        
        if validation.passed && !validation.requiresHumanReview {
            // Auto-deploy
            try await deploySkill(generatedSkill)
        } else {
            // Save for human review
            var pendingSkill = generatedSkill
            pendingSkill.status = .pending
            try await storage.write(
                path: "learning/pending-skills/\(generatedSkill.id).json",
                value: pendingSkill
            )
        }
    }
    
    private func deploySkill(_ skill: GeneratedSkill) async throws {
        let distiller = SkillDistiller()
        let distilled = distiller.distill(skill: skill)
        
        let deployer = SkillDeployer(storage: storage)
        try await deployer.deploy(distilled: distilled)
    }
    
    // MARK: - Helpers
    
    private func cloudOptInPrompt() -> String {
        """
        🤔 That didn't work for you. Want me to try a different approach?
        
        This will use cloud AI for a smarter answer. (Uses data, privacy policy applies)
        
        Reply: **Yes** to try again / **No** to skip
        """
    }
    
    private func buildEscalationContext(exchange: Exchange) async throws -> EscalationRequest {
        let builder = EscalationContextBuilder()
        let context = try await loadSkillContext(for: exchange)
        let conversation = try await loadRecentConversation(familyId: exchange.familyId)
        
        let feedback = FeedbackEvent(
            exchangeId: exchange.id,
            userMessage: exchange.userMessage,
            assistantResponse: exchange.assistantResponse,
            feedbackType: .thumbsDown,
            timestamp: Date(),
            familyId: exchange.familyId,
            skillName: exchange.skillName
        )
        
        return try await builder.build(
            exchange: exchange,
            feedback: feedback,
            context: context,
            conversation: conversation
        )
    }
    
    private func appendToJSONL<T: Encodable>(path: String, entry: T) async throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(entry)
        let jsonString = String(data: jsonData, encoding: .utf8)! + "\n"
        
        let existing = try? await storage.read(path: path, type: String.self)
        let updated = (existing ?? "") + jsonString
        try await storage.write(path: path, value: updated)
    }
}

public enum FeedbackResponse: Sendable {
    case acknowledged
    case offerEscalation(prompt: String)
    case escalated(response: String, awaitingFeedback: Bool)
}
```

### Storage Schema

```
~/clawd/homeos/learning/
├── feedback/                        # Raw feedback events
│   └── {exchange-id}.json
├── escalations/                     # Escalation requests sent to cloud
│   └── {escalation-id}.json
├── escalation-responses/            # Cloud LLM responses
│   └── {escalation-id}.json
├── solutions/                       # Successful solutions (learned)
│   └── {solution-id}.json
├── solutions.jsonl                  # All solutions in JSONL format
├── pending-skills/                  # Skills awaiting validation/review
│   └── {skill-id}.json
├── deployed-skills/                 # Validated and deployed skills
│   └── {skill-id}.json
├── manual-teach/                    # User-taught patterns
│   └── {teach-id}.json
├── corrections/                     # User corrections to wrong responses
│   └── {correction-id}.json
├── rag-index/                       # RAG chunks for skill retrieval
│   └── {chunk-id}.json
├── training-data/                   # Formatted for fine-tuning
│   ├── escalations.jsonl
│   ├── intent-classification.jsonl
│   └── tool-calling.jsonl
└── deployment-log/                  # Deployment history
    └── {skill-id}.json
```

---

## Example: Learning a New Skill

### Scenario: Vehicle Maintenance

User asks: *"Can you check if my car needs an oil change?"*

#### Step 1: On-Device Attempt

```
On-device: No skill matches "oil change" well.
Best match: home-maintenance (0.25 confidence — below threshold)
Response: "I'm not sure how to help with that. Could you tell me more about what you need?"
```

User gives 👎

#### Step 2: Cloud Escalation Offer

```
OiMy: "🤔 That didn't work for you. Want me to try a different approach?
      This will use cloud AI for a smarter answer."

User: "Yes"
```

#### Step 3: Cloud Escalation (Sonnet 4.5)

**Context sent:**
- Original: "Can you check if my car needs an oil change?"
- On-device attempt: home-maintenance skill, low confidence
- Family data: 2019 Honda Accord, last oil change date in storage

**Cloud response:**
```
Based on your records, your 2019 Honda Accord had its last oil change on 
March 15, 2025 at 45,230 miles.

Honda recommends oil changes every 7,500 miles or 12 months.

Current status:
• Days since last change: 118 days
• Estimated current miles: ~48,000 (based on your driving patterns)
• Miles since last change: ~2,770

✅ You're fine for now! Schedule your next oil change around 52,730 miles 
   or September 2025, whichever comes first.

Want me to set a reminder?

[SKILL_CANDIDATE]
Name: vehicle-maintenance
Trigger: oil change, tire rotation, car service, vehicle maintenance, mechanic, car inspection
Pattern: Check vehicle records → lookup maintenance interval for make/model → calculate since last service → provide recommendation
Tools: storage (vehicle records), calendar (scheduling)
[/SKILL_CANDIDATE]
```

User gives ✅

#### Step 4: Skill Creation Triggered

Opus 4.5 generates a full skill pattern:

```markdown
# Vehicle Maintenance

## Description
Track and manage vehicle maintenance schedules including oil changes, 
tire rotations, inspections, and service appointments.

## Trigger Keywords
oil change, tire rotation, car service, vehicle maintenance, mechanic, 
car inspection, brake check, fluid check, car needs service, when to 
service car, maintenance schedule, check engine, car repair, auto service,
vehicle service, car checkup, tune up, transmission service, coolant change,
car battery

## Sample Utterances
- "When does my car need an oil change?"
- "Is it time for a tire rotation?"
- "Schedule car maintenance"
- "My check engine light is on"
- "When was the last oil change?"
...

## Flow

```
IF user asks about specific maintenance item (oil, tires, brakes, etc.):
  1. Load vehicle data from storage/vehicles.json
  2. Find maintenance record for that item
  3. Look up recommended interval for vehicle make/model
  4. Calculate days/miles since last service
  5. IF overdue:
     → "Your [vehicle] is overdue for [service]. Last done [date] at [miles]."
     → OFFER to schedule appointment
  6. ELSE IF due soon (within 1 month or 1000 miles):
     → "Your [vehicle] will need [service] soon. Schedule for [date]?"
  7. ELSE:
     → "Your [vehicle] is good! Next [service] due around [date/miles]."

IF user wants to schedule:
  → HANDOFF to telephony skill with mechanic details

IF user reports a problem (check engine light, strange noise):
  → Classify urgency (immediate/soon/monitor)
  → Provide appropriate guidance
  → OFFER to find nearby mechanics
```

## Risk Levels
- Checking maintenance status: LOW
- Setting reminders: LOW  
- Scheduling service appointment: MEDIUM
- Calling mechanic: HIGH (requires telephony handoff)

## Handoffs
- Incoming: tools (reminder set for maintenance)
- Outgoing: telephony (booking appointments)

## Few-Shot Examples

User: "When does my car need an oil change?"
Assistant: "Your 2019 Honda Accord had its last oil change 118 days ago at 45,230 miles. You're good for another ~2,500 miles or until September. Want me to set a reminder?"

User: "My check engine light came on"
Assistant: "⚠️ A check engine light can indicate various issues. For safety:
1. If the car is running normally, you can drive to a mechanic soon (within 1-2 days)
2. If the light is blinking or you notice performance issues, stop driving and get it checked immediately

Want me to find nearby mechanics or schedule a diagnostic?"

...
```

#### Step 5: Validation

- ✅ 85% of synthetic tests pass
- ✅ No conflicts with existing skills
- ✅ Risk levels appropriate
- ⚠️ Requires human review (calls mechanics = HIGH risk handoff)

#### Step 6: Deployment

After human approval:
- Skill added to `/docs/OiMy/small-skills/vehicle-maintenance.md`
- Keywords added to `SKILL_INTENT_MAP.md`
- Few-shot examples added to `GEMMA_SYSTEM_PROMPT.md`
- Training data added to `training-data/escalations.jsonl`

#### Step 7: Future Requests

Now when user asks "Check my tire pressure" or "When's my car inspection due?", the on-device model handles it without cloud escalation.

---

## Summary

The Adaptive Learning System creates a self-improving loop:

1. **On-device skills** handle ~95% of requests
2. **User feedback** (explicit or implicit) catches failures
3. **Cloud escalation** solves complex cases with Sonnet/Opus
4. **Learning pipeline** captures successful solutions
5. **Skill creation** generalizes solutions into reusable patterns
6. **Validation** ensures quality and safety
7. **Deployment** enriches on-device capabilities
8. **Fine-tuning** periodically improves base models

The result: OiMy gets smarter with every family interaction, while respecting privacy and keeping most processing on-device.
