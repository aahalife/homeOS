---
name: restaurant-reservation
description: Make restaurant reservations by calling restaurants directly using AI voice. Use when the user wants to book a table, make a dinner reservation, reserve a restaurant, or schedule dining at a specific venue. Handles the complete flow from search to confirmation.
---

# Restaurant Reservation Skill

Automate restaurant reservations using AI-powered voice calls. This skill searches for restaurants, presents options, and makes reservation calls on behalf of the user with their approval.

## When to Use

- User asks to "book a restaurant" or "make a reservation"
- User mentions "dinner reservation", "lunch booking", or "table for X"
- User wants to celebrate an occasion at a restaurant
- User needs to find and book a restaurant for a specific date/time

## Prerequisites

- Twilio phone number configured for the workspace
- Voice synthesis service available (Echo-TTS or 11Labs)
- User approval for outbound calls (HIGH risk action)

## Workflow Steps

### Step 1: Search Restaurants

Search based on user criteria:

```typescript
interface SearchCriteria {
  cuisine?: string;          // Italian, Japanese, Mexican, etc.
  location: string;          // Address or area
  priceRange?: '$' | '$$' | '$$$' | '$$$$';
  rating?: number;           // Minimum rating (1-5)
  occasion?: string;         // Anniversary, birthday, business
  partySize: number;
  date: string;              // YYYY-MM-DD
  preferredTime: string;     // HH:MM
  dietaryRequirements?: string[];
}
```

**Data Sources:**
- Google Places API
- Yelp Fusion API
- OpenTable (where available)
- User's past restaurant history

### Step 2: Present Options

Display top 3-5 restaurant options with:

- Restaurant name and cuisine type
- Rating and review count
- Price range indicator
- Distance from location
- Key highlights (outdoor seating, private rooms, etc.)
- Estimated availability

### Step 3: User Approval

Before making any call, present:

```
🍽️ Ready to make a reservation

Restaurant: [Name]
Date: [Date] at [Time]
Party Size: [Number] people
Phone: [Restaurant Phone]

This will initiate an AI voice call to the restaurant.

[Approve Call] [Choose Different Restaurant] [Cancel]
```

**Risk Level: HIGH** - Always requires explicit approval

### Step 4: Configure Voice Agent

Prepare the AI voice agent with:

```typescript
interface ReservationCallConfig {
  restaurantName: string;
  restaurantPhone: string;
  reservationDetails: {
    date: string;
    time: string;
    partySize: number;
    name: string;
    specialRequests?: string;
  };
  voiceProfile: string;      // User's selected voice
  maxAttempts: number;       // Retry limit
  fallbackBehavior: 'voicemail' | 'callback' | 'abort';
}
```

### Step 5: Execute Call

The voice agent will:

1. Dial the restaurant
2. Introduce itself: "Hi, I'm calling to make a reservation..."
3. Provide reservation details
4. Handle questions and confirmations
5. Note any special information (parking, dress code)
6. Thank and hang up

**Live Monitoring:**
- Real-time transcript streamed to user
- User can listen to call audio
- Emergency abort option available

### Step 6: Analyze Outcome

Parse the call result:

```typescript
interface CallOutcome {
  status: 'confirmed' | 'waitlisted' | 'unavailable' | 'callback_required' | 'failed';
  confirmationNumber?: string;
  confirmedTime?: string;      // May differ from requested
  specialInstructions?: string;
  alternativeOffered?: {
    date?: string;
    time?: string;
  };
}
```

### Step 7: Calendar Integration

If reservation confirmed:

1. Create calendar event with:
   - Restaurant name and address
   - Confirmation number
   - Party size
   - Any special instructions
2. Set reminder (default: 2 hours before)
3. Include directions link

## Call Script Template

```
Agent: Hi, I'm calling to make a dinner reservation for [DATE].

Host: [Response]

Agent: I'd like to reserve a table for [PARTY_SIZE] people at [TIME].
       The reservation would be under the name [NAME].

Host: [Response - may ask questions]

Agent: [Handle questions about occasion, seating preference, etc.]

Host: [Confirmation or alternative]

Agent: Perfect, thank you! Could you confirm the reservation details?
       [Verify details]

Agent: Great, we'll see you then. Thank you!
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No answer | Retry up to 3 times, then offer alternatives |
| Fully booked | Present alternative times/dates offered |
| Voicemail | Leave message with callback number |
| Call failed | Notify user, suggest manual booking |
| Wrong number | Verify and retry with correct number |

## User Preferences Learned

- Favorite cuisines and restaurants
- Preferred reservation times
- Typical party sizes
- Seating preferences (indoor/outdoor/bar)
- Special occasion patterns

## Example Interaction

**User**: "Book us a nice Italian place for our anniversary next Saturday, party of 2"

**Assistant**:
```
I found some great Italian restaurants for your anniversary:

1. 🏆 Osteria Romana - $$$ - 4.8★
   Classic Roman cuisine, romantic atmosphere
   2.3 miles away

2. Bella Vista - $$$$ - 4.6★
   Fine dining, private tables available
   3.1 miles away

3. Trattoria Milano - $$ - 4.5★
   Cozy neighborhood spot, excellent pasta
   1.8 miles away

Which would you prefer? I can call to make the reservation.
```

**User**: "Let's go with Osteria Romana, 7:30pm"

**Assistant**:
```
🍽️ Ready to make a reservation

Restaurant: Osteria Romana
Date: Saturday, January 18th at 7:30 PM
Party Size: 2 people
Occasion: Anniversary

I'll call the restaurant now to secure your table.

[Approve Call] [Change Details] [Cancel]
```

## Safety Considerations

- Never share personal financial information during calls
- Verify restaurant phone numbers before calling
- Record calls only with proper disclosure
- Allow user to abort call at any time
- Don't leave detailed personal information on voicemails
