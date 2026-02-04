import Foundation

/// ViewModel for app settings
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var spoonacularKey: String = ""
    @Published var usdaKey: String = ""
    @Published var twilioSid: String = ""
    @Published var twilioToken: String = ""
    @Published var twilioPhone: String = ""
    @Published var googlePlacesKey: String = ""
    @Published var isSaving: Bool = false
    @Published var saveMessage: String?

    private let keychain = KeychainManager.shared

    init() {
        loadKeys()
    }

    func loadKeys() {
        spoonacularKey = keychain.getAPIKey(for: KeychainManager.APIKeys.spoonacular) ?? ""
        usdaKey = keychain.getAPIKey(for: KeychainManager.APIKeys.usda) ?? ""
        twilioSid = keychain.getAPIKey(for: KeychainManager.APIKeys.twilioAccountSid) ?? ""
        twilioToken = keychain.getAPIKey(for: KeychainManager.APIKeys.twilioAuthToken) ?? ""
        twilioPhone = keychain.getAPIKey(for: KeychainManager.APIKeys.twilioPhoneNumber) ?? ""
        googlePlacesKey = keychain.getAPIKey(for: KeychainManager.APIKeys.googlePlaces) ?? ""
    }

    func saveKeys() {
        isSaving = true
        do {
            if !spoonacularKey.isEmpty { try keychain.saveAPIKey(spoonacularKey, for: KeychainManager.APIKeys.spoonacular) }
            if !usdaKey.isEmpty { try keychain.saveAPIKey(usdaKey, for: KeychainManager.APIKeys.usda) }
            if !twilioSid.isEmpty { try keychain.saveAPIKey(twilioSid, for: KeychainManager.APIKeys.twilioAccountSid) }
            if !twilioToken.isEmpty { try keychain.saveAPIKey(twilioToken, for: KeychainManager.APIKeys.twilioAuthToken) }
            if !twilioPhone.isEmpty { try keychain.saveAPIKey(twilioPhone, for: KeychainManager.APIKeys.twilioPhoneNumber) }
            if !googlePlacesKey.isEmpty { try keychain.saveAPIKey(googlePlacesKey, for: KeychainManager.APIKeys.googlePlaces) }
            saveMessage = "API keys saved securely"
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "onboarding_complete")
        UserDefaults.standard.removeObject(forKey: "active_skills")
        try? PersistenceController.shared.deleteAllData()
    }
}
