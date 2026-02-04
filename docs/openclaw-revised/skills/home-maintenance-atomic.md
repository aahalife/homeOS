# Home Maintenance Skill: Atomic Function Breakdown

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Implementation Ready

---

## 1. Skill Overview

The Home Maintenance skill provides emergency triage, safety protocols, contractor coordination, and preventive maintenance scheduling. It prioritizes life safety in emergencies and provides intelligent workflows for routine repairs.

### User Stories

1. **Emergency Response**: "My basement is flooding!" → Immediate safety guidance + emergency contractor dispatch
2. **Gas Leak**: "I smell gas" → Evacuate protocol + 911 call + utility company notification
3. **Electrical Fire**: "Smoke from outlet" → Do not use water + evacuate + call 911
4. **Routine Repair**: "AC not cooling" → Assess urgency + search contractors + schedule service
5. **Preventive Maintenance**: "When should I change my HVAC filter?" → Calendar reminder + supplies ordering
6. **Contractor Search**: "Find a plumber" → Search by location + ratings + availability
7. **Maintenance Calendar**: "What maintenance is due?" → Monthly/quarterly/annual task list

---

## 2. Atomic Functions (Swift Signatures)

### 2.1 Emergency Assessment

```swift
// Assess the severity level of a maintenance issue
func assessEmergencyLevel(
    issue: String,
    details: [String: Any],
    homeProfile: HomeProfile
) async -> EmergencyLevel

// Get specific emergency protocol for issue type
func getEmergencyProtocol(
    issueType: EmergencyType
) -> SafetyProtocol

// Check if immediate evacuation is required
func requiresEvacuation(
    emergencyLevel: EmergencyLevel,
    issueType: EmergencyType
) -> Bool

// Generate step-by-step safety instructions
func generateSafetyInstructions(
    protocol: SafetyProtocol,
    homeProfile: HomeProfile
) -> [SafetyStep]

// Assess environmental conditions (temperature, weather)
func assessEnvironmentalUrgency(
    issueType: EmergencyType,
    outsideTempF: Double,
    weatherConditions: WeatherConditions
) -> UrgencyModifier
```

### 2.2 Contractor Search & Coordination

```swift
// Search for service providers by type and location
func searchContractors(
    serviceType: ServiceType,
    location: CLLocation,
    radius: Double = 25.0 // miles
) async throws -> [ServiceProvider]

// Get saved contractors for this home
func getSavedContractors(
    homeId: UUID,
    serviceType: ServiceType? = nil
) async -> [ServiceProvider]

// Get contractor ratings from multiple sources
func aggregateContractorRatings(
    contractor: ServiceProvider
) async throws -> AggregatedRating

// Check contractor availability
func checkContractorAvailability(
    providerId: UUID,
    urgency: EmergencyLevel
) async throws -> AvailabilityInfo

// Initiate contact with contractor
func contactContractor(
    provider: ServiceProvider,
    issue: MaintenanceIssue,
    preferredMethod: ContactMethod // call, SMS, email
) async throws -> ContactResult

// Schedule service appointment
func scheduleServiceAppointment(
    provider: ServiceProvider,
    preferredDate: Date,
    issue: MaintenanceIssue
) async throws -> ServiceAppointment

// Save contractor to home profile
func saveContractor(
    homeId: UUID,
    provider: ServiceProvider,
    rating: Double?,
    notes: String?
) async throws -> Bool
```

### 2.3 Preventive Maintenance

```swift
// Get maintenance schedule for home
func getMaintenanceSchedule(
    homeId: UUID
) async -> [MaintenanceTask]

// Get tasks due in next N days
func getUpcomingMaintenanceTasks(
    homeId: UUID,
    daysAhead: Int = 30
) async -> [MaintenanceTask]

// Generate default maintenance calendar for home type
func generateDefaultMaintenanceCalendar(
    homeType: HomeType, // house, condo, apartment
    hvacType: HVACType?,
    hasChimney: Bool,
    hasWell: Bool,
    hasSeptic: Bool
) -> [MaintenanceTask]

// Mark maintenance task as completed
func completeMaintenanceTask(
    taskId: UUID,
    completionDate: Date,
    notes: String?,
    cost: Decimal?
) async throws -> Bool

// Create custom maintenance task
func createCustomMaintenanceTask(
    homeId: UUID,
    title: String,
    frequency: MaintenanceFrequency,
    nextDueDate: Date,
    notes: String?
) async throws -> MaintenanceTask

// Get supplies needed for maintenance task
func getMaintenanceSupplies(
    task: MaintenanceTask
) -> [MaintenanceSupply]
```

### 2.4 Repair History & Documentation

```swift
// Log completed repair
func logRepair(
    homeId: UUID,
    issueType: EmergencyType,
    provider: ServiceProvider?,
    date: Date,
    cost: Decimal,
    description: String,
    photoURLs: [URL]?
) async throws -> RepairRecord

// Get repair history for home
func getRepairHistory(
    homeId: UUID,
    issueType: EmergencyType? = nil,
    dateRange: DateInterval? = nil
) async -> [RepairRecord]

// Get average repair costs by type
func getAverageRepairCosts(
    homeId: UUID,
    issueType: EmergencyType
) async -> CostAnalysis

// Export repair history for insurance/sale
func exportRepairHistory(
    homeId: UUID,
    format: ExportFormat // PDF, CSV
) async throws -> URL
```

### 2.5 Home Profile Management

```swift
// Get home profile with utility locations
func getHomeProfile(
    homeId: UUID
) async -> HomeProfile

// Update utility shutoff locations
func updateShutoffLocations(
    homeId: UUID,
    shutoffInfo: ShutoffInfo
) async throws -> Bool

// Update HVAC specifications
func updateHVACInfo(
    homeId: UUID,
    hvacInfo: HVACInfo
) async throws -> Bool

// Store important home documents
func storeHomeDocument(
    homeId: UUID,
    documentType: DocumentType, // warranty, manual, inspection
    fileURL: URL,
    expirationDate: Date?
) async throws -> HomeDocument
```

### 2.6 Utility Functions

```swift
// Get current weather conditions
func getCurrentWeather(
    location: CLLocation
) async throws -> WeatherConditions

// Check if issue requires same-day service
func requiresSameDayService(
    issueType: EmergencyType,
    weather: WeatherConditions,
    timeOfDay: Date
) -> Bool

// Estimate repair cost range
func estimateRepairCost(
    issueType: EmergencyType,
    severity: EmergencyLevel,
    location: CLLocation
) async throws -> CostEstimate

// Generate contractor call script
func generateContractorCallScript(
    issue: MaintenanceIssue,
    urgency: EmergencyLevel
) -> String
```

---

## 3. Emergency Assessment Matrix

### Critical (Evacuate + Call 911)

| Issue | Trigger Keywords | Protocol | Response Time |
|-------|-----------------|----------|---------------|
| **Gas Leak** | "gas smell", "rotten egg", "propane leak" | Evacuate → Call 911 from outside → Do NOT use electronics → Do NOT operate switches | IMMEDIATE |
| **Electrical Fire** | "outlet sparking", "electrical fire", "burning smell from breaker" | Do NOT use water → Evacuate → Call 911 | IMMEDIATE |
| **Carbon Monoxide** | "CO detector", "carbon monoxide alarm" | Evacuate → Call 911 → Open windows if safe | IMMEDIATE |
| **Major Structural** | "ceiling collapse", "wall crack spreading", "floor sinking" | Evacuate → Call 911 → Document for insurance | IMMEDIATE |
| **Sewage Backup (Severe)** | "raw sewage in home", "toilet overflowing everywhere" | Evacuate contaminated areas → Call emergency plumber → Health risk | Same Hour |

### Urgent (Same Day Service)

