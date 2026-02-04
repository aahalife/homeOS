import Foundation
import HomeOSCore

public struct PsyRichSkill: SkillProtocol {
    public let name = "psy-rich"
    public let description = "Suggest psychologically rich experiences for personal growth"
    public let triggerKeywords = ["experience", "enrich", "meaningful", "bored", "rut", "interesting", "something new", "explore"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        
        if message.contains("quick") || message.contains("right now") || message.contains("15 min") {
            return quickSuggestions(context: context)
        } else {
            return try await fullSuggestions(context: context)
        }
    }
    
    // MARK: - Quick (HARDCODED — no LLM needed)
    
    private func quickSuggestions(context: SkillContext) -> SkillResult {
        let hour = Calendar.current.component(.hour, from: context.currentDate)
        
        let suggestions: [String]
        if hour < 12 {
            suggestions = [
                "🌅 Go outside and watch the sky for 5 minutes",
                "📚 Read a Wikipedia random article — learn something new",
                "🎵 Listen to a song in a language you don't speak"
            ]
        } else if hour < 17 {
            suggestions = [
                "🚶 Walk a route you've never taken (15 min)",
                "✏️ Sketch something near you — badly, on purpose (10 min)",
                "📞 Call someone you haven't talked to in months"
            ]
        } else {
            suggestions = [
                "🌅 Watch the sky change colors at dusk",
                "🎵 Listen to a full album with eyes closed",
                "☕ Make tea and sit in intentional silence for 5 minutes"
            ]
        }
        
        var response = "⏱️ QUICK RICHNESS\n\n"
        for s in suggestions { response += "• \(s)\n" }
        response += "\nWhich feels right?"
        return .response(response)
    }
    
    // MARK: - Full Suggestions (LLM-assisted)
    
    private func fullSuggestions(context: SkillContext) async throws -> SkillResult {
        let prompt = """
        Suggest 4 psychologically rich experiences, one for each category:
        1. Novel (unfamiliar, new)
        2. Perspective-shifting (changes worldview)
        3. Complex (intellectually engaging)
        4. Aesthetic (beauty and wonder)
        
        User context: "\(context.intent.rawMessage)"
        Each must be CONCRETE: specific activity, estimated duration, cost, what makes it enriching.
        """
        
        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "experiences": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "category": {"type": "string"},
                            "emoji": {"type": "string"},
                            "name": {"type": "string"},
                            "duration": {"type": "string"},
                            "cost": {"type": "string"},
                            "whyEnriching": {"type": "string"}
                        },
                        "required": ["category", "name", "duration", "cost", "whyEnriching"]
                    }
                }
            },
            "required": ["experiences"]
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        guard let data = json.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let experiences = result["experiences"] as? [[String: Any]] else {
            return quickSuggestions(context: context) // Fallback to hardcoded
        }
        
        var response = "🌟 EXPERIENCES FOR YOU\n\n"
        for exp in experiences {
            let emoji = exp["emoji"] as? String ?? "✨"
            response += "\(emoji) \(exp["category"] as? String ?? "")\n"
            response += "  \(exp["name"] as? String ?? "")\n"
            response += "  ⏱️ \(exp["duration"] ?? "") • 💰 \(exp["cost"] ?? "")\n"
            response += "  ✨ \(exp["whyEnriching"] as? String ?? "")\n\n"
        }
        response += "Which resonates? I can help plan it!"
        return .response(response)
    }
}
