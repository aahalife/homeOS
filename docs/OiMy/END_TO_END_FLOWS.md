# End-to-End Flows — Implementation Guide

How skills work together across reactive, proactive, and scheduled scenarios. This is the practical wiring guide for the iOS app.

---

## Architecture Overview

### Three Skill Activation Modes

| Mode | Trigger | Example |
|------|---------|---------|
| **Reactive** | User sends a message | "Emma has a fever" → healthcare skill |
| **Proactive** | App detects a condition | Medication refill in 7 days → nudge user |
| **Scheduled** | Timer fires | 7:00 AM daily → morning briefing |

### The Skill Lifecycle

```
[Trigger] → [Intent Classification] → [Skill Selection] → [Info Gathering]
    → [Execution] → [Response/Action] → [Storage Update] → [Follow-up/Handoff]
```

Every skill follows `SkillProtocol`. The orchestrator calls `canHandle(intent:)` on candidate skills, picks the highest confidence, then calls `execute(context:)`. The result is one of four cases:

```swift
public enum SkillResult: Sendable {
    case response(String)              // Direct reply to user
    case needsApproval(ApprovalRequest) // Blocked on user confirmation
    case handoff(HandoffRequest)       // Route to another skill
    case error(String)                 // Something went wrong
}
```

### The Orchestrator Loop

This is the central engine. Every message flows through it:

```swift
// SkillOrchestrator.swift

final class SkillOrchestrator: Sendable {
    let registry: SkillRegistry
    let storage: any StorageProvider
    let llm: any LLMBridge
    let scheduler: SkillScheduler
    let family: Family

    /// Main entry point for all user messages
    func handleMessage(_ raw: String, from member: FamilyMember) async throws -> String {
        // 1. Parse intent
        let intent = UserIntent(
            rawMessage: raw,
            entities: EntityExtractor.extract(from: raw, family: family),
            urgency: UrgencyClassifier.classify(raw)
        )

        // 2. Enrich context (see Pattern: Contextual Enrichment)
        let context = try await buildContext(intent: intent, member: member)

        // 3. Route — find best skill
        let skill = route(intent: intent)

        // 4. Execute
        var result = try await skill.execute(context: context)

        // 5. Handle chained results
        result = try await resolveResult(result, originalIntent: intent, member: member)

        // 6. Check contextual triggers (proactive suggestions)
        let suggestions = checkContextualTriggers(skill: skill, intent: intent, member: member)

        // 7. Schedule follow-ups
        if case .response(let text) = result {
            return text + suggestions
        }
        return ""
    }

    /// Resolve handoffs and approvals recursively
    private func resolveResult(
        _ result: SkillResult,
        originalIntent: UserIntent,
        member: FamilyMember,
        depth: Int = 0
    ) async throws -> SkillResult {
        guard depth < 5 else { return .error("Too many handoffs") }

        switch result {
        case .handoff(let request):
            guard let nextSkill = registry.find(request.targetSkill) else {
                return .error("Skill '\(request.targetSkill)' not found")
            }
            let handoffIntent = UserIntent(
                rawMessage: request.reason,
                entities: .empty,
                urgency: originalIntent.urgency
            )
            let ctx = try await buildContext(intent: handoffIntent, member: member)
            let nextResult = try await nextSkill.execute(context: ctx)
            return try await resolveResult(nextResult, originalIntent: originalIntent, member: member, depth: depth + 1)

        case .needsApproval(let request):
            // Store pending approval, return prompt to user
            try await storage.write(
                path: "tasks/pending/approval-\(Int(Date().timeIntervalSince1970)).json",
                data: PendingApproval(description: request.description, details: request.details, risk: request.riskLevel)
            )
            return .response(formatApprovalPrompt(request))

        case .response, .error:
            return result
        }
    }
}
```

### Routing: ChatTurn + Confidence Scoring

```swift
func route(intent: UserIntent) -> any SkillProtocol {
    // Priority-ordered keyword matching (from chat-turn SKILL.md)
    // 1. Telephony: "call", "phone", "dial"
    // 2. Restaurant: "reservation", "book a table"
    // 3. Marketplace: "sell", "list for sale"
    // 4. Hire Helper: "babysitter", "tutor", "hire"

    // Then confidence scoring across all skills
    let scored = registry.allSkills
        .map { ($0, $0.canHandle(intent: intent)) }
        .filter { $0.1 > 0.3 }
        .sorted { $0.1 > $1.1 }

    return scored.first?.0 ?? generalChatSkill
}
```

---

## Reactive Flows (User-Initiated)

### Flow 1: "Kid is sick" — Healthcare → Wellness → School Multi-Skill Chain

**User context:** Parent discovers their 8-year-old has a fever at 6:30 AM on a school day.

#### Step-by-step implementation

**Step 1: User sends message**
```
"Emma has a fever, she's at 101.5"
```

**Step 2: Intent parsing**
```swift
let intent = UserIntent(
    rawMessage: "Emma has a fever, she's at 101.5",
    keywords: ["emma", "has", "a", "fever", "she's", "at", "101.5"],
    entities: ExtractedEntities(
        people: ["Emma"],       // Matched against family.json
        amounts: [101.5]        // Extracted numeric value
    ),
    urgency: .urgent            // "fever" triggers urgent classification
)
```

**Step 3: ChatTurn routes to healthcare** (keyword match: "fever")

**Step 4: Healthcare skill executes**

```swift
// HealthcareSkill.execute()
func execute(context: SkillContext) async throws -> SkillResult {
    // a. Always show disclaimer
    var response = "⚠️ I am NOT a doctor. This is informational only.\n\n"

    // b. Emergency check
    let member = context.family.member(named: "Emma")  // age 8
    let temp = 101.5

    // Emergency threshold: 102°F for kids age 3+, 100.4°F for under 3
    if temp >= emergencyThreshold(age: member.age) {
        return .response(emergencyTemplate)
    }

    // c. Severity classification
    // 100-102°F = MODERATE for age 8
    let severity: Severity = .moderate

    // d. Self-care template with age-appropriate advice
    response += """
    🏠 SELF-CARE — Emma

    Symptoms: Fever 101.5°F

    Suggestions:
    - Rest and stay hydrated (aim for 48 oz water today)
    - Children's acetaminophen or ibuprofen per package directions
    - Light clothing, cool compress on forehead
    - Popsicles and clear fluids count toward hydration

    ⚠️ See a doctor if:
    - Fever reaches 102°F or higher
    - No improvement in 24 hours
    - New symptoms appear (rash, stiff neck, difficulty breathing)
    """

    // e. Handoff to wellness for recovery tracking
    return .handoff(HandoffRequest(
        targetSkill: "wellness",
        reason: "recovery tracking",
        context: [
            "member": "Emma",
            "age": "8",
            "condition": "fever 101.5°F",
            "track": "hydration, rest, temperature"
        ]
    ))
}
```

**Step 5: Orchestrator follows handoff → Wellness skill**

```swift
// WellnessSkill receives handoff context
func execute(context: SkillContext) async throws -> SkillResult {
    // Set up hydration tracking (adjusted for sick child)
    let hydrationGoal = HydrationGoal(
        memberId: "emma",
        targetOz: 48,           // Reduced from normal 64oz
        reason: "sick — fever recovery",
        checkInInterval: 7200   // Every 2 hours
    )
    try await context.storage.write(
        path: "data/health/hydration_tracking.json",
        data: hydrationGoal
    )

    // Schedule check-in nudges
    scheduler.schedule(
        repeating: .hours(2),
        starting: Date().addingTimeInterval(7200),
        action: .wellnessCheckIn(member: "emma", prompt: "How's Emma feeling? Has she had water?")
    )

    return .response("💧 Hydration tracking set up for Emma (48oz goal). I'll check in every 2 hours.")
}
```

