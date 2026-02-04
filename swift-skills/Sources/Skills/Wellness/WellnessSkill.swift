import Foundation
import HomeOSCore

public struct WellnessSkill: SkillProtocol {
    public let name = "wellness"
    public let description = "Track hydration, steps, sleep, and screen time with adaptive nudges"
    public let triggerKeywords = [
        "water", "hydration", "drink", "steps", "walk", "sleep", "screen time",
        "wellness", "health check", "how am I doing", "fitness", "exercise",
        "tired", "energy", "mood"
    ]

    // MARK: - Wellness Goals
    private static let hydrationGoalOz: Double = 64.0
    private static let stepsGoal: Int = 8000
    private static let sleepGoalHours: Double = 8.0
    private static let kidsScreenTimeLimitMin: Int = 120 // 2 hours

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let message = intent.rawMessage.lowercased()
        let matches = triggerKeywords.filter { message.contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("water") || message.contains("hydration") || message.contains("drink") {
            return try await handleHydration(context: context)
        } else if message.contains("step") || message.contains("walk") || message.contains("exercise") {
            return try await handleSteps(context: context)
        } else if message.contains("sleep") || message.contains("tired") {
            return try await handleSleep(context: context)
        } else if message.contains("screen") {
            return try await handleScreenTime(context: context)
        } else {
            return try await wellnessDashboard(context: context)
        }
    }

    // MARK: - Dashboard

    private func wellnessDashboard(context: SkillContext) async throws -> SkillResult {
        let today = dateString(context.currentDate)
        let hour = currentHour(date: context.currentDate, timeZone: context.timeZone)

        var response = "🌿 WELLNESS DASHBOARD\n"
        response += "📅 \(today) • \(timeOfDayGreeting(hour: hour))\n\n"

        for member in context.family.members {
            let log = try? await context.storage.read(
                path: "data/wellness/\(member.id)/\(today).json",
                type: WellnessLog.self
            )

            response += "👤 \(member.name)\n"

            let hydration = log?.hydrationOz ?? 0
            let hydPct = min(100, Int((hydration / Self.hydrationGoalOz) * 100))
            response += "  💧 Water: \(Int(hydration))oz / \(Int(Self.hydrationGoalOz))oz (\(hydPct)%)\n"

            let steps = log?.steps ?? 0
            let stepPct = min(100, Int((Double(steps) / Double(Self.stepsGoal)) * 100))
            response += "  👟 Steps: \(steps) / \(Self.stepsGoal) (\(stepPct)%)\n"

            let sleep = log?.sleepHours ?? 0
            response += "  😴 Sleep: \(String(format: "%.1f", sleep))h / \(String(format: "%.0f", Self.sleepGoalHours))h\n"

            if member.role == .child {
                let screen = log?.screenTimeMinutes ?? 0
                let remaining = max(0, Self.kidsScreenTimeLimitMin - screen)
                response += "  📱 Screen: \(screen)min / \(Self.kidsScreenTimeLimitMin)min (\(remaining)min left)\n"
            }

            if let mood = log?.mood {
                let moodEmoji = moodToEmoji(mood)
                response += "  \(moodEmoji) Mood: \(mood)/10\n"
            }
            response += "\n"
        }

        // Time-adaptive nudge
        let nudge = generateTimeAdaptiveNudge(hour: hour, context: context)
        if let nudge = nudge {
            response += "💡 \(nudge)\n"
        }

        return .response(response)
    }

    // MARK: - Hydration

    private func handleHydration(context: SkillContext) async throws -> SkillResult {
        let today = dateString(context.currentDate)
        let hour = currentHour(date: context.currentDate, timeZone: context.timeZone)

        // Check if logging water
        let amounts = context.intent.entities.amounts
        if let oz = amounts.first {
            return try await logHydration(oz: oz, context: context, today: today)
        }

        // Otherwise show status with nudge
        var response = "💧 HYDRATION STATUS\n\n"

        for member in context.family.members {
            let log = try? await context.storage.read(
                path: "data/wellness/\(member.id)/\(today).json",
                type: WellnessLog.self
            )
            let current = log?.hydrationOz ?? 0
            let remaining = max(0, Self.hydrationGoalOz - current)
            let pct = min(100, Int((current / Self.hydrationGoalOz) * 100))
            let bar = progressBar(percent: pct)

            response += "👤 \(member.name): \(Int(current))oz / \(Int(Self.hydrationGoalOz))oz\n"
            response += "   \(bar) \(pct)%\n"
            if remaining > 0 {
                let hoursLeft = max(1, 22 - hour)
                let perHour = remaining / Double(hoursLeft)
                response += "   Aim for ~\(Int(perHour))oz per hour to hit your goal\n"
            } else {
                response += "   🎉 Goal reached!\n"
            }
            response += "\n"
        }

        return .response(response)
    }

    private func logHydration(oz: Double, context: SkillContext, today: String) async throws -> SkillResult {
        let memberId = context.family.members.first?.id ?? "default"
        let memberName = context.family.members.first?.name ?? "You"

        var log = (try? await context.storage.read(
            path: "data/wellness/\(memberId)/\(today).json",
            type: WellnessLog.self
        )) ?? WellnessLog(memberId: memberId, date: today)

        let previous = log.hydrationOz ?? 0
        log.hydrationOz = previous + oz
        try await context.storage.write(
            path: "data/wellness/\(memberId)/\(today).json", value: log
        )

        let total = log.hydrationOz ?? 0
        let pct = min(100, Int((total / Self.hydrationGoalOz) * 100))

        var response = "💧 Logged \(Int(oz))oz for \(memberName)\n"
        response += "   Total today: \(Int(total))oz / \(Int(Self.hydrationGoalOz))oz (\(pct)%)\n"
        if total >= Self.hydrationGoalOz {
            response += "   🎉 You've hit your hydration goal! Keep sipping!"
        }
        return .response(response)
    }

