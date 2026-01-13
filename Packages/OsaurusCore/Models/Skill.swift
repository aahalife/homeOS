//
//  Skill.swift
//  OsaurusCore
//
//  Defines a Skill - an AI-powered capability that can be executed by the assistant
//  to help with family tasks like meal planning, scheduling, and more.
//

import Foundation

// MARK: - Skill Category

/// Categories for organizing skills
public enum SkillCategory: String, Codable, CaseIterable, Sendable {
    case utilities = "Utilities"
    case healthcare = "Healthcare"
    case mealPlanning = "Meal Planning"
    case family = "Family"
    case home = "Home"
    case education = "Education"
    case wellness = "Wellness"
    case services = "Services"
    case personal = "Personal"
    case other = "Other"

    public var icon: String {
        switch self {
        case .utilities: return "wrench.and.screwdriver"
        case .healthcare: return "heart.text.square"
        case .mealPlanning: return "fork.knife"
        case .family: return "figure.2.and.child.holdinghands"
        case .home: return "house"
        case .education: return "book"
        case .wellness: return "figure.mind.and.body"
        case .services: return "person.2"
        case .personal: return "person"
        case .other: return "square.grid.2x2"
        }
    }
}

// MARK: - Skill Status

/// Current status of a skill
public enum SkillStatus: String, Codable, Sendable {
    case available = "Available"
    case requiresSetup = "Requires Setup"
    case disabled = "Disabled"
    case updating = "Updating"

    public var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .requiresSetup: return "exclamationmark.triangle.fill"
        case .disabled: return "xmark.circle.fill"
        case .updating: return "arrow.clockwise"
        }
    }

    public var color: String {
        switch self {
        case .available: return "green"
        case .requiresSetup: return "orange"
        case .disabled: return "gray"
        case .updating: return "blue"
        }
    }
}

// MARK: - Skill Source

/// Where the skill came from
public enum SkillSource: String, Codable, Sendable {
    case bundled = "Bundled"
    case community = "Community"
    case userCreated = "User Created"

    public var icon: String {
        switch self {
        case .bundled: return "shippingbox.fill"
        case .community: return "globe"
        case .userCreated: return "person.crop.circle.badge.plus"
        }
    }
}

// MARK: - Skill Badges

/// Badges that can be displayed on skill cards
public struct SkillBadges: Codable, Sendable, Equatable {
    /// Skill is bundled with the app
    public var isBundled: Bool
    /// Skill requires network connectivity
    public var requiresNetwork: Bool
    /// Skill needs additional setup (API keys, etc.)
    public var requiresSetup: Bool
    /// Skill is designed for family use
    public var isFamily: Bool
    /// Skill can run proactively (scheduled/triggered)
    public var isProactive: Bool

    public init(
        isBundled: Bool = false,
        requiresNetwork: Bool = false,
        requiresSetup: Bool = false,
        isFamily: Bool = false,
        isProactive: Bool = false
    ) {
        self.isBundled = isBundled
        self.requiresNetwork = requiresNetwork
        self.requiresSetup = requiresSetup
        self.isFamily = isFamily
        self.isProactive = isProactive
    }

    /// All active badge labels
    public var activeBadges: [(label: String, icon: String, color: String)] {
        var badges: [(String, String, String)] = []
        if isBundled { badges.append(("Bundled", "shippingbox.fill", "blue")) }
        if requiresNetwork { badges.append(("Network", "wifi", "purple")) }
        if requiresSetup { badges.append(("Setup Required", "gear", "orange")) }
        if isFamily { badges.append(("Family", "figure.2.and.child.holdinghands", "green")) }
        if isProactive { badges.append(("Proactive", "bolt.fill", "yellow")) }
        return badges
    }
}

// MARK: - Skill Tool Requirement

/// A tool or MCP server required by a skill
public struct SkillToolRequirement: Codable, Sendable, Equatable, Identifiable {
    public var id: String { toolName }

    /// Name of the required tool (e.g., "google_calendar", "osaurus.browser")
    public let toolName: String
    /// Human-readable description of what this tool is used for
    public let purpose: String
    /// Whether this tool is required or optional
    public let isRequired: Bool
    /// MCP server that provides this tool (if any)
    public let mcpServer: String?

