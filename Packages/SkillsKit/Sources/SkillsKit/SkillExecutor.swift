//
//  SkillExecutor.swift
//  SkillsKit
//
//  Executes skills by orchestrating tool calls based on the skill definition.
//  Designed for deterministic execution by small LLMs.
//

import Foundation

/// Delegate protocol for skill execution callbacks
public protocol SkillExecutorDelegate: AnyObject, Sendable {
    /// Called before executing a tool step
    func skillExecutor(_ executor: SkillExecutor, willExecuteStep step: ToolStep, in skill: SkillDefinition)
    /// Called after executing a tool step
    func skillExecutor(
        _ executor: SkillExecutor, didExecuteStep step: ToolStep, result: ToolResult, in skill: SkillDefinition
    )
    /// Called when approval is required
    func skillExecutor(
        _ executor: SkillExecutor, requiresApprovalFor step: ToolStep, in skill: SkillDefinition
    ) async -> Bool
    /// Called when an error occurs
    func skillExecutor(
        _ executor: SkillExecutor, encounteredError error: SkillExecutionError, at step: ToolStep?,
        in skill: SkillDefinition
    )
    /// Called when skill execution completes
    func skillExecutor(
        _ executor: SkillExecutor, didCompleteSkill skill: SkillDefinition, results: [ToolResult]
    )
}

/// Result of a tool execution
public struct ToolResult: Sendable {
    public let step: Int
    public let tool: String
    public let success: Bool
    public let output: String?
    public let error: String?
    public let duration: TimeInterval

    public init(
        step: Int, tool: String, success: Bool, output: String? = nil, error: String? = nil,
        duration: TimeInterval = 0
    ) {
        self.step = step
        self.tool = tool
        self.success = success
        self.output = output
        self.error = error
        self.duration = duration
    }
}

/// Errors that can occur during skill execution
public enum SkillExecutionError: Error, Sendable {
    case missingCapability(String)
    case toolNotAvailable(String)
    case stepFailed(Int, String)
    case approvalDenied(Int)
    case timeout(Int)
    case safetyViolation(String)
    case cancelled
}

/// Context for skill execution
public struct SkillContext: Sendable {
    /// Parameters extracted from user input
    public let parameters: [String: String]
    /// User ID for multi-tenant scenarios
    public let userId: String?
    /// Family member context (e.g., which child's schedule)
    public let familyMemberId: String?
    /// Session ID for tracking
    public let sessionId: String

    public init(
        parameters: [String: String] = [:],
        userId: String? = nil,
        familyMemberId: String? = nil,
        sessionId: String = UUID().uuidString
    ) {
        self.parameters = parameters
        self.userId = userId
        self.familyMemberId = familyMemberId
        self.sessionId = sessionId
    }
}

/// Protocol for tool providers (MCP servers, built-in tools, etc.)
public protocol ToolProvider: Sendable {
    /// Check if a tool is available
    func isToolAvailable(_ toolName: String) async -> Bool
    /// Execute a tool with parameters
    func executeTool(_ toolName: String, parameters: [String: Any]) async throws -> String
}

