import Foundation

/// Gamifies engagement through achievements and milestones to celebrate
/// user progress without being intrusive or annoying.
final class AchievementSystem {
    private let logger = AppLogger.shared
    private var earnedAchievements: Set<UUID> = []

    // MARK: - Achievement Catalog

    private lazy var allAchievements: [Achievement] = [
        // Usage Milestones
        Achievement(
            title: "First Week Champion",
            description: "Used OpenClaw for 7 days",
            category: .usage,
            milestone: .daysActive(7),
            iconName: "calendar",
            celebrationMessage: "You've made it through your first week! You're building great habits! 🎉"
        ),
        Achievement(
            title: "Monthly Milestone",
            description: "30 days of family management excellence",
            category: .usage,
            milestone: .daysActive(30),
            iconName: "star.fill",
            celebrationMessage: "One month with OpenClaw! You're a family management pro! 🌟"
        ),
        Achievement(
            title: "100 Day Club",
            description: "100 days of consistent use",
            category: .usage,
            milestone: .daysActive(100),
            iconName: "trophy.fill",
            celebrationMessage: "100 days! You're a OpenClaw power user! Your dedication is inspiring! 💯"
        ),

        // Consistency Achievements
        Achievement(
            title: "Week Warrior",
            description: "7-day usage streak",
            category: .consistency,
            milestone: .streak(7),
            iconName: "flame.fill",
            celebrationMessage: "7 days in a row! You're on fire! 🔥"
        ),
        Achievement(
            title: "Consistency King",
            description: "30-day usage streak",
            category: .consistency,
            milestone: .streak(30),
            iconName: "crown.fill",
            celebrationMessage: "30-day streak! You're absolutely crushing it! 👑"
        ),
        Achievement(
            title: "Unstoppable",
            description: "60-day usage streak",
            category: .consistency,
            milestone: .streak(60),
            iconName: "bolt.fill",
            celebrationMessage: "60 days straight! Nothing can stop you now! ⚡"
        ),

        // Skill-Specific: Meal Planning
        Achievement(
            title: "Meal Planner",
            description: "Planned 10 meals",
            category: .skill,
            milestone: .skillUsage(.mealPlanning, 10),
            iconName: "fork.knife",
            celebrationMessage: "10 meals planned! Your family is eating well! 🍽️"
        ),
        Achievement(
            title: "Chef's Choice",
            description: "Planned 25 meals",
            category: .skill,
            milestone: .skillUsage(.mealPlanning, 25),
            iconName: "chef.fill",
            celebrationMessage: "25 meals! You're a menu planning master! 👨‍🍳"
        ),
        Achievement(
            title: "Culinary Expert",
            description: "Planned 50 meals",
            category: .skill,
            milestone: .skillUsage(.mealPlanning, 50),
            iconName: "star.circle.fill",
            celebrationMessage: "50 meals planned! Your meal planning skills are world-class! 🌟"
        ),

        // Skill-Specific: Healthcare
        Achievement(
            title: "Health Conscious",
            description: "Tracked 10 health items",
            category: .skill,
            milestone: .skillUsage(.healthcare, 10),
            iconName: "heart.fill",
            celebrationMessage: "Taking care of your family's health! Great job! ❤️"
        ),
        Achievement(
            title: "Wellness Warrior",
            description: "Tracked 25 health items",
            category: .skill,
            milestone: .skillUsage(.healthcare, 25),
            iconName: "heart.circle.fill",
            celebrationMessage: "25 health check-ins! Your family's health is in good hands! 🏥"
        ),

        // Skill-Specific: Education
        Achievement(
            title: "Homework Helper",
            description: "Tracked 20 assignments",
            category: .skill,
            milestone: .skillUsage(.education, 20),
            iconName: "book.fill",
            celebrationMessage: "Keeping on top of homework! Your kids are lucky to have you! 📚"
        ),
        Achievement(
            title: "Education Champion",
            description: "Tracked 50 assignments",
            category: .skill,
            milestone: .skillUsage(.education, 50),
            iconName: "graduationcap.fill",
            celebrationMessage: "50 assignments tracked! You're raising future scholars! 🎓"
        ),

        // Skill-Specific: Family Coordination
        Achievement(
            title: "Family Organizer",
            description: "Coordinated 15 family events",
            category: .skill,
            milestone: .skillUsage(.familyCoordination, 15),
            iconName: "calendar.badge.clock",
            celebrationMessage: "Keeping everyone in sync! You're the family's MVP! 📅"
        ),
        Achievement(
            title: "Coordination Master",
            description: "Coordinated 40 family events",
            category: .skill,
            milestone: .skillUsage(.familyCoordination, 40),
            iconName: "person.3.fill",
            celebrationMessage: "40 events coordinated! Your organizational skills are amazing! 🎯"
        ),

        // Family Achievements
        Achievement(
            title: "Perfect Week",
            description: "All homework completed for the week",
            category: .family,
            milestone: .familyGoal("perfect_homework_week"),
            iconName: "checkmark.seal.fill",
            celebrationMessage: "All homework done this week! Your kids are crushing it! ✅"
        ),
        Achievement(
            title: "Health Heroes",
            description: "No missed medications for 30 days",
            category: .family,
            milestone: .familyGoal("perfect_medication_month"),
            iconName: "cross.case.fill",
            celebrationMessage: "Perfect medication compliance! Your family's health routine is solid! 💊"
        ),
        Achievement(
            title: "Meal Success",
            description: "7 days of home-cooked meals",
            category: .family,
            milestone: .familyGoal("week_homemade_meals"),
            iconName: "house.fill",
            celebrationMessage: "A week of home cooking! Your family is eating healthy! 🏡"
        ),
        Achievement(
            title: "Family Bond",
            description: "Perfect attendance at family events",
            category: .family,
            milestone: .familyGoal("perfect_attendance"),
            iconName: "heart.text.square.fill",
            celebrationMessage: "Everyone made it to family events! Building strong connections! 👨‍👩‍👧‍👦"
        )
    ]

