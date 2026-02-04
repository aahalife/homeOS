import Foundation

// MARK: - Health Profile

public struct HealthProfile: Codable, Sendable {
    public var memberId: String
    public var conditions: [String]?
    public var medications: [Medication]
    public var allergies: [String]?
    public var primaryDoctor: DoctorInfo?
    public var insurance: InsuranceInfo?
    public var appointments: [CalendarEvent]?
    
    public init(
        memberId: String,
        conditions: [String]? = nil,
        medications: [Medication] = [],
        allergies: [String]? = nil,
        primaryDoctor: DoctorInfo? = nil,
        insurance: InsuranceInfo? = nil,
        appointments: [CalendarEvent]? = nil
    ) {
        self.memberId = memberId
        self.conditions = conditions
        self.medications = medications
        self.allergies = allergies
        self.primaryDoctor = primaryDoctor
        self.insurance = insurance
        self.appointments = appointments
    }
    
    /// Medications due at a given time (HH:MM format)
    public func medicationsDue(at time: String) -> [Medication] {
        medications.filter { $0.times.contains(time) }
    }
    
    /// Check if any prescriptions need refill within N days
    public func refillsNeeded(withinDays days: Int, from date: Date = Date()) -> [Medication] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: date)!
        
        return medications.filter { med in
            guard let refillStr = med.refillDate, let refillDate = formatter.date(from: refillStr) else { return false }
            return refillDate <= cutoff
        }
    }
}

public struct DoctorInfo: Codable, Sendable {
    public var name: String
    public var specialty: String?
    public var phone: String?
    public var address: String?
    
    public init(name: String, specialty: String? = nil, phone: String? = nil, address: String? = nil) {
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.address = address
    }
}

public struct InsuranceInfo: Codable, Sendable {
    public var provider: String
    public var memberId: String
    public var groupNumber: String?
    public var phone: String?
    
    public init(provider: String, memberId: String, groupNumber: String? = nil, phone: String? = nil) {
        self.provider = provider
        self.memberId = memberId
        self.groupNumber = groupNumber
        self.phone = phone
    }
}

// MARK: - Wellness Tracking

public struct WellnessLog: Codable, Sendable {
    public var memberId: String
    public var date: String  // "YYYY-MM-DD"
    public var hydrationOz: Double?
    public var steps: Int?
    public var sleepHours: Double?
    public var screenTimeMinutes: Int?
    public var mood: Int?  // 1-10
    public var notes: String?
    
    public init(
        memberId: String,
        date: String,
        hydrationOz: Double? = nil,
        steps: Int? = nil,
        sleepHours: Double? = nil,
        screenTimeMinutes: Int? = nil,
        mood: Int? = nil,
        notes: String? = nil
    ) {
        self.memberId = memberId
        self.date = date
        self.hydrationOz = hydrationOz
        self.steps = steps
        self.sleepHours = sleepHours
        self.screenTimeMinutes = screenTimeMinutes
        self.mood = mood
        self.notes = notes
    }
}

// MARK: - Habit Tracking

public struct Habit: Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var memberId: String
    public var atomicVersion: String    // The tiny 2-minute version
    public var cue: String              // "After I [existing habit]"
    public var reward: String?
    public var stage: HabitStage
    public var currentStreak: Int
    public var bestStreak: Int
    public var completionLog: [String]  // dates completed: ["2024-01-15", ...]
    public var createdAt: String
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        memberId: String,
        atomicVersion: String,
        cue: String,
        reward: String? = nil,
        stage: HabitStage = .preparation,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        completionLog: [String] = [],
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.name = name
        self.memberId = memberId
        self.atomicVersion = atomicVersion
        self.cue = cue
        self.reward = reward
        self.stage = stage
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.completionLog = completionLog
        self.createdAt = createdAt
    }
    
    /// Success rate as percentage (0-100)
    public var successRate: Double {
        guard !completionLog.isEmpty else { return 0 }
        let daysSinceCreation = max(1, completionLog.count)
        return Double(completionLog.count) / Double(daysSinceCreation) * 100
    }
}

public enum HabitStage: String, Codable, Sendable {
    case contemplation  // Thinking about it
    case preparation    // Decided, planning
    case action         // Doing it
    case maintenance    // Sustained
}