**Step 6: Contextual trigger — school notification**

Back in the orchestrator, after the handoff chain completes:

```swift
func checkContextualTriggers(skill: any SkillProtocol, intent: UserIntent, member: FamilyMember) -> String {
    var suggestions = ""

    if skill.name == "healthcare" {
        // Check if it's a school day
        let today = Date()
        let isWeekday = !Calendar.current.isDateInWeekend(today)

        if isWeekday, let child = intent.entities.people.first {
            // Check if child is school-age
            let childMember = family.member(named: child)
            if childMember.age >= 5 && childMember.age <= 18 {
                suggestions += "\n\n📢 It's a school day. Should I notify school that \(child) will be absent?"
                // Store suggestion for follow-up
                scheduler.schedule(
                    once: Date().addingTimeInterval(60),
                    action: .pendingSuggestion(
                        type: "school_absence",
                        member: child,
                        expiresIn: 3600
                    )
                )
            }
        }
    }
    return suggestions
}
```

**Step 7: User approves → School skill generates absence notification**

```swift
// SchoolSkill handles absence notification
// User says: "Yes, notify school"

func generateAbsenceNotification(child: String, reason: String) async throws -> SkillResult {
    let draft = """
    📧 Draft to [Teacher] re: Emma

    Subject: Emma - Absent Today

    Dear [Teacher],

    Emma will be absent from school today due to illness (fever).
    We expect her to return once her fever has resolved for 24 hours.

    Please send any homework assignments home or let us know how
    to access them online.

    Thank you,
    [Parent Name]

    ---
    Adjust before sending?
    """
    return .needsApproval(ApprovalRequest(
        description: "Send absence notification to Emma's school",
        details: ["Email to teacher", "Reason: fever"],
        riskLevel: .high,
        onDecision: { approved in
            if approved {
                // Send via configured method
                return .response("✅ Absence notification sent to Emma's teacher.")
            }
            return .response("Cancelled. You can notify them yourself if needed.")
        }
    ))
}
```

**Step 8: Mental-load adjusts morning briefing**

```swift
// In the morning briefing generator, check active health conditions
func generateMorningBriefing() async -> String {
    let healthTracking = try? await storage.read(
        path: "data/health/hydration_tracking.json",
        type: HydrationGoal.self
    )

    // Filter out activities for sick family members
    let activeMembers = family.members.filter { member in
        healthTracking?.memberId != member.id  // Exclude sick member's activities
    }

    // Briefing mentions Emma's status
    // "🤒 Emma is home sick (fever 101.5°F). Hydration tracking active."
    // Omits Emma's school carpool, after-school activities, etc.
    ...
}
```

#### Complete Timeline

```
6:30 AM — User: "Emma has a fever, she's at 101.5"
6:30 AM — Healthcare: triage → MODERATE → self-care advice + disclaimer
6:30 AM — Handoff → Wellness: hydration tracking (48oz goal), 2hr check-ins
6:30 AM — Contextual trigger: "Should I notify school?"
6:31 AM — User: "Yes"
6:31 AM — School: drafts absence email → shows for approval
6:32 AM — User approves → email sent
7:00 AM — Morning briefing: excludes Emma's activities, shows "🤒 Emma home sick"
8:30 AM — Wellness check-in: "How's Emma feeling? Has she had water?"
10:30 AM — Wellness check-in
12:30 PM — Wellness check-in + "Her fever was 101.5 this morning — has it changed?"
```

#### Storage state after this flow

```
~/clawd/homeos/
├── data/
│   ├── health/
│   │   ├── hydration_tracking.json    ← NEW: Emma's tracking
│   │   └── family_health.json         ← UPDATED: fever logged
│   ├── school/
│   │   └── events.json                ← UPDATED: absence recorded
│   └── calendar.json                  ← UPDATED: Emma's events flagged
├── tasks/
│   └── active/
│       └── wellness-emma-fever.json   ← NEW: recovery task
└── logs/
    └── actions.log                    ← APPENDED: healthcare triage, school notification
```

---

### Flow 2: "Plan date night" — Restaurant + Calendar + HireHelper

**User context:** Parent wants to plan a date night this Saturday.

#### Step-by-step

**Step 1: User message**
```
"Help me plan a date night this Saturday"
```

**Step 2: ChatTurn routes to restaurant-reservation** (keyword: "date night" implies dining)

But wait — "plan" is broader than just a restaurant. The orchestrator detects multi-skill potential:

```swift
// Multiple skills score > 0.3 confidence
// restaurant-reservation: 0.7 ("date night" → dining)
// family-bonding: 0.5 ("date night" → couple time)
// hire-helper: 0.4 (date night implies childcare needed)

// Orchestrator picks restaurant as primary, queues contextual triggers for others
```

**Step 3: Restaurant skill gathers requirements**

```swift
func execute(context: SkillContext) async throws -> SkillResult {
    // Check stored preferences
    let diningPrefs = try? await context.storage.read(
        path: "memory/dining.json",
        type: DiningPreferences.self
    )
    let familyData = try? await context.storage.read(
        path: "data/family.json",
        type: Family.self
    )

    // Determine what's missing
    var have: [String: Any] = [
        "date": "Saturday",
        "occasion": "date night"
    ]
    let needed = ["time", "party_size", "location", "cuisine"]

    // Party size = 2 (date night implies couple)
    have["party_size"] = 2

    // Still need: time, location, cuisine
    return .response("""
    Love it! Date night 💑 A few details:
    1. 📅 Saturday — what time? (default: 7:00 PM)
    2. 📍 What area/neighborhood?
    3. 🍽️ Cuisine preference?

    \(diningPrefs != nil ? "Last time you enjoyed \(diningPrefs!.lastRestaurant) — something similar?" : "")
    """)
}
```

**Step 4: User provides details**
```
"Italian, downtown, 7:30"
```

**Step 5: Restaurant skill searches and presents options**

```swift
// Search web for: "best Italian restaurants downtown"
// Check saved favorites in memory/restaurants.json
// Cross-reference dietary restrictions from family.json

return .response("""
🍽️ Options for Saturday 7:30 PM:

1. ⭐ Trattoria Roma — $$$ — 4.8★
   📍 0.5 mi downtown | Italian
   ✨ Fresh pasta, great wine list, romantic atmosphere
   📞 (555) 234-5678 | 🌐 opentable.com/trattoria-roma

2. ⭐ Bella Notte — $$ — 4.6★
   📍 0.3 mi downtown | Italian
   ✨ Cozy, candlelit, excellent tiramisu
   📞 (555) 345-6789 | 🌐 bellanotte.com/reserve

3. ⭐ Osteria Moderna — $$$$ — 4.9★
   📍 0.8 mi downtown | Modern Italian
   ✨ Chef's tasting menu, special occasion perfect
   📞 (555) 456-7890 | 🌐 osteriamoderna.com

Which one?
""")
```

**Step 6: User picks → booking assist**

User: "Let's do Bella Notte"

```swift
// Online booking available
return .response("""
✅ Book here: bellanotte.com/reserve
Enter: Saturday, 7:30 PM, 2 people, [Your Name]

Let me know once confirmed — I'll add it to your calendar.
""")
```

If phone-only → handoff to telephony:
```swift
return .handoff(HandoffRequest(
    targetSkill: "telephony",
    reason: "Restaurant requires phone reservation",
    context: [
        "business_name": "Bella Notte",
        "phone": "(555) 345-6789",
        "purpose": "reservation",
        "date": "Saturday",
        "time": "7:30 PM",
        "party_size": "2",
        "name": "[Parent Name]",
        "occasion": "date night"
    ]
))
```

