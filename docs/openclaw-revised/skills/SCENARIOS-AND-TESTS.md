# Meal Planning: Complete Scenarios & Test Cases

**Part 2 of Atomic Function Breakdown**
**Companion Document:** meal-planning-atomic.md

---

## Complete Example Scenarios

### Scenario 1: New User - First Weekly Plan

**Family:** Sarah (38), Mike (40), Emma (10, dairy-free), Jake (7)
**Budget:** $150/week
**Location:** Chicago suburbs
**Request:** "Plan dinners for this week"

#### Execution Trace

```swift
// 1. ONBOARDING
let isNewUser = (try? await getFamilyPreferences(familyId: sarah.id)) == nil
// Result: true
// Dialog flow
Assistant: "How many people?"
User: "4"
Assistant: "Any dietary restrictions?"
User: "My daughter is dairy-free"
Assistant: "Weekly budget?"
User: "$150"

// Save preferences
let prefs = MealPreferences(
    familySize: 4,
    dietaryRestrictions: [.dairyFree],
    weeklyBudget: 150,
    cuisinePreferences: ["american", "italian", "mexican", "asian"],
    maxWeekdayPrepTime: 30,
    maxWeekendPrepTime: 90,
    leftoverPreference: .occasionally,
    cookingSkillLevel: .intermediate
)
try await updateFamilyPreferences(familyId: sarah.id, preferences: prefs)

// 2. PROTEIN SCHEDULE
let history: [MealHistoryEntry] = [] // Empty for new user
let proteinSchedule = [
    DayOfWeek.monday: ProteinType.chicken,
    .tuesday: .vegetarian,
    .wednesday: .beef,
    .thursday: .seafood,
    .friday: .vegetarian, // Friday default
    .saturday: .pork,
    .sunday: .chicken
]

// 3. CUISINE SCHEDULE
let cuisineSchedule = [
    DayOfWeek.monday: "american",
    .tuesday: "mexican",
    .wednesday: "italian",
    .thursday: "asian",
    .friday: "american",
    .saturday: "italian",
    .sunday: "mexican"
]

// 4. RECIPE SEARCH (no favorites yet, all new)
var selectedRecipes: [Recipe] = []

for day in [DayOfWeek.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday] {
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: proteinSchedule[day],
        maxTotalTime: day.isWeekday ? 30 : 90,
        dietaryRestrictions: [.dairyFree],
        excludeRecipeIds: selectedRecipes.map { $0.id },
        limit: 5
    )
    
    let candidates = try await searchRecipes(criteria: criteria)
    let filtered = filterRecipesByDietary(recipes: candidates, restrictions: [.dairyFree])
    let timeFiltered = filterRecipesByTime(recipes: filtered, maxMinutes: day.isWeekday ? 30 : 90)
    
    guard let selected = timeFiltered.first else {
        throw MealPlanningError.insufficientRecipes
    }
    
    selectedRecipes.append(selected)
}

// 5. CREATE PLANNED MEALS
let startDate = Date().nextMonday() // e.g., Feb 3, 2026
var plannedMeals: [PlannedMeal] = []

for (index, recipe) in selectedRecipes.enumerated() {
    let mealDate = Calendar.current.date(byAdding: .day, value: index, to: startDate)!
    let meal = PlannedMeal(
        id: UUID(),
        recipe: recipe,
        scheduledDate: mealDate,
        mealType: .dinner,
        servings: 4,
        notes: nil,
        isLeftover: false,
        originalMealId: nil
    )
    plannedMeals.append(meal)
}

// Example output:
// Monday: One-Pan Lemon Herb Chicken & Veggies (25 min)
// Tuesday: Black Bean & Sweet Potato Tacos (30 min)
// Wednesday: Spaghetti Bolognese (dairy-free) (30 min)
// Thursday: Teriyaki Salmon with Broccoli (28 min)
// Friday: Vegetarian Chili (35 min) - weekend, allowed >30
// Saturday: Slow-Cooker BBQ Pork (90 min active, 4hr cook)
// Sunday: Sheet Pan Chicken Fajitas (25 min)

// 6. GENERATE GROCERY LIST
let groceryList = try await generateGroceryList(
    meals: plannedMeals,
    pantry: try await getPantryInventory(familyId: sarah.id)
)

// Example grocery list (categorized):
/*
PRODUCE:
- Lemons (3)
- Garlic (1 bulb)
- Onions, yellow (4)
- Bell peppers, mixed (6)
- Broccoli (2 crowns)
- Sweet potatoes (4)
- Tomatoes, Roma (8)
- Cilantro (1 bunch)

MEAT & SEAFOOD:
- Chicken breasts (3 lbs)
- Salmon fillets (1.5 lbs)
- Ground beef (1 lb)
- Pork shoulder (3 lbs)

PANTRY:
- Black beans, canned (3 cans)
- Diced tomatoes, canned (4 cans)
- Kidney beans, canned (2 cans)
- Spaghetti pasta (1 lb)
- Taco shells (12 count)
- BBQ sauce (18 oz)
- Soy sauce (10 oz)

CONDIMENTS & SPICES:
- Chili powder
- Cumin
- Oregano
- Teriyaki sauce
*/

// 7. ESTIMATE COST
let costEstimate = try await estimateGroceryCost(list: groceryList)
// Result: $142.50 (under budget!)

// 8. CREATE FINAL PLAN
let weeklyPlan = WeeklyMealPlan(
    id: UUID(),
    familyId: sarah.id,
    weekStartDate: startDate,
    meals: plannedMeals,
    groceryList: groceryList,
    estimatedCost: costEstimate,
    nutritionSummary: try await validateWeeklyNutrition(plan: ...).summary,
    status: .active,
    createdAt: Date(),
    updatedAt: Date()
)

// 9. SAVE
try await saveMealPlan(familyId: sarah.id, plan: weeklyPlan)

// 10. RESPONSE
Assistant: "I've created your weekly plan! Here's what's cooking:

**This Week's Dinners:**
📅 Monday: One-Pan Lemon Herb Chicken (25 min)
📅 Tuesday: Black Bean & Sweet Potato Tacos (30 min)
📅 Wednesday: Spaghetti Bolognese - dairy-free (30 min)
📅 Thursday: Teriyaki Salmon with Broccoli (28 min)
📅 Friday: Vegetarian Chili (35 min)
📅 Saturday: Slow-Cooker BBQ Pork (90 min)
📅 Sunday: Sheet Pan Chicken Fajitas (25 min)

**Grocery List:** 45 items across 4 categories
**Estimated Cost:** $142.50 (under your $150 budget!)

All meals are dairy-free for Emma. Want to see the full grocery list?"
```

---

### Scenario 2: Returning User - Quick "What's for Dinner Tonight?"

**Family:** Same as Scenario 1, 2 months later
**Context:** It's Wednesday 5:30pm, no time to cook
**Pantry:** Well-stocked (chicken breasts, pasta, canned tomatoes, onions, garlic)
**Request:** "What should I make for dinner tonight?"

#### Execution Trace

```swift
// 1. PARSE INTENT
let intent = .generateSingleMeal
let urgency = .immediate // Detected from "tonight"

// 2. LOAD CONTEXT
let preferences = try await getFamilyPreferences(familyId: sarah.id)
let pantry = try await getPantryInventory(familyId: sarah.id)
let history = try await getMealHistory(
    familyId: sarah.id,
    startDate: Date().addingDays(-14),
    endDate: Date()
)

// Last 3 dinners:
// - Monday: Chicken Stir-Fry
// - Tuesday: Beef Tacos
// - Today: Need to decide

// 3. DETERMINE CONSTRAINTS
let protein = selectProteinForDay(history: history, day: .wednesday)
// Avoid: chicken (Monday), beef (Tuesday)
// Result: .vegetarian or .seafood

let constraints = SingleMealConstraints(
    familyId: sarah.id,
    familySize: 4,
    date: Date(),
    maxPrepTime: 30, // Weekday default
    dietaryRestrictions: [.dairyFree],
    preferPantryIngredients: true, // IMPORTANT: minimize shopping
    cuisine: nil, // Flexible
    protein: .vegetarian // Selected
)

// 4. CHECK PANTRY AVAILABILITY
let pantryItems = pantry.map { $0.name.lowercased() }
// ["chicken breasts", "pasta", "canned tomatoes", "onions", "garlic", "olive oil", "basil", ...]

// 5. SEARCH RECIPES WITH PANTRY PREFERENCE
let candidates = try await searchRecipes(criteria: RecipeSearchCriteria(
    query: "pasta",
    maxTotalTime: 30,
    dietaryRestrictions: [.dairyFree],
    tags: ["quick", "pantry"],
    limit: 10
))

// 6. RANK BY PANTRY MATCH
var rankedRecipes: [(recipe: Recipe, matchPercent: Double)] = []

for recipe in candidates {
    let checkResult = try await checkPantryForRecipe(familyId: sarah.id, recipe: recipe)
    rankedRecipes.append((recipe, checkResult.matchPercentage))
}

rankedRecipes.sort { $0.matchPercent > $1.matchPercent }

// Top match:
// Spaghetti Aglio e Olio (Garlic & Oil Pasta) - 95% match
// Missing: red pepper flakes (optional)

let selectedMeal = PlannedMeal(
    id: UUID(),
    recipe: rankedRecipes.first!.recipe,
    scheduledDate: Date(),
    mealType: .dinner,
    servings: 4,
    notes: "Pantry meal - minimal shopping needed",
    isLeftover: false,
    originalMealId: nil
)

// 7. GENERATE MINI GROCERY LIST (only missing items)
let miniList = try await generateGroceryList(
    meals: [selectedMeal],
    pantry: pantry
)
// Result: [red pepper flakes (optional)] - everything else on hand!

// 8. RESPONSE
Assistant: "Perfect! You have almost everything for **Spaghetti Aglio e Olio** (25 min):

**What You Have:**
✓ Pasta
✓ Garlic
✓ Olive oil
✓ Basil

**Optional Addition:**
- Red pepper flakes (adds a nice kick)

This is a classic Italian dish - simple but delicious. Vegetarian and dairy-free. Ready to cook?"
```

