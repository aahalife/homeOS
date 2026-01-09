---
name: chat-turn
description: Handle conversational AI interactions with multi-phase processing including understanding, memory recall, planning, execution, and reflection. Use when the user sends a chat message, asks a question, requests information, or wants to perform any action through natural language conversation.
---

# Chat Turn Skill

Process user messages through a 6-phase pipeline that understands intent, recalls context, plans actions, executes with approval gates, and learns from interactions.

## When to Use

This is the core conversational skill - use it for ANY user interaction.

## Storage Setup

Ensure the HomeOS directory structure exists:

```bash
mkdir -p ~/clawd/homeos/{memory/{conversations,preferences,entities,learnings},data,tasks/{active,pending,completed},logs}
```

## Phase 1: Understand

**Goal:** Parse what the user wants.

**Steps:**
1. Identify the primary intent (question, request, action, chat)
2. Extract entities (people, places, dates, items)
3. Assess urgency (urgent, normal, low priority)
4. Determine if clarification is needed

**If unclear, ask for clarification:**
```
I want to make sure I understand correctly. Are you asking me to:
1. [Interpretation A]
2. [Interpretation B]

Or did you mean something else?
```

**Log the understanding:**
```bash
echo "$(date -Iseconds) | UNDERSTAND | intent: [intent] | entities: [entities]" >> ~/clawd/homeos/logs/actions.log
```

## Phase 2: Recall

**Goal:** Gather relevant context.

**Steps:**

1. **Check family profiles:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null
```

2. **Check relevant preferences:**
```bash
# For dining requests
cat ~/clawd/homeos/memory/preferences/dining.json 2>/dev/null

# For activity requests  
cat ~/clawd/homeos/memory/preferences/activities.json 2>/dev/null
```

3. **Check recent related tasks:**
```bash
ls -la ~/clawd/homeos/tasks/completed/ | tail -10
```

4. **Check calendar for conflicts:**
```bash
cat ~/clawd/homeos/data/calendar.json 2>/dev/null | grep -A5 "$(date +%Y-%m-%d)"
```

**Use recalled information to personalize response.**

## Phase 3: Plan

**Goal:** Create an execution plan with risk assessment.

**Risk Classification:**

| Risk Level | Actions | Approval |
|------------|---------|----------|
| **LOW** | Search, lookup, generate suggestions, read files | No approval needed |
| **MEDIUM** | Save preferences, set reminders, update data | Ask once, remember |
| **HIGH** | Make calls, spend money, post publicly, send messages | ALWAYS ask |

**Plan Format:**
```
PLAN:
1. [Action] - [Risk Level]
2. [Action] - [Risk Level]
3. [Action] - [Risk Level]

