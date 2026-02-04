import Foundation
import HomeOSCore

/// ChatTurn is the router — it classifies user intent and dispatches to the right skill.
/// For Gemma 3n, routing is primarily keyword-based with LLM fallback.
public final class ChatTurnRouter: Sendable {
    
    private let skills: [any SkillProtocol]
    
    public init(skills: [any SkillProtocol]) {
        self.skills = skills
    }
    
    /// Route a user message to the appropriate skill and execute it.
    public func handle(context: SkillContext) async throws -> SkillResult {
        // Step 1: Try keyword-based routing (fast, deterministic)
        let keywordMatch = matchByKeywords(intent: context.intent)
        
        if let skill = keywordMatch, skill.canHandle(intent: context.intent) > 0.5 {
            return try await skill.execute(context: context)
        }
        
        // Step 2: Score all skills and pick the best
        let scored = skills.map { skill in
            (skill: skill, score: skill.canHandle(intent: context.intent))
        }.sorted { $0.score > $1.score }
        
        if let best = scored.first, best.score > 0.3 {
            return try await best.skill.execute(context: context)
        }
        
        // Step 3: Fall back to LLM classification
        let categories = skills.map { skill in
            ClassificationCategory(
                name: skill.name,
                description: skill.description,
                examples: skill.triggerKeywords
            )
        }
        
        let classified = try await context.llm.classify(
            input: context.intent.rawMessage,
            categories: categories
        )
        
        if let matchedSkill = skills.first(where: { $0.name == classified }) {
            return try await matchedSkill.execute(context: context)
        }
        
        // Step 4: No skill matched — general response
        return .response("I'm not sure how to help with that. I can help with:\n" +
            skills.map { "• \($0.name): \($0.description)" }.joined(separator: "\n"))
    }
    
    // MARK: - Keyword Routing
    
    /// Priority-ordered keyword routing rules.
    /// These are checked FIRST before scoring, ensuring deterministic routing.
    private func matchByKeywords(intent: UserIntent) -> (any SkillProtocol)? {
        let message = intent.rawMessage.lowercased()
        let words = Set(intent.keywords)
        
        // Emergency detection — highest priority
        let emergencyKeywords: Set<String> = ["emergency", "911", "gas smell", "fire", "flood", "leak"]
        if !emergencyKeywords.intersection(Set(message.components(separatedBy: .whitespaces))).isEmpty {
            return findSkill("home-maintenance")
        }
        
        // Routing rules in priority order
        let rules: [(keywords: [String], contains: [String], skill: String)] = [
            // Health emergencies
            (["chest", "pain"], ["breathing", "allergic"], "healthcare"),
            
            // Elder care
            (["mom", "dad", "parent", "elderly", "grandma", "grandpa"], ["check in", "check on", "medication"], "elder-care"),
            
            // Healthcare
            (["doctor", "appointment", "medication", "prescription", "symptom", "sick", "refill"], [], "healthcare"),
            
            // Education
            (["homework", "grades", "assignment", "study", "test", "exam", "tutor"], [], "education"),
            
            // School orchestration
            (["school monitoring", "school setup", "weekly school", "all school"], [], "school"),
            
            // Meal planning
            (["dinner", "meal plan", "grocery", "recipe", "cook", "eat", "lunch"], [], "meal-planning"),
            
            // Restaurant
            (["restaurant", "reservation", "book a table", "dinner out", "dine out"], [], "restaurant-reservation"),
            
            // Home maintenance
            (["repair", "fix", "broken", "plumber", "electrician", "hvac", "maintenance", "leak"], [], "home-maintenance"),
            
            // Transportation
            (["uber", "lyft", "ride", "commute", "traffic", "carpool", "parking"], [], "transportation"),
            
            // Family comms
            (["announce", "chore", "check-in", "family message", "emergency contact"], [], "family-comms"),
            
            // Family bonding
            (["activity", "weekend", "outing", "date night", "what should we do", "bored"], [], "family-bonding"),
            
            // Mental load
            (["overwhelmed", "too much", "stressed", "briefing", "planning", "organize"], [], "mental-load"),
            
            // Habits
            (["habit", "streak", "motivation", "consistency"], [], "habits"),
            
            // Wellness
            (["hydration", "water", "steps", "sleep", "screen time", "posture", "wellness"], [], "wellness"),
            
            // Hire helper
            (["babysitter", "nanny", "housekeeper", "cleaner", "sitter", "tutor", "hire"], [], "hire-helper"),
            
            // Marketplace
            (["sell", "marketplace", "list for sale", "post for sale", "get rid of"], [], "marketplace-sell"),
            
            // Telephony
            (["call", "phone", "dial"], ["call the", "phone call"], "telephony"),
            
            // Note to actions
            (["article", "video", "podcast", "how do i apply", "turn into habit"], [], "note-to-actions"),
            
            // Psy rich
            (["experience", "enrich", "meaningful", "in a rut", "interesting"], [], "psy-rich"),
            
            // Tools (catch-all utilities)
            (["calendar", "reminder", "weather", "note", "search", "timer"], [], "tools"),
        ]
        
        for rule in rules {
            // Check if any keyword is in the message words
            let keywordMatch = rule.keywords.contains { keyword in
                words.contains(keyword) || message.contains(keyword)
            }
            // Check if any "contains" phrase is in the full message
            let containsMatch = rule.contains.isEmpty || rule.contains.contains { message.contains($0) }
            
            if keywordMatch && containsMatch {
                return findSkill(rule.skill)
            }
        }
        
        return nil
    }
    
    private func findSkill(_ name: String) -> (any SkillProtocol)? {
        skills.first { $0.name == name }
    }
}
