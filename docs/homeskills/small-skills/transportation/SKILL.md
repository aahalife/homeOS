---
name: transportation-small
description: Manage rides, commutes, carpools, and parking for families. Use when user needs a ride, checks traffic, coordinates carpool, asks about commute, or needs parking info.
version: 1.0-small
risk_default: LOW
---

# Transportation Skill (Small-Model)

## RISK RULES

IF action is booking a ride (Uber/Lyft/taxi):
  → RISK: HIGH
  → REQUIRE explicit user confirmation with "BOOK" keyword
  → Show cost estimate BEFORE booking

IF action is reserving parking with payment:
  → RISK: MEDIUM
  → REQUIRE user confirmation before charging

IF action is checking traffic OR commute time OR directions:
  → RISK: LOW
  → No confirmation needed

IF action is creating/viewing carpool schedule:
  → RISK: LOW
  → No confirmation needed

IF action is sharing live location:
  → RISK: MEDIUM
  → Confirm who receives it

## STORAGE

Data path: ~/clawd/homeos/data/
Memory path: ~/clawd/homeos/memory/
Files: transportation/rides.json, transportation/carpools.json, transportation/commute_prefs.json

## COMMUTE & TRAFFIC (RISK: LOW)

IF user asks "how long to get to [PLACE]" OR "traffic to [PLACE]":

Template:

🚗 COMMUTE: [ORIGIN] → [DESTINATION]

Drive time (normal): [MINUTES] min
Drive time (now): [MINUTES] min ([+/-DIFFERENCE])
Traffic level: [🟢 Light / 🟡 Moderate / 🔴 Heavy]

Route options:
- Route 1: [ROUTE_NAME] - [MINUTES] min, [MILES] mi [FASTEST/SHORTEST]
- Route 2: [ROUTE_NAME] - [MINUTES] min, [MILES] mi

Alerts: [ACCIDENTS/CONSTRUCTION/NONE]

💡 Leave by [TIME] to arrive by [TARGET_TIME]

IF user has a calendar event at the destination:
- Calculate departure time automatically
- Offer to set a departure reminder

OUTPUT_HANDOFF for departure reminder:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "set departure reminder", "context": { "reminder": "Leave for [DESTINATION]", "time": "[DEPARTURE_TIME]", "event": "[EVENT_NAME]" } }
```

## RIDE BOOKING (RISK: HIGH)

STEP 1 - Get ride estimates:

IF user says "get me a ride" OR "how much is an Uber/Lyft to [PLACE]":

Template:

🚗 RIDE OPTIONS to [DESTINATION]

From: [PICKUP_ADDRESS]
To: [DESTINATION_ADDRESS]
Distance: [MILES] mi
ETA: [MINUTES] min

- UberX: $[LOW]-$[HIGH] - [WAIT] min wait
- UberXL: $[LOW]-$[HIGH] - [WAIT] min wait
- Lyft: $[LOW]-$[HIGH] - [WAIT] min wait
- Lyft XL: $[LOW]-$[HIGH] - [WAIT] min wait

💡 Best value: [OPTION]
💡 Fastest pickup: [OPTION]

Which would you like to book?

STEP 2 - Confirm booking (MUST DO):

⚠️ RIDE BOOKING - APPROVAL REQUIRED

Booking: [SERVICE] [RIDE_TYPE]
Pickup: [ADDRESS]
Dropoff: [ADDRESS]
Est. cost: $[LOW]-$[HIGH]
ETA pickup: [MINUTES] min
Payment: [METHOD]

Type "BOOK" to confirm.
Type "CANCEL" to abort.

DO NOT book without explicit "BOOK" confirmation from user.

STEP 3 - After booking confirmed:

✅ RIDE BOOKED

Driver: [NAME] - [RATING]⭐
Vehicle: [COLOR] [MAKE_MODEL]
License plate: [PLATE]
Arriving in: [MINUTES] min

Track your ride: [URL]

Save ride to ~/clawd/homeos/data/transportation/rides.json

## CARPOOL COORDINATION (RISK: LOW)

IF user wants to set up a carpool:

Ask:
1. What event/activity?
2. What days/times?
3. Who is in the carpool? (names and addresses)
4. Who can drive which days?

Template for carpool schedule:

🚗 CARPOOL: [EVENT_NAME]
Schedule: [DAYS] at [TIME]
Location: [DESTINATION]

- [DAY_1]: [DRIVER_NAME] drives
  - [TIME_1] pick up [PASSENGER] at [ADDRESS]
  - [TIME_2] pick up [PASSENGER] at [ADDRESS]
  - [TIME_3] arrive [DESTINATION]

- [DAY_2]: [DRIVER_NAME] drives
  - [TIME_1] pick up [PASSENGER] at [ADDRESS]
  - [TIME_2] arrive [DESTINATION]

Save to ~/clawd/homeos/data/transportation/carpools.json

IF user wants carpool reminders:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "set carpool reminders", "context": { "event": "[EVENT]", "days": "[DAYS]", "driver_schedule": "[SCHEDULE]", "recurring": true } }
```

