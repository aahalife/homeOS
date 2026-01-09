---
name: infrastructure
description: Core infrastructure for all HomeOS skills including memory storage, approval workflows, calendar integration, and common utilities. This skill is automatically included with all other skills.
---

# HomeOS Infrastructure

This document defines the core systems used by all HomeOS skills. Every skill should follow these conventions.

## Memory & Storage System

All persistent data is stored in the workspace under `~/clawd/homeos/`:

```
~/clawd/homeos/
├── memory/
│   ├── conversations/     # Recent conversation context
│   ├── preferences/       # User and family preferences
│   ├── entities/          # People, places, things mentioned
│   └── learnings/         # What worked, what didn't
├── data/
│   ├── family.json        # Family member profiles
│   ├── home.json          # Home information (address, shutoffs, etc.)
│   ├── providers.json     # Service providers (plumbers, sitters, etc.)
│   ├── pantry.json        # Kitchen inventory
│   ├── recipes.json       # Saved recipes
│   └── calendar.json      # Local calendar cache
├── tasks/
│   ├── active/            # Currently running tasks
│   ├── pending/           # Awaiting user input
│   └── completed/         # Finished tasks
└── logs/
    └── actions.log        # Audit trail of all actions
```

### Initializing Storage

Before using any skill, ensure the directory structure exists:

```bash
mkdir -p ~/clawd/homeos/{memory/{conversations,preferences,entities,learnings},data,tasks/{active,pending,completed},logs}
```

### Reading/Writing Data

**Read user preferences:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null || echo '{}'
```

**Write/update data (use jq for JSON):**
```bash
# Update a preference
echo '{"cuisine": ["Italian", "Mexican"]}' > ~/clawd/homeos/memory/preferences/dining.json
```

**Log an action:**
```bash
echo "$(date -Iseconds) | ACTION | description here" >> ~/clawd/homeos/logs/actions.log
```

## Approval Workflow

Actions are classified by risk level:

| Level | Examples | Approval Required |
|-------|----------|-------------------|
| **LOW** | Search, read data, generate suggestions | No |
| **MEDIUM** | Save preferences, send notifications | Ask once, remember preference |
| **HIGH** | Phone calls, purchases, post publicly, send messages | Always ask, explicit confirmation |

### How to Request Approval

For HIGH risk actions, ALWAYS present a clear approval request:

```
⚠️ APPROVAL REQUIRED

[Describe what you're about to do]

Details:
- [Specific detail 1]
- [Specific detail 2]
- [Cost/impact if applicable]

Reply "yes" or "approved" to proceed, or "no" to cancel.
```

**NEVER proceed with HIGH risk actions without explicit "yes", "approved", "go ahead", "do it", or similar affirmation.**

### Saving Approval Decisions

For MEDIUM risk actions, after getting approval once:

```bash
echo '{"action": "send_reminders", "approved": true, "date": "2024-01-15"}' >> ~/clawd/homeos/memory/preferences/approvals.json
```

## Calendar Integration

HomeOS uses a local calendar cache that can sync with external calendars.

### Adding Events

```bash
# Add to local calendar
cat >> ~/clawd/homeos/data/calendar.json << 'EOF'
{
  "id": "$(uuidgen)",
  "title": "Dinner at Osteria Romana",
  "date": "2024-01-20",
  "time": "19:30",
  "duration": 120,
  "location": "123 Main St",
  "notes": "Anniversary dinner, confirmation #12345",
  "reminders": ["2h", "1d"]
}
EOF
```

### Checking Calendar

```bash
cat ~/clawd/homeos/data/calendar.json 2>/dev/null | jq '.[] | select(.date >= "'$(date +%Y-%m-%d)'")'  
```

## Weather Information

Get weather using wttr.in (no API key required):

```bash
# Current weather
curl -s "wttr.in/?format=%C+%t+%h+%w"

# Weather for specific location
curl -s "wttr.in/Baltimore?format=%C+%t"

# Detailed forecast
curl -s "wttr.in/Baltimore?format=3"
```

## Location & Maps

For location-based searches, use the stored home address:

```bash
cat ~/clawd/homeos/data/home.json | jq -r '.address'
```

For distance/directions, provide Google Maps links:
```
https://www.google.com/maps/dir/?api=1&origin=HOME_ADDRESS&destination=DESTINATION
```

## Web Search

When you need to search for information (restaurants, services, events):

1. **Use browser tool** if available for detailed searches
2. **Provide search suggestions** if browser unavailable:
   - "Search Google for: [query]"
   - Provide direct links when possible

## Error Handling

When something fails:

1. **Log the error:**
```bash
echo "$(date -Iseconds) | ERROR | [skill] | [description]" >> ~/clawd/homeos/logs/actions.log
```

2. **Inform the user clearly:**
```
❌ I couldn't complete [action] because [reason].

Options:
1. [Alternative approach]
2. [Manual workaround]
3. Try again later

What would you like to do?
```

3. **Never silently fail** - always tell the user what happened

## Task State Management

For multi-step tasks, save state so you can resume:

```bash
# Save task state
cat > ~/clawd/homeos/tasks/active/restaurant-booking-$(date +%s).json << 'EOF'
{
  "skill": "restaurant-reservation",
  "started": "2024-01-15T10:30:00",
  "step": "awaiting_restaurant_selection",
  "data": {
    "date": "2024-01-20",
    "party_size": 2,
    "options_presented": ["Osteria Romana", "Bella Vista"]
  }
}
EOF
```

## Family Profiles

Store family information for personalization:

```json
// ~/clawd/homeos/data/family.json
{
  "members": [
    {
      "name": "John",
      "role": "parent",
      "preferences": {
        "cuisine": ["Italian", "Japanese"],
        "dietary": []
      }
    },
    {
      "name": "Emma", 
      "role": "child",
      "age": 7,
      "preferences": {
        "dietary": ["no spicy"]
      },
      "allergies": ["peanuts"]
    }
  ],
  "owner_phone": "+14438315129",
  "owner_telegram": "@username"
}
```

## Service Provider Database

Store trusted service providers:

```json
// ~/clawd/homeos/data/providers.json
{
  "plumber": {
    "name": "ABC Plumbing",
    "phone": "+1234567890",
    "rating": 5,
    "notes": "Used for bathroom reno, great work",
    "last_used": "2024-01-10"
  },
  "babysitter": {
    "name": "Sarah M.",
    "phone": "+1987654321",
    "rate": 22,
    "rating": 5,
    "notes": "Kids love her"
  }
}
```

## Graceful Degradation

When a capability isn't available:

| Missing Capability | Fallback |
|-------------------|----------|
| Voice AI calling | Provide call script for user to call manually |
| API integration | Use browser automation or provide manual steps |
| External service | Search for alternatives or provide DIY instructions |
| Real-time data | Use cached data with timestamp warning |

## Verification Steps

After every significant action:

1. **Verify the action completed** (check file exists, API returned success)
2. **Confirm with user** for important actions
3. **Log the outcome** for future reference
4. **Update relevant data** (calendar, preferences, etc.)

## Interruptibility

All skills should support:

- **Pause**: Save state and wait for user input
- **Resume**: Pick up where left off
- **Cancel**: Clean up and abort gracefully
- **Modify**: Change parameters mid-task

When user says "cancel", "stop", "never mind":
1. Confirm cancellation
2. Clean up any partial state
3. Log the cancellation
4. Offer alternatives
