//
//  ConsentManager.swift
//  OsaurusCore
//
//  Manages user consent and approvals for sensitive operations in Oi My AI.
//  Provides persistent consent storage and approval workflows.
//

import Foundation

// MARK: - Consent Types

/// Categories of operations that may require consent
public enum ConsentCategory: String, Codable, Sendable, CaseIterable {
    case toolExecution = "tool_execution"
    case dataAccess = "data_access"
    case externalApi = "external_api"
    case fileSystem = "file_system"
    case network = "network"
    case systemCommands = "system_commands"
    case purchases = "purchases"
    case sharing = "sharing"
}

/// Duration of consent validity
public enum ConsentDuration: String, Codable, Sendable {
    case once = "once"
    case session = "session"
    case hour = "hour"
    case day = "day"
    case week = "week"
    case always = "always"

    var timeInterval: TimeInterval? {
        switch self {
        case .once: return 0
        case .session: return nil // Special handling
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .always: return nil
        }
    }
}

/// A specific consent record
public struct ConsentRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let category: ConsentCategory
    public let actionId: String
    public let description: String
    public let duration: ConsentDuration
    public let grantedAt: Date
    public let grantedBy: UUID? // Family member ID
    public let expiresAt: Date?
    public let metadata: [String: String]?

    public init(
        id: UUID = UUID(),
        category: ConsentCategory,
        actionId: String,
        description: String,
        duration: ConsentDuration,
        grantedAt: Date = Date(),
        grantedBy: UUID? = nil,
        expiresAt: Date? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.category = category
        self.actionId = actionId
        self.description = description
        self.duration = duration
        self.grantedAt = grantedAt
        self.grantedBy = grantedBy
        self.expiresAt = expiresAt
        self.metadata = metadata
    }

    public var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
}

/// Request for consent
public struct ConsentRequest: Sendable {
    public let category: ConsentCategory
    public let actionId: String
    public let title: String
    public let description: String
    public let riskLevel: RiskLevel
    public let suggestedDuration: ConsentDuration
    public let requiredPermissions: [String]?

    public enum RiskLevel: String, Sendable {
        case low
        case medium
        case high
        case critical
    }

    public init(
        category: ConsentCategory,
        actionId: String,
        title: String,
        description: String,
        riskLevel: RiskLevel = .medium,
        suggestedDuration: ConsentDuration = .session,
        requiredPermissions: [String]? = nil
    ) {
        self.category = category
        self.actionId = actionId
        self.title = title
        self.description = description
        self.riskLevel = riskLevel
        self.suggestedDuration = suggestedDuration
        self.requiredPermissions = requiredPermissions
    }
}

// MARK: - Consent Manager

/// Manages consent records and approval workflows
@MainActor
public final class ConsentManager: ObservableObject {
    public static let shared = ConsentManager()

    // MARK: - Published State

    /// Active consent records
    @Published public private(set) var consents: [ConsentRecord] = []

    /// Pending consent requests
    @Published public private(set) var pendingRequests: [ConsentRequest] = []

    // MARK: - Private

    private let sessionId = UUID()
    private var sessionConsents: Set<String> = []

    private init() {
        loadConsents()
        cleanupExpired()
    }

    // MARK: - Public API

    /// Check if consent exists for an action
    public func hasConsent(category: ConsentCategory, actionId: String) -> Bool {
        // Check session consents
        let sessionKey = "\(category.rawValue):\(actionId)"
        if sessionConsents.contains(sessionKey) {
            return true
        }

        // Check persistent consents
        return consents.contains { consent in
            consent.category == category &&
            consent.actionId == actionId &&
            !consent.isExpired
        }
    }

    /// Grant consent for an action
    public func grant(
        category: ConsentCategory,
        actionId: String,
        description: String,
        duration: ConsentDuration,
        grantedBy: UUID? = nil,
        metadata: [String: String]? = nil
    ) {
        // Handle session consent
        if duration == .session {
            let sessionKey = "\(category.rawValue):\(actionId)"
            sessionConsents.insert(sessionKey)
            return
        }

        // Calculate expiry
        var expiresAt: Date? = nil
        if let interval = duration.timeInterval, interval > 0 {
            expiresAt = Date().addingTimeInterval(interval)
        } else if duration == .once {
            expiresAt = Date() // Expires immediately after use
        }

        let record = ConsentRecord(
            category: category,
            actionId: actionId,
            description: description,
            duration: duration,
            grantedBy: grantedBy,
            expiresAt: expiresAt,
            metadata: metadata
        )

        // Remove existing consent for same action
        consents.removeAll { $0.category == category && $0.actionId == actionId }
        consents.append(record)
        saveConsents()

        logInfo("Consent granted: \(category.rawValue)/\(actionId) for \(duration.rawValue)", category: .security)
    }

