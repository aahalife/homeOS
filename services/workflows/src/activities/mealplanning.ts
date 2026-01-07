/**
 * Meal Planning Activities for homeOS
 *
 * Family meal and nutrition management:
 * - Weekly meal planning
 * - Recipe suggestions based on preferences/restrictions
 * - Automatic grocery list generation
 * - Nutrition tracking
 * - Pantry inventory management
 */

import Anthropic from '@anthropic-ai/sdk';

// ============================================================================
// TYPES
// ============================================================================

export interface DietaryPreferences {
  restrictions: string[]; // e.g., ['vegetarian', 'gluten-free', 'nut-allergy']
  preferences: string[]; // e.g., ['low-carb', 'high-protein']
  dislikes: string[];
  cuisines: string[]; // preferred cuisines
}

export interface Recipe {
  id: string;
  name: string;
  description: string;
  cuisine: string;
  prepTime: number; // minutes
  cookTime: number;
  servings: number;
  difficulty: 'easy' | 'medium' | 'hard';
  ingredients: {
    name: string;
    amount: number;
    unit: string;
    category: string;
  }[];
  instructions: string[];
  nutritionPerServing: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
    fiber?: number;
  };
  tags: string[];
  imageUrl?: string;
  sourceUrl?: string;
}

export interface MealPlan {
  id: string;
  weekOf: string; // ISO date of week start
  meals: {
    day: string;
    date: string;
    breakfast?: { recipeId: string; recipeName: string };
    lunch?: { recipeId: string; recipeName: string };
    dinner?: { recipeId: string; recipeName: string };
    snacks?: string[];
  }[];
  groceryList: GroceryItem[];
  estimatedCost: number;
  totalCalories: number;
}

export interface GroceryItem {
  name: string;
  amount: number;
  unit: string;
  category: string;
  estimated_price?: number;
  needed_for: string[]; // recipe names
  in_pantry?: boolean;
}

export interface PantryItem {
  id: string;
  name: string;
  quantity: number;
  unit: string;
  category: string;
  expirationDate?: string;
  location?: string; // pantry, fridge, freezer
}

// ============================================================================
// RECIPE SEARCH
// ============================================================================

export interface SearchRecipesInput {
  workspaceId: string;
  query?: string;
  ingredients?: string[]; // search by available ingredients
  dietary?: DietaryPreferences;
  maxPrepTime?: number;
  cuisine?: string;
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
}

export async function searchRecipes(input: SearchRecipesInput): Promise<Recipe[]> {
  const { query, ingredients, dietary, maxPrepTime, cuisine, mealType } = input;

  // In production, integrate with:
  // - Spoonacular API
  // - Edamam Recipe API
  // - Custom recipe database

  const anthropicKey = process.env['ANTHROPIC_API_KEY'];

  if (anthropicKey && query) {
    try {
      const client = new Anthropic({ apiKey: anthropicKey });

      const prompt = `Suggest 3 recipes for: ${query}
${ingredients ? `Using ingredients: ${ingredients.join(', ')}` : ''}
${dietary?.restrictions.length ? `Dietary restrictions: ${dietary.restrictions.join(', ')}` : ''}
${maxPrepTime ? `Max prep time: ${maxPrepTime} minutes` : ''}
${cuisine ? `Cuisine preference: ${cuisine}` : ''}
${mealType ? `Meal type: ${mealType}` : ''}

Return as JSON array: [{"name": "...", "description": "...", "cuisine": "...", "prepTime": 15, "cookTime": 30, "servings": 4, "difficulty": "easy", "ingredients": [{"name": "...", "amount": 1, "unit": "cup", "category": "produce"}], "instructions": ["..."], "nutritionPerServing": {"calories": 300, "protein": 20, "carbs": 30, "fat": 10}, "tags": ["healthy"]}]`;

      const response = await client.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });

      const text = response.content[0]?.type === 'text' ? response.content[0].text : '[]';
      const recipes = JSON.parse(text.replace(/```json\n?/g, '').replace(/```\n?/g, ''));

      return recipes.map((r: Omit<Recipe, 'id'>, i: number) => ({
        id: `recipe-${Date.now()}-${i}`,
        ...r,
      }));
    } catch (error) {
      console.warn('AI recipe search failed:', error);
    }
  }

  // Return default recipes
  return getDefaultRecipes(mealType);
}

