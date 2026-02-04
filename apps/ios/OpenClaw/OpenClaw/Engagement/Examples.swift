import Foundation

/// Example implementations showing how to use the Engagement Strategy
/// in real-world scenarios within OpenClaw.

// MARK: - Example 1: Enhanced Meal Planning Skill

class EnhancedMealPlanningSkill {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Generates a weekly meal plan with engagement features
    func generateWeeklyPlan(family: Family) async -> (plan: MealPlan, message: String) {
        // Get personalized, varied meal suggestions
        let recentMeals = getRecentMeals(days: 14)
        let suggestions = engagement.suggestMeals(
            for: family,
            count: 7,
            recentMeals: recentMeals
        )

        // Create meal plan
        let plan = MealPlan(
            familyId: family.id,
            weekStartDate: Date(),
            meals: suggestions,
            estimatedCost: calculateCost(suggestions)
        )

        // Record interaction for learning
        engagement.recordInteraction(skill: .mealPlanning)

        // Get contextual tip
        let tips = engagement.getContextualTips(skill: .mealPlanning)
        let tip = tips.first?.message ?? ""

        // Get varied success message
        let success = engagement.getSuccessMessage()

        // Check for cultural events this week
        let culturalEvents = engagement.getCulturalEvents()
        var eventMessage = ""
        if let (event, recipes) = culturalEvents.first {
            eventMessage = "\n\n🎉 **\(event.name)** is coming up on \(event.date.formatted(.dateTime.month().day()))! Try: \(recipes.first?.title ?? "")"
        }

        // Compose message
        var message = "\(success) Here's your meal plan for the week.\n\n"
        message += formatMealList(suggestions)
        message += eventMessage

        if !tip.isEmpty {
            message += "\n\n" + tip
        }

        return (plan, message)
    }

    /// Suggests tonight's dinner with natural variation
    func suggestTonightDinner(family: Family) async -> (meal: PlannedMeal, message: String) {
        // Get thinking message while processing
        let thinking = engagement.getThinkingMessage()

        // Get recent meals to ensure variety
        let recentMeals = getRecentMeals(days: 7)

        // Get suggestions
        let suggestions = engagement.suggestMeals(
            for: family,
            count: 5,
            recentMeals: recentMeals
        )

        // Score and select best match
        let scored = suggestions.map { meal in
            (meal: meal, score: engagement.scoreRecipe(meal.recipe))
        }.sorted { $0.score > $1.score }

        guard let selected = scored.first?.meal else {
            return (PlannedMeal(date: Date(), mealType: .dinner, recipe: Recipe(), servings: 4),
                    "I couldn't find a good match. Let me try again.")
        }

        // Record selection for learning
        engagement.recordMealFeedback(recipe: selected.recipe, rating: nil)

        // Create varied response
        let baseMessage = "How about \(selected.recipe.title)? Ready in \(selected.recipe.totalTime) minutes."
        let variants = [
            "I think you'd enjoy \(selected.recipe.title). Takes about \(selected.recipe.totalTime) minutes.",
            "Tonight's suggestion: \(selected.recipe.title) (\(selected.recipe.totalTime) min).",
            "Let's try \(selected.recipe.title) - quick and easy at \(selected.recipe.totalTime) minutes."
        ]

        let message = engagement.getVariedResponse(base: baseMessage, variants: variants)

        return (selected, message)
    }

    // Helper methods
    private func getRecentMeals(days: Int) -> [PlannedMeal] {
        // In production, query from database
        return []
    }

    private func calculateCost(_ meals: [PlannedMeal]) -> Decimal {
        // In production, calculate actual cost
        return Decimal(50.00)
    }

    private func formatMealList(_ meals: [PlannedMeal]) -> String {
        meals.enumerated().map { index, meal in
            "**Day \(index + 1):** \(meal.recipe.title) (\(meal.recipe.totalTime) min)"
        }.joined(separator: "\n")
    }
}

// MARK: - Example 2: Enhanced Mental Load Skill

class EnhancedMentalLoadSkill {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Generates personalized morning briefing
    func generateMorningBriefing(family: Family) async -> String {
        var briefing = ""

        // Personalized greeting
        briefing += engagement.getPersonalizedGreeting(family: family)
        briefing += "\n\n"

        // Check for new achievements
        if !engagement.newAchievements.isEmpty {
            for achievement in engagement.newAchievements.prefix(1) {
                briefing += achievement.celebrationMessage + "\n\n"
            }
        }

        // Get relevant briefing sections based on user preferences
        let sections = getBriefingSections(family: family)

        briefing += sections.joined(separator: "\n\n")

        // Add contextual tip
        let tips = engagement.getContextualTips(skill: .mentalLoad)
        if let tip = tips.first {
            briefing += "\n\n" + tip.message
        }

        // Check for new features
        if !engagement.newFeatures.isEmpty {
            if let feature = engagement.newFeatures.first {
                briefing += "\n\n✨ **New Feature Available:** \(feature.title)"
            }
        }

        // Record interaction
        engagement.recordInteraction(skill: .mentalLoad)

        return briefing
    }