| Issue | Conditions | Protocol | Response Time |
|-------|-----------|----------|---------------|
| **Major Water Leak** | Flooding, visible water damage | Shut main water valve → Call emergency plumber → Document damage | 1-2 Hours |
| **No Heat (Winter)** | Outside temp < 32°F | Check thermostat/breaker → Call HVAC → Risk of pipe freeze | 2-4 Hours |
| **No AC (Extreme Heat)** | Outside temp > 95°F, elderly/children present | Check breaker → Call HVAC → Heat exhaustion risk | 2-4 Hours |
| **Sump Pump Failure** | During rain/flooding | Backup pumping → Emergency plumber | 2-4 Hours |
| **Water Heater Leak** | Active leak, hot water | Shut off water + gas/electric → Call plumber | 4-6 Hours |

### Routine (Schedule Within 1-7 Days)

| Issue | Conditions | Protocol | Response Time |
|-------|-----------|----------|---------------|
| **AC Not Cooling** | Weather mild, no health risk | Check filter → Schedule HVAC technician | 1-3 Days |
| **Appliance Broken** | Dishwasher, dryer, washer not working | Troubleshoot → Schedule repair | 3-7 Days |
| **Minor Leak** | Dripping faucet, slow drain | DIY attempted → Schedule plumber | 3-7 Days |
| **Pest Issue** | Ants, mice (not infestation) | Traps/prevention → Schedule exterminator | 5-7 Days |

---

## 4. SAFETY-FIRST Emergency Protocols

### 4.1 Gas Leak Protocol

**CRITICAL: GAS LEAKS ARE LIFE-THREATENING**

```swift
struct GasLeakProtocol: SafetyProtocol {
    var steps: [SafetyStep] = [
        SafetyStep(
            order: 1,
            instruction: "DO NOT use any electronics, switches, or create sparks",
            criticalSafety: true,
            icon: "⚠️"
        ),
        SafetyStep(
            order: 2,
            instruction: "Evacuate everyone immediately - leave doors open",
            criticalSafety: true,
            icon: "🚶"
        ),
        SafetyStep(
            order: 3,
            instruction: "Once outside and at safe distance, call 911",
            criticalSafety: true,
            icon: "📞"
        ),
        SafetyStep(
            order: 4,
            instruction: "Call gas utility company emergency line: [Auto-fill based on location]",
            criticalSafety: true,
            icon: "🏢"
        ),
        SafetyStep(
            order: 5,
            instruction: "Do NOT re-enter until authorities declare safe",
            criticalSafety: true,
            icon: "🚫"
        )
    ]

    var lifeSafetyPriority: Int = 1
    var requiresEvacuation: Bool = true
    var callEmergencyServices: Bool = true
}
```

**User-Facing Message:**
```
🚨 GAS LEAK EMERGENCY 🚨

IMMEDIATE ACTIONS:
1. DO NOT touch light switches, phones, or any electronics
2. EVACUATE NOW - Leave doors open
3. Move to safe location (100+ feet away)
4. Call 911 from outside
5. Call gas company: [Number]

DO NOT RE-ENTER until fire department clears the scene.
Gas is explosive - every second counts.
```

### 4.2 Major Flood/Water Leak Protocol

```swift
struct FloodProtocol: SafetyProtocol {
    var steps: [SafetyStep] = [
        SafetyStep(
            order: 1,
            instruction: "If water near electrical outlets, shut off main breaker ONLY if safe to access",
            criticalSafety: true,
            icon: "⚡"
        ),
        SafetyStep(
            order: 2,
            instruction: "Shut off main water valve: [Show location from HomeProfile]",
            criticalSafety: true,
            icon: "🚰"
        ),
        SafetyStep(
            order: 3,
            instruction: "Move valuables to higher ground",
            criticalSafety: false,
            icon: "📦"
        ),
        SafetyStep(
            order: 4,
            instruction: "Take photos/video for insurance",
            criticalSafety: false,
            icon: "📸"
        ),
        SafetyStep(
            order: 5,
            instruction: "Calling emergency plumber...",
            criticalSafety: true,
            icon: "📞"
        )
    ]

    var lifeSafetyPriority: Int = 2
    var requiresEvacuation: Bool = false
    var callEmergencyServices: Bool = false
}
```

**Main Water Valve Location Prompt:**
```
💧 SHUT OFF MAIN WATER VALVE

Location: [If saved: "Basement, near water heater" | If not saved: "Usually in basement, crawlspace, or outside near foundation"]

[Show Diagram/Photo if available]

Turn valve clockwise until fully closed.
Can't find it? Call emergency plumber immediately: [Calling...]
```

### 4.3 Electrical Fire Protocol

```swift
struct ElectricalFireProtocol: SafetyProtocol {
    var steps: [SafetyStep] = [
        SafetyStep(
            order: 1,
            instruction: "DO NOT USE WATER - Electrocution risk",
            criticalSafety: true,
            icon: "⚠️"
        ),
        SafetyStep(
            order: 2,
            instruction: "If small: Use Class C fire extinguisher if available",
            criticalSafety: true,
            icon: "🧯"
        ),
        SafetyStep(
            order: 3,
            instruction: "If spreading: Evacuate immediately and call 911",
            criticalSafety: true,
            icon: "🚶"
        ),
        SafetyStep(
            order: 4,
            instruction: "Shut off main electrical breaker if safe to access",
            criticalSafety: true,
            icon: "⚡"
        ),
        SafetyStep(
            order: 5,
            instruction: "Do not re-enter until fire department clears",
            criticalSafety: true,
            icon: "🚫"
        )
    ]

    var lifeSafetyPriority: Int = 1
    var requiresEvacuation: Bool = true
    var callEmergencyServices: Bool = true
}
```

### 4.4 No Heat in Freezing Weather Protocol

```swift
struct FreezingNoHeatProtocol: SafetyProtocol {
    var steps: [SafetyStep] = [
        SafetyStep(
            order: 1,
            instruction: "Check thermostat - ensure it's set above current temp and on 'Heat' mode",
            criticalSafety: false,
            icon: "🌡️"
        ),
        SafetyStep(
            order: 2,
            instruction: "Check circuit breaker for furnace - may have tripped",
            criticalSafety: false,
            icon: "⚡"
        ),
        SafetyStep(
            order: 3,
            instruction: "Open cabinet doors under sinks to prevent pipe freeze",
            criticalSafety: true,
            icon: "🚰"
        ),
        SafetyStep(
            order: 4,
            instruction: "Let faucets drip slowly to keep water moving",
            criticalSafety: true,
            icon: "💧"
        ),
        SafetyStep(
            order: 5,
            instruction: "Close off unused rooms, use space heaters safely",
            criticalSafety: true,
            icon: "🔥"
        ),
        SafetyStep(
            order: 6,
            instruction: "Calling emergency HVAC technician...",
            criticalSafety: true,
            icon: "📞"
        )
    ]

    var lifeSafetyPriority: Int = 3
    var requiresEvacuation: Bool = false
    var callEmergencyServices: Bool = false
    var urgencyNote: String = "Risk of frozen pipes causing major damage"
}
```

### 4.5 Carbon Monoxide Alarm Protocol

```swift
struct CarbonMonoxideProtocol: SafetyProtocol {
    var steps: [SafetyStep] = [
        SafetyStep(
            order: 1,
            instruction: "EVACUATE IMMEDIATELY - CO is odorless and deadly",
            criticalSafety: true,
            icon: "🚨"
        ),
        SafetyStep(
            order: 2,
            instruction: "Call 911 from outside - report CO alarm",
            criticalSafety: true,
            icon: "📞"
        ),
        SafetyStep(
            order: 3,
            instruction: "If safe, open windows while evacuating",
            criticalSafety: true,
            icon: "🪟"
        ),
        SafetyStep(
            order: 4,
            instruction: "Do NOT re-enter until fire department tests and clears",
            criticalSafety: true,
            icon: "🚫"
        ),
        SafetyStep(
            order: 5,
            instruction: "Seek medical attention if experiencing: headache, dizziness, nausea",
            criticalSafety: true,
            icon: "🏥"
        )
    ]

    var lifeSafetyPriority: Int = 1
    var requiresEvacuation: Bool = true
    var callEmergencyServices: Bool = true
}
```

