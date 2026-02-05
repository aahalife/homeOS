name: note-to-actions-extract
description: Transform content (article, video, idea) into atomic habits with implementation plan
args:
  content:
    type: string
    required: true
    description: URL, text, or description of content to process

steps:
  - id: detect-content-type
    command: >
      echo "$CONTENT" | jq -R '{
        input: .,
        type: (if test("^https?://") then "url"
               elif test("youtube|youtu.be") then "video"
               else "text" end)
      }'

  - id: fetch-content
    command: >
      if echo '$type' | jq -r '.type' | grep -q "url"; then
        openclaw.invoke --tool web_fetch --args-json '{"url": "$CONTENT", "maxChars": 5000}'
      else
        echo '{"text": "$CONTENT"}'
      fi
    stdin: $detect-content-type.stdout

  - id: extract-insights
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Extract 3-5 key insights from this content. For each insight, identify one concrete behavior change it suggests. Focus on actionable takeaways, not theory.",
        "input": $CONTENT_TEXT,
        "schema": {
          "type": "object",
          "properties": {
            "title": {"type": "string"},
            "summary": {"type": "string"},
            "insights": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "insight": {"type": "string"},
                  "behavior": {"type": "string"},
                  "difficulty": {"type": "string"}
                },
                "required": ["insight", "behavior", "difficulty"]
              }
            }
          },
          "required": ["title", "summary", "insights"]
        }
      }'

  - id: create-atomic-habits
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "For each insight, create an atomic habit using the 4 Laws framework. The atomic version must be doable in under 2 minutes. Be specific — not vague.",
        "input": $INSIGHTS,
        "schema": {
          "type": "object",
          "properties": {
            "habits": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "atomicVersion": {"type": "string"},
                  "cue": {"type": "string"},
                  "craving": {"type": "string"},
                  "response": {"type": "string"},
                  "reward": {"type": "string"},
                  "implementationIntention": {"type": "string"}
                },
                "required": ["name", "atomicVersion", "cue", "craving", "response", "reward", "implementationIntention"]
              }
            },
            "recommended_first": {"type": "integer"}
          },
          "required": ["habits", "recommended_first"]
        }
      }'
    stdin: $extract-insights.stdout

  - id: format-output
    command: >
      echo '$input' | jq -r '
        "📝 CONTENT ANALYZED\n\n" +
        "━━━ KEY INSIGHTS ━━━\n\n" +
        ($INSIGHTS.insights | to_entries | map(
          ((.key + 1) | tostring) + ". " + .value.insight + "\n" +
          "   → Behavior: " + .value.behavior + "\n"
        ) | join("\n")) +
        "\n━━━ ATOMIC HABITS ━━━\n\n" +
        (.habits | to_entries | map(
          "⚛️ " + .value.name + "\n" +
          "   Do this: \"" + .value.atomicVersion + "\"\n" +
          "   When: " + .value.cue + "\n" +
          "   Why it works: " + .value.craving + "\n" +
          "   Reward: " + .value.reward + "\n"
        ) | join("\n")) +
        "\n🎯 START WITH: #" + (.recommended_first | tostring) + " — easiest to begin, highest impact.\n\n" +
        "Want me to activate this habit with daily check-ins?"'
    stdin: $create-atomic-habits.stdout

  - id: approve-activate
    command: approve --preview-from-stdin --prompt "Activate habit tracking for the recommended habit?"
    stdin: $format-output.stdout
    approval: required

  - id: save-habit
    command: >
      echo '$habits' | jq --arg idx "$RECOMMENDED" '.habits[($idx | tonumber)] | {
        id: ("habit-" + (now | tostring)),
        name: .name,
        member_id: "current_user",
        atomic_version: .atomicVersion,
        cue: .cue,
        reward: .reward,
        stage: "preparation",
        current_streak: 0,
        best_streak: 0,
        completion_log: [],
        created_at: (now | todate)
      }' >> ~/clawd/homeos/data/habits/active_habits.json
    stdin: $create-atomic-habits.stdout
    condition: $approve-activate.approved
