# HomeOS Claude Skills

This directory contains Claude skills that can be used by AI agents to perform HomeOS tasks. These skills provide step-by-step guidance for accomplishing family home automation tasks, and can be used independently of Temporal workflows.

## Skill Categories

### Conversational Skills
- **chat-turn.md** - Handle natural language conversation with understanding, planning, and execution

### Reservation & Booking Skills
- **restaurant-reservation.md** - Make restaurant reservations via phone calls
- **appointment-booking.md** - Schedule appointments with service providers

### Marketplace Skills
- **marketplace-sell.md** - List and sell items on Facebook Marketplace/eBay
- **marketplace-buy.md** - Search and purchase items from online marketplaces

### Family Management Skills
- **meal-planning.md** - Generate weekly meal plans and grocery lists
- **family-bonding.md** - Plan family activities and outings
- **family-communication.md** - Manage family calendars and coordination

### Home Management Skills
- **home-maintenance.md** - Track and schedule home maintenance tasks
- **hire-helper.md** - Find and hire domestic help and service providers

### Health & Wellness Skills
- **healthcare.md** - Manage healthcare appointments and records
- **wellness.md** - Track wellness activities and routines
- **transportation.md** - Manage family transportation and logistics

### Education Skills
- **school.md** - Track school activities, homework, and events

## Using These Skills

Each skill file contains:

1. **Purpose** - What the skill accomplishes
2. **Prerequisites** - Required APIs, credentials, or setup
3. **Input Parameters** - What information the agent needs
4. **Step-by-Step Instructions** - How to execute the skill
5. **Error Handling** - How to handle common errors
6. **Approval Gates** - When to ask for user approval (HIGH risk actions)

### Risk Levels

Skills use three risk levels:
- **LOW** - Safe actions that don't require approval (reading data, searching)
- **MEDIUM** - Actions with limited impact (creating drafts, generating plans)
- **HIGH** - Actions requiring approval (phone calls, payments, posting publicly, sharing PII)

### Example Usage

```typescript
// Agent receives user message: "Book me a table at an Italian restaurant for 4 people tonight"

// 1. Understand the intent
const understanding = {
  intent: "restaurant_reservation",
  entities: {
    cuisine: "Italian",
    partySize: 4,
    dateTime: "tonight"
  }
};

// 2. Load the restaurant-reservation skill
// 3. Execute each step, requesting approval for HIGH risk actions
// 4. Return the result to the user
```

## Multi-Tenant Considerations

When executing skills in a multi-tenant environment:

1. **Workspace Isolation** - All data operations must be scoped to the user's workspaceId
2. **Credential Management** - API keys are stored per-workspace in encrypted secrets
3. **Rate Limiting** - Respect per-user rate limits on external APIs
4. **Audit Logging** - Log all actions with workspaceId for compliance

## Transitioning from Temporal

These skills can replace Temporal workflows when:
- Lower latency is needed for simple tasks
- Cost optimization is required
- Running in environments without Temporal
- Using open-source LLMs that don't support Temporal SDK

The skill format ensures consistent behavior whether using Temporal workflows or direct agent execution.
