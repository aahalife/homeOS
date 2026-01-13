//
//  RubeService.swift
//  OsaurusCore
//
//  Service for managing Rube (Composio) MCP integration.
//  Handles connection, tool discovery, and tool execution.
//

import Combine
import Foundation

/// Notification posted when Rube connection status changes
extension Notification.Name {
    static let rubeConnectionStatusChanged = Notification.Name("rubeConnectionStatusChanged")
}

/// Service for managing Rube (Composio) MCP connection
@MainActor
public final class RubeService: ObservableObject {
    public static let shared = RubeService()

    // MARK: - Published State

    /// Current configuration
    @Published public private(set) var configuration: RubeConfiguration

    /// Current connection status
    @Published public private(set) var connectionStatus: RubeConnectionStatus

    /// Whether currently connecting
    @Published public private(set) var isConnecting: Bool = false

    /// Discovered tools from Rube
    @Published public private(set) var discoveredTools: [RubeToolInfo] = []

    // MARK: - Private

    /// The underlying MCP provider ID (used with MCPProviderManager)
    private var mcpProviderId: UUID?

    /// Provider name constant
    private static let providerName = "Rube"

    private init() {
        let loadedConfig = RubeConfigurationStore.load()
        self.configuration = loadedConfig
        self.connectionStatus = loadedConfig.lastConnectionStatus ?? RubeConnectionStatus()
    }

    // MARK: - Public API

    /// Check if Rube integration is available (has API key)
    public var isAvailable: Bool {
        RubeConfigurationStore.hasAPIKey()
    }

    /// Enable or disable Rube integration
    public func setEnabled(_ enabled: Bool) {
        configuration.enabled = enabled
        configuration.updatedAt = Date()
        RubeConfigurationStore.save(configuration)

        if enabled && configuration.autoConnect && isAvailable {
            Task {
                await connect()
            }
        } else if !enabled {
            Task {
                await disconnect()
            }
        }
    }

    /// Update the API key
    public func updateAPIKey(_ apiKey: String) -> Bool {
        let success = RubeConfigurationStore.saveAPIKey(apiKey)
        if success {
            // Reconnect if enabled
            if configuration.enabled {
                Task {
                    await disconnect()
                    await connect()
                }
            }
        }
        return success
    }

    /// Remove the API key and disable integration
    public func removeAPIKey() {
        RubeConfigurationStore.deleteAPIKey()
        configuration.enabled = false
        configuration.updatedAt = Date()
        RubeConfigurationStore.save(configuration)

        Task {
            await disconnect()
        }
    }

    /// Connect to Rube MCP server
    public func connect() async {
        guard configuration.enabled else {
            updateStatus(error: "Rube integration is disabled")
            return
        }

        guard let apiKey = RubeConfigurationStore.getAPIKey(), !apiKey.isEmpty else {
            updateStatus(error: "No API key configured")
            return
        }

        isConnecting = true
        defer { isConnecting = false }

        do {
            // Create or get the MCP provider
            let providerId = try await getOrCreateMCPProvider(apiKey: apiKey)
            self.mcpProviderId = providerId

            // Connect via MCPProviderManager
            try await MCPProviderManager.shared.connect(providerId: providerId)

            // Get discovered tools
            let state = MCPProviderManager.shared.providerStates[providerId]
            let tools = state?.discoveredToolNames ?? []

            // Build tool info
            discoveredTools = tools.map { toolName in
                RubeToolInfo(
                    name: toolName,
                    fullName: "\(Self.providerName.lowercased())_\(toolName)",
                    category: categorize(toolName: toolName)
                )
            }

            // Update status
            connectionStatus = RubeConnectionStatus(
                isConnected: true,
                toolCount: tools.count,
                discoveredTools: tools,
                lastError: nil,
                connectedAt: Date()
            )
            configuration.lastConnectionStatus = connectionStatus
            RubeConfigurationStore.save(configuration)

            NotificationCenter.default.post(name: .rubeConnectionStatusChanged, object: nil)

            print("[Oi My AI] Rube connected: \(tools.count) tools discovered")

        } catch {
            updateStatus(error: error.localizedDescription)
            print("[Oi My AI] Rube connection failed: \(error)")
        }
    }

    /// Disconnect from Rube
    public func disconnect() async {
        guard let providerId = mcpProviderId else { return }

        do {
            try await MCPProviderManager.shared.disconnect(providerId: providerId)
        } catch {
            print("[Oi My AI] Rube disconnect error: \(error)")
        }

        discoveredTools = []
        connectionStatus = RubeConnectionStatus(
            isConnected: false,
            toolCount: 0,
            discoveredTools: [],
            lastError: nil,
            connectedAt: nil
        )
        configuration.lastConnectionStatus = connectionStatus
        RubeConfigurationStore.save(configuration)

        NotificationCenter.default.post(name: .rubeConnectionStatusChanged, object: nil)
    }

    /// Test connection without persisting
    public func testConnection(apiKey: String) async -> RubeConnectionStatus {
        do {
            let headers = ["x-api-key": apiKey]
            let toolCount = try await MCPProviderManager.shared.testConnection(
                url: configuration.endpoint,
                token: nil,
                headers: headers
            )

            return RubeConnectionStatus(
                isConnected: true,
                toolCount: toolCount,
                discoveredTools: [],
                lastError: nil,
                connectedAt: Date()
            )
        } catch {
            return RubeConnectionStatus(
                isConnected: false,
                toolCount: 0,
                discoveredTools: [],
                lastError: error.localizedDescription,
                connectedAt: nil
            )
        }
    }

    /// Execute a tool via Rube
    public func executeTool(name: String, arguments: [String: Any]) async throws -> String {
        guard let providerId = mcpProviderId else {
            throw RubeError.notConnected
        }

        guard connectionStatus.isConnected else {
            throw RubeError.notConnected
        }

        // Convert arguments to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: arguments)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        return try await MCPProviderManager.shared.executeTool(
            providerId: providerId,
            toolName: name,
            argumentsJSON: jsonString
        )
    }

    /// Get tools filtered by category
    public func tools(in category: RubeToolCategory) -> [RubeToolInfo] {
        discoveredTools.filter { $0.category == category }
    }

    /// Check if a specific tool is available
    public func hasTools(_ toolName: String) -> Bool {
        discoveredTools.contains { $0.name == toolName || $0.fullName == toolName }
    }

    // MARK: - Private Helpers

    private func getOrCreateMCPProvider(apiKey: String) async throws -> UUID {
        // Check if provider already exists
        if let existingId = mcpProviderId {
            // Update the API key in keychain
            MCPProviderKeychain.saveToken(apiKey, for: existingId)
            return existingId
        }

        // Check if there's already a Rube provider in the list
        let existing = MCPProviderManager.shared.configuration.providers.first { $0.name == Self.providerName }
        if let existing = existing {
            mcpProviderId = existing.id
            MCPProviderKeychain.saveToken(apiKey, for: existing.id)
            return existing.id
        }

        // Create new provider
        let provider = MCPProvider(
            id: UUID(),
            name: Self.providerName,
            url: configuration.endpoint,
            enabled: true,
            customHeaders: [:],
            streamingEnabled: true,
            discoveryTimeout: configuration.discoveryTimeout,
            toolCallTimeout: configuration.toolCallTimeout,
            autoConnect: configuration.autoConnect,
            secretHeaderKeys: ["Authorization"]
        )

        // Save to MCPProviderManager
        await MainActor.run {
            MCPProviderManager.shared.addProvider(provider, token: "Bearer \(apiKey)")
        }
        mcpProviderId = provider.id

        return provider.id
    }

    private func updateStatus(error: String) {
        connectionStatus = RubeConnectionStatus(
            isConnected: false,
            toolCount: 0,
            discoveredTools: [],
            lastError: error,
            connectedAt: nil
        )
        configuration.lastConnectionStatus = connectionStatus
        RubeConfigurationStore.save(configuration)

        NotificationCenter.default.post(name: .rubeConnectionStatusChanged, object: nil)
    }

    private func categorize(toolName: String) -> RubeToolCategory {
        let lowercased = toolName.lowercased()
        for category in RubeToolCategory.allCases {
            for prefix in category.toolPrefixes {
                if lowercased.hasPrefix(prefix) || lowercased.contains(prefix) {
                    return category
                }
            }
        }
        return .other
    }
}

// MARK: - Rube Tool Info

/// Information about a discovered Rube tool
public struct RubeToolInfo: Identifiable, Sendable {
    public var id: String { fullName }

    /// Original tool name from Rube
    public let name: String

    /// Full name as registered in ToolRegistry (prefixed)
    public let fullName: String

    /// Category for organization
    public let category: RubeToolCategory

    public init(name: String, fullName: String, category: RubeToolCategory) {
        self.name = name
        self.fullName = fullName
        self.category = category
    }
}

// MARK: - Rube Errors

/// Errors that can occur with Rube integration
public enum RubeError: Error, LocalizedError {
    case notConnected
    case noAPIKey
    case connectionFailed(String)
    case toolExecutionFailed(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to Rube"
        case .noAPIKey:
            return "No API key configured for Rube"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .toolExecutionFailed(let reason):
            return "Tool execution failed: \(reason)"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - Auto-Connect on Launch

extension RubeService {
    /// Called on app launch to auto-connect if configured
    public func connectIfEnabled() async {
        guard configuration.enabled && configuration.autoConnect && isAvailable else {
            return
        }

        await connect()
    }
}
