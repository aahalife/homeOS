//
//  SkillsManagerView.swift
//  OsaurusCore
//
//  Management view for viewing, enabling, and configuring Skills
//

import SwiftUI

// MARK: - Skills Manager View

struct SkillsManagerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var skillsManager = SkillsManager.shared

    private var theme: ThemeProtocol { themeManager.currentTheme }

    @State private var selectedSkillId: UUID?
    @State private var hasAppeared = false
    @State private var successMessage: String?
    @State private var showingSkillDetail: Skill?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -10)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hasAppeared)

            // Category filter pills
            if !skillsManager.availableCategories.isEmpty {
                categoryFilterView
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05), value: hasAppeared)
            }

            // Content
            ZStack {
                if skillsManager.skills.isEmpty {
                    SkillsEmptyState(hasAppeared: hasAppeared)
                } else if skillsManager.filteredSkills.isEmpty {
                    noResultsView
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(minimum: 320), spacing: 20),
                                GridItem(.flexible(minimum: 320), spacing: 20),
                            ],
                            spacing: 20
                        ) {
                            ForEach(Array(skillsManager.filteredSkills.enumerated()), id: \.element.id) {
                                index, skill in
                                SkillCard(
                                    skill: skill,
                                    animationDelay: Double(index) * 0.03,
                                    hasAppeared: hasAppeared,
                                    onToggle: { enabled in
                                        skillsManager.setEnabled(enabled, for: skill.id)
                                        showSuccess(enabled ? "Enabled \"\(skill.name)\"" : "Disabled \"\(skill.name)\"")
                                    },
                                    onShowDetail: {
                                        showingSkillDetail = skill
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                }

                // Success toast
                if let message = successMessage {
                    VStack {
                        Spacer()
                        successToast(message)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryBackground)
        .environment(\.theme, themeManager.currentTheme)
        .sheet(item: $showingSkillDetail) { skill in
            SkillDetailSheet(skill: skill, onDismiss: { showingSkillDetail = nil })
        }
        .onAppear {
            skillsManager.refresh()
            withAnimation(.easeOut(duration: 0.25).delay(0.05)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ManagerHeaderWithActions(
            title: "Skills",
            subtitle: "AI-powered capabilities for your family",
            count: skillsManager.skills.isEmpty ? nil : skillsManager.skills.count
        ) {
            HeaderIconButton("arrow.clockwise", help: "Refresh skills") {
                skillsManager.refresh()
            }

            if skillsManager.skillsRequiringSetup > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("\(skillsManager.skillsRequiringSetup) need setup")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All categories pill
                CategoryPill(
                    category: nil,
                    isSelected: skillsManager.selectedCategory == nil,
                    count: skillsManager.skills.count,
                    onSelect: {
                        withAnimation(.spring(response: 0.3)) {
                            skillsManager.selectedCategory = nil
                        }
                    }
                )

                // Individual category pills
                ForEach(skillsManager.availableCategories, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: skillsManager.selectedCategory == category,
                        count: skillsManager.skills.filter { $0.category == category }.count,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                skillsManager.selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(theme.secondaryBackground.opacity(0.5))
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(theme.tertiaryText)

            Text("No skills match your filters")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.secondaryText)

            Button("Clear Filters") {
                withAnimation {
                    skillsManager.selectedCategory = nil
                    skillsManager.searchText = ""
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(theme.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success Toast

    private func successToast(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(theme.successColor)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.primaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(theme.cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(theme.successColor.opacity(0.3), lineWidth: 1)
        )
    }

    private func showSuccess(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            successMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                successMessage = nil
            }
        }
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    @Environment(\.theme) private var theme

    let category: SkillCategory?
    let isSelected: Bool
    let count: Int
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 11, weight: .medium))
                }

                Text(category?.rawValue ?? "All")
                    .font(.system(size: 12, weight: .medium))

                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : theme.tertiaryText)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.2) : theme.tertiaryBackground)
                    )
            }
            .foregroundColor(isSelected ? .white : theme.primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? theme.accentColor : theme.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : theme.cardBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Empty State

private struct SkillsEmptyState: View {
    @Environment(\.theme) private var theme

    let hasAppeared: Bool

    @State private var glowIntensity: CGFloat = 0.6

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Glowing icon
            ZStack {
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 88, height: 88)
                    .blur(radius: 25)
                    .opacity(glowIntensity * 0.25)

                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 88, height: 88)
                    .blur(radius: 12)
                    .opacity(glowIntensity * 0.15)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentColor.opacity(0.15),
                                theme.accentColor.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "brain.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: hasAppeared)

            VStack(spacing: 8) {
                Text("Loading Skills...")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)

                Text("Skills will appear here once loaded")
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: hasAppeared)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
        }
    }
}

