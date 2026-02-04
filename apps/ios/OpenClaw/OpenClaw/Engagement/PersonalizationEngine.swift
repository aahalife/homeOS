import Foundation

/// Learns user preferences over time and adapts the experience accordingly
/// to create a personalized, intelligent assistant that gets better with use.
final class PersonalizationEngine {
    private let logger = AppLogger.shared
    private var preferences: UserPreferences

    init(preferences: UserPreferences = UserPreferences()) {
        self.preferences = preferences
    }

    // MARK: - Meal Preferences Learning

    /// Records meal selection to learn preferences
    func recordMealSelection(recipe: Recipe) {
        logger.info("Recording meal preference: \(recipe.cuisine)")

        // Track cuisine preferences
        let currentCount = preferences.favoriteCuisines[recipe.cuisine] ?? 0
        preferences.favoriteCuisines[recipe.cuisine] = currentCount + 1

        // Track protein preferences
        let proteinCount = preferences.favoriteProteins[recipe.primaryProtein] ?? 0
        preferences.favoriteProteins[recipe.primaryProtein] = proteinCount + 1

        // Track cook time preferences
        preferences.preferredCookTimes.append(recipe.totalTime)

        preferences.lastUpdated = Date()
    }

    /// Records meal rating to improve future suggestions
    func recordMealRating(recipeId: UUID, rating: Double) {
        logger.info("Recording meal rating: \(rating) stars")
        preferences.mealSuccessRatings[recipeId] = rating
        preferences.lastUpdated = Date()
    }

