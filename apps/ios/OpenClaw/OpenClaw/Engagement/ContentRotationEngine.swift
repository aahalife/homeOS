import Foundation

/// Manages recipe discovery, seasonal awareness, cultural events, and trending content
/// to keep the meal planning experience fresh and interesting over time.
final class ContentRotationEngine {
    private let logger = AppLogger.shared

    // MARK: - Recipe Discovery

    /// Introduces 2-3 new recipes per week from different cuisines
    func getWeeklyNewRecipes(
        week: Int,
        familyPreferences: FamilyPreferences,
        previousRecipes: Set<UUID>
    ) -> [Recipe] {
        logger.info("Generating new recipes for week \(week)")

        // Rotate cuisines to ensure variety
        let cuisinePool = getCuisineRotation(week: week, preferences: familyPreferences)

        // Generate 2-3 new recipes
        var newRecipes: [Recipe] = []
        let count = (week % 2 == 0) ? 3 : 2 // Alternate between 2 and 3

        for i in 0..<count {
            let cuisine = cuisinePool[i % cuisinePool.count]
            if let recipe = generateDiscoveryRecipe(
                cuisine: cuisine,
                week: week,
                index: i,
                familyPreferences: familyPreferences,
                excluding: previousRecipes
            ) {
                newRecipes.append(recipe)
            }
        }

        return newRecipes
    }

    /// Suggests seasonal appropriate meals based on current season
    func getSeasonalSuggestions(
        season: SeasonalTheme = SeasonalTheme.spring.currentSeason,
        familyPreferences: FamilyPreferences
    ) -> [Recipe] {
        logger.info("Generating seasonal suggestions for \(season.rawValue)")

        let seasonalIngredients = season.suggestedIngredients

        return [
            Recipe(
                title: getSeasonalRecipeTitle(season: season, index: 0),
                description: "A perfect \(season.rawValue) dish featuring seasonal ingredients",
                cuisine: getSeasonalCuisine(season: season),
                prepTime: 15,
                cookTime: 30,
                totalTime: 45,
                servings: 4,
                difficulty: .intermediate,
                ingredients: createSeasonalIngredients(from: seasonalIngredients),
                instructions: createBasicInstructions(),
                tags: ["seasonal", season.rawValue, "fresh"]
            ),
            Recipe(
                title: getSeasonalRecipeTitle(season: season, index: 1),
                description: "Light and refreshing \(season.rawValue) favorite",
                cuisine: "Mediterranean",
                prepTime: 10,
                cookTime: 20,
                totalTime: 30,
                servings: 4,
                difficulty: .easy,
                ingredients: createSeasonalIngredients(from: seasonalIngredients, light: true),
                instructions: createBasicInstructions(),
                tags: ["seasonal", season.rawValue, "quick"]
            )
        ]
    }

    /// Suggests themed meals for upcoming cultural events
    func getCulturalEventSuggestions(daysAhead: Int = 14) -> [(CulturalEvent, [Recipe])] {
        let upcoming = CulturalEvent.upcomingEvents
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: daysAhead, to: Date()) ?? Date()

