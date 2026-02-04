import Foundation

/// Manages progressive feature unlocking to avoid overwhelming new users
/// while maintaining long-term engagement through gradual discovery.
final class ProgressiveDiscovery {
    private let logger = AppLogger.shared

    // MARK: - Feature Catalog

    private lazy var allFeatures: [FeatureDiscovery] = [
        // Week 1: Core Features
        FeatureDiscovery(
            featureName: "meal_planning_basic",
            title: "Meal Planning",
            description: "Get weekly meal plans and grocery lists tailored to your family",
            unlockCriteria: .immediate,
            isUnlocked: true,
            category: .mealPlanning,
            priority: 1
        ),
        FeatureDiscovery(
            featureName: "basic_health",
            title: "Health Tracking",
            description: "Track medications and get symptom assessments",
            unlockCriteria: .immediate,
            isUnlocked: true,
            category: .healthcare,
            priority: 2
        ),
        FeatureDiscovery(
            featureName: "family_calendar",
            title: "Family Calendar",
            description: "See everyone's schedule in one place",
            unlockCriteria: .immediate,
            isUnlocked: true,
            category: .familyCoordination,
            priority: 3
        ),

        // Week 2-4: Intermediate Features
        FeatureDiscovery(
            featureName: "dietary_preferences",
            title: "Smart Recipe Filtering",
            description: "Recipes automatically filtered by your family's dietary restrictions",
            unlockCriteria: .daysSinceInstall(7),
            category: .mealPlanning,
            priority: 4
        ),
        FeatureDiscovery(
            featureName: "homework_tracking",
            title: "Homework Tracker",
            description: "Never miss an assignment - track all your kids' homework",
            unlockCriteria: .daysSinceInstall(7),
            category: .education,
            priority: 5
        ),
        FeatureDiscovery(
            featureName: "elder_check_ins",
            title: "Elder Care Check-ins",
            description: "Daily check-ins and alerts for elderly family members",
            unlockCriteria: .daysSinceInstall(10),
            category: .elderCare,
            priority: 6
        ),
        FeatureDiscovery(
            featureName: "morning_briefing",
            title: "Morning Briefing",
            description: "Start your day with a personalized family briefing",
            unlockCriteria: .daysSinceInstall(14),
            category: .mentalLoad,
            priority: 7
        ),
        FeatureDiscovery(
            featureName: "grocery_optimization",
            title: "Smart Grocery Lists",
            description: "Organized by store aisle with price estimates",
            unlockCriteria: .skillUsageCount(.mealPlanning, 5),
            category: .mealPlanning,
            priority: 8
        ),
        FeatureDiscovery(
            featureName: "provider_search",
            title: "Healthcare Provider Search",
            description: "Find doctors, dentists, and specialists near you",
            unlockCriteria: .daysSinceInstall(21),
            category: .healthcare,
            priority: 9
        ),

        // Month 2+: Advanced Features
        FeatureDiscovery(
            featureName: "seasonal_recipes",
            title: "Seasonal Recipe Rotation",
            description: "Discover recipes featuring fresh, seasonal ingredients",
            unlockCriteria: .daysSinceInstall(30),
            category: .mealPlanning,
            priority: 10
        ),
        FeatureDiscovery(
            featureName: "study_plans",
            title: "AI Study Plans",
            description: "Personalized study schedules for better grades",
            unlockCriteria: .skillUsageCount(.education, 10),
            category: .education,
            priority: 11
        ),
        FeatureDiscovery(
            featureName: "home_maintenance",
            title: "Home Maintenance Planner",
            description: "Track HVAC, plumbing, and other home maintenance",
            unlockCriteria: .daysSinceInstall(45),
            category: .homeMaintenance,
            priority: 12
        ),
        FeatureDiscovery(
            featureName: "chore_assignments",
            title: "Smart Chore Assignment",
            description: "Fairly distribute chores with age-appropriate tasks",
            unlockCriteria: .daysSinceInstall(30),
            category: .familyCoordination,
            priority: 13
        ),
        FeatureDiscovery(
            featureName: "weekly_reports",
            title: "Weekly Family Report",
            description: "Get insights on meals, health, education, and more",
            unlockCriteria: .daysSinceInstall(60),
            category: .mentalLoad,
            priority: 14
        ),

        // Power User Features (100+ days)
        FeatureDiscovery(
            featureName: "recipe_ratings",
            title: "Recipe Rating & Favorites",
            description: "Rate recipes to get better suggestions over time",
            unlockCriteria: .daysSinceInstall(100),
            category: .mealPlanning,
            priority: 15
        ),
        FeatureDiscovery(
            featureName: "custom_meal_plans",
            title: "Custom Meal Plan Templates",
            description: "Create and save your own meal plan templates",
            unlockCriteria: .skillUsageCount(.mealPlanning, 20),
            category: .mealPlanning,
            priority: 16
        ),
        FeatureDiscovery(
            featureName: "medication_alerts",
            title: "Advanced Medication Alerts",
            description: "Interaction warnings and refill reminders",
            unlockCriteria: .daysSinceInstall(100),
            category: .healthcare,
            priority: 17
        ),
        FeatureDiscovery(
            featureName: "multi_family",
            title: "Multi-Family Coordination",
            description: "Coordinate with extended family and caregivers",
            unlockCriteria: .milestone("power_user"),
            category: .familyCoordination,
            priority: 18
        )
    ]