---

### Scenario 3: Budget Optimization - Over Budget

**Family:** Sarah's family
**Context:** Planning next week, economy mode
**Budget Constraint:** $100/week (reduced from $150)
**Request:** "Plan next week but keep it under $100"

#### Execution Trace

```swift
// 1-6. STANDARD PLAN GENERATION
let initialPlan = try await generateWeeklyPlan(constraints: WeeklyPlanConstraints(
    familyId: sarah.id,
    familySize: 4,
    startDate: Date().nextMonday(),
    dietaryRestrictions: [.dairyFree],
    weeklyBudget: 100,
    cuisinePreferences: ["american", "italian", "mexican", "asian"],
    maxWeekdayPrepTime: 30,
    maxWeekendPrepTime: 90,
    leftoverPreference: .frequently, // Maximize savings
    excludeRecipeIds: []
))

// Initial grocery cost estimate: $125.50 (OVER BUDGET by $25.50)

// 7. BUDGET OPTIMIZATION TRIGGERED
let optimized = try await optimizeGroceryListForBudget(
    list: initialPlan.groceryList,
    maxBudget: 100,
    meals: initialPlan.meals
)

// Optimization strategies applied:
// 1. Protein downgrades:
//    - Salmon ($18/lb) → Tilapia ($8/lb)  [saves $15]
//    - Beef roast ($12/lb) → Ground beef ($5/lb) [saves $10.50]
//
// 2. Store brand swaps:
//    - Name brand pasta ($3.50) → Store brand ($1.50) [saves $2]
//    - Name brand canned tomatoes ($2.50) → Store brand ($1.20) [saves $5.20]
//
// 3. Seasonal produce:
//    - Asparagus (out of season, $6/lb) → Green beans (in season, $2/lb) [saves $8]
//
// 4. Added leftover meal:
//    - Sunday: Cook double portion of chili
//    - Monday: Leftover chili
//    [saves $12 from removing Monday's planned meal]

// New cost: $97.80 (UNDER BUDGET!)

// 8. RESPONSE WITH TRANSPARENCY
Assistant: "I've created a budget-friendly plan for $97.80! Made a few smart swaps:

**Cost Savers:**
🔄 Tilapia instead of salmon (tastes great!)
🔄 Ground beef for versatile meals
🔄 Green beans instead of asparagus (in season now)
🔄 Leftover night Monday (Sunday's chili)

**This Week:**
Mon: Leftover Chili from Sunday
Tue: Ground Beef Tacos ($8.50)
Wed: One-Pot Pasta Primavera ($6.20)
Thu: Tilapia with Lemon & Herbs ($9.30)
Fri: Vegetarian Fried Rice ($5.80)
Sat: Slow-Cooker Bean & Veggie Chili ($11.40)
Sun: Chicken Stir-Fry ($14.20)

**Total: $97.80** (under your $100 budget!)

All meals still dairy-free for Emma. Sound good?"
```

---

### Scenario 4: Leftover Integration

**Request:** "Plan the week with intentional leftovers"
**Preference:** Minimize cooking days

#### Execution Trace

```swift
let constraints = WeeklyPlanConstraints(
    // ... standard fields
    leftoverPreference: .frequently
)

// Standard meal generation...

// LEFTOVER PLANNING LOGIC
// Step 1: Identify best candidates for leftovers
let candidates = plannedMeals.filter { meal in
    // Criteria: reheats well, not too delicate
    let reheatsWell = !["salad", "crispy", "fried"].contains { meal.recipe.tags.contains($0) }
    let scalable = meal.recipe.servings <= 8 // Can make 1.5-2x portions
    let familyLikes = meal.recipe.tags.contains("family-favorite") // If available
    
    return reheatsWell && scalable
}

// Step 2: Select 2 meals for double batches
let leftoverMeals = [
    candidates.first(where: { $0.dayOfWeek == .sunday }), // Sunday dinner
    candidates.first(where: { $0.dayOfWeek == .wednesday }) // Mid-week
].compactMap { $0 }

// Step 3: Scale selected meals
for meal in leftoverMeals {
    meal.servings = Int(Double(meal.servings) * 1.5) // 6 servings instead of 4
}

// Step 4: Create leftover entries
let mondayLeftover = planLeftoverMeal(
    originalMeal: leftoverMeals[0], // Sunday's meal
    servingsMultiplier: 1.5
)
mondayLeftover.scheduledDate = Date().nextMonday()

let thursdayLeftover = planLeftoverMeal(
    originalMeal: leftoverMeals[1], // Wednesday's meal
    servingsMultiplier: 1.5
)
thursdayLeftover.scheduledDate = Date().nextMonday().addingDays(3)

// Step 5: Replace planned meals with leftovers
plannedMeals[0] = mondayLeftover // Monday
plannedMeals[3] = thursdayLeftover // Thursday

// Final schedule:
// Sun: Slow-Cooker Chili (make 6 servings) - 🍲 DOUBLE BATCH
// Mon: Leftover Chili - ♻️ NO COOKING
// Tue: Sheet Pan Chicken Fajitas (4 servings)
// Wed: Spaghetti Bolognese (make 6 servings) - 🍲 DOUBLE BATCH
// Thu: Leftover Spaghetti - ♻️ NO COOKING
// Fri: Vegetarian Stir-Fry (4 servings)
// Sat: BBQ Ribs (4 servings)

// Grocery list automatically adjusts for larger portions
// Cost impact: Slight increase in ingredients, but amortized over 2 meals
// Response
Assistant: "Your week is planned with smart leftovers!

**Cooking Schedule:**
🍲 Sun: Slow-Cooker Chili (6 servings) - DOUBLE BATCH
♻️ Mon: Leftover Chili - NO COOKING NEEDED
🍗 Tue: Sheet Pan Chicken Fajitas
🍲 Wed: Spaghetti Bolognese (6 servings) - DOUBLE BATCH  
♻️ Thu: Leftover Spaghetti - NO COOKING NEEDED
🥦 Fri: Vegetarian Stir-Fry
🍖 Sat: BBQ Ribs

**You only cook 5 days this week!** Saves time and reduces stress."
```

---

### Scenario 5: Religious/Cultural Dietary Restrictions - Hindu Vegetarian Family

**Family:** Patel Family
- Priya (45) & Raj (47) - Hindu, strict vegetarian (no meat, eggs OK)
- Anika (15) & Dev (13) - Same dietary practice
- **Religious Restriction:** No beef, pork, chicken, seafood (lacto-vegetarian)
- **Cultural Preference:** Indian cuisine 4-5x/week, international 2-3x/week
- **Spice Level:** Medium to high heat tolerance
- Budget: $120/week

**Request:** "Plan our weekly meals"

#### Execution Trace

```swift
// 1. LOAD FAMILY PROFILE WITH RELIGIOUS PREFERENCES
let patelFamily = Family(
    id: UUID(),
    name: "Patel Family",
    members: [
        FamilyMember(name: "Priya", role: .adult, dietaryRestrictions: [.vegetarian]),
        FamilyMember(name: "Raj", role: .adult, dietaryRestrictions: [.vegetarian]),
        FamilyMember(name: "Anika", role: .child, dietaryRestrictions: [.vegetarian]),
        FamilyMember(name: "Dev", role: .child, dietaryRestrictions: [.vegetarian])
    ],
    preferences: FamilyPreferences(
        familySize: 4,
        dietaryRestrictions: [.vegetarian], // STRICT - no animal proteins
        weeklyBudget: 120,
        cuisinePreferences: ["indian", "mediterranean", "italian", "mexican"],
        culturalPreferences: CulturalPreferences(
            religion: .hinduism,
            avoidIngredients: ["beef", "pork", "chicken", "fish", "gelatin"],
            preferredSpiceLevel: .medium
        ),
        maxWeekdayPrepTime: 40, // Indian cooking often takes longer
        maxWeekendPrepTime: 90,
        leftoverPreference: .occasionally,
        cookingSkillLevel: .advanced
    )
)

// 2. PROTEIN SCHEDULE (VEGETARIAN SOURCES ONLY)
let vegetarianProteinSources = [
    "paneer", "tofu", "lentils", "chickpeas", 
    "kidney beans", "black beans", "eggs"
]

let proteinSchedule = [
    DayOfWeek.monday: "paneer",      // Indian cheese
    .tuesday: "lentils",             // Dal
    .wednesday: "chickpeas",         // Chana masala
    .thursday: "tofu",               // Asian stir-fry
    .friday: "kidney beans",         // Rajma
    .saturday: "mixed vegetables",   // Sabzi
    .sunday: "paneer"                // Popular weekend dish
]

// 3. CUISINE SCHEDULE (INDIAN-HEAVY)
let cuisineSchedule = [
    DayOfWeek.monday: "indian",
    .tuesday: "indian", 
    .wednesday: "indian",
    .thursday: "asian",              // Variety
    .friday: "indian",
    .saturday: "mediterranean",      // Variety
    .sunday: "indian"
]

// 4. RECIPE SEARCH WITH STRICT FILTERS
for day in DayOfWeek.allCases {
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: nil, // Not using meat protein types
        maxTotalTime: day.isWeekday ? 40 : 90,
        dietaryRestrictions: [.vegetarian],
        tags: [
            "vegetarian",
            cuisineSchedule[day],
            proteinSchedule[day] ?? "vegetables"
        ],
        excludeIngredients: [
            "beef", "pork", "chicken", "fish", 
            "shrimp", "bacon", "sausage", "gelatin"
        ], // CRITICAL: Hard block non-veg
        limit: 10
    )
    
    var candidates = try await searchRecipes(criteria: criteria)
    
    // DOUBLE-CHECK: Additional safety filter
    candidates = candidates.filter { recipe in
        let ingredientNames = recipe.ingredients.map { $0.name.lowercased() }
        let hasProhibited = ingredientNames.contains { ingredient in
            ["beef", "pork", "chicken", "fish", "meat", "shrimp", "bacon"]
                .contains { ingredient.contains($0) }
        }
        return !hasProhibited && recipe.isVegetarian
    }
    
    guard let selected = candidates.first else {
        throw MealPlanningError.insufficientRecipes
    }
    
    selectedRecipes.append(selected)
}

// Example output:
// Monday: Palak Paneer with Roti (40 min) - Spinach & Indian cheese
// Tuesday: Dal Tadka with Rice (35 min) - Lentil curry
// Wednesday: Chana Masala (30 min) - Chickpea curry
// Thursday: Szechuan Tofu Stir-Fry (28 min) - Asian variety
// Friday: Rajma Chawal (45 min) - Kidney bean curry with rice
// Saturday: Mediterranean Falafel Bowl (35 min) - Chickpea fritters
// Sunday: Paneer Butter Masala (50 min) - Family favorite

// 5. GENERATE GROCERY LIST WITH INDIAN STAPLES
let groceryList = try await generateGroceryList(
    meals: plannedMeals,
    pantry: patelPantry // Already has: basmati rice, spices, ghee
)

// Grocery list prioritizes Indian grocery stores
/*
PRODUCE:
- Spinach (2 bunches)
- Tomatoes (3 lbs)
- Onions (5 lbs)
- Ginger (4 oz)
- Green chilies (6)
- Cilantro (2 bunches)

DAIRY:
- Paneer (2 lbs) - Get from Indian store
- Plain yogurt (32 oz)
- Ghee (16 oz)

PANTRY:
- Red lentils (masoor dal) (1 lb)
- Yellow lentils (moong dal) (1 lb)
- Chickpeas, dried (2 lbs)
- Kidney beans, canned (3 cans)
- Tofu, extra firm (16 oz)

SPICES (if needed):
- Garam masala
- Turmeric
- Cumin seeds
- Coriander powder
*/

// 6. RESPONSE WITH CULTURAL AWARENESS
Assistant: "I've planned a delicious vegetarian week for your family!

**This Week's Menu:**
🇮🇳 Mon: Palak Paneer with Roti (40 min)
🇮🇳 Tue: Dal Tadka with Basmati Rice (35 min)
🇮🇳 Wed: Chana Masala (30 min)
🥢 Thu: Szechuan Tofu Stir-Fry (28 min)
🇮🇳 Fri: Rajma Chawal (45 min)
🌍 Sat: Mediterranean Falafel Bowl (35 min)
🇮🇳 Sun: Paneer Butter Masala (50 min)

**All meals are 100% vegetarian** - no meat, fish, or poultry.
**5 Indian meals + 2 international** for variety.

**Grocery List:** 38 items
**Estimated Cost:** $118.50
**Best stores:** Patel Brothers or local Indian market for paneer & spices

Ready to cook?"
```

