//
//  SkillToolProvider.swift
//  OsaurusCore
//
//  Bridges SkillsKit's ToolProvider protocol with OsaurusCore's ToolRegistry and RubeService.
//  Enables skills to execute tools from built-in sources, MCP providers, and Rube.
//

import Foundation

/// Tool provider that bridges SkillsKit with OsaurusCore's tool infrastructure
@MainActor
public final class SkillToolProvider: @unchecked Sendable {
    public static let shared = SkillToolProvider()

    private init() {}

    // MARK: - Tool Provider Protocol Implementation

    /// Check if a tool is available
    public func isToolAvailable(_ toolName: String) async -> Bool {
        // Check ToolRegistry (includes built-in and MCP provider tools)
        let registryTools = await MainActor.run {
            ToolRegistry.shared.listTools()
        }
        if registryTools.contains(where: { $0.name == toolName }) {
            return true
        }

        // Check Rube tools
        let rubeTools = await MainActor.run {
            RubeService.shared.discoveredTools
        }
        if rubeTools.contains(where: { $0.name == toolName || $0.fullName == toolName }) {
            return true
        }

        // Check for tool name variations (with/without provider prefix)
        let normalizedName = normalizeToolName(toolName)
        if registryTools.contains(where: { normalizeToolName($0.name) == normalizedName }) {
            return true
        }

        return false
    }

    /// Execute a tool with parameters
    public func executeTool(_ toolName: String, parameters: [String: Any]) async throws -> String {
        // Convert parameters to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

        // Check if it's a Rube tool
        let rubeTools = await MainActor.run {
            RubeService.shared.discoveredTools
        }
        if let rubeTool = rubeTools.first(where: { $0.name == toolName || $0.fullName == toolName }) {
            return try await RubeService.shared.executeTool(name: rubeTool.name, arguments: parameters)
        }

        // Try ToolRegistry
        return try await MainActor.run {
            try await ToolRegistry.shared.execute(name: toolName, argumentsJSON: jsonString)
        }
    }

    /// Get all available tools grouped by source
    public func availableTools() async -> AvailableTools {
        let registryTools = await MainActor.run {
            ToolRegistry.shared.listTools()
        }

        let rubeConnected = await MainActor.run {
            RubeService.shared.connectionStatus.isConnected
        }

        let rubeTools = await MainActor.run {
            RubeService.shared.discoveredTools
        }

        // Categorize registry tools
        var builtinTools: [String] = []
        var mcpProviderTools: [String] = []

        for tool in registryTools {
            if tool.name.hasPrefix("osaurus.") {
                builtinTools.append(tool.name)
            } else {
                mcpProviderTools.append(tool.name)
            }
        }

        return AvailableTools(
            builtin: builtinTools,
            mcpProviders: mcpProviderTools,
            rube: rubeConnected ? rubeTools.map { $0.fullName } : [],
            rubeConnected: rubeConnected
        )
    }

    /// Check which tools from a list are available
    public func checkToolAvailability(_ toolNames: [String]) async -> [String: Bool] {
        var results: [String: Bool] = [:]
        for name in toolNames {
            results[name] = await isToolAvailable(name)
        }
        return results
    }

    /// Get tool information
    public func toolInfo(_ toolName: String) async -> ToolInfo? {
        // Check ToolRegistry
        let registryTools = await MainActor.run {
            ToolRegistry.shared.listTools()
        }
        if let entry = registryTools.first(where: { $0.name == toolName }) {
            return ToolInfo(
                name: entry.name,
                description: entry.description,
                source: entry.name.hasPrefix("osaurus.") ? .builtin : .mcpProvider,
                isEnabled: entry.isEnabled
            )
        }

        // Check Rube
        let rubeTools = await MainActor.run {
            RubeService.shared.discoveredTools
        }
        if let rubeTool = rubeTools.first(where: { $0.name == toolName || $0.fullName == toolName }) {
            return ToolInfo(
                name: rubeTool.fullName,
                description: "Rube tool: \(rubeTool.name)",
                source: .rube,
                isEnabled: true
            )
        }

        return nil
    }

