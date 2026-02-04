import Foundation

/// Manages the rate and type of changes introduced to users to prevent
/// overwhelming them while still keeping the experience fresh.
final class ChangeManager {
    private let logger = AppLogger.shared
    private var changeBudget: ChangeBudget
    private var userPreferences: ChangePreferences

    init(changeBudget: ChangeBudget = ChangeBudget(weekStartDate: Date())) {
        self.changeBudget = changeBudget
        self.userPreferences = ChangePreferences()
    }

    // MARK: - Change Budget Management

    /// Checks if a new change can be introduced this week
    func canIntroduceChange(type: ChangeEvent.ChangeType, priority: Priority = .medium) -> Bool {
        // Reset budget if new week
        changeBudget.reset()

        // Check capacity
        if !changeBudget.hasCapacity {
            logger.info("Change budget exhausted for this week")
            return false
        }

        // Check if user has opted out of this type of change
        if userPreferences.blockedChangeTypes.contains(type) {
            logger.info("User has opted out of \(type.rawValue) changes")
            return false
        }

        // High priority changes can exceed budget slightly
        if priority == .urgent || priority == .high {
            return changeBudget.changesThisWeek.count < changeBudget.weeklyLimit + 1
        }

        return true
    }

    /// Records that a change has been introduced
    func recordChange(_ change: ChangeEvent) {
        logger.info("Recording change: \(change.title)")
        changeBudget.changesThisWeek.append(change)
    }

    /// Gets changes scheduled for this week
    func getScheduledChanges() -> [ChangeEvent] {
        changeBudget.reset()
        return changeBudget.changesThisWeek
    }

    // MARK: - Change Categorization

    /// Proposes changes for the upcoming week based on available budget
    func proposeChanges(
        availableChanges: [ChangeEvent],
        userStats: UserStats
    ) -> [ChangeEvent] {
        changeBudget.reset()

        // Filter out changes user has blocked
        let eligible = availableChanges.filter { change in
            !userPreferences.blockedChangeTypes.contains(change.type) &&
            !userPreferences.dontChangePreferences.contains(change.id)
        }

        // Prioritize by category - balance different types
        let categorized = Dictionary(grouping: eligible, by: { $0.category })

        var proposed: [ChangeEvent] = []
        let categories: [ChangeEvent.ChangeCategory] = [.content, .functionality, .interface, .algorithm]

        // Try to get one change from each category
        for category in categories {
            if proposed.count >= changeBudget.weeklyLimit {
                break
            }

            if let changes = categorized[category],
               let change = selectBestChange(from: changes, userStats: userStats) {
                proposed.append(change)
            }
        }

        // Fill remaining budget with high-priority changes
        let remaining = changeBudget.weeklyLimit - proposed.count
        if remaining > 0 {
            let highPriority = eligible
                .filter { !proposed.contains($0) }
                .sorted { getChangePriority($0, userStats: userStats) >
                         getChangePriority($1, userStats: userStats) }

            proposed.append(contentsOf: Array(highPriority.prefix(remaining)))
        }

        return proposed
    }

    private func selectBestChange(
        from changes: [ChangeEvent],
        userStats: UserStats
    ) -> ChangeEvent? {
        // Score changes based on relevance to user
        changes.max { a, b in
            getChangePriority(a, userStats: userStats) <
            getChangePriority(b, userStats: userStats)
        }
    }

    private func getChangePriority(_ change: ChangeEvent, userStats: UserStats) -> Double {
        var score = 1.0

        // Content changes are safest
        switch change.category {
        case .content:
            score *= 1.5
        case .functionality:
            score *= 1.2
        case .interface:
            score *= 0.8 // More disruptive
        case .algorithm:
            score *= 1.0
        }

        // New users get fewer changes
        if userStats.daysSinceInstall < 14 {
            score *= 0.5
        }

        // Power users can handle more changes
        if userStats.daysSinceInstall > 100 {
            score *= 1.3
        }

        return score
    }

