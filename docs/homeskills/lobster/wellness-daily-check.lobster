name: wellness-daily-check
description: Daily wellness check-in — hydration, movement, sleep summary with adaptive nudges
args:
  member_id:
    type: string
    required: true
    description: Family member ID to check on

steps:
  - id: load-prefs
    command: >
      cat ~/clawd/homeos/memory/preferences/wellness/$MEMBER_ID.json 2>/dev/null ||
      echo '{"hydration_goal_oz":64,"step_goal":8000,"sleep_goal_hours":8,"screen_limit_min":120}'

  - id: load-today
    command: >
      cat ~/clawd/homeos/data/wellness/$(date +%Y-%m-%d)_$MEMBER_ID.json 2>/dev/null ||
      echo '{"hydration_oz":0,"steps":0,"sleep_hours":null,"screen_minutes":0}'

  - id: compute-progress
    command: >
      echo '{
        "prefs": '$PREFS',
        "today": '$TODAY',
        "hour": '$(date +%H)'
      }' | jq '
        {
          hydration: {
            current: .today.hydration_oz,
            goal: .prefs.hydration_goal_oz,
            pct: ((.today.hydration_oz / .prefs.hydration_goal_oz * 100) | floor),
            on_track: ((.today.hydration_oz / .prefs.hydration_goal_oz * 100) >= (.hour / 16 * 100))
          },
          steps: {
            current: .today.steps,
            goal: .prefs.step_goal,
            pct: ((.today.steps / .prefs.step_goal * 100) | floor)
          },
          sleep: {
            hours: .today.sleep_hours,
            goal: .prefs.sleep_goal_hours,
            quality: (if .today.sleep_hours == null then "unknown"
              elif .today.sleep_hours >= .prefs.sleep_goal_hours then "good"
              elif .today.sleep_hours >= (.prefs.sleep_goal_hours - 1) then "okay"
              else "poor" end)
          },
          screen: {
            minutes: .today.screen_minutes,
            limit: .prefs.screen_limit_min,
            remaining: (.prefs.screen_limit_min - .today.screen_minutes)
          },
          time_of_day: (if .hour < 12 then "morning" elif .hour < 17 then "afternoon" else "evening" end)
        }'
    stdin: $load-prefs.stdout

  - id: format-report
    command: >
      echo '$input' | jq -r '
        "🌿 WELLNESS CHECK\n\n" +
        "💧 Hydration: " + (.hydration.current | tostring) + "/" + (.hydration.goal | tostring) + " oz (" + (.hydration.pct | tostring) + "%)\n" +
        (if .hydration.on_track then "   ✅ On track!\n" else "   ⚠️ Drink up!\n" end) +
        "\n👣 Steps: " + (.steps.current | tostring) + "/" + (.steps.goal | tostring) + " (" + (.steps.pct | tostring) + "%)\n" +
        "\n😴 Sleep: " + (if .sleep.hours then (.sleep.hours | tostring) + "h — " + .sleep.quality else "Not logged" end) + "\n" +
        "\n📱 Screen: " + (.screen.minutes | tostring) + " min" +
        (if .screen.remaining > 0 then " (" + (.screen.remaining | tostring) + " min left)\n" else " ⚠️ Limit reached\n" end) +
        "\n" +
        (if .time_of_day == "morning" then "💡 Start hydrating early — it adds up!"
        elif .time_of_day == "afternoon" then "💡 Good time for a walk to boost steps!"
        else "💡 Wind down screens for better sleep tonight." end)'
    stdin: $compute-progress.stdout
