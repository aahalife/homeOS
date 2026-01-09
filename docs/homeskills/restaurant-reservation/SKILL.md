---
name: restaurant-reservation
description: Make restaurant reservations by searching for options and helping coordinate bookings. Use when the user wants to book a table, make a dinner reservation, reserve a restaurant, or schedule dining at a specific venue. Handles the complete flow from search to confirmation.
---

# Restaurant Reservation Skill

Help users find and book restaurant reservations through search, recommendations, and booking assistance.

## When to Use

- User asks to "book a restaurant" or "make a reservation"
- User mentions "dinner reservation", "lunch booking", or "table for X"
- User wants to celebrate an occasion at a restaurant
- User needs to find and book a restaurant for a specific date/time

## Workflow Overview

```
1. Gather Requirements → 2. Search/Recommend → 3. Present Options 
→ 4. User Selects → 5. Assist with Booking → 6. Confirm & Calendar
```

## Step 1: Gather Requirements

**Essential information needed:**
- Date and time
- Party size
- Location/area
- Any preferences (cuisine, price range, occasion)

**Ask if not provided:**
```
I'd love to help you find a restaurant! Let me get a few details:

1. 📅 What date and time?
2. 👥 How many people?
3. 📍 What area/neighborhood?
4. 🍽️ Any cuisine preference or occasion?
```

**Check stored preferences:**
```bash
cat ~/clawd/homeos/memory/preferences/dining.json 2>/dev/null
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members[].preferences.dietary // empty'
```

**Remember dietary restrictions from family profiles:**
- Allergies
- Dietary restrictions (vegetarian, gluten-free, etc.)
- Preferences

## Step 2: Search for Restaurants

**Primary method - Web search:**

Use browser to search:
```
https://www.google.com/search?q=best+[CUISINE]+restaurants+[LOCATION]+[OCCASION]
```

Or search OpenTable:
```
https://www.opentable.com/s?dateTime=[DATE]T[TIME]&covers=[PARTY_SIZE]&metroId=[METRO]&term=[CUISINE]
```

**Alternative - Provide search guidance:**
```
I recommend checking these for [CUISINE] restaurants in [AREA]:

1. OpenTable: opentable.com/[area] - Easy online booking
2. Yelp: yelp.com/search?find_desc=[cuisine]&find_loc=[area]
3. Google Maps: Search "[cuisine] restaurant [area]"

Would you like me to search now, or do you have a place in mind?
```

**Check for previously enjoyed restaurants:**
```bash
cat ~/clawd/homeos/memory/preferences/restaurants.json 2>/dev/null
```

## Step 3: Present Options

Format restaurant options clearly:

```
🍽️ Restaurant Options for [DATE]

1. ⭐ [Restaurant Name] - [Price Range] - [Rating]★
   📍 [Distance] away | 🍽️ [Cuisine]
   ✨ [Key highlight - romantic, great views, etc.]
   📱 [Phone] | 🌐 [Website]

2. [Restaurant Name] - [Price Range] - [Rating]★
   📍 [Distance] away | 🍽️ [Cuisine]
   ✨ [Key highlight]
   📱 [Phone] | 🌐 [Website]

3. [Restaurant Name] - [Price Range] - [Rating]★
   📍 [Distance] away | 🍽️ [Cuisine]
   ✨ [Key highlight]
   📱 [Phone] | 🌐 [Website]

Which one interests you? I can help with the reservation.
```

**Include important details:**
- Price range ($, $$, $$$, $$$$)
- Rating and review count
- Distance from user's location
- Why it's a good fit for their occasion
- Contact info for booking

## Step 4: Booking Assistance

Once user selects a restaurant:

### Option A: Online Booking Available (Preferred)

Provide direct booking link:
```
Great choice! You can book directly here:

🔗 [OpenTable/Resy/Restaurant website booking link]

Details to enter:
- Date: [DATE]
- Time: [TIME]
- Party size: [NUMBER]
- Name: [User's name if known]

Let me know once you've booked and I'll add it to your calendar!
```

### Option B: Phone Booking Required

**Provide call script:**
```
📞 To book, call: [PHONE NUMBER]

Here's what to say:
"Hi, I'd like to make a reservation for [DATE] at [TIME] 
for [NUMBER] people, under the name [NAME]."

Mention if relevant:
- It's for [OCCASION - anniversary, birthday, etc.]
- [Any dietary requirements]
- [Seating preference - outdoor, quiet corner, etc.]

Let me know the confirmation details and I'll add it to your calendar!
```

### Option C: Offer to Draft Message

If restaurant accepts email/message bookings:
```
I can draft a reservation request for you to send:

---
Subject: Reservation Request - [DATE]

Hello,

I would like to make a reservation for:
- Date: [DATE]
- Time: [TIME]  
- Party size: [NUMBER] guests
- Name: [NAME]
- Occasion: [OCCASION]
- Special requests: [Any dietary needs, seating preferences]

Please confirm availability.

Thank you!
---

Would you like me to adjust anything before you send it?
```

