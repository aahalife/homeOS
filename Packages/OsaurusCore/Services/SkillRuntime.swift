//
//  SkillRuntime.swift
//  OsaurusCore
//
//  Executes skills using SkillExecutor and SkillToolProvider.
//  Manages the lifecycle of skill execution with approval gates and audit trails.
//

import Foundation
import SkillsKit

// MARK: - Skill Execution Result

/// Result of a skill execution
public struct SkillExecutionResult: Sendable {
    /// Whether the skill completed successfully
    public let success: Bool

    /// The skill that was executed
    public let skillId: String

    /// Human-readable response message
    public let response: String

    /// Individual step results
    public let stepResults: [StepExecutionResult]

    /// Total execution time in seconds
    public let executionTime: TimeInterval

    /// Any error that occurred
    public let error: SkillRuntimeError?

    /// Audit trail for compliance/debugging
    public let auditTrail: [AuditEntry]

    public init(
        success: Bool,
        skillId: String,
        response: String,
        stepResults: [StepExecutionResult],
        executionTime: TimeInterval,
        error: SkillRuntimeError? = nil,
        auditTrail: [AuditEntry] = []
    ) {
        self.success = success
        self.skillId = skillId
        self.response = response
        self.stepResults = stepResults
        self.executionTime = executionTime
        self.error = error
        self.auditTrail = auditTrail
    }
}

/// Result of a single step execution
public struct StepExecutionResult: Sendable {
    public let stepNumber: Int
    public let toolName: String
    public let success: Bool
    public let output: String?
    public let error: String?
    public let duration: TimeInterval

    public init(
        stepNumber: Int,
        toolName: String,
        success: Bool,
        output: String? = nil,
        error: String? = nil,
        duration: TimeInterval = 0
    ) {
        self.stepNumber = stepNumber
        self.toolName = toolName
        self.success = success
        self.output = output
        self.error = error
        self.duration = duration
    }
}

/// Audit entry for skill execution
public struct AuditEntry: Sendable {
    public let timestamp: Date
    public let event: String
    public let details: String?

    public init(timestamp: Date = Date(), event: String, details: String? = nil) {
        self.timestamp = timestamp
        self.event = event
        self.details = details
    }
}

// MARK: - Skill Runtime Errors

public enum SkillRuntimeError: Error, LocalizedError, Sendable {
    case skillNotFound(String)
    case missingRequiredTool(String)
    case approvalDenied(step: Int)
    case approvalTimeout(step: Int)
    case stepExecutionFailed(step: Int, reason: String)
    case safetyViolation(String)
    case cancelled
    case timeout

    public var errorDescription: String? {
        switch self {
        case .skillNotFound(let id):
            return "Skill not found: \(id)"
        case .missingRequiredTool(let tool):
            return "Required tool not available: \(tool)"
        case .approvalDenied(let step):
            return "User denied approval for step \(step)"
        case .approvalTimeout(let step):
            return "Approval timeout for step \(step)"
        case .stepExecutionFailed(let step, let reason):
            return "Step \(step) failed: \(reason)"
        case .safetyViolation(let reason):
            return "Safety constraint violated: \(reason)"
        case .cancelled:
            return "Skill execution was cancelled"
        case .timeout:
            return "Skill execution timed out"
        }
    }
}

// MARK: - Approval Request

/// Request for user approval before executing a high-risk step
public struct ApprovalRequest: Sendable {
    public let skillId: String
    public let skillName: String
    public let stepNumber: Int
    public let toolName: String
    public let description: String
    public let riskLevel: RiskLevel
    public let parameters: [String: String]

    public enum RiskLevel: String, Sendable {
        case high
        case medium
        case low
    }
}

// MARK: - Skill Runtime Delegate

/// Delegate for handling runtime events
@MainActor
public protocol SkillRuntimeDelegate: AnyObject, Sendable {
    /// Called when approval is needed for a step
    func skillRuntime(_ runtime: SkillRuntime, needsApprovalFor request: ApprovalRequest) async -> Bool

    /// Called when a step starts executing
    func skillRuntime(_ runtime: SkillRuntime, didStartStep step: Int, tool: String)

    /// Called when a step completes
    func skillRuntime(_ runtime: SkillRuntime, didCompleteStep step: Int, result: StepExecutionResult)

    /// Called when skill execution completes
    func skillRuntime(_ runtime: SkillRuntime, didComplete result: SkillExecutionResult)
}

// Default implementations
extension SkillRuntimeDelegate {
    public func skillRuntime(_ runtime: SkillRuntime, didStartStep step: Int, tool: String) {}
    public func skillRuntime(_ runtime: SkillRuntime, didCompleteStep step: Int, result: StepExecutionResult) {}
    public func skillRuntime(_ runtime: SkillRuntime, didComplete result: SkillExecutionResult) {}
}

// MARK: - Skill Runtime

/// Runtime for executing skills
@MainActor
public final class SkillRuntime: @unchecked Sendable {
    public static let shared = SkillRuntime()

    /// Delegate for runtime events
    public weak var delegate: SkillRuntimeDelegate?

