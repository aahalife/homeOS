---
name: hire-helper
description: Find and hire household help including babysitters, housekeepers, tutors, and caregivers. Use when the user needs to find childcare, cleaning services, tutoring, pet care, senior care, or any recurring household help. Handles search, screening, interviewing, and hiring.
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

| Category | Examples |
|----------|----------|
| Childcare | Babysitter, nanny, au pair |
| Education | Tutor, music teacher, language instructor |
| Household | Housekeeper, cleaner, organizer |
| Pet Care | Dog walker, pet sitter, groomer |
| Elder Care | Caregiver, companion, home health aide |
| Specialized | Personal chef, driver, errand runner |

## Workflow Steps

### Step 1: Define Requirements

Gather detailed needs:

```typescript
interface HelperRequirements {
  category: HelperCategory;
  frequency: 'one_time' | 'recurring';
  schedule: {
    daysNeeded: string[];
    hoursPerDay: number;
    preferredTimes: string;
    startDate: Date;
    endDate?: Date;
  };
  requirements: {
    experience: number;        // Years minimum
    certifications?: string[]; // CPR, teaching cert, etc.
    backgroundCheck: boolean;
    carRequired: boolean;
    languages?: string[];
    specialNeeds?: string[];
  };
  compensation: {
    type: 'hourly' | 'salary' | 'per_visit';
    rateRange: { min: number; max: number };
    benefits?: string[];
  };
  preferences: {
    ageRange?: { min: number; max: number };
    gender?: string;
    nonSmoker: boolean;
    petFriendly?: boolean;
  };
}
```

**For Childcare, also collect:**
```typescript
interface ChildcareRequirements {
  children: {
    age: number;
    specialNeeds?: string[];
    allergies?: string[];
  }[];
  duties: string[];           // Light housework, cooking, homework help
  transportation: boolean;    // School pickup/dropoff
}
```

### Step 2: Search Candidates

Search across platforms:

```typescript
interface CandidateSearch {
  platforms: string[];        // Care.com, Sittercity, Rover, local
  filters: HelperRequirements;
  radius: number;
  sortBy: 'rating' | 'experience' | 'rate' | 'reviews';
}

interface Candidate {
  id: string;
  name: string;
  photo?: string;
  rating: number;
  reviewCount: number;
  experience: number;
  hourlyRate: number;
  availability: string;
  bio: string;
  certifications: string[];
  backgroundCheckStatus: 'completed' | 'pending' | 'not_started';
  references: number;
  responseRate: number;
  highlights: string[];
}
```

**Search Platforms:**
- Care.com
- Sittercity
- Rover (pets)
- Urban Sitter
- Nextdoor
- Local Facebook groups
- University job boards

### Step 3: Screen Candidates

Initial screening criteria:

```typescript
interface ScreeningResult {
  candidate: Candidate;
  matchScore: number;         // 0-100
  strengths: string[];
  concerns: string[];
  questions: string[];        // Suggested interview questions
  redFlags: string[];
}
```

**Screening Factors:**
- Experience matches requirements
- Availability aligns with schedule
- Rate within budget
- Positive reviews and references
- Background check status
- Response time and communication

**Red Flags to Watch:**
- Inconsistent work history
- Reluctance for background check
- No verifiable references
- Pushy about advance payment
- Unwilling to do trial period
- Vague about qualifications

### Step 4: Contact & Initial Interview

Facilitate outreach:

```typescript
interface InitialContact {
  candidateId: string;
  messageTemplate: string;
  interviewQuestions: string[];
  payDiscussion: boolean;
  trialMention: boolean;
}
```

**Initial Message Template:**
```
Hi [Name],

I came across your profile on [Platform] and I'm looking for a
[babysitter/housekeeper/etc.] for [frequency].

Quick details:
- [Children's ages / home size / pet info]
- Schedule: [Days/times needed]
- Location: [General area]

Would you be available for a brief phone call to discuss further?

Thanks,
[User Name]
```

**Suggested Interview Questions:**

*For Babysitters:*
- What do you enjoy most about working with children?
- How would you handle [specific scenario]?
- What activities would you plan for the kids?
- Are you CPR/First Aid certified?

