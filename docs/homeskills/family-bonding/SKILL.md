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

## Activity Categories

| Category | Examples |
|----------|----------|
| Outdoor | Parks, hiking, beach, camping, sports |
| Indoor | Games, crafts, cooking, movies, museums |
| Educational | Science centers, zoos, historic sites |
| Active | Swimming, biking, sports, playground |
| Creative | Art projects, music, building, gardening |
| Social | Playdates, parties, community events |
| Relaxation | Spa day, picnic, stargazing, reading |

## Workflow Steps

### Step 1: Understand Context

Gather activity requirements:

```typescript
interface ActivityRequest {
  participants: {
    adults: number;
    children: { age: number; interests?: string[] }[];
  };
  constraints: {
    date?: Date;
    timeAvailable: number;    // Hours
    budget?: number;
    travelRadius: number;     // Miles
    mobility?: string[];      // Restrictions
  };
  preferences: {
    indoorOutdoor: 'indoor' | 'outdoor' | 'either';
    activityLevel: 'relaxed' | 'moderate' | 'active';
    category?: string;
    avoid?: string[];
  };
  weather?: {
    temperature: number;
    conditions: string;
  };
}
```

### Step 2: Generate Suggestions

Create personalized activity list:

```typescript
interface ActivitySuggestion {
  name: string;
  category: string;
  description: string;
  ageAppropriate: { min: number; max: number };
  duration: string;
  cost: {
    estimate: string;         // "Free", "$", "$$", "$$$"
    breakdown?: string;
  };
  location?: {
    name: string;
    address: string;
    distance: number;
  };
  bestTime: string;
  whatYouNeed: string[];
  tips: string[];
  weatherDependent: boolean;
  matchScore: number;         // How well it fits the request
}
```

### Step 3: Present Options

Show activity options with details:

```
🎯 Weekend Activity Ideas for Your Family

Based on: 2 adults, kids ages 5 & 9, budget ~$50, nice weather

1. 🌳 Explore Riverside Nature Trail
   Duration: 2-3 hours | Cost: Free
   Distance: 4.2 miles from home

   Easy hiking trail with playground at midpoint.
   Great for bikes or walking. Pack a picnic!

   Perfect for: Getting outdoors, active fun

2. 🎨 Family Art Workshop at Creative Studio
   Duration: 2 hours | Cost: $45 (family of 4)
   Distance: 2.8 miles from home

   Paint your own ceramics - everyone makes something!
   Saturday sessions: 10am, 2pm, 4pm

   Perfect for: Rainy day backup, keepsakes

3. 🎳 Cosmic Bowling Night
   Duration: 2 hours | Cost: $40-50
   Distance: 3.5 miles from home

   Saturday night glow bowling with music.
   Bumpers available for kids. Arcade games too.

   Perfect for: Active fun, all ages enjoy

[Plan This Activity] [More Ideas] [Filter Options]
```

### Step 4: Plan the Activity

Create detailed activity plan:

```typescript
interface ActivityPlan {
  activity: ActivitySuggestion;
  schedule: {
    departureTime: string;
    activityStart: string;
    activityEnd: string;
    mealPlan?: string;
  };
  preparation: string[];      // What to bring/do
  reservations?: {
    required: boolean;
    booked: boolean;
    confirmationNumber?: string;
  };
  backup: {
    activity: string;
    reason: string;           // If weather changes, etc.
  };
  reminders: {
    time: Date;
    message: string;
  }[];
}
```

### Step 5: Calendar Integration

Add to family calendar:

- Event with location and time
- Preparation reminders
- Pack list notification
- Weather check reminder (morning of)

## Age-Appropriate Activities

### Toddlers (1-3)
- Sensory play activities
- Short playground visits
- Story time at library
- Petting zoos
- Splash pads
- Simple crafts

### Preschool (3-5)
- Children's museums
- Easy nature walks
- Cooking simple recipes
- Building forts
- Backyard camping
- Dance parties

### School Age (6-10)
- Board game tournaments
- Bike rides
- Swimming
- Science experiments
- Scavenger hunts
- Sports activities

### Tweens (11-13)
- Escape rooms
- Mini golf
- Movie marathons
- DIY projects
- Volunteer activities
- Learning new skills

