---
name: tools
description: Core utility tools including calendar management, grocery ordering, web content fetching, weather checks, reminders, notes, and general planning. Use when the user needs calendar access, wants to create reminders, check weather, search the web, add groceries to cart, or use any utility function.
---

# Tools Skill

Core utility functions that power many other skills - calendar, groceries, weather, reminders, notes, and more.

## When to Use

- User asks about calendar or scheduling
- User wants to set a reminder
- User needs weather information
- User wants to order groceries
- User needs to search for information
- User wants to take notes or retrieve notes
- User needs planning assistance

## Available Tools

| Tool | Risk Level | Use For |
|------|------------|----------|
| calendar.view | LOW | View events |
| calendar.create | MEDIUM | Add events |
| calendar.update | MEDIUM | Modify events |
| calendar.delete | HIGH | Remove events |
| groceries.search | LOW | Find products |
| groceries.add | MEDIUM | Add to cart |
| groceries.checkout | HIGH | Place order |
| weather | LOW | Get forecast |
| reminder.set | LOW | Create reminders |
| notes.create | LOW | Save notes |
| notes.search | LOW | Find notes |
| search | LOW | Web search |
| planning.breakdown | LOW | Task planning |

## Calendar Tools

### View Calendar

**Request format:**
```
📅 CALENDAR

Show me: [Today / This Week / Specific Date / Date Range]
```

**Response format:**
```
📅 YOUR CALENDAR - [Date Range]

━━━ TODAY - [Day, Date] ━━━
09:00  💼 Team meeting (1 hour)
       📍 Zoom - [link]

12:00  🍽 Lunch with Sarah
       📍 Cafe Milano

15:00  👶 Pediatrician - Emma
       📍 123 Medical Dr

━━━ TOMORROW - [Day, Date] ━━━
10:00  📞 Call with client

[No events for rest of day]

💡 3 events today, 1 tomorrow
```

### Create Event

**⚠️ MEDIUM RISK - Confirm before creating:**
```
📅 ADD EVENT

Title: [Event Name]
When: [Date] at [Time]
Duration: [Length]
Location: [Where]
Attendees: [People]
Reminders: [When to remind]

Add this to your calendar?
```

**After confirmation:**
```
✅ EVENT ADDED

📅 [Event Title]
📆 [Date] at [Time]
📍 [Location]
⏰ Reminders: 30 min before, 1 day before

🔗 Calendar link: [link]
```

### Find Free Time

**Request:**
```
When am I free [this week / on Date]?
```

**Response:**
```
📅 FREE TIME - [Date/Range]

━━━ [Day] ━━━
✅ 9:00 AM - 10:00 AM (1 hour)
❌ 10:00 AM - 12:00 PM (Team meeting)
✅ 12:00 PM - 2:00 PM (2 hours)
❌ 2:00 PM - 3:00 PM (Client call)
✅ 3:00 PM - 5:00 PM (2 hours) ⭐ Best slot!

Suggested slot for a 1-hour meeting: 3:00 PM - 4:00 PM

Want me to schedule something?
```

## Grocery Tools

### Search Products

**Request:**
```
Find [product] at [store / any store]
```

**Response:**
```
🛒 GROCERY SEARCH: [Query]

Store: [Store Name]

1. [Product Name] - [Brand]
   💰 $[Price] | [Size]
   ✅ In stock

2. [Product Name] - [Brand]
   💰 $[Price] | [Size]
   ✅ In stock

3. [Product Name] - [Brand]
   💰 $[Price] | [Size]
   ❌ Out of stock

Add any to your cart?
```

### Add to Cart

**⚠️ MEDIUM RISK - Confirm items:**
```
🛒 ADD TO CART

Adding to [Store] cart:

• [Product 1] x [Qty] - $[Price]
• [Product 2] x [Qty] - $[Price]

Subtotal: $[Amount]

Confirm?
```

### View Cart

```
🛒 YOUR CART - [Store]

Items:
• [Product 1] x [Qty] - $[Price]
• [Product 2] x [Qty] - $[Price]
• [Product 3] x [Qty] - $[Price]

────────────────────
Subtotal: $[Amount]
Delivery: $[Fee]
Service: $[Fee]
────────────────────
Total: $[Amount]

Ready to checkout?
```

### Checkout

**⚠️ HIGH RISK - Explicit approval required:**
```
⚠️ GROCERY ORDER APPROVAL

You're about to place an order:

🛒 [Store Name]
📍 Delivery to: [Address]
📅 Delivery: [Time Window]
💳 Payment: [Method ending in XXXX]

• [X] items
• Total: $[Amount]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type "ORDER" to confirm and charge your card.
Type "CANCEL" to abort.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Weather Tool

**Request:**
```
What's the weather [today / tomorrow / this week]?
Weather in [location]?
```

**Response:**
```
🌤️ WEATHER - [Location]

Now: [Temp]°F - [Conditions]
Feels like: [Temp]°F
Humidity: [X]%
Wind: [X] mph

📅 FORECAST:
• Today: High [X]° / Low [X]° - [Conditions]
• Tomorrow: High [X]° / Low [X]° - [Conditions]
• [Day 3]: High [X]° / Low [X]° - [Conditions]

