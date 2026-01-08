# Meal Planning Skill

Generate weekly meal plans, grocery lists, and recipe suggestions for families.

## Purpose

Create nutritionally balanced meal plans based on family preferences, dietary restrictions, and budget, then generate organized grocery lists.

## Prerequisites

- LLM API key
- Recipe database access (Spoonacular, Edamam, or local DB)
- Optional: Store APIs for price comparison

## Input Parameters

```typescript
interface MealPlanInput {
  workspaceId: string;
  familySize: number;
  dietary?: {
    restrictions: string[];    // ["vegetarian", "gluten-free", "nut-free"]
    preferences: string[];     // ["low-carb", "high-protein"]
    dislikes: string[];        // ["mushrooms", "eggplant"]
    cuisines: string[];        // ["Italian", "Mexican", "Asian"]
  };
  budget?: number;             // Weekly budget in dollars
  startDate?: string;          // Start date for meal plan
  includeBreakfast?: boolean;
  includeLunch?: boolean;
}
```

## Step-by-Step Instructions

### Step 1: Check Pantry Inventory

**Risk Level: LOW**

Retrieve current pantry items to incorporate into meal planning.

```typescript
const pantryItems = await memory.query({
  workspaceId,
  type: 'pantry',
  filters: { location: 'all' }
});

const availableIngredients = pantryItems.map(item => ({
  name: item.name,
  quantity: item.quantity,
  expiresAt: item.expiresAt
}));

// Prioritize items expiring soon
const expiringItems = availableIngredients
  .filter(item => item.expiresAt && daysTilExpiry(item.expiresAt) < 7)
  .sort((a, b) => new Date(a.expiresAt) - new Date(b.expiresAt));
```

### Step 2: Generate Meal Plan

**Risk Level: LOW**

Create a weekly meal plan using LLM and recipe database.

```typescript
const mealPlanPrompt = `Create a ${7}-day meal plan for a family of ${familySize}.

Dietary requirements:
- Restrictions: ${dietary.restrictions.join(', ') || 'None'}
- Preferences: ${dietary.preferences.join(', ') || 'None'}
- Dislikes: ${dietary.dislikes.join(', ') || 'None'}
- Preferred cuisines: ${dietary.cuisines.join(', ') || 'Any'}

Budget: ${budget ? `$${budget}/week` : 'Flexible'}

Include: ${includeBreakfast ? 'Breakfast, ' : ''}${includeLunch ? 'Lunch, ' : ''}Dinner

Ingredients to use up (expiring soon):
${expiringItems.map(i => `- ${i.name} (expires in ${daysTilExpiry(i.expiresAt)} days)`).join('\n')}

Generate in this format:
{
  "weekOf": "2024-01-15",
  "meals": [
    {
      "day": "Monday",
      "breakfast": { "name": "", "prepTime": 0, "servings": 0 },
      "lunch": { "name": "", "prepTime": 0, "servings": 0 },
      "dinner": { "name": "", "prepTime": 0, "servings": 0, "recipe": {} }
    }
  ],
  "estimatedCost": 0,
  "nutritionSummary": { "avgCalories": 0, "avgProtein": 0 }
}`;

const mealPlan = await llm.complete({
  system: mealPlanPrompt,
  user: JSON.stringify({ familySize, dietary, budget })
});

// Enrich with full recipes from database
for (const day of mealPlan.meals) {
  if (day.dinner) {
    day.dinner.recipe = await recipes.search({
      name: day.dinner.name,
      dietary: dietary.restrictions
    });
  }
}
```

### Step 3: Generate Grocery List

**Risk Level: LOW**

Create a consolidated grocery list from the meal plan.

```typescript
// Extract all ingredients from recipes
const allIngredients = [];

for (const day of mealPlan.meals) {
  for (const mealType of ['breakfast', 'lunch', 'dinner']) {
    const meal = day[mealType];
    if (meal?.recipe?.ingredients) {
      allIngredients.push(...meal.recipe.ingredients);
    }
  }
}

// Consolidate and scale ingredients
const consolidatedList = consolidateIngredients(allIngredients, familySize);

// Check against pantry
const groceryList = consolidatedList.map(item => {
  const inPantry = availableIngredients.find(
    p => p.name.toLowerCase().includes(item.name.toLowerCase())
  );

  return {
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
    category: item.category,
    inPantry: !!inPantry,
    pantryQuantity: inPantry?.quantity || 0,
    needToBuy: !inPantry || inPantry.quantity < item.quantity
  };
});

// Organize by category
const byCategory = groupBy(groceryList, 'category');

// Estimate total cost
const estimatedTotal = groceryList
  .filter(item => item.needToBuy)
  .reduce((sum, item) => sum + estimatePrice(item), 0);
```