    // MARK: - Achievement Checking

    /// Checks for new achievements based on user stats
    func checkForNewAchievements(stats: UserStats) -> [Achievement] {
        let newAchievements = allAchievements.filter { achievement in
            !earnedAchievements.contains(achievement.id) &&
            achievement.milestone.isMet(stats: stats)
        }

        if !newAchievements.isEmpty {
            logger.info("User earned \(newAchievements.count) new achievement(s)")

            // Mark as earned
            for achievement in newAchievements {
                earnedAchievements.insert(achievement.id)
            }
        }

        return newAchievements
    }

    /// Gets all earned achievements
    func getEarnedAchievements() -> [Achievement] {
        allAchievements.filter { earnedAchievements.contains($0.id) }
    }

    /// Gets achievements in progress (close to earning)
    func getInProgressAchievements(stats: UserStats, threshold: Double = 0.7) -> [AchievementProgress] {
        allAchievements
            .filter { !earnedAchievements.contains($0.id) }
            .compactMap { achievement -> AchievementProgress? in
                let progress = calculateProgress(for: achievement, stats: stats)
                if progress >= threshold && progress < 1.0 {
                    return AchievementProgress(
                        achievement: achievement,
                        progress: progress,
                        remainingSteps: getRemainingSteps(for: achievement, stats: stats)
                    )
                }
                return nil
            }
            .sorted { $0.progress > $1.progress }
    }

    private func calculateProgress(for achievement: Achievement, stats: UserStats) -> Double {
        switch achievement.milestone {
        case .daysActive(let required):
            return min(1.0, Double(stats.daysSinceInstall) / Double(required))

        case .skillUsage(let skill, let required):
            let current = stats.skillUsageCounts[skill] ?? 0
            return min(1.0, Double(current) / Double(required))

        case .streak(let required):
            return min(1.0, Double(stats.currentStreak) / Double(required))

        case .familyGoal:
            // Family goals are binary - either achieved or not
            return achievement.milestone.isMet(stats: stats) ? 1.0 : 0.0
        }
    }

    private func getRemainingSteps(for achievement: Achievement, stats: UserStats) -> String {
        switch achievement.milestone {
        case .daysActive(let required):
            let remaining = required - stats.daysSinceInstall
            return "\(remaining) more day\(remaining == 1 ? "" : "s")"

        case .skillUsage(let skill, let required):
            let current = stats.skillUsageCounts[skill] ?? 0
            let remaining = required - current
            return "\(remaining) more use\(remaining == 1 ? "" : "s") of \(skill.rawValue)"

        case .streak(let required):
            let remaining = required - stats.currentStreak
            return "\(remaining) more day\(remaining == 1 ? "" : "s") in a row"

        case .familyGoal(let goal):
            return "Complete \(goal.replacingOccurrences(of: "_", with: " "))"
        }
    }

    // MARK: - Achievement Display

    /// Creates a non-intrusive celebration for achievement
    func celebrateAchievement(_ achievement: Achievement) -> AchievementCelebration {
        AchievementCelebration(
            achievement: achievement,
            style: getCelebrationStyle(for: achievement.category),
            showDuration: 5.0, // seconds
            soundEffect: getSoundEffect(for: achievement.category)
        )
    }

    private func getCelebrationStyle(for category: Achievement.AchievementCategory) -> CelebrationStyle {
        switch category {
        case .usage:
            return .confetti
        case .consistency:
            return .fireworks
        case .skill:
            return .stars
        case .family:
            return .hearts
        }
    }

    private func getSoundEffect(for category: Achievement.AchievementCategory) -> String {
        switch category {
        case .usage: return "achievement_unlocked"
        case .consistency: return "streak_milestone"
        case .skill: return "skill_mastered"
        case .family: return "family_win"
        }
    }

