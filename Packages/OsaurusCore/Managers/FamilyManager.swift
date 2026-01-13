//
//  FamilyManager.swift
//  OsaurusCore
//
//  Service for managing family operations in Oi My AI.
//  Handles family creation, member management, and join flow.
//

import Combine
import Foundation

// MARK: - Notifications

extension Notification.Name {
    static let familyChanged = Notification.Name("familyChanged")
    static let familyMemberAdded = Notification.Name("familyMemberAdded")
    static let familyMemberRemoved = Notification.Name("familyMemberRemoved")
    static let familyJoinRequestReceived = Notification.Name("familyJoinRequestReceived")
}

// MARK: - Family Manager

/// Service for managing family operations
@MainActor
public final class FamilyManager: ObservableObject {
    public static let shared = FamilyManager()

    // MARK: - Published State

    /// Current family (nil if not set up)
    @Published public private(set) var family: Family?

    /// Current user's member record (primary member on this device)
    @Published public private(set) var currentMember: FamilyMember?

    /// Pending join requests awaiting approval
    @Published public private(set) var pendingJoinRequests: [FamilyJoinRequest] = []

    /// Whether family mode is enabled
    @Published public private(set) var isFamilyModeEnabled: Bool = false

    // MARK: - Private

    private var cleanupTimer: Timer?

    private init() {
        loadState()
        startCleanupTimer()
    }

    // MARK: - State Management

    private func loadState() {
        family = FamilyStore.loadFamily()
        isFamilyModeEnabled = family != nil

        if let family = family {
            currentMember = family.primaryMember
            pendingJoinRequests = FamilyStore.pendingRequests(for: family.id)
        }
    }

    private func saveState() {
        guard var family = family else { return }

        family.updatedAt = Date()
        FamilyStore.cleanupExpiredInvites(in: &family)
        FamilyStore.saveFamily(family)

        self.family = family
        NotificationCenter.default.post(name: .familyChanged, object: nil)
    }

