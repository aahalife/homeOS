# Meal Planning Skill: Atomic Function Breakdown

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Production-Ready Implementation Guide
**Target Platform:** iOS 17.0+, Swift 5.10+

---

## Table of Contents

1. [Skill Overview](#1-skill-overview)
2. [User Stories](#2-user-stories)
3. [Atomic Functions](#3-atomic-functions)
4. [Deterministic Decision Tree](#4-deterministic-decision-tree)
5. [State Machine](#5-state-machine)
6. [Data Structures](#6-data-structures)
7. [Example Scenarios](#7-example-scenarios)
8. [API Integrations](#8-api-integrations)
9. [Test Cases](#9-test-cases)
10. [Error Handling](#10-error-handling)

---

## 1. Skill Overview

### Purpose
The Meal Planning skill automates weekly dinner planning, grocery list generation, and pantry management for American families. It reduces the mental load of answering "What's for dinner?" by providing intelligent, personalized meal suggestions that account for dietary restrictions, time constraints, budget, and family preferences.

### Core Capabilities
- **Weekly Meal Planning**: Generate 7-day dinner plans with variety and balance
- **Single Meal Suggestions**: Quick "what's for dinner tonight?" recommendations
- **Grocery List Generation**: Smart lists organized by store category
- **Pantry Management**: Track ingredients to reduce waste and cost
- **Recipe Search**: Find meals matching specific criteria
- **Cost Estimation**: Budget-aware planning with price tracking
- **Leftover Planning**: Intentional meal sizing for next-day use

### Design Principles
1. **Pragmatic Repetition**: Families eat favorites 2-4 times/month
2. **Time-Aware**: Weekdays = 30min max, weekends = 60-90min cooking
3. **Protein Rotation**: Avoid same protein consecutive days
4. **Cuisine Variety**: 3-4 different cuisines per week
5. **Incremental Learning**: Never block on missing preferences

---

## 2. User Stories

### Primary User: Sarah, 38-year-old working parent

**Story 1: Weekly Planning (New User)**
```
As a new user
I want to generate my first weekly meal plan
So that I don't have to think about dinners all week

Acceptance Criteria:
- System asks minimal questions (family size, dietary restrictions)
- Generates 7 dinners with variety
- Creates organized grocery list
- Saves preferences for future use
```

**Story 2: Quick Tonight Decision**
```
As a busy parent at 5pm
I want a quick dinner suggestion using what I have
So that I don't order expensive takeout

Acceptance Criteria:
- Response within 2 seconds
- Uses pantry inventory if available
- Suggests 30-minute recipes
- Offers 2-3 alternatives
```

**Story 3: Dietary Restriction**
```
As a parent with a dairy-free child
I want all meal plans to exclude dairy
So that I don't accidentally plan unsafe meals

Acceptance Criteria:
- All recipes filtered by restriction
- Clear allergen labeling
- Substitution suggestions when relevant
```

**Story 4: Budget Conscious Planning**
```
As a family on a tight budget ($120/week)
I want meal plans that fit my grocery budget
So that I don't overspend on food

Acceptance Criteria:
- Estimated cost shown before confirmation
- Suggests cheaper alternatives if over budget
- Tracks actual spending vs. estimate
```

**Story 5: Leftover Integration**
```
As someone who hates food waste
I want intentional leftover planning
So that I cook once and eat twice

Acceptance Criteria:
- Plans 1-2 meals/week with extra servings
- Labels next day as "Leftovers: [Meal Name]"
- Adjusts grocery quantities accordingly
```

---

## 3. Atomic Functions

All functions are pure, testable, and composable. Each has a single responsibility.

### 3.1 Preference Management

#### `getFamilyPreferences(familyId: UUID) async throws -> MealPreferences`
Retrieves saved meal planning preferences for a family.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** `MealPreferences` object containing dietary restrictions, budget, cuisine preferences

**Errors:**
- `MealPlanningError.familyNotFound`
- `MealPlanningError.databaseError`

**Swift Signature:**
```swift
func getFamilyPreferences(familyId: UUID) async throws -> MealPreferences
```

---

#### `updateFamilyPreferences(familyId: UUID, preferences: MealPreferences) async throws -> Bool`
Saves or updates meal planning preferences.

**Parameters:**
- `familyId`: Unique identifier for family
- `preferences`: Updated preferences object

**Returns:** `true` if successful

**Errors:**
- `MealPlanningError.familyNotFound`
- `MealPlanningError.invalidPreferences`
- `MealPlanningError.databaseError`

**Swift Signature:**
```swift
func updateFamilyPreferences(
    familyId: UUID,
    preferences: MealPreferences
) async throws -> Bool
```

---

#### `getDietaryRestrictions(familyId: UUID) async throws -> [DietaryRestriction]`
Gets aggregated dietary restrictions for all family members.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** Array of all dietary restrictions across family members

**Logic:**
- Queries all family members
- Deduplicates restrictions
- Prioritizes most restrictive (vegan > vegetarian)

**Swift Signature:**
```swift
func getDietaryRestrictions(familyId: UUID) async throws -> [DietaryRestriction]
```

---

### 3.2 Pantry Management

#### `getPantryInventory(familyId: UUID) async throws -> [PantryItem]`
Retrieves current pantry inventory with quantities and expiration dates.

**Parameters:**
- `familyId`: Unique identifier for family

**Returns:** Array of pantry items with metadata

**Swift Signature:**
```swift
func getPantryInventory(familyId: UUID) async throws -> [PantryItem]
```

---

#### `updatePantryItem(familyId: UUID, item: PantryItem, quantity: Decimal) async throws -> Bool`
Updates quantity of specific pantry item (add/remove/set).

**Parameters:**
- `familyId`: Unique identifier for family
- `item`: Pantry item to update
- `quantity`: New quantity (positive = add, negative = remove)

**Returns:** `true` if successful

**Swift Signature:**
```swift
func updatePantryItem(
    familyId: UUID,
    item: PantryItem,
    quantity: Decimal
) async throws -> Bool
```

---

#### `checkPantryForRecipe(familyId: UUID, recipe: Recipe) async throws -> PantryCheckResult`
Determines what ingredients are available vs. needed for a recipe.

**Parameters:**
- `familyId`: Unique identifier for family
- `recipe`: Recipe to check against

**Returns:** `PantryCheckResult` with available/missing/insufficient ingredients

**Swift Signature:**
```swift
func checkPantryForRecipe(
    familyId: UUID,
    recipe: Recipe
) async throws -> PantryCheckResult
```

---

### 3.3 Recipe Search & Filtering

#### `searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe]`
Searches recipe database with flexible criteria.

**Parameters:**
- `criteria`: Search criteria object (see Data Structures)

**Returns:** Array of matching recipes, ranked by relevance

**External API:** Spoonacular API

**Swift Signature:**
```swift
func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe]
```

---

#### `filterRecipesByDietary(recipes: [Recipe], restrictions: [DietaryRestriction]) -> [Recipe]`
Filters recipes to match dietary restrictions (pure function).

**Parameters:**
- `recipes`: Array of recipes to filter
- `restrictions`: Dietary restrictions to apply

**Returns:** Filtered array (only compatible recipes)

**Logic:**
- Vegan: excludes all animal products
- Vegetarian: excludes meat/seafood
- Gluten-free: excludes wheat/barley/rye
- Dairy-free: excludes milk/cheese/butter
- Nut-free: excludes all tree nuts/peanuts

**Swift Signature:**
```swift
func filterRecipesByDietary(
    recipes: [Recipe],
    restrictions: [DietaryRestriction]
) -> [Recipe]
```

---

#### `filterRecipesByTime(recipes: [Recipe], maxMinutes: Int) -> [Recipe]`
Filters recipes by maximum preparation time (pure function).

**Parameters:**
- `recipes`: Array of recipes to filter
- `maxMinutes`: Maximum allowed prep + cook time

**Returns:** Filtered array

**Swift Signature:**
```swift
func filterRecipesByTime(recipes: [Recipe], maxMinutes: Int) -> [Recipe]
```

---

#### `rankRecipesByPreference(recipes: [Recipe], history: [MealHistoryEntry]) -> [Recipe]`
Ranks recipes based on past ratings and frequency (pure function).

**Parameters:**
- `recipes`: Array of recipes to rank
- `history`: Past meal history with ratings

**Returns:** Re-ranked array (favorites first, never-tried last)

**Logic:**
- Rated 5 stars → boost score +3
- Rated 4 stars → boost score +2
- Rated 1-2 stars → exclude entirely
- Made in last 14 days → penalize score -2
- Made 3+ times in last 90 days → penalize score -1
- Never tried → neutral score

**Swift Signature:**
```swift
func rankRecipesByPreference(
    recipes: [Recipe],
    history: [MealHistoryEntry]
) -> [Recipe]
```

---

### 3.4 Meal Plan Generation

#### `generateWeeklyPlan(constraints: WeeklyPlanConstraints) async throws -> WeeklyMealPlan`
Core function: generates a balanced 7-day meal plan.

**Parameters:**
- `constraints`: Comprehensive constraints object (see Data Structures)

**Returns:** `WeeklyMealPlan` with 7 dinners, grocery list, cost estimate

**Decision Logic:**
1. Load family preferences and history
2. Determine protein rotation schedule
3. Select 2-3 past favorites (rated 4-5 stars)
4. Search for 4-5 new recipes matching criteria
5. Assign meals to days (time-aware: weekday = fast, weekend = complex)
6. Plan 1 leftover day
7. Validate variety (cuisine, protein, cooking method)
8. Generate grocery list
9. Estimate total cost

**Swift Signature:**
```swift
func generateWeeklyPlan(
    constraints: WeeklyPlanConstraints
) async throws -> WeeklyMealPlan
```

---

#### `generateSingleMeal(constraints: SingleMealConstraints) async throws -> PlannedMeal`
Suggests one meal for immediate use (tonight's dinner).

**Parameters:**
- `constraints`: Single meal constraints (time, pantry-first, etc.)

**Returns:** `PlannedMeal` object

**Decision Logic:**
1. Check pantry inventory
2. Prefer recipes using existing ingredients (>60% match)
3. Apply time constraint (default 30min)
4. Check protein rotation (avoid yesterday's protein)
5. Return top-ranked option

**Swift Signature:**
```swift
func generateSingleMeal(
    constraints: SingleMealConstraints
) async throws -> PlannedMeal
```

---

#### `selectProteinForDay(history: [MealHistoryEntry], day: DayOfWeek) -> ProteinType`
Determines optimal protein for a specific day (pure function).

**Parameters:**
- `history`: Recent meal history (last 14 days)
- `day`: Day of week being planned

**Returns:** Recommended `ProteinType`

**Decision Logic:**
- Never repeat protein from previous day
- Rotate through: Chicken → Beef → Vegetarian → Seafood → Pork
- Track frequency: if protein used 3+ times in last 14 days, skip
- Friday default: fish or vegetarian (cultural pattern)

**Swift Signature:**
```swift
func selectProteinForDay(
    history: [MealHistoryEntry],
    day: DayOfWeek
) -> ProteinType
```

---

#### `selectCuisineForDay(history: [MealHistoryEntry], preferences: [String]) -> String`
Determines optimal cuisine for variety (pure function).

**Parameters:**
- `history`: Recent meal history (last 7 days)
- `preferences`: User's preferred cuisines

**Returns:** Cuisine string (e.g., "italian", "mexican", "asian")

**Decision Logic:**
- Aim for 3-4 different cuisines per week
- Never repeat cuisine 2 days in a row
- Rotate through user preferences
- Default fallback: ["american", "italian", "mexican", "asian"]

**Swift Signature:**
```swift
func selectCuisineForDay(
    history: [MealHistoryEntry],
    preferences: [String]
) -> String
```

---

#### `planLeftoverMeal(originalMeal: PlannedMeal, servingsMultiplier: Decimal) -> PlannedMeal`
Creates a leftover meal entry (pure function).

**Parameters:**
- `originalMeal`: The meal being cooked with extra servings
- `servingsMultiplier`: How many extra servings (e.g., 1.5 = 50% more)

**Returns:** New `PlannedMeal` marked as leftover

**Swift Signature:**
```swift
func planLeftoverMeal(
    originalMeal: PlannedMeal,
    servingsMultiplier: Decimal
) -> PlannedMeal
```

---

### 3.5 Grocery List Management

#### `generateGroceryList(meals: [PlannedMeal], pantry: [PantryItem]) async throws -> GroceryList`
Creates organized grocery list from meal plan.

**Parameters:**
- `meals`: Array of planned meals
- `pantry`: Current pantry inventory

**Returns:** `GroceryList` organized by store category

**Decision Logic:**
1. Extract all ingredients from meals
2. Aggregate quantities (e.g., 3 recipes need onions = 5 total)
3. Subtract pantry inventory
4. Categorize by store section (produce, dairy, meat, pantry, etc.)
5. Sort within category by typical store layout

**Swift Signature:**
```swift
func generateGroceryList(
    meals: [PlannedMeal],
    pantry: [PantryItem]
) async throws -> GroceryList
```

---

#### `categorizeIngredient(ingredient: Ingredient) -> GroceryCategory`
Assigns ingredient to grocery store category (pure function).

**Parameters:**
- `ingredient`: Ingredient to categorize

**Returns:** `GroceryCategory` enum value

**Categories:**
- Produce (fruits, vegetables)
- Meat & Seafood
- Dairy & Eggs
- Bakery
- Pantry Staples (grains, canned goods)
- Frozen
- Condiments & Spices
- Beverages

**Swift Signature:**
```swift
func categorizeIngredient(ingredient: Ingredient) -> GroceryCategory
```

---

#### `estimateGroceryCost(list: GroceryList) async throws -> CostEstimate`
Estimates total cost of grocery list.

**Parameters:**
- `list`: Grocery list to price

**Returns:** `CostEstimate` with item-level and total costs

**External API:** Store price APIs (Kroger, Walmart, etc.) or USDA average prices

**Fallback:** Use cached average prices by category

**Swift Signature:**
```swift
func estimateGroceryCost(list: GroceryList) async throws -> CostEstimate
```

---

#### `optimizeGroceryListForBudget(list: GroceryList, maxBudget: Decimal, meals: [PlannedMeal]) async throws -> OptimizedGroceryResult`
Adjusts grocery list to fit budget constraint.

**Parameters:**
- `list`: Original grocery list
- `maxBudget`: Maximum allowed spending
- `meals`: Meal plan (for suggesting cheaper substitutes)

**Returns:** `OptimizedGroceryResult` with adjusted list and substitution notes

**Decision Logic:**
1. Calculate current total
2. If under budget, return as-is
3. If over budget:
   - Suggest store brand alternatives (-20% cost)
   - Suggest cheaper protein swaps (beef → chicken, seafood → canned tuna)
   - Suggest seasonal produce alternatives
4. Recalculate until under budget

**Swift Signature:**
```swift
func optimizeGroceryListForBudget(
    list: GroceryList,
    maxBudget: Decimal,
    meals: [PlannedMeal]
) async throws -> OptimizedGroceryResult
```

---

### 3.6 Meal History & Analytics

#### `saveMealPlan(familyId: UUID, plan: WeeklyMealPlan) async throws -> Bool`
Persists meal plan to database.

**Parameters:**
- `familyId`: Unique identifier for family
- `plan`: Meal plan to save

**Returns:** `true` if successful

**Swift Signature:**
```swift
func saveMealPlan(
    familyId: UUID,
    plan: WeeklyMealPlan
) async throws -> Bool
```

---

#### `getMealHistory(familyId: UUID, startDate: Date, endDate: Date) async throws -> [MealHistoryEntry]`
Retrieves historical meals within date range.

**Parameters:**
- `familyId`: Unique identifier for family
- `startDate`: Start of date range
- `endDate`: End of date range

**Returns:** Array of historical meal entries

**Swift Signature:**
```swift
func getMealHistory(
    familyId: UUID,
    startDate: Date,
    endDate: Date
) async throws -> [MealHistoryEntry]
```

---

#### `rateMeal(familyId: UUID, mealId: UUID, rating: Int, notes: String?) async throws -> Bool`
Saves user rating for a completed meal.

**Parameters:**
- `familyId`: Unique identifier for family
- `mealId`: Meal being rated
- `rating`: 1-5 stars
- `notes`: Optional feedback text

**Returns:** `true` if successful

**Validation:**
- Rating must be 1-5

**Swift Signature:**
```swift
func rateMeal(
    familyId: UUID,
    mealId: UUID,
    rating: Int,
    notes: String?
) async throws -> Bool
```

---

#### `getFavoriteRecipes(familyId: UUID, minRating: Int, minOccurrences: Int) async throws -> [Recipe]`
Retrieves family's favorite recipes based on ratings and frequency.

**Parameters:**
- `familyId`: Unique identifier for family
- `minRating`: Minimum star rating (default 4)
- `minOccurrences`: Minimum times cooked (default 2)

**Returns:** Array of favorite recipes

**Swift Signature:**
```swift
func getFavoriteRecipes(
    familyId: UUID,
    minRating: Int = 4,
    minOccurrences: Int = 2
) async throws -> [Recipe]
```

---

### 3.7 Nutrition Analysis

#### `calculateNutrition(meal: PlannedMeal) async throws -> NutritionInfo`
Calculates nutritional information for a meal.

**Parameters:**
- `meal`: Planned meal to analyze

**Returns:** `NutritionInfo` object with calories, macros, vitamins

**External API:** USDA FoodData Central

**Swift Signature:**
```swift
func calculateNutrition(meal: PlannedMeal) async throws -> NutritionInfo
```

---

#### `validateWeeklyNutrition(plan: WeeklyMealPlan, guidelines: NutritionGuidelines?) async throws -> NutritionValidationResult`
Checks if weekly plan meets nutritional balance.

**Parameters:**
- `plan`: Weekly meal plan to validate
- `guidelines`: Optional custom guidelines (defaults to USDA MyPlate)

**Returns:** Validation result with recommendations

**Checks:**
- Protein variety (≥3 different sources)
- Vegetable servings (≥2 per dinner)
- Whole grains (≥3 times per week)
- Excessive sodium (flag if >2300mg average)

**Swift Signature:**
```swift
func validateWeeklyNutrition(
    plan: WeeklyMealPlan,
    guidelines: NutritionGuidelines?
) async throws -> NutritionValidationResult
```

---

### 3.8 Utility Functions

#### `scaleMeal(meal: PlannedMeal, targetServings: Int) -> PlannedMeal`
Adjusts ingredient quantities for different serving sizes (pure function).

**Parameters:**
- `meal`: Original meal
- `targetServings`: Desired number of servings

**Returns:** New meal with scaled ingredients

**Swift Signature:**
```swift
func scaleMeal(meal: PlannedMeal, targetServings: Int) -> PlannedMeal
```

---

#### `convertUnit(amount: Decimal, from: Unit, to: Unit) throws -> Decimal`
Converts ingredient measurements (pure function).

**Parameters:**
- `amount`: Quantity to convert
- `from`: Original unit
- `to`: Target unit

**Returns:** Converted amount

**Supported Conversions:**
- Volume: cup, tablespoon, teaspoon, fluid ounce, milliliter, liter
- Weight: ounce, pound, gram, kilogram
- Count: unit, dozen

**Errors:**
- `MealPlanningError.incompatibleUnits` (can't convert weight to volume without density)

**Swift Signature:**
```swift
func convertUnit(amount: Decimal, from: Unit, to: Unit) throws -> Decimal
```

---

#### `formatRecipeInstructions(recipe: Recipe) -> String`
Formats recipe steps into readable text (pure function).

**Parameters:**
- `recipe`: Recipe to format

**Returns:** Formatted multi-line string with numbered steps

**Swift Signature:**
```swift
func formatRecipeInstructions(recipe: Recipe) -> String
```

---

## 4. Deterministic Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│          User Request: Meal Planning Intent Detected        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │ Parse Intent & Extract │
            │ Parameters             │
            └────────┬───────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ "Plan week"  │ │ "Tonight?"   │ │ "Shopping"   │
│              │ │              │ │ "list"       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       ▼                ▼                ▼
┌──────────────────────────────┐ ┌──────────────────┐
│ Check: New User?             │ │ Check: Existing  │
│ (no meal history)            │ │ Active Plan?     │
└────┬────────────────┬────────┘ └────┬────────┬────┘
     │                │               │        │
     │ YES            │ NO            │ YES    │ NO
     ▼                ▼               ▼        ▼
┌──────────────┐ ┌──────────────┐ ┌────────┐ ┌──────────┐
│ ONBOARDING   │ │ RETURNING    │ │ Return │ │ Error:   │
│ FLOW         │ │ USER FLOW    │ │ List   │ │ No Plan  │
└──────┬───────┘ └──────┬───────┘ └────────┘ └──────────┘
       │                │
       ▼                ▼
┌──────────────────────────────────────────────┐
│ Ask: Family Size?                            │
│ - Auto-detect from family members if avail  │
│ - Default: 4 if no data                     │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Ask: Dietary Restrictions?                   │
│ - Check family member profiles              │
│ - Allow override/additions                  │
│ - Default: none                             │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Ask: Weekly Budget? (Optional)               │
│ - Default: no constraint                     │
│ - Suggested: $150 for family of 4           │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Save Preferences                             │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ MEAL PLAN GENERATION ENGINE                  │
│                                              │
│ Step 1: Load Context                         │
│ ├─ Family preferences                        │
│ ├─ Dietary restrictions                      │
│ ├─ Meal history (last 90 days)              │
│ ├─ Pantry inventory                          │
│ └─ Budget constraint                         │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 2: Determine Protein Schedule (7 days)  │
│                                              │
│ Algorithm:                                   │
│ FOR each day in week:                        │
│   proteins_used_last_14_days = history       │
│   yesterday_protein = day > 0 ? day-1 : null │
│                                              │
│   available_proteins = [chicken, beef,       │
│     vegetarian, seafood, pork] - yesterday   │
│                                              │
│   # Apply frequency limits                   │
│   FOR protein in available_proteins:         │
│     count = proteins_used_last_14_days[p]    │
│     IF count >= 4:                           │
│       available_proteins.remove(protein)     │
│                                              │
│   # Special day defaults                     │
│   IF day == FRIDAY:                          │
│     prefer [seafood, vegetarian]             │
│                                              │
│   selected = available_proteins.random()     │
│   schedule[day] = selected                   │
│                                              │
│ RETURN schedule                              │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 3: Determine Cuisine Schedule (7 days)  │
│                                              │
│ Algorithm:                                   │
│ user_preferences = ["italian", "mexican",    │
│   "asian", "american"]  # example            │
│ cuisines_this_week = []                      │
│                                              │
│ FOR each day in week:                        │
│   yesterday_cuisine = day > 0 ? day-1 : null │
│                                              │
│   available = user_preferences.filter(       │
│     c => c != yesterday_cuisine &&           │
│          cuisines_this_week.count(c) < 3     │
│   )                                          │
│                                              │
│   selected = available.random()              │
│   cuisines_this_week.append(selected)        │
│   schedule[day] = selected                   │
│                                              │
│ RETURN schedule                              │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 4: Select Past Favorites (2-3 meals)    │
│                                              │
│ favorites = getFavoriteRecipes(              │
│   familyId, minRating: 4, minOccurrences: 2  │
│ )                                            │
│                                              │
│ # Filter out recently cooked (last 14 days)  │
│ eligible = favorites.filter(                 │
│   recipe => !cooked_in_last_14_days(recipe)  │
│ )                                            │
│                                              │
│ selected_favorites = eligible.random(2-3)    │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 5: Search New Recipes (4-5 meals)       │
│                                              │
│ remaining_days = 7 - selected_favorites.count│
│                                              │
│ FOR each remaining day:                      │
│   criteria = RecipeSearchCriteria(           │
│     protein: protein_schedule[day],          │
│     cuisine: cuisine_schedule[day],          │
│     maxPrepTime: isWeekday(day) ? 30 : 90,   │
│     dietaryRestrictions: family.restrictions,│
│     excludeRecipeIds: already_planned_ids    │
│   )                                          │
│                                              │
│   candidates = searchRecipes(criteria)       │
│   filtered = filterRecipesByDietary(...)     │
│   ranked = rankRecipesByPreference(...)      │
│                                              │
│   selected = ranked.first()                  │
│   new_recipes.append(selected)               │
│                                              │
│ RETURN new_recipes                           │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 6: Assign Meals to Days                 │
│                                              │
│ all_meals = selected_favorites + new_recipes │
│                                              │
│ FOR day in [Monday...Sunday]:                │
│   constraints = DayConstraints(              │
│     protein: protein_schedule[day],          │
│     cuisine: cuisine_schedule[day],          │
│     maxTime: isWeekday(day) ? 30 : 90        │
│   )                                          │
│                                              │
│   matching = all_meals.filter(matches(...))  │
│   selected = matching.first()                │
│   weekly_plan[day] = selected                │
│   all_meals.remove(selected)                 │
│                                              │
│ RETURN weekly_plan                           │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 7: Plan Leftover Day (Optional)         │
│                                              │
│ IF budget_constraint OR user_preference:     │
│   # Select best candidate for leftovers      │
│   candidates = weekly_plan.filter(           │
│     meal => meal.scalable &&                 │
│              meal.day in [Sun, Mon, Tue]     │
│   )                                          │
│                                              │
│   best = candidates.max_by(                  │
│     meal => meal.rating                      │
│   )                                          │
│                                              │
│   leftover_day = best.day + 1                │
│   weekly_plan[leftover_day] = planLeftover(  │
│     originalMeal: best,                      │
│     servingsMultiplier: 1.5                  │
│   )                                          │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 8: Generate Grocery List                │
│                                              │
│ grocery_list = generateGroceryList(          │
│   meals: weekly_plan.meals,                  │
│   pantry: getPantryInventory(familyId)       │
│ )                                            │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 9: Estimate Cost                        │
│                                              │
│ cost_estimate = estimateGroceryCost(         │
│   list: grocery_list                         │
│ )                                            │
│                                              │
│ IF cost_estimate.total > budget:             │
│   optimized = optimizeGroceryListForBudget(  │
│     list: grocery_list,                      │
│     maxBudget: budget,                       │
│     meals: weekly_plan.meals                 │
│   )                                          │
│   grocery_list = optimized.list              │
│   cost_estimate = optimized.cost             │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 10: Validate Variety                    │
│                                              │
│ checks = [                                   │
│   uniqueProteins >= 3,                       │
│   uniqueCuisines >= 3,                       │
│   noConsecutiveRepeats,                      │
│   weekdayMealsUnder30Min                     │
│ ]                                            │
│                                              │
│ IF all checks pass:                          │
│   PROCEED                                    │
│ ELSE:                                        │
│   REGENERATE with stricter constraints       │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│ Step 11: Save & Return                       │
│                                              │
│ saveMealPlan(familyId, weekly_plan)          │
│                                              │
│ RETURN WeeklyMealPlan {                      │
│   meals: [...],                              │
│   groceryList: [...],                        │
│   estimatedCost: $XXX,                       │
│   nutritionSummary: {...}                    │
│ }                                            │
└──────────────────────────────────────────────┘
```

---

## 5. State Machine

### States

```
┌─────────────┐
│    IDLE     │ ◄─────────────────────┐
└──────┬──────┘                       │
       │                              │
       │ User: "Plan meals"           │
       ▼                              │
┌─────────────────────┐               │
│ GATHERING_CONTEXT   │               │
│ - Check new user?   │               │
│ - Load preferences  │               │
│ - Check history     │               │
└──────┬──────────────┘               │
       │                              │
       │ [New User]                   │
       ▼                              │
┌─────────────────────┐               │
│ ONBOARDING          │               │
│ - Ask family size   │               │
│ - Ask dietary       │               │
│ - Ask budget        │               │
└──────┬──────────────┘               │
       │                              │
       │ [Info Collected]             │
       ▼                              │
┌─────────────────────┐               │
│ GENERATING_PLAN     │               │
│ - Protein schedule  │               │
│ - Cuisine schedule  │               │
│ - Search recipes    │               │
│ - Assign to days    │               │
└──────┬──────────────┘               │
       │                              │
       │ [Plan Complete]              │
       ▼                              │
┌─────────────────────┐               │
│ GENERATING_GROCERY  │               │
│ - Extract ingredients│              │
│ - Check pantry      │               │
│ - Categorize items  │               │
└──────┬──────────────┘               │
       │                              │
       │ [List Ready]                 │
       ▼                              │
┌─────────────────────┐               │
│ ESTIMATING_COST     │               │
│ - Price lookup      │               │
│ - Calculate total   │               │
└──────┬──────────────┘               │
       │                              │
       │ [Cost Calculated]            │
       ▼                              │
┌─────────────────────┐               │
│ BUDGET_CHECK        │               │
│ - Compare to limit  │               │
└──────┬──────┬───────┘               │
       │      │                       │
   [OK]│      │[Over Budget]          │
       │      ▼                       │
       │  ┌─────────────────────┐    │
       │  │ OPTIMIZING_BUDGET   │    │
       │  │ - Find alternatives │    │
       │  │ - Suggest swaps     │    │
       │  └──────┬──────────────┘    │
       │         │                   │
       │         │ [Optimized]       │
       │         ▼                   │
       └───►┌─────────────────────┐  │
            │ AWAITING_APPROVAL   │  │
            │ - Show plan         │  │
            │ - Show cost         │  │
            │ - Ask confirm       │  │
            └──────┬──────┬───────┘  │
                   │      │          │
          [Approve]│      │[Reject]  │
                   │      ├──────────┘
                   │      │
                   │      ▼
                   │  ┌─────────────────────┐
                   │  │ REGENERATING        │
                   │  │ - Adjust constraints│
                   │  └──────┬──────────────┘
                   │         │
                   │         └─────►[Back to GENERATING_PLAN]
                   │
                   ▼
            ┌─────────────────────┐
            │ SAVING_PLAN         │
            │ - Persist to DB     │
            │ - Update history    │
            └──────┬──────────────┘
                   │
                   │ [Saved]
                   ▼
            ┌─────────────────────┐
            │ PLAN_READY          │
            │ - Return results    │
            │ - Set reminders     │
            └──────┬──────────────┘
                   │
                   │ [Complete]
                   ▼
            ┌─────────────────────┐
            │ IDLE                │
            └─────────────────────┘
```

### State Transitions (Swift Enum)

```swift
enum MealPlanningState: Equatable {
    case idle
    case gatheringContext(familyId: UUID)
    case onboarding(step: OnboardingStep)
    case generatingPlan(constraints: WeeklyPlanConstraints)
    case generatingGrocery(meals: [PlannedMeal])
    case estimatingCost(groceryList: GroceryList)
    case budgetCheck(cost: Decimal, budget: Decimal)
    case optimizingBudget(list: GroceryList, target: Decimal)
    case awaitingApproval(plan: WeeklyMealPlan)
    case regenerating(feedback: RegenerationReason)
    case savingPlan(plan: WeeklyMealPlan)
    case planReady(plan: WeeklyMealPlan)
    case error(MealPlanningError)
}

enum OnboardingStep {
    case familySize
    case dietaryRestrictions
    case budget
    case cuisinePreferences
}

enum RegenerationReason {
    case userRejected
    case lackOfVariety
    case budgetExceeded
    case missingDietaryFilter
}
```

### State Transition Logic

```swift
class MealPlanningStateMachine {
    private(set) var currentState: MealPlanningState = .idle

    func transition(to newState: MealPlanningState) {
        // Validate transition is legal
        guard isValidTransition(from: currentState, to: newState) else {
            print("Invalid state transition: \(currentState) -> \(newState)")
            return
        }

        currentState = newState
        handleStateEntry(newState)
    }

    private func isValidTransition(
        from: MealPlanningState,
        to: MealPlanningState
    ) -> Bool {
        switch (from, to) {
        case (.idle, .gatheringContext):
            return true
        case (.gatheringContext, .onboarding):
            return true
        case (.gatheringContext, .generatingPlan):
            return true
        case (.onboarding, .generatingPlan):
            return true
        case (.generatingPlan, .generatingGrocery):
            return true
        case (.generatingGrocery, .estimatingCost):
            return true
        case (.estimatingCost, .budgetCheck):
            return true
        case (.budgetCheck, .awaitingApproval):
            return true
        case (.budgetCheck, .optimizingBudget):
            return true
        case (.optimizingBudget, .awaitingApproval):
            return true
        case (.awaitingApproval, .savingPlan):
            return true
        case (.awaitingApproval, .regenerating):
            return true
        case (.regenerating, .generatingPlan):
            return true
        case (.savingPlan, .planReady):
            return true
        case (.planReady, .idle):
            return true
        case (_, .error):
            return true // Can always transition to error
        default:
            return false
        }
    }

    private func handleStateEntry(_ state: MealPlanningState) {
        // Trigger side effects when entering state
        switch state {
        case .gatheringContext(let familyId):
            Task {
                await loadFamilyContext(familyId)
            }
        case .generatingPlan(let constraints):
            Task {
                await executePlanGeneration(constraints)
            }
        case .savingPlan(let plan):
            Task {
                await persistPlan(plan)
            }
        default:
            break
        }
    }
}
```

---

## 6. Data Structures

### Core Models

```swift
// MARK: - Meal Preferences

struct MealPreferences: Codable {
    var familySize: Int
    var dietaryRestrictions: [DietaryRestriction]
    var weeklyBudget: Decimal?
    var cuisinePreferences: [String]
    var maxWeekdayPrepTime: Int // minutes
    var maxWeekendPrepTime: Int // minutes
    var leftoverPreference: LeftoverPreference
    var cookingSkillLevel: SkillLevel

    static var `default`: MealPreferences {
        MealPreferences(
            familySize: 4,
            dietaryRestrictions: [],
            weeklyBudget: nil,
            cuisinePreferences: ["american", "italian", "mexican", "asian"],
            maxWeekdayPrepTime: 30,
            maxWeekendPrepTime: 90,
            leftoverPreference: .occasionally,
            cookingSkillLevel: .intermediate
        )
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian
    case vegan
    case glutenFree = "gluten-free"
    case dairyFree = "dairy-free"
    case nutFree = "nut-free"
    case shellfishFree = "shellfish-free"
    case lowCarb = "low-carb"
    case lowSodium = "low-sodium"
    case kosher
    case halal
}

enum LeftoverPreference: String, Codable {
    case never
    case occasionally // 1x per week
    case frequently // 2x per week
    case always // maximize leftovers
}

enum SkillLevel: String, Codable {
    case beginner
    case intermediate
    case advanced
}

// MARK: - Recipe

struct Recipe: Codable, Identifiable {
    let id: UUID
    var externalId: Int? // Spoonacular ID
    var title: String
    var description: String?
    var cuisine: String
    var dishTypes: [String] // e.g., ["main course", "dinner"]
    var prepTime: Int // minutes
    var cookTime: Int // minutes
    var totalTime: Int // minutes
    var servings: Int
    var difficulty: SkillLevel
    var ingredients: [Ingredient]
    var instructions: [RecipeStep]
    var nutrition: NutritionInfo?
    var imageUrl: String?
    var sourceUrl: String?
    var tags: [String] // e.g., ["quick", "one-pot", "kid-friendly"]

    // Dietary flags
    var isVegetarian: Bool
    var isVegan: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
    var isNutFree: Bool

    // Computed properties
    var primaryProtein: ProteinType {
        // Determine from ingredients
        if ingredients.contains(where: { $0.isChicken }) {
            return .chicken
        } else if ingredients.contains(where: { $0.isBeef }) {
            return .beef
        } else if ingredients.contains(where: { $0.isSeafood }) {
            return .seafood
        } else if ingredients.contains(where: { $0.isPork }) {
            return .pork
        } else {
            return .vegetarian
        }
    }
}

struct Ingredient: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Decimal
    var unit: IngredientUnit
    var preparation: String? // e.g., "diced", "minced"
    var category: IngredientCategory
    var isOptional: Bool

    // Ingredient classification flags
    var isChicken: Bool {
        name.lowercased().contains("chicken")
    }
    var isBeef: Bool {
        name.lowercased().contains("beef") || name.lowercased().contains("steak")
    }
    var isSeafood: Bool {
        ["fish", "salmon", "tuna", "shrimp", "crab"].contains { name.lowercased().contains($0) }
    }
    var isPork: Bool {
        name.lowercased().contains("pork") || name.lowercased().contains("bacon")
    }
}

enum IngredientUnit: String, Codable {
    // Volume
    case cup, tablespoon, teaspoon, fluidOunce = "fl oz", milliliter, liter

    // Weight
    case ounce, pound, gram, kilogram

    // Count
    case unit, dozen, pinch, dash

    // Cans/Packages
    case can, package, jar, box
}

enum IngredientCategory: String, Codable {
    case produce
    case meat
    case seafood
    case dairy
    case bakery
    case pantry
    case frozen
    case condiments
    case spices
    case beverages
    case other
}

struct RecipeStep: Codable, Identifiable {
    let id: UUID
    var number: Int
    var instruction: String
    var estimatedMinutes: Int?
}

enum ProteinType: String, Codable {
    case chicken
    case beef
    case pork
    case seafood
    case vegetarian
    case eggs
}

// MARK: - Planned Meal

struct PlannedMeal: Codable, Identifiable {
    let id: UUID
    var recipe: Recipe
    var scheduledDate: Date
    var mealType: MealType
    var servings: Int
    var notes: String?
    var isLeftover: Bool
    var originalMealId: UUID? // If this is a leftover

    var dayOfWeek: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: scheduledDate)
        return DayOfWeek(rawValue: weekday) ?? .sunday
    }
}

enum MealType: String, Codable {
    case breakfast
    case lunch
    case dinner
    case snack
}

enum DayOfWeek: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var isWeekday: Bool {
        self != .saturday && self != .sunday
    }
}

// MARK: - Weekly Meal Plan

struct WeeklyMealPlan: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var weekStartDate: Date // Always Monday
    var meals: [PlannedMeal] // 7 dinners
    var groceryList: GroceryList
    var estimatedCost: CostEstimate
    var nutritionSummary: WeeklyNutritionSummary?
    var status: PlanStatus
    var createdAt: Date
    var updatedAt: Date

    var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
    }
}

enum PlanStatus: String, Codable {
    case draft
    case active
    case completed
    case archived
}

// MARK: - Grocery List

struct GroceryList: Codable, Identifiable {
    let id: UUID
    var items: [GroceryItem]
    var categorizedItems: [GroceryCategory: [GroceryItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }

    var totalItems: Int {
        items.count
    }
}

struct GroceryItem: Codable, Identifiable {
    let id: UUID
    var ingredient: Ingredient
    var quantity: Decimal
    var unit: IngredientUnit
    var category: GroceryCategory
    var estimatedPrice: Decimal?
    var isPurchased: Bool
    var notes: String?
}

enum GroceryCategory: String, Codable, CaseIterable {
    case produce
    case meatSeafood = "Meat & Seafood"
    case dairy = "Dairy & Eggs"
    case bakery
    case pantry = "Pantry Staples"
    case frozen
    case condiments = "Condiments & Spices"
    case beverages

    var sortOrder: Int {
        switch self {
        case .produce: return 1
        case .meatSeafood: return 2
        case .dairy: return 3
        case .bakery: return 4
        case .pantry: return 5
        case .frozen: return 6
        case .condiments: return 7
        case .beverages: return 8
        }
    }
}

// MARK: - Cost Estimation

struct CostEstimate: Codable {
    var itemCosts: [UUID: Decimal] // groceryItemId -> cost
    var subtotal: Decimal
    var tax: Decimal
    var total: Decimal
    var confidence: CostConfidence
    var lastUpdated: Date
}

enum CostConfidence: String, Codable {
    case high // Real-time API prices
    case medium // Cached prices (< 7 days old)
    case low // Estimated averages
}

// MARK: - Pantry

struct PantryItem: Codable, Identifiable {
    let id: UUID
    var name: String
    var quantity: Decimal
    var unit: IngredientUnit
    var category: IngredientCategory
    var purchaseDate: Date?
    var expirationDate: Date?
    var location: PantryLocation

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }

    var isLowStock: Bool {
        quantity <= 1.0
    }
}

enum PantryLocation: String, Codable {
    case pantry
    case refrigerator
    case freezer
    case spiceRack
}

struct PantryCheckResult: Codable {
    var availableIngredients: [Ingredient]
    var missingIngredients: [Ingredient]
    var insufficientIngredients: [(ingredient: Ingredient, have: Decimal, need: Decimal)]

    var matchPercentage: Double {
        let total = availableIngredients.count + missingIngredients.count + insufficientIngredients.count
        guard total > 0 else { return 0 }
        return Double(availableIngredients.count) / Double(total) * 100
    }
}

// MARK: - Nutrition

struct NutritionInfo: Codable {
    var calories: Int
    var protein: Decimal // grams
    var carbohydrates: Decimal // grams
    var fat: Decimal // grams
    var fiber: Decimal // grams
    var sugar: Decimal // grams
    var sodium: Decimal // milligrams
    var cholesterol: Decimal // milligrams

    // Micronutrients (optional)
    var vitaminA: Decimal?
    var vitaminC: Decimal?
    var calcium: Decimal?
    var iron: Decimal?
}

struct WeeklyNutritionSummary: Codable {
    var averageCaloriesPerMeal: Int
    var totalProtein: Decimal
    var totalCarbs: Decimal
    var totalFat: Decimal
    var averageSodium: Decimal
    var vegetableServings: Int
    var proteinVariety: [ProteinType]
}

struct NutritionGuidelines: Codable {
    var dailyCalories: Int
    var proteinGrams: Decimal
    var carbGrams: Decimal
    var fatGrams: Decimal
    var maxSodium: Decimal
    var minVegetableServings: Int

    static var usdaMyPlate: NutritionGuidelines {
        NutritionGuidelines(
            dailyCalories: 2000,
            proteinGrams: 50,
            carbGrams: 275,
            fatGrams: 78,
            maxSodium: 2300,
            minVegetableServings: 2
        )
    }
}

struct NutritionValidationResult: Codable {
    var isBalanced: Bool
    var warnings: [NutritionWarning]
    var recommendations: [String]
}

enum NutritionWarning: String, Codable {
    case lowProteinVariety
    case highSodium
    case insufficientVegetables
    case excessiveCalories
    case lowFiber
}

// MARK: - Meal History

struct MealHistoryEntry: Codable, Identifiable {
    let id: UUID
    var familyId: UUID
    var recipe: Recipe
    var cookedDate: Date
    var servings: Int
    var rating: Int? // 1-5 stars
    var notes: String?
    var photos: [String]? // URLs
    var actualCost: Decimal?
}

// MARK: - Search Criteria

struct RecipeSearchCriteria: Codable {
    var query: String?
    var cuisine: String?
    var protein: ProteinType?
    var maxPrepTime: Int?
    var maxTotalTime: Int?
    var dietaryRestrictions: [DietaryRestriction]
    var excludeRecipeIds: [UUID]
    var tags: [String]?
    var skillLevel: SkillLevel?
    var limit: Int = 10
}

struct WeeklyPlanConstraints: Codable {
    var familyId: UUID
    var familySize: Int
    var startDate: Date
    var dietaryRestrictions: [DietaryRestriction]
    var weeklyBudget: Decimal?
    var cuisinePreferences: [String]
    var maxWeekdayPrepTime: Int
    var maxWeekendPrepTime: Int
    var leftoverPreference: LeftoverPreference
    var excludeRecipeIds: [UUID]
}

struct SingleMealConstraints: Codable {
    var familyId: UUID
    var familySize: Int
    var date: Date
    var maxPrepTime: Int
    var dietaryRestrictions: [DietaryRestriction]
    var preferPantryIngredients: Bool
    var cuisine: String?
    var protein: ProteinType?
}

// MARK: - Optimization

struct OptimizedGroceryResult: Codable {
    var originalCost: Decimal
    var optimizedCost: Decimal
    var groceryList: GroceryList
    var substitutions: [Substitution]
    var savingsAmount: Decimal
}

struct Substitution: Codable, Identifiable {
    let id: UUID
    var original: GroceryItem
    var replacement: GroceryItem
    var reason: String
    var savingsAmount: Decimal
}

// MARK: - Errors

enum MealPlanningError: Error, LocalizedError {
    case familyNotFound
    case invalidPreferences
    case databaseError(String)
    case recipeNotFound
    case insufficientRecipes
    case budgetTooLow
    case apiError(String)
    case incompatibleUnits
    case invalidServingSize
    case pantryNotFound

    var errorDescription: String? {
        switch self {
        case .familyNotFound:
            return "Family profile not found"
        case .invalidPreferences:
            return "Invalid meal preferences provided"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .recipeNotFound:
            return "Recipe not found"
        case .insufficientRecipes:
            return "Not enough recipes match your criteria. Try relaxing some constraints."
        case .budgetTooLow:
            return "Weekly budget is too low to create a meal plan. Minimum $80 recommended for a family of 4."
        case .apiError(let message):
            return "External API error: \(message)"
        case .incompatibleUnits:
            return "Cannot convert between incompatible units"
        case .invalidServingSize:
            return "Serving size must be between 1 and 20"
        case .pantryNotFound:
            return "Pantry inventory not found"
        }
    }
}
```

---

## 7. Example Scenarios

### Scenario 1: New User - First Weekly Plan

**Context:**
- Sarah, new OpenClaw user
- Family: 2 adults, 2 kids (ages 7, 10)
- No meal history
- Daughter Emma is dairy-free

**User Input:**
```
"Plan dinners for this week"
```

**Execution Flow:**

**Step 1: Intent Detection**
```swift
let intent = await gemma3n.parseIntent("Plan dinners for this week")
// Result: { skill: "meal_planning", action: "generate_weekly_plan" }
```

**Step 2: Check User Status**
```swift
let preferences = try? await getFamilyPreferences(familyId: sarah.id)
// Result: nil (new user)
```

**Step 3: Onboarding**
```
Assistant: "I'd love to help plan your week! Quick setup:

How many people are you cooking for?"

User: "4 - me, my husband, and our two kids"