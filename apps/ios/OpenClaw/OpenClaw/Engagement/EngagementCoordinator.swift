import Foundation
import Combine

/// Central coordinator that orchestrates all engagement systems to create
/// a fresh, personalized experience that evolves with the user.
@MainActor
final class EngagementCoordinator: ObservableObject {
    private let logger = AppLogger.shared

    // MARK: - Components
    private let contentRotation = ContentRotationEngine()
    private let randomness = NaturalRandomness()
    private let discovery = ProgressiveDiscovery()
    private let contentRefresh = ContentRefreshManager()
    private let personalization: PersonalizationEngine
    private let changeManager: ChangeManager
    private let achievements = AchievementSystem()

    // MARK: - State
    @Published private(set) var engagementState: EngagementState
    @Published private(set) var currentGreeting: String = "Hello!"
    @Published private(set) var newAchievements: [Achievement] = []
    @Published private(set) var newFeatures: [FeatureDiscovery] = []

    init(userId: String = "default") {
        self.engagementState = EngagementState(userId: userId)
        self.personalization = PersonalizationEngine(preferences: engagementState.preferences)
        self.changeManager = ChangeManager(changeBudget: engagementState.changeBudget)
    }

    // MARK: - Daily Engagement Flow

    /// Called when user opens the app - updates greeting and checks for updates
    func handleAppLaunch(family: Family) async {
        logger.info("Handling app launch - checking engagement updates")

        // Update greeting
        currentGreeting = randomness.getGreeting()

        // Update stats
        updateUsageStats()

        // Check for new achievements
        checkAchievements()

        // Check for new feature unlocks
        checkFeatureUnlocks()

        // Perform daily content refresh if needed
        if shouldRefreshContent(.daily) {
            await refreshDailyContent(family: family)
        }

        // Check for weekly updates
        if shouldRefreshContent(.weekly) {
            await refreshWeeklyContent(family: family)
        }

        // Save state
        saveState()
    }

    /// Generates a personalized greeting based on time and user
    func getPersonalizedGreeting(family: Family) -> String {
        let base = randomness.getGreeting()

        // Add personalization based on time of day and context
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        var greeting = base

        // Add family context
        if hour < 12 && engagementState.stats.currentStreak >= 7 {
            greeting += " You're on a \(engagementState.stats.currentStreak)-day streak!"
        }

        // Surprise delight occasionally
        if let delight = randomness.getSurpriseDelight(stats: engagementState.stats) {
            greeting += "\n\n" + delight
        }

        return personalization.formatResponse(greeting)
    }

    // MARK: - Recipe Suggestions

    /// Gets meal suggestions with natural variety
    func suggestMeals(
        for family: Family,
        count: Int = 3,
        recentMeals: [PlannedMeal] = []
    ) -> [PlannedMeal] {
        // Get candidates from content rotation
        let week = calendar.component(.weekOfYear, from: Date())
        let newRecipes = contentRotation.getWeeklyNewRecipes(
            week: week,
            familyPreferences: family.preferences,
            previousRecipes: Set(recentMeals.map { $0.recipe.id })
        )

        // Get seasonal suggestions
        let seasonal = contentRotation.getSeasonalSuggestions(familyPreferences: family.preferences)

        // Combine and score with personalization
        var allCandidates = (newRecipes + seasonal).map { recipe in
            PlannedMeal(
                date: Date(),
                mealType: .dinner,
                recipe: recipe,
                servings: family.members.count
            )
        }

        // Use natural randomness to select varied meals
        var selected: [PlannedMeal] = []
        for _ in 0..<count {
            if let meal = randomness.selectVariedMeal(
                candidates: allCandidates,
                recentMeals: recentMeals + selected
            ) {
                selected.append(meal)
                allCandidates.removeAll { $0.id == meal.id }
            }
        }

        return selected
    }

    /// Scores recipes using personalization
    func scoreRecipe(_ recipe: Recipe) -> Double {
        personalization.scoreRecipe(recipe)
    }

    // MARK: - Learning & Adaptation

