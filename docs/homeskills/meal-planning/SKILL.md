---
name: meal-planning
description: Create weekly meal plans with grocery lists and prep schedules. Use when the user wants help planning meals, creating a grocery list, deciding what to cook, managing their pantry, or organizing meal prep. Considers dietary restrictions and family preferences.
---

# Meal Planning Skill

Generate personalized weekly meal plans, shopping lists, and prep schedules tailored to family preferences, dietary requirements, and budget.

## When to Use

- User asks "what should we have for dinner?"
- User wants a "weekly meal plan" or "menu for the week"
- User needs a "grocery list" or "shopping list"
- User mentions "meal prep" or "batch cooking"
- User asks about recipes or cooking ideas
- User wants to manage pantry inventory

## Prerequisites

- Family member profiles (ages, preferences)
- Dietary restrictions/allergies stored
- Instacart connection (optional, for ordering)
- Calendar access (for scheduling)

## Workflow Steps

### Step 1: Gather Requirements

Collect meal planning parameters:

```typescript
interface MealPlanRequest {
  duration: number;           // Days to plan (default: 7)
  mealsPerDay: ('breakfast' | 'lunch' | 'dinner' | 'snacks')[];
  servings: number;           // People to feed
  budget?: {
    weekly: number;
    perMeal: number;
  };
  dietaryRestrictions: string[];  // Vegetarian, gluten-free, etc.
  allergies: string[];
  cuisinePreferences: string[];
  cookingTime: 'quick' | 'moderate' | 'elaborate';
  skillLevel: 'beginner' | 'intermediate' | 'advanced';
}
```

### Step 2: Pantry Check

Review current inventory:

```typescript
interface PantryInventory {
  items: PantryItem[];
  expiringSoon: PantryItem[];  // Within 3 days
  staples: {                    // Always keep stocked
    item: string;
    currentLevel: 'full' | 'low' | 'empty';
  }[];
}

interface PantryItem {
  name: string;
  quantity: number;
  unit: string;
  expirationDate?: Date;
  location: 'pantry' | 'fridge' | 'freezer';
}
```

**Prioritize:**
- Use expiring ingredients first
- Build meals around what's available
- Minimize food waste

### Step 3: Generate Meal Plan

Create balanced weekly menu:

```typescript
interface WeeklyMealPlan {
  week: string;               // Week of [date]
  days: DayPlan[];
  nutritionSummary: NutritionInfo;
  estimatedCost: number;
  prepSchedule: PrepTask[];
}

interface DayPlan {
  date: Date;
  meals: {
    breakfast?: Meal;
    lunch?: Meal;
    dinner?: Meal;
    snacks?: Meal[];
  };
}

interface Meal {
  name: string;
  recipe: Recipe;
  prepTime: number;           // Minutes
  cookTime: number;
  servings: number;
  tags: string[];             // Quick, kid-friendly, make-ahead
}
```

**Balance Considerations:**
- Variety in proteins (meat, fish, vegetarian)
- Different cuisines throughout week
- Mix of quick and involved recipes
- Leftover utilization (Sunday roast → Monday sandwiches)

### Step 4: Create Shopping List

Generate organized grocery list:

```typescript
interface GroceryList {
  categories: {
    produce: GroceryItem[];
    protein: GroceryItem[];
    dairy: GroceryItem[];
    pantryStaples: GroceryItem[];
    frozen: GroceryItem[];
    other: GroceryItem[];
  };
  estimatedTotal: number;
  stores: {                   // If multi-store shopping preferred
    store: string;
    items: GroceryItem[];
    estimatedCost: number;
  }[];
}

interface GroceryItem {
  name: string;
  quantity: number;
  unit: string;
  estimatedPrice: number;
  usedIn: string[];           // Which recipes need this
  substitutes?: string[];
  priority: 'essential' | 'nice_to_have';
}
```

### Step 5: Prep Schedule

