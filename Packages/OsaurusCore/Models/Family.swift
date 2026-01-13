//
//  Family.swift
//  OsaurusCore
//
//  Data models for family management in Oi My AI.
//  Supports multi-user households with role-based permissions.
//

import Foundation

// MARK: - Family

/// Represents a family unit in Oi My AI
public struct Family: Codable, Identifiable, Sendable {
    /// Unique family identifier (locally generated UUID)
    public let id: UUID

    /// Human-readable family name (e.g., "The Smiths")
    public var name: String

    /// When the family was created
    public let createdAt: Date

    /// When the family was last modified
    public var updatedAt: Date

    /// The primary user's member ID (owner of this Mac)
    public let primaryMemberId: UUID

    /// All family members
    public var members: [FamilyMember]

    /// Active join invitations
    public var pendingInvites: [FamilyInvite]

    /// Family-wide settings
    public var settings: FamilySettings

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        primaryMemberId: UUID,
        members: [FamilyMember] = [],
        pendingInvites: [FamilyInvite] = [],
        settings: FamilySettings = FamilySettings()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.primaryMemberId = primaryMemberId
        self.members = members
        self.pendingInvites = pendingInvites
        self.settings = settings
    }

    /// Get the primary (owner) member
    public var primaryMember: FamilyMember? {
        members.first { $0.id == primaryMemberId }
    }

    /// Get member by ID
    public func member(withId id: UUID) -> FamilyMember? {
        members.first { $0.id == id }
    }

    /// Get member by Telegram handle
    public func member(withTelegramHandle handle: String) -> FamilyMember? {
        members.first { $0.telegramHandle?.lowercased() == handle.lowercased() }
    }
}

// MARK: - Family Member

/// Represents a member of a family
public struct FamilyMember: Codable, Identifiable, Sendable, Equatable {
    /// Unique member identifier
    public let id: UUID

    /// Display name
    public var name: String

    /// Role in the family
    public var role: FamilyRole

    /// Telegram handle (without @)
    public var telegramHandle: String?

    /// Email for notifications
    public var email: String?

    /// Profile image data (small, for display)
    public var avatarData: Data?

    /// When the member joined
    public let joinedAt: Date

    /// Per-member permissions
    public var permissions: MemberPermissions

    /// Quiet hours (no proactive messages)
    public var quietHours: QuietHours?

    /// Whether this member is currently active
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        role: FamilyRole,
        telegramHandle: String? = nil,
        email: String? = nil,
        avatarData: Data? = nil,
        joinedAt: Date = Date(),
        permissions: MemberPermissions = MemberPermissions(),
        quietHours: QuietHours? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.telegramHandle = telegramHandle
        self.email = email
        self.avatarData = avatarData
        self.joinedAt = joinedAt
        self.permissions = permissions
        self.quietHours = quietHours
        self.isActive = isActive
    }
}

// MARK: - Family Role

/// Role of a family member
public enum FamilyRole: String, Codable, Sendable, CaseIterable {
    case parent = "Parent"
    case child = "Child"
    case teen = "Teen"
    case grandparent = "Grandparent"
    case caregiver = "Caregiver"
    case other = "Other"

    /// Default permissions for this role
    public var defaultPermissions: MemberPermissions {
        switch self {
        case .parent:
            return MemberPermissions(
                canManageFamily: true,
                canApproveJoins: true,
                skillAccess: .all,
                dataAccess: .full,
                canMakePayments: true,
                canScheduleProactive: true
            )
        case .teen:
            return MemberPermissions(
                canManageFamily: false,
                canApproveJoins: false,
                skillAccess: .limited(excluded: ["healthcare.medical_records", "finance.payments"]),
                dataAccess: .limited(scopes: ["calendar.read", "weather", "tasks"]),
                canMakePayments: false,
                canScheduleProactive: true
            )
        case .child:
            return MemberPermissions(
                canManageFamily: false,
                canApproveJoins: false,
                skillAccess: .limited(excluded: ["healthcare", "finance", "hire_helper"]),
                dataAccess: .limited(scopes: ["weather", "tasks.own"]),
                canMakePayments: false,
                canScheduleProactive: false
            )
        case .grandparent:
            return MemberPermissions(
                canManageFamily: false,
                canApproveJoins: false,
                skillAccess: .all,
                dataAccess: .limited(scopes: ["calendar.read", "weather", "healthcare.own"]),
                canMakePayments: false,
                canScheduleProactive: true
            )
        case .caregiver:
            return MemberPermissions(
                canManageFamily: false,
                canApproveJoins: false,
                skillAccess: .limited(excluded: ["finance"]),
                dataAccess: .limited(scopes: ["calendar.read", "tasks", "healthcare.view"]),
                canMakePayments: false,
                canScheduleProactive: true
            )
        case .other:
            return MemberPermissions(
                canManageFamily: false,
                canApproveJoins: false,
                skillAccess: .limited(excluded: ["healthcare", "finance"]),
                dataAccess: .limited(scopes: ["calendar.read", "weather"]),
                canMakePayments: false,
                canScheduleProactive: false
            )
        }
    }
}

