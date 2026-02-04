# Integration Guide: Engagement Strategy with OpenClaw

This guide shows how to integrate the Engagement Strategy into the existing OpenClaw application.

## Step 1: Update AppState

Add the EngagementCoordinator to your AppState:

```swift
// File: App/AppState.swift

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // ... existing properties ...

    // Add engagement coordinator
    let engagementCoordinator: EngagementCoordinator

    init() {
        self.keychainManager = KeychainManager()
        self.networkMonitor = NetworkMonitor()
        self.logger = AppLogger.shared
        self.modelManager = ModelManager()
        self.skillOrchestrator = SkillOrchestrator()

        // Initialize engagement coordinator with user ID
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? UUID().uuidString
        self.engagementCoordinator = EngagementCoordinator(userId: userId)

        // Save user ID if new
        UserDefaults.standard.set(userId, forKey: "user_id")
    }

    func initialize() async {
        logger.info("Initializing OpenClaw app...")

        // ... existing initialization ...

        // Initialize engagement system
        if let family = currentFamily {
            await engagementCoordinator.handleAppLaunch(family: family)
        }

        isLoading = false
        logger.info("OpenClaw initialization complete")
    }
}
```

## Step 2: Update MealPlanningSkill

Enhance the meal planning skill with engagement features:

```swift
// File: Skills/MealPlanning/MealPlanningSkill.swift

import Foundation

final class MealPlanningSkill {
    private let spoonacularAPI = SpoonacularAPI.shared
    private let logger = AppLogger.shared

    // Access engagement through AppState
    private var engagement: EngagementCoordinator {
        // In production, inject this properly
        // For now, assume it's accessible via app state
        return AppState.shared.engagementCoordinator
    }

    func generateWeeklyPlan(family: Family) async throws -> MealPlan {
        logger.info("Generating weekly meal plan for family: \(family.name)")

        // Get recent meals to avoid repetition
        let recentMeals = loadRecentMeals(familyId: family.id)

        // Use engagement coordinator for varied, personalized suggestions
        let plannedMeals = engagement.suggestMeals(
            for: family,
            count: 7,
            recentMeals: recentMeals
        )

        // Create grocery list
        let groceryList = generateGroceryList(from: plannedMeals)

        // Calculate cost
        let estimatedCost = calculateCost(groceryList)

        // Create meal plan
        let plan = MealPlan(
            familyId: family.id,
            weekStartDate: Date(),
            meals: plannedMeals,
            groceryList: groceryList,
            estimatedCost: estimatedCost,
            status: .active
        )

        // Record interaction for engagement tracking
        engagement.recordInteraction(skill: .mealPlanning, successful: true)

        logger.info("Meal plan generated with \(plannedMeals.count) meals")

        return plan
    }

    func suggestTonightDinner(family: Family) async throws -> PlannedMeal {
        logger.info("Suggesting tonight's dinner")

        let recentMeals = loadRecentMeals(familyId: family.id, days: 7)

        // Get personalized suggestions
        let suggestions = engagement.suggestMeals(
            for: family,
            count: 5,
            recentMeals: recentMeals
        )

        // Score and select best
        let selected = suggestions.max { a, b in
            engagement.scoreRecipe(a.recipe) < engagement.scoreRecipe(b.recipe)
        } ?? suggestions[0]

        // Record selection
        engagement.recordMealFeedback(recipe: selected.recipe, rating: nil)
        engagement.recordInteraction(skill: .mealPlanning)

        return selected
    }

    // Add method to rate meals
    func rateMeal(recipeId: UUID, rating: Double) {
        logger.info("Recording meal rating: \(rating)")

        // This updates personalization
        // The recipe will be found from the ID in production
        // For now, we just record the rating
        engagement.recordMealFeedback(
            recipe: Recipe(id: recipeId),
            rating: rating
        )
    }

    // Helper methods
    private func loadRecentMeals(familyId: UUID, days: Int = 14) -> [PlannedMeal] {
        // Load from Core Data in production
        return []
    }

    private func generateGroceryList(from meals: [PlannedMeal]) -> GroceryList {
        // Existing implementation
        return GroceryList(items: [], estimatedTotal: 0)
    }

    private func calculateCost(_ list: GroceryList) -> Decimal {
        // Existing implementation
        return list.estimatedTotal
    }
}
```

