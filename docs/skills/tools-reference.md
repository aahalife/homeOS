# HomeOS Tools Reference

This document describes all available tools that can be used by Claude skills and agents.

## Tool Categories

- **LLM Tools** - Natural language understanding and generation
- **Memory Tools** - Store and retrieve information
- **Telephony Tools** - Make and manage phone calls
- **Calendar Tools** - Manage schedules and events
- **Marketplace Tools** - Buy and sell items
- **Integration Tools** - Connect with external services

---

## LLM Tools

### understand

Analyze a user message to extract intent and entities.

```typescript
interface UnderstandInput {
  workspaceId: string;
  userId: string;
  message: string;
  sessionId?: string;
}

interface UnderstandOutput {
  intent: string;
  entities: Record<string, unknown>;
  confidence: number;
  needsClarification: boolean;
  clarificationQuestions?: string[];
}
```

**Risk Level:** LOW

### plan

Create an execution plan for a user request.

```typescript
interface PlanInput {
  workspaceId: string;
  userId: string;
  understanding: UnderstandOutput;
  memories: unknown[];
}

interface PlanOutput {
  steps: PlanStep[];
  reasoning: string;
}
```

**Risk Level:** LOW

### reflect

Validate the result of a tool execution.

```typescript
interface ReflectInput {
  workspaceId: string;
  step: PlanStep;
  result: unknown;
}

interface ReflectOutput {
  success: boolean;
  issues?: string[];
  shouldRetry?: boolean;
}
```

**Risk Level:** LOW

### writeback

Generate a response to the user.

```typescript
interface WritebackInput {
  workspaceId: string;
  userId: string;
  sessionId?: string;
  understanding: UnderstandOutput;
  executedActions: string[];
}

interface WritebackOutput {
  content: string;
}
```

**Risk Level:** LOW

---

## Memory Tools

### recall

Retrieve relevant memories from storage.

```typescript
interface RecallInput {
  workspaceId: string;
  query: string;
  context?: unknown;
  types?: ('working' | 'episodic' | 'semantic' | 'procedural' | 'strategic')[];
  limit?: number;
}

interface RecallOutput {
  memories: Memory[];
  relevanceScores: number[];
}
```

**Risk Level:** LOW

### storeMemory

Store information in memory.

```typescript
interface StoreMemoryInput {
  workspaceId: string;
  type: 'working' | 'episodic' | 'semantic' | 'procedural' | 'strategic';
  content: string;
  salience?: number;      // 0-1, importance
  piiLevel?: 'none' | 'low' | 'high';
  tags?: string[];
}

interface StoreMemoryOutput {
  memoryId: string;
  stored: boolean;
}
```

**Risk Level:** LOW

### searchEntities

Search for stored entities.

```typescript
interface SearchEntitiesInput {
  workspaceId: string;
  kind?: 'person' | 'place' | 'organization' | 'product' | 'event' | 'concept';
  query: string;
}

interface Entity {
  id: string;
  kind: string;
  name: string;
  attributes: Record<string, unknown>;
}
```

**Risk Level:** LOW

---

## Telephony Tools

### placeCall

Make an automated phone call using voice AI.

```typescript
interface PlaceCallInput {
  workspaceId: string;
  phoneNumber: string;
  purpose: 'restaurant_reservation' | 'appointment_booking' | 'general_inquiry' | 'customer_service';
  script: {
    greeting: string;
    request: string;
    specialRequests?: string[];
    negotiationBounds?: {
      timeFlexibility?: string;
      priceRange?: { min: number; max: number };
      depositAllowed?: boolean;
    };
  };
  context?: {
    businessName?: string;
    dateTime?: string;
    partySize?: number;
    userName?: string;
  };
  idempotencyKey: string;
}

interface PlaceCallOutput {
  callSid: string;
  status: 'completed' | 'failed' | 'no_answer' | 'busy' | 'voicemail';
  transcript: string;
  outcome: 'success' | 'voicemail' | 'no_answer' | 'failed' | 'callback_needed';
  analysis?: CallAnalysis;
  recordingUrl?: string;
  durationSeconds?: number;
}
```

**Risk Level:** HIGH - Requires approval

### searchCandidates

Search for businesses or service providers.

```typescript
interface SearchCandidatesInput {
  workspaceId: string;
  type: 'restaurant' | 'doctor' | 'salon' | 'service' | 'store';
  query: string;
  location: string;
  dateTime?: string;
  filters?: {
    minRating?: number;
    priceLevel?: number;
    openNow?: boolean;
  };
}

interface Candidate {
  id: string;
  name: string;
  address: string;
  phoneNumber: string;
  rating?: number;
  priceLevel?: number;
  hours?: string[];
  website?: string;
}
```

**Risk Level:** LOW

### handleCallOutcome

Process the results of a completed call.

```typescript
interface HandleCallOutcomeInput {
  workspaceId: string;
  callResult: PlaceCallOutput;
}

interface HandleCallOutcomeOutput {
  success: boolean;
  confirmedDateTime?: string;
  confirmationNumber?: string;
  needsFollowUp?: boolean;
  followUpAction?: string;
}
```

**Risk Level:** LOW

---

## Calendar Tools

### createCalendarEvent

Create a calendar event.

