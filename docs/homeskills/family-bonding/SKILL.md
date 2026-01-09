---
name: family-bonding
description: Plan family activities, outings, and quality time experiences. Use when the user wants ideas for family activities, date nights, weekend plans, kids activities, family outings, or wants to find local events. Considers ages, interests, weather, and budget.
---

# Family Bonding Skill

Suggest and plan meaningful family activities, outings, and experiences that bring family members closer together.

## When to Use

- User asks "what should we do this weekend?"
- User wants "family activity ideas" or "things to do"
- User is planning a "family outing" or "day trip"
- User needs "date night ideas" for parents
- User asks about local events for kids/family
- User wants indoor/outdoor activity suggestions

## Step 1: Understand the Context

**Check family info:**
```bash
cat ~/clawd/homeos/data/family.json 2>/dev/null | jq '.members[] | {name, age, interests: .preferences.activities}'
```

**Check weather:**
```bash
curl -s "wttr.in/?format=%C+%t" 2>/dev/null
```

**Gather activity requirements:**
```
🎨 Let's find something fun! Quick questions:

1. 👥 Who's participating? (ages help a lot)
2. 📅 When? (today, this weekend, specific date)
3. ⏰ How much time? (few hours, half day, full day)
4. 🏘️ Indoor or outdoor? (or either?)
5. 💰 Budget? (free, $, $$, $$$)
6. 🌟 Any themes? (active, creative, educational, relaxed)
```

## Step 2: Generate Activity Ideas

**Format activity suggestions:**
```
🌟 ACTIVITY IDEAS for [Context]

Based on: [Family composition, weather, preferences]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏠 AT HOME:

1. [Activity Name]
   ⏱️ [Duration] | 💰 [Cost: Free/$/$$/] 
   👶 Best for ages: [range]
   📝 [Brief description and why it's fun]

2. [Activity Name]
   ⏱️ [Duration] | 💰 [Cost]
   👶 Best for ages: [range]
   📝 [Description]

🚗 OUT & ABOUT:

3. [Activity/Venue Name]
   ⏱️ [Duration] | 💰 [Cost] | 📍 [Distance]
   👶 Best for ages: [range]
   📝 [Description]
   🔗 [Website if applicable]

4. [Activity/Venue Name]
   ⏱️ [Duration] | 💰 [Cost] | 📍 [Distance]
   👶 Best for ages: [range]
   📝 [Description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Which sounds fun? I can help plan the details!
```

## Activity Ideas Library

### By Age Group

**Toddlers (1-3):**
- Sensory bins (rice, water, play dough)
- Bubble play
- Dance party
- Playground visits
- Petting zoo
- Library story time
- Splash pad
- Nature walks with wagon

**Preschool (3-5):**
- Craft projects (simple painting, collage)
- Baking cookies together
- Scavenger hunts
- Children's museums
- Swimming lessons
- Building forts
- Bug hunting
- Puppet shows

**School Age (6-10):**
- Board game tournaments
- Science experiments
- Bike rides
- Geocaching
- Cooking together
- Mini golf
- Bowling
- Movie marathons
- Camping (backyard counts!)

**Tweens (11-13):**
- Escape rooms
- Laser tag
- Rock climbing
- Cooking competitions
- DIY projects
- Video game tournaments
- Volunteer activities
- Learning new skills together

**All Ages:**
- Family game night
- Picnics
- Stargazing
- Photo walks
- Karaoke night
- Puzzle nights
- Family movie night
- Cooking/baking together

### By Weather

**Rainy Day / Indoor:**
```
☔ RAINY DAY IDEAS

🏠 At Home:
• Fort building + movie marathon
• Board game tournament
• Baking project (cookies, pizza from scratch)
• Indoor scavenger hunt
• Arts & crafts station
• Dance party / Just Dance video game
• Science experiments
• Puzzle challenge

🚗 Out:
• Children's museum
• Indoor playground
• Bowling alley
• Trampoline park
• Library visit
• Movie theater
• Aquarium
• Indoor mini golf
```

