name: family-comms-announce
description: Send a family announcement with priority level and acknowledgment tracking
args:
  message:
    type: string
    required: true
    description: The announcement message
  priority:
    type: string
    default: "normal"
    description: Priority level (normal|important|urgent)
  recipients:
    type: string
    default: "all"
    description: Who to send to (all|parents|kids|comma-separated member IDs)

steps:
  # Step 1: Load family members
  - id: load-family
    command: cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{"members":[]}'

  # Step 2: Filter recipients
  - id: filter-recipients
    command: >
      echo '$input' | jq --arg recipients "$RECIPIENTS" '
        if $recipients == "all" then .members
        elif $recipients == "parents" then [.members[] | select(.role == "parent")]
        elif $recipients == "kids" then [.members[] | select(.role == "child")]
        else [.members[] | select(.id as $id | $recipients | split(",") | map(ltrimstr(" ")) | index($id))]
        end |
        map({name, id, role, quiet_hours})'
    stdin: $load-family.stdout

  # Step 3: Check quiet hours (don't send during quiet hours unless urgent)
  - id: check-quiet
    command: >
      echo '$input' | jq --arg priority "$PRIORITY" --arg hour "$(date +%H)" '
        map(
          if $priority != "urgent" and .quiet_hours != null then
            if (.quiet_hours.start | tonumber) <= ($hour | tonumber) or ($hour | tonumber) < (.quiet_hours.end | tonumber)
            then . + {"send": false, "reason": "quiet hours"}
            else . + {"send": true}
            end
          else . + {"send": true}
          end
        )'
    stdin: $filter-recipients.stdout

  # Step 4: Format announcement
  - id: format-announce
    command: >
      echo '{
        "recipients": '$RECIPIENTS_FILTERED',
        "message": "$MESSAGE",
        "priority": "$PRIORITY"
      }' | jq -r '
        (if .priority == "urgent" then "🔴" elif .priority == "important" then "🟡" else "🟢" end) +
        " FAMILY ANNOUNCEMENT\n\n" +
        .message + "\n\n" +
        "📤 Sending to:\n" +
        ([.recipients[] | select(.send == true) | "  ✅ " + .name] | join("\n")) +
        (if ([.recipients[] | select(.send == false)] | length) > 0 then
          "\n\n⏸️ Delayed (quiet hours):\n" +
          ([.recipients[] | select(.send == false) | "  ⏳ " + .name + " (" + .reason + ")"] | join("\n"))
        else "" end)'

  # Step 5: Approve before sending
  - id: approve-send
    command: approve --preview-from-stdin --prompt "Send this announcement?"
    stdin: $format-announce.stdout
    approval: required

  # Step 6: Send to each recipient
  - id: send-messages
    command: >
      echo '$recipients' | jq -c '.[] | select(.send == true)' |
      while read member; do
        name=$(echo "$member" | jq -r '.name')
        openclaw.invoke --tool message --action send --args-json "{
          \"message\": \"📢 $MESSAGE\",
          \"provider\": \"current\"
        }"
      done && echo '{"status": "sent"}'
    stdin: $check-quiet.stdout
    condition: $approve-send.approved

  # Step 7: Save announcement for tracking
  - id: save-announce
    command: >
      cat >> ~/clawd/homeos/data/announcements.json << ANNOUNCE
      {
        "id": "announce-$(date +%s)",
        "message": "$MESSAGE",
        "priority": "$PRIORITY",
        "sent_at": "$(date -Iseconds)",
        "recipients": $(echo '$recipients' | jq '[.[] | select(.send == true) | .id]'),
        "acknowledged_by": []
      }
      ANNOUNCE
      echo '{"saved": true}'
    condition: $approve-send.approved
