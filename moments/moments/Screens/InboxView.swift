import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    private let approvals: [ApprovalItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "NEEDS YOUR APPROVAL")

                    if approvals.isEmpty {
                        StandardCard {
                            Text("No approvals yet. Oi will surface approvals here as workflows run.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else {
                        ForEach(approvals) { item in
                            StandardCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(item.detail)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(item.timeAgo)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                    HStack(spacing: 12) {
                                        Button("Approve") {}
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 14)
                                            .background(Color(hex: "34C759"))
                                            .cornerRadius(10)
                                        Button("Deny") {}
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color(hex: "FF3B30"))
                                        Spacer()
                                        Button("Details") {}
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.primary)
                                    }
                                }
                            }
                        }
                    }

                    SectionHeader(title: "RECENT")

                    if viewModel.notifications.isEmpty {
                        StandardCard {
                            Text("No recent updates yet.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else {
                        ForEach(viewModel.notifications) { item in
                            StandardCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(item.isUnread ? AppTheme.primary : AppTheme.surfaceSecondary)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(item.detail)
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text(item.timeAgo)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                    Spacer()
                                }
                            }
                            .onTapGesture {
                                Task { await viewModel.markRead(item) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Inbox")
            .toolbar {
                Button("Mark All Read") {
                    Task { await viewModel.markAllRead() }
                }
                .font(.subheadline)
            }
        }
        .task {
            await viewModel.refresh()
        }
    }
}

private struct ApprovalItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let timeAgo: String
}

private struct NotificationItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let timeAgo: String
    let isUnread: Bool
}

@MainActor
private final class InboxViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .runtimeEventReceived,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refresh() async {
        guard let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            notifications = []
            return
        }

        do {
            let records = try await ControlPlaneAPI.shared.fetchNotifications(token: token, workspaceId: workspaceId)
            notifications = records.map { record in
                NotificationItem(
                    id: record.id,
                    title: record.title,
                    detail: record.body,
                    timeAgo: relativeTime(from: record.createdAt),
                    isUnread: record.status != "read"
                )
            }
        } catch {
            print("Failed to load notifications: \(error)")
        }
    }

    func markRead(_ item: NotificationItem, refreshAfter: Bool = true) async {
        guard item.isUnread,
              let token = KeychainStore.shared.getString(forKey: "authToken"),
              let workspaceId = UserDefaults.standard.string(forKey: "workspaceId"),
              !token.isEmpty,
              !workspaceId.isEmpty else {
            return
        }

        do {
            try await ControlPlaneAPI.shared.markNotificationRead(
                token: token,
                workspaceId: workspaceId,
                notificationId: item.id
            )
            if refreshAfter {
                await refresh()
            }
        } catch {
            print("Failed to mark notification read: \(error)")
        }
    }

    func markAllRead() async {
        for item in notifications where item.isUnread {
            await markRead(item, refreshAfter: false)
        }
        await refresh()
    }

    private func relativeTime(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "Just now" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) min ago" }
        if interval < 86400 { return "\(Int(interval / 3600)) hr ago" }
        return "\(Int(interval / 86400)) d ago"
    }
}
