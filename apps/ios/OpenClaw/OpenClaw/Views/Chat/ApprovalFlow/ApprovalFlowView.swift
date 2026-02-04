import SwiftUI

/// Complete approval flow system for high-risk actions
struct ApprovalFlowView: View {
    let request: ApprovalRequest
    let onApprove: (ApprovalResult) -> Void
    let onReject: (ApprovalResult) -> Void

    @State private var showDetails = false
    @State private var note: String = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Risk indicator
                    riskHeader

                    // Action summary
                    actionSummary

                    // Details
                    detailsSection

                    // Explanation
                    explanationSection

                    // Note (optional)
                    noteSection

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Approval Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .interactiveDismissDisabled(isProcessing)
        }
    }

    // MARK: - Risk Header

    private var riskHeader: some View {
        VStack(spacing: 16) {
            // Risk badge
            ZStack {
                Circle()
                    .fill(riskColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: riskIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(riskColor)
            }

            VStack(spacing: 4) {
                Text(request.riskLevel.rawValue.capitalized + " Risk Action")
                    .font(.headline)
                    .foregroundStyle(riskColor)

                Text(request.actionType.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let expiresAt = request.expiresAt {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("Expires: \(expiresAt.formatted(date: .omitted, time: .shortened))")
                }
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Summary

    private var actionSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(request.title)
                .font(.title3.bold())

            Text(request.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Action Details")
                    .font(.headline)

                Spacer()

                Button(action: { withAnimation { showDetails.toggle() } }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            if showDetails {
                VStack(spacing: 12) {
                    ForEach(request.details) { detail in
                        ApprovalDetailRow(detail: detail)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                // Show only important details
                ForEach(request.details.filter { $0.important }) { detail in
                    ApprovalDetailRow(detail: detail)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Why This Needs Approval", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Text(explanationText)
                .font(.body)
                .foregroundStyle(.secondary)

            if request.riskLevel == .high {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Please review carefully before proceeding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Note (Optional)")
                .font(.headline)

            TextField("Your thoughts or modifications...", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Approve button
            Button(action: { handleApprove() }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Approve")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Reject button
            Button(action: { handleReject() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                    Text("Reject")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            // Modify button (if applicable)
            if canModify {
                Button(action: { handleModify() }) {
                    HStack {
                        Image(systemName: "pencil.circle")
                        Text("Modify Request")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed Properties

    private var riskColor: Color {
        switch request.riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private var riskIcon: String {
        switch request.riskLevel {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    private var explanationText: String {
        switch request.riskLevel {
        case .low:
            return "This action has minimal risk but requires your confirmation to proceed. You can approve this with confidence."
        case .medium:
            return "This action requires your attention as it may have important consequences. Please review the details carefully."
        case .high:
            return "This is a high-risk action that requires careful consideration. Please ensure all details are correct before approving."
        }
    }

    private var canModify: Bool {
        // Some actions can be modified before approval
        request.actionType == .booking || request.actionType == .scheduling
    }

    // MARK: - Actions

    private func handleApprove() {
        isProcessing = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let result = ApprovalResult(
            approved: true,
            timestamp: Date(),
            note: note.isEmpty ? nil : note,
            canUndo: request.actionType != .purchase,
            undoDeadline: Date().addingTimeInterval(300) // 5 minutes
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onApprove(result)
            dismiss()
        }
    }

    private func handleReject() {
        isProcessing = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        let result = ApprovalResult(
            approved: false,
            timestamp: Date(),
            note: note.isEmpty ? nil : note,
            canUndo: false,
            undoDeadline: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onReject(result)
            dismiss()
        }
    }

    private func handleModify() {
        // Navigate to modification screen
    }
}

// MARK: - Approval Detail Row

struct ApprovalDetailRow: View {
    let detail: ApprovalDetail

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = detail.icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(detail.important ? .orange : .blue)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(detail.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(detail.value)
                    .font(.body.weight(detail.important ? .semibold : .regular))
                    .foregroundStyle(detail.important ? .primary : .primary)
            }

            Spacer()

            if detail.important {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(detail.important ? Color.orange.opacity(0.05) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Approval History View

struct ApprovalHistoryView: View {
    @StateObject private var viewModel = ApprovalHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.approvalHistory) { request in
                        ApprovalHistoryCard(request: request)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Approval History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ApprovalHistoryCard: View {
    let request: ApprovalRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.headline)

                    Text(request.actionType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(status: request.status)
            }

            Text(request.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if let result = request.result {
                    Spacer()
                    if result.canUndo, let deadline = result.undoDeadline, deadline > Date() {
                        Button(action: {}) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatusBadge: View {
    let status: ApprovalRequest.ApprovalStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - View Model

class ApprovalHistoryViewModel: ObservableObject {
    @Published var approvalHistory: [ApprovalRequest] = []

    init() {
        loadHistory()
    }

    func loadHistory() {
        // Load from storage
    }
}

#Preview("Approval Flow") {
    ApprovalFlowView(
        request: ApprovalRequest(
            title: "Book Doctor Appointment",
            description: "I'd like to book an appointment with Dr. Sarah Johnson for a routine checkup on March 15, 2026 at 2:30 PM.",
            actionType: .booking,
            riskLevel: .medium,
            details: [
                ApprovalDetail(label: "Doctor", value: "Dr. Sarah Johnson", icon: "stethoscope", important: true),
                ApprovalDetail(label: "Date", value: "March 15, 2026", icon: "calendar", important: true),
                ApprovalDetail(label: "Time", value: "2:30 PM", icon: "clock", important: true),
                ApprovalDetail(label: "Type", value: "Routine Checkup", icon: "heart"),
                ApprovalDetail(label: "Duration", value: "30 minutes", icon: "timer"),
                ApprovalDetail(label: "Location", value: "Main Street Clinic", icon: "mappin"),
                ApprovalDetail(label: "Insurance", value: "Covered", icon: "shield.checkmark")
            ],
            expiresAt: Date().addingTimeInterval(3600)
        ),
        onApprove: { _ in },
        onReject: { _ in }
    )
}

#Preview("Approval History") {
    ApprovalHistoryView()
}
