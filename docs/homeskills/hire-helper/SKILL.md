---
name: hire-helper
description: Find and hire household help including babysitters, housekeepers, tutors, and caregivers. Use when the user needs to find childcare, cleaning services, tutoring, pet care, senior care, or any recurring household help. Handles search, screening guidance, and hiring.
---

# Hire Helper Skill

Help families find, screen, and hire trusted household help including babysitters, housekeepers, tutors, pet sitters, and caregivers.

## When to Use

- User needs a babysitter or nanny
- User wants to hire a housekeeper or cleaner
- User is looking for a tutor for their children
- User needs pet care (dog walker, pet sitter)
- User needs elder care or caregiver
- User wants to find any recurring household help

## Helper Categories

| Category | Examples | Typical Rate |
|----------|----------|-------------|
| Childcare | Babysitter, nanny, au pair | $15-30/hr |
| Education | Tutor, music teacher | $25-75/hr |
| Household | Housekeeper, cleaner | $25-50/hr |
| Pet Care | Dog walker, pet sitter | $15-25/visit |
| Elder Care | Caregiver, companion | $18-35/hr |

## Workflow Overview

```
1. Define Needs → 2. Search Candidates → 3. Screen & Interview 
→ 4. Trial Period → 5. Hire & Onboard
```

## Step 1: Define Requirements

**Gather detailed needs:**

### For Babysitters/Nannies:
```
👶 Childcare Search - Let me understand your needs:

1. 👧 Children: How many and what ages?
2. 📅 Schedule: What days/times do you need care?
   - Regular schedule or occasional?
   - After school? Evenings? Weekends?
3. 📍 Location: At your home or pickup needed?
4. 💰 Budget: What's your hourly rate range?
5. ✅ Must-haves:
   - CPR/First Aid certified?
   - Own transportation?
   - Experience with [infant/toddler/school-age]?
   - Any special needs experience?
6. 💕 Nice-to-haves:
   - Light housework?
   - Homework help?
   - Meal prep for kids?
   - Specific language?
```

### For Housekeepers:
```
🧹 Cleaning Help - Let me understand your needs:

1. 🏠 Home size: Approx square footage or rooms?
2. 📅 Frequency: Weekly, bi-weekly, monthly, one-time?
3. 📝 Scope:
   - Regular cleaning (dust, vacuum, mop, bathrooms)?
   - Deep cleaning (baseboards, inside appliances)?
   - Laundry?
   - Organization?
4. 💰 Budget: Per visit or hourly rate?
5. ✅ Requirements:
   - Bring own supplies?
   - Pet-friendly?
   - Eco-friendly products?
```

### For Tutors:
```
📚 Tutor Search - Let me understand your needs:

1. 🎓 Subject(s): What needs help?
2. 👦 Student: Age and grade level?
3. 🎯 Goal: Homework help, test prep, enrichment?
4. 📅 Schedule: How often and when?
5. 📍 Format: In-person or online?
6. 💰 Budget: Hourly rate range?
```

## Step 2: Search for Candidates

**Check if you have saved helpers:**
```bash
cat ~/clawd/homeos/data/providers.json 2>/dev/null | jq '.babysitter, .housekeeper, .tutor'
```

**Search platforms guidance:**
```
🔍 Where to Find [Helper Type]

🌟 TOP PLATFORMS:

1. Care.com - care.com
   • Largest network
   • Background checks available
   • Reviews and references
   • 💰 Subscription required for messaging

2. Sittercity - sittercity.com
   • Focus on childcare
   • Detailed profiles
   • 💰 Subscription for full access

3. UrbanSitter - urbansitter.com
   • Facebook connections for trust
   • Good for occasional sitters
   • Pay-per-booking option

4. Rover - rover.com (pets)
   • Dog walking, pet sitting
   • Insurance included
   • GPS tracking on walks

🏠 FREE OPTIONS:

5. Nextdoor - nextdoor.com
   • Neighbor recommendations
   • Local teens for babysitting
   • Free to post/search

6. Facebook Groups
   • "[Your City] Babysitters"
   • "Nannies of [Your Area]"
   • Free but less vetted

7. Local College Job Boards
   • Education majors for tutoring
   • Responsible students for sitting

Want me to help you write a job posting?
```

