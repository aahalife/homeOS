import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionManager
    @Binding var selectedTab: MainTab
    @State private var priorities: [PriorityItem] = [
        PriorityItem(title: "Emma - Physics lab due", isComplete: false),
        PriorityItem(title: "Jack - Soccer practice 4 PM", isComplete: false),
        PriorityItem(title: "Sign permission slip", isComplete: false)
    ]
    @State private var showScheduleSheet = false

    private let scheduleItems: [ScheduleItem] = [
        ScheduleItem(time: "8:00 AM", title: "School drop-off", icon: "car.fill"),
        ScheduleItem(time: "10:00 AM", title: "Parent - Client call", icon: "briefcase.fill"),
        ScheduleItem(time: "3:30 PM", title: "Emma - Dentist", icon: "cross.case.fill"),
        ScheduleItem(time: "4:00 PM", title: "Jack - Soccer", icon: "sportscourt.fill"),
        ScheduleItem(time: "6:30 PM", title: "Family dinner", icon: "fork.knife")
    ]

    private let attentionItems = [
        "1 approval pending",
        "Emma's grade dropped (Physics)"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    StandardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "clipboard.fill")
                                Text("TODAY'S PRIORITIES")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)

                            ForEach($priorities) { $item in
                                Button {
                                    item.isComplete.toggle()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isComplete ? Color(hex: "34C759") : AppTheme.textTertiary)
                                        Text(item.title)
                                            .foregroundColor(.primary)
                                            .strikethrough(item.isComplete, color: AppTheme.textTertiary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    StandardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                Text("FAMILY SCHEDULE")
                                Spacer()
                                Button("See full") {
                                    showScheduleSheet = true
                                }
                                .font(.caption)
                                .foregroundColor(AppTheme.primary)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)

                            ForEach(scheduleItems) { item in
                                HStack(spacing: 12) {
                                    Text(item.time)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                        .frame(width: 70, alignment: .leading)
                                    Image(systemName: item.icon)
                                        .foregroundColor(AppTheme.primary)
                                    Text(item.title)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        showScheduleSheet = true
                    }

                    StandardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: "FF9500"))
                                Text("NEEDS ATTENTION")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textSecondary)

                            ForEach(attentionItems, id: \.self) { item in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: "FF3B30"))
                                        .frame(width: 6, height: 6)
                                    Text(item)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Button(action: { selectedTab = .chat }) {
                        HStack(spacing: 12) {
                            Text("Ask Oi anything...")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Image(systemName: "mic.fill")
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showScheduleSheet) {
                ScheduleDetailView(items: scheduleItems)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(greeting), \(firstName)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
            }

            HStack(spacing: 12) {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(Color(hex: "FF9500"))
                    Text("52 F")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var firstName: String {
        let name = session.userName
        if let first = name.split(separator: " ").first {
            return String(first)
        }
        return name
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

private struct PriorityItem: Identifiable {
    let id = UUID()
    let title: String
    var isComplete: Bool
}

private struct ScheduleItem: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let icon: String
}

private struct ScheduleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let items: [ScheduleItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Text(item.time)
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                            .frame(width: 70, alignment: .leading)
                        Image(systemName: item.icon)
                            .foregroundColor(AppTheme.primary)
                        Text(item.title)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Family Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
