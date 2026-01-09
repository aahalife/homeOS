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

## Storage Setup

```bash
mkdir -p ~/clawd/homeos/data
# Initialize files if they don't exist
[ ! -f ~/clawd/homeos/data/pantry.json ] && echo '{"items": [], "updated": "'$(date -Iseconds)'"}' > ~/clawd/homeos/data/pantry.json
[ ! -f ~/clawd/homeos/data/recipes.json ] && echo '{"favorites": [], "tried": []}' > ~/clawd/homeos/data/recipes.json
```

## Workflow Overview

```
1. Gather Requirements → 2. Check Pantry → 3. Generate Meal Plan 
→ 4. Create Shopping List → 5. Prep Schedule → 6. Save & Track
```

## Step 1: Gather Requirements

**Check stored family info first:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members[] | {name, dietary: .preferences.dietary, allergies}'
```

**Collect meal planning parameters:**
```
🍽️ Let's plan your meals! A few questions:

1. 📅 How many days? (I usually do 5-7)
2. 👥 How many people eating?
3. 🌿 Any dietary needs? (vegetarian, gluten-free, allergies?)
4. ⏰ How much cooking time on weeknights? (15/30/45 min?)
5. 💰 Budget range? (budget-friendly / moderate / splurge)
6. 🍽️ Any cuisines you love or want to avoid?
```

**If family info exists, confirm:**
```
I have your family info saved:
- [X] people
- Dietary: [restrictions]
- Allergies: [allergies]

Is this still accurate, or any changes?
```

## Step 2: Check Pantry

**Review what's on hand:**
```bash
cat ~/clawd/homeos/data/pantry.json 2>/dev/null | jq '.items[] | select(.quantity > 0)'
```

**Ask about pantry status:**
```
🥫 Pantry Check

Before I plan, what do you have on hand?

1. 🚀 Proteins? (chicken, ground beef, tofu, fish, eggs?)
2. 🍚 Grains/starches? (rice, pasta, bread, potatoes?)
3. 🥬 Fresh produce to use up?
4. 🧀 Dairy? (milk, cheese, yogurt?)
5. 🫘 Anything expiring soon?

I'll build meals around what you have to minimize waste and cost.
```

**Prioritize using:**
- Items expiring soon
- Proteins already in freezer
- Seasonal produce (cheaper, better quality)
- Pantry staples that need using

## Step 3: Generate Meal Plan

**Create balanced weekly menu:**

```
📅 WEEKLY MEAL PLAN: [Week of DATE]

Family: [X] people | Budget: [LEVEL] | Time: [X] min weeknights

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MONDAY
  🍽️ [Dinner Name]
  ⏱️ [X] min | [Cuisine] | [Tags: quick, kid-friendly, etc.]
  📝 [Brief description]

TUESDAY  
  🍽️ [Dinner Name]
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]

WEDNESDAY
  🍽️ [Dinner Name]
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]

THURSDAY
  🍽️ [Dinner Name] 
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]

FRIDAY
  🍽️ [Dinner Name]
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]

SATURDAY
  🍽️ [Dinner Name] - [More elaborate weekend meal]
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]

SUNDAY
  🍽️ [Dinner Name] - [Batch cook for week ahead]
  ⏱️ [X] min | [Cuisine]
  📝 [Brief description]
  📦 Leftovers: [How to use through week]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ Highlights:
• [Balance note - variety, nutrition]
• [Budget note - if applicable]
• [Prep efficiency note]

Want to swap any meals or see the full recipes?
```

**Meal planning principles:**
- Variety in proteins (chicken 2x max, mix in fish, vegetarian, beef)
- Different cuisines throughout week (Italian, Mexican, Asian, American)
- Quick meals on busy nights (Monday, Wednesday)
- More elaborate on weekends
- Use Sunday batch cooking for weeknight shortcuts
- Leftover integration (roast chicken → chicken salad next day)

## Step 4: Create Shopping List

**Generate organized grocery list:**

```
🛒 SHOPPING LIST

For: [Week of DATE] | Est. Total: $[AMOUNT]

🥬 PRODUCE
☐ [Item] - [Quantity] - $[Est.] - (for: [Meals])
☐ [Item] - [Quantity] - $[Est.]
☐ [Item] - [Quantity] - $[Est.]

🐔 PROTEIN
☐ [Item] - [Quantity] - $[Est.]
☐ [Item] - [Quantity] - $[Est.]

🧀 DAIRY
☐ [Item] - [Quantity] - $[Est.]
☐ [Item] - [Quantity] - $[Est.]