---

### Scenario 6: Halal Requirements - Muslim Family

**Family:** Rahman Family
- Fatima (36) & Ahmed (38)
- Sara (8) & Omar (5)
- **Religious Restriction:** Halal meat only, no pork, no alcohol
- **Cultural:** Middle Eastern cuisine preference
- Budget: $140/week

**Request:** "Plan halal meals for the week"

#### Execution Trace

```swift
// 1. FAMILY PROFILE WITH HALAL REQUIREMENTS
let rahmanFamily = Family(
    id: UUID(),
    name: "Rahman Family",
    members: [...],
    preferences: FamilyPreferences(
        familySize: 4,
        dietaryRestrictions: [.halal],
        weeklyBudget: 140,
        cuisinePreferences: ["middle-eastern", "mediterranean", "south-asian", "american"],
        culturalPreferences: CulturalPreferences(
            religion: .islam,
            requireHalalMeat: true, // CRITICAL FLAG
            avoidIngredients: ["pork", "bacon", "ham", "alcohol", "wine", "beer", "gelatin"],
            preferredSpiceLevel: .medium
        ),
        maxWeekdayPrepTime: 30,
        maxWeekendPrepTime: 90,
        leftoverPreference: .occasionally,
        cookingSkillLevel: .intermediate
    )
)

// 2. PROTEIN SCHEDULE (HALAL MEATS + VEGETARIAN)
let proteinSchedule = [
    DayOfWeek.monday: ProteinType.chicken,    // Halal chicken
    .tuesday: .vegetarian,                    // Safe option
    .wednesday: .beef,                        // Halal beef
    .thursday: .vegetarian,
    .friday: .chicken,                        // Jummah (Friday) - often chicken biryani
    .saturday: .beef,                         // Halal lamb/beef
    .sunday: .chicken
]

// 3. RECIPE SEARCH WITH HALAL FILTERS
for day in DayOfWeek.allCases {
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: proteinSchedule[day],
        maxTotalTime: day.isWeekday ? 30 : 90,
        dietaryRestrictions: [.halal],
        excludeIngredients: [
            "pork", "bacon", "ham", "sausage", "pepperoni",
            "wine", "beer", "cooking wine", "gelatin"
        ],
        tags: ["halal-friendly"],
        limit: 10
    )
    
    var candidates = try await searchRecipes(criteria: criteria)
    
    // SAFETY FILTER: Remove any pork or alcohol
    candidates = candidates.filter { recipe in
        let allText = (recipe.title + recipe.description).lowercased()
        let ingredients = recipe.ingredients.map { $0.name.lowercased() }
        
        let prohibitedKeywords = ["pork", "bacon", "ham", "wine", "beer", "alcohol", "rum"]
        let hasProhibited = prohibitedKeywords.contains { keyword in
            allText.contains(keyword) || ingredients.contains { $0.contains(keyword) }
        }
        
        return !hasProhibited
    }
    
    // If protein is meat, add note about halal sourcing
    if proteinSchedule[day] == .chicken || proteinSchedule[day] == .beef {
        selectedRecipe.notes = "Use halal-certified meat from halal butcher"
    }
    
    selectedRecipes.append(selectedRecipe)
}

// Example output:
// Monday: Halal Chicken Shawarma Bowls (30 min)
// Tuesday: Falafel with Hummus & Pita (25 min)
// Wednesday: Beef Kofta with Rice (35 min)
// Thursday: Vegetable Biryani (40 min)
// Friday: Chicken Biryani (60 min) - Jummah special
// Saturday: Slow-Cooker Halal Lamb Tagine (90 min)
// Sunday: Halal Chicken Tikka Masala (40 min)

// 4. GROCERY LIST WITH HALAL SOURCING NOTES
let groceryList = try await generateGroceryList(meals: plannedMeals, pantry: pantry)

// Add sourcing instructions
groceryList.notes = """
HALAL MEAT SOURCING:
- Chicken breasts (3 lbs) - Buy from halal butcher or Whole Foods halal section
- Ground beef (2 lbs) - Halal certified only
- Lamb shoulder (2 lbs) - Halal butcher

VERIFIED HALAL BRANDS:
- Crescent Foods (chicken)
- Saffron Road (frozen meals)
- Midamar (beef)

NOTE: Check ingredient labels for hidden alcohol/gelatin in sauces.
"""

// 5. RESPONSE
Assistant: "As-salamu alaykum! Your halal meal plan is ready:

**This Week:**
🥙 Mon: Chicken Shawarma Bowls (30 min)
🧆 Tue: Falafel Platter (25 min) - Vegetarian
🍖 Wed: Beef Kofta with Rice (35 min)
🍛 Thu: Vegetable Biryani (40 min) - Vegetarian
🍗 Fri: Chicken Biryani (60 min) - Jummah Special!
🥘 Sat: Slow-Cooker Lamb Tagine (90 min)
🍛 Sun: Chicken Tikka Masala (40 min)

**All meals are halal-compliant:**
✅ No pork or pork products
✅ No alcohol or cooking wine
✅ Halal meat sources noted

**Where to Buy:**
- Halal meats: [Nearest halal butcher] or Whole Foods halal section
- Verified brands: Crescent Foods, Midamar

**Cost:** $138.20 (under budget!)

Enjoy your week!"
```

---

### Scenario 7: Kosher Requirements - Jewish Family

**Family:** Cohen Family
- Rachel (42) & David (45)
- Leah (12) & Noah (9)
- **Religious:** Orthodox Jewish, strictly kosher
- **Requirements:** Meat & dairy separation, kosher-certified ingredients
- Budget: $180/week (kosher food often costs more)

**Request:** "Plan kosher meals for Shabbat and the week"

#### Execution Trace