**Step 7: Contextual triggers fire**

```swift
// After restaurant is confirmed, orchestrator checks:

// Trigger 1: Kids need supervision
if family.hasChildren {
    suggestions += "\n\n👶 Need a babysitter for Saturday evening?"
    // If yes → handoff to hire-helper skill
}

// Trigger 2: Calendar event
suggestions += "\n\n📅 Want me to add this to the calendar?"
// If yes → save to data/calendar.json
```

**Step 8: Calendar + reminders**

```swift
// Save confirmed reservation
let event = CalendarEvent(
    id: "res-\(Int(Date().timeIntervalSince1970))",
    title: "Date Night — Bella Notte",
    date: "2025-01-18",
    time: "19:30",
    location: "123 Main St, Downtown",
    notes: "Party of 2, Italian"
)
try await storage.write(path: "data/calendar.json", data: event, mode: .append)

// Schedule reminders
scheduler.schedule(once: saturdayAt(14, 00), action: .reminder("Date night tonight! Bella Notte at 7:30 PM 💑"))
scheduler.schedule(once: saturdayAt(18, 30), action: .reminder("Leave in 30 min for Bella Notte 📍"))
```

**Step 9: Day after — follow-up**

```swift
// Sunday, triggered by scheduler
"How was Bella Notte last night? Would you go back? ⭐"
// Save feedback to memory/restaurants.json for future recommendations
```

#### Complete Timeline

```
Tuesday  — User: "Help me plan date night this Saturday"
Tuesday  — Restaurant: gathers preferences
Tuesday  — User: "Italian, downtown, 7:30"
Tuesday  — Restaurant: presents 3 options
Tuesday  — User: "Bella Notte"
Tuesday  — Restaurant: booking link provided
Tuesday  — Contextual: "Need a babysitter?"
Tuesday  — User: "Yes" → hire-helper skill activates
Tuesday  — Calendar event created + reminders set
Saturday 2:00 PM — Reminder: "Date night tonight!"
Saturday 6:30 PM — Reminder: "Leave in 30 min"
Sunday   — Follow-up: "How was Bella Notte?"
```

---

### Flow 3: "Sell the old couch" — Marketplace Lifecycle

**User context:** Family wants to sell a used couch on Facebook Marketplace.

#### Step-by-step

**Step 1: ChatTurn routes to marketplace-sell** (keyword: "sell")

**Step 2: Info gathering loop**

```swift
func execute(context: SkillContext) async throws -> SkillResult {
    // Need: item description, condition, photos, price
    let needed = ["item", "condition", "age", "original_price", "photos"]

    return .response("""
    🏷️ Let's list that couch! I need a few things:

    1. 📝 Describe it (color, material, size, brand if known)
    2. 📊 Condition? (like new / good / fair / worn)
    3. 📅 How old is it?
    4. 💰 What did you pay originally? (helps with pricing)
    5. 📸 Can you take 3-4 photos? (front, side, close-up of any wear)
    """)
}
```

**Step 3: User provides details across 1-2 messages**

```
"It's a gray IKEA Kivik sectional, 3 years old, good condition,
paid $900. There's a small stain on one cushion."
```

**Step 4: Pricing research**

```swift
// Search web for: "IKEA Kivik sectional gray used price"
// Cross-reference with condition, age, and local market

return .response("""
💰 PRICING RESEARCH

IKEA Kivik Sectional (gray, 3 years, good condition):
- New retail: $899
- Similar listings nearby: $250-$450
- My recommendation: $350 (fair price, quick sale)
- Stretch price: $425 (may take longer)

List at $350? Or pick a different price?
""")
```

**Step 5: Listing creation** (MEDIUM risk — confirm before posting)

```swift
return .needsApproval(ApprovalRequest(
    description: "Create marketplace listing",
    details: [
        "Item: IKEA Kivik Sectional (gray)",
        "Price: $350",
        "Platform: Facebook Marketplace",
        "Note: Will mention small stain in description"
    ],
    riskLevel: .medium,
    onDecision: { approved in
        if approved {
            let listing = """
            📋 LISTING READY

            Title: IKEA Kivik Sectional — Gray — Great Condition
            Price: $350

            Description:
            IKEA Kivik sectional sofa in gray. 3 years old, great shape.
            Very comfortable, pet-free and smoke-free home.
            Small stain on one cushion (see photo) — priced accordingly.
            Dimensions: [IKEA specs]
            Retail: $899

            Pick up only. Can help load.

            📸 Attach your photos and post!

            I'll help you handle buyer messages.
            """
            return .response(listing)
        }
        return .response("No worries. Let me know if you change your mind.")
    }
))
```

**Step 6: Buyer communication handling**

When buyers message, user can forward to HomeOS:

```swift
// User: "Someone messaged about the couch: 'Is it still available? Would you take $200?'"

func handleBuyerMessage(message: String, listing: Listing) -> SkillResult {
    let analysis = analyzeBuyerMessage(message)

    // Lowball detection
    if analysis.offerPercent < 0.5 {
        return .response("""
        🤔 That's a lowball ($200 vs $350 asking).

        Suggested reply:
        "Thanks for your interest! The lowest I can go is $300.
        It's in great condition and retails for $899. Let me know!"

        Or counter at a different price?
        """)
    }

    // Scam detection
    if analysis.scamIndicators.count > 0 {
        return .response("""
        ⚠️ SCAM WARNING

        Red flags detected:
        \(analysis.scamIndicators.map { "- 🚩 \($0)" }.joined(separator: "\n"))

        Recommendation: Do not proceed. Block this buyer.
        Common scams: fake payment screenshots, "I'll send a mover",
        overpayment with refund request.
        """)
    }

    return .response("Looks like a genuine buyer. Suggested reply: ...")
}
```

**Step 7: Safe meetup guidance**

```swift
// Buyer agreed to $325, wants to pick up
return .response("""
🤝 MEETUP SAFETY

✅ Do:
- Meet in a public place (police station parking lots have safe trade zones)
- Bring someone with you
- Daytime only
- Cash or verified payment (Venmo/Zelle) BEFORE they take the item
- Take a photo of their license plate

❌ Don't:
- Share your home address until payment is confirmed
- Accept checks or money orders
- Let them "come back with the rest later"

Suggested message:
"Great! Can you meet at [Safe Location] on [Day] at [Time]?
Cash or Venmo, $325. I can help load it into your vehicle."
""")
```

**Step 8: Post-sale cleanup**

```swift
// User: "Sold the couch!"
return .response("""
🎉 Sold! Nice work.

Cleanup:
- ☐ Mark listing as sold / remove
- ☐ Save $325 to household budget? (optional)
- ✅ I've removed the couch task from your active items

Want to sell anything else?
""")

// Clean up task state
try await storage.move(
    from: "tasks/active/marketplace-couch.json",
    to: "tasks/completed/marketplace-couch-\(timestamp).json"
)
```

---

### Flow 4: "Grandma missed her check-in" — Elder Care Escalation

**User context:** Grandma (72, lives alone, diabetes) has a scheduled 9:00 AM check-in. She doesn't respond.

#### Escalation chain implementation

