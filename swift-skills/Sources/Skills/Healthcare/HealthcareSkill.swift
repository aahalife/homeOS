import Foundation
import HomeOSCore

public struct HealthcareSkill: SkillProtocol {
    public let name = "healthcare"
    public let description = "Medication reminders, refill tracking, symptom triage, and appointment management"
    public let triggerKeywords = [
        "medication", "medicine", "pill", "prescription", "refill", "symptom",
        "doctor", "appointment", "pharmacy", "dose", "sick", "pain", "fever",
        "headache", "cough", "nausea", "health", "medical"
    ]

    private static let medicalDisclaimer = """
        ⚠️ DISCLAIMER: This is not medical advice. Always consult a qualified \
        healthcare professional for diagnosis and treatment. If you're experiencing \
        a medical emergency, call 911 immediately.
        """

    public init() {}

    public func canHandle(intent: UserIntent) -> Double {
        let matches = triggerKeywords.filter { intent.rawMessage.lowercased().contains($0) }
        if intent.urgency == .emergency { return 1.0 }
        return min(Double(matches.count) * 0.3, 1.0)
    }

    public func execute(context: SkillContext) async throws -> SkillResult {
        let message = context.intent.rawMessage.lowercased()

        if message.contains("refill") || message.contains("prescription") {
            return try await checkRefills(context: context)
        } else if message.contains("appointment") || message.contains("doctor") || message.contains("schedule") {
            return try await handleAppointment(context: context)
        } else if message.contains("symptom") || message.contains("sick") || message.contains("pain")
            || message.contains("fever") || message.contains("headache") || message.contains("cough")
            || message.contains("nausea") {
            return try await triageSymptoms(context: context)
        } else if message.contains("medication") || message.contains("medicine") || message.contains("pill")
            || message.contains("dose") {
            return try await medicationReminder(context: context)
        } else {
            return try await medicationReminder(context: context)
        }
    }

    // MARK: - Medication Reminders

    private func medicationReminder(context: SkillContext) async throws -> SkillResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = context.timeZone
        let currentTime = formatter.string(from: context.currentDate)

        var response = "💊 MEDICATION OVERVIEW\n\n"
        var anyMeds = false

        for member in context.family.members {
            guard let medications = member.medications, !medications.isEmpty else { continue }
            anyMeds = true
            response += "👤 \(member.name)\n"

            for med in medications {
                let isDue = med.times.contains(where: { isTimeClose($0, to: currentTime) })
                let status = isDue ? "⏰ DUE NOW" : "✅ Scheduled"
                response += "  • \(med.name) (\(med.dosage)) — \(status)\n"
                response += "    Times: \(med.times.joined(separator: ", "))\n"
                if let purpose = med.purpose {
                    response += "    For: \(purpose)\n"
                }
            }
            response += "\n"
        }

        if !anyMeds {
            return .response("No medications are currently tracked for your family. Would you like to add one?")
        }

        // Check upcoming refills using date math (NOT LLM)
        let refillAlerts = checkUpcomingRefills(family: context.family, from: context.currentDate)
        if !refillAlerts.isEmpty {
            response += "🔔 REFILL ALERTS\n"
            for alert in refillAlerts {
                response += "  ⚠️ \(alert)\n"
            }
            response += "\n"
        }

