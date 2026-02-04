import Foundation

// Import required types from other modules
// SkillType is defined in CoreModels.swift
// ProteinType is defined in MealPlanningModels.swift

// MARK: - Content Rotation Models

struct RecipeRotation: Codable {
    var weekNumber: Int
    var newRecipes: [Recipe]
    var seasonalTheme: SeasonalTheme
    var culturalEvents: [CulturalEvent]
    var trendingRecipes: [Recipe]
}

enum SeasonalTheme: String, Codable {
    case spring, summer, fall, winter

    var currentSeason: SeasonalTheme {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    var description: String {
        switch self {
        case .spring: return "Fresh spring vegetables, light salads, grilling season begins"
        case .summer: return "BBQ favorites, cold soups, fresh fruits, outdoor dining"
        case .fall: return "Hearty stews, pumpkin dishes, comfort foods, holiday prep"
        case .winter: return "Warm soups, slow-cooked meals, holiday traditions, citrus"
        }
    }

    var suggestedIngredients: [String] {
        switch self {
        case .spring: return ["asparagus", "peas", "strawberries", "lamb", "artichokes"]
        case .summer: return ["tomatoes", "corn", "watermelon", "zucchini", "peaches"]
        case .fall: return ["pumpkin", "squash", "apples", "sweet potato", "brussels sprouts"]
        case .winter: return ["root vegetables", "citrus", "kale", "cranberries", "pomegranate"]
        }
    }
}

struct CulturalEvent: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var cuisine: String
    var suggestedRecipes: [String]
    var description: String

    static var upcomingEvents: [CulturalEvent] {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)

        var events: [CulturalEvent] = [
            CulturalEvent(
                name: "Lunar New Year",
                date: calendar.date(from: DateComponents(year: year, month: 2, day: 10)) ?? now,
                cuisine: "Chinese",
                suggestedRecipes: ["Dumplings", "Longevity Noodles", "Spring Rolls"],
                description: "Celebrate with traditional dishes symbolizing prosperity and good fortune"
            ),
            CulturalEvent(
                name: "Cinco de Mayo",
                date: calendar.date(from: DateComponents(year: year, month: 5, day: 5)) ?? now,
                cuisine: "Mexican",
                suggestedRecipes: ["Tacos", "Guacamole", "Enchiladas"],
                description: "Mexican heritage celebration with vibrant flavors"
            ),
            CulturalEvent(
                name: "July 4th",
                date: calendar.date(from: DateComponents(year: year, month: 7, day: 4)) ?? now,
                cuisine: "American",
                suggestedRecipes: ["BBQ Ribs", "Coleslaw", "Apple Pie"],
                description: "Independence Day cookout classics"
            ),
            CulturalEvent(
                name: "Diwali",
                date: calendar.date(from: DateComponents(year: year, month: 10, day: 31)) ?? now,
                cuisine: "Indian",
                suggestedRecipes: ["Samosas", "Butter Chicken", "Gulab Jamun"],
                description: "Festival of lights celebration with traditional sweets and savories"
            ),
            CulturalEvent(
                name: "Thanksgiving",
                date: calendar.date(from: DateComponents(year: year, month: 11, day: 28)) ?? now,
                cuisine: "American",
                suggestedRecipes: ["Roast Turkey", "Pumpkin Pie", "Stuffing"],
                description: "Traditional American harvest celebration"
            ),
            CulturalEvent(
                name: "Christmas",
                date: calendar.date(from: DateComponents(year: year, month: 12, day: 25)) ?? now,
                cuisine: "American",
                suggestedRecipes: ["Honey Glazed Ham", "Sugar Cookies", "Hot Chocolate"],
                description: "Holiday feast traditions"
            )
        ]

        return events.filter { $0.date > now }
    }
}

// MARK: - Randomness Models

struct GreetingVariation {
    var morningGreetings: [String]
    var afternoonGreetings: [String]
    var eveningGreetings: [String]
    var successMessages: [String]
    var encouragements: [String]

