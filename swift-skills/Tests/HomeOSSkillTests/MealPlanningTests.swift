import XCTest
@testable import HomeOSCore
@testable import HomeOSSkills

final class MealPlanningTests: XCTestCase {
    
    var storage: InMemoryStorage!
    var mockLLM: MockLLMBridge!
    var skill: MealPlanningSkill!
    
    override func setUp() async throws {
        storage = InMemoryStorage()
        mockLLM = MockLLMBridge()
        skill = MealPlanningSkill()
    }
    
    // MARK: - Routing Tests
    
    func testTriggersOnDinnerKeyword() {
        let intent = UserIntent(rawMessage: "What should we have for dinner?")
        XCTAssertGreaterThan(skill.canHandle(intent: intent), 0.0)
    }
    
    func testTriggersOnMealPlanKeyword() {
        let intent = UserIntent(rawMessage: "Create a meal plan for this week")
        XCTAssertGreaterThan(skill.canHandle(intent: intent), 0.0)
    }
    
    func testTriggersOnGroceryKeyword() {
        let intent = UserIntent(rawMessage: "Give me a grocery list")
        XCTAssertGreaterThan(skill.canHandle(intent: intent), 0.0)
    }
    
    func testDoesNotTriggerOnUnrelated() {
        let intent = UserIntent(rawMessage: "Book a doctor appointment")
        XCTAssertEqual(skill.canHandle(intent: intent), 0.0)
    }
    
    // MARK: - Dinner Suggestion Tests
    