    // MARK: - Gradual Rollout

    /// Determines if user should receive a gradual rollout feature
    func shouldReceiveGradualFeature(
        featureId: String,
        rolloutPercentage: Double,
        userStats: UserStats
    ) -> Bool {
        // Use deterministic hash based on userId to ensure consistency
        let hash = abs(featureId.hashValue)
        let userBucket = Double(hash % 100) / 100.0

        // Check if user falls within rollout percentage
        if userBucket > rolloutPercentage {
            return false
        }

        // Additional checks based on user stats
        // New users (< 7 days) - only get stable features
        if userStats.daysSinceInstall < 7 && rolloutPercentage < 1.0 {
            return false
        }

        return true
    }

    /// Stages a rollout - increases percentage over time
    func getCurrentRolloutPercentage(
        startDate: Date,
        fullRolloutDays: Int = 14
    ) -> Double {
        let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: startDate,
            to: Date()
        ).day ?? 0

        // Start at 10%, increase to 100% over fullRolloutDays
        let basePercentage = 0.1
        let increment = (1.0 - basePercentage) / Double(fullRolloutDays)

        let currentPercentage = min(1.0, basePercentage + (increment * Double(daysSinceStart)))

        logger.info("Rollout at \(Int(currentPercentage * 100))% (day \(daysSinceStart))")