    static let standard = GreetingVariation(
        morningGreetings: [
            "Good morning! Ready to plan an amazing day?",
            "Morning! Let's make today great.",
            "Rise and shine! What's on the agenda today?",
            "Good morning! I'm here to help.",
            "Morning! Let's tackle today together.",
            "Hey there! Ready for a fresh start?",
            "Good morning! What can I help you with today?",
            "Morning! Hope you slept well.",
            "Good morning! Let's get organized.",
            "Hey! Let's make today productive."
        ],
        afternoonGreetings: [
            "Good afternoon! How's your day going?",
            "Afternoon! Need help with anything?",
            "Hey! Hope you're having a good day.",
            "Good afternoon! What's next on your list?",
            "Afternoon! Let's keep the momentum going.",
            "Hi there! How can I assist you?",
            "Good afternoon! Ready to plan ahead?",
            "Hey! Let's tackle what's next.",
            "Afternoon! What can I do for you?",
            "Hi! Hope your day is going smoothly."
        ],
        eveningGreetings: [
            "Good evening! Ready to wind down?",
            "Evening! Let's plan for tomorrow.",
            "Hey! How was your day?",
            "Good evening! Time to relax and plan ahead.",
            "Evening! Let's prep for a smooth tomorrow.",
            "Hi there! Ready for the evening routine?",
            "Good evening! What's on your mind?",
            "Hey! Let's get ready for tomorrow.",
            "Evening! How can I help you wind down?",
            "Hi! Ready to wrap up the day?"
        ],
        successMessages: [
            "Great job! You're crushing it!",
            "Nicely done! Keep up the good work!",
            "Excellent! You're on a roll!",
            "Perfect! That's all set.",
            "Wonderful! You're making great progress!",
            "Awesome! All taken care of.",
            "Fantastic! You're doing amazing!",
            "Well done! That was smooth.",
            "Brilliant! You're on top of things!",
            "Outstanding! Keep it going!"
        ],
        encouragements: [
            "You've got this!",
            "One step at a time, you're doing great.",
            "Making progress every day!",
            "You're handling this like a pro!",
            "Keep going, you're almost there!",
            "You're doing better than you think!",
            "Small steps lead to big wins!",
            "You're making it happen!",
            "Progress, not perfection!",
            "You're building great habits!"
        ]
    )
}

struct SurpriseDelight: Codable {
    var id: UUID = UUID()
    var message: String
    var triggerCondition: TriggerCondition
    var frequency: DelightFrequency
    var lastShown: Date?

    enum TriggerCondition: String, Codable {
        case weeklyStreak
        case monthlyMilestone
        case perfectWeek
        case firstTimeUser
        case randomPositive
    }

    enum DelightFrequency: String, Codable {
        case daily, weekly, biweekly, monthly, oneTime
    }
}

// MARK: - Progressive Discovery Models

struct FeatureDiscovery: Codable, Identifiable {
    var id: UUID = UUID()
    var featureName: String
    var title: String
    var description: String
    var unlockCriteria: UnlockCriteria
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var isNew: Bool = true
    var category: SkillType
    var priority: Int // Lower = shown first

    enum UnlockCriteria: Codable {
        case daysSinceInstall(Int)
        case skillUsageCount(SkillType, Int)
        case milestone(String)
        case immediate

        func isMet(userStats: UserStats) -> Bool {
            switch self {
            case .daysSinceInstall(let days):
                return userStats.daysSinceInstall >= days
            case .skillUsageCount(let skill, let count):
                return (userStats.skillUsageCounts[skill] ?? 0) >= count
            case .milestone(let name):
                return userStats.achievedMilestones.contains(name)
            case .immediate:
                return true
            }
        }

        // MARK: - Codable
        private enum CodingKeys: String, CodingKey {
            case type
            case days
            case skill
            case count
            case milestoneName
        }

        private enum CriteriaType: String, Codable {
            case daysSinceInstall
            case skillUsageCount
            case milestone
            case immediate
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(CriteriaType.self, forKey: .type)

