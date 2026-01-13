//
//  SkillIntegration.swift
//  OsaurusCore
//
//  Integration layer between the Chat UI and Skill Execution Engine.
//  Provides fast-path skill detection before LLM invocation.
//

import Foundation
import SkillsKit

// MARK: - Skill Integration Service

/// Service that bridges chat sessions with skill execution
@MainActor
public final class SkillIntegrationService: @unchecked Sendable {
    public static let shared = SkillIntegrationService()

    /// Minimum confidence to trigger fast-path skill execution
    public var fastPathConfidenceThreshold: Double = 0.75

    /// Whether fast-path skill detection is enabled
    public var enableFastPath: Bool = true

    /// Delegate for skill execution events
    public weak var delegate: SkillIntegrationDelegate?

    private init() {
        // Initialize SkillLoader with bundled skills
        _ = SkillLoader.shared
    }

    // MARK: - Fast Path Detection

    /// Check if input should trigger fast-path skill execution
    /// Returns the match if confidence is above threshold, nil otherwise
    public func checkFastPath(input: String) async -> IntentMatchResult? {
        guard enableFastPath else { return nil }

        let match = await IntentMatcher.shared.bestMatch(input: input)

        if let match = match, match.confidence >= fastPathConfidenceThreshold {
            print("[Oi My AI][Skill] Fast path match: \(match.skill.name) (confidence: \(String(format: "%.2f", match.confidence)))")
            return match
        }

        return nil
    }

    /// Execute a skill from a fast-path match
    /// Returns a formatted response suitable for display in chat
    public func executeFastPath(
        match: IntentMatchResult,
        userInput: String,
        sessionContext: SkillSessionContext
    ) async -> SkillExecutionResponse {
        print("[Oi My AI][Skill] Executing fast-path skill: \(match.skill.name)")

        // Notify delegate
        delegate?.skillIntegration(self, willExecuteSkill: match.skill.id, via: .fastPath)

        do {
            let result = try await SkillRuntime.shared.execute(match: match, userInput: userInput)

            // Notify delegate
            delegate?.skillIntegration(self, didExecuteSkill: match.skill.id, success: true)

            return SkillExecutionResponse(
                success: true,
                response: formatSuccessResponse(result: result, skill: match.skill),
                skillId: match.skill.id,
                skillName: match.skill.name,
                executionTime: result.executionTime,
                disclaimers: match.skill.safetyConstraints?.requiredDisclaimers
            )

        } catch {
            // Notify delegate
            delegate?.skillIntegration(self, didExecuteSkill: match.skill.id, success: false)

            return SkillExecutionResponse(
                success: false,
                response: formatErrorResponse(error: error, skill: match.skill),
                skillId: match.skill.id,
                skillName: match.skill.name,
                executionTime: 0,
                disclaimers: nil
            )
        }
    }

    // MARK: - LLM-Assisted Skill Execution

    /// Check if LLM response indicates a skill should be executed
    /// This is for when the LLM decides to invoke a skill tool
    public func parseSkillInvocation(from toolCall: ToolCall) -> SkillInvocationRequest? {
        // Check if this is a skill execution tool call
        guard toolCall.function.name == "execute_skill" ||
              toolCall.function.name.hasPrefix("skill_") else {
            return nil
        }

        // Parse the arguments
        guard let data = toolCall.function.arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let skillId = args["skill_id"] as? String ?? args["skillId"] as? String
        let parameters = args["parameters"] as? [String: Any] ?? args

        guard let skillId = skillId else { return nil }

        return SkillInvocationRequest(
            skillId: skillId,
            parameters: parameters,
            toolCallId: toolCall.id
        )
    }

