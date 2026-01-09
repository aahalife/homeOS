---
name: transportation
description: Manage family transportation including ride booking, commute alerts, carpool coordination, and parking. Use when the user needs a ride, wants to check traffic, asks about commute times, needs to coordinate carpools, or is looking for parking.
---

# Transportation Skill

Manage rides, commutes, carpools, and parking for the family.

## When to Use

- User needs to book an Uber/Lyft
- User asks about commute time or traffic
- User wants to coordinate carpool
- User needs to find parking
- User asks about family member locations (transport context)
- User planning trips that involve driving

## Workflow Overview

```
1. Identify Transport Need → 2. Get Options → 3. Compare/Select
→ 4. Book/Plan → 5. Track & Notify
```

## Ride Booking

### Get Ride Estimates

**Request:**
```
Get me a ride to [destination]
How much is an Uber to [destination]?
```

**Response:**
```
🚗 RIDE OPTIONS to [Destination]

From: [Your Location]
To: [Destination]
Distance: [X] miles | ETA: [X] min

━━━ UBER ━━━
• UberX: $15-22 | 5 min away
• UberXL: $22-30 | 8 min away
• Uber Black: $45-55 | 3 min away

━━━ LYFT ━━━
• Lyft: $14-20 | 4 min away
• Lyft XL: $20-28 | 6 min away

💡 Best value: Lyft Standard ($14-20)
💡 Fastest pickup: Uber Black (3 min)

Which would you like to book?
```

### Book a Ride

**⚠️ HIGH RISK - Requires explicit approval:**
```
⚠️ RIDE BOOKING APPROVAL

Booking: [Uber/Lyft] [Ride Type]

📍 Pickup: [Address]
🎯 Dropoff: [Address]
💰 Est. cost: $[XX]-$[XX]
⏱️ ETA pickup: [X] minutes

This will charge your [payment method].

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Type "BOOK" to confirm.
Type "CANCEL" to abort.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**After booking:**
```
✅ RIDE BOOKED!

🚗 [Uber/Lyft] [Ride Type]

👤 Driver: [Name] - [Rating]⭐
🚙 Vehicle: [Color] [Make Model]
📋 License: [Plate]

⏰ Arriving in [X] minutes

📍 Track your ride:
🔗 [Tracking URL]

I'll notify you when the driver arrives!
```

### Track Active Ride

```
🚗 RIDE STATUS

👤 Driver: [Name]
🚙 [Vehicle Description]

✅ Status: [On the way / Arriving / Waiting]
⏰ ETA: [X] minutes

📍 Driver location: [Description]

🔗 Live tracking: [URL]
```

## Commute & Traffic

### Check Commute Time

**Request:**
```
How long to get to [destination]?
Traffic to [destination]?
```

**Response:**
```
🚗 COMMUTE: [Origin] → [Destination]

Current conditions:

⏱️ Normal time: 20 min
⏱️ With traffic: 28 min (+8 min)
🚦 Traffic: 🟡 Moderate

━━━ ROUTE OPTIONS ━━━

1. Via Highway 101 (Fastest)
   ⏱️ 28 min | 12.5 mi
   ⚠️ Slowdown near Exit 42

2. Via Surface Streets
   ⏱️ 32 min | 10.2 mi
   ✅ No delays

💡 Leave by [Time] to arrive by [Target Time]

🚨 ALERTS:
• Accident reported on Hwy 101 near Oak Street

Want me to set a departure reminder?
```

### Departure Alerts

**Proactive alert:**
```
🚨 DEPARTURE ALERT

You have: [Event] at [Time]
Location: [Address]

Recommended departure: [Time] (in 15 min)

Current conditions:
• Drive time: 25 min (normally 20)
• Traffic: Moderate
• Weather: Clear

📍 Directions: [Google Maps link]

Leave now or snooze 5 min?
```

## Carpool Coordination

### Create Carpool

**Request:**
```
Set up carpool for [event]
Organize carpool to [destination]
```

**Response:**
```
🚗 CARPOOL SETUP

Event: [Event Name]
Destination: [Address]
Date: [Date/Time]

