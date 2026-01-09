---
name: home-maintenance
description: Schedule and manage home maintenance tasks with service provider coordination. Use when the user mentions home repairs, maintenance scheduling, finding contractors, HVAC service, plumbing issues, appliance repairs, or any home upkeep needs. Handles both routine maintenance and emergency situations.
---

# Home Maintenance Skill

Manage home maintenance scheduling, service provider search, and emergency reporting for all household repair and upkeep needs.

## When to Use

- User mentions needing repairs (plumbing, electrical, HVAC)
- User asks about home maintenance schedules
- User needs to find a contractor or handyman
- User reports an emergency (water leak, no heat, broken appliance)
- User wants to schedule routine maintenance
- User asks about home warranty claims

## Workflow Steps

### Step 1: Assess the Situation

Classify the maintenance need:

```typescript
interface MaintenanceRequest {
  category: MaintenanceCategory;
  urgency: 'emergency' | 'urgent' | 'routine' | 'preventive';
  description: string;
  location: string;           // Room/area of home
  symptoms: string[];
  photos?: string[];
  affectedSystems: string[];
}

type MaintenanceCategory =
  | 'plumbing'
  | 'electrical'
  | 'hvac'
  | 'appliance'
  | 'roofing'
  | 'landscaping'
  | 'pest_control'
  | 'cleaning'
  | 'general_handyman';
```

**Urgency Classification:**

| Level | Description | Response Time |
|-------|-------------|---------------|
| Emergency | Safety hazard, major damage | Immediate |
| Urgent | Significant inconvenience | Same day |
| Routine | Standard repair needed | Within week |
| Preventive | Scheduled maintenance | Flexible |

### Step 2: Emergency Handling

For emergencies, provide immediate guidance:

```typescript
interface EmergencyResponse {
  immediateActions: string[];    // What to do NOW
  safetyWarnings: string[];
  shutoffLocations: {
    water: string;
    gas: string;
    electrical: string;
  };
  emergencyContacts: Contact[];
  doNotDo: string[];             // Common mistakes to avoid
}
```

**Emergency Examples:**

**Water Leak:**
```
🚨 EMERGENCY: Water Leak

Immediate Actions:
1. Turn off water main (usually in basement or by meter)
2. Turn off water heater if leak is near
3. Move valuables away from water
4. Document damage with photos

⚠️ Do NOT:
- Use electrical appliances near water
- Ignore small leaks (they grow fast)

📞 I'm finding emergency plumbers now...
```

**Gas Smell:**
```
🚨 EMERGENCY: Gas Smell Detected

Immediate Actions:
1. Do NOT turn on/off any switches or appliances
2. Open windows and doors
3. Leave the house immediately
4. Call gas company from outside: [Number]
5. Call 911 if smell is strong

⚠️ Do NOT:
- Use phone inside the house
- Light any flames
- Start your car in garage

This is a life-safety emergency. Exit now.
```

### Step 3: Search Service Providers

Find qualified professionals:

```typescript
interface ProviderSearch {
  serviceType: string;
  location: string;
  radius: number;              // Miles
  filters: {
    rating: number;            // Minimum rating
    licensed: boolean;
    insured: boolean;
    availableNow?: boolean;
    acceptsWarranty?: boolean;
  };
  sortBy: 'rating' | 'distance' | 'price' | 'availability';
}

interface ServiceProvider {
  name: string;
  company: string;
  phone: string;
  rating: number;
  reviewCount: number;
  specialties: string[];
  availability: string;
  estimatedCost: {
    diagnostic: number;
    typical: { min: number; max: number };
  };
  credentials: {
    licensed: boolean;
    insured: boolean;
    bonded: boolean;
    licenseNumber?: string;
  };
  responseTime: string;
}
```

**Data Sources:**
- Yelp
- Google Business
- Angi (HomeAdvisor)
- Thumbtack
- Nextdoor recommendations

### Step 4: Present Options

Show provider options with comparison:

