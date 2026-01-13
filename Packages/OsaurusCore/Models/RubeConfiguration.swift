//
//  RubeConfiguration.swift
//  OsaurusCore
//
//  Configuration for Rube (Composio) MCP integration.
//  Provides access to 500+ tools via a unified MCP interface.
//

import Foundation

// MARK: - Rube Configuration

/// Configuration for the Rube (Composio) MCP provider
public struct RubeConfiguration: Codable, Sendable {
    /// Whether Rube integration is enabled (feature flag)
    public var enabled: Bool

    /// The Rube/Composio API endpoint
    public var endpoint: String

    /// Custom headers (non-secret)
    public var customHeaders: [String: String]

    /// Discovery timeout in seconds
    public var discoveryTimeout: TimeInterval

    /// Tool call timeout in seconds
    public var toolCallTimeout: TimeInterval

    /// Auto-connect on app launch
    public var autoConnect: Bool

    /// Last connection status
    public var lastConnectionStatus: RubeConnectionStatus?

    /// When the configuration was last modified
    public var updatedAt: Date

    // MARK: - Defaults

    /// Default Rube/Composio MCP endpoint
    public static let defaultEndpoint = "https://mcp.composio.dev"

    /// Default configuration
    public static let defaultConfig = RubeConfiguration(
        enabled: false,
        endpoint: defaultEndpoint,
        customHeaders: [:],
        discoveryTimeout: 30,
        toolCallTimeout: 60,
        autoConnect: false,
        lastConnectionStatus: nil,
        updatedAt: Date()
    )

    public init(
        enabled: Bool = false,
        endpoint: String = RubeConfiguration.defaultEndpoint,
        customHeaders: [String: String] = [:],
        discoveryTimeout: TimeInterval = 30,
        toolCallTimeout: TimeInterval = 60,
        autoConnect: Bool = false,
        lastConnectionStatus: RubeConnectionStatus? = nil,
        updatedAt: Date = Date()
    ) {
        self.enabled = enabled
        self.endpoint = endpoint
        self.customHeaders = customHeaders
        self.discoveryTimeout = discoveryTimeout
        self.toolCallTimeout = toolCallTimeout
        self.autoConnect = autoConnect
        self.lastConnectionStatus = lastConnectionStatus
        self.updatedAt = updatedAt
    }
}

// MARK: - Connection Status

/// Status of the Rube connection
public struct RubeConnectionStatus: Codable, Sendable {
    public var isConnected: Bool
    public var toolCount: Int
    public var discoveredTools: [String]
    public var lastError: String?
    public var connectedAt: Date?

    public init(
        isConnected: Bool = false,
        toolCount: Int = 0,
        discoveredTools: [String] = [],
        lastError: String? = nil,
        connectedAt: Date? = nil
    ) {
        self.isConnected = isConnected
        self.toolCount = toolCount
        self.discoveredTools = discoveredTools
        self.lastError = lastError
        self.connectedAt = connectedAt
    }

    /// Display-friendly status string
    public var statusDescription: String {
        if isConnected {
            return "Connected (\(toolCount) tools)"
        } else if let error = lastError {
            return "Error: \(error)"
        } else {
            return "Not connected"
        }
    }
}

// MARK: - Rube Tool Categories

/// Categories of tools available through Rube/Composio
public enum RubeToolCategory: String, CaseIterable, Sendable {
    case calendar = "Calendar"
    case communication = "Communication"
    case commerce = "Commerce"
    case productivity = "Productivity"
    case social = "Social"
    case weather = "Weather"
    case search = "Search"
    case other = "Other"

    /// Tool prefixes that map to this category
    public var toolPrefixes: [String] {
        switch self {
        case .calendar:
            return ["google_calendar", "outlook_calendar", "calendly"]
        case .communication:
            return ["gmail", "slack", "discord", "twilio", "sendgrid"]
        case .commerce:
            return ["instacart", "amazon", "shopify", "stripe"]
        case .productivity:
            return ["notion", "asana", "trello", "todoist", "google_docs"]
        case .social:
            return ["twitter", "linkedin", "facebook", "nextdoor"]
        case .weather:
            return ["openweathermap", "weatherapi"]
        case .search:
            return ["google", "yelp", "exa", "brave"]
        case .other:
            return []
        }
    }
}

// MARK: - Configuration Store

/// Persistence for Rube configuration
public enum RubeConfigurationStore {
    /// Key for UserDefaults (non-sensitive data only)
    private static let configKey = "RubeConfiguration"

    /// Keychain service for API key
    private static let keychainService = "ai.oimyai.rube"
    private static let keychainAccount = "api_key"

    // MARK: - Configuration

    /// Load configuration from UserDefaults
    public static func load() -> RubeConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configKey) else {
            return .defaultConfig
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(RubeConfiguration.self, from: data)
        } catch {
            print("[Oi My AI] Failed to load Rube config: \(error)")
            return .defaultConfig
        }
    }

    /// Save configuration to UserDefaults
    public static func save(_ config: RubeConfiguration) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(config)
            UserDefaults.standard.set(data, forKey: configKey)
        } catch {
            print("[Oi My AI] Failed to save Rube config: \(error)")
        }
    }

    // MARK: - API Key (Keychain)

    /// Save API key to Keychain
    @discardableResult
    public static func saveAPIKey(_ apiKey: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else { return false }

        // Delete existing key first
        deleteAPIKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Get API key from Keychain
    public static func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
            let data = result as? Data,
            let apiKey = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return apiKey
    }

    /// Delete API key from Keychain
    @discardableResult
    public static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if API key exists
    public static func hasAPIKey() -> Bool {
        getAPIKey() != nil
    }
}