## Step 3: Update MentalLoadSkill

Add engagement to briefings:

```swift
// File: Skills/MentalLoad/MentalLoadSkill.swift

import Foundation

final class MentalLoadSkill {
    private let logger = AppLogger.shared

    private var engagement: EngagementCoordinator {
        return AppState.shared.engagementCoordinator
    }

    func generateMorningBriefing(family: Family) async -> MorningBriefing {
        logger.info("Generating morning briefing")

        // Get personalized greeting
        let greeting = engagement.getPersonalizedGreeting(family: family)

        // Build briefing sections
        var sections: [BriefingSection] = []

        // Add greeting as first section
        sections.append(BriefingSection(
            title: "Good Morning",
            content: greeting,
            priority: .high
        ))

        // Check for new achievements
        if !engagement.newAchievements.isEmpty {
            let achievement = engagement.newAchievements[0]
            sections.append(BriefingSection(
                title: "Achievement Unlocked!",
                content: achievement.celebrationMessage,
                priority: .high
            ))
        }

        // Weather
        sections.append(BriefingSection(
            title: "Today's Weather",
            content: await getWeatherSummary(family: family),
            priority: .medium
        ))

        // Calendar events
        sections.append(BriefingSection(
            title: "Today's Schedule",
            content: await getCalendarSummary(family: family),
            priority: .high
        ))

        // Meal plan
        sections.append(BriefingSection(
            title: "Today's Meals",
            content: await getMealSummary(family: family),
            priority: .medium
        ))

        // Contextual tips
        let tips = engagement.getContextualTips(skill: .mentalLoad)
        if let tip = tips.first {
            sections.append(BriefingSection(
                title: "Tip of the Day",
                content: tip.message,
                priority: .low
            ))
        }

        // Cultural events
        let culturalEvents = engagement.getCulturalEvents()
        if let (event, recipes) = culturalEvents.first {
            sections.append(BriefingSection(
                title: "Upcoming Event",
                content: "🎉 \(event.name) on \(event.date.formatted(.dateTime.month().day()))\n\(event.description)",
                priority: .low
            ))
        }

        // New features
        if !engagement.newFeatures.isEmpty {
            let feature = engagement.newFeatures[0]
            sections.append(BriefingSection(
                title: "New Feature Available",
                content: "✨ \(feature.title)\n\(feature.description)",
                priority: .low
            ))
        }

        // Record interaction
        engagement.recordInteraction(skill: .mentalLoad)

        return MorningBriefing(
            date: Date(),
            familyId: family.id,
            sections: sections
        )
    }

    func formatBriefing(_ briefing: MorningBriefing) -> String {
        briefing.sections
            .sorted { $0.priority > $1.priority }
            .map { section in
                if section.title.isEmpty {
                    return section.content
                } else {
                    return "**\(section.title)**\n\(section.content)"
                }
            }
            .joined(separator: "\n\n")
    }

    // Helper methods
    private func getWeatherSummary(family: Family) async -> String {
        // Call WeatherAPI in production
        return "Sunny, 72°F - Perfect weather today!"
    }

    private func getCalendarSummary(family: Family) async -> String {
        // Call GoogleCalendarAPI in production
        return "3 events scheduled:\n• Team meeting at 9 AM\n• Lunch with client at 12 PM\n• Kids' soccer practice at 4 PM"
    }

    private func getMealSummary(family: Family) async -> String {
        // Get today's meals from meal plan
        return "🍳 Breakfast: Oatmeal\n🥗 Lunch: Caesar Salad\n🍽️ Dinner: Chicken Stir-Fry"
    }
}

struct BriefingSection {
    let title: String
    let content: String
    let priority: Priority
}

struct MorningBriefing {
    let date: Date
    let familyId: UUID
    let sections: [BriefingSection]
}
```