    /// Records user interaction for learning
    func recordInteraction(skill: SkillType, successful: Bool = true) {
        // Update stats
        let currentCount = engagementState.stats.skillUsageCounts[skill] ?? 0
        engagementState.stats.skillUsageCounts[skill] = currentCount + 1
        engagementState.stats.totalInteractions += 1

        // Update streak
        updateStreak()

        // Check for achievements
        checkAchievements()

        logger.info("Recorded interaction: \(skill.rawValue)")
    }

    /// Records meal selection and rating
    func recordMealFeedback(recipe: Recipe, rating: Double?) {
        personalization.recordMealSelection(recipe: recipe)

        if let rating = rating {
            personalization.recordMealRating(recipeId: recipe.id, rating: rating)
        }
    }

    /// Learns from user's conversation tone
    func adaptToUserTone(message: String) {
        personalization.adaptTone(userMessage: message)
    }

    /// Remembers conversation context
    func rememberContext(topic: String, details: [String: String]) {
        personalization.rememberContext(topic: topic, details: details)
    }

    // MARK: - Progressive Discovery

    /// Gets features available to user
    func getAvailableFeatures() -> [FeatureDiscovery] {
        discovery.getUnlockedFeatures(userStats: engagementState.stats)
    }

    /// Gets upcoming features preview
    func getUpcomingFeatures() -> [FeatureDiscovery] {
        discovery.getUpcomingFeatures(userStats: engagementState.stats)
    }

    /// Gets contextual tips for current usage
    func getContextualTips(skill: SkillType) -> [ContextualTip] {
        discovery.getContextualTips(
            userStats: engagementState.stats,
            currentSkill: skill,
            previouslyShownTips: []
        )
    }

    // MARK: - Content Freshness

    /// Gets new recipes for the week
    func getWeeklyRecipes(family: Family) -> [Recipe] {
        contentRotation.getWeeklyNewRecipes(
            week: engagementState.contentRotationWeek,
            familyPreferences: family.preferences,
            previousRecipes: []
        )
    }

    /// Gets cultural event suggestions
    func getCulturalEvents() -> [(CulturalEvent, [Recipe])] {
        contentRotation.getCulturalEventSuggestions(daysAhead: 14)
    }

    /// Gets trending recipes
    func getTrendingRecipes() -> [Recipe] {
        let month = calendar.component(.month, from: Date())
        return contentRotation.getTrendingRecipes(
            month: month,
            userRatings: engagementState.preferences.mealSuccessRatings
        )
    }

    // MARK: - Change Management

    /// Proposes changes for user acceptance
    func proposeChanges() -> [ChangeEvent] {
        // Generate potential changes
        let potentialChanges = generatePotentialChanges()

        // Filter and prioritize
        return changeManager.proposeChanges(
            availableChanges: potentialChanges,
            userStats: engagementState.stats
        )
    }

    /// Records user's acceptance/rejection of change
    func respondToChange(changeId: UUID, accepted: Bool) {
        if !accepted {
            changeManager.lockFeature(changeId, reason: "User declined")
        }
    }

    private func generatePotentialChanges() -> [ChangeEvent] {
        var changes: [ChangeEvent] = []

        // New recipes
        changes.append(ChangeEvent(
            type: .newRecipe,
            title: "New Seasonal Recipes",
            description: "Try fresh spring recipes featuring seasonal ingredients",
            scheduledDate: Date(),
            isOptional: true,
            category: .content
        ))

        // New tips
        changes.append(ChangeEvent(
            type: .newTip,
            title: "Meal Prep Tips",
            description: "Learn how to save time with Sunday meal prep",
            scheduledDate: Date(),
            isOptional: true,
            category: .content
        ))

        return changes
    }

    // MARK: - Achievements

    /// Gets earned achievements
    func getEarnedAchievements() -> [Achievement] {
        achievements.getEarnedAchievements()
    }

    /// Gets achievements in progress
    func getInProgressAchievements() -> [AchievementSystem.AchievementProgress] {
        achievements.getInProgressAchievements(stats: engagementState.stats)
    }

    /// Gets achievement statistics
    func getAchievementStats() -> AchievementSystem.AchievementStatistics {
        achievements.getStatistics()
    }

    // MARK: - Helper Methods

    private let calendar = Calendar.current

    private func updateUsageStats() {
        engagementState.stats.totalInteractions += 1
        engagementState.stats.lastActiveDate = Date()
    }

