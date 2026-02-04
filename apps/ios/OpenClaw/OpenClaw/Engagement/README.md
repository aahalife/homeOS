# OpenClaw Engagement Strategy

A comprehensive system to keep the app feeling fresh and engaging on day 7, day 30, day 100+, even with deterministic logic.

## Overview

The Engagement Strategy consists of seven interconnected systems that work together to create a personalized, evolving experience:

1. **ContentRotationEngine** - Fresh recipes and seasonal content
2. **NaturalRandomness** - Controlled variation in responses
3. **ProgressiveDiscovery** - Gradual feature unlocking
4. **ContentRefreshManager** - Dynamic content updates
5. **PersonalizationEngine** - Learning user preferences
6. **ChangeManager** - Balanced change introduction
7. **AchievementSystem** - Milestone celebration

All systems are coordinated by `EngagementCoordinator` which integrates them seamlessly with existing skills.

## Quick Start

### Integration with AppState

```swift
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // ... existing properties ...

    let engagementCoordinator: EngagementCoordinator

    init() {
        // ... existing initialization ...
        self.engagementCoordinator = EngagementCoordinator(userId: "user_123")
    }

    func initialize() async {
        // ... existing initialization ...

        // Initialize engagement system
        if let family = currentFamily {
            await engagementCoordinator.handleAppLaunch(family: family)
        }
    }
}
```

### Using in Skills

```swift
// In MealPlanningSkill.swift
func generateWeeklyPlan(family: Family) async throws -> MealPlan {
    // Get engagement coordinator from app state
    let engagement = AppState.shared.engagementCoordinator

    // Get varied meal suggestions
    let meals = engagement.suggestMeals(
        for: family,
        count: 7,
        recentMeals: getRecentMeals()
    )

    // Record interaction
    engagement.recordInteraction(skill: .mealPlanning)

    // Get varied success message
    let successMessage = engagement.getSuccessMessage()

    return MealPlan(meals: meals)
}
```

## System Details

### 1. Content Rotation Engine

Keeps meal planning fresh with rotating recipes and seasonal awareness.

**Features:**
- 2-3 new recipes per week from different cuisines
- Seasonal ingredient suggestions (spring/summer/fall/winter)
- Cultural event recipes (Thanksgiving, Diwali, Lunar New Year, etc.)
- Monthly trending recipes
- Recipe ratings feedback loop (4+ stars promoted)

**Example Usage:**
```swift
let engine = ContentRotationEngine()

// Get weekly new recipes
let newRecipes = engine.getWeeklyNewRecipes(
    week: 42,
    familyPreferences: family.preferences,
    previousRecipes: alreadySeen
)

// Get seasonal suggestions
let seasonal = engine.getSeasonalSuggestions(
    season: .fall,
    familyPreferences: family.preferences
)

// Get cultural event recipes
let culturalEvents = engine.getCulturalEventSuggestions(daysAhead: 14)
for (event, recipes) in culturalEvents {
    print("\(event.name): \(recipes.count) recipes")
}

// Get trending recipes
let trending = engine.getTrendingRecipes(
    month: 10,
    userRatings: ratingsMap
)
```

**Seasonal Themes:**
- **Spring**: Fresh vegetables, herbs, light salads
- **Summer**: BBQ, cold soups, fresh fruits
- **Fall**: Hearty stews, pumpkin, comfort foods
- **Winter**: Warm soups, slow-cooked meals, citrus

### 2. Natural Randomness

Adds controlled variation to keep interactions feeling natural.

