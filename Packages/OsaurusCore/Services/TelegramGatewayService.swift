//
//  TelegramGatewayService.swift
//  OsaurusCore
//
//  Telegram Gateway service for Oi My AI.
//  Enables family members to interact via Telegram using long polling.
//

import Combine
import Foundation

// MARK: - Notifications

extension Notification.Name {
    static let telegramConnectionStatusChanged = Notification.Name("telegramConnectionStatusChanged")
    static let telegramMessageReceived = Notification.Name("telegramMessageReceived")
}

// MARK: - Telegram Gateway Service

/// Service for managing Telegram bot gateway
@MainActor
public final class TelegramGatewayService: ObservableObject {
    public static let shared = TelegramGatewayService()

    // MARK: - Published State

    /// Current configuration
    @Published public private(set) var configuration: TelegramConfiguration

    /// Current connection status
    @Published public private(set) var connectionStatus: TelegramConnectionStatus

    /// Whether currently polling
    @Published public private(set) var isPolling: Bool = false

    /// Recent messages (for debugging/display)
    @Published public private(set) var recentMessages: [TelegramIncomingMessage] = []

    // MARK: - Private

    private var pollingTask: Task<Void, Never>?
    private var lastUpdateId: Int64 = 0
    private let baseURL = "https://api.telegram.org/bot"

    /// Rate limiting: track message counts per user
    private var userMessageCounts: [Int64: (count: Int, windowStart: Date)] = [:]

    private init() {
        self.configuration = TelegramConfigurationStore.load()
        self.connectionStatus = configuration.lastConnectionStatus ?? TelegramConnectionStatus()
    }

    // MARK: - Public API

    /// Check if Telegram gateway is available (has bot token)
    public var isAvailable: Bool {
        TelegramConfigurationStore.hasBotToken()
    }

    /// Enable or disable Telegram gateway
    public func setEnabled(_ enabled: Bool) {
        configuration.enabled = enabled
        configuration.updatedAt = Date()
        TelegramConfigurationStore.save(configuration)

        if enabled && isAvailable {
            startPolling()
        } else {
            stopPolling()
        }
    }

    /// Update the bot token
    public func updateBotToken(_ token: String) -> Bool {
        let success = TelegramConfigurationStore.saveBotToken(token)
        if success && configuration.enabled {
            Task {
                await reconnect()
            }
        }
        return success
    }

    /// Remove the bot token and disable gateway
    public func removeBotToken() {
        TelegramConfigurationStore.deleteBotToken()
        configuration.enabled = false
        configuration.updatedAt = Date()
        TelegramConfigurationStore.save(configuration)
        stopPolling()

        connectionStatus = TelegramConnectionStatus()
        NotificationCenter.default.post(name: .telegramConnectionStatusChanged, object: nil)
    }

    /// Start polling for messages
    public func startPolling() {
        guard configuration.enabled else { return }
        guard isAvailable else {
            updateStatus(error: "No bot token configured")
            return
        }
        guard !isPolling else { return }

        isPolling = true
        print("[Oi My AI][Telegram] Starting polling...")

        pollingTask = Task { @MainActor in
            await pollLoop()
        }
    }

    /// Stop polling
    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false

        connectionStatus.isConnected = false
        configuration.lastConnectionStatus = connectionStatus
        TelegramConfigurationStore.save(configuration)