        response += Self.medicalDisclaimer
        return .response(response)
    }

    // MARK: - Refill Checks (Date Math Only)

    private func checkRefills(context: SkillContext) async throws -> SkillResult {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current

        var response = "💊 PRESCRIPTION REFILL STATUS\n\n"
        var hasRefills = false

        for member in context.family.members {
            guard let medications = member.medications else { continue }
            for med in medications {
                guard let refillStr = med.refillDate,
                      let refillDate = formatter.date(from: refillStr) else { continue }

                hasRefills = true
                let daysUntil = calendar.dateComponents([.day], from: context.currentDate, to: refillDate).day ?? 0

                let urgency: String
                if daysUntil < 0 {
                    urgency = "🔴 OVERDUE by \(abs(daysUntil)) day(s)"
                } else if daysUntil <= 3 {
                    urgency = "🟡 Due in \(daysUntil) day(s) — order now"
                } else if daysUntil <= 7 {
                    urgency = "🟢 Due in \(daysUntil) day(s)"
                } else {
                    urgency = "✅ Due in \(daysUntil) day(s)"
                }

                response += "👤 \(member.name) — \(med.name) (\(med.dosage))\n"
                response += "   \(urgency)\n"
                response += "   Refill date: \(refillStr)\n\n"
            }
        }

        if !hasRefills {
            response += "No refill dates are currently tracked. Add refill dates to medications to get alerts.\n\n"
        }

        response += Self.medicalDisclaimer
        return .response(response)
    }

    // MARK: - Symptom Triage (Classify via LLM, Never Diagnose)

    private func triageSymptoms(context: SkillContext) async throws -> SkillResult {
        let categories: [ClassificationCategory] = [
            ClassificationCategory(
                name: "emergency",
                description: "Life-threatening symptoms requiring 911",
                examples: ["chest pain", "difficulty breathing", "severe bleeding", "stroke symptoms", "unconscious"]
            ),
            ClassificationCategory(
                name: "urgent",
                description: "Needs same-day medical attention",
                examples: ["high fever over 103", "deep cut", "severe pain", "allergic reaction"]
            ),
            ClassificationCategory(
                name: "moderate",
                description: "Should see doctor within 1-2 days",
                examples: ["persistent fever", "worsening cough", "ear pain", "rash spreading"]
            ),
            ClassificationCategory(
                name: "mild",
                description: "Monitor at home, see doctor if worsening",
                examples: ["mild headache", "common cold", "minor aches", "slight cough"]
            ),
        ]

        let classification: String
        do {
            classification = try await context.llm.classify(
                input: context.intent.rawMessage,
                categories: categories
            )
        } catch {
            classification = "moderate"
        }

        var response: String
        switch classification {
        case "emergency":
            response = """
                🚨 POTENTIAL EMERGENCY

                Based on the symptoms described, this may require immediate medical attention.

                ☎️  CALL 911 NOW if you or someone is experiencing:
                • Chest pain or pressure
                • Difficulty breathing
                • Severe bleeding that won't stop
                • Signs of stroke (face drooping, arm weakness, speech difficulty)
                • Loss of consciousness

                Do NOT wait. Call emergency services immediately.

                """
        case "urgent":
            response = """
                🟡 URGENT — Same-Day Care Recommended

                The symptoms described suggest you should seek medical attention today.

                📋 Recommended actions:
                • Contact your primary care doctor for a same-day appointment
                • Visit an urgent care clinic if your doctor is unavailable
                • Monitor symptoms closely — go to ER if they worsen

                """
            if let doctor = findPrimaryDoctor(family: context.family) {
                response += "📞 Your doctor: \(doctor.name)"
                if let phone = doctor.phone { response += " — \(phone)" }
                response += "\n\n"
            }
        case "moderate":
            response = """
                🟠 MODERATE — Schedule a Doctor Visit

                These symptoms are worth having checked, but don't appear immediately dangerous.

                📋 Recommended actions:
                • Schedule an appointment within the next 1-2 days
                • Rest and stay hydrated
                • Track any changes in symptoms
                • Seek urgent care if symptoms worsen significantly

                """
        default:
            response = """
                🟢 MILD — Home Monitoring

                These symptoms can likely be managed at home for now.

                📋 Recommended actions:
                • Rest and stay hydrated
                • Over-the-counter remedies may help (consult pharmacist)
                • Monitor for changes over 24-48 hours
                • See a doctor if symptoms persist or worsen

                """
        }

        response += Self.medicalDisclaimer
        return .response(response)
    }

    // MARK: - Appointment Help

    private func handleAppointment(context: SkillContext) async throws -> SkillResult {
        let medicalEvents = context.calendar.filter { $0.type == .medical }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var response = "🏥 MEDICAL APPOINTMENTS\n\n"

        let upcoming = medicalEvents.filter {
            guard let eventDate = formatter.date(from: $0.date) else { return false }
            return eventDate >= context.currentDate
        }.sorted { $0.date < $1.date }

        if upcoming.isEmpty {
            response += "No upcoming medical appointments found.\n\n"
        } else {
            for event in upcoming.prefix(5) {
                response += "📅 \(event.title)\n"
                response += "   Date: \(event.date)"
                if let time = event.time { response += " at \(time)" }
                response += "\n"
                if let loc = event.location { response += "   📍 \(loc)\n" }
                response += "\n"
            }
        }

        if let doctor = findPrimaryDoctor(family: context.family) {
            response += "👨‍⚕️ Primary Doctor: \(doctor.name)\n"
            if let phone = doctor.phone { response += "   📞 \(phone)\n" }
            if let addr = doctor.address { response += "   📍 \(addr)\n" }
        }

        response += "\nWould you like to schedule a new appointment?\n\n"
        response += Self.medicalDisclaimer
        return .response(response)
    }

    // MARK: - Helpers

    private func isTimeClose(_ scheduled: String, to current: String) -> Bool {
        let sParts = scheduled.split(separator: ":").compactMap { Int($0) }
        let cParts = current.split(separator: ":").compactMap { Int($0) }
        guard sParts.count == 2, cParts.count == 2 else { return false }
        let diff = abs((sParts[0] * 60 + sParts[1]) - (cParts[0] * 60 + cParts[1]))
        return diff <= 30
    }

    private func checkUpcomingRefills(family: Family, from date: Date) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        var alerts: [String] = []

        for member in family.members {
            guard let medications = member.medications else { continue }
            for med in medications {
                guard let refillStr = med.refillDate,
                      let refillDate = formatter.date(from: refillStr) else { continue }
                let days = calendar.dateComponents([.day], from: date, to: refillDate).day ?? 0
                if days <= 7 {
                    alerts.append("\(member.name)'s \(med.name) refill in \(max(0, days)) day(s)")
                }
            }
        }
        return alerts
    }

    private func findPrimaryDoctor(family: Family) -> DoctorInfo? {
        // Try to find from stored health profiles — fallback nil
        return nil
    }
}