🍞 BAKERY/BREAD
☐ [Item] - [Quantity] - $[Est.]

🫘 PANTRY (if needed)
☐ [Item] - [Quantity] - $[Est.]

🧃 FROZEN
☐ [Item] - [Quantity] - $[Est.]

━━━━━━━━━━━━━━━━━━━━━━━━

Total items: [X]
Estimated total: $[AMOUNT]

💡 Tips:
• [Store-specific tip if relevant]
• [Substitution option]
```

**Shopping list features:**
- Organized by store section
- Quantities specified
- Shows which meals need each item
- Suggests substitutions
- Flags sale items if known

**Cross-check with pantry:**
```
I removed these since you already have them:
• [Item] - you have [quantity]
• [Item] - you have [quantity]

Saving you ~$[amount]
```

## Step 5: Prep Schedule

**Create batch cooking plan:**

```
👨‍🍳 PREP SCHEDULE

Sunday Prep Day - [X] hours total

1. ⏱️ [15 min] Wash & chop vegetables
   - Onions for [meals]
   - Peppers for [meals]
   - Lettuce for salads
   ➡️ Store: airtight containers in fridge (5 days)

2. ⏱️ [20 min] Cook grains
   - [2 cups rice] for [meals]
   - [Quinoa] for [meals]
   ➡️ Store: fridge in containers (5 days)

3. ⏱️ [30 min] Prep proteins
   - Marinate [chicken] for Tuesday
   - Brown [ground beef] for Thursday
   ➡️ Store: marinated in fridge, cooked in fridge

4. ⏱️ [15 min] Make sauce/dressing
   - [Sauce name] for [meals]
   ➡️ Store: jar in fridge (1 week)

━━━━━━━━━━━━━━━━━━━━━━━━

Weeknight shortcuts from this prep:
• Monday: Just assemble, veggies ready
• Tuesday: Chicken marinated, grill + serve
• etc.
```

## Step 6: Provide Recipes

**When user asks for a specific recipe:**

```
📝 [RECIPE NAME]

Servings: [X] | Prep: [X] min | Cook: [X] min
Difficulty: [Easy/Medium/Advanced]

INGREDIENTS:
• [Amount] [Ingredient]
• [Amount] [Ingredient]
• [Amount] [Ingredient]

INSTRUCTIONS:
1. [Step 1]
2. [Step 2]
3. [Step 3]
4. [Step 4]
5. [Step 5]

💡 Tips:
• [Helpful tip]
• [Make-ahead option]
• [Substitution if relevant]

👶 Kid-friendly mod: [If applicable]
🌿 Vegetarian mod: [If applicable]
```

**Save favorite recipes:**
```bash
cat >> ~/clawd/homeos/data/recipes.json << 'EOF'
{
  "name": "RECIPE_NAME",
  "cuisine": "CUISINE",
  "prep_time": 15,
  "cook_time": 30,
  "servings": 4,
  "ingredients": ["list", "of", "ingredients"],
  "instructions": ["step 1", "step 2"],
  "rating": 5,
  "notes": "Family loved it",
  "last_made": "DATE"
}
EOF
```

## Step 7: Save & Track

**Save the meal plan:**
```bash
cat > ~/clawd/homeos/data/mealplan_$(date +%Y%m%d).json << 'EOF'
{
  "week_of": "DATE",
  "days": [
    {"day": "Monday", "dinner": "MEAL"},
    {"day": "Tuesday", "dinner": "MEAL"},
    ...
  ],
  "shopping_list": [...],
  "estimated_cost": AMOUNT
}
EOF
```

**Update pantry after shopping:**
```
Did you get everything on the list? I'll update your pantry.

[After confirmation, update pantry.json with new items]
```

## Handling Dietary Restrictions

**Common restrictions and adaptations:**

| Restriction | Swap Ideas |
|-------------|------------|
| Vegetarian | Tofu, tempeh, beans, lentils, eggs |
| Vegan | All above minus eggs + dairy subs |
| Gluten-free | Rice, quinoa, GF pasta, corn tortillas |
| Dairy-free | Oat milk, coconut cream, nutritional yeast |
| Low-carb | Cauliflower rice, zucchini noodles, lettuce wraps |
| Nut-free | Sunflower seeds, pumpkin seeds for crunch |

**When family has mixed needs:**
```
I see you have mixed dietary needs:
• [Person 1]: [Restriction]
• [Person 2]: No restrictions

