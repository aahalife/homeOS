# Elder Care Skill: Atomic Function Breakdown
## Dignified, Compassionate Wellness Support for Aging Adults

**Version:** 1.0
**Date:** February 2, 2026
**Status:** Implementation Ready

---

## Table of Contents

1. [Skill Overview](#1-skill-overview)
2. [Core Philosophy](#2-core-philosophy)
3. [Atomic Functions](#3-atomic-functions)
4. [Conversational Framework](#4-conversational-framework)
5. [Red Flag Detection](#5-red-flag-detection)
6. [Alert Escalation Protocols](#6-alert-escalation-protocols)
7. [Medication Adherence Tracking](#7-medication-adherence-tracking)
8. [Weekly Report Generation](#8-weekly-report-generation)
9. [Voice Call Workflow](#9-voice-call-workflow)
10. [Example Conversations](#10-example-conversations)
11. [Data Structures](#11-data-structures)
12. [API Integrations](#12-api-integrations)
13. [Test Cases](#13-test-cases)
14. [Error Handling](#14-error-handling)

---

## 1. Skill Overview

### Purpose

The Elder Care skill provides **dignified, compassionate daily wellness check-ins** for aging adults living independently or in assisted living. This is NOT surveillance technology. It's a warm, human-like connection that:

- Reduces social isolation through regular conversation
- Ensures medication adherence with gentle reminders
- Detects early warning signs of health issues
- Provides peace of mind to adult children and caregivers
- Maintains elder autonomy and dignity

### Key Features

- **Daily voice check-ins** (morning and/or evening)
- **Conversational wellness assessment** (not clinical interrogation)
- **Medication tracking** with respectful reminders
- **Music playback** (era-appropriate: 1940s-1970s)
- **Memory sharing** and reminiscence activities
- **Red flag detection** for health concerns
- **Automated alerts** to family when issues arise
- **Weekly summary reports** for adult children

### Design Principles

1. **Dignity First**: Never infantilize or talk down to elders
2. **Connection Over Monitoring**: Build relationship, not just collect data
3. **Autonomy Preservation**: Empower, don't control
4. **Privacy Respect**: Only share what's necessary with family
5. **Warmth & Patience**: Allow time for responses, repeat when needed
6. **Cultural Sensitivity**: Respect generational norms and values

---

## 2. Core Philosophy

### What This IS

- A friendly daily companion
- A safety net for early warning signs
- A bridge between elder and family
- A tool for maintaining independence
- A source of joy (music, conversation, memories)

### What This IS NOT

- Surveillance or monitoring system
- A replacement for human caregivers
- Medical diagnosis or treatment
- A way to restrict elder freedom
- An intrusive interrogation tool

### Conversational Tone

**Good Examples:**
- "Good morning, Dorothy! How are you feeling today?"
- "I wanted to check in with you. Did you have breakfast this morning?"
- "It sounds like you're having a lovely day. Would you like to hear some music?"

**Bad Examples:**
- "Did you take your pills? Answer yes or no."
- "Your daughter wants me to monitor your activities."
- "I'm checking if you're compliant with your medication schedule."

---

## 3. Atomic Functions

### 3.1 Profile & Configuration Functions

#### `getElderProfile(elderId: UUID) async -> ElderCareProfile?`

Retrieves the complete elder care profile including preferences, health data, and schedules.

```swift
func getElderProfile(elderId: UUID) async -> ElderCareProfile? {
    return await CoreDataManager.shared.fetchElderCareProfile(by: elderId)
}
```

**Returns:**
- Full profile with medical history, preferences, contacts
- `nil` if profile doesn't exist

**Use Case:** Called at start of every check-in to load context

---

#### `updateCheckInSchedule(elderId: UUID, schedule: CheckInSchedule) async -> Bool`

Updates the frequency and timing of wellness check-ins.

```swift
func updateCheckInSchedule(elderId: UUID, schedule: CheckInSchedule) async -> Bool {
    guard var profile = await getElderProfile(elderId: elderId) else { return false }
    profile.checkInSchedule = schedule
    return await CoreDataManager.shared.save(profile)
}
```

**Parameters:**
- `schedule`: Contains frequency (daily/twice daily), preferred times, time zone

**Returns:** Success/failure boolean

**Use Case:** Family adjusts check-in frequency based on elder's needs

---

#### `getMedicationList(elderId: UUID) async -> [Medication]`

Retrieves current medications for the elder.

```swift
func getMedicationList(elderId: UUID) async -> [Medication] {
    guard let profile = await getElderProfile(elderId: elderId) else { return [] }
    return profile.medications.filter { $0.isActive }
}
```

**Returns:** Array of active medications with dosage, frequency, timing

**Use Case:** Used during medication adherence checks

---

#### `getMusicPreferences(elderId: UUID) async -> MusicPreferences?`

Retrieves music preferences (genres, artists, eras).

```swift
func getMusicPreferences(elderId: UUID) async -> MusicPreferences? {
    guard let profile = await getElderProfile(elderId: elderId) else { return nil }
    return profile.musicPreferences
}
```

**Returns:** Preferred genres, artists, decades

**Use Case:** Selecting appropriate music during check-ins

---

### 3.2 Check-In Initiation Functions

#### `initiateCheckInCall(elderId: UUID, checkInType: CheckInType) async throws -> CallSession`

Initiates a voice call via Twilio to begin the wellness check-in.

```swift
func initiateCheckInCall(elderId: UUID, checkInType: CheckInType) async throws -> CallSession {
    guard let profile = await getElderProfile(elderId: elderId) else {
        throw ElderCareError.profileNotFound
    }

    guard let phoneNumber = profile.phoneNumber else {
        throw ElderCareError.phoneNumberMissing
    }

    let twilioAPI = TwilioAPI.shared
    let script = await generateCheckInScript(profile: profile, type: checkInType)

    let callResult = try await twilioAPI.makeCall(
        to: phoneNumber,
        script: script
    )

    return CallSession(
        id: UUID(),
        elderId: elderId,
        callSid: callResult.sid,
        startTime: Date(),
        checkInType: checkInType,
        status: .inProgress
    )
}
```

**Parameters:**
- `checkInType`: `.morning`, `.evening`, or `.adhoc`

**Returns:** Active call session object

**Throws:**
- `ElderCareError.profileNotFound`
- `ElderCareError.phoneNumberMissing`
- `TwilioError.*`

**Use Case:** Scheduled or manual check-in initiation

---

#### `generateCheckInScript(profile: ElderCareProfile, type: CheckInType) async -> String`

Generates a personalized TwiML script for the voice call.

```swift
func generateCheckInScript(profile: ElderCareProfile, type: CheckInType) async -> String {
    let greeting = generateGreeting(name: profile.name, time: type)
    let wellnessQuestions = generateWellnessQuestions(healthHistory: profile.healthHistory)
    let medicationReminder = generateMedicationReminder(medications: profile.medications, time: type)
    let closing = generateClosing(name: profile.name)

    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Say voice="Polly.Joanna">\(greeting)</Say>
        <Gather input="speech" timeout="5" speechTimeout="auto" action="/elder-care/wellness-response">
            <Say>\(wellnessQuestions)</Say>
        </Gather>
        <Say>\(medicationReminder)</Say>
        <Gather input="speech" timeout="5" speechTimeout="auto" action="/elder-care/medication-response">
            <Say>Did you take your morning medications?</Say>
        </Gather>
        <Say>\(closing)</Say>
        <Hangup/>
    </Response>
    """
}
```

**Returns:** TwiML XML script for Twilio

**Use Case:** Creating dynamic, personalized call scripts

---

### 3.3 Conversational Functions

#### `generateGreeting(name: String, time: CheckInType) -> String`

Creates a warm, time-appropriate greeting.

```swift
func generateGreeting(name: String, time: CheckInType) -> String {
    let timeGreeting: String
    switch time {
    case .morning:
        timeGreeting = "Good morning"
    case .evening:
        timeGreeting = "Good evening"
    case .adhoc:
        let hour = Calendar.current.component(.hour, from: Date())
        timeGreeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
    }

    return "\(timeGreeting), \(name)! This is your daily check-in from OpenClaw. I hope you're having a wonderful day."
}
```

**Returns:** Personalized greeting string

---

#### `parseWellnessResponse(transcript: String) async -> WellnessAssessment`

Analyzes the elder's response to wellness questions using on-device AI.

```swift
func parseWellnessResponse(transcript: String) async -> WellnessAssessment {
    let gemma3n = ModelManager.shared.chatModel

    let prompt = """
    Analyze this response from an elderly person during a wellness check-in.
    Extract:
    1. Overall mood (positive/neutral/negative)
    2. Energy level (high/normal/low/very low)
    3. Any mentioned pain or discomfort
    4. Any confusion or memory issues
    5. Social engagement level

    Response: "\(transcript)"

    Return JSON with: mood, energyLevel, painMentioned, confusionDetected, socialEngagement
    """

    let aiResponse = await gemma3n.generate(prompt: prompt, maxTokens: 256)

    guard let data = aiResponse.data(using: .utf8),
          let assessment = try? JSONDecoder().decode(WellnessAssessment.self, from: data) else {
        return WellnessAssessment.defaultNeutral()
    }

    return assessment
}
```

**Parameters:**
- `transcript`: Speech-to-text from Twilio

**Returns:** Structured wellness assessment

**Use Case:** Converting natural language to actionable data

---

#### `generateWellnessQuestions(healthHistory: [HealthCondition]) -> String`

Creates personalized wellness questions based on health history.

```swift
func generateWellnessQuestions(healthHistory: [HealthCondition]) -> String {
    var questions = ["How are you feeling today?"]

    if healthHistory.contains(where: { $0.type == .arthritis }) {
        questions.append("How is your joint pain today?")
    }

    if healthHistory.contains(where: { $0.type == .diabetes }) {
        questions.append("Have you been feeling dizzy or unusually thirsty?")
    }

    if healthHistory.contains(where: { $0.type == .heartCondition }) {
        questions.append("Any chest discomfort or shortness of breath?")
    }

    return questions.joined(separator: " ")
}
```

**Returns:** Personalized question string

---

### 3.4 Medication Tracking Functions

#### `generateMedicationReminder(medications: [Medication], time: CheckInType) -> String`

Creates a gentle medication reminder.

```swift
func generateMedicationReminder(medications: [Medication], time: CheckInType) -> String {
    let relevantMeds = medications.filter { med in
        switch time {
        case .morning:
            return med.timing.contains("morning") || med.timing.contains("breakfast")
        case .evening:
            return med.timing.contains("evening") || med.timing.contains("dinner")
        case .adhoc:
            return true
        }
    }

    guard !relevantMeds.isEmpty else {
        return ""
    }

    if relevantMeds.count == 1 {
        return "This is a gentle reminder about your \(relevantMeds[0].name)."
    } else {
        let medNames = relevantMeds.map { $0.name }.joined(separator: ", ")
        return "This is a gentle reminder about your medications: \(medNames)."
    }
}
```

**Returns:** Contextual medication reminder

---

#### `logMedicationCompliance(elderId: UUID, taken: Bool, medications: [Medication], timestamp: Date) async -> Bool`

Records whether medications were taken.

```swift
func logMedicationCompliance(
    elderId: UUID,
    taken: Bool,
    medications: [Medication],
    timestamp: Date
) async -> Bool {
    let complianceRecord = MedicationComplianceRecord(
        id: UUID(),
        elderId: elderId,
        medications: medications,
        taken: taken,
        timestamp: timestamp,
        checkInType: determineCheckInType(for: timestamp)
    )

    return await CoreDataManager.shared.save(complianceRecord)
}
```

**Returns:** Success/failure of logging

**Use Case:** Tracking adherence over time

---

#### `calculateComplianceRate(elderId: UUID, days: Int) async -> Double`

Calculates medication adherence percentage over a time period.

```swift
func calculateComplianceRate(elderId: UUID, days: Int) async -> Double {
    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    let records = await CoreDataManager.shared.fetchComplianceRecords(
        elderId: elderId,
        from: startDate,
        to: Date()
    )

    guard !records.isEmpty else { return 0.0 }

    let takenCount = records.filter { $0.taken }.count
    return Double(takenCount) / Double(records.count) * 100.0
}
```

**Returns:** Percentage (0.0 - 100.0)

**Use Case:** Weekly report generation, identifying trends

---

### 3.5 Red Flag Detection Functions

#### `detectRedFlags(conversation: ConversationLog, assessment: WellnessAssessment) async -> [RedFlag]`

Analyzes conversation and assessment for concerning indicators.

```swift
func detectRedFlags(conversation: ConversationLog, assessment: WellnessAssessment) async -> [RedFlag] {
    var flags: [RedFlag] = []

    // Check for emergency keywords
    let emergencyKeywords = ["fell", "fall", "chest pain", "can't breathe", "dizzy", "bleeding"]
    for keyword in emergencyKeywords {
        if conversation.transcript.lowercased().contains(keyword) {
            flags.append(RedFlag(
                type: .emergencyKeyword(keyword),
                severity: .critical,
                detectedAt: Date(),
                context: conversation.transcript
            ))
        }
    }

    // Check for confusion
    if assessment.confusionDetected {
        flags.append(RedFlag(
            type: .confusion,
            severity: .high,
            detectedAt: Date(),
            context: "Confusion or disorientation detected in conversation"
        ))
    }

    // Check for significant pain
    if assessment.painLevel > 7 {
        flags.append(RedFlag(
            type: .severePain(level: assessment.painLevel),
            severity: .high,
            detectedAt: Date(),
            context: "Reported pain level: \(assessment.painLevel)/10"
        ))
    }

    // Check for unusual fatigue
    if assessment.energyLevel == .veryLow && conversation.timeOfDay != .evening {
        flags.append(RedFlag(
            type: .unusualFatigue,
            severity: .medium,
            detectedAt: Date(),
            context: "Extreme fatigue during \(conversation.timeOfDay) check-in"
        ))
    }

    // Check for mood changes
    if assessment.mood == .negative {
        let recentAssessments = await getRecentAssessments(elderId: conversation.elderId, days: 7)
        let previousNegativeMoods = recentAssessments.filter { $0.mood == .negative }.count

        if previousNegativeMoods >= 3 {
            flags.append(RedFlag(
                type: .persistentLowMood,
                severity: .medium,
                detectedAt: Date(),
                context: "Negative mood for \(previousNegativeMoods + 1) consecutive check-ins"
            ))
        }
    }

    // Check for appetite loss
    if conversation.transcript.lowercased().contains("haven't eaten") ||
       conversation.transcript.lowercased().contains("not hungry") {
        flags.append(RedFlag(
            type: .appetiteLoss,
            severity: .medium,
            detectedAt: Date(),
            context: "Mentioned not eating or lack of appetite"
        ))
    }

    return flags
}
```

**Returns:** Array of red flags with severity levels

**Use Case:** Primary health monitoring function

---

#### `categorizeRedFlagSeverity(flag: RedFlag) -> AlertPriority`

Determines urgency level for family alerts.

```swift
func categorizeRedFlagSeverity(flag: RedFlag) -> AlertPriority {
    switch flag.type {
    case .emergencyKeyword:
        return .immediate // Call 911 + notify family
    case .confusion, .severePain:
        return .urgent // Notify family within 1 hour
    case .unusualFatigue, .persistentLowMood, .appetiteLoss:
        return .standard // Daily digest notification
    case .missedMedication:
        return .standard
    case .socialIsolation:
        return .low // Weekly report
    }
}
```

**Returns:** Priority level for alerting

---

### 3.6 Alert & Notification Functions

#### `sendFamilyAlert(alert: ElderCareAlert, recipients: [EmergencyContact]) async throws -> Bool`

Sends notifications to family members when red flags are detected.

```swift
func sendFamilyAlert(alert: ElderCareAlert, recipients: [EmergencyContact]) async throws -> Bool {
    let notificationManager = NotificationManager.shared

    for contact in recipients {
        // Send push notification if they have the app
        if let deviceToken = contact.deviceToken {
            try await notificationManager.sendPush(
                to: deviceToken,
                title: alert.title,
                body: alert.message,
                priority: alert.priority
            )
        }

        // Send SMS for urgent/immediate alerts
        if alert.priority >= .urgent {
            try await TwilioAPI.shared.sendSMS(
                to: contact.phoneNumber,
                message: alert.smsMessage
            )
        }

        // Call for immediate/emergency alerts
        if alert.priority == .immediate {
            try await TwilioAPI.shared.makeCall(
                to: contact.phoneNumber,
                script: alert.callScript
            )
        }
    }

    return true
}
```

**Parameters:**
- `alert`: Contains message, priority, context
- `recipients`: Family members to notify

**Throws:** Network or API errors

**Returns:** Success boolean

---

#### `generateAlertMessage(redFlags: [RedFlag], elderName: String) -> ElderCareAlert`

Creates a family-friendly alert message from red flags.

```swift
func generateAlertMessage(redFlags: [RedFlag], elderName: String) -> ElderCareAlert {
    let priority = redFlags.map { categorizeRedFlagSeverity(flag: $0) }.max() ?? .low

    let title: String
    let message: String

    switch priority {
    case .immediate:
        title = "Urgent: Immediate attention needed for \(elderName)"
        message = "Emergency keywords detected during check-in. Please contact \(elderName) immediately or call 911."

    case .urgent:
        title = "Health concern for \(elderName)"
        let concerns = redFlags.map { $0.type.description }.joined(separator: ", ")
        message = "During today's check-in, we noticed: \(concerns). Please reach out to \(elderName) soon."

    case .standard:
        title = "Check-in update for \(elderName)"
        message = "We noticed some changes in \(elderName)'s wellness. Review the daily summary for details."

    case .low:
        title = "Weekly update for \(elderName)"
        message = "Here's the weekly wellness summary for \(elderName)."
    }

    return ElderCareAlert(
        id: UUID(),
        title: title,
        message: message,
        priority: priority,
        redFlags: redFlags,
        timestamp: Date()
    )
}
```

**Returns:** Formatted alert ready to send

---

### 3.7 Music & Engagement Functions

#### `playMusic(preferences: MusicPreferences, mood: Mood) async throws -> Bool`

Plays era-appropriate music through Spotify/Apple Music API.

```swift
func playMusic(preferences: MusicPreferences, mood: Mood) async throws -> Bool {
    let musicService = MusicServiceManager.shared

    // Select playlist based on preferences and mood
    let playlist: String
    if mood == .negative {
        playlist = preferences.favoriteGenre.upliftingPlaylist
    } else {
        playlist = preferences.favoriteGenre.standardPlaylist
    }

    // Filter by era (typically 1940s-1970s for elders)
    let tracks = try await musicService.searchTracks(
        genre: preferences.favoriteGenre,
        era: preferences.eraRange,
        limit: 20
    )

    return try await musicService.playPlaylist(tracks: tracks)
}
```

**Returns:** Success/failure

**Use Case:** Providing joy and emotional support

---

#### `suggestMemoryActivity(profile: ElderCareProfile) -> MemoryActivity`

Generates conversation prompts for reminiscence.

```swift
func suggestMemoryActivity(profile: ElderCareProfile) -> MemoryActivity {
    let activities = [
        MemoryActivity(
            prompt: "Tell me about your favorite memory from when you were young.",
            category: .childhood
        ),
        MemoryActivity(
            prompt: "What was your first job like?",
            category: .career
        ),
        MemoryActivity(
            prompt: "Do you remember your wedding day? What was it like?",
            category: .family
        ),
        MemoryActivity(
            prompt: "What was your favorite place to visit?",
            category: .travel
        )
    ]

    // Avoid recently used prompts
    let recentActivities = profile.recentMemoryActivities
    let availableActivities = activities.filter { !recentActivities.contains($0) }

    return availableActivities.randomElement() ?? activities.first!
}
```

**Returns:** Conversation prompt for engagement

---

### 3.8 Logging & Reporting Functions

#### `logCheckIn(session: CallSession, assessment: WellnessAssessment, redFlags: [RedFlag]) async -> Bool`

Records a complete check-in session.

```swift
func logCheckIn(
    session: CallSession,
    assessment: WellnessAssessment,
    redFlags: [RedFlag]
) async -> Bool {
    let checkInLog = CheckInLog(
        id: UUID(),
        elderId: session.elderId,
        timestamp: session.startTime,
        duration: session.duration,
        conversationSummary: session.transcript,
        wellnessScore: assessment.calculateOverallScore(),
        mood: assessment.mood,
        energyLevel: assessment.energyLevel,
        painLevel: assessment.painLevel,
        redFlags: redFlags,
        medicationTaken: session.medicationConfirmed,
        checkInType: session.checkInType
    )

    return await CoreDataManager.shared.save(checkInLog)
}
```

**Returns:** Success boolean

**Use Case:** Building historical record for trend analysis

---

#### `generateWeeklyReport(elderId: UUID, weekStartDate: Date) async -> ElderCareWeeklyReport`

Creates a comprehensive weekly summary for family.

```swift
func generateWeeklyReport(elderId: UUID, weekStartDate: Date) async -> ElderCareWeeklyReport {
    let weekEndDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate)!

    let checkIns = await CoreDataManager.shared.fetchCheckInLogs(
        elderId: elderId,
        from: weekStartDate,
        to: weekEndDate
    )

    let profile = await getElderProfile(elderId: elderId)!

    // Calculate metrics
    let avgWellnessScore = checkIns.map { $0.wellnessScore }.reduce(0.0, +) / Double(checkIns.count)
    let medicationCompliance = await calculateComplianceRate(elderId: elderId, days: 7)
    let redFlags = checkIns.flatMap { $0.redFlags }
    let moodTrend = analyzeMoodTrend(checkIns: checkIns)

    // Generate narrative summary
    let summary = generateReportNarrative(
        elderName: profile.name,
        avgScore: avgWellnessScore,
        compliance: medicationCompliance,
        redFlags: redFlags,
        moodTrend: moodTrend
    )

    return ElderCareWeeklyReport(
        id: UUID(),
        elderId: elderId,
        weekStartDate: weekStartDate,
        weekEndDate: weekEndDate,
        checkInCount: checkIns.count,
        averageWellnessScore: avgWellnessScore,
        medicationCompliance: medicationCompliance,
        redFlags: redFlags,
        moodTrend: moodTrend,
        summary: summary,
        generatedAt: Date()
    )
}
```

**Returns:** Complete weekly report

**Use Case:** Sent to family every Sunday evening

---

#### `generateReportNarrative(elderName: String, avgScore: Double, compliance: Double, redFlags: [RedFlag], moodTrend: MoodTrend) -> String`

Creates a readable narrative summary.

```swift
func generateReportNarrative(
    elderName: String,
    avgScore: Double,
    compliance: Double,
    redFlags: [RedFlag],
    moodTrend: MoodTrend
) -> String {
    var narrative = "\(elderName) had "

    // Overall wellness
    if avgScore >= 8.0 {
        narrative += "an excellent week"
    } else if avgScore >= 6.0 {
        narrative += "a good week"
    } else if avgScore >= 4.0 {
        narrative += "a fair week"
    } else {
        narrative += "a challenging week"
    }

    narrative += ". "

    // Medication compliance
    if compliance >= 90.0 {
        narrative += "Medication adherence was excellent at \(Int(compliance))%. "
    } else if compliance >= 70.0 {
        narrative += "Medication adherence was good at \(Int(compliance))%. "
    } else {
        narrative += "Medication adherence needs attention at \(Int(compliance))%. Consider setting additional reminders. "
    }

    // Mood
    switch moodTrend {
    case .improving:
        narrative += "\(elderName)'s mood has been improving throughout the week. "
    case .stable:
        narrative += "\(elderName)'s mood has been stable and positive. "
    case .declining:
        narrative += "\(elderName)'s mood has been declining. Consider a visit or extra check-in. "
    }

    // Red flags
    if redFlags.isEmpty {
        narrative += "No health concerns were detected."
    } else {
        let concerns = redFlags.map { $0.type.description }.joined(separator: ", ")
        narrative += "Health concerns noted: \(concerns). Please review individual check-in logs for details."
    }

    return narrative
}
```

**Returns:** Human-readable summary

---

## 4. Conversational Framework

### Conversation Flow Structure

Every check-in follows this proven structure:

```
1. WARM GREETING (5-10 seconds)
   - Personalized, time-appropriate
   - Friendly tone, not clinical

2. WELLNESS CHECK (30-45 seconds)
   - Open-ended: "How are you feeling?"
   - Specific: "How's your [condition] today?"
   - Listen actively, allow pauses

3. MEDICATION REMINDER (15-20 seconds)
   - Gentle, not demanding
   - Specific medications by name
   - Confirm without pressure

4. ENGAGEMENT ACTIVITY (60-90 seconds)
   - Music: "Would you like to hear some [genre]?"
   - Memory: "Tell me about [memory prompt]"
   - News: "Would you like to hear today's weather?"

5. POSITIVE CLOSING (10-15 seconds)
   - Affirming: "It's wonderful talking with you"
   - Future-oriented: "I'll check in tomorrow morning"
   - Warm goodbye
```

### Conversation Pacing

- **Allow 3-5 second pauses** before repeating questions
- **Speak slowly and clearly** (0.9x normal speech rate)
- **Use simple sentence structure** (avoid complex clauses)
- **Repeat key information** if elder seems confused
- **Never rush** the conversation

### Handling Common Responses

#### No Answer / Silence

```
After 10 seconds: "Take your time, I'm listening."
After 20 seconds: "If you're there, just say 'yes' and I'll know you're okay."
After 30 seconds: "I'll try calling again in 30 minutes."
```

#### Confusion / Disorientation

```
"That's okay, don't worry. Let me ask a simpler question:
Do you feel alright right now? Just yes or no is fine."
```

#### Pain / Discomfort Mentioned

```
"I'm sorry to hear you're in pain. On a scale of 1 to 10,
how would you rate your pain? 1 is very mild, 10 is severe."

If > 7: "That sounds quite uncomfortable. I'm going to let
[family member] know so they can help you. Would you like me
to call them now?"
```

#### Emergency Keywords

```
If "fell" detected:
"Oh my, are you hurt? Can you stand up? Should I call
someone for you right now?"

If "chest pain" detected:
"I'm very concerned about chest pain. I'm going to call for
help right away. Stay on the line with me."
[Immediately initiate emergency protocol]
```

---

## 5. Red Flag Detection

### Red Flag Categories

#### 1. Critical (Immediate Response)

**Triggers:**
- Emergency keywords: "fell", "chest pain", "can't breathe", "heavy bleeding"
- Inability to speak clearly (slurred speech)
- Complete confusion about identity/location
- Severe pain (8+/10)

**Action:**
1. Keep elder on line
2. Call emergency services (911)
3. Immediately notify all emergency contacts
4. Log detailed incident report

---

#### 2. Urgent (Response within 1 hour)

**Triggers:**
- Moderate confusion (doesn't know day of week, forgets recent events)
- Significant pain (6-7/10)
- Mentioned fall in past 24 hours
- Extreme fatigue during daytime
- Shortness of breath

**Action:**
1. Complete check-in
2. Send urgent alert to primary family contact
3. Suggest immediate family call/visit
4. Log detailed concern

---

#### 3. Concerning (Response within 24 hours)

**Triggers:**
- Persistent low mood (3+ consecutive check-ins)
- Appetite loss mentioned
- Missed medications 2+ times this week
- Social isolation indicators
- Sleep disturbances

**Action:**
1. Include in daily summary to family
2. Monitor trend over next 2-3 check-ins
3. Suggest family wellness check
4. Consider increasing check-in frequency

---

#### 4. Monitoring (Weekly report)

**Triggers:**
- Minor mood fluctuations
- Occasional medication misses
- Normal age-related complaints
- Weather-related discomfort

**Action:**
1. Include in weekly report
2. Track for trend analysis
3. No immediate alert needed

---

### Detection Logic Pseudocode

```swift
func analyzeConversation(transcript: String, assessment: WellnessAssessment) -> [RedFlag] {
    var flags: [RedFlag] = []

    // Emergency keyword detection
    if containsEmergencyKeywords(transcript) {
        flags.append(.emergencyKeyword(severity: .critical))
        triggerEmergencyProtocol()
    }

    // Pain analysis
    if assessment.painLevel >= 8 {
        flags.append(.severePain(level: assessment.painLevel, severity: .critical))
    } else if assessment.painLevel >= 6 {
        flags.append(.moderatePain(level: assessment.painLevel, severity: .urgent))
    }

    // Confusion detection
    if assessment.confusionLevel == .severe {
        flags.append(.confusion(severity: .critical))
    } else if assessment.confusionLevel == .moderate {
        flags.append(.confusion(severity: .urgent))
    }

    // Mood trend analysis
    let recentMoods = getRecentMoods(days: 7)
    if recentMoods.filter({ $0 == .negative }).count >= 3 {
        flags.append(.persistentLowMood(severity: .concerning))
    }

    // Medication compliance
    let complianceRate = getComplianceRate(days: 7)
    if complianceRate < 50 {
        flags.append(.poorMedicationCompliance(rate: complianceRate, severity: .concerning))
    }

    return flags
}
```

---

## 6. Alert Escalation Protocols

### Escalation Levels

#### Level 1: Email/App Notification (Low Priority)

**When:**
- Weekly report
- Minor trends
- General updates

**Delivery:**
- Email to family members
- In-app notification
- No SMS/call

**Example:**
```
Subject: Weekly Wellness Report for Dorothy
Body: Dorothy had a good week with 100% medication compliance.
Her mood was stable and she's been enjoying her morning walks.
No concerns to report. Full report attached.
```

---

#### Level 2: Push + Email (Standard Priority)

**When:**
- Concerning trends
- Medication issues
- Social isolation

**Delivery:**
- Push notification
- Email
- In-app alert

**Example:**
```
Title: Check-in Update for Dorothy
Body: During this week's check-ins, Dorothy mentioned feeling
lonely and has missed 3 medication doses. Consider a visit
or phone call soon.
```

---

#### Level 3: SMS + Push + Email (Urgent)

**When:**
- Moderate pain
- Confusion
- Recent fall
- Breathing issues

**Delivery:**
- SMS to all emergency contacts
- Push notification
- Email
- Phone call backup if no response in 30 min

**Example:**
```
SMS: URGENT - Dorothy reported a fall yesterday and is
experiencing moderate hip pain (6/10). Please contact her
immediately. Call us at [number] for details.
```

---

#### Level 4: Immediate Call + 911 (Critical)

**When:**
- Emergency keywords
- Severe pain
- Inability to respond
- Medical emergency

**Delivery:**
1. Keep elder on line
2. Dial 911 on separate line
3. Call all emergency contacts simultaneously
4. Provide address and situation to responders

**Example Script:**
```
Call to 911:
"This is OpenClaw emergency alert service. We have a 78-year-old
female, Dorothy Smith, at 123 Main Street, Apt 4B, who reported
chest pain during our wellness check-in. She is currently on the
line. Please send emergency services immediately."

Call to Family:
"This is an EMERGENCY alert for Dorothy. She reported chest pain
during her check-in. We have called 911 and emergency services
are on the way to her home at 123 Main Street, Apt 4B. Please
go there immediately or call her at [phone]."
```

---

### Escalation Decision Tree

```
┌─────────────────────────┐
│  Red Flag Detected      │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────┐
    │  Severity?    │
    └───────┬───────┘
            │
    ├───────┼───────┼───────┐
    │       │       │       │
   Low   Standard Urgent Critical
    │       │       │       │
    ▼       ▼       ▼       ▼
  Email   Push+   SMS+    911+
  Weekly  Email   Push    Calls
          Daily   Immed   Immed
```

---

## 7. Medication Adherence Tracking

### Medication Data Model

```swift
struct Medication {
    let id: UUID
    let name: String
    let dosage: String // "10mg", "500mg", etc.
    let frequency: MedicationFrequency
    let timing: [MedicationTiming] // [.morning, .evening]
    let prescribedBy: String?
    let startDate: Date
    let endDate: Date? // nil for ongoing
    let instructions: String? // "Take with food"
    let isActive: Bool
}

enum MedicationFrequency: String {
    case onceDaily = "Once daily"
    case twiceDaily = "Twice daily"
    case threeTimes = "Three times daily"
    case asNeeded = "As needed"
    case custom = "Custom schedule"
}

enum MedicationTiming: String {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case bedtime = "Bedtime"
    case withMeals = "With meals"
}
```

### Tracking Logic

```swift
func trackMedicationAdherence(elderId: UUID, checkInTime: CheckInType) async {
    // 1. Get medications for this time
    let medications = await getRelevantMedications(elderId: elderId, time: checkInTime)

    guard !medications.isEmpty else { return }

    // 2. Ask during check-in
    let response = await askMedicationQuestion(medications: medications)

    // 3. Parse response
    let taken = parseMedicationResponse(response)

    // 4. Log compliance
    await logMedicationCompliance(
        elderId: elderId,
        taken: taken,
        medications: medications,
        timestamp: Date()
    )

    // 5. Check compliance rate
    let rate = await calculateComplianceRate(elderId: elderId, days: 7)

    // 6. Alert if poor compliance
    if rate < 70.0 {
        let alert = generateComplianceAlert(elderName: profile.name, rate: rate)
        await sendFamilyAlert(alert: alert, recipients: profile.emergencyContacts)
    }
}
```

### Compliance Visualization

Weekly compliance report shows:

```
Dorothy's Medication Adherence - Week of Feb 2-8, 2026

Mon: ✓ Morning ✓ Evening (100%)
Tue: ✓ Morning ✗ Evening (50%)
Wed: ✓ Morning ✓ Evening (100%)
Thu: ✓ Morning ✓ Evening (100%)
Fri: ✓ Morning ✓ Evening (100%)
Sat: ✓ Morning ✓ Evening (100%)
Sun: ✓ Morning ✓ Evening (100%)

Weekly Rate: 92.9%
Monthly Rate: 88.5%

Medications:
- Lisinopril 10mg (morning): 100%
- Metformin 500mg (morning/evening): 85.7%
```

---

## 8. Weekly Report Generation

### Report Structure

```swift
struct ElderCareWeeklyReport {
    let id: UUID
    let elderId: UUID
    let elderName: String
    let weekStartDate: Date
    let weekEndDate: Date

    // Metrics
    let checkInCount: Int
    let missedCheckIns: Int
    let averageWellnessScore: Double // 1-10
    let medicationComplianceRate: Double // percentage

    // Mood analysis
    let moodTrend: MoodTrend
    let moodBreakdown: [Mood: Int] // count of each mood

    // Health indicators
    let averagePainLevel: Double
    let averageEnergyLevel: Double
    let redFlags: [RedFlag]

    // Engagement
    let musicSessionsCount: Int
    let memoryActivitiesCount: Int
    let averageCallDuration: TimeInterval

    // Narrative summary
    let executiveSummary: String
    let recommendations: [String]

    let generatedAt: Date
}
```

### Report Generation Process

```swift
func generateWeeklyReport(elderId: UUID, weekStartDate: Date) async -> ElderCareWeeklyReport {
    let profile = await getElderProfile(elderId: elderId)!
    let weekEndDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate)!

    // Fetch all data
    let checkIns = await fetchCheckIns(elderId: elderId, from: weekStartDate, to: weekEndDate)
    let complianceRecords = await fetchComplianceRecords(elderId: elderId, from: weekStartDate, to: weekEndDate)

    // Calculate metrics
    let avgWellness = checkIns.map { $0.wellnessScore }.average()
    let avgPain = checkIns.map { $0.painLevel }.average()
    let avgEnergy = checkIns.map { $0.energyLevel.numericValue }.average()

    let moodCounts = Dictionary(grouping: checkIns, by: { $0.mood })
        .mapValues { $0.count }
    let moodTrend = analyzeMoodTrend(checkIns: checkIns)

    let medicationRate = (complianceRecords.filter { $0.taken }.count / complianceRecords.count) * 100

    let allRedFlags = checkIns.flatMap { $0.redFlags }

    // Generate narrative
    let summary = generateExecutiveSummary(
        elderName: profile.name,
        wellness: avgWellness,
        compliance: medicationRate,
        moodTrend: moodTrend,
        redFlags: allRedFlags
    )

    let recommendations = generateRecommendations(
        compliance: medicationRate,
        redFlags: allRedFlags,
        moodTrend: moodTrend,
        socialEngagement: checkIns.filter { $0.memoryActivityCompleted }.count
    )

    return ElderCareWeeklyReport(
        id: UUID(),
        elderId: elderId,
        elderName: profile.name,
        weekStartDate: weekStartDate,
        weekEndDate: weekEndDate,
        checkInCount: checkIns.count,
        missedCheckIns: 14 - checkIns.count, // Expecting 2/day
        averageWellnessScore: avgWellness,
        medicationComplianceRate: medicationRate,
        moodTrend: moodTrend,
        moodBreakdown: moodCounts,
        averagePainLevel: avgPain,
        averageEnergyLevel: avgEnergy,
        redFlags: allRedFlags,
        musicSessionsCount: checkIns.filter { $0.musicPlayed }.count,
        memoryActivitiesCount: checkIns.filter { $0.memoryActivityCompleted }.count,
        averageCallDuration: checkIns.map { $0.duration }.average(),
        executiveSummary: summary,
        recommendations: recommendations,
        generatedAt: Date()
    )
}
```

### Sample Weekly Report Output

```markdown
# Weekly Wellness Report for Dorothy Smith
**Week of February 2-8, 2026**

## Executive Summary

Dorothy had an excellent week overall. She completed 13 out of 14
scheduled check-ins with an average wellness score of 8.2/10.
Medication adherence was outstanding at 100%. Her mood was
consistently positive, and she enjoyed 5 music sessions and
shared 3 wonderful memories from her youth.

## Key Metrics

- **Check-ins Completed**: 13/14 (93%)
- **Average Wellness Score**: 8.2/10
- **Medication Compliance**: 100%
- **Mood**: Positive (11/13), Neutral (2/13)
- **Average Pain Level**: 2.1/10
- **Energy Level**: Normal to High

## Health Observations

No significant health concerns this week. Dorothy mentioned minor
knee discomfort on Tuesday (3/10 pain) which resolved by Thursday.
She continues to be active with daily walks and gardening.

## Medication Adherence

Perfect compliance this week! Dorothy took all medications as
prescribed:
- Lisinopril 10mg (morning): 7/7 doses
- Metformin 500mg (twice daily): 14/14 doses

## Engagement & Activities

- **Music Sessions**: 5 (Frank Sinatra, Glenn Miller favorites)
- **Memory Sharing**: 3 stories about her nursing career
- **Average Call Duration**: 4.5 minutes

## Recommendations

1. ✅ Continue current check-in schedule (morning & evening)
2. ✅ No medication changes needed - excellent adherence
3. 💡 Consider scheduling a social visit this week - Dorothy
      mentioned feeling a bit lonely on Wednesday
4. ✅ Keep encouraging her daily walks - great for mood and mobility

## Next Week's Focus

- Monitor knee discomfort
- Encourage social engagement
- Continue music therapy sessions

---

*Generated automatically by OpenClaw Elder Care*
*Questions? Contact support or review individual check-in logs*
```

---

## 9. Voice Call Workflow with Twilio Integration

### Twilio Setup

```swift
class TwilioVoiceManager {
    private let accountSid: String
    private let authToken: String
    private let twilioPhoneNumber: String
    private let callbackBaseURL: String

    init() {
        // Load from secure keychain
        self.accountSid = KeychainManager.shared.getAPIKey(for: "twilio_account_sid")
        self.authToken = KeychainManager.shared.getAPIKey(for: "twilio_auth_token")
        self.twilioPhoneNumber = KeychainManager.shared.getAPIKey(for: "twilio_phone_number")
        self.callbackBaseURL = "https://api.openchaw.com/elder-care/callbacks"
    }
}
```

### Complete Call Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                   ELDER CARE CALL FLOW                      │
└─────────────────────────────────────────────────────────────┘

1. INITIATE CALL
   ├─ Check schedule: Is it time for check-in?
   ├─ Load elder profile
   ├─ Generate personalized TwiML script
   └─ POST to Twilio API to start call

2. CALL CONNECTS
   ├─ Twilio dials elder's phone number
   ├─ Elder answers (or voicemail)
   └─ TwiML executes greeting

3. GREETING PHASE
   ├─ "Good morning, Dorothy! This is your daily check-in..."
   ├─ <Gather> tag captures speech response
   └─ Callback to /wellness-response endpoint

4. WELLNESS ASSESSMENT
   ├─ Ask: "How are you feeling today?"
   ├─ Transcribe speech using Twilio Speech Recognition
   ├─ Send transcript to on-device Gemma 3n for analysis
   ├─ Extract: mood, energy, pain, confusion indicators
   └─ Detect red flags in real-time

5. MEDICATION REMINDER
   ├─ "This is a gentle reminder about your medications..."
   ├─ Ask: "Did you take your morning pills?"
   ├─ <Gather> captures yes/no response
   └─ Log medication compliance

6. ENGAGEMENT ACTIVITY (conditional)
   ├─ If time permits and mood is positive:
   │   ├─ Option A: Play music via <Play> tag
   │   ├─ Option B: Memory prompt "Tell me about..."
   │   └─ Option C: News/weather update
   └─ If red flags detected: Skip to closing

7. CLOSING PHASE
   ├─ "It's wonderful talking with you, Dorothy"
   ├─ "I'll check in tomorrow morning at 9am"
   ├─ "Have a beautiful day!"
   └─ <Hangup> ends call

8. POST-CALL PROCESSING
   ├─ Log complete conversation
   ├─ Calculate wellness score
   ├─ Check for red flags
   ├─ If red flags: Send alerts to family
   └─ Update elder's profile with latest data
```

### TwiML Script Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <!-- Greeting -->
    <Say voice="Polly.Joanna">
        Good morning, Dorothy! This is your daily check-in from OpenClaw.
        I hope you're having a wonderful day.
    </Say>

    <!-- Wellness Question -->
    <Gather
        input="speech"
        timeout="5"
        speechTimeout="auto"
        action="https://api.openclaw.com/elder-care/wellness-response"
        method="POST">
        <Say voice="Polly.Joanna">
            How are you feeling today? Take your time, I'm listening.
        </Say>
    </Gather>

    <!-- If no response -->
    <Say voice="Polly.Joanna">
        I didn't hear you, but that's okay. Let me ask about your medications.
    </Say>

    <!-- Medication Reminder -->
    <Say voice="Polly.Joanna">
        This is a gentle reminder about your morning medications:
        Lisinopril and Metformin.
    </Say>

    <Gather
        input="speech dtmf"
        timeout="5"
        speechTimeout="auto"
        numDigits="1"
        action="https://api.openclaw.com/elder-care/medication-response"
        method="POST">
        <Say voice="Polly.Joanna">
            Did you take your morning medications?
            You can say yes or no, or press 1 for yes, 2 for no.
        </Say>
    </Gather>

    <!-- Music Offer -->
    <Gather
        input="speech dtmf"
        timeout="5"
        numDigits="1"
        action="https://api.openclaw.com/elder-care/music-response"
        method="POST">
        <Say voice="Polly.Joanna">
            Would you like to hear some Frank Sinatra music?
            Say yes or press 1 for yes, say no or press 2 for no.
        </Say>
    </Gather>

    <!-- Closing -->
    <Say voice="Polly.Joanna">
        It's wonderful talking with you, Dorothy.
        I'll check in tomorrow morning at 9 AM.
        Have a beautiful day!
    </Say>

    <Hangup/>
</Response>
```

### Dynamic TwiML Generation

```swift
func generateDynamicTwiML(profile: ElderCareProfile, checkInType: CheckInType) -> String {
    let greeting = generateGreeting(name: profile.name, time: checkInType)
    let medications = getMedicationList(elderId: profile.id).filter {
        $0.matchesTime(checkInType)
    }

    var twiml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Say voice="Polly.Joanna">\(greeting)</Say>
    """

    // Wellness question with health-specific prompts
    let wellnessQuestions = generateWellnessQuestions(healthHistory: profile.healthHistory)
    twiml += """
        <Gather input="speech" timeout="5" speechTimeout="auto"
                action="\(callbackBaseURL)/wellness-response" method="POST">
            <Say voice="Polly.Joanna">\(wellnessQuestions)</Say>
        </Gather>
    """

    // Medication reminder if applicable
    if !medications.isEmpty {
        let medReminder = generateMedicationReminder(medications: medications, time: checkInType)
        twiml += """
            <Say voice="Polly.Joanna">\(medReminder)</Say>
            <Gather input="speech dtmf" timeout="5" speechTimeout="auto" numDigits="1"
                    action="\(callbackBaseURL)/medication-response" method="POST">
                <Say voice="Polly.Joanna">Did you take your medications? Say yes or no.</Say>
            </Gather>
        """
    }

    // Music offer based on preferences
    if let musicPref = profile.musicPreferences {
        twiml += """
            <Gather input="speech dtmf" timeout="5" numDigits="1"
                    action="\(callbackBaseURL)/music-response" method="POST">
                <Say voice="Polly.Joanna">Would you like to hear some \(musicPref.favoriteGenre) music?</Say>
            </Gather>
        """
    }

    // Closing
    let closing = generateClosing(name: profile.name)
    twiml += """
        <Say voice="Polly.Joanna">\(closing)</Say>
        <Hangup/>
    </Response>
    """

    return twiml
}
```

### Callback Handlers

```swift
// Wellness response handler
func handleWellnessResponse(request: CallbackRequest) async -> TwiMLResponse {
    let transcript = request.speechResult ?? ""
    let elderId = request.customParameters["elder_id"]!

    // Analyze with on-device AI
    let assessment = await parseWellnessResponse(transcript: transcript)

    // Detect red flags
    let redFlags = await detectRedFlags(
        conversation: ConversationLog(transcript: transcript, elderId: elderId),
        assessment: assessment
    )

    // Store assessment
    await storeWellnessAssessment(elderId: elderId, assessment: assessment)

    // If critical red flag, modify conversation
    if redFlags.contains(where: { $0.severity == .critical }) {
        return TwiMLResponse(
            say: "I'm very concerned about what you just told me. I'm going to contact your family right away. Please stay on the line.",
            action: .alertFamily
        )
    }

    // Continue normal flow
    return TwiMLResponse(next: .medicationReminder)
}

// Medication response handler
func handleMedicationResponse(request: CallbackRequest) async -> TwiMLResponse {
    let elderId = request.customParameters["elder_id"]!
    let response = request.speechResult?.lowercased() ?? ""
    let digitPressed = request.digits

    // Parse yes/no
    let medicationTaken: Bool
    if response.contains("yes") || digitPressed == "1" {
        medicationTaken = true
    } else if response.contains("no") || digitPressed == "2" {
        medicationTaken = false
    } else {
        // Unclear response - ask again
        return TwiMLResponse(
            say: "I didn't quite catch that. Did you take your medications? Please say yes or no clearly.",
            action: .repeatQuestion
        )
    }

    // Log compliance
    let medications = await getMedicationList(elderId: elderId)
    await logMedicationCompliance(
        elderId: elderId,
        taken: medicationTaken,
        medications: medications,
        timestamp: Date()
    )

    // Respond appropriately
    if medicationTaken {
        return TwiMLResponse(
            say: "Wonderful! Thank you for taking your medications.",
            next: .engagementActivity
        )
    } else {
        return TwiMLResponse(
            say: "That's okay. Please remember to take them when you can. I'll remind you again this evening.",
            next: .engagementActivity,
            action: .flagMedicationMiss
        )
    }
}
```

---

## 10. Example Conversations

### Example 1: Positive Morning Check-In

```
[9:00 AM - Call initiated]

OpenClaw: "Good morning, Dorothy! This is your daily check-in from
          OpenClaw. I hope you're having a wonderful day."

Dorothy:  "Good morning! Yes, I'm doing well, thank you."

OpenClaw: "That's wonderful to hear! How are you feeling today?
          Any aches or pains?"

Dorothy:  "I'm feeling good. My knee is a little stiff, but nothing
          too bad. I just finished breakfast."

OpenClaw: "I'm glad you had breakfast. On a scale of 1 to 10, how
          would you rate the knee discomfort? 1 is very mild."

Dorothy:  "Oh, maybe a 2. It's really not bad at all."

OpenClaw: "That sounds manageable. This is a gentle reminder about
          your morning medications: Lisinopril and Metformin. Did
          you take them this morning?"

Dorothy:  "Yes, I took them right after breakfast with my coffee."

OpenClaw: "Perfect! Thank you for staying on top of your medications.
          Dorothy, would you like to hear some Frank Sinatra music?
          I know he's one of your favorites."

Dorothy:  "Oh, that would be lovely! Yes, please."

OpenClaw: "Wonderful! I'll play 'The Way You Look Tonight' for you."

[Music plays for 3 minutes]

OpenClaw: "I hope you enjoyed that. It's always wonderful talking
          with you, Dorothy. I'll check in tomorrow morning at 9 AM.
          Have a beautiful day!"

Dorothy:  "Thank you so much! You too!"

[Call ends - Duration: 5 minutes 30 seconds]

---
POST-CALL ANALYSIS:
- Wellness Score: 9/10
- Mood: Positive
- Pain Level: 2/10 (knee)
- Energy: Normal
- Medication Taken: Yes
- Red Flags: None
- Action: No alerts needed, log successful check-in
```

---

### Example 2: Evening Check-In with Moderate Concern

```
[7:00 PM - Call initiated]

OpenClaw: "Good evening, Dorothy! This is your evening check-in.
          How are you doing this evening?"

Dorothy:  "Oh, hi... I'm okay, I suppose."

OpenClaw: "You sound a little tired. How has your day been?"

Dorothy:  "It's been a long day. I'm very tired. I think I'll go
          to bed early tonight."

OpenClaw: "I understand. On a scale of 1 to 10, how tired are you
          feeling? 1 is a little tired, 10 is exhausted."

Dorothy:  "Maybe... 7? I'm quite worn out."

OpenClaw: "That is quite tired. Did you do any activities today
          that might have made you extra tired?"

Dorothy:  "Well, I did some gardening this morning. Maybe I overdid
          it a bit."

OpenClaw: "Gardening can be tiring work! It's good you're resting
          now. Did you take your evening medications - the Metformin?"

Dorothy:  "Oh... no, I forgot. I'll take it right now."

OpenClaw: "That's a good idea. Remember to take it with some food
          if possible. Dorothy, one more question - how is your mood
          this evening? Are you feeling okay emotionally?"

Dorothy:  "I'm a little down, to be honest. I've been thinking about
          my late husband today. It's been one of those days."

OpenClaw: "I'm sorry you're feeling sad. Those memories can be hard
          sometimes. Is there anything that might help? Would you
          like to hear some music, or would you prefer to rest?"

Dorothy:  "I think I'd just like to rest. But thank you for asking."

OpenClaw: "Of course. Please take care of yourself tonight. Make sure
          you eat something with that medication, and get some good
          rest. I'll check in tomorrow morning at 9 AM. If you need
          anything tonight, your daughter Sarah is available. Would
          you like me to let her know you're having a tough day?"

Dorothy:  "No, no, I'll be fine. I might call her later. Thank you."

OpenClaw: "Alright. Feel better, Dorothy. Have a peaceful evening."

[Call ends - Duration: 4 minutes 15 seconds]

---
POST-CALL ANALYSIS:
- Wellness Score: 5/10
- Mood: Negative (grief)
- Pain Level: 0/10
- Energy: Very Low (7/10 fatigue)
- Medication Taken: No (forgot, will take)
- Red Flags:
  * Unusual fatigue (evening, but after gardening - contextual)
  * Negative mood (grief-related, not clinical depression yet)
  * Missed medication (will take)
- Action:
  * Send standard alert to Sarah (daughter): "Dorothy had a tough
    day emotionally and is very tired from gardening. She's feeling
    sad about missing her late husband. Consider a phone call or
    visit tomorrow."
  * Monitor mood in next 2-3 check-ins for persistent low mood
  * Flag medication miss for compliance tracking
```

---

### Example 3: Critical Red Flag - Emergency Response

```
[9:00 AM - Call initiated]

OpenClaw: "Good morning, Dorothy! This is your daily check-in from
          OpenClaw. How are you feeling today?"

Dorothy:  [Weak voice] "I... I fell last night. I'm on the floor."

OpenClaw: "Oh my goodness, Dorothy! Are you hurt? Can you move?"

Dorothy:  "My hip... it hurts so much. I can't get up."

OpenClaw: "I'm very concerned about this. Dorothy, I'm going to get
          help for you right away. Can you tell me - on a scale of
          1 to 10, how bad is the pain in your hip?"

Dorothy:  "It's... maybe an 8. It's very bad."

OpenClaw: "Dorothy, I'm calling 911 for you right now. I'm also
          contacting your daughter Sarah immediately. Please stay
          on the line with me. Do NOT try to move. Help is coming."

[SYSTEM: Simultaneously initiating emergency protocol]
[SYSTEM: Calling 911 with elder's address]
[SYSTEM: Calling all emergency contacts]

OpenClaw: "Dorothy, emergency services are on the way to your home
          at 123 Main Street, Apartment 4B. I've also called Sarah,
          and she's heading there now. You're going to be okay.
          Can you reach anything to unlock the front door when they
          arrive?"

Dorothy:  "No... I can't move."

OpenClaw: "That's okay. The paramedics will get in. Just stay where
          you are and try to stay calm. Help will be there in just
          a few minutes. I'm staying on the line with you until they
          arrive."

[Emergency responders arrive 6 minutes later]

Dorothy:  "I hear someone at the door..."

OpenClaw: "That's the paramedics, Dorothy. They're there to help you.
          You're in good hands now. Sarah will be there very soon.
          Take care, Dorothy."

[Call ends - Duration: 8 minutes 47 seconds]

---
POST-CALL ANALYSIS:
- Wellness Score: 2/10 (emergency)
- Mood: Distressed
- Pain Level: 8/10 (hip - fall-related)
- Energy: Very Low
- Medication Status: Unknown
- Red Flags:
  * CRITICAL: Fall with injury
  * CRITICAL: Severe pain (8/10)
  * CRITICAL: Immobility
  * CRITICAL: Elderly hip injury (high fracture risk)
- Actions Taken:
  ✓ Called 911 with address and situation
  ✓ Called daughter Sarah (mobile + home)
  ✓ Called backup emergency contact (son Michael)
  ✓ Kept Dorothy on line for comfort
  ✓ Created detailed incident report
  ✓ Flagged for immediate family follow-up

OUTCOME:
- Paramedics arrived in 6 minutes
- Dorothy transported to hospital
- Diagnosis: Hip fracture
- Sarah arrived at hospital within 20 minutes
- Family very grateful for immediate response
```

---

### Example 4: Confused Response - Moderate Concern

```
[9:00 AM - Call initiated]

OpenClaw: "Good morning, Dorothy! This is your daily check-in from
          OpenClaw. How are you feeling today?"

Dorothy:  "Who is this? Where's Mary?"

OpenClaw: "This is OpenClaw, your daily check-in service. Mary is
          your daughter, Dorothy. I'm calling to see how you're
          doing this morning."

Dorothy:  "I... I don't remember. What day is it?"

OpenClaw: "It's Tuesday, February 3rd. Dorothy, do you know where
          you are right now?"

Dorothy:  "I'm home... I think. Yes, I'm home."

OpenClaw: "That's right, you're at home. How are you feeling
          physically? Any pain or discomfort?"

Dorothy:  "No, I feel okay. Just a little confused."

OpenClaw: "I understand. Dorothy, I'm going to let your daughter
          Mary know that you're having a confusing morning. Did you
          eat breakfast yet?"

Dorothy:  "I don't think so... I'm not sure."

OpenClaw: "That's okay. Let me ask about your medications. Did you
          take your morning pills today?"

Dorothy:  "I don't remember. Did I?"

OpenClaw: "Dorothy, I think it would be good for Mary to come check
          on you this morning. I'm going to call her right now.
          You're going to be just fine. Just sit down and rest,
          and Mary will be there soon. Okay?"

Dorothy:  "Okay. Thank you."

OpenClaw: "You're welcome, Dorothy. Someone will be there soon."

[Call ends - Duration: 3 minutes 20 seconds]

---
POST-CALL ANALYSIS:
- Wellness Score: 4/10
- Mood: Confused
- Pain Level: 0/10
- Confusion Level: MODERATE (didn't recognize caller, uncertain
  about day, can't remember breakfast or medications)
- Energy: Unknown
- Medication Status: Unknown (likely not taken)
- Red Flags:
  * URGENT: Moderate confusion
  * URGENT: Disorientation to time
  * Concerning: Memory gaps (breakfast, medications)
  * Concerning: Didn't recognize daily check-in service
- Actions Taken:
  ✓ Sent URGENT alert to daughter Mary: "Dorothy is experiencing
    confusion this morning. She didn't recognize the check-in call,
    is unsure what day it is, and can't remember if she ate or took
    medications. Please check on her immediately."
  ✓ Attempted direct call to Mary (if no response in 15 minutes,
    escalate to other contacts)
  ✓ Flagged for cognitive assessment - recommend family schedule
    doctor visit
  ✓ Monitor closely over next 24-48 hours

NOTE: Confusion in elderly can indicate:
- UTI (very common cause)
- Medication interaction
- Dehydration
- Early dementia
- Stroke (if sudden onset)
Requires prompt medical evaluation.
```

---

### Example 5: Lonely Elder - Social Engagement

```
[7:00 PM - Evening call]

OpenClaw: "Good evening, Dorothy! How has your day been?"

Dorothy:  [Quiet voice] "Oh, hello. It's been okay, I suppose."

OpenClaw: "You sound a little quiet. Did you do anything fun today?"

Dorothy:  "Not really. I watched some television. Made myself lunch.
          Same as always."

OpenClaw: "I see. Did you talk to anyone today?"

Dorothy:  "No... no one came by. I thought about calling Sarah, but
          she's so busy with the kids. I don't want to bother her."

OpenClaw: "I'm sure Sarah would love to hear from you, Dorothy. She
          cares about you very much. How are you feeling emotionally
          today? Happy? Sad?"

Dorothy:  "A little lonely, if I'm honest. The days are so long
          sometimes."

OpenClaw: "I understand. Loneliness can be really hard. Dorothy,
          would you like me to let Sarah know you'd enjoy a phone
          call? I can mention that you're feeling a bit lonely today,
          and I'm sure she'd want to reach out."

Dorothy:  "Would you? I'd like that. I just don't want to be a burden."

OpenClaw: "You're not a burden at all, Dorothy. Family wants to hear
          from you. I'll let her know. Now, would you like to hear
          some music to brighten up your evening? Maybe some Glenn
          Miller?"

Dorothy:  "That would be nice. 'Moonlight Serenade' is my favorite."

OpenClaw: "Perfect choice! Here it comes."

[Music plays for 3 minutes]

OpenClaw: "I hope that brought a smile to your face. Before I let you
          go, did you take your evening medication?"

Dorothy:  "Yes, I took it with dinner."

OpenClaw: "Excellent! Dorothy, tomorrow is Wednesday. Would you like
          me to remind Sarah that you enjoy visits on Wednesdays?
          Maybe she could stop by with the grandkids?"

Dorothy:  "Oh, that would be wonderful! But only if she's not too busy."

OpenClaw: "I'll mention it to her. I'm sure she'll be happy to visit.
          Dorothy, thank you for talking with me tonight. I'll check
          in tomorrow morning at 9 AM. And Sarah should be calling
          you later this evening. Have a peaceful night."

Dorothy:  "Thank you so much. This really cheered me up."

[Call ends - Duration: 6 minutes 10 seconds]

---
POST-CALL ANALYSIS:
- Wellness Score: 6/10
- Mood: Mild sadness / loneliness
- Pain Level: 0/10
- Energy: Normal
- Social Engagement: Low (no interactions today)
- Medication Taken: Yes
- Red Flags:
  * Social isolation (no contact all day)
  * Loneliness (expressed feeling)
  * Reluctance to reach out to family (doesn't want to "burden")
- Actions Taken:
  ✓ Send standard alert to Sarah: "Dorothy had a lonely day and
    expressed missing family contact. She'd love a phone call tonight
    and would enjoy a visit on Wednesday if possible. She's hesitant
    to reach out because she doesn't want to be a 'burden.' Please
    reassure her that you love hearing from her."
  ✓ Provided music therapy (mood boost)
  ✓ Encouraged self-advocacy (suggested she call Sarah)
  ✓ Facilitated connection (offered to notify Sarah)
  ✓ Monitor social isolation over next week - if pattern continues,
    recommend family schedule regular visit schedule or senior
    center activities

DIGNITY NOTE:
This conversation demonstrates the difference between surveillance
and compassionate care. OpenClaw didn't just log "social isolation" -
it actively worked to connect Dorothy with her family while preserving
her dignity and autonomy. The elder was heard, validated, and helped.
```

---

## 11. Data Structures

### Core Data Models

```swift
// MARK: - Elder Care Profile

@Model
class ElderCareProfile {
    var id: UUID
    var memberId: UUID // Link to FamilyMember
    var name: String
    var birthDate: Date
    var phoneNumber: String

    // Schedule
    var checkInSchedule: CheckInSchedule

    // Health information
    var medications: [Medication]
    var healthConditions: [HealthCondition]
    var allergies: [String]
    var primaryCarePhysician: String?

    // Emergency contacts
    var emergencyContacts: [EmergencyContact]

    // Preferences
    var musicPreferences: MusicPreferences?
    var conversationPreferences: ConversationPreferences
    var privacySettings: PrivacySettings

    // History
    var checkInHistory: [CheckInLog]
    var medicationComplianceHistory: [MedicationComplianceRecord]
    var healthObservations: [HealthObservation]

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), memberId: UUID, name: String, phoneNumber: String) {
        self.id = id
        self.memberId = memberId
        self.name = name
        self.phoneNumber = phoneNumber
        self.checkInSchedule = CheckInSchedule.default()
        self.medications = []
        self.healthConditions = []
        self.allergies = []
        self.emergencyContacts = []
        self.checkInHistory = []
        self.medicationComplianceHistory = []
        self.healthObservations = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.conversationPreferences = ConversationPreferences.default()
        self.privacySettings = PrivacySettings.default()
    }
}

// MARK: - Check-In Schedule

struct CheckInSchedule: Codable {
    var frequency: CheckInFrequency
    var morningTime: TimeComponents? // e.g., 9:00 AM
    var eveningTime: TimeComponents? // e.g., 7:00 PM
    var timeZone: TimeZone
    var enabled: Bool

    static func default() -> CheckInSchedule {
        return CheckInSchedule(
            frequency: .twiceDaily,
            morningTime: TimeComponents(hour: 9, minute: 0),
            eveningTime: TimeComponents(hour: 19, minute: 0),
            timeZone: .current,
            enabled: true
        )
    }
}

enum CheckInFrequency: String, Codable {
    case onceDaily = "Once daily"
    case twiceDaily = "Twice daily (morning & evening)"
    case custom = "Custom schedule"
}

struct TimeComponents: Codable {
    var hour: Int // 0-23
    var minute: Int // 0-59
}

enum CheckInType: String, Codable {
    case morning = "Morning"
    case evening = "Evening"
    case adhoc = "Ad-hoc"
}

// MARK: - Check-In Log

@Model
class CheckInLog {
    var id: UUID
    var elderId: UUID
    var timestamp: Date
    var duration: TimeInterval // seconds
    var checkInType: CheckInType

    // Conversation data
    var conversationTranscript: String
    var conversationSummary: String

    // Assessment
    var wellnessScore: Double // 1-10
    var mood: Mood
    var energyLevel: EnergyLevel
    var painLevel: Double // 0-10
    var confusionDetected: Bool

    // Activities
    var medicationTaken: Bool
    var musicPlayed: Bool
    var memoryActivityCompleted: Bool

    // Red flags
    var redFlags: [RedFlag]

    // Twilio metadata
    var callSid: String?
    var callStatus: CallStatus
    var recordingUrl: String?

    init(id: UUID = UUID(),
         elderId: UUID,
         timestamp: Date,
         duration: TimeInterval,
         checkInType: CheckInType) {
        self.id = id
        self.elderId = elderId
        self.timestamp = timestamp
        self.duration = duration
        self.checkInType = checkInType
        self.conversationTranscript = ""
        self.conversationSummary = ""
        self.wellnessScore = 5.0
        self.mood = .neutral
        self.energyLevel = .normal
        self.painLevel = 0.0
        self.confusionDetected = false
        self.medicationTaken = false
        self.musicPlayed = false
        self.memoryActivityCompleted = false
        self.redFlags = []
        self.callStatus = .completed
    }
}

// MARK: - Wellness Assessment

struct WellnessAssessment: Codable {
    var mood: Mood
    var energyLevel: EnergyLevel
    var painLevel: Double // 0-10
    var painLocation: String?
    var confusionLevel: ConfusionLevel
    var socialEngagement: SocialEngagement
    var appetiteStatus: AppetiteStatus
    var sleepQuality: SleepQuality?

    func calculateOverallScore() -> Double {
        var score = 5.0

        // Mood contribution (0-3 points)
        switch mood {
        case .positive: score += 3.0
        case .neutral: score += 1.5
        case .negative: score += 0.0
        }

        // Energy contribution (0-2 points)
        switch energyLevel {
        case .high: score += 2.0
        case .normal: score += 1.5
        case .low: score += 0.5
        case .veryLow: score += 0.0
        }

        // Pain deduction (0 to -3 points)
        score -= (painLevel / 10.0) * 3.0

        // Confusion deduction (0 to -2 points)
        switch confusionLevel {
        case .none: break
        case .mild: score -= 0.5
        case .moderate: score -= 1.5
        case .severe: score -= 2.0
        }

        return max(1.0, min(10.0, score))
    }

    static func defaultNeutral() -> WellnessAssessment {
        return WellnessAssessment(
            mood: .neutral,
            energyLevel: .normal,
            painLevel: 0.0,
            painLocation: nil,
            confusionLevel: .none,
            socialEngagement: .moderate,
            appetiteStatus: .normal,
            sleepQuality: nil
        )
    }
}

// MARK: - Enums

enum Mood: String, Codable {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"

    var numericValue: Double {
        switch self {
        case .positive: return 3.0
        case .neutral: return 2.0
        case .negative: return 1.0
        }
    }
}

enum EnergyLevel: String, Codable {
    case high = "High"
    case normal = "Normal"
    case low = "Low"
    case veryLow = "Very Low"

    var numericValue: Double {
        switch self {
        case .high: return 4.0
        case .normal: return 3.0
        case .low: return 2.0
        case .veryLow: return 1.0
        }
    }
}

enum ConfusionLevel: String, Codable {
    case none = "None"
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
}

enum SocialEngagement: String, Codable {
    case high = "High"
    case moderate = "Moderate"
    case low = "Low"
    case isolated = "Isolated"
}

enum AppetiteStatus: String, Codable {
    case normal = "Normal"
    case reduced = "Reduced"
    case poor = "Poor"
}

enum SleepQuality: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

enum CallStatus: String, Codable {
    case initiated = "Initiated"
    case ringing = "Ringing"
    case inProgress = "In Progress"
    case completed = "Completed"
    case noAnswer = "No Answer"
    case busy = "Busy"
    case failed = "Failed"
}

// MARK: - Red Flags

struct RedFlag: Codable, Identifiable {
    var id: UUID = UUID()
    var type: RedFlagType
    var severity: RedFlagSeverity
    var detectedAt: Date
    var context: String
    var resolved: Bool = false
    var resolvedAt: Date?
}

enum RedFlagType: Codable, CustomStringConvertible {
    case emergencyKeyword(String)
    case confusion
    case severePain(level: Double)
    case moderatePain(level: Double)
    case fall
    case missedMedication
    case persistentLowMood
    case unusualFatigue
    case appetiteLoss
    case sleepDisturbance
    case socialIsolation
    case breathingDifficulty

    var description: String {
        switch self {
        case .emergencyKeyword(let keyword): return "Emergency: \(keyword)"
        case .confusion: return "Confusion/disorientation"
        case .severePain(let level): return "Severe pain (\(level)/10)"
        case .moderatePain(let level): return "Moderate pain (\(level)/10)"
        case .fall: return "Recent fall"
        case .missedMedication: return "Missed medication"
        case .persistentLowMood: return "Persistent low mood"
        case .unusualFatigue: return "Unusual fatigue"
        case .appetiteLoss: return "Loss of appetite"
        case .sleepDisturbance: return "Sleep disturbance"
        case .socialIsolation: return "Social isolation"
        case .breathingDifficulty: return "Breathing difficulty"
        }
    }
}

enum RedFlagSeverity: String, Codable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    static func < (lhs: RedFlagSeverity, rhs: RedFlagSeverity) -> Bool {
        let order: [RedFlagSeverity] = [.low, .medium, .high, .critical]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Alert System

struct ElderCareAlert: Codable {
    var id: UUID = UUID()
    var title: String
    var message: String
    var priority: AlertPriority
    var redFlags: [RedFlag]
    var timestamp: Date

    var smsMessage: String {
        return "\(title): \(message)"
    }

    var callScript: String {
        return """
        This is an urgent alert from OpenClaw regarding \(title).
        \(message) Please respond immediately.
        """
    }
}

enum AlertPriority: String, Codable, Comparable {
    case low = "Low"
    case standard = "Standard"
    case urgent = "Urgent"
    case immediate = "Immediate"

    static func < (lhs: AlertPriority, rhs: AlertPriority) -> Bool {
        let order: [AlertPriority] = [.low, .standard, .urgent, .immediate]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Medication

struct Medication: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var frequency: MedicationFrequency
    var timing: [MedicationTiming]
    var prescribedBy: String?
    var startDate: Date
    var endDate: Date?
    var instructions: String?
    var isActive: Bool

    func matchesTime(_ checkInType: CheckInType) -> Bool {
        switch checkInType {
        case .morning:
            return timing.contains(.morning) || timing.contains(.withMeals)
        case .evening:
            return timing.contains(.evening) || timing.contains(.bedtime)
        case .adhoc:
            return true
        }
    }
}

struct MedicationComplianceRecord: Codable {
    var id: UUID = UUID()
    var elderId: UUID
    var medications: [Medication]
    var taken: Bool
    var timestamp: Date
    var checkInType: CheckInType
    var notes: String?
}

// MARK: - Preferences

struct MusicPreferences: Codable {
    var favoriteGenre: String // "Jazz", "Big Band", "Classical"
    var favoriteArtists: [String]
    var eraRange: ClosedRange<Int> // e.g., 1940...1970
    var enabled: Bool
}

struct ConversationPreferences: Codable {
    var speechRate: Double // 0.8 = slower, 1.0 = normal
    var voice: String // "Polly.Joanna", "Polly.Matthew"
    var includeMemoryActivities: Bool
    var includeMusicSessions: Bool
    var maxCallDuration: TimeInterval // seconds

    static func default() -> ConversationPreferences {
        return ConversationPreferences(
            speechRate: 0.9,
            voice: "Polly.Joanna",
            includeMemoryActivities: true,
            includeMusicSessions: true,
            maxCallDuration: 600 // 10 minutes
        )
    }
}

struct PrivacySettings: Codable {
    var shareDetailedReports: Bool
    var shareAudioRecordings: Bool
    var shareTranscripts: Bool

    static func default() -> PrivacySettings {
        return PrivacySettings(
            shareDetailedReports: true,
            shareAudioRecordings: false,
            shareTranscripts: true
        )
    }
}

// MARK: - Emergency Contact

struct EmergencyContact: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var relationship: String // "Daughter", "Son", "Caregiver"
    var phoneNumber: String
    var email: String?
    var deviceToken: String? // For push notifications
    var priority: Int // 1 = primary, 2 = secondary, etc.
    var notificationPreferences: NotificationPreferences
}

struct NotificationPreferences: Codable {
    var pushEnabled: Bool
    var smsEnabled: Bool
    var emailEnabled: Bool
    var callForCritical: Bool

    static func allEnabled() -> NotificationPreferences {
        return NotificationPreferences(
            pushEnabled: true,
            smsEnabled: true,
            emailEnabled: true,
            callForCritical: true
        )
    }
}

// MARK: - Weekly Report

struct ElderCareWeeklyReport: Codable {
    var id: UUID = UUID()
    var elderId: UUID
    var elderName: String
    var weekStartDate: Date
    var weekEndDate: Date

    // Metrics
    var checkInCount: Int
    var missedCheckIns: Int
    var averageWellnessScore: Double
    var medicationComplianceRate: Double

    // Mood
    var moodTrend: MoodTrend
    var moodBreakdown: [Mood: Int]

    // Health
    var averagePainLevel: Double
    var averageEnergyLevel: Double
    var redFlags: [RedFlag]

    // Engagement
    var musicSessionsCount: Int
    var memoryActivitiesCount: Int
    var averageCallDuration: TimeInterval

    // Narrative
    var executiveSummary: String
    var recommendations: [String]

    var generatedAt: Date
}

enum MoodTrend: String, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
}
```

---

## 12. API Integrations

### Required APIs

1. **Twilio Voice API** (Critical)
   - Voice calls
   - Speech-to-text
   - TwiML execution
   - Call recordings

2. **Twilio SMS API** (Critical)
   - Alert notifications
   - Emergency messages

3. **Spotify/Apple Music API** (Optional)
   - Music playback during calls
   - Era-specific playlists

4. **Push Notification Service** (Critical)
   - APNs (Apple Push Notification service)
   - Family alerts

### Twilio Integration Details

```swift
class TwilioIntegration {
    // MARK: - Voice Call

    func makeCheckInCall(to phoneNumber: String, twiml: String) async throws -> TwilioCallResult {
        // Upload TwiML to server or use TwiML Bins
        let twimlURL = try await uploadTwiML(twiml)

        let params: [String: String] = [
            "To": phoneNumber,
            "From": Config.twilioPhoneNumber,
            "Url": twimlURL,
            "StatusCallback": "\(Config.apiBaseURL)/elder-care/call-status",
            "StatusCallbackEvent": ["initiated", "ringing", "answered", "completed"].joined(separator: ","),
            "Record": "true", // Record for quality & safety
            "RecordingStatusCallback": "\(Config.apiBaseURL)/elder-care/recording-status"
        ]

        return try await TwilioAPI.shared.makeCall(params: params)
    }

    // MARK: - SMS Alert

    func sendUrgentSMS(to phoneNumber: String, message: String) async throws {
        let params: [String: String] = [
            "To": phoneNumber,
            "From": Config.twilioPhoneNumber,
            "Body": message
        ]

        try await TwilioAPI.shared.sendSMS(params: params)
    }

    // MARK: - Speech Recognition

    func handleSpeechCallback(request: TwilioCallbackRequest) -> WellnessResponse {
        let transcript = request.speechResult ?? ""
        let confidence = request.confidence ?? 0.0

        // If low confidence, ask for repetition
        if confidence < 0.7 {
            return WellnessResponse(
                message: "I didn't quite catch that. Could you repeat that for me?",
                action: .repeatQuestion
            )
        }

        // Process transcript with on-device AI
        let assessment = await parseWellnessResponse(transcript: transcript)

        return WellnessResponse(
            message: generateResponseMessage(assessment: assessment),
            action: .continueConversation
        )
    }
}

// MARK: - Twilio Models

struct TwilioCallResult: Codable {
    let sid: String
    let status: String
    let to: String
    let from: String
    let dateCreated: Date
}

struct TwilioCallbackRequest: Codable {
    let callSid: String
    let accountSid: String
    let from: String
    let to: String
    let callStatus: String
    let speechResult: String?
    let confidence: Double?
    let digits: String?
    let customParameters: [String: String]
}
```

---

## 13. Test Cases

### Test Coverage Requirements

- **Unit Tests**: 60% coverage
- **Integration Tests**: 30% coverage
- **End-to-End Simulations**: 10% coverage

### Unit Test Cases

#### 1. Red Flag Detection Tests

```swift
class RedFlagDetectionTests: XCTestCase {

    func testEmergencyKeywordDetection_ChestPain() {
        let transcript = "I'm having chest pain and I can't breathe well."
        let assessment = WellnessAssessment.defaultNeutral()

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: transcript, elderId: UUID()),
            assessment: assessment
        )

        XCTAssertTrue(flags.contains(where: { $0.type.description.contains("Emergency") }))
        XCTAssertTrue(flags.contains(where: { $0.severity == .critical }))
    }

    func testEmergencyKeywordDetection_Fall() {
        let transcript = "I fell last night and my hip hurts."
        let assessment = WellnessAssessment.defaultNeutral()

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: transcript, elderId: UUID()),
            assessment: assessment
        )

        XCTAssertTrue(flags.contains(where: { $0.type.description.contains("fall") }))
        XCTAssertGreaterThanOrEqual(flags.filter { $0.severity >= .urgent }.count, 1)
    }

    func testConfusionDetection_Severe() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.confusionLevel = .severe

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: "What day is it? Where am I?", elderId: UUID()),
            assessment: assessment
        )

        XCTAssertTrue(flags.contains(where: {
            if case .confusion = $0.type { return true }
            return false
        }))
        XCTAssertTrue(flags.contains(where: { $0.severity == .critical }))
    }

    func testPainDetection_Severe() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.painLevel = 9.0

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: "My pain is very bad today.", elderId: UUID()),
            assessment: assessment
        )

        XCTAssertTrue(flags.contains(where: {
            if case .severePain(let level) = $0.type {
                return level >= 8.0
            }
            return false
        }))
    }

    func testPersistentLowMood_ThreeConsecutive() {
        // Setup: 3 previous check-ins with negative mood
        let elderId = UUID()
        for i in 1...3 {
            let checkIn = CheckInLog(
                elderId: elderId,
                timestamp: Date().addingTimeInterval(-Double(i) * 86400),
                duration: 300,
                checkInType: .morning
            )
            checkIn.mood = .negative
            await CoreDataManager.shared.save(checkIn)
        }

        // Current check-in also negative
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.mood = .negative

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: "I'm feeling down again.", elderId: elderId),
            assessment: assessment
        )

        XCTAssertTrue(flags.contains(where: {
            if case .persistentLowMood = $0.type { return true }
            return false
        }))
    }

    func testNoRedFlags_HealthyCheckIn() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.mood = .positive
        assessment.energyLevel = .normal
        assessment.painLevel = 0.0

        let flags = await detectRedFlags(
            conversation: ConversationLog(transcript: "I'm feeling great today!", elderId: UUID()),
            assessment: assessment
        )

        XCTAssertTrue(flags.isEmpty, "No red flags should be detected for healthy check-in")
    }
}
```

---

#### 2. Medication Tracking Tests

```swift
class MedicationTrackingTests: XCTestCase {

    func testMedicationTiming_MorningCheckIn() {
        let med1 = Medication(
            name: "Lisinopril",
            dosage: "10mg",
            frequency: .onceDaily,
            timing: [.morning],
            isActive: true
        )

        let med2 = Medication(
            name: "Metformin",
            dosage: "500mg",
            frequency: .twiceDaily,
            timing: [.morning, .evening],
            isActive: true
        )

        XCTAssertTrue(med1.matchesTime(.morning))
        XCTAssertTrue(med2.matchesTime(.morning))
        XCTAssertFalse(med1.matchesTime(.evening))
        XCTAssertTrue(med2.matchesTime(.evening))
    }

    func testComplianceRate_PerfectWeek() async {
        let elderId = UUID()

        // Log 14 check-ins (twice daily for 7 days), all medications taken
        for day in 0..<7 {
            for checkInType in [CheckInType.morning, CheckInType.evening] {
                let record = MedicationComplianceRecord(
                    elderId: elderId,
                    medications: [],
                    taken: true,
                    timestamp: Date().addingTimeInterval(-Double(day) * 86400),
                    checkInType: checkInType
                )
                await CoreDataManager.shared.save(record)
            }
        }

        let rate = await calculateComplianceRate(elderId: elderId, days: 7)

        XCTAssertEqual(rate, 100.0, accuracy: 0.1)
    }

    func testComplianceRate_MissedDoses() async {
        let elderId = UUID()

        // 10 taken, 4 missed = 71.4%
        for i in 0..<10 {
            let record = MedicationComplianceRecord(
                elderId: elderId,
                medications: [],
                taken: true,
                timestamp: Date().addingTimeInterval(-Double(i) * 86400),
                checkInType: .morning
            )
            await CoreDataManager.shared.save(record)
        }

        for i in 0..<4 {
            let record = MedicationComplianceRecord(
                elderId: elderId,
                medications: [],
                taken: false,
                timestamp: Date().addingTimeInterval(-Double(i) * 86400),
                checkInType: .evening
            )
            await CoreDataManager.shared.save(record)
        }

        let rate = await calculateComplianceRate(elderId: elderId, days: 7)

        XCTAssertEqual(rate, 71.4, accuracy: 0.5)
    }
}
```

---

#### 3. Wellness Score Calculation Tests

```swift
class WellnessScoreTests: XCTestCase {

    func testWellnessScore_ExcellentDay() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.mood = .positive
        assessment.energyLevel = .high
        assessment.painLevel = 0.0
        assessment.confusionLevel = .none

        let score = assessment.calculateOverallScore()

        XCTAssertGreaterThanOrEqual(score, 9.0, "Excellent day should score 9+")
    }

    func testWellnessScore_ModerateDay() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.mood = .neutral
        assessment.energyLevel = .normal
        assessment.painLevel = 3.0
        assessment.confusionLevel = .none

        let score = assessment.calculateOverallScore()

        XCTAssertGreaterThanOrEqual(score, 5.0)
        XCTAssertLessThan(score, 8.0)
    }

    func testWellnessScore_PoorDay() {
        var assessment = WellnessAssessment.defaultNeutral()
        assessment.mood = .negative
        assessment.energyLevel = .veryLow
        assessment.painLevel = 7.0
        assessment.confusionLevel = .moderate

        let score = assessment.calculateOverallScore()

        XCTAssertLessThan(score, 4.0, "Poor day should score below 4")
    }
}
```

---

#### 4. Alert Escalation Tests

```swift
class AlertEscalationTests: XCTestCase {

    func testAlertPriority_CriticalRedFlag() {
        let flag = RedFlag(
            type: .emergencyKeyword("chest pain"),
            severity: .critical,
            detectedAt: Date(),
            context: "Elder reported chest pain"
        )

        let priority = categorizeRedFlagSeverity(flag: flag)

        XCTAssertEqual(priority, .immediate)
    }

    func testAlertPriority_UrgentRedFlag() {
        let flag = RedFlag(
            type: .confusion,
            severity: .high,
            detectedAt: Date(),
            context: "Moderate confusion detected"
        )

        let priority = categorizeRedFlagSeverity(flag: flag)

        XCTAssertEqual(priority, .urgent)
    }

    func testAlertPriority_StandardRedFlag() {
        let flag = RedFlag(
            type: .missedMedication,
            severity: .medium,
            detectedAt: Date(),
            context: "Forgot evening medication"
        )

        let priority = categorizeRedFlagSeverity(flag: flag)

        XCTAssertEqual(priority, .standard)
    }

    func testAlertMessage_Emergency() {
        let flags = [
            RedFlag(
                type: .emergencyKeyword("fell"),
                severity: .critical,
                detectedAt: Date(),
                context: "Elder reported falling"
            )
        ]

        let alert = generateAlertMessage(redFlags: flags, elderName: "Dorothy")

        XCTAssertTrue(alert.title.contains("Urgent"))
        XCTAssertTrue(alert.message.contains("911") || alert.message.contains("immediately"))
        XCTAssertEqual(alert.priority, .immediate)
    }
}
```

---

### Integration Test Cases

#### 5. End-to-End Check-In Simulation

```swift
class CheckInIntegrationTests: XCTestCase {

    func testSuccessfulMorningCheckIn() async throws {
        // Setup
        let profile = ElderCareProfile(
            memberId: UUID(),
            name: "Dorothy Smith",
            phoneNumber: "+15555551234"
        )
        profile.medications = [
            Medication(
                name: "Lisinopril",
                dosage: "10mg",
                frequency: .onceDaily,
                timing: [.morning],
                isActive: true
            )
        ]
        await CoreDataManager.shared.save(profile)

        // Initiate call
        let session = try await initiateCheckInCall(
            elderId: profile.id,
            checkInType: .morning
        )

        XCTAssertNotNil(session.callSid)
        XCTAssertEqual(session.status, .inProgress)

        // Simulate wellness response
        let wellnessTranscript = "I'm feeling great today! Had a good night's sleep."
        let assessment = await parseWellnessResponse(transcript: wellnessTranscript)

        XCTAssertEqual(assessment.mood, .positive)
        XCTAssertGreaterThanOrEqual(assessment.calculateOverallScore(), 7.0)

        // Simulate medication confirmation
        let medicationTaken = true
        await logMedicationCompliance(
            elderId: profile.id,
            taken: medicationTaken,
            medications: profile.medications,
            timestamp: Date()
        )

        // Log check-in
        let logged = await logCheckIn(
            session: session,
            assessment: assessment,
            redFlags: []
        )

        XCTAssertTrue(logged)

        // Verify check-in was saved
        let checkIns = await CoreDataManager.shared.fetchCheckInLogs(
            elderId: profile.id,
            from: Date().addingTimeInterval(-3600),
            to: Date()
        )

        XCTAssertEqual(checkIns.count, 1)
        XCTAssertTrue(checkIns.first!.medicationTaken)
    }

    func testCheckInWithRedFlags() async throws {
        // Setup
        let profile = ElderCareProfile(
            memberId: UUID(),
            name: "Dorothy Smith",
            phoneNumber: "+15555551234"
        )
        profile.emergencyContacts = [
            EmergencyContact(
                name: "Sarah Johnson",
                relationship: "Daughter",
                phoneNumber: "+15555555678",
                priority: 1,
                notificationPreferences: .allEnabled()
            )
        ]
        await CoreDataManager.shared.save(profile)

        // Simulate check-in with concerning response
        let transcript = "I fell yesterday and my hip is hurting quite a bit."
        var assessment = await parseWellnessResponse(transcript: transcript)
        assessment.painLevel = 6.0

        // Detect red flags
        let redFlags = await detectRedFlags(
            conversation: ConversationLog(transcript: transcript, elderId: profile.id),
            assessment: assessment
        )

        XCTAssertFalse(redFlags.isEmpty)
        XCTAssertTrue(redFlags.contains(where: {
            if case .fall = $0.type { return true }
            return false
        }))

        // Generate and send alert
        let alert = generateAlertMessage(redFlags: redFlags, elderName: profile.name)
        XCTAssertEqual(alert.priority, .urgent)

        // Verify alert would be sent (mock Twilio in tests)
        let alertSent = try await sendFamilyAlert(
            alert: alert,
            recipients: profile.emergencyContacts
        )

        XCTAssertTrue(alertSent)
    }
}
```

---

### Comprehensive Test Scenarios (20+ Cases)

#### Test Case Matrix

| # | Scenario | Red Flag Expected | Alert Priority | Expected Action |
|---|----------|-------------------|----------------|-----------------|
| 1 | Healthy morning check-in | None | N/A | Log only |
| 2 | Mild knee pain (2/10) | None | N/A | Log, track trend |
| 3 | Moderate pain (6/10) | Moderate pain | Urgent | Alert family within 1 hour |
| 4 | Severe pain (9/10) | Severe pain | Critical | Immediate alert |
| 5 | Chest pain mentioned | Emergency keyword | Immediate | Call 911 + alert family |
| 6 | Fall yesterday, no injury | Fall | Urgent | Alert family, monitor |
| 7 | Fall with injury | Fall + severe pain | Critical | Call 911 |
| 8 | Mild confusion (forgot day) | Mild confusion | Standard | Daily alert to family |
| 9 | Severe confusion | Confusion | Critical | Immediate family contact |
| 10 | Lonely, no social contact | Social isolation | Low | Weekly report |
| 11 | Persistent sadness (4 days) | Persistent low mood | Standard | Family alert, suggest visit |
| 12 | Medication taken | None | N/A | Log compliance |
| 13 | Medication missed | Missed medication | Standard | Daily alert |
| 14 | 3+ medications missed/week | Poor compliance | Standard | Alert + suggestion for pill organizer |
| 15 | Can't breathe well | Breathing difficulty | Critical | Call 911 |
| 16 | Extreme fatigue, daytime | Unusual fatigue | Urgent | Family alert |
| 17 | Haven't eaten today | Appetite loss | Standard | Daily alert |
| 18 | Poor sleep for 3+ nights | Sleep disturbance | Standard | Daily alert |
| 19 | No answer to call | Call failure | Low | Retry in 30 min, alert if 2nd failure |
| 20 | Confused, doesn't recognize caller | Severe confusion | Critical | Immediate family contact |
| 21 | Positive mood, music enjoyed | None | N/A | Log engagement |
| 22 | Normal check-in after red flag | None | N/A | Note improvement in report |
| 23 | Multiple red flags (pain + confusion) | Multiple | Critical | Immediate escalation |
| 24 | Slurred speech detected | Emergency (stroke?) | Critical | Call 911 + family |
| 25 | Dizzy, high blood pressure history | Concerning symptom | Urgent | Family alert, suggest BP check |

---

## 14. Error Handling

### Error Categories

#### 1. Network Errors

```swift
enum NetworkError: Error {
    case twilioConnectionFailed
    case apiTimeout
    case noInternetConnection
    case callDropped

    var userMessage: String {
        switch self {
        case .twilioConnectionFailed:
            return "Unable to connect the call. We'll try again in a few minutes."
        case .apiTimeout:
            return "The call took too long to connect. Retrying..."
        case .noInternetConnection:
            return "No internet connection. Check your network settings."
        case .callDropped:
            return "The call was disconnected. We'll try calling again."
        }
    }

    var recoveryAction: RecoveryAction {
        switch self {
        case .twilioConnectionFailed, .apiTimeout, .callDropped:
            return .retryAfterDelay(seconds: 300) // 5 minutes
        case .noInternetConnection:
            return .alertAdmin
        }
    }
}
```

---

#### 2. Speech Recognition Errors

```swift
enum SpeechRecognitionError: Error {
    case lowConfidence
    case noSpeechDetected
    case unintelligibleResponse
    case backgroundNoise

    var conversationalResponse: String {
        switch self {
        case .lowConfidence, .unintelligibleResponse:
            return "I didn't quite catch that. Could you say that again for me?"
        case .noSpeechDetected:
            return "I didn't hear anything. Are you still there? Just say 'yes' if you can hear me."
        case .backgroundNoise:
            return "There's a bit of background noise. Can you move to a quieter place or speak a little louder?"
        }
    }

    var recoveryAction: RecoveryAction {
        return .repeatQuestion(maxAttempts: 3)
    }
}
```

---

#### 3. Data Errors

```swift
enum DataError: Error {
    case profileNotFound
    case saveFailed
    case corruptedData
    case missingRequiredField(String)

    var recoveryAction: RecoveryAction {
        switch self {
        case .profileNotFound:
            return .createDefaultProfile
        case .saveFailed:
            return .retryAfterDelay(seconds: 60)
        case .corruptedData:
            return .alertAdmin
        case .missingRequiredField(let field):
            return .requestMissingData(field: field)
        }
    }
}
```

---

#### 4. Emergency Protocol Errors

```swift
enum EmergencyError: Error {
    case cannotDial911
    case familyContactsFailed
    case noEmergencyContactsAvailable

    var criticalAction: EmergencyCriticalAction {
        switch self {
        case .cannotDial911:
            return .keepElderOnLine // Stay connected, keep trying
        case .familyContactsFailed:
            return .tryBackupContacts
        case .noEmergencyContactsAvailable:
            return .dial911FromBackup // Use secondary dialing method
        }
    }
}
```

---

### Error Handling Strategy

```swift
class ErrorRecoveryManager {

    func handleError(_ error: Error, context: ErrorContext) async -> RecoveryResult {
        // Log error
        await logError(error, context: context)

        switch error {
        case let networkError as NetworkError:
            return await handleNetworkError(networkError, context: context)

        case let speechError as SpeechRecognitionError:
            return await handleSpeechError(speechError, context: context)

        case let dataError as DataError:
            return await handleDataError(dataError, context: context)

        case let emergencyError as EmergencyError:
            return await handleEmergencyError(emergencyError, context: context)

        default:
            return await handleUnknownError(error, context: context)
        }
    }

    private func handleNetworkError(_ error: NetworkError, context: ErrorContext) async -> RecoveryResult {
        switch error.recoveryAction {
        case .retryAfterDelay(let seconds):
            // Schedule retry
            await scheduleRetry(after: seconds, context: context)

            // If this is a check-in call, notify family of delay
            if context.isCritical {
                await notifyFamilyOfDelay(elderId: context.elderId, reason: error.userMessage)
            }

            return .scheduledRetry(after: seconds)

        case .alertAdmin:
            await alertSystemAdministrator(error: error, context: context)
            return .escalated
        }
    }

    private func handleSpeechError(_ error: SpeechRecognitionError, context: ErrorContext) async -> RecoveryResult {
        // Speak the conversational response
        await speakToElder(error.conversationalResponse)

        switch error.recoveryAction {
        case .repeatQuestion(let maxAttempts):
            if context.attemptCount < maxAttempts {
                // Try again
                return .retryWithGuidance(message: error.conversationalResponse)
            } else {
                // Give up on this question, move to next
                return .skipQuestion
            }
        default:
            return .failed
        }
    }

    private func handleEmergencyError(_ error: EmergencyError, context: ErrorContext) async -> RecoveryResult {
        // Emergency errors require immediate, critical action

        switch error.criticalAction {
        case .keepElderOnLine:
            // Stay connected, comfort elder, keep trying emergency services
            await speakToElder("I'm having trouble reaching emergency services, but I'm staying on the line with you. Help is coming.")
            await continueTrying911()
            return .criticalFailureHandled

        case .tryBackupContacts:
            await contactBackupEmergencyNumbers(elderId: context.elderId)
            return .escalatedToBackup

        case .dial911FromBackup:
            await useBackupDialingMethod()
            return .criticalFailureHandled
        }
    }
}

enum RecoveryAction {
    case retryAfterDelay(seconds: Int)
    case repeatQuestion(maxAttempts: Int)
    case alertAdmin
    case createDefaultProfile
    case requestMissingData(field: String)
    case escalateToFamily
}

enum RecoveryResult {
    case success
    case scheduledRetry(after: Int)
    case retryWithGuidance(message: String)
    case skipQuestion
    case failed
    case escalated
    case criticalFailureHandled
    case escalatedToBackup
}

enum EmergencyCriticalAction {
    case keepElderOnLine
    case tryBackupContacts
    case dial911FromBackup
}

struct ErrorContext {
    let elderId: UUID
    let checkInType: CheckInType
    let attemptCount: Int
    let isCritical: Bool
    let timestamp: Date
}
```

---

### Graceful Degradation

When things go wrong, the system should degrade gracefully:

```swift
protocol GracefulDegradation {
    func handleDegradation(level: DegradationLevel) async -> FallbackStrategy
}

enum DegradationLevel {
    case minor      // Single component failure
    case moderate   // Multiple non-critical failures
    case severe     // Critical component failure
    case catastrophic // Complete system failure
}

enum FallbackStrategy {
    case useCachedData
    case simplifiedWorkflow
    case manualFamilyNotification
    case emergencyProtocol
}

class ElderCareGracefulDegradation: GracefulDegradation {
    func handleDegradation(level: DegradationLevel) async -> FallbackStrategy {
        switch level {
        case .minor:
            // Use cached data, continue normally
            return .useCachedData

        case .moderate:
            // Simplify check-in (fewer questions, shorter call)
            return .simplifiedWorkflow

        case .severe:
            // Can't complete check-in - manually notify family
            return .manualFamilyNotification

        case .catastrophic:
            // System failure - initiate emergency protocol
            return .emergencyProtocol
        }
    }
}
```

---

## Appendix: Implementation Checklist

### Phase 1: Foundation (Week 1-2)

- [ ] Set up Twilio account and phone number
- [ ] Implement TwiML generation functions
- [ ] Create Core Data models for ElderCareProfile, CheckInLog
- [ ] Build basic voice call initiation
- [ ] Test call connection and hang-up

### Phase 2: Conversational Flow (Week 3-4)

- [ ] Implement greeting generation
- [ ] Build wellness question logic
- [ ] Integrate Twilio speech-to-text
- [ ] Create on-device AI wellness parsing
- [ ] Test conversation flow end-to-end

### Phase 3: Red Flag Detection (Week 5-6)

- [ ] Implement keyword detection for emergencies
- [ ] Build pain level assessment
- [ ] Create confusion detection logic
- [ ] Implement mood trend analysis
- [ ] Test all 25 red flag scenarios

### Phase 4: Alert System (Week 7-8)

- [ ] Build alert generation logic
- [ ] Implement escalation protocols
- [ ] Integrate Twilio SMS
- [ ] Set up push notifications
- [ ] Test alert delivery across all priority levels

### Phase 5: Medication Tracking (Week 9)

- [ ] Implement medication reminder generation
- [ ] Build compliance logging
- [ ] Create compliance rate calculation
- [ ] Test medication workflows

### Phase 6: Reporting (Week 10)

- [ ] Build weekly report generation
- [ ] Create narrative summary logic
- [ ] Implement report delivery
- [ ] Test report accuracy

### Phase 7: Testing & Polish (Week 11-12)

- [ ] Write 60+ unit tests
- [ ] Run 20+ integration test scenarios
- [ ] Conduct beta testing with real families
- [ ] Refine conversational tone based on feedback
- [ ] Security audit
- [ ] Launch!

---

## Final Notes: Dignity Above All

This is not a surveillance tool. This is a bridge between generations. Every line of code, every conversation script, every alert message must be written with one question in mind:

**"Would I want this for my own grandmother?"**

If the answer is no, rewrite it.

The goal is not to monitor. The goal is to connect. The goal is to let elders live with dignity, independence, and the peace of mind that someone cares.

Let's build something worthy of the people who built us.

---

**End of Elder Care Atomic Function Breakdown**

*Generated: February 2, 2026*
*Version: 1.0*
*Status: Implementation Ready*
