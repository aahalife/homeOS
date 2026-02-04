import Foundation

// MARK: - Family Model

public struct Family: Codable, Sendable {
    public var members: [FamilyMember]
    public var ownerPhone: String?
    
    public init(members: [FamilyMember] = [], ownerPhone: String? = nil) {
        self.members = members
        self.ownerPhone = ownerPhone
    }
    
    /// Get members by role
    public func members(role: MemberRole) -> [FamilyMember] {
        members.filter { $0.role == role }
    }
    
    /// Get member by ID
    public func member(id: String) -> FamilyMember? {
        members.first { $0.id == id }
    }
    
    /// Get all children sorted by age
    public var children: [FamilyMember] {
        members.filter { $0.role == .child }.sorted { ($0.age ?? 0) < ($1.age ?? 0) }
    }
    
    /// Get all parents
    public var parents: [FamilyMember] {
        members.filter { $0.role == .parent }
    }
    
    /// Get all elders
    public var elders: [FamilyMember] {
        members.filter { $0.role == .elder }
    }
}

// MARK: - Family Member

public struct FamilyMember: Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var role: MemberRole
    public var age: Int?
    public var phone: String?
    public var email: String?
    public var preferences: MemberPreferences?
    public var allergies: [String]?
    public var medications: [Medication]?
    public var quietHours: QuietHours?
    
    public init(
        id: String,
        name: String,
        role: MemberRole,
        age: Int? = nil,
        phone: String? = nil,
        email: String? = nil,
        preferences: MemberPreferences? = nil,
        allergies: [String]? = nil,
        medications: [Medication]? = nil,
        quietHours: QuietHours? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.age = age
        self.phone = phone
        self.email = email
        self.preferences = preferences
        self.allergies = allergies
        self.medications = medications
        self.quietHours = quietHours
    }
    
    /// Age group for activity/content matching
    public var ageGroup: AgeGroup? {
        guard let age = age else { return nil }
        switch age {
        case 0...3: return .toddler
        case 4...5: return .preschool
        case 6...10: return .schoolAge
        case 11...13: return .tween
        case 14...17: return .teen
        default: return .adult
        }
    }
}

// MARK: - Supporting Types

public enum MemberRole: String, Codable, Sendable {
    case parent
    case child
    case elder
}

public enum AgeGroup: String, Codable, Sendable {
    case toddler     // 0-3
    case preschool   // 4-5
    case schoolAge   // 6-10
    case tween       // 11-13
    case teen        // 14-17
    case adult       // 18+
}

public struct MemberPreferences: Codable, Sendable {
    public var dietary: [String]?
    public var cuisines: [String]?
    public var activities: [String]?
    public var musicEra: String?
    public var musicArtists: [String]?
    public var interests: [String]?
    
    public init(
        dietary: [String]? = nil,
        cuisines: [String]? = nil,
        activities: [String]? = nil,
        musicEra: String? = nil,
        musicArtists: [String]? = nil,
        interests: [String]? = nil
    ) {
        self.dietary = dietary
        self.cuisines = cuisines
        self.activities = activities
        self.musicEra = musicEra
        self.musicArtists = musicArtists
        self.interests = interests
    }
}

public struct Medication: Codable, Sendable {
    public var name: String
    public var dosage: String
    public var times: [String]  // ["08:00", "20:00"]
    public var purpose: String?
    public var refillDate: String?
    
    public init(name: String, dosage: String, times: [String], purpose: String? = nil, refillDate: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.times = times
        self.purpose = purpose
        self.refillDate = refillDate
    }
}

public struct QuietHours: Codable, Sendable {
    public var start: String  // "21:00"
    public var end: String    // "07:00"
    
    public init(start: String, end: String) {
        self.start = start
        self.end = end
    }
}