---

## 5. Contractor Search & Coordination Workflows

### 5.1 Search Strategy (Tiered Approach)

```swift
func searchContractorsWithFallback(
    serviceType: ServiceType,
    location: CLLocation,
    urgency: EmergencyLevel
) async throws -> [ServiceProvider] {

    var allProviders: [ServiceProvider] = []

    // Tier 1: Saved/Previously Used Contractors
    let savedContractors = await getSavedContractors(
        homeId: currentHome.id,
        serviceType: serviceType
    )
    allProviders.append(contentsOf: savedContractors)

    // Tier 2: Google Places API (most coverage)
    do {
        let googleResults = try await GooglePlacesAPI.search(
            query: "\(serviceType.rawValue) near me",
            location: location,
            radius: urgency == .emergency ? 50 : 25 // Expand radius for emergencies
        )
        allProviders.append(contentsOf: googleResults)
    } catch {
        print("Google Places failed: \(error)")
    }

    // Tier 3: Yelp Fusion API
    do {
        let yelpResults = try await YelpAPI.search(
            categories: serviceType.yelpCategory,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radius: Int(urgency == .emergency ? 40000 : 20000) // meters
        )
        allProviders.append(contentsOf: yelpResults)
    } catch {
        print("Yelp failed: \(error)")
    }

    // Tier 4: Angi (formerly Angie's List)
    do {
        let angiResults = try await AngiAPI.search(
            serviceType: serviceType,
            zipCode: await getZipCode(from: location)
        )
        allProviders.append(contentsOf: angiResults)
    } catch {
        print("Angi failed: \(error)")
    }

    // Deduplicate and sort
    let uniqueProviders = Dictionary(grouping: allProviders, by: { $0.phone })
        .compactMap { $0.value.first }

    return rankProviders(
        providers: uniqueProviders,
        urgency: urgency
    )
}
```

### 5.2 Contractor Ranking Algorithm

```swift
func rankProviders(
    providers: [ServiceProvider],
    urgency: EmergencyLevel
) -> [ServiceProvider] {

    return providers.sorted { provider1, provider2 in
        let score1 = calculateProviderScore(provider1, urgency: urgency)
        let score2 = calculateProviderScore(provider2, urgency: urgency)
        return score1 > score2
    }
}

func calculateProviderScore(
    _ provider: ServiceProvider,
    urgency: EmergencyLevel
) -> Double {
    var score: Double = 0.0

    // Previously used = highest trust
    if provider.lastUsed != nil {
        score += 50.0
    }

    // Rating weight (0-25 points)
    if let rating = provider.rating {
        score += (rating / 5.0) * 25.0
    }

    // Review count (0-15 points, caps at 100 reviews)
    if let reviewCount = provider.reviewCount {
        score += min(Double(reviewCount) / 100.0, 1.0) * 15.0
    }

    // Emergency availability (0-10 points)
    if urgency == .emergency || urgency == .urgent {
        if provider.offers24HourService {
            score += 10.0
        }
    }

    // Proximity bonus (0-10 points, within 10 miles)
    if let distance = provider.distanceFromHome {
        if distance < 10.0 {
            score += (10.0 - distance) // Closer = better
        }
    }

    return score
}
```

### 5.3 Automated Contractor Contact

```swift
func contactContractor(
    provider: ServiceProvider,
    issue: MaintenanceIssue,
    preferredMethod: ContactMethod
) async throws -> ContactResult {

    let script = generateContractorCallScript(
        issue: issue,
        urgency: issue.emergencyLevel
    )

    switch preferredMethod {
    case .call:
        // Use Twilio to make call with pre-recorded message
        return try await TwilioAPI.makeCall(
            to: provider.phone,
            script: script,
            requestCallback: true
        )

    case .sms:
        return try await TwilioAPI.sendSMS(
            to: provider.phone,
            message: script
        )

    case .email:
        return try await sendEmail(
            to: provider.email,
            subject: "Urgent: \(issue.title)",
            body: script
        )
    }
}

func generateContractorCallScript(
    issue: MaintenanceIssue,
    urgency: EmergencyLevel
) -> String {
    let urgencyPrefix = urgency == .emergency || urgency == .urgent
        ? "URGENT - "
        : ""

    return """
    \(urgencyPrefix)\(issue.title)

    Address: \(currentHome.address)
    Issue: \(issue.description)
    Urgency: \(urgency.displayName)

    Contact: \(currentUser.name)
    Phone: \(currentUser.phone)

    Please call back as soon as possible to schedule service.

    Sent via OpenClaw Home Maintenance
    """
}
```

---

## 6. Preventive Maintenance Calendar

### 6.1 Monthly Tasks

```swift
let monthlyTasks: [MaintenanceTask] = [
    MaintenanceTask(
        id: UUID(),
        title: "Check HVAC Filter",
        description: "Inspect and replace if dirty. 1-inch filters monthly, 4-inch filters quarterly.",
        frequency: .monthly,
        category: .hvac,
        estimatedTime: 5, // minutes
        supplies: [
            MaintenanceSupply(name: "HVAC Filter", size: "16x25x1", cost: 15.00)
        ],
        diyFriendly: true,
        instructionsURL: URL(string: "https://www.energy.gov/energysaver/maintaining-your-air-conditioner")
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Test Smoke & CO Detectors",
        description: "Press test button on each detector. Replace batteries if low.",
        frequency: .monthly,
        category: .safety,
        estimatedTime: 10,
        supplies: [
            MaintenanceSupply(name: "9V Batteries", quantity: 6, cost: 12.00)
        ],
        diyFriendly: true,
        criticalSafety: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Check Plumbing for Leaks",
        description: "Inspect under sinks, around toilets, water heater for moisture or drips.",
        frequency: .monthly,
        category: .plumbing,
        estimatedTime: 15,
        diyFriendly: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Clean Garbage Disposal",
        description: "Run ice cubes and citrus peels to clean and deodorize.",
        frequency: .monthly,
        category: .appliances,
        estimatedTime: 5,
        diyFriendly: true
    )
]
```

### 6.2 Quarterly Tasks

```swift
let quarterlyTasks: [MaintenanceTask] = [
    MaintenanceTask(
        id: UUID(),
        title: "Clean Dryer Vent",
        description: "Remove lint from vent hose and outside exhaust. Fire hazard if neglected.",
        frequency: .quarterly,
        category: .appliances,
        estimatedTime: 30,
        supplies: [
            MaintenanceSupply(name: "Dryer Vent Brush", cost: 15.00)
        ],
        diyFriendly: true,
        criticalSafety: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Test Garage Door Safety Features",
        description: "Test auto-reverse by placing object under door.",
        frequency: .quarterly,
        category: .safety,
        estimatedTime: 10,
        diyFriendly: true,
        criticalSafety: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Clean Refrigerator Coils",
        description: "Vacuum coils on back or bottom to improve efficiency.",
        frequency: .quarterly,
        category: .appliances,
        estimatedTime: 20,
        diyFriendly: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Check Caulking Around Tubs/Showers",
        description: "Re-caulk any cracked or missing areas to prevent water damage.",
        frequency: .quarterly,
        category: .plumbing,
        estimatedTime: 45,
        supplies: [
            MaintenanceSupply(name: "Silicone Caulk", cost: 8.00)
        ],
        diyFriendly: true
    )
]
```

### 6.3 Semi-Annual Tasks

