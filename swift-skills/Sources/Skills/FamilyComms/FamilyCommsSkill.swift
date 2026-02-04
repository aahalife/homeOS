import Foundation
import HomeOSCore

public struct FamilyCommsSkill: SkillProtocol {
    public let name = "family-comms"
    public let description = "Family announcements, calendar coordination, chore assignments, and check-ins"
    public let triggerKeywords = [
        "announce", "announcement", "tell everyone", "family meeting", "chore",
        "chores", "whose turn", "check in", "family calendar", "schedule",
        "coordinate", "who's doing", "assign", "rotate", "quiet hours"
    ]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let message = intent.rawMessage.lowercased()
        let matches = triggerKeywords.filter { message.contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("announce") || message.contains("tell everyone") || message.contains("family meeting") {
            return try await handleAnnouncement(context: context)
        } else if message.contains("chore") || message.contains("whose turn") || message.contains("assign")
            || message.contains("rotate") {
            return try await handleChores(context: context)
        } else if message.contains("calendar") || message.contains("schedule") || message.contains("coordinate") {
            return try await familyCalendar(context: context)
        } else if message.contains("check in") || message.contains("check-in") {
            return try await familyCheckIn(context: context)
        } else {
            return try await familyCalendar(context: context)
        }
    }

    // MARK: - Announcements (HIGH Risk — Requires Approval)

    private func handleAnnouncement(context: SkillContext) async throws -> SkillResult {
        // Check quiet hours before sending
        if isQuietHours(family: context.family, date: context.currentDate, timeZone: context.timeZone) {
            return .response(
                "🤫 It's currently quiet hours for some family members. "
                + "Would you like to schedule this announcement for later, "
                + "or mark it as urgent to send now?"
            )
        }

        let recipients = context.family.members.map { $0.name }
        let message = context.intent.rawMessage

        return .needsApproval(ApprovalRequest(
            description: "Send family announcement",
            details: [
                "Message: \(message)",
                "Recipients: \(recipients.joined(separator: ", "))",
                "Members: \(recipients.count)",
            ],
            riskLevel: .high,
            onDecision: { approved in
                if approved {
                    let log = AnnouncementLog(
                        date: ISO8601DateFormatter().string(from: context.currentDate),
                        message: message,
                        recipients: recipients,
                        status: "sent"
                    )
                    try? await context.storage.append(
                        path: "data/family-comms/announcements.json", item: log
                    )
                    return .response(
                        "📢 ANNOUNCEMENT SENT\n\n"
                        + "Delivered to: \(recipients.joined(separator: ", "))\n"
                        + "Message: \(message)"
                    )
                } else {
                    return .response("Announcement cancelled.")
                }
            }
        ))
    }

    // MARK: - Chore Management

    private func handleChores(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        // Load existing chore assignments
        let existingChores = (try? await context.storage.read(
            path: "data/family-comms/chore_rotation.json",
            type: [ChoreAssignment].self
        )) ?? []

        if message.contains("whose turn") || message.contains("who's doing") {
            return showChoreStatus(chores: existingChores, family: context.family)
        }

        // Determine eligible members (children + parents, fair distribution)
        let eligible = context.family.members.filter { member in
            guard let age = member.age else { return member.role == .parent }
            return age >= 6 // Kids 6+ can do age-appropriate chores
        }

        guard !eligible.isEmpty else {
            return .response("No eligible family members for chore assignment.")
        }

        // Calculate fair distribution — who has fewest recent chores
        let choreCounts = computeChoreCounts(
            chores: existingChores, members: eligible, date: context.currentDate
        )

        let defaultChores = [
            "dishes", "vacuuming", "laundry", "trash", "tidying up",
            "wiping counters", "setting table", "feeding pets",
        ]

        let prompt = """
        Assign chores fairly for today among these family members:
        \(eligible.map { "\($0.name) (age: \($0.age ?? 0), role: \($0.role.rawValue), recent chores: \(choreCounts[$0.id] ?? 0))" }.joined(separator: "\n"))
        
        Available chores: \(defaultChores.joined(separator: ", "))
        
        Rules:
        - Younger kids (6-10) get simpler tasks
        - Distribute fairly — those with fewer recent chores get more
        - Parents should do harder tasks
        - 2-3 chores per person max
        
        Return JSON array with objects: {"memberId": "...", "name": "...", "chores": ["..."]}
        """

        let schema = JSONSchema("""
        {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "memberId": { "type": "string" },
                    "name": { "type": "string" },
                    "chores": { "type": "array", "items": { "type": "string" } }
                },
                "required": ["memberId", "name", "chores"]
            }
        }
        """)

        let json: String
        do {
            json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        } catch {
            return .response(fairFallbackAssignment(eligible: eligible, chores: defaultChores))
        }

        guard let data = json.data(using: .utf8),
              let assignments = try? JSONDecoder().decode([ChoreDTO].self, from: data),
              !assignments.isEmpty
        else {
            return .response(fairFallbackAssignment(eligible: eligible, chores: defaultChores))
        }

        var response = "🧹 TODAY'S CHORE ASSIGNMENTS\n\n"
        let dateStr = dateString(context.currentDate)

        for assignment in assignments {
            response += "👤 \(assignment.name)\n"
            for chore in assignment.chores {
                response += "   ☐ \(chore)\n"
            }
            response += "\n"

            let record = ChoreAssignment(
                memberId: assignment.memberId,
                memberName: assignment.name,
                chore: assignment.chores.joined(separator: ", "),
                date: dateStr,
                completed: false
            )
            try? await context.storage.append(
                path: "data/family-comms/chore_rotation.json", item: record
            )
        }

        response += "Everyone pitch in! 💪 Mark chores done when finished."
        return .response(response)
    }

