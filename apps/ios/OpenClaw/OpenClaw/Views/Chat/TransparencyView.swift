import SwiftUI

/// Transparency dashboard showing what OpenClaw did and plans to do
struct TransparencyView: View {
    @StateObject private var viewModel = TransparencyViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var showingPrivacySettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trust score card
                    trustScoreCard

                    // Daily summary
                    dailySummarySection

                    // Key actions today
                    keyActionsSection

                    // Planned actions
                    plannedActionsSection

                    // API calls
                    apiCallsSection

                    // Data usage
                    dataUsageSection

                    // Activity log
                    activityLogSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transparency")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView(settings: $viewModel.privacySettings)
            }
        }
    }

    // MARK: - Trust Score Card

    private var trustScoreCard: some View {
        VStack(spacing: 16) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: viewModel.trustScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: trustScoreColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(viewModel.trustScore))")
                        .font(.system(size: 48, weight: .bold))
                    Text("Trust Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Score description
            Text(trustScoreDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Quick stats
            HStack(spacing: 24) {
                QuickStat(
                    value: "\(viewModel.dailySummary.actionsCompleted)",
                    label: "Actions",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                QuickStat(
                    value: "\(viewModel.dailySummary.apiCallsMade)",
                    label: "API Calls",
                    icon: "network",
                    color: .blue
                )

                QuickStat(
                    value: viewModel.dailySummary.automationsSaved,
                    label: "Time Saved",
                    icon: "clock.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }

    private var trustScoreColors: [Color] {
        if viewModel.trustScore >= 90 {
            return [.green, .mint]
        } else if viewModel.trustScore >= 70 {
            return [.blue, .cyan]
        } else {
            return [.orange, .yellow]
        }
    }

    private var trustScoreDescription: String {
        if viewModel.trustScore >= 90 {
            return "Excellent! OpenClaw is working transparently and reliably."
        } else if viewModel.trustScore >= 70 {
            return "Good performance with room for improvement."
        } else {
            return "Some actions need your attention to improve trust."
        }
    }

    // MARK: - Daily Summary

    private var dailySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Today's Summary",
                subtitle: selectedDate.formatted(date: .long, time: .omitted),
                icon: "calendar"
            )

            StatsGrid(stats: [
                ("Actions Completed", "\(viewModel.dailySummary.actionsCompleted)", "checkmark.circle.fill", Color.green),
                ("API Calls Made", "\(viewModel.dailySummary.apiCallsMade)", "network", Color.blue),
                ("Data Points", "\(viewModel.dailySummary.dataPointsAccessed)", "lock.shield.fill", Color.purple),
                ("Time Saved", viewModel.dailySummary.automationsSaved, "clock.fill", Color.orange)
            ])
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Key Actions

    private var keyActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "What I Did Today",
                subtitle: "\(viewModel.dailySummary.keyActions.count) key actions",
                icon: "sparkles"
            )

            ForEach(viewModel.dailySummary.keyActions) { action in
                KeyActionCard(action: action)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Planned Actions

    private var plannedActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "What's Planned",
                subtitle: "\(viewModel.dailySummary.plannedActions.count) upcoming actions",
                icon: "calendar.badge.clock"
            )

            ForEach(viewModel.dailySummary.plannedActions) { action in
                PlannedActionCard(action: action)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - API Calls

    private var apiCallsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "API Calls",
                subtitle: "\(viewModel.recentApiCalls.count) calls made",
                icon: "server.rack"
            )

            ForEach(viewModel.recentApiCalls.prefix(5)) { call in
                APICallRow(call: call)
            }

            if viewModel.recentApiCalls.count > 5 {
                Button(action: { viewModel.showAllApiCalls() }) {
                    Text("View All API Calls")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data Usage

    private var dataUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Data Usage",
                subtitle: "What data was accessed and why",
                icon: "lock.shield"
            )

            ForEach(viewModel.recentDataUsage.prefix(5)) { usage in
                DataUsageRow(usage: usage)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Activity Log

    private var activityLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(
                    title: "Activity Log",
                    subtitle: "Detailed timeline",
                    icon: "list.bullet.rectangle"
                )

                Spacer()

                Menu {
                    ForEach(ActivityLog.ActivityCategory.allCases, id: \.self) { category in
                        Button(action: { viewModel.filterLog(by: category) }) {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                }
            }

            ForEach(viewModel.filteredActivityLog.prefix(10)) { log in
                ActivityLogRow(log: log)
            }

            if viewModel.filteredActivityLog.count > 10 {
                Button(action: { viewModel.showAllLogs() }) {
                    Text("View All Logs")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { showingPrivacySettings = true }) {
                Image(systemName: "gearshape.fill")
            }
        }

        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { dismiss() }
        }
    }
}

// MARK: - Supporting Views

struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatsGrid: View {
    let stats: [(String, String, String, Color)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                VStack(spacing: 8) {
                    Image(systemName: stat.2)
                        .font(.title2)
                        .foregroundStyle(stat.3)

                    Text(stat.1)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    Text(stat.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct KeyActionCard: View {
    let action: KeyAction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(action.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: action.icon)
                    .foregroundStyle(action.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline.weight(.semibold))

                Text(action.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(action.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PlannedActionCard: View {
    let action: PlannedAction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline.weight(.semibold))

                Text(action.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label(
                        action.scheduledFor.formatted(date: .omitted, time: .shortened),
                        systemImage: "clock"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    if action.requiresApproval {
                        Label("Approval needed", systemImage: "hand.raised")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct APICallRow: View {
    let call: APICall

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(call.service)
                        .font(.subheadline.weight(.semibold))

                    Text(call.endpoint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: call.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(call.success ? .green : .red)
            }

            Text(call.purpose)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(call.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let responseTime = call.responseTime {
                    Text("• \(Int(responseTime * 1000))ms")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DataUsageRow: View {
    let usage: DataUsage

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(usage.sensitivity.color.opacity(0.2))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(usage.dataType)
                    .font(.subheadline.weight(.medium))

                Text(usage.purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(usage.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(usage.sensitivity.rawValue.capitalized)
                .font(.caption2.bold())
                .foregroundStyle(usage.sensitivity.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(usage.sensitivity.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ActivityLogRow: View {
    let log: ActivityLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.category.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: log.category.icon)
                    .font(.caption)
                    .foregroundStyle(log.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(log.action)
                    .font(.subheadline.weight(.semibold))

                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let reasoning = log.reasoning {
                    Text("Why: \(reasoning)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.top, 2)
                }

                Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @Binding var settings: PrivacySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Allow Data Collection", isOn: $settings.allowDataCollection)
                    Toggle("Allow API Logging", isOn: $settings.allowAPILogging)
                    Toggle("Allow Activity Tracking", isOn: $settings.allowActivityTracking)
                } header: {
                    Text("Data Collection")
                } footer: {
                    Text("These settings control what data OpenClaw can collect and log.")
                }

                Section {
                    Stepper("Keep data for \(settings.dataRetentionDays) days", value: $settings.dataRetentionDays, in: 7...90)
                } header: {
                    Text("Data Retention")
                }

                Section {
                    Toggle("Require approval for sensitive data", isOn: $settings.requireApprovalForSensitiveData)
                    Toggle("Share anonymous usage statistics", isOn: $settings.shareUsageStatistics)
                } header: {
                    Text("Privacy Controls")
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - View Model

class TransparencyViewModel: ObservableObject {
    @Published var dailySummary: DailySummary
    @Published var recentApiCalls: [APICall] = []
    @Published var recentDataUsage: [DataUsage] = []
    @Published var activityLog: [ActivityLog] = []
    @Published var filteredActivityLog: [ActivityLog] = []
    @Published var privacySettings = PrivacySettings()
    @Published var trustScore: Double = 95.0

    init() {
        // Mock data for preview
        self.dailySummary = DailySummary(
            keyActions: [],
            plannedActions: [],
            stats: DayStats()
        )
        loadData()
    }

    func loadData() {
        // Load from storage or API
        filteredActivityLog = activityLog
    }

    func filterLog(by category: ActivityLog.ActivityCategory) {
        filteredActivityLog = activityLog.filter { $0.category == category }
    }

    func showAllApiCalls() {
        // Navigate to full API calls list
    }

    func showAllLogs() {
        // Navigate to full activity log
    }
}

#Preview {
    TransparencyView()
}
