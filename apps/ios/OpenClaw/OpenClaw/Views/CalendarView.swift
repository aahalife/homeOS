import SwiftUI

/// Family calendar view
struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var events: [CalendarEvent] = []
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                Divider()

                if filteredEvents.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar", description: Text("No events scheduled for this day."))
                } else {
                    List(filteredEvents) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                            HStack {
                                Text(event.startTime.timeString)
                                Text("-")
                                Text(event.endTime.timeString)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let member = event.memberName {
                                Text(member)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Calendar")
            .task { await loadEvents() }
        }
    }

    private var filteredEvents: [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    private func loadEvents() async {
        guard let family = appState.currentFamily else { return }
        events = await FamilyCoordinationSkill().getUpcomingEvents(family: family, daysAhead: 30)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppState())
}
