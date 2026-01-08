import SwiftUI

struct ActionsView: View {
    @StateObject private var viewModel = ActionsViewModel()
    @State private var showMakeCall = false
    @State private var showSellItem = false
    @State private var showGroceries = false
    @State private var showHireHelper = false
    @State private var showSchedule = false
    @State private var showNoteToAction = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Actions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        // Quick actions grid
                        quickActionsSection

                        // Recent actions
                        recentActionsSection
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showMakeCall) {
            MakeCallSheet()
        }
        .sheet(isPresented: $showSellItem) {
            SellItemSheet()
        }
        .sheet(isPresented: $showGroceries) {
            GroceriesSheet()
        }
        .sheet(isPresented: $showHireHelper) {
            HireHelperSheet()
        }
        .sheet(isPresented: $showSchedule) {
            ScheduleSheet()
        }
        .sheet(isPresented: $showNoteToAction) {
            NoteToActionSheet()
        }
        .task {
            await viewModel.loadRecentActions()
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionCard(
                    icon: "phone.fill",
                    title: "Make a Call",
                    color: .green,
                    action: { showMakeCall = true }
                )

                QuickActionCard(
                    icon: "bag.fill",
                    title: "Sell Item",
                    color: .orange,
                    action: { showSellItem = true }
                )

                QuickActionCard(
                    icon: "cart.fill",
                    title: "Groceries",
                    color: .blue,
                    action: { showGroceries = true }
                )

                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Hire Helper",
                    color: .purple,
                    action: { showHireHelper = true }
                )

                QuickActionCard(
                    icon: "calendar",
                    title: "Schedule",
                    color: .pink,
                    action: { showSchedule = true }
                )

                QuickActionCard(
                    icon: "doc.text.fill",
                    title: "Note → Action",
                    color: .cyan,
                    action: { showNoteToAction = true }
                )
            }
        }
    }

    private var recentActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            if viewModel.recentActions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                    Text("No recent actions")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(GlassSurface(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentActions) { action in
                        RecentActionRow(
                            icon: action.icon,
                            title: action.title,
                            subtitle: action.subtitle,
                            time: action.timeAgo,
                            color: action.color
                        )
                    }
                }
            }
        }
    }
}

// MARK: - View Model

struct RecentAction: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: Date
    let actionType: ActionType

    enum ActionType {
        case call, marketplace, groceries, helper, schedule, note
    }

    var color: Color {
        switch actionType {
        case .call: return .green
        case .marketplace: return .orange
        case .groceries: return .blue
        case .helper: return .purple
        case .schedule: return .pink
        case .note: return .cyan
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

@MainActor
class ActionsViewModel: ObservableObject {
    @Published var recentActions: [RecentAction] = []
    @Published var isLoading = false

    func loadRecentActions() async {
        // In production, fetch from API
        // For now, show sample data
        recentActions = [
            RecentAction(
                id: "1",
                icon: "phone.fill",
                title: "Called Osteria Mozza",
                subtitle: "Reservation confirmed for Friday 7pm",
                timestamp: Date().addingTimeInterval(-7200),
                actionType: .call
            ),
            RecentAction(
                id: "2",
                icon: "bag.fill",
                title: "Posted stroller listing",
                subtitle: "3 interested buyers",
                timestamp: Date().addingTimeInterval(-86400),
                actionType: .marketplace
            ),
            RecentAction(
                id: "3",
                icon: "cart.fill",
                title: "Instacart order placed",
                subtitle: "22 items, delivery tomorrow",
                timestamp: Date().addingTimeInterval(-172800),
                actionType: .groceries
            )
        ]
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(GlassSurface(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct RecentActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        GlassCard(cornerRadius: 12, padding: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

#Preview {
    ActionsView()
}