Create batch cooking schedule:

```typescript
interface PrepSchedule {
  prepDay: Date;              // Usually Sunday
  tasks: PrepTask[];
  totalTime: number;
  equipment: string[];
}

interface PrepTask {
  task: string;
  duration: number;
  forMeals: string[];
  storage: string;            // How to store
  shelfLife: number;          // Days
  instructions: string;
}
```

**Prep Day Tasks:**
- Wash and chop vegetables
- Marinate proteins
- Cook grains (rice, quinoa)
- Prepare sauces/dressings
- Portion snacks

### Step 6: Integration Options

**Instacart Integration:**
```
📝 Grocery List Ready

32 items | Estimated: $127.50

[Order via Instacart] [Export List] [Print]
```

**Calendar Integration:**
- Add "Meal Prep Sunday" event
- Daily dinner reminders with recipe link
- Defrost reminders for frozen items

## Dietary Restriction Handling

| Restriction | Considerations |
|-------------|----------------|
| Vegetarian | No meat/fish, check for hidden gelatin |
| Vegan | No animal products, check for honey/dairy |
| Gluten-free | Verify all ingredients, cross-contamination |
| Dairy-free | Substitute milk, cheese, butter |
| Nut-free | Check for tree nuts, peanuts in all forms |
| Low-sodium | Limit processed foods, adjust seasoning |
| Keto | High fat, very low carb, track macros |

## Family-Friendly Features

- Kid-friendly alternatives for spicy dishes
- Hide vegetables in sauces for picky eaters
- Lunch box ideas for school
- Snack prep for after-school
- Birthday/party menu planning

## Example Interaction

**User**: "Plan our meals for next week. We're vegetarian, my son is allergic to nuts, and we like Indian and Mexican food."

**Assistant**:
```
🍽️ Weekly Meal Plan (Jan 13-19)

MONDAY
  Dinner: Vegetable Tikka Masala with Naan
  ⏱️ 35 min | 👨‍👩‍👦 Serves 4

TUESDAY
  Dinner: Black Bean Tacos with Cilantro Lime Rice
  ⏱️ 25 min | 👨‍👩‍👦 Serves 4 | 🌶️ Kid-mild version

WEDNESDAY
  Dinner: Palak Paneer with Jeera Rice
  ⏱️ 40 min | 👨‍👩‍👦 Serves 4

THURSDAY
  Dinner: Cheese Quesadillas with Guacamole
  ⏱️ 15 min | 👨‍👩‍👦 Serves 4 | ⚡ Quick meal

FRIDAY
  Dinner: Chana Masala with Roti
  ⏱️ 30 min | 👨‍👩‍👦 Serves 4

SATURDAY
  Dinner: Enchilada Casserole
  ⏱️ 45 min | 👨‍👩‍👦 Serves 6 | 📦 Leftovers for Sunday

SUNDAY
  Dinner: Leftover Enchiladas + Fresh Salad
  ⏱️ 10 min | ♻️ Using Saturday's prep

---

📝 Shopping List: 28 items | Est. $95

🥬 Produce (12)     | 🧀 Dairy (5)
🥫 Pantry (8)       | 🧊 Frozen (3)

✅ All recipes are nut-free
✅ All recipes are vegetarian

[View Full Recipes] [Get Grocery List] [Order on Instacart]
```

## Recipe Storage

Save family favorites:

```typescript
interface SavedRecipe {
  id: string;
  name: string;
  source: 'generated' | 'imported' | 'custom';
  rating: number;             // Family rating 1-5
  lastMade: Date;
  notes: string;              // "Kids loved it", "Add more spice"
  modifications: string[];
  tags: string[];
}
```

## Smart Suggestions

- Suggest recipes based on weather (soup on cold days)
- Factor in busy schedule (quick meals on activity nights)
- Holiday/seasonal menu ideas
- Budget-conscious alternatives when needed
- Use sales/coupons from connected stores
