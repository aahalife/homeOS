import Foundation

/// Meal Planning Skill - Weekly dinner plans, recipes, grocery lists
final class MealPlanningSkill {
    private let spoonacularAPI = SpoonacularAPI()
    private let usdaAPI = USDAFoodDataAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Weekly Plan Generation

    func generateWeeklyPlan(family: Family) async throws -> MealPlan {
        logger.info("Generating weekly meal plan for \(family.name)")

        let startDate = Date().startOfWeek.addingDays(1) // Start Monday
        var meals: [PlannedMeal] = []
        var usedProteins: [ProteinType] = []
        var totalCost: Decimal = 0

        let budget = family.preferences.weeklyGroceryBudget ?? 150

        for day in 0..<7 {
            let date = startDate.addingDays(day)
            let isWeekday = date.isWeekday
            let maxTime = isWeekday ? family.preferences.maxWeekdayCookTime : family.preferences.maxWeekendCookTime

            // Get recipe candidates
            var candidates = try await getRecipeCandidates(
                family: family,
                maxTime: maxTime,
                excludeProteins: usedProteins.suffix(1).map { $0 } // No consecutive repeat
            )

            // If API fails or returns empty, use stubs
            if candidates.isEmpty {
                candidates = StubRecipeData.sampleRecipes.filter { $0.totalTime <= maxTime }
            }

            // Filter by dietary restrictions
            let filtered = filterByDiet(recipes: candidates, restrictions: family.dietaryRestrictions)
            guard let recipe = filtered.first ?? candidates.first else { continue }

            let meal = PlannedMeal(
                date: date,
                mealType: .dinner,
                recipe: recipe,
                servings: family.members.count,
                notes: generateMealNotes(recipe: recipe, family: family)
            )
            meals.append(meal)

            usedProteins.append(recipe.primaryProtein)
            totalCost += estimateMealCost(recipe: recipe, servings: family.members.count)
        }

        let plan = MealPlan(
            familyId: family.id,
            weekStartDate: startDate,
            meals: meals,
            groceryList: generateGroceryListFromMeals(meals),
            estimatedCost: min(totalCost, budget),
            status: .draft
        )

        // Persist
        persistence.saveData(plan, type: "meal_plan")

        return plan
    }

    // MARK: - Tonight's Dinner

    func suggestTonightDinner(family: Family) async throws -> PlannedMeal {
        let maxTime = 30 // Quick weeknight meal

        var candidates = try await getRecipeCandidates(family: family, maxTime: maxTime)
        // Filter by max time since stub data may not respect the criteria
        candidates = candidates.filter { $0.totalTime <= maxTime }
        if candidates.isEmpty {
            candidates = StubRecipeData.sampleRecipes.filter { $0.totalTime <= maxTime }
        }

        let filtered = filterByDiet(recipes: candidates, restrictions: family.dietaryRestrictions)
        let recipe = filtered.randomElement() ?? candidates.first ?? StubRecipeData.sampleRecipes[0]

        return PlannedMeal(
            date: Date(),
            mealType: .dinner,
            recipe: recipe,
            servings: family.members.count,
            notes: "Quick dinner suggestion"
        )
    }

    // MARK: - Grocery List

    func generateGroceryList(family: Family) async throws -> GroceryList {
        // Get current meal plan or generate one
        let plans: [MealPlan] = persistence.loadData(type: "meal_plan")
        let currentPlan: MealPlan
        if let existing = plans.first {
            currentPlan = existing
        } else {
            currentPlan = try await generateWeeklyPlan(family: family)
        }

        return currentPlan.groceryList ?? generateGroceryListFromMeals(currentPlan.meals)
    }

    // MARK: - Helpers

    private func getRecipeCandidates(family: Family, maxTime: Int, excludeProteins: [ProteinType] = []) async throws -> [Recipe] {
        let criteria = RecipeSearchCriteria(
            dietaryRestrictions: family.dietaryRestrictions,
            maxTotalTime: maxTime,
            limit: 10
        )

        do {
            let recipes = try await spoonacularAPI.searchRecipes(criteria: criteria)
            return recipes.filter { recipe in
                !excludeProteins.contains(recipe.primaryProtein)
            }
        } catch {
            logger.warning("Recipe API search failed: \(error.localizedDescription)")
            return StubRecipeData.sampleRecipes
        }
    }

    private func filterByDiet(recipes: [Recipe], restrictions: [DietaryRestriction]) -> [Recipe] {
        guard !restrictions.isEmpty else { return recipes }

        return recipes.filter { recipe in
            for restriction in restrictions {
                switch restriction {
                case .vegetarian where !recipe.isVegetarian: return false
                case .vegan where !recipe.isVegan: return false
                case .glutenFree where !recipe.isGlutenFree: return false
                case .dairyFree where !recipe.isDairyFree: return false
                case .halal where recipe.primaryProtein == .pork: return false
                case .kosher where recipe.primaryProtein == .pork: return false
                default: continue
                }
            }
            return true
        }
    }

    private func generateGroceryListFromMeals(_ meals: [PlannedMeal]) -> GroceryList {
        var itemMap: [String: GroceryItem] = [:]
        var total: Decimal = 0

        for meal in meals {
            for ingredient in meal.recipe.ingredients {
                let key = ingredient.name.lowercased()
                if var existing = itemMap[key] {
                    existing.quantity += ingredient.amount
                    itemMap[key] = existing
                } else {
                    let price = estimateIngredientPrice(ingredient)
                    total += price
                    itemMap[key] = GroceryItem(
                        name: ingredient.name,
                        quantity: ingredient.amount,
                        unit: ingredient.unit,
                        category: ingredient.category,
                        estimatedPrice: price
                    )
                }
            }
        }

        return GroceryList(
            items: Array(itemMap.values).sorted { $0.category.rawValue < $1.category.rawValue },
            estimatedTotal: total
        )
    }

    private func estimateMealCost(recipe: Recipe, servings: Int) -> Decimal {
        // Rough estimation: $2-$5 per serving
        let perServing: Decimal = recipe.primaryProtein == .seafood ? 5 : (recipe.isVegetarian ? 2 : 3.5)
        return perServing * Decimal(servings)
    }

    private func estimateIngredientPrice(_ ingredient: Ingredient) -> Decimal {
        switch ingredient.category {
        case .meat: return 5
        case .produce: return 2
        case .dairy: return 3
        case .pantry: return 2
        default: return 2
        }
    }

    private func generateMealNotes(recipe: Recipe, family: Family) -> String? {
        var notes: [String] = []
        if family.dietaryRestrictions.contains(.dairyFree) && recipe.isDairyFree {
            notes.append("Dairy-free safe")
        }
        if family.dietaryRestrictions.contains(.nutFree) && recipe.isNutFree {
            notes.append("Nut-free safe")
        }
        if family.dietaryRestrictions.contains(.halal) {
            notes.append("Ensure halal sourcing for meat")
        }
        return notes.isEmpty ? nil : notes.joined(separator: " | ")
    }
}