Who's in the carpool?
• Driver: [Who's driving?]
• Passengers: [Who needs a ride?]

Pickup points:
• [Address 1] - pick up [Name]
• [Address 2] - pick up [Name]

Create this carpool?
```

**Carpool confirmation:**
```
✅ CARPOOL CREATED

🚗 CARPOOL: [Event]
📅 [Date] at [Time]

👤 Driver: [Name]
🚙 Seats available: [X]

📍 ROUTE:
1. [Pickup 1] - [Time] - [Passenger]
2. [Pickup 2] - [Time] - [Passenger]
3. 🎯 [Destination] - [Arrival]

Total drive time: [X] min

📱 Notifications will be sent to all passengers.
```

### Join Carpool

```
🚗 JOIN CARPOOL

[Driver Name] is driving to [Event]:

📅 [Date] at [Time]
📍 Pickup from: [Location]
⏰ Pickup time: [Time]

Seats available: [X]

Join this carpool?
```

### Carpool Reminders

**To driver:**
```
🚗 CARPOOL REMINDER

You're driving to [Event] today!

📅 [Date] at [Arrival Time]

📍 Your route:
1. Leave home: [Time]
2. Pick up [Name] at [Location]: [Time]
3. Pick up [Name] at [Location]: [Time]
4. Arrive [Destination]: [Time]

Total: [X] passengers, [X] min drive

All passengers have been notified.
```

**To passenger:**
```
🚗 CARPOOL PICKUP

[Driver] is picking you up for [Event]!

📍 Pickup: [Your Address]
⏰ Time: [Time] (in [X] minutes)
🚙 Vehicle: [Description]

Please be ready 5 min early.
```

## Parking

### Find Parking

**Request:**
```
Find parking near [destination]
Where can I park at [location]?
```

**Response:**
```
🅿️ PARKING: Near [Destination]

━━━ GARAGES ━━━

1. Downtown Garage
   📍 0.2 mi from destination
   💰 $3/hr | $15/day
   ✅ Available | 🔒 Reservable
   💡 "Covered, well-lit"

2. City Center Parking
   📍 0.4 mi from destination
   💰 $2/hr | $12/day
   ✅ Available

━━━ STREET PARKING ━━━

3. 2nd Avenue
   📍 0.1 mi
   💰 $2/hr (2 hr max)
   ⚠️ Limited availability

━━━ FREE OPTIONS ━━━

4. Side Street (3rd & Oak)
   📍 0.5 mi
   💰 Free after 6pm

💡 Recommendation: Downtown Garage - closest and can reserve

Reserve a spot?
```

### Reserve Parking

**⚠️ MEDIUM RISK - Confirm reservation:**
```
🅿️ PARKING RESERVATION

📍 Downtown Garage
📅 [Date]
⏰ [Start Time] - [End Time]
💰 Estimated: $[XX]

Confirm reservation?
```

## Family Location (Transport Context)

**Check locations:**
```
📍 FAMILY LOCATIONS

Last updated: [Time]

👨 Dad
   📍 Work - 123 Office Blvd
   🔋 85%
   👣 Updated 5 min ago

👩 Mom
   📍 Home
   🔋 62%
   👣 Updated just now

👧 Emma
   📍 School - Lincoln High
   🔋 45%
   👣 Updated 15 min ago

👦 Jack
   📍 Soccer practice - City Fields
   🔋 78%
   👣 Updated 3 min ago

📍 View on map: [Link]
```

## Storage Structure

```
~/clawd/homeos/
├── data/
│   ├── transportation/
│   │   ├── rides.json           # Ride history
│   │   ├── carpools.json        # Active carpools
│   │   ├── locations.json       # Family locations
│   │   └── commute_prefs.json   # Saved routes
│   └── calendar.json            # Transport-related events
└── memory/
    └── preferences/
        └── transport.json       # Preferred services, routes
```

## Example Interactions

**User:** "I need to get to the airport by 6pm"

**Assistant:**
```
✈️ AIRPORT TRIP PLANNING

Destination: [Airport Name]
Target arrival: 6:00 PM

Current conditions:
• Drive time: 35 min (normally 25 min)
• Traffic: Heavy - rush hour
• Weather: Clear

🚨 Recommended departure: 5:15 PM
   (Buffer for traffic + airport navigation)

━━━ OPTIONS ━━━

1. 🚗 Drive yourself
   • Est. parking: $12/day
   • Leave by 5:15 PM

2. 🚕 Uber/Lyft
   • Est. cost: $35-45
   • Request at 5:00 PM
   • No parking worries

3. 👤 Ask family for ride
   • [Dad] is available

💡 Recommendation: Rideshare - avoids parking costs
for multi-day trip and rush hour stress.

What would you like to do?
```

**User:** "Book an Uber"

**Assistant:**
```
🚗 UBER BOOKING

I'll schedule an Uber for you:

📍 Pickup: [Your Address]
🎯 Dropoff: [Airport]
⏰ Request at: 5:00 PM (arriving ~5:45 PM)

⚠️ APPROVAL REQUIRED

Est. cost: $35-45
Ride type: UberX

Type "BOOK" to schedule this ride.
```

**User:** "Set up carpool for Emma's soccer"

**Assistant:**
```
🚗 CARPOOL SETUP: Emma's Soccer

I see Emma has soccer practice:
• Tuesday & Thursday at 4:00 PM
• Location: City Sports Complex

Let me set this up:

1. Who else needs rides?
   (Give me names/families)

2. Who can drive which days?
   (We can rotate)

3. What are pickup addresses?

Once I have this, I'll create a carpool schedule!
```

## Integration Points

- **Calendar**: Transport events and departure reminders
- **Family Comms**: Coordinate pickups and carpools
- **Education**: School commute and activity transport
- **Healthcare**: Doctor appointment transport