```swift
// ElderCareScheduler.swift

struct EscalationLevel {
    let delay: TimeInterval
    let action: EscalationAction
}

enum EscalationAction {
    case retry
    case alertPrimary
    case alertAllFamily
    case suggestEmergency
}

let escalationChain: [EscalationLevel] = [
    EscalationLevel(delay: 0,    action: .retry),           // Immediate retry
    EscalationLevel(delay: 900,  action: .retry),           // 15 min: retry again
    EscalationLevel(delay: 1800, action: .alertPrimary),    // 30 min: alert primary caregiver
    EscalationLevel(delay: 3600, action: .alertAllFamily),  // 1 hour: alert everyone
    EscalationLevel(delay: 5400, action: .suggestEmergency) // 1.5 hours: suggest 911
]

func handleMissedCheckIn(elder: ElderProfile, level: Int = 0) async {
    guard level < escalationChain.count else { return }
    let step = escalationChain[level]

    switch step.action {
    case .retry:
        // Try calling again
        let reached = try await initiateCheckIn(elder: elder)
        if !reached {
            scheduler.schedule(
                once: Date().addingTimeInterval(escalationChain[level + 1].delay - step.delay),
                action: .elderEscalation(elderId: elder.id, level: level + 1)
            )
        }

    case .alertPrimary:
        // Notify the primary caregiver (the user)
        notify(
            member: elder.primaryCaregiver,
            message: """
            ⚠️ \(elder.name) hasn't responded to check-in.

            Last successful check-in: \(elder.lastCheckIn?.formatted() ?? "Unknown")
            Attempts: \(level) calls, no answer

            Options:
            1. I'll keep trying
            2. Call \(elder.name) yourself: \(elder.phone)
            3. Contact a neighbor
            """
        )

    case .alertAllFamily:
        // Notify all family members on the elder's contact list
        for contact in elder.emergencyContacts {
            notify(
                member: contact,
                message: """
                🚨 \(elder.name) WELLNESS ALERT

                Has not responded to check-in for 1 hour.
                Last check-in: \(elder.lastCheckIn?.formatted() ?? "Unknown")
                Phone: \(elder.phone)
                Address: \(elder.address)

                Please attempt contact or visit if nearby.
                """
            )
        }

    case .suggestEmergency:
        notify(
            member: elder.primaryCaregiver,
            message: """
            🚨🚨 URGENT: \(elder.name) — No response for 1.5 hours

            All contact attempts have failed.

            ⚠️ APPROVAL REQUIRED
            Should I help arrange a wellness check?
            - Option 1: Call non-emergency police line for welfare check
            - Option 2: Call \(elder.name)'s nearest neighbor: \(elder.nearestNeighbor?.phone ?? "N/A")
            - Option 3: Call 911

            Reply with your choice or call 911 directly.
            """
        )
    }

    // Log every escalation step
    try await storage.write(
        path: "data/elder_care/check_ins/escalation-\(Int(Date().timeIntervalSince1970)).json",
        data: EscalationLog(
            elderId: elder.id,
            level: level,
            action: step.action,
            timestamp: Date(),
            resolved: false
        )
    )
}
```

#### Timeline

```
9:00 AM — Scheduled check-in fires → call Grandma
9:00 AM — No answer → log, schedule retry
9:15 AM — Retry #1 → no answer
9:30 AM — Alert primary caregiver (user): "Mom hasn't responded"
10:00 AM — Alert all family members
10:30 AM — Suggest emergency welfare check (if still no response)
```

#### De-escalation

```swift
// At any point, if Grandma answers or someone confirms she's OK:
func resolveEscalation(elderId: String, resolution: String) async {
    // Cancel all pending escalation tasks
    scheduler.cancelAll(matching: .elderEscalation(elderId: elderId))

    // Log resolution
    try await storage.write(
        path: "data/elder_care/check_ins/\(Date().formatted()).json",
        data: CheckInLog(
            elderId: elderId,
            resolved: true,
            resolution: resolution,
            timestamp: Date()
        )
    )

    // Notify anyone who was alerted
    notifyAll(elder.emergencyContacts, message: "✅ \(elder.name) is OK. \(resolution)")
}
```

---

## Proactive Flows (App-Initiated)

### Flow 5: Medication Refill Warning

**Trigger:** Daily scheduled check at 8:00 AM scans medication refill dates.

```swift
// SkillScheduler.swift — runs daily at 8:00 AM

func checkMedicationRefills() async {
    guard let meds = try? await storage.read(
        path: "data/health/medications.json",
        type: [Medication].self
    ) else { return }

    let today = Date()
    let calendar = Calendar.current

    for med in meds where med.refillDate != nil && med.isActive {
        let daysUntilRefill = calendar.dateComponents(
            [.day], from: today, to: med.refillDate!
        ).day ?? 0

        switch daysUntilRefill {
        case 1...3:
            // Urgent — include call-to-action
            notify(
                member: med.memberId,
                message: """
                💊 REFILL URGENT — \(med.name)

                Runs out in \(daysUntilRefill) day\(daysUntilRefill == 1 ? "" : "s")!

                Quick refill:
                📞 Call \(med.pharmacy.phone)
                🌐 \(med.pharmacy.website)
                Rx #: \(med.rxNumber ?? "check bottle")

                Want me to call the pharmacy for you?
                """
            )
        case 4...7:
            // Reminder — low pressure
            notify(
                member: med.memberId,
                message: "💊 \(med.name) refill needed in \(daysUntilRefill) days. Pharmacy: \(med.pharmacy.name). Want me to help?"
            )
        default:
            break
        }
    }
}
```

**If user says "Yes, call the pharmacy":**

```swift
// Handoff to telephony
return .handoff(HandoffRequest(
    targetSkill: "telephony",
    reason: "Medication refill phone call",
    context: [
        "business_name": med.pharmacy.name,
        "phone": med.pharmacy.phone,
        "purpose": "prescription refill",
        "rx_number": med.rxNumber ?? "unknown",
        "medication": med.name,
        "member_name": med.memberName
    ]
))
```

---

### Flow 6: Dinner Planning Nudge (4:30 PM)

**Trigger:** Daily at 4:30 PM, check if dinner is planned.

```swift
// SkillScheduler.swift — runs daily at 4:30 PM

func checkDinnerPlan() async {
    let today = Date().formatted(date: .abbreviated, time: .omitted)

    // Check if meal is already planned
    let mealPlan = try? await storage.read(
        path: "data/meal_plan.json",
        type: MealPlan.self
    )

    let hasDinnerPlanned = mealPlan?.dinnerFor(today) != nil

    guard !hasDinnerPlanned else { return }

    // Load recent meals to avoid repeats
    let recentMeals = try? await storage.read(
        path: "memory/meal_history.json",
        type: [MealEntry].self
    )
    let last3 = recentMeals?.suffix(3).map(\.meal) ?? []

    // Generate suggestion (avoiding recent meals)
    let allQuickMeals = ["Tacos", "Pasta", "Stir fry", "Soup & sandwiches",
                          "Pizza", "Grilled chicken", "Quesadillas", "Fried rice"]
    let suggestion = allQuickMeals.first { !last3.contains($0) } ?? "Tacos"

    notify(
        member: "primary_parent",
        message: """
        🍽️ No dinner planned yet!

        💡 How about \(suggestion) tonight?
        - Time: ~20 min
        - Effort: easy
        - Why: haven't had it this week

        Alternatives:
        - \(allQuickMeals.filter { $0 != suggestion && !last3.contains($0) }.prefix(2).joined(separator: "\n- "))

        Sound good? Or what are you in the mood for?
        """
    )
}
```

---

### Flow 7: Wellness Nudge — Low Steps at 6 PM

**Trigger:** HealthKit data check at 6:00 PM.