function getDefaultRecipes(mealType?: string): Recipe[] {
  const recipes: Recipe[] = [
    {
      id: 'recipe-1',
      name: 'Grilled Chicken Salad',
      description: 'Light and healthy grilled chicken over mixed greens',
      cuisine: 'American',
      prepTime: 15,
      cookTime: 20,
      servings: 4,
      difficulty: 'easy',
      ingredients: [
        { name: 'chicken breast', amount: 1, unit: 'lb', category: 'protein' },
        { name: 'mixed greens', amount: 6, unit: 'cups', category: 'produce' },
        { name: 'cherry tomatoes', amount: 1, unit: 'cup', category: 'produce' },
        { name: 'olive oil', amount: 2, unit: 'tbsp', category: 'pantry' },
      ],
      instructions: [
        'Season chicken with salt and pepper',
        'Grill chicken for 6-7 minutes per side',
        'Let rest 5 minutes, then slice',
        'Arrange greens and tomatoes on plates',
        'Top with sliced chicken and drizzle with olive oil',
      ],
      nutritionPerServing: { calories: 320, protein: 35, carbs: 8, fat: 16 },
      tags: ['healthy', 'high-protein', 'low-carb'],
    },
    {
      id: 'recipe-2',
      name: 'Vegetable Stir Fry',
      description: 'Quick and colorful vegetable stir fry with tofu',
      cuisine: 'Asian',
      prepTime: 10,
      cookTime: 15,
      servings: 4,
      difficulty: 'easy',
      ingredients: [
        { name: 'tofu', amount: 14, unit: 'oz', category: 'protein' },
        { name: 'broccoli', amount: 2, unit: 'cups', category: 'produce' },
        { name: 'bell peppers', amount: 2, unit: 'whole', category: 'produce' },
        { name: 'soy sauce', amount: 3, unit: 'tbsp', category: 'pantry' },
      ],
      instructions: [
        'Press and cube tofu',
        'Heat oil in wok over high heat',
        'Stir fry tofu until golden',
        'Add vegetables and stir fry 5 minutes',
        'Add soy sauce and toss to coat',
      ],
      nutritionPerServing: { calories: 220, protein: 18, carbs: 15, fat: 12 },
      tags: ['vegetarian', 'quick', 'healthy'],
    },
    {
      id: 'recipe-3',
      name: 'Pasta Primavera',
      description: 'Classic pasta with fresh spring vegetables',
      cuisine: 'Italian',
      prepTime: 15,
      cookTime: 20,
      servings: 6,
      difficulty: 'easy',
      ingredients: [
        { name: 'penne pasta', amount: 1, unit: 'lb', category: 'pantry' },
        { name: 'zucchini', amount: 2, unit: 'whole', category: 'produce' },
        { name: 'cherry tomatoes', amount: 1, unit: 'pint', category: 'produce' },
        { name: 'parmesan cheese', amount: 0.5, unit: 'cup', category: 'dairy' },
      ],
      instructions: [
        'Cook pasta according to package directions',
        'Sauté vegetables in olive oil',
        'Toss pasta with vegetables',
        'Top with parmesan and serve',
      ],
      nutritionPerServing: { calories: 380, protein: 14, carbs: 62, fat: 9 },
      tags: ['vegetarian', 'family-friendly'],
    },
  ];

  if (mealType === 'breakfast') {
    return [
      {
        id: 'recipe-breakfast-1',
        name: 'Overnight Oats',
        description: 'Healthy make-ahead breakfast',
        cuisine: 'American',
        prepTime: 5,
        cookTime: 0,
        servings: 1,
        difficulty: 'easy',
        ingredients: [
          { name: 'rolled oats', amount: 0.5, unit: 'cup', category: 'pantry' },
          { name: 'milk', amount: 0.5, unit: 'cup', category: 'dairy' },
          { name: 'yogurt', amount: 0.25, unit: 'cup', category: 'dairy' },
          { name: 'berries', amount: 0.5, unit: 'cup', category: 'produce' },
        ],
        instructions: [
          'Combine oats, milk, and yogurt in jar',
          'Refrigerate overnight',
          'Top with berries before serving',
        ],
        nutritionPerServing: { calories: 280, protein: 12, carbs: 45, fat: 6 },
        tags: ['healthy', 'make-ahead', 'breakfast'],
      },
    ];
  }

  return recipes;
}

// ============================================================================
// MEAL PLAN GENERATION
// ============================================================================

