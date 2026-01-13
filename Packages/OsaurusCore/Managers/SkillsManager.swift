//
//  SkillsManager.swift
//  OsaurusCore
//
//  Manages skill lifecycle - loading, enabling/disabling, and usage tracking
//

import Combine
import Foundation
import SwiftUI

/// Notification posted when skills are updated
extension Notification.Name {
    static let skillsUpdated = Notification.Name("skillsUpdated")
}

/// Manages all skills and their states
@MainActor
public final class SkillsManager: ObservableObject {
    public static let shared = SkillsManager()

    /// All available skills (bundled + installed)
    @Published public private(set) var skills: [Skill] = []

    /// Filter for displayed skills
    @Published public var searchText: String = ""

    /// Selected category filter
    @Published public var selectedCategory: SkillCategory?

    /// Skills grouped by category
    public var skillsByCategory: [SkillCategory: [Skill]] {
        Dictionary(grouping: filteredSkills) { $0.category }
    }

    /// Filtered skills based on search and category
    public var filteredSkills: [Skill] {
        var result = skills

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.shortDescription.localizedCaseInsensitiveContains(searchText)
                    || $0.slug.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    /// Categories that have skills
    public var availableCategories: [SkillCategory] {
        let categoriesWithSkills = Set(skills.map { $0.category })
        return SkillCategory.allCases.filter { categoriesWithSkills.contains($0) }
    }

    /// Count of skills requiring setup
    public var skillsRequiringSetup: Int {
        skills.filter { $0.status == .requiresSetup }.count
    }

    /// Count of enabled skills
    public var enabledSkillsCount: Int {
        skills.filter { $0.isEnabled }.count
    }

    private init() {
        refresh()
    }

    // MARK: - Public API

    /// Reload skills from disk
    public func refresh() {
        skills = SkillStore.loadAll()
        NotificationCenter.default.post(name: .skillsUpdated, object: nil)
    }

    /// Get a skill by ID
    public func skill(for id: UUID) -> Skill? {
        skills.first { $0.id == id }
    }

    /// Get a skill by slug
    public func skill(bySlug slug: String) -> Skill? {
        skills.first { $0.slug == slug }
    }

    /// Enable or disable a skill
    public func setEnabled(_ enabled: Bool, for id: UUID) {
        guard var skill = skill(for: id) else { return }

        // Bundled skills can only be toggled in memory
        skill.isEnabled = enabled
        skill.updatedAt = Date()

        if skill.source != .bundled {
            SkillStore.save(skill)
        }

        // Update in-memory list
        if let index = skills.firstIndex(where: { $0.id == id }) {
            skills[index] = skill
        }

        NotificationCenter.default.post(name: .skillsUpdated, object: nil)
    }

    /// Record that a skill was used
    public func recordUsage(for id: UUID) {
        SkillStore.recordUsage(id: id)

        // Update in-memory
        if let index = skills.firstIndex(where: { $0.id == id }) {
            var skill = skills[index]
            skill.lastUsedAt = Date()
            skill.usageCount += 1
            skills[index] = skill
        }
    }

    /// Install a new skill from a definition
    @discardableResult
    public func install(skill: Skill) -> Bool {
        // Check if slug already exists
        if skills.contains(where: { $0.slug == skill.slug }) {
            print("[Oi My AI] Skill with slug '\(skill.slug)' already exists")
            return false
        }

        SkillStore.save(skill)
        refresh()
        return true
    }

    /// Uninstall a skill
    @discardableResult
    public func uninstall(id: UUID) -> Bool {
        guard SkillStore.delete(id: id) else {
            return false
        }
        refresh()
        return true
    }

    /// Update a skill's configuration
    public func update(_ skill: Skill) {
        guard skill.source != .bundled else {
            print("[Oi My AI] Cannot update bundled skill")
            return
        }

        var updated = skill
        updated.updatedAt = Date()
        SkillStore.save(updated)
        refresh()
    }

    // MARK: - Skill Execution

    /// Check if a skill can be executed (all required tools available)
    public func canExecute(id: UUID) -> Bool {
        guard let skill = skill(for: id) else { return false }
        return skill.isEnabled && skill.status == .available
    }

    /// Get missing tools for a skill
    public func missingTools(for id: UUID) -> [SkillToolRequirement] {
        guard let skill = skill(for: id) else { return [] }

        // TODO: Check against ToolRegistry when available
        return skill.requiredTools.filter { tool in
            // For now, return empty - will integrate with ToolRegistry later
            false
        }
    }

    // MARK: - Statistics

    /// Most recently used skills
    public var recentlyUsedSkills: [Skill] {
        skills
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    /// Most frequently used skills
    public var frequentlyUsedSkills: [Skill] {
        skills
            .filter { $0.usageCount > 0 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(5)
            .map { $0 }
    }
}