    private func startCleanupTimer() {
        // Clean up expired invites every minute
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupExpired()
            }
        }
    }

    private func cleanupExpired() {
        guard var family = family else { return }
        let beforeCount = family.pendingInvites.count
        FamilyStore.cleanupExpiredInvites(in: &family)

        if family.pendingInvites.count != beforeCount {
            self.family = family
            FamilyStore.saveFamily(family)
        }

        // Refresh pending requests
        pendingJoinRequests = FamilyStore.pendingRequests(for: family.id)
    }

    // MARK: - Family Creation

    /// Create a new family with the current user as primary
    public func createFamily(
        name: String,
        primaryMemberName: String,
        primaryRole: FamilyRole = .parent
    ) -> Family {
        let primaryMember = FamilyMember(
            name: primaryMemberName,
            role: primaryRole,
            permissions: primaryRole.defaultPermissions
        )

        let newFamily = Family(
            name: name,
            primaryMemberId: primaryMember.id,
            members: [primaryMember]
        )

        family = newFamily
        currentMember = primaryMember
        isFamilyModeEnabled = true

        saveState()

        print("[Oi My AI] Family created: \(name) with primary member \(primaryMemberName)")
        return newFamily
    }

    /// Update family settings
    public func updateFamilySettings(_ settings: FamilySettings) {
        guard var family = family else { return }
        family.settings = settings
        self.family = family
        saveState()
    }

    /// Rename the family
    public func renameFamily(_ newName: String) {
        guard var family = family else { return }
        family.name = newName
        self.family = family
        saveState()
    }

    /// Delete the family (requires primary member)
    public func deleteFamily() {
        guard let family = family else { return }
        guard currentMember?.id == family.primaryMemberId else {
            print("[Oi My AI] Only primary member can delete family")
            return
        }

        FamilyStore.deleteFamily(id: family.id)
        self.family = nil
        self.currentMember = nil
        self.isFamilyModeEnabled = false
        self.pendingJoinRequests = []

        NotificationCenter.default.post(name: .familyChanged, object: nil)
    }

    // MARK: - Member Management

    /// Add a new member to the family
    public func addMember(_ member: FamilyMember) {
        guard var family = family else { return }
        guard canManageFamily() else {
            print("[Oi My AI] Current member cannot manage family")
            return
        }

        // Ensure no duplicate
        guard !family.members.contains(where: { $0.id == member.id }) else {
            return
        }

        family.members.append(member)
        self.family = family
        saveState()

        NotificationCenter.default.post(
            name: .familyMemberAdded,
            object: nil,
            userInfo: ["memberId": member.id]
        )

        print("[Oi My AI] Member added: \(member.name) (\(member.role.rawValue))")
    }

    /// Remove a member from the family
    public func removeMember(id: UUID) {
        guard var family = family else { return }
        guard canManageFamily() else {
            print("[Oi My AI] Current member cannot manage family")
            return
        }

        // Cannot remove primary member
        guard id != family.primaryMemberId else {
            print("[Oi My AI] Cannot remove primary member")
            return
        }

        family.members.removeAll { $0.id == id }
        self.family = family
        saveState()

        NotificationCenter.default.post(
            name: .familyMemberRemoved,
            object: nil,
            userInfo: ["memberId": id]
        )
    }

    /// Update a member's information
    public func updateMember(_ member: FamilyMember) {
        guard var family = family else { return }

        // Can update self or manage family
        let canUpdate = member.id == currentMember?.id || canManageFamily()
        guard canUpdate else {
            print("[Oi My AI] Cannot update this member")
            return
        }

        if let index = family.members.firstIndex(where: { $0.id == member.id }) {
            family.members[index] = member
            self.family = family

            // Update current member if it's us
            if member.id == currentMember?.id {
                currentMember = member
            }

            saveState()
        }
    }

    /// Update a member's permissions
    public func updateMemberPermissions(memberId: UUID, permissions: MemberPermissions) {
        guard var family = family else { return }
        guard canManageFamily() else { return }

        if let index = family.members.firstIndex(where: { $0.id == memberId }) {
            family.members[index].permissions = permissions
            self.family = family
            saveState()
        }
    }

    /// Get a member by ID
    public func member(withId id: UUID) -> FamilyMember? {
        family?.member(withId: id)
    }

    /// Get a member by Telegram handle
    public func member(withTelegramHandle handle: String) -> FamilyMember? {
        family?.member(withTelegramHandle: handle)
    }

    // MARK: - Permission Checks

    /// Check if current member can manage family
    public func canManageFamily() -> Bool {
        guard let member = currentMember else { return false }
        return member.permissions.canManageFamily || member.id == family?.primaryMemberId
    }

    /// Check if current member can approve joins
    public func canApproveJoins() -> Bool {
        guard let member = currentMember else { return false }
        return member.permissions.canApproveJoins || member.id == family?.primaryMemberId
    }

    /// Check if a member can execute a skill
    public func canExecuteSkill(memberId: UUID, skillId: String) -> Bool {
        guard let member = family?.member(withId: memberId) else { return false }

        // Check skill access level
        guard member.permissions.skillAccess.isAllowed(skillId) else {
            return false
        }

        // Check family restrictions
        if let family = family,
           family.settings.restrictedSkills.contains(where: { skillId.hasPrefix($0) }) {
            // Restricted skills require primary member
            return memberId == family.primaryMemberId
        }

        return true
    }

    /// Check if a member is in quiet hours
    public func isInQuietHours(memberId: UUID) -> Bool {
        guard let member = family?.member(withId: memberId),
              let quietHours = member.quietHours else {
            return false
        }
        return quietHours.isQuietNow()
    }

    // MARK: - Join Flow

    /// Create a new invitation code
    public func createInvite(
        suggestedRole: FamilyRole = .other,
        suggestedName: String? = nil,
        expiresIn: TimeInterval = 600 // 10 minutes
    ) -> FamilyInvite? {
        guard var family = family else { return nil }
        guard canApproveJoins() else {
            print("[Oi My AI] Current member cannot create invites")
            return nil
        }

        guard let currentMemberId = currentMember?.id else { return nil }

        let invite = FamilyInvite(
            expiresAt: Date().addingTimeInterval(expiresIn),
            suggestedRole: suggestedRole,
            suggestedName: suggestedName,
            createdBy: currentMemberId
        )

        family.pendingInvites.append(invite)
        self.family = family
        saveState()

        print("[Oi My AI] Invite created: \(invite.code) (expires in \(Int(expiresIn/60)) min)")
        return invite
    }

    /// Validate an invite code (for joining)
    public func validateInviteCode(_ code: String) -> FamilyInvite? {
        guard let family = family else { return nil }
        return family.pendingInvites.first { $0.code == code && $0.isValid }
    }

    /// Submit a join request using an invite code
    public func submitJoinRequest(
        inviteCode: String,
        name: String,
        telegramHandle: String?,
        preferredRole: FamilyRole? = nil
    ) -> FamilyJoinRequest? {
        guard let family = family else { return nil }
        guard let invite = validateInviteCode(inviteCode) else {
            print("[Oi My AI] Invalid or expired invite code")
            return nil
        }

        let role = preferredRole ?? invite.suggestedRole
        let proposedMember = FamilyMember(
            name: name,
            role: role,
            telegramHandle: telegramHandle,
            permissions: role.defaultPermissions
        )

        let request = FamilyJoinRequest(
            familyId: family.id,
            inviteCode: inviteCode,
            proposedMember: proposedMember
        )

        FamilyStore.addJoinRequest(request)
        pendingJoinRequests = FamilyStore.pendingRequests(for: family.id)

        NotificationCenter.default.post(
            name: .familyJoinRequestReceived,
            object: nil,
            userInfo: ["requestId": request.id]
        )

        print("[Oi My AI] Join request submitted: \(name)")
        return request
    }

    /// Approve a join request
    public func approveJoinRequest(_ requestId: UUID, message: String? = nil) {
        guard var family = family else { return }
        guard canApproveJoins() else { return }

        var requests = FamilyStore.loadJoinRequests()
        guard let index = requests.firstIndex(where: { $0.id == requestId }) else {
            return
        }

        var request = requests[index]
        request.status = .approved
        request.responseMessage = message
        request.respondedBy = currentMember?.id
        request.respondedAt = Date()

        // Add member to family
        family.members.append(request.proposedMember)

        // Mark invite as used
        if let inviteIndex = family.pendingInvites.firstIndex(where: { $0.code == request.inviteCode }) {
            family.pendingInvites[inviteIndex].isUsed = true
        }

        requests[index] = request
        FamilyStore.saveJoinRequests(requests)

        self.family = family
        saveState()

        pendingJoinRequests = FamilyStore.pendingRequests(for: family.id)

        NotificationCenter.default.post(
            name: .familyMemberAdded,
            object: nil,
            userInfo: ["memberId": request.proposedMember.id]
        )

        print("[Oi My AI] Join request approved: \(request.proposedMember.name)")
    }

    /// Deny a join request
    public func denyJoinRequest(_ requestId: UUID, message: String? = nil) {
        guard let family = family else { return }
        guard canApproveJoins() else { return }

        var requests = FamilyStore.loadJoinRequests()
        guard let index = requests.firstIndex(where: { $0.id == requestId }) else {
            return
        }

        requests[index].status = .denied
        requests[index].responseMessage = message
        requests[index].respondedBy = currentMember?.id
        requests[index].respondedAt = Date()

        FamilyStore.saveJoinRequests(requests)
        pendingJoinRequests = FamilyStore.pendingRequests(for: family.id)

        print("[Oi My AI] Join request denied: \(requests[index].proposedMember.name)")
    }

    /// Cancel an invitation
    public func cancelInvite(_ inviteId: UUID) {
        guard var family = family else { return }
        guard canApproveJoins() else { return }

        family.pendingInvites.removeAll { $0.id == inviteId }
        self.family = family
        saveState()
    }

    // MARK: - Refresh

    /// Refresh state from storage
    public func refresh() {
        loadState()
    }
}

// MARK: - Family Manager Errors

public enum FamilyManagerError: Error, LocalizedError {
    case notFamilyMember
    case insufficientPermissions
    case invalidInviteCode
    case inviteExpired
    case familyNotFound
    case memberNotFound

    public var errorDescription: String? {
        switch self {
        case .notFamilyMember:
            return "You are not a member of this family"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .invalidInviteCode:
            return "Invalid invite code"
        case .inviteExpired:
            return "This invite has expired"
        case .familyNotFound:
            return "Family not found"
        case .memberNotFound:
            return "Family member not found"
        }
    }
}