```swift
// SkillScheduler.swift — runs daily at 6:00 PM

func checkStepCount() async {
    guard let healthData = try? await healthKit.readSteps(for: .today) else { return }

    let stepGoal = try? await storage.read(
        path: "memory/wellness_goals.json",
        type: WellnessGoals.self
    )?.dailySteps ?? 8000

    let currentSteps = healthData.steps
    let percentComplete = Double(currentSteps) / Double(stepGoal)

    // Check user's stress level for adaptive nudging (from habits skill pattern)
    let stressLevel = try? await detectStressLevel()

    switch (percentComplete, stressLevel) {
    case (0.8..., _):
        // On track — no nudge needed
        break

    case (0.5..<0.8, .low):
        notify(member: "user", message: """
        🚶 You're at \(currentSteps) steps (\(Int(percentComplete * 100))% of \(stepGoal)).
        A 15-minute walk after dinner gets you there! 🌅
        """)

    case (0.5..<0.8, .medium), (0.5..<0.8, .high):
        notify(member: "user", message: """
        🚶 \(currentSteps) steps today. No pressure — even a short walk helps.
        Or skip it and rest. You know what you need. ❤️
        """)

    case (..<0.5, .low):
        notify(member: "user", message: """
        🚶 Only \(currentSteps) steps today. Still time for a walk!
        Even 10 minutes makes a difference. Want a reminder in 30 min?
        """)

    case (..<0.5, _):
        // High stress + low steps → be gentle
        // Don't nudge at all, or very light
        break

    default:
        break
    }
}
```

---

## Scheduled Flows (Time-Driven)

### Flow 8: Morning Briefing — Mental Load Orchestration

**Schedule:** 7:00 AM daily (configurable in `memory/briefing_config.json`)

This is the most complex scheduled flow. It pulls from nearly every skill's storage.

```swift
// MorningBriefingGenerator.swift

func generateMorningBriefing() async -> String {
    let today = Date()
    let isWeekend = Calendar.current.isDateInWeekend(today)

    // Gather from ALL sources in parallel
    async let calendarEvents = storage.read(path: "data/calendar.json", type: [CalendarEvent].self)
    async let tasks = storage.read(path: "tasks/active/", type: [HomeTask].self)
    async let medications = storage.read(path: "data/health/medications.json", type: [Medication].self)
    async let weatherData = weatherService.forecast(for: .today)
    async let mealPlan = storage.read(path: "data/meal_plan.json", type: MealPlan.self)
    async let reminders = storage.read(path: "data/reminders.json", type: [Reminder].self)
    async let elderStatus = storage.read(path: "data/elder_care/check_ins/latest.json", type: CheckInLog.self)
    async let habits = storage.read(path: "data/habits/active_habits.json", type: [Habit].self)
    async let schoolEvents = storage.read(path: "data/school/events.json", type: [SchoolEvent].self)
    async let healthTracking = storage.read(path: "data/health/hydration_tracking.json", type: HydrationGoal.self)

    // Assemble context
    let context = BriefingContext(
        date: today,
        isWeekend: isWeekend,
        events: (try? await calendarEvents)?.filter { $0.isToday } ?? [],
        tasks: (try? await tasks)?.filter { $0.dueDate == today } ?? [],
        medications: (try? await medications)?.filter { $0.isActive } ?? [],
        weather: try? await weatherData,
        dinner: try? await mealPlan?.dinnerFor(today),
        reminders: (try? await reminders)?.filter { $0.isToday } ?? [],
        elderStatus: try? await elderStatus,
        habits: (try? await habits) ?? [],
        schoolEvents: isWeekend ? [] : ((try? await schoolEvents)?.filter { $0.isToday } ?? []),
        sickMembers: try? await healthTracking  // From Flow 1
    )

    // Build briefing using template
    return buildBriefing(from: context)
}

func buildBriefing(from ctx: BriefingContext) -> String {
    var sections: [String] = []

    // Header
    let dayName = ctx.date.formatted(.dateTime.weekday(.wide))
    let dateStr = ctx.date.formatted(date: .abbreviated, time: .omitted)
    sections.append("☕ GOOD MORNING! \(dayName), \(dateStr)")

    // Weather
    if let w = ctx.weather {
        sections.append("🌤️ Weather: \(w.conditions), \(w.tempF)°F")
    }

    // Sick family members (from active health tracking)
    if let sick = ctx.sickMembers {
        sections.append("🤒 \(sick.memberName) is home sick — hydration tracking active")
    }

    // Top 3 priorities
    let priorities = prioritize(events: ctx.events, tasks: ctx.tasks, reminders: ctx.reminders)
    sections.append("""
    🚨 Top 3 today:
    \(priorities.prefix(3).enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
    """)

    // Schedule
    if !ctx.events.isEmpty {
        sections.append("""
        📅 Schedule:
        \(ctx.events.map { "- \($0.time): \($0.title)" }.joined(separator: "\n"))
        """)
    }

    // School (weekdays only)
    if !ctx.isWeekend && !ctx.schoolEvents.isEmpty {
        sections.append("""
        🏫 School:
        \(ctx.schoolEvents.map { "- \($0.summary)" }.joined(separator: "\n"))
        """)
    }

    // Medications
    if !ctx.medications.isEmpty {
        sections.append("""
        💊 Medications:
        \(ctx.medications.map { "- \($0.name) \($0.dosage) at \($0.timeOfDay)" }.joined(separator: "\n"))
        """)
    }

    // Habits
    if !ctx.habits.isEmpty {
        sections.append("""
        🎯 Habits:
        \(ctx.habits.map { "- ☐ \($0.name) (streak: \($0.streak) days 🔥)" }.joined(separator: "\n"))
        """)
    }

    // Dinner
    if let dinner = ctx.dinner {
        sections.append("🍽️ Dinner plan: \(dinner)")
    } else {
        sections.append("🍽️ No dinner planned — I'll nudge you at 4:30")
    }

    // Elder care
    if let elder = ctx.elderStatus {
        sections.append("👵 \(elder.name): Last check-in \(elder.timeAgo) — \(elder.mood)")
    }

    return sections.joined(separator: "\n\n")
}
```

#### The Full Daily Cycle

```
7:00 AM  — ☕ Morning Briefing (collects from all skills)
8:00 AM  — 💊 Medication refill check
9:00 AM  — 👵 Elder morning check-in
12:00 PM — 🎯 Mid-day habit check-in: "Today's habits: [list]. How's it going?"
4:00 PM  — 📚 School daily check (weekdays)
4:30 PM  — 🍽️ Dinner nudge (if no plan)
6:00 PM  — 🚶 Wellness step check
7:00 PM  — 👵 Elder evening check-in
9:00 PM  — 🌙 Evening wind-down:
                ✅ What got done
                📅 Tomorrow preview
                ☐ Prep checklist
```

Implementation of the daily schedule:

```swift
// SkillScheduler.swift

func configureDailyCycle(config: BriefingConfig) {
    // Morning
    schedule(daily: config.morningTime ?? "07:00", action: .morningBriefing)
    schedule(daily: "08:00", action: .medicationRefillCheck)
    schedule(daily: "09:00", action: .elderCheckIn(type: .morning))

    // Mid-day
    schedule(daily: "12:00", action: .habitCheckIn(type: .midDay))

    // Afternoon
    if !Calendar.current.isDateInWeekend(Date()) {
        schedule(daily: "16:00", action: .schoolDailyCheck)
    }
    schedule(daily: "16:30", action: .dinnerNudge)

    // Evening
    schedule(daily: "18:00", action: .wellnessStepCheck)
    schedule(daily: "19:00", action: .elderCheckIn(type: .evening))
    schedule(daily: config.eveningTime ?? "21:00", action: .eveningWindDown)
}
```

---

### Flow 9: Weekly School Summary

**Schedule:** Friday 4:00 PM (configurable)