```swift
let semiAnnualTasks: [MaintenanceTask] = [
    MaintenanceTask(
        id: UUID(),
        title: "HVAC Tune-Up (Spring)",
        description: "Professional AC inspection and cleaning before cooling season.",
        frequency: .semiAnnual,
        season: .spring,
        category: .hvac,
        estimatedTime: 90,
        estimatedCost: 125.00,
        diyFriendly: false,
        requiresProfessional: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Furnace Inspection (Fall)",
        description: "Professional furnace check before heating season.",
        frequency: .semiAnnual,
        season: .fall,
        category: .hvac,
        estimatedTime: 90,
        estimatedCost: 125.00,
        diyFriendly: false,
        requiresProfessional: true,
        criticalSafety: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Clean Gutters",
        description: "Remove leaves and debris. Check downspouts drain properly.",
        frequency: .semiAnnual,
        category: .exterior,
        estimatedTime: 120,
        supplies: [
            MaintenanceSupply(name: "Gutter Scoop", cost: 12.00)
        ],
        diyFriendly: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Test Sump Pump",
        description: "Pour water into pit to ensure pump activates properly.",
        frequency: .semiAnnual,
        season: .spring,
        category: .plumbing,
        estimatedTime: 15,
        diyFriendly: true
    )
]
```

### 6.4 Annual Tasks

```swift
let annualTasks: [MaintenanceTask] = [
    MaintenanceTask(
        id: UUID(),
        title: "Chimney Inspection",
        description: "Professional inspection for creosote buildup and structural issues.",
        frequency: .annual,
        category: .safety,
        estimatedTime: 120,
        estimatedCost: 150.00,
        diyFriendly: false,
        requiresProfessional: true,
        criticalSafety: true,
        applicableIf: { home in home.hasChimney }
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Water Heater Flush",
        description: "Drain sediment from tank to improve efficiency and lifespan.",
        frequency: .annual,
        category: .plumbing,
        estimatedTime: 60,
        diyFriendly: true,
        instructionsURL: URL(string: "https://www.energy.gov/energysaver/tankless-or-demand-type-water-heaters")
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Septic System Inspection",
        description: "Professional inspection and pumping if needed (typically every 3-5 years).",
        frequency: .annual,
        category: .plumbing,
        estimatedTime: 90,
        estimatedCost: 400.00,
        diyFriendly: false,
        requiresProfessional: true,
        applicableIf: { home in home.hasSeptic }
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Pressure Wash Exterior",
        description: "Clean siding, deck, driveway to prevent mold and deterioration.",
        frequency: .annual,
        category: .exterior,
        estimatedTime: 240,
        supplies: [
            MaintenanceSupply(name: "Pressure Washer Rental", cost: 100.00)
        ],
        diyFriendly: true
    ),

    MaintenanceTask(
        id: UUID(),
        title: "Check Roof Condition",
        description: "Inspect for missing/damaged shingles, flashing issues.",
        frequency: .annual,
        category: .exterior,
        estimatedTime: 45,
        diyFriendly: false,
        requiresProfessional: true
    )
]
```

---

## 7. Example Scenarios

### Scenario 1: Gas Leak Emergency

**User Input:** "I smell gas in my house"

**System Flow:**
```
1. assessEmergencyLevel() → .emergency
2. getEmergencyProtocol(.gasLeak) → GasLeakProtocol
3. requiresEvacuation() → true
4. Display CRITICAL SAFETY INSTRUCTIONS (red screen)
5. Auto-dial 911 (requires user confirmation)
6. Get gas utility emergency number by location
7. Log emergency event
```

**User-Facing Response:**
```
🚨 GAS LEAK EMERGENCY 🚨

STOP READING - ACT NOW:

1. DO NOT touch any switches or electronics
2. EVACUATE IMMEDIATELY
3. Call 911 from outside: [CALL NOW]
4. Call gas company: (555) 123-4567 [CALL]

Gas is explosive. Every second matters.
DO NOT re-enter until authorities clear the scene.
```

### Scenario 2: Basement Flooding (Major Leak)

**User Input:** "My basement is flooding! Water everywhere!"

**System Flow:**
```
1. assessEmergencyLevel() → .urgent
2. getEmergencyProtocol(.majorWaterLeak) → FloodProtocol
3. generateSafetyInstructions() with home-specific valve location
4. searchContractors(serviceType: .plumber, urgency: .urgent)
5. contactContractor() with emergency message
6. Create insurance documentation checklist
```

**User-Facing Response:**
```
💧 MAJOR WATER LEAK - ACT FAST

IMMEDIATE STEPS:
1. ⚡ If water near outlets, shut main breaker (if safe)
2. 🚰 SHUT MAIN WATER VALVE
   Location: Basement, near water heater [Show Photo]
   Turn clockwise until fully closed

3. 📸 Take photos for insurance
4. 📞 Calling emergency plumber...

Finding 24-hour plumbers near you...

[List of 3 contractors with ratings, call buttons]

Water damage increases every minute - acting now!
```

### Scenario 3: AC Not Working (Routine)

**User Input:** "My AC isn't cooling, it's getting warm"

**System Flow:**
```
1. assessEmergencyLevel() → .routine (unless extreme heat)
2. getCurrentWeather() → Check outside temp
3. If temp < 85°F → Routine troubleshooting
4. If temp > 95°F with vulnerable people → Upgrade to .urgent
5. Provide DIY troubleshooting steps
6. searchContractors(serviceType: .hvac)
```

**User-Facing Response:**
```
🌡️ AC Not Cooling - Let's troubleshoot

Current outside temp: 78°F (Routine urgency)

TRY THESE FIRST:
☐ Check thermostat is set to COOL and temp below current
☐ Check circuit breaker for AC hasn't tripped
☐ Check air filter - replace if dirty/clogged
☐ Ensure outside unit is running and not blocked

Still not working?

HVAC Technicians Near You:
1. ⭐ Cool Air Pros - 4.8★ (203 reviews)
   Last used: March 2025 ✓
   Distance: 3.2 miles
   Available: Tomorrow
   [CALL] [SCHEDULE]

2. Arctic Comfort HVAC - 4.6★ (89 reviews)
   Distance: 5.1 miles
   Available: Next day
   [CALL] [SCHEDULE]

Estimated cost: $75-150 for diagnosis
```

### Scenario 4: Preventive Maintenance Check-In

**User Input:** "What home maintenance is due this month?"

**System Flow:**
```
1. getUpcomingMaintenanceTasks(daysAhead: 30)
2. Group by urgency (overdue, due this week, due this month)
3. Highlight critical safety tasks
4. Provide supplies list
```

**User-Facing Response:**
```
🏠 Home Maintenance Due

OVERDUE (2 tasks):
⚠️ Test Smoke Detectors (Due Jan 15)
   Takes 10 min | DIY-friendly
   Safety Critical ⚠️
   [MARK COMPLETE] [INSTRUCTIONS]

📅 Check HVAC Filter (Due Jan 20)
   Takes 5 min | Need: 16x25x1 filter ($15)
   [MARK COMPLETE] [BUY FILTER]

DUE THIS WEEK:
🔧 Clean Garbage Disposal (Due Feb 5)
   Takes 5 min | Use ice + citrus
   [MARK COMPLETE]

DUE THIS MONTH:
🚿 Check Plumbing for Leaks (Due Feb 28)
   Takes 15 min
   [SCHEDULE REMINDER]

[VIEW FULL CALENDAR] [ADD CUSTOM TASK]
```

### Scenario 5: Finding Contractor for New Issue

**User Input:** "I need an electrician, my outlet isn't working"

**System Flow:**
```
1. assessEmergencyLevel() → .routine
2. Ask clarifying questions (sparking? burning smell?)
3. searchContractors(serviceType: .electrician)
4. Present options sorted by saved/rating/distance
```

**User-Facing Response:**
```
⚡ Need Electrician - Outlet Not Working

Quick Safety Check:
• Any sparking or burning smell? → No
• Other outlets in room working? → Yes

Assessment: Routine repair (likely tripped breaker/bad outlet)

Electricians Near You:
1. ⭐ Bright Spark Electric - 4.9★ (156 reviews)
   You used them before ✓
   Notes: "Fast, fair pricing"
   Distance: 4.1 miles
   [CALL] [SCHEDULE]

2. Power Pro Electrical - 4.7★ (92 reviews)
   24-hour emergency service
   Distance: 6.3 miles
   [CALL] [SCHEDULE]

3. Hometown Electrical - 4.5★ (67 reviews)
   Distance: 8.2 miles
   [CALL] [SCHEDULE]

Estimated cost: $100-200 for outlet replacement

[SHOW MORE] [SAVE FOR LATER]
```

