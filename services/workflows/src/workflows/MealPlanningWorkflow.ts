/**
 * Meal Planning Workflows for homeOS
 *
 * Family meal and nutrition management:
 * - Weekly meal plan generation
 * - Grocery list creation
 * - Recipe suggestions
 */

import {
  proxyActivities,
} from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const {
  searchRecipes,
  generateMealPlan,
  generateGroceryList,
  getPantryItems,
  addPantryItem,
  logMeal,
  getNutritionSummary,
  emitTaskEvent,
  storeMemory,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '5 minutes',
  retry: { maximumAttempts: 3 },
});

// ============================================================================
// MEAL PLAN WORKFLOW
// ============================================================================

export interface MealPlanWorkflowInput {
  workspaceId: string;
  familySize: number;
  dietary?: {
    restrictions: string[];
    preferences: string[];
    dislikes: string[];
    cuisines: string[];
  };
  budget?: number;
  startDate?: string;
  includeBreakfast?: boolean;
  includeLunch?: boolean;
}

export async function MealPlanWorkflow(input: MealPlanWorkflowInput): Promise<{
  mealPlan: unknown;
  groceryList: unknown;
  estimatedCost: number;
}> {
  const {
    workspaceId,
    familySize,
    dietary,
    budget,
    startDate,
    includeBreakfast = true,
    includeLunch = false,
  } = input;

  await emitTaskEvent(workspaceId, 'mealplanning.plan.generating', { familySize });

  // Check pantry for available items
  const pantryItems = await getPantryItems({ workspaceId, location: 'all' });
  const availableIngredients = pantryItems.map((item) => item.name);

  // Generate meal plan
  const mealPlan = await generateMealPlan({
    workspaceId,
    familySize,
    dietary,
    budget,
    startDate,
    includeBreakfast,
    includeLunch,
  });

  // Generate grocery list based on meal plan
  const groceryListResult = await generateGroceryList({
    workspaceId,
    mealPlanId: mealPlan.id,
    checkPantry: true,
  });

  // Mark pantry items as available
  for (const item of groceryListResult.items) {
    if (availableIngredients.some((ing) =>
      ing.toLowerCase().includes(item.name.toLowerCase()) ||
      item.name.toLowerCase().includes(ing.toLowerCase())
    )) {
      item.in_pantry = true;
    }
  }

  // Store meal plan in memory
  await storeMemory({
    workspaceId,
    type: 'procedural',
    content: JSON.stringify({
      type: 'meal_plan',
      weekOf: mealPlan.weekOf,
      mealsPlanned: mealPlan.meals.length,
      estimatedCost: mealPlan.estimatedCost,
    }),
    salience: 0.7,
    tags: ['mealplanning', 'weekly-plan'],
  });

  await emitTaskEvent(workspaceId, 'mealplanning.plan.complete', {
    mealPlanId: mealPlan.id,
    mealsPlanned: mealPlan.meals.length,
    groceryItems: groceryListResult.items.length,
  });

  return {
    mealPlan,
    groceryList: groceryListResult,
    estimatedCost: mealPlan.estimatedCost,
  };
}

// ============================================================================
// GROCERY LIST WORKFLOW
// ============================================================================

export interface GroceryListWorkflowInput {
  workspaceId: string;
  mealPlanId?: string;
  additionalItems?: string[];
  groupByStore?: boolean;
}

export async function GroceryListWorkflow(input: GroceryListWorkflowInput): Promise<{
  items: unknown[];
  byCategory: Record<string, unknown[]>;
  estimatedTotal: number;
  pantryItemsToUse: unknown[];
}> {
  const { workspaceId, mealPlanId, additionalItems = [] } = input;

  await emitTaskEvent(workspaceId, 'mealplanning.grocerylist.generating', {});

  // Get items from meal plan
  const groceryList = await generateGroceryList({
    workspaceId,
    mealPlanId,
    additionalItems,
    checkPantry: true,
  });

  // Get pantry items that will be used
  const pantryItems = await getPantryItems({ workspaceId, location: 'all' });

  // Find items we already have
  const pantryItemsToUse = pantryItems.filter((pantryItem) =>
    groceryList.items.some((groceryItem) =>
      pantryItem.name.toLowerCase().includes(groceryItem.name.toLowerCase()) ||
      groceryItem.name.toLowerCase().includes(pantryItem.name.toLowerCase())
    )
  );

  // Filter out items we already have
  const itemsToBy = groceryList.items.filter((item) => !item.in_pantry);

  await emitTaskEvent(workspaceId, 'mealplanning.grocerylist.complete', {
    totalItems: groceryList.items.length,
    itemsToBuy: itemsToBy.length,
    usingFromPantry: pantryItemsToUse.length,
  });

  return {
    items: itemsToBy,
    byCategory: groceryList.byCategory,
    estimatedTotal: groceryList.estimatedTotal,
    pantryItemsToUse,
  };
}

// ============================================================================
// RECIPE SUGGESTION WORKFLOW
// ============================================================================

export interface RecipeSuggestionWorkflowInput {
  workspaceId: string;
  query?: string;
  useAvailableIngredients?: boolean;
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  maxPrepTime?: number;
  dietary?: {
    restrictions: string[];
    preferences: string[];
  };
}

export async function RecipeSuggestionWorkflow(input: RecipeSuggestionWorkflowInput): Promise<{
  recipes: unknown[];
  suggestions: string[];
}> {
  const {
    workspaceId,
    query,
    useAvailableIngredients = false,
    mealType,
    maxPrepTime,
    dietary,
  } = input;

  await emitTaskEvent(workspaceId, 'mealplanning.recipes.searching', { query, mealType });

  let availableIngredients: string[] = [];

  if (useAvailableIngredients) {
    const pantryItems = await getPantryItems({ workspaceId, location: 'all' });
    availableIngredients = pantryItems.map((item) => item.name);
  }

  const recipes = await searchRecipes({
    workspaceId,
    query,
    ingredients: availableIngredients.length > 0 ? availableIngredients : undefined,
    dietary,
    maxPrepTime,
    mealType,
  });

  // Generate suggestions based on what we found
  const suggestions: string[] = [];

  if (recipes.length === 0) {
    suggestions.push('Try broadening your search criteria');
    if (dietary?.restrictions.length) {
      suggestions.push('Consider temporarily relaxing dietary restrictions');
    }
  } else {
    const quickRecipes = recipes.filter((r) => r.prepTime + r.cookTime <= 30);
    if (quickRecipes.length > 0) {
      suggestions.push(`${quickRecipes.length} recipes can be ready in 30 minutes or less`);
    }

    const healthyRecipes = recipes.filter((r) => r.tags?.includes('healthy'));
    if (healthyRecipes.length > 0) {
      suggestions.push(`${healthyRecipes.length} healthy options available`);
    }
  }

  await emitTaskEvent(workspaceId, 'mealplanning.recipes.found', {
    count: recipes.length,
  });

  return { recipes, suggestions };
}
