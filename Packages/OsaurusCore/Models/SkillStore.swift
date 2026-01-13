//
//  SkillStore.swift
//  OsaurusCore
//
//  Persistence for Skills (Application Support bundle directory)
//

import Foundation

@MainActor
public enum SkillStore {
    /// Optional directory override for tests
    static var overrideDirectory: URL?

    // MARK: - Public API

    /// Load all skills sorted by category then name, including bundled
    public static func loadAll() -> [Skill] {
        // Start with bundled skills
        var skills = Skill.sampleSkills

        // Load custom/installed skills from disk
        let directory = skillsDirectory()
        ensureDirectoryExists(directory)

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else {
            return sortSkills(skills)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let skill = try decoder.decode(Skill.self, from: data)
                // Don't load if it conflicts with bundled skill slugs
                if !Skill.sampleSkills.contains(where: { $0.slug == skill.slug }) {
                    skills.append(skill)
                }
            } catch {
                print("[Oi My AI] Failed to load skill from \(file.lastPathComponent): \(error)")
            }
        }

        return sortSkills(skills)
    }

    /// Load a specific skill by ID
    public static func load(id: UUID) -> Skill? {
        // Check bundled first
        if let bundled = Skill.sampleSkills.first(where: { $0.id == id }) {
            return bundled
        }

        // Load from disk
        let url = skillFileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Skill.self, from: data)
        } catch {
            print("[Oi My AI] Failed to load skill \(id): \(error)")
            return nil
        }
    }

    /// Load a skill by slug
    public static func load(slug: String) -> Skill? {
        // Check bundled first
        if let bundled = Skill.sampleSkills.first(where: { $0.slug == slug }) {
            return bundled
        }

        // Search in directory
        let directory = skillsDirectory()
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let skill = try decoder.decode(Skill.self, from: data)
                if skill.slug == slug {
                    return skill
                }
            } catch {
                continue
            }
        }

        return nil
    }

    /// Save a skill (creates or updates). Cannot save bundled skills.
    public static func save(_ skill: Skill) {
        // Don't persist bundled skills
        guard skill.source != .bundled else {
            print("[Oi My AI] Cannot save bundled skill: \(skill.name)")
            return
        }

        let url = skillFileURL(for: skill.id)
        ensureDirectoryExists(url.deletingLastPathComponent())

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(skill)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("[Oi My AI] Failed to save skill \(skill.id): \(error)")
        }
    }

    /// Delete a skill by ID. Cannot delete bundled skills.
    /// Returns true if deletion was successful
    @discardableResult
    public static func delete(id: UUID) -> Bool {
        // Cannot delete bundled skills
        if Skill.sampleSkills.contains(where: { $0.id == id }) {
            print("[Oi My AI] Cannot delete bundled skill")
            return false
        }

        let url = skillFileURL(for: id)
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("[Oi My AI] Failed to delete skill \(id): \(error)")
            return false
        }
    }

    /// Check if a skill exists
    public static func exists(id: UUID) -> Bool {
        if Skill.sampleSkills.contains(where: { $0.id == id }) {
            return true
        }
        let url = skillFileURL(for: id)
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Update skill usage statistics
    public static func recordUsage(id: UUID) {
        guard var skill = load(id: id) else { return }

        // Bundled skills track usage in memory only for now
        guard skill.source != .bundled else { return }

        skill.lastUsedAt = Date()
        skill.usageCount += 1
        skill.updatedAt = Date()
        save(skill)
    }

    // MARK: - Private

    private static func skillsDirectory() -> URL {
        if let overrideDirectory {
            return overrideDirectory.appendingPathComponent("Skills", isDirectory: true)
        }
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "com.fantasticapp.oimyai"
        return
            supportDir
            .appendingPathComponent(bundleId, isDirectory: true)
            .appendingPathComponent("Skills", isDirectory: true)
    }

    private static func skillFileURL(for id: UUID) -> URL {
        skillsDirectory().appendingPathComponent("\(id.uuidString).json")
    }

    private static func ensureDirectoryExists(_ url: URL) {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print("[Oi My AI] Failed to create directory \(url.path): \(error)")
            }
        }
    }

    private static func sortSkills(_ skills: [Skill]) -> [Skill] {
        skills.sorted { a, b in
            // Sort by category first, then by name
            if a.category.rawValue != b.category.rawValue {
                return a.category.rawValue < b.category.rawValue
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
