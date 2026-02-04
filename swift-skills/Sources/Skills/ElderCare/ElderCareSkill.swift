import Foundation
import HomeOSCore

public struct ElderCareSkill: SkillProtocol {
    public let name = "elder-care"
    public let description = "Warm check-ins, medication tracking, music therapy, and family updates for elderly members"
    public let triggerKeywords = [
        "check in", "check-in", "grandma", "grandpa", "elder", "senior",
        "medication reminder", "music", "play music", "family update",
        "how are you", "morning check", "evening check", "wellness check"
    ]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let message = intent.rawMessage.lowercased()
        let matches = triggerKeywords.filter { message.contains($0) }
        // Boost if elder members exist and message is conversational
        let hasElders = matches.count > 0
        return min(Double(matches.count) * 0.3 + (hasElders ? 0.1 : 0.0), 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("music") || message.contains("play") || message.contains("song") {
            return try await suggestMusic(context: context)
        } else if message.contains("medication") || message.contains("medicine") || message.contains("pill") {
            return try await elderMedicationCheck(context: context)
        } else if message.contains("family update") || message.contains("what's happening") || message.contains("news") {
            return try await familyUpdate(context: context)
        } else if message.contains("check in") || message.contains("check-in") || message.contains("how are") {
            return try await warmCheckIn(context: context)
        } else {
            return try await warmCheckIn(context: context)
        }
    }

    // MARK: - Warm Check-In

    private func warmCheckIn(context: SkillContext) async throws -> SkillResult {
        let elders = context.family.elders
        guard !elders.isEmpty else {
            return .response("No elder family members are registered. Would you like to add one?")
        }

        let elder = elders.first!
        let hour = currentHour(date: context.currentDate, timeZone: context.timeZone)
        let timeOfDay = hour < 12 ? "morning" : (hour < 17 ? "afternoon" : "evening")

        let prompt = """
        You are a warm, caring home assistant speaking to \(elder.name), \
        an elderly family member\(elder.age != nil ? " who is \(elder.age!) years old" : ""). \
        Generate a friendly \(timeOfDay) check-in message. Be conversational, warm, and genuine.
        
        Ask about:
        1. How they're feeling today
        2. If they slept well (morning) / had a good day (evening)
        3. If they need anything
        
        Keep it SHORT (3-4 sentences). Use a caring, respectful tone. \
        Don't be patronizing. Speak as a helpful companion, not a nurse.
        """

        let greeting: String
        do {
            greeting = try await context.llm.generate(prompt: prompt)
        } catch {
            greeting = "Good \(timeOfDay), \(elder.name)! 😊 How are you feeling today? Is there anything I can help you with?"
        }

        // Check if medications are due
        let medAlert = checkElderMedsDue(elder: elder, date: context.currentDate, timeZone: context.timeZone)

        var response = "💛 CHECK-IN: \(elder.name)\n\n"
        response += greeting + "\n"

        if let alert = medAlert {
            response += "\n💊 Medication reminder: \(alert)\n"
        }

        // Log the check-in
        let log = CheckInLog(
            memberId: elder.id,
            date: dateString(context.currentDate),
            time: timeString(context.currentDate, timeZone: context.timeZone),
            type: "scheduled"
        )
        try? await context.storage.append(path: "data/elder-care/checkins.json", item: log)

        return .response(response)
    }

    // MARK: - Medication Tracking

    private func elderMedicationCheck(context: SkillContext) async throws -> SkillResult {
        let elders = context.family.elders
        guard !elders.isEmpty else {
            return .response("No elder family members registered.")
        }

        var response = "💊 ELDER MEDICATION STATUS\n\n"

        for elder in elders {
            guard let medications = elder.medications, !medications.isEmpty else { continue }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.timeZone = context.timeZone
            let now = formatter.string(from: context.currentDate)

            response += "👤 \(elder.name)\n"
            for med in medications {
                let nextDose = med.times.first(where: { $0 > now }) ?? med.times.first ?? "--"
                let isDue = med.times.contains(where: { isWithinWindow($0, current: now, windowMinutes: 30) })

                if isDue {
                    response += "  ⏰ \(med.name) — \(med.dosage) — DUE NOW\n"
                } else {
                    response += "  ✅ \(med.name) — \(med.dosage) — next at \(nextDose)\n"
                }
                if let purpose = med.purpose {
                    response += "     For: \(purpose)\n"
                }
            }

            // Refill check using date math
            let refills = checkRefillsForMember(medications: medications, from: context.currentDate)
            if !refills.isEmpty {
                response += "\n  🔔 Refill needed:\n"
                for r in refills { response += "     • \(r)\n" }
            }
            response += "\n"
        }

        // Generate a warm reminder via LLM
        let reminderPrompt = """
        Generate a SHORT, warm medication reminder for an elderly person. \
        Be encouraging and gentle. One sentence. Example tone: \
        "Time for your afternoon medicine — you're doing great keeping on track!"
        """
        if let warmReminder = try? await context.llm.generate(prompt: reminderPrompt) {
            response += "💬 \(warmReminder)\n"
        }

        return .response(response)
    }

