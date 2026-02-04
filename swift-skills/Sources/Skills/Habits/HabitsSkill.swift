import Foundation
import HomeOSCore

public struct HabitsSkill: SkillProtocol {
    public let name = "habits"
    public let description = "Track and nurture habits through behavioral science"
    public let triggerKeywords = ["habit", "streak", "motivation", "consistency", "routine", "daily practice"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        
        if message.contains("done") || message.contains("did it") || message.contains("completed") {
            return try await logCompletion(context: context)
        } else if message.contains("missed") || message.contains("skip") || message.contains("fail") {
            return try await handleMiss(context: context)
        } else if message.contains("start") || message.contains("new habit") || message.contains("build") {
            return try await createHabit(context: context)
        } else if message.contains("how") || message.contains("progress") || message.contains("streak") {
            return try await showProgress(context: context)
        } else {
            return try await dailyCheckIn(context: context)
        }
    }
    
    // MARK: - Create Habit
    
    private func createHabit(context: SkillContext) async throws -> SkillResult {
        // Detect stage from language (DETERMINISTIC)
        let message = context.intent.rawMessage.lowercased()
        let stage: HabitStage
        if message.contains("thinking") || message.contains("maybe") || message.contains("should i") {
            stage = .contemplation
        } else if message.contains("going to") || message.contains("want to start") || message.contains("plan to") {
            stage = .preparation
        } else if message.contains("started") || message.contains("doing") || message.contains("trying") {
            stage = .action
        } else {
            stage = .preparation
        }
        
        let prompt = """
        User wants to build a habit: "\(context.intent.rawMessage)"
        Create an atomic version (2-minute rule). Be specific.
        """
        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "atomicVersion": {"type": "string"},
                "suggestedCue": {"type": "string"},
                "reward": {"type": "string"}
            },
            "required": ["name", "atomicVersion", "suggestedCue", "reward"]
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return .response("🎯 Let's set up your habit! What specifically do you want to do? I'll make it atomic (so small you can't say no).")
        }
        
        let response = """
        ⚛️ ATOMIC HABIT SETUP
        
        🎯 Your habit: \(result["name"] ?? "")
        ✨ Atomic version: "\(result["atomicVersion"] ?? "")"
        
        📋 THE FORMULA:
          After I \(result["suggestedCue"] ?? "[existing habit]"),
          I will \(result["atomicVersion"] ?? "[your habit]").
          Then I \(result["reward"] ?? "celebrate with a fist pump").
        
        🔒 THE DEAL:
        • Even on bad days: just the atomic version
        • More is optional. The minimum is mandatory.
        • Never miss twice in a row.
        
        ⏰ I'll check in tomorrow. Day 1 starts now!
        
        Want to activate this habit?
        """
        
        return .response(response)
    }
    
    // MARK: - Log Completion
    
    private func logCompletion(context: SkillContext) async throws -> SkillResult {
        var habits = (try? await context.storage.read(path: "data/habits/active_habits.json", type: [Habit].self)) ?? []
        
        guard !habits.isEmpty else {
            return .response("You don't have any active habits yet. Want to start one?")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        
        // Update first incomplete habit (or match by name if mentioned)
        if let idx = habits.firstIndex(where: { !$0.completionLog.contains(today) }) {
            habits[idx].completionLog.append(today)
            habits[idx].currentStreak += 1
            if habits[idx].currentStreak > habits[idx].bestStreak {
                habits[idx].bestStreak = habits[idx].currentStreak
            }
            
            try? await context.storage.write(path: "data/habits/active_habits.json", value: habits)
            
            let streak = habits[idx].currentStreak
            let milestone = streakMilestone(streak)
            
            return .response("""
            🎉 \(habits[idx].name) ✅ Done!
            
            🔥 Streak: \(streak) days
            📊 Best streak: \(habits[idx].bestStreak) days
            \(milestone)
            
            Keep it going! Tomorrow is day \(streak + 1).
            """)
        }
        
        return .response("✅ All habits already logged today! You're crushing it.")
    }
    
    // MARK: - Handle Miss
    
    private func handleMiss(context: SkillContext) async throws -> SkillResult {
        var habits = (try? await context.storage.read(path: "data/habits/active_habits.json", type: [Habit].self)) ?? []
        
        guard let idx = habits.firstIndex(where: { $0.currentStreak > 0 }) else {
            return .response("No active streaks to miss. Want to start fresh?")
        }
        
        let oldStreak = habits[idx].currentStreak
        habits[idx].currentStreak = 0
        try? await context.storage.write(path: "data/habits/active_habits.json", value: habits)
        
        return .response("""
        💬 No worries. Missing one day is normal.
        
        📝 The facts:
        • You built a \(oldStreak)-day streak before
        • That PROVES you can do this
        • One miss doesn't erase progress
        
        ⚡ The rule: Never miss TWICE in a row.
        Tomorrow, just do the atomic version.
        
        What got in the way? (Knowing helps me help you)
        """)
    }
    
    // MARK: - Show Progress
    
    private func showProgress(context: SkillContext) async throws -> SkillResult {
        let habits = (try? await context.storage.read(path: "data/habits/active_habits.json", type: [Habit].self)) ?? []
        
        guard !habits.isEmpty else {
            return .response("📊 No active habits. Want to start one?")
        }
        
        var response = "📊 YOUR HABIT PORTFOLIO\n\n"
        
        for habit in habits {
            let stageEmoji: String
            switch habit.stage {
            case .contemplation: stageEmoji = "🤔"
            case .preparation: stageEmoji = "📋"
            case .action: stageEmoji = "💪"
            case .maintenance: stageEmoji = "✅"
            }
            
            response += "\(stageEmoji) \(habit.name)\n"
            response += "  Atomic: \"\(habit.atomicVersion)\"\n"
            response += "  🔥 Streak: \(habit.currentStreak) days (best: \(habit.bestStreak))\n"
            response += "  📊 Success rate: \(Int(habit.successRate))%\n\n"
        }
        
        response += "Active habits: \(habits.count) / recommended max: 3"
        return .response(response)
    }
    
    // MARK: - Daily Check-In
    
    private func dailyCheckIn(context: SkillContext) async throws -> SkillResult {
        let habits = (try? await context.storage.read(path: "data/habits/active_habits.json", type: [Habit].self)) ?? []
        
        guard !habits.isEmpty else {
            return .response("💬 No active habits. Tell me something you want to build into a habit and I'll help make it atomic!")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: context.currentDate)
        
        var response = "💬 HABIT CHECK-IN\n\n"
        for habit in habits {
            let done = habit.completionLog.contains(today)
            response += "🎯 \(habit.name)\n"
            response += "  \"\(habit.atomicVersion)\"\n"
            response += "  🔥 Streak: \(habit.currentStreak) days\n"
            response += "  \(done ? "✅ Done today!" : "☐ Not yet — did you do it?")\n\n"
        }
        response += "Say \"done\" or \"missed\" to update!"
        return .response(response)
    }
    
    // MARK: - Helpers
    
    private func streakMilestone(_ streak: Int) -> String {
        switch streak {
        case 7: return "\n🌟 1 WEEK! You proved you can start."
        case 21: return "\n🌟 3 WEEKS! Real momentum building."
        case 30: return "\n🌟 30 DAYS! This is becoming part of you."
        case 66: return "\n🌟 66 DAYS! Science says this is habit now."
        case 100: return "\n🌟 💯 100 DAYS! You're in rare company. Incredible."
        default: return ""
        }
    }
}
