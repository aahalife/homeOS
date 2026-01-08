# Marketplace Sell Skill

List and sell items on Facebook Marketplace or eBay.

## Purpose

Take photos of an item, identify it, price it competitively, create a listing, and handle buyer communications.

## Prerequisites

- LLM API key with vision capabilities (Claude, GPT-4V)
- Facebook Marketplace API or eBay API credentials
- Composio integration for platform automation

## Input Parameters

```typescript
interface MarketplaceSellInput {
  workspaceId: string;
  userId: string;
  photos: string[];           // URLs or base64 encoded images
  userDescription?: string;   // Optional user-provided description
}
```

## Step-by-Step Instructions

### Step 1: Identify Item from Photos

**Risk Level: LOW**

Use vision LLM to analyze photos and identify the item.

```typescript
const identificationPrompt = `Analyze these product photos and identify:
{
  "name": "product name",
  "brand": "brand name or 'Unknown'",
  "model": "model number if visible",
  "condition": "new | like_new | good | fair | poor",
  "category": "electronics | furniture | clothing | toys | etc",
  "color": "primary color",
  "dimensions": { "length": null, "width": null, "height": null },
  "features": ["list", "of", "features"],
  "flaws": ["any", "visible", "damage"],
  "estimatedAge": "approximate age"
}`;

const itemInfo = await llm.vision({
  system: identificationPrompt,
  images: photos
});
```

### Step 2: Find Comparable Listings

**Risk Level: LOW**

Search for similar items to determine competitive pricing.

```typescript
const searchQuery = `${itemInfo.brand} ${itemInfo.name} ${itemInfo.condition}`;

// Search eBay completed listings
const ebayComps = await ebay.search({
  query: searchQuery,
  filter: 'sold_items',
  limit: 10
});

// Search Facebook Marketplace
const fbComps = await facebook.marketplace.search({
  query: searchQuery,
  location: userLocation,
  radius: 50
});

// Calculate suggested price
const prices = [...ebayComps, ...fbComps]
  .filter(item => item.sold)
  .map(item => item.price);

const suggestedPrice = {
  low: percentile(prices, 25),
  median: percentile(prices, 50),
  high: percentile(prices, 75)
};
```

### Step 3: Create Listing Draft

**Risk Level: MEDIUM**

Generate an optimized listing with title and description.

```typescript
const listingPrompt = `Create a compelling marketplace listing for this item:
${JSON.stringify(itemInfo)}

Comparable prices: $${suggestedPrice.low} - $${suggestedPrice.high}

Generate:
{
  "title": "attention-grabbing title under 80 chars",
  "description": "detailed description with bullet points",
  "price": suggested_price_number,
  "category": "marketplace category",
  "condition": "listing condition",
  "tags": ["relevant", "search", "tags"]
}

Tips for great listings:
- Lead with brand name and key feature
- Include dimensions and condition details
- Mention "pickup only" or "will ship"
- Use keywords buyers search for`;

const draft = await llm.complete({
  system: listingPrompt,
  user: JSON.stringify({ itemInfo, comparables: suggestedPrice })
});

// Emit draft for user review
await emit('marketplace.draft', {
  workspaceId,
  draft,
  photos,
  comparables: { ebayComps, fbComps }
});
```

### Step 4: Request Listing Approval

**Risk Level: HIGH - REQUIRES APPROVAL**

Get user approval before posting publicly.

```typescript
const approvalEnvelope = {
  intent: `Post "${draft.title}" for $${draft.price} on Facebook Marketplace`,
  toolName: 'marketplace.post_listing',
  inputs: {
    title: draft.title,
    description: draft.description,
    price: draft.price,
    photos: photos,
    category: draft.category
  },
  riskLevel: 'high',
  expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
};

const approved = await requestApproval(approvalEnvelope);
if (!approved) {
  return { success: false, reason: 'User did not approve listing' };
}
```

### Step 5: Post Listing

**Risk Level: HIGH**

Publish the listing to the marketplace.

```typescript
// Use Composio to automate Facebook Marketplace posting
const listing = await composio.execute('facebook_marketplace_create_listing', {
  title: draft.title,
  description: draft.description,
  price: draft.price,
  photos: photos,
  category: draft.category,
  condition: draft.condition,
  location: userLocation
});

await emit('marketplace.listed', {
  workspaceId,
  listingId: listing.id,
  url: listing.url
});
```

### Step 6: Handle Buyer Messages

**Risk Level: VARIES**

Monitor and respond to buyer inquiries.

```typescript
// Set up message monitoring
const messageLoop = async () => {
  while (listing.status === 'active') {
    const messages = await marketplace.getMessages(listing.id);

    for (const message of messages) {
      // Check for scam patterns
      const riskCheck = await checkMessageRisk(message);

      if (riskCheck.isScam) {
        await emit('marketplace.scam_detected', {
          buyerId: message.buyerId,
          reason: riskCheck.reason
        });
        continue;
      }

      // Determine appropriate response
      if (riskCheck.intent === 'price_negotiation') {
        // Auto-respond to lowball offers
        if (message.offeredPrice < draft.price * 0.7) {
          await sendResponse(message, "Thanks for your interest! My lowest price is $X.");
        } else {
          // Ask user approval for reasonable offers
          const offerApproved = await requestApproval({
            intent: `Accept offer of $${message.offeredPrice}`,
            riskLevel: 'medium'
          });
          // Handle response based on approval
        }
      }

      if (riskCheck.intent === 'purchase') {
        // Schedule pickup - requires address sharing approval
        await handlePurchaseIntent(message);
      }
    }

    await sleep(60000); // Check every minute
  }
};
```

### Step 7: Schedule Pickup (if purchase)

**Risk Level: HIGH - REQUIRES APPROVAL**

Coordinate safe meeting for item exchange.

```typescript
const handlePurchaseIntent = async (message) => {
  // Request approval to share address
  const addressApproval = await requestApproval({
    intent: 'Share pickup address with buyer',
    toolName: 'marketplace.message_buyer',
    inputs: { includeAddress: true },
    riskLevel: 'high',
    piiFields: ['address']
  });

  if (!addressApproval) {
    await sendResponse(message, "I'll get back to you with pickup details.");
    return;
  }

  // Suggest safe meeting times
  const availability = await calendar.getAvailability(userId, {
    startDate: new Date(),
    endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
  });

  const pickupOptions = availability
    .filter(slot => slot.available)
    .filter(slot => isDaytime(slot.start))  // Safety: daylight hours only
    .slice(0, 3);

  await sendResponse(message, formatPickupOptions(pickupOptions));
};
```

## Error Handling

| Error | Recovery |
|-------|----------|
| Photo analysis failed | Ask user for better photos |
| No comparables found | Use category average pricing |
| Listing post failed | Retry, check for policy violations |
| Scam message detected | Ignore and flag |
| API rate limited | Queue and retry later |

## Output

```typescript
interface MarketplaceSellOutput {
  success: boolean;
  listingId?: string;
  listingUrl?: string;
  soldPrice?: number;
}
```

## Scam Detection Patterns

The following patterns indicate potential scams:

- Offers to pay more than asking price
- Requests to communicate off-platform
- Shipping to different address than buyer
- Zelle/wire transfer requests
- "Is this still available?" followed by scam link
- Requests for personal information early
- Urgency tactics ("need it today!")

## Safety Guidelines

1. **Public meeting places** - Suggest police station or busy store parking lot
2. **Daylight hours only** - No evening or night pickups
3. **Bring someone** - Recommend seller brings a friend
4. **Cash only** - Avoid payment apps for in-person sales
5. **Trust your gut** - Cancel if anything feels off