## Step 4: Update ChatViewModel

Integrate engagement into chat interactions:

```swift
// File: ViewModels/ChatViewModel.swift

import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false

    private let skillOrchestrator: SkillOrchestrator
    private let modelManager: ModelManager
    private let engagement: EngagementCoordinator
    private var family: Family?

    init(
        skillOrchestrator: SkillOrchestrator,
        modelManager: ModelManager,
        engagement: EngagementCoordinator,
        family: Family?
    ) {
        self.skillOrchestrator = skillOrchestrator
        self.modelManager = modelManager
        self.engagement = engagement
        self.family = family
    }

    func sendMessage(_ text: String) async {
        guard let family = family else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Learn from user's tone
        engagement.adaptToUserTone(message: text)

        // Show thinking message
        isProcessing = true
        let thinkingText = engagement.getThinkingMessage()
        let thinkingMessage = ChatMessage(role: .assistant, content: thinkingText)
        messages.append(thinkingMessage)

        // Process request
        let response = await skillOrchestrator.processRequest(
            text: text,
            family: family,
            chatHistory: messages
        )

        // Remove thinking message
        messages.removeLast()

        // Format response with personalization
        let formattedResponse = engagement.getVariedResponse(
            base: response.text,
            variants: []
        )

        // Add assistant response
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: formattedResponse,
            skill: response.skill,
            attachments: response.attachments
        )
        messages.append(assistantMessage)

        isProcessing = false

        // Remember context
        if response.confidence > 0.7 {
            engagement.rememberContext(
                topic: response.skill.rawValue,
                details: ["query": text, "action": response.action.rawValue]
            )
        }
    }
}
```

## Step 5: Create Achievement View

Add a view to display achievements:

```swift
// File: Views/Engagement/AchievementsView.swift

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Your Achievements")
                    .font(.largeTitle)
                    .bold()

                // Stats Summary
                statsSection

                // Earned Achievements
                earnedSection

                // In Progress
                inProgressSection
            }
            .padding()
        }
        .navigationTitle("Achievements")
    }

    private var statsSection: some View {
        let stats = appState.engagementCoordinator.getAchievementStats()

        return VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.headline)

            HStack {
                StatCard(
                    title: "Earned",
                    value: "\(stats.earnedAchievements)",
                    icon: "trophy.fill",
                    color: .yellow
                )

                StatCard(
                    title: "Total",
                    value: "\(stats.totalAchievements)",
                    icon: "star.fill",
                    color: .blue
                )

                StatCard(
                    title: "Completion",
                    value: "\(Int(stats.completionPercentage * 100))%",
                    icon: "chart.bar.fill",
                    color: .green
                )
            }
        }
    }

    private var earnedSection: some View {
        let earned = appState.engagementCoordinator.getEarnedAchievements()

        return VStack(alignment: .leading, spacing: 10) {
            Text("Unlocked (\(earned.count))")
                .font(.headline)

            ForEach(earned) { achievement in
                AchievementCard(achievement: achievement, isEarned: true)
            }
        }
    }

    private var inProgressSection: some View {
        let inProgress = appState.engagementCoordinator.getInProgressAchievements()

        return VStack(alignment: .leading, spacing: 10) {
            Text("In Progress (\(inProgress.count))")
                .font(.headline)

            ForEach(inProgress, id: \.achievement.id) { progress in
                AchievementProgressCard(progress: progress)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isEarned: Bool

    var body: some View {
        HStack {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(isEarned ? .yellow : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AchievementProgressCard: View {
    let progress: AchievementSystem.AchievementProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: progress.achievement.iconName)
                    .foregroundColor(.blue)

                Text(progress.achievement.title)
                    .font(.headline)

                Spacer()

                Text("\(progress.percentComplete)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress.progress)
                .tint(.blue)

            Text(progress.motivationalMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
```

## Step 6: Update Main Tab View

Add achievements to the tab bar:

```swift
// File: Views/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            // Existing tabs...

            // Add Achievements tab
            NavigationView {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "trophy")
            }
            .badge(appState.engagementCoordinator.newAchievements.count)
        }
    }
}
```

## Step 7: Add Engagement Dashboard

Create a dashboard showing engagement metrics:

```swift
// File: Views/Engagement/EngagementDashboard.swift

import SwiftUI

struct EngagementDashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting
                greetingSection

                // Quick Stats
                quickStatsSection

                // New Features
                if !appState.engagementCoordinator.newFeatures.isEmpty {
                    newFeaturesSection
                }

                // Recommendations
                recommendationsSection

                // Full Report Button
                Button(action: showFullReport) {
                    Text("View Full Report")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private var greetingSection: some View {
        Text(appState.engagementCoordinator.currentGreeting)
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
    }

    private var quickStatsSection: some View {
        let stats = appState.engagementCoordinator.engagementState.stats

        return VStack(alignment: .leading) {
            Text("Your Progress")
                .font(.headline)

            HStack {
                StatCard(
                    title: "Day Streak",
                    value: "\(stats.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )

                StatCard(
                    title: "Days Active",
                    value: "\(stats.daysSinceInstall)",
                    icon: "calendar",
                    color: .blue
                )
            }
        }
    }

    private var newFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New Features")
                .font(.headline)

            ForEach(appState.engagementCoordinator.newFeatures) { feature in
                FeatureCard(feature: feature)
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading) {
            Text("Personalized for You")
                .font(.headline)

            // Show personalized content based on preferences
            Text("Content coming soon...")
                .foregroundColor(.secondary)
        }
    }

    private func showFullReport() {
        let report = appState.engagementCoordinator.generateEngagementReport()
        print(report)
    }
}

struct FeatureCard: View {
    let feature: FeatureDiscovery

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(feature.title)
                        .font(.headline)

                    if feature.isNew {
                        Text("NEW")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
```

## Step 8: Testing

Test the integration:

```swift
// File: Tests/EngagementTests.swift

import XCTest
@testable import OpenClaw

class EngagementIntegrationTests: XCTestCase {
    var engagement: EngagementCoordinator!
    var family: Family!

    override func setUp() {
        super.setUp()
        engagement = EngagementCoordinator(userId: "test_user")
        family = createTestFamily()
    }

    func testAppLaunch() async {
        await engagement.handleAppLaunch(family: family)

        XCTAssertFalse(engagement.currentGreeting.isEmpty)
    }

    func testMealSuggestions() {
        let meals = engagement.suggestMeals(for: family, count: 3)

        XCTAssertEqual(meals.count, 3)
        XCTAssertTrue(meals.allSatisfy { $0.recipe.totalTime > 0 })
    }

    func testAchievements() {
        // Simulate 7 days of use
        engagement.engagementState.stats.daysSinceInstall = 7

        let earned = engagement.getEarnedAchievements()

        XCTAssertTrue(earned.contains { $0.title == "First Week Champion" })
    }

    private func createTestFamily() -> Family {
        Family(
            name: "Test Family",
            members: [
                FamilyMember(name: "Parent", role: .adult),
                FamilyMember(name: "Child", role: .child, birthYear: 2015)
            ],
            preferences: FamilyPreferences()
        )
    }
}
```

## Deployment Checklist

- [ ] Add EngagementCoordinator to AppState
- [ ] Update MealPlanningSkill with engagement features
- [ ] Update MentalLoadSkill with personalized briefings
- [ ] Update ChatViewModel with tone adaptation
- [ ] Add AchievementsView
- [ ] Add EngagementDashboardView
- [ ] Update MainTabView with new tabs
- [ ] Test all engagement features
- [ ] Monitor analytics for engagement metrics

## Next Steps

1. **Monitor Metrics**: Track how users interact with new features
2. **Iterate**: Adjust based on user feedback
3. **Expand**: Add more personalization rules
4. **Optimize**: Fine-tune algorithms based on data

The engagement system is now fully integrated and ready to keep users engaged for 7, 30, 100+ days!
