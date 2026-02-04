import Foundation

/// Adds controlled randomness to keep interactions feeling natural and varied
/// without compromising the quality of suggestions.
final class NaturalRandomness {
    private let logger = AppLogger.shared

    // MARK: - Controlled Recipe Selection

    /// Picks from top 3-5 options instead of always selecting #1
    func selectFromTopCandidates<T>(
        candidates: [T],
        scoringFunction: (T) -> Double,
        topCount: Int = 5,
        randomness: Double = 0.3
    ) -> T? {
        guard !candidates.isEmpty else { return nil }

        // Score all candidates
        let scored = candidates.map { (item: $0, score: scoringFunction($0)) }
        let sorted = scored.sorted { $0.score > $1.score }

        // Take top N
        let topN = Array(sorted.prefix(topCount))

        // Use weighted random selection favoring higher scores
        if randomness > 0 {
            return weightedRandomSelection(from: topN)
        } else {
            return topN.first?.item
        }
    }

    /// Weighted random selection - higher scores have higher probability
    private func weightedRandomSelection<T>(from scored: [(item: T, score: Double)]) -> T? {
        guard !scored.isEmpty else { return nil }

        // Create weights that favor higher scores but still give chances to lower ones
        let weights = scored.enumerated().map { index, pair -> Double in
            let positionWeight = 1.0 / Double(index + 1) // 1.0, 0.5, 0.33, 0.25, 0.20
            return pair.score * positionWeight
        }

        let totalWeight = weights.reduce(0, +)
        let random = Double.random(in: 0..<totalWeight)

        var accumulator = 0.0
        for (index, weight) in weights.enumerated() {
            accumulator += weight
            if random < accumulator {
                return scored[index].item
            }
        }

        return scored.first?.item
    }

    // MARK: - Greeting Variations

    /// Returns a random greeting appropriate for time of day
    func getGreeting(hour: Int? = nil) -> String {
        let currentHour = hour ?? Calendar.current.component(.hour, from: Date())

        let greetings = GreetingVariation.standard

        let pool: [String]
        switch currentHour {
        case 5..<12:
            pool = greetings.morningGreetings
        case 12..<17:
            pool = greetings.afternoonGreetings
        default:
            pool = greetings.eveningGreetings
        }

        return pool.randomElement() ?? "Hello!"
    }

    /// Returns a random success message
    func getSuccessMessage() -> String {
        GreetingVariation.standard.successMessages.randomElement() ?? "Done!"
    }

    /// Returns a random encouragement message
    func getEncouragement() -> String {
        GreetingVariation.standard.encouragements.randomElement() ?? "Keep going!"
    }

    /// Returns varied confirmation messages
    func getConfirmation() -> String {
        let confirmations = [
            "Got it!",
            "All set!",
            "Done!",
            "Perfect!",
            "Understood!",
            "On it!",
            "Will do!",
            "Consider it done!",
            "No problem!",
            "Absolutely!"
        ]
        return confirmations.randomElement() ?? "OK!"
    }

    /// Returns varied thinking messages
    func getThinkingMessage() -> String {
        let messages = [
            "Let me check on that...",
            "One moment...",
            "Looking into it...",
            "Give me a second...",
            "Checking now...",
            "Let me find that for you...",
            "Working on it...",
            "Just a moment...",
            "Searching...",
            "Processing..."
        ]
        return messages.randomElement() ?? "Please wait..."
    }

    // MARK: - Surprise Delights

    /// Determines if user should receive a surprise delight
    func shouldShowSurpriseDelight(
        lastShown: Date?,
        frequency: SurpriseDelight.DelightFrequency,
        randomChance: Double = 0.1
    ) -> Bool {
        // Check frequency first
        if let last = lastShown {
            let calendar = Calendar.current
            let now = Date()

            let daysSince = calendar.dateComponents([.day], from: last, to: now).day ?? 0

            switch frequency {
            case .daily:
                if daysSince < 1 { return false }
            case .weekly:
                if daysSince < 7 { return false }
            case .biweekly:
                if daysSince < 14 { return false }
            case .monthly:
                if daysSince < 30 { return false }
            case .oneTime:
                return false // Already shown
            }
        }

        // Add random element - not every eligible time should show
        return Double.random(in: 0...1) < randomChance
    }

    /// Gets a surprise delight message based on user stats
    func getSurpriseDelight(stats: UserStats) -> String? {
        var messages: [String] = []

        // Streak-based
        if stats.currentStreak >= 7 {
            messages.append("🌟 Wow! You've been using OpenClaw for \(stats.currentStreak) days straight. You're amazing!")
        }

        // Milestone-based
        if stats.daysSinceInstall == 7 {
            messages.append("🎉 One week with OpenClaw! You're building great family management habits!")
        } else if stats.daysSinceInstall == 30 {
            messages.append("🎊 30 days! You've made OpenClaw part of your family routine. That's incredible!")
        } else if stats.daysSinceInstall == 100 {
            messages.append("💯 100 days! You're a OpenClaw power user! Your family management skills are top-notch!")
        }

        // Usage-based
        if stats.totalInteractions % 50 == 0 && stats.totalInteractions > 0 {
            messages.append("✨ That's \(stats.totalInteractions) interactions! You're really making the most of OpenClaw!")
        }

        // Random positive reinforcement
        let randomPositive = [
            "You're doing a great job managing your family!",
            "Your family is lucky to have you!",
            "You're crushing this parenting thing!",
            "Small efforts every day lead to big results!",
            "You're building amazing routines!",
            "Your organization skills are inspiring!",
            "Keep up the fantastic work!",
            "You make family management look easy!",
            "You're setting a great example!",
            "Your dedication is paying off!"
        ]

        if Double.random(in: 0...1) < 0.05 { // 5% chance for random positive
            messages.append(randomPositive.randomElement() ?? "")
        }

        return messages.randomElement()
    }

