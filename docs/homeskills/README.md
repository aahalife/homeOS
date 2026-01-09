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

### Core Infrastructure
| Skill | Description | Use When |
|-------|-------------|----------|
| [_infrastructure](./_infrastructure/SKILL.md) | Core systems: storage, approvals, calendar | Included with all skills |
| [chat-turn](./chat-turn/SKILL.md) | Conversational AI with 6-phase processing | Processing any user message |
| [tools](./tools/SKILL.md) | Calendar, reminders, weather, groceries, search | Utility operations |

### Family Management
| Skill | Description | Use When |
|-------|-------------|----------|
| [family-comms](./family-comms/SKILL.md) | Announcements, calendar, chores, check-ins | Family coordination |
| [family-bonding](./family-bonding/SKILL.md) | Activity ideas and outing planning | Family activity suggestions |
| [mental-load](./mental-load/SKILL.md) | Reduce cognitive burden with automation | Feeling overwhelmed, need planning |
| [elder-care](./elder-care/SKILL.md) | Check-in on elderly parents, medication, engagement | Caring for aging parents |

### Education
| Skill | Description | Use When |
|-------|-------------|----------|
| [education](./education/SKILL.md) | Homework, grades, LMS integration | School tasks for children |
| [school](./school/SKILL.md) | Orchestrate full school management | Comprehensive school monitoring |

### Health & Wellness
| Skill | Description | Use When |
|-------|-------------|----------|
| [healthcare](./healthcare/SKILL.md) | Doctors, medications, appointments, symptoms | Health management |
| [wellness](./wellness/SKILL.md) | Hydration, movement, sleep, screen time | Daily wellness tracking |
| [habits](./habits/SKILL.md) | Habit tracking with behavioral science | Building new habits |

### Personal Growth
| Skill | Description | Use When |
|-------|-------------|----------|
| [psy-rich](./psy-rich/SKILL.md) | Psychologically rich experience suggestions | Want meaningful activities |
| [note-to-actions](./note-to-actions/SKILL.md) | Turn content into atomic habits | Applying what you learn |

### Services & Booking
| Skill | Description | Use When |
|-------|-------------|----------|
| [restaurant-reservation](./restaurant-reservation/SKILL.md) | Restaurant search and booking | Book a table |
| [marketplace-sell](./marketplace-sell/SKILL.md) | Sell items on FB Marketplace/eBay | Sell something |
| [hire-helper](./hire-helper/SKILL.md) | Find babysitters, cleaners, tutors | Need household help |
| [telephony](./telephony/SKILL.md) | AI voice calls for reservations, appointments | Phone-based tasks |

### Home Management
| Skill | Description | Use When |
|-------|-------------|----------|
| [home-maintenance](./home-maintenance/SKILL.md) | Repairs, contractors, emergencies | Home repair needs |
| [meal-planning](./meal-planning/SKILL.md) | Weekly meals with grocery lists | Food planning |
| [transportation](./transportation/SKILL.md) | Rides, commute, carpools, parking | Getting around |

## Skill Categories

### Core
- **_infrastructure** - Storage, approvals, calendar, error handling (included with all skills)
- **chat-turn** - Core conversation handling with memory, planning, and execution
- **tools** - Utility functions: calendar, reminders, weather, search

### Family Life
- **family-comms** - Family coordination, announcements, chores
- **family-bonding** - Activity planning and quality time
- **mental-load** - Reduce cognitive burden, automate planning
- **elder-care** - Care for aging parents

### Education
- **education** - School task management
- **school** - Comprehensive school workflow orchestration

### Health & Wellness
- **healthcare** - Medical appointments, medications, symptoms
- **wellness** - Daily health habits and tracking
- **habits** - Behavior change with psychological insights

### Personal Development
- **psy-rich** - Psychologically rich experiences
- **note-to-actions** - Content to atomic habits

### Services
- **restaurant-reservation** - Restaurant booking
- **marketplace-sell** - Online selling
- **hire-helper** - Household help recruitment
- **telephony** - AI voice calling

### Home
- **home-maintenance** - Repairs and emergencies
- **meal-planning** - Food planning and groceries
- **transportation** - Rides and commute management

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
│   ├── calendar.json      # Local calendar cache
│   ├── education/         # School data
│   ├── health/            # Healthcare data
│   ├── habits/            # Habit tracking
│   ├── wellness/          # Wellness logs
│   └── elder_care/        # Elder care profiles
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
6. **Conversational** - Natural dialogue, not forms
7. **Context-Aware** - Use known preferences, adapt to situation
8. **Stress-Aware** - Gentle when needed, challenging when appropriate

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
