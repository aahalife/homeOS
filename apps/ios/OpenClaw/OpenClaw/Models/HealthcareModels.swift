import Foundation

// MARK: - Healthcare Models

struct HealthRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var appointments: [Appointment] = []
    var medications: [Medication] = []
    var immunizations: [Immunization] = []
    var symptomLogs: [SymptomLog] = []
    var insuranceInfo: InsuranceInfo?
}

struct Medication: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var genericName: String?
    var dosage: String
    var frequency: MedicationFrequency
    var prescribedBy: String?
    var refillDate: Date?
    var startDate: Date?
    var warnings: String?
    var activeIngredient: String?
}

enum MedicationFrequency: String, Codable, CaseIterable {
    case onceDaily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case thriceDaily = "Three Times Daily"
    case asNeeded = "As Needed"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var dosesPerDay: Int {
        switch self {
        case .onceDaily: return 1
        case .twiceDaily: return 2
        case .thriceDaily: return 3
        case .asNeeded: return 0
        case .weekly: return 0
        case .monthly: return 0
        }
    }
}

struct Appointment: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var providerName: String
    var specialty: String
    var appointmentDate: Date
    var reason: String
    var status: AppointmentStatus = .scheduled
    var location: String?
    var notes: String?
    var calendarEventId: String?
}

enum AppointmentStatus: String, Codable {
    case scheduled, completed, cancelled, noShow
}

struct Immunization: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var dateAdministered: Date
    var provider: String?
    var nextDueDate: Date?
}

struct SymptomLog: Identifiable, Codable {
    var id: UUID = UUID()
    var memberId: UUID
    var symptoms: [Symptom]
    var timestamp: Date = Date()
    var triageResult: TriageAction?
    var notes: String?
}

struct Symptom: Codable {
    var type: SymptomType
    var severity: SymptomSeverity
    var duration: TimeInterval
    var description: String
    var temperature: Double?

    var isEmergency: Bool {
        switch type {
        case .chestPain, .difficultyBreathing, .severeBleed,
             .lossOfConsciousness, .strokeSymptoms, .severeAllergicReaction:
            return true
        case .headInjury where severity == .high:
            return true
        default:
            return false
        }
    }
}

enum SymptomType: String, Codable {
    case fever, cough, headache, soreThroat, nausea
    case chestPain, difficultyBreathing, severeBleed
    case lossOfConsciousness, strokeSymptoms, severeAllergicReaction
    case rash, stomachPain, backPain, jointPain
    case dizziness, fatigue, earPain
    case headInjury, fall, burn
    case other
}

enum SymptomSeverity: String, Codable, Comparable {
    case low, medium, high

    static func < (lhs: SymptomSeverity, rhs: SymptomSeverity) -> Bool {
        let order: [SymptomSeverity] = [.low, .medium, .high]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

enum TriageAction: String, Codable {
    case selfCareWithMonitoring = "Self-care with monitoring"
    case scheduleDoctorVisit = "Schedule a doctor visit"
    case urgentCare = "Visit urgent care today"
    case call911 = "Call 911 immediately"

    var urgencyLevel: UrgencyLevel {
        switch self {
        case .selfCareWithMonitoring: return .routine
        case .scheduleDoctorVisit: return .moderate
        case .urgentCare: return .urgent
        case .call911: return .emergency
        }
    }
}

enum UrgencyLevel: String, Codable {
    case routine, moderate, urgent, emergency
}

struct InsuranceInfo: Codable {
    var provider: String
    var planType: String // PPO, HMO, etc.
    var memberId: String
    var groupNumber: String?
}

struct DrugInfo: Codable {
    var name: String
    var genericName: String?
    var activeIngredient: String?
    var warnings: String?
    var dosage: String?
}

struct HealthcareProvider: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var specialty: String
    var phone: String?
    var address: String?
    var rating: Double?
    var acceptsInsurance: [String] = []
}