---

## 8. Data Structures

### 8.1 Core Models

```swift
// Emergency level classification
enum EmergencyLevel: String, Codable {
    case routine      // Schedule within week
    case urgent       // Same day service
    case critical     // Within hours
    case emergency    // Immediate (911/evacuation)
}

// Types of maintenance issues
enum EmergencyType: String, Codable {
    case gasLeak
    case electricalFire
    case carbonMonoxide
    case majorWaterLeak
    case minorLeak
    case noHeat
    case noAC
    case hvacNotWorking
    case applianceBroken
    case plumbingClog
    case sewageBackup
    case roofLeak
    case structuralDamage
    case pestInfestation
    case lockout
    case other

    var defaultServiceType: ServiceType {
        switch self {
        case .gasLeak: return .plumber
        case .electricalFire, .other: return .electrician
        case .majorWaterLeak, .minorLeak, .plumbingClog, .sewageBackup: return .plumber
        case .noHeat, .noAC, .hvacNotWorking: return .hvac
        case .applianceBroken: return .appliance
        case .roofLeak: return .roofing
        case .structuralDamage: return .general
        case .pestInfestation: return .pest
        case .carbonMonoxide: return .hvac
        case .lockout: return .locksmith
        }
    }
}

// Service provider types
enum ServiceType: String, Codable {
    case plumber
    case electrician
    case hvac
    case appliance
    case roofing
    case general
    case landscaping
    case pest
    case locksmith
    case carpenter
    case painter

    var yelpCategory: String {
        switch self {
        case .plumber: return "plumbing"
        case .electrician: return "electricians"
        case .hvac: return "hvac"
        case .appliance: return "appliancerepair"
        case .roofing: return "roofing"
        case .general: return "handyman"
        case .landscaping: return "landscaping"
        case .pest: return "pestcontrol"
        case .locksmith: return "locksmiths"
        case .carpenter: return "carpenters"
        case .painter: return "painters"
        }
    }
}

// Maintenance issue details
struct MaintenanceIssue: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var issueType: EmergencyType
    var emergencyLevel: EmergencyLevel
    var reportedDate: Date
    var photoURLs: [URL]?
    var location: String? // "Basement", "Master bathroom", etc.
    var resolution: ResolutionStatus
}

enum ResolutionStatus: String, Codable {
    case open
    case contractorContacted
    case scheduled
    case inProgress
    case resolved
    case cancelled
}

// Service provider information
struct ServiceProvider: Codable, Identifiable {
    var id: UUID
    var name: String
    var serviceType: ServiceType
    var phone: String
    var email: String?
    var address: String?
    var website: URL?
    var rating: Double?
    var reviewCount: Int?
    var distanceFromHome: Double? // miles
    var offers24HourService: Bool
    var lastUsed: Date?
    var userNotes: String?
    var source: ProviderSource // saved, google, yelp, angi
}

enum ProviderSource: String, Codable {
    case saved
    case google
    case yelp
    case angi
    case referral
}

// Home profile
struct HomeProfile: Codable, Identifiable {
    var id: UUID
    var address: String
    var homeType: HomeType
    var squareFeet: Int?
    var yearBuilt: Int?
    var shutoffLocations: ShutoffInfo
    var hvacInfo: HVACInfo?
    var hasChimney: Bool
    var hasWell: Bool
    var hasSeptic: Bool
    var contractors: [ServiceProvider]
    var maintenanceSchedule: [MaintenanceTask]
    var repairHistory: [RepairRecord]
    var documents: [HomeDocument]
}

enum HomeType: String, Codable {
    case singleFamily
    case condo
    case townhouse
    case apartment
    case mobileHome
}

// Utility shutoff information
struct ShutoffInfo: Codable {
    var mainWaterValve: ValveLocation?
    var mainElectricalBreaker: ValveLocation?
    var gasShutoff: ValveLocation?
    var sewerCleanout: ValveLocation?
}

struct ValveLocation: Codable {
    var location: String // "Basement near water heater"
    var photoURL: URL?
    var instructions: String?
}

// HVAC system information
struct HVACInfo: Codable {
    var systemType: HVACType
    var brand: String?
    var modelNumber: String?
    var installDate: Date?
    var filterSize: String? // "16x25x1"
    var lastServiceDate: Date?
}

enum HVACType: String, Codable {
    case centralAir
    case heatPump
    case furnace
    case boiler
    case ductless
    case geothermal
}

// Maintenance task
struct MaintenanceTask: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var frequency: MaintenanceFrequency
    var season: Season?
    var category: MaintenanceCategory
    var estimatedTime: Int // minutes
    var estimatedCost: Decimal?
    var supplies: [MaintenanceSupply]?
    var diyFriendly: Bool
    var requiresProfessional: Bool
    var criticalSafety: Bool
    var nextDueDate: Date
    var lastCompletedDate: Date?
    var instructionsURL: URL?
    var applicableIf: ((HomeProfile) -> Bool)?
}

enum MaintenanceFrequency: String, Codable {
    case monthly
    case quarterly
    case semiAnnual
    case annual
    case custom
}

enum Season: String, Codable {
    case spring, summer, fall, winter
}

enum MaintenanceCategory: String, Codable {
    case hvac
    case plumbing
    case electrical
    case appliances
    case exterior
    case interior
    case safety
    case landscaping
}

// Maintenance supplies
struct MaintenanceSupply: Codable {
    var name: String
    var size: String?
    var quantity: Int?
    var cost: Decimal
    var purchaseURL: URL?
}

// Repair record
struct RepairRecord: Codable, Identifiable {
    var id: UUID
    var homeId: UUID
    var issueType: EmergencyType
    var provider: ServiceProvider?
    var date: Date
    var cost: Decimal
    var description: String
    var photoURLs: [URL]?
    var warrantyExpiration: Date?
    var invoiceURL: URL?
}

// Safety protocol
protocol SafetyProtocol {
    var steps: [SafetyStep] { get }
    var lifeSafetyPriority: Int { get } // 1 = highest
    var requiresEvacuation: Bool { get }
    var callEmergencyServices: Bool { get }
}

struct SafetyStep: Codable {
    var order: Int
    var instruction: String
    var criticalSafety: Bool
    var icon: String
    var completedAt: Date?
}

// Weather conditions
struct WeatherConditions: Codable {
    var temperature: Double // Fahrenheit
    var conditions: String // "Clear", "Rain", "Snow"
    var windSpeed: Double // mph
    var humidity: Double // percentage
}
```

---

## 9. API Integrations Required

### 9.1 Google Places API

**Purpose:** Search for contractors by location and service type

**Endpoints:**
- `places/nearbysearch/json` - Find contractors near location
- `place/details/json` - Get detailed info (phone, hours, reviews)

**Integration:**
```swift
class GooglePlacesAPI {
    private let apiKey: String
    private let baseURL = "https://maps.googleapis.com/maps/api/place"

    func search(
        query: String,
        location: CLLocation,
        radius: Double = 25.0 // miles
    ) async throws -> [ServiceProvider] {
        let radiusMeters = Int(radius * 1609.34) // miles to meters

        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(radiusMeters)"),
            URLQueryItem(name: "type", value: "establishment")
        ]

        let request = APIRequest<GooglePlacesResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )

        let response = try await request.execute()
        return response.results.map { mapToServiceProvider($0) }
    }
}
```

**Rate Limits:**
- Free tier: $200 credit/month (~40,000 requests)
- Cost: $0.017 per Nearby Search request

### 9.2 Yelp Fusion API

**Purpose:** Get contractor ratings, reviews, and contact info

