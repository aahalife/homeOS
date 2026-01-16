import Foundation

struct OnboardingPreferences: Codable {
    var dietaryRestrictions: [String]
    var autoApproveBelow: Double
    var morningBriefTime: String
    var quietHoursStart: String
    var quietHoursEnd: String
    var emergencyContactName: String?
    var emergencyContactPhone: String?
}

final class OnboardingPreferencesStore {
    static let shared = OnboardingPreferencesStore()

    private init() {}

    func save(_ prefs: OnboardingPreferences) {
        guard let url = fileURL() else { return }
        do {
            let data = try JSONEncoder().encode(prefs)
            try data.write(to: url)
        } catch {
            print("Failed to save onboarding preferences: \(error)")
        }
    }

    func load() -> OnboardingPreferences? {
        guard let url = fileURL(), FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(OnboardingPreferences.self, from: data)
        } catch {
            print("Failed to load onboarding preferences: \(error)")
            return nil
        }
    }

    private func fileURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("onboarding_preferences.json")
    }
}
