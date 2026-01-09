---
name: home-maintenance
description: Schedule and manage home maintenance tasks with service provider coordination. Use when the user mentions home repairs, maintenance scheduling, finding contractors, HVAC service, plumbing issues, appliance repairs, or any home upkeep needs. Handles both routine maintenance and emergency situations.
---

# Home Maintenance Skill

Manage home maintenance scheduling, service provider search, and emergency guidance for all household repair and upkeep needs.

## When to Use

- User mentions needing repairs (plumbing, electrical, HVAC)
- User asks about home maintenance schedules
- User needs to find a contractor or handyman
- User reports an emergency (water leak, no heat, broken appliance)
- User wants to schedule routine maintenance

## Storage Setup

```bash
mkdir -p ~/clawd/homeos/data
# Initialize home info if not exists
[ ! -f ~/clawd/homeos/data/home.json ] && echo '{}' > ~/clawd/homeos/data/home.json
[ ! -f ~/clawd/homeos/data/providers.json ] && echo '{}' > ~/clawd/homeos/data/providers.json
[ ! -f ~/clawd/homeos/data/maintenance_log.json ] && echo '[]' > ~/clawd/homeos/data/maintenance_log.json
```

## Emergency vs Non-Emergency

**FIRST: Assess urgency**

| 🚨 EMERGENCY | ⏰ URGENT | 📅 ROUTINE |
|-------------|----------|----------|
| Gas smell | No hot water | Filter replacement |
| Major water leak | AC broken (hot day) | Annual tune-up |
| No heat (freezing) | Toilet clogged | Gutter cleaning |
| Electrical fire risk | Appliance broken | Painting |
| Sewage backup | Minor leak | Upgrades |

## Emergency Handling

**For ANY emergency, lead with safety:**

### 🚨 Gas Smell Emergency
```
🚨 GAS SMELL - THIS IS URGENT

❗ DO IMMEDIATELY:
1. DO NOT turn on/off ANY switches or appliances
2. DO NOT use your phone inside
3. Open windows/doors as you exit
4. Get everyone outside NOW
5. Call gas company from OUTSIDE: [Local gas company #]
6. Call 911 if smell is strong
7. Don't re-enter until cleared by professionals

❌ DO NOT:
- Light any flames
- Use electrical switches
- Start your car in garage
- Ignore "minor" gas smells

This is a life-safety emergency. Exit first, call second.
```

### 🚨 Major Water Leak Emergency
```
🚨 WATER LEAK - ACT FAST

❗ DO IMMEDIATELY:
1. TURN OFF MAIN WATER VALVE
   📍 Typical locations:
   - Basement near front wall
   - Near water heater
   - In garage
   - At street (meter box)
   
2. Turn off water heater (if leak is major)
3. Turn off electricity in affected areas (if water near outlets)
4. Move valuables away from water
5. Take photos/video for insurance
6. Start removing water (towels, wet vac, mops)

📞 Call emergency plumber NOW.

Do you know where your main water shutoff is?
```

### 🚨 No Heat Emergency (Freezing Temps)
```
🚨 NO HEAT IN FREEZING WEATHER

❗ IMMEDIATE STEPS:
1. Check thermostat - is it set to HEAT and above room temp?
2. Check circuit breaker for furnace
3. Check if pilot light is on (gas furnace)
4. Replace thermostat batteries

🏠 KEEP WARM:
- Close off unused rooms
- Hang blankets over windows
- Use space heaters safely (not near flammables)
- Open cabinet doors to prevent pipe freezing
- Let faucets drip slightly

📞 I'll help you find emergency HVAC service.

Did any of the quick fixes work?
```

### 🚨 Electrical Emergency
```
🚨 ELECTRICAL ISSUE

If you see sparks, smell burning, or see smoke:
1. Don't touch anything
2. Turn off main breaker if safe to reach
3. Call 911 if active fire/smoke
4. Exit if unsure

If circuit breaker keeps tripping:
1. Unplug devices on that circuit
2. Reset breaker (flip OFF, then ON)
3. If it trips again, leave it off
4. Call electrician - do not keep resetting

Do you see sparks or smell burning?
```

## Non-Emergency Repairs

### Step 1: Understand the Problem

```
🔧 Let me help with your [issue]. A few questions:

1. What exactly is happening? (describe symptoms)
2. When did it start?
3. Have you tried anything already?
4. Any related issues? (unusual sounds, smells, etc.)

This helps me suggest whether it's DIY-able or needs a pro.
```

### Step 2: DIY vs Professional Assessment