**Nice Weather / Outdoor:**
```
☀️ OUTDOOR IDEAS

🌳 Free/Cheap:
• Park + picnic
• Nature hike
• Beach or lake day
• Bike ride
• Playground hopping
• Backyard camping
• Stargazing
• Kite flying

🎫 Activities:
• Zoo or wildlife park
• Botanical gardens
• Mini golf
• Batting cages
• Farmers market
• Pick-your-own farm
• Outdoor concert
• Sports event
```

### By Budget

**Free:**
- Parks and playgrounds
- Library events
- Hiking trails
- Beach/lake (public)
- Free museum days
- Community events
- Backyard activities
- Nature walks

**Budget-Friendly ($0-25):**
- Bowling (especially with deals)
- Dollar store craft supplies
- Baking at home
- Matinee movies
- Picnic at the park
- Dollar theater
- City events

**Mid-Range ($25-75):**
- Mini golf + ice cream
- Trampoline parks
- Children's museums
- Movie + popcorn
- Bowling + pizza
- Skating rink

**Splurge ($75+):**
- Theme parks
- Escape rooms (family)
- Professional sports game
- Special shows/concerts
- Day trips
- Resort day passes

## Date Night Ideas (Parents)

```
💑 DATE NIGHT IDEAS

🌙 Classic Evening Out:
• Dinner + movie
• Nice restaurant + walk
• Concert or show
• Comedy club
• Wine tasting

🎯 Active Dates:
• Bowling
• Mini golf
• Escape room (just you two!)
• Cooking class
• Dance lesson
• Rock climbing gym

🌟 Unique Dates:
• Food tour
• Trivia night at a bar
• Arcade bar
• Paint & sip class
• Drive-in movie
• Karaoke

🏠 At-Home Date (after kids asleep):
• Cook a fancy meal together
• Movie + special snacks
• Game night for two
• Backyard fire pit
• Spa night at home

💰 Budget:
• $ = $30-50 total
• $$ = $50-100
• $$$ = $100-200

Need a sitter? I can help with that too! (see hire-helper skill)
```

## Seasonal Activity Ideas

### Spring
- Plant a garden together
- Fly kites
- Visit farmers market
- Bike rides as weather warms
- Spring cleaning as a team (with rewards!)
- Cherry blossom viewing
- Baseball games begin

### Summer
- Pool/beach days
- Backyard camping
- Ice cream making
- Water balloon fights
- Outdoor movie nights
- Catch fireflies
- Road trip day adventures
- Late bedtime stargazing

### Fall
- Apple picking
- Pumpkin patch
- Leaf pile jumping
- Halloween activities
- Football games
- Hot cider & donuts
- Fall crafts (leaf art)
- Hayrides

### Winter
- Snow activities (sledding, snowman)
- Holiday baking marathon
- Indoor fort building
- Hot cocoa bar
- Holiday light tours
- Ice skating
- Game marathon days
- Movie marathon (holiday films)

## Planning an Activity

**When user picks an activity:**
```
🎯 PLANNING: [Activity]

📅 When: [Date/time]
📍 Where: [Location if applicable]
💰 Cost: [Estimated total]

📝 PREP LIST:
☐ [Item/task 1]
☐ [Item/task 2]
☐ [Item/task 3]

⏰ TIMELINE:
• [Time]: [Step 1]
• [Time]: [Step 2]
• [Time]: [Step 3]

💡 TIPS:
• [Helpful tip 1]
• [Helpful tip 2]

🌧️ BACKUP PLAN:
If weather changes: [Alternative]

Want me to add this to your calendar?
```

**Save to calendar:**
```bash
cat >> ~/clawd/homeos/data/calendar.json << 'EOF'
{
  "type": "activity",
  "title": "ACTIVITY_NAME",
  "date": "DATE",
  "time": "TIME",
  "duration": MINUTES,
  "location": "LOCATION",
  "notes": "PREP_NOTES",
  "participants": ["family"]
}
EOF
```

## Finding Local Events

**Event search guidance:**
```
📅 FINDING LOCAL EVENTS

Search these for [Your Area]:

1. Facebook Events
   facebook.com/events/
   Filter: This weekend, family-friendly

2. Eventbrite
   eventbrite.com
   Search: "kids" or "family" + [your city]

3. Local Parent Blogs/Sites
   • [City]momsblog.com
   • [Local] Kids Calendar
   • Red Tricycle

4. Local Library
   Check website for free events
   Story time, craft activities, performances

5. Parks & Recreation
   City website → Parks dept
   Free and low-cost programs

6. Local Museums
   Many have free days or family programs

What type of event interests you?
```

