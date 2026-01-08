# Home Maintenance Skill

Track and schedule home maintenance tasks, find service providers, and manage home inventory.

## Purpose

Help families stay on top of home maintenance by tracking schedules, finding qualified contractors, and managing emergency repairs.

## Prerequisites

- LLM API key
- Location services for provider search
- Calendar integration
- Optional: HomeAdvisor/Angi API

## Input Parameters

```typescript
interface HomeMaintenanceInput {
  workspaceId: string;
  action: 'get_schedule' | 'find_provider' | 'create_request' | 'report_emergency';
  details: MaintenanceDetails;
}

interface MaintenanceDetails {
  category?: string;           // "HVAC", "plumbing", "electrical", etc.
  urgency?: 'routine' | 'soon' | 'urgent' | 'emergency';
  description?: string;
  location?: string;           // Room or area
  preferredDates?: string[];
}
```

## Maintenance Schedule Sub-Skill

### Get Maintenance Schedule

**Risk Level: LOW**

Retrieve upcoming and overdue maintenance tasks.

```typescript
const getMaintenanceSchedule = async (workspaceId: string) => {
  // Standard home maintenance schedule
  const maintenanceItems = [
    { task: "Replace HVAC filter", frequency: "monthly", category: "HVAC" },
    { task: "Test smoke detectors", frequency: "monthly", category: "Safety" },
    { task: "Clean garbage disposal", frequency: "monthly", category: "Plumbing" },
    { task: "Check water heater", frequency: "quarterly", category: "Plumbing" },
    { task: "Clean dryer vent", frequency: "quarterly", category: "Appliances" },
    { task: "Inspect roof", frequency: "biannually", category: "Exterior" },
    { task: "HVAC service", frequency: "biannually", category: "HVAC" },
    { task: "Gutter cleaning", frequency: "biannually", category: "Exterior" },
    { task: "Chimney inspection", frequency: "annually", category: "Safety" },
    { task: "Septic pumping", frequency: "3-5 years", category: "Plumbing" }
  ];

  // Get last completion dates from memory
  const completionHistory = await memory.query({
    workspaceId,
    type: 'procedural',
    tags: ['maintenance', 'completed']
  });

  // Calculate due dates
  const schedule = maintenanceItems.map(item => {
    const lastDone = findLastCompletion(completionHistory, item.task);
    const nextDue = calculateNextDue(lastDone, item.frequency);
    const status = getStatus(nextDue);

    return {
      ...item,
      lastCompleted: lastDone,
      nextDue,
      status,  // 'overdue', 'due_soon', 'on_track'
      daysUntilDue: daysBetween(new Date(), nextDue)
    };
  });

  return {
    overdue: schedule.filter(s => s.status === 'overdue'),
    dueSoon: schedule.filter(s => s.status === 'due_soon'),
    onTrack: schedule.filter(s => s.status === 'on_track')
  };
};
```

## Find Service Provider Sub-Skill

### Search for Contractors

**Risk Level: LOW**

Find qualified service providers in the area.

```typescript
interface SearchProvidersInput {
  workspaceId: string;
  category: string;        // "plumber", "electrician", "HVAC"
  location: string;
  urgency: string;
  requirements?: string[]; // ["licensed", "insured", "24/7"]
}

const searchServiceProviders = async (input: SearchProvidersInput) => {
  // Search multiple sources
  const [googleResults, yelpResults] = await Promise.all([
    googlePlaces.search({
      query: `${input.category} near ${input.location}`,
      type: 'establishment'
    }),
    yelp.search({
      term: input.category,
      location: input.location,
      attributes: input.requirements
    })
  ]);

  // Combine and dedupe results
  const providers = mergeAndDedupeProviders(googleResults, yelpResults);

  // Score providers
  const scoredProviders = providers.map(provider => ({
    ...provider,
    score: calculateProviderScore(provider, {
      prioritizeRating: true,
      prioritizeReviews: true,
      prioritizeAvailability: input.urgency === 'urgent'
    })
  }));

  // Sort by score
  return scoredProviders.sort((a, b) => b.score - a.score);
};
```

### Provider Scoring

```typescript
const calculateProviderScore = (provider, preferences) => {
  let score = 0;

  // Base rating score (0-50 points)
  score += (provider.rating / 5) * 50;

  // Review count score (0-20 points)
  score += Math.min(provider.reviewCount / 100, 1) * 20;

  // Responsiveness (0-15 points)
  if (provider.respondsIn24h) score += 15;
  else if (provider.respondsIn48h) score += 10;

  // License/Insurance verification (0-15 points)
  if (provider.verified) score += 15;

  return score;
};
```

## Service Request Sub-Skill

### Create Service Request

**Risk Level: MEDIUM**

Create a request for service quotes.

```typescript
const createServiceRequest = async (input: {
  workspaceId: string;
  category: string;
  description: string;
  photos?: string[];
  preferredDates: string[];
  budget?: { min: number; max: number };
}) => {
  // Generate detailed description from photos if provided
  let enhancedDescription = input.description;

  if (input.photos?.length) {
    const photoAnalysis = await llm.vision({
      system: "Analyze these photos of a home maintenance issue. Describe what you see, potential causes, and severity.",
      images: input.photos
    });
    enhancedDescription = `${input.description}\n\nPhoto Analysis: ${photoAnalysis}`;
  }

  const request = {
    id: generateId(),
    workspaceId: input.workspaceId,
    category: input.category,
    description: enhancedDescription,
    photos: input.photos,
    preferredDates: input.preferredDates,
    budget: input.budget,
    status: 'pending_quotes',
    createdAt: new Date().toISOString()
  };

  await memory.store({
    workspaceId: input.workspaceId,
    type: 'procedural',
    content: JSON.stringify(request),
    tags: ['maintenance', 'request', input.category]
  });

  return request;
};
```