export interface GenerateMealPlanInput {
  workspaceId: string;
  familySize: number;
  dietary?: DietaryPreferences;
  budget?: number; // weekly budget
  startDate?: string;
  includeBreakfast?: boolean;
  includeLunch?: boolean;
  leftoverDays?: string[]; // days to use leftovers
}

export async function generateMealPlan(input: GenerateMealPlanInput): Promise<MealPlan> {
  const {
    workspaceId,
    familySize,
    dietary,
    budget,
    startDate,
    includeBreakfast = true,
    includeLunch = false,
  } = input;

  const weekStart = startDate ? new Date(startDate) : getNextMonday();
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Get recipe suggestions
  const dinnerRecipes = await searchRecipes({ workspaceId, mealType: 'dinner', dietary });
  const breakfastRecipes = includeBreakfast
    ? await searchRecipes({ workspaceId, mealType: 'breakfast', dietary })
    : [];

  const meals: MealPlan['meals'] = [];
  const allIngredients: Map<string, GroceryItem> = new Map();

  for (let i = 0; i < 7; i++) {
    const date = new Date(weekStart);
    date.setDate(date.getDate() + i);

    const dinnerRecipe = dinnerRecipes[i % dinnerRecipes.length];
    const breakfastRecipe = breakfastRecipes[i % Math.max(breakfastRecipes.length, 1)];

    const meal: MealPlan['meals'][0] = {
      day: days[i],
      date: date.toISOString().split('T')[0],
      dinner: { recipeId: dinnerRecipe.id, recipeName: dinnerRecipe.name },
    };

    if (includeBreakfast && breakfastRecipe) {
      meal.breakfast = { recipeId: breakfastRecipe.id, recipeName: breakfastRecipe.name };
    }

    meals.push(meal);

    // Aggregate ingredients
    for (const ingredient of dinnerRecipe.ingredients) {
      const key = `${ingredient.name}-${ingredient.unit}`;
      const existing = allIngredients.get(key);
      if (existing) {
        existing.amount += ingredient.amount * (familySize / dinnerRecipe.servings);
        existing.needed_for.push(dinnerRecipe.name);
      } else {
        allIngredients.set(key, {
          name: ingredient.name,
          amount: ingredient.amount * (familySize / dinnerRecipe.servings),
          unit: ingredient.unit,
          category: ingredient.category,
          needed_for: [dinnerRecipe.name],
        });
      }
    }
  }

  const groceryList = Array.from(allIngredients.values()).map((item) => ({
    ...item,
    amount: Math.ceil(item.amount * 10) / 10, // Round up
  }));

  return {
    id: `mealplan-${Date.now()}`,
    weekOf: weekStart.toISOString().split('T')[0],
    meals,
    groceryList,
    estimatedCost: budget || groceryList.length * 3, // Rough estimate
    totalCalories: dinnerRecipes.reduce((sum, r) => sum + r.nutritionPerServing.calories, 0) * familySize,
  };
}

function getNextMonday(): Date {
  const now = new Date();
  const dayOfWeek = now.getDay();
  const daysUntilMonday = dayOfWeek === 0 ? 1 : 8 - dayOfWeek;
  now.setDate(now.getDate() + daysUntilMonday);
  now.setHours(0, 0, 0, 0);
  return now;
}

// ============================================================================
// GROCERY LIST
// ============================================================================

export interface GenerateGroceryListInput {
  workspaceId: string;
  mealPlanId?: string;
  additionalItems?: string[];
  checkPantry?: boolean;
}

export async function generateGroceryList(input: GenerateGroceryListInput): Promise<{
  items: GroceryItem[];
  estimatedTotal: number;
  byCategory: Record<string, GroceryItem[]>;
}> {
  const { additionalItems = [] } = input;

  // Get items from meal plan (would be fetched from database)
  const mealPlanItems: GroceryItem[] = [
    { name: 'chicken breast', amount: 2, unit: 'lb', category: 'protein', needed_for: ['Grilled Chicken Salad'] },
    { name: 'mixed greens', amount: 12, unit: 'oz', category: 'produce', needed_for: ['Grilled Chicken Salad'] },
    { name: 'pasta', amount: 1, unit: 'lb', category: 'pantry', needed_for: ['Pasta Primavera'] },
  ];

  // Add additional items
  for (const item of additionalItems) {
    mealPlanItems.push({
      name: item,
      amount: 1,
      unit: 'each',
      category: 'other',
      needed_for: ['Additional request'],
    });
  }

  // Group by category
  const byCategory: Record<string, GroceryItem[]> = {};
  for (const item of mealPlanItems) {
    if (!byCategory[item.category]) {
      byCategory[item.category] = [];
    }
    byCategory[item.category].push(item);
  }

  // Estimate total (rough approximation)
  const estimatedTotal = mealPlanItems.length * 4.5;

  return {
    items: mealPlanItems,
    estimatedTotal,
    byCategory,
  };
}

