name: habits-checkin
description: Daily habit check-in — ask about completion, update streaks, provide adaptive encouragement
args:
  member_id:
    type: string
    required: true
    description: Member to check in with

steps:
  - id: load-habits
    command: >
      cat ~/clawd/homeos/data/habits/active_habits.json 2>/dev/null |
      jq --arg mid "$MEMBER_ID" '[.[] | select(.member_id == $mid)]' || echo '[]'

  - id: check-empty
    command: >
      echo '$input' | jq 'if length == 0
        then {"status": "none", "message": "You have no active habits. Want to start one?"}
        else {"status": "active", "habits": ., "count": length}
        end'
    stdin: $load-habits.stdout

  - id: compute-streaks
    command: >
      echo '$input' | jq --arg today "$(date +%Y-%m-%d)" --arg yesterday "$(date -d '-1 day' +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)" '
        .habits | map(
          . + {
            completed_today: (.completion_log | index($today) != null),
            completed_yesterday: (.completion_log | index($yesterday) != null),
            success_rate: (if (.completion_log | length) > 0
              then ((.completion_log | length) / (((now - (.created_at | fromdateiso8601)) / 86400) | ceil | fmax(1)) * 100 | floor)
              else 0 end)
          }
        )'
    stdin: $check-empty.stdout
    condition: $check-empty.json.status == "active"

  - id: format-checkin
    command: >
      echo '$input' | jq -r '
        "💬 HABIT CHECK-IN\n\n" +
        (to_entries | map(
          "🎯 " + .value.name + "\n" +
          "   Atomic: \"" + .value.atomic_version + "\"\n" +
          "   🔥 Streak: " + (.value.current_streak | tostring) + " days\n" +
          "   📊 Success: " + (.value.success_rate | tostring) + "%\n" +
          (if .value.completed_today then "   ✅ Done today!\n"
           else "   ☐ Not yet — did you do it?\n" end)
        ) | join("\n")) +
        "\n\nUpdate your habits by saying \"done [habit name]\" or \"missed [habit name]\""'
    stdin: $compute-streaks.stdout

  - id: generate-encouragement
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Generate a brief (1-2 sentence) encouraging message for someone with these habit stats. Be warm and genuine, not generic. Reference their specific streak or success rate.",
        "input": $HABIT_STATS,
        "schema": {
          "type": "object",
          "properties": {
            "message": {"type": "string"}
          },
          "required": ["message"],
          "additionalProperties": false
        }
      }'
    stdin: $compute-streaks.stdout