// MARK: - Skill Card

private struct SkillCard: View {
    @Environment(\.theme) private var theme

    let skill: Skill
    let animationDelay: Double
    let hasAppeared: Bool
    let onToggle: (Bool) -> Void
    let onShowDetail: () -> Void

    @State private var isHovered = false

    /// Generate a consistent color based on category
    private var categoryColor: Color {
        switch skill.category {
        case .utilities: return .blue
        case .healthcare: return .red
        case .mealPlanning: return .orange
        case .family: return .green
        case .home: return .brown
        case .education: return .purple
        case .wellness: return .mint
        case .services: return .indigo
        case .personal: return .pink
        case .other: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top, spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.15), categoryColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Circle()
                        .strokeBorder(categoryColor.opacity(0.4), lineWidth: 2)

                    Image(systemName: skill.category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(skill.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)

                        // Status indicator
                        statusBadge
                    }

                    Text(skill.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(categoryColor)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { skill.isEnabled },
                    set: { onToggle($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            }

            // Description
            Text(skill.shortDescription)
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)

            // Badges
            badgesView

            // Required tools preview
            if !skill.requiredTools.isEmpty {
                toolsPreview
            }

            // Footer
            HStack {
                // Usage count
                if skill.usageCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9))
                        Text("\(skill.usageCount) uses")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(theme.tertiaryText)
                }

                Spacer()

