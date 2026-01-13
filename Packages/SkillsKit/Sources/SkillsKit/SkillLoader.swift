//
//  SkillLoader.swift
//  SkillsKit
//
//  Loads skill definitions from bundled JSON files and external sources.
//

import Foundation

/// Loads and manages skill definitions
public final class SkillLoader: @unchecked Sendable {
    public static let shared = SkillLoader()

    /// Cached skill definitions
    private var cachedSkills: [String: SkillDefinition] = [:]

    /// Directory for user-installed skills
    private let userSkillsDirectory: URL

    private init() {
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.fantasticapp.oimyai"
        userSkillsDirectory =
            supportDir
            .appendingPathComponent(bundleId, isDirectory: true)
            .appendingPathComponent("Skills", isDirectory: true)

        // Ensure directory exists
        try? fm.createDirectory(at: userSkillsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Load all skill definitions (bundled + user-installed)
    public func loadAllSkills() -> [SkillDefinition] {
        var skills: [SkillDefinition] = []

        // Load bundled skills
        skills.append(contentsOf: loadBundledSkills())

        // Load user-installed skills
        skills.append(contentsOf: loadUserSkills())

        // Cache for quick lookup
        for skill in skills {
            cachedSkills[skill.id] = skill
        }

        return skills
    }

    /// Get a skill by ID
    public func skill(byId id: String) -> SkillDefinition? {
        if let cached = cachedSkills[id] {
            return cached
        }
        // Try loading if not cached
        _ = loadAllSkills()
        return cachedSkills[id]
    }

    /// Alias for skill(byId:) for compatibility
    public func skill(withId id: String) -> SkillDefinition? {
        skill(byId: id)
    }

    /// Get all loaded skills
    public var allSkills: [SkillDefinition] {
        if cachedSkills.isEmpty {
            _ = loadAllSkills()
        }
        return Array(cachedSkills.values)
    }

    /// Load a single skill from JSON data
    public func loadSkill(from data: Data) throws -> SkillDefinition {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SkillDefinition.self, from: data)
    }

    /// Load a single skill from a JSON file
    public func loadSkill(from url: URL) throws -> SkillDefinition {
        let data = try Data(contentsOf: url)
        return try loadSkill(from: data)
    }

    /// Install a skill definition (save to user directory)
    public func installSkill(_ definition: SkillDefinition) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let data = try encoder.encode(definition)
        let filename = "\(definition.id.replacingOccurrences(of: ".", with: "_")).json"
        let url = userSkillsDirectory.appendingPathComponent(filename)

        try data.write(to: url)
        cachedSkills[definition.id] = definition
    }

    /// Uninstall a user-installed skill
    public func uninstallSkill(id: String) throws {
        let filename = "\(id.replacingOccurrences(of: ".", with: "_")).json"
        let url = userSkillsDirectory.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        cachedSkills.removeValue(forKey: id)
    }

    // MARK: - Private

    /// Load bundled skill definitions from the package resources
    private func loadBundledSkills() -> [SkillDefinition] {
        var skills: [SkillDefinition] = []

        // Get bundled skills directory from package resources
        guard let resourceURL = Bundle.module.url(forResource: "BundledSkills", withExtension: nil) else {
            print("[SkillsKit] BundledSkills directory not found in bundle")
            return skills
        }

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
        else {
            return skills
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let skill = try decoder.decode(SkillDefinition.self, from: data)
                skills.append(skill)
            } catch {
                print("[SkillsKit] Failed to load bundled skill from \(file.lastPathComponent): \(error)")
            }
        }

        return skills
    }

    /// Load user-installed skill definitions
    private func loadUserSkills() -> [SkillDefinition] {
        var skills: [SkillDefinition] = []

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: userSkillsDirectory, includingPropertiesForKeys: nil)
        else {
            return skills
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let skill = try decoder.decode(SkillDefinition.self, from: data)
                skills.append(skill)
            } catch {
                print("[SkillsKit] Failed to load user skill from \(file.lastPathComponent): \(error)")
            }
        }

        return skills
    }
}

// MARK: - Skill Validation

extension SkillLoader {
    /// Validate a skill definition
    public func validateSkill(_ definition: SkillDefinition) -> [SkillValidationError] {
        var errors: [SkillValidationError] = []

        // Check required fields
        if definition.id.isEmpty {
            errors.append(.missingField("id"))
        }
        if definition.name.isEmpty {
            errors.append(.missingField("name"))
        }
        if definition.category.isEmpty {
            errors.append(.missingField("category"))
        }

        // Validate tool sequence
        for (index, step) in definition.toolSequence.enumerated() {
            if step.tool.isEmpty {
                errors.append(.invalidToolStep(index + 1, "Tool name is empty"))
            }
        }

        // Check for duplicate steps
        let stepNumbers = definition.toolSequence.map { $0.step }
        if Set(stepNumbers).count != stepNumbers.count {
            errors.append(.duplicateSteps)
        }

        return errors
    }
}

/// Validation errors for skill definitions
public enum SkillValidationError: Error, CustomStringConvertible {
    case missingField(String)
    case invalidToolStep(Int, String)
    case duplicateSteps
    case invalidCapability(String)

    public var description: String {
        switch self {
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .invalidToolStep(let step, let reason):
            return "Invalid tool step \(step): \(reason)"
        case .duplicateSteps:
            return "Duplicate step numbers in tool sequence"
        case .invalidCapability(let reason):
            return "Invalid capability: \(reason)"
        }
    }
}
