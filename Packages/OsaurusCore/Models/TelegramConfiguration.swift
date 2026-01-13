//
//  TelegramConfiguration.swift
//  OsaurusCore
//
//  Configuration for Telegram Gateway in Oi My AI.
//  Enables family members to interact via Telegram messaging.
//

import Foundation

// MARK: - Telegram Configuration

/// Configuration for the Telegram Gateway
public struct TelegramConfiguration: Codable, Sendable {
    /// Whether Telegram gateway is enabled
    public var enabled: Bool

    /// Polling interval in seconds
    public var pollingInterval: TimeInterval

    /// Maximum messages to process per poll
    public var maxMessagesPerPoll: Int

    /// Rate limit: max messages per user per minute
    public var rateLimitPerMinute: Int

    /// Whether to require family membership for responses
    public var requireFamilyMembership: Bool

    /// Auto-reply message for non-family members
    public var nonFamilyReplyMessage: String?

    /// Last connection status
    public var lastConnectionStatus: TelegramConnectionStatus?

    /// When the configuration was last modified
    public var updatedAt: Date

    // MARK: - Defaults

    public static let defaultConfig = TelegramConfiguration(
        enabled: false,
        pollingInterval: 2.0,
        maxMessagesPerPoll: 10,
        rateLimitPerMinute: 20,
        requireFamilyMembership: true,
        nonFamilyReplyMessage: "Sorry, I only respond to registered family members.",
        lastConnectionStatus: nil,
        updatedAt: Date()
    )

    public init(
        enabled: Bool = false,
        pollingInterval: TimeInterval = 2.0,
        maxMessagesPerPoll: Int = 10,
        rateLimitPerMinute: Int = 20,
        requireFamilyMembership: Bool = true,
        nonFamilyReplyMessage: String? = nil,
        lastConnectionStatus: TelegramConnectionStatus? = nil,
        updatedAt: Date = Date()
    ) {
        self.enabled = enabled
        self.pollingInterval = pollingInterval
        self.maxMessagesPerPoll = maxMessagesPerPoll
        self.rateLimitPerMinute = rateLimitPerMinute
        self.requireFamilyMembership = requireFamilyMembership
        self.nonFamilyReplyMessage = nonFamilyReplyMessage
        self.lastConnectionStatus = lastConnectionStatus
        self.updatedAt = updatedAt
    }
}

// MARK: - Connection Status

/// Status of the Telegram connection
public struct TelegramConnectionStatus: Codable, Sendable {
    public var isConnected: Bool
    public var botUsername: String?
    public var lastPollTime: Date?
    public var messagesProcessed: Int
    public var lastError: String?

    public init(
        isConnected: Bool = false,
        botUsername: String? = nil,
        lastPollTime: Date? = nil,
        messagesProcessed: Int = 0,
        lastError: String? = nil
    ) {
        self.isConnected = isConnected
        self.botUsername = botUsername
        self.lastPollTime = lastPollTime
        self.messagesProcessed = messagesProcessed
        self.lastError = lastError
    }

    public var statusDescription: String {
        if isConnected {
            if let username = botUsername {
                return "Connected as @\(username)"
            }
            return "Connected"
        } else if let error = lastError {
            return "Error: \(error)"
        } else {
            return "Not connected"
        }
    }
}

// MARK: - Telegram Message

/// Incoming message from Telegram
public struct TelegramIncomingMessage: Codable, Identifiable, Sendable {
    public let id: Int64
    public let chatId: Int64
    public let userId: Int64
    public let username: String?
    public let firstName: String?
    public let text: String
    public let date: Date

    public init(
        id: Int64,
        chatId: Int64,
        userId: Int64,
        username: String?,
        firstName: String?,
        text: String,
        date: Date
    ) {
        self.id = id
        self.chatId = chatId
        self.userId = userId
        self.username = username
        self.firstName = firstName
        self.text = text
        self.date = date
    }

    /// Get display name for the sender
    public var displayName: String {
        if let first = firstName, !first.isEmpty {
            return first
        }
        if let user = username {
            return "@\(user)"
        }
        return "User \(userId)"
    }
}