### Request Quotes

**Risk Level: HIGH - REQUIRES APPROVAL**

Contact service providers to request quotes.

```typescript
const requestQuotes = async (input: {
  workspaceId: string;
  requestId: string;
  providers: Provider[];
}) => {
  // Get request details
  const request = await getRequest(input.requestId);

  // Request approval before contacting providers
  const approved = await requestApproval({
    intent: `Request quotes from ${input.providers.length} ${request.category} providers`,
    toolName: 'maintenance.request_quotes',
    inputs: {
      providers: input.providers.map(p => p.name),
      description: request.description
    },
    riskLevel: 'medium'
  });

  if (!approved) {
    return { success: false, reason: 'User did not approve' };
  }

  // Send quote requests
  const quoteRequests = await Promise.all(
    input.providers.map(async provider => {
      try {
        const response = await sendQuoteRequest(provider, request);
        return { provider, status: 'sent', response };
      } catch (error) {
        return { provider, status: 'failed', error: error.message };
      }
    })
  );

  return {
    success: true,
    requestsSent: quoteRequests.filter(q => q.status === 'sent').length,
    requestsFailed: quoteRequests.filter(q => q.status === 'failed').length
  };
};
```

## Emergency Reporting Sub-Skill

### Report Emergency

**Risk Level: HIGH**

Handle urgent home emergencies with prioritized response.

```typescript
const reportEmergency = async (input: {
  workspaceId: string;
  type: 'water_leak' | 'gas_leak' | 'electrical' | 'no_heat' | 'no_ac' | 'security';
  description: string;
  severity: 'high' | 'critical';
}) => {
  // Emergency response guidance
  const emergencyGuidance = {
    water_leak: {
      immediate: "Turn off water main valve",
      location: "Usually near water meter or in basement",
      safetyTips: ["Don't touch electrical outlets near water", "Move valuables to dry area"]
    },
    gas_leak: {
      immediate: "Evacuate immediately, don't use switches",
      call: "Gas company emergency line or 911",
      safetyTips: ["Don't use phone inside", "Don't start car in garage"]
    },
    electrical: {
      immediate: "Turn off main breaker if safe",
      warning: "Don't touch anything wet or sparking",
      call: "Electrician or fire department if fire/smoke"
    }
  };

  // Get guidance for this emergency type
  const guidance = emergencyGuidance[input.type];

  // Find emergency service providers
  const providers = await searchServiceProviders({
    workspaceId: input.workspaceId,
    category: input.type.replace('_', ' '),
    location: await getUserLocation(input.workspaceId),
    urgency: 'emergency',
    requirements: ['24/7', 'emergency']
  });

  // Filter for 24/7 availability
  const emergencyProviders = providers.filter(p =>
    p.hours?.includes('24') || p.emergency === true
  );

  return {
    guidance,
    emergencyProviders: emergencyProviders.slice(0, 3),
    nextSteps: [
      `Follow immediate action: ${guidance.immediate}`,
      guidance.call ? `Call: ${guidance.call}` : null,
      "Document damage with photos for insurance"
    ].filter(Boolean)
  };
};
```

## Home Inventory Sub-Skill

**Risk Level: LOW**

Track home appliances and systems for maintenance scheduling.

```typescript
const getHomeInventory = async (workspaceId: string) => {
  const inventory = await memory.query({
    workspaceId,
    type: 'home_inventory',
    tags: ['appliances', 'systems']
  });

  return inventory.map(item => ({
    ...item,
    warrantyStatus: checkWarrantyStatus(item),
    maintenanceHistory: await getMaintenanceHistory(item.id),
    nextScheduledService: calculateNextService(item)
  }));
};

const addInventoryItem = async (input: {
  workspaceId: string;
  name: string;
  category: string;
  brand: string;
  model: string;
  purchaseDate: string;
  warrantyExpires?: string;
  location: string;
}) => {
  await memory.store({
    workspaceId: input.workspaceId,
    type: 'home_inventory',
    content: JSON.stringify(input),
    tags: ['appliances', input.category]
  });
};
```

## Error Handling

| Error | Recovery |
|-------|----------|
| No providers found | Expand search radius, suggest DIY resources |
| Provider not responding | Try next provider, mark as unresponsive |
| Emergency unhandled | Escalate to 911, provide safety guidance |

## Output

```typescript
interface MaintenanceOutput {
  success: boolean;
  schedule?: MaintenanceSchedule;
  providers?: Provider[];
  request?: ServiceRequest;
  emergency?: EmergencyResponse;
}
```

## Approval Requirements

| Action | Risk Level | Reason |
|--------|------------|--------|
| View schedule | LOW | Read-only |
| Search providers | LOW | Read-only |
| Create request | MEDIUM | Stores data |
| Request quotes | HIGH | External contact |
| Share address | HIGH | PII sharing |