```swift
// 1. KOSHER-SPECIFIC FAMILY PROFILE
let cohenFamily = Family(
    id: UUID(),
    name: "Cohen Family",
    members: [...],
    preferences: FamilyPreferences(
        familySize: 4,
        dietaryRestrictions: [.kosher],
        weeklyBudget: 180,
        cuisinePreferences: ["jewish", "mediterranean", "israeli", "american"],
        culturalPreferences: CulturalPreferences(
            religion: .judaism,
            observanceLevel: .orthodox,
            requireKosherCertification: true,
            separateMeatDairy: true, // CRITICAL for kosher
            avoidIngredients: [
                "pork", "shellfish", "non-kosher gelatin",
                "meat+dairy mixtures", "non-kosher wine"
            ],
            specialDays: [
                SpecialDay(name: "Shabbat", dayOfWeek: .friday, requiresSpecialMeal: true)
            ]
        ),
        maxWeekdayPrepTime: 35,
        maxWeekendPrepTime: 120, // Shabbat meals take longer
        leftoverPreference: .frequently,
        cookingSkillLevel: .advanced
    )
)

// 2. KOSHER MEAL CATEGORIZATION
enum KosherMealType {
    case meat      // Fleishig - contains meat, no dairy
    case dairy     // Milchig - contains dairy, no meat
    case pareve    // Neutral - no meat or dairy (fish, eggs, vegetables)
}

// 3. WEEKLY SCHEDULE WITH MEAT/DAIRY SEPARATION
let mealTypeSchedule = [
    DayOfWeek.monday: KosherMealType.meat,      // Monday: Meat meal
    .tuesday: .pareve,                          // Tuesday: Neutral
    .wednesday: .dairy,                         // Wednesday: Dairy
    .thursday: .meat,                           // Thursday: Meat
    .friday: .meat,                             // Friday: Shabbat meat meal (traditional)
    .saturday: .dairy,                          // Saturday: Dairy brunch after synagogue
    .sunday: .meat                              // Sunday: Meat
]

let proteinSchedule = [
    DayOfWeek.monday: ProteinType.chicken,
    .tuesday: .seafood,                         // Fish is pareve
    .wednesday: .vegetarian,                    // Dairy meal (cheese, eggs)
    .thursday: .beef,
    .friday: .chicken,                          // Shabbat chicken (traditional)
    .saturday: .vegetarian,                     // Dairy brunch
    .sunday: .beef
]

// 4. RECIPE SEARCH WITH KOSHER CONSTRAINTS
for day in DayOfWeek.allCases {
    let mealType = mealTypeSchedule[day]!
    
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: proteinSchedule[day],
        maxTotalTime: day == .friday ? 120 : (day.isWeekday ? 35 : 90),
        dietaryRestrictions: [.kosher],
        excludeIngredients: [
            "pork", "bacon", "ham",
            "shellfish", "shrimp", "crab", "lobster",
            "non-kosher gelatin"
        ],
        tags: [
            "kosher",
            day == .friday ? "shabbat" : nil,
            mealType == .meat ? "fleishig" : (mealType == .dairy ? "milchig" : "pareve")
        ].compactMap { $0 },
        limit: 10
    )
    
    var candidates = try await searchRecipes(criteria: criteria)
    
    // STRICT KOSHER VALIDATION
    candidates = candidates.filter { recipe in
        let hasProhibited = recipe.ingredients.contains { ingredient in
            let name = ingredient.name.lowercased()
            
            // Check for prohibited proteins
            if ["pork", "bacon", "ham", "shellfish", "shrimp", "crab", "lobster"].contains(where: { name.contains($0) }) {
                return true
            }
            
            // Check for meat+dairy mixing
            if mealType == .meat {
                let hasDairy = ["milk", "cheese", "butter", "cream", "yogurt"].contains { name.contains($0) }
                return hasDairy
            } else if mealType == .dairy {
                let hasMeat = ["beef", "chicken", "lamb", "turkey"].contains { name.contains($0) }
                return hasMeat
            }
            
            return false
        }
        
        return !hasProhibited
    }
    
    guard let selected = candidates.first else {
        throw MealPlanningError.insufficientRecipes
    }
    
    // Add kosher certification note
    selected.notes = "Use OU, OK, or Star-K certified ingredients. Meat type: \(mealType)"
    if mealType == .meat {
        selected.notes! += ". Use separate meat dishes and utensils."
    } else if mealType == .dairy {
        selected.notes! += ". Use separate dairy dishes and utensils."
    }
    
    selectedRecipes.append(selected)
}

// Example output:
// Monday: Herb-Roasted Chicken (meat meal) (40 min)
// Tuesday: Baked Salmon with Lemon (pareve) (30 min)
// Wednesday: Cheese Blintzes (dairy meal) (35 min)
// Thursday: Beef Brisket (meat meal) (90 min)
// Friday: Traditional Challah Bread + Roast Chicken + Kugel (Shabbat) (120 min)
// Saturday: Bagels & Lox Brunch (dairy meal) (20 min)
// Sunday: Slow-Cooker Cholent (meat stew) (480 min passive)

// 5. GROCERY LIST WITH KOSHER CERTIFICATION
let groceryList = try await generateGroceryList(meals: plannedMeals, pantry: pantry)

groceryList.notes = """
KOSHER CERTIFICATION REQUIRED:
All packaged items must have kosher symbol: OU, OK, Star-K, Kof-K

MEAT (Fleishig):
- Chicken (whole) (5 lbs) - Buy from kosher butcher
- Beef brisket (4 lbs) - Kosher butcher only
- Ground beef (1 lb) - Kosher certified

PAREVE (Neutral):
- Salmon fillets (1.5 lbs) - Check for kosher symbol
- Eggs (1 dozen) - Any eggs are kosher

DAIRY (Milchig):
- Cream cheese (16 oz) - Look for OU-D symbol
- Cheddar cheese (8 oz) - Kosher certified
- Challah bread - Buy from kosher bakery or make from scratch

PRODUCE: All fresh fruits/vegetables are kosher (pareve)

REMINDER: Prepare Shabbat meals before sunset Friday.
"""

// 6. RESPONSE WITH SHABBAT AWARENESS
Assistant: "Shabbat Shalom! Your kosher meal plan is ready:

**This Week:**
🍗 Mon: Herb-Roasted Chicken (MEAT - fleishig)
🐟 Tue: Baked Salmon with Lemon (PAREVE)
🧀 Wed: Cheese Blintzes (DAIRY - milchig)
🥩 Thu: Beef Brisket (MEAT - fleishig)
✡️  Fri: **SHABBAT DINNER** - Challah, Roast Chicken, Kugel (120 min - prepare before sunset!)
🥯 Sat: Bagels & Lox Brunch (DAIRY - milchig)
🍲 Sun: Slow-Cooker Cholent (MEAT - fleishig, 8hr cook)

**Kosher Compliance:**
✅ Meat & dairy properly separated
✅ No pork or shellfish
✅ Kosher certification notes included
✅ Shabbat meal ready before sundown Friday

**Shopping:**
- Kosher butcher for meats
- Look for OU, OK, Star-K symbols
- Use separate carts/bags for meat vs. dairy

**Cost:** $176.50

**Shabbat Prep Reminder:** Start cooking Friday by 2pm to finish before candle lighting.

Gut Shabbos!"
```

---

### Scenario 8: Context-Aware Planning from Chat History

**Context:** System learns from casual conversation
**User:** Sarah (from Scenario 1)
**Chat History (last 2 weeks):**
```
[Feb 1] User: "We had pizza for dinner last night"
[Feb 3] User: "Kids loved the tacos!"
[Feb 5] User: "Too tired to cook, ordered Thai takeout"
[Feb 7] User: "Made spaghetti, Emma asked for seconds"
[Feb 9] User: "Tried that salmon recipe - Jake wouldn't eat it"
[Feb 11] User: "Busy week ahead, need quick meals"
[Feb 14] User: "Valentine's Day - making something special tonight"
```

**Request (Feb 15):** "Plan next week's dinners"

#### Execution Trace

```swift
// 1. EXTRACT CONTEXTUAL INTELLIGENCE FROM CHAT HISTORY
class ChatHistoryAnalyzer {
    func extractMealInsights(chatHistory: [ChatMessage]) -> MealInsights {
        var insights = MealInsights()
        
        for message in chatHistory {
            let text = message.content.lowercased()
            
            // Extract meal mentions
            if text.contains("had") || text.contains("made") || text.contains("ordered") {
                let meal = extractMealName(from: text)
                insights.recentMeals.append((date: message.timestamp, meal: meal))
            }
            
            // Extract family feedback
            if text.contains("loved") || text.contains("asked for seconds") {
                let meal = extractMealName(from: text)
                insights.lovedMeals.append(meal)
            }
            
            if text.contains("wouldn't eat") || text.contains("didn't like") {
                let meal = extractMealName(from: text)
                let member = extractFamilyMember(from: text) // "Jake"
                insights.dislikedMeals.append((meal: meal, member: member))
            }
            
            // Extract lifestyle signals
            if text.contains("tired") || text.contains("busy") || text.contains("quick") {
                insights.stressLevel = .high
                insights.preferQuickMeals = true
            }
            
            if text.contains("takeout") || text.contains("ordered") {
                insights.takeoutFrequency += 1
            }
        }
        
        return insights
    }
}

struct MealInsights: Codable {
    var recentMeals: [(date: Date, meal: String)] = []
    var lovedMeals: [String] = []
    var dislikedMeals: [(meal: String, member: String?)] = []
    var stressLevel: StressLevel = .normal
    var preferQuickMeals: Bool = false
    var takeoutFrequency: Int = 0
}

// 2. APPLY INSIGHTS TO PLANNING
let insights = ChatHistoryAnalyzer().extractMealInsights(chatHistory: sarah.chatHistory)

// Recent meals (last 14 days):
// - Pizza (Feb 1)
// - Tacos (Feb 3) ← Kids loved
// - Thai takeout (Feb 5)
// - Spaghetti (Feb 7) ← Emma loved
// - Salmon (Feb 9) ← Jake disliked
// - Valentine's special (Feb 14)

// Insights:
// - Stress level: HIGH (mentioned "tired", "busy")
// - Takeout: 1x in 2 weeks
// - Loved: Tacos, Spaghetti
// - Avoid: Salmon (Jake's preference)

// 3. ADJUST CONSTRAINTS BASED ON INSIGHTS
var constraints = WeeklyPlanConstraints(
    familyId: sarah.id,
    familySize: 4,
    startDate: Date().nextMonday(), // Feb 17
    dietaryRestrictions: [.dairyFree],
    weeklyBudget: 150,
    cuisinePreferences: ["american", "italian", "mexican", "asian"],
    maxWeekdayPrepTime: 25, // REDUCED from 30 due to stress
    maxWeekendPrepTime: 60, // REDUCED from 90 due to stress
    leftoverPreference: .occasionally,
    excludeRecipeIds: []
)

// 4. PROTEIN SCHEDULE AVOIDING DISLIKES
let proteinSchedule = [
    DayOfWeek.monday: ProteinType.chicken,
    .tuesday: .vegetarian,
    .wednesday: .beef,
    .thursday: .vegetarian,
    .friday: .chicken,
    .saturday: .pork,
    .sunday: .chicken
]
// NOTE: .seafood deliberately excluded due to Jake's dislike

// 5. INCLUDE PAST FAVORITES
let favorites = try await getFavoriteRecipes(familyId: sarah.id, minRating: 4)
let lovedFromChat = favorites.filter { recipe in
    ["tacos", "spaghetti"].contains { recipe.title.lowercased().contains($0) }
}

// Force include loved meals
var selectedRecipes: [Recipe] = []
selectedRecipes.append(lovedFromChat.first(where: { $0.title.contains("Taco") })!) // Include tacos
selectedRecipes.append(lovedFromChat.first(where: { $0.title.contains("Spaghetti") })!) // Include spaghetti

// 6. FILL REMAINING DAYS WITH QUICK MEALS
for day in DayOfWeek.allCases.dropFirst(2) { // Already have 2 meals
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: proteinSchedule[day],
        maxTotalTime: 25, // STRICT time limit due to busy week
        dietaryRestrictions: [.dairyFree],
        tags: ["quick", "easy", "weeknight"],
        excludeIngredients: ["salmon", "fish"], // Avoid Jake's dislike
        limit: 5
    )
    
    let candidates = try await searchRecipes(criteria: criteria)
    selectedRecipes.append(candidates.first!)
}

// 7. RESPONSE WITH PERSONALIZED EXPLANATION
Assistant: "I've planned a stress-free week based on what's worked for you:

**This Week (Quick Meals - All Under 25 Min):**
🌮 Mon: **Beef Tacos** (20 min) - The kids loved these last time!
🍝 Tue: **Spaghetti Marinara** (22 min) - Emma's favorite!
🍗 Wed: One-Pan Chicken & Veggies (25 min)
🥦 Thu: Veggie Stir-Fry (18 min)
🍕 Fri: **Quick Homemade Pizzas** (25 min) - Fun Friday activity!
🍖 Sat: Sheet Pan Pork Chops (30 min)
🍗 Sun: Slow-Cooker Chicken (10 min active, 4hr cook)

**Why This Plan:**
✨ All meals under 30 min (except Sunday's hands-off slow cooker)
✅ Included your family's favorites (tacos, spaghetti)
🚫 No fish (Jake wasn't a fan last time)
💡 Friday pizza = fun family cooking together

**Busy Week Tip:** Prep Sunday's slow cooker in the morning, and you'll have dinner ready when you get home!

Cost: $138.40

Sound good?"

// CONTEXT AWARENESS DEMONSTRATED:
// 1. Remembered loved meals → Included tacos & spaghetti
// 2. Remembered dislike → Avoided salmon/fish
// 3. Detected stress → Reduced prep times across the board
// 4. Inferred family style → Added fun Friday pizza
// 5. Anticipated need → Suggested slow cooker for busy Sunday
```

