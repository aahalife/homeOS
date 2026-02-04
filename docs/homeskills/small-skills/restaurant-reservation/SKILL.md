---
name: restaurant-reservation
description: Find and book restaurant reservations. Use when user wants to book a table, make a dinner/lunch reservation, or find a restaurant for a date.
risk: MEDIUM (search/suggest) to HIGH (booking via phone)
---

# Restaurant Reservation Skill

## When to Use

User says anything about: booking a restaurant, making a reservation, table for X, dinner plans, lunch booking, celebrate at a restaurant.

## Step 1: Gather Requirements

Ask for anything missing from this list:
- **Date and time** (REQUIRED)
- **Party size** (REQUIRED)
- **Location/area** (REQUIRED)
- **Cuisine preference** (optional, ask if not given)
- **Occasion** (optional, ask if not given)
- **Budget** ($, $$, $$$, $$$$) (optional)

Template:
```
I'll help find a restaurant! A few details:
1. 📅 Date and time?
2. 👥 How many people?
3. 📍 What area?
4. 🍽️ Cuisine preference or occasion?
```

Check stored preferences first:
```bash
cat ~/clawd/homeos/memory/dining.json 2>/dev/null
cat ~/clawd/homeos/data/family.json 2>/dev/null
```

If family has dietary restrictions on file, mention them:
"I see [name] has [restriction] — I'll factor that in."

## Step 2: Search

Search the web for: `best [CUISINE] restaurants [LOCATION] [OCCASION]`

Also check OpenTable:
```
https://www.opentable.com/s?dateTime=[DATE]T[TIME]&covers=[SIZE]&term=[CUISINE]
```

Check saved favorites:
```bash
cat ~/clawd/homeos/memory/restaurants.json 2>/dev/null
```

## Step 3: Present Options

Show 3 options. For each option include:
- Name, price range ($-$$$$), rating
- Distance, cuisine type
- One highlight (why it fits)
- Phone number and website

Template:
```
🍽️ Options for [DATE]:

1. ⭐ [Name] — [$$] — [4.8]★
   📍 [Distance] | [Cuisine]
   ✨ [Highlight]
   📞 [Phone] | 🌐 [URL]

2. ...
3. ...

Which one?
```

Do NOT use tables. Use the bullet format above.

## Step 4: Assist Booking

Once user picks a restaurant:

**If online booking available (MEDIUM risk):**
```
Book here: [direct link]
Enter: [DATE], [TIME], [PARTY SIZE], [NAME]
Let me know once confirmed — I'll add it to your calendar.
```

**If phone booking required → HANDOFF to telephony:**
```
OUTPUT_HANDOFF:
  to: telephony
  reason: Restaurant requires phone reservation
  data:
    business_name: [restaurant]
    phone: [number]
    purpose: reservation
    date: [date]
    time: [time]
    party_size: [N]
    name: [reservation name]
    occasion: [if any]
    dietary: [if any]
    flexibility: [time flexibility]
```

**If user wants to call themselves, give script:**
```
📞 Call [NUMBER] and say:
"Hi, I'd like a reservation for [DATE] at [TIME] for [N] people under [NAME]."
Mention: [occasion], [dietary needs]
```

## Step 5: Confirm and Save

After booking is confirmed:

```
✅ Reservation confirmed!
🍽️ [Restaurant]
📅 [Date] at [Time]
👥 [Party size]
📍 [Address]
📝 Confirmation: [# if given]
```

Save to calendar:
```bash
echo '{"id":"res-'$(date +%s)'","title":"Dinner at RESTAURANT","date":"DATE","time":"TIME","location":"ADDR","notes":"Party of N, conf #X"}' >> ~/clawd/homeos/data/calendar.json
```

Save restaurant to memory:
```bash
echo '{"name":"RESTAURANT","cuisine":"TYPE","visited":"DATE","occasion":"OCC","rating":null}' >> ~/clawd/homeos/memory/restaurants.json
```

## Step 6: Follow-Up

Day before: remind user with address + map link.
Day after: "How was [restaurant]? Would you go back?"
Save their feedback to ~/clawd/homeos/memory/restaurants.json.

## Special Cases

**Fully booked:** Offer alternative times, dates, or similar restaurants.
**Large party (6+):** Warn that phone booking is likely required. Suggest private dining.
**Special occasion:** Note it in booking. Suggest mentioning it to the restaurant.
**Dietary restrictions:** Filter search results. Mention in booking notes.

## Defaults

- If no time given, suggest 7:00 PM
- If no budget given, assume $$-$$$
- Time flexibility default: ±30 minutes
- Reminder default: 2 hours before
