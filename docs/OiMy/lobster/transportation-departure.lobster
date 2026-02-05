name: transportation-departure
description: Calculate departure time and send proactive alert for upcoming calendar events
args:
  event_id:
    type: string
    required: true
    description: Calendar event ID to calculate departure for

steps:
  - id: load-event
    command: >
      cat ~/clawd/homeos/data/calendar.json 2>/dev/null |
      jq --arg id "$EVENT_ID" '.[] | select(.id == $id)' || echo '{"error": "Event not found"}'

  - id: load-home
    command: >
      cat ~/clawd/homeos/data/home.json 2>/dev/null | jq -r '.address // "unknown"'

  - id: get-traffic
    command: >
      echo '{"event": '$EVENT', "home": "$HOME_ADDR"}' | jq '{
        location: .event.location,
        event_time: .event.time,
        estimated_drive_min: 25,
        traffic_multiplier: 1.3,
        buffer_min: 10,
        adjusted_drive_min: (25 * 1.3 + 10 | floor)
      }'

  - id: format-alert
    command: >
      echo '$input' | jq -r '
        "🚗 DEPARTURE ALERT\n\n" +
        "📅 " + "$EVENT_TITLE" + " at " + .event_time + "\n" +
        "📍 " + .location + "\n\n" +
        "⏱️ Drive time: " + (.estimated_drive_min | tostring) + " min\n" +
        "🚦 With traffic: " + (.adjusted_drive_min | tostring) + " min\n" +
        "🕐 Leave by: [CALCULATED_TIME]\n\n" +
        "💡 Set to leave in 15 minutes?"'
    stdin: $get-traffic.stdout