    func testDinnerSuggestionRespectsAllergies() async throws {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Mom", role: .parent),
            FamilyMember(id: "2", name: "Kid", role: .child, age: 7, allergies: ["peanuts", "shellfish"])
        ])
        
        mockLLM.generateResponses["Suggest ONE dinner"] = """
        {
            "name": "Chicken Stir Fry",
            "cuisine": "Asian",
            "prepMinutes": 25,
            "description": "Quick chicken and veggie stir fry with rice",
            "keyIngredients": ["chicken breast", "broccoli", "soy sauce", "rice"]
        }
        """
        
        let context = SkillContext(
            family: family,
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What should we have for dinner tonight?")
        )
        
        let result = try await skill.execute(context: context)
        
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("Chicken Stir Fry"))
            XCTAssertTrue(text.contains("peanuts"))  // Should mention allergy safety
            XCTAssertTrue(text.contains("shellfish"))
        } else {
            XCTFail("Expected response, got \(result)")
        }
    }
    
    func testDinnerSuggestionForVegetarianFamily() async throws {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Mom", role: .parent, preferences: MemberPreferences(dietary: ["vegetarian"])),
            FamilyMember(id: "2", name: "Dad", role: .parent)
        ])
        
        mockLLM.generateResponses["Suggest ONE dinner"] = """
        {
            "name": "Palak Paneer",
            "cuisine": "Indian",
            "prepMinutes": 30,
            "description": "Creamy spinach curry with paneer cheese",
            "keyIngredients": ["spinach", "paneer", "cream", "spices"]
        }
        """
        
        let context = SkillContext(
            family: family,
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What's for dinner?")
        )
        
        let result = try await skill.execute(context: context)
        
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("vegetarian"))
        } else {
            XCTFail("Expected response")
        }
    }
    
    // MARK: - Meal Plan Tests
    
    func testMealPlanGenerationFor4PersonFamily() async throws {
        let family = Family(members: [
            FamilyMember(id: "1", name: "Mom", role: .parent),
            FamilyMember(id: "2", name: "Dad", role: .parent),
            FamilyMember(id: "3", name: "Emma", role: .child, age: 10),
            FamilyMember(id: "4", name: "Jack", role: .child, age: 7)
        ])
        
        mockLLM.generateResponses["Create a 7-day dinner meal plan"] = """
        [
            {"day": "Monday", "name": "Tacos", "cuisine": "Mexican", "prepMinutes": 20, "description": "Easy weeknight tacos"},
            {"day": "Tuesday", "name": "Stir Fry", "cuisine": "Asian", "prepMinutes": 25, "description": "Chicken stir fry"},
            {"day": "Wednesday", "name": "Pasta", "cuisine": "Italian", "prepMinutes": 20, "description": "Spaghetti and meatballs"},
            {"day": "Thursday", "name": "Bean Burritos", "cuisine": "Mexican", "prepMinutes": 15, "description": "Meatless burritos"},
            {"day": "Friday", "name": "Pizza", "cuisine": "Italian", "prepMinutes": 45, "description": "Homemade pizza night"},
            {"day": "Saturday", "name": "Grilled Salmon", "cuisine": "American", "prepMinutes": 35, "description": "Salmon with veggies"},
            {"day": "Sunday", "name": "Pot Roast", "cuisine": "American", "prepMinutes": 180, "description": "Slow cooker roast"}
        ]
        """
        
        let context = SkillContext(
            family: family,
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "Plan meals for this week")
        )
        
        let result = try await skill.execute(context: context)
        
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("WEEKLY MEAL PLAN"))
            XCTAssertTrue(text.contains("4 people"))
            XCTAssertTrue(text.contains("Monday"))
            XCTAssertTrue(text.contains("Sunday"))
            XCTAssertTrue(text.contains("Tacos"))
        } else {
            XCTFail("Expected response")
        }
        
        // Verify plan was saved
        let saved = try? await storage.read(path: "data/current_meal_plan.json", type: [MealPlanDayDTO].self)
        XCTAssertEqual(saved?.count, 7)
    }
    
    // MARK: - Grocery List Tests
    
    func testGroceryListWithoutPlanReturnsGuidance() async throws {
        let context = SkillContext(
            family: Family(),
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "Give me a grocery list")
        )
        
        let result = try await skill.execute(context: context)
        
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("meal plan") || text.contains("create one"))
        } else {
            XCTFail("Expected response")
        }
    }
    
    func testGroceryListWithExistingPlan() async throws {
        // Seed a meal plan
        let plan = [
            MealPlanDayDTO(day: "Monday", name: "Tacos", cuisine: "Mexican", prepMinutes: 20, description: "Easy tacos"),
            MealPlanDayDTO(day: "Tuesday", name: "Pasta", cuisine: "Italian", prepMinutes: 20, description: "Spaghetti")
        ]
        try await storage.seed(path: "data/current_meal_plan.json", value: plan)
        
        mockLLM.generateResponses["Generate a grocery list"] = """
        {
            "sections": [
                {
                    "section": "Produce",
                    "items": [
                        {"name": "Lettuce", "quantity": "1 head"},
                        {"name": "Tomatoes", "quantity": "4 medium"}
                    ]
                },
                {
                    "section": "Protein",
                    "items": [
                        {"name": "Ground beef", "quantity": "1 lb"}
                    ]
                }
            ]
        }
        """
        
        let context = SkillContext(
            family: Family(),
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "Give me a grocery list")
        )
        
        let result = try await skill.execute(context: context)
        
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("GROCERY LIST"))
            XCTAssertTrue(text.contains("Lettuce"))
            XCTAssertTrue(text.contains("Ground beef"))
        } else {
            XCTFail("Expected response")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testHandlesLLMFailureGracefully() async throws {
        mockLLM.defaultResponse = "invalid json {"
        
        let context = SkillContext(
            family: Family(members: [FamilyMember(id: "1", name: "Test", role: .parent)]),
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What should we have for dinner?")
        )
        
        let result = try await skill.execute(context: context)
        
        // Should not crash — should give a friendly fallback
        if case .response(let text) = result {
            XCTAssertFalse(text.isEmpty)
        } else if case .error = result {
            // Also acceptable
        } else {
            XCTFail("Expected response or error")
        }
    }
    
    func testEmptyFamilyStillWorks() async throws {
        mockLLM.generateResponses["Suggest ONE dinner"] = """
        {
            "name": "Quick Pasta",
            "cuisine": "Italian",
            "prepMinutes": 15,
            "description": "Simple garlic pasta",
            "keyIngredients": ["pasta", "garlic", "olive oil"]
        }
        """
        
        let context = SkillContext(
            family: Family(),
            storage: storage,
            llm: mockLLM,
            intent: UserIntent(rawMessage: "What's for dinner?")
        )
        
        let result = try await skill.execute(context: context)
        if case .response(let text) = result {
            XCTAssertTrue(text.contains("Quick Pasta"))
        } else {
            XCTFail("Expected response")
        }
    }
}

// Test DTO (matches the internal type)
private struct MealPlanDayDTO: Codable {
    let day: String
    let name: String
    let cuisine: String
    let prepMinutes: Int
    let description: String
}
