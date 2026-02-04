import Foundation

/// Healthcare Skill - Medication tracking, symptom triage, provider search
/// CRITICAL: This skill NEVER provides medical diagnoses
final class HealthcareSkill {
    private let fdaAPI = OpenFDAAPI()
    private let placesAPI = GooglePlacesAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // MARK: - Safety Disclaimer

    static let safetyDisclaimer = """
    **Important:** Not medical advice. OpenClaw cannot diagnose medical conditions. \
    Always consult with a qualified healthcare professional for medical decisions.
    """

    // MARK: - Symptom Assessment

    func assessSymptoms(description: String, family: Family) async -> String {
        logger.info("Assessing symptoms: \(description)")

        let lower = description.lowercased()
        let triage = triageSymptoms(description: lower)

        var response = ""

        switch triage {
        case .call911:
            response = """
            **CALL 911 IMMEDIATELY**

            Based on what you described, this may be a medical emergency. Please:
            1. Call 911 right now
            2. Do not drive to the hospital yourself
            3. Stay calm and follow the operator's instructions

            \(Self.safetyDisclaimer)
            """

        case .urgentCare:
            response = """
            **Seek Medical Care Today**

            These symptoms should be evaluated by a doctor today. Options:
            1. Visit your nearest urgent care center
            2. Call your doctor's office for a same-day appointment
            3. If symptoms worsen, call 911

            \(Self.safetyDisclaimer)
            """

        case .scheduleDoctorVisit:
            response = """
            **Schedule a Doctor Visit**

            These symptoms should be discussed with your doctor within the next few days. In the meantime:
            - Monitor symptoms and note any changes
            - Stay hydrated and get rest
            - If symptoms suddenly worsen, seek immediate care

            Would you like me to help find an in-network provider?

            \(Self.safetyDisclaimer)
            """

        case .selfCareWithMonitoring:
            response = """
            **Self-Care Recommended**

            Based on what you described, monitoring at home seems appropriate. Suggestions:
            - Rest and stay hydrated
            - Monitor temperature if fever is present
            - Over-the-counter medication may help (ask your pharmacist)
            - See a doctor if symptoms persist beyond 48 hours or worsen

            \(Self.safetyDisclaimer)
            """
        }

        // Log the assessment
        let log = SymptomLog(
            memberId: family.members.first?.id ?? UUID(),
            symptoms: [Symptom(type: inferSymptomType(lower), severity: inferSeverity(triage), duration: 0, description: description)],
            triageResult: triage
        )
        persistence.saveData(log, type: "symptom_log")

        return response
    }

    // MARK: - Triage Engine

    private func triageSymptoms(description: String) -> TriageAction {
        // Emergency keywords - ALWAYS call 911
        let emergencyKeywords = [
            "chest pain", "can't breathe", "difficulty breathing",
            "severe bleeding", "unresponsive", "unconscious",
            "stroke", "face drooping", "seizure",
            "severe allergic", "anaphylaxis", "choking"
        ]

        if emergencyKeywords.contains(where: { description.contains($0) }) {
            return .call911
        }

        // Urgent keywords - Same day care
        let urgentKeywords = [
            "high fever", "104", "103", "vomiting blood",
            "severe pain", "broken", "deep cut",
            "head injury", "confused", "dehydrated",
            "fever for 3 days", "fever for three days"
        ]

        if urgentKeywords.contains(where: { description.contains($0) }) {
            return .urgentCare
        }

        // Moderate keywords - Schedule visit
        let moderateKeywords = [
            "fever", "101", "102", "persistent cough",
            "ear pain", "infection", "rash that's spreading",
            "swollen", "sprain", "not eating"
        ]

        if moderateKeywords.contains(where: { description.contains($0) }) {
            return .scheduleDoctorVisit
        }

        // Default to self-care for mild symptoms
        return .selfCareWithMonitoring
    }

    // MARK: - Medication Tracking

    func logMedicationTaken(memberName: String) -> String {
        let timestamp = Date()
        logger.info("Medication taken logged for \(memberName) at \(timestamp)")
        return "Logged: \(memberName) took medication at \(timestamp.timeString). Great job staying on track!"
    }

    func getMedicationInfo(name: String) async throws -> DrugInfo {
        return try await fdaAPI.validateMedication(name: name)
    }

    // MARK: - Provider Search

    func searchProviders(family: Family, specialty: String?) async throws -> [HealthcareProvider] {
        // Use stub data since we'd need real location + Google Places
        let providers = [
            HealthcareProvider(name: "Dr. Sarah Johnson, MD", specialty: specialty ?? "Family Medicine", phone: "(555) 234-5678", address: "100 Medical Center Dr", rating: 4.8),
            HealthcareProvider(name: "Dr. Michael Chen, MD", specialty: specialty ?? "Pediatrics", phone: "(555) 345-6789", address: "200 Health Pkwy", rating: 4.6),
            HealthcareProvider(name: "Dr. Priya Patel, MD", specialty: specialty ?? "Internal Medicine", phone: "(555) 456-7890", address: "300 Wellness Blvd", rating: 4.9)
        ]

        return providers
    }

    // MARK: - Helpers

    private func inferSymptomType(_ description: String) -> SymptomType {
        if description.contains("fever") || description.contains("temperature") { return .fever }
        if description.contains("cough") { return .cough }
        if description.contains("headache") || description.contains("head hurt") { return .headache }
        if description.contains("sore throat") { return .soreThroat }
        if description.contains("nausea") || description.contains("throw up") || description.contains("vomit") { return .nausea }
        if description.contains("chest") { return .chestPain }
        if description.contains("breathing") { return .difficultyBreathing }
        if description.contains("rash") { return .rash }
        if description.contains("stomach") { return .stomachPain }
        if description.contains("dizzy") { return .dizziness }
        if description.contains("tired") || description.contains("fatigue") { return .fatigue }
        if description.contains("ear") { return .earPain }
        if description.contains("head injury") || description.contains("hit head") { return .headInjury }
        return .other
    }

    private func inferSeverity(_ triage: TriageAction) -> SymptomSeverity {
        switch triage {
        case .call911, .urgentCare: return .high
        case .scheduleDoctorVisit: return .medium
        case .selfCareWithMonitoring: return .low
        }
    }
}
