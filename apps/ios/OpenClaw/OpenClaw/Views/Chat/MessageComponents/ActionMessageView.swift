import SwiftUI

/// Action messages with buttons for approve, modify, cancel
struct ActionMessageView: View {
    let data: ActionData
    @State private var showingDetails = false
    @State private var actionResult: ActionResult?

    var body: some View {
        VStack(spacing: 0) {
            // Header with risk indicator
            headerSection

            // Message content
            contentSection

            // Deadline if applicable
            if let deadline = data.deadline {
                deadlineSection(deadline)
            }

            // Actions
            actionsSection
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(riskColor.opacity(0.3), lineWidth: 2)
        )
        .sheet(isPresented: $showingDetails) {
            ActionDetailsSheet(data: data)
        }
        .overlay {
            if let result = actionResult {
                ActionResultOverlay(result: result)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Risk indicator
            RiskBadge(level: data.riskLevel)

            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if data.requiresApproval {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised")
                            .font(.caption2)
                        Text("Approval Required")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
            }

            Spacer()

            Button(action: { showingDetails = true }) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View details")
        }
        .padding()
        .background(riskColor.opacity(0.05))
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.message)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Warning for high-risk actions
            if data.riskLevel == .high {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Please review carefully before approving")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }

    private func deadlineSection(_ deadline: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption)
            Text("Action needed by \(deadline.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            ForEach(data.actions) { action in
                ActionButtonLarge(action: action) {
                    handleAction(action)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }

    private var riskColor: Color {
        switch data.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func handleAction(_ action: CardAction) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Show result
        withAnimation(.spring(response: 0.3)) {
            actionResult = ActionResult(
                action: action.type,
                success: true,
                message: "Action completed successfully"
            )
        }

        // Hide result after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                actionResult = nil
            }
        }
    }
}

// MARK: - Risk Badge

struct RiskBadge: View {
    let level: ActionData.RiskLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
            Text(level.rawValue.capitalized)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch level {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.shield"
        case .high: return "xmark.shield"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Action Button Large

struct ActionButtonLarge: View {
    let action: CardAction
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }) {
            HStack {
                Image(systemName: iconForAction)
                    .font(.body)
                Text(action.title)
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(action.title) button")
    }

    private var iconForAction: String {
        switch action.type {
        case .approve: return "checkmark.circle.fill"
        case .modify: return "pencil.circle.fill"
        case .cancel: return "xmark.circle.fill"
        case .viewDetails: return "eye.fill"
        case .share: return "square.and.arrow.up"
        case .custom: return "star.fill"
        }
    }

    private var backgroundColor: Color {
        switch action.style {
        case .primary:
            return .blue
        case .secondary:
            return Color(.systemGray5)
        case .destructive:
            return Color.red.opacity(0.1)
        }
    }

    private var textColor: Color {
        switch action.style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .red
        }
    }
}

// MARK: - Action Details Sheet

struct ActionDetailsSheet: View {
    let data: ActionData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(data.title)
                            .font(.title2.bold())
                        Text(data.message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Risk assessment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Risk Assessment")
                            .font(.headline)

                        RiskDetailsView(level: data.riskLevel)
                    }

                    Divider()

                    // Additional context
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What This Means")
                            .font(.headline)

                        Text(contextForRiskLevel)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if data.requiresApproval {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why Approval is Required")
                                .font(.headline)

                            Text("This action has been flagged for manual review to ensure it aligns with your preferences and safety guidelines.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Action Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var contextForRiskLevel: String {
        switch data.riskLevel {
        case .low:
            return "This is a routine action that can be safely automated. You can approve this with confidence."
        case .medium:
            return "This action requires your attention. Please review the details to ensure it matches your expectations."
        case .high:
            return "This is a significant action that may have important consequences. Please carefully review all details before approving."
        }
    }
}

// MARK: - Risk Details View

struct RiskDetailsView: View {
    let level: ActionData.RiskLevel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(level.rawValue.capitalized + " Risk")
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var color: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var icon: String {
        switch level {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    private var description: String {
        switch level {
        case .low:
            return "Routine action with minimal impact"
        case .medium:
            return "Requires attention and review"
        case .high:
            return "Significant action requiring careful consideration"
        }
    }
}

// MARK: - Action Result

struct ActionResult {
    let action: CardAction.ActionType
    let success: Bool
    let message: String
}

struct ActionResultOverlay: View {
    let result: ActionResult

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(result.success ? .green : .red)

            Text(result.message)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 20)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Low risk action
            ActionMessageView(
                data: ActionData(
                    id: UUID(),
                    title: "Send Reminder",
                    message: "I'll send a reminder to pick up the kids at 3 PM today.",
                    riskLevel: .low,
                    actions: [
                        CardAction(id: UUID(), title: "Approve", type: .approve, style: .primary),
                        CardAction(id: UUID(), title: "Cancel", type: .cancel, style: .secondary)
                    ],
                    requiresApproval: false,
                    deadline: nil
                )
            )

            // Medium risk action
            ActionMessageView(
                data: ActionData(
                    id: UUID(),
                    title: "Schedule Appointment",
                    message: "I'd like to schedule a dentist appointment for next Tuesday at 2 PM. This will send a booking request to Dr. Smith's office.",
                    riskLevel: .medium,
                    actions: [
                        CardAction(id: UUID(), title: "Approve", type: .approve, style: .primary),
                        CardAction(id: UUID(), title: "Modify Time", type: .modify, style: .secondary),
                        CardAction(id: UUID(), title: "Cancel", type: .cancel, style: .destructive)
                    ],
                    requiresApproval: true,
                    deadline: Date().addingTimeInterval(3600)
                )
            )

            // High risk action
            ActionMessageView(
                data: ActionData(
                    id: UUID(),
                    title: "Make Purchase",
                    message: "I'm about to purchase $250 worth of groceries from Whole Foods using your saved payment method. This includes all items on your weekly meal plan.",
                    riskLevel: .high,
                    actions: [
                        CardAction(id: UUID(), title: "Approve Purchase", type: .approve, style: .primary),
                        CardAction(id: UUID(), title: "Review Items", type: .viewDetails, style: .secondary),
                        CardAction(id: UUID(), title: "Cancel", type: .cancel, style: .destructive)
                    ],
                    requiresApproval: true,
                    deadline: Date().addingTimeInterval(1800)
                )
            )
        }
        .padding()
    }
}