        return currentPercentage
    }

    // MARK: - User Preferences

    /// Allows user to opt out of specific change types
    func optOutOfChangeType(_ type: ChangeEvent.ChangeType) {
        logger.info("User opted out of \(type.rawValue) changes")
        userPreferences.blockedChangeTypes.insert(type)
    }

    /// Allows user to mark specific features as "don't change"
    func lockFeature(_ changeId: UUID, reason: String) {
        logger.info("User locked feature: \(reason)")
        userPreferences.dontChangePreferences.insert(changeId)
        userPreferences.lockReasons[changeId] = reason
    }

    /// Checks if user has locked a feature
    func isFeatureLocked(_ changeId: UUID) -> Bool {
        userPreferences.dontChangePreferences.contains(changeId)
    }

    /// Gets user's change preferences
    func getChangePreferences() -> ChangePreferences {
        userPreferences
    }

    // MARK: - Opt-in for Experimental Features

    /// Checks if user has opted into experimental features
    func hasOptedIntoExperimental() -> Bool {
        userPreferences.experimentalFeaturesEnabled
    }

    /// Enables experimental features
    func enableExperimentalFeatures() {
        logger.info("User enabled experimental features")
        userPreferences.experimentalFeaturesEnabled = true
    }

    /// Disables experimental features
    func disableExperimentalFeatures() {
        logger.info("User disabled experimental features")
        userPreferences.experimentalFeaturesEnabled = false
    }

    /// Gets experimental features available to user
    func getExperimentalFeatures() -> [ExperimentalFeature] {
        guard hasOptedIntoExperimental() else { return [] }

        return [
            ExperimentalFeature(
                name: "AI Recipe Generation",
                description: "Generate custom recipes based on ingredients you have",
                status: .beta,
                risks: ["May suggest unusual combinations", "Nutritional info might be estimated"]
            ),
            ExperimentalFeature(
                name: "Voice Commands",
                description: "Control OpenClaw with voice",
                status: .alpha,
                risks: ["May misinterpret commands", "Requires microphone access"]
            ),
            ExperimentalFeature(
                name: "Smart Predictions",
                description: "Predict what you'll need before you ask",
                status: .beta,
                risks: ["May make incorrect predictions", "Uses more data"]
            )
        ]
    }

    struct ExperimentalFeature {
        let name: String
        let description: String
        let status: FeatureStatus
        let risks: [String]

        enum FeatureStatus: String {
            case alpha = "Alpha (Unstable)"
            case beta = "Beta (Testing)"
            case preview = "Preview (Almost Ready)"
        }
    }

    // MARK: - Change Announcements

    /// Creates user-friendly announcement for change
    func announceChange(_ change: ChangeEvent) -> ChangeAnnouncement {
        var announcement = ChangeAnnouncement(
            title: change.title,
            description: change.description,
            type: change.type,
            canOptOut: change.isOptional
        )

        // Customize message based on type
        switch change.type {
        case .newRecipe:
            announcement.emoji = "🍽️"
            announcement.callToAction = "Try it tonight"

        case .newFeature:
            announcement.emoji = "✨"
            announcement.callToAction = "Learn more"

        case .newTip:
            announcement.emoji = "💡"
            announcement.callToAction = "Got it"

        case .uiUpdate:
            announcement.emoji = "🎨"
            announcement.callToAction = "See what's new"
            announcement.helpText = "Don't worry, your data and settings are unchanged"

        case .behaviorChange:
            announcement.emoji = "⚙️"
            announcement.callToAction = "Understand changes"
            announcement.helpText = "This improves your experience based on feedback"
        }

        return announcement
    }

    struct ChangeAnnouncement {
        var title: String
        var description: String
        var type: ChangeEvent.ChangeType
        var emoji: String = "📢"
        var canOptOut: Bool
        var callToAction: String = "OK"
        var helpText: String?

        var formattedMessage: String {
            var message = "\(emoji) **\(title)**\n\n\(description)"

            if let help = helpText {
                message += "\n\n\(help)"
            }

            if canOptOut {
                message += "\n\n_You can disable this in settings_"
            }

            return message
        }
    }

    // MARK: - Change History

    private var changeHistory: [ChangeEvent] = []

    /// Adds change to history
    func addToHistory(_ change: ChangeEvent) {
        var updatedChange = change
        updatedChange.userAccepted = true
        changeHistory.append(updatedChange)

        // Keep last 50 changes
        if changeHistory.count > 50 {
            changeHistory = Array(changeHistory.suffix(50))
        }
    }

    /// Gets recent change history
    func getChangeHistory(limit: Int = 10) -> [ChangeEvent] {
        Array(changeHistory.suffix(limit).reversed())
    }

    /// Gets summary of changes over time
    func getChangeSummary(days: Int = 30) -> ChangeSummary {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        ) ?? Date()

        let recentChanges = changeHistory.filter { $0.scheduledDate >= cutoffDate }

        let byType = Dictionary(grouping: recentChanges, by: { $0.type })

        return ChangeSummary(
            totalChanges: recentChanges.count,
            newRecipes: byType[.newRecipe]?.count ?? 0,
            newFeatures: byType[.newFeature]?.count ?? 0,
            newTips: byType[.newTip]?.count ?? 0,
            uiUpdates: byType[.uiUpdate]?.count ?? 0,
            behaviorChanges: byType[.behaviorChange]?.count ?? 0,
            periodDays: days
        )
    }

    struct ChangeSummary {
        let totalChanges: Int
        let newRecipes: Int
        let newFeatures: Int
        let newTips: Int
        let uiUpdates: Int
        let behaviorChanges: Int
        let periodDays: Int

        var description: String {
            """
            Changes in last \(periodDays) days:
            - Total: \(totalChanges)
            - New recipes: \(newRecipes)
            - New features: \(newFeatures)
            - Tips: \(newTips)
            - UI updates: \(uiUpdates)
            - Behavior improvements: \(behaviorChanges)
            """
        }
    }
}

// MARK: - Supporting Types

struct ChangePreferences: Codable {
    var blockedChangeTypes: Set<ChangeEvent.ChangeType> = []
    var dontChangePreferences: Set<UUID> = []
    var lockReasons: [UUID: String] = [:]
    var experimentalFeaturesEnabled: Bool = false
    var changeFrequencyPreference: ChangeFrequency = .balanced

    enum ChangeFrequency: String, Codable {
        case minimal // Only critical updates
        case balanced // Weekly 1-2 changes
        case frequent // Up to 3-4 changes per week
    }
}