**Help write job posting:**
```
📝 JOB POSTING DRAFT

Title: [Part-time Babysitter / Housekeeper / Tutor] Needed in [Area]

[Friendly intro about your family]

We're looking for:
• [Key requirement 1]
• [Key requirement 2]
• [Key requirement 3]

Schedule: [Days/times]
Rate: $[X]-[Y]/hour [or competitive rate]
Location: [General area - not exact address yet]

Ideal candidate:
• [Quality 1]
• [Quality 2]
• [Experience preference]

Please include in your response:
• Your relevant experience
• Your availability
• References

We look forward to hearing from you!

---
Looks good? I can adjust anything.
```

## Step 3: Screening Candidates

**Initial screening checklist:**
```
✅ SCREENING CHECKLIST for [Candidate Name]

📝 PROFILE REVIEW:
☐ Experience matches your needs (years, type)
☐ Availability aligns with your schedule
☐ Rate within your budget
☐ Reviews are positive (read recent ones)
☐ Response is professional and timely

🚩 WATCH FOR RED FLAGS:
☐ Vague about experience
☐ Can't provide references
☐ Reluctant about background check
☐ Wants to communicate off-platform
☐ Inconsistent work history
☐ Pushy about meeting immediately
☐ Too good to be true
```

**Interview questions to ask:**

### For Babysitters:
```
📞 BABYSITTER INTERVIEW QUESTIONS

👤 Background:
1. "Tell me about your childcare experience."
2. "What ages have you worked with most?"
3. "Why do you enjoy working with children?"

🎯 Scenarios:
4. "What would you do if [child] wouldn't stop crying?"
5. "How would you handle a tantrum in public?"
6. "What if a child got hurt - scraped knee, bumped head?"
7. "What activities would you do with a [age] year old?"

💱 Practical:
8. "Are you CPR certified? When does it expire?"
9. "Do you have reliable transportation?"
10. "What's your availability like?"
11. "What's your rate? Are you flexible on [X]?"

📚 References:
12. "Can you provide 2-3 references from families you've worked with?"

📝 Listen for:
• Genuine enthusiasm about kids
• Specific examples, not vague answers
• Safety awareness
• Reliability indicators
```

### For Housekeepers:
```
📞 HOUSEKEEPER INTERVIEW QUESTIONS

👤 Background:
1. "How long have you been cleaning professionally?"
2. "What types of homes do you typically clean?"

🛠️ Process:
3. "Walk me through how you'd clean a bathroom/kitchen."
4. "Do you bring your own supplies or use mine?"
5. "How long would my home take? [describe size]"
6. "What products do you use? Any I should provide?"

💱 Practical:
7. "What's your rate for a home like mine?"
8. "What days/times are you available?"
9. "Do you have a cancellation policy?"
10. "Are you insured/bonded?"

📚 References:
11. "Can you provide references from current clients?"

📝 Listen for:
• Systematic approach
• Attention to detail
• Reliability and consistency
• Communication style
```

## Step 4: Background Checks

**Options for background checks:**
```
🔍 BACKGROUND CHECK OPTIONS

Level 1 - Basic ($20-30):
• Identity verification
• National criminal database
• Sex offender registry

Level 2 - Standard ($40-60):
• All of Level 1, plus:
• County criminal records
• SSN verification
• Address history

Level 3 - Comprehensive ($75-100):
• All of Level 2, plus:
• Driving record (MVR)
• Employment verification
• Credit check (if handling finances)

🎯 Recommended:
• Babysitters/Nannies: Level 2 minimum
• Housekeepers: Level 1-2
• Caregivers: Level 2-3

💻 Services:
• Care.com (included with membership)
• Checkr - checkr.com
• GoodHire - goodhire.com
• Sterling - sterlingcheck.com
```

**Reference check script:**
```
📞 REFERENCE CHECK SCRIPT

"Hi, I'm [Name]. [Candidate] gave your name as a reference - 
they're applying to be our [babysitter/housekeeper/etc.].
Do you have 5 minutes?"

Questions:
1. "How do you know [Candidate]?"
2. "How long did they work for you?"
3. "What were their responsibilities?"
4. "Were they reliable and punctual?"
5. "How were they with [kids/cleaning/teaching]?"
6. "Was there anything they struggled with?"
7. "Why did they leave?"
8. "Would you hire them again?"

📝 Document their responses for your records.
```

## Step 5: Trial Period

**Setting up a trial:**
```
📝 TRIAL ARRANGEMENT

Before committing to regular schedule, do a trial:

👶 Babysitter Trial:
• First session: Stay home (in another room)
• Second session: Short outing (1-2 hours)
• Third session: Full evening

🧹 Housekeeper Trial:
• First clean: Be home to show preferences
• Second clean: Check results thoroughly

📚 Tutor Trial:
• 2-3 sessions before committing monthly
• Check in with student after each

After trial, discuss:
• "How did you feel it went?"
• "Any concerns or questions?"
• "Ready to set up a regular schedule?"
```

