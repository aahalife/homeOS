import SwiftUI

struct ActionsView: View {
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
                    color: .green
                )

                QuickActionCard(
                    icon: "bag.fill",
                    title: "Sell Item",
                    color: .orange
                )

                QuickActionCard(
                    icon: "cart.fill",
                    title: "Groceries",
                    color: .blue
                )

                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Hire Helper",
                    color: .purple
                )

                QuickActionCard(
                    icon: "calendar",
                    title: "Schedule",
                    color: .pink
                )

                QuickActionCard(
                    icon: "doc.text.fill",
                    title: "Note → Action",
                    color: .cyan
                )
            }
        }
    }

    private var recentActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 8) {
                RecentActionRow(
                    icon: "phone.fill",
                    title: "Called Osteria Mozza",
                    subtitle: "Reservation confirmed",
                    time: "2 hours ago",
                    color: .green
                )

                RecentActionRow(
                    icon: "bag.fill",
                    title: "Posted stroller listing",
                    subtitle: "3 interested buyers",
                    time: "Yesterday",
                    color: .orange
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button {
            // Action
        } label: {
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
