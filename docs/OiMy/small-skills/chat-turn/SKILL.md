---
name: chat-turn
description: Route every user message to the right skill. If no skill matches, handle as general chat.
---

# Chat Turn — Message Router

Every user message enters here. Route it or handle it.

## Routing Rules (check in this order, stop at first match)

### Priority 1: Telephony
If message contains ANY of: "call", "phone", "dial", "ring"
AND references a business, person, or phone number
→ ROUTE TO: telephony
→ OUTPUT_HANDOFF: to=telephony, data={raw_message, extracted_number_if_any}

### Priority 2: Restaurant Reservation
If message contains ANY of: "reservation", "book a table", "book a restaurant", "dinner reservation", "lunch reservation", "table for", "reserve a table", "book dinner", "book lunch"
→ ROUTE TO: restaurant-reservation
→ OUTPUT_HANDOFF: to=restaurant-reservation, data={raw_message}

### Priority 3: Marketplace Sell
If message contains ANY of: "sell", "list for sale", "post on marketplace", "sell on facebook", "sell on ebay", "sell on craigslist", "how much is my", "what's my X worth", "get rid of"
AND references a physical item
→ ROUTE TO: marketplace-sell
→ OUTPUT_HANDOFF: to=marketplace-sell, data={raw_message, item_name}

### Priority 4: Hire Helper
If message contains ANY of: "babysitter", "nanny", "housekeeper", "cleaner", "tutor", "dog walker", "pet sitter", "caregiver", "hire", "find someone to"
→ ROUTE TO: hire-helper
→ OUTPUT_HANDOFF: to=hire-helper, data={raw_message, helper_type}

### Priority 5: General Chat (no routing)
If none of the above match → handle directly.

## How to Handle General Chat

1. UNDERSTAND: What does the user want? (question, request, chitchat)
2. RECALL: Check ~/clawd/homeos/data/family.json and ~/clawd/homeos/memory/ for context
3. RESPOND: Answer the question, fulfill the request, or chat back
4. LEARN: If user reveals a preference or fact, save it:
```bash
# Save new preference
echo '{"key":"value","updated":"DATE"}' > ~/clawd/homeos/memory/pref-name.json
```

## Risk Assessment (every action)

Before doing anything, classify it:
- LOW (search, read, suggest) → just do it
- MEDIUM (save data, set reminder) → ask once
- HIGH (call, purchase, post, send) → ALWAYS ask, see infrastructure skill

## Multi-Turn Tracking

If a task spans multiple messages:
1. Save state: ~/clawd/homeos/tasks/active/chat-TIMESTAMP.json
2. On next message, check for active tasks first
3. If user changes topic: "We were working on [X]. Continue that or switch to [new topic]?"

## Response Format

Every response has 4 parts:
1. **Acknowledge** — show you understood
2. **Status** — what's happening
3. **Details** — the actual content
4. **Next step** — what happens next or what you need

## Ambiguous Messages

If the message could match multiple skills:
- Ask: "Did you mean [A] or [B]?"
- Do NOT guess. Do NOT route to both.

If the message is unclear:
- Ask ONE clarifying question
- Do not ask more than two questions before doing something useful

## Logging

Log every routed message:
```bash
echo "$(date -Iseconds) | ROUTE | [skill-name] | [summary]" >> ~/clawd/homeos/logs/actions.log
```