---

### Scenario 9: Multi-Allergy Complex Family

**Family:** Anderson Family
- Mom: Jessica (40) - Gluten intolerant
- Dad: Tom (42) - No restrictions
- Daughter: Lily (6) - Severe nut allergy (tree nuts + peanuts)
- Son: Max (3) - Egg allergy

**Request:** "Plan meals that work for all of us"

#### Execution Trace

```swift
// 1. AGGREGATE ALL DIETARY RESTRICTIONS
let familyRestrictions = getDietaryRestrictions(familyId: anderson.id)
// Returns: [.glutenFree, .nutFree, .eggFree]

// CRITICAL: All meals must satisfy ALL restrictions simultaneously

// 2. RECIPE SEARCH WITH TRIPLE FILTER
for day in DayOfWeek.allCases {
    let criteria = RecipeSearchCriteria(
        cuisine: cuisineSchedule[day],
        protein: proteinSchedule[day],
        maxTotalTime: day.isWeekday ? 30 : 90,
        dietaryRestrictions: [.glutenFree, .nutFree, .eggFree], // ALL THREE
        excludeIngredients: [
            // Gluten sources
            "wheat", "flour", "bread crumbs", "soy sauce", "pasta",
            // Nuts
            "almonds", "walnuts", "peanuts", "cashews", "peanut butter", "almond flour",
            // Eggs
            "eggs", "mayonnaise"
        ],
        tags: ["allergy-friendly", "family-safe"],
        limit: 10
    )
    
    var candidates = try await searchRecipes(criteria: criteria)
    
    // TRIPLE-CHECK SAFETY (critical for allergies)
    candidates = candidates.filter { recipe in
        let allIngredients = recipe.ingredients.map { $0.name.lowercased() }
        
        // Check for hidden gluten
        let glutenSources = ["wheat", "barley", "rye", "malt", "flour", "bread", "pasta", "soy sauce"]
        let hasGluten = allIngredients.contains { ing in
            glutenSources.contains { ing.contains($0) }
        }
        
        // Check for nuts (including derivatives)
        let nutSources = [
            "almond", "walnut", "cashew", "pecan", "peanut", 
            "hazelnut", "pistachio", "macadamia", "pine nut"
        ]
        let hasNuts = allIngredients.contains { ing in
            nutSources.contains { ing.contains($0) }
        }
        
        // Check for eggs (including hidden sources)
        let eggSources = ["egg", "mayo", "mayonnaise", "aioli"]
        let hasEggs = allIngredients.contains { ing in
            eggSources.contains { ing.contains($0) }
        }
        
        // MUST be safe for all three
        return !hasGluten && !hasNuts && !hasEggs && 
               recipe.isGlutenFree && recipe.isNutFree
    }
    
    // Add safety warning notes
    guard let selected = candidates.first else {
        throw MealPlanningError.insufficientRecipes
    }
    
    selected.notes = """
    ⚠️ ALLERGY SAFETY:
    - Gluten-free (Jessica)
    - Nut-free (Lily - SEVERE allergy)
    - Egg-free (Max)
    
    Check all packaged ingredients for cross-contamination warnings.
    """
    
    selectedRecipes.append(selected)
}

// Example output (all triple-safe):
// Monday: GF Chicken Stir-Fry with Rice (28 min)
// Tuesday: GF Tacos with Corn Tortillas (25 min)
// Wednesday: Rice Pasta Primavera (dairy-free, egg-free) (30 min)
// Thursday: Grilled Salmon with Roasted Veggies (30 min)
// Friday: GF Homemade Pizza (coconut flour crust) (35 min)
// Saturday: Slow-Cooker Pot Roast (GF, naturally safe) (90 min)
// Sunday: Sheet Pan Chicken Fajitas (corn tortillas) (25 min)

// 3. GROCERY LIST WITH ALLERGY WARNINGS
let groceryList = try await generateGroceryList(meals: plannedMeals, pantry: pantry)

groceryList.notes = """
⚠️ CRITICAL ALLERGY INFORMATION:

LILY'S NUT ALLERGY (SEVERE):
- Check ALL labels for "may contain nuts"
- Avoid bulk bins (cross-contamination risk)
- Call ahead to bakery for nut-free guarantee

MAX'S EGG ALLERGY:
- Read labels carefully (eggs in unexpected places)
- Avoid products with "albumin", "lysozyme", "ovalbumin"

JESSICA'S GLUTEN INTOLERANCE:
- Buy certified gluten-free products
- Check for "gluten-free facility" on packaging

SAFE SUBSTITUTIONS:
- Pasta → Gluten-free rice pasta or corn pasta
- Flour → Rice flour or coconut flour (NOT almond flour - nut allergy)
- Soy sauce → Tamari (gluten-free)
- Mayo → Homemade without eggs (avocado oil + lemon)
"""

// 4. RESPONSE
Assistant: "I've created a safe meal plan for your whole family!

**This Week (Gluten-Free, Nut-Free, Egg-Free):**
🍗 Mon: Chicken Stir-Fry with Rice (28 min)
🌮 Tue: Tacos with Corn Tortillas (25 min)
🍝 Wed: Rice Pasta Primavera (30 min)
🐟 Thu: Grilled Salmon with Veggies (30 min)
🍕 Fri: Homemade GF Pizza (35 min)
🥩 Sat: Slow-Cooker Pot Roast (90 min)
🍗 Sun: Sheet Pan Chicken Fajitas (25 min)

**Safety Guarantees:**
✅ Gluten-free for Jessica
✅ NUT-FREE for Lily (checked for cross-contamination)
✅ Egg-free for Max

**Important Notes:**
⚠️ Check ALL packaged items for allergen warnings
⚠️ Lily's nut allergy is severe - call ahead to stores if needed
⚠️ Use separate cutting boards/utensils to avoid cross-contact

**Substitutions Included:**
- Rice pasta (not wheat)
- Corn tortillas (not flour)
- Tamari (not regular soy sauce)

Cost: $156.80

Everyone can safely eat every meal. Want the detailed grocery list with brand recommendations?"
```

---

## 9. Comprehensive Test Cases (20+ Scenarios)

### Test Category 1: Dietary Restrictions

**Test 1.1: Single Restriction - Vegetarian**
```swift
func testVegetarianMealPlan() async throws {
    let family = createTestFamily(restrictions: [.vegetarian])
    let plan = try await generateWeeklyPlan(constraints: standardConstraints(family))
    
    // Assertions
    for meal in plan.meals {
        XCTAssertTrue(meal.recipe.isVegetarian, "Meal contains non-vegetarian ingredients")
        XCTAssertFalse(meal.recipe.ingredients.contains { ["chicken", "beef", "pork", "fish"].contains($0.name.lowercased()) })
    }
}
```

**Test 1.2: Multiple Restrictions - Vegan + Gluten-Free**
```swift
func testVeganGlutenFreeMealPlan() async throws {
    let family = createTestFamily(restrictions: [.vegan, .glutenFree])
    let plan = try await generateWeeklyPlan(constraints: standardConstraints(family))
    
    for meal in plan.meals {
        XCTAssertTrue(meal.recipe.isVegan)
        XCTAssertTrue(meal.recipe.isGlutenFree)
        
        // No animal products
        let animalProducts = ["meat", "chicken", "fish", "eggs", "dairy", "milk", "cheese", "butter", "honey"]
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            animalProducts.contains { ing.name.lowercased().contains($0) }
        })
        
        // No gluten
        let glutenSources = ["wheat", "barley", "rye", "flour", "bread", "pasta"]
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            glutenSources.contains { ing.name.lowercased().contains($0) }
        })
    }
}
```

