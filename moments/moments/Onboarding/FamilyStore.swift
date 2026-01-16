import Foundation

struct FamilyMemberProfile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var role: FamilyRole
    var age: Int?
}

enum FamilyRole: String, CaseIterable, Codable {
    case spouse
    case parent
    case teen
    case child
    case grandparent
    case caregiver
    case other

    var title: String {
        switch self {
        case .spouse: return "Spouse"
        case .parent: return "Parent"
        case .teen: return "Teen"
        case .child: return "Child"
        case .grandparent: return "Grandparent"
        case .caregiver: return "Caregiver"
        case .other: return "Other"
        }
    }

    var requiresAge: Bool {
        switch self {
        case .teen, .child:
            return true
        default:
            return false
        }
    }
}

final class FamilyStore {
    static let shared = FamilyStore()

    private init() {}

    func loadCandidates() -> [FamilyMemberProfile] {
        guard let snapshot = loadSnapshot() else { return [] }
        let candidates = snapshot.contacts
            .filter { $0.isFamilyCandidate }
            .prefix(6)

        return candidates.map { contact in
            FamilyMemberProfile(
                name: contact.displayName,
                role: inferredRole(from: contact.relationHints),
                age: nil
            )
        }
    }

    func saveConfirmed(_ members: [FamilyMemberProfile]) {
        guard let url = confirmedURL() else { return }
        do {
            let data = try JSONEncoder().encode(members)
            try data.write(to: url)
        } catch {
            print("Failed to save family members: \(error)")
        }
    }

    func syncConfirmed(_ members: [FamilyMemberProfile]) async {
        do {
            try await ControlPlaneClient.shared.sendFamilyMembers(members)
        } catch {
            print("Family sync failed: \(error)")
        }
    }

    func suggestedEmergencyContact() -> EmergencyContactSuggestion? {
        guard let snapshot = loadSnapshot() else { return nil }
        let priorityKeywords = ["spouse", "wife", "husband", "partner", "parent", "mom", "dad", "grandparent", "grandmother", "grandfather", "grandma", "grandpa"]

        let contact = snapshot.contacts.first { contact in
            contact.relationHints.contains { hint in
                priorityKeywords.contains { hint.contains($0) }
            }
        } ?? snapshot.contacts.first(where: { $0.isFamilyCandidate })

        guard let contact else { return nil }
        let last4 = contact.phoneLast4.first
        return EmergencyContactSuggestion(name: contact.displayName, phoneLast4: last4)
    }

    private func loadSnapshot() -> InferenceSnapshot? {
        guard let url = snapshotURL(), FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(InferenceSnapshot.self, from: data)
        } catch {
            print("Failed to read inference snapshot: \(error)")
            return nil
        }
    }

    private func snapshotURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("inference_snapshot.json")
    }

    private func confirmedURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("family_confirmed.json")
    }

    private func inferredRole(from hints: [String]) -> FamilyRole {
        let joined = hints.joined(separator: " ").lowercased()
        if joined.contains("spouse") || joined.contains("wife") || joined.contains("husband") || joined.contains("partner") {
            return .spouse
        }
        if joined.contains("grandparent") || joined.contains("grandmother") || joined.contains("grandfather") || joined.contains("grandma") || joined.contains("grandpa") {
            return .grandparent
        }
        if joined.contains("child") || joined.contains("son") || joined.contains("daughter") {
            return .child
        }
        if joined.contains("teen") {
            return .teen
        }
        if joined.contains("parent") || joined.contains("mom") || joined.contains("dad") || joined.contains("mother") || joined.contains("father") {
            return .parent
        }
        if joined.contains("caregiver") {
            return .caregiver
        }
        return .other
    }
}

struct EmergencyContactSuggestion {
    let name: String
    let phoneLast4: String?
}
