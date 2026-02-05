name: home-maintenance-emergency
description: Triage home emergencies with safety-first instructions and service provider lookup
args:
  issue:
    type: string
    required: true
    description: Description of the home issue

steps:
  # Step 1: Classify the issue severity (deterministic rules first)
  - id: classify-severity
    command: >
      echo "$ISSUE" | tr '[:upper:]' '[:lower:]' | jq -R '{issue: .} |
        if (.issue | test("gas|smell gas|gas leak")) then
          {severity: "emergency", type: "gas", instructions: "EXIT_IMMEDIATELY"}
        elif (.issue | test("fire|smoke|burning|sparks")) then
          {severity: "emergency", type: "fire", instructions: "EXIT_CALL_911"}
        elif (.issue | test("flood|major leak|burst pipe|sewage")) then
          {severity: "emergency", type: "water", instructions: "SHUTOFF_WATER"}
        elif (.issue | test("no heat|freezing|furnace out")) then
          {severity: "urgent", type: "heating", instructions: "KEEP_WARM_CALL_HVAC"}
        elif (.issue | test("no ac|air conditioning|cooling")) then
          {severity: "urgent", type: "cooling", instructions: "STAY_COOL_CALL_HVAC"}
        elif (.issue | test("power out|no electricity|breaker")) then
          {severity: "urgent", type: "electrical", instructions: "CHECK_BREAKER"}
        elif (.issue | test("leak|drip|clog|running toilet")) then
          {severity: "routine", type: "plumbing", instructions: "DIY_OR_PRO"}
        else
          {severity: "routine", type: "general", instructions: "ASSESS_AND_ADVISE"}
        end'

  # Step 2: Get safety instructions for emergencies
  - id: safety-instructions
    command: >
      echo '$input' | jq -r '
        if .severity == "emergency" then
          if .type == "gas" then
            "🚨 GAS EMERGENCY — DO THIS NOW:\n\n" +
            "1. DO NOT touch ANY switches or appliances\n" +
            "2. DO NOT use your phone inside\n" +
            "3. Open windows as you exit\n" +
            "4. Get everyone outside NOW\n" +
            "5. Call gas company from OUTSIDE\n" +
            "6. Call 911 if smell is strong\n\n" +
            "❌ DO NOT: light flames, flip switches, start car in garage"
          elif .type == "fire" then
            "🚨 FIRE EMERGENCY:\n\n" +
            "1. Get everyone out immediately\n" +
            "2. Call 911\n" +
            "3. Do NOT go back inside\n" +
            "4. Meet at your designated spot"
          else
            "🚨 WATER EMERGENCY:\n\n" +
            "1. TURN OFF MAIN WATER VALVE\n" +
            "   Typical locations: basement, near water heater, garage, street meter\n" +
            "2. Turn off electricity in affected areas\n" +
            "3. Move valuables away from water\n" +
            "4. Take photos for insurance\n" +
            "5. Call emergency plumber"
          end
        elif .severity == "urgent" then
          "⚠️ URGENT — Quick checks first:\n" + .instructions
        else
          "🔧 Let me help assess this."
        end'
    stdin: $classify-severity.stdout

  # Step 3: Load saved service providers
  - id: load-providers
    command: >
      echo '$input' | jq --slurpfile providers <(cat ~/clawd/homeos/data/providers.json 2>/dev/null || echo '{}') '
        .type as $type |
        if $type == "plumbing" or $type == "water" then ($providers[0].plumber // null)
        elif $type == "electrical" then ($providers[0].electrician // null)
        elif $type == "heating" or $type == "cooling" then ($providers[0].hvac // null)
        else ($providers[0].handyman // null)
        end |
        if . then {found: true, provider: .}
        else {found: false, search_term: (
          if $type == "water" or $type == "plumbing" then "emergency plumber"
          elif $type == "electrical" then "emergency electrician"
          elif $type == "heating" or $type == "cooling" then "emergency HVAC"
          else "handyman"
          end
        )}
        end'
    stdin: $classify-severity.stdout

  # Step 4: Compile full response
  - id: compile-response
    command: >
      echo '{
        "severity": '$SEVERITY',
        "safety": "$SAFETY_TEXT",
        "provider": '$PROVIDER'
      }' | jq -r '
        .safety + "\n\n" +
        "━━━━━━━━━━━━━━━━━━━\n\n" +
        if .provider.found then
          "📞 YOUR SAVED PRO:\n" +
          "  " + .provider.provider.name + "\n" +
          "  📞 " + .provider.provider.phone + "\n" +
          "  ⭐ Rating: " + (.provider.provider.rating | tostring) + "/5\n"
        else
          "🔍 FIND HELP:\n" +
          "  Search: \"" + .provider.search_term + " near me\"\n" +
          "  google.com/search?q=" + (.provider.search_term | gsub(" "; "+")) + "+near+me\n"
        end'

  # Step 5: Log the incident
  - id: log-incident
    command: >
      echo '$(date -Iseconds) | HOME_EMERGENCY | severity:$SEVERITY_LEVEL | type:$TYPE | issue:$ISSUE' >> ~/clawd/homeos/logs/actions.log
