---
name: chat-turn
description: Handle conversational AI interactions with multi-phase processing including understanding, memory recall, planning, execution, and reflection. Use when the user sends a chat message, asks a question, requests information, or wants to perform any action through natural language conversation.
---

# Chat Turn Skill

Process user messages through a sophisticated 6-phase pipeline that understands intent, recalls relevant context, plans actions, executes with appropriate approval gates, and learns from interactions.

## When to Use

- User sends any chat message or question
- User requests an action (e.g., "book a restaurant", "order groceries")
- User asks for information or recommendations
- Any conversational interaction requiring understanding and response

## Processing Phases

### Phase 1: Understand

Analyze the user's message to extract:

- **Intent**: What the user wants to accomplish
- **Entities**: People, places, dates, items mentioned
- **Sentiment**: Emotional tone and urgency
- **Context Requirements**: What additional information is needed

```typescript
interface UnderstandResult {
  intent: string;
  entities: Entity[];
  sentiment: 'positive' | 'neutral' | 'negative' | 'urgent';
  confidence: number;
  clarificationNeeded?: string[];
}
```

### Phase 2: Recall

Query the memory system to retrieve relevant context:

- Recent conversation history
- User preferences and past interactions
- Family member information
- Related tasks and their outcomes
- Workspace-specific knowledge

### Phase 3: Plan

Generate an execution plan based on understanding and context:

```typescript
interface ActionPlan {
  steps: PlanStep[];
  riskLevel: 'LOW' | 'MEDIUM' | 'HIGH';
  estimatedDuration: string;
  requiredApprovals: string[];
  fallbackStrategy?: string;
}

interface PlanStep {
  id: string;
  action: string;
  tool?: string;
  parameters?: Record<string, unknown>;
  dependsOn?: string[];
}
```

### Phase 4: Execute

Execute the plan with appropriate approval gates:

**Risk Levels:**

| Level | Description | Approval Required |
|-------|-------------|-------------------|
| LOW | Read-only, informational | No |
| MEDIUM | Limited impact, reversible | User preference |
| HIGH | Financial, external calls, irreversible | Always |

**HIGH Risk Actions (Always Require Approval):**
- Phone calls to external parties
- Financial transactions > $50
- Posting to social media
- Sending messages on user's behalf
- Modifying calendar events
- Purchasing items

### Phase 5: Reflect

After execution, analyze the outcome:

- Was the user's intent satisfied?
- What worked well or poorly?
- Should any preferences be updated?
- Are follow-up actions needed?

### Phase 6: Writeback

Persist learnings to the memory system:

- Update user preferences based on choices
- Store successful interaction patterns
- Record task outcomes for future reference
- Update entity relationships

## Response Format

Always respond with:

1. **Acknowledgment**: Confirm understanding of the request
2. **Status**: Current progress or completion state
3. **Details**: Relevant information or results
4. **Next Steps**: What happens next or what the user can do

## Multi-Tenant Considerations

- All data is scoped to the workspace
- Never expose data from other workspaces
- Respect user-specific preferences within the workspace
- Handle family member context appropriately

## Error Handling

When errors occur:

1. Provide a clear, non-technical explanation
2. Suggest alternative approaches if available
3. Offer to retry or escalate as appropriate
4. Log errors for system improvement

## Example Interaction

**User**: "Can you make a dinner reservation for my anniversary next Friday?"

**Phase 1 (Understand)**:
- Intent: Restaurant reservation
- Entities: Occasion (anniversary), Date (next Friday)
- Sentiment: Positive, planning ahead

**Phase 2 (Recall)**:
- User's favorite cuisine preferences
- Past anniversary restaurant choices
- Partner's dietary restrictions
- Preferred reservation times

**Phase 3 (Plan)**:
1. Search for romantic restaurants
2. Filter by dietary requirements
3. Present options to user
4. Get approval for selection
5. Make reservation call
6. Add to calendar

**Phase 4 (Execute)**:
- Present restaurant options (LOW risk)
- Await user selection
- Request approval for call (HIGH risk)
- Execute reservation workflow

**Phase 5 (Reflect)**:
- Reservation successful
- User chose Italian restaurant
- Update preference weights

**Phase 6 (Writeback)**:
- Store restaurant preference
- Link to anniversary occasion type
- Record successful interaction pattern
