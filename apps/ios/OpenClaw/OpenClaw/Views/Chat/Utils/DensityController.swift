import SwiftUI
import Combine

/// Manages information density preferences for chat messages
class DensityController: ObservableObject {
    @Published var globalDensity: DensityLevel = .conversational
    @Published var messageDensities: [UUID: DensityLevel] = [:]

    enum DensityLevel: String, Codable, CaseIterable {
        case conversational = "Conversational"
        case detailed = "Detailed"
        case summary = "Summary"

        var description: String {
            switch self {
            case .conversational:
                return "Concise and friendly responses"
            case .detailed:
                return "Show all steps and reasoning"
            case .summary:
                return "Just the final results"
            }
        }

        var icon: String {
            switch self {
            case .conversational: return "bubble.left"
            case .detailed: return "list.bullet"
            case .summary: return "text.alignleft"
            }
        }
    }

    // MARK: - Singleton

    static let shared = DensityController()

    private init() {
        loadPreferences()
    }

    // MARK: - Public Methods

    func setGlobalDensity(_ level: DensityLevel) {
        globalDensity = level
        savePreferences()
    }

    func setDensity(_ level: DensityLevel, forMessage messageId: UUID) {
        messageDensities[messageId] = level
        savePreferences()
    }

    func getDensity(forMessage messageId: UUID) -> DensityLevel {
        messageDensities[messageId] ?? globalDensity
    }

    func shouldShowDetailed(forMessage messageId: UUID) -> Bool {
        getDensity(forMessage: messageId) == .detailed
    }

    func shouldShowSummary(forMessage messageId: UUID) -> Bool {
        getDensity(forMessage: messageId) == .summary
    }

    func formatContent(_ content: String, forMessageId messageId: UUID) -> String {
        let density = getDensity(forMessage: messageId)

        switch density {
        case .conversational:
            return formatConversational(content)
        case .detailed:
            return formatDetailed(content)
        case .summary:
            return formatSummary(content)
        }
    }

    // MARK: - Private Methods

    private func formatConversational(_ content: String) -> String {
        // Keep it concise and friendly
        return content
    }

    private func formatDetailed(_ content: String) -> String {
        // Add reasoning and steps
        return content
    }

    private func formatSummary(_ content: String) -> String {
        // Extract key points only
        let sentences = content.components(separatedBy: ". ")
        if sentences.count > 2 {
            return sentences.prefix(2).joined(separator: ". ") + "."
        }
        return content
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "densityPreferences"),
           let decoded = try? JSONDecoder().decode(DensityPreferences.self, from: data) {
            globalDensity = decoded.globalDensity
            messageDensities = decoded.messageDensities
        }
    }

    private func savePreferences() {
        let preferences = DensityPreferences(
            globalDensity: globalDensity,
            messageDensities: messageDensities
        )
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "densityPreferences")
        }
    }
}

// MARK: - Density Preferences Model

struct DensityPreferences: Codable {
    let globalDensity: DensityController.DensityLevel
    let messageDensities: [UUID: DensityController.DensityLevel]
}

// MARK: - Density Selector View

struct DensitySelectorView: View {
    @ObservedObject var controller: DensityController
    let messageId: UUID?

    var body: some View {
        Menu {
            ForEach(DensityController.DensityLevel.allCases, id: \.self) { level in
                Button(action: {
                    if let messageId = messageId {
                        controller.setDensity(level, forMessage: messageId)
                    } else {
                        controller.setGlobalDensity(level)
                    }
                }) {
                    Label {
                        VStack(alignment: .leading) {
                            Text(level.rawValue)
                                .font(.body)
                            Text(level.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: level.icon)
                    }
                }
            }
        } label: {
            Label("Density", systemImage: currentDensity.icon)
        }
    }

    private var currentDensity: DensityController.DensityLevel {
        if let messageId = messageId {
            return controller.getDensity(forMessage: messageId)
        }
        return controller.globalDensity
    }
}

// MARK: - Inline Density Toggle

struct InlineDensityToggle: View {
    @ObservedObject var controller: DensityController
    let messageId: UUID
    @State private var isExpanded = false

    var body: some View {
        Button(action: { toggleDensity() }) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                Text(isExpanded ? "Show Less" : "Show More")
                    .font(.caption)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .onAppear {
            isExpanded = controller.shouldShowDetailed(forMessage: messageId)
        }
    }

    private func toggleDensity() {
        let currentDensity = controller.getDensity(forMessage: messageId)

        let newDensity: DensityController.DensityLevel = {
            switch currentDensity {
            case .summary:
                return .conversational
            case .conversational:
                return .detailed
            case .detailed:
                return .summary
            }
        }()

        controller.setDensity(newDensity, forMessage: messageId)
        isExpanded = newDensity == .detailed
    }
}

#Preview {
    VStack(spacing: 20) {
        DensitySelectorView(
            controller: DensityController.shared,
            messageId: nil
        )

        InlineDensityToggle(
            controller: DensityController.shared,
            messageId: UUID()
        )
    }
    .padding()
}