    private func updateStreak() {
        guard let lastActive = engagementState.stats.lastActiveDate else {
            engagementState.stats.currentStreak = 1
            return
        }

        let daysSince = calendar.dateComponents([.day], from: lastActive, to: Date()).day ?? 0

        if daysSince == 0 {
            // Same day - no change to streak
            return
        } else if daysSince == 1 {
            // Consecutive day - increase streak
            engagementState.stats.currentStreak += 1
            if engagementState.stats.currentStreak > engagementState.stats.longestStreak {
                engagementState.stats.longestStreak = engagementState.stats.currentStreak
            }
        } else {
            // Streak broken
            engagementState.stats.currentStreak = 1
        }
    }

    private func checkAchievements() {
        let earned = achievements.checkForNewAchievements(stats: engagementState.stats)

        if !earned.isEmpty {
            newAchievements = earned
            logger.info("New achievements earned: \(earned.count)")

            // Celebrate without being intrusive
            for achievement in earned {
                let celebration = achievements.celebrateAchievement(achievement)
                logger.info("🎉 \(achievement.celebrationMessage)")
            }
        }
    }

    private func checkFeatureUnlocks() {
        let unlocked = discovery.checkForNewUnlocks(
            userStats: engagementState.stats,
            currentUnlocked: engagementState.unlockedFeatures
        )

        if !unlocked.isEmpty {
            newFeatures = unlocked
            engagementState.unlockedFeatures.append(contentsOf: unlocked.map { $0.id })
            logger.info("New features unlocked: \(unlocked.count)")
        }
    }

    private func shouldRefreshContent(_ frequency: ContentRefreshFrequency) -> Bool {
        guard let lastCheck = engagementState.lastEngagementCheck else { return true }

        let daysSince = calendar.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0

        switch frequency {
        case .daily: return daysSince >= 1
        case .weekly: return daysSince >= 7
        case .monthly: return daysSince >= 30
        case .quarterly: return daysSince >= 90
        }
    }

    private func refreshDailyContent(family: Family) async {
        logger.info("Refreshing daily content")
        let _ = await contentRefresh.performScheduledRefresh(family: family)
    }

    private func refreshWeeklyContent(family: Family) async {
        logger.info("Refreshing weekly content")
        engagementState.contentRotationWeek += 1
    }

    // MARK: - State Persistence

    private func saveState() {
        // In production, save to UserDefaults or Core Data
        logger.info("Saving engagement state")
        personalization.savePreferences()
        achievements.saveProgress()
    }

    func loadState() {
        // In production, load from UserDefaults or Core Data
        logger.info("Loading engagement state")
    }

    // MARK: - Public API for Skills

    /// Called by skills to get varied responses
    func getVariedResponse(base: String, variants: [String] = []) -> String {
        let varied = randomness.varyResponse(base: base, variants: variants)
        return personalization.formatResponse(varied)
    }

    /// Gets success message
    func getSuccessMessage() -> String {
        personalization.formatResponse(randomness.getSuccessMessage())
    }

    /// Gets confirmation message
    func getConfirmation() -> String {
        personalization.formatResponse(randomness.getConfirmation())
    }

    /// Gets thinking/processing message
    func getThinkingMessage() -> String {
        personalization.formatResponse(randomness.getThinkingMessage())
    }

    // MARK: - Reporting

    /// Generates engagement report for user
    func generateEngagementReport() -> String {
        let stats = engagementState.stats
        let achievementStats = achievements.getStatistics()
        let personalizationSummary = personalization.getPersonalizationSummary()

        return """
        📊 Your OpenClaw Journey

        **Activity**
        - Days since install: \(stats.daysSinceInstall)
        - Current streak: \(stats.currentStreak) days
        - Longest streak: \(stats.longestStreak) days
        - Total interactions: \(stats.totalInteractions)

        **Achievements**
        \(achievementStats.summary)

        **Personalization**
        \(personalizationSummary.description)

        **Skills Usage**
        \(stats.skillUsageCounts.map { "- \($0.key.rawValue): \($0.value)" }.joined(separator: "\n"))

        You're doing amazing! Keep up the great work managing your family! 🌟
        """
    }
}
