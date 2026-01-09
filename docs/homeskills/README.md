# HomeOS Skills for Claude Code

This directory contains Claude Code skills for HomeOS - the family AI assistant. These skills can be used with Claude Code or published to [ClawdHub](https://clawdhub.com/skills).

## What are Skills?

Skills are markdown files that give Claude specific knowledge and instructions for handling particular tasks. When a user asks Claude something that matches a skill's description, Claude automatically applies that skill's guidance.

## Available Skills

| Skill | Description | Use When |
|-------|-------------|----------|
| [chat-turn](./chat-turn/SKILL.md) | Conversational AI with 6-phase processing | Processing any user message |
| [restaurant-reservation](./restaurant-reservation/SKILL.md) | AI voice calls to book restaurants | User wants to book a table |
| [marketplace-sell](./marketplace-sell/SKILL.md) | Sell items on FB Marketplace/eBay | User wants to sell something |
| [meal-planning](./meal-planning/SKILL.md) | Weekly meal plans with grocery lists | User needs meal/food planning |
| [home-maintenance](./home-maintenance/SKILL.md) | Repairs, contractors, emergencies | User has home repair needs |
| [hire-helper](./hire-helper/SKILL.md) | Find babysitters, cleaners, tutors | User needs household help |
| [family-bonding](./family-bonding/SKILL.md) | Activity ideas and outing planning | User wants family activity ideas |

## Skill Categories

### Conversational
- **chat-turn** - Core conversation handling with memory, planning, and execution

### Services
- **restaurant-reservation** - Voice AI restaurant bookings
- **marketplace-sell** - Online marketplace listing automation
- **hire-helper** - Household help recruitment

### Family Management
- **meal-planning** - Food planning and grocery coordination
- **family-bonding** - Activity planning and quality time

### Home Management
- **home-maintenance** - Repairs, maintenance, and emergencies

## Risk Levels

Each skill operation has an associated risk level:

| Level | Description | Approval Required |
|-------|-------------|-------------------|
| **LOW** | Read-only, informational | No |
| **MEDIUM** | Limited impact, reversible | User preference |
| **HIGH** | Financial, external calls, irreversible | Always |

### HIGH Risk Actions (Always Require Approval)
- Making phone calls to external parties
- Financial transactions > $50
- Posting to social media or marketplaces
- Sending messages on user's behalf
- Modifying calendar events
- Purchasing items

## Using These Skills

### With Claude Code

1. Copy the skill folder to your `.claude/skills/` directory
2. The skill will be automatically available when relevant

### Publishing to ClawdHub

1. Visit [clawdhub.com/skills](https://clawdhub.com/skills)
2. Create an account
3. Upload the SKILL.md file
4. Add tags and metadata
5. Submit for review

## Skill Format

Each skill follows the Claude Code SKILL.md format:

```markdown
---
name: skill-name
description: What this skill does. Include trigger words users might say.
---

# Skill Name

Instructions and guidance for Claude...
```

### Required Fields
- `name` - Unique identifier (lowercase, hyphens)
- `description` - When to use this skill (triggers activation)

### Optional Fields
- `allowed-tools` - Restrict which tools the skill can use
- `model` - Preferred model (opus, sonnet, haiku)
- `context` - Additional context files to include

## Contributing

To add a new skill:

1. Create a new directory: `docs/homeskills/your-skill-name/`
2. Create `SKILL.md` with proper frontmatter
3. Keep instructions clear and actionable
4. Include examples and edge cases
5. Document risk levels for operations

## Related Documentation

- [Claude Code Skills Guide](https://code.claude.com/docs/en/skills)
- [HomeOS Architecture](../architecture/)
- [Original Skill Specs](../skills/)