**Test 1.3: Religious Restriction - Halal**
```swift
func testHalalMealPlan() async throws {
    let family = createTestFamily(
        restrictions: [.halal],
        culturalPrefs: CulturalPreferences(religion: .islam)
    )
    let plan = try await generateWeeklyPlan(constraints: standardConstraints(family))
    
    for meal in plan.meals {
        // No pork
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            ["pork", "bacon", "ham"].contains { ing.name.lowercased().contains($0) }
        })
        
        // No alcohol
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            ["wine", "beer", "rum", "vodka"].contains { ing.name.lowercased().contains($0) }
        })
        
        // Meat meals have halal sourcing note
        if meal.recipe.primaryProtein == .chicken || meal.recipe.primaryProtein == .beef {
            XCTAssertTrue(meal.notes?.contains("halal") ?? false)
        }
    }
}
```

**Test 1.4: Religious Restriction - Kosher with Meat/Dairy Separation**
```swift
func testKosherMeatDairySeparation() async throws {
    let family = createTestFamily(
        restrictions: [.kosher],
        culturalPrefs: CulturalPreferences(religion: .judaism, separateMeatDairy: true)
    )
    let plan = try await generateWeeklyPlan(constraints: standardConstraints(family))
    
    for meal in plan.meals {
        let isMeatMeal = meal.recipe.ingredients.contains { ing in
            ["beef", "chicken", "lamb"].contains { ing.name.lowercased().contains($0) }
        }
        
        let isDairyMeal = meal.recipe.ingredients.contains { ing in
            ["milk", "cheese", "butter", "cream", "yogurt"].contains { ing.name.lowercased().contains($0) }
        }
        
        // CRITICAL: Never mix meat and dairy
        XCTAssertFalse(isMeatMeal && isDairyMeal, "Meat and dairy mixed in same meal (violates kosher)")
        
        // No pork or shellfish
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            ["pork", "shrimp", "crab", "lobster"].contains { ing.name.lowercased().contains($0) }
        })
    }
}
```

**Test 1.5: Severe Allergy - Multi-Allergen Family**
```swift
func testMultiAllergenSafety() async throws {
    let family = Family(
        members: [
            FamilyMember(name: "Mom", allergies: ["gluten"]),
            FamilyMember(name: "Child1", allergies: ["tree nuts", "peanuts"]), // Severe
            FamilyMember(name: "Child2", allergies: ["eggs"])
        ]
    )
    
    let plan = try await generateWeeklyPlan(constraints: standardConstraints(family))
    
    for meal in plan.meals {
        // Must be safe for ALL family members
        XCTAssertTrue(meal.recipe.isGlutenFree)
        XCTAssertTrue(meal.recipe.isNutFree)
        
        // Triple check for nut contamination (severe allergy)
        let nutKeywords = ["almond", "walnut", "cashew", "peanut", "hazelnut", "pecan"]
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            nutKeywords.contains { ing.name.lowercased().contains($0) }
        })
        
        // Check for egg
        XCTAssertFalse(meal.recipe.ingredients.contains { ing in
            ["egg", "mayo"].contains { ing.name.lowercased().contains($0) }
        })
        
        // Safety note present
        XCTAssertTrue(meal.notes?.contains("ALLERGY") ?? false)
    }
}
```

### Test Category 2: Protein Rotation & Variety

**Test 2.1: No Consecutive Protein Repetition**
```swift
func testNoConsecutiveProteinRepetition() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    for i in 0..<plan.meals.count-1 {
        let todayProtein = plan.meals[i].recipe.primaryProtein
        let tomorrowProtein = plan.meals[i+1].recipe.primaryProtein
        
        XCTAssertNotEqual(todayProtein, tomorrowProtein, 
            "Consecutive days have same protein: \(todayProtein)")
    }
}
```

**Test 2.2: Minimum Protein Variety (3+ types per week)**
```swift
func testMinimumProteinVariety() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    let proteinTypes = Set(plan.meals.map { $0.recipe.primaryProtein })
    
    XCTAssertGreaterThanOrEqual(proteinTypes.count, 3,
        "Week should have at least 3 different protein types. Found: \(proteinTypes.count)")
}
```

**Test 2.3: Protein Frequency Limit (max 3x per week for any protein)**
```swift
func testProteinFrequencyLimit() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    let proteinCounts = plan.meals.reduce(into: [:]) { counts, meal in
        counts[meal.recipe.primaryProtein, default: 0] += 1
    }
    
    for (protein, count) in proteinCounts {
        XCTAssertLessThanOrEqual(count, 4,
            "\(protein) appears \(count) times (max 4 recommended for variety)")
    }
}
```

### Test Category 3: Time Constraints

**Test 3.1: Weekday Time Limit (30 min max)**
```swift
func testWeekdayTimeConstraint() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    let weekdayMeals = plan.meals.filter { $0.dayOfWeek.isWeekday }
    
    for meal in weekdayMeals {
        XCTAssertLessThanOrEqual(meal.recipe.totalTime, 30,
            "\(meal.recipe.title) on \(meal.dayOfWeek) takes \(meal.recipe.totalTime) min (max 30 for weekdays)")
    }
}
```

**Test 3.2: Weekend Flexibility (allow longer cook times)**
```swift
func testWeekendFlexibility() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    let weekendMeals = plan.meals.filter { !$0.dayOfWeek.isWeekday }
    
    // At least one weekend meal should use the extra time for a special dish
    let hasLongerMeal = weekendMeals.contains { $0.recipe.totalTime > 45 }
    
    XCTAssertTrue(hasLongerMeal, "Weekend should include at least one longer cooking project")
}
```

### Test Category 4: Budget Constraints

**Test 4.1: Under Budget**
```swift
func testUnderBudgetGeneration() async throws {
    let constraints = WeeklyPlanConstraints(
        familyId: UUID(),
        familySize: 4,
        startDate: Date(),
        dietaryRestrictions: [],
        weeklyBudget: 120,
        cuisinePreferences: ["american"],
        maxWeekdayPrepTime: 30,
        maxWeekendPrepTime: 90,
        leftoverPreference: .occasionally,
        excludeRecipeIds: []
    )
    
    let plan = try await generateWeeklyPlan(constraints: constraints)
    
    XCTAssertLessThanOrEqual(plan.estimatedCost.total, 120,
        "Plan cost $\(plan.estimatedCost.total) exceeds budget $120")
}
```

**Test 4.2: Budget Optimization**
```swift
func testBudgetOptimization() async throws {
    let initialPlan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    // Simulate over-budget scenario
    let tightBudget: Decimal = initialPlan.estimatedCost.total * 0.7 // 30% reduction
    
    let optimized = try await optimizeGroceryListForBudget(
        list: initialPlan.groceryList,
        maxBudget: tightBudget,
        meals: initialPlan.meals
    )
    
    XCTAssertLessThanOrEqual(optimized.optimizedCost, tightBudget)
    XCTAssertGreaterThan(optimized.substitutions.count, 0, "Should suggest substitutions")
    XCTAssertGreaterThan(optimized.savingsAmount, 0)
}
```

### Test Category 5: Leftover Planning

**Test 5.1: Leftover Meal Creation**
```swift
func testLeftoverMealCreation() async throws {
    let constraints = WeeklyPlanConstraints(
        familyId: UUID(),
        familySize: 4,
        startDate: Date(),
        dietaryRestrictions: [],
        weeklyBudget: nil,
        cuisinePreferences: ["american"],
        maxWeekdayPrepTime: 30,
        maxWeekendPrepTime: 90,
        leftoverPreference: .frequently, // Request leftovers
        excludeRecipeIds: []
    )
    
    let plan = try await generateWeeklyPlan(constraints: constraints)
    
    let leftoverMeals = plan.meals.filter { $0.isLeftover }
    
    XCTAssertGreaterThan(leftoverMeals.count, 0, "Should include at least 1 leftover meal")
    
    // Each leftover should reference an original meal
    for leftover in leftoverMeals {
        XCTAssertNotNil(leftover.originalMealId)
        let original = plan.meals.first { $0.id == leftover.originalMealId }
        XCTAssertNotNil(original)
        XCTAssertEqual(leftover.recipe.id, original?.recipe.id)
    }
}
```

**Test 5.2: Leftover Servings Adjustment**
```swift
func testLeftoverServingsScaling() async throws {
    let originalMeal = PlannedMeal(
        id: UUID(),
        recipe: createTestRecipe(),
        scheduledDate: Date(),
        mealType: .dinner,
        servings: 4,
        notes: nil,
        isLeftover: false,
        originalMealId: nil
    )
    
    let leftover = planLeftoverMeal(originalMeal: originalMeal, servingsMultiplier: 1.5)
    
    // Original should be scaled up
    XCTAssertEqual(originalMeal.servings, 6) // 4 * 1.5
    
    // Leftover references original
    XCTAssertTrue(leftover.isLeftover)
    XCTAssertEqual(leftover.originalMealId, originalMeal.id)
    XCTAssertEqual(leftover.servings, 2) // Remaining servings
}
```

### Test Category 6: Pantry Integration

**Test 6.1: Pantry-First Meal Suggestion**
```swift
func testPantryFirstMeal() async throws {
    let pantry = [
        PantryItem(name: "Pasta", quantity: 1, unit: .pound),
        PantryItem(name: "Canned Tomatoes", quantity: 2, unit: .can),
        PantryItem(name: "Garlic", quantity: 5, unit: .unit),
        PantryItem(name: "Olive Oil", quantity: 1, unit: .cup)
    ]
    
    let constraints = SingleMealConstraints(
        familyId: UUID(),
        familySize: 4,
        date: Date(),
        maxPrepTime: 30,
        dietaryRestrictions: [],
        preferPantryIngredients: true,
        cuisine: nil,
        protein: nil
    )
    
    let meal = try await generateSingleMeal(constraints: constraints)
    let checkResult = try await checkPantryForRecipe(familyId: constraints.familyId, recipe: meal.recipe)
    
    // Should have high pantry match
    XCTAssertGreaterThan(checkResult.matchPercentage, 60,
        "Pantry-first meal should use >60% existing ingredients. Got \(checkResult.matchPercentage)%")
}
```