    /// Execute a skill invoked by the LLM
    public func executeLLMInvocation(
        request: SkillInvocationRequest,
        sessionContext: SkillSessionContext
    ) async -> SkillExecutionResponse {
        print("[Oi My AI][Skill] Executing LLM-invoked skill: \(request.skillId)")

        // Notify delegate
        delegate?.skillIntegration(self, willExecuteSkill: request.skillId, via: .llmInvocation)

        do {
            let context = SkillExecutionContext(
                userInput: sessionContext.lastUserInput,
                familyMemberId: sessionContext.familyMemberId,
                sessionId: sessionContext.sessionId
            )

            let result = try await SkillRuntime.shared.execute(
                skillId: request.skillId,
                parameters: request.parameters,
                context: context
            )

            // Notify delegate
            delegate?.skillIntegration(self, didExecuteSkill: request.skillId, success: true)

            guard let skill = SkillLoader.shared.skill(withId: request.skillId) else {
                return SkillExecutionResponse(
                    success: true,
                    response: result.response,
                    skillId: request.skillId,
                    skillName: request.skillId,
                    executionTime: result.executionTime,
                    disclaimers: nil
                )
            }

            return SkillExecutionResponse(
                success: true,
                response: formatSuccessResponse(result: result, skill: skill),
                skillId: request.skillId,
                skillName: skill.name,
                executionTime: result.executionTime,
                disclaimers: skill.safetyConstraints?.requiredDisclaimers
            )

        } catch {
            // Notify delegate
            delegate?.skillIntegration(self, didExecuteSkill: request.skillId, success: false)

            return SkillExecutionResponse(
                success: false,
                response: "Skill execution failed: \(error.localizedDescription)",
                skillId: request.skillId,
                skillName: request.skillId,
                executionTime: 0,
                disclaimers: nil
            )
        }
    }

    // MARK: - Response Formatting

    private func formatSuccessResponse(result: SkillExecutionResult, skill: SkillDefinition) -> String {
        var response = result.response

        // Add disclaimers if present
        if let disclaimers = skill.safetyConstraints?.requiredDisclaimers, !disclaimers.isEmpty {
            response += "\n\n---\n"
            response += "_" + disclaimers.joined(separator: " ") + "_"
        }

        return response
    }

    private func formatErrorResponse(error: Error, skill: SkillDefinition) -> String {
        if let runtimeError = error as? SkillRuntimeError {
            switch runtimeError {
            case .missingRequiredTool(let tool):
                return "I couldn't complete the \(skill.name) task because the required tool '\(tool)' is not available. Please check your integrations in Settings."
            case .approvalDenied:
                return "The \(skill.name) task was cancelled because approval was not granted."
            case .safetyViolation(let reason):
                return reason
            default:
                return "I encountered an error while trying to help with \(skill.name): \(runtimeError.localizedDescription ?? "Unknown error")"
            }
        }

        return "I encountered an error while trying to help with \(skill.name). Please try again or rephrase your request."
    }

    // MARK: - Skill Registration for LLM

    /// Generate tool specs for skills that the LLM can invoke
    public func generateSkillToolSpecs() -> [ChatToolSpec] {
        let skills = SkillLoader.shared.allSkills

        return skills.map { skill in
            ChatToolSpec(
                type: "function",
                function: ChatToolFunction(
                    name: "skill_\(skill.id.replacingOccurrences(of: ".", with: "_"))",
                    description: "\(skill.shortDescription). Triggers: \(skill.voiceTriggers.joined(separator: ", "))",
                    parameters: generateSkillParameters(skill)
                )
            )
        }
    }

    private func generateSkillParameters(_ skill: SkillDefinition) -> [String: Any] {
        var properties: [String: Any] = [:]
        var required: [String] = []

        // Extract parameters from tool sequence
        for step in skill.toolSequence {
            for param in step.params {
                if properties[param] == nil {
                    properties[param] = [
                        "type": "string",
                        "description": "Parameter for \(step.tool)"
                    ]
                }
            }
        }

        return [
            "type": "object",
            "properties": properties,
            "required": required
        ]
    }
}

// MARK: - Supporting Types

/// Response from skill execution
public struct SkillExecutionResponse: Sendable {
    public let success: Bool
    public let response: String
    public let skillId: String
    public let skillName: String
    public let executionTime: TimeInterval
    public let disclaimers: [String]?

    public init(
        success: Bool,
        response: String,
        skillId: String,
        skillName: String,
        executionTime: TimeInterval,
        disclaimers: [String]?
    ) {
        self.success = success
        self.response = response
        self.skillId = skillId
        self.skillName = skillName
        self.executionTime = executionTime
        self.disclaimers = disclaimers
    }
}