**Endpoints:**
- `/v3/businesses/search` - Search by category and location
- `/v3/businesses/{id}` - Get business details
- `/v3/businesses/{id}/reviews` - Get reviews

**Integration:**
```swift
class YelpAPI {
    private let apiKey: String
    private let baseURL = "https://api.yelp.com/v3"

    func search(
        categories: String,
        latitude: Double,
        longitude: Double,
        radius: Int = 40000 // meters (25 miles)
    ) async throws -> [ServiceProvider] {
        var components = URLComponents(string: "\(baseURL)/businesses/search")!
        components.queryItems = [
            URLQueryItem(name: "categories", value: categories),
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "sort_by", value: "rating"),
            URLQueryItem(name: "limit", value: "20")
        ]

        let request = APIRequest<YelpSearchResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: nil
        )

        let response = try await request.execute()
        return response.businesses.map { mapToServiceProvider($0) }
    }
}
```

**Rate Limits:**
- Free tier: 5,000 API calls/day
- No cost for standard usage

### 9.3 Angi API (formerly Angie's List)

**Purpose:** Find pre-screened, rated contractors

**Note:** Angi API requires business partnership agreement

**Alternative:** Use Thumbtack API or HomeAdvisor API as alternatives

### 9.4 Twilio API

**Purpose:** Make automated calls/SMS to contractors

**Endpoints:**
- `/2010-04-01/Accounts/{AccountSid}/Calls.json` - Make call
- `/2010-04-01/Accounts/{AccountSid}/Messages.json` - Send SMS

**Integration:**
```swift
class TwilioAPI {
    private let accountSid: String
    private let authToken: String
    private let phoneNumber: String

    func makeCall(
        to: String,
        script: String,
        requestCallback: Bool = true
    ) async throws -> CallResult {
        // TwiML URL would host script as voice instructions
        let twimlURL = try await uploadTwiML(script)

        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSid)/Calls.json")!

        let parameters = [
            "To": to,
            "From": phoneNumber,
            "Url": twimlURL,
            "Method": "GET",
            "StatusCallback": requestCallback ? callbackURL : nil
        ].compactMapValues { $0 }

        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()

        let request = APIRequest<CallResult>(
            endpoint: url,
            method: .POST,
            headers: [
                "Authorization": "Basic \(credentials)",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: body.data(using: .utf8)
        )

        return try await request.execute()
    }

    func sendSMS(to: String, message: String) async throws -> SMSResult {
        let url = URL(string: "https://api.twilio.com/2010-04-01/Accounts/\(accountSid)/Messages.json")!

        let parameters = [
            "To": to,
            "From": phoneNumber,
            "Body": message
        ]

        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()

        let request = APIRequest<SMSResult>(
            endpoint: url,
            method: .POST,
            headers: [
                "Authorization": "Basic \(credentials)",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: body.data(using: .utf8)
        )

        return try await request.execute()
    }
}
```

**Costs:**
- Voice calls: $0.0130/min (outbound in US)
- SMS: $0.0079/message (outbound in US)

### 9.5 Weather API (OpenWeatherMap or WeatherAPI.com)

**Purpose:** Check temperature for heat/cold emergency assessment

**Integration:**
```swift
class WeatherAPI {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"

    func getCurrentWeather(
        location: CLLocation
    ) async throws -> WeatherConditions {
        var components = URLComponents(string: "\(baseURL)/weather")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial") // Fahrenheit
        ]

        let request = APIRequest<WeatherResponse>(
            endpoint: components.url!,
            method: .GET,
            headers: [:],
            body: nil
        )

        let response = try await request.execute()
        return WeatherConditions(
            temperature: response.main.temp,
            conditions: response.weather.first?.main ?? "Unknown",
            windSpeed: response.wind.speed,
            humidity: response.main.humidity
        )
    }
}
```

**Rate Limits:**
- Free tier: 1,000 calls/day
- Cost: Free for basic usage

---

## 10. Test Cases (20+ Scenarios)

### 10.1 Emergency Scenarios

```swift
class EmergencyTests: XCTestCase {

    func testGasLeakDetection() async throws {
        let issue = "I smell gas in my kitchen"
        let level = await assessEmergencyLevel(
            issue: issue,
            details: [:],
            homeProfile: testHome
        )

        XCTAssertEqual(level, .emergency)

        let protocol = getEmergencyProtocol(issueType: .gasLeak)
        XCTAssertTrue(protocol.requiresEvacuation)
        XCTAssertTrue(protocol.callEmergencyServices)
        XCTAssertEqual(protocol.lifeSafetyPriority, 1)
    }

    func testElectricalFireProtocol() async throws {
        let issue = "Sparking outlet with smoke"
        let level = await assessEmergencyLevel(
            issue: issue,
            details: ["visible_smoke": true],
            homeProfile: testHome
        )

        XCTAssertEqual(level, .emergency)

        let steps = generateSafetyInstructions(
            protocol: ElectricalFireProtocol(),
            homeProfile: testHome
        )

        XCTAssertTrue(steps.contains(where: { $0.instruction.contains("DO NOT USE WATER") }))
        XCTAssertTrue(steps.contains(where: { $0.instruction.contains("Evacuate") }))
    }

    func testCarbonMonoxideAlarm() async throws {
        let issue = "CO detector going off"
        let level = await assessEmergencyLevel(
            issue: issue,
            details: [:],
            homeProfile: testHome
        )

        XCTAssertEqual(level, .emergency)
        XCTAssertTrue(requiresEvacuation(emergencyLevel: level, issueType: .carbonMonoxide))
    }

    func testMajorFloodEvacuationDecision() async throws {
        let issue = "Basement flooding rapidly"
        let level = await assessEmergencyLevel(
            issue: issue,
            details: ["water_depth_inches": 12, "electrical_risk": true],
            homeProfile: testHome
        )

        XCTAssertEqual(level, .urgent)

        let protocol = getEmergencyProtocol(issueType: .majorWaterLeak)
        let steps = generateSafetyInstructions(protocol: protocol, homeProfile: testHome)

        XCTAssertTrue(steps.first?.instruction.contains("electrical") ?? false)
    }

    func testNoHeatInFreezingWeather() async throws {
        let weather = WeatherConditions(
            temperature: 15.0, // 15°F
            conditions: "Clear",
            windSpeed: 10.0,
            humidity: 60.0
        )

        let urgency = assessEnvironmentalUrgency(
            issueType: .noHeat,
            outsideTempF: weather.temperature,
            weatherConditions: weather
        )

        XCTAssertEqual(urgency, .upgradeToUrgent)

        let requiresSameDay = requiresSameDayService(
            issueType: .noHeat,
            weather: weather,
            timeOfDay: Date()
        )

        XCTAssertTrue(requiresSameDay)
    }

    func testNoHeatInMildWeather() async throws {
        let weather = WeatherConditions(
            temperature: 55.0, // 55°F
            conditions: "Clear",
            windSpeed: 5.0,
            humidity: 50.0
        )

        let level = await assessEmergencyLevel(
            issue: "Furnace not working",
            details: [:],
            homeProfile: testHome
        )

        let urgency = assessEnvironmentalUrgency(
            issueType: .noHeat,
            outsideTempF: weather.temperature,
            weatherConditions: weather
        )

        XCTAssertEqual(urgency, .standard)
        XCTAssertEqual(level, .routine)
    }
}
```

### 10.2 Contractor Search Tests