    // MARK: - Helpers

    private func normalizeToolName(_ name: String) -> String {
        // Remove common prefixes for matching
        let prefixes = ["osaurus.", "rube_", "composio_"]
        var normalized = name.lowercased()
        for prefix in prefixes {
            if normalized.hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count))
                break
            }
        }
        return normalized
    }
}

// MARK: - Supporting Types

/// Summary of available tools by source
public struct AvailableTools: Sendable {
    public let builtin: [String]
    public let mcpProviders: [String]
    public let rube: [String]
    public let rubeConnected: Bool

    public var totalCount: Int {
        builtin.count + mcpProviders.count + rube.count
    }

    public var allTools: [String] {
        builtin + mcpProviders + rube
    }
}

/// Information about a tool
public struct ToolInfo: Sendable {
    public let name: String
    public let description: String
    public let source: ToolSource
    public let isEnabled: Bool

    public init(name: String, description: String, source: ToolSource, isEnabled: Bool) {
        self.name = name
        self.description = description
        self.source = source
        self.isEnabled = isEnabled
    }
}

/// Source of a tool
public enum ToolSource: String, Sendable {
    case builtin = "Built-in"
    case mcpProvider = "MCP Provider"
    case rube = "Rube (Composio)"
}

// MARK: - Skill Capability Checker

/// Checks if skills have their required capabilities available
public struct SkillCapabilityChecker {
    /// Check if all required tools for a capability set are available
    public static func checkCapabilities(
        _ capabilities: SkillCapabilitiesInfo
    ) async -> CapabilityCheckResult {
        var missingRequired: [String] = []
        var missingOptional: [String] = []
        var availableTools: [String] = []

        let provider = SkillToolProvider.shared

        // Check builtin tools
        for tool in capabilities.builtinTools {
            if await provider.isToolAvailable(tool) {
                availableTools.append(tool)
            } else {
                missingRequired.append(tool)
            }
        }

        // Check MCP server tools
        for server in capabilities.mcpServers {
            for tool in server.tools {
                let fullToolName = server.server.map { "\($0).\(tool)" } ?? tool
                if await provider.isToolAvailable(tool) || await provider.isToolAvailable(fullToolName) {
                    availableTools.append(tool)
                } else if server.required {
                    missingRequired.append(tool)
                } else {
                    missingOptional.append(tool)
                }
            }
        }

        return CapabilityCheckResult(
            canExecute: missingRequired.isEmpty,
            availableTools: availableTools,
            missingRequired: missingRequired,
            missingOptional: missingOptional
        )
    }
}

/// Simplified capability info for checking
public struct SkillCapabilitiesInfo {
    public let builtinTools: [String]
    public let mcpServers: [MCPServerInfo]

    public init(builtinTools: [String], mcpServers: [MCPServerInfo]) {
        self.builtinTools = builtinTools
        self.mcpServers = mcpServers
    }
}

/// MCP server info for capability checking
public struct MCPServerInfo {
    public let provider: String
    public let server: String?
    public let tools: [String]
    public let required: Bool

    public init(provider: String, server: String?, tools: [String], required: Bool) {
        self.provider = provider
        self.server = server
        self.tools = tools
        self.required = required
    }
}

/// Result of capability check
public struct CapabilityCheckResult: Sendable {
    public let canExecute: Bool
    public let availableTools: [String]
    public let missingRequired: [String]
    public let missingOptional: [String]

    public var summary: String {
        if canExecute {
            if missingOptional.isEmpty {
                return "All tools available"
            } else {
                return "Ready (optional tools missing: \(missingOptional.joined(separator: ", ")))"
            }
        } else {
            return "Missing required: \(missingRequired.joined(separator: ", "))"
        }
    }
}