**DIY-friendly fixes:**
```
🛠️ This sounds like something you might fix yourself!

Problem: [Issue]
Likely cause: [Cause]
DIY difficulty: [Easy/Medium]

📝 Steps to try:
1. [Step 1]
2. [Step 2]
3. [Step 3]

📺 Video guide: [Search term for YouTube]

🛠️ Tools needed:
- [Tool 1]
- [Tool 2]

⚠️ Call a pro if:
- [Warning sign 1]
- [Warning sign 2]

Want to try this, or prefer I find a professional?
```

**Needs professional:**
```
👨‍🔧 This one needs a professional.

Why: [Explanation - safety, complexity, code requirements]

Type of pro needed: [Plumber/Electrician/HVAC/Handyman]

Expected cost range: $[X] - $[Y]

Want me to help find someone?
```

### Step 3: Find Service Providers

**Check for saved providers first:**
```bash
cat ~/clawd/homeos/data/providers.json 2>/dev/null | jq '.["CATEGORY"]'
```

**If trusted provider exists:**
```
👍 You've used [Provider Name] before for [service].
You rated them [X] stars.
Phone: [Number]

Want me to help you contact them, or find other options?
```

**Search for new providers:**
```
🔍 Finding [Service Type] near you...

Search these for reviews and availability:

1. Google: "[service] near [location]"
   google.com/search?q=[service]+near+me

2. Yelp: yelp.com/search?find_desc=[service]

3. Nextdoor: Check for neighbor recommendations

4. Angi: angi.com/companylist/[service]

What to look for:
✅ 4+ star rating with many reviews
✅ Licensed and insured
✅ Clear pricing or free estimates
✅ Good response time
❌ Avoid: No reviews, won't give references, wants cash only upfront
```

**Present provider options:**
```
🔧 [SERVICE TYPE] Options Near You

1. ⭐ [Company Name] - [Rating]★ ([X] reviews)
   📞 [Phone]
   💰 Service call: $[X]
   ✅ Licensed, Insured
   📝 "[Recent review snippet]"

2. [Company Name] - [Rating]★ ([X] reviews)
   📞 [Phone]
   💰 Service call: $[X]
   ✅ Licensed, Insured

3. [Company Name] - [Rating]★ ([X] reviews)
   📞 [Phone]
   💰 Service call: $[X]

💡 Questions to ask when you call:
• Are you available [today/this week]?
• What's the service call fee?
• Can you give me an estimate before starting work?
• Are you licensed and insured?
```

### Step 4: Help Schedule Service

**Provide call script:**
```
📞 When you call [Company], here's what to say:

"Hi, I need help with [problem description]. 
[Brief symptoms].
Can someone come out [today/this week]?
What's your service call fee?"

Be ready to provide:
• Your address
• Your phone number
• Best time for appointment
• Access instructions (gate code, etc.)

Let me know the appointment details and I'll add a reminder!
```

### Step 5: Track and Follow Up

**Save appointment:**
```bash
cat >> ~/clawd/homeos/data/calendar.json << 'EOF'
{
  "type": "maintenance",
  "title": "SERVICE_TYPE - COMPANY_NAME",
  "date": "DATE",
  "time": "TIME",
  "notes": "ISSUE_DESCRIPTION",
  "provider": {
    "name": "COMPANY",
    "phone": "PHONE"
  }
}
EOF
```

**After service - save provider:**
```
How did it go with [Company]?

1. ⭐⭐⭐⭐⭐ Excellent - definitely use again
2. ⭐⭐⭐⭐ Good - would use again
3. ⭐⭐⭐ Okay - maybe try someone else
4. ⭐⭐ Poor - won't use again
5. ⭐ Terrible - avoid

I'll save this for future reference.
```

```bash
# Save provider with rating
cat ~/clawd/homeos/data/providers.json | jq '.CATEGORY = {"name": "COMPANY", "phone": "PHONE", "rating": X, "last_used": "DATE", "notes": "USER_NOTES"}' > /tmp/providers.json && mv /tmp/providers.json ~/clawd/homeos/data/providers.json
```

## Home Information Setup

**First time - gather essential info:**
```
🏠 Let me save some important home info for emergencies:

1. 📍 Address: [For service provider scheduling]
2. 💵 Do you rent or own?
3. 📞 Landlord/property manager contact: [If renting]
4. 📜 Home warranty company: [If applicable]

Shutoff locations (IMPORTANT for emergencies):
5. 💧 Main water shutoff: [Where is it?]
6. ⚡ Electrical panel: [Where is it?]
7. 🔥 Gas shutoff: [Where is it?]
8. 🌡️ HVAC filter location: [For regular maintenance]
```