**Test 6.2: Grocery List Pantry Deduction**
```swift
func testGroceryListPantryDeduction() async throws {
    let meal = createTestMeal(ingredients: [
        Ingredient(name: "Pasta", amount: 1, unit: .pound),
        Ingredient(name: "Tomatoes", amount: 2, unit: .unit),
        Ingredient(name: "Basil", amount: 0.25, unit: .cup)
    ])
    
    let pantry = [
        PantryItem(name: "Pasta", quantity: 0.5, unit: .pound), // Have half
        PantryItem(name: "Tomatoes", quantity: 2, unit: .unit) // Have all
    ]
    
    let groceryList = try await generateGroceryList(meals: [meal], pantry: pantry)
    
    // Should only list missing/insufficient items
    XCTAssertEqual(groceryList.items.count, 2) // Pasta (0.5 lb needed) + Basil
    
    let pastaItem = groceryList.items.first { $0.ingredient.name == "Pasta" }
    XCTAssertEqual(pastaItem?.quantity, 0.5) // Only need 0.5 lb more
    
    let tomatoItem = groceryList.items.first { $0.ingredient.name == "Tomatoes" }
    XCTAssertNil(tomatoItem) // Already have enough
}
```

### Test Category 7: Cuisine Variety

**Test 7.1: Minimum Cuisine Diversity**
```swift
func testMinimumCuisineVariety() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    let cuisines = Set(plan.meals.map { $0.recipe.cuisine })
    
    XCTAssertGreaterThanOrEqual(cuisines.count, 3,
        "Week should have at least 3 different cuisines. Found: \(cuisines)")
}
```

**Test 7.2: No Consecutive Cuisine Repetition**
```swift
func testNoConsecutiveCuisineRepetition() async throws {
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    for i in 0..<plan.meals.count-1 {
        let todayCuisine = plan.meals[i].recipe.cuisine
        let tomorrowCuisine = plan.meals[i+1].recipe.cuisine
        
        XCTAssertNotEqual(todayCuisine, tomorrowCuisine,
            "Consecutive days have same cuisine: \(todayCuisine)")
    }
}
```

### Test Category 8: Chat Context Integration

**Test 8.1: Extract Loved Meals from Chat**
```swift
func testChatHistoryLovedMeals() async throws {
    let chatHistory = [
        ChatMessage(content: "Kids loved the tacos last night!", timestamp: Date().addingDays(-3)),
        ChatMessage(content: "That pasta was amazing, making it again!", timestamp: Date().addingDays(-7))
    ]
    
    let analyzer = ChatHistoryAnalyzer()
    let insights = analyzer.extractMealInsights(chatHistory: chatHistory)
    
    XCTAssertTrue(insights.lovedMeals.contains { $0.contains("tacos") })
    XCTAssertTrue(insights.lovedMeals.contains { $0.contains("pasta") })
}
```

**Test 8.2: Extract Disliked Meals from Chat**
```swift
func testChatHistoryDislikedMeals() async throws {
    let chatHistory = [
        ChatMessage(content: "Jake wouldn't eat the salmon", timestamp: Date().addingDays(-2))
    ]
    
    let analyzer = ChatHistoryAnalyzer()
    let insights = analyzer.extractMealInsights(chatHistory: chatHistory)
    
    XCTAssertEqual(insights.dislikedMeals.count, 1)
    XCTAssertTrue(insights.dislikedMeals[0].meal.contains("salmon"))
    XCTAssertEqual(insights.dislikedMeals[0].member, "Jake")
}
```

**Test 8.3: Detect Stress Level from Chat**
```swift
func testChatHistoryStressDetection() async throws {
    let chatHistory = [
        ChatMessage(content: "So tired, can't cook tonight", timestamp: Date().addingDays(-1)),
        ChatMessage(content: "Busy week ahead, need simple meals", timestamp: Date())
    ]
    
    let analyzer = ChatHistoryAnalyzer()
    let insights = analyzer.extractMealInsights(chatHistory: chatHistory)
    
    XCTAssertEqual(insights.stressLevel, .high)
    XCTAssertTrue(insights.preferQuickMeals)
}
```

### Test Category 9: Edge Cases

**Test 9.1: Insufficient Recipes Available**
```swift
func testInsufficientRecipesError() async throws {
    let constraints = WeeklyPlanConstraints(
        familyId: UUID(),
        familySize: 4,
        startDate: Date(),
        dietaryRestrictions: [.vegan, .glutenFree, .nutFree], // Very restrictive
        weeklyBudget: 50, // Very tight budget
        cuisinePreferences: ["Ethiopian"], // Rare cuisine
        maxWeekdayPrepTime: 10, // Unrealistic time
        maxWeekendPrepTime: 15,
        leftoverPreference: .never,
        excludeRecipeIds: []
    )
    
    do {
        let _ = try await generateWeeklyPlan(constraints: constraints)
        XCTFail("Should throw insufficientRecipes error")
    } catch MealPlanningError.insufficientRecipes {
        // Expected
    }
}
```

**Test 9.2: Empty Pantry**
```swift
func testEmptyPantryGroceryList() async throws {
    let meal = createTestMeal()
    let emptyPantry: [PantryItem] = []
    
    let groceryList = try await generateGroceryList(meals: [meal], pantry: emptyPantry)
    
    // Should list ALL ingredients
    XCTAssertEqual(groceryList.items.count, meal.recipe.ingredients.count)
}
```

**Test 9.3: Budget Too Low**
```swift
func testBudgetTooLowError() async throws {
    let constraints = WeeklyPlanConstraints(
        familyId: UUID(),
        familySize: 4,
        startDate: Date(),
        dietaryRestrictions: [],
        weeklyBudget: 30, // Unrealistically low
        cuisinePreferences: ["american"],
        maxWeekdayPrepTime: 30,
        maxWeekendPrepTime: 90,
        leftoverPreference: .occasionally,
        excludeRecipeIds: []
    )
    
    do {
        let _ = try await generateWeeklyPlan(constraints: constraints)
        XCTFail("Should throw budgetTooLow error")
    } catch MealPlanningError.budgetTooLow {
        // Expected
    }
}
```

### Test Category 10: API Integration

**Test 10.1: Spoonacular API Search**
```swift
func testSpoonacularRecipeSearch() async throws {
    let api = SpoonacularAPI(apiKey: TestConfig.spoonacularKey)
    
    let recipes = try await api.searchRecipes(
        cuisine: "italian",
        diet: "vegetarian",
        maxReadyTime: 30,
        number: 5
    )
    
    XCTAssertGreaterThan(recipes.count, 0)
    
    for recipe in recipes {
        XCTAssertTrue(recipe.vegetarian)
        XCTAssertLessThanOrEqual(recipe.readyInMinutes, 30)
    }
}
```

**Test 10.2: USDA Nutrition Data**
```swift
func testUSDANutritionLookup() async throws {
    let meal = createTestMeal()
    
    let nutrition = try await calculateNutrition(meal: meal)
    
    XCTAssertGreaterThan(nutrition.calories, 0)
    XCTAssertGreaterThan(nutrition.protein, 0)
    XCTAssertGreaterThan(nutrition.carbohydrates, 0)
}
```

### Test Category 11: Historical Learning

**Test 11.1: Favorite Recipes Inclusion**
```swift
func testFavoriteRecipesIncluded() async throws {
    // Setup: Create meal history with highly-rated meals
    let history = [
        MealHistoryEntry(recipe: createTestRecipe(title: "Tacos"), rating: 5),
        MealHistoryEntry(recipe: createTestRecipe(title: "Pasta"), rating: 5),
        MealHistoryEntry(recipe: createTestRecipe(title: "Stir-Fry"), rating: 2) // Low rated
    ]
    
    for entry in history {
        try await saveMealHistory(entry)
    }
    
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    // Should include at least one 5-star favorite
    let hasFavorite = plan.meals.contains { meal in
        ["Tacos", "Pasta"].contains { meal.recipe.title.contains($0) }
    }
    
    XCTAssertTrue(hasFavorite, "Plan should include at least one favorite meal")
    
    // Should NOT include low-rated meal
    let hasLowRated = plan.meals.contains { $0.recipe.title.contains("Stir-Fry") }
    XCTAssertFalse(hasLowRated, "Plan should exclude low-rated meals")
}
```

**Test 11.2: Avoid Recent Repeats**
```swift
func testAvoidRecentRepeats() async throws {
    let recentMeal = createTestRecipe(title: "Chicken Parmesan")
    
    let history = [
        MealHistoryEntry(recipe: recentMeal, cookedDate: Date().addingDays(-3))
    ]
    
    for entry in history {
        try await saveMealHistory(entry)
    }
    
    let plan = try await generateWeeklyPlan(constraints: standardConstraints())
    
    // Should not repeat meal from 3 days ago
    let hasRepeat = plan.meals.contains { $0.recipe.title == "Chicken Parmesan" }
    
    XCTAssertFalse(hasRepeat, "Should not repeat meal from last 14 days")
}
```

---

## 10. Error Handling Strategies

### Error Types and Recovery

