//
//  SkillsKitTests.swift
//  SkillsKit
//
//  Tests for SkillsKit functionality
//

import XCTest
@testable import SkillsKit

final class SkillsKitTests: XCTestCase {

    // MARK: - SkillDefinition Tests

    func testSkillDefinitionDecoding() throws {
        let json = """
        {
            "id": "test.skill.v1",
            "name": "Test Skill",
            "version": "1.0.0",
            "category": "Test",
            "short_description": "A test skill",
            "full_description": "A longer description",
            "tags": ["test", "example"],
            "capabilities": {
                "mcp_servers": [],
                "builtin_tools": ["osaurus.filesystem"],
                "optional": []
            },
            "tool_sequence": [
                {
                    "step": 1,
                    "tool": "osaurus.filesystem",
                    "params": ["path"],
                    "requires_approval": false
                }
            ],
            "example_prompts": ["Test this skill"],
            "voice_triggers": ["test skill"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let skill = try decoder.decode(SkillDefinition.self, from: data)

        XCTAssertEqual(skill.id, "test.skill.v1")
        XCTAssertEqual(skill.name, "Test Skill")
        XCTAssertEqual(skill.version, "1.0.0")
        XCTAssertEqual(skill.category, "Test")
        XCTAssertEqual(skill.tags, ["test", "example"])
        XCTAssertEqual(skill.capabilities.builtinTools, ["osaurus.filesystem"])
        XCTAssertEqual(skill.toolSequence.count, 1)
        XCTAssertEqual(skill.toolSequence[0].tool, "osaurus.filesystem")
    }

    func testSkillDefinitionWithSafetyConstraints() throws {
        let json = """
        {
            "id": "safety.test.v1",
            "name": "Safety Test",
            "version": "1.0.0",
            "category": "Healthcare",
            "short_description": "Test safety constraints",
            "capabilities": {
                "mcp_servers": [],
                "builtin_tools": [],
                "optional": []
            },
            "tool_sequence": [],
            "example_prompts": [],
            "voice_triggers": [],
            "safety_constraints": {
                "prohibited_actions": ["diagnose"],
                "required_disclaimers": ["Not medical advice"],
                "emergency_keywords": ["chest pain", "heart attack"],
                "emergency_action": "Call 911",
                "requires_adult_supervision": true
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let skill = try decoder.decode(SkillDefinition.self, from: data)

        XCTAssertNotNil(skill.safetyConstraints)
        XCTAssertEqual(skill.safetyConstraints?.prohibitedActions, ["diagnose"])
        XCTAssertEqual(skill.safetyConstraints?.emergencyKeywords, ["chest pain", "heart attack"])
        XCTAssertTrue(skill.safetyConstraints?.requiresAdultSupervision ?? false)
    }

    // MARK: - SkillLoader Tests

    func testSkillValidation() {
        let loader = SkillLoader.shared

        // Valid skill
        let validSkill = SkillDefinition(
            id: "test.valid.v1",
            name: "Valid Skill",
            category: "Test",
            shortDescription: "A valid skill"
        )
        let validErrors = loader.validateSkill(validSkill)
        XCTAssertTrue(validErrors.isEmpty)

        // Invalid skill - missing name
        let invalidSkill = SkillDefinition(
            id: "test.invalid.v1",
            name: "",
            category: "Test",
            shortDescription: "Invalid"
        )
        let invalidErrors = loader.validateSkill(invalidSkill)
        XCTAssertFalse(invalidErrors.isEmpty)
    }

    // MARK: - MockToolProvider Tests

    func testMockToolProvider() async {
        let provider = MockToolProvider()
        provider.registerTool("test.tool", response: "Success!")

        // Test availability
        let available = await provider.isToolAvailable("test.tool")
        XCTAssertTrue(available)

        let notAvailable = await provider.isToolAvailable("missing.tool")
        XCTAssertFalse(notAvailable)

        // Test execution
        do {
            let result = try await provider.executeTool("test.tool", parameters: [:])
            XCTAssertEqual(result, "Success!")
        } catch {
            XCTFail("Tool execution should not fail")
        }

        // Test missing tool execution
        do {
            _ = try await provider.executeTool("missing.tool", parameters: [:])
            XCTFail("Should throw for missing tool")
        } catch {
            // Expected
        }
    }

    // MARK: - ToolStep Tests

    func testToolStepWithCondition() throws {
        let step = ToolStep(
            step: 1,
            tool: "calendar.create_event",
            params: ["title", "date"],
            requiresApproval: true,
            condition: "action == create",
            description: "Create calendar event"
        )

        XCTAssertEqual(step.step, 1)
        XCTAssertEqual(step.tool, "calendar.create_event")
        XCTAssertTrue(step.requiresApproval)
        XCTAssertEqual(step.condition, "action == create")
    }

    // MARK: - ApprovalGates Tests

    func testApprovalGates() {
        let gates = ApprovalGates(
            highRisk: ["payment", "delete"],
            mediumRisk: ["update"],
            validResponses: ["yes", "confirm"],
            timeoutSeconds: 30
        )

        XCTAssertEqual(gates.highRisk, ["payment", "delete"])
        XCTAssertEqual(gates.mediumRisk, ["update"])
        XCTAssertEqual(gates.timeoutSeconds, 30)
    }
}
