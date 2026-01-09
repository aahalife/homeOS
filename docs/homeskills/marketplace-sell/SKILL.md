---
name: marketplace-sell
description: Sell items on Facebook Marketplace, eBay, Craigslist, and other platforms with AI-powered listing assistance. Use when the user wants to sell something, list an item for sale, post on marketplace, or get rid of items. Includes photo analysis, pricing suggestions, and buyer communication guidance.
---

# Marketplace Sell Skill

Help users sell items on online marketplaces by creating optimized listings, suggesting prices, and providing safety guidance for transactions.

## When to Use

- User says "I want to sell..." or "help me sell..."
- User mentions "list on marketplace", "post for sale"
- User asks about selling items, getting rid of stuff
- User wants to declutter or make money from items

## Workflow Overview

```
1. Identify Item → 2. Assess Condition → 3. Research Price 
→ 4. Create Listing → 5. Post (with approval) → 6. Handle Buyers → 7. Complete Sale
```

## Step 1: Identify the Item

**Gather item details:**
```
I'll help you sell that! Let me get some details:

1. 📦 What are you selling? (Brand, model if applicable)
2. 📸 Can you send photos? (More angles = faster sale)
3. 📝 What condition is it in?
4. 🤔 Why are you selling? (Helps write compelling description)
```

**If user sends photos, analyze them:**
- Identify brand/model visible in photos
- Assess visible condition
- Note any damage or wear shown
- Suggest additional photos needed

**Photo guidance:**
```
For best results, please include photos of:
✅ Front/main view (in good lighting)
✅ Back and sides  
✅ Any labels, serial numbers, or brand markings
✅ Any defects, scratches, or wear (honesty sells!)
✅ Size reference if relevant (coin, hand, ruler)
✅ Item in use or with accessories included
```

## Step 2: Assess Condition

**Condition categories:**

| Condition | Description | Pricing Impact |
|-----------|-------------|----------------|
| **New/Sealed** | Never opened, tags attached | 80-90% of retail |
| **Like New** | Used once or twice, no wear | 60-75% of retail |
| **Good** | Normal wear, fully functional | 40-60% of retail |
| **Fair** | Visible wear, works fine | 25-40% of retail |
| **Poor** | Heavy wear or issues | 10-25% of retail |

**Ask clarifying questions:**
```
To price this right, a few questions:

1. How old is it? (Purchased when?)
2. How much was it used?
3. Does everything work properly?
4. Any scratches, dents, or cosmetic issues?
5. Do you have the original box/accessories?
```

## Step 3: Research Pricing

**Search sold listings for comparable items:**

```
Let me research what these are selling for...

Search these to compare:

💰 eBay Sold Listings:
https://www.ebay.com/sch/i.html?_nkw=[ITEM]&LH_Complete=1&LH_Sold=1

💰 Facebook Marketplace (your area):
https://www.facebook.com/marketplace/search/?query=[ITEM]

💰 Amazon (for new price reference):
https://www.amazon.com/s?k=[ITEM]
```

**Present pricing recommendation:**
```
💰 Pricing Analysis for [ITEM]

Research findings:
- New retail price: $[X]
- Recent eBay sold: $[Y] - $[Z] (average $[AVG])
- Local marketplace: $[A] - $[B]

My recommendation:
- ⚡ Quick sale price: $[LOW] (sells in 1-3 days)
- ✅ Fair price: $[MID] (sells in 1-2 weeks)
- 💪 Firm price: $[HIGH] (may take longer)

Which pricing strategy do you prefer?
```

**Price adjustment factors:**
- ➕ Original packaging/accessories: +10-20%
- ➕ Receipt/warranty: +5-10%
- ➖ Cosmetic damage: -10-30%
- ➖ Functional issues: -30-50%
- ➖ Missing accessories: -10-20%

## Step 4: Create the Listing

**Generate optimized listing:**

```
📝 Draft Listing

TITLE: [Brand] [Model] [Key Specs] - [Condition]
Example: "Apple iPhone 13 Pro 256GB Sierra Blue - Excellent Condition"

💲 PRICE: $[AMOUNT] (or Best Offer)

DESCRIPTION:
[Brand] [Model] in [condition] condition.

• [Key feature 1]
• [Key feature 2]
• [Key feature 3]

Condition notes:
[Honest description of any wear or issues]

Includes:
• [Item]
• [Accessory 1]
• [Accessory 2]

[Why selling - optional but builds trust]

Local pickup in [AREA]. Cash or [payment method].
Serious inquiries only.

---

How does this look? I can adjust the title, price, or description.
```

**Title best practices:**
- Lead with brand name
- Include model number/name
- Key specs (size, capacity, color)
- Condition indicator
- Stay under 80 characters

**Description tips:**
- Be honest about condition
- Highlight key features
- Mention what's included
- State pickup location (general area, not home address)
- Include payment preferences

## Step 5: Post the Listing

**⚠️ HIGH RISK - Requires Approval**

```
⚠️ APPROVAL REQUIRED

I've prepared your listing. To post it, you'll need to:

📱 Facebook Marketplace:
1. Open Facebook app → Marketplace → Sell
2. Upload your photos
3. Copy/paste this listing info:
   [TITLE]
   [PRICE]
   [DESCRIPTION]
4. Set your location
5. Publish!

💻 eBay:
1. Go to ebay.com/sell
2. List your item
3. Use these details as a guide

Would you like me to:
1. Copy the listing text for you to paste
2. Walk through the posting step-by-step
3. Adjust anything before you post
```

