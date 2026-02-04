name: hire-helper-search
description: Guide the process of finding and screening household help (babysitter, cleaner, tutor, etc.)
args:
  helper_type:
    type: string
    required: true
    description: Type of helper (babysitter|nanny|housekeeper|tutor|caregiver|pet-sitter)

steps:
  - id: load-family
    command: cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{"members":[]}'

  - id: determine-requirements
    command: >
      echo '{
        "helper_type": "$HELPER_TYPE",
        "family": '$FAMILY'
      }' | jq '
        if .helper_type == "babysitter" or .helper_type == "nanny" then
          {
            type: .helper_type,
            children: [.family.members[] | select(.role == "child") | {name, age}],
            child_count: ([.family.members[] | select(.role == "child")] | length),
            requirements: {
              cpr_required: true,
              background_check: "REQUIRED",
              own_transport: "preferred",
              rate_range: "$15-30/hr"
            },
            safety_notes: [
              "🔒 Background check REQUIRED for all childcare providers",
              "📞 Always call 2-3 references (actually call, don't skip)",
              "👥 First meeting in public place or with another adult home",
              "🚫 Never share exact address before meeting"
            ]
          }
        elif .helper_type == "housekeeper" then
          {
            type: .helper_type,
            requirements: {
              background_check: "recommended",
              insured: "preferred",
              rate_range: "$25-50/hr"
            },
            safety_notes: ["🔒 Background check recommended for home access"]
          }
        elif .helper_type == "tutor" then
          {
            type: .helper_type,
            students: [.family.members[] | select(.role == "child") | {name, age}],
            requirements: {
              background_check: "recommended",
              rate_range: "$25-75/hr"
            },
            safety_notes: []
          }
        else
          {
            type: .helper_type,
            requirements: {background_check: "recommended", rate_range: "varies"},
            safety_notes: []
          }
        end'
    stdin: $load-family.stdout

  - id: generate-posting
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Create a job posting for a HELPER_TYPE. Family details: REQUIREMENTS. Keep it friendly, specific, and professional. Include: intro, what you need, schedule flexibility, rate range, what to include in application.",
        "schema": {
          "type": "object",
          "properties": {
            "title": {"type": "string"},
            "posting": {"type": "string"}
          },
          "required": ["title", "posting"]
        }
      }'

  - id: create-screening-checklist
    command: >
      echo '$reqs' | jq -r '
        "✅ SCREENING CHECKLIST: " + .type + "\n\n" +
        "📋 PROFILE REVIEW:\n" +
        "  ☐ Experience matches needs\n" +
        "  ☐ Availability aligns\n" +
        "  ☐ Rate within " + .requirements.rate_range + "\n" +
        "  ☐ Recent positive reviews\n" +
        "  ☐ Professional communication\n\n" +
        "🔍 BACKGROUND CHECK: " + .requirements.background_check + "\n\n" +
        "🚩 RED FLAGS (reject if any):\n" +
        "  ☐ Cannot provide references\n" +
        "  ☐ Reluctant about background check\n" +
        "  ☐ Wants to communicate off-platform\n" +
        "  ☐ Vague about experience\n" +
        "  ☐ Inconsistent work history\n" +
        "  ☐ Asks for payment before starting\n\n" +
        (.safety_notes | map("⚠️ " + .) | join("\n"))'
    stdin: $determine-requirements.stdout

  - id: approve-posting
    command: approve --preview-from-stdin --prompt "Use this job posting and screening checklist?"
    stdin: $create-screening-checklist.stdout
    approval: required

  - id: compile-output
    command: >
    condition: $approve-posting.approved
      echo '{
        "posting": '$POSTING',
        "checklist": "$CHECKLIST",
        "search_platforms": [
          "Care.com — largest network, background checks available",
          "Sittercity — focus on childcare",
          "UrbanSitter — friend connections",
          "Nextdoor — local recommendations (free)",
          "Facebook Groups — local community groups"
        ]
      }' | jq -r '
        "👤 FINDING A " + ("$HELPER_TYPE" | ascii_upcase) + "\n\n" +
        "📝 JOB POSTING DRAFT:\n" + .posting.posting + "\n\n" +
        "🔍 WHERE TO SEARCH:\n" + (.search_platforms | to_entries | map("  " + ((.key + 1) | tostring) + ". " + .value) | join("\n")) + "\n\n" +
        .checklist'