    private func getBriefingSections(family: Family) -> [String] {
        var sections: [String] = []

        // Weather
        sections.append("☀️ **Today's Weather:** Sunny, 72°F")

        // Calendar
        sections.append("📅 **Today's Schedule:**\n- Morning team meeting (9 AM)\n- Kids' soccer practice (4 PM)")

        // Meals
        sections.append("🍽️ **Tonight's Dinner:** Chicken Stir-Fry (planned)")

        // Cultural events
        let culturalEvents = engagement.getCulturalEvents()
        if let (event, _) = culturalEvents.first {
            sections.append("🎉 **Upcoming:** \(event.name) - \(event.description)")
        }

        return sections
    }
}

// MARK: - Example 3: Achievement Integration

class AchievementIntegration {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Shows achievements dashboard
    func showAchievementsDashboard() -> String {
        var dashboard = "🏆 **Your Achievements**\n\n"

        // Earned achievements
        let earned = engagement.getEarnedAchievements()
        dashboard += "**Unlocked (\(earned.count)):**\n"
        for achievement in earned.prefix(5) {
            dashboard += "✅ \(achievement.title) - \(achievement.description)\n"
        }

        dashboard += "\n**In Progress:**\n"

        // In-progress achievements
        let inProgress = engagement.getInProgressAchievements()
        for progress in inProgress.prefix(3) {
            let progressBar = createProgressBar(progress: progress.progress)
            dashboard += "\(progressBar) \(progress.achievement.title)\n"
            dashboard += "   \(progress.motivationalMessage)\n"
        }

        // Statistics
        dashboard += "\n" + engagement.getAchievementStats().summary

        return dashboard
    }

    private func createProgressBar(progress: Double) -> String {
        let filled = Int(progress * 10)
        let empty = 10 - filled
        return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
    }
}

// MARK: - Example 4: Onboarding Flow

class EnhancedOnboarding {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Gets onboarding message based on user's day
    func getOnboardingMessage(daysSinceInstall: Int) -> String {
        switch daysSinceInstall {
        case 0:
            return """
            👋 Welcome to OpenClaw!

            I'm here to help manage your family's meals, health, education, and more.

            Let's start simple - today we'll focus on:
            • 🍽️ Meal planning
            • 📅 Family calendar
            • 🏥 Basic health tracking

            More features will unlock as you get comfortable. No rush!
            """

        case 1:
            return """
            \(engagement.getPersonalizedGreeting(family: Family()))

            Great to see you back! Yesterday you tried meal planning.

            💡 **Tip:** You can ask me to "plan this week's dinners" for a full 7-day meal plan.

            What would you like help with today?
            """

        case 7:
            return """
            🎉 You've completed your first week with OpenClaw!

            You've unlocked new features:
            • 🎯 Smart recipe filtering
            • 📚 Homework tracking
            • 💊 Medication reminders

            You're building great family management habits! Keep it up!
            """

        case 30:
            return """
            🌟 30 Days with OpenClaw!

            You're now a power user! Here's what's new:
            • 🍂 Seasonal recipe rotation
            • ✅ Smart chore assignments
            • 📊 Weekly family reports

            You've also earned the "Monthly Milestone" achievement! 🏆
            """

        default:
            return engagement.getPersonalizedGreeting(family: Family())
        }
    }
}

// MARK: - Example 5: Recipe Rating & Learning

class RecipeRatingSystem {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Records recipe rating and provides feedback
    func rateRecipe(recipe: Recipe, rating: Double) -> String {
        // Record for personalization
        engagement.recordMealFeedback(recipe: recipe, rating: rating)

        // Get varied response based on rating
        let response: String

        if rating >= 4.5 {
            response = engagement.getVariedResponse(
                base: "So glad you loved it! I'll suggest more \(recipe.cuisine) recipes like this.",
                variants: [
                    "Amazing! This is going into your favorites.",
                    "Fantastic! I'll remember you love \(recipe.cuisine) dishes.",
                    "That's great! More recipes like this coming your way."
                ]
            )
        } else if rating >= 3.0 {
            response = engagement.getVariedResponse(
                base: "Thanks for the feedback! I'll adjust future suggestions.",
                variants: [
                    "Got it! I'll fine-tune the recommendations.",
                    "Understood. I'll learn from this.",
                    "Thanks! This helps me suggest better meals."
                ]
            )
        } else {
            response = engagement.getVariedResponse(
                base: "Sorry this didn't work out. I'll avoid similar recipes.",
                variants: [
                    "My apologies. I'll steer clear of this style.",
                    "Thanks for letting me know. I'll adjust.",
                    "Noted! I'll suggest different options next time."
                ]
            )
        }

        return response
    }