**Save home info:**
```bash
cat > ~/clawd/homeos/data/home.json << 'EOF'
{
  "address": "ADDRESS",
  "type": "own|rent",
  "landlord": {
    "name": "NAME",
    "phone": "PHONE"
  },
  "warranty": {
    "company": "COMPANY",
    "phone": "PHONE",
    "policy": "POLICY_NUMBER"
  },
  "shutoffs": {
    "water": "LOCATION",
    "electric": "LOCATION",
    "gas": "LOCATION"
  },
  "hvac_filter": {
    "size": "SIZE",
    "location": "LOCATION"
  },
  "updated": "DATE"
}
EOF
```

## Preventive Maintenance Schedule

```
📅 HOME MAINTENANCE CALENDAR

MONTHLY:
☐ Check HVAC filter (replace every 1-3 months)
☐ Test smoke/CO detectors
☐ Run garbage disposal with ice cubes
☐ Check for water leaks under sinks

QUARTERLY:
☐ Test garage door auto-reverse
☐ Clean dryer vent
☐ Check water heater for sediment
☐ Inspect caulking in bathrooms

BI-ANNUALLY:
☐ Spring: AC tune-up, check irrigation
☐ Fall: Furnace tune-up, clean gutters

ANNUALLY:
☐ Chimney inspection/cleaning
☐ Septic pumping (if applicable)
☐ Professional dryer vent cleaning
☐ Water heater flush

Want me to set up reminders for any of these?
```

## Common Issues Quick Reference

### Plumbing
```
🚿 CLOGGED DRAIN
DIY first:
1. Plunger (cup for sinks, flange for toilets)
2. Baking soda + vinegar (1/2 cup each, wait 30 min)
3. Drain snake for hair clogs

⚠️ Call pro if: Multiple drains clogged, sewage smell

🚰 RUNNING TOILET
DIY first:
1. Jiggle handle
2. Check flapper - replace if worn ($5 fix)
3. Adjust float level

⚠️ Call pro if: Still running after flapper replacement

💧 DRIPPING FAUCET
DIY: Replace washer or cartridge (YouTube + $10 parts)
Pro: If you're not comfortable with it (~$100-150)
```

### HVAC
```
❄️ AC NOT COOLING
Check first:
1. Thermostat set to COOL, below room temp?
2. Filter clean? (dirty filter = no airflow)
3. Outside unit running? (listen for fan)
4. Circuit breaker tripped?
5. Ice on lines? (turn off, let thaw 2 hrs)

🔥 HEATER NOT WORKING
Check first:
1. Thermostat set to HEAT, above room temp?
2. Filter clean?
3. Pilot light on? (gas furnaces)
4. Circuit breaker?

⚠️ Call HVAC pro if basic checks don't help
```

### Electrical
```
⚡ OUTLET NOT WORKING
Check first:
1. Is it a GFCI outlet? Press RESET button
2. Check circuit breaker
3. Test with something you KNOW works

⚠️ Call electrician if:
- Sparking, burning smell
- Breaker keeps tripping
- Outlet is warm to touch
- Multiple outlets affected

NEVER DIY: Panel work, new circuits, outdoor wiring
```

## Example Interactions

**User:** "My AC stopped working and it's 95 degrees!"

**Assistant:**
```
🌡️ AC emergency on a hot day - let's fix this fast!

⚡ Quick checks (try these now):

1. Thermostat check:
   - Set to COOL?
   - Set BELOW current room temp?
   - Fresh batteries?

2. Circuit breaker:
   - Check panel for tripped breaker
   - Flip OFF, then ON to reset

3. Air filter:
   - When did you last change it?
   - Dirty filter = AC freeze-up

4. Outside unit:
   - Is the fan spinning?
   - Any ice on the lines?

Try these and let me know what you find!

❄️ Meanwhile, stay cool:
- Close blinds on sunny windows
- Use fans to circulate air
- Stay hydrated
```

**User:** "Checked all that. Outside unit fan isn't spinning."

**Assistant:**
```
Fan not spinning usually means:
- Capacitor failure (common, ~$150-250 repair)
- Fan motor issue (~$300-500 repair)
- Contactor problem (~$100-200 repair)

This needs a pro. Let me help you find one.

🔧 HVAC Emergency Service

Search: "emergency AC repair near me"
Google: google.com/search?q=emergency+ac+repair+near+me

When you call, ask:
• "Can someone come today?"
• "What's your emergency service fee?"
• "Outside unit fan isn't spinning"

💡 Expect:
- Emergency fee: $75-150
- Repair: $150-500 depending on issue
- Total: $225-650 range

Do you have a home warranty? Sometimes AC is covered.

Would you like me to find specific companies to call?
```
