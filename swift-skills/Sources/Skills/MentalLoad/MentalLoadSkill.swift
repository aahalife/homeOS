import Foundation
import HomeOSCore

public struct MentalLoadSkill: SkillProtocol {
    public let name = "mental-load"
    public let description = "Morning/evening briefings, weekly planning, and overwhelm support"
    public let triggerKeywords = ["briefing", "morning", "evening", "overwhelmed", "stressed", "weekly plan",
                                  "what's today", "what do i have", "too much", "can't cope", "plan my week",
                                  "summary", "rundown", "what's next"]

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        let base = min(Double(matches.count) * 0.3, 1.0)
        // Boost for urgency signals
        if intent.urgency == .urgent || intent.urgency == .emergency { return min(base + 0.2, 1.0) }
        return base
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("overwhelm") || message.contains("too much") || message.contains("stressed") || message.contains("can't cope") {
            return try await overwhelmSupport(context: context)
        } else if message.contains("week") || message.contains("plan my") {
            return try await weeklyPlanning(context: context)
        } else if isEvening(context: context) {
            return try await eveningBriefing(context: context)
        } else {
            return try await morningBriefing(context: context)
        }
    }

    // MARK: - Morning Briefing

    private func morningBriefing(context: SkillContext) async throws -> SkillResult {
        let todayStr = dateString(context.currentDate)
        let todayEvents = context.calendar.filter { $0.date == todayStr }.sorted { ($0.time ?? "") < ($1.time ?? "") }
        let tasks = try await loadTasks(context: context, date: todayStr)
        let overdue = tasks.filter { $0.status == .overdue || ($0.dueDate ?? "" < todayStr && $0.status == .pending) }
        let todayTasks = tasks.filter { $0.dueDate == todayStr && $0.status == .pending }

        // Deterministic priority sort: urgent > high > overdue > normal > low
        let sorted = (overdue + todayTasks).sorted { priorityScore($0) > priorityScore($1) }
        let top5 = Array(sorted.prefix(5))

        var response = "☀️ GOOD MORNING — \(formattedDate(context.currentDate))\n\n"

        // Events
        if todayEvents.isEmpty {
            response += "📅 No events today — open schedule!\n\n"
        } else {
            response += "📅 TODAY'S SCHEDULE\n"
            for event in todayEvents {
                let time = event.time ?? "All day"
                let dur = event.duration.map { " (\($0)min)" } ?? ""
                response += "  • \(time)\(dur) — \(event.title)\n"
                if let loc = event.location { response += "    📍 \(loc)\n" }
            }
            response += "\n"
        }

        // Priority tasks — PROPOSE, don't ask
        if !top5.isEmpty {
            response += "✅ HERE'S WHAT I'D TACKLE TODAY\n"
            for (i, task) in top5.enumerated() {
                let flag = task.status == .overdue ? " ⚠️ OVERDUE" : ""
                let pri = task.priority == .urgent ? " 🔴" : task.priority == .high ? " 🟠" : ""
                response += "  \(i + 1). \(task.title)\(pri)\(flag)\n"
            }
            let remaining = sorted.count - top5.count
            if remaining > 0 { response += "  (+\(remaining) more tasks)\n" }
            response += "\n"
        }

        // Medication reminders
        let meds = morningMedications(family: context.family)
        if !meds.isEmpty {
            response += "💊 MEDICATION REMINDERS\n"
            for (name, med) in meds {
                response += "  • \(name): \(med.name) \(med.dosage)\n"
            }
            response += "\n"
        }

        response += "Ready to adjust priorities or need more detail on anything?"
        return .response(response)
    }

    // MARK: - Evening Briefing

    private func eveningBriefing(context: SkillContext) async throws -> SkillResult {
        let todayStr = dateString(context.currentDate)
        let tomorrowStr = dateString(Calendar.current.date(byAdding: .day, value: 1, to: context.currentDate)!)
        let tomorrowEvents = context.calendar.filter { $0.date == tomorrowStr }.sorted { ($0.time ?? "") < ($1.time ?? "") }
        let tasks = try await loadTasks(context: context, date: todayStr)
        let completed = tasks.filter { $0.status == .completed && $0.completedAt?.hasPrefix(todayStr) == true }
        let stillPending = tasks.filter { $0.dueDate == todayStr && $0.status == .pending }

        var response = "🌙 EVENING WRAP-UP — \(formattedDate(context.currentDate))\n\n"

        // Today's wins
        if !completed.isEmpty {
            response += "🏆 COMPLETED TODAY (\(completed.count))\n"
            for task in completed.prefix(5) {
                response += "  ✓ \(task.title)\n"
            }
            response += "\n"
        }

        // Unfinished — no guilt, just facts
        if !stillPending.isEmpty {
            response += "📋 ROLLING TO TOMORROW (\(stillPending.count))\n"
            for task in stillPending.prefix(3) {
                response += "  → \(task.title)\n"
            }
            response += "\n"
        }

        // Tomorrow preview
        if !tomorrowEvents.isEmpty {
            response += "📅 TOMORROW'S SCHEDULE\n"
            for event in tomorrowEvents.prefix(5) {
                response += "  • \(event.time ?? "TBD") — \(event.title)\n"
            }
            let firstTime = tomorrowEvents.first?.time ?? "morning"
            response += "\n⏰ First event: \(firstTime)\n\n"
        } else {
            response += "📅 Tomorrow looks clear!\n\n"
        }

        response += "Rest well. Tomorrow's handled."
        return .response(response)
    }

    // MARK: - Weekly Planning

    private func weeklyPlanning(context: SkillContext) async throws -> SkillResult {
        var response = "📋 WEEKLY PLAN PROPOSAL\n\n"

        let allTasks = try await loadTasks(context: context, date: nil)
        let pending = allTasks.filter { $0.status == .pending || $0.status == .overdue }
            .sorted { priorityScore($0) > priorityScore($1) }

        // Spread tasks across the week — propose, don't ask
        let days = (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: context.currentDate)! }
        for (dayIdx, day) in days.enumerated() {
            let dayStr = dateString(day)
            let dayEvents = context.calendar.filter { $0.date == dayStr }
            let dayLabel = dayIdx == 0 ? "Today" : dayIdx == 1 ? "Tomorrow" : weekdayName(day)
            let busyHours = dayEvents.reduce(0) { $0 + ($1.duration ?? 60) } / 60
            let capacity = max(0, 3 - busyHours) // rough task capacity

            response += "📆 \(dayLabel) (\(formattedShortDate(day)))\n"
            if !dayEvents.isEmpty {
                for event in dayEvents.prefix(3) {
                    response += "  📅 \(event.time ?? "—") \(event.title)\n"
                }
            }

            let dayTasks = Array(pending.filter { $0.dueDate == dayStr || ($0.dueDate == nil && dayIdx < 3) }.prefix(capacity))
            for task in dayTasks {
                response += "  ☐ \(task.title)\n"
            }
            response += "\n"
        }

        response += "I've spread tasks based on your calendar density. Want to adjust anything?"
        return .response(response)
    }

    // MARK: - Overwhelm Support

    private func overwhelmSupport(context: SkillContext) async throws -> SkillResult {
        let todayStr = dateString(context.currentDate)
        let tasks = try await loadTasks(context: context, date: todayStr)
        let pending = tasks.filter { $0.status == .pending || $0.status == .overdue }
            .sorted { priorityScore($0) > priorityScore($1) }

        var response = "🫂 I hear you. Let's simplify.\n\n"
        response += "You have \(pending.count) things on your plate. Here's what actually matters today:\n\n"

        // Only show top 3 — reduce cognitive load
        let mustDo = Array(pending.prefix(3))
        response += "🔴 MUST DO (just these 3)\n"
        for (i, task) in mustDo.enumerated() {
            response += "  \(i + 1). \(task.title)\n"
        }

        let canWait = pending.count - mustDo.count
        if canWait > 0 {
            response += "\n🟡 CAN WAIT (\(canWait) tasks)\n"
            response += "  I'll reschedule these to later this week.\n"
        }

        response += "\n💡 START WITH #1. Just that one thing.\n"
        response += "Everything else can wait. You've got this.\n"
        response += "\nWant me to reschedule the rest, or delegate anything?"
        return .response(response)
    }

    // MARK: - Helpers

    private func isEvening(context: SkillContext) -> Bool {
        let hour = Calendar.current.component(.hour, from: context.currentDate)
        return hour >= 17
    }

    private func priorityScore(_ task: HomeTask) -> Int {
        var score = 0
        switch task.priority {
        case .urgent: score += 100
        case .high: score += 75
        case .normal: score += 50
        case .low: score += 25
        }
        if task.status == .overdue { score += 50 }
        if task.type == .medication { score += 30 }
        if task.type == .appointment { score += 20 }
        return score
    }

    private func loadTasks(context: SkillContext, date: String?) async throws -> [HomeTask] {
        (try? await context.storage.read(path: "data/tasks.json", type: [HomeTask].self)) ?? []
    }

    private func morningMedications(family: Family) -> [(String, Medication)] {
        family.members.flatMap { member in
            (member.medications ?? []).filter { med in
                med.times.contains(where: { $0 <= "10:00" && $0 >= "06:00" })
            }.map { (member.name, $0) }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date)
    }

    private func weekdayName(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: date)
    }
}