```
🔧 Found 3 Plumbers Available Today

1. ⭐ ABC Plumbing - 4.9★ (324 reviews)
   📍 2.3 miles | ⏱️ Can arrive in 2 hours
   💰 $89 service call + parts/labor
   ✅ Licensed, Insured, 30+ years

2. Quick Fix Plumbing - 4.7★ (156 reviews)
   📍 4.1 miles | ⏱️ Can arrive in 4 hours
   💰 $75 service call + parts/labor
   ✅ Licensed, Insured

3. Budget Plumber - 4.2★ (89 reviews)
   📍 5.5 miles | ⏱️ Tomorrow morning
   💰 $50 service call + parts/labor
   ✅ Licensed

[Call ABC Plumbing] [Compare All] [See More Options]
```

### Step 5: Schedule Service

Coordinate appointment:

```typescript
interface ServiceAppointment {
  provider: ServiceProvider;
  scheduledDate: Date;
  timeWindow: string;          // "8AM-12PM"
  serviceDescription: string;
  accessInstructions: string;  // Gate code, etc.
  estimatedDuration: number;
  estimatedCost: number;
  paymentMethod: string;
  confirmationNumber?: string;
}
```

**Scheduling Options:**
- Direct call via voice AI (HIGH risk, requires approval)
- Online booking through provider website
- Request callback

### Step 6: Track & Follow Up

Monitor service completion:

- Appointment reminders
- Provider arrival notification
- Service completion confirmation
- Invoice/receipt storage
- Satisfaction follow-up
- Schedule next maintenance

## Maintenance Categories

### Plumbing
- Leaks (faucet, pipe, toilet)
- Clogs (drain, toilet, sewer)
- Water heater issues
- Fixture installation
- Garbage disposal
- Water pressure problems

### Electrical
- Outlet/switch issues
- Circuit breaker problems
- Light fixture installation
- Ceiling fan installation
- Panel upgrades
- GFCI installation

### HVAC
- AC not cooling
- Heater not working
- Thermostat issues
- Filter replacement
- Duct cleaning
- System tune-ups

### Appliances
- Refrigerator
- Dishwasher
- Washer/dryer
- Oven/stove
- Microwave
- Garbage disposal

## Preventive Maintenance Schedule

```typescript
interface MaintenanceSchedule {
  monthly: MaintenanceTask[];
  quarterly: MaintenanceTask[];
  biannual: MaintenanceTask[];
  annual: MaintenanceTask[];
}
```

**Example Annual Schedule:**

| Month | Tasks |
|-------|-------|
| January | Check smoke detectors, inspect pipes for freezing |
| February | HVAC filter change |
| March | Spring HVAC tune-up, gutter cleaning |
| April | Check irrigation system |
| May | AC service, window screens |
| June | Pest inspection |
| July | Check attic ventilation |
| August | Back-to-school safety check |
| September | Fall HVAC tune-up |
| October | Winterize irrigation, clean gutters |
| November | Furnace inspection |
| December | Check holiday lighting safety |

## Example Interaction

**User**: "My AC stopped working and it's 95 degrees outside"

**Assistant**:
```
🌡️ AC Emergency - Let's get you cool fast!

Quick Checks (do these now):
1. ✓ Is the thermostat set to COOL and below room temp?
2. ✓ Check if circuit breaker tripped (flip off then on)
3. ✓ Is the outdoor unit running? (listen for fan)
4. ✓ Check if filter is clogged (replace if dirty)

Did any of these help? [Yes, fixed!] [No, still broken]
```

**User**: "No, still broken"

**Assistant**:
```
Let me find emergency AC repair services.

🔧 Available Now - AC Repair

1. ⭐ CoolTech HVAC - 4.8★ (412 reviews)
   📍 3.1 miles | ⏱️ 45 min away
   💰 $95 emergency call
   ✅ Same-day repair, Licensed

2. Arctic Air Services - 4.6★ (234 reviews)
   📍 5.2 miles | ⏱️ 1.5 hours
   💰 $85 emergency call
   ✅ EPA certified, Insured

In the meantime:
- Close blinds on sunny windows
- Use fans to circulate air
- Stay hydrated

[Call CoolTech Now] [See More Options] [I'll Handle It]
```

## Home Warranty Integration

If user has home warranty:
- Check coverage before searching providers
- Initiate claim process
- Track claim status
- Schedule warranty-assigned technician
- Document for reimbursement