    // MARK: - Steps

    private func handleSteps(context: SkillContext) async throws -> SkillResult {
        let today = dateString(context.currentDate)
        let hour = currentHour(date: context.currentDate, timeZone: context.timeZone)

        var response = "👟 STEP TRACKER\n\n"

        for member in context.family.members {
            let log = try? await context.storage.read(
                path: "data/wellness/\(member.id)/\(today).json",
                type: WellnessLog.self
            )
            let steps = log?.steps ?? 0
            let pct = min(100, Int((Double(steps) / Double(Self.stepsGoal)) * 100))
            let remaining = max(0, Self.stepsGoal - steps)

            response += "👤 \(member.name): \(steps) / \(Self.stepsGoal) steps\n"
            response += "   \(progressBar(percent: pct)) \(pct)%\n"

            if remaining > 0 && hour < 21 {
                let minsWalking = remaining / 100 // ~100 steps per minute
                response += "   💡 A \(minsWalking)-minute walk would get you there!\n"
            } else if remaining == 0 {
                response += "   🎉 Goal smashed!\n"
            }
            response += "\n"
        }

        return .response(response)
    }

    // MARK: - Sleep

    private func handleSleep(context: SkillContext) async throws -> SkillResult {
        let today = dateString(context.currentDate)
        let hour = currentHour(date: context.currentDate, timeZone: context.timeZone)

        var response = "😴 SLEEP TRACKER\n\n"

        for member in context.family.members {
            let log = try? await context.storage.read(
                path: "data/wellness/\(member.id)/\(today).json",
                type: WellnessLog.self
            )
            let sleep = log?.sleepHours ?? 0
            let goal = member.role == .child ? 10.0 : Self.sleepGoalHours
            let pct = min(100, Int((sleep / goal) * 100))

            response += "👤 \(member.name): \(String(format: "%.1f", sleep))h / \(String(format: "%.0f", goal))h\n"
            response += "   \(progressBar(percent: pct)) \(pct)%\n"

            if sleep < goal - 1.0 {
                response += "   ⚠️ Below target — prioritize rest tonight\n"
            } else if sleep >= goal {
                response += "   ✅ Well rested!\n"
            }
            response += "\n"
        }

        // Evening nudge for bedtime
        if hour >= 20 {
            response += "🌙 It's getting late! Time to wind down:\n"
            response += "  • Dim the lights\n"
            response += "  • Put screens away\n"
            response += "  • Try some light reading or stretching\n"
        }

        return .response(response)
    }

    // MARK: - Screen Time (Kids)

    private func handleScreenTime(context: SkillContext) async throws -> SkillResult {
        let today = dateString(context.currentDate)
        let children = context.family.children

        if children.isEmpty {
            return .response("No children registered in the family. Screen time tracking is primarily for kids.")
        }

        var response = "📱 SCREEN TIME — Kids\n\n"

        for child in children {
            let log = try? await context.storage.read(
                path: "data/wellness/\(child.id)/\(today).json",
                type: WellnessLog.self
            )
            let screen = log?.screenTimeMinutes ?? 0
            let limit = Self.kidsScreenTimeLimitMin
            let remaining = max(0, limit - screen)
            let pct = min(100, Int((Double(screen) / Double(limit)) * 100))

            response += "👤 \(child.name)"
            if let age = child.age { response += " (age \(age))" }
            response += "\n"
            response += "   Used: \(screen) min / \(limit) min\n"
            response += "   \(progressBar(percent: pct)) \(pct)%\n"

            if remaining == 0 {
                response += "   🛑 Screen time limit reached!\n"
            } else if remaining <= 30 {
                response += "   ⚠️ Only \(remaining) minutes left\n"
            } else {
                response += "   ✅ \(remaining) minutes remaining\n"
            }
            response += "\n"
        }

        response += "💡 Tip: Swap screen time for outdoor play, reading, or board games!"
        return .response(response)
    }

    // MARK: - Time-Adaptive Nudges

    private func generateTimeAdaptiveNudge(hour: Int, context: SkillContext) -> String? {
        switch hour {
        case 6...8:
            return "🌅 Good morning! Start with a glass of water to kickstart hydration."
        case 9...11:
            return "☀️ Mid-morning check: Have you had 16oz of water yet? A short walk boosts focus!"
        case 12...13:
            return "🍽 Lunchtime! Drink water with your meal. A post-lunch walk aids digestion."
        case 14...16:
            return "☕ Afternoon slump? Try water before coffee — dehydration often mimics fatigue."
        case 17...18:
            return "🌆 Evening approaching! Check your step count — there's still time for a walk."
        case 19...20:
            return "🍽 After dinner is a great time for a family walk. Wind down screens soon."
        case 21...22:
            return "🌙 Time to wind down. Dim lights, put screens away, and prepare for quality sleep."
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func currentHour(date: Date, timeZone: TimeZone) -> Int {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    private func timeOfDayGreeting(hour: Int) -> String {
        switch hour {
        case 5...11: return "Good morning ☀️"
        case 12...16: return "Good afternoon 🌤"
        case 17...20: return "Good evening 🌆"
        default: return "Night owl? 🦉"
        }
    }

    private func progressBar(percent: Int) -> String {
        let filled = percent / 10
        let empty = 10 - filled
        return "[" + String(repeating: "█", count: filled) + String(repeating: "░", count: empty) + "]"
    }

    private func moodToEmoji(_ mood: Int) -> String {
        switch mood {
        case 1...3: return "😔"
        case 4...5: return "😐"
        case 6...7: return "🙂"
        case 8...9: return "😊"
        case 10: return "🤩"
        default: return "😐"
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