    // MARK: - Meal Variety

    /// Ensures meal variety by avoiding recent selections
    func selectVariedMeal(
        candidates: [PlannedMeal],
        recentMeals: [PlannedMeal],
        lookbackDays: Int = 7
    ) -> PlannedMeal? {
        // Get recent cuisine types and proteins
        let recentCuisines = Set(recentMeals.map { $0.recipe.cuisine })
        let recentProteins = Set(recentMeals.map { $0.recipe.primaryProtein })

        // Score candidates - penalize if same cuisine/protein as recent
        let scored = candidates.map { meal -> (meal: PlannedMeal, score: Double) in
            var score = 1.0

            // Penalize same cuisine
            if recentCuisines.contains(meal.recipe.cuisine) {
                score *= 0.5
            }

            // Penalize same protein
            if recentProteins.contains(meal.recipe.primaryProtein) {
                score *= 0.6
            }

            // Bonus for variety
            if !recentCuisines.contains(meal.recipe.cuisine) &&
               !recentProteins.contains(meal.recipe.primaryProtein) {
                score *= 1.5
            }

            return (meal, score)
        }

        // Select from top scored with some randomness
        return selectFromTopCandidates(
            candidates: scored.map { $0.meal },
            scoringFunction: { meal in
                scored.first(where: { $0.meal.id == meal.id })?.score ?? 0
            },
            topCount: 3,
            randomness: 0.4
        )
    }

    /// Adds natural variation to timing (e.g., reminders)
    func addTimeVariation(to date: Date, variationMinutes: Int = 15) -> Date {
        let variation = Int.random(in: -variationMinutes...variationMinutes)
        return Calendar.current.date(byAdding: .minute, value: variation, to: date) ?? date
    }

    /// Randomly shuffles a list while maintaining some structure
    func shuffleWithStructure<T>(items: [T], keepFirstN: Int = 0) -> [T] {
        guard items.count > keepFirstN else { return items }

        let fixed = Array(items.prefix(keepFirstN))
        let shuffled = Array(items.dropFirst(keepFirstN)).shuffled()

        return fixed + shuffled
    }

    /// Introduces controlled randomness in list ordering
    func organicSort<T>(
        items: [T],
        primaryScore: (T) -> Double,
        randomnessFactor: Double = 0.2
    ) -> [T] {
        items.sorted { a, b in
            let scoreA = primaryScore(a)
            let scoreB = primaryScore(b)

            // Add small random factor to scores
            let randomA = scoreA * (1.0 + Double.random(in: -randomnessFactor...randomnessFactor))
            let randomB = scoreB * (1.0 + Double.random(in: -randomnessFactor...randomnessFactor))

            return randomA > randomB
        }
    }

    /// Picks a varied response from templates
    func fillTemplate(_ template: String, with values: [String: String]) -> String {
        var result = template

        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }

        // Add natural variation to sentence structure
        let variations = [
            result,
            result.replacingOccurrences(of: "I found", with: "Here's"),
            result.replacingOccurrences(of: "I've", with: "I just"),
            result.replacingOccurrences(of: "You have", with: "You've got")
        ]

        return variations.randomElement() ?? result
    }

    /// Determines if feature should be highlighted (controlled randomness)
    func shouldHighlightFeature(
        featureId: String,
        userEngagement: Double,
        baseChance: Double = 0.15
    ) -> Bool {
        // Higher engagement = lower highlight frequency (they already use it)
        let adjustedChance = baseChance * (1.0 - userEngagement)
        return Double.random(in: 0...1) < adjustedChance
    }

    // MARK: - Response Variation

    /// Generates varied responses for the same intent
    func varyResponse(base: String, variants: [String] = []) -> String {
        if variants.isEmpty {
            return base
        }

        // 70% chance to use base, 30% chance for variant
        if Double.random(in: 0...1) < 0.7 {
            return base
        }

        return variants.randomElement() ?? base
    }

    /// Adds natural filler words occasionally
    func addNaturalFillers(to text: String, probability: Double = 0.1) -> String {
        guard Double.random(in: 0...1) < probability else { return text }

        let fillers = [
            "By the way, ",
            "Just so you know, ",
            "Quick note: ",
            "Oh, and ",
            "Also, ",
            "Speaking of which, "
        ]

        if let filler = fillers.randomElement() {
            return filler + text.prefix(1).lowercased() + text.dropFirst()
        }

        return text
    }
}