```typescript
interface CreateCalendarEventInput {
  workspaceId: string;
  userId: string;
  title: string;
  dateTime: string;
  durationMinutes?: number;
  location?: string;
  notes?: string;
  reminders?: number[];  // minutes before
}

interface CalendarEvent {
  eventId: string;
  title: string;
  startTime: string;
  endTime: string;
  location?: string;
  link?: string;
}
```

**Risk Level:** LOW

### getCalendarAvailability

Check calendar availability.

```typescript
interface GetCalendarAvailabilityInput {
  workspaceId: string;
  userId: string;
  startDate: string;
  endDate: string;
}

interface TimeSlot {
  start: string;
  end: string;
  available: boolean;
}
```

**Risk Level:** LOW

---

## Marketplace Tools

### identifyItem

Identify an item from photos using vision AI.

```typescript
interface IdentifyItemInput {
  workspaceId: string;
  photos: string[];
  userDescription?: string;
}

interface IdentifyItemOutput {
  name: string;
  brand?: string;
  model?: string;
  condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor';
  category: string;
  features: string[];
  flaws: string[];
}
```

**Risk Level:** LOW

### findComparables

Find similar items for pricing.

```typescript
interface FindComparablesInput {
  workspaceId: string;
  itemName: string;
  brand?: string;
  condition: string;
}

interface Comparable {
  source: string;
  price: number;
  sold: boolean;
  condition: string;
  url: string;
}
```

**Risk Level:** LOW

### createListingDraft

Generate a marketplace listing.

```typescript
interface CreateListingDraftInput {
  workspaceId: string;
  itemInfo: IdentifyItemOutput;
  comparables: Comparable[];
  photos: string[];
}

interface ListingDraft {
  title: string;
  description: string;
  price: number;
  category: string;
  condition: string;
  tags: string[];
}
```

**Risk Level:** MEDIUM

### postListing

Publish a listing to marketplace.

```typescript
interface PostListingInput {
  workspaceId: string;
  draft: ListingDraft;
  idempotencyKey: string;
}

interface PostListingOutput {
  listingId: string;
  url: string;
  status: 'active' | 'pending' | 'failed';
}
```

**Risk Level:** HIGH - Requires approval

### checkMessageRisk

Analyze a buyer message for scam patterns.

```typescript
interface CheckMessageRiskInput {
  workspaceId: string;
  buyerId: string;
  content: string;
}

interface CheckMessageRiskOutput {
  isScam: boolean;
  reason?: string;
  intent: 'question' | 'price_negotiation' | 'purchase' | 'other';
  requiresAddressSharing?: boolean;
  proposedTimes?: string[];
}
```

**Risk Level:** LOW

### sendBuyerMessage

Send a message to a buyer.

```typescript
interface SendBuyerMessageInput {
  workspaceId: string;
  listingId: string;
  buyerId: string;
  message: string;
  idempotencyKey: string;
}
```

**Risk Level:** MEDIUM

---

## Approval Tools

### requestApproval

Request user approval for a high-risk action.

```typescript
interface RequestApprovalInput {
  workspaceId: string;
  userId: string;
  intent: string;
  toolName: string;
  inputs: Record<string, unknown>;
  riskLevel: 'low' | 'medium' | 'high';
  piiFields?: string[];
  expiresIn?: number;  // milliseconds
}

interface RequestApprovalOutput {
  envelopeId: string;
  status: 'pending' | 'approved' | 'denied' | 'expired';
}
```

**Risk Level:** N/A (meta-tool)

---

## Event Tools

### emitTaskEvent

Emit an event for task progress tracking.

```typescript
interface EmitTaskEventInput {
  workspaceId: string;
  eventType: string;
  payload: Record<string, unknown>;
}
```

**Risk Level:** LOW

---

## Integration Tools

### composioExecute

Execute an action via Composio integration.

```typescript
interface ComposioExecuteInput {
  workspaceId: string;
  action: string;
  params: Record<string, unknown>;
  connectionId?: string;
}

interface ComposioExecuteOutput {
  success: boolean;
  data?: unknown;
  error?: string;
}
```

**Risk Level:** VARIES by action

---

## Risk Level Guidelines

| Risk Level | Requires Approval | Examples |
|------------|-------------------|----------|
| LOW | No | Reading data, searching, analyzing |
| MEDIUM | Sometimes | Creating drafts, scheduling |
| HIGH | Always | Phone calls, payments, sharing PII, posting publicly |

## Idempotency

Tools that modify external state should include an `idempotencyKey` parameter to prevent duplicate operations if retried.

```typescript
// Good
await postListing({
  workspaceId,
  draft,
  idempotencyKey: `listing-${workspaceId}-${itemId}-${timestamp}`
});

// The same idempotencyKey will return the same result without creating duplicates
```

## Error Handling

All tools return errors in a consistent format:

```typescript
interface ToolError {
  code: string;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
}

// Common error codes
// 'NOT_FOUND' - Resource not found
// 'UNAUTHORIZED' - Missing or invalid credentials
// 'RATE_LIMITED' - Too many requests
// 'VALIDATION_ERROR' - Invalid input
// 'EXTERNAL_ERROR' - Third-party API error
// 'TIMEOUT' - Operation timed out
```