// ============================================================================
// PANTRY MANAGEMENT
// ============================================================================

export interface GetPantryInput {
  workspaceId: string;
  location?: 'pantry' | 'fridge' | 'freezer' | 'all';
  expiringWithin?: number; // days
}

export async function getPantryItems(input: GetPantryInput): Promise<PantryItem[]> {
  const { location = 'all', expiringWithin } = input;

  // In production, would fetch from database
  const items: PantryItem[] = [
    { id: 'p1', name: 'Rice', quantity: 2, unit: 'lb', category: 'grains', location: 'pantry' },
    { id: 'p2', name: 'Olive Oil', quantity: 1, unit: 'bottle', category: 'oils', location: 'pantry' },
    { id: 'p3', name: 'Milk', quantity: 0.5, unit: 'gallon', category: 'dairy', location: 'fridge', expirationDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString() },
    { id: 'p4', name: 'Chicken breast', quantity: 1, unit: 'lb', category: 'protein', location: 'freezer' },
  ];

  let filtered = items;

  if (location !== 'all') {
    filtered = filtered.filter((item) => item.location === location);
  }

  if (expiringWithin) {
    const cutoff = new Date(Date.now() + expiringWithin * 24 * 60 * 60 * 1000);
    filtered = filtered.filter((item) =>
      item.expirationDate && new Date(item.expirationDate) <= cutoff
    );
  }

  return filtered;
}

export interface AddPantryItemInput {
  workspaceId: string;
  item: Omit<PantryItem, 'id'>;
}

export async function addPantryItem(input: AddPantryItemInput): Promise<PantryItem> {
  return {
    id: `pantry-${Date.now()}`,
    ...input.item,
  };
}

// ============================================================================
// NUTRITION TRACKING
// ============================================================================

export interface LogMealInput {
  workspaceId: string;
  memberId: string;
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  items: { name: string; portion: string; calories?: number }[];
  date?: string;
}

export interface NutritionLog {
  id: string;
  memberId: string;
  date: string;
  mealType: string;
  items: { name: string; portion: string; calories: number }[];
  totalCalories: number;
}

export async function logMeal(input: LogMealInput): Promise<NutritionLog> {
  const { memberId, mealType, items, date } = input;

  // Estimate calories if not provided
  const processedItems = items.map((item) => ({
    ...item,
    calories: item.calories || estimateCalories(item.name),
  }));

  const totalCalories = processedItems.reduce((sum, item) => sum + item.calories, 0);

  return {
    id: `meal-log-${Date.now()}`,
    memberId,
    date: date || new Date().toISOString().split('T')[0],
    mealType,
    items: processedItems,
    totalCalories,
  };
}

function estimateCalories(foodName: string): number {
  // Very rough estimates - in production, use nutrition API
  const estimates: Record<string, number> = {
    chicken: 250,
    salad: 100,
    pasta: 350,
    rice: 200,
    vegetable: 50,
    fruit: 80,
    bread: 100,
    egg: 70,
  };

  const lower = foodName.toLowerCase();
  for (const [key, cal] of Object.entries(estimates)) {
    if (lower.includes(key)) {
      return cal;
    }
  }

  return 200; // Default estimate
}

export interface GetNutritionSummaryInput {
  workspaceId: string;
  memberId: string;
  startDate: string;
  endDate: string;
}

export async function getNutritionSummary(input: GetNutritionSummaryInput): Promise<{
  totalCalories: number;
  averageDaily: number;
  byMealType: Record<string, number>;
  daysTracked: number;
}> {
  // Would query logged meals from database
  return {
    totalCalories: 14000,
    averageDaily: 2000,
    byMealType: {
      breakfast: 3500,
      lunch: 4200,
      dinner: 5600,
      snack: 700,
    },
    daysTracked: 7,
  };
}
