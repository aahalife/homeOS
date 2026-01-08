# Hire Helper Skill

Find and hire domestic help and service providers (babysitters, housekeepers, tutors, etc.).

## Purpose

Help families find, vet, and hire qualified domestic helpers with proper background checks and scheduling.

## Prerequisites

- LLM API key
- Care.com or Sittercity API (optional)
- Background check service integration
- Calendar integration

## Input Parameters

```typescript
interface HireHelperInput {
  workspaceId: string;
  helperType: 'babysitter' | 'nanny' | 'housekeeper' | 'tutor' | 'pet_sitter' | 'elder_care';
  requirements: {
    schedule: ScheduleRequirement;
    experience?: number;         // Years of experience
    certifications?: string[];   // ["CPR", "First Aid", "Teaching Cert"]
    languages?: string[];
    specialNeeds?: string[];     // ["infant care", "special needs", "pets"]
    transportation?: boolean;    // Has own transportation
  };
  location: string;
  budget?: { min: number; max: number; period: 'hourly' | 'weekly' | 'monthly' };
}

interface ScheduleRequirement {
  type: 'one_time' | 'recurring' | 'full_time' | 'part_time';
  dates?: string[];              // For one-time
  daysOfWeek?: string[];         // For recurring
  startTime: string;
  endTime: string;
}
```

## Step-by-Step Instructions

### Step 1: Define Job Requirements

**Risk Level: LOW**

Create a detailed job posting based on input.

```typescript
const createJobDescription = async (input: HireHelperInput) => {
  const jobPrompt = `Create a job posting for a ${input.helperType} position:

Requirements:
${JSON.stringify(input.requirements, null, 2)}

Location: ${input.location}
Budget: ${input.budget ? `$${input.budget.min}-${input.budget.max}/${input.budget.period}` : 'Negotiable'}

Generate:
{
  "title": "Job title",
  "description": "Detailed job description",
  "responsibilities": ["list", "of", "duties"],
  "requirements": ["must", "have", "qualifications"],
  "preferredQualifications": ["nice", "to", "have"],
  "schedule": "Schedule description",
  "compensation": "Pay range and structure"
}`;

  return await llm.complete({
    system: jobPrompt
  });
};
```

### Step 2: Search for Candidates

**Risk Level: LOW**

Search for qualified candidates across platforms.

```typescript
const searchCandidates = async (input: {
  workspaceId: string;
  helperType: string;
  location: string;
  requirements: Requirements;
}) => {
  // Search multiple platforms
  const searchParams = {
    category: input.helperType,
    location: input.location,
    radius: 15,  // miles
    filters: {
      experience: input.requirements.experience,
      certifications: input.requirements.certifications,
      availability: input.requirements.schedule
    }
  };

  // Note: In production, integrate with Care.com, Sittercity, etc.
  // For now, use LLM to generate mock candidates for planning

  const candidates = await platformSearch(searchParams);

  // Score and rank candidates
  const rankedCandidates = candidates.map(candidate => ({
    ...candidate,
    matchScore: calculateMatchScore(candidate, input.requirements),
    flags: identifyRedFlags(candidate)
  }));

  return rankedCandidates.sort((a, b) => b.matchScore - a.matchScore);
};
```

### Step 3: Initial Screening

**Risk Level: LOW**

Review candidate profiles and identify top prospects.

```typescript
const screenCandidates = async (candidates: Candidate[]) => {
  const screeningChecklist = [
    'Profile completeness',
    'Verification status',
    'Reviews and ratings',
    'Experience relevance',
    'Certification validity',
    'Response rate',
    'Availability match'
  ];

  const screened = candidates.map(candidate => {
    const scores = {};

    // Profile completeness (0-10)
    scores.profileComplete = calculateProfileCompleteness(candidate);

    // Verification status (0-10)
    scores.verified = candidate.verified ? 10 : 0;

    // Reviews (0-10)
    scores.reviews = Math.min(candidate.rating * 2, 10);

    // Experience match (0-10)
    scores.experience = calculateExperienceMatch(candidate);

    // Overall screening score
    const totalScore = Object.values(scores).reduce((a, b) => a + b, 0);

    return {
      ...candidate,
      screeningScores: scores,
      totalScore,
      recommendation: totalScore > 35 ? 'strong' : totalScore > 25 ? 'consider' : 'pass'
    };
  });

  return {
    strongCandidates: screened.filter(c => c.recommendation === 'strong'),
    considerCandidates: screened.filter(c => c.recommendation === 'consider'),
    passedCandidates: screened.filter(c => c.recommendation === 'pass')
  };
};
```

### Step 4: Contact Candidates

**Risk Level: HIGH - REQUIRES APPROVAL**

Reach out to top candidates.

```typescript
const contactCandidates = async (input: {
  workspaceId: string;
  candidates: Candidate[];
  jobDescription: JobDescription;
}) => {
  // Request approval before contacting
  const approved = await requestApproval({
    intent: `Contact ${input.candidates.length} ${input.helperType} candidates`,
    toolName: 'helpers.contact_candidates',
    inputs: {
      candidateNames: input.candidates.map(c => c.name),
      messagePreview: 'Hi, I saw your profile and think you might be a great fit...'
    },
    riskLevel: 'high'
  });

  if (!approved) {
    return { success: false, reason: 'User did not approve' };
  }

  // Generate personalized messages
  const messages = await Promise.all(
    input.candidates.map(async candidate => {
      const message = await generatePersonalizedMessage(candidate, input.jobDescription);
      return { candidate, message };
    })
  );

  // Send messages (platform-specific)
  const results = await Promise.all(
    messages.map(async ({ candidate, message }) => {
      try {
        await sendMessage(candidate.platform, candidate.id, message);
        return { candidate: candidate.name, status: 'sent' };
      } catch (error) {
        return { candidate: candidate.name, status: 'failed', error: error.message };
      }
    })
  );

  return { success: true, results };
};
```