💡 [Context-aware tip, e.g., "Bring an umbrella!"]
```

## Reminder Tool

### Set Reminder

**Request:**
```
Remind me to [task] at/in [time]
```

**Response:**
```
⏰ REMINDER SET

Reminder: [Task]
When: [Date and Time]

🔔 I'll notify you at that time.

Need to adjust or add more reminders?
```

**Save reminder:**
```bash
cat >> ~/clawd/homeos/tasks/active/reminder-$(date +%s).json << 'EOF'
{
  "type": "reminder",
  "message": "TASK",
  "trigger_time": "TIMESTAMP",
  "recurring": null,
  "status": "pending"
}
EOF
```

### List Reminders

```
⏰ YOUR REMINDERS

Upcoming:
• Today 3:00 PM - Call dentist
• Tomorrow 9:00 AM - Submit report
• Friday 5:00 PM - Pick up dry cleaning

Recurring:
• Every Monday 8:00 AM - Team standup
• Every 1st of month - Pay rent

Want to add, edit, or delete any?
```

## Notes Tool

### Create Note

**Request:**
```
Note: [content]
Remember: [content]
Save this: [content]
```

**Response:**
```
📝 NOTE SAVED

"[Note content]"

Tags: [auto-detected tags]
Saved: [timestamp]

I'll remember this for you.
```

### Search Notes

**Request:**
```
Find my note about [topic]
What did I save about [topic]?
```

**Response:**
```
📝 FOUND NOTES: "[query]"

1. [Date] - "[Note excerpt...]"
   Tags: [tags]

2. [Date] - "[Note excerpt...]"
   Tags: [tags]

Want to see the full note?
```

## Search Tool

**Request:**
```
Search for [query]
Look up [query]
```

**Response:**
```
🔍 SEARCH: "[query]"

1. [Title]
   [URL]
   [Snippet...]

2. [Title]
   [URL]
   [Snippet...]

3. [Title]
   [URL]
   [Snippet...]

Want me to summarize any of these?
```

## Planning Tool

### Task Breakdown

**Request:**
```
Help me plan: [goal]
Break down: [task]
```

**Response:**
```
📝 PLAN: [Goal]

━━━ STEPS ━━━

1. [Step 1]
   └─ Est. time: [duration]
   └─ Details: [specifics]

2. [Step 2]
   └─ Est. time: [duration]
   └─ Details: [specifics]

3. [Step 3]
   └─ Est. time: [duration]
   └─ Details: [specifics]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total estimated time: [duration]

💡 Tips:
• [Helpful tip 1]
• [Helpful tip 2]

Want me to schedule these or set reminders?
```

## Time Utilities

**Current time:**
```
🕐 CURRENT TIME

[Time] [AM/PM] - [Timezone]
[Day], [Date]

Timezones:
• EST: [time]
• PST: [time]
• UTC: [time]
```

**Time conversion:**
```
🕐 TIME CONVERSION

[Time] [From Timezone]
↓
[Time] [To Timezone]
```

## Error Handling

**When tool not configured:**
```
⚠️ TOOL NOT CONFIGURED

[Tool name] isn't set up yet.

To use this, you'll need to:
1. [Setup step 1]
2. [Setup step 2]

Alternative:
• [Manual workaround]
```

**When tool fails:**
```
❌ TOOL ERROR

[Tool name] encountered an issue:
[Error description]

Options:
1. Try again
2. Use alternative method
3. Skip for now

What would you like to do?
```

## Example Interactions

**User:** "What's on my calendar tomorrow?"

**Assistant:**
```
📅 TOMORROW - Thursday, January 18

09:00  💼 Team standup (30 min)
       📍 Zoom

11:00  📞 Client call - Acme Corp (1 hour)
       📍 Phone

14:00  👶 Emma - Dentist appointment
       📍 Smile Dental, 123 Main St

18:00  🎹 Jack - Piano lesson
       📍 Music Academy

4 events tomorrow.

💡 Note: You'll need to coordinate pickup for Emma's
dentist with Jack's piano lesson - they overlap by 30 min.

Need help with that?
```

**User:** "Add milk and eggs to my grocery list"

**Assistant:**
```
🛒 ADDING TO CART - Instacart

Searching for products...

Found:
• Organic Whole Milk (1 gal) - $5.99 ✅
• Large Eggs (dozen) - $4.49 ✅

Add these to your cart?
```

**User:** "Yes"

**Assistant:**
```
✅ ADDED TO CART

• Organic Whole Milk (1 gal) - $5.99
• Large Eggs (dozen) - $4.49

Cart total: $10.48 (+ delivery)

Continue shopping or checkout?
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   ├── calendar.json          # Calendar events
│   ├── grocery_cart.json      # Current cart
│   └── grocery_lists.json     # Saved lists
├── memory/
│   └── notes/                 # Saved notes
├── tasks/
│   └── active/
│       └── reminder-*.json    # Active reminders
└── logs/
    └── tools.log              # Tool usage log
```

## Integration Points

- **All Skills**: Calendar and reminders used everywhere
- **Meal Planning**: Grocery tools
- **Family Comms**: Calendar for family events
- **Healthcare**: Reminders for medications