    /// Gets preferred cuisines sorted by frequency
    func getPreferredCuisines(limit: Int = 5) -> [String] {
        preferences.favoriteCuisines
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    /// Gets preferred proteins
    func getPreferredProteins() -> [ProteinType] {
        preferences.favoriteProteins
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// Gets average preferred cook time
    func getPreferredCookTime() -> Int {
        guard !preferences.preferredCookTimes.isEmpty else { return 30 }

        let sum = preferences.preferredCookTimes.reduce(0, +)
        return sum / preferences.preferredCookTimes.count
    }

    /// Scores a recipe based on learned preferences
    func scoreRecipe(_ recipe: Recipe) -> Double {
        var score = 1.0

        // Cuisine preference (up to 2x multiplier)
        if let cuisineFrequency = preferences.favoriteCuisines[recipe.cuisine] {
            let totalSelections = preferences.favoriteCuisines.values.reduce(0, +)
            let cuisineRatio = Double(cuisineFrequency) / Double(max(totalSelections, 1))
            score *= (1.0 + cuisineRatio)
        }

        // Protein preference (up to 1.5x multiplier)
        if let proteinFrequency = preferences.favoriteProteins[recipe.primaryProtein] {
            let totalProtein = preferences.favoriteProteins.values.reduce(0, +)
            let proteinRatio = Double(proteinFrequency) / Double(max(totalProtein, 1))
            score *= (1.0 + proteinRatio * 0.5)
        }

        // Cook time preference (closer to preferred = higher score)
        let preferredTime = getPreferredCookTime()
        let timeDifference = abs(recipe.totalTime - preferredTime)
        let timeScore = max(0.5, 1.0 - (Double(timeDifference) / 100.0))
        score *= timeScore

        // Previous rating (strong signal)
        if let previousRating = preferences.mealSuccessRatings[recipe.id] {
            score *= (previousRating / 5.0) * 1.5
        }

        return score
    }

    // MARK: - Reminder Timing Adaptation

    /// Records when user responds to reminders to learn optimal timing
    func recordReminderResponse(type: String, sentAt: Date, respondedAt: Date) {
        let responseTime = Calendar.current.dateComponents(
            [.minute],
            from: sentAt,
            to: respondedAt
        ).minute ?? 0

        logger.info("Reminder response time: \(responseTime) minutes for \(type)")

        // If user responded within 15 minutes, this is a good time
        if responseTime <= 15 {
            preferences.optimalReminderTimes[type] = sentAt
            preferences.lastUpdated = Date()
        }
    }

    /// Gets optimal time to send a reminder based on learned behavior
    func getOptimalReminderTime(for type: String, defaultTime: Date) -> Date {
        if let optimal = preferences.optimalReminderTimes[type] {
            // Use the learned hour/minute, but today's date
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: optimal)
            let minute = calendar.component(.minute, from: optimal)

            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute

            return calendar.date(from: components) ?? defaultTime
        }

        return defaultTime
    }

    /// Adjusts reminder frequency based on engagement
    func adjustReminderFrequency(type: String, engagement: Double) -> ReminderFrequency {
        // High engagement (>0.8) = can remind more often
        // Low engagement (<0.3) = reduce frequency

        if engagement > 0.8 {
            return .high
        } else if engagement > 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    enum ReminderFrequency {
        case high // Daily
        case medium // Every 2-3 days
        case low // Weekly
    }

    // MARK: - Briefing Content Customization

    /// Records which sections of the briefing were read
    func recordBriefingEngagement(section: String, wasRead: Bool) {
        logger.info("Briefing section '\(section)' read: \(wasRead)")
        preferences.briefingReadPatterns[section] = wasRead
        preferences.lastUpdated = Date()
    }

    /// Gets sections to include in briefing based on engagement
    func getRelevantBriefingSections() -> [BriefingSection] {
        var sections: [BriefingSection] = []

        // Always include high-priority sections
        sections.append(.weather)
        sections.append(.todaySchedule)

        // Include sections based on engagement
        if preferences.briefingReadPatterns["meals"] != false {
            sections.append(.todayMeals)
        }

        if preferences.briefingReadPatterns["health"] != false {
            sections.append(.healthReminders)
        }

        if preferences.briefingReadPatterns["education"] != false {
            sections.append(.homeworkDue)
        }

        if preferences.briefingReadPatterns["chores"] != false {
            sections.append(.familyTasks)
        }

        // Only include if explicitly engaged
        if preferences.briefingReadPatterns["news"] == true {
            sections.append(.relevantNews)
        }

        return sections
    }

    enum BriefingSection: String {
        case weather, todaySchedule, todayMeals, healthReminders
        case homeworkDue, familyTasks, relevantNews
    }

    // MARK: - Conversation Context Memory

    private var conversationMemory: [ConversationMemory] = []

    /// Remembers context from conversations
    func rememberContext(topic: String, details: [String: String], importance: Double = 0.5) {
        logger.info("Remembering context: \(topic)")

        let memory = ConversationMemory(
            topic: topic,
            details: details,
            timestamp: Date(),
            importance: importance
        )

        conversationMemory.append(memory)

        // Keep only recent important memories (last 100)
        if conversationMemory.count > 100 {
            conversationMemory = conversationMemory
                .sorted { $0.importance > $1.importance }
                .prefix(100)
                .sorted { $0.timestamp > $1.timestamp }
                .map { $0 }
        }
    }

    /// Retrieves relevant context for current conversation
    func getRelevantContext(topic: String, limit: Int = 3) -> [ConversationMemory] {
        conversationMemory
            .filter { $0.topic.lowercased().contains(topic.lowercased()) ||
                      topic.lowercased().contains($0.topic.lowercased()) }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }

    struct ConversationMemory {
        let topic: String
        let details: [String: String]
        let timestamp: Date
        let importance: Double

        var ageInDays: Int {
            Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
        }
    }

    // MARK: - Tone Adaptation

    /// Learns user's preferred conversation tone
    func adaptTone(userMessage: String) {
        let lowerMessage = userMessage.lowercased()

        // Detect formal language
        let formalWords = ["please", "kindly", "would you", "could you", "thank you"]
        let formalCount = formalWords.filter { lowerMessage.contains($0) }.count

        // Detect casual language
        let casualWords = ["hey", "yeah", "yep", "gonna", "wanna", "cool", "awesome"]
        let casualCount = casualWords.filter { lowerMessage.contains($0) }.count

        // Detect brevity preference
        let isConcise = userMessage.split(separator: " ").count < 5

        // Update tone preference
        if formalCount >= 2 {
            preferences.conversationTone = .formal
        } else if casualCount >= 2 {
            preferences.conversationTone = .casual
        } else if isConcise {
            preferences.conversationTone = .concise
        } else {
            preferences.conversationTone = .friendly
        }

        preferences.lastUpdated = Date()
    }

    /// Formats response according to learned tone
    func formatResponse(_ baseResponse: String, tone: ConversationTone? = nil) -> String {
        let activeTone = tone ?? preferences.conversationTone

        switch activeTone {
        case .formal:
            return formatFormal(baseResponse)
        case .friendly:
            return formatFriendly(baseResponse)
        case .casual:
            return formatCasual(baseResponse)
        case .concise:
            return formatConcise(baseResponse)
        }
    }

    private func formatFormal(_ text: String) -> String {
        var formatted = text

        // Add polite phrases
        if !formatted.contains("please") && !formatted.contains("Please") {
            formatted = formatted.replacingOccurrences(of: "Let me", with: "Please allow me to")
        }

        // Use full words
        formatted = formatted.replacingOccurrences(of: "I'll", with: "I will")
        formatted = formatted.replacingOccurrences(of: "you're", with: "you are")

        return formatted
    }

    private func formatFriendly(_ text: String) -> String {
        // Default tone - no changes needed
        return text
    }

    private func formatCasual(_ text: String) -> String {
        var formatted = text

        // Use contractions
        formatted = formatted.replacingOccurrences(of: "I will", with: "I'll")
        formatted = formatted.replacingOccurrences(of: "you are", with: "you're")

        // Casual phrases
        formatted = formatted.replacingOccurrences(of: "Certainly", with: "Sure")
        formatted = formatted.replacingOccurrences(of: "Excellent", with: "Great")

        return formatted
    }

    private func formatConcise(_ text: String) -> String {
        var formatted = text

        // Remove filler words
        let fillers = ["Just so you know, ", "By the way, ", "I should mention that ",
                       "I think ", "I believe ", "In my opinion, "]

        for filler in fillers {
            formatted = formatted.replacingOccurrences(of: filler, with: "")
        }

        // Shorten phrases
        formatted = formatted.replacingOccurrences(of: "Let me check on that for you", with: "Checking")
        formatted = formatted.replacingOccurrences(of: "I'll look into that", with: "Looking")

        return formatted
    }

    // MARK: - Personalization Insights

    /// Generates a summary of learned preferences
    func getPersonalizationSummary() -> PersonalizationSummary {
        PersonalizationSummary(
            topCuisines: getPreferredCuisines(limit: 3),
            topProteins: getPreferredProteins(),
            averageCookTime: getPreferredCookTime(),
            conversationTone: preferences.conversationTone,
            totalMealsRated: preferences.mealSuccessRatings.count,
            memoriesStored: conversationMemory.count,
            lastUpdated: preferences.lastUpdated
        )
    }

    struct PersonalizationSummary {
        let topCuisines: [String]
        let topProteins: [ProteinType]
        let averageCookTime: Int
        let conversationTone: ConversationTone
        let totalMealsRated: Int
        let memoriesStored: Int
        let lastUpdated: Date

        var description: String {
            """
            Personalization Profile:
            - Favorite cuisines: \(topCuisines.joined(separator: ", "))
            - Preferred proteins: \(topProteins.map { $0.rawValue }.joined(separator: ", "))
            - Typical cook time: ~\(averageCookTime) minutes
            - Conversation style: \(conversationTone.rawValue)
            - Meals rated: \(totalMealsRated)
            - Context memories: \(memoriesStored)
            - Last updated: \(lastUpdated.formatted())
            """
        }
    }

    // MARK: - Persistence

    func savePreferences() {
        // In production, save to UserDefaults or Core Data
        logger.info("Saving personalization preferences")
    }

    func loadPreferences() -> UserPreferences {
        // In production, load from UserDefaults or Core Data
        logger.info("Loading personalization preferences")
        return preferences
    }
}
