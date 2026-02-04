import Foundation

// MARK: - Calendar Event

public struct CalendarEvent: Codable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var date: String          // "YYYY-MM-DD"
    public var time: String?         // "HH:MM"
    public var duration: Int?        // minutes
    public var location: String?
    public var type: EventType?
    public var notes: String?
    public var reminders: [String]?  // ["2h", "1d"]
    public var participants: [String]? // member IDs
    public var recurring: RecurringPattern?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        date: String,
        time: String? = nil,
        duration: Int? = nil,
        location: String? = nil,
        type: EventType? = nil,
        notes: String? = nil,
        reminders: [String]? = nil,
        participants: [String]? = nil,
        recurring: RecurringPattern? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.time = time
        self.duration = duration
        self.location = location
        self.type = type
        self.notes = notes
        self.reminders = reminders
        self.participants = participants
        self.recurring = recurring
    }
}

public enum EventType: String, Codable, Sendable {
    case medical
    case school
    case activity
    case restaurant
    case maintenance
    case work
    case family
    case reminder
    case other
}

public struct RecurringPattern: Codable, Sendable {
    public var frequency: RecurringFrequency
    public var interval: Int   // every N [frequency]
    public var endDate: String? // "YYYY-MM-DD"
    
    public init(frequency: RecurringFrequency, interval: Int = 1, endDate: String? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
    }
}

public enum RecurringFrequency: String, Codable, Sendable {
    case daily, weekly, monthly, yearly
}