    struct AchievementCelebration {
        let achievement: Achievement
        let style: CelebrationStyle
        let showDuration: Double
        let soundEffect: String
    }

    enum CelebrationStyle {
        case confetti, fireworks, stars, hearts
    }

    struct AchievementProgress {
        let achievement: Achievement
        let progress: Double // 0.0 to 1.0
        let remainingSteps: String

        var percentComplete: Int {
            Int(progress * 100)
        }

        var motivationalMessage: String {
            if progress >= 0.9 {
                return "So close! Just \(remainingSteps)!"
            } else if progress >= 0.7 {
                return "Great progress! \(remainingSteps) to go!"
            } else {
                return "Keep it up! \(remainingSteps) remaining."
            }
        }
    }

    // MARK: - Statistics

    /// Gets achievement statistics
    func getStatistics() -> AchievementStatistics {
        let totalAchievements = allAchievements.count
        let earned = earnedAchievements.count
        let percentage = totalAchievements > 0 ? (Double(earned) / Double(totalAchievements)) : 0.0

        let byCategory = Dictionary(grouping: allAchievements) { $0.category }
        let earnedByCategory = byCategory.mapValues { achievements in
            achievements.filter { earnedAchievements.contains($0.id) }.count
        }

        return AchievementStatistics(
            totalAchievements: totalAchievements,
            earnedAchievements: earned,
            completionPercentage: percentage,
            earnedByCategory: earnedByCategory
        )
    }

    struct AchievementStatistics {
        let totalAchievements: Int
        let earnedAchievements: Int
        let completionPercentage: Double
        let earnedByCategory: [Achievement.AchievementCategory: Int]

        var summary: String {
            """
            Achievement Progress:
            - Earned: \(earnedAchievements)/\(totalAchievements) (\(Int(completionPercentage * 100))%)
            - Usage: \(earnedByCategory[.usage] ?? 0)
            - Consistency: \(earnedByCategory[.consistency] ?? 0)
            - Skill: \(earnedByCategory[.skill] ?? 0)
            - Family: \(earnedByCategory[.family] ?? 0)
            """
        }
    }

    // MARK: - Leaderboard (Family)

    /// Creates a friendly family leaderboard (optional feature)
    func createFamilyLeaderboard(familyMembers: [FamilyMemberStats]) -> FamilyLeaderboard {
        let sorted = familyMembers.sorted { $0.achievementCount > $1.achievementCount }

        return FamilyLeaderboard(
            members: sorted,
            totalFamilyAchievements: sorted.reduce(0) { $0 + $1.achievementCount },
            topPerformer: sorted.first?.name ?? "Unknown"
        )
    }

    struct FamilyMemberStats {
        let name: String
        let achievementCount: Int
        let currentStreak: Int
    }

    struct FamilyLeaderboard {
        let members: [FamilyMemberStats]
        let totalFamilyAchievements: Int
        let topPerformer: String

        var encouragingMessage: String {
            "Amazing work, \(topPerformer)! The whole family is doing great with \(totalFamilyAchievements) achievements!"
        }
    }

    // MARK: - Persistence

    func saveProgress() {
        // In production, save to UserDefaults or Core Data
        logger.info("Saving achievement progress: \(earnedAchievements.count) achievements")
    }

    func loadProgress(achievementIds: Set<UUID>) {
        earnedAchievements = achievementIds
        logger.info("Loaded \(earnedAchievements.count) earned achievements")
    }

    // MARK: - Special Events

    /// Checks for special date-based achievements (birthdays, holidays, etc.)
    func checkSpecialEventAchievements(family: Family) -> [SpecialAchievement] {
        var special: [SpecialAchievement] = []
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)

        // Birthday achievements
        for member in family.members {
            if let birthYear = member.birthYear {
                let birthMonth = calendar.component(.month, from: calendar.date(from: DateComponents(year: birthYear, month: 1, day: 1)) ?? today)
                let birthDay = calendar.component(.day, from: calendar.date(from: DateComponents(year: birthYear, month: 1, day: 1)) ?? today)

                if month == birthMonth && day == birthDay {
                    special.append(SpecialAchievement(
                        title: "🎂 Birthday!",
                        description: "Happy birthday to \(member.name)!",
                        date: today
                    ))
                }
            }
        }

        // Holiday achievements
        if month == 12 && day == 25 {
            special.append(SpecialAchievement(
                title: "🎄 Holiday Season",
                description: "Merry Christmas! Great job keeping the family organized during the holidays!",
                date: today
            ))
        }

        if month == 7 && day == 4 {
            special.append(SpecialAchievement(
                title: "🎆 Independence Day",
                description: "Happy 4th of July! Hope you're having a great family celebration!",
                date: today
            ))
        }

        return special
    }

    struct SpecialAchievement {
        let title: String
        let description: String
        let date: Date
    }
}
