import Foundation

// MARK: - Meal Planning Models

struct MealPlan: Identifiable, Codable {
    var id: UUID = UUID()
    var familyId: UUID
    var weekStartDate: Date
    var meals: [PlannedMeal]
    var groceryList: GroceryList?
    var estimatedCost: Decimal
    var status: PlanStatus = .draft
    var createdAt: Date = Date()
}

struct PlannedMeal: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var mealType: MealType
    var recipe: Recipe
    var servings: Int
    var isLeftover: Bool = false
    var notes: String?
}

struct Recipe: Identifiable, Codable {
    var id: UUID = UUID()
    var externalId: Int?
    var title: String
    var description: String?
    var cuisine: String
    var dishTypes: [String] = []
    var prepTime: Int // minutes
    var cookTime: Int // minutes
    var totalTime: Int // minutes
    var servings: Int
    var difficulty: RecipeDifficulty = .intermediate
    var ingredients: [Ingredient]
    var instructions: [InstructionStep]
    var imageUrl: String?
    var sourceUrl: String?
    var isVegetarian: Bool = false
    var isVegan: Bool = false
    var isGlutenFree: Bool = false
    var isDairyFree: Bool = false
    var isNutFree: Bool = true
    var primaryProtein: ProteinType = .none
    var tags: [String] = []
    var rating: Double?
    var caloriesPerServing: Int?
}

struct Ingredient: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var unit: String
    var category: GroceryCategory
}

struct InstructionStep: Identifiable, Codable {
    var id: UUID = UUID()
    var stepNumber: Int
    var text: String
}

struct GroceryList: Identifiable, Codable {
    var id: UUID = UUID()
    var items: [GroceryItem]
    var estimatedTotal: Decimal

    var categorized: [GroceryCategory: [GroceryItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
}

struct GroceryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var category: GroceryCategory
    var estimatedPrice: Decimal?
    var isPurchased: Bool = false
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case meat = "Meat & Seafood"
    case dairy = "Dairy"
    case bakery = "Bakery"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case condiments = "Condiments"
    case other = "Other"
}

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack
    case suhoor, iftar // Ramadan support
}

enum PlanStatus: String, Codable {
    case draft, active, completed, archived
}

enum RecipeDifficulty: String, Codable {
    case easy, intermediate, advanced
}

enum ProteinType: String, Codable {
    case chicken, beef, pork, seafood, vegetarian, vegan, none
}

struct PantryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var expiryDate: Date?
    var category: GroceryCategory
}

struct RecipeSearchCriteria {
    var query: String?
    var cuisine: String?
    var dietaryRestrictions: [DietaryRestriction] = []
    var maxTotalTime: Int?
    var limit: Int = 10
}

// MARK: - Nutrition

struct NutritionInfo: Codable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
}

struct FoodItem: Codable {
    var fdcId: Int
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}
