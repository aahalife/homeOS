import Foundation

// MARK: - Skill Protocol

/// Every HomeOS skill conforms to this protocol.
/// Skills are stateless — all state lives in Storage.
public protocol SkillProtocol: Sendable {
    /// Unique skill identifier (e.g., "meal-planning")
    var name: String { get }
    
    /// Human-readable description
    var description: String { get }
    
    /// Keywords that trigger this skill (used by ChatTurn router)
    var triggerKeywords: [String] { get }
    
    /// Check if this skill can handle the given intent.
    /// Returns a confidence score 0.0-1.0.
    func canHandle(intent: UserIntent) -> Double
    
    /// Execute the skill with the given context.
    /// Returns a SkillResult (response, approval request, handoff, or error).
    func execute(context: SkillContext) async throws -> SkillResult
}

// MARK: - User Intent

/// Parsed user message with extracted entities.
public struct UserIntent: Sendable {
    public let rawMessage: String
    public let keywords: [String]       // Lowercased words
    public let entities: ExtractedEntities
    public let urgency: Urgency
    
    public init(rawMessage: String, keywords: [String] = [], entities: ExtractedEntities = .empty, urgency: Urgency = .normal) {
        self.rawMessage = rawMessage
        self.keywords = keywords.isEmpty ? rawMessage.lowercased().split(separator: " ").map(String.init) : keywords
        self.entities = entities
        self.urgency = urgency
    }
}

public struct ExtractedEntities: Sendable {
    public var people: [String]
    public var dates: [String]
    public var times: [String]
    public var locations: [String]
    public var amounts: [Double]
    
    public static let empty = ExtractedEntities(people: [], dates: [], times: [], locations: [], amounts: [])
    
    public init(people: [String] = [], dates: [String] = [], times: [String] = [], locations: [String] = [], amounts: [Double] = []) {
        self.people = people
        self.dates = dates
        self.times = times
        self.locations = locations
        self.amounts = amounts
    }
}

public enum Urgency: String, Sendable {
    case low, normal, urgent, emergency
}

// MARK: - Skill Context

/// Everything a skill needs to do its job.
public struct SkillContext: Sendable {
    public let family: Family
    public let calendar: [CalendarEvent]
    public let storage: any StorageProvider
    public let llm: any LLMBridge
    public let intent: UserIntent
    public let currentDate: Date
    public let timeZone: TimeZone
    
    public init(
        family: Family,
        calendar: [CalendarEvent] = [],
        storage: any StorageProvider,
        llm: any LLMBridge,
        intent: UserIntent,
        currentDate: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        self.family = family
        self.calendar = calendar
        self.storage = storage
        self.llm = llm
        self.intent = intent
        self.currentDate = currentDate
        self.timeZone = timeZone
    }
}

// MARK: - Skill Result

public enum SkillResult: Sendable {
    /// Direct response to the user
    case response(String)
    
    /// Needs user approval before proceeding
    case needsApproval(ApprovalRequest)
    
    /// Hand off to another skill
    case handoff(HandoffRequest)
    
    /// Error occurred
    case error(String)
}

public struct ApprovalRequest: Sendable {
    public let description: String
    public let details: [String]
    public let riskLevel: RiskLevel
    /// Closure to call with approval decision
    public let onDecision: @Sendable (Bool) async throws -> SkillResult
    
    public init(description: String, details: [String], riskLevel: RiskLevel, onDecision: @escaping @Sendable (Bool) async throws -> SkillResult) {
        self.description = description
        self.details = details
        self.riskLevel = riskLevel
        self.onDecision = onDecision
    }
}

public struct HandoffRequest: Sendable {
    public let targetSkill: String
    public let reason: String
    public let context: [String: String]
    
    public init(targetSkill: String, reason: String, context: [String: String] = [:]) {
        self.targetSkill = targetSkill
        self.reason = reason
        self.context = context
    }
}

public enum RiskLevel: String, Sendable {
    case low     // Read-only, informational
    case medium  // Limited impact, ask once
    case high    // Always require explicit approval
}