        NotificationCenter.default.post(name: .telegramConnectionStatusChanged, object: nil)
        print("[Oi My AI][Telegram] Stopped polling")
    }

    /// Reconnect (stop and start)
    public func reconnect() async {
        stopPolling()
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        startPolling()
    }

    /// Test connection and get bot info
    public func testConnection() async -> TelegramConnectionStatus {
        guard let token = TelegramConfigurationStore.getBotToken() else {
            return TelegramConnectionStatus(isConnected: false, lastError: "No bot token")
        }

        do {
            let info = try await getBotInfo(token: token)
            return TelegramConnectionStatus(
                isConnected: true,
                botUsername: info.username,
                lastPollTime: Date(),
                messagesProcessed: 0
            )
        } catch {
            return TelegramConnectionStatus(
                isConnected: false,
                lastError: error.localizedDescription
            )
        }
    }

    /// Send a message to a chat
    public func sendMessage(_ message: TelegramOutgoingMessage) async throws {
        guard let token = TelegramConfigurationStore.getBotToken() else {
            throw TelegramError.noToken
        }

        let url = URL(string: "\(baseURL)\(token)/sendMessage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "chat_id": message.chatId,
            "text": message.text
        ]

        if let parseMode = message.parseMode {
            body["parse_mode"] = parseMode
        }

        if let replyTo = message.replyToMessageId {
            body["reply_to_message_id"] = replyTo
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TelegramError.sendFailed("HTTP error")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["ok"] as? Bool == true else {
            throw TelegramError.sendFailed("API error")
        }

        print("[Oi My AI][Telegram] Message sent to chat \(message.chatId)")
    }

    /// Send a proactive message to a family member
    public func sendToFamilyMember(memberId: UUID, text: String) async throws {
        guard let mapping = TelegramUserMappingStore.findMapping(familyMemberId: memberId) else {
            throw TelegramError.userNotLinked
        }

        let message = TelegramOutgoingMessage(chatId: mapping.telegramUserId, text: text)
        try await sendMessage(message)
    }

    // MARK: - Polling Loop

    private func pollLoop() async {
        guard let token = TelegramConfigurationStore.getBotToken() else {
            updateStatus(error: "No bot token")
            isPolling = false
            return
        }

        // Get initial bot info
        do {
            let info = try await getBotInfo(token: token)
            connectionStatus.isConnected = true
            connectionStatus.botUsername = info.username
            connectionStatus.lastError = nil
            configuration.lastConnectionStatus = connectionStatus
            TelegramConfigurationStore.save(configuration)
            NotificationCenter.default.post(name: .telegramConnectionStatusChanged, object: nil)
            print("[Oi My AI][Telegram] Connected as @\(info.username ?? "unknown")")
        } catch {
            updateStatus(error: error.localizedDescription)
            isPolling = false
            return
        }

        // Main polling loop
        while !Task.isCancelled && isPolling {
            do {
                let updates = try await getUpdates(token: token)

                for update in updates {
                    if let message = update.message {
                        await handleIncomingMessage(message, token: token)
                    }

                    // Track highest update ID
                    if update.updateId > lastUpdateId {
                        lastUpdateId = update.updateId
                    }
                }

                connectionStatus.lastPollTime = Date()

            } catch {
                if !Task.isCancelled {
                    print("[Oi My AI][Telegram] Poll error: \(error)")
                    connectionStatus.lastError = error.localizedDescription
                }
            }

            // Wait before next poll
            try? await Task.sleep(nanoseconds: UInt64(configuration.pollingInterval * 1_000_000_000))
        }

        isPolling = false
    }

    private func getUpdates(token: String) async throws -> [TelegramUpdate] {
        var urlComponents = URLComponents(string: "\(baseURL)\(token)/getUpdates")!
        urlComponents.queryItems = [
            URLQueryItem(name: "offset", value: "\(lastUpdateId + 1)"),
            URLQueryItem(name: "limit", value: "\(configuration.maxMessagesPerPoll)"),
            URLQueryItem(name: "timeout", value: "30")
        ]

        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TelegramError.pollFailed("HTTP error")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["ok"] as? Bool == true,
              let result = json["result"] as? [[String: Any]] else {
            throw TelegramError.pollFailed("Invalid response")
        }

        return result.compactMap { TelegramUpdate(from: $0) }
    }

    private func getBotInfo(token: String) async throws -> BotInfo {
        let url = URL(string: "\(baseURL)\(token)/getMe")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TelegramError.connectionFailed("HTTP error")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["ok"] as? Bool == true,
              let result = json["result"] as? [String: Any] else {
            throw TelegramError.connectionFailed("Invalid response")
        }

        return BotInfo(
            id: result["id"] as? Int64 ?? 0,
            username: result["username"] as? String,
            firstName: result["first_name"] as? String
        )
    }

    // MARK: - Message Handling

    private func handleIncomingMessage(_ message: TelegramMessageData, token: String) async {
        let incoming = TelegramIncomingMessage(
            id: message.messageId,
            chatId: message.chatId,
            userId: message.userId,
            username: message.username,
            firstName: message.firstName,
            text: message.text ?? "",
            date: Date(timeIntervalSince1970: TimeInterval(message.date))
        )

        // Add to recent messages
        recentMessages.insert(incoming, at: 0)
        if recentMessages.count > 50 {
            recentMessages = Array(recentMessages.prefix(50))
        }

        connectionStatus.messagesProcessed += 1

        // Check rate limit
        if !checkRateLimit(userId: incoming.userId) {
            print("[Oi My AI][Telegram] Rate limited user \(incoming.userId)")
            return
        }

        // Check family membership if required
        if configuration.requireFamilyMembership {
            let mapping = TelegramUserMappingStore.findMapping(telegramUserId: incoming.userId)

            if mapping == nil {
                // Try to auto-link by username
                if let username = incoming.username,
                   let member = FamilyManager.shared.member(withTelegramHandle: username) {
                    // Auto-link
                    let newMapping = TelegramUserMapping(
                        telegramUserId: incoming.userId,
                        telegramUsername: username,
                        familyMemberId: member.id
                    )
                    TelegramUserMappingStore.addMapping(newMapping)
                    print("[Oi My AI][Telegram] Auto-linked @\(username) to \(member.name)")
                } else {
                    // Not a family member
                    if let reply = configuration.nonFamilyReplyMessage {
                        let response = TelegramOutgoingMessage(
                            chatId: incoming.chatId,
                            text: reply,
                            replyToMessageId: incoming.id
                        )
                        try? await sendMessage(response)
                    }
                    return
                }
            }
        }

        // Post notification for processing
        NotificationCenter.default.post(
            name: .telegramMessageReceived,
            object: nil,
            userInfo: ["message": incoming]
        )

        // Process message through skill/chat system
        await processMessage(incoming)
    }

    private func processMessage(_ message: TelegramIncomingMessage) async {
        // Skip empty messages
        guard !message.text.isEmpty else { return }

        // Get family member context if available
        let mapping = TelegramUserMappingStore.findMapping(telegramUserId: message.userId)
        let memberId = mapping?.familyMemberId

        // Check quiet hours
        if let memberId = memberId, FamilyManager.shared.isInQuietHours(memberId: memberId) {
            // Don't process during quiet hours (but allow through for now - just log)
            print("[Oi My AI][Telegram] User \(message.displayName) is in quiet hours")
        }

        // Try fast-path skill execution first
        if let match = await IntentMatcher.shared.bestMatch(input: message.text),
           match.confidence >= 0.75 {
            // Check if member can execute this skill
            if let memberId = memberId,
               !FamilyManager.shared.canExecuteSkill(memberId: memberId, skillId: match.skill.id) {
                let response = TelegramOutgoingMessage(
                    chatId: message.chatId,
                    text: "Sorry, you don't have permission to use this skill.",
                    replyToMessageId: message.id
                )
                try? await sendMessage(response)
                return
            }

            // Execute skill
            let context = SkillSessionContext(
                sessionId: "telegram_\(message.chatId)",
                lastUserInput: message.text,
                familyMemberId: memberId?.uuidString
            )

            let result = await SkillIntegrationService.shared.executeFastPath(
                match: match,
                userInput: message.text,
                sessionContext: context
            )

            let response = TelegramOutgoingMessage(
                chatId: message.chatId,
                text: result.response,
                replyToMessageId: message.id
            )
            try? await sendMessage(response)
            return
        }

        // Fall back to simple acknowledgment for now
        // In production, this would route to the LLM
        let response = TelegramOutgoingMessage(
            chatId: message.chatId,
            text: "I received your message. Processing with AI is not yet implemented for Telegram.",
            replyToMessageId: message.id
        )
        try? await sendMessage(response)
    }

    // MARK: - Rate Limiting

    private func checkRateLimit(userId: Int64) -> Bool {
        let now = Date()
        let windowDuration: TimeInterval = 60 // 1 minute window

        if let record = userMessageCounts[userId] {
            if now.timeIntervalSince(record.windowStart) < windowDuration {
                // Within window
                if record.count >= configuration.rateLimitPerMinute {
                    return false // Rate limited
                }
                userMessageCounts[userId] = (record.count + 1, record.windowStart)
            } else {
                // New window
                userMessageCounts[userId] = (1, now)
            }
        } else {
            // First message from this user
            userMessageCounts[userId] = (1, now)
        }

        return true
    }

    // MARK: - Helpers

    private func updateStatus(error: String) {
        connectionStatus = TelegramConnectionStatus(isConnected: false, lastError: error)
        configuration.lastConnectionStatus = connectionStatus
        TelegramConfigurationStore.save(configuration)
        NotificationCenter.default.post(name: .telegramConnectionStatusChanged, object: nil)
    }
}

