import SwiftUI

// MARK: - Task Models

struct UserTask: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: TaskCategory
    let priority: TaskPriority
    let dueDate: Date?
    let createdAt: Date
    let relatedMessageId: UUID?
    let actionRequired: ActionRequired?
    let status: TaskStatus
    let metadata: TaskMetadata?

    enum TaskCategory: String, Codable, CaseIterable {
        case urgent = "Urgent"
        case today = "Today"
        case thisWeek = "This Week"
        case later = "Later"

        var color: Color {
            switch self {
            case .urgent: return .red
            case .today: return .orange
            case .thisWeek: return .blue
            case .later: return .gray
            }
        }

        var icon: String {
            switch self {
            case .urgent: return "exclamationmark.triangle.fill"
            case .today: return "sun.max.fill"
            case .thisWeek: return "calendar"
            case .later: return "clock"
            }
        }
    }

    enum TaskPriority: String, Codable {
        case low
        case medium
        case high
        case critical
    }

    enum TaskStatus: String, Codable {
        case pending
        case approved
        case rejected
        case completed
        case expired
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TaskCategory,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        relatedMessageId: UUID? = nil,
        actionRequired: ActionRequired? = nil,
        status: TaskStatus = .pending,
        metadata: TaskMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.relatedMessageId = relatedMessageId
        self.actionRequired = actionRequired
        self.status = status
        self.metadata = metadata
    }
}

struct ActionRequired: Codable, Hashable {
    let type: ActionType
    let details: String
    let riskLevel: RiskLevel
    let estimatedImpact: String?

    enum ActionType: String, Codable {
        case approval
        case confirmation
        case input
        case review
    }

    enum RiskLevel: String, Codable {
        case low
        case medium
        case high
    }
}

struct TaskMetadata: Codable, Hashable {
    let estimatedDuration: TimeInterval?
    let dependencies: [UUID]?
    let tags: [String]?
    let source: String?
    let canBatch: Bool
}

// MARK: - Approval Models

struct ApprovalRequest: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let actionType: ApprovalActionType
    let riskLevel: ActionRequired.RiskLevel
    let details: [ApprovalDetail]
    let createdAt: Date
    let expiresAt: Date?
    let status: ApprovalStatus
    let result: ApprovalResult?

    enum ApprovalActionType: String, Codable {
        case booking
        case phoneCall
        case purchase
        case dataSharing
        case scheduling
        case communication
        case other
    }

    enum ApprovalStatus: String, Codable {
        case pending
        case approved
        case rejected
        case expired
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: ApprovalActionType,
        riskLevel: ActionRequired.RiskLevel,
        details: [ApprovalDetail],
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        status: ApprovalStatus = .pending,
        result: ApprovalResult? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.riskLevel = riskLevel
        self.details = details
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.status = status
        self.result = result
    }
}

struct ApprovalDetail: Identifiable, Codable {
    let id: UUID
    let label: String
    let value: String
    let icon: String?
    let important: Bool

    init(
        id: UUID = UUID(),
        label: String,
        value: String,
        icon: String? = nil,
        important: Bool = false
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.icon = icon
        self.important = important
    }
}

struct ApprovalResult: Codable {
    let approved: Bool
    let timestamp: Date
    let note: String?
    let canUndo: Bool
    let undoDeadline: Date?
}

// MARK: - Batch Approval

struct BatchApprovalGroup: Identifiable {
    let id: UUID
    let title: String
    let tasks: [UserTask]
    let category: UserTask.TaskCategory
    let canApproveAll: Bool

    init(
        id: UUID = UUID(),
        title: String,
        tasks: [UserTask],
        category: UserTask.TaskCategory,
        canApproveAll: Bool = true
    ) {
        self.id = id
        self.title = title
        self.tasks = tasks
        self.category = category
        self.canApproveAll = canApproveAll
    }
}
