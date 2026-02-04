import Foundation
import HomeOSCore

public struct NoteToActionsSkill: SkillProtocol {
    public let name = "note-to-actions"
    public let description = "Transform articles, videos, and ideas into atomic habits"
    public let triggerKeywords = ["article", "video", "podcast", "how do i apply", "turn into habit", "actionable", "implement this"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage
        
        // Extract insights and create atomic habits
        let prompt = """
        Analyze this content and extract 3 actionable habits:
        "\(message)"
        For each habit, apply the 4 Laws: make it Obvious (cue), Attractive (craving), Easy (2-min version), Satisfying (reward).
        """
        
        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "title": {"type": "string"},
                "summary": {"type": "string"},
                "habits": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": {"type": "string"},
                            "atomicVersion": {"type": "string"},
                            "cue": {"type": "string"},
                            "reward": {"type": "string"},
                            "difficulty": {"type": "string"}
                        },
                        "required": ["name", "atomicVersion", "cue", "reward", "difficulty"]
                    }
                },
                "recommendedFirst": {"type": "integer"}
            },
            "required": ["title", "summary", "habits", "recommendedFirst"]
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let habits = result["habits"] as? [[String: Any]] else {
            return .response("📝 Share an article link, video, or idea, and I'll extract actionable habits from it!")
        }
        
        var response = "📝 CONTENT ANALYZED\n\n"
        response += "📖 \(result["title"] ?? "")\n"
        response += "\(result["summary"] ?? "")\n\n"
        response += "━━━ ATOMIC HABITS ━━━\n\n"
        
        for (i, habit) in habits.enumerated() {
            response += "⚛️ \(i + 1). \(habit["name"] ?? "")\n"
            response += "  Do this: \"\(habit["atomicVersion"] ?? "")\"\n"
            response += "  When: \(habit["cue"] ?? "")\n"
            response += "  Reward: \(habit["reward"] ?? "")\n"
            response += "  Difficulty: \(habit["difficulty"] ?? "")\n\n"
        }
        
        let recommended = result["recommendedFirst"] as? Int ?? 0
        response += "🎯 START WITH: #\(recommended + 1) — easiest + highest impact.\n\n"
        response += "Want me to activate this habit with daily check-ins?"
        
        return .response(response)
    }
}