I'll suggest meals that work for everyone, with easy modifications:
• Base recipe everyone can eat
• Add-ons for those who can have them
```

## Budget Optimization

**Budget-friendly strategies:**
```
💰 Budget Tips for This Week:

1. Buy whole chicken ($X) vs. breasts ($Y) - save $Z
2. [Store] has [item] on sale this week
3. Frozen [vegetable] same nutrition, half price
4. Batch cook [item] - 3 meals from 1 cooking session
5. Meatless Monday saves ~$X this week
```

**Track spending:**
```
Last 4 weeks grocery spending:
• Week 1: $[X]
• Week 2: $[X]
• Week 3: $[X]
• Week 4: $[X]
Average: $[X]/week

This week's plan: $[X] - [above/below] average
```

## Example Interaction

**User:** "Plan meals for this week. We're vegetarian, 2 adults, like Indian and Mexican food, 30 min max on weeknights."

**Assistant:**
```
Perfect! Vegetarian meals with Indian & Mexican flair coming up. 🌿

Quick check - anything you need to use up from the fridge?
```

**User:** "Some spinach that's getting old, and bell peppers"

**Assistant:**
```
📅 WEEKLY MEAL PLAN: Jan 13-19

Family: 2 vegetarians | Budget: Moderate | ⏱️ 30 min weeknights
✨ Using up: spinach, bell peppers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MONDAY
  🍽️ Palak Paneer with Naan
  ⏱️ 30 min | Indian | Uses: spinach!
  📝 Creamy spinach curry with cheese cubes

TUESDAY
  🍽️ Black Bean Fajitas
  ⏱️ 25 min | Mexican | Uses: bell peppers!
  📝 Sizzling peppers & onions with beans, fixings

WEDNESDAY
  🍽️ Chana Masala with Rice
  ⏱️ 25 min | Indian | ⚡ Pantry meal
  📝 Spiced chickpea curry, aromatic rice

THURSDAY
  🍽️ Cheese Quesadillas + Guacamole
  ⏱️ 15 min | Mexican | ⚡ Quick night!
  📝 Easy cheesy quesadillas, fresh guac & salsa

FRIDAY
  🍽️ Vegetable Biryani
  ⏱️ 35 min | Indian | Uses: remaining peppers
  📝 Fragrant rice with mixed vegetables

SATURDAY
  🍽️ Enchilada Casserole
  ⏱️ 45 min | Mexican | 👨‍🍳 Weekend cooking
  📝 Layered tortillas, beans, cheese, red sauce
  📦 Makes enough for Sunday leftovers!

SUNDAY
  🍽️ Leftover Enchilada Bowls + Salad
  ⏱️ 10 min | ♻️ Easy night
  📝 Saturday's casserole over rice with fresh toppings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ This plan:
• Uses your spinach (Mon) and peppers (Tue, Fri)
• Mix of Indian (3) and Mexican (4) meals
• All under 30 min except Sat weekend cooking
• Sunday = easy leftovers!

Want the shopping list, or any swaps?
```

**User:** "Looks great! Give me the shopping list"

**Assistant:**
```
🛒 SHOPPING LIST

For: Jan 13-19 | Est. Total: $65-75

🥬 PRODUCE
☐ Onions, 3 large - $2
☐ Tomatoes, 4 medium - $3
☐ Cilantro, 1 bunch - $1
☐ Limes, 4 - $2
☐ Avocados, 3 - $4
☐ Garlic, 1 head - $1
☐ Ginger, small piece - $1
(Spinach & peppers - using what you have!)

🧀 DAIRY
☐ Paneer, 14oz block - $6
☐ Shredded Mexican cheese, 16oz - $5
☐ Sour cream, 8oz - $2

🫘 CANNED/DRY
☐ Chickpeas, 2 cans - $3
☐ Black beans, 2 cans - $3
☐ Diced tomatoes, 2 cans - $3
☐ Enchilada sauce, 2 cans - $4
☐ Basmati rice, 2 lb bag - $4
☐ Flour tortillas, 2 packs - $5

🌶️ SPICES (check pantry first!)
☐ Garam masala - $4
☐ Cumin - $3
☐ Chili powder - $3

🍞 BREAD
☐ Naan bread, 4 pack - $4

━━━━━━━━━━━━━━━━━━━━━━━━

Total: ~24 items
Estimated: $65-75

💡 Tips:
• Check your spice cabinet - you might have these
• Trader Joe's has great prices on paneer
• Buy 3 avocados at different ripeness levels

Ready to shop! Want the prep schedule too?
```
