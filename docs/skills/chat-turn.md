# Chat Turn Skill

Handle natural language conversation with understanding, planning, execution, and response generation.

## Purpose

Process a user's natural language message and respond appropriately, potentially executing actions on their behalf.

## Prerequisites

- LLM API key (Anthropic or OpenAI)
- Memory storage system
- Tool registry

## Input Parameters

```typescript
interface ChatTurnInput {
  workspaceId: string;
  userId: string;
  message: string;
  sessionId?: string;
}
```

## Step-by-Step Instructions

### Phase 1: Understand

**Risk Level: LOW**

Parse the user's message to extract intent and entities.

```typescript
// System prompt for understanding
const systemPrompt = `You are analyzing a user message to understand their intent.
Extract:
- intent: What does the user want to accomplish?
- entities: Named entities like names, dates, locations, items
- confidence: How confident are you in this understanding (0-1)?
- needsClarification: Does this need clarification before proceeding?
- clarificationQuestions: If clarification is needed, what questions?

Respond in JSON format.`;

// Call LLM
const understanding = await llm.complete({
  system: systemPrompt,
  user: message
});
```

### Phase 2: Recall

**Risk Level: LOW**

Retrieve relevant memories from the user's workspace.

```typescript
// Query memory store
const memories = await memory.search({
  workspaceId,
  query: message,
  types: ['episodic', 'semantic', 'procedural'],
  limit: 10
});
```

### Phase 3: Plan

**Risk Level: LOW**

Create an execution plan based on understanding and memories.

```typescript
// System prompt for planning
const systemPrompt = `You are a planning agent. Given the user's intent and relevant memories,
create a step-by-step plan to accomplish their goal.

For each step, specify:
- intent: What this step accomplishes
- toolName: Which tool to use
- inputs: The inputs for the tool
- riskLevel: low, medium, or high
- requiresApproval: Whether user approval is needed

High-risk actions that ALWAYS require approval:
- Spending money (checkout, deposits, payments)
- External communications (calls, messages, emails)
- Public posting (marketplace listings, social media)
- Sharing PII (address, phone, personal info)
- Deleting or modifying data

Respond in JSON format with { steps: [...], reasoning: "..." }`;
```

### Phase 4: Execute (with Approval Gates)

**Risk Level: VARIES**

Execute each step in the plan, requesting approval for HIGH risk actions.

```typescript
for (const step of plan.steps) {
  if (step.requiresApproval) {
    // Create approval envelope
    const envelope = {
      intent: step.intent,
      toolName: step.toolName,
      inputs: step.inputs,
      riskLevel: step.riskLevel,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    };

    // Request approval from user
    const approved = await requestApproval(envelope);

    if (!approved) {
      executedActions.push(`Skipped: ${step.intent} (not approved)`);
      continue;
    }
  }

  // Execute the tool
  try {
    const result = await tools.execute(step.toolName, step.inputs);
    executedActions.push(`Completed: ${step.intent}`);

    // Phase 5: Reflect on result
    await reflect(step, result);
  } catch (error) {
    executedActions.push(`Failed: ${step.intent} - ${error.message}`);
  }
}
```

### Phase 5: Reflect

**Risk Level: LOW**

Validate the result of each action.

```typescript
const reflectionPrompt = `You are validating the result of a tool execution.
Check if the result matches expectations and identify any issues.

Respond in JSON: { success: boolean, issues?: string[], shouldRetry?: boolean }`;
```

### Phase 6: Writeback

**Risk Level: LOW**

Update memory and generate the response.

```typescript
// Store new memories
await memory.store({
  workspaceId,
  type: 'episodic',
  content: `User asked: ${message}. Actions taken: ${executedActions.join(', ')}`,
  salience: 0.7
});

// Generate response
const responsePrompt = `You are generating a response to the user summarizing what was done.
Be concise and friendly. Use bullet points for multiple actions.`;

const response = await llm.complete({
  system: responsePrompt,
  user: JSON.stringify({ intent: understanding.intent, actions: executedActions })
});
```

## Error Handling

| Error | Recovery |
|-------|----------|
| LLM API error | Retry with exponential backoff, fallback to simpler model |
| Tool execution failed | Log error, continue with next step, inform user |
| Memory lookup failed | Continue without memories, log warning |
| Approval timeout | Skip action, inform user |

## Output

```typescript
interface ChatTurnOutput {
  response: string;
  actions: string[];
}
```

## Available Tools

The following tools can be invoked during execution:

- `calendar.create_event` - Create calendar events
- `calendar.check_availability` - Check calendar availability
- `telephony.place_call` - Make phone calls (HIGH risk)
- `telephony.search_candidates` - Search for businesses
- `marketplace.create_listing` - Create marketplace listing (HIGH risk)
- `memory.store` - Store information in memory
- `memory.recall` - Retrieve information from memory