### Step 5: Schedule Interviews

**Risk Level: MEDIUM**

Coordinate interview times with candidates.

```typescript
const scheduleInterviews = async (input: {
  workspaceId: string;
  userId: string;
  candidates: Candidate[];
  interviewType: 'phone' | 'video' | 'in_person';
}) => {
  // Get user availability
  const availability = await calendar.getAvailability(input.userId, {
    startDate: new Date(),
    endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    duration: 30  // 30 min interview slots
  });

  // Propose times to candidates
  const interviews = await Promise.all(
    input.candidates.map(async (candidate, index) => {
      const slot = availability[index];  // Assign different slots

      return {
        candidate,
        proposedTime: slot,
        type: input.interviewType,
        status: 'pending_confirmation'
      };
    })
  );

  // Create calendar holds
  for (const interview of interviews) {
    await calendar.createEvent({
      workspaceId: input.workspaceId,
      userId: input.userId,
      title: `Interview: ${interview.candidate.name} (${input.helperType})`,
      dateTime: interview.proposedTime.start,
      durationMinutes: 30,
      notes: `${interview.type} interview for ${input.helperType} position`
    });
  }

  return interviews;
};
```

### Step 6: Background Check

**Risk Level: HIGH - REQUIRES APPROVAL**

Run background checks on final candidates.

```typescript
const runBackgroundCheck = async (input: {
  workspaceId: string;
  candidate: Candidate;
  checkType: 'basic' | 'comprehensive';
}) => {
  // Request approval for background check
  const approved = await requestApproval({
    intent: `Run ${input.checkType} background check on ${input.candidate.name}`,
    toolName: 'helpers.background_check',
    inputs: {
      candidateName: input.candidate.name,
      checkType: input.checkType,
      estimatedCost: input.checkType === 'basic' ? 25 : 75
    },
    riskLevel: 'high'
  });

  if (!approved) {
    return { success: false, reason: 'User did not approve' };
  }

  // Background check components
  const checks = {
    basic: ['identity', 'ssn_trace', 'sex_offender'],
    comprehensive: [
      'identity', 'ssn_trace', 'sex_offender',
      'criminal_county', 'criminal_federal',
      'driving_record', 'employment_verification',
      'reference_check'
    ]
  };

  // Run checks (integrate with Checkr, GoodHire, etc.)
  const results = await backgroundCheckService.run({
    candidate: {
      name: input.candidate.name,
      email: input.candidate.email,
      consent: true  // Must have candidate consent
    },
    checks: checks[input.checkType]
  });

  return {
    success: true,
    status: results.status,  // 'clear', 'review', 'alert'
    summary: results.summary,
    fullReport: results.reportUrl  // Link to full report
  };
};
```

### Step 7: Make Offer

**Risk Level: HIGH - REQUIRES APPROVAL**

Extend a job offer to selected candidate.

```typescript
const makeOffer = async (input: {
  workspaceId: string;
  candidate: Candidate;
  offer: {
    rate: number;
    period: 'hourly' | 'weekly' | 'salary';
    schedule: Schedule;
    startDate: string;
    benefits?: string[];
    trialPeriod?: number;  // days
  };
}) => {
  // Generate offer letter
  const offerLetter = await generateOfferLetter(input);

  // Request approval
  const approved = await requestApproval({
    intent: `Make job offer to ${input.candidate.name}`,
    toolName: 'helpers.make_offer',
    inputs: {
      candidateName: input.candidate.name,
      rate: `$${input.offer.rate}/${input.offer.period}`,
      startDate: input.offer.startDate
    },
    riskLevel: 'high'
  });

  if (!approved) {
    return { success: false };
  }

  // Send offer
  await sendOffer(input.candidate, offerLetter);

  return {
    success: true,
    offerSent: true,
    nextSteps: [
      'Wait for candidate response',
      'Prepare onboarding materials',
      'Set up payment method'
    ]
  };
};
```

## Error Handling

| Error | Recovery |
|-------|----------|
| No candidates found | Expand search, adjust requirements |
| Candidate not responding | Send follow-up, try next candidate |
| Background check failed | Review details, consider alternatives |
| Schedule conflict | Propose alternative times |

## Output

```typescript
interface HireHelperOutput {
  success: boolean;
  candidates?: Candidate[];
  interviews?: Interview[];
  backgroundCheck?: BackgroundCheckResult;
  offer?: OfferResult;
}
```

## Approval Requirements

| Action | Risk Level | Reason |
|--------|------------|--------|
| Search candidates | LOW | Read-only |
| Contact candidates | HIGH | External communication |
| Schedule interviews | MEDIUM | Calendar changes |
| Background check | HIGH | Cost + sensitive data |
| Make offer | HIGH | Employment commitment |

## Safety Considerations

1. **Always verify references** - Contact at least 2 references
2. **Background checks required** - For any in-home help
3. **Trial period** - Start with 2-week trial
4. **Clear expectations** - Written job description and house rules
5. **Payment records** - Use platform or payroll service for documentation
