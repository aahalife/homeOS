import Foundation

// MARK: - Task / Reminder

public struct HomeTask: Codable, Sendable, Identifiable {
    public var id: String
    public var type: TaskType
    public var title: String
    public var description: String?
    public var assignee: String?     // member ID
    public var dueDate: String?      // "YYYY-MM-DD"
    public var dueTime: String?      // "HH:MM"
    public var status: TaskStatus
    public var priority: TaskPriority
    public var recurring: RecurringPattern?
    public var createdAt: String
    public var completedAt: String?
    public var metadata: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        type: TaskType,
        title: String,
        description: String? = nil,
        assignee: String? = nil,
        dueDate: String? = nil,
        dueTime: String? = nil,
        status: TaskStatus = .pending,
        priority: TaskPriority = .normal,
        recurring: RecurringPattern? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        completedAt: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.assignee = assignee
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.status = status
        self.priority = priority
        self.recurring = recurring
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.metadata = metadata
    }
}

public enum TaskType: String, Codable, Sendable {
    case chore
    case reminder
    case homework
    case medication
    case appointment
    case errand
    case maintenance
    case other
}

public enum TaskStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case completed
    case overdue
    case cancelled
}

public enum TaskPriority: String, Codable, Sendable {
    case low
    case normal
    case high
    case urgent
}
