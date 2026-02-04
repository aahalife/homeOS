name: mental-load-briefing
description: Generate morning or evening briefing that consolidates calendar, tasks, weather, school, and medications into one actionable summary
args:
  type:
    type: string
    default: "morning"
    description: Briefing type (morning|evening|weekly)

steps:
  # Step 1: Load family data
  - id: load-family
    command: cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{"members":[]}'

  # Step 2: Get today's calendar events
  - id: load-calendar
    command: >
      cat ~/clawd/homeos/data/calendar.json 2>/dev/null |
      jq --arg today "$(date +%Y-%m-%d)" '[.[] | select(.date == $today)]' || echo '[]'

  # Step 3: Get weather
  - id: get-weather
    command: curl -s "wttr.in/?format=%C+%t+%h" 2>/dev/null || echo "Weather unavailable"

  # Step 4: Get pending tasks and chores
  - id: load-tasks
    command: >
      cat ~/clawd/homeos/tasks/active/*.json 2>/dev/null |
      jq -s '[.[] | select(.status == "pending")]' || echo '[]'

  # Step 5: Check medication reminders
  - id: load-medications
    command: >
      cat ~/clawd/homeos/data/health/family_health.json 2>/dev/null |
      jq '[.members[]? | . as $m | .medications[]? | {member: $m.name, med: .name, dosage: .dosage, times: .times}]' || echo '[]'

  # Step 6: Check school items (if family has children)
  - id: load-school
    command: >
      cat ~/clawd/homeos/data/education/homework_check.json 2>/dev/null |
      jq '.students // []' || echo '[]'

  # Step 7: Compile briefing using LLM for natural language
  - id: compile-briefing
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Create a concise BRIEFING_TYPE briefing from this data. Prioritize by urgency. Group into: priorities (top 3), schedule, reminders. Be warm and encouraging. If morning: focus on today. If evening: summarize today + prep tomorrow. If weekly: overview of week ahead with coordination needs.",
        "input": {
          "type": "$TYPE",
          "calendar": $CALENDAR,
          "weather": "$WEATHER",
          "tasks": $TASKS,
          "medications": $MEDS,
          "school": $SCHOOL,
          "family_count": $FAMILY_COUNT
        },
        "schema": {
          "type": "object",
          "properties": {
            "greeting": {"type": "string"},
            "priorities": {"type": "array", "items": {"type": "string"}},
            "schedule": {"type": "array", "items": {"type": "string"}},
            "reminders": {"type": "array", "items": {"type": "string"}},
            "coordination_needed": {"type": "array", "items": {"type": "string"}},
            "tip": {"type": "string"}
          },
          "required": ["greeting", "priorities", "schedule", "reminders", "tip"],
          "additionalProperties": false
        }
      }'

  # Step 8: Format final briefing
  - id: format-output
    command: >
      echo '$input' | jq -r '
        .greeting + "\n\n" +
        "🎯 PRIORITIES\n" + (.priorities | to_entries | map("  " + (.key + 1 | tostring) + ". " + .value) | join("\n")) + "\n\n" +
        "📅 SCHEDULE\n" + (.schedule | map("  • " + .) | join("\n")) + "\n\n" +
        "🔔 REMINDERS\n" + (.reminders | map("  • " + .) | join("\n")) + "\n\n" +
        (if (.coordination_needed // [] | length) > 0
         then "⚠️ COORDINATION NEEDED\n" + (.coordination_needed | map("  • " + .) | join("\n")) + "\n\n"
         else "" end) +
        "💡 " + .tip'
    stdin: $compile-briefing.stdout