        return upcoming
            .filter { $0.date <= cutoffDate }
            .map { event in
                let recipes = event.suggestedRecipes.enumerated().map { index, recipeName in
                    Recipe(
                        title: recipeName,
                        description: "Traditional \(event.cuisine) dish for \(event.name)",
                        cuisine: event.cuisine,
                        prepTime: 20,
                        cookTime: 40,
                        totalTime: 60,
                        servings: 6,
                        difficulty: index == 0 ? .easy : .intermediate,
                        ingredients: createCulturalIngredients(cuisine: event.cuisine),
                        instructions: createBasicInstructions(),
                        tags: ["cultural", event.name, event.cuisine]
                    )
                }
                return (event, recipes)
            }
    }

    /// Rotates in popular recipes monthly based on ratings
    func getTrendingRecipes(
        month: Int,
        userRatings: [UUID: Double],
        globalTrending: [Recipe] = []
    ) -> [Recipe] {
        logger.info("Generating trending recipes for month \(month)")

        // Combine user-rated favorites with globally trending
        let userFavorites = getUserTopRatedRecipes(ratings: userRatings)

        // If we have global data, use it; otherwise generate deterministic trending
        if !globalTrending.isEmpty {
            return Array(globalTrending.prefix(5))
        }

        // Generate deterministic "trending" recipes based on month
        return generateMonthlyTrending(month: month)
    }

    /// Promotes recipes with 4+ star ratings
    func getHighRatedRecipes(ratings: [UUID: Double]) -> [Recipe] {
        let highRated = ratings.filter { $0.value >= 4.0 }
        logger.info("Found \(highRated.count) high-rated recipes")

        // In production, this would fetch actual recipes by ID
        // For now, generate representative recipes
        return highRated.prefix(3).enumerated().map { index, _ in
            Recipe(
                title: "Highly Rated Recipe #\(index + 1)",
                description: "Loved by your family with a 4+ star rating",
                cuisine: ["Italian", "Mexican", "Asian"][index % 3],
                prepTime: 15,
                cookTime: 25,
                totalTime: 40,
                servings: 4,
                difficulty: .easy,
                ingredients: createGenericIngredients(),
                instructions: createBasicInstructions(),
                rating: 4.5,
                tags: ["family-favorite", "highly-rated"]
            )
        }
    }

    // MARK: - Helper Methods

    private func getCuisineRotation(week: Int, preferences: FamilyPreferences) -> [String] {
        let allCuisines = [
            "Italian", "Mexican", "Chinese", "Japanese", "Indian",
            "Thai", "Mediterranean", "American", "Korean", "Vietnamese",
            "Greek", "French", "Spanish", "Middle Eastern", "Caribbean"
        ]

        // Prioritize preferred cuisines
        var rotation = preferences.preferredCuisines.isEmpty ? allCuisines : preferences.preferredCuisines

        // Add variety by including one non-preferred cuisine
        if !preferences.preferredCuisines.isEmpty {
            let others = allCuisines.filter { !preferences.preferredCuisines.contains($0) }
            if let surprise = others.randomElement() {
                rotation.append(surprise)
            }
        }

        // Rotate based on week number for determinism
        let startIndex = (week * 2) % rotation.count
        return Array(rotation[startIndex...] + rotation[..<startIndex])
    }

    private func generateDiscoveryRecipe(
        cuisine: String,
        week: Int,
        index: Int,
        familyPreferences: FamilyPreferences,
        excluding: Set<UUID>
    ) -> Recipe? {
        // Generate a deterministic but varied recipe
        let recipeVariants = [
            "Classic", "Modern", "Traditional", "Fusion", "Home-style",
            "Restaurant-style", "Quick", "Slow-cooked", "One-pot", "Fresh"
        ]

        let dishTypes = [
            "Bowl", "Curry", "Stir-fry", "Pasta", "Soup",
            "Salad", "Tacos", "Rice dish", "Noodles", "Casserole"
        ]

        let variant = recipeVariants[(week + index) % recipeVariants.count]
        let dish = dishTypes[(week * 3 + index) % dishTypes.count]

        return Recipe(
            title: "\(variant) \(cuisine) \(dish)",
            description: "A delicious \(cuisine.lowercased()) dish perfect for weeknight dinners",
            cuisine: cuisine,
            prepTime: [10, 15, 20][(week + index) % 3],
            cookTime: [20, 30, 40][(week + index) % 3],
            totalTime: [30, 45, 60][(week + index) % 3],
            servings: 4,
            difficulty: [.easy, .intermediate, .intermediate][(week + index) % 3],
            ingredients: createCuisineSpecificIngredients(cuisine: cuisine),
            instructions: createBasicInstructions(),
            tags: ["new", cuisine, "weekly-discovery"]
        )
    }

    private func getSeasonalRecipeTitle(season: SeasonalTheme, index: Int) -> String {
        let titles: [SeasonalTheme: [String]] = [
            .spring: ["Spring Vegetable Medley", "Fresh Herb Chicken", "Asparagus Risotto"],
            .summer: ["Grilled Summer Vegetables", "Fresh Tomato Pasta", "Watermelon Feta Salad"],
            .fall: ["Butternut Squash Soup", "Apple Cider Chicken", "Pumpkin Risotto"],
            .winter: ["Root Vegetable Stew", "Citrus Glazed Salmon", "Winter Minestrone"]
        ]
        return titles[season]?[index % 3] ?? "Seasonal Dish"
    }

    private func getSeasonalCuisine(season: SeasonalTheme) -> String {
        switch season {
        case .spring: return "Mediterranean"
        case .summer: return "American"
        case .fall: return "Italian"
        case .winter: return "French"
        }
    }

    private func createSeasonalIngredients(from seasonalItems: [String], light: Bool = false) -> [Ingredient] {
        var ingredients: [Ingredient] = []

        for (index, item) in seasonalItems.prefix(3).enumerated() {
            ingredients.append(Ingredient(
                name: item,
                amount: Double(index + 1),
                unit: ["cups", "lbs", "pieces"][index % 3],
                category: .produce
            ))
        }

        if !light {
            ingredients.append(Ingredient(name: "Olive oil", amount: 2, unit: "tbsp", category: .pantry))
            ingredients.append(Ingredient(name: "Garlic", amount: 3, unit: "cloves", category: .produce))
        }

        return ingredients
    }

    private func createCulturalIngredients(cuisine: String) -> [Ingredient] {
        let ingredientMap: [String: [String]] = [
            "Chinese": ["soy sauce", "ginger", "scallions", "rice"],
            "Mexican": ["tortillas", "cilantro", "lime", "beans"],
            "Indian": ["curry powder", "coconut milk", "basmati rice", "naan"],
            "Italian": ["pasta", "tomatoes", "basil", "parmesan"],
            "American": ["potatoes", "butter", "herbs", "bread"]
        ]

        let items = ingredientMap[cuisine] ?? ["onions", "garlic", "salt", "pepper"]

        return items.enumerated().map { index, name in
            Ingredient(
                name: name,
                amount: Double(index + 1),
                unit: ["cups", "tbsp", "oz", "pieces"][index % 4],
                category: .pantry
            )
        }
    }

    private func createCuisineSpecificIngredients(cuisine: String) -> [Ingredient] {
        createCulturalIngredients(cuisine: cuisine)
    }

    private func createGenericIngredients() -> [Ingredient] {
        [
            Ingredient(name: "Main ingredient", amount: 1, unit: "lb", category: .meat),
            Ingredient(name: "Vegetables", amount: 2, unit: "cups", category: .produce),
            Ingredient(name: "Seasoning", amount: 1, unit: "tsp", category: .pantry)
        ]
    }

    private func createBasicInstructions() -> [InstructionStep] {
        [
            InstructionStep(stepNumber: 1, text: "Prepare ingredients by washing and chopping as needed."),
            InstructionStep(stepNumber: 2, text: "Heat cooking vessel and add primary ingredients."),
            InstructionStep(stepNumber: 3, text: "Cook according to recipe specifications."),
            InstructionStep(stepNumber: 4, text: "Season to taste and serve warm.")
        ]
    }

    private func getUserTopRatedRecipes(ratings: [UUID: Double]) -> [Recipe] {
        let topRated = ratings
            .filter { $0.value >= 4.0 }
            .sorted { $0.value > $1.value }
            .prefix(3)

        return topRated.map { _ in
            // In production, fetch actual recipes
            Recipe(
                title: "Family Favorite",
                description: "A recipe your family loves",
                cuisine: "Various",
                prepTime: 15,
                cookTime: 30,
                totalTime: 45,
                servings: 4,
                difficulty: .easy,
                ingredients: createGenericIngredients(),
                instructions: createBasicInstructions(),
                rating: 4.5
            )
        }
    }

    private func generateMonthlyTrending(month: Int) -> [Recipe] {
        let trendingThemes = [
            "One-Pot Wonders",
            "Sheet Pan Dinners",
            "30-Minute Meals",
            "Comfort Food Classics",
            "Healthy Bowl",
            "Budget-Friendly",
            "Make-Ahead",
            "Family Favorites",
            "Restaurant Copycat",
            "Instant Pot",
            "Air Fryer",
            "Mediterranean Diet"
        ]

        let theme = trendingThemes[month % trendingThemes.count]

        return (0..<3).map { index in
            Recipe(
                title: "\(theme) Recipe #\(index + 1)",
                description: "Trending this month: \(theme.lowercased()) style cooking",
                cuisine: ["Italian", "Mexican", "Asian"][index],
                prepTime: 10 + (index * 5),
                cookTime: 20 + (index * 10),
                totalTime: 30 + (index * 15),
                servings: 4,
                difficulty: [.easy, .easy, .intermediate][index],
                ingredients: createGenericIngredients(),
                instructions: createBasicInstructions(),
                tags: ["trending", theme, "popular"]
            )
        }
    }
}
