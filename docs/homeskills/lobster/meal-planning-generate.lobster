name: meal-planning-generate
description: Generate a weekly meal plan, grocery list, and prep schedule for the family
args:
  days:
    type: integer
    default: 7
    description: Number of days to plan
  budget:
    type: string
    default: "moderate"
    description: Budget level (budget|moderate|splurge)

steps:
  # Step 1: Load family data for dietary constraints
  - id: load-family
    command: cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{"members":[]}'

  # Step 2: Extract dietary restrictions and allergies (SAFETY CRITICAL)
  - id: extract-constraints
    command: >
      echo '$input' | jq '{
        member_count: (.members | length),
        has_children: ([.members[] | select(.role == "child")] | length > 0),
        dietary: [.members[].preferences.dietary // [] | .[]] | unique,
        allergies: [.members[].allergies // [] | .[]] | unique,
        cuisines: [.members[].preferences.cuisines // [] | .[]] | unique
      }'
    stdin: $load-family.stdout

  # Step 3: Check recent meals to avoid repeats
  - id: recent-meals
    command: cat ~/clawd/homeos/data/meal_history.json 2>/dev/null | jq '[.[-3:].[].name] // []' || echo '[]'

  # Step 4: Check pantry for items to use up
  - id: check-pantry
    command: cat ~/clawd/homeos/data/pantry.json 2>/dev/null | jq '[.items[] | select(.quantity > 0)] // []' || echo '[]'

  # Step 5: Generate meal plan using LLM (structured output)
  - id: generate-plan
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Create a DAYS-day dinner meal plan. Family: MEMBER_COUNT people. Dietary: DIETARY. Allergies (MUST AVOID): ALLERGIES. Budget: BUDGET. Recent meals to avoid: RECENT. Pantry items to use: PANTRY. Rules: weeknights under 30min, variety in proteins and cuisines, max 2 chicken dishes, include 1 meatless day. HAS_CHILDREN_NOTE",
        "schema": {
          "type": "object",
          "properties": {
            "meals": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "day": {"type": "string"},
                  "name": {"type": "string"},
                  "cuisine": {"type": "string"},
                  "prepMinutes": {"type": "integer"},
                  "description": {"type": "string"},
                  "keyIngredients": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["day", "name", "cuisine", "prepMinutes", "description", "keyIngredients"]
              }
            },
            "estimatedWeeklyCost": {"type": "string"}
          },
          "required": ["meals", "estimatedWeeklyCost"],
          "additionalProperties": false
        }
      }'

  # Step 6: Generate grocery list from the meal plan
  - id: generate-grocery
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Generate a grocery list grouped by store section for these meals. Only include items that need to be purchased (check against pantry). Include quantities.",
        "input": $PLAN_AND_PANTRY,
        "schema": {
          "type": "object",
          "properties": {
            "sections": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "section": {"type": "string"},
                  "items": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "name": {"type": "string"},
                        "quantity": {"type": "string"},
                        "estimatedPrice": {"type": "string"}
                      },
                      "required": ["name", "quantity"]
                    }
                  }
                },
                "required": ["section", "items"]
              }
            },
            "estimatedTotal": {"type": "string"}
          },
          "required": ["sections", "estimatedTotal"],
          "additionalProperties": false
        }
      }'
    stdin: $generate-plan.stdout

  # Step 7: Present plan and grocery list for approval
  - id: approve-plan
    command: approve --preview-from-stdin --limit 20 --prompt "Here is your meal plan and grocery list. Approve to save?"
    stdin: $generate-grocery.stdout
    approval: required

  # Step 8: Save the approved meal plan
  - id: save-plan
    command: >
      echo '$plan' | jq '.meals' > ~/clawd/homeos/data/current_meal_plan.json &&
      echo '$grocery' > ~/clawd/homeos/data/current_grocery_list.json &&
      echo '{"status": "saved", "message": "Meal plan and grocery list saved!"}'
    stdin: $generate-plan.stdout
    condition: $approve-plan.approved

  # Step 9: Set meal prep reminders
  - id: set-reminders
    command: >
      openclaw.invoke --tool message --action send --args-json '{
        "message": "📅 Your meal plan is ready! Sunday prep day reminder set.",
        "provider": "current"
      }'
    condition: $approve-plan.approved
