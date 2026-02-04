import SwiftUI

/// Accessibility utilities for chat interface
struct AccessibilityHelpers {
    // MARK: - Voice Over Announcements

    static func announce(_ message: String, priority: AccessibilityNotificationPriority = .default) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    static func announcePageChange(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: message)
        }
    }

    static func announceLayoutChange(_ element: Any? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }

    // MARK: - Accessibility Labels

    static func messageLabel(from message: EnhancedChatMessage) -> String {
        let role = message.role == .user ? "You" : "OpenClaw"
        var label = "\(role) said: \(message.content)"

        if let metadata = message.metadata {
            if let confidence = metadata.confidence {
                label += ". Confidence: \(Int(confidence * 100)) percent"
            }
            if metadata.requiresHumanFallback {
                label += ". May require human verification"
            }
            if metadata.canUndo {
                label += ". Can be undone"
            }
        }

        return label
    }

    static func taskLabel(from task: UserTask) -> String {
        var label = "\(task.category.rawValue) task: \(task.title). \(task.description)"

        if let dueDate = task.dueDate {
            label += ". Due: \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        }

        if let action = task.actionRequired {
            label += ". \(action.type.rawValue.capitalized) required. \(action.riskLevel.rawValue.capitalized) risk"
        }

        return label
    }

    static func approvalLabel(from request: ApprovalRequest) -> String {
        var label = "\(request.riskLevel.rawValue.capitalized) risk approval required"
        label += ". \(request.title). \(request.description)"
        label += ". \(request.details.count) details to review"

        if let expiresAt = request.expiresAt {
            label += ". Expires at \(expiresAt.formatted(date: .omitted, time: .shortened))"
        }

        return label
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let hapticFeedback: Bool

    init(hapticFeedback: Bool = true) {
        self.hapticFeedback = hapticFeedback
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticFeedback {
                    HapticManager.shared.lightImpact()
                }
            }
    }
}

// MARK: - Accessible Card

struct AccessibleCard<Content: View>: View {
    let label: String
    let hint: String?
    let content: Content

    init(label: String, hint: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.hint = hint
        self.content = content()
    }

    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - Dynamic Type Support

extension View {
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }

    func minimumScaleFactor(_ factor: CGFloat) -> some View {
        self.minimumScaleFactor(factor)
    }
}

// MARK: - High Contrast Support

struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .opacity(contrast == .increased ? 1.0 : 0.9)
    }
}

extension View {
    func adaptToContrast() -> some View {
        self.modifier(HighContrastModifier())
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : animation, value: UUID())
    }
}

extension View {
    func respectReduceMotion(_ animation: Animation = AnimationHelpers.smoothSpring) -> some View {
        self.modifier(ReduceMotionModifier(animation: animation))
    }
}

// MARK: - Accessible Progress Indicator

struct AccessibleProgressIndicator: View {
    let progress: Double
    let total: Double
    let label: String

    var body: some View {
        ProgressView(value: progress, total: total)
            .accessibilityLabel("\(label): \(Int((progress / total) * 100)) percent complete")
            .accessibilityValue("\(Int(progress)) of \(Int(total))")
    }
}

// MARK: - Accessible Toggle

struct AccessibleToggle: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityLabel(label)
        .accessibilityHint(description ?? "")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Focus Management

class FocusManager: ObservableObject {
    @Published var focusedField: FocusableField?

    enum FocusableField: Hashable {
        case chatInput
        case searchBar
        case noteField
    }

    func focus(_ field: FocusableField) {
        focusedField = field
        AccessibilityHelpers.announceLayoutChange()
    }

    func clearFocus() {
        focusedField = nil
    }
}

// MARK: - Custom Accessibility Actions

struct AccessibilityActionsModifier: ViewModifier {
    let actions: [(String, () -> Void)]

    func body(content: Content) -> some View {
        var modifiedContent = AnyView(content)

        for action in actions {
            modifiedContent = AnyView(
                modifiedContent.accessibilityAction(named: action.0) {
                    action.1()
                }
            )
        }

        return modifiedContent
    }
}

extension View {
    func accessibilityActions(_ actions: [(String, () -> Void)]) -> some View {
        self.modifier(AccessibilityActionsModifier(actions: actions))
    }
}

// MARK: - Readable Content Guide

struct ReadableContentModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 700) // Comfortable reading width
            .padding(.horizontal)
    }
}

extension View {
    func readableContentWidth() -> some View {
        self.modifier(ReadableContentModifier())
    }
}

// MARK: - Voice Over Helpers

struct VoiceOverHelpView: View {
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Over Instructions")
                .font(.headline)

            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(instruction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voice Over Instructions: \(instructions.joined(separator: ". "))")
    }
}

// MARK: - Accessibility Rotor

extension View {
    func addAccessibilityRotor() -> some View {
        self.accessibilityRotor("Messages") {
            // Add custom rotor content
        }
    }
}

#Preview("Accessibility Helpers") {
    ScrollView {
        VStack(spacing: 20) {
            AccessibleCard(
                label: "Example Card",
                hint: "Double tap to interact"
            ) {
                VStack {
                    Text("Content")
                        .font(.headline)
                    Text("Description")
                        .font(.body)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            AccessibleProgressIndicator(
                progress: 7,
                total: 10,
                label: "Task completion"
            )

            AccessibleToggle(
                isOn: .constant(true),
                label: "Enable Notifications",
                description: "Receive updates about important events"
            )

            VoiceOverHelpView(instructions: [
                "Swipe right to move to the next message",
                "Double tap to select an action",
                "Swipe down with two fingers to dismiss"
            ])
        }
        .padding()
    }
}