```swift
// SchoolSkill — weekly aggregation

func generateWeeklySummary() async -> String {
    let children = try await storage.read(path: "data/family.json", type: Family.self)
        .members.filter { $0.role == .child }

    var report = "📚 WEEKLY SCHOOL REPORT — Week of \(weekDateRange())\n"

    for child in children {
        let weekData = try await storage.read(
            path: "data/school/weekly/\(child.id)-\(weekId()).json",
            type: WeeklySchoolData.self
        )

        report += """

        ━━━ \(child.name.uppercased()) (\(child.grade)) ━━━

        ✅ Completed: \(weekData.completed) of \(weekData.total) assignments
        📊 Grade changes:
        \(weekData.gradeChanges.map { "- \($0.subject): \($0.oldGrade)% → \($0.newGrade)% \($0.trend)" }.joined(separator: "\n"))
        ⏰ Study time logged: \(weekData.studyHours) hours
        🎯 Next week priorities:
        \(weekData.priorities.map { "- \($0)" }.joined(separator: "\n"))
        """

        // Flag concerns
        if weekData.completionRate < 0.8 {
            report += "\n⚠️ Completion rate below 80% — check in with \(child.name)"
        }
        for change in weekData.gradeChanges where change.newGrade < 80 {
            report += "\n⚠️ \(change.subject) dropped below 80%"
        }
    }

    // Parent action items
    report += """

    ━━━ PARENT ACTION ITEMS ━━━
    \(generateParentActions(children).map { "☐ \($0)" }.joined(separator: "\n"))

    🎉 WINS THIS WEEK:
    \(generateWins(children).map { "- \($0)" }.joined(separator: "\n"))
    """

    // Save report
    try await storage.write(
        path: "data/school/weekly/\(weekId()).json",
        data: report
    )

    return report
}
```

---

### Flow 10: Habit Streak Check-in

**Schedule:** Daily at configured times (default: morning + evening)

```swift
// HabitsSkill — adaptive check-in

func dailyCheckIn(type: CheckInType) async -> String {
    let habits = try await storage.read(
        path: "data/habits/active_habits.json",
        type: [Habit].self
    )
    guard !habits.isEmpty else { return "" }

    // Detect stress level from context
    let stressLevel = await detectStressLevel()

    switch type {
    case .morning:
        let habitList = habits.map { "☐ \($0.name) (\($0.tinyVersion))" }.joined(separator: "\n")

        switch stressLevel {
        case .low:
            return """
            🌅 Today's habits:
            \(habitList)

            Feeling? 💪 Ready / 😐 Meh / 😓 Struggling
            🔥 Remember your why: \(habits.first?.motivator ?? "consistency builds confidence")
            """
        case .medium:
            return """
            🌅 Today's habits (no pressure — tiny versions count):
            \(habitList)

            Start with the easiest one. Momentum builds. 🌊
            """
        case .high:
            return """
            🌅 Tough day ahead? Self-care IS the habit today.
            If you can, just one tiny thing: \(habits.first?.tinyVersion ?? "2 minutes")
            No guilt if you skip. Rest matters too. ❤️
            """
        }

    case .evening:
        return """
        🌙 How did today go?
        \(habits.map { "\($0.name): Done ✅ / No ❌ / Partial 〰️" }.joined(separator: "\n"))
        """
    }
}

/// Detect stress from multiple signals
func detectStressLevel() async -> StressLevel {
    // Check recent messages for stress keywords
    let recentMessages = try? await storage.read(
        path: "memory/recent_context.json",
        type: RecentContext.self
    )

    if let msg = recentMessages?.lastMessage?.lowercased() {
        if msg.contains("stressed") || msg.contains("overwhelmed") || msg.contains("terrible") {
            return .high
        }
        if msg.contains("busy") || msg.contains("a lot going on") || msg.contains("meh") {
            return .medium
        }
    }

    // Check calendar density
    let todayEvents = try? await storage.read(
        path: "data/calendar.json",
        type: [CalendarEvent].self
    )?.filter { $0.isToday }

    if (todayEvents?.count ?? 0) > 5 {
        return .medium  // Busy day
    }

    return .low
}
```

#### Streak management

```swift
func logHabitCompletion(habitId: String, status: CompletionStatus) async {
    var habit = try await storage.read(
        path: "data/habits/active_habits.json",
        type: [Habit].self
    ).first { $0.id == habitId }!

    switch status {
    case .complete:
        habit.streak += 1
        habit.totalCompletions += 1
        let milestone = checkMilestone(habit.streak)

        var response = "🎉 \(habit.name) ✅ Streak: \(habit.streak) days 🔥"
        if let ms = milestone {
            response += "\n\n🏆 \(ms)"  // "7 days: You proved you can start."
        }
        notify(member: "user", message: response)

    case .missed:
        if habit.streak > 7 {
            // Significant streak broken — trigger relapse support
            notify(member: "user", message: """
            💬 STREAK PAUSED — \(habit.name)
            Your \(habit.streak)-day streak paused. You built \(habit.streak) days — you CAN do this.
            One miss doesn't erase progress. What happened?
            """)
        }
        // Mercy rule: 1 miss pauses streak, doesn't reset to 0
        habit.streakPaused = true

    case .partial:
        // Partial counts — streak continues
        habit.streak += 1
        notify(member: "user", message: "👍 Showed up — that counts. Streak: \(habit.streak) days")
    }

    try await storage.write(path: "data/habits/active_habits.json", data: habit)
    try await storage.write(
        path: "data/habits/habit_log.json",
        data: HabitLogEntry(habitId: habitId, date: Date(), status: status),
        mode: .append
    )
}
```

---

## Implementation Patterns

### Pattern: Info Gathering Loop

Skills often need multiple pieces of information. This pattern collects them progressively:

```swift
// InfoGatherer.swift

struct InfoRequirement {
    let key: String
    let question: String
    let required: Bool
    let defaultValue: String?
    let validator: ((String) -> Bool)?
}

func gatherInfo(
    requirements: [InfoRequirement],
    have: [String: String],
    taskId: String
) async -> SkillResult {
    let missing = requirements.filter { req in
        req.required && have[req.key] == nil
    }

    if missing.isEmpty {
        return .ready(have)  // All info collected, proceed
    }

    // Ask for up to 3 missing items at once (don't overwhelm)
    let toAsk = missing.prefix(3)
    let questions = toAsk.enumerated().map { "\($0.offset + 1). \($0.element.question)" }

    // Save partial state for multi-turn
    try await storage.write(
        path: "tasks/active/\(taskId).json",
        data: GatheringState(requirements: requirements, collected: have)
    )

    return .response(questions.joined(separator: "\n"))
}

// On next message, check for active gathering tasks
func checkActiveGathering(message: String) async -> (String, GatheringState)? {
    let activeTasks = try? await storage.listFiles(path: "tasks/active/")
    for task in activeTasks ?? [] {
        if let state = try? await storage.read(path: task, type: GatheringState.self) {
            if state.isGathering {
                return (task, state)
            }
        }
    }
    return nil
}
```

### Pattern: Approval Gate

All HIGH-risk actions must go through this gate. MEDIUM-risk actions go through once and are remembered.

```swift
// ApprovalGate.swift

func requestApproval(
    action: String,
    details: [String],
    risk: RiskLevel,
    skill: String,
    onApproved: @escaping @Sendable () async throws -> SkillResult
) -> SkillResult {

    switch risk {
    case .low:
        // No approval needed — just do it
        return try await onApproved()

    case .medium:
        // Check if previously approved for this action type
        let approvals = try? await storage.read(
            path: "memory/approvals.json",
            type: [String: Bool].self
        )
        if approvals?["\(skill):\(action)"] == true {
            return try await onApproved()
        }
        // Fall through to ask
        fallthrough

    case .high:
        return .needsApproval(ApprovalRequest(
            description: action,
            details: details,
            riskLevel: risk,
            onDecision: { approved in
                if approved {
                    // For MEDIUM, remember approval
                    if risk == .medium {
                        var approvals = (try? await storage.read(
                            path: "memory/approvals.json",
                            type: [String: Bool].self
                        )) ?? [:]
                        approvals["\(skill):\(action)"] = true
                        try await storage.write(path: "memory/approvals.json", data: approvals)
                    }
                    return try await onApproved()
                }
                return .response("Cancelled.")
            }
        ))
    }
}
```

