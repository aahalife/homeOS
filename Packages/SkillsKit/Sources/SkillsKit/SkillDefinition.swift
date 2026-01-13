//
//  SkillDefinition.swift
//  SkillsKit
//
//  Defines the schema for skill definitions that can be loaded from JSON/YAML.
//  Designed for deterministic execution by small LLMs (7B-70B parameters).
//

import Foundation

// MARK: - Skill Definition

/// A complete skill definition that can be loaded from a JSON file
public struct SkillDefinition: Codable, Identifiable, Sendable {
    /// Unique identifier (e.g., "home.meal_planning.v1")
    public let id: String
    /// Human-readable name
    public let name: String
    /// Version string (semver)
    public let version: String
    /// Category for organization
    public let category: String
    /// Short description for UI
    public let shortDescription: String
    /// Full description with usage details
    public let fullDescription: String
    /// Author/maintainer
    public let author: String?
    /// Tags for search
    public let tags: [String]
    /// Required capabilities (MCP tools, APIs, etc.)
    public let capabilities: SkillCapabilities
    /// Tool execution sequence for deterministic execution
    public let toolSequence: [ToolStep]
    /// Fallback sequence when primary tools unavailable
    public let fallbackSequence: [ToolStep]?
    /// Approval gates for high-risk actions
    public let approvalGates: ApprovalGates?
    /// Example prompts that trigger this skill
    public let examplePrompts: [String]
    /// Voice trigger phrases
    public let voiceTriggers: [String]
    /// Proactive scheduling configuration
    public let proactiveConfig: ProactiveConfig?
    /// Safety constraints
    public let safetyConstraints: SafetyConstraints?
    /// UI configuration
    public let uiConfig: SkillUIConfig?

    public init(
        id: String,
        name: String,
        version: String = "1.0.0",
        category: String,
        shortDescription: String,
        fullDescription: String = "",
        author: String? = nil,
        tags: [String] = [],
        capabilities: SkillCapabilities = SkillCapabilities(),
        toolSequence: [ToolStep] = [],
        fallbackSequence: [ToolStep]? = nil,
        approvalGates: ApprovalGates? = nil,
        examplePrompts: [String] = [],
        voiceTriggers: [String] = [],
        proactiveConfig: ProactiveConfig? = nil,
        safetyConstraints: SafetyConstraints? = nil,
        uiConfig: SkillUIConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.category = category
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription.isEmpty ? shortDescription : fullDescription
        self.author = author
        self.tags = tags
        self.capabilities = capabilities
        self.toolSequence = toolSequence
        self.fallbackSequence = fallbackSequence
        self.approvalGates = approvalGates
        self.examplePrompts = examplePrompts
        self.voiceTriggers = voiceTriggers
        self.proactiveConfig = proactiveConfig
        self.safetyConstraints = safetyConstraints
        self.uiConfig = uiConfig
    }
}

// MARK: - Skill Capabilities

/// Required capabilities for a skill to function
public struct SkillCapabilities: Codable, Sendable {
    /// MCP server requirements
    public let mcpServers: [MCPServerRequirement]
    /// Built-in tool requirements
    public let builtinTools: [String]
    /// Optional capabilities that enhance but aren't required
    public let optional: [CapabilityRequirement]

    public init(
        mcpServers: [MCPServerRequirement] = [],
        builtinTools: [String] = [],
        optional: [CapabilityRequirement] = []
    ) {
        self.mcpServers = mcpServers
        self.builtinTools = builtinTools
        self.optional = optional
    }
}

/// MCP server requirement
public struct MCPServerRequirement: Codable, Sendable {
    /// Provider type: "rube", "standalone", "official"
    public let provider: String
    /// Server name (e.g., "openweathermap-mcp", "exa-mcp")
    public let server: String?
    /// Required tools from this server
    public let tools: [String]
    /// Configuration for this server
    public let config: [String: String]?
    /// Whether this server is required or optional
    public let required: Bool

    public init(
        provider: String,
        server: String? = nil,
        tools: [String],
        config: [String: String]? = nil,
        required: Bool = true
    ) {
        self.provider = provider
        self.server = server
        self.tools = tools
        self.config = config
        self.required = required
    }
}

/// Generic capability requirement
public struct CapabilityRequirement: Codable, Sendable {
    /// Type: "mcp", "builtin", "api"
    public let type: String
    /// Provider name
    public let provider: String?
    /// Tool names
    public let tools: [String]
    /// Usage description
    public let usage: String?

    public init(
        type: String,
        provider: String? = nil,
        tools: [String],
        usage: String? = nil
    ) {
        self.type = type
        self.provider = provider
        self.tools = tools
        self.usage = usage
    }
}

// MARK: - Tool Execution

/// A single step in the tool execution sequence
public struct ToolStep: Codable, Sendable, Identifiable {
    public var id: Int { step }

    /// Step number (1-indexed)
    public let step: Int
    /// Tool name to invoke (e.g., "google_calendar.create_event")
    public let tool: String
    /// Parameter names to extract from context
    public let params: [String]
    /// Static parameter values
    public let staticParams: [String: AnyCodable]?
    /// Whether user approval is required before this step
    public let requiresApproval: Bool
    /// Condition for execution (e.g., "if weather.condition == 'rain'")
    public let condition: String?
    /// Description of what this step does
    public let description: String?
    /// How to handle errors
    public let onError: ErrorHandling?