/// Executes skills by orchestrating tool calls
public actor SkillExecutor {
    /// Delegate for execution callbacks
    public weak var delegate: SkillExecutorDelegate?

    /// Tool provider for executing tools
    private let toolProvider: ToolProvider

    /// Current execution state
    private var isExecuting = false
    private var currentSkill: SkillDefinition?
    private var currentStep: Int = 0
    private var results: [ToolResult] = []

    public init(toolProvider: ToolProvider) {
        self.toolProvider = toolProvider
    }

    // MARK: - Public API

    /// Execute a skill with the given context
    public func execute(skill: SkillDefinition, context: SkillContext) async throws -> [ToolResult] {
        guard !isExecuting else {
            throw SkillExecutionError.cancelled
        }

        isExecuting = true
        currentSkill = skill
        currentStep = 0
        results = []

        defer {
            isExecuting = false
            currentSkill = nil
        }

        // Check safety constraints first
        if let safety = skill.safetyConstraints {
            try checkSafetyConstraints(safety, context: context)
        }

        // Check capabilities
        try await checkCapabilities(skill.capabilities)

        // Execute tool sequence
        let sequence =
            try await canExecutePrimarySequence(skill)
            ? skill.toolSequence
            : (skill.fallbackSequence ?? skill.toolSequence)

        for step in sequence.sorted(by: { $0.step < $1.step }) {
            currentStep = step.step

            // Check condition
            if let condition = step.condition, !evaluateCondition(condition, context: context, results: results) {
                continue
            }

            // Notify delegate
            await delegate?.skillExecutor(self, willExecuteStep: step, in: skill)

            // Check approval
            if step.requiresApproval {
                let approved = await delegate?.skillExecutor(
                    self, requiresApprovalFor: step, in: skill
                ) ?? false
                if !approved {
                    throw SkillExecutionError.approvalDenied(step.step)
                }
            }

            // Execute the step
            let result = await executeStep(step, context: context)
            results.append(result)

            // Notify delegate
            await delegate?.skillExecutor(self, didExecuteStep: step, result: result, in: skill)

            // Handle errors
            if !result.success {
                if let errorHandling = step.onError {
                    try await handleError(errorHandling, step: step, context: context)
                } else {
                    throw SkillExecutionError.stepFailed(step.step, result.error ?? "Unknown error")
                }
            }
        }

        // Notify completion
        await delegate?.skillExecutor(self, didCompleteSkill: skill, results: results)

        return results
    }

    /// Cancel current execution
    public func cancel() {
        isExecuting = false
    }

    /// Get current execution status
    public func status() -> (isExecuting: Bool, currentStep: Int, skill: String?) {
        return (isExecuting, currentStep, currentSkill?.id)
    }

    // MARK: - Private

    private func checkSafetyConstraints(_ safety: SafetyConstraints, context: SkillContext) throws {
        // Check for emergency keywords in parameters
        let inputText =
            context.parameters.values.joined(separator: " ").lowercased()
        for keyword in safety.emergencyKeywords {
            if inputText.contains(keyword.lowercased()) {
                throw SkillExecutionError.safetyViolation(
                    "Emergency keyword detected: \(keyword). \(safety.emergencyAction ?? "Please contact emergency services if needed.")"
                )
            }
        }
    }

    private func checkCapabilities(_ capabilities: SkillCapabilities) async throws {
        // Check MCP server requirements
        for server in capabilities.mcpServers where server.required {
            for tool in server.tools {
                let available = await toolProvider.isToolAvailable(tool)
                if !available {
                    throw SkillExecutionError.missingCapability(
                        "Required tool not available: \(tool) (from \(server.provider))"
                    )
                }
            }
        }

        // Check built-in tools
        for tool in capabilities.builtinTools {
            let available = await toolProvider.isToolAvailable(tool)
            if !available {
                throw SkillExecutionError.toolNotAvailable(tool)
            }
        }
    }

    private func canExecutePrimarySequence(_ skill: SkillDefinition) async -> Bool {
        for step in skill.toolSequence {
            let available = await toolProvider.isToolAvailable(step.tool)
            if !available {
                return false
            }
        }
        return true
    }

    private func executeStep(_ step: ToolStep, context: SkillContext) async -> ToolResult {
        let startTime = Date()

        // Build parameters
        var params: [String: Any] = [:]
        for param in step.params {
            if let value = context.parameters[param] {
                params[param] = value
            }
        }
        // Add static params
        if let staticParams = step.staticParams {
            for (key, value) in staticParams {
                params[key] = value.value
            }
        }

        do {
            let output = try await toolProvider.executeTool(step.tool, parameters: params)
            let duration = Date().timeIntervalSince(startTime)
            return ToolResult(
                step: step.step,
                tool: step.tool,
                success: true,
                output: output,
                duration: duration
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return ToolResult(
                step: step.step,
                tool: step.tool,
                success: false,
                error: error.localizedDescription,
                duration: duration
            )
        }
    }

    private func handleError(_ handling: ErrorHandling, step: ToolStep, context: SkillContext) async throws {
        switch handling.action {
        case "skip":
            return  // Continue to next step
        case "retry":
            let maxRetries = handling.retries ?? 3
            for _ in 0..<maxRetries {
                let result = await executeStep(step, context: context)
                if result.success {
                    results.append(result)
                    return
                }
            }
            throw SkillExecutionError.stepFailed(step.step, "Retries exhausted")
        case "fallback":
            if let fallbackTool = handling.fallbackTool {
                var fallbackStep = step
                // Create a modified step with fallback tool
                let modifiedStep = ToolStep(
                    step: step.step,
                    tool: fallbackTool,
                    params: step.params,
                    staticParams: step.staticParams,
                    requiresApproval: step.requiresApproval,
                    condition: step.condition,
                    description: "Fallback: \(step.description ?? "")",
                    onError: nil
                )
                let result = await executeStep(modifiedStep, context: context)
                results.append(result)
                if !result.success {
                    throw SkillExecutionError.stepFailed(step.step, "Fallback also failed")
                }
            }
        case "abort":
            throw SkillExecutionError.stepFailed(step.step, handling.userMessage ?? "Step failed, aborting")
        default:
            throw SkillExecutionError.stepFailed(step.step, "Unknown error handling action")
        }
    }

    private func evaluateCondition(_ condition: String, context: SkillContext, results: [ToolResult]) -> Bool {
        // Simple condition evaluation - can be expanded
        // Format: "variable == value" or "variable != value"
        let parts = condition.components(separatedBy: " ")
        guard parts.count >= 3 else { return true }

        let variable = parts[0]
        let op = parts[1]
        let value = parts[2...].joined(separator: " ")

        // Check context parameters
        if let contextValue = context.parameters[variable] {
            switch op {
            case "==": return contextValue == value
            case "!=": return contextValue != value
            default: return true
            }
        }

        // Check previous results
        for result in results {
            if result.tool == variable, let output = result.output {
                switch op {
                case "==": return output == value
                case "!=": return output != value
                case "contains": return output.contains(value)
                default: return true
                }
            }
        }

        return true
    }
}

// MARK: - Mock Tool Provider (for testing)

/// Mock tool provider for testing skills
public final class MockToolProvider: ToolProvider, @unchecked Sendable {
    private var availableTools: Set<String>
    private var toolResponses: [String: String]

    public init(
        availableTools: Set<String> = [],
        toolResponses: [String: String] = [:]
    ) {
        self.availableTools = availableTools
        self.toolResponses = toolResponses
    }

    public func registerTool(_ name: String, response: String = "OK") {
        availableTools.insert(name)
        toolResponses[name] = response
    }

    public func isToolAvailable(_ toolName: String) async -> Bool {
        availableTools.contains(toolName)
    }

    public func executeTool(_ toolName: String, parameters: [String: Any]) async throws -> String {
        guard availableTools.contains(toolName) else {
            throw SkillExecutionError.toolNotAvailable(toolName)
        }
        return toolResponses[toolName] ?? "Executed \(toolName)"
    }
}