    // MARK: - Feature Discovery

    /// Gets features that should be unlocked based on user stats
    func checkForNewUnlocks(userStats: UserStats, currentUnlocked: [UUID]) -> [FeatureDiscovery] {
        let currentUnlockedSet = Set(currentUnlocked)

        let newUnlocks = allFeatures.filter { feature in
            !currentUnlockedSet.contains(feature.id) &&
            feature.unlockCriteria.isMet(userStats: userStats)
        }

        if !newUnlocks.isEmpty {
            logger.info("Unlocking \(newUnlocks.count) new features for user")
        }

        return newUnlocks.sorted { $0.priority < $1.priority }
    }

    /// Gets currently unlocked features
    func getUnlockedFeatures(userStats: UserStats) -> [FeatureDiscovery] {
        allFeatures.filter { $0.unlockCriteria.isMet(userStats: userStats) }
    }

    /// Gets features to display in "Coming Soon" section
    func getUpcomingFeatures(userStats: UserStats, limit: Int = 3) -> [FeatureDiscovery] {
        let locked = allFeatures.filter { !$0.unlockCriteria.isMet(userStats: userStats) }

        return locked
            .sorted { $0.priority < $1.priority }
            .prefix(limit)
            .map { feature in
                var updated = feature
                // Add context about when it will unlock
                updated.description += "\n\n" + unlockDescription(for: feature.unlockCriteria, stats: userStats)
                return updated
            }
    }

    private func unlockDescription(for criteria: FeatureDiscovery.UnlockCriteria, stats: UserStats) -> String {
        switch criteria {
        case .daysSinceInstall(let days):
            let remaining = days - stats.daysSinceInstall
            if remaining > 0 {
                return "Unlocks in \(remaining) day\(remaining == 1 ? "" : "s")"
            }
            return "Unlock now!"

        case .skillUsageCount(let skill, let count):
            let current = stats.skillUsageCounts[skill] ?? 0
            let remaining = count - current
            if remaining > 0 {
                return "Use \(skill.rawValue) \(remaining) more time\(remaining == 1 ? "" : "s") to unlock"
            }
            return "Unlock now!"

        case .milestone(let name):
            return "Complete '\(name)' milestone to unlock"

        case .immediate:
            return "Available now"
        }
    }

    // MARK: - Contextual Tips

