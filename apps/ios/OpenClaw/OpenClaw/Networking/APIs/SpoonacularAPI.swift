import Foundation

/// Spoonacular Recipe API client
/// Documentation: https://spoonacular.com/food-api/docs
final class SpoonacularAPI: BaseAPIClient {
    private let baseURL = "https://api.spoonacular.com"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
        super.init()
    }

    convenience init() {
        let key = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.spoonacular) ?? ""
        self.init(apiKey: key)
    }

    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Recipe Search

    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe] {
        guard isConfigured else {
            logger.warning("Spoonacular API key not configured, using stub data")
            return StubRecipeData.sampleRecipes
        }

        try await APIRateLimiter.shared.checkLimit(api: "spoonacular", maxRequests: 140, windowSeconds: 86400)

        var components = URLComponents(string: "\(baseURL)/recipes/complexSearch")!
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "number", value: String(criteria.limit)),
            URLQueryItem(name: "addRecipeInformation", value: "true"),
            URLQueryItem(name: "fillIngredients", value: "true")
        ]

        if let query = criteria.query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let cuisine = criteria.cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let maxTime = criteria.maxTotalTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: String(maxTime)))
        }
        if !criteria.dietaryRestrictions.isEmpty {
            let diets = criteria.dietaryRestrictions.compactMap { restriction -> String? in
                switch restriction {
                case .vegetarian: return "vegetarian"
                case .vegan: return "vegan"
                case .glutenFree: return "gluten free"
                default: return nil
                }
            }.joined(separator: ",")
            if !diets.isEmpty {
                queryItems.append(URLQueryItem(name: "diet", value: diets))
            }
        }

        components.queryItems = queryItems
        guard let url = components.url else { throw APIError.invalidURL }

        let response: SpoonacularSearchResponse = try await request(url: url)
        return response.results.map { convertToRecipe($0) }
    }

    func getRecipeDetails(id: Int) async throws -> Recipe {
        guard isConfigured else { return StubRecipeData.sampleRecipes[0] }

        let url = URL(string: "\(baseURL)/recipes/\(id)/information?apiKey=\(apiKey)&includeNutrition=false")!
        let spoonRecipe: SpoonacularRecipeDetail = try await request(url: url)
        return convertToRecipe(spoonRecipe)
    }

    // MARK: - Conversion

    private func convertToRecipe(_ sr: SpoonacularRecipeDetail) -> Recipe {
        Recipe(
            externalId: sr.id,
            title: sr.title,
            description: sr.summary?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
            cuisine: sr.cuisines?.first ?? "American",
            dishTypes: sr.dishTypes ?? [],
            prepTime: sr.preparationMinutes ?? 15,
            cookTime: sr.cookingMinutes ?? 15,
            totalTime: sr.readyInMinutes ?? 30,
            servings: sr.servings ?? 4,
            ingredients: (sr.extendedIngredients ?? []).map { ing in
                Ingredient(
                    name: ing.name ?? "Unknown",
                    amount: ing.amount ?? 1.0,
                    unit: ing.unit ?? "unit",
                    category: categorizeIngredient(ing.aisle ?? "")
                )
            },
            instructions: (sr.analyzedInstructions?.first?.steps ?? []).map { step in
                InstructionStep(stepNumber: step.number ?? 0, text: step.step ?? "")
            },
            imageUrl: sr.image,
            sourceUrl: sr.sourceUrl,
            isVegetarian: sr.vegetarian ?? false,
            isVegan: sr.vegan ?? false,
            isGlutenFree: sr.glutenFree ?? false,
            isDairyFree: sr.dairyFree ?? false,
            caloriesPerServing: nil
        )
    }

    private func categorizeIngredient(_ aisle: String) -> GroceryCategory {
        let lower = aisle.lowercased()
        if lower.contains("produce") || lower.contains("fruit") || lower.contains("vegetable") { return .produce }
        if lower.contains("meat") || lower.contains("seafood") { return .meat }
        if lower.contains("dairy") || lower.contains("milk") || lower.contains("cheese") { return .dairy }
        if lower.contains("bakery") || lower.contains("bread") { return .bakery }
        if lower.contains("frozen") { return .frozen }
        if lower.contains("beverage") || lower.contains("drink") { return .beverages }
        if lower.contains("condiment") || lower.contains("spice") { return .condiments }
        return .pantry
    }
}

// MARK: - Spoonacular Response Types

struct SpoonacularSearchResponse: Codable {
    let results: [SpoonacularRecipeDetail]
    let totalResults: Int?
}

struct SpoonacularRecipeDetail: Codable {
    let id: Int
    let title: String
    let summary: String?
    let cuisines: [String]?
    let dishTypes: [String]?
    let readyInMinutes: Int?
    let preparationMinutes: Int?
    let cookingMinutes: Int?
    let servings: Int?
    let extendedIngredients: [SpoonacularIngredient]?
    let analyzedInstructions: [SpoonacularInstruction]?
    let image: String?
    let sourceUrl: String?
    let vegetarian: Bool?
    let vegan: Bool?
    let glutenFree: Bool?
    let dairyFree: Bool?
}

struct SpoonacularIngredient: Codable {
    let id: Int?
    let name: String?
    let amount: Double?
    let unit: String?
    let aisle: String?
}

struct SpoonacularInstruction: Codable {
    let steps: [SpoonacularStep]?
}

struct SpoonacularStep: Codable {
    let number: Int?
    let step: String?
}