// MARK: - Internal Types

private struct BotInfo {
    let id: Int64
    let username: String?
    let firstName: String?
}

private struct TelegramUpdate {
    let updateId: Int64
    let message: TelegramMessageData?

    init?(from json: [String: Any]) {
        guard let updateId = json["update_id"] as? Int64 else { return nil }
        self.updateId = updateId

        if let msgJson = json["message"] as? [String: Any] {
            self.message = TelegramMessageData(from: msgJson)
        } else {
            self.message = nil
        }
    }
}

private struct TelegramMessageData {
    let messageId: Int64
    let chatId: Int64
    let userId: Int64
    let username: String?
    let firstName: String?
    let text: String?
    let date: Int64

    init?(from json: [String: Any]) {
        guard let messageId = json["message_id"] as? Int64,
              let chat = json["chat"] as? [String: Any],
              let chatId = chat["id"] as? Int64,
              let from = json["from"] as? [String: Any],
              let userId = from["id"] as? Int64,
              let date = json["date"] as? Int64 else {
            return nil
        }

        self.messageId = messageId
        self.chatId = chatId
        self.userId = userId
        self.username = from["username"] as? String
        self.firstName = from["first_name"] as? String
        self.text = json["text"] as? String
        self.date = date
    }
}

// MARK: - Telegram Errors

public enum TelegramError: Error, LocalizedError {
    case noToken
    case connectionFailed(String)
    case pollFailed(String)
    case sendFailed(String)
    case userNotLinked
    case rateLimited

    public var errorDescription: String? {
        switch self {
        case .noToken:
            return "No bot token configured"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .pollFailed(let reason):
            return "Polling failed: \(reason)"
        case .sendFailed(let reason):
            return "Send failed: \(reason)"
        case .userNotLinked:
            return "User not linked to a family member"
        case .rateLimited:
            return "Rate limited"
        }
    }
}

// MARK: - Auto-Connect on Launch

extension TelegramGatewayService {
    /// Called on app launch to auto-connect if configured
    public func connectIfEnabled() {
        guard configuration.enabled && isAvailable else { return }
        startPolling()
    }
}