Approval prompt format (matches infrastructure skill):

```swift
func formatApprovalPrompt(_ request: ApprovalRequest) -> String {
    """
    ⚠️ APPROVAL REQUIRED
    Action: \(request.description)
    Details:
    \(request.details.map { "- \($0)" }.joined(separator: "\n"))
    Risk: \(request.riskLevel.rawValue.uppercased())

    Reply YES to proceed or NO to cancel.
    """
}

// Parse user response
func isApproved(_ message: String) -> Bool {
    let approved = ["yes", "yep", "yeah", "approved", "go ahead", "do it", "proceed", "call"]
    return approved.contains(message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
}

func isDenied(_ message: String) -> Bool {
    let denied = ["no", "cancel", "stop", "wait", "nevermind", "never mind"]
    return denied.contains(message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
}

// "maybe", "I guess", "sure" → AMBIGUOUS → ask again
func isAmbiguous(_ message: String) -> Bool {
    return !isApproved(message) && !isDenied(message)
}
```

### Pattern: Contextual Enrichment

Before passing a message to any skill, the orchestrator enriches it with ambient context:

```swift
// ContextBuilder.swift

func buildContext(intent: UserIntent, member: FamilyMember) async throws -> SkillContext {
    // 1. Load family data
    let family = try await storage.read(path: "data/family.json", type: Family.self)

    // 2. Load today's calendar
    let calendar = (try? await storage.read(
        path: "data/calendar.json",
        type: [CalendarEvent].self
    ))?.filter { $0.isToday } ?? []

    // 3. Recent conversation (last 5 messages for multi-turn context)
    let recentMessages = try? await storage.read(
        path: "memory/recent_context.json",
        type: RecentContext.self
    )

    // 4. Active tasks/reminders
    let activeTasks = try? await storage.listFiles(path: "tasks/active/")

    // 5. HealthKit data (if available and permitted)
    let healthData: HealthSnapshot? = {
        guard HealthKitManager.isAuthorized else { return nil }
        return try? await HealthKitManager.shared.todaySnapshot()
        // Contains: steps, heartRate, sleep, activeCalories
    }()

    // 6. Location (if available and permitted)
    let location: Location? = LocationManager.shared.lastKnownLocation

    // 7. Time context
    let timeContext = TimeContext(
        date: Date(),
        timeZone: .current,
        isWeekend: Calendar.current.isDateInWeekend(Date()),
        timeOfDay: classifyTimeOfDay(Date())  // morning/afternoon/evening/night
    )

    // 8. Build enriched intent
    let enrichedIntent = UserIntent(
        rawMessage: intent.rawMessage,
        keywords: intent.keywords,
        entities: EntityExtractor.extract(
            from: intent.rawMessage,
            family: family,
            calendar: calendar
        ),
        urgency: intent.urgency
    )

    return SkillContext(
        family: family,
        calendar: calendar,
        storage: storage,
        llm: llm,
        intent: enrichedIntent,
        currentDate: Date(),
        timeZone: .current
    )
}

enum TimeOfDay {
    case earlyMorning  // 5-8 AM
    case morning       // 8-12 PM
    case afternoon     // 12-5 PM
    case evening       // 5-9 PM
    case night         // 9 PM - 5 AM
}
```

### Pattern: Storage as Shared Memory

Skills communicate through storage. This is the complete layout:

```
~/clawd/homeos/
│
├── data/                              # Structured data (all skills read/write)
│   ├── family.json                    # Family members, roles, ages, preferences
│   ├── calendar.json                  # All events (medical, school, social, tasks)
│   ├── reminders.json                 # Active reminders
│   ├── meal_plan.json                 # Weekly meal plan
│   ├── weekly_plan.json               # Weekly overview
│   │
│   ├── health/
│   │   ├── family_health.json         # Member profiles, allergies, doctors
│   │   ├── medications.json           # Active meds, schedules, refill dates
│   │   ├── appointments.json          # Past and upcoming appointments
│   │   └── hydration_tracking.json    # Active hydration goals (sick members)
│   │
│   ├── habits/
│   │   ├── active_habits.json         # Current habits, streaks, stages
│   │   ├── habit_log.json             # Daily completion log
│   │   ├── barriers.json              # Identified barriers per habit
│   │   └── motivators.json            # What motivates each member
│   │
│   ├── school/
│   │   ├── monitoring.json            # Monitoring config (times, thresholds)
│   │   ├── events.json                # School events, deadlines
│   │   └── weekly/                    # Weekly report archives
│   │       └── 2025-W03.json
│   │
│   └── elder_care/
│       ├── [parent_id].json           # Elder profiles
│       ├── health_log.json            # Health trends
│       ├── medications/               # Elder-specific med tracking
│       └── check_ins/
│           ├── latest.json            # Most recent check-in
│           └── 2025-01-15.json        # Historical logs
│
├── memory/                            # Preferences, learnings (long-lived)
│   ├── dining.json                    # Restaurant preferences
│   ├── restaurants.json               # Visited restaurants + ratings
│   ├── meal_history.json              # What the family has eaten recently
│   ├── briefing_config.json           # Morning/evening briefing preferences
│   ├── approvals.json                 # Remembered MEDIUM-risk approvals
│   ├── wellness_goals.json            # Step goals, hydration targets
│   ├── elder_stories.json             # Captured family stories/wisdom
│   ├── recent_context.json            # Last 5 messages for multi-turn
│   ├── preferences/
│   │   └── health_prefs.json          # Notification prefs, pharmacy choices
│   └── learnings/
│       ├── habit_patterns.json        # What time of day works for habits
│       └── what_works.json            # Strategies that helped
│
├── tasks/                             # Task state machine
│   ├── active/                        # Currently in-progress
│   │   ├── marketplace-couch.json     # Multi-step: selling couch
│   │   └── wellness-emma-fever.json   # Multi-step: tracking Emma's recovery
│   ├── pending/                       # Waiting on user input/approval
│   │   └── approval-1705234567.json   # Pending approval request
│   └── completed/                     # Done (archived)
│       └── marketplace-couch-1705234567.json
│
└── logs/                              # Audit trail
    ├── actions.log                    # All skill actions (timestamped)
    └── calls.json                     # Telephony call log
```

#### How skills share state — examples:

```swift
// Healthcare writes → Wellness reads
// Healthcare:
try await storage.write(path: "data/health/hydration_tracking.json", data: hydrationGoal)
// Wellness:
let goal = try await storage.read(path: "data/health/hydration_tracking.json", type: HydrationGoal.self)

// School writes → Mental-load reads for briefing
// School:
try await storage.write(path: "data/school/events.json", data: todayEvents)
// Mental-load:
let schoolEvents = try await storage.read(path: "data/school/events.json", type: [SchoolEvent].self)

// Any skill writes → Calendar aggregates
// Restaurant:
try await storage.write(path: "data/calendar.json", data: reservationEvent, mode: .append)
// Healthcare:
try await storage.write(path: "data/calendar.json", data: appointmentEvent, mode: .append)
// Morning briefing reads ALL calendar events
let allEvents = try await storage.read(path: "data/calendar.json", type: [CalendarEvent].self)
```

