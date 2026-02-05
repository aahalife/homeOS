name: healthcare-refill
description: Check all family medications for upcoming refills and help request them
args:
  days_ahead:
    type: integer
    default: 7
    description: How many days ahead to check for refills

steps:
  # Step 1: Load family health data
  - id: load-health
    command: cat ~/clawd/homeos/data/health/family_health.json 2>/dev/null || echo '{"members":[]}'

  # Step 2: Find medications needing refill within N days
  - id: find-refills
    command: >
      echo '$input' | jq --arg days "$DAYS_AHEAD" --arg today "$(date +%Y-%m-%d)" '
        [.members[] | . as $member |
          .medications[]? |
          select(.refill_date != null) |
          select(.refill_date <= ($today | split("-") | .[0:3] | join("-"))) |
          {
            member_name: $member.name,
            member_id: $member.id,
            medication: .name,
            dosage: .dosage,
            refill_date: .refill_date,
            pharmacy: (.pharmacy // "Not specified"),
            rx_number: (.rx_number // "Unknown")
          }
        ]'
    stdin: $load-health.stdout

  # Step 3: Check if any refills are needed
  - id: check-empty
    command: >
      echo '$input' | jq 'if length == 0
        then {"status": "none", "message": "✅ No medications need refilling in the next DAYS_AHEAD days."}
        else {"status": "needed", "count": length, "refills": .}
        end'
    stdin: $find-refills.stdout

  # Step 4: Format refill report (only if refills needed)
  - id: format-report
    command: >
      echo '$input' | jq -r '
        if .status == "none" then .message
        else
          "💊 PRESCRIPTION REFILLS NEEDED\n\n" +
          (.refills | to_entries | map(
            "• " + .value.member_name + ": " + .value.medication + " " + .value.dosage + "\n" +
            "  📅 Refill by: " + .value.refill_date + "\n" +
            "  🏪 Pharmacy: " + .value.pharmacy + "\n" +
            "  Rx#: " + .value.rx_number + "\n"
          ) | join("\n"))
        end'
    stdin: $check-empty.stdout

  # Step 5: Ask for approval to send refill reminders
  - id: approve-reminders
    command: approve --preview-from-stdin --prompt "Send refill reminders for these medications?"
    stdin: $format-report.stdout
    approval: required
    condition: $check-empty.json.status == "needed"

  # Step 6: Create reminder tasks
  - id: create-reminders
    command: >
      echo '$refills' | jq -c '.refills[]' | while read refill; do
        echo "$refill" | jq '{
          type: "medication_refill",
          member: .member_id,
          medication: .medication,
          pharmacy: .pharmacy,
          rx_number: .rx_number,
          due: .refill_date,
          status: "pending"
        }' >> ~/clawd/homeos/tasks/active/refill-$(date +%s).json
      done && echo '{"status": "reminders_created"}'
    stdin: $check-empty.stdout
    condition: $approve-reminders.approved
