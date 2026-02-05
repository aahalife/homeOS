name: marketplace-sell-list
description: Create an optimized marketplace listing with pricing research and safety guidance
args:
  item:
    type: string
    required: true
    description: Item to sell
  condition:
    type: string
    default: "good"
    description: Item condition (new|like-new|good|fair|poor)

steps:
  - id: research-price
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Research pricing for: ITEM in CONDITION condition. Provide retail price, typical resale range, and recommended listing prices at 3 levels (quick sale, fair, firm).",
        "schema": {
          "type": "object",
          "properties": {
            "retailPrice": {"type": "string"},
            "resaleRange": {"type": "string"},
            "quickSalePrice": {"type": "string"},
            "fairPrice": {"type": "string"},
            "firmPrice": {"type": "string"}
          },
          "required": ["retailPrice", "resaleRange", "quickSalePrice", "fairPrice", "firmPrice"]
        }
      }'

  - id: generate-listing
    command: >
      openclaw.invoke --tool llm-task --action json --args-json '{
        "prompt": "Create an optimized marketplace listing for: ITEM in CONDITION condition. Include a compelling title (under 80 chars, lead with brand), detailed description, and list of recommended photos to take.",
        "input": {"pricing": $PRICING},
        "schema": {
          "type": "object",
          "properties": {
            "title": {"type": "string"},
            "description": {"type": "string"},
            "recommendedPhotos": {"type": "array", "items": {"type": "string"}}
          },
          "required": ["title", "description", "recommendedPhotos"]
        }
      }'
    stdin: $research-price.stdout

  - id: add-safety
    command: >
      echo '{
        "listing": '$LISTING',
        "pricing": '$PRICING'
      }' | jq -r '
        "📦 MARKETPLACE LISTING READY\n\n" +
        "📝 TITLE: " + .listing.title + "\n" +
        "💰 RECOMMENDED PRICE: " + .pricing.fairPrice + "\n" +
        "  ⚡ Quick sale: " + .pricing.quickSalePrice + "\n" +
        "  💪 Hold firm: " + .pricing.firmPrice + "\n\n" +
        "📄 DESCRIPTION:\n" + .listing.description + "\n\n" +
        "📸 PHOTOS NEEDED:\n" + (.listing.recommendedPhotos | map("  ☐ " + .) | join("\n")) + "\n\n" +
        "━━━━━━━━━━━━━━━━━━━\n\n" +
        "🚨 SAFETY REMINDERS:\n\n" +
        "✅ SAFE meeting spots:\n" +
        "  • Police station parking lot\n" +
        "  • Bank lobby (business hours)\n" +
        "  • Busy shopping center\n\n" +
        "✅ SAFE payment:\n" +
        "  • Cash (count in front of them)\n" +
        "  • Venmo/PayPal (verify received)\n\n" +
        "🚩 SCAM CHECKLIST (reject if ANY):\n" +
        "  ☐ Offers MORE than asking price\n" +
        "  ☐ Wants to send a mover or assistant\n" +
        "  ☐ Asks to ship before payment clears\n" +
        "  ☐ Sends verification links\n" +
        "  ☐ Asks for personal info (SSN, bank)\n" +
        "  ☐ Only texts, refuses platform messages\n" +
        "  ☐ Story is overly complicated\n\n" +
        "❌ NEVER accept: checks, money orders, wire transfers"'

  - id: approve-post
    command: approve --preview-from-stdin --prompt "Ready to post this listing? (You will copy/paste to your marketplace)"
    stdin: $add-safety.stdout
    approval: required

  - id: save-listing
    command: >
      cat >> ~/clawd/homeos/data/marketplace_listings.json << LISTING
      {
        "id": "listing-$(date +%s)",
        "item": "$ITEM",
        "condition": "$CONDITION",
        "price": "$FAIR_PRICE",
        "status": "active",
        "created": "$(date -Iseconds)"
      }
      LISTING
    condition: $approve-post.approved
