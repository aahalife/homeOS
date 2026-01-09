---
name: marketplace-sell
description: Sell items on Facebook Marketplace and eBay with AI-powered listing creation. Use when the user wants to sell something, list an item for sale, post on marketplace, or get rid of items. Includes photo analysis, pricing suggestions, and buyer communication.
---

# Marketplace Sell Skill

Help users sell items on online marketplaces by creating optimized listings, suggesting prices, and managing buyer communications safely.

## When to Use

- User says "I want to sell..." or "help me sell..."
- User mentions "list on marketplace", "post for sale"
- User asks about selling items, getting rid of stuff
- User wants to declutter or make money from items

## Prerequisites

- Facebook account connected (via Composio OAuth)
- eBay account connected (optional, for broader reach)
- Camera/photo access for item pictures
- User approval for posting (HIGH risk action)

## Workflow Steps

### Step 1: Item Identification

Analyze photos using vision AI:

```typescript
interface ItemAnalysis {
  category: string;           // Electronics, Furniture, Clothing, etc.
  title: string;              // Suggested listing title
  brand?: string;             // Detected brand
  model?: string;             // Detected model
  condition: 'new' | 'like_new' | 'good' | 'fair' | 'poor';
  description: string;        // Generated description
  suggestedPrice: {
    low: number;
    recommended: number;
    high: number;
  };
  keywords: string[];         // SEO keywords
}
```

**Photo Guidelines Provided to User:**
- Take photos in good lighting
- Include multiple angles
- Show any defects or wear
- Include size reference if relevant
- Capture brand/model labels

### Step 2: Price Research

Research market prices using:

- Recent sold listings on eBay
- Current Facebook Marketplace listings
- Amazon pricing (for new comparison)
- Condition-based depreciation

```typescript
interface PriceResearch {
  averageSoldPrice: number;
  priceRange: { min: number; max: number };
  daysToSell: number;         // Average time to sell
  demandLevel: 'high' | 'medium' | 'low';
  bestTimeToPost: string;     // Day/time recommendation
}
```

### Step 3: Create Listing

Generate optimized listing:

```typescript
interface MarketplaceListing {
  title: string;              // Max 80 chars, keyword-rich
  description: string;        // Detailed, honest, formatted
  price: number;
  category: string;
  condition: string;
  location: string;           // Pickup location (not home address)
  shippingOption: 'local_pickup' | 'shipping' | 'both';
  photos: string[];           // Ordered for best presentation
  tags: string[];
}
```

**Title Best Practices:**
- Lead with brand and model
- Include key specs (size, color, capacity)
- Add condition indicator
- Example: "Apple iPhone 13 Pro 256GB - Excellent Condition"

### Step 4: User Review & Approval

Present listing preview:

```
📦 Ready to List Your Item

Title: [Generated Title]
Price: $[Amount] (Market range: $X - $Y)
Platform: Facebook Marketplace

Description:
[Generated Description]

Photos: [Thumbnails]

This will post publicly on Facebook Marketplace.

[Post Listing] [Edit Details] [Cancel]
```

**Risk Level: HIGH** - Always requires approval before posting

### Step 5: Post & Monitor

After posting:
- Confirm successful listing
- Provide direct link to listing
- Set up notification monitoring for:
  - New messages from buyers
  - Price inquiries
  - Offers received

### Step 6: Buyer Communication

Handle buyer messages with AI assistance:

```typescript
interface BuyerMessage {
  buyerId: string;
  message: string;
  timestamp: Date;
  suggestedResponse: string;
  riskIndicators: string[];   // Scam signals
}
```

**Auto-Response Templates:**
- "Is this still available?" → "Yes, it's available! When would you like to pick it up?"
- Price negotiation → Suggest counter-offer within range
- Questions → Provide relevant details from listing

### Step 7: Safe Transaction

Guide safe meetup/transaction:

- Suggest public meeting locations
- Recommend daylight hours
- Advise cash or verified payment methods
- Provide safety checklist

## Scam Detection

Watch for red flags:

| Red Flag | Action |
|----------|--------|
| Offering more than asking price | Warning: Likely scam |
| Asking to ship before payment | Block, don't respond |
| Requesting personal info (SSN, bank) | Report buyer |
| Sending "verification" links | Warning: Phishing |
| Check/money order payment | Decline, request cash |
| Asking to communicate off-platform | Caution user |

```typescript
interface ScamRiskAssessment {
  riskLevel: 'low' | 'medium' | 'high';
  indicators: string[];
  recommendation: string;
  shouldBlock: boolean;
}
```

## Safety Guidelines

### Meeting Locations
- Police station parking lots
- Bank lobbies
- Busy shopping centers
- Coffee shops
- Never at home for first meeting

### Payment
- Cash preferred for local sales
- Venmo/PayPal for shipped items
- Never accept checks
- Verify payment before releasing item
- Count cash in front of buyer

### Personal Information
- Use first name only
- Don't share home address
- Use marketplace messaging only
- Don't share phone number initially

## Example Interaction

**User**: "I want to sell my old MacBook Pro"

**Assistant**:
```
I'd be happy to help you sell your MacBook Pro!

To create the best listing, please:
1. 📸 Take 4-6 photos (front, back, screen on, keyboard, any wear)
2. Tell me the model year and specs if you know them
3. Note any issues (battery health, scratches, etc.)

Once I have the photos, I'll research current prices and create an optimized listing for you.
```

**User**: [Sends photos]

**Assistant**:
```
Great photos! I've identified your MacBook:

📱 MacBook Pro 14" (2021)
   • Apple M1 Pro chip
   • 16GB RAM, 512GB SSD
   • Condition: Excellent (minor wear on bottom)

💰 Price Analysis:
   • Recent sales: $1,150 - $1,450
   • Recommended price: $1,299
   • Quick sale price: $1,199

📝 Draft Listing:

"MacBook Pro 14" 2021 M1 Pro 16GB/512GB - Excellent"

Powerful M1 Pro MacBook Pro in excellent condition.
Includes original charger. Battery health at 92%.
Minor cosmetic wear on bottom (see photos).
Factory reset, ready for new owner.

Would you like me to post this on Facebook Marketplace?
```

## Listing Optimization Tips

- Post on Thursday-Sunday for best visibility
- Respond to inquiries within 1 hour
- Renew listing every 7 days
- Drop price 10% if no interest after 2 weeks
- Cross-post to eBay for broader reach