    /// Revoke consent for an action
    public func revoke(category: ConsentCategory, actionId: String) {
        // Remove session consent
        let sessionKey = "\(category.rawValue):\(actionId)"
        sessionConsents.remove(sessionKey)

        // Remove persistent consent
        consents.removeAll { $0.category == category && $0.actionId == actionId }
        saveConsents()

        logInfo("Consent revoked: \(category.rawValue)/\(actionId)", category: .security)
    }

    /// Revoke all consents for a category
    public func revokeAll(category: ConsentCategory) {
        sessionConsents = sessionConsents.filter { !$0.hasPrefix(category.rawValue) }
        consents.removeAll { $0.category == category }
        saveConsents()

        logInfo("All consents revoked for category: \(category.rawValue)", category: .security)
    }

    /// Revoke all consents
    public func revokeAllConsents() {
        sessionConsents.removeAll()
        consents.removeAll()
        saveConsents()

        logInfo("All consents revoked", category: .security)
    }

    /// Use a one-time consent (marks it as expired)
    public func useOnceConsent(category: ConsentCategory, actionId: String) {
        if let index = consents.firstIndex(where: {
            $0.category == category && $0.actionId == actionId && $0.duration == .once
        }) {
            consents.remove(at: index)
            saveConsents()
        }
    }

    /// Get all consents for a category
    public func consents(for category: ConsentCategory) -> [ConsentRecord] {
        consents.filter { $0.category == category && !$0.isExpired }
    }

    /// Get all active (non-expired) consents
    public func activeConsents() -> [ConsentRecord] {
        consents.filter { !$0.isExpired }
    }

    // MARK: - Consent Requests

    /// Add a pending consent request
    public func requestConsent(_ request: ConsentRequest) {
        guard !pendingRequests.contains(where: {
            $0.category == request.category && $0.actionId == request.actionId
        }) else { return }

        pendingRequests.append(request)

        logInfo("Consent requested: \(request.category.rawValue)/\(request.actionId)", category: .security)
    }

    /// Approve a pending request
    public func approveRequest(_ request: ConsentRequest, duration: ConsentDuration, grantedBy: UUID? = nil) {
        grant(
            category: request.category,
            actionId: request.actionId,
            description: request.description,
            duration: duration,
            grantedBy: grantedBy
        )

        pendingRequests.removeAll {
            $0.category == request.category && $0.actionId == request.actionId
        }
    }

    /// Deny a pending request
    public func denyRequest(_ request: ConsentRequest) {
        pendingRequests.removeAll {
            $0.category == request.category && $0.actionId == request.actionId
        }

        logInfo("Consent denied: \(request.category.rawValue)/\(request.actionId)", category: .security)
    }

    // MARK: - Persistence

    private static let consentsKey = "OiMyAI_Consents"

    private func loadConsents() {
        guard let data = UserDefaults.standard.data(forKey: Self.consentsKey) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            consents = try decoder.decode([ConsentRecord].self, from: data)
        } catch {
            logError("Failed to load consents: \(error)", category: .security)
        }
    }

    private func saveConsents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(consents)
            UserDefaults.standard.set(data, forKey: Self.consentsKey)
        } catch {
            logError("Failed to save consents: \(error)", category: .security)
        }
    }

    private func cleanupExpired() {
        let before = consents.count
        consents.removeAll { $0.isExpired }
        let removed = before - consents.count

        if removed > 0 {
            saveConsents()
            logDebug("Cleaned up \(removed) expired consents", category: .security)
        }
    }
}

// MARK: - Convenience Extensions

extension ConsentManager {
    /// Check consent for tool execution
    public func hasToolConsent(toolId: String) -> Bool {
        hasConsent(category: .toolExecution, actionId: toolId)
    }

    /// Grant consent for tool execution
    public func grantToolConsent(toolId: String, duration: ConsentDuration = .session) {
        grant(
            category: .toolExecution,
            actionId: toolId,
            description: "Execute tool: \(toolId)",
            duration: duration
        )
    }

    /// Check consent for external API
    public func hasApiConsent(apiId: String) -> Bool {
        hasConsent(category: .externalApi, actionId: apiId)
    }

    /// Grant consent for external API
    public func grantApiConsent(apiId: String, duration: ConsentDuration = .session) {
        grant(
            category: .externalApi,
            actionId: apiId,
            description: "Access API: \(apiId)",
            duration: duration
        )
    }
}

// MARK: - Tool Consent Helpers

extension ConsentManager {
    /// Create a consent request for a tool
    public static func toolRequest(
        toolId: String,
        toolName: String,
        description: String,
        riskLevel: ConsentRequest.RiskLevel = .medium
    ) -> ConsentRequest {
        ConsentRequest(
            category: .toolExecution,
            actionId: toolId,
            title: "Execute \(toolName)",
            description: description,
            riskLevel: riskLevel,
            suggestedDuration: .session
        )
    }
}
