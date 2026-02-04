import Foundation

/// USDA FoodData Central API - FREE
/// Documentation: https://fdc.nal.usda.gov/api-guide.html
final class USDAFoodDataAPI: BaseAPIClient {
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let apiKey: String

    init(apiKey: String = "DEMO_KEY") {
        self.apiKey = KeychainManager.shared.getAPIKey(for: KeychainManager.APIKeys.usda) ?? apiKey
        super.init()
    }

    func searchFood(query: String, pageSize: Int = 10) async throws -> [FoodItem] {
        var components = URLComponents(string: "\(baseURL)/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "api_key", value: apiKey)
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: USDASearchResponse = try await request(url: url)
        return response.foods.map { food in
            FoodItem(
                fdcId: food.fdcId,
                name: food.description,
                calories: food.foodNutrients.first(where: { $0.nutrientName == "Energy" })?.value ?? 0,
                protein: food.foodNutrients.first(where: { $0.nutrientName == "Protein" })?.value ?? 0,
                carbs: food.foodNutrients.first(where: { $0.nutrientName?.contains("Carbohydrate") == true })?.value ?? 0,
                fat: food.foodNutrients.first(where: { $0.nutrientName?.contains("lipid") == true })?.value ?? 0
            )
        }
    }

    func getFoodDetails(fdcId: Int) async throws -> FoodItem {
        let url = URL(string: "\(baseURL)/food/\(fdcId)?api_key=\(apiKey)")!
        let food: USDAFoodDetail = try await request(url: url)
        return FoodItem(
            fdcId: food.fdcId,
            name: food.description,
            calories: food.foodNutrients?.first(where: { $0.nutrient?.name == "Energy" })?.amount ?? 0,
            protein: food.foodNutrients?.first(where: { $0.nutrient?.name == "Protein" })?.amount ?? 0,
            carbs: food.foodNutrients?.first(where: { $0.nutrient?.name?.contains("Carbohydrate") == true })?.amount ?? 0,
            fat: food.foodNutrients?.first(where: { $0.nutrient?.name?.contains("lipid") == true })?.amount ?? 0
        )
    }
}

// MARK: - USDA Response Types

struct USDASearchResponse: Codable {
    let totalHits: Int
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]
}

struct USDANutrient: Codable {
    let nutrientName: String?
    let value: Double?
    let unitName: String?
}

struct USDAFoodDetail: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDAFoodNutrientDetail]?
}

struct USDAFoodNutrientDetail: Codable {
    let nutrient: USDANutrientInfo?
    let amount: Double?
}

struct USDANutrientInfo: Codable {
    let name: String?
    let unitName: String?
}
