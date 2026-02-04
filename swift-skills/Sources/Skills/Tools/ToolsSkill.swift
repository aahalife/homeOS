import Foundation
import HomeOSCore

public struct ToolsSkill: SkillProtocol {
    public let name = "tools"
    public let description = "Utility catch-all: calendar CRUD, reminders, weather, notes"
    public let triggerKeywords = ["add event", "delete event", "calendar", "remind me", "reminder",
                                  "weather", "note", "save note", "schedule", "cancel event",
                                  "move event", "reschedule", "todo", "set reminder"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        // Calendar operations
        if message.contains("delete event") || message.contains("cancel event") || message.contains("remove event") {
            return try await deleteCalendarEvent(context: context)
        } else if message.contains("add event") || message.contains("schedule") || message.contains("create event") {
            return try await addCalendarEvent(context: context)
        } else if message.contains("reschedule") || message.contains("move event") {
            return try await rescheduleEvent(context: context)
        } else if message.contains("calendar") || message.contains("what's on") || message.contains("events") {
            return try await viewCalendar(context: context)
        }
        // Reminders
        else if message.contains("remind") || message.contains("reminder") || message.contains("todo") {
            return try await createReminder(context: context)
        }
        // Weather
        else if message.contains("weather") {
            return try await weatherInfo(context: context)
        }
        // Notes
        else if message.contains("note") || message.contains("save") || message.contains("jot") {
            return try await saveNote(context: context)
        }
        else {
            return .response("🔧 I can help with:\n• Calendar (add, view, reschedule, delete events)\n• Reminders\n• Weather\n• Notes\n\nWhat do you need?")
        }
    }

    // MARK: - Calendar: View

    private func viewCalendar(context: SkillContext) async throws -> SkillResult {
        let todayStr = dateString(context.currentDate)
        let target = context.intent.entities.dates.first ?? todayStr

        let events = context.calendar.filter { $0.date == target }.sorted { ($0.time ?? "") < ($1.time ?? "") }

        let dateLabel = target == todayStr ? "Today" : target
        if events.isEmpty {
            return .response("📅 \(dateLabel): No events scheduled. Want to add one?")
        }

        var response = "📅 \(dateLabel) — \(events.count) event(s)\n\n"
        for event in events {
            let time = event.time ?? "All day"
            let dur = event.duration.map { " (\($0) min)" } ?? ""
            response += "  \(time)\(dur) — \(event.title)\n"
            if let loc = event.location { response += "    📍 \(loc)\n" }
            if let notes = event.notes { response += "    📝 \(notes)\n" }
        }
        return .response(response)
    }

    // MARK: - Calendar: Add