/// Outgoing message to Telegram
public struct TelegramOutgoingMessage: Codable, Sendable {
    public let chatId: Int64
    public let text: String
    public let parseMode: String?
    public let replyToMessageId: Int64?

    public init(
        chatId: Int64,
        text: String,
        parseMode: String? = "Markdown",
        replyToMessageId: Int64? = nil
    ) {
        self.chatId = chatId
        self.text = text
        self.parseMode = parseMode
        self.replyToMessageId = replyToMessageId
    }
}

// MARK: - Configuration Store

/// Persistence for Telegram configuration
public enum TelegramConfigurationStore {
    /// Key for UserDefaults
    private static let configKey = "TelegramConfiguration"

    /// Keychain service for bot token
    private static let keychainService = "ai.oimyai.telegram"
    private static let keychainAccount = "bot_token"

    // MARK: - Configuration

    /// Load configuration from UserDefaults
    public static func load() -> TelegramConfiguration {
        guard let data = UserDefaults.standard.data(forKey: configKey) else {
            return .defaultConfig
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(TelegramConfiguration.self, from: data)
        } catch {
            print("[Oi My AI] Failed to load Telegram config: \(error)")
            return .defaultConfig
        }
    }

    /// Save configuration to UserDefaults
    public static func save(_ config: TelegramConfiguration) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(config)
            UserDefaults.standard.set(data, forKey: configKey)
        } catch {
            print("[Oi My AI] Failed to save Telegram config: \(error)")
        }
    }

    // MARK: - Bot Token (Keychain)

    /// Save bot token to Keychain
    @discardableResult
    public static func saveBotToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }

        // Delete existing token first
        deleteBotToken()

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

    /// Get bot token from Keychain
    public static func getBotToken() -> String? {
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
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    /// Delete bot token from Keychain
    @discardableResult
    public static func deleteBotToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if bot token exists
    public static func hasBotToken() -> Bool {
        getBotToken() != nil
    }
}

// MARK: - Telegram User Mapping

/// Maps Telegram users to family members
public struct TelegramUserMapping: Codable, Sendable {
    public let telegramUserId: Int64
    public let telegramUsername: String?
    public let familyMemberId: UUID
    public let linkedAt: Date

    public init(
        telegramUserId: Int64,
        telegramUsername: String?,
        familyMemberId: UUID,
        linkedAt: Date = Date()
    ) {
        self.telegramUserId = telegramUserId
        self.telegramUsername = telegramUsername
        self.familyMemberId = familyMemberId
        self.linkedAt = linkedAt
    }
}

/// Store for Telegram user mappings
public enum TelegramUserMappingStore {
    private static let mappingsKey = "TelegramUserMappings"

    public static func load() -> [TelegramUserMapping] {
        guard let data = UserDefaults.standard.data(forKey: mappingsKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TelegramUserMapping].self, from: data)
        } catch {
            return []
        }
    }

    public static func save(_ mappings: [TelegramUserMapping]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(mappings)
            UserDefaults.standard.set(data, forKey: mappingsKey)
        } catch {
            print("[Oi My AI] Failed to save Telegram mappings: \(error)")
        }
    }

    public static func addMapping(_ mapping: TelegramUserMapping) {
        var mappings = load()
        // Remove existing mapping for this Telegram user
        mappings.removeAll { $0.telegramUserId == mapping.telegramUserId }
        mappings.append(mapping)
        save(mappings)
    }

    public static func removeMapping(telegramUserId: Int64) {
        var mappings = load()
        mappings.removeAll { $0.telegramUserId == telegramUserId }
        save(mappings)
    }

    public static func findMapping(telegramUserId: Int64) -> TelegramUserMapping? {
        load().first { $0.telegramUserId == telegramUserId }
    }

    public static func findMapping(familyMemberId: UUID) -> TelegramUserMapping? {
        load().first { $0.familyMemberId == familyMemberId }
    }
}
