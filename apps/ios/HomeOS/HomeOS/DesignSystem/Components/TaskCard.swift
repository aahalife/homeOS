import SwiftUI

struct TaskCard: View {
    let task: TaskItem
    var onApprove: (() -> Void)?
    var onDeny: (() -> Void)?

    @State private var isExpanded = false
    @State private var isProcessing = false
    @Namespace private var animation

    var body: some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: task.categoryIcon)
                        .font(.title3)
                        .foregroundColor(task.statusColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(task.summary)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        StatusPill(status: task.statusText, color: task.statusColor)
                    }
                }

                if isExpanded {
                    GlowDivider()

                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        if let details = task.details {
                            Text(details)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // Risk level indicator
                        if task.riskLevel != .low {
                            HStack(spacing: 6) {
                                Image(systemName: task.riskLevel == .high ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                    .foregroundColor(task.riskLevel == .high ? .orange : .yellow)

                                Text(task.riskLevel == .high ? "High risk action" : "Medium risk action")
                                    .font(.caption)
                                    .foregroundColor(task.riskLevel == .high ? .orange : .yellow)
                            }
                        }
                    }

                    // Action buttons
                    if task.requiresApproval && task.status == .needsApproval && !isProcessing {
                        HStack(spacing: 12) {
                            LiquidButton(title: "Approve", icon: "checkmark", action: {
                                isProcessing = true
                                onApprove?()
                            })
                            .matchedGeometryEffect(id: "approve", in: animation)

                            LiquidButton(title: "Deny", icon: "xmark", action: {
                                isProcessing = true
                                onDeny?()
                            }, style: .destructive)
                        }
                    }
                }

                // Expand/collapse indicator
                HStack {
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// Task model
struct TaskItem: Identifiable {
    let id: String
    let title: String
    let summary: String
    let category: Category
    let status: Status
    let riskLevel: RiskLevel
    let requiresApproval: Bool
    let details: String?
    let createdAt: Date

    enum Category: String {
        case chat, telephony, marketplace, helpers, calendar, groceries, integration

        var icon: String {
            switch self {
            case .chat: return "bubble.left"
            case .telephony: return "phone"
            case .marketplace: return "bag"
            case .helpers: return "person.2"
            case .calendar: return "calendar"
            case .groceries: return "cart"
            case .integration: return "puzzle.piece"
            }
        }
    }

    enum Status: String {
        case queued, running, needsApproval, blocked, done, failed

        var text: String {
            switch self {
            case .queued: return "Queued"
            case .running: return "Running"
            case .needsApproval: return "Needs Approval"
            case .blocked: return "Blocked"
            case .done: return "Done"
            case .failed: return "Failed"
            }
        }

        var color: Color {
            switch self {
            case .queued: return .gray
            case .running: return .blue
            case .needsApproval: return .orange
            case .blocked: return .red
            case .done: return .green
            case .failed: return .red
            }
        }
    }

    enum RiskLevel: String {
        case low, medium, high
    }

    var categoryIcon: String { category.icon }
    var statusText: String { status.text }
    var statusColor: Color { status.color }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        TaskCard(task: TaskItem(
            id: "1",
            title: "Book restaurant",
            summary: "Finding Italian restaurants for Friday 7pm",
            category: .telephony,
            status: .needsApproval,
            riskLevel: .high,
            requiresApproval: true,
            details: "I found 3 restaurants matching your criteria. Ready to call Osteria Mozza to make a reservation.",
            createdAt: Date()
        ))
        .padding()
    }
}