## PARKING (RISK: LOW for search, MEDIUM for reserve)

IF user asks "where can I park" OR "find parking near [PLACE]":

Template:

🅿️ PARKING near [DESTINATION]

- [GARAGE_NAME] - [DISTANCE] mi away
  Cost: $[RATE]/hr, $[MAX]/day
  Status: [Available/Limited/Full]
  Notes: [COVERED/UNCOVERED/RESERVABLE]

- [STREET_OPTION] - [DISTANCE] mi away
  Cost: $[RATE]/hr ([MAX_HOURS] hr max)
  Status: [Available/Limited]

- Free: [FREE_OPTION] - [DISTANCE] mi away
  Notes: [RESTRICTIONS]

💡 Recommendation: [BEST_OPTION] - [REASON]

IF user wants to reserve (RISK: MEDIUM):

🅿️ PARKING RESERVATION

Location: [GARAGE]
Date: [DATE]
Time: [START] - [END]
Cost: $[AMOUNT]

Confirm reservation? (yes/no)

## DEPARTURE ALERTS

IF user has a calendar event with a location:
- Calculate drive time including current traffic
- Add buffer: +10 min for normal trips, +30 min for airport
- Send alert template:

🚨 DEPARTURE ALERT

Event: [EVENT_NAME] at [EVENT_TIME]
Location: [ADDRESS]
Drive time now: [MINUTES] min
Recommended departure: [TIME] (in [MINUTES_UNTIL] min)
Traffic: [LEVEL]
Weather: [CONDITIONS]

Directions: [MAP_LINK]

## AIRPORT TRIPS (SPECIAL CASE)

IF destination contains "airport" OR user mentions flight:
- Add extra buffer: 30 min for navigation + security
- Suggest options: drive + park, rideshare, family drop-off
- Template:

✈️ AIRPORT TRIP

Destination: [AIRPORT]
Target arrival: [TIME]
Drive time now: [MINUTES] min
Recommended departure: [TIME] (includes 30 min buffer)

Options:
1. 🚗 Drive yourself - parking ~$[RATE]/day
2. 🚕 Rideshare - est. $[COST], no parking hassle
3. 👤 Family drop-off - free, need a driver

💡 Recommendation: [BEST_FOR_SITUATION]

## CROSS-SKILL HANDOFFS

IF user needs to schedule a recurring transport event:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "calendar event for transport", "context": { "title": "[TRANSPORT_EVENT]", "recurring": "[PATTERN]", "time": "[TIME]", "notes": "[DETAILS]" } }
```

IF user mentions car trouble or car maintenance:
```
OUTPUT_HANDOFF: { "next_skill": "home-maintenance", "reason": "vehicle issue", "context": { "issue": "[CAR_PROBLEM]", "vehicle": "[MAKE_MODEL]", "urgency": "[LEVEL]" } }
```

IF user needs to pick up groceries:
```
OUTPUT_HANDOFF: { "next_skill": "meal-planning", "reason": "grocery trip planning", "context": { "store": "[STORE]", "has_shopping_list": true } }
```

## FAMILY CONTEXT

IF family.json exists and has children:
- School commute = recurring, suggest carpool
- Activity transport (soccer, piano, etc.) = suggest carpool rotation
- Teen drivers = note independently but flag for parent awareness

IF multiple family members need transport at overlapping times:
- Flag the conflict
- Suggest solutions: carpool, rideshare for one, reschedule