### Mixed Ages
- Family movie nights
- Picnics in the park
- Baking together
- Stargazing
- Family photos
- Holiday traditions

## Seasonal Ideas

### Spring
- Plant a garden
- Fly kites
- Visit farmers market
- Nature photography
- Outdoor picnics
- Baseball games

### Summer
- Beach days
- Water balloon fights
- Outdoor movies
- Camping trips
- Ice cream making
- Fireworks viewing

### Fall
- Apple picking
- Pumpkin patches
- Leaf pile jumping
- Halloween activities
- Football games
- Hot cocoa nights

### Winter
- Snow activities
- Holiday baking
- Indoor forts
- Game marathons
- Winter crafts
- Hot springs visit

## Local Event Discovery

Search for events:

```typescript
interface EventSearch {
  location: string;
  dateRange: { start: Date; end: Date };
  categories: string[];
  ageGroups: string[];
  priceRange: string;
}

interface LocalEvent {
  name: string;
  description: string;
  date: Date;
  time: string;
  location: string;
  cost: string;
  ageRange: string;
  category: string;
  source: string;            // Eventbrite, Facebook, etc.
  url: string;
}
```

**Event Sources:**
- Eventbrite
- Facebook Events
- Local newspaper
- Parks & Recreation
- Library programs
- School newsletters

## Example Interactions

**User**: "What can we do with the kids this rainy Saturday?"

**Assistant**:
```
☔ Rainy Day Fun for the Family!

Perfect for staying dry with kids ages 5 & 9:

🏠 AT HOME IDEAS:

1. 🍪 Family Bake-Off
   Make cookies or cupcakes together
   Let kids decorate their own!
   Cost: Ingredients you have | Time: 1-2 hours

2. 🎬 Movie Marathon + Fort
   Build a blanket fort in the living room
   Popcorn, pillows, pick 2-3 movies
   Cost: Free | Time: Afternoon

3. 🎲 Board Game Tournament
   Bracket-style competition
   Winner picks dinner!
   Cost: Free | Time: 2-3 hours

🚗 NEARBY OPTIONS:

4. 🎳 Galaxy Lanes Bowling
   $8/person includes shoes
   3.2 miles | Opens 10am
   Indoor arcade too!

5. 📚 Story Time at Main Library
   Free! Saturday at 11am
   Craft activity included
   2.1 miles away

6. 🔬 Discovery Science Center
   $12/kid, $15/adult
   Hands-on exhibits
   5.4 miles | Open 10am-5pm

Which sounds fun? I can help plan any of these!
```

**User**: "We need a date night idea for next Friday"

**Assistant**:
```
💑 Date Night Ideas for Friday

I can help with both the plans AND finding a sitter!

🍽️ DINNER & ACTIVITY OPTIONS:

1. Classic Romance
   Dinner at Bella Notte (Italian, $$$$)
   + Walk along Harbor Promenade
   Est: $120-150 | 4 hours

2. Fun & Games
   Dinner at Pacific Grill ($$$)
   + Comedy Show at Laugh Factory
   Est: $100-130 | 4 hours

3. Adventure Night
   Food Hall Tasting Tour ($)
   + Escape Room Challenge
   Est: $80-100 | 3.5 hours

4. Low-Key Evening
   Wine Bar & Small Plates ($$)
   + Outdoor Movie in the Park (free!)
   Est: $60-80 | 3 hours

📍 All options within 15 min drive

Need a sitter? I found 3 available that night:
- Sarah M. ($22/hr) - ⭐ 4.9
- Emily K. ($20/hr) - ⭐ 4.8
- Jessica T. ($25/hr) - ⭐ 4.7

[Plan Date Night] [Find Different Sitter] [Other Ideas]
```

## Recurring Activities

Set up regular family time:

```typescript
interface RecurringActivity {
  name: string;
  frequency: 'weekly' | 'biweekly' | 'monthly';
  dayOfWeek: string;
  time: string;
  activities: string[];       // Rotation of activities
  reminders: boolean;
}
```

**Suggested Traditions:**
- Weekly game night (Fridays)
- Monthly movie night (first Saturday)
- Seasonal outings (quarterly)
- Birthday traditions
- Holiday activities