---

## Error Handling & Edge Cases

### LLM is slow or unresponsive

```swift
func executeWithTimeout<T>(_ work: @Sendable () async throws -> T, timeout: TimeInterval = 15) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await work() }
        group.addTask {
            try await Task.sleep(for: .seconds(timeout))
            throw SkillError.timeout
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

// Usage in orchestrator
do {
    let result = try await executeWithTimeout({ try await skill.execute(context: ctx) })
    // handle result
} catch SkillError.timeout {
    // Fallback: use template-based response without LLM
    return .response(skill.fallbackResponse(for: intent))
}
```

Every skill should have a `fallbackResponse` that works without LLM — this is why the skill docs use fill-in-the-blank templates.

### Handoff target doesn't exist

```swift
case .handoff(let request):
    guard let nextSkill = registry.find(request.targetSkill) else {
        // Log the error
        log(.error, skill: skill.name, "Handoff target '\(request.targetSkill)' not found")

        // Tell the user gracefully
        return .response("""
        I was going to hand this off to \(request.targetSkill), but that feature isn't available yet.

        Here's what I can tell you:
        - Reason for handoff: \(request.reason)
        - Context: \(request.context.values.joined(separator: ", "))

        Want me to try something else?
        """)
    }
```

### Storage is corrupted

```swift
func safeRead<T: Decodable>(path: String, type: T.Type, default defaultValue: T) async -> T {
    do {
        return try await storage.read(path: path, type: type)
    } catch {
        // Log corruption
        log(.error, skill: "storage", "Corrupted file at \(path): \(error)")

        // Backup corrupted file
        try? await storage.move(from: path, to: "\(path).corrupted.\(Int(Date().timeIntervalSince1970))")

        // Return default
        return defaultValue
    }
}

// Usage
let meds = await safeRead(
    path: "data/health/medications.json",
    type: [Medication].self,
    default: []
)
```

### User cancels mid-flow

```swift
func handleCancel(activeTask: String) async -> SkillResult {
    // 1. Confirm
    // (After user confirms cancellation:)

    // 2. Clean up task state
    let taskData = try? await storage.read(path: "tasks/active/\(activeTask)", type: TaskState.self)
    try? await storage.move(
        from: "tasks/active/\(activeTask)",
        to: "tasks/completed/\(activeTask)-cancelled"
    )

    // 3. Cancel scheduled follow-ups
    if let followUps = taskData?.scheduledFollowUps {
        for followUp in followUps {
            scheduler.cancel(followUp)
        }
    }

    // 4. Log
    log(.info, skill: taskData?.skill ?? "unknown", "Task cancelled by user: \(activeTask)")

    return .response("Cancelled. \(taskData?.friendlyDescription ?? "Task") stopped.")
}
```

### Two skills conflict (both want to send a notification)

```swift
// NotificationCoordinator.swift

actor NotificationCoordinator {
    private var recentNotifications: [(Date, String, String)] = []  // (time, skill, member)

    func shouldSend(skill: String, member: String, message: String) -> Bool {
        let now = Date()

        // Don't send more than 3 notifications in 30 minutes to same member
        let recentToMember = recentNotifications.filter {
            $0.2 == member && now.timeIntervalSince($0.0) < 1800
        }
        if recentToMember.count >= 3 {
            // Queue for later instead of dropping
            scheduler.schedule(
                once: Date().addingTimeInterval(1800),
                action: .deferredNotification(skill: skill, member: member, message: message)
            )
            return false
        }

        // Don't send same-skill notification within 5 minutes
        let recentFromSkill = recentNotifications.filter {
            $0.1 == skill && $0.2 == member && now.timeIntervalSince($0.0) < 300
        }
        if !recentFromSkill.isEmpty {
            return false  // Deduplicate
        }

        recentNotifications.append((now, skill, member))
        return true
    }

    /// Batch multiple pending notifications into one message
    func batchPending(for member: String) -> String? {
        // Combine queued notifications into a single digest
        let pending = pendingQueue.filter { $0.member == member }
        guard pending.count >= 2 else { return nil }

        return """
        📬 Updates:
        \(pending.map { "• \($0.message)" }.joined(separator: "\n"))
        """
    }
}
```

### Network failure during external calls

```swift
func withRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 2,
    _ work: () async throws -> T
) async throws -> T {
    var lastError: Error?
    for attempt in 1...maxAttempts {
        do {
            return try await work()
        } catch {
            lastError = error
            if attempt < maxAttempts {
                try await Task.sleep(for: .seconds(delay * Double(attempt)))
            }
        }
    }
    throw lastError!
}
```

---

## Quick Reference: Skill Interaction Map

```
User Message
     │
     ▼
┌─────────────┐
│  ChatTurn    │ ← Entry point (routes ALL messages)
│  (Router)    │
└──────┬──────┘
       │ routes to best-fit skill
       ▼
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐   │
│  │ Healthcare  │→│ Wellness  │  │ Restaurant   │   │
│  │ (triage)    │  │ (tracking)│  │ (search/book)│   │
│  └─────┬──────┘  └───────────┘  └──────┬───────┘   │
│        │                                │            │
│        ▼                                ▼            │
│  ┌────────────┐               ┌──────────────┐     │
│  │ School     │               │ Telephony    │     │
│  │ (absence)  │               │ (phone book) │     │
│  └────────────┘               └──────────────┘     │
│                                                      │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐   │
│  │ Mental Load│  │ Habits    │  │ Elder Care   │   │
│  │ (briefing) │  │ (streaks) │  │ (check-ins)  │   │
│  └────────────┘  └───────────┘  └──────────────┘   │
│                                                      │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐   │
│  │ Marketplace│  │ HireHelper│  │ Family Bond  │   │
│  │ (sell)     │  │ (sitter)  │  │ (activities) │   │
│  └────────────┘  └───────────┘  └──────────────┘   │
│                                                      │
└──────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│   Storage    │ ← Shared memory (~/clawd/homeos/)
│  (JSON files)│   All skills read/write here
└──────────────┘
```

### Handoff Pairs (which skills chain to which)

| From | To | When |
|------|----|------|
| Healthcare → | Wellness | Sick member needs recovery tracking |
| Healthcare → | Habits | User wants medication adherence habit |
| Healthcare → | School | Sick child on school day |
| Restaurant → | Telephony | Restaurant requires phone booking |
| Restaurant → | Calendar | Reservation confirmed |
| Elder Care → | Family Comms | Family coordination needed |
| Elder Care → | Mental Load | Caregiver overwhelm |
| Mental Load → | Family Bonding | Activity ideas needed |
| School → | Education | Single-child deep dive |
| Habits → | Wellness | Wellness-related habit |
| Any skill → | Telephony | Phone call needed |

---

## Testing Checklist

Before shipping any flow, verify:

- [ ] **Happy path** — full flow works end-to-end
- [ ] **Missing info** — skill asks for what it needs (doesn't guess)
- [ ] **Cancellation** — user can cancel at any step, state is cleaned up
- [ ] **Handoff chain** — each handoff passes correct context
- [ ] **Approval gate** — HIGH-risk actions block until explicit YES
- [ ] **Ambiguous approval** — "maybe"/"sure" triggers re-ask, not action
- [ ] **Storage** — correct files created/updated after each step
- [ ] **Scheduled follow-ups** — fire at correct times
- [ ] **Error recovery** — graceful message + state saved on failure
- [ ] **Notification dedup** — same notification not sent twice
- [ ] **Stress adaptation** — nudges are gentler when user is stressed
- [ ] **Medical disclaimer** — shown on EVERY healthcare response
