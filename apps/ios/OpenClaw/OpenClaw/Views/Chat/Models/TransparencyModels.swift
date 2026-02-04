import SwiftUI

// MARK: - Transparency Models

struct ActivityLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let action: String
    let category: ActivityCategory
    let details: String?
    let apiCalls: [APICall]?
    let dataUsed: [DataUsage]?
    let reasoning: String?
    let outcome: String?

    enum ActivityCategory: String, Codable, CaseIterable {
        case communication = "Communication"
        case scheduling = "Scheduling"
        case health = "Health"
        case meal = "Meal Planning"
        case education = "Education"
        case home = "Home Management"
        case api = "API Calls"
        case data = "Data Access"
        case other = "Other"

        var icon: String {
            switch self {
            case .communication: return "bubble.left.and.bubble.right"
            case .scheduling: return "calendar"
            case .health: return "heart.fill"
            case .meal: return "fork.knife"
            case .education: return "book.fill"
            case .home: return "house.fill"
            case .api: return "network"
            case .data: return "lock.shield"
            case .other: return "ellipsis.circle"
            }
        }

        var color: Color {
            switch self {
            case .communication: return .blue
            case .scheduling: return .orange
            case .health: return .red
            case .meal: return .green
            case .education: return .purple
            case .home: return .brown
            case .api: return .cyan
            case .data: return .indigo
            case .other: return .gray
            }
        }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: String,
        category: ActivityCategory,
        details: String? = nil,
        apiCalls: [APICall]? = nil,
        dataUsed: [DataUsage]? = nil,
        reasoning: String? = nil,
        outcome: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.category = category
        self.details = details
        self.apiCalls = apiCalls
        self.dataUsed = dataUsed
        self.reasoning = reasoning
        self.outcome = outcome
    }
}

struct APICall: Identifiable, Codable {
    let id: UUID
    let service: String
    let endpoint: String
    let purpose: String
    let timestamp: Date
    let responseTime: TimeInterval?
    let success: Bool
    let dataExchanged: String?

    init(
        id: UUID = UUID(),
        service: String,
        endpoint: String,
        purpose: String,
        timestamp: Date = Date(),
        responseTime: TimeInterval? = nil,
        success: Bool = true,
        dataExchanged: String? = nil
    ) {
        self.id = id
        self.service = service
        self.endpoint = endpoint
        self.purpose = purpose
        self.timestamp = timestamp
        self.responseTime = responseTime
        self.success = success
        self.dataExchanged = dataExchanged
    }
}

struct DataUsage: Identifiable, Codable {
    let id: UUID
    let dataType: String
    let purpose: String
    let timestamp: Date
    let sensitivity: DataSensitivity
    let retention: String?

    enum DataSensitivity: String, Codable {
        case low
        case medium
        case high
        case critical

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }

    init(
        id: UUID = UUID(),
        dataType: String,
        purpose: String,
        timestamp: Date = Date(),
        sensitivity: DataSensitivity,
        retention: String? = nil
    ) {
        self.id = id
        self.dataType = dataType
        self.purpose = purpose
        self.timestamp = timestamp
        self.sensitivity = sensitivity
        self.retention = retention
    }
}

struct DailySummary: Identifiable {
    let id: UUID
    let date: Date
    let keyActions: [KeyAction]
    let plannedActions: [PlannedAction]
    let stats: DayStats

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        keyActions: [KeyAction],
        plannedActions: [PlannedAction],
        stats: DayStats
    ) {
        self.id = id
        self.date = date
        self.keyActions = keyActions
        self.plannedActions = plannedActions
        self.stats = stats
    }
}

struct KeyAction: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
    let timestamp: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        color: Color,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.timestamp = timestamp
    }
}

struct PlannedAction: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let scheduledFor: Date
    let icon: String
    let requiresApproval: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        scheduledFor: Date,
        icon: String,
        requiresApproval: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.scheduledFor = scheduledFor
        self.icon = icon
        self.requiresApproval = requiresApproval
    }
}

struct DayStats {
    let actionsCompleted: Int
    let apiCallsMade: Int
    let dataPointsAccessed: Int
    let automationsSaved: String
    let trustScore: Double // 0-100

    init(
        actionsCompleted: Int = 0,
        apiCallsMade: Int = 0,
        dataPointsAccessed: Int = 0,
        automationsSaved: String = "0 min",
        trustScore: Double = 95.0
    ) {
        self.actionsCompleted = actionsCompleted
        self.apiCallsMade = apiCallsMade
        self.dataPointsAccessed = dataPointsAccessed
        self.automationsSaved = automationsSaved
        self.trustScore = trustScore
    }
}

// MARK: - Privacy Controls

struct PrivacySettings: Codable {
    var allowDataCollection: Bool
    var allowAPILogging: Bool
    var allowActivityTracking: Bool
    var dataRetentionDays: Int
    var requireApprovalForSensitiveData: Bool
    var shareUsageStatistics: Bool

    init(
        allowDataCollection: Bool = true,
        allowAPILogging: Bool = true,
        allowActivityTracking: Bool = true,
        dataRetentionDays: Int = 30,
        requireApprovalForSensitiveData: Bool = true,
        shareUsageStatistics: Bool = false
    ) {
        self.allowDataCollection = allowDataCollection
        self.allowAPILogging = allowAPILogging
        self.allowActivityTracking = allowActivityTracking
        self.dataRetentionDays = dataRetentionDays
        self.requireApprovalForSensitiveData = requireApprovalForSensitiveData
        self.shareUsageStatistics = shareUsageStatistics
    }
}