    public init(
        toolName: String,
        purpose: String,
        isRequired: Bool = true,
        mcpServer: String? = nil
    ) {
        self.toolName = toolName
        self.purpose = purpose
        self.isRequired = isRequired
        self.mcpServer = mcpServer
    }
}

// MARK: - Skill Trigger

/// Ways a skill can be triggered
public enum SkillTrigger: Codable, Sendable, Equatable {
    /// Triggered by user voice command
    case voice(phrases: [String])
    /// Triggered by schedule
    case scheduled(frequency: String)
    /// Triggered by another skill
    case chainedFrom(skillId: String)
    /// Triggered manually via UI
    case manual

    public var displayName: String {
        switch self {
        case .voice: return "Voice"
        case .scheduled: return "Scheduled"
        case .chainedFrom: return "Chained"
        case .manual: return "Manual"
        }
    }

    public var icon: String {
        switch self {
        case .voice: return "waveform"
        case .scheduled: return "calendar.badge.clock"
        case .chainedFrom: return "link"
        case .manual: return "hand.tap"
        }
    }
}

// MARK: - Skill Model

/// A skill that can be executed by the AI assistant
public struct Skill: Codable, Identifiable, Sendable, Equatable {
    /// Unique identifier for the skill
    public let id: UUID
    /// Internal name/slug for the skill
    public let slug: String
    /// Display name of the skill
    public var name: String
    /// Brief description shown on skill cards
    public var shortDescription: String
    /// Full description shown in detail view
    public var fullDescription: String
    /// Category for organization
    public var category: SkillCategory
    /// Current status
    public var status: SkillStatus
    /// Where the skill came from
    public let source: SkillSource
    /// Badges to display
    public var badges: SkillBadges
    /// Tools required by this skill
    public var requiredTools: [SkillToolRequirement]
    /// Ways this skill can be triggered
    public var triggers: [SkillTrigger]
    /// Example prompts that would activate this skill
    public var examplePrompts: [String]
    /// Version of the skill
    public var version: String
    /// Author of the skill
    public var author: String?
    /// Whether the skill is enabled
    public var isEnabled: Bool
    /// When the skill was installed
    public let installedAt: Date
    /// When the skill was last updated
    public var updatedAt: Date
    /// Last time the skill was used
    public var lastUsedAt: Date?
    /// Number of times the skill has been used
    public var usageCount: Int

    public init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        shortDescription: String,
        fullDescription: String = "",
        category: SkillCategory = .other,
        status: SkillStatus = .available,
        source: SkillSource = .bundled,
        badges: SkillBadges = SkillBadges(),
        requiredTools: [SkillToolRequirement] = [],
        triggers: [SkillTrigger] = [.manual],
        examplePrompts: [String] = [],
        version: String = "1.0.0",
        author: String? = nil,
        isEnabled: Bool = true,
        installedAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        usageCount: Int = 0
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription.isEmpty ? shortDescription : fullDescription
        self.category = category
        self.status = status
        self.source = source
        self.badges = badges
        self.requiredTools = requiredTools
        self.triggers = triggers
        self.examplePrompts = examplePrompts
        self.version = version
        self.author = author
        self.isEnabled = isEnabled
        self.installedAt = installedAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
    }

    // MARK: - Computed Properties

    /// Whether all required tools are available
    public var hasAllRequiredTools: Bool {
        // TODO: Check against ToolRegistry
        return status == .available
    }

    /// Missing required tools
    public var missingTools: [SkillToolRequirement] {
        // TODO: Check against ToolRegistry
        return []
    }
}

// MARK: - Sample Skills