    /// Generates contextual tips based on usage patterns
    func getContextualTips(
        userStats: UserStats,
        currentSkill: SkillType?,
        previouslyShownTips: Set<UUID>
    ) -> [ContextualTip] {
        var tips: [ContextualTip] = []

        // Meal planning tips
        if let mealUsage = userStats.skillUsageCounts[.mealPlanning], mealUsage >= 3 {
            tips.append(ContextualTip(
                message: "💡 Tip: You can ask for recipes by cuisine type, like 'suggest an Italian dinner'",
                relatedFeature: "meal_planning",
                usageContext: "frequent_meal_planning",
                priority: 1
            ))
        }

        // Healthcare tips
        if userStats.daysSinceInstall >= 7 && userStats.skillUsageCounts[.healthcare] ?? 0 == 0 {
            tips.append(ContextualTip(
                message: "💊 Did you know? I can help track medications and check symptoms",
                relatedFeature: "healthcare",
                usageContext: "unused_skill",
                priority: 2
            ))
        }

        // Education tips
        if let eduUsage = userStats.skillUsageCounts[.education], eduUsage >= 5 {
            tips.append(ContextualTip(
                message: "📚 Pro tip: Ask me to 'create a study plan' for upcoming tests",
                relatedFeature: "study_plans",
                usageContext: "education_power_user",
                priority: 3
            ))
        }

        // Morning briefing tips
        if userStats.daysSinceInstall >= 14 {
            tips.append(ContextualTip(
                message: "☀️ Try asking for your 'morning briefing' to start the day organized",
                relatedFeature: "morning_briefing",
                usageContext: "established_user",
                priority: 4
            ))
        }

        // Skill-specific tips based on current context
        if let skill = currentSkill {
            tips.append(contentsOf: getSkillSpecificTips(skill: skill, stats: userStats))
        }

        // Filter out previously shown tips that have hit their max
        return tips.filter { !previouslyShownTips.contains($0.id) || $0.timesShown < $0.maxShows }
            .sorted { $0.priority < $1.priority }
    }

    private func getSkillSpecificTips(skill: SkillType, stats: UserStats) -> [ContextualTip] {
        switch skill {
        case .mealPlanning:
            return [
                ContextualTip(
                    message: "Try specifying cook time: 'dinner recipe under 30 minutes'",
                    relatedFeature: "meal_planning",
                    usageContext: "mealPlanning",
                    priority: 5
                )
            ]

        case .healthcare:
            return [
                ContextualTip(
                    message: "I can find nearby doctors and specialists - just ask!",
                    relatedFeature: "provider_search",
                    usageContext: "healthcare",
                    priority: 6
                )
            ]

        case .education:
            return [
                ContextualTip(
                    message: "Connect Google Classroom for automatic homework tracking",
                    relatedFeature: "homework_tracking",
                    usageContext: "education",
                    priority: 7
                )
            ]

        default:
            return []
        }
    }

    // MARK: - Feature Announcements

    /// Creates announcement for newly unlocked feature
    func createFeatureAnnouncement(feature: FeatureDiscovery) -> String {
        let emoji = getEmojiForCategory(feature.category)

        return """
        \(emoji) New Feature Unlocked!

        **\(feature.title)**
        \(feature.description)

        You can start using this right away. Try asking me about it!
        """
    }

    private func getEmojiForCategory(_ category: SkillType) -> String {
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

    /// Gets onboarding steps for new users
    func getOnboardingSteps(currentStep: Int = 0) -> [OnboardingStep] {
        let steps = [
            OnboardingStep(
                step: 0,
                title: "Welcome to OpenClaw!",
                description: "Let's start with the basics - meal planning and family calendar.",
                action: "Start with core features"
            ),
            OnboardingStep(
                step: 1,
                title: "Try Your First Meal Plan",
                description: "Ask me to 'plan this week's dinners' to see how easy it is.",
                action: "Generate meal plan"
            ),
            OnboardingStep(
                step: 2,
                title: "More Features Unlock Over Time",
                description: "As you use OpenClaw, you'll discover new capabilities. Take it one step at a time!",
                action: "Got it!"
            )
        ]

        return steps
    }

    struct OnboardingStep {
        let step: Int
        let title: String
        let description: String
        let action: String
    }

    // MARK: - Feature Usage Tracking

    /// Records when a feature is used to help with recommendations
    func recordFeatureUsage(featureName: String, timestamp: Date = Date()) {
        logger.info("Feature used: \(featureName)")
        // In production, this would persist to analytics
    }

    /// Determines if feature should show "New" badge
    func shouldShowNewBadge(feature: FeatureDiscovery, unlockDate: Date) -> Bool {
        let daysSinceUnlock = Calendar.current.dateComponents(
            [.day],
            from: unlockDate,
            to: Date()
        ).day ?? 0

        return daysSinceUnlock <= 7 // Show "New" for 7 days after unlock
    }
}
