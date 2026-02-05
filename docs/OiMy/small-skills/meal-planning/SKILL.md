---
name: meal-planning-small
description: Weekly meal plans, grocery lists, and prep schedules for families. Use when user asks about dinner, meal plans, grocery lists, recipes, meal prep, or what to cook. ALWAYS cross-check allergies against family.json.
version: 1.0-small
risk_default: LOW
---

# Meal Planning Skill (Small-Model)

## RISK RULES

All meal-planning actions are RISK: LOW except:
- IF suggesting a meal with a known allergen → RISK: CRITICAL (never do this)
- IF ordering groceries via handoff → RISK: MEDIUM (confirm with user)

## CONSTRAINT RULES (ALWAYS ENFORCE)

HARD CONSTRAINTS (never violate):
- Allergies from family.json → NEVER include these ingredients
- IF family.json lists a member with allergy to [X], then [X] and all derivatives are BANNED
- IF unsure whether ingredient contains allergen → EXCLUDE it and note why

SOFT PREFERENCES (try to follow, can flex):
- Dietary preferences (vegetarian, low-carb, etc.) → follow when possible
- Cuisine preferences → rotate through liked cuisines
- Budget targets → aim for but can exceed slightly

BEFORE generating any meal plan:
1. Read ~/clawd/homeos/data/family.json
2. Extract ALL allergies for ALL family members
3. Extract dietary preferences
4. Cross-check EVERY suggested meal against allergy list

## STORAGE

Data path: ~/clawd/homeos/data/
Memory path: ~/clawd/homeos/memory/
Files: family.json, pantry.json, recipes.json, mealplan_[DATE].json

## STEP 1 - GATHER INFO

IF family.json exists:
- Read it and confirm: "I have your family info: [COUNT] people, allergies: [LIST], preferences: [LIST]. Still accurate?"

IF family.json does NOT exist:
- Ask: How many people? Any allergies? (CRITICAL) Any dietary preferences? How much weeknight cooking time? Budget level?

Always ask:
- How many days to plan?
- Anything in fridge to use up?
- Any cuisines wanted this week?

## STEP 2 - CHECK PANTRY

IF pantry.json exists:
- Read it and list items expiring soon
- Plan meals around expiring items first

IF pantry.json does NOT exist:
- Ask: What proteins, grains, and produce do you have on hand?

Priority order for ingredient selection:
1. Items expiring soon (reduce waste)
2. Proteins already in freezer
3. Seasonal produce (cheaper and better)
4. Pantry staples needing use

## STEP 3 - GENERATE MEAL PLAN

Template for each day:

🍽️ [DAY_NAME]
- Meal: [MEAL_NAME]
- Time: [COOK_MINUTES] min
- Cuisine: [CUISINE_TYPE]
- Tags: [QUICK/KID-FRIENDLY/BATCH-COOK/LEFTOVER]
- Brief: [ONE_LINE_DESCRIPTION]

Planning rules:
- Same protein max 2x per week
- Mix cuisines across the week
- Monday/Wednesday = quickest meals (busy weeknights)
- Saturday = more elaborate cooking allowed
- Sunday = batch cook OR easy leftovers
- IF a family member is under 10 years old: include at least 2 kid-friendly meals
- IF budget is "budget-friendly": include 1 meatless meal, prefer whole chicken over breasts

Allergy check (DO THIS FOR EVERY MEAL):
- For each meal, list main ingredients mentally
- IF any ingredient matches an allergy in family.json → REPLACE the meal
- IF substitution possible (e.g., dairy-free cheese) → note the substitution explicitly

## STEP 4 - SHOPPING LIST

Template:

🛒 SHOPPING LIST - Week of [DATE]

🥬 PRODUCE
- [ITEM] - [QUANTITY] (for: [WHICH_MEALS])

🐔 PROTEIN
- [ITEM] - [QUANTITY] (for: [WHICH_MEALS])

🧀 DAIRY
- [ITEM] - [QUANTITY] (for: [WHICH_MEALS])

🫘 PANTRY/CANNED
- [ITEM] - [QUANTITY] (for: [WHICH_MEALS])