// MARK: - Member Permissions

/// Permissions for a family member
public struct MemberPermissions: Codable, Sendable, Equatable {
    /// Can manage family settings and members
    public var canManageFamily: Bool

    /// Can approve join requests
    public var canApproveJoins: Bool

    /// Skill access level
    public var skillAccess: SkillAccessLevel

    /// Data access level
    public var dataAccess: DataAccessLevel

    /// Can authorize payments/purchases
    public var canMakePayments: Bool

    /// Can schedule proactive automations
    public var canScheduleProactive: Bool

    public init(
        canManageFamily: Bool = false,
        canApproveJoins: Bool = false,
        skillAccess: SkillAccessLevel = .all,
        dataAccess: DataAccessLevel = .full,
        canMakePayments: Bool = false,
        canScheduleProactive: Bool = false
    ) {
        self.canManageFamily = canManageFamily
        self.canApproveJoins = canApproveJoins
        self.skillAccess = skillAccess
        self.dataAccess = dataAccess
        self.canMakePayments = canMakePayments
        self.canScheduleProactive = canScheduleProactive
    }
}

/// Skill access level for a member
public enum SkillAccessLevel: Codable, Sendable, Equatable {
    case all
    case limited(excluded: [String])
    case allowList(allowed: [String])
    case none

    /// Check if a skill is allowed
    public func isAllowed(_ skillId: String) -> Bool {
        switch self {
        case .all:
            return true
        case .limited(let excluded):
            return !excluded.contains { skillId.hasPrefix($0) || skillId == $0 }
        case .allowList(let allowed):
            return allowed.contains { skillId.hasPrefix($0) || skillId == $0 }
        case .none:
            return false
        }
    }
}

/// Data access level for a member
public enum DataAccessLevel: Codable, Sendable, Equatable {
    case full
    case limited(scopes: [String])
    case readOnly
    case none

    /// Check if a scope is allowed
    public func isAllowed(_ scope: String) -> Bool {
        switch self {
        case .full:
            return true
        case .limited(let scopes):
            return scopes.contains { scope.hasPrefix($0) || scope == $0 }
        case .readOnly:
            return scope.hasSuffix(".read") || scope == "read"
        case .none:
            return false
        }
    }
}

// MARK: - Quiet Hours

/// Quiet hours configuration (no proactive messages)
public struct QuietHours: Codable, Sendable, Equatable {
    /// Start time (hour, 0-23)
    public var startHour: Int

    /// Start minute (0-59)
    public var startMinute: Int

    /// End time (hour, 0-23)
    public var endHour: Int

    /// End minute (0-59)
    public var endMinute: Int

    /// Days of week (1=Sunday, 7=Saturday), empty means every day
    public var daysOfWeek: [Int]

    /// Time zone identifier
    public var timeZone: String

    public init(
        startHour: Int = 22,
        startMinute: Int = 0,
        endHour: Int = 7,
        endMinute: Int = 0,
        daysOfWeek: [Int] = [],
        timeZone: String = TimeZone.current.identifier
    ) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.daysOfWeek = daysOfWeek
        self.timeZone = timeZone
    }

    /// Check if current time is within quiet hours
    public func isQuietNow() -> Bool {
        let tz = TimeZone(identifier: timeZone) ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz

        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: now)

        guard let hour = components.hour,
              let minute = components.minute,
              let weekday = components.weekday else {
            return false
        }

        // Check day of week if specified
        if !daysOfWeek.isEmpty && !daysOfWeek.contains(weekday) {
            return false
        }

        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        // Handle overnight quiet hours (e.g., 22:00 to 07:00)
        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }
}