## Step 5: Confirmation & Calendar

Once user confirms booking is made:

```
✅ Excellent! Let me save that.

Reservation Details:
🍽️ [Restaurant Name]
📅 [Date] at [Time]
👥 Party of [Number]
📍 [Address]
📝 Confirmation: [Number if provided]

I'll remind you [2 hours] before. Anything else you need?
```

**Save to calendar:**
```bash
cat >> ~/clawd/homeos/data/calendar.json << 'EOF'
{
  "id": "reservation-TIMESTAMP",
  "type": "restaurant",
  "title": "Dinner at RESTAURANT_NAME",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "duration": 120,
  "location": "ADDRESS",
  "notes": "Party of X, Confirmation #XXX",
  "reminders": ["2h", "1d"],
  "occasion": "OCCASION"
}
EOF
```

**Save restaurant preference:**
```bash
cat >> ~/clawd/homeos/memory/preferences/restaurants.json << 'EOF'
{
  "name": "RESTAURANT_NAME",
  "cuisine": "CUISINE",
  "visited": "DATE",
  "occasion": "OCCASION",
  "rating": null,
  "notes": ""
}
EOF
```

## Step 6: Follow-Up

**Day before reminder:**
```
🍽️ Reminder: Dinner tomorrow!

[Restaurant Name]
[Time] - Party of [X]
[Address]

🗺️ Directions: [Google Maps link]

Enjoy your [occasion]!
```

**After the dinner (next day):**
```
How was dinner at [Restaurant]? 

I'd love to remember your experience:
- Would you go back? (yes/no/maybe)
- Any notes for next time?
```

**Save feedback:**
```bash
# Update restaurant preference with rating
jq '.[] | select(.name == "RESTAURANT") | .rating = USER_RATING | .notes = "USER_NOTES"' ~/clawd/homeos/memory/preferences/restaurants.json
```

## Handling Special Situations

### Fully Booked
```
Unfortunately [Restaurant] appears fully booked for [DATE/TIME].

Options:
1. ⏰ Try a different time (they might have [earlier/later])
2. 📅 Try a different date
3. 🍽️ Check out [Similar Restaurant] instead
4. 📝 Add to waitlist (I'll remind you to check back)

What would you prefer?
```

### Large Party (6+)
```
For a party of [X], you'll likely need to:
1. Call ahead - large parties often can't book online
2. Book further in advance
3. Consider private dining options

Should I find restaurants with private dining rooms?
```

### Special Occasions
```
For your [anniversary/birthday/celebration], would you like me to:
1. 🎂 Note the occasion when booking (they may do something special)
2. 💐 Look for restaurants known for celebrations
3. 🍾 Order something special in advance (champagne, cake)
```

### Dietary Restrictions
```
I remember [Family Member] has [dietary restriction].

I'll look for restaurants that:
- Have [restriction]-friendly options
- Can accommodate allergies
- Have good reviews for dietary needs

Want me to include this in the search?
```

## Example Interaction

**User:** "Book us a nice Italian place for our anniversary next Saturday, party of 2"

**Assistant:**
```
Happy anniversary! 🎉 Let me find the perfect Italian spot.

A few questions:
1. What time works best? (I'd suggest 7-8pm for romantic ambiance)
2. Any neighborhood preference?
3. Price range - $$ (casual) to $$$$ (splurge)?
```

**User:** "7:30pm, downtown area, willing to splurge"

**Assistant:**
[Searches for upscale Italian restaurants downtown]

```
🍽️ Top Italian Restaurants for Your Anniversary

1. ⭐ Osteria Romana - $$$$ - 4.8★ (324 reviews)
   📍 0.5 mi from downtown | Est. 1985
   ✨ Romantic candlelit setting, housemade pasta
   📱 (555) 123-4567 | Reservations via OpenTable

2. La Pergola - $$$$ - 4.7★ (256 reviews)
   📍 0.8 mi from downtown | Rooftop terrace
   ✨ City views, sommelier on staff
   📱 (555) 234-5678 | Phone reservations only

3. Trattoria Toscana - $$$ - 4.6★ (412 reviews)
   📍 Downtown | Cozy atmosphere
   ✨ Best tiramisu in town, BYOB
   📱 (555) 345-6789 | Book on Resy

Which catches your eye? ❤️
```

**User:** "Osteria Romana sounds perfect"

**Assistant:**
```
Excellent choice! Osteria Romana is perfect for anniversaries.

🔗 Book here: opentable.com/osteria-romana

Details to enter:
- Saturday, [DATE]
- 7:30 PM
- 2 guests
- Special occasion: Anniversary ❤️

Tip: Mention it's your anniversary - they often do something special!

Once booked, share the confirmation and I'll add it to your calendar with a reminder.
```

## Voice AI Calling (Future Enhancement)

*Note: Direct phone calling via AI voice is not currently available. When this capability is added:*

1. Request explicit approval before any call
2. Provide real-time transcript
3. Allow user to listen/abort
4. Handle voicemail gracefully

For now, provide call scripts and assist with online booking instead.
