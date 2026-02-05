name: restaurant-reservation-book
description: Search for restaurants and assist with booking a reservation
args:
  cuisine:
    type: string
    default: ""
    description: Preferred cuisine type
  date:
    type: string
    required: true
    description: Date for reservation (YYYY-MM-DD)
  time:
    type: string
    default: "19:00"
    description: Preferred time (HH:MM)
  party_size:
    type: integer
    default: 2
    description: Number of guests
  occasion:
    type: string
    default: ""
    description: Special occasion if any

steps:
  - id: load-prefs
    command: >
      cat ~/clawd/homeos/memory/preferences/dining.json 2>/dev/null || echo '{}'

  - id: load-dietary
    command: >
      cat ~/clawd/homeos/data/family.json 2>/dev/null |
      jq '{dietary: [.members[].preferences.dietary // [] | .[]] | unique, allergies: [.members[].allergies // [] | .[]] | unique}' ||
      echo '{"dietary":[],"allergies":[]}'

  - id: search-restaurants
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Suggest 3 restaurants. Cuisine: CUISINE (or general if empty). Location: near user. Budget: moderate-upscale. Party size: PARTY_SIZE. Occasion: OCCASION. Dietary needs: DIETARY. For each give name, cuisine, price range, why its good for this occasion.",
        "schema": {
          "type": "object",
          "properties": {
            "restaurants": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": {"type": "string"},
                  "cuisine": {"type": "string"},
                  "priceRange": {"type": "string"},
                  "highlight": {"type": "string"},
                  "bookingMethod": {"type": "string"}
                },
                "required": ["name", "cuisine", "priceRange", "highlight", "bookingMethod"]
              }
            }
          },
          "required": ["restaurants"]
        }
      }'

  - id: format-options
    command: >
      echo '$input' | jq -r '
        "🍽️ RESTAURANT OPTIONS\n\n" +
        "📅 " + "$DATE" + " at " + "$TIME" + " • 👥 " + "$PARTY_SIZE" + " guests\n" +
        (if "$OCCASION" != "" then "🎉 " + "$OCCASION" + "\n" else "" end) +
        "\n" +
        (.restaurants | to_entries | map(
          ((.key + 1) | tostring) + ". " + .value.name + " — " + .value.priceRange + "\n" +
          "   🍽️ " + .value.cuisine + "\n" +
          "   ✨ " + .value.highlight + "\n" +
          "   📱 Book via: " + .value.bookingMethod + "\n"
        ) | join("\n")) +
        "\nWhich one? I will help you book."'
    stdin: $search-restaurants.stdout

  - id: approve-booking
    command: approve --preview-from-stdin --prompt "Proceed with booking assistance for your chosen restaurant?"
    stdin: $format-options.stdout
    approval: required

  - id: save-to-calendar
    command: >
      cat >> ~/clawd/homeos/data/calendar.json << EVENT
      {
        "id": "reservation-$(date +%s)",
        "type": "restaurant",
        "title": "Dinner Reservation",
        "date": "$DATE",
        "time": "$TIME",
        "duration": 120,
        "notes": "Party of $PARTY_SIZE. $OCCASION",
        "reminders": ["2h", "1d"]
      }
      EVENT
      echo '{"status": "saved_to_calendar"}'
    condition: $approve-booking.approved
