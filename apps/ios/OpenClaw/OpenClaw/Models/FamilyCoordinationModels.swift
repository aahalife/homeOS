import Foundation

// MARK: - Family Coordination Models

struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var memberId: UUID?
    var memberName: String?
    var location: String?
    var isAllDay: Bool = false
    var recurrence: String?
    var externalId: String?
    var source: CalendarSource = .local
}

enum CalendarSource: String, Codable {
    case local, google, apple
}

struct BroadcastMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var senderId: UUID
    var senderName: String
    var message: String
    var recipients: [UUID]
    var timestamp: Date = Date()
    var readBy: [UUID] = []
    var replies: [BroadcastReply] = []
}

struct BroadcastReply: Identifiable, Codable {
    var id: UUID = UUID()
    var senderId: UUID
    var senderName: String
    var message: String
    var timestamp: Date = Date()
}

struct Chore: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var assignedTo: UUID
    var assignedToName: String
    var assignedBy: UUID
    var dueDate: Date
    var points: Int
    var status: ChoreStatus = .assigned
    var completedAt: Date?
    var verifiedBy: UUID?
}

enum ChoreStatus: String, Codable {
    case assigned, inProgress, completed, verified, overdue
}

struct FamilyMemberLocation: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var memberName: String
    var latitude: Double
    var longitude: Double
    var placeName: String?
    var batteryLevel: Double?
    var lastUpdated: Date = Date()
    var sharingEnabled: Bool = true
}

struct ScheduleConflict: Identifiable, Codable {
    var id: UUID = UUID()
    var event1: CalendarEvent
    var event2: CalendarEvent
    var memberName: String
    var resolution: String?
}

// MARK: - Mental Load Models

struct MorningBriefing: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var weather: WeatherSummary?
    var calendarHighlights: [CalendarEvent]
    var urgentTasks: [TaskItem]
    var mealPlanToday: PlannedMeal?
    var reminders: [String]
    var motivationalNote: String?
}

struct EveningWindDown: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var completedTasks: [TaskItem]
    var tomorrowPriorities: [TaskItem]
    var tomorrowMeal: PlannedMeal?
    var suggestions: [String]
    var reflectionPrompt: String?
}

struct TaskItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var skill: SkillType
    var priority: Priority
    var dueDate: Date?
    var isCompleted: Bool = false
    var assignedTo: String?
}

struct WeatherSummary: Codable {
    var temperatureHigh: Double
    var temperatureLow: Double
    var description: String
    var precipitation: Bool
    var advisory: String?
}

struct WeeklyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var weekStartDate: Date
    var calendarEvents: [CalendarEvent]
    var mealPlan: MealPlan?
    var chores: [Chore]
    var appointments: [Appointment]
    var reminders: [ProactiveReminder]
    var conflicts: [ScheduleConflict]
}

struct ProactiveReminder: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var triggerDate: Date
    var skill: SkillType
    var priority: Priority
    var actionable: Bool = true
    var actionLabel: String?
}
