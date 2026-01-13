//
//  FamilyStore.swift
//  OsaurusCore
//
//  Persistence layer for family data.
//  Stores family configuration in Application Support directory.
//

import Foundation

// MARK: - Family Store

/// Persistence for family data
public enum FamilyStore {
    /// Storage key for UserDefaults (non-sensitive family ID reference only)
    private static let familyIdKey = "OiMyAI_FamilyId"

    /// Directory for family data files
    private static var familyDataDirectory: URL {
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.fantasticapp.oimyai"
        let dir = supportDir
            .appendingPathComponent(bundleId, isDirectory: true)
            .appendingPathComponent("Family", isDirectory: true)

        // Ensure directory exists
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// File path for family data
    private static func familyFilePath(for id: UUID) -> URL {
        familyDataDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    /// File path for join requests
    private static var joinRequestsFilePath: URL {
        familyDataDirectory.appendingPathComponent("join_requests.json")
    }

    // MARK: - Family CRUD

    /// Check if a family exists
    public static func hasFamily() -> Bool {
        guard let familyId = currentFamilyId() else { return false }
        return FileManager.default.fileExists(atPath: familyFilePath(for: familyId).path)
    }

    /// Get current family ID from UserDefaults
    public static func currentFamilyId() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: familyIdKey) else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    /// Set current family ID
    public static func setCurrentFamilyId(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: familyIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: familyIdKey)
        }
    }

    /// Load the current family
    public static func loadFamily() -> Family? {
        guard let familyId = currentFamilyId() else { return nil }
        return loadFamily(id: familyId)
    }

    /// Load a family by ID
    public static func loadFamily(id: UUID) -> Family? {
        let path = familyFilePath(for: id)

        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Family.self, from: data)
        } catch {
            print("[Oi My AI] Failed to load family: \(error)")
            return nil
        }
    }

    /// Save a family
    public static func saveFamily(_ family: Family) {
        let path = familyFilePath(for: family.id)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(family)
            try data.write(to: path, options: .atomic)

            // Update current family reference
            setCurrentFamilyId(family.id)

            print("[Oi My AI] Family saved: \(family.name) (\(family.members.count) members)")
        } catch {
            print("[Oi My AI] Failed to save family: \(error)")
        }
    }

    /// Delete a family
    public static func deleteFamily(id: UUID) {
        let path = familyFilePath(for: id)

        do {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
            }

            // Clear current family reference if it matches
            if currentFamilyId() == id {
                setCurrentFamilyId(nil)
            }

            print("[Oi My AI] Family deleted: \(id)")
        } catch {
            print("[Oi My AI] Failed to delete family: \(error)")
        }
    }

    // MARK: - Join Requests

    /// Load all pending join requests
    public static func loadJoinRequests() -> [FamilyJoinRequest] {
        let path = joinRequestsFilePath

        guard FileManager.default.fileExists(atPath: path.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([FamilyJoinRequest].self, from: data)
        } catch {
            print("[Oi My AI] Failed to load join requests: \(error)")
            return []
        }
    }

    /// Save join requests
    public static func saveJoinRequests(_ requests: [FamilyJoinRequest]) {
        let path = joinRequestsFilePath

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(requests)
            try data.write(to: path, options: .atomic)
        } catch {
            print("[Oi My AI] Failed to save join requests: \(error)")
        }
    }

    /// Add a join request
    public static func addJoinRequest(_ request: FamilyJoinRequest) {
        var requests = loadJoinRequests()
        requests.append(request)
        saveJoinRequests(requests)
    }

    /// Update a join request
    public static func updateJoinRequest(_ request: FamilyJoinRequest) {
        var requests = loadJoinRequests()
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index] = request
            saveJoinRequests(requests)
        }
    }

    /// Remove a join request
    public static func removeJoinRequest(id: UUID) {
        var requests = loadJoinRequests()
        requests.removeAll { $0.id == id }
        saveJoinRequests(requests)
    }

    /// Get pending join requests for a family
    public static func pendingRequests(for familyId: UUID) -> [FamilyJoinRequest] {
        loadJoinRequests().filter { $0.familyId == familyId && $0.status == .pending }
    }

    // MARK: - Cleanup

    /// Clean up expired invites from a family
    public static func cleanupExpiredInvites(in family: inout Family) {
        let now = Date()
        family.pendingInvites.removeAll { !$0.isValid }

        // Also expire old join requests
        var requests = loadJoinRequests()
        var changed = false

        for i in 0..<requests.count {
            if requests[i].status == .pending &&
               requests[i].requestedAt.addingTimeInterval(3600) < now { // 1 hour expiry
                requests[i].status = .expired
                changed = true
            }
        }

        if changed {
            saveJoinRequests(requests)
        }
    }

    /// Purge all family data (for testing/reset)
    public static func purgeAllData() {
        let fm = FileManager.default

        do {
            let contents = try fm.contentsOfDirectory(at: familyDataDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try fm.removeItem(at: file)
            }
            setCurrentFamilyId(nil)
            print("[Oi My AI] All family data purged")
        } catch {
            print("[Oi My AI] Failed to purge family data: \(error)")
        }
    }
}

// MARK: - Migration Support

extension FamilyStore {
    /// Migrate family data from older versions if needed
    public static func migrateIfNeeded() {
        // Future: Add migration logic when schema changes
        // For now, this is a placeholder for forward compatibility
    }
}