### Step 4: Store Meal Plan in Memory

**Risk Level: LOW**

Save the meal plan for future reference.

```typescript
await memory.store({
  workspaceId,
  type: 'procedural',
  content: JSON.stringify({
    type: 'meal_plan',
    weekOf: mealPlan.weekOf,
    mealsPlanned: mealPlan.meals.length,
    estimatedCost: mealPlan.estimatedCost
  }),
  salience: 0.7,
  tags: ['mealplanning', 'weekly-plan']
});
```

### Step 5: Create Prep Schedule (Optional)

**Risk Level: LOW**

Generate a meal prep schedule for batch cooking.

```typescript
const prepSchedulePrompt = `Based on this meal plan, create a meal prep schedule:

${JSON.stringify(mealPlan.meals)}

Identify:
1. Ingredients that can be prepped ahead
2. Meals that can be batch cooked
3. Suggested prep day activities
4. Storage instructions

Format:
{
  "prepDay": "Sunday",
  "activities": [
    { "task": "", "duration": 0, "produces": [] }
  ],
  "dailyTasks": {
    "Monday": ["quick tasks for the day"]
  }
}`;

const prepSchedule = await llm.complete({
  system: prepSchedulePrompt
});
```

## Recipe Suggestion Sub-Skill

Find recipes based on available ingredients or criteria.

```typescript
interface RecipeSuggestionInput {
  workspaceId: string;
  query?: string;                    // "chicken dinner"
  useAvailableIngredients?: boolean;
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  maxPrepTime?: number;              // minutes
  dietary?: DietaryPreferences;
}

const searchRecipes = async (input: RecipeSuggestionInput) => {
  const searchParams = {
    query: input.query,
    type: input.mealType,
    maxReadyTime: input.maxPrepTime,
    diet: input.dietary?.restrictions.join(','),
    excludeIngredients: input.dietary?.dislikes?.join(',')
  };

  if (input.useAvailableIngredients) {
    const pantry = await getPantryItems(input.workspaceId);
    searchParams.includeIngredients = pantry.map(i => i.name).join(',');
  }

  const recipes = await recipeAPI.complexSearch(searchParams);

  return recipes.map(r => ({
    id: r.id,
    name: r.title,
    prepTime: r.preparationMinutes,
    cookTime: r.cookingMinutes,
    servings: r.servings,
    tags: r.diets,
    nutrition: r.nutrition,
    image: r.image
  }));
};
```

## Pantry Management Sub-Skills

### Add to Pantry

```typescript
const addPantryItem = async (input: {
  workspaceId: string;
  name: string;
  quantity: number;
  unit: string;
  location?: string;
  expiresAt?: string;
}) => {
  await memory.store({
    workspaceId: input.workspaceId,
    type: 'pantry',
    content: JSON.stringify(input),
    tags: ['pantry', input.location || 'general']
  });
};
```

### Log Meal

```typescript
const logMeal = async (input: {
  workspaceId: string;
  userId: string;
  mealType: string;
  foods: Array<{ name: string; servings: number }>;
}) => {
  const nutrition = await calculateNutrition(input.foods);

  await memory.store({
    workspaceId: input.workspaceId,
    type: 'episodic',
    content: JSON.stringify({
      type: 'meal_log',
      date: new Date().toISOString(),
      ...input,
      nutrition
    }),
    tags: ['nutrition', 'meal-log', input.mealType]
  });
};
```

## Error Handling

| Error | Recovery |
|-------|----------|
| Recipe not found | Search for alternatives, use LLM to generate |
| Budget exceeded | Suggest cheaper substitutions |
| Dietary conflict | Flag and ask user to resolve |
| API rate limited | Use cached recipes |

## Output

```typescript
interface MealPlanOutput {
  mealPlan: {
    weekOf: string;
    meals: DayMeal[];
    estimatedCost: number;
    nutritionSummary: NutritionSummary;
  };
  groceryList: {
    items: GroceryItem[];
    byCategory: Record<string, GroceryItem[]>;
    estimatedTotal: number;
    pantryItemsToUse: string[];
  };
}
```

## Integration Points

- **Calendar** - Add meal prep reminders
- **Shopping** - Send grocery list to Instacart/Amazon Fresh
- **Memory** - Track family preferences over time
- **Health** - Monitor nutritional goals