```swift
class ContractorSearchTests: XCTestCase {

    func testFindPlumbersNearLocation() async throws {
        let location = CLLocation(latitude: 40.7128, longitude: -74.0060) // NYC

        let contractors = try await searchContractors(
            serviceType: .plumber,
            location: location,
            radius: 25.0
        )

        XCTAssertGreaterThan(contractors.count, 0)
        XCTAssertTrue(contractors.allSatisfy { $0.serviceType == .plumber })
    }

    func testContractorRanking() async throws {
        let savedContractor = ServiceProvider(
            id: UUID(),
            name: "Trusted Plumber",
            serviceType: .plumber,
            phone: "555-1234",
            rating: 4.5,
            reviewCount: 100,
            distanceFromHome: 5.0,
            offers24HourService: true,
            lastUsed: Date(),
            source: .saved
        )

        let newContractor = ServiceProvider(
            id: UUID(),
            name: "New Plumber",
            serviceType: .plumber,
            phone: "555-5678",
            rating: 4.9,
            reviewCount: 200,
            distanceFromHome: 3.0,
            offers24HourService: false,
            lastUsed: nil,
            source: .google
        )

        let ranked = rankProviders(
            providers: [newContractor, savedContractor],
            urgency: .urgent
        )

        // Saved contractor should rank higher due to trust factor
        XCTAssertEqual(ranked.first?.name, "Trusted Plumber")
    }

    func testEmergencyContractorPrioritization() async throws {
        let contractors = [
            ServiceProvider(name: "24Hr Emergency", offers24HourService: true, rating: 4.3),
            ServiceProvider(name: "High Rated", offers24HourService: false, rating: 4.9),
            ServiceProvider(name: "Previously Used", offers24HourService: false, rating: 4.5, lastUsed: Date())
        ]

        let ranked = rankProviders(providers: contractors, urgency: .emergency)

        // For emergency, 24-hour service and previous use matter most
        XCTAssertTrue(ranked.first?.offers24HourService == true || ranked.first?.lastUsed != nil)
    }

    func testContractorCallScriptGeneration() throws {
        let issue = MaintenanceIssue(
            id: UUID(),
            title: "Basement flooding",
            description: "Water coming from ceiling",
            issueType: .majorWaterLeak,
            emergencyLevel: .urgent,
            reportedDate: Date(),
            location: "Basement"
        )

        let script = generateContractorCallScript(issue: issue, urgency: .urgent)

        XCTAssertTrue(script.contains("URGENT"))
        XCTAssertTrue(script.contains("Basement flooding"))
        XCTAssertTrue(script.contains(testHome.address))
    }
}
```

### 10.3 Preventive Maintenance Tests

```swift
class PreventiveMaintenanceTests: XCTestCase {

    func testMonthlyTaskScheduling() async throws {
        let tasks = await getUpcomingMaintenanceTasks(
            homeId: testHome.id,
            daysAhead: 30
        )

        let hvacFilterTask = tasks.first(where: { $0.title.contains("HVAC Filter") })
        XCTAssertNotNil(hvacFilterTask)
        XCTAssertEqual(hvacFilterTask?.frequency, .monthly)
        XCTAssertTrue(hvacFilterTask?.diyFriendly ?? false)
    }

    func testSeasonalHVACTuneup() async throws {
        // Spring - should recommend AC tuneup
        let springTasks = semiAnnualTasks.filter { $0.season == .spring }
        let acTuneup = springTasks.first(where: { $0.title.contains("AC") })

        XCTAssertNotNil(acTuneup)
        XCTAssertFalse(acTuneup?.diyFriendly ?? true)
        XCTAssertTrue(acTuneup?.requiresProfessional ?? false)
    }

    func testCriticalSafetyTasksHighlighted() async throws {
        let allTasks = monthlyTasks + quarterlyTasks + semiAnnualTasks + annualTasks
        let criticalTasks = allTasks.filter { $0.criticalSafety }

        XCTAssertTrue(criticalTasks.contains(where: { $0.title.contains("Smoke") }))
        XCTAssertTrue(criticalTasks.contains(where: { $0.title.contains("CO Detector") }))
        XCTAssertTrue(criticalTasks.contains(where: { $0.title.contains("Dryer Vent") }))
    }

    func testConditionalTasksForHomeType() async throws {
        var homeWithChimney = testHome
        homeWithChimney.hasChimney = true

        let calendar = generateDefaultMaintenanceCalendar(
            homeType: homeWithChimney.homeType,
            hvacType: homeWithChimney.hvacInfo?.systemType,
            hasChimney: true,
            hasWell: false,
            hasSeptic: false
        )

        XCTAssertTrue(calendar.contains(where: { $0.title.contains("Chimney") }))

        var homeWithoutChimney = testHome
        homeWithoutChimney.hasChimney = false

        let calendar2 = generateDefaultMaintenanceCalendar(
            homeType: homeWithoutChimney.homeType,
            hvacType: nil,
            hasChimney: false,
            hasWell: false,
            hasSeptic: false
        )

        XCTAssertFalse(calendar2.contains(where: { $0.title.contains("Chimney") }))
    }

    func testTaskCompletionTracking() async throws {
        let task = MaintenanceTask(
            id: UUID(),
            title: "Test Task",
            description: "Testing",
            frequency: .monthly,
            category: .hvac,
            estimatedTime: 10,
            diyFriendly: true,
            requiresProfessional: false,
            criticalSafety: false,
            nextDueDate: Date()
        )

        let success = try await completeMaintenanceTask(
            taskId: task.id,
            completionDate: Date(),
            notes: "Completed successfully",
            cost: 0
        )

        XCTAssertTrue(success)

        let updatedTask = await getMaintenanceSchedule(homeId: testHome.id)
            .first(where: { $0.id == task.id })

        XCTAssertNotNil(updatedTask?.lastCompletedDate)
    }
}
```

### 10.4 Repair History Tests

```swift
class RepairHistoryTests: XCTestCase {

    func testLogRepairWithCost() async throws {
        let repair = try await logRepair(
            homeId: testHome.id,
            issueType: .minorLeak,
            provider: testContractor,
            date: Date(),
            cost: 150.00,
            description: "Fixed leaking faucet in kitchen",
            photoURLs: nil
        )

        XCTAssertEqual(repair.cost, 150.00)
        XCTAssertEqual(repair.issueType, .minorLeak)
    }

    func testGetRepairHistoryByType() async throws {
        // Log multiple repairs
        _ = try await logRepair(homeId: testHome.id, issueType: .minorLeak, cost: 100)
        _ = try await logRepair(homeId: testHome.id, issueType: .noAC, cost: 200)
        _ = try await logRepair(homeId: testHome.id, issueType: .minorLeak, cost: 150)

        let plumbingRepairs = await getRepairHistory(
            homeId: testHome.id,
            issueType: .minorLeak
        )

        XCTAssertEqual(plumbingRepairs.count, 2)
        XCTAssertTrue(plumbingRepairs.allSatisfy { $0.issueType == .minorLeak })
    }

    func testAverageRepairCostCalculation() async throws {
        _ = try await logRepair(homeId: testHome.id, issueType: .hvacNotWorking, cost: 150)
        _ = try await logRepair(homeId: testHome.id, issueType: .hvacNotWorking, cost: 200)
        _ = try await logRepair(homeId: testHome.id, issueType: .hvacNotWorking, cost: 250)

        let analysis = await getAverageRepairCosts(
            homeId: testHome.id,
            issueType: .hvacNotWorking
        )

        XCTAssertEqual(analysis.average, 200.00)
        XCTAssertEqual(analysis.min, 150.00)
        XCTAssertEqual(analysis.max, 250.00)
    }

    func testExportRepairHistoryForInsurance() async throws {
        _ = try await logRepair(homeId: testHome.id, issueType: .roofLeak, cost: 2500, description: "Roof repair after storm")

        let exportURL = try await exportRepairHistory(
            homeId: testHome.id,
            format: .pdf
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
    }
}
```

### 10.5 Integration Tests

