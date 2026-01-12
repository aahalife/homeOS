# Hearth: Family Assistant for Mac

> A simple, delightful Mac app that helps families stay connected, organized, and cared for.

This directory contains the complete Product Requirements Document (PRD) for Hearth, a native macOS application built on top of Clawdbot that brings AI-powered family assistance to the Mac with an Apple-quality user experience.

## Documents

### Core PRD
| Document | Description |
|----------|-------------|
| [PRD.md](./PRD.md) | Complete Product Requirements Document |
| [USER_STORIES.md](./USER_STORIES.md) | Detailed user stories with acceptance criteria |
| [PERSONAS.md](./PERSONAS.md) | Target user personas and scenarios |

### Design & Experience
| Document | Description |
|----------|-------------|
| [DESIGN_PRINCIPLES.md](./DESIGN_PRINCIPLES.md) | Apple-inspired design philosophy |
| [SOUL.md](./SOUL.md) | Personality, voice, and emotional intelligence |
| [MULTI_CHANNEL_FLOWS.md](./MULTI_CHANNEL_FLOWS.md) | User flows across Mac, iMessage, phone, voice |

### Technical Implementation
| Document | Description |
|----------|-------------|
| [TECHNICAL_ARCHITECTURE.md](./TECHNICAL_ARCHITECTURE.md) | SwiftUI + Clawdbot integration |
| [CLAWDBOT_INTEGRATION.md](./CLAWDBOT_INTEGRATION.md) | Clawdbot config, code changes, setup |
| [SKILLS_CATALOG.md](./SKILLS_CATALOG.md) | 100+ skills organized by domain |
| [AUTOMATION_PATTERNS.md](./AUTOMATION_PATTERNS.md) | Allowlists, error recovery, parallel execution |

## Quick Summary

**Hearth** is a native macOS menu bar application that serves as a family's digital assistant hub. It connects to Clawdbot as its backend and provides a beautifully simple interface for:

- 👨‍👩‍👧‍👦 **Family Coordination** - Shared calendars, chore management, announcements
- 👵 **Elder Care Check-ins** - Daily AI-powered calls with grandparents, medication reminders
- 📚 **Education Support** - Homework tracking, grade monitoring for kids
- 🏠 **Home Management** - Meal planning, maintenance scheduling, bill tracking
- 💆 **Mental Load Reduction** - Proactive reminders, decision simplification
- 💰 **Financial Automation** - Bill detection, payment tracking, subscription management
- 🫁 **Emotional Support** - Meltdown support, mindfulness, screen time management

## Target Family

A typical US family:
- **Parents** (Mom & Dad) - Primary users, managing household
- **Children** (2 kids, ages 8 & 12) - Homework, activities, chores
- **Grandparents** - Elder care check-ins, connection, engagement

## Key Differentiators

### 1. Relentless Automation
Hearth doesn't just remind - it **does**. Bill detected? Paid. Form needed? Filled. Service signup required? Done. With smart "always allow" rules and the Ralph Wiggum error recovery pattern, tasks complete themselves.

### 2. Multi-Channel Native
Not just a Mac app - Hearth reaches family members where they are:
- Parents: Mac app + iMessage + voice
- Teens: iMessage
- Kids: Parent-mediated reminders
- Grandparents: AI phone calls

### 3. Warm, Not Robotic
Hearth has a soul - warm, capable, anticipatory. It celebrates wins, stays calm in crises, and knows when to back off. See [SOUL.md](./SOUL.md).

### 4. Privacy-First
All data local by default. No monetization of family data. Ever.

## Built On

- [Clawdbot](https://github.com/clawdbot/clawdbot) - Core AI assistant backend
- [HomeOS Skills](../homeskills/) - Family-focused capabilities

## Skills Coverage

100+ skills across 12 domains (see [SKILLS_CATALOG.md](./SKILLS_CATALOG.md)):

1. **Financial Management** - Bills, payments, budgeting, subscriptions
2. **Home Operations** - Maintenance, cleaning, emergencies, inventory
3. **Family Logistics** - Calendar, transportation, activities, events
4. **Health & Wellness** - Appointments, medications, fitness, sleep
5. **Education** - Homework, grades, school communications, tutoring
6. **Elder Care** - Check-ins, medications, engagement, safety
7. **Nutrition & Meals** - Planning, recipes, groceries, restaurants
8. **Emotional Support** - Meltdowns, mindfulness, screen time, bonding
9. **Social & Relationships** - Birthdays, gifts, thank-yous
10. **Administrative** - Documents, renewals, warranties, insurance
11. **Communication** - Multi-channel messaging, voice, telephony
12. **Automation** - Orchestration, preferences, error recovery

## Philosophy

*"Technology should help families be more present with each other, not more distracted."*

Hearth embraces Apple's design philosophy:
- **Simple** - One-click actions, no configuration required
- **Delightful** - Beautiful animations, warm personality
- **Invisible** - Works in the background until needed
- **Trustworthy** - Clear privacy, user control over data
- **Relentless** - Automates everything possible, learns and improves

## Getting Started

See [CLAWDBOT_INTEGRATION.md](./CLAWDBOT_INTEGRATION.md) for:
- Clawdbot configuration
- Required API keys and services
- Workspace setup
- Cron job configuration
- Multi-channel provider setup

---

*Hearth: The warm, capable presence that helps families thrive.*
