# Restaurant Reservation Skill

Make restaurant reservations via automated phone calls using voice AI.

## Purpose

Search for restaurants, select a candidate, and make a reservation by placing an automated phone call.

## Prerequisites

- Retell AI API key (for voice AI)
- Twilio account (for phone infrastructure)
- Google Places API key (for restaurant discovery)
- Google Calendar API (for scheduling integration)

## Input Parameters

```typescript
interface ReservationInput {
  workspaceId: string;
  userId: string;
  restaurantType: string;        // "Italian", "sushi", "steakhouse"
  dateTime: string;              // "2024-01-15 7:00 PM"
  partySize: number;             // 4
  specialRequests: string[];     // ["outdoor seating", "high chair"]
  location: string;              // "San Francisco, CA"
  negotiationBounds: {
    timeFlexibility: string;     // "30 minutes"
    priceRange?: { min: number; max: number };
  };
}
```

## Step-by-Step Instructions

### Step 1: Search for Candidates

**Risk Level: LOW**

Search for restaurants matching the user's criteria.

```typescript
// Use Google Places API
const searchParams = {
  query: `${restaurantType} restaurant`,
  location: location,
  type: 'restaurant',
  openNow: false  // We want to check availability, not just open now
};

const candidates = await googlePlaces.textSearch(searchParams);

// Enrich with details (phone number, hours)
const enrichedCandidates = [];
for (const place of candidates.slice(0, 5)) {
  const details = await googlePlaces.placeDetails(place.place_id, [
    'formatted_phone_number',
    'opening_hours',
    'website'
  ]);

  if (details.formatted_phone_number) {
    enrichedCandidates.push({
      id: place.place_id,
      name: place.name,
      address: place.formatted_address,
      phoneNumber: details.formatted_phone_number,
      rating: place.rating,
      priceLevel: place.price_level,
      hours: details.opening_hours?.weekday_text,
      website: details.website
    });
  }
}
```

### Step 2: Present Candidates to User

**Risk Level: LOW**

Show the user the top candidates and let them select one.

```typescript
// Emit event with candidates for user selection
await emit('reservation.candidates', {
  workspaceId,
  candidates: enrichedCandidates.slice(0, 3)
});

// Wait for user selection
const selection = await waitForSignal('candidateSelection', {
  timeout: '1 hour'
});

const chosen = candidates.find(c => c.id === selection.selectedCandidateId);
```

### Step 3: Request Call Approval

**Risk Level: HIGH - REQUIRES APPROVAL**

Before placing a phone call, request explicit user approval.

```typescript
const approvalEnvelope = {
  intent: `Call ${chosen.name} to make a reservation`,
  toolName: 'telephony.place_call',
  inputs: {
    phoneNumber: chosen.phoneNumber,
    restaurantName: chosen.name,
    dateTime: dateTime,
    partySize: partySize,
    specialRequests: specialRequests,
    negotiationBounds: negotiationBounds
  },
  riskLevel: 'high',
  piiFields: ['phoneNumber'],
  expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
};

const approved = await requestApproval(approvalEnvelope);
if (!approved) {
  return { success: false, reason: 'User did not approve the call' };
}
```

### Step 4: Configure Voice Agent

**Risk Level: MEDIUM**

Set up the Retell AI agent with the appropriate script.

```typescript
const agentPrompt = `You are a friendly, professional assistant making a phone call to book a restaurant reservation on behalf of a family. Be polite, natural, and conversational.

## Your Task
- Make a reservation for ${partySize} people
- Requested date and time: ${dateTime}
- Name for reservation: ${userName}

## Conversation Guidelines
1. Greet warmly and state your purpose clearly
2. Provide all necessary details: party size, date, time, name for reservation
3. If the requested time isn't available, ask for the next closest option
4. Confirm all details before ending the call
5. Thank them and say goodbye politely

## Important Rules
- NEVER share credit card information
- If they ask questions you can't answer, say you'll call back
- Stay calm if put on hold - wait patiently
- If the call seems to be going nowhere after 3 attempts, politely end

## Handling Negotiation
- If requested time unavailable: Accept alternatives within ${negotiationBounds.timeFlexibility}
- If they require a deposit: Politely decline, say you'll provide upon arrival

## Special Requests
${specialRequests.join(', ')}`;

const agentId = await retell.createAgent({
  agentName: `reservation-${Date.now()}`,
  voiceId: '11labs-Adrian',
  generalPrompt: agentPrompt,
  beginMessage: `Hi! I'm calling to make a reservation at ${chosen.name}. I'd like a table for ${partySize} on ${dateTime}.`,
  maxCallDurationSec: 600,
  enableBackchannel: true
});
```

### Step 5: Place the Call

**Risk Level: HIGH**

Initiate the phone call via Retell AI.

```typescript
const callResult = await retell.createPhoneCall({
  agentId,
  toPhoneNumber: formatE164(chosen.phoneNumber),
  fromPhoneNumber: twilioPhoneNumber,
  metadata: {
    workspaceId,
    purpose: 'restaurant_reservation'
  },
  retellLlmDynamicVariables: {
    restaurant_name: chosen.name,
    party_size: partySize.toString(),
    date_time: dateTime,
    user_name: userName
  }
});

// Poll for completion
const completedCall = await pollCallStatus(callResult.callId, {
  maxWaitMs: 600000,  // 10 minutes
  pollIntervalMs: 5000
});
```

### Step 6: Analyze Transcript

**Risk Level: LOW**

Use LLM to analyze the call transcript and extract results.

```typescript
const analysisPrompt = `Analyze this restaurant reservation call transcript and extract:
{
  "callSuccessful": boolean,
  "summary": "brief summary",
  "confirmedDateTime": "YYYY-MM-DD HH:MM" or null,
  "confirmationNumber": "string" or null,
  "needsFollowUp": boolean,
  "followUpReason": "string" or null
}`;

const analysis = await llm.complete({
  system: analysisPrompt,
  user: completedCall.transcript
});
```

### Step 7: Create Calendar Event

**Risk Level: LOW**

If reservation successful, add to the user's calendar.

```typescript
if (analysis.callSuccessful) {
  await calendar.createEvent({
    workspaceId,
    userId,
    title: `Reservation at ${chosen.name}`,
    dateTime: analysis.confirmedDateTime || dateTime,
    durationMinutes: 120,
    location: chosen.address,
    notes: `Party of ${partySize}. Confirmation: ${analysis.confirmationNumber || 'N/A'}`,
    reminders: [60, 1440]  // 1 hour and 1 day before
  });
}
```

## Error Handling

| Error | Recovery |
|-------|----------|
| No candidates found | Broaden search criteria or try different location |
| Call not answered | Try again later or try next candidate |
| Voicemail reached | Leave no message, try again during business hours |
| No availability | Ask user if they want to try different date/time |
| Retell API error | Retry with exponential backoff |

## Output

```typescript
interface ReservationOutput {
  success: boolean;
  reservation?: {
    restaurantName: string;
    dateTime: string;
    confirmationNumber?: string;
  };
  transcript?: string;
}
```

## Approval Requirements

The following actions require user approval:

| Action | Risk Level | Reason |
|--------|------------|--------|
| Place phone call | HIGH | External communication |
| Share phone number | HIGH | PII sharing |
| Accept deposit requirement | HIGH | Financial commitment |
