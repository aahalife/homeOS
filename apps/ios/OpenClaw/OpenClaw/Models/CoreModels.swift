import Foundation

// MARK: - Family Models

struct Family: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var members: [FamilyMember]
    var preferences: FamilyPreferences
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var adults: [FamilyMember] { members.filter { $0.role == .adult } }
    var children: [FamilyMember] { members.filter { $0.role == .child } }
    var elders: [FamilyMember] { members.filter { $0.role == .elder } }
    var dietaryRestrictions: [DietaryRestriction] {
        Array(Set(members.flatMap { $0.dietaryRestrictions }))
    }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: MemberRole
    var birthYear: Int?
    var dietaryRestrictions: [DietaryRestriction] = []
    var allergies: [String] = []
    var healthConditions: [String] = []
    var schoolInfo: SchoolInfo?

    var age: Int? {
        guard let birthYear = birthYear else { return nil }
        return Calendar.current.component(.year, from: Date()) - birthYear
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FamilyMember, rhs: FamilyMember) -> Bool {
        lhs.id == rhs.id
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case adult = "Adult"
    case child = "Child"
    case elder = "Elder"
}

struct FamilyPreferences: Codable {
    var weeklyGroceryBudget: Decimal?
    var preferredCuisines: [String] = []
    var maxWeekdayCookTime: Int = 30
    var maxWeekendCookTime: Int = 60
    var mealPlanningEnabled: Bool = true
    var healthcareEnabled: Bool = true
    var educationEnabled: Bool = true
    var elderCareEnabled: Bool = true
    var homeMaintenanceEnabled: Bool = true
    var familyCoordinationEnabled: Bool = true
    var mentalLoadEnabled: Bool = true
    var morningBriefingTime: String = "07:00"
    var eveningWindDownTime: String = "20:00"
    var homeAddress: String?
    var homeCity: String?
    var homeState: String?
    var homeZipCode: String?

    init() {}
}

struct SchoolInfo: Codable, Hashable {
    var schoolName: String
    var gradeLevel: Int
    var lmsType: LMSType?
    var lmsConnected: Bool = false
}

enum LMSType: String, Codable {
    case googleClassroom = "Google Classroom"
    case canvas = "Canvas"
}

// MARK: - Dietary

enum DietaryRestriction: String, Codable, CaseIterable, Hashable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case halal = "Halal"
    case kosher = "Kosher"
    case lowCarb = "Low-Carb"
    case none = "No Restrictions"
}

// MARK: - Skills

enum SkillType: String, Codable, CaseIterable, Identifiable {
    case mealPlanning = "Meal Planning"
    case healthcare = "Healthcare"
    case education = "Education"
    case elderCare = "Elder Care"
    case homeMaintenance = "Home Maintenance"
    case familyCoordination = "Family Coordination"
    case mentalLoad = "Mental Load"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mealPlanning: return "fork.knife"
        case .healthcare: return "heart.text.square"
        case .education: return "book"
        case .elderCare: return "figure.2.and.child.holdinghands"
        case .homeMaintenance: return "house"
        case .familyCoordination: return "calendar"
        case .mentalLoad: return "brain.head.profile"
        }
    }

    var description: String {
        switch self {
        case .mealPlanning: return "Weekly meal plans, grocery lists, recipes"
        case .healthcare: return "Medications, appointments, symptom checks"
        case .education: return "Homework tracking, grades, study plans"
        case .elderCare: return "Daily check-ins, medication reminders"
        case .homeMaintenance: return "Emergency triage, contractor search"
        case .familyCoordination: return "Shared calendar, announcements, chores"
        case .mentalLoad: return "Morning briefings, reminders, planning"
        }
    }
}

// MARK: - Priority

enum Priority: String, Codable, Comparable {
    case low, medium, high, urgent

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        let order: [Priority] = [.low, .medium, .high, .urgent]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Chat Models

struct ChatMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var timestamp: Date = Date()
    var skill: SkillType?
    var attachments: [ChatAttachment]?
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatAttachment: Codable {
    var type: AttachmentType
    var title: String
    var data: String // JSON-encoded payload

    enum AttachmentType: String, Codable {
        case mealPlan
        case recipe
        case groceryList
        case appointment
        case assignment
        case checkInSummary
        case contractor
        case calendar
        case briefing
    }
}