**Save listing for reference:**
```bash
cat >> ~/clawd/homeos/data/marketplace_listings.json << 'EOF'
{
  "id": "listing-TIMESTAMP",
  "item": "ITEM_NAME",
  "price": PRICE,
  "platform": "facebook",
  "status": "active",
  "created": "DATE",
  "views": 0,
  "inquiries": 0
}
EOF
```

## Step 6: Handle Buyer Messages

**Common messages and suggested responses:**

### "Is this still available?"
```
Suggested response:
"Yes, still available! When would you like to pick it up?"
```

### Price negotiation
```
Buyer offers $[LOWER_PRICE] (your asking: $[PRICE])

Options:
1. Accept: "Sounds good, when can you pick up?"
2. Counter: "I could do $[COUNTER]. Does that work?"
3. Hold firm: "Price is firm at $[PRICE], it's priced to sell."
4. Decline: "Thanks for the offer, but I'll pass."

My suggestion: [Based on how long listed, demand, etc.]
```

### Questions about the item
```
Buyer asks: "[QUESTION]"

Suggested response based on your item details:
"[HELPFUL_HONEST_ANSWER]"
```

## Step 7: Complete the Sale

### Meeting Safety Guidelines

```
🚨 Safety First!

✅ SAFE meeting locations:
- Police station parking lot (many have designated spots)
- Bank lobby during business hours
- Busy shopping center (well-lit, cameras)
- Coffee shop or fast food restaurant

❌ AVOID:
- Your home (first meeting)
- Isolated locations
- Nighttime meetings
- Going alone for high-value items
```

### Payment Safety

```
💵 Payment Tips:

✅ SAFE payment methods:
- Cash (count it in front of them)
- Venmo/PayPal (verify payment received before handing over)
- Facebook Pay (for Marketplace)

❌ NEVER accept:
- Checks (bounce risk)
- Money orders (easy to fake)
- Wire transfers
- "I'll pay extra for shipping" (classic scam)
- Zelle from unknown buyers (hard to dispute)
```

### Scam Detection

**Red flags to watch for:**

```
🚩 SCAM ALERT - Be careful if buyer:

⚠️ Offers MORE than asking price
⚠️ Wants to send a "mover" or "assistant"
⚠️ Asks you to ship before payment clears
⚠️ Sends "verification" links
⚠️ Asks for personal info (SSN, bank account)
⚠️ Only communicates via text (not platform messages)
⚠️ Story seems too complicated

When in doubt: Trust your gut. Block and move on.
```

### Completing the Transaction

```
🎉 Sale Complete Checklist:

☐ Met in safe location
☐ Verified payment received
☐ Buyer inspected item
☐ Both parties satisfied
☐ Mark listing as sold

Congrats on the sale! 💰
```

**Update listing status:**
```bash
# Mark as sold in records
jq '(.[] | select(.id == "listing-ID") | .status) = "sold" | .sold_date = "DATE" | .sold_price = PRICE' ~/clawd/homeos/data/marketplace_listings.json > /tmp/listings.json && mv /tmp/listings.json ~/clawd/homeos/data/marketplace_listings.json
```

## Listing Optimization Tips

**Best times to post:**
- Thursday-Sunday evening (most active)
- Avoid Monday mornings
- Renew listings on weekends

**If not selling:**
```
Your [ITEM] has been listed for [X days] with [Y views].

Suggestions to improve:
1. 💲 Lower price by 10-15%
2. 📸 Add more/better photos
3. 📝 Improve title keywords
4. 🔄 Renew/repost the listing
5. 📱 Cross-post to eBay/Craigslist

Want me to help with any of these?
```

## Example Interaction

**User:** "I want to sell my old MacBook Pro"

**Assistant:**
```
I'll help you sell your MacBook Pro! 💻

First, let me get some details:

1. What year/model is it? (Check  → About This Mac)
2. Specs: RAM, storage, processor?
3. Condition: Any issues, scratches, battery health?
4. Do you have the charger and original box?

And please send 4-6 photos:
- Lid closed, top view
- Open, screen on
- Keyboard close-up
- Bottom (for model info)
- Any wear or damage
```

**User:** "2021 14-inch, M1 Pro, 16GB/512GB. Excellent condition, 92% battery health. Have charger, no box."

**Assistant:**
```
💻 Great machine! Let me research pricing...

💰 Pricing Analysis: MacBook Pro 14" 2021 M1 Pro 16GB/512GB

Research:
- New price: $1,999
- eBay sold (excellent): $1,150 - $1,450
- FB Marketplace local: $1,100 - $1,350

Your advantages:
✅ Excellent condition
✅ Great battery health (92%)
✅ Includes charger

My recommendation:
- ⚡ Quick sale: $1,199 (sells fast)
- ✅ Fair price: $1,299 (1-2 weeks)
- 💪 Hold firm: $1,399 (patient approach)

Which strategy works for you?
```

**User:** "Let's go with $1,299"

**Assistant:**
```
Perfect! Here's your listing:

📝 LISTING DRAFT

TITLE:
MacBook Pro 14" 2021 M1 Pro 16GB/512GB - Excellent Condition

PRICE: $1,299 (or best offer)

DESCRIPTION:
Apple MacBook Pro 14-inch (2021) in excellent condition.

• Apple M1 Pro chip
• 16GB unified memory
• 512GB SSD storage
• Battery health: 92%
• Beautiful Liquid Retina XDR display

No scratches or dents. Screen is perfect. Keyboard and trackpad work flawlessly. 

Factory reset and ready for new owner.

Includes:
• MacBook Pro
• Original Apple charger

Upgrading to new machine - this one has been great.

Local pickup in [YOUR AREA]. Cash or Venmo.
Serious buyers only please.

---

Looks good? Ready to post on Facebook Marketplace?
```
