import Foundation

/// Elder Care Skill - Dignified wellness check-ins, medication adherence, alerts
final class ElderCareSkill {
    private let twilioAPI = TwilioAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Check-In

    func performCheckIn(family: Family) async -> String {
        let elders = family.elders
        guard !elders.isEmpty else {
            return "No elder family members configured. You can add elder care contacts in Settings."
        }

        var summaries: [String] = []

        for elder in elders {
            let profile = getOrCreateProfile(for: elder)
            let checkIn = generateCheckInLog(for: profile)

            // Save check-in
            persistence.saveData(checkIn, type: "checkin_\(elder.id.uuidString)")

            // Check for red flags
            if checkIn.hasRedFlags {
                let alert = ElderCareAlert(
                    elderId: elder.id,
                    elderName: elder.name,
                    alertType: .redFlagDetected,
                    severity: .warning,
                    message: "Red flags detected during check-in: \(checkIn.redFlags.joined(separator: ", "))",
                    redFlags: checkIn.redFlags
                )
                persistence.saveData(alert, type: "elder_alert")
            }

            let moodEmoji = checkIn.mood.emoji
            summaries.append("""
            **\(elder.name)** \(moodEmoji)
            - Wellness: \(checkIn.wellnessScore)/10
            - Mood: \(checkIn.mood.rawValue)
            - Medication taken: \(checkIn.medicationTaken ? "Yes" : "No")
            - Notes: \(checkIn.conversationSummary)
            \(checkIn.hasRedFlags ? "- **Red flags:** \(checkIn.redFlags.joined(separator: ", "))" : "")
            """)
        }

        return summaries.joined(separator: "\n\n")
    }

    // MARK: - Alerts

    func getRecentAlerts(family: Family) async -> [ElderCareAlert] {
        var allAlerts: [ElderCareAlert] = []
        for elder in family.elders {
            let alerts: [ElderCareAlert] = persistence.loadData(type: "elder_alert")
            let elderAlerts = alerts.filter { $0.elderId == elder.id && !$0.acknowledged }
            allAlerts.append(contentsOf: elderAlerts)
        }
        return allAlerts.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Weekly Report

    func generateWeeklyReport(family: Family) async -> String {
        let elders = family.elders
        guard !elders.isEmpty else { return "No elder family members configured." }

        var reports: [String] = []

        for elder in elders {
            let checkIns: [CheckInLog] = persistence.loadData(type: "checkin_\(elder.id.uuidString)")
            let weekAgo = Date().addingDays(-7)
            let weekCheckIns = checkIns.filter { $0.timestamp >= weekAgo }

            let totalCheckIns = weekCheckIns.count
            let avgWellness = weekCheckIns.isEmpty ? 0.0 : Double(weekCheckIns.map { $0.wellnessScore }.reduce(0, +)) / Double(totalCheckIns)
            let medCompliance = weekCheckIns.isEmpty ? 0.0 : Double(weekCheckIns.filter { $0.medicationTaken }.count) / Double(totalCheckIns)
            let redFlagCount = weekCheckIns.filter { $0.hasRedFlags }.count

            reports.append("""
            **\(elder.name) - Weekly Summary**
            - Total check-ins: \(totalCheckIns)
            - Average wellness: \(String(format: "%.1f", avgWellness))/10
            - Medication adherence: \(Int(medCompliance * 100))%
            - Red flags this week: \(redFlagCount)
            \(redFlagCount > 0 ? "  Recommendation: Consider scheduling a wellness visit." : "  Overall: Looking good!")
            """)
        }

        return reports.joined(separator: "\n\n")
    }

    // MARK: - Voice Check-In (Twilio)

    func initiateVoiceCheckIn(elder: FamilyMember) async throws -> String {
        let profile = getOrCreateProfile(for: elder)
        let greeting = generateGreeting(for: elder)

        if twilioAPI.isConfigured {
            let _ = try await twilioAPI.initiateElderCheckIn(elder: profile, greeting: greeting)
            return "Voice check-in call initiated to \(elder.name)."
        } else {
            return "Voice calls require Twilio configuration. Using in-app check-in instead."
        }
    }

    // MARK: - Red Flag Detection

    func analyzeForRedFlags(transcript: String) -> [String] {
        var flags: [String] = []

        let confusionKeywords = ["don't remember", "can't remember", "confused", "what day", "who are you", "where am i"]
        let painKeywords = ["hurts", "pain", "ache", "sore", "fell", "fall"]
        let moodKeywords = ["sad", "lonely", "don't want to", "give up", "nobody cares"]
        let appetiteKeywords = ["not hungry", "haven't eaten", "can't eat", "no appetite", "if i ate", "didn't eat", "forgot to eat", "skipped meal"]

        let lower = transcript.lowercased()

        if confusionKeywords.contains(where: { lower.contains($0) }) {
            flags.append("confusion")
        }
        if painKeywords.contains(where: { lower.contains($0) }) {
            flags.append("pain_reported")
        }
        if moodKeywords.contains(where: { lower.contains($0) }) {
            flags.append("mood_concern")
        }
        if appetiteKeywords.contains(where: { lower.contains($0) }) {
            flags.append("appetite_loss")
        }

        return flags
    }

    // MARK: - Helpers

    private func getOrCreateProfile(for member: FamilyMember) -> ElderCareProfile {
        let profiles: [ElderCareProfile] = persistence.loadData(type: "elder_profile_\(member.id.uuidString)")
        if let existing = profiles.first { return existing }

        let profile = ElderCareProfile(
            memberId: member.id,
            memberName: member.name,
            checkInSchedule: CheckInSchedule(),
            medications: [],
            healthConditions: member.healthConditions
        )
        persistence.saveData(profile, type: "elder_profile_\(member.id.uuidString)")
        return profile
    }

    private func generateCheckInLog(for profile: ElderCareProfile) -> CheckInLog {
        // Simulate a realistic check-in result
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: TimeOfDay = hour < 12 ? .morning : (hour < 17 ? .afternoon : .evening)

        let moods: [MoodRating] = [.great, .good, .good, .okay, .good]
        let mood = moods.randomElement() ?? .good
        let wellnessScore = mood.numericValue * 2
        let medicationTaken = Double.random(in: 0...1) > 0.1 // 90% compliance

        return CheckInLog(
            elderId: profile.memberId,
            timeOfDay: timeOfDay,
            wellnessScore: wellnessScore,
            mood: mood,
            medicationTaken: medicationTaken,
            conversationSummary: "\(profile.memberName) reported feeling \(mood.rawValue.lowercased()) today.",
            redFlags: medicationTaken ? [] : ["missed_medication"]
        )
    }

    private func generateGreeting(for elder: FamilyMember) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening")
        return "\(timeGreeting), \(elder.name)! This is your daily check-in. How are you feeling today?"
    }
}