    public init(
        step: Int,
        tool: String,
        params: [String] = [],
        staticParams: [String: AnyCodable]? = nil,
        requiresApproval: Bool = false,
        condition: String? = nil,
        description: String? = nil,
        onError: ErrorHandling? = nil
    ) {
        self.step = step
        self.tool = tool
        self.params = params
        self.staticParams = staticParams
        self.requiresApproval = requiresApproval
        self.condition = condition
        self.description = description
        self.onError = onError
    }
}

/// Error handling configuration
public struct ErrorHandling: Codable, Sendable {
    /// Action: "skip", "retry", "fallback", "abort"
    public let action: String
    /// Number of retries (if action == "retry")
    public let retries: Int?
    /// Fallback tool to use (if action == "fallback")
    public let fallbackTool: String?
    /// Message to show user
    public let userMessage: String?

    public init(
        action: String,
        retries: Int? = nil,
        fallbackTool: String? = nil,
        userMessage: String? = nil
    ) {
        self.action = action
        self.retries = retries
        self.fallbackTool = fallbackTool
        self.userMessage = userMessage
    }
}

// MARK: - Approval Gates

/// Configuration for actions requiring user approval
public struct ApprovalGates: Codable, Sendable {
    /// High-risk actions that always require approval
    public let highRisk: [String]
    /// Medium-risk actions that require approval in certain contexts
    public let mediumRisk: [String]
    /// Valid approval responses
    public let validResponses: [String]
    /// Timeout in seconds before auto-declining
    public let timeoutSeconds: Int?

    public init(
        highRisk: [String] = [],
        mediumRisk: [String] = [],
        validResponses: [String] = ["yes", "approved", "go ahead", "confirm"],
        timeoutSeconds: Int? = 30
    ) {
        self.highRisk = highRisk
        self.mediumRisk = mediumRisk
        self.validResponses = validResponses
        self.timeoutSeconds = timeoutSeconds
    }
}

// MARK: - Proactive Configuration

/// Configuration for proactive/scheduled skill execution
public struct ProactiveConfig: Codable, Sendable {
    /// Whether this skill can run proactively
    public let enabled: Bool
    /// Schedule type: "daily", "weekly", "cron"
    public let scheduleType: String?
    /// Schedule value (e.g., "08:00" for daily, "0 8 * * 1-5" for cron)
    public let scheduleValue: String?
    /// Trigger conditions beyond schedule
    public let triggerConditions: [TriggerCondition]?

    public init(
        enabled: Bool = false,
        scheduleType: String? = nil,
        scheduleValue: String? = nil,
        triggerConditions: [TriggerCondition]? = nil
    ) {
        self.enabled = enabled
        self.scheduleType = scheduleType
        self.scheduleValue = scheduleValue
        self.triggerConditions = triggerConditions
    }
}

/// A condition that can trigger a proactive skill
public struct TriggerCondition: Codable, Sendable {
    /// Type: "time", "location", "event", "sensor"
    public let type: String
    /// Condition expression
    public let condition: String
    /// Description
    public let description: String?

    public init(type: String, condition: String, description: String? = nil) {
        self.type = type
        self.condition = condition
        self.description = description
    }
}

// MARK: - Safety Constraints

/// Safety constraints for skill execution
public struct SafetyConstraints: Codable, Sendable {
    /// Actions that are never allowed
    public let prohibitedActions: [String]
    /// Required disclaimers to show
    public let requiredDisclaimers: [String]
    /// Emergency detection keywords
    public let emergencyKeywords: [String]
    /// Emergency action (e.g., "prompt_911")
    public let emergencyAction: String?
    /// Maximum cost per execution (USD)
    public let maxCostUsd: Double?
    /// Whether to require adult supervision
    public let requiresAdultSupervision: Bool

    public init(
        prohibitedActions: [String] = [],
        requiredDisclaimers: [String] = [],
        emergencyKeywords: [String] = [],
        emergencyAction: String? = nil,
        maxCostUsd: Double? = nil,
        requiresAdultSupervision: Bool = false
    ) {
        self.prohibitedActions = prohibitedActions
        self.requiredDisclaimers = requiredDisclaimers
        self.emergencyKeywords = emergencyKeywords
        self.emergencyAction = emergencyAction
        self.maxCostUsd = maxCostUsd
        self.requiresAdultSupervision = requiresAdultSupervision
    }
}

// MARK: - UI Configuration

/// UI configuration for the skill card
public struct SkillUIConfig: Codable, Sendable {
    /// Icon name (SF Symbol)
    public let icon: String
    /// Accent color hex
    public let accentColor: String?
    /// Badge labels to show
    public let badges: [String]
    /// Custom card background
    public let cardStyle: String?

    public init(
        icon: String = "brain",
        accentColor: String? = nil,
        badges: [String] = [],
        cardStyle: String? = nil
    ) {
        self.icon = icon
        self.accentColor = accentColor
        self.badges = badges
        self.cardStyle = cardStyle
    }
}

// MARK: - AnyCodable Helper

/// Type-erased codable wrapper for dynamic JSON values
public struct AnyCodable: Codable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