## Step 6: Hire & Onboard

**Onboarding checklist:**

### For Babysitters:
```
📋 BABYSITTER ONBOARDING

Before First Solo Shift:
☐ House tour (exits, fire extinguisher, first aid)
☐ Kids' routines and rules
☐ Food/snacks allowed
☐ Screen time rules
☐ Bedtime routine
☐ Discipline approach
☐ Emergency contacts list
☐ Allergies/medications
☐ WiFi password
☐ Spare key/code arrangement

Provide In Writing:
☐ Your contact numbers
☐ Poison Control: 1-800-222-1222
☐ Pediatrician number
☐ Trusted neighbor contact
☐ Home address (for 911)
☐ Insurance card location
```

### For Housekeepers:
```
📋 HOUSEKEEPER ONBOARDING

☐ Walk through priorities for each room
☐ Show product storage / preferences
☐ Discuss "always do" vs "as needed" tasks
☐ Set up key/code access
☐ Alarm system instructions
☐ Pet handling (if applicable)
☐ Payment method and schedule
☐ Communication preference (text/app)
```

**Payment setup:**
```
💵 PAYMENT OPTIONS

✅ Recommended:
• Venmo - Easy, instant
• Zelle - Bank-to-bank, no fees
• Cash - Simple for occasional

📋 For Regular Employees:
• Consider payroll service (Care.com HomePay)
• Handles taxes, W-2s, insurance
• Required if paying $2,600+/year to one person

📅 Payment Schedule:
• Babysitters: End of each session
• Housekeepers: Per visit or bi-weekly
• Regular staff: Weekly or bi-weekly
```

**Save helper information:**
```bash
cat >> ~/clawd/homeos/data/providers.json << 'EOF'
{
  "CATEGORY": {
    "name": "NAME",
    "phone": "PHONE",
    "email": "EMAIL",
    "rate": HOURLY_RATE,
    "schedule": "REGULAR_SCHEDULE",
    "started": "DATE",
    "rating": 5,
    "notes": "NOTES",
    "emergency_contact": "THEIR_EMERGENCY"
  }
}
EOF
```

## Example Interaction

**User:** "I need to find a babysitter for Saturday nights"

**Assistant:**
```
👶 I'll help you find a Saturday night sitter!

A few questions:

1. 👧 Kids: How many and ages?
2. ⏰ Time: What hours typically? (e.g., 6pm-midnight)
3. 📅 Frequency: Every Saturday or occasional?
4. 💰 Rate: What's your budget? (Local average: $18-25/hr)
5. ✅ Requirements: CPR certified? Own car? 
```

**User:** "2 kids, ages 4 and 7. Every other Saturday 6pm-midnight. Budget $20-25/hour. CPR preferred."

**Assistant:**
```
Perfect! Here's my recommendation:

🔍 WHERE TO SEARCH:

1. UrbanSitter - Great for occasional/regular sitting
   urbansitter.com
   • Book vetted sitters quickly
   • See sitters your friends have used

2. Care.com - Largest pool of candidates
   care.com
   • Most options, detailed profiles
   • Background checks available

3. Nextdoor - Local recommendations
   • Post asking for sitter referrals
   • Neighbors vouch for local teens/adults

📝 I can draft a job post for you:

---
"Looking for Saturday Night Babysitter

Our family needs a responsible sitter for our 4 and 7 year old, 
every other Saturday evening (6pm-midnight).

We're looking for:
• Experience with young children
• CPR certified (preferred)
• Reliable transportation
• Fun, engaging personality

Kids are active and love games, crafts, and stories!

Rate: $20-25/hour based on experience
Location: [Your Area]

Please tell us about yourself and your childcare experience!"
---

Want me to adjust this, or shall I help you with interview questions once you find candidates?
```

## Safety Reminders

```
🚨 SAFETY FIRST

❗ Never share before meeting:
• Exact home address
• Your daily schedule/routine
• When house is empty
❗ First meeting:
• Meet in public place (coffee shop)
• Have another adult present at home interview
• Trust your instincts

❗ Background checks:
• Always for childcare
• Strongly recommended for home access

❗ References:
• Actually call them
• Ask specific questions
• 2-3 minimum
```
