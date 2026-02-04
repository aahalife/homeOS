import Foundation

/// Pattern-matching based intent classifier (stub for on-device AI)
final class StubIntentClassifier: IntentClassifier {

    private let patterns: [(keywords: [String], skill: SkillType, action: SkillAction)] = [
        // Meal Planning
        (["plan dinner", "plan meal", "meal plan", "plan week", "plan next week", "what to eat", "dinners for"], .mealPlanning, .planWeek),
        (["tonight", "dinner tonight", "what for dinner", "quick meal", "what should i make"], .mealPlanning, .planTonight),
        (["recipe", "find recipe", "search recipe", "how to make", "how to cook"], .mealPlanning, .searchRecipe),
        (["grocery", "shopping list", "grocery list", "need to buy"], .mealPlanning, .generateGroceryList),
        (["pantry", "what do i have", "in my pantry", "ingredients i have"], .mealPlanning, .pantryCheck),

        // Healthcare
        (["symptom", "fever", "headache", "cough", "pain", "sick", "not feeling", "threw up", "vomit"], .healthcare, .checkSymptom),
        (["medication", "medicine", "take my", "took my", "pill", "dose", "refill"], .healthcare, .trackMedication),
        (["appointment", "book doctor", "schedule doctor", "doctor visit", "checkup"], .healthcare, .bookAppointment),
        (["drug info", "side effect", "interaction", "what is this medication"], .healthcare, .checkMedication),
        (["find doctor", "find pediatrician", "in network", "provider", "specialist"], .healthcare, .findProvider),

        // Education
        (["homework", "assignment", "what's due", "homework due", "assignment due"], .education, .checkHomework),
        (["grade", "grades", "doing in school", "doing in class", "doing in math", "doing in science", "doing in english", "doing in history", "score", "report card", "gpa"], .education, .checkGrades),
        (["study plan", "study schedule", "test prep", "exam prep", "prepare for test"], .education, .createStudyPlan),
        (["email teacher", "contact teacher", "message teacher", "write teacher"], .education, .contactTeacher),

        // Elder Care
        (["check in", "check on", "how is mom", "how is dad", "how is grandma", "how is grandpa", "how is grandma doing", "how is mom doing", "how is dad doing", "how is grandpa doing", "grandma doing", "grandpa doing", "mom doing", "dad doing"], .elderCare, .checkStatus),
        (["elder alert", "elder care alert", "red flag"], .elderCare, .reviewAlerts),
        (["weekly report", "elder summary", "care report"], .elderCare, .weeklyReport),

        // Home Maintenance
        (["flooding", "flood", "water leak", "gas leak", "smell gas", "fire", "smoke", "emergency", "broken pipe"], .homeMaintenance, .reportEmergency),
        (["find plumber", "find electrician", "find contractor", "need repair", "repair service", "plumber", "electrician", "contractor", "handyman", "roofer"], .homeMaintenance, .findContractor),
        (["maintenance", "filter", "hvac", "when should i", "maintenance schedule"], .homeMaintenance, .maintenanceCalendar),
        (["schedule repair", "book repair", "fix my"], .homeMaintenance, .scheduleMaintenance),

        // Family Coordination
        (["calendar", "schedule", "what's on", "events today", "events this week", "busy this"], .familyCoordination, .checkCalendar),
        (["add event", "create event", "schedule event", "add to calendar"], .familyCoordination, .createEvent),
        (["chore", "assign", "task", "clean room", "do dishes", "take out trash"], .familyCoordination, .assignChore),
        (["broadcast", "tell everyone", "message everyone", "announce", "let everyone know"], .familyCoordination, .broadcastMessage),
        (["where is", "where are", "location", "everyone at"], .familyCoordination, .whereIsEveryone),

        // Mental Load
        (["morning", "briefing", "what's today", "daily brief", "today's plan"], .mentalLoad, .morningBriefing),
        (["evening", "wind down", "end of day", "tonight's plan", "bedtime"], .mentalLoad, .eveningWindDown),
        (["weekly plan", "plan the week", "this week", "next week plan"], .mentalLoad, .weeklyPlanning),
        (["remind me", "reminder", "don't forget", "remember to"], .mentalLoad, .setReminder),
    ]

    func classify(text: String) -> IntentResult {
        let lower = text.lowercased()

        // Check for greetings
        let greetings = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
        if greetings.contains(where: { lower.hasPrefix($0) }) {
            return IntentResult(skill: .mentalLoad, action: .greeting, confidence: 0.9, entities: [:])
        }

        // Check for help
        let helpKeywords = ["help", "what can you do", "features", "skills"]
        if helpKeywords.contains(where: { lower.contains($0) }) {
            return IntentResult(skill: .mentalLoad, action: .help, confidence: 0.9, entities: [:])
        }

        // Pattern matching
        var bestMatch: (skill: SkillType, action: SkillAction, score: Int)?

        for pattern in patterns {
            let matchCount = pattern.keywords.filter { lower.contains($0) }.count
            if matchCount > 0 {
                if bestMatch == nil || matchCount > bestMatch!.score {
                    bestMatch = (pattern.skill, pattern.action, matchCount)
                }
            }
        }

        if let match = bestMatch {
            let entities = extractEntities(from: text)
            let confidence = min(Double(match.score) * 0.3 + 0.5, 0.95)
            return IntentResult(skill: match.skill, action: match.action, confidence: confidence, entities: entities)
        }

        // Default to general help
        return IntentResult(skill: .mentalLoad, action: .unknown, confidence: 0.2, entities: [:])
    }

    // MARK: - Entity Extraction

    private func extractEntities(from text: String) -> [String: String] {
        var entities: [String: String] = [:]

        // Extract names
        let namePatterns = ["for (\\w+)", "(\\w+)'s", "about (\\w+)"]
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                entities["person"] = String(text[range])
            }
        }

        // Extract time references
        let timePatterns = ["tonight", "tomorrow", "this week", "next week", "today"]
        for time in timePatterns where text.lowercased().contains(time) {
            entities["time"] = time
            break
        }

        // Extract budget mentions
        if let regex = try? NSRegularExpression(pattern: "\\$?(\\d+)", options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            entities["budget"] = String(text[range])
        }

        return entities
    }
}