            switch type {
            case .daysSinceInstall:
                let days = try container.decode(Int.self, forKey: .days)
                self = .daysSinceInstall(days)
            case .skillUsageCount:
                let skill = try container.decode(SkillType.self, forKey: .skill)
                let count = try container.decode(Int.self, forKey: .count)
                self = .skillUsageCount(skill, count)
            case .milestone:
                let name = try container.decode(String.self, forKey: .milestoneName)
                self = .milestone(name)
            case .immediate:
                self = .immediate
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .daysSinceInstall(let days):
                try container.encode(CriteriaType.daysSinceInstall, forKey: .type)
                try container.encode(days, forKey: .days)
            case .skillUsageCount(let skill, let count):
                try container.encode(CriteriaType.skillUsageCount, forKey: .type)
                try container.encode(skill, forKey: .skill)
                try container.encode(count, forKey: .count)
            case .milestone(let name):
                try container.encode(CriteriaType.milestone, forKey: .type)
                try container.encode(name, forKey: .milestoneName)
            case .immediate:
                try container.encode(CriteriaType.immediate, forKey: .type)
            }
        }
    }
}

struct ContextualTip: Codable, Identifiable {
    var id: UUID = UUID()
    var message: String
    var relatedFeature: String
    var usageContext: String
    var priority: Int
    var timesShown: Int = 0
    var maxShows: Int = 3
}

// MARK: - Content Refresh Models

enum ContentRefreshFrequency: String, Codable {
    case daily, weekly, monthly, quarterly
}

struct DynamicContent: Codable {
    var contentId: String
    var lastRefreshed: Date
    var frequency: ContentRefreshFrequency
    var dataSource: String
    var cachedData: String?

    func needsRefresh() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch frequency {
        case .daily:
            return !calendar.isDateInToday(lastRefreshed)
        case .weekly:
            let weekDiff = calendar.dateComponents([.weekOfYear], from: lastRefreshed, to: now).weekOfYear ?? 0
            return weekDiff >= 1
        case .monthly:
            let monthDiff = calendar.dateComponents([.month], from: lastRefreshed, to: now).month ?? 0
            return monthDiff >= 1
        case .quarterly:
            let monthDiff = calendar.dateComponents([.month], from: lastRefreshed, to: now).month ?? 0
            return monthDiff >= 3
        }
    }
}

// MARK: - Personalization Models

struct UserPreferences: Codable {
    var favoriteCuisines: [String: Int] = [:] // Cuisine -> frequency
    var favoriteProteins: [String: Int] = [:] // ProteinType.rawValue -> frequency
    var preferredCookTimes: [Int] = [] // Minutes
    var mealSuccessRatings: [String: Double] = [:] // RecipeID.uuidString -> rating
    var optimalReminderTimes: [String: Date] = [:] // ReminderType -> time
    var briefingReadPatterns: [String: Bool] = [:] // Section -> isRead
    var conversationTone: ConversationTone = .friendly
    var lastUpdated: Date = Date()

    // Helper methods to convert between types
    func getProteinFrequency(_ protein: ProteinType) -> Int {
        favoriteProteins[protein.rawValue] ?? 0
    }

    mutating func setProteinFrequency(_ protein: ProteinType, count: Int) {
        favoriteProteins[protein.rawValue] = count
    }

    func getMealRating(_ recipeId: UUID) -> Double? {
        mealSuccessRatings[recipeId.uuidString]
    }

    mutating func setMealRating(_ recipeId: UUID, rating: Double) {
        mealSuccessRatings[recipeId.uuidString] = rating
    }
}

enum ConversationTone: String, Codable {
    case formal, friendly, casual, concise
}

struct UserStats: Codable {
    var installDate: Date
    var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }
    var skillUsageCounts: [String: Int] = [:] // SkillType.rawValue -> count
    var achievedMilestones: Set<String> = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalInteractions: Int = 0

    // Helper methods to convert between types
    func getSkillUsageCount(_ skill: SkillType) -> Int {
        skillUsageCounts[skill.rawValue] ?? 0
    }

    mutating func setSkillUsageCount(_ skill: SkillType, count: Int) {
        skillUsageCounts[skill.rawValue] = count
    }

    mutating func incrementSkillUsage(_ skill: SkillType) {
        let current = getSkillUsageCount(skill)
        setSkillUsageCount(skill, count: current + 1)
    }
    var lastActiveDate: Date?
}