    /// Default timeout for approval requests (seconds)
    public var approvalTimeout: TimeInterval = 30

    /// Maximum execution time for a skill (seconds)
    public var maxExecutionTime: TimeInterval = 300

    /// Whether to run safety checks
    public var enableSafetyChecks: Bool = true

    private var currentExecution: Task<SkillExecutionResult, Error>?

    private init() {}

    // MARK: - Public API

    /// Execute a skill by ID with the given parameters
    public func execute(
        skillId: String,
        parameters: [String: Any],
        context: SkillExecutionContext = SkillExecutionContext()
    ) async throws -> SkillExecutionResult {
        let startTime = Date()
        var auditTrail: [AuditEntry] = []

        auditTrail.append(AuditEntry(event: "execution_started", details: "Skill: \(skillId)"))

        // 1. Load the skill
        guard let skill = SkillLoader.shared.skill(withId: skillId) else {
            throw SkillRuntimeError.skillNotFound(skillId)
        }

        auditTrail.append(AuditEntry(event: "skill_loaded", details: skill.name))

        // 2. Check safety constraints
        if enableSafetyChecks, let safety = skill.safetyConstraints {
            if let violation = checkSafetyConstraints(safety, input: context.userInput) {
                auditTrail.append(AuditEntry(event: "safety_violation", details: violation))
                throw SkillRuntimeError.safetyViolation(violation)
            }
        }

        // 3. Check tool availability
        let capabilitiesInfo = buildCapabilitiesInfo(skill)
        let capabilityCheck = await SkillCapabilityChecker.checkCapabilities(capabilitiesInfo)

        if !capabilityCheck.canExecute {
            let missing = capabilityCheck.missingRequired.first ?? "unknown"
            auditTrail.append(AuditEntry(event: "missing_tools", details: missing))
            throw SkillRuntimeError.missingRequiredTool(missing)
        }

        auditTrail.append(AuditEntry(event: "tools_verified", details: "\(capabilityCheck.availableTools.count) tools available"))

        // 4. Execute tool sequence
        var stepResults: [StepExecutionResult] = []
        let toolProvider = SkillToolProvider.shared

        for step in skill.toolSequence {
            // Check if step condition is met
            if let condition = step.condition, !evaluateCondition(condition, params: parameters) {
                auditTrail.append(AuditEntry(event: "step_skipped", details: "Step \(step.step): condition not met"))
                continue
            }

            // Check if approval is needed
            if step.requiresApproval || isHighRiskStep(step, skill: skill) {
                let approved = await requestApproval(step: step, skill: skill, parameters: parameters)
                if !approved {
                    auditTrail.append(AuditEntry(event: "approval_denied", details: "Step \(step.step)"))
                    throw SkillRuntimeError.approvalDenied(step: step.step)
                }
                auditTrail.append(AuditEntry(event: "approval_granted", details: "Step \(step.step)"))
            }

            // Execute the step
            delegate?.skillRuntime(self, didStartStep: step.step, tool: step.tool)
            auditTrail.append(AuditEntry(event: "step_started", details: "Step \(step.step): \(step.tool)"))

            let stepStart = Date()
            do {
                let toolParams = buildToolParameters(step: step, userParams: parameters, previousResults: stepResults)
                let output = try await toolProvider.executeTool(step.tool, parameters: toolParams)

                let stepResult = StepExecutionResult(
                    stepNumber: step.step,
                    toolName: step.tool,
                    success: true,
                    output: output,
                    duration: Date().timeIntervalSince(stepStart)
                )
                stepResults.append(stepResult)
                delegate?.skillRuntime(self, didCompleteStep: step.step, result: stepResult)
                auditTrail.append(AuditEntry(event: "step_completed", details: "Step \(step.step) succeeded"))

            } catch {
                let stepResult = StepExecutionResult(
                    stepNumber: step.step,
                    toolName: step.tool,
                    success: false,
                    error: error.localizedDescription,
                    duration: Date().timeIntervalSince(stepStart)
                )
                stepResults.append(stepResult)
                delegate?.skillRuntime(self, didCompleteStep: step.step, result: stepResult)
                auditTrail.append(AuditEntry(event: "step_failed", details: "Step \(step.step): \(error.localizedDescription)"))

                // Try fallback if available
                if let fallbackSequence = skill.fallbackSequence {
                    auditTrail.append(AuditEntry(event: "fallback_started"))
                    // Execute fallback (simplified - just note it for now)
                    _ = fallbackSequence
                }

                throw SkillRuntimeError.stepExecutionFailed(step: step.step, reason: error.localizedDescription)
            }

            // Check max execution time
            if Date().timeIntervalSince(startTime) > maxExecutionTime {
                auditTrail.append(AuditEntry(event: "timeout"))
                throw SkillRuntimeError.timeout
            }
        }

        // 5. Build response
        let response = buildResponse(skill: skill, stepResults: stepResults)
        let executionTime = Date().timeIntervalSince(startTime)

        auditTrail.append(AuditEntry(event: "execution_completed", details: "Duration: \(String(format: "%.2f", executionTime))s"))

        let result = SkillExecutionResult(
            success: true,
            skillId: skillId,
            response: response,
            stepResults: stepResults,
            executionTime: executionTime,
            auditTrail: auditTrail
        )

        delegate?.skillRuntime(self, didComplete: result)
        return result
    }

