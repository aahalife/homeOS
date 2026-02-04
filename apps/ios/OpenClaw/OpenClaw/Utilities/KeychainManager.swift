import Foundation
import Security

/// Secure storage manager using iOS Keychain Services
final class KeychainManager {
    static let shared = KeychainManager()

    private let serviceName = "com.aahalife.openclaw"

    enum KeychainError: LocalizedError {
        case saveFailed(OSStatus)
        case retrievalFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed

        var errorDescription: String? {
            switch self {
            case .saveFailed(let status):
                return "Keychain save failed with status: \(status)"
            case .retrievalFailed(let status):
                return "Keychain retrieval failed with status: \(status)"
            case .deleteFailed(let status):
                return "Keychain delete failed with status: \(status)"
            case .dataConversionFailed:
                return "Failed to convert data to/from Keychain"
            }
        }
    }

    // MARK: - API Key Management

    func saveAPIKey(_ key: String, for service: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func getAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    func deleteAPIKey(for service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - Convenience

    struct APIKeys {
        static let spoonacular = "spoonacular_api_key"
        static let usda = "usda_api_key"
        static let googleClientId = "google_client_id"
        static let twilioAccountSid = "twilio_account_sid"
        static let twilioAuthToken = "twilio_auth_token"
        static let twilioPhoneNumber = "twilio_phone_number"
        static let yelp = "yelp_api_key"
        static let googlePlaces = "google_places_api_key"
        static let weatherApi = "weather_api_key"
    }
}