// MARK: - Change Management Models

struct ChangeEvent: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ChangeType
    var title: String
    var description: String
    var scheduledDate: Date
    var isOptional: Bool
    var userAccepted: Bool?
    var category: ChangeCategory

    enum ChangeType: String, Codable {
        case newRecipe, newFeature, newTip, uiUpdate, behaviorChange
    }

    enum ChangeCategory: String, Codable {
        case content, functionality, interface, algorithm
    }
}

struct ChangeBudget: Codable {
    var weeklyLimit: Int = 2
    var changesThisWeek: [ChangeEvent] = []
    var weekStartDate: Date

    var hasCapacity: Bool {
        changesThisWeek.count < weeklyLimit
    }

    mutating func reset() {
        let calendar = Calendar.current
        if let weeksSince = calendar.dateComponents([.weekOfYear], from: weekStartDate, to: Date()).weekOfYear,
           weeksSince >= 1 {
            changesThisWeek = []
            weekStartDate = calendar.startOfDay(for: Date())
        }
    }
}

// MARK: - Achievement Models

struct Achievement: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var category: AchievementCategory
    var milestone: Milestone
    var earnedAt: Date?
    var isEarned: Bool = false
    var iconName: String
    var celebrationMessage: String

    enum AchievementCategory: String, Codable {
        case usage, consistency, skill, family
    }

    enum Milestone: Codable, Equatable {
        case daysActive(Int)
        case skillUsage(SkillType, Int)
        case streak(Int)
        case familyGoal(String)

        func isMet(stats: UserStats) -> Bool {
            switch self {
            case .daysActive(let days):
                return stats.daysSinceInstall >= days
            case .skillUsage(let skill, let count):
                return stats.getSkillUsageCount(skill) >= count
            case .streak(let days):
                return stats.currentStreak >= days
            case .familyGoal(let goal):
                return stats.achievedMilestones.contains(goal)
            }
        }

        // MARK: - Codable
        private enum CodingKeys: String, CodingKey {
            case type
            case days
            case skill
            case count
            case goal
        }

        private enum MilestoneType: String, Codable {
            case daysActive
            case skillUsage
            case streak
            case familyGoal
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(MilestoneType.self, forKey: .type)

            switch type {
            case .daysActive:
                let days = try container.decode(Int.self, forKey: .days)
                self = .daysActive(days)
            case .skillUsage:
                let skill = try container.decode(SkillType.self, forKey: .skill)
                let count = try container.decode(Int.self, forKey: .count)
                self = .skillUsage(skill, count)
            case .streak:
                let days = try container.decode(Int.self, forKey: .days)
                self = .streak(days)
            case .familyGoal:
                let goal = try container.decode(String.self, forKey: .goal)
                self = .familyGoal(goal)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .daysActive(let days):
                try container.encode(MilestoneType.daysActive, forKey: .type)
                try container.encode(days, forKey: .days)
            case .skillUsage(let skill, let count):
                try container.encode(MilestoneType.skillUsage, forKey: .type)
                try container.encode(skill, forKey: .skill)
                try container.encode(count, forKey: .count)
            case .streak(let days):
                try container.encode(MilestoneType.streak, forKey: .type)
                try container.encode(days, forKey: .days)
            case .familyGoal(let goal):
                try container.encode(MilestoneType.familyGoal, forKey: .type)
                try container.encode(goal, forKey: .goal)
            }
        }
    }
}

// MARK: - Engagement State

struct EngagementState: Codable {
    var userId: String
    var installDate: Date
    var stats: UserStats
    var preferences: UserPreferences
    var unlockedFeatures: [UUID] = []
    var earnedAchievements: [UUID] = []
    var contentRotationWeek: Int = 1
    var changeBudget: ChangeBudget
    var lastEngagementCheck: Date?

    init(userId: String) {
        self.userId = userId
        self.installDate = Date()
        self.stats = UserStats(installDate: Date())
        self.preferences = UserPreferences()
        self.changeBudget = ChangeBudget(weekStartDate: Date())
    }
}
