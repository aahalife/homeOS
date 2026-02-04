import Foundation

/// Family Coordination Skill - Calendar, chores, broadcast messaging, location
final class FamilyCoordinationSkill {
    private let calendarAPI = GoogleCalendarAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Calendar

    func getUpcomingEvents(family: Family, daysAhead: Int = 7) async -> [CalendarEvent] {
        let timeMin = Date()
        let timeMax = Date().addingDays(daysAhead)

        if calendarAPI.isAuthenticated {
            do {
                return try await calendarAPI.listEvents(timeMin: timeMin, timeMax: timeMax)
            } catch {
                logger.warning("Google Calendar fetch failed: \(error.localizedDescription)")
            }
        }

        // Return stub data + stored events
        let stored: [CalendarEvent] = persistence.loadData(type: "calendar_events")
        let upcoming = stored.filter { $0.startTime >= timeMin && $0.startTime <= timeMax }
        return upcoming.isEmpty ? StubCalendarData.sampleEvents : upcoming
    }

    func createEvent(title: String, startTime: Date, endTime: Date, member: FamilyMember? = nil) async -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            startTime: startTime,
            endTime: endTime,
            memberId: member?.id,
            memberName: member?.name,
            source: .local
        )

        // Try Google Calendar
        if calendarAPI.isAuthenticated {
            do {
                let googleEvent = try await calendarAPI.createEvent(title: title, startTime: startTime, endTime: endTime)
                persistence.saveData(googleEvent, type: "calendar_events")
                return googleEvent
            } catch {
                logger.warning("Failed to create Google Calendar event: \(error.localizedDescription)")
            }
        }

        // Save locally
        persistence.saveData(event, type: "calendar_events")
        return event
    }

    func detectConflicts(events: [CalendarEvent]) -> [ScheduleConflict] {
        var conflicts: [ScheduleConflict] = []
        let sorted = events.sorted { $0.startTime < $1.startTime }

        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                let event1 = sorted[i]
                let event2 = sorted[j]

                // Check for overlap
                if event1.endTime > event2.startTime && event1.startTime < event2.endTime {
                    conflicts.append(ScheduleConflict(
                        event1: event1,
                        event2: event2,
                        memberName: event1.memberName ?? "Unknown"
                    ))
                }
            }
        }

        return conflicts
    }

    // MARK: - Chores

    func assignChore(family: Family, task: String, to personName: String) -> Chore {
        let assignee = family.members.first { $0.name.lowercased().contains(personName.lowercased()) } ?? family.children.first ?? family.members.first!
        let assigner = family.adults.first ?? family.members.first!

        let chore = Chore(
            title: task,
            assignedTo: assignee.id,
            assignedToName: assignee.name,
            assignedBy: assigner.id,
            dueDate: Date().addingDays(1),
            points: calculateChorePoints(task: task)
        )

        persistence.saveData(chore, type: "chores")
        logger.info("Chore '\(task)' assigned to \(assignee.name)")
        return chore
    }

    func getChores(family: Family) -> [Chore] {
        let chores: [Chore] = persistence.loadData(type: "chores")
        return chores.filter { chore in
            family.members.contains { $0.id == chore.assignedTo }
        }.sorted { $0.dueDate < $1.dueDate }
    }

    func getChoreLeaderboard(family: Family) -> [(name: String, points: Int)] {
        let chores: [Chore] = persistence.loadData(type: "chores")
        let completed = chores.filter { $0.status == .completed || $0.status == .verified }

        var pointsByMember: [UUID: Int] = [:]
        for chore in completed {
            pointsByMember[chore.assignedTo, default: 0] += chore.points
        }

        return family.members.map { member in
            (name: member.name, points: pointsByMember[member.id] ?? 0)
        }.sorted { $0.points > $1.points }
    }

    // MARK: - Broadcast

    func broadcastMessage(family: Family, message: String) {
        let broadcast = BroadcastMessage(
            senderId: family.adults.first?.id ?? UUID(),
            senderName: family.adults.first?.name ?? "Family",
            message: message,
            recipients: family.members.map { $0.id }
        )

        persistence.saveData(broadcast, type: "broadcasts")
        logger.info("Broadcast sent: \(message)")
    }

    // MARK: - Location

    func getFamilyLocations(family: Family) -> [FamilyMemberLocation] {
        // In production, this would use CoreLocation
        return family.members.map { member in
            FamilyMemberLocation(
                memberId: member.id,
                memberName: member.name,
                latitude: 0, longitude: 0,
                placeName: member.role == .child ? "School" : "Home",
                batteryLevel: Double.random(in: 0.3...1.0),
                sharingEnabled: true
            )
        }
    }

    // MARK: - Schedule Optimization

    func findCommonFreeTime(family: Family, duration: Int = 60) async -> [DateInterval] {
        let events = await getUpcomingEvents(family: family)
        var freeSlots: [DateInterval] = []

        let today = Date().startOfDay
        for day in 0..<7 {
            let dayStart = today.addingDays(day).addingHours(9) // Start at 9 AM
            let dayEnd = today.addingDays(day).addingHours(21)  // End at 9 PM
            let dayEvents = events.filter { Calendar.current.isDate($0.startTime, inSameDayAs: dayStart) }

            // Find gaps in schedule
            var currentTime = dayStart
            for event in dayEvents.sorted(by: { $0.startTime < $1.startTime }) {
                if event.startTime.timeIntervalSince(currentTime) >= Double(duration * 60) {
                    freeSlots.append(DateInterval(start: currentTime, end: event.startTime))
                }
                currentTime = max(currentTime, event.endTime)
            }

            if dayEnd.timeIntervalSince(currentTime) >= Double(duration * 60) {
                freeSlots.append(DateInterval(start: currentTime, end: dayEnd))
            }
        }

        return freeSlots
    }

    // MARK: - Helpers

    private func calculateChorePoints(task: String) -> Int {
        let lower = task.lowercased()
        if lower.contains("clean room") || lower.contains("tidy") { return 10 }
        if lower.contains("dishes") || lower.contains("wash") { return 15 }
        if lower.contains("vacuum") || lower.contains("mop") { return 20 }
        if lower.contains("laundry") { return 25 }
        if lower.contains("mow") || lower.contains("yard") { return 30 }
        if lower.contains("trash") || lower.contains("garbage") { return 10 }
        return 15
    }
}
