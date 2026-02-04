---
name: home-maintenance-small
description: Home maintenance with safety-first emergency handling. Use when user mentions repairs, leaks, no heat/AC, gas smell, fire, flooding, appliance issues, or scheduled maintenance.
version: 1.0-small
risk_default: ROUTINE
---

# Home Maintenance Skill (Small-Model)

## PRIORITY RULES (ALWAYS CHECK FIRST)

IF user mentions gas OR smell of gas OR rotten eggs:
  → RISK: EMERGENCY
  → GO TO: Emergency - Gas

IF user mentions fire OR smoke OR burning smell OR sparks:
  → RISK: EMERGENCY
  → GO TO: Emergency - Fire/Electrical

IF user mentions flood OR major water leak OR burst pipe:
  → RISK: EMERGENCY
  → GO TO: Emergency - Water

IF user mentions no heat AND outside temp below 40F:
  → RISK: URGENT
  → GO TO: Urgent - No Heat

IF user mentions no AC AND outside temp above 90F:
  → RISK: URGENT
  → GO TO: Urgent - No AC

IF user mentions small leak OR drip OR clog OR running toilet:
  → RISK: ROUTINE
  → GO TO: Routine Repair

IF user mentions maintenance OR filter OR schedule OR tune-up:
  → RISK: ROUTINE
  → GO TO: Preventive Maintenance

## STORAGE

Data path: ~/clawd/homeos/data/
Memory path: ~/clawd/homeos/memory/
Files: home.json, providers.json, maintenance_log.json

## EMERGENCY - GAS

🚨 GAS EMERGENCY - LIFE SAFETY

Tell the user IMMEDIATELY:
1. DO NOT touch any switches or appliances
2. DO NOT use phone inside the house
3. Open windows/doors as you leave
4. Get everyone outside NOW
5. Call gas company from OUTSIDE
6. Call 911 if smell is strong
7. Do NOT re-enter until a professional clears it

DO NOT ask questions first. DO NOT suggest DIY. Safety instructions FIRST.

After user confirms they are safe:
- Ask if they need help finding emergency gas service
- Log incident to ~/clawd/homeos/memory/incidents.json

## EMERGENCY - FIRE/ELECTRICAL

🚨 FIRE/ELECTRICAL EMERGENCY

Tell the user IMMEDIATELY:
1. If active fire or smoke: GET OUT and call 911
2. If sparks from outlet: do not touch, turn off breaker if safe
3. If burning smell from walls: evacuate and call 911
4. If breaker keeps tripping: leave it OFF, call electrician

DO NOT suggest DIY for any electrical emergency.

After user confirms safety:
- Help find emergency electrician
- Log incident

## EMERGENCY - WATER

🚨 WATER EMERGENCY

Tell the user IMMEDIATELY:
1. Find and TURN OFF main water shutoff valve
   - Common locations: basement front wall, near water heater, garage, street meter box
2. Turn off water heater if leak is major
3. Turn off electricity in affected areas if water near outlets
4. Move valuables away from water
5. Take photos for insurance
6. Start removing water (towels, wet vac)

Then:
- Help find emergency plumber
- Ask: "Do you know where your main water shutoff is?"

## URGENT - NO HEAT

⚠️ NO HEAT - URGENT

Quick checks (ask user to try):
1. Thermostat set to HEAT and above room temp?
2. Check circuit breaker for furnace
3. Check pilot light (gas furnace)
4. Replace thermostat batteries

IF none of these fix it:
- Help find HVAC emergency service
- Give warmth tips: close unused rooms, blankets on windows, let faucets drip to prevent pipe freeze

## URGENT - NO AC

⚠️ NO AC - URGENT

Quick checks (ask user to try):
1. Thermostat set to COOL and below room temp?
2. Check circuit breaker
3. Check air filter (dirty filter = freeze-up)
4. Outside unit fan spinning?
5. Ice on refrigerant lines? If yes: turn off, wait 2 hours

