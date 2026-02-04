import Foundation

// MARK: - Home Maintenance Models

struct HomeProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var familyId: UUID
    var address: String
    var city: String?
    var state: String?
    var zipCode: String?
    var shutoffLocations: ShutoffInfo?
    var hvacAge: Int? // years
    var savedContractors: [ServiceProvider] = []
    var maintenanceSchedule: [MaintenanceTask] = []
    var repairHistory: [RepairRecord] = []
}

struct ShutoffInfo: Codable {
    var waterMainLocation: String?
    var gasShutoffLocation: String?
    var electricalPanelLocation: String?
    var notes: String?
}

struct ServiceProvider: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var serviceType: ServiceType
    var phone: String
    var address: String?
    var rating: Double?
    var reviewCount: Int?
    var lastUsed: Date?
    var notes: String?
    var source: String? // "Yelp", "Google", "Manual"
}

enum ServiceType: String, Codable, CaseIterable {
    case plumber = "Plumber"
    case electrician = "Electrician"
    case hvac = "HVAC"
    case appliance = "Appliance Repair"
    case roofing = "Roofing"
    case general = "General Contractor"
    case landscaping = "Landscaping"
    case pest = "Pest Control"
    case locksmith = "Locksmith"
    case cleaning = "Cleaning"

    var yelpCategory: String {
        switch self {
        case .plumber: return "plumbing"
        case .electrician: return "electricians"
        case .hvac: return "hvac"
        case .appliance: return "appliancerepair"
        case .roofing: return "roofing"
        case .general: return "contractors"
        case .landscaping: return "landscaping"
        case .pest: return "pest_control"
        case .locksmith: return "locksmiths"
        case .cleaning: return "homecleaning"
        }
    }
}

struct MaintenanceTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var frequency: MaintenanceFrequency
    var lastCompleted: Date?
    var nextDue: Date
    var priority: Priority = .medium
    var category: ServiceType
    var isCompleted: Bool = false
}

enum MaintenanceFrequency: String, Codable {
    case monthly, quarterly, semiAnnual, annual
}

struct RepairRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var description: String
    var provider: String?
    var cost: Decimal?
    var category: ServiceType
    var notes: String?
}

// MARK: - Emergency

enum EmergencyType: String, Codable {
    case gasLeak = "Gas Leak"
    case majorWaterLeak = "Major Water Leak"
    case electricalFire = "Electrical Fire"
    case sewageBackup = "Sewage Backup"
    case noHeat = "No Heat"
    case noAC = "No AC"
    case roofDamage = "Roof Damage"
    case brokenWindow = "Broken Window"
    case lockedOut = "Locked Out"
    case applianceFailure = "Appliance Failure"
    case other = "Other"

    var requiresEvacuation: Bool {
        switch self {
        case .gasLeak, .electricalFire: return true
        default: return false
        }
    }
}

enum EmergencyLevel: String, Codable {
    case routine = "Routine"
    case urgent = "Urgent"
    case critical = "Critical"
    case emergency = "Emergency"
}

struct SafetyProtocol: Codable {
    var emergencyType: EmergencyType
    var level: EmergencyLevel
    var steps: [SafetyStep]
    var callEmergencyServices: Bool
    var evacuate: Bool
}

struct SafetyStep: Identifiable, Codable {
    var id: UUID = UUID()
    var stepNumber: Int
    var instruction: String
    var isUrgent: Bool = false
    var warning: String?
}

struct MaintenanceIssue: Codable {
    var type: EmergencyType
    var description: String
    var severity: EmergencyLevel
    var details: [String: String] = [:]
}

struct WeatherConditions: Codable {
    var temperatureF: Double
    var feelsLikeF: Double
    var humidity: Int
    var description: String
    var windSpeedMph: Double
}
