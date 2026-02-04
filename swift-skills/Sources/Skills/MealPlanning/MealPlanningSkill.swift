import Foundation
import HomeOSCore

public struct MealPlanningSkill: SkillProtocol {
    public let name = "meal-planning"
    public let description = "Create weekly meal plans with grocery lists and prep schedules"
    public let triggerKeywords = ["dinner", "meal plan", "grocery", "recipe", "cook", "eat", "lunch", "what to eat", "meal prep", "shopping list", "pantry"]
    
    public init() {}
    
    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        return min(Double(matches.count) * 0.3, 1.0)
    }
    
    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()
        
        // Determine sub-action
        if message.contains("grocery") || message.contains("shopping list") {
            return try await generateGroceryList(context: context)
        } else if message.contains("recipe") {
            return try await suggestRecipe(context: context)
        } else if message.contains("what") && (message.contains("dinner") || message.contains("eat") || message.contains("cook")) {
            return try await suggestDinner(context: context)
        } else {
            return try await generateMealPlan(context: context)
        }
    }
    
    // MARK: - Suggest Tonight's Dinner
    
    private func suggestDinner(context: SkillContext) async throws -> SkillResult {
        let dietary = collectDietaryRestrictions(family: context.family)
        let allergies = collectAllergies(family: context.family)
        let memberCount = context.family.members.count
        
        // Check recent meals to avoid repeats
        let recentMeals = try? await context.storage.read(path: "data/meal_history.json", type: [MealRecord].self)
        let last3 = (recentMeals ?? []).suffix(3).map { $0.name }
        
        let prompt = """
        Suggest ONE dinner for tonight.
        Family size: \(memberCount)
        Dietary restrictions: \(dietary.isEmpty ? "none" : dietary.joined(separator: ", "))
        Allergies (MUST AVOID): \(allergies.isEmpty ? "none" : allergies.joined(separator: ", "))
        Recent meals to avoid repeating: \(last3.isEmpty ? "none" : last3.joined(separator: ", "))
        Weeknight = quick (under 30 min preferred).
        
        Respond with JSON:
        """
        
        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "name": { "type": "string" },
                "cuisine": { "type": "string" },
                "prepMinutes": { "type": "integer" },
                "description": { "type": "string" },
                "keyIngredients": { "type": "array", "items": { "type": "string" } }
            },
            "required": ["name", "cuisine", "prepMinutes", "description", "keyIngredients"],
            "additionalProperties": false
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        
        // Parse and format response
        guard let data = json.data(using: .utf8),
              let meal = try? JSONDecoder().decode(DinnerSuggestion.self, from: data) else {
            return .response("🍽 I'd suggest something quick tonight — tacos, stir-fry, or pasta are always solid weeknight options. What sounds good?")
        }
        
        let response = """
        🍽 DINNER SUGGESTION
        
        \(meal.name)
        ⏱️ \(meal.prepMinutes) min • \(meal.cuisine)
        📝 \(meal.description)
        
        🛒 Key ingredients: \(meal.keyIngredients.joined(separator: ", "))
        
        \(dietary.isEmpty ? "" : "✅ Meets dietary needs: \(dietary.joined(separator: ", "))")
        \(allergies.isEmpty ? "" : "✅ Allergy-safe: avoids \(allergies.joined(separator: ", "))")
        
        Want the full recipe, or a different suggestion?
        """
        
        return .response(response)
    }
    
    // MARK: - Generate Weekly Meal Plan
    
    private func generateMealPlan(context: SkillContext) async throws -> SkillResult {
        let dietary = collectDietaryRestrictions(family: context.family)
        let allergies = collectAllergies(family: context.family)
        let memberCount = context.family.members.count
        let hasKids = context.family.children.count > 0
        
        let prompt = """
        Create a 7-day dinner meal plan.
        Family: \(memberCount) people\(hasKids ? " (includes children)" : "")
        Dietary: \(dietary.isEmpty ? "none" : dietary.joined(separator: ", "))
        Allergies (MUST AVOID): \(allergies.isEmpty ? "none" : allergies.joined(separator: ", "))
        Rules:
        - Weeknights (Mon-Thu): under 30 min
        - Weekend (Fri-Sun): can be longer
        - Variety: different proteins and cuisines each day
        - Max 2 chicken dishes per week
        - Include 1 meatless day
        \(hasKids ? "- Include kid-friendly options" : "")
        
        Return JSON array of 7 meals.
        """
        
        let schema = JSONSchema("""
        {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "day": { "type": "string" },
                    "name": { "type": "string" },
                    "cuisine": { "type": "string" },
                    "prepMinutes": { "type": "integer" },
                    "description": { "type": "string" }
                },
                "required": ["day", "name", "cuisine", "prepMinutes", "description"]
            }
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        
        guard let data = json.data(using: .utf8),
              let meals = try? JSONDecoder().decode([MealPlanDay].self, from: data),
              !meals.isEmpty else {
            return .response("I had trouble generating a meal plan. Can you tell me more about your preferences — cuisines you like, time available for cooking, any restrictions?")
        }
        
        var response = "📅 WEEKLY MEAL PLAN\n\n"
        response += "👥 \(memberCount) people"
        if !dietary.isEmpty { response += " • \(dietary.joined(separator: ", "))" }
        response += "\n\n"
        
        for meal in meals {
            response += "• \(meal.day): \(meal.name)\n"
            response += "  ⏱️ \(meal.prepMinutes) min • \(meal.cuisine)\n"
            response += "  📝 \(meal.description)\n\n"
        }
        
        response += "Want the grocery list for this plan, or swap any meals?"
        
        // Save the plan
        let dateStr = ISO8601DateFormatter().string(from: context.currentDate)
        try? await context.storage.write(path: "data/current_meal_plan.json", value: meals)
        
        return .response(response)
    }
    
    // MARK: - Generate Grocery List
    
    private func generateGroceryList(context: SkillContext) async throws -> SkillResult {
        // Try to load current meal plan
        guard let meals = try? await context.storage.read(path: "data/current_meal_plan.json", type: [MealPlanDay].self),
              !meals.isEmpty else {
            return .response("I don't have a meal plan saved yet. Want me to create one first, then generate the grocery list?")
        }
        
        let mealList = meals.map { "\($0.day): \($0.name)" }.joined(separator: "\n")
        
        let prompt = """
        Generate a grocery list for these meals:
        \(mealList)
        
        Group by store section. Include quantities.
        Return JSON.
        """
        
        let schema = JSONSchema("""
        {
            "type": "object",
            "properties": {
                "sections": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "section": { "type": "string" },
                            "items": {
                                "type": "array",
                                "items": {
                                    "type": "object",
                                    "properties": {
                                        "name": { "type": "string" },
                                        "quantity": { "type": "string" }
                                    },
                                    "required": ["name", "quantity"]
                                }
                            }
                        },
                        "required": ["section", "items"]
                    }
                }
            },
            "required": ["sections"]
        }
        """)
        
        let json = try await context.llm.generateJSON(prompt: prompt, schema: schema)
        
        guard let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode(GroceryList.self, from: data) else {
            return .response("I had trouble generating the list. Here are the meals I'm working with:\n\(mealList)\n\nWant me to try again?")
        }
        
        var response = "🛒 GROCERY LIST\n\n"
        for section in list.sections {
            response += "📌 \(section.section.uppercased())\n"
            for item in section.items {
                response += "  ☐ \(item.name) — \(item.quantity)\n"
            }
            response += "\n"
        }
        
        response += "Total items: \(list.sections.flatMap(\.items).count)"
        
        return .response(response)
    }
    
    // MARK: - Suggest Recipe
    
    private func suggestRecipe(context: SkillContext) async throws -> SkillResult {
        let dietary = collectDietaryRestrictions(family: context.family)
        let allergies = collectAllergies(family: context.family)
        
        let prompt = """
        Provide a detailed recipe based on: "\(context.intent.rawMessage)"
        Dietary: \(dietary.isEmpty ? "none" : dietary.joined(separator: ", "))
        Allergies (MUST AVOID): \(allergies.isEmpty ? "none" : allergies.joined(separator: ", "))
        
        Include: title, servings, prep time, cook time, ingredients with amounts, numbered steps, tips.
        """
        
        let response = try await context.llm.generate(prompt: prompt)
        return .response("📝 " + response)
    }
    
    // MARK: - Helpers
    
    /// Collect ALL dietary restrictions across family (hard constraints)
    private func collectDietaryRestrictions(family: Family) -> [String] {
        var restrictions: Set<String> = []
        for member in family.members {
            if let dietary = member.preferences?.dietary {
                restrictions.formUnion(dietary)
            }
        }
        return Array(restrictions).sorted()
    }
    
    /// Collect ALL allergies across family (CRITICAL safety constraint)
    private func collectAllergies(family: Family) -> [String] {
        var allAllergies: Set<String> = []
        for member in family.members {
            if let allergies = member.allergies {
                allAllergies.formUnion(allergies)
            }
        }
        return Array(allAllergies).sorted()
    }
}

// MARK: - DTOs

private struct DinnerSuggestion: Codable {
    let name: String
    let cuisine: String
    let prepMinutes: Int
    let description: String
    let keyIngredients: [String]
}

private struct MealPlanDay: Codable {
    let day: String
    let name: String
    let cuisine: String
    let prepMinutes: Int
    let description: String
}

private struct MealRecord: Codable {
    let name: String
    let date: String
}

private struct GroceryList: Codable {
    let sections: [GrocerySection]
}

private struct GrocerySection: Codable {
    let section: String
    let items: [GroceryItem]
}

private struct GroceryItem: Codable {
    let name: String
    let quantity: String
}