                // View details button
                Button(action: onShowDetail) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(theme.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            skill.isEnabled ? categoryColor.opacity(0.3) : theme.cardBorder,
                            lineWidth: skill.isEnabled ? 1.5 : 1
                        )
                )
                .shadow(
                    color: skill.isEnabled ? categoryColor.opacity(0.1) : Color.black.opacity(isHovered ? 0.08 : 0.04),
                    radius: isHovered ? 10 : 5,
                    x: 0,
                    y: isHovered ? 3 : 2
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(animationDelay), value: hasAppeared)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        let statusColor: Color = {
            switch skill.status {
            case .available: return .green
            case .requiresSetup: return .orange
            case .disabled: return .gray
            case .updating: return .blue
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: skill.status.icon)
                .font(.system(size: 8, weight: .bold))

            if skill.status != .available {
                Text(skill.status.rawValue)
                    .font(.system(size: 9, weight: .medium))
            }
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
    }

    // MARK: - Badges View

    @ViewBuilder
    private var badgesView: some View {
        let badges = skill.badges.activeBadges
        if !badges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(badges, id: \.label) { badge in
                        HStack(spacing: 4) {
                            Image(systemName: badge.icon)
                                .font(.system(size: 8, weight: .semibold))

                            Text(badge.label)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(Color(badge.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(badge.color).opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Tools Preview

    private var toolsPreview: some View {
        HStack(spacing: 4) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(theme.tertiaryText)

            Text(
                skill.requiredTools.prefix(3).map { $0.toolName }.joined(separator: ", ")
                    + (skill.requiredTools.count > 3 ? " +\(skill.requiredTools.count - 3)" : "")
            )
            .font(.system(size: 10))
            .foregroundColor(theme.tertiaryText)
            .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.tertiaryBackground.opacity(0.5))
        )
    }
}

// MARK: - Color Extension for Badge Colors

private extension Color {
    init(_ colorName: String) {
        switch colorName {
        case "blue": self = .blue
        case "purple": self = .purple
        case "orange": self = .orange
        case "green": self = .green
        case "yellow": self = .yellow
        case "red": self = .red
        default: self = .gray
        }
    }
}

// MARK: - Skill Detail Sheet

private struct SkillDetailSheet: View {
    @StateObject private var themeManager = ThemeManager.shared

    let skill: Skill
    let onDismiss: () -> Void

    @State private var hasAppeared = false

    private var theme: ThemeProtocol { themeManager.currentTheme }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Description section
                    DetailSection(title: "Description", icon: "text.alignleft") {
                        Text(skill.fullDescription)
                            .font(.system(size: 13))
                            .foregroundColor(theme.primaryText)
                            .lineSpacing(4)
                    }

                    // Example prompts
                    if !skill.examplePrompts.isEmpty {
                        DetailSection(title: "Example Prompts", icon: "text.bubble") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(skill.examplePrompts, id: \.self) { prompt in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "quote.opening")
                                            .font(.system(size: 10))
                                            .foregroundColor(theme.tertiaryText)

                                        Text(prompt)
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.secondaryText)
                                            .italic()
                                    }
                                }
                            }
                        }
                    }

                    // Triggers
                    if !skill.triggers.isEmpty {
                        DetailSection(title: "Triggers", icon: "bolt") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(skill.triggers.enumerated()), id: \.offset) { _, trigger in
                                    HStack(spacing: 8) {
                                        Image(systemName: trigger.icon)
                                            .font(.system(size: 11))
                                            .foregroundColor(theme.accentColor)
                                            .frame(width: 20)

                                        Text(trigger.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(theme.primaryText)

                                        if case .voice(let phrases) = trigger {
                                            Text("(\(phrases.joined(separator: ", ")))")
                                                .font(.system(size: 11))
                                                .foregroundColor(theme.tertiaryText)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Required tools
                    if !skill.requiredTools.isEmpty {
                        DetailSection(title: "Required Tools", icon: "wrench.and.screwdriver") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(skill.requiredTools) { tool in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(
                                            systemName: tool.isRequired
                                                ? "checkmark.circle.fill" : "circle.dashed"
                                        )
                                        .font(.system(size: 12))
                                        .foregroundColor(tool.isRequired ? .green : .orange)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(tool.toolName)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(theme.primaryText)

                                                if !tool.isRequired {
                                                    Text("Optional")
                                                        .font(.system(size: 9, weight: .medium))
                                                        .foregroundColor(.orange)
                                                        .padding(.horizontal, 5)
                                                        .padding(.vertical, 1)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color.orange.opacity(0.1))
                                                        )
                                                }
                                            }

                                            Text(tool.purpose)
                                                .font(.system(size: 11))
                                                .foregroundColor(theme.tertiaryText)

                                            if let mcpServer = tool.mcpServer {
                                                Text("via \(mcpServer)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(theme.accentColor)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Metadata
                    DetailSection(title: "Info", icon: "info.circle") {
                        VStack(alignment: .leading, spacing: 8) {
                            MetadataRow(label: "Version", value: skill.version)
                            if let author = skill.author {
                                MetadataRow(label: "Author", value: author)
                            }
                            MetadataRow(label: "Source", value: skill.source.rawValue)
                            MetadataRow(
                                label: "Installed",
                                value: skill.installedAt.formatted(date: .abbreviated, time: .omitted)
                            )
                            if skill.usageCount > 0 {
                                MetadataRow(label: "Used", value: "\(skill.usageCount) times")
                            }
                        }
                    }
                }
                .padding(24)
            }

            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
        .background(theme.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primaryBorder.opacity(0.5), lineWidth: 1)
        )
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasAppeared)
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentColor.opacity(0.2),
                                theme.accentColor.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: skill.category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.accentColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text(skill.category.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(theme.tertiaryBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(theme.secondaryBackground)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Spacer()

            Button("Done", action: onDismiss)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accentColor)
                )
                .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            theme.secondaryBackground
                .overlay(
                    Rectangle()
                        .fill(theme.primaryBorder)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - Detail Section

private struct DetailSection<Content: View>: View {
    @StateObject private var themeManager = ThemeManager.shared

    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    private var theme: ThemeProtocol { themeManager.currentTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.accentColor)

                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(theme.secondaryText)
                    .tracking(0.5)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    @Environment(\.theme) private var theme

    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.tertiaryText)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.primaryText)
        }
    }
}

#Preview {
    SkillsManagerView()
}