```swift
class HomeMaintenanceIntegrationTests: XCTestCase {

    func testEndToEndEmergencyFlow() async throws {
        // User reports gas leak
        let issue = "I smell gas"

        // 1. Assess emergency
        let level = await assessEmergencyLevel(issue: issue, details: [:], homeProfile: testHome)
        XCTAssertEqual(level, .emergency)

        // 2. Get protocol
        let protocol = getEmergencyProtocol(issueType: .gasLeak)
        XCTAssertTrue(protocol.requiresEvacuation)

        // 3. Generate instructions
        let steps = generateSafetyInstructions(protocol: protocol, homeProfile: testHome)
        XCTAssertGreaterThan(steps.count, 0)

        // 4. Log emergency event
        let record = try await logRepair(
            homeId: testHome.id,
            issueType: .gasLeak,
            provider: nil,
            date: Date(),
            cost: 0,
            description: "Gas leak emergency - evacuated, called 911",
            photoURLs: nil
        )

        XCTAssertNotNil(record.id)
    }

    func testEndToEndRoutineRepairFlow() async throws {
        // User reports AC not cooling
        let issue = "My AC isn't cooling well"

        // 1. Assess - routine unless extreme heat
        let weather = WeatherConditions(temperature: 75, conditions: "Clear", windSpeed: 5, humidity: 50)
        let level = await assessEmergencyLevel(issue: issue, details: [:], homeProfile: testHome)
        XCTAssertEqual(level, .routine)

        // 2. Search contractors
        let contractors = try await searchContractors(
            serviceType: .hvac,
            location: testLocation,
            radius: 25
        )
        XCTAssertGreaterThan(contractors.count, 0)

        // 3. Rank and select
        let ranked = rankProviders(providers: contractors, urgency: .routine)
        let selectedContractor = ranked.first!

        // 4. Contact contractor
        let script = generateContractorCallScript(
            issue: MaintenanceIssue(
                id: UUID(),
                title: "AC not cooling",
                description: issue,
                issueType: .noAC,
                emergencyLevel: .routine,
                reportedDate: Date()
            ),
            urgency: .routine
        )

        XCTAssertTrue(script.contains("AC not cooling"))

        // 5. Schedule appointment
        let appointment = try await scheduleServiceAppointment(
            provider: selectedContractor,
            preferredDate: Date().addingTimeInterval(86400 * 2), // 2 days out
            issue: MaintenanceIssue(
                id: UUID(),
                title: "AC repair",
                description: issue,
                issueType: .noAC,
                emergencyLevel: .routine,
                reportedDate: Date()
            )
        )

        XCTAssertNotNil(appointment.id)

        // 6. Save contractor for future
        let saved = try await saveContractor(
            homeId: testHome.id,
            provider: selectedContractor,
            rating: nil,
            notes: "Scheduled for AC repair"
        )

        XCTAssertTrue(saved)
    }
}
```

---

## 11. Error Handling Strategies

### 11.1 Network Failures

```swift
func searchContractorsWithRetry(
    serviceType: ServiceType,
    location: CLLocation,
    maxRetries: Int = 3
) async throws -> [ServiceProvider] {

    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            return try await searchContractorsWithFallback(
                serviceType: serviceType,
                location: location,
                urgency: .routine
            )
        } catch let error as NetworkError {
            lastError = error

            if attempt < maxRetries {
                // Exponential backoff
                let delay = TimeInterval(pow(2.0, Double(attempt)))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    // All retries failed - throw last error
    throw lastError ?? NetworkError.unknown
}
```

### 11.2 Missing Data Graceful Degradation

```swift
func getEmergencyProtocolWithFallback(
    issueType: EmergencyType,
    homeProfile: HomeProfile?
) -> SafetyProtocol {

    let protocol = getEmergencyProtocol(issueType: issueType)

    // If home profile missing, use generic instructions
    if homeProfile == nil || homeProfile?.shutoffLocations.mainWaterValve == nil {
        return protocol.withGenericInstructions()
    }

    return protocol
}

extension SafetyProtocol {
    func withGenericInstructions() -> SafetyProtocol {
        // Replace home-specific steps with generic guidance
        var modified = self
        modified.steps = modified.steps.map { step in
            var genericStep = step
            if step.instruction.contains("valve location") {
                genericStep.instruction = "Locate main water valve (usually in basement, crawlspace, or outside near foundation) and turn clockwise to close"
            }
            return genericStep
        }
        return modified
    }
}
```

### 11.3 API Rate Limiting

```swift
class APIRateLimiter {
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    private let queue = DispatchQueue(label: "com.openclaw.ratelimiter")

    func checkRateLimit(for api: String, limit: Int, window: TimeInterval) async throws {
        try await queue.sync {
            let now = Date()

            if let existing = requestCounts[api] {
                if now < existing.resetTime {
                    if existing.count >= limit {
                        throw APIError.rateLimitExceeded(retryAfter: existing.resetTime)
                    }
                    requestCounts[api] = (existing.count + 1, existing.resetTime)
                } else {
                    // Window expired, reset
                    requestCounts[api] = (1, now.addingTimeInterval(window))
                }
            } else {
                requestCounts[api] = (1, now.addingTimeInterval(window))
            }
        }
    }
}

// Usage
func searchContractorsWithRateLimit(
    serviceType: ServiceType,
    location: CLLocation
) async throws -> [ServiceProvider] {

    try await rateLimiter.checkRateLimit(
        for: "google_places",
        limit: 100,
        window: 3600 // 1 hour
    )

    return try await GooglePlacesAPI.search(...)
}
```

### 11.4 Emergency Protocol Fail-Safe

```swift
func handleEmergencyWithFailSafe(
    issue: String,
    details: [String: Any]
) async -> EmergencyResponse {

    do {
        let level = try await assessEmergencyLevel(
            issue: issue,
            details: details,
            homeProfile: getHomeProfile()
        )

        let protocol = getEmergencyProtocol(issueType: detectIssueType(issue))

        return EmergencyResponse(
            level: level,
            protocol: protocol,
            success: true
        )

    } catch {
        // CRITICAL: On ANY error in emergency assessment, default to highest safety level
        return EmergencyResponse(
            level: .emergency,
            protocol: GenericEmergencyProtocol(),
            success: false,
            error: error,
            message: "Unable to assess automatically. If this is an emergency, call 911 immediately."
        )
    }
}
```

### 11.5 User-Facing Error Messages

```swift
enum UserFacingError: Error, LocalizedError {
    case networkUnavailable
    case noContractorsFound
    case apiKeyMissing
    case locationPermissionDenied
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Can't connect to internet. Check your connection and try again."

        case .noContractorsFound:
            return "Couldn't find contractors nearby. Try expanding search radius or call emergency services if urgent."

        case .apiKeyMissing:
            return "Service temporarily unavailable. Please try again later."

        case .locationPermissionDenied:
            return "Location access needed to find nearby contractors. Enable in Settings."

        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    var recoverysuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "If this is an emergency, call 911 directly at [CALL 911 BUTTON]"

        case .noContractorsFound:
            return "You can:\n• Manually search online\n• Call your previously used contractor\n• Ask neighbors for referrals"

        case .locationPermissionDenied:
            return "Go to Settings > Privacy > Location Services > OpenClaw and enable location access."

        default:
            return "Contact support if this persists."
        }
    }
}
```

---

## 12. Summary

This Home Maintenance skill provides:

1. **Life-Safety Priority**: Immediate, clear protocols for gas leaks, fires, CO alarms
2. **Emergency Triage**: Intelligent assessment of urgency based on issue + environmental conditions
3. **Contractor Coordination**: Multi-source search with trust-based ranking
4. **Preventive Maintenance**: Comprehensive calendar preventing costly emergency repairs
5. **Repair Tracking**: Historical records for insurance, home sale, cost analysis

**Critical Success Factors:**
- Emergency protocols MUST be instantly accessible (no network dependency)
- Safety instructions MUST be crystal clear (life-or-death clarity)
- Contractor search MUST have fallback sources (never return "none found" in emergency)
- UI MUST use high-contrast warnings for emergencies (red backgrounds, large text)

**Future Enhancements:**
- Integration with smart home sensors (water leak detectors, smoke alarms)
- AR overlays showing shutoff valve locations via camera
- Warranty tracking and expiration alerts
- Neighborhood contractor referral network
- Home value impact tracking from repairs/maintenance

---

**End of Document**