    /// Execute a skill from an intent match
    public func execute(match: IntentMatchResult, userInput: String) async throws -> SkillExecutionResult {
        var params: [String: Any] = match.extractedParams
        params["_userInput"] = userInput
        params["_matchedTrigger"] = match.matchedTrigger

        let context = SkillExecutionContext(userInput: userInput)
        return try await execute(skillId: match.skill.id, parameters: params, context: context)
    }

    /// Cancel current execution
    public func cancel() {
        currentExecution?.cancel()
        currentExecution = nil
    }

    // MARK: - Private Helpers

    private func checkSafetyConstraints(_ safety: SafetyConstraints, input: String?) -> String? {
        guard let input = input else { return nil }

        let lowercased = input.lowercased()

        // Check emergency keywords
        for keyword in safety.emergencyKeywords {
            if lowercased.contains(keyword.lowercased()) {
                return "Emergency detected: \(safety.emergencyAction ?? "Please seek appropriate help")"
            }
        }

        return nil
    }

    private func buildCapabilitiesInfo(_ skill: SkillDefinition) -> SkillCapabilitiesInfo {
        var mcpServers: [MCPServerInfo] = []

        for server in skill.capabilities.mcpServers {
            mcpServers.append(MCPServerInfo(
                provider: server.provider,
                server: server.server,
                tools: server.tools,
                required: server.required
            ))
        }

        return SkillCapabilitiesInfo(
            builtinTools: skill.capabilities.builtinTools,
            mcpServers: mcpServers
        )
    }

    private func evaluateCondition(_ condition: String, params: [String: Any]) -> Bool {
        // Simple condition evaluation (e.g., "action == create")
        let parts = condition.components(separatedBy: " == ")
        guard parts.count == 2 else { return true }

        let key = parts[0].trimmingCharacters(in: .whitespaces)
        let value = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")

        if let paramValue = params[key] as? String {
            return paramValue.lowercased() == value.lowercased()
        }

        return true // Default to true if param not found
    }

    private func isHighRiskStep(_ step: ToolStep, skill: SkillDefinition) -> Bool {
        guard let gates = skill.approvalGates else { return false }

        let toolLower = step.tool.lowercased()

        for highRisk in gates.highRisk {
            if toolLower.contains(highRisk.lowercased()) {
                return true
            }
        }

        return false
    }

    private func requestApproval(step: ToolStep, skill: SkillDefinition, parameters: [String: Any]) async -> Bool {
        guard let delegate = delegate else {
            // No delegate, auto-approve low-risk, deny high-risk
            return !step.requiresApproval
        }

        let request = ApprovalRequest(
            skillId: skill.id,
            skillName: skill.name,
            stepNumber: step.step,
            toolName: step.tool,
            description: step.description ?? "Execute \(step.tool)",
            riskLevel: step.requiresApproval ? .high : .medium,
            parameters: parameters.compactMapValues { "\($0)" }
        )

        // Request approval with timeout
        let approved = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await delegate.skillRuntime(self, needsApprovalFor: request)
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(self.approvalTimeout * 1_000_000_000))
                return false
            }

            // Return first result (either approval or timeout)
            return await group.next() ?? false
        }

        return approved
    }

    private func buildToolParameters(step: ToolStep, userParams: [String: Any], previousResults: [StepExecutionResult]) -> [String: Any] {
        var params: [String: Any] = [:]

        // Map user params to tool params
        for paramName in step.params {
            if let value = userParams[paramName] {
                params[paramName] = value
            }
        }

        // Add previous step outputs if referenced
        for result in previousResults where result.success {
            params["_step\(result.stepNumber)_output"] = result.output
        }

        return params
    }

    private func buildResponse(skill: SkillDefinition, stepResults: [StepExecutionResult]) -> String {
        // Get the last successful output or build a summary
        if let lastSuccess = stepResults.last(where: { $0.success }), let output = lastSuccess.output {
            return output
        }

        let successCount = stepResults.filter { $0.success }.count
        return "Completed \(successCount) of \(stepResults.count) steps for \(skill.name)"
    }
}

// MARK: - Execution Context

/// Context for skill execution
public struct SkillExecutionContext: Sendable {
    /// Original user input
    public let userInput: String?

    /// Family member ID (if applicable)
    public let familyMemberId: String?

    /// Session ID for tracking
    public let sessionId: String

    /// Whether this is a voice-initiated request
    public let isVoiceRequest: Bool

    public init(
        userInput: String? = nil,
        familyMemberId: String? = nil,
        sessionId: String = UUID().uuidString,
        isVoiceRequest: Bool = false
    ) {
        self.userInput = userInput
        self.familyMemberId = familyMemberId
        self.sessionId = sessionId
        self.isVoiceRequest = isVoiceRequest
    }
}
