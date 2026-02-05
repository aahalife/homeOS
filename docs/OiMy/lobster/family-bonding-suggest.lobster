name: family-bonding-suggest
description: Suggest family activities based on ages, weather, budget, and preferences
args:
  activity_type:
    type: string
    default: "any"
    description: Type (indoor|outdoor|any)
  budget:
    type: string
    default: "moderate"
    description: Budget (free|budget|moderate|splurge)

steps:
  - id: load-family
    command: >
      cat ~/clawd/homeos/data/family.json 2>/dev/null |
      jq '{
        members: [.members[] | {name, role, age, interests: .preferences.activities}],
        child_ages: [.members[] | select(.role == "child") | .age],
        has_toddlers: ([.members[] | select(.role == "child" and .age <= 3)] | length > 0),
        has_teens: ([.members[] | select(.role == "child" and .age >= 13)] | length > 0)
      }' || echo '{"members":[],"child_ages":[],"has_toddlers":false,"has_teens":false}'

  - id: get-weather
    command: curl -s "wttr.in/?format=j1" 2>/dev/null | jq '{temp_f: .current_condition[0].temp_F, condition: .current_condition[0].weatherDesc[0].value}' || echo '{"temp_f":"72","condition":"Clear"}'

  - id: check-history
    command: >
      cat ~/clawd/homeos/memory/preferences/activities.json 2>/dev/null |
      jq '[.[-5:].[].activity] // []' || echo '[]'

  - id: generate-suggestions
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Suggest 5 family activities. Family: FAMILY_INFO. Weather: WEATHER. Budget: BUDGET. Type: ACTIVITY_TYPE. Recent activities to avoid repeating: RECENT. Rules: must work for ALL ages present. If toddlers: no activities requiring sitting still. If teens: nothing they would find boring. Include mix of active and relaxed. Each needs: name, duration, estimated cost, age suitability, what makes it fun.",
        "input": {
          "family": $FAMILY,
          "weather": $WEATHER,
          "recent": $RECENT,
          "budget": "$BUDGET",
          "type": "$ACTIVITY_TYPE"
        },
        "schema": {
          "type": "object",
          "properties": {
            "activities": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "duration": {"type": "string"},
                  "cost": {"type": "string"},
                  "ages": {"type": "string"},
                  "whyFun": {"type": "string"},
                  "location": {"type": "string"}
                },
                "required": ["name", "duration", "cost", "ages", "whyFun"]
              }
            }
          },
          "required": ["activities"]
        }
      }'

  - id: format-suggestions
    command: >
      echo '$input' | jq -r '
        "🌟 FAMILY ACTIVITY IDEAS\n\n" +
        "🌤️ Weather: " + "$WEATHER_DESC" + " " + "$TEMP" + "°F\n" +
        "💰 Budget: " + "$BUDGET" + "\n\n" +
        (.activities | to_entries | map(
          ((.key + 1) | tostring) + ". " + .value.name + "\n" +
          "   ⏱️ " + .value.duration + " • 💰 " + .value.cost + "\n" +
          "   👶 Ages: " + .value.ages + "\n" +
          "   ✨ " + .value.whyFun + "\n" +
          (if .value.location then "   📍 " + .value.location + "\n" else "" end)
        ) | join("\n")) +
        "\nPick one and I will help plan it!"'
    stdin: $generate-suggestions.stdout