    // MARK: - Family Calendar Overview

    private func familyCalendar(context: SkillContext) async throws -> SkillResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        let weekEnd = formatter.string(
            from: Calendar.current.date(byAdding: .day, value: 7, to: context.currentDate)!
        )

        let upcoming = context.calendar
            .filter { $0.date >= today && $0.date <= weekEnd }
            .sorted { $0.date < $1.date }

        var response = "📅 FAMILY CALENDAR — This Week\n\n"

        if upcoming.isEmpty {
            response += "Nothing scheduled this week! A quiet stretch ahead.\n"
        } else {
            var lastDate = ""
            for event in upcoming {
                if event.date != lastDate {
                    response += "📆 \(event.date)\n"
                    lastDate = event.date
                }
                response += "  • \(event.title)"
                if let time = event.time { response += " at \(time)" }
                if let participants = event.participants, !participants.isEmpty {
                    let names = participants.compactMap { id in
                        context.family.member(id: id)?.name
                    }
                    if !names.isEmpty { response += " — \(names.joined(separator: ", "))" }
                }
                response += "\n"
            }
        }

        // Check for scheduling conflicts
        let conflicts = findConflicts(events: upcoming)
        if !conflicts.isEmpty {
            response += "\n⚠️ POTENTIAL CONFLICTS:\n"
            for conflict in conflicts {
                response += "  • \(conflict)\n"
            }
        }

        return .response(response)
    }

    // MARK: - Family Check-In

    private func familyCheckIn(context: SkillContext) async throws -> SkillResult {
        var response = "👨‍👩‍👧‍👦 FAMILY CHECK-IN\n\n"

        for member in context.family.members {
            response += "👤 \(member.name) (\(member.role.rawValue))\n"

            if let meds = member.medications, !meds.isEmpty {
                response += "   💊 Medications: \(meds.map { $0.name }.joined(separator: ", "))\n"
            }

            let memberEvents = context.calendar.filter {
                $0.participants?.contains(member.id) == true
            }.prefix(2)
            if !memberEvents.isEmpty {
                response += "   📅 Next: \(memberEvents.map { $0.title }.joined(separator: ", "))\n"
            }
            response += "\n"
        }

        response += "Everyone accounted for! Need to send a message to anyone?"
        return .response(response)
    }

    // MARK: - Quiet Hours

    private func isQuietHours(family: Family, date: Date, timeZone: TimeZone) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        let now = formatter.string(from: date)

        return family.members.contains { member in
            guard let quiet = member.quietHours else { return false }
            if quiet.start > quiet.end {
                // Overnight: e.g., 21:00 to 07:00
                return now >= quiet.start || now <= quiet.end
            } else {
                return now >= quiet.start && now <= quiet.end
            }
        }
    }

    // MARK: - Helpers

    private func computeChoreCounts(
        chores: [ChoreAssignment], members: [FamilyMember], date: Date
    ) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekAgo = formatter.string(
            from: Calendar.current.date(byAdding: .day, value: -7, to: date)!
        )
        var counts: [String: Int] = [:]
        for member in members { counts[member.id] = 0 }
        for chore in chores where chore.date >= weekAgo {
            counts[chore.memberId, default: 0] += 1
        }
        return counts
    }

    private func showChoreStatus(chores: [ChoreAssignment], family: Family) -> SkillResult {
        let today = dateString(Date())
        let todayChores = chores.filter { $0.date == today }

        if todayChores.isEmpty {
            return .response("No chores assigned for today. Want me to create a chore list?")
        }

        var response = "🧹 TODAY'S CHORES\n\n"
        for chore in todayChores {
            let status = chore.completed ? "✅" : "☐"
            response += "\(status) \(chore.memberName): \(chore.chore)\n"
        }
        return .response(response)
    }

    private func fairFallbackAssignment(eligible: [FamilyMember], chores: [String]) -> String {
        var response = "🧹 TODAY'S CHORE ASSIGNMENTS\n\n"
        var choreIndex = 0
        for member in eligible {
            let count = member.role == .parent ? 3 : 2
            response += "👤 \(member.name)\n"
            for _ in 0..<count {
                if choreIndex < chores.count {
                    response += "   ☐ \(chores[choreIndex])\n"
                    choreIndex += 1
                }
            }
            response += "\n"
        }
        return response
    }

    private func findConflicts(events: [CalendarEvent]) -> [String] {
        var conflicts: [String] = []
        let sorted = events.filter { $0.time != nil }.sorted { ($0.time ?? "") < ($1.time ?? "") }
        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                guard sorted[i].date == sorted[j].date,
                      let t1 = sorted[i].time, let t2 = sorted[j].time,
                      let dur = sorted[i].duration else { continue }
                let end1 = addMinutes(to: t1, minutes: dur)
                if end1 > t2 {
                    conflicts.append("\(sorted[i].title) overlaps with \(sorted[j].title) on \(sorted[i].date)")
                }
            }
        }
        return conflicts
    }

    private func addMinutes(to time: String, minutes: Int) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return time }
        let total = parts[0] * 60 + parts[1] + minutes
        return String(format: "%02d:%02d", (total / 60) % 24, total % 60)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - DTOs

private struct AnnouncementLog: Codable {
    let date: String
    let message: String
    let recipients: [String]
    let status: String
}

private struct ChoreAssignment: Codable {
    let memberId: String
    let memberName: String
    let chore: String
    let date: String
    let completed: Bool
}

private struct ChoreDTO: Codable {
    let memberId: String
    let name: String
    let chores: [String]
}