// MARK: - Family Settings

/// Family-wide settings
public struct FamilySettings: Codable, Sendable {
    /// Enable family sharing features
    public var sharingEnabled: Bool

    /// Enable location sharing between members
    public var locationSharingEnabled: Bool

    /// Default quiet hours for new members
    public var defaultQuietHours: QuietHours?

    /// Require approval for skill execution from non-primary members
    public var requireApprovalForRemoteSkills: Bool

    /// Skills that always require primary approval
    public var restrictedSkills: [String]

    /// Maximum daily budget for payment-enabled skills (in cents)
    public var dailyBudgetCents: Int?

    public init(
        sharingEnabled: Bool = true,
        locationSharingEnabled: Bool = false,
        defaultQuietHours: QuietHours? = QuietHours(),
        requireApprovalForRemoteSkills: Bool = true,
        restrictedSkills: [String] = ["finance.payment", "hire_helper.booking"],
        dailyBudgetCents: Int? = nil
    ) {
        self.sharingEnabled = sharingEnabled
        self.locationSharingEnabled = locationSharingEnabled
        self.defaultQuietHours = defaultQuietHours
        self.requireApprovalForRemoteSkills = requireApprovalForRemoteSkills
        self.restrictedSkills = restrictedSkills
        self.dailyBudgetCents = dailyBudgetCents
    }
}

// MARK: - Family Invite

/// Invitation to join a family
public struct FamilyInvite: Codable, Identifiable, Sendable {
    /// Unique invite identifier
    public let id: UUID

    /// 6-digit join code
    public let code: String

    /// When the invite was created
    public let createdAt: Date

    /// When the invite expires (10 min TTL by default)
    public let expiresAt: Date

    /// Suggested role for the invitee
    public var suggestedRole: FamilyRole

    /// Suggested name (can be changed by invitee)
    public var suggestedName: String?

    /// Who created this invite
    public let createdBy: UUID

    /// Whether the invite has been used
    public var isUsed: Bool

    public init(
        id: UUID = UUID(),
        code: String = FamilyInvite.generateCode(),
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(600), // 10 minutes
        suggestedRole: FamilyRole = .other,
        suggestedName: String? = nil,
        createdBy: UUID,
        isUsed: Bool = false
    ) {
        self.id = id
        self.code = code
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.suggestedRole = suggestedRole
        self.suggestedName = suggestedName
        self.createdBy = createdBy
        self.isUsed = isUsed
    }

    /// Whether the invite is still valid
    public var isValid: Bool {
        !isUsed && Date() < expiresAt
    }

    /// Time remaining in seconds
    public var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }

    /// Generate a 6-digit numeric code
    public static func generateCode() -> String {
        String(format: "%06d", Int.random(in: 100000...999999))
    }
}

// MARK: - Join Request

/// Request to join a family (pending approval)
public struct FamilyJoinRequest: Codable, Identifiable, Sendable {
    /// Unique request identifier
    public let id: UUID

    /// The family being joined
    public let familyId: UUID

    /// The invite code used
    public let inviteCode: String

    /// Proposed member info
    public var proposedMember: FamilyMember

    /// When the request was made
    public let requestedAt: Date

    /// Status of the request
    public var status: JoinRequestStatus

    /// Response message from approver
    public var responseMessage: String?

    /// Who responded to the request
    public var respondedBy: UUID?

    /// When the response was given
    public var respondedAt: Date?

    public init(
        id: UUID = UUID(),
        familyId: UUID,
        inviteCode: String,
        proposedMember: FamilyMember,
        requestedAt: Date = Date(),
        status: JoinRequestStatus = .pending,
        responseMessage: String? = nil,
        respondedBy: UUID? = nil,
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.inviteCode = inviteCode
        self.proposedMember = proposedMember
        self.requestedAt = requestedAt
        self.status = status
        self.responseMessage = responseMessage
        self.respondedBy = respondedBy
        self.respondedAt = respondedAt
    }
}

/// Status of a join request
public enum JoinRequestStatus: String, Codable, Sendable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    case expired = "expired"
}