extension Skill {
    /// Sample bundled skills for development/testing
    public static var sampleSkills: [Skill] {
        [
            Skill(
                slug: "meal-planning",
                name: "Meal Planning",
                shortDescription: "Plan weekly meals and generate shopping lists",
                fullDescription: "Help plan meals for the week based on dietary preferences, generate shopping lists, and sync with your favorite grocery services.",
                category: .mealPlanning,
                status: .available,
                source: .bundled,
                badges: SkillBadges(isBundled: true, requiresNetwork: true, isFamily: true),
                requiredTools: [
                    SkillToolRequirement(toolName: "plantoeat", purpose: "Meal planning and recipes", mcpServer: "rube"),
                    SkillToolRequirement(toolName: "instacart", purpose: "Grocery ordering", isRequired: false, mcpServer: "rube")
                ],
                triggers: [.manual, .voice(phrases: ["plan meals", "what's for dinner"])],
                examplePrompts: ["Plan meals for this week", "What should we have for dinner?", "Make a shopping list"],
                author: "Oi My AI"
            ),
            Skill(
                slug: "family-calendar",
                name: "Family Calendar",
                shortDescription: "Manage family events and schedules",
                fullDescription: "Keep track of family events, school activities, appointments, and more. Syncs with Apple Calendar and Google Calendar.",
                category: .family,
                status: .available,
                source: .bundled,
                badges: SkillBadges(isBundled: true, requiresNetwork: true, isFamily: true, isProactive: true),
                requiredTools: [
                    SkillToolRequirement(toolName: "apple_calendar", purpose: "Native calendar access"),
                    SkillToolRequirement(toolName: "google_calendar", purpose: "Google Calendar sync", isRequired: false, mcpServer: "rube")
                ],
                triggers: [.manual, .voice(phrases: ["check calendar", "what's on the schedule"]), .scheduled(frequency: "Daily")],
                examplePrompts: ["What's on the calendar today?", "Schedule a dentist appointment", "When is soccer practice?"],
                author: "Oi My AI"
            ),
            Skill(
                slug: "healthcare",
                name: "Healthcare Assistant",
                shortDescription: "Manage medications, appointments, and health records",
                fullDescription: "Track medications, schedule doctor appointments, store health records, and get reminders for prescriptions.",
                category: .healthcare,
                status: .requiresSetup,
                source: .bundled,
                badges: SkillBadges(isBundled: true, requiresNetwork: true, requiresSetup: true, isFamily: true),
                requiredTools: [
                    SkillToolRequirement(toolName: "apple_calendar", purpose: "Appointment scheduling"),
                    SkillToolRequirement(toolName: "osaurus.filesystem", purpose: "Health record storage")
                ],
                triggers: [.manual, .voice(phrases: ["medication reminder", "doctor appointment"])],
                examplePrompts: ["Remind me to take my medication", "Schedule a checkup", "When is my next appointment?"],
                author: "Oi My AI"
            ),
            Skill(
                slug: "hire-helper",
                name: "Hire Helper",
                shortDescription: "Find and book local service providers",
                fullDescription: "Search for and book local service providers for tasks like cleaning, repairs, lawn care, and more using TaskRabbit, Nextdoor, and other services.",
                category: .services,
                status: .requiresSetup,
                source: .bundled,
                badges: SkillBadges(isBundled: true, requiresNetwork: true, requiresSetup: true),
                requiredTools: [
                    SkillToolRequirement(toolName: "taskrabbit", purpose: "Task booking", mcpServer: "rube"),
                    SkillToolRequirement(toolName: "nextdoor", purpose: "Local recommendations", isRequired: false, mcpServer: "rube"),
                    SkillToolRequirement(toolName: "exa", purpose: "Web search for providers", mcpServer: "exa-mcp")
                ],
                triggers: [.manual, .voice(phrases: ["find a handyman", "book a cleaner"])],
                examplePrompts: ["Find someone to mow the lawn", "I need a plumber", "Book a house cleaner for Saturday"],
                author: "Oi My AI"
            ),
            Skill(
                slug: "weather",
                name: "Weather",
                shortDescription: "Get weather forecasts and alerts",
                fullDescription: "Check current weather conditions, forecasts, and severe weather alerts for your location and family members' locations.",
                category: .utilities,
                status: .available,
                source: .bundled,
                badges: SkillBadges(isBundled: true, requiresNetwork: true, isProactive: true),
                requiredTools: [
                    SkillToolRequirement(toolName: "openweathermap", purpose: "Weather data", mcpServer: "openweathermap-mcp")
                ],
                triggers: [.manual, .voice(phrases: ["weather", "forecast"]), .scheduled(frequency: "Daily")],
                examplePrompts: ["What's the weather?", "Will it rain tomorrow?", "Weekend forecast"],
                author: "Oi My AI"
            )
        ]
    }
}