*For Housekeepers:*
- What cleaning products do you prefer/avoid?
- How do you prioritize tasks in a large home?
- Do you have experience with [specific needs]?
- What's your policy on supplies?

### Step 5: In-Person Interview

Schedule and prepare:

```typescript
interface InterviewSchedule {
  candidate: Candidate;
  date: Date;
  location: string;           // Home or public place
  duration: number;
  attendees: string[];
  agenda: string[];
  trialTask?: string;
}
```

**Interview Agenda:**
1. Introduction and tour (if at home)
2. Review experience and qualifications
3. Discuss specific scenarios
4. Explain expectations and duties
5. Trial activity (if applicable)
6. Discuss compensation and schedule
7. Answer candidate questions

### Step 6: Background Check

Coordinate verification:

```typescript
interface BackgroundCheck {
  type: 'basic' | 'comprehensive';
  checks: {
    criminal: boolean;
    sexOffender: boolean;
    driveRecord: boolean;
    creditCheck: boolean;
    identityVerification: boolean;
    employmentVerification: boolean;
  };
  provider: string;           // Checkr, GoodHire, etc.
  estimatedDays: number;
  cost: number;
}
```

**Background Check Options:**
- Basic: Identity, criminal, sex offender ($20-40)
- Comprehensive: All above + driving, employment ($50-100)

### Step 7: Make Offer & Onboard

Finalize hiring:

```typescript
interface HelperOffer {
  compensation: {
    rate: number;
    type: 'hourly' | 'weekly' | 'per_visit';
    paymentMethod: string;
    paySchedule: string;
  };
  schedule: {
    days: string[];
    hours: string;
    startDate: Date;
  };
  trial: {
    duration: string;         // "2 weeks"
    review: Date;
  };
  policies: {
    cancellation: string;
    sick: string;
    holiday: string;
    overtime: string;
  };
}
```

**Onboarding Checklist:**
- [ ] Emergency contact list
- [ ] House rules and expectations
- [ ] Access arrangements (keys, codes)
- [ ] Important information (allergies, routines)
- [ ] First day schedule
- [ ] Payment setup

## Safety Guidelines

### Interview Safety
- First meeting in public place (coffee shop)
- Have another adult present at home interview
- Trust your instincts
- Don't share full address until verified

### Reference Checks
- Call at least 2 references
- Ask specific questions about reliability
- Verify employment dates
- Ask "Would you hire them again?"

### Trial Period
- Start with short shifts
- Stay home (or nearby) for first few sessions
- Check in unexpectedly
- Get children's feedback

## Example Interaction

**User**: "I need to find a babysitter for Saturday nights"

**Assistant**:
```
I'll help you find a babysitter! Let me gather some details:

👶 Children & Schedule:
1. How many children and their ages?
2. What time on Saturdays (e.g., 6pm-11pm)?
3. How often? Every week or occasional?

💰 Preferences:
4. What's your budget per hour? (Local avg: $18-25/hr)
5. Any must-haves? (CPR certified, experience with infants, etc.)
```

**User**: "2 kids, ages 4 and 7. Every other Saturday, 6pm-midnight. $20-25/hour, CPR certified preferred"

**Assistant**:
```
Got it! Searching for babysitters...

👤 Top Matches Near You:

1. ⭐ Sarah M. - 4.9★ (47 reviews)
   $22/hr | CPR & First Aid certified
   5 years experience, Elementary teacher
   "Fantastic with my 5 and 8 year old!" - Recent review
   ✅ Background check completed

2. Emily K. - 4.8★ (32 reviews)
   $20/hr | CPR certified
   3 years experience, College student (Education major)
   "So creative with activities" - Recent review
   ✅ Background check completed

3. Jessica T. - 4.7★ (28 reviews)
   $25/hr | CPR, First Aid, Swim certified
   7 years experience, Former nanny
   "My kids ask for her every time" - Recent review
   ✅ Background check completed

All are available every other Saturday evening.

[Message Sarah] [See All Profiles] [Adjust Criteria]
```

## Ongoing Management

- Schedule tracking
- Payment reminders
- Review/feedback collection
- Backup finder for emergencies
- Annual rate review reminders