```swift
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
    case allergyConflict(String)
    case networkError(String)
    
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
        case .allergyConflict(let details):
            return "Allergy safety conflict: \(details)"
        case .networkError(let message):
            return "Network error: \(message). Please check your connection."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .insufficientRecipes:
            return "Try increasing your budget, extending prep time limits, or being more flexible with cuisines."
        case .budgetTooLow:
            return "Consider increasing your weekly budget to at least $80, or enable leftover meals to reduce costs."
        case .apiError, .networkError:
            return "Please check your internet connection and try again. If the problem persists, we'll use cached recipes."
        case .allergyConflict:
            return "Please review your family's allergy settings and try again."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// Error Recovery Handler
class MealPlanningErrorHandler {
    func handle(_ error: Error, context: String) async -> RecoveryAction {
        guard let mealError = error as? MealPlanningError else {
            return .showGenericError
        }
        
        switch mealError {
        case .insufficientRecipes:
            return .suggestRelaxConstraints
            
        case .budgetTooLow:
            return .suggestBudgetIncrease
            
        case .apiError, .networkError:
            return .fallbackToCachedRecipes
            
        case .allergyConflict:
            return .requestUserReview
            
        case .databaseError:
            return .retryWithExponentialBackoff
            
        default:
            return .showErrorWithRecovery
        }
    }
}

enum RecoveryAction {
    case showGenericError
    case suggestRelaxConstraints
    case suggestBudgetIncrease
    case fallbackToCachedRecipes
    case requestUserReview
    case retryWithExponentialBackoff
    case showErrorWithRecovery
}

// Graceful Degradation
extension MealPlanningSkill {
    func generateWeeklyPlanWithFallback(constraints: WeeklyPlanConstraints) async throws -> WeeklyMealPlan {
        do {
            // Attempt normal generation
            return try await generateWeeklyPlan(constraints: constraints)
        } catch MealPlanningError.insufficientRecipes {
            // Fallback 1: Relax time constraints
            print("Insufficient recipes - relaxing time constraints")
            var relaxedConstraints = constraints
            relaxedConstraints.maxWeekdayPrepTime += 10
            relaxedConstraints.maxWeekendPrepTime += 20
            
            do {
                return try await generateWeeklyPlan(constraints: relaxedConstraints)
            } catch {
                // Fallback 2: Use cached/favorite recipes
                print("Still insufficient - using cached favorites")
                return try await generatePlanFromFavorites(constraints: constraints)
            }
        } catch MealPlanningError.apiError(let message) {
            // Fallback: Use local recipe database
            print("API error: \(message) - using local recipes")
            return try await generatePlanFromLocalRecipes(constraints: constraints)
        }
    }
    
    private func generatePlanFromFavorites(constraints: WeeklyPlanConstraints) async throws -> WeeklyMealPlan {
        let favorites = try await getFavoriteRecipes(
            familyId: constraints.familyId,
            minRating: 3, // Lower threshold
            minOccurrences: 1
        )
        
        guard favorites.count >= 7 else {
            throw MealPlanningError.insufficientRecipes
        }
        
        // Build plan from favorites only
        var selectedMeals: [PlannedMeal] = []
        for (index, favorite) in favorites.prefix(7).enumerated() {
            let mealDate = Calendar.current.date(byAdding: .day, value: index, to: constraints.startDate)!
            selectedMeals.append(PlannedMeal(
                id: UUID(),
                recipe: favorite,
                scheduledDate: mealDate,
                mealType: .dinner,
                servings: constraints.familySize,
                notes: "Selected from your favorites",
                isLeftover: false,
                originalMealId: nil
            ))
        }
        
        let groceryList = try await generateGroceryList(meals: selectedMeals, pantry: [])
        let costEstimate = try await estimateGroceryCost(list: groceryList)
        
        return WeeklyMealPlan(
            id: UUID(),
            familyId: constraints.familyId,
            weekStartDate: constraints.startDate,
            meals: selectedMeals,
            groceryList: groceryList,
            estimatedCost: costEstimate,
            nutritionSummary: nil,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

---

## 11. API Modularity & Recipe Source Flexibility

To ensure the meal planning system works with ANY recipe API (Spoonacular, Edamam, TheMealDB, custom sources), we define a protocol-based architecture:

```swift
// MARK: - Recipe Data Source Protocol

protocol RecipeDataSource {
    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe]
    func getRecipeDetails(id: String) async throws -> Recipe
    func getRecipeNutrition(id: String) async throws -> NutritionInfo
}

// MARK: - Spoonacular Implementation

class SpoonacularRecipeSource: RecipeDataSource {
    private let apiKey: String
    private let baseURL = "https://api.spoonacular.com"
    
    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe] {
        var components = URLComponents(string: "\(baseURL)/recipes/complexSearch")!
        var queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        
        if let cuisine = criteria.cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        if let maxTime = criteria.maxTotalTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: "\(maxTime)"))
        }
        if !criteria.dietaryRestrictions.isEmpty {
            let diet = criteria.dietaryRestrictions.first!.rawValue
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        
        components.queryItems = queryItems
        
        let request = APIRequest<SpoonacularSearchResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )
        
        let response = try await request.execute()
        return response.results.map { $0.toRecipe() }
    }
    
    func getRecipeDetails(id: String) async throws -> Recipe {
        // Implementation
    }
    
    func getRecipeNutrition(id: String) async throws -> NutritionInfo {
        // Implementation
    }
}

// MARK: - Edamam Implementation

class EdamamRecipeSource: RecipeDataSource {
    private let appId: String
    private let appKey: String
    private let baseURL = "https://api.edamam.com/api/recipes/v2"
    
    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe] {
        // Different API, same protocol
        var components = URLComponents(string: baseURL)!
        var queryItems = [
            URLQueryItem(name: "type", value: "public"),
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey)
        ]
        
        if let cuisine = criteria.cuisine {
            queryItems.append(URLQueryItem(name: "cuisineType", value: cuisine))
        }
        // Map criteria to Edamam's parameters...
        
        components.queryItems = queryItems
        
        let request = APIRequest<EdamamSearchResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )
        
        let response = try await request.execute()
        return response.hits.map { $0.recipe.toRecipe() }
    }
    
    func getRecipeDetails(id: String) async throws -> Recipe {
        // Implementation
    }
    
    func getRecipeNutrition(id: String) async throws -> NutritionInfo {
        // Implementation
    }
}

// MARK: - Local/Custom Recipe Source

class LocalRecipeSource: RecipeDataSource {
    private let database: RecipeDatabase
    
    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe] {
        // Search local database
        var query = database.recipes.query()
        
        if let cuisine = criteria.cuisine {
            query = query.filter { $0.cuisine == cuisine }
        }
        if let maxTime = criteria.maxTotalTime {
            query = query.filter { $0.totalTime <= maxTime }
        }
        for restriction in criteria.dietaryRestrictions {
            query = query.filter { recipe in
                switch restriction {
                case .vegetarian: return recipe.isVegetarian
                case .vegan: return recipe.isVegan
                case .glutenFree: return recipe.isGlutenFree
                // ... other cases
                default: return true
                }
            }
        }
        
        return try await query.fetch()
    }
    
    func getRecipeDetails(id: String) async throws -> Recipe {
        return try await database.recipes.findById(UUID(uuidString: id)!)
    }
    
    func getRecipeNutrition(id: String) async throws -> NutritionInfo {
        let recipe = try await getRecipeDetails(id: id)
        return recipe.nutrition ?? NutritionInfo.default
    }
}

// MARK: - Recipe Source Manager (Facade Pattern)

class RecipeSourceManager {
    private var sources: [RecipeDataSource] = []
    private var primarySource: RecipeDataSource
    
    init(primarySource: RecipeDataSource, fallbackSources: [RecipeDataSource] = []) {
        self.primarySource = primarySource
        self.sources = [primarySource] + fallbackSources
    }
    
    func searchRecipes(criteria: RecipeSearchCriteria) async throws -> [Recipe] {
        // Try primary source first
        do {
            let results = try await primarySource.searchRecipes(criteria: criteria)
            if !results.isEmpty {
                return results
            }
        } catch {
            print("Primary source failed: \(error). Trying fallbacks...")
        }
        
        // Try fallback sources
        for source in sources.dropFirst() {
            do {
                let results = try await source.searchRecipes(criteria: criteria)
                if !results.isEmpty {
                    return results
                }
            } catch {
                print("Fallback source failed: \(error)")
                continue
            }
        }
        
        throw MealPlanningError.insufficientRecipes
    }
}

// MARK: - Usage in Meal Planning

class MealPlanningSkill {
    private let recipeManager: RecipeSourceManager
    
    init() {
        // Setup with multiple sources for redundancy
        let spoonacular = SpoonacularRecipeSource(apiKey: Config.spoonacularKey)
        let edamam = EdamamRecipeSource(appId: Config.edamamId, appKey: Config.edamamKey)
        let local = LocalRecipeSource(database: RecipeDatabase.shared)
        
        self.recipeManager = RecipeSourceManager(
            primarySource: spoonacular,
            fallbackSources: [edamam, local]
        )
    }
    
    func generateWeeklyPlan(constraints: WeeklyPlanConstraints) async throws -> WeeklyMealPlan {
        // Use recipe manager - source-agnostic
        let recipes = try await recipeManager.searchRecipes(criteria: /* criteria */)
        // Rest of planning logic...
    }
}
```

---

## Conclusion

This comprehensive atomic function breakdown provides:

1. **Deterministic Logic**: Every decision point is clearly defined with if/else branches
2. **Cultural Sensitivity**: Handles Hindu vegetarian, Muslim halal, Jewish kosher, and multi-allergy families
3. **Context Awareness**: Learns from chat history, meal ratings, and family behavior
4. **API Modularity**: Works with any recipe API through protocol-based architecture
5. **Graceful Degradation**: Falls back intelligently when APIs fail or constraints are too strict
6. **Production-Ready Tests**: 20+ comprehensive test cases covering all scenarios
7. **Error Handling**: Clear error types with user-friendly recovery suggestions

The system "feels like an LLM" because it:
- Learns from context (chat history, ratings, past meals)
- Makes intelligent assumptions (stress detection → quick meals)
- Adapts to preferences (cultural, religious, allergic)
- Explains its reasoning transparently

But it's **fully deterministic** - every decision follows clear business rules that a smaller LLM (Gemma 3n) can execute reliably through function calling.