    // MARK: - Music Suggestions

    private func suggestMusic(context: SkillContext) async throws -> SkillResult {
        let elders = context.family.elders
        let elder = elders.first

        let era = elder?.preferences?.musicEra ?? "1960s-1970s"
        let artists = elder?.preferences?.musicArtists ?? []
        let elderName = elder?.name ?? "your family member"

        let prompt = """
        Suggest 5 songs for \(elderName) who enjoys music from the \(era) era.\
        \(artists.isEmpty ? "" : " They especially like: \(artists.joined(separator: ", ")).")
        
        For each song include: title, artist, and a brief warm note about why it's a great pick.
        Format as a numbered list. Be warm and nostalgic in tone.
        """

        let suggestions: String
        do {
            suggestions = try await context.llm.generate(prompt: prompt)
        } catch {
            return .response("🎵 How about some classics from the \(era)? I can help find favorites if you tell me what \(elderName) enjoys!")
        }

        var response = "🎵 MUSIC FOR \(elderName.uppercased())\n\n"
        response += suggestions + "\n\n"
        response += "Would you like me to create a longer playlist or try a different era?"

        return .response(response)
    }

    // MARK: - Family Update

    private func familyUpdate(context: SkillContext) async throws -> SkillResult {
        let elders = context.family.elders
        let elderName = elders.first?.name ?? "the family"

        // Gather recent family events
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        let threeDaysAgo = formatter.string(
            from: Calendar.current.date(byAdding: .day, value: -3, to: context.currentDate)!
        )

        let recentEvents = context.calendar.filter { $0.date >= threeDaysAgo && $0.date <= today }
        let upcomingEvents = context.calendar.filter { $0.date > today }
            .sorted { $0.date < $1.date }
            .prefix(5)

        let eventSummary = recentEvents.map { "• \($0.title) on \($0.date)" }.joined(separator: "\n")
        let upcomingSummary = upcomingEvents.map { "• \($0.title) on \($0.date)" }.joined(separator: "\n")

        let children = context.family.children.map { $0.name }

        let prompt = """
        Create a warm, conversational family update for \(elderName). \
        Speak as if you're a family helper sharing news gently and cheerfully.
        
        Recent family happenings:
        \(eventSummary.isEmpty ? "Nothing specific recorded" : eventSummary)
        
        Upcoming events:
        \(upcomingSummary.isEmpty ? "Nothing scheduled yet" : upcomingSummary)
        
        Family children: \(children.isEmpty ? "none" : children.joined(separator: ", "))
        
        Keep it warm, positive, and brief (5-6 sentences max). \
        Mention the kids by name if possible.
        """

        let update: String
        do {
            update = try await context.llm.generate(prompt: prompt)
        } catch {
            return .response("📰 Here's what's happening with the family — everything is going well! Would you like to hear about any specific family member?")
        }

        var response = "📰 FAMILY UPDATE FOR \(elderName.uppercased())\n\n"
        response += update + "\n\n"
        response += "Would you like to send a message to any family member?"

        return .response(response)
    }

    // MARK: - Helpers

    private func currentHour(date: Date, timeZone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.component(.hour, from: date)
    }

    private func checkElderMedsDue(elder: FamilyMember, date: Date, timeZone: TimeZone) -> String? {
        guard let medications = elder.medications else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        let now = formatter.string(from: date)

        let due = medications.filter { med in
            med.times.contains(where: { isWithinWindow($0, current: now, windowMinutes: 30) })
        }

        if due.isEmpty { return nil }
        return due.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
    }

    private func isWithinWindow(_ scheduled: String, current: String, windowMinutes: Int) -> Bool {
        let sParts = scheduled.split(separator: ":").compactMap { Int($0) }
        let cParts = current.split(separator: ":").compactMap { Int($0) }
        guard sParts.count == 2, cParts.count == 2 else { return false }
        let diff = abs((sParts[0] * 60 + sParts[1]) - (cParts[0] * 60 + cParts[1]))
        return diff <= windowMinutes
    }

    private func checkRefillsForMember(medications: [Medication], from date: Date) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        var alerts: [String] = []
        for med in medications {
            guard let refillStr = med.refillDate,
                  let refillDate = formatter.date(from: refillStr) else { continue }
            let days = calendar.dateComponents([.day], from: date, to: refillDate).day ?? 0
            if days <= 7 {
                alerts.append("\(med.name) — refill in \(max(0, days)) day(s)")
            }
        }
        return alerts
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func timeString(_ date: Date, timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = timeZone
        return f.string(from: date)
    }
}

// MARK: - DTOs

private struct CheckInLog: Codable {
    let memberId: String
    let date: String
    let time: String
    let type: String
}
