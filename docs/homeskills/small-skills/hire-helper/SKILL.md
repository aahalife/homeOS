---
name: hire-helper
description: Find and hire household help — babysitters, housekeepers, tutors, pet sitters, caregivers. Search, screen, hire.
risk: LOW (search) to MEDIUM (save provider) to HIGH (if phone call needed)
---

# Hire Helper Skill

## When to Use

User needs: babysitter, nanny, housekeeper, cleaner, tutor, dog walker, pet sitter, caregiver, or any recurring household help.

## Helper Types and Typical Rates

- **Childcare** (babysitter, nanny, au pair): $15-30/hr
- **Education** (tutor, music teacher): $25-75/hr
- **Household** (housekeeper, cleaner): $25-50/hr
- **Pet care** (dog walker, pet sitter): $15-25/visit
- **Elder care** (caregiver, companion): $18-35/hr

## Step 1: Define Requirements

Ask for missing info based on helper type.

**For childcare:**
```
👶 Childcare search — I need:
1. 👧 How many kids and ages?
2. 📅 Schedule? (days/times, regular or occasional)
3. 📍 At your home or elsewhere?
4. 💰 Budget per hour?
5. ✅ Must-haves? (CPR cert, own car, experience level)
6. 💕 Nice-to-haves? (light housework, homework help, language)
```

**For housekeeping:**
```
🧹 Cleaning help — I need:
1. 🏠 Home size? (rooms or sq ft)
2. 📅 How often? (weekly, biweekly, monthly, one-time)
3. 📝 Scope? (regular clean, deep clean, laundry, organizing)
4. 💰 Budget per visit?
5. ✅ Requirements? (own supplies, pet-friendly, eco products)
```

**For tutoring:**
```
📚 Tutor search — I need:
1. 🎓 Subject(s)?
2. 👦 Student age and grade?
3. 🎯 Goal? (homework help, test prep, enrichment)
4. 📅 How often and when?
5. 📍 In-person or online?
6. 💰 Budget per hour?
```

Check saved providers first:
```bash
cat ~/clawd/homeos/data/providers.json 2>/dev/null
```

## Step 2: Search

Recommend platforms by type:

**Paid platforms (more vetted):**
- Care.com — largest network, background checks available
- Sittercity — childcare focused
- UrbanSitter — Facebook-connected trust network
- Rover — pets only, includes insurance

**Free options:**
- Nextdoor — neighbor recommendations
- Facebook Groups — "[City] Babysitters", "Nannies of [Area]"
- Local college job boards — great for tutors

Help draft a job posting:
```
📝 JOB POST DRAFT:

"[Part-time Babysitter / Housekeeper / Tutor] Needed in [Area]

[Friendly intro about your family]

Looking for:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Schedule: [days/times]
Rate: $[X]-$[Y]/hour
Location: [general area — NOT exact address]

Please include: your experience, availability, and references."
```

## Step 3: Screen Candidates

### Initial screening checklist:
- ☐ Experience matches needs (years, type)
- ☐ Availability aligns with schedule
- ☐ Rate within budget
- ☐ Reviews are positive (read recent ones)
- ☐ Response is professional and timely

### Red flags — WARN if any are true:
- ☐ Vague about experience
- ☐ Can't or won't provide references
- ☐ Reluctant about background check
- ☐ Wants to communicate off-platform immediately
- ☐ Inconsistent work history
- ☐ Pushy about meeting at your home right away

### Interview questions by type:

**Babysitter/nanny:**
1. "What's your childcare experience?"
2. "What ages have you worked with?"
3. "What would you do if the child wouldn't stop crying?"
4. "How would you handle a tantrum?"
5. "What if a child got hurt?"
6. "Are you CPR certified?"
7. "Can you provide 2-3 family references?"

**Housekeeper:**
1. "How long have you cleaned professionally?"
2. "Walk me through how you'd clean a kitchen."
3. "Do you bring your own supplies?"
4. "How long would my home take?"
5. "Are you insured/bonded?"
6. "References from current clients?"

**Tutor:**
1. "What's your background in [subject]?"
2. "How do you assess where a student needs help?"
3. "How do you handle a student who's frustrated?"
4. "References from other families?"

## Step 4: Background Checks

### ⚠️ CHILDCARE: Background check is STRONGLY RECOMMENDED

For babysitters, nannies, and anyone caring for children alone:
```
⚠️ STRONG RECOMMENDATION: Run a background check before leaving children with this person.

Background check options:
- Care.com (included with membership)
- Checkr — checkr.com ($30-75)
- GoodHire — goodhire.com ($40-100)

Minimum check for childcare:
- Identity verification
- National criminal database
- Sex offender registry
- County criminal records

This is strongly recommended, not optional, for anyone who will be alone with your children.
```

For housekeepers: recommended (Level 1-2)
For tutors: recommended if in-home
For pet care: optional

### Reference check script:
```
📞 Call references and ask:
1. "How do you know [candidate]?"
2. "How long did they work for you?"
3. "Were they reliable and punctual?"
4. "Any concerns?"
5. "Would you hire them again?"
```

## Step 5: Trial Period

- **Babysitter:** Session 1 = stay home. Session 2 = short outing (1-2h). Session 3 = full shift.
- **Housekeeper:** First clean = be home to show preferences. Second clean = evaluate.
- **Tutor:** 2-3 sessions before committing monthly.

After trial, discuss: "How did it go? Ready for regular schedule?"

## Step 6: Hire and Onboard

**Babysitter onboarding — provide in writing:**
- Emergency contacts list
- Kids' routines, food rules, screen time rules
- Bedtime routine
- Allergies and medications
- House tour (exits, fire extinguisher, first aid)
- WiFi password, spare key/code
- Home address (for 911), pediatrician number
- Poison Control: 1-800-222-1222

**Housekeeper onboarding:**
- Walk through priorities per room
- Show product storage and preferences
- "Always do" vs "as needed" tasks
- Key/code access and alarm instructions
- Pet handling if applicable

**Payment setup:**
- Occasional sitters: cash or Venmo at end of session
- Regular staff: weekly or biweekly via Venmo/Zelle
- If paying one person $2,600+/year: consider payroll service (Care.com HomePay) for tax compliance

Save provider:
```bash
echo '{"type":"TYPE","name":"NAME","phone":"PHONE","rate":RATE,"schedule":"SCHED","started":"DATE","rating":5,"notes":"NOTES"}' >> ~/clawd/homeos/data/providers.json
```

## Safety Rules

**Before meeting a candidate:**
- First meeting in PUBLIC (coffee shop)
- Have another adult present for home interviews
- Never share exact address before meeting
- Never share daily schedule or when house is empty
- Trust your instincts — if something feels off, move on

**If phone call needed for hiring → HANDOFF:**
```
OUTPUT_HANDOFF:
  to: telephony
  reason: Need to call candidate/agency
  data:
    business_name: [name/agency]
    phone: [number]
    purpose: hiring inquiry
```

## Defaults

- Background check: strongly recommended for childcare, recommended for home access
- Trial period: always suggest before committing
- Payment: Venmo or cash
- References: minimum 2, actually call them