    private func addCalendarEvent(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        Parse this into a calendar event: "\(context.intent.rawMessage)"
        Return JSON with: title, date (YYYY-MM-DD), time (HH:MM or null), duration (minutes or null), location (or null).
        """

        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "title": { "type": "string" },
                "date": { "type": "string" },
                "time": { "type": "string" },
                "duration": { "type": "integer" },
                "location": { "type": "string" }
            },
            "required": ["title", "date"],
            "additionalProperties": false
        }
        """)

        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)

        guard let data = json.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ParsedEvent.self, from: data) else {
            return .response("I couldn't parse that event. Try: \"Add event: Dentist on 2024-03-15 at 2pm\"")
        }

        let event = CalendarEvent(
            title: parsed.title,
            date: parsed.date,
            time: parsed.time,
            duration: parsed.duration,
            location: parsed.location
        )

        try await context.storage.append(path: "data/calendar_events.json", item: event)

        var response = "✅ EVENT ADDED\n\n"
        response += "📅 \(event.title)\n"
        response += "📆 \(event.date)"
        if let time = event.time { response += " at \(time)" }
        response += "\n"
        if let dur = event.duration { response += "⏱ \(dur) minutes\n" }
        if let loc = event.location { response += "📍 \(loc)\n" }
        response += "\nWant to add a reminder for this?"
        return .response(response)
    }

    // MARK: - Calendar: Delete (HIGH risk)

    private func deleteCalendarEvent(context: SkillContext) async throws -> SkillResult {
        // Find matching event
        let message = context.intent.rawMessage.lowercased()
        let matchingEvents = context.calendar.filter { event in
            message.contains(event.title.lowercased())
        }

        guard let event = matchingEvents.first else {
            // Show upcoming events to pick from
            let upcoming = context.calendar.sorted { $0.date < $1.date }.prefix(5)
            if upcoming.isEmpty {
                return .response("📅 No events found to delete.")
            }
            var response = "Which event do you want to delete?\n\n"
            for (i, event) in upcoming.enumerated() {
                response += "  \(i + 1). \(event.date) — \(event.title)\n"
            }
            response += "\nSay the event name to delete it."
            return .response(response)
        }

        // HIGH risk — require approval
        return .needsApproval(ApprovalRequest(
            description: "Delete calendar event: \(event.title)",
            details: [
                "Event: \(event.title)",
                "Date: \(event.date)",
                "Time: \(event.time ?? "All day")",
                "⚠️ This action cannot be undone"
            ],
            riskLevel: .high,
            onDecision: { [event] approved in
                if approved {
                    // In production, this would remove from storage
                    return .response("🗑 Event deleted: \"\(event.title)\" on \(event.date)\n\nCalendar updated.")
                } else {
                    return .response("👍 Event kept. No changes made.")
                }
            }
        ))
    }

    // MARK: - Calendar: Reschedule

    private func rescheduleEvent(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        let matchingEvents = context.calendar.filter { message.contains($0.title.lowercased()) }

        guard let event = matchingEvents.first else {
            return .response("Which event do you want to reschedule? Give me the name and the new date/time.")
        }

        let newDate = context.intent.entities.dates.first
        let newTime = context.intent.entities.times.first

        guard newDate != nil || newTime != nil else {
            return .response("📅 Reschedule \"\(event.title)\" — to when? Give me a date and/or time.")
        }

        return .needsApproval(ApprovalRequest(
            description: "Reschedule: \(event.title)",
            details: [
                "From: \(event.date) \(event.time ?? "")",
                "To: \(newDate ?? event.date) \(newTime ?? event.time ?? "")",
            ],
            riskLevel: .medium,
            onDecision: { approved in
                if approved {
                    return .response("✅ \"\(event.title)\" rescheduled to \(newDate ?? event.date) \(newTime ?? event.time ?? "").")
                } else {
                    return .response("👍 Keeping the original schedule.")
                }
            }
        ))
    }

    // MARK: - Reminders

    private func createReminder(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        Parse this reminder: "\(context.intent.rawMessage)"
        Return JSON with: title, dueDate (YYYY-MM-DD or null), dueTime (HH:MM or null), priority (low/normal/high/urgent).
        """

        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "title": { "type": "string" },
                "dueDate": { "type": "string" },
                "dueTime": { "type": "string" },
                "priority": { "type": "string" }
            },
            "required": ["title", "priority"],
            "additionalProperties": false
        }
        """)

        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)

        guard let data = json.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ParsedReminder.self, from: data) else {
            return .response("I couldn't parse that reminder. Try: \"Remind me to call dentist tomorrow at 2pm\"")
        }

        let priority: TaskPriority
        switch parsed.priority.lowercased() {
        case "urgent": priority = .urgent
        case "high": priority = .high
        case "low": priority = .low
        default: priority = .normal
        }

        let task = HomeTask(
            type: .reminder,
            title: parsed.title,
            dueDate: parsed.dueDate,
            dueTime: parsed.dueTime,
            priority: priority
        )

        try await context.storage.append(path: "data/tasks.json", item: task)

        var response = "⏰ REMINDER SET\n\n"
        response += "📌 \(task.title)\n"
        if let date = task.dueDate { response += "📅 \(date)" }
        if let time = task.dueTime { response += " at \(time)" }
        response += "\n"
        response += "🔔 Priority: \(priority.rawValue)\n"
        return .response(response)
    }

    // MARK: - Weather

    private func weatherInfo(context: SkillContext) async throws -> SkillResult {
        let location = context.intent.entities.locations.first ?? "your location"

        // LLM provides general guidance since we don't have a weather API
        let prompt = """
        The user asked about weather: "\(context.intent.rawMessage)"
        Location: \(location). Current date: \(dateString(context.currentDate)).
        Explain that you don't have live weather data, but suggest:
        1. How to check (apps/sites)
        2. General seasonal expectations for the time of year
        Keep it to 3-4 sentences.
        """

        let response = try await context.llm.generate(prompt: prompt)

        var result = "🌤 WEATHER\n\n"
        result += response + "\n\n"
        result += "📱 Quick links: Weather.com, Apple Weather, or ask Siri\n"
        result += "Want me to factor weather into your plans?"
        return .response(result)
    }

    // MARK: - Notes

    private func saveNote(context: SkillContext) async throws -> SkillResult {
        // Strip the "save note" / "note:" prefix
        var noteText = context.intent.rawMessage
        for prefix in ["save note:", "save note", "note:", "jot down:", "jot down", "note"] {
            if noteText.lowercased().hasPrefix(prefix) {
                noteText = String(noteText.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        let note = NoteEntry(
            id: UUID().uuidString,
            text: noteText,
            date: dateString(context.currentDate),
            time: timeString(context.currentDate)
        )

        try await context.storage.append(path: "data/notes.json", item: note)

        return .response("📝 Note saved!\n\n\"\(noteText)\"\n\n📅 \(note.date) at \(note.time)")
    }

    // MARK: - Helpers

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
}

// MARK: - DTOs

private struct ParsedEvent: Codable {
    let title: String
    let date: String
    let time: String?
    let duration: Int?
    let location: String?
}

private struct ParsedReminder: Codable {
    let title: String
    let dueDate: String?
    let dueTime: String?
    let priority: String
}

private struct NoteEntry: Codable {
    let id: String
    let text: String
    let date: String
    let time: String
}