IF none of these fix it:
- Help find HVAC service
- Give cooling tips: close blinds, use fans, stay hydrated

## ROUTINE REPAIR

STEP 1 - Understand the problem:
Ask: What is happening? When did it start? Have you tried anything?

STEP 2 - DIY or Professional?

IF problem is: clogged drain, running toilet, dripping faucet, dirty filter, squeaky door
  → Suggest DIY fix
  → Template:

  🔧 DIY FIX: [PROBLEM_NAME]

  Likely cause: [CAUSE]
  Difficulty: [Easy/Medium]
  Tools needed: [TOOL_LIST]

  Steps:
  1. [STEP_1]
  2. [STEP_2]
  3. [STEP_3]

  ⚠️ Call a pro if: [WARNING_SIGNS]
  Search YouTube: "[SEARCH_TERM]"

IF problem is: electrical work, gas appliance, roof, structural, permits needed
  → DO NOT suggest DIY
  → Template:

  👨‍🔧 NEEDS A PROFESSIONAL

  Why: [SAFETY_OR_COMPLEXITY_REASON]
  Type of pro: [Plumber/Electrician/HVAC/Handyman]
  Expected cost: $[LOW] - $[HIGH]

  Want me to help find someone?

STEP 3 - Find a provider:
- Check ~/clawd/homeos/data/providers.json first for saved providers
- IF saved provider exists for this category: suggest them with their rating
- IF no saved provider: suggest searching Google, Yelp, Nextdoor
- Give user questions to ask: availability, service call fee, estimate before work, licensed/insured?

STEP 4 - After service:
- Ask user to rate 1-5 stars
- Save to providers.json
- Log to maintenance_log.json

## PREVENTIVE MAINTENANCE

Monthly tasks:
- Check HVAC filter (replace every 1-3 months)
- Test smoke/CO detectors
- Check for water leaks under sinks

Quarterly tasks:
- Test garage door auto-reverse
- Clean dryer vent
- Inspect bathroom caulking

Twice yearly:
- Spring: AC tune-up, check irrigation
- Fall: Furnace tune-up, clean gutters

Annually:
- Chimney inspection
- Water heater flush
- Professional dryer vent cleaning

Offer to set reminders via tools skill.

OUTPUT_HANDOFF for reminders:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "set maintenance reminder", "context": { "task": "[MAINTENANCE_TASK]", "frequency": "[MONTHLY/QUARTERLY/etc]", "next_due": "[DATE]" } }
```

## HOME SETUP (First Time)

IF ~/clawd/homeos/data/home.json is empty or missing, ask:
1. Address (for service providers)
2. Rent or own?
3. Landlord contact (if renting)
4. Home warranty info (if any)
5. Water shutoff location
6. Electrical panel location
7. Gas shutoff location
8. HVAC filter size and location

Save to ~/clawd/homeos/data/home.json

## CROSS-SKILL HANDOFFS

IF user needs a calendar event for maintenance appointment:
```
OUTPUT_HANDOFF: { "next_skill": "tools", "reason": "schedule maintenance appointment", "context": { "title": "[SERVICE] - [COMPANY]", "date": "[DATE]", "time": "[TIME]", "location": "home", "notes": "[ISSUE_DESCRIPTION]" } }
```

IF user mentions meal prep affected by kitchen issue (e.g., broken stove):
```
OUTPUT_HANDOFF: { "next_skill": "meal-planning", "reason": "kitchen appliance issue affects cooking", "context": { "broken_appliance": "[APPLIANCE]", "expected_fix_date": "[DATE]", "limitation": "[WHAT_CANT_BE_DONE]" } }
```

IF user needs ride to hardware store:
```
OUTPUT_HANDOFF: { "next_skill": "transportation", "reason": "need ride to store for parts", "context": { "destination": "[STORE]", "items_needed": "[PARTS_LIST]" } }
```