    /// Gets recipe recommendations based on learned preferences
    func getPersonalizedRecommendations(count: Int = 3) -> [(Recipe, String)] {
        // Get trending recipes
        let trending = engagement.getTrendingRecipes()

        // Score them based on personalization
        let scored = trending.map { recipe in
            (recipe: recipe, score: engagement.scoreRecipe(recipe))
        }.sorted { $0.score > $1.score }

        // Return top N with explanations
        return scored.prefix(count).map { item in
            let explanation: String
            if item.score > 1.5 {
                explanation = "Perfect match - based on your love of \(item.recipe.cuisine) food!"
            } else if item.score > 1.2 {
                explanation = "Great fit - similar to recipes you've rated highly."
            } else {
                explanation = "Worth a try - trending this week!"
            }
            return (item.recipe, explanation)
        }
    }
}

// MARK: - Example 6: Feature Discovery Flow

class FeatureDiscoveryFlow {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Shows available and upcoming features
    func showFeatureDiscovery() -> String {
        var content = "🔍 **Features**\n\n"

        // Available features
        let available = engagement.getAvailableFeatures()
        content += "**Available Now:**\n"
        for feature in available.sorted(by: { $0.priority < $1.priority }).prefix(5) {
            let badge = feature.isNew ? " 🆕" : ""
            content += "• \(feature.title)\(badge)\n  \(feature.description)\n"
        }

        // Upcoming features
        let upcoming = engagement.getUpcomingFeatures()
        if !upcoming.isEmpty {
            content += "\n**Coming Soon:**\n"
            for feature in upcoming {
                content += "• \(feature.title)\n  \(feature.description)\n"
            }
        }

        return content
    }

    /// Announces newly unlocked feature
    func announceNewFeature(feature: FeatureDiscovery) -> String {
        let categoryEmoji = getCategoryEmoji(feature.category)

        return """
        \(categoryEmoji) **New Feature Unlocked!**

        **\(feature.title)**
        \(feature.description)

        Try it out by asking me about it. You can find it in the \(feature.category.rawValue) section.

        Happy exploring! 🎉
        """
    }

    private func getCategoryEmoji(_ category: SkillType) -> String {
        switch category {
        case .mealPlanning: return "🍽️"
        case .healthcare: return "🏥"
        case .education: return "📚"
        case .elderCare: return "👴"
        case .homeMaintenance: return "🔧"
        case .familyCoordination: return "📅"
        case .mentalLoad: return "🧠"
        }
    }
}

// MARK: - Example 7: Usage Analytics

class EngagementAnalytics {
    private let engagement: EngagementCoordinator

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    /// Generates comprehensive engagement report
    func generateReport() -> String {
        engagement.generateEngagementReport()
    }

    /// Gets weekly summary
    func getWeeklySummary() -> String {
        let stats = engagement.engagementState.stats

        return """
        📊 **This Week's Activity**

        **Engagement:**
        • Days active this week: 5/7
        • Current streak: \(stats.currentStreak) days 🔥
        • Total interactions: \(stats.totalInteractions)

        **Top Skills Used:**
        \(getTopSkills(stats: stats))

        **Achievements:**
        • Earned this week: \(getRecentAchievements())
        • Close to unlocking: \(getAlmostEarnedAchievements())

        Keep up the great work! You're \(getEncouragementLevel(stats: stats))
        """
    }

    private func getTopSkills(stats: UserStats) -> String {
        stats.skillUsageCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "• \($0.key.rawValue): \($0.value) times" }
            .joined(separator: "\n")
    }

    private func getRecentAchievements() -> Int {
        engagement.getEarnedAchievements().count
    }

    private func getAlmostEarnedAchievements() -> Int {
        engagement.getInProgressAchievements().count
    }

    private func getEncouragementLevel(stats: UserStats) -> String {
        if stats.currentStreak >= 30 {
            return "absolutely crushing it! 🌟"
        } else if stats.currentStreak >= 7 {
            return "doing amazing! Keep it going! 💪"
        } else {
            return "off to a great start! 🎯"
        }
    }
}

// MARK: - Example Usage in SwiftUI

#if canImport(SwiftUI)
import SwiftUI

@MainActor
class ExampleViewModel: ObservableObject {
    private let engagement: EngagementCoordinator

    @Published var greeting: String = ""
    @Published var achievements: [Achievement] = []
    @Published var recommendations: [(Recipe, String)] = []

    init(engagement: EngagementCoordinator) {
        self.engagement = engagement
    }

    func loadDashboard(family: Family) async {
        // Get personalized greeting
        greeting = engagement.getPersonalizedGreeting(family: family)

        // Get achievements
        achievements = engagement.getEarnedAchievements()

        // Get personalized recipe recommendations
        let ratingSystem = RecipeRatingSystem(engagement: engagement)
        recommendations = ratingSystem.getPersonalizedRecommendations(count: 3)
    }

    func handleMealRating(recipe: Recipe, rating: Double) {
        let ratingSystem = RecipeRatingSystem(engagement: engagement)
        let response = ratingSystem.rateRecipe(recipe: recipe, rating: rating)
        print(response)
    }
}
#endif