**Features:**
- 50+ greeting variations
- Top-N selection (picks from top 3-5, not always #1)
- Varied success messages and confirmations
- Surprise delights (random positive reinforcement)
- Meal variety algorithms

**Example Usage:**
```swift
let randomness = NaturalRandomness()

// Get time-appropriate greeting
let greeting = randomness.getGreeting() // Auto-detects time
// Returns: "Good morning! Ready to plan an amazing day?"
//      or: "Morning! Let's make today great."
//      or: "Rise and shine! What's on the agenda today?"

// Get success message
let success = randomness.getSuccessMessage()
// Returns: "Great job! You're crushing it!"
//      or: "Excellent! You're on a roll!"

// Select from top candidates with natural variation
let selectedMeal = randomness.selectFromTopCandidates(
    candidates: allMeals,
    scoringFunction: { meal in scoreRecipe(meal.recipe) },
    topCount: 5,
    randomness: 0.3 // 30% randomness factor
)

// Check for surprise delights
if randomness.shouldShowSurpriseDelight(
    lastShown: lastDelightDate,
    frequency: .weekly,
    randomChance: 0.1
) {
    if let delight = randomness.getSurpriseDelight(stats: userStats) {
        print(delight)
        // "🌟 Wow! You've been using OpenClaw for 7 days straight!"
    }
}
```

**Greeting Types:**
- Morning (5 AM - 12 PM): 10 variations
- Afternoon (12 PM - 5 PM): 10 variations
- Evening (5 PM - 5 AM): 10 variations
- Success messages: 10+ variations
- Encouragements: 10+ variations

### 3. Progressive Discovery

Gradually unlocks features to avoid overwhelming new users.

**Features:**
- Week 1: Core features only
- Week 2-4: Intermediate features
- Month 2+: Advanced features
- 100+ days: Power user features
- Contextual tips based on usage

**Example Usage:**
```swift
let discovery = ProgressiveDiscovery()

// Check for new unlocks
let newFeatures = discovery.checkForNewUnlocks(
    userStats: userStats,
    currentUnlocked: unlockedFeatureIds
)

for feature in newFeatures {
    print(discovery.createFeatureAnnouncement(feature: feature))
    // "🍽️ New Feature Unlocked!
    //  **Smart Recipe Filtering**
    //  Recipes automatically filtered by dietary restrictions"
}

// Get unlocked features
let unlocked = discovery.getUnlockedFeatures(userStats: userStats)

// Get upcoming features preview
let upcoming = discovery.getUpcomingFeatures(userStats: userStats, limit: 3)
for feature in upcoming {
    print("\(feature.title): \(feature.description)")
}

// Get contextual tips
let tips = discovery.getContextualTips(
    userStats: userStats,
    currentSkill: .mealPlanning,
    previouslyShownTips: shownTips
)
```

**Feature Unlock Timeline:**
- **Day 1**: Meal planning, health tracking, family calendar
- **Day 7**: Recipe filtering, homework tracking
- **Day 10**: Elder care check-ins
- **Day 14**: Morning briefing
- **Day 21**: Provider search
- **Day 30**: Seasonal recipes, chore assignments
- **Day 45**: Home maintenance planner
- **Day 60**: Weekly family reports
- **Day 100+**: Recipe ratings, custom templates, advanced alerts

### 4. Content Refresh Manager

Keeps content current with regular updates from various sources.

**Features:**
- Daily: Weather, calendar events, news
- Weekly: New recipes, seasonal tips, family insights
- Monthly: Usage reports, achievements, trending recipes
- Quarterly: New features, system improvements

**Example Usage:**
```swift
let refreshManager = ContentRefreshManager()

// Perform scheduled refresh
let report = await refreshManager.performScheduledRefresh(family: family)
print(report.summary)
// "Refresh Complete
//  - Items updated: 12
//  - Weather updated: sunny, 72°F
//  - Today's events: 3
//  - New recipes: 2"

// Refresh specific content type
let weatherUpdate = await refreshManager.refreshContent(
    type: .weather,
    family: family
)
print(weatherUpdate) // "sunny, 72°F"
```

**Refresh Schedule:**
- **Daily** (every morning):
  - Current weather conditions
  - Today's calendar events
  - Relevant news headlines

- **Weekly** (Monday mornings):
  - 2-3 new recipes
  - Seasonal cooking tips
  - Family usage insights
  - Upcoming cultural events

- **Monthly** (1st of month):
  - Usage report summary
  - Achievement summary
  - Trending recipes rotation
  - Health tips

- **Quarterly** (Jan/Apr/Jul/Oct):
  - New skill features
  - System improvements
  - Seasonal planning

### 5. Personalization Engine

Learns user preferences over time for increasingly relevant suggestions.

**Features:**
- Meal preference learning (cuisines, proteins, cook times)
- Adaptive reminder timing
- Briefing content customization
- Conversation context memory
- Tone adaptation (formal/friendly/casual/concise)

**Example Usage:**
```swift
let personalization = PersonalizationEngine()

// Record meal selection
personalization.recordMealSelection(recipe: selectedRecipe)

// Record rating
personalization.recordMealRating(recipeId: recipe.id, rating: 4.5)

// Get preferred cuisines
let favorites = personalization.getPreferredCuisines(limit: 5)
// Returns: ["Italian", "Mexican", "Thai", "Japanese", "Indian"]

// Score recipe based on learned preferences
let score = personalization.scoreRecipe(recipe)
// Higher score = better match to user preferences

// Adapt to user's tone
personalization.adaptTone(userMessage: "Hey, can you help me find a quick dinner?")
// Learns casual tone preference

// Format response according to learned tone
let response = personalization.formatResponse("I will help you with that")
// Casual tone: "I'll help you with that"
// Formal tone: "I will help you with that"
// Concise tone: "Helping"

// Remember conversation context
personalization.rememberContext(
    topic: "dinner preferences",
    details: ["time": "quick", "type": "dinner", "cuisine": "italian"]
)

// Retrieve context later
let context = personalization.getRelevantContext(topic: "dinner")
```

**Learning Capabilities:**
- **Cuisines**: Tracks frequency of selection
- **Proteins**: Chicken, beef, seafood, vegetarian preferences
- **Cook Times**: Learns average preferred cooking duration
- **Ratings**: Uses 4+ star recipes more frequently
- **Reminder Timing**: Learns when user typically responds
- **Briefing Sections**: Only shows sections user reads
- **Conversation Tone**: Adapts formality based on user language

### 6. Change Manager

Prevents overwhelming users with too many changes at once.

**Features:**
- Change budget: Max 1-2 changes per week
- Change categories: Content, functionality, interface, algorithm
- User opt-in for experimental features
- Gradual feature rollout
- Respect "don't change this" preferences

**Example Usage:**
```swift
let changeManager = ChangeManager()

// Check if can introduce change
if changeManager.canIntroduceChange(type: .newRecipe, priority: .medium) {
    // Introduce new recipe
    let change = ChangeEvent(
        type: .newRecipe,
        title: "New Fall Recipes",
        description: "Try pumpkin and squash dishes",
        scheduledDate: Date(),
        isOptional: true,
        category: .content
    )

    changeManager.recordChange(change)
}

// Propose changes for the week
let proposed = changeManager.proposeChanges(
    availableChanges: allPossibleChanges,
    userStats: userStats
)

// Announce change to user
let announcement = changeManager.announceChange(proposed[0])
print(announcement.formattedMessage)

// User can opt out of change types
changeManager.optOutOfChangeType(.uiUpdate)

// User can lock specific features
changeManager.lockFeature(featureId, reason: "I like it as is")

// Check experimental features
if changeManager.hasOptedIntoExperimental() {
    let experimental = changeManager.getExperimentalFeatures()
    // Show beta features
}
```

**Change Budget:**
- Default: 1-2 changes per week
- New users (<14 days): More conservative
- Power users (100+ days): Can handle more changes
- Categories balanced: One content + one feature change max

**Gradual Rollout:**
```swift
// Roll out feature to 10% → 100% over 14 days
let percentage = changeManager.getCurrentRolloutPercentage(
    startDate: featureStartDate,
    fullRolloutDays: 14
)

if changeManager.shouldReceiveGradualFeature(
    featureId: "smart_predictions",
    rolloutPercentage: percentage,
    userStats: userStats
) {
    // Show feature to this user
}
```

### 7. Achievement System

Celebrates milestones without being intrusive or annoying.

**Features:**
- Usage milestones (7, 30, 100 days)
- Consistency achievements (7, 30, 60-day streaks)
- Skill-specific achievements (10, 25, 50 uses)
- Family achievements (perfect homework week, etc.)
- Non-intrusive celebrations

**Example Usage:**
```swift
let achievements = AchievementSystem()

// Check for new achievements
let earned = achievements.checkForNewAchievements(stats: userStats)

for achievement in earned {
    // Create celebration
    let celebration = achievements.celebrateAchievement(achievement)

    print(achievement.celebrationMessage)
    // "🎉 You've made it through your first week! You're building great habits!"

    // Show celebration UI (5 seconds, confetti style)
    showCelebration(celebration)
}

// Get earned achievements
let allEarned = achievements.getEarnedAchievements()

// Get achievements in progress
let inProgress = achievements.getInProgressAchievements(
    stats: userStats,
    threshold: 0.7 // Show if ≥70% complete
)

for progress in inProgress {
    print("\(progress.achievement.title): \(progress.percentComplete)%")
    print(progress.motivationalMessage)
    // "Great progress! 3 more days to go!"
}

// Get statistics
let stats = achievements.getStatistics()
print(stats.summary)
// "Achievement Progress:
//  - Earned: 8/20 (40%)
//  - Usage: 2
//  - Consistency: 1
//  - Skill: 3
//  - Family: 2"
```

**Achievement Categories:**

**Usage Milestones:**
- First Week Champion (7 days)
- Monthly Milestone (30 days)
- 100 Day Club (100 days)

**Consistency:**
- Week Warrior (7-day streak)
- Consistency King (30-day streak)
- Unstoppable (60-day streak)

**Skill-Specific:**
- Meal Planner (10 meals)
- Chef's Choice (25 meals)
- Culinary Expert (50 meals)
- Health Conscious (10 health items)
- Homework Helper (20 assignments)

**Family:**
- Perfect Week (all homework done)
- Health Heroes (no missed medications)
- Meal Success (7 days home-cooked)

## Integration Examples

### Example 1: Morning Briefing with Engagement

```swift
func generateMorningBriefing(family: Family) async -> String {
    let engagement = AppState.shared.engagementCoordinator

    // Get personalized greeting
    let greeting = engagement.getPersonalizedGreeting(family: family)

    // Check for new achievements
    let newAchievements = engagement.newAchievements

    // Get contextual tips
    let tips = engagement.getContextualTips(skill: .mentalLoad)

    // Get fresh content
    let culturalEvents = engagement.getCulturalEvents()

    var briefing = greeting + "\n\n"

    // Add achievement celebration
    if let achievement = newAchievements.first {
        briefing += "\(achievement.celebrationMessage)\n\n"
    }

    // Add standard briefing content
    briefing += "**Today's Schedule:**\n"
    briefing += getScheduleSummary()

    // Add cultural event if relevant
    if let (event, _) = culturalEvents.first {
        briefing += "\n\n🎉 **Upcoming:** \(event.name) on \(event.date.formatted())"
    }

    // Add tip if available
    if let tip = tips.first {
        briefing += "\n\n\(tip.message)"
    }

    return briefing
}
```

### Example 2: Recipe Suggestion with Personalization

```swift
func suggestTonightDinner(family: Family) async throws -> PlannedMeal {
    let engagement = AppState.shared.engagementCoordinator

    // Get recent meals to avoid repetition
    let recentMeals = getRecentMeals(days: 7)

    // Get varied suggestions
    let suggestions = engagement.suggestMeals(
        for: family,
        count: 3,
        recentMeals: recentMeals
    )

    // Select best match
    let selected = suggestions.max { a, b in
        engagement.scoreRecipe(a.recipe) < engagement.scoreRecipe(b.recipe)
    } ?? suggestions[0]

    // Record interaction
    engagement.recordInteraction(skill: .mealPlanning)

    return selected
}
```

### Example 3: Feature Unlock Notification

```swift
func checkAndAnnounceNewFeatures() {
    let engagement = AppState.shared.engagementCoordinator

    if !engagement.newFeatures.isEmpty {
        for feature in engagement.newFeatures {
            // Show non-intrusive notification
            showNotification(
                title: "New Feature Unlocked!",
                message: feature.title,
                badge: "NEW"
            )
        }
    }
}
```

## Best Practices

### 1. Don't Overwhelm Users
- Stick to 1-2 changes per week maximum
- Progressive feature unlocking over days/weeks
- Respect user's "don't change" preferences

### 2. Learn and Adapt
- Track meal ratings and preferences
- Adjust reminder timing based on response patterns
- Customize briefing based on what user reads

### 3. Celebrate Without Annoying
- Brief celebrations (5 seconds max)
- No blocking modals for achievements
- Can be dismissed easily

### 4. Maintain Context
- Remember conversation topics
- Use context in future interactions
- Build on previous preferences

### 5. Stay Fresh
- Rotate content weekly
- Introduce seasonal variations
- Update trending content monthly

## Testing

### Test Engagement Flow

```swift
// Test new user experience
func testNewUserEngagement() {
    let coordinator = EngagementCoordinator(userId: "test_user")

    // Day 1: Should see core features only
    let day1Features = coordinator.getAvailableFeatures()
    XCTAssertEqual(day1Features.count, 3) // Basic only

    // Simulate 7 days
    coordinator.engagementState.stats.daysSinceInstall = 7

    // Day 7: Should unlock more features
    let day7Features = coordinator.getAvailableFeatures()
    XCTAssert(day7Features.count > 3)

    // Check for achievements
    let achievements = coordinator.getEarnedAchievements()
    XCTAssert(achievements.contains { $0.title == "First Week Champion" })
}

// Test personalization
func testPersonalization() {
    let engine = PersonalizationEngine()

    // Record preferences
    let italianRecipe = Recipe(cuisine: "Italian", ...)
    engine.recordMealSelection(recipe: italianRecipe)
    engine.recordMealRating(recipeId: italianRecipe.id, rating: 5.0)

    // Check learned preferences
    let favorites = engine.getPreferredCuisines()
    XCTAssertEqual(favorites.first, "Italian")

    // Score similar recipe
    let anotherItalian = Recipe(cuisine: "Italian", ...)
    let score = engine.scoreRecipe(anotherItalian)
    XCTAssert(score > 1.0) // Should be boosted
}
```

## Analytics & Monitoring

Track key engagement metrics:

```swift
// Track in EngagementCoordinator
struct EngagementMetrics {
    var dailyActiveUsers: Int
    var averageStreak: Double
    var featureAdoptionRate: [String: Double]
    var achievementEarnRate: [String: Int]
    var personalizedContentScore: Double
}
```

## Future Enhancements

1. **Machine Learning Integration**
   - Use actual ML models for recipe recommendations
   - Predict optimal timing for features/tips
   - Personalized achievement difficulty

2. **Social Features**
   - Family leaderboards (opt-in)
   - Share achievements
   - Recipe recommendations from similar families

3. **Advanced Personalization**
   - Voice tone adaptation
   - Emoji usage preferences
   - Response length preferences

4. **A/B Testing Framework**
   - Test different engagement strategies
   - Measure impact on retention
   - Optimize change frequency

## Support

For questions or issues:
- Check existing code examples
- Review test cases
- See integration examples above

## License

Part of the OpenClaw project.