🍞 BREAD/BAKERY
- [ITEM] - [QUANTITY]

🧊 FROZEN
- [ITEM] - [QUANTITY]

Estimated total: $[AMOUNT]
Total items: [COUNT]

Rules:
- Organize by store section (as shown above)
- Remove items already in pantry.json
- IF item removed because in pantry: mention it ("Skipped [X] - you already have it")
- Show which meals need each item
- Note allergen-free alternatives if relevant

## STEP 5 - PREP SCHEDULE

IF user asks for prep schedule or batch cooking plan:

Template:

👨‍🍳 PREP SCHEDULE - [DAY]

Step 1: [TASK] - [TIME_MINUTES] min
- Details: [WHAT_TO_DO]
- Store: [HOW_TO_STORE] (lasts [DAYS] days)
- Used in: [WHICH_MEALS]

Step 2: [TASK] - [TIME_MINUTES] min
- Details: [WHAT_TO_DO]
- Store: [HOW_TO_STORE]
- Used in: [WHICH_MEALS]

Total prep time: [TOTAL] min

Weeknight time savings:
- [DAY]: [ORIGINAL_TIME] → [NEW_TIME] min (saved [SAVED] min)

## STEP 6 - RECIPES

IF user asks for a specific recipe:

Template:

📝 [RECIPE_NAME]

Servings: [COUNT]
Prep: [MINUTES] min
Cook: [MINUTES] min
Difficulty: [Easy/Medium]

⚠️ Allergen check: [SAFE for all family members / MODIFIED for [NAME]'s [ALLERGY]]

Ingredients:
- [AMOUNT] [INGREDIENT]
- [AMOUNT] [INGREDIENT]

Instructions:
1. [STEP]
2. [STEP]
3. [STEP]

Tips:
- [HELPFUL_TIP]
- Kid-friendly mod: [IF_APPLICABLE]
- Substitution: [IF_APPLICABLE]

## STEP 7 - SAVE

Save meal plan to ~/clawd/homeos/data/mealplan_[DATE].json
Save new favorite recipes to ~/clawd/homeos/data/recipes.json
Update pantry.json after shopping

## MIXED DIETARY NEEDS

IF family members have different dietary needs:
- Plan base meals that work for the most restrictive member
- Suggest add-ons for others (e.g., "add chicken on the side for [NAME]")
- Template:

Base meal (works for everyone): [MEAL]
Add-on for [NAME]: [ADDITION]
Note: [ALLERGEN_SAFE_CONFIRMATION]

## BUDGET STRATEGIES

IF budget = "budget-friendly":
- Suggest meatless Monday
- Prefer whole chicken over parts
- Recommend frozen vegetables (same nutrition, lower cost)
- Suggest batch cooking to get 3 meals from 1 session
- Track weekly spending in mealplan files

## CROSS-SKILL HANDOFFS

IF user wants a calendar event for meal prep day:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "schedule meal prep session", "context": { "title": "Meal Prep Sunday", "date": "[DATE]", "duration": "[HOURS] hours", "notes": "Prep for week of [DATE]" } }
```

IF user wants grocery delivery:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "order groceries", "context": { "items": [LIST_FROM_SHOPPING_LIST], "store_preference": "[STORE]" } }
```

IF user mentions kitchen appliance is broken (can't cook something):
```
OUTPUT_HANDOFF: { "next_skill": "home-maintenance", "reason": "kitchen appliance needs repair", "context": { "appliance": "[APPLIANCE]", "symptom": "[WHAT_HAPPENED]" } }
```

IF user needs ride to grocery store:
```
OUTPUT_HANDOFF: { "next_skill": "transportation", "reason": "need ride to grocery store", "context": { "destination": "[STORE_NAME]", "carrying": "groceries" } }
```

## ERROR HANDLING

IF family.json not found:
- Say: "I don't have your family info yet. Let me ask a few questions to make safe meal plans."
- Ask about allergies FIRST (most critical)
- Save responses to family.json

IF allergy info is ambiguous:
- Default to EXCLUDING the ingredient
- Say: "I'm not sure if [INGREDIENT] is safe for [NAME]'s [ALLERGY], so I've left it out. Let me know if it's okay to include."
