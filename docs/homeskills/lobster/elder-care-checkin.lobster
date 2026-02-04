name: elder-care-checkin
description: Run a daily check-in workflow for elderly parents including wellness check, medication reminder, and family update
args:
  parent_id:
    type: string
    required: true
    description: ID of the elder to check in on
  check_type:
    type: string
    default: "morning"
    description: Type of check-in (morning|evening)

steps:
  # Step 1: Load elder profile
  - id: load-elder
    command: cat ~/clawd/homeos/data/elder_care/$PARENT_ID.json 2>/dev/null || echo '{"error":"Profile not found"}'

  # Step 2: Check if profile exists
  - id: validate
    command: >
      echo '$input' | jq 'if .error then
        {"status": "error", "message": "❌ Elder profile not found. Please set up elder care first."}
      else
        {"status": "ok", "elder": .}
      end'
    stdin: $load-elder.stdout

  # Step 3: Get today's medication schedule
  - id: get-medications
    command: >
      echo '$input' | jq --arg type "$CHECK_TYPE" '
        .elder.medications // [] |
        if $type == "morning" then [.[] | select(.times[] | test("^0[6-9]|^1[0-1]"))]
        else [.[] | select(.times[] | test("^1[2-9]|^2[0-3]"))]
        end |
        {medications: ., count: length}'
    stdin: $validate.stdout
    condition: $validate.json.status == "ok"

  # Step 4: Generate check-in conversation script using LLM
  - id: generate-script
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Generate a warm, caring CHECK_TYPE check-in conversation script for ELDER_NAME. Their interests are: INTERESTS. Medications to remind: MEDICATIONS. Keep it conversational, not clinical. Include: greeting, wellness question, medication reminder, engagement question, positive close.",
        "schema": {
          "type": "object",
          "properties": {
            "greeting": {"type": "string"},
            "wellness_question": {"type": "string"},
            "medication_reminder": {"type": "string"},
            "engagement_question": {"type": "string"},
            "closing": {"type": "string"}
          },
          "required": ["greeting", "wellness_question", "medication_reminder", "engagement_question", "closing"],
          "additionalProperties": false
        }
      }'

  # Step 5: Format the check-in message
  - id: format-checkin
    command: >
      echo '$input' | jq -r '
        (if "$CHECK_TYPE" == "morning" then "🌅" else "🌙" end) +
        " CHECK_TYPE CHECK-IN: " + "$ELDER_NAME" + "\n\n" +
        "1️⃣ " + .greeting + "\n\n" +
        "2️⃣ " + .wellness_question + "\n\n" +
        "3️⃣ " + .medication_reminder + "\n\n" +
        "4️⃣ " + .engagement_question + "\n\n" +
        "5️⃣ " + .closing'
    stdin: $generate-script.stdout

  # Step 6: Approve before initiating contact
  - id: approve-checkin
    command: approve --preview-from-stdin --prompt "Initiate this check-in call/message?"
    stdin: $format-checkin.stdout
    approval: required

  # Step 7: Log the check-in
  - id: log-checkin
    command: >
      cat >> ~/clawd/homeos/data/elder_care/check_ins/$(date +%Y-%m-%d).json << CHECKIN
      {
        "parent_id": "$PARENT_ID",
        "type": "$CHECK_TYPE",
        "timestamp": "$(date -Iseconds)",
        "medications_reminded": $(echo '$meds' | jq '.medications | map(.name)'),
        "status": "completed"
      }
      CHECKIN
      echo '{"status": "logged"}'
    stdin: $get-medications.stdout
    condition: $approve-checkin.approved

  # Step 8: Send summary to family members
  - id: notify-family
    command: >
      echo '$elder' | jq -r '.elder.family_contacts[] | select(.notify == true) | .name' |
      while read contact; do
        openclaw.invoke --tool message --action send --args-json "{
          \"message\": \"👵 CHECK_TYPE check-in with ELDER_NAME completed. All good.\",
          \"provider\": \"current\"
        }"
      done
    stdin: $validate.stdout
    condition: $approve-checkin.approved
