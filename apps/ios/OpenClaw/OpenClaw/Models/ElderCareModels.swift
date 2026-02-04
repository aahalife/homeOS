import Foundation

// MARK: - Elder Care Models

struct ElderCareProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var memberName: String
    var phoneNumber: String?
    var checkInSchedule: CheckInSchedule
    var medications: [Medication] = []
    var healthConditions: [String] = []
    var emergencyContacts: [EmergencyContact] = []
    var musicPreferences: MusicPreferences?
    var checkInHistory: [CheckInLog] = []
}

struct CheckInSchedule: Codable {
    var morningEnabled: Bool = true
    var morningTime: String = "09:00"
    var eveningEnabled: Bool = true
    var eveningTime: String = "18:00"
    var method: CheckInMethod = .notification

    var dailyCount: Int {
        (morningEnabled ? 1 : 0) + (eveningEnabled ? 1 : 0)
    }
}

enum CheckInMethod: String, Codable {
    case voiceCall = "Voice Call"
    case notification = "Notification"
    case sms = "SMS"
}

struct CheckInLog: Identifiable, Codable {
    var id: UUID = UUID()
    var elderId: UUID
    var timestamp: Date = Date()
    var timeOfDay: TimeOfDay
    var wellnessScore: Int // 1-10
    var mood: MoodRating
    var medicationTaken: Bool
    var conversationSummary: String
    var redFlags: [String] = []
    var notes: String?

    var hasRedFlags: Bool { !redFlags.isEmpty }
}

enum TimeOfDay: String, Codable {
    case morning, afternoon, evening, night
}

enum MoodRating: String, Codable, CaseIterable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case notWell = "Not Well"
    case poor = "Poor"

    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .okay: return "😐"
        case .notWell: return "😕"
        case .poor: return "😟"
        }
    }

    var numericValue: Int {
        switch self {
        case .great: return 5
        case .good: return 4
        case .okay: return 3
        case .notWell: return 2
        case .poor: return 1
        }
    }
}

struct EmergencyContact: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var relationship: String
    var phone: String
    var isPrimary: Bool = false
}

struct MusicPreferences: Codable {
    var favoriteGenres: [String] = ["Oldies", "Classical"]
    var favoriteArtists: [String] = []
    var preferredDecades: [String] = ["1950s", "1960s"]
}

// MARK: - Red Flags

enum RedFlag: String, Codable {
    case confusion = "Confusion/Disorientation"
    case unusualFatigue = "Unusual Fatigue"
    case pain = "Reports Pain"
    case fall = "Recent Fall"
    case missedMedication = "Missed Medication"
    case moodChange = "Significant Mood Change"
    case appetiteLoss = "Loss of Appetite"
    case sleepDisturbance = "Sleep Issues"
    case memoryIssues = "Memory Problems"
    case breathingDifficulty = "Breathing Difficulty"
}

struct ElderCareAlert: Identifiable, Codable {
    var id: UUID = UUID()
    var elderId: UUID
    var elderName: String
    var alertType: ElderAlertType
    var severity: AlertSeverity
    var message: String
    var redFlags: [String]
    var timestamp: Date = Date()
    var acknowledged: Bool = false
}

enum ElderAlertType: String, Codable {
    case redFlagDetected
    case missedCheckIn
    case missedMedication
    case emergencyKeyword
    case weeklyReport
}

enum AlertSeverity: String, Codable {
    case info, warning, urgent, emergency
}

struct WeeklyElderReport: Identifiable, Codable {
    var id: UUID = UUID()
    var elderId: UUID
    var elderName: String
    var weekStartDate: Date
    var weekEndDate: Date
    var totalCheckIns: Int
    var averageWellnessScore: Double
    var averageMood: String
    var medicationAdherence: Double // percentage
    var redFlagCount: Int
    var summary: String
    var recommendations: [String]
}
