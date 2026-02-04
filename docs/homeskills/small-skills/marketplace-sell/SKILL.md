---
name: marketplace-sell
description: Help users sell items on Facebook Marketplace, eBay, Craigslist. Listing creation, pricing, buyer communication, scam detection.
risk: MEDIUM (research/draft) to HIGH (posting)
---

# Marketplace Sell Skill

## When to Use

User wants to: sell something, list an item, post on marketplace, get rid of stuff, know what something is worth, declutter for money.

## Step 1: Identify the Item

Ask for missing info:
```
I'll help you sell that! Details needed:
1. 📦 What is it? (brand, model if applicable)
2. 📸 Photos? (more = faster sale)
3. 📝 Condition?
4. 🤔 Why selling? (helps write description)
```

If user sends photos: identify brand/model, assess visible condition, note damage.

Photo checklist — ask for any missing:
- Front/main view in good lighting
- Back and sides
- Labels, serial numbers, brand markings
- Any defects or wear (honesty sells)
- Size reference if relevant

## Step 2: Assess Condition

Five levels:
- **New/Sealed** — never opened, tags on → 80-90% retail
- **Like New** — used 1-2 times, no wear → 60-75% retail
- **Good** — normal wear, fully functional → 40-60% retail
- **Fair** — visible wear, works fine → 25-40% retail
- **Poor** — heavy wear or issues → 10-25% retail

Adjustments:
- Original box/accessories: +10-20%
- Receipt/warranty: +5-10%
- Cosmetic damage: -10-30%
- Functional issues: -30-50%
- Missing accessories: -10-20%

## Step 3: Research Price

Search eBay sold listings:
```
https://www.ebay.com/sch/i.html?_nkw=[ITEM]&LH_Complete=1&LH_Sold=1
```

Present three price points:
```
💰 Pricing for [ITEM]:
- New retail: $[X]
- Recent sold: $[Y]-$[Z] (avg $[A])

Recommendation:
- ⚡ Quick sale: $[LOW] (1-3 days)
- ✅ Fair price: $[MID] (1-2 weeks)
- 💪 Firm price: $[HIGH] (may take longer)

Which strategy?
```

## Step 4: Create Listing

Draft template:
```
📝 LISTING DRAFT

TITLE: [Brand] [Model] [Key Specs] — [Condition]
(Under 80 chars. Lead with brand.)

PRICE: $[AMOUNT] (or Best Offer)

DESCRIPTION:
[Brand] [Model] in [condition] condition.

- [Feature 1]
- [Feature 2]
- [Feature 3]

Condition: [honest description of wear]

Includes:
- [Item]
- [Accessory 1]

[Why selling — builds trust]

Local pickup in [GENERAL AREA]. Cash or Venmo.
Serious inquiries only.
```

Rules for listings:
- Be honest about condition
- NEVER put exact home address — use general area
- State payment methods upfront
- No tables — use bullet lists

## Step 5: Post (HIGH RISK)

⚠️ Posting requires approval. Show the user the final listing and ask:

```
⚠️ APPROVAL REQUIRED
Ready to post this listing on [platform].
Review the draft above.
Reply YES to proceed or NO to edit.
```

Then guide them through posting (or post if automation available).

Save listing:
```bash
echo '{"id":"list-'$(date +%s)'","item":"NAME","price":X,"platform":"facebook","status":"active","created":"DATE"}' >> ~/clawd/homeos/data/marketplace_listings.json
```

## Step 6: Handle Buyers

Common responses:

**"Is this still available?"** → "Yes! When can you pick up?"

**Price negotiation:**
- If offer is ≥80% of asking → suggest accepting
- If offer is 60-80% → suggest countering at midpoint
- If offer is <60% → suggest declining politely
- If listed >7 days → suggest being more flexible

**Questions about item** → draft honest answer from item details.

## Step 7: Complete Sale — Safety

### SCAM DETECTION CHECKLIST

Before any meetup or accepting payment, check ALL of these. If ANY are true → WARN USER:

1. ☐ **Overpayment scam**: Buyer offers MORE than asking price
2. ☐ **Proxy scam**: Buyer wants to send a "mover", "assistant", or "friend" instead of coming themselves
3. ☐ **Ship-first scam**: Buyer asks you to ship BEFORE payment clears
4. ☐ **Phishing**: Buyer sends links to "verify" your identity, "confirm" the listing, or "accept payment"
5. ☐ **Off-platform**: Buyer insists on communicating only via text/email, not the marketplace messaging
6. ☐ **Info harvesting**: Buyer asks for SSN, bank account, or personal details beyond what's needed
7. ☐ **Fake payment screenshot**: Buyer shows a screenshot of payment instead of you verifying in your own app
8. ☐ **Cashier's check / money order**: Buyer wants to pay by check or money order (easily faked)
9. ☐ **Rush pressure**: Buyer creates urgency ("must have it TODAY", "leaving town tomorrow") to skip safety steps
10. ☐ **Too-complex story**: Buyer has an elaborate story about why they can't meet normally, pay normally, or communicate normally

If ANY box is checked:
```
🚩 SCAM WARNING
This buyer shows a scam pattern: [which one]
Recommendation: Do NOT proceed. Block and move on.
```

### Safe Meeting

```
✅ SAFE meeting spots:
- Police station parking lot
- Bank lobby (business hours)
- Busy shopping center (cameras, people)
- Coffee shop

❌ AVOID:
- Your home (first meeting)
- Isolated locations
- Nighttime meetings
- Going alone for high-value items ($200+)
```

### Safe Payment

```
✅ SAFE payment:
- Cash (count in person)
- Venmo/PayPal (verify received in YOUR app before handing over)
- Facebook Pay (for Marketplace)

❌ NEVER accept:
- Checks or money orders
- Wire transfers
- "I'll pay extra for shipping"
- Zelle from strangers
- Payment screenshots (verify in app)
```

### After Sale

Mark as sold:
```bash
# Update listing status
echo "$(date -Iseconds) | SOLD | [item] | $[price]" >> ~/clawd/homeos/logs/actions.log
```

## Listing Not Selling?

If listed >7 days with low interest:
```
Your [ITEM] has been listed [X] days.
Suggestions:
1. 💲 Lower price 10-15%
2. 📸 Better/more photos
3. 📝 Improve title keywords
4. 🔄 Repost the listing
5. 📱 Cross-post to another platform
```

## Defaults

- Default platform: Facebook Marketplace
- Default payment: Cash or Venmo
- Price strategy default: "fair price" (middle option)
- Best posting times: Thursday-Sunday evening
