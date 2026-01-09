# HomeOS Skills for Clawdbot

This directory contains skills for HomeOS - the family AI assistant. These skills are designed to work with [Clawdbot](https://github.com/clawdbot/clawdbot) and can be published to [ClawdHub](https://clawdhub.com/skills).

## What are Skills?

Skills are markdown files that give the AI assistant specific knowledge and instructions for handling particular tasks. When a user asks something that matches a skill's description, the assistant automatically applies that skill's guidance.

## Quick Start

To use these skills with Clawdbot:

```bash
# Copy skills to your Clawdbot workspace
cp -r docs/homeskills/* ~/clawd/skills/

# Initialize the storage structure
mkdir -p ~/clawd/homeos/{memory/{conversations,preferences,entities,learnings},data,tasks/{active,pending,completed},logs}
```

## Available Skills

| Skill | Description | Use When |
|-------|-------------|----------|
| [_infrastructure](./_infrastructure/SKILL.md) | Core systems: storage, approvals, calendar | Included with all skills |
| [chat-turn](./chat-turn/SKILL.md) | Conversational AI with 6-phase processing | Processing any user message |
| [restaurant-reservation](./restaurant-reservation/SKILL.md) | Help find and book restaurants | User wants to book a table |
| [marketplace-sell](./marketplace-sell/SKILL.md) | Sell items on FB Marketplace/eBay | User wants to sell something |
| [meal-planning](./meal-planning/SKILL.md) | Weekly meal plans with grocery lists | User needs meal/food planning |
| [home-maintenance](./home-maintenance/SKILL.md) | Repairs, contractors, emergencies | User has home repair needs |
| [hire-helper](./hire-helper/SKILL.md) | Find babysitters, cleaners, tutors | User needs household help |
| [family-bonding](./family-bonding/SKILL.md) | Activity ideas and outing planning | User wants family activity ideas |

## Skill Categories

### Core
- **_infrastructure** - Storage, approvals, calendar, error handling (included with all skills)

### Conversational
- **chat-turn** - Core conversation handling with memory, planning, and execution

### Services & Booking
- **restaurant-reservation** - Restaurant search and booking assistance
- **marketplace-sell** - Online marketplace listing and selling
- **hire-helper** - Household help recruitment

### Family Management
- **meal-planning** - Food planning and grocery coordination
- **family-bonding** - Activity planning and quality time

### Home Management
- **home-maintenance** - Repairs, maintenance, and emergencies

## Storage Structure

All skills share a common storage structure:

```
~/clawd/homeos/
├── memory/
│   ├── conversations/     # Recent conversation context
│   ├── preferences/       # User and family preferences
│   ├── entities/          # People, places, things mentioned
│   └── learnings/         # What worked, what didn't
├── data/
│   ├── family.json        # Family member profiles
│   ├── home.json          # Home information (address, shutoffs)
│   ├── providers.json     # Service providers (plumbers, sitters)
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

## Risk Levels & Approvals

Each skill operation has an associated risk level:

| Level | Description | Approval Required |
|-------|-------------|-------------------|
| **LOW** | Read-only, informational | No |
| **MEDIUM** | Limited impact, reversible | Ask once, remember preference |
| **HIGH** | Financial, external actions, irreversible | Always ask explicitly |

### HIGH Risk Actions (Always Require Explicit Approval)
- Making phone calls to external parties
- Financial transactions > $50
- Posting to social media or marketplaces
- Sending messages on user's behalf
- Modifying calendar events
- Purchasing items
- Sharing personal information

## Skill Design Principles

These skills are designed to be:

1. **Actionable** - Concrete steps, not abstract concepts
2. **Reliable** - Error handling, fallbacks, verification
3. **Safe** - Approval gates, risk classification, safety reminders
4. **Persistent** - Save preferences, learn from interactions
5. **Interruptible** - Can pause, resume, or cancel gracefully

## Using These Skills

### With Clawdbot

1. Copy skills to your `~/clawd/skills/` directory
2. Initialize the storage structure (see Quick Start)
3. Skills are automatically available when relevant

### Skill Format

Each skill follows this format:

```markdown
---
name: skill-name
description: What this skill does. Include trigger words.
---

# Skill Name

Instructions and guidance...
```

## Contributing

To improve a skill:

1. Identify gaps, ambiguities, or missing steps
2. Add concrete, actionable instructions
3. Include error handling and fallbacks
4. Add examples for common scenarios
5. Test with real interactions

## Related Documentation

- [Clawdbot Documentation](https://docs.clawd.bot)
- [ClawdHub Skills](https://clawdhub.com/skills)
- [HomeOS Architecture](../architecture/)