## Example Interactions

**User:** "What should we do this rainy Saturday?"

**Assistant:**
```
☔ Rainy Saturday Fun!

Quick check - who's participating and ages?
(I can tailor ideas better!)

Meanwhile, here are some winners:

🏠 AT HOME:

1. Epic Fort + Movie Marathon
   ⏱️ All day | 💰 Free
   Build the ultimate blanket fort, make popcorn,
   watch 2-3 favorite movies. Classic!

2. Family Bake-Off
   ⏱️ 2-3 hours | 💰 $ (ingredients)
   Everyone decorates their own cupcakes
   or cookies. Judge and award prizes!

3. Indoor Scavenger Hunt
   ⏱️ 1 hour | 💰 Free
   I can generate clues for your house!

🚗 WORTH GOING OUT:

4. Trampoline Park
   ⏱️ 2 hours | 💰 $$ ($15-25/person)
   Burn off energy, fun for all ages

5. Bowling
   ⏱️ 2 hours | 💰 $$ ($40-60 family)
   Bumpers for little ones, pizza after!

What sounds fun? I can help plan whichever you pick!
```

**User:** "Let's do the bake-off! Kids are 5 and 8."

**Assistant:**
```
🧁 FAMILY BAKE-OFF - Let's Plan!

Perfect ages for this! Here's the plan:

📝 WHAT YOU'LL NEED:

Option A - Cupcake Decorating:
☐ Cupcakes (bake or buy 12-18)
☐ Frosting (2-3 colors/flavors)
☐ Sprinkles, candies, toppings
☐ Piping bags (or zip-lock bags work!)

Option B - Cookie Decorating:
☐ Sugar cookies (slice-and-bake is easy)
☐ Royal icing or frosting
☐ Food coloring
☐ Sprinkles and decorations

⏰ SUGGESTED TIMELINE:
• 2:00 - Set up stations (one per person)
• 2:15 - Explain rules, set timer (30-45 min)
• 2:15-3:00 - DECORATE!
• 3:00 - Judging time (everyone votes)
• 3:15 - Awards + taste testing 🎉

🏆 FUN CATEGORIES TO JUDGE:
• Most Creative
• Most Colorful
• Best Theme
• Yummiest Looking
• Best Effort (so everyone wins something!)

💡 TIPS:
• Cover the table with a plastic tablecloth (easy cleanup)
• Put each person's name on their plate
• Take photos before eating!
• Have wet wipes ready

Need me to add a grocery list or set a reminder?
```

**User:** "We need a date night idea for Friday. Haven't been out in forever!"

**Assistant:**
```
💑 Date Night! Let's get you two out.

Quick questions:
1. 💰 Budget for the evening?
2. 🍽️ Dinner included or just activity?
3. 🎯 Vibe: Relaxed, adventurous, romantic, fun?
4. ⏰ How long can you be out?

Meanwhile, some popular combos:

🌟 CLASSIC ROMANCE:
Nice dinner + after-dinner drinks
💰 $$-$$$ | ⏰ 3-4 hours

🎯 ACTIVE & FUN:
Bowling or mini golf + casual dinner
💰 $$ | ⏰ 3 hours

✨ UNIQUE EXPERIENCE:
Cooking class or paint & sip
💰 $$-$$$ | ⏰ 2-3 hours

🍿 EASY & RELAXED:
Dinner + movie (skip the blockbuster, try indie)
💰 $$ | ⏰ 4 hours

Do you have childcare lined up, or need help finding a sitter?
```

## Save Activity Preferences

**Track what the family enjoyed:**
```bash
cat >> ~/clawd/homeos/memory/preferences/activities.json << 'EOF'
{
  "activity": "ACTIVITY_NAME",
  "date": "DATE",
  "participants": ["who went"],
  "rating": 5,
  "notes": "Kids loved it / would do again",
  "cost": AMOUNT
}
EOF
```

**Use for future suggestions:**
```
I remember you all loved [activity] last [time]!
Want to do that again, or try something new?
```