Approval needed for: [list HIGH risk steps]
```

**Save complex plans:**
```bash
cat > ~/clawd/homeos/tasks/active/task-$(date +%s).json << 'EOF'
{
  "created": "TIMESTAMP",
  "intent": "USER_INTENT",
  "steps": [
    {"action": "step1", "risk": "LOW", "status": "pending"},
    {"action": "step2", "risk": "HIGH", "status": "pending"}
  ],
  "current_step": 0
}
EOF
```

## Phase 4: Execute

**Goal:** Carry out the plan with appropriate gates.

### For LOW Risk Actions
Proceed immediately. Examples:
- Search for information
- Generate suggestions
- Read stored data
- Provide recommendations

### For MEDIUM Risk Actions
Check if previously approved:
```bash
grep "action_name" ~/clawd/homeos/memory/preferences/approvals.json 2>/dev/null
```

If not previously approved, ask once:
```
I'll need to [action]. Is that okay? 
(I'll remember your preference for next time)
```

### For HIGH Risk Actions
**ALWAYS request explicit approval:**

```
⚠️ APPROVAL REQUIRED

I'm about to: [specific action]

Details:
- [Detail 1]
- [Detail 2]
- [Cost/Impact if applicable]

Reply "yes" to proceed, or "no" to cancel.
```

**Wait for explicit confirmation.** Valid approvals:
- "yes", "yeah", "yep"
- "approved", "approve"
- "go ahead", "proceed"
- "do it"

**Do NOT proceed on:**
- "maybe", "I guess"
- "sure" (ambiguous - ask to confirm)
- No response
- Anything unclear

### Execution Logging

```bash
echo "$(date -Iseconds) | EXECUTE | [action] | [result]" >> ~/clawd/homeos/logs/actions.log
```

## Phase 5: Reflect

**Goal:** Assess the outcome.

**Questions to consider:**
1. Did the action complete successfully?
2. Was the user satisfied? (Check their response)
3. Were there any issues or errors?
4. What could be improved next time?

**If something failed:**
```
❌ That didn't work as expected.

What happened: [explanation]

Options:
1. [Alternative approach]
2. [Try again with different parameters]
3. [Manual workaround]

What would you like to do?
```

**If successful, confirm:**
```
✅ Done! [Brief summary of what was accomplished]

[Any relevant details or next steps]
```

## Phase 6: Writeback

**Goal:** Persist learnings for future interactions.

**What to save:**

1. **User preferences discovered:**
```bash
# Example: User prefers Italian restaurants
cat > ~/clawd/homeos/memory/preferences/dining.json << 'EOF'
{
  "favorite_cuisines": ["Italian"],
  "price_preference": "$$$",
  "updated": "2024-01-15"
}
EOF
```

2. **Successful patterns:**
```bash
echo '{"pattern": "anniversary_dinner", "approach": "romantic_italian", "success": true}' >> ~/clawd/homeos/memory/learnings/patterns.json
```

3. **Entity relationships:**
```bash
# Example: Learned spouse's name
cat ~/clawd/homeos/data/family.json | jq '.members += [{"name": "Sarah", "role": "spouse"}]' > /tmp/family.json && mv /tmp/family.json ~/clawd/homeos/data/family.json
```

## Response Format

Every response should include:

1. **Acknowledgment** - Show you understood
2. **Status** - What's happening/happened
3. **Details** - Relevant information
4. **Next Steps** - What happens next or options

**Example Good Response:**
```
Got it - you want to book a romantic dinner for your anniversary next Friday.

I found 3 great options:
1. 🍽️ Osteria Romana - $$$ - 4.8★
2. 🍽️ Bella Vista - $$$$ - 4.6★  
3. 🍽️ Trattoria Milano - $$ - 4.5★

Which one interests you? Once you choose, I'll help make the reservation.
```

## Error Handling

**When something goes wrong:**

1. Don't panic or over-apologize
2. Explain clearly what happened
3. Offer alternatives
4. Log for debugging

```bash
echo "$(date -Iseconds) | ERROR | [context] | [error]" >> ~/clawd/homeos/logs/actions.log
```

**Recovery response:**
```
I ran into an issue: [brief explanation]

Here's what we can do:
1. [Option A]
2. [Option B]

Which would you prefer?
```

## Multi-Turn Conversations

For conversations spanning multiple messages:

1. **Maintain context** - Remember what was discussed
2. **Track progress** - Know where you are in a task
3. **Handle interruptions** - If user changes topic, acknowledge and offer to resume later

```
I notice we were in the middle of [previous task]. Would you like to:
1. Continue with that
2. Start fresh with [new request]
```

## Handoff to Other Skills

When a request matches a specific skill:

1. **Restaurant booking** → Use restaurant-reservation skill
2. **Selling items** → Use marketplace-sell skill
3. **Meal planning** → Use meal-planning skill
4. **Home repairs** → Use home-maintenance skill
5. **Finding helpers** → Use hire-helper skill
6. **Family activities** → Use family-bonding skill

These skills have specialized workflows - invoke them for best results.