/// Request to invoke a skill (from LLM)
public struct SkillInvocationRequest: Sendable {
    public let skillId: String
    public let parameters: [String: Any]
    public let toolCallId: String

    public init(skillId: String, parameters: [String: Any], toolCallId: String) {
        self.skillId = skillId
        self.parameters = parameters
        self.toolCallId = toolCallId
    }
}

/// Context for skill execution within a chat session
public struct SkillSessionContext: Sendable {
    public let sessionId: String
    public let lastUserInput: String?
    public let familyMemberId: String?
    public let personaId: UUID?

    public init(
        sessionId: String,
        lastUserInput: String? = nil,
        familyMemberId: String? = nil,
        personaId: UUID? = nil
    ) {
        self.sessionId = sessionId
        self.lastUserInput = lastUserInput
        self.familyMemberId = familyMemberId
        self.personaId = personaId
    }
}

/// How a skill was invoked
public enum SkillInvocationType: String, Sendable {
    case fastPath = "fast_path"
    case llmInvocation = "llm_invocation"
}

// MARK: - Delegate Protocol

/// Delegate for skill integration events
@MainActor
public protocol SkillIntegrationDelegate: AnyObject {
    func skillIntegration(_ service: SkillIntegrationService, willExecuteSkill skillId: String, via: SkillInvocationType)
    func skillIntegration(_ service: SkillIntegrationService, didExecuteSkill skillId: String, success: Bool)
}

// Default implementations
extension SkillIntegrationDelegate {
    public func skillIntegration(_ service: SkillIntegrationService, willExecuteSkill skillId: String, via: SkillInvocationType) {}
    public func skillIntegration(_ service: SkillIntegrationService, didExecuteSkill skillId: String, success: Bool) {}
}

// MARK: - ChatSession Extension for Skills

extension ChatSession {
    /// Check if input should be handled by fast-path skill execution
    /// Returns true if skill was executed, false if normal LLM flow should continue
    @MainActor
    func tryFastPathSkillExecution(input: String, images: [Data]) async -> Bool {
        // Skip fast path if there are images (requires LLM vision)
        guard images.isEmpty else { return false }

        // Check for fast-path match
        guard let match = await SkillIntegrationService.shared.checkFastPath(input: input) else {
            return false
        }

        // Create session context
        let context = SkillSessionContext(
            sessionId: sessionId?.uuidString ?? UUID().uuidString,
            lastUserInput: input,
            personaId: personaId
        )

        // Execute the skill
        let response = await SkillIntegrationService.shared.executeFastPath(
            match: match,
            userInput: input,
            sessionContext: context
        )

        // Add user turn
        turns.append(ChatTurn(role: .user, content: input, images: []))

        // Add skill response turn
        let assistantTurn = ChatTurn(role: .assistant, content: response.response)
        assistantTurn.skillExecution = SkillExecutionMetadata(
            skillId: response.skillId,
            skillName: response.skillName,
            success: response.success,
            executionTime: response.executionTime
        )
        turns.append(assistantTurn)

        // Save session
        save()

        return true
    }
}

// MARK: - ChatTurn Extension for Skill Metadata

/// Metadata about skill execution attached to a turn
public class SkillExecutionMetadata: @unchecked Sendable {
    public let skillId: String
    public let skillName: String
    public let success: Bool
    public let executionTime: TimeInterval

    public init(skillId: String, skillName: String, success: Bool, executionTime: TimeInterval) {
        self.skillId = skillId
        self.skillName = skillName
        self.success = success
        self.executionTime = executionTime
    }
}

extension ChatTurn {
    private static var skillExecutionKey: UInt8 = 0

    /// Skill execution metadata (if this turn was generated by skill execution)
    public var skillExecution: SkillExecutionMetadata? {
        get {
            objc_getAssociatedObject(self, &Self.skillExecutionKey) as? SkillExecutionMetadata
        }
        set {
            objc_setAssociatedObject(self, &Self.skillExecutionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
