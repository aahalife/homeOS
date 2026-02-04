# Engagement Strategy Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      EngagementCoordinator                       │
│                    (Central Orchestration)                       │
│                                                                  │
│  • Manages user state                                           │
│  • Coordinates all 7 systems                                    │
│  • Handles app launch                                           │
│  • Provides unified API                                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ Orchestrates
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
         ▼                                   ▼
┌─────────────────┐                 ┌─────────────────┐
│  Content Layer  │                 │  Learning Layer │
└─────────────────┘                 └─────────────────┘
```

## Detailed Component Architecture

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    ENGAGEMENT COORDINATOR                     ┃
┃                  (Main Entry Point - 364 LOC)                 ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼

┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│  Content Rotation │  │ Natural Randomness│  │Progressive Discov.│
│   (308 LOC)       │  │   (352 LOC)       │  │   (348 LOC)       │
├───────────────────┤  ├───────────────────┤  ├───────────────────┤
│ • Weekly recipes  │  │ • 50+ greetings   │  │ • 18 features     │
│ • Seasonal themes │  │ • Top-N selection │  │ • Unlock timeline │
│ • Cultural events │  │ • Varied responses│  │ • Contextual tips │
│ • Trending        │  │ • Surprise delights│ │ • Onboarding      │
└───────────────────┘  └───────────────────┘  └───────────────────┘

┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│ Content Refresh   │  │ Personalization   │  │  Change Manager   │
│   (363 LOC)       │  │   (417 LOC)       │  │   (456 LOC)       │
├───────────────────┤  ├───────────────────┤  ├───────────────────┤
│ • Daily updates   │  │ • Preference learn│  │ • Change budget   │
│ • Weekly updates  │  │ • Recipe scoring  │  │ • Gradual rollout │
│ • Monthly reports │  │ • Tone adaptation │  │ • User opt-in     │
│ • Quarterly       │  │ • Context memory  │  │ • Experimental    │
└───────────────────┘  └───────────────────┘  └───────────────────┘

        ┌───────────────────────────┐
        │   Achievement System      │
        │      (471 LOC)            │
        ├───────────────────────────┤
        │ • 20+ achievements        │
        │ • Progress tracking       │
        │ • Celebrations            │
        │ • Statistics              │
        └───────────────────────────┘
```

## Data Flow

### 1. App Launch Flow

```
User Opens App
      │
      ▼
┌─────────────────┐
│   AppState      │
│  .initialize()  │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────┐
│ EngagementCoordinator            │
│  .handleAppLaunch(family)        │
└────────┬─────────────────────────┘
         │
         ├─► Update greeting
         ├─► Update usage stats
         ├─► Check achievements ──────► 🏆 New achievement!
         ├─► Check feature unlocks ───► ✨ New feature!
         ├─► Daily content refresh ───► 🌤️ Weather, 📅 Events
         └─► Weekly content refresh ──► 🍽️ New recipes
```

### 2. Meal Suggestion Flow

```
User Requests Meal Plan
      │
      ▼
┌─────────────────────────┐
│  MealPlanningSkill      │
│  .generateWeeklyPlan()  │
└────────┬────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ EngagementCoordinator                    │
│  .suggestMeals(family, count, recent)    │
└────┬─────────────────────────────────────┘
     │
     ├─► ContentRotationEngine
     │   │ • Get weekly new recipes (2-3)
     │   │ • Get seasonal suggestions
     │   └─► Returns: [Recipe]
     │
     ├─► PersonalizationEngine
     │   │ • Score each recipe
     │   │ • Based on learned preferences
     │   └─► Returns: Scores
     │
     ├─► NaturalRandomness
     │   │ • Select from top candidates
     │   │ • Ensure variety (no repeats)
     │   └─► Returns: Selected meals
     │
     └─► Record interaction
         └─► Update stats, check achievements
```

### 3. Learning Flow

```
User Rates Meal (4.5 stars)
      │
      ▼
┌────────────────────────────────┐
│ EngagementCoordinator          │
│  .recordMealFeedback()         │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ PersonalizationEngine          │
│  .recordMealSelection()        │
│  .recordMealRating()           │
└────────┬───────────────────────┘
         │
         ├─► Update cuisine preferences
         ├─► Update protein preferences
         ├─► Update cook time preferences
         └─► Store rating

Future Suggestions
      │
      ▼
┌────────────────────────────────┐
│ PersonalizationEngine          │
│  .scoreRecipe(recipe)          │
└────────┬───────────────────────┘
         │
         └─► Higher scores for:
             • Same cuisine (Italian: 1.8x)
             • Same protein (Chicken: 1.3x)
             • Similar cook time (1.2x)
             • High rating (4.5/5 = 1.35x)

             Total Score: 1.0 × 1.8 × 1.3 × 1.2 × 1.35 = 3.79
             (Much more likely to be suggested!)
```

### 4. Feature Unlock Flow

```
User Active for 7 Days
      │
      ▼
┌────────────────────────────────┐
│ EngagementCoordinator          │
│  .handleAppLaunch()            │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ ProgressiveDiscovery           │
│  .checkForNewUnlocks()         │
└────────┬───────────────────────┘
         │
         ├─► Check unlock criteria
         │   • daysSinceInstall >= 7? ✓
         │   • skillUsageCount >= X?
         │   • milestone achieved?
         │
         ├─► Return unlocked features:
         │   • Smart Recipe Filtering
         │   • Homework Tracking
         │
         └─► Update state
             └─► Show "New Feature" badge
```

### 5. Achievement Flow

```
User Uses App 7 Days in a Row
      │
      ▼
┌────────────────────────────────┐
│ EngagementCoordinator          │
│  .recordInteraction()          │
└────────┬───────────────────────┘
         │
         ├─► Update stats.currentStreak = 7
         │
         ▼
┌────────────────────────────────┐
│ AchievementSystem              │
│  .checkForNewAchievements()    │
└────────┬───────────────────────┘
         │
         ├─► Check all achievements
         │   • "Week Warrior": streak(7) ✓
         │   • "First Week Champion": daysActive(7) ✓
         │
         ├─► Return earned achievements
         │
         └─► Celebrate!
             └─► "🔥 7 days in a row! You're on fire!"
```

## State Management

```
┌──────────────────────────────────────────────────────────┐
│                    EngagementState                        │
├──────────────────────────────────────────────────────────┤
│  userId: String                                          │
│  installDate: Date                                       │
│  stats: UserStats ────────────────────────────┐          │
│  preferences: UserPreferences ─────────┐      │          │
│  unlockedFeatures: [UUID]              │      │          │
│  earnedAchievements: [UUID]            │      │          │
│  contentRotationWeek: Int              │      │          │
│  changeBudget: ChangeBudget            │      │          │
└────────────────────────────────────────┼──────┼──────────┘
                                         │      │
         ┌───────────────────────────────┘      │
         │                                      │
         ▼                                      ▼
┌─────────────────────────┐    ┌──────────────────────────────┐
│     UserStats           │    │    UserPreferences           │
├─────────────────────────┤    ├──────────────────────────────┤
│ • daysSinceInstall      │    │ • favoriteCuisines           │
│ • currentStreak         │    │ • favoriteProteins           │
│ • longestStreak         │    │ • preferredCookTimes         │
│ • totalInteractions     │    │ • mealSuccessRatings         │
│ • skillUsageCounts      │    │ • optimalReminderTimes       │
│ • achievedMilestones    │    │ • briefingReadPatterns       │
│ • lastActiveDate        │    │ • conversationTone           │
└─────────────────────────┘    └──────────────────────────────┘
```

## Integration Architecture

```
┌────────────────────────────────────────────────────────────┐
│                        AppState                            │
│                                                            │
│  • modelManager: ModelManager                              │
│  • skillOrchestrator: SkillOrchestrator                    │
│  • engagementCoordinator: EngagementCoordinator  ◄─── NEW  │
│  • currentFamily: Family?                                  │
└────────────────┬───────────────────────────────────────────┘
                 │
                 │ Provides to
                 │
                 ▼
┌────────────────────────────────────────────────────────────┐
│                    SkillOrchestrator                       │
│                                                            │
│  • mealPlanning: MealPlanningSkill ──┐                    │
│  • healthcare: HealthcareSkill       │                    │
│  • education: EducationSkill         │ Uses               │
│  • mentalLoad: MentalLoadSkill ──────┼───────┐            │
│  • ... other skills                  │       │            │
└──────────────────────────────────────┼───────┼────────────┘
                                       │       │
                                       │       │
                                       ▼       ▼
                         ┌───────────────────────────────────┐
                         │   EngagementCoordinator           │
                         │                                   │
                         │  • suggestMeals()                 │
                         │  • recordInteraction()            │
                         │  • getPersonalizedGreeting()      │
                         │  • getVariedResponse()            │
                         └───────────────────────────────────┘
```

## File Dependencies

```
EngagementModels.swift (Foundation)
         │
         │ Used by all systems
         │
         ├─► ContentRotationEngine.swift
         ├─► NaturalRandomness.swift
         ├─► ProgressiveDiscovery.swift
         ├─► ContentRefreshManager.swift
         ├─► PersonalizationEngine.swift
         ├─► ChangeManager.swift
         └─► AchievementSystem.swift
                  │
                  │ All orchestrated by
                  │
                  ▼
         EngagementCoordinator.swift
                  │
                  │ Used in
                  │
                  ├─► AppState.swift
                  ├─► MealPlanningSkill.swift
                  ├─► MentalLoadSkill.swift
                  ├─► ChatViewModel.swift
                  └─► Views (SwiftUI)
```

## System Interactions Example

### Scenario: User Opens App on Day 30

```
1. AppState.initialize()
   └─► EngagementCoordinator.handleAppLaunch(family)

2. Update Greeting
   └─► NaturalRandomness.getGreeting()
       ├─► Check time: 9 AM = morning
       └─► Return: "Good morning! Ready to plan an amazing day?"

3. Update Stats
   ├─► stats.daysSinceInstall = 30
   ├─► stats.totalInteractions += 1
   └─► updateStreak()
       └─► stats.currentStreak = 15

4. Check Achievements
   └─► AchievementSystem.checkForNewAchievements(stats)
       ├─► daysActive(30)? YES! ✓
       └─► Return: ["Monthly Milestone"]
           └─► Show: "🌟 30 days! You're a family management pro!"

5. Check Features
   └─► ProgressiveDiscovery.checkForNewUnlocks(stats, unlocked)
       ├─► daysSinceInstall >= 30? YES! ✓
       └─► Return: ["Seasonal Recipes", "Chore Assignments"]
           └─► Show: "✨ New features unlocked!"

6. Daily Content Refresh
   └─► ContentRefreshManager.performScheduledRefresh(family)
       ├─► Weather: "Sunny, 72°F"
       ├─► Calendar: "3 events today"
       └─► News: "2 relevant stories"

7. Weekly Content Refresh (if Monday)
   └─► ContentRotationEngine.getWeeklyNewRecipes(week: 5)
       └─► Return: ["Thai Basil Chicken", "Butternut Squash Soup"]

8. Result: User sees fresh, personalized content!
```

## Performance Characteristics

| System | Time Complexity | Space Complexity | Notes |
|--------|----------------|------------------|-------|
| ContentRotationEngine | O(n) | O(1) | n = recipe pool size |
| NaturalRandomness | O(n log n) | O(n) | Sorting for top-N |
| ProgressiveDiscovery | O(n) | O(1) | n = feature count |
| ContentRefreshManager | O(1) | O(1) | Cached results |
| PersonalizationEngine | O(n) | O(n) | n = preferences |
| ChangeManager | O(n) | O(n) | n = change history |
| AchievementSystem | O(n) | O(1) | n = achievement count |

All systems are designed for real-time performance with minimal overhead.

## Thread Safety

```
@MainActor
final class EngagementCoordinator: ObservableObject {
    // All UI updates happen on main thread
    @Published var newAchievements: [Achievement]
    @Published var newFeatures: [FeatureDiscovery]

    // Async operations properly handled
    func handleAppLaunch(family: Family) async {
        // Network calls, file I/O
    }
}
```

## Persistence Strategy

```
UserDefaults
    ├─► user_id: String
    ├─► onboarding_complete: Bool
    └─► active_skills: [String]

Core Data
    ├─► Family
    ├─► MealPlan
    ├─► PlannedMeal
    └─► Recipe

EngagementState (Future: Core Data)
    ├─► UserStats
    ├─► UserPreferences
    ├─► UnlockedFeatures
    └─► EarnedAchievements
```

## Testing Architecture

```
Unit Tests
    ├─► ContentRotationEngineTests
    ├─► NaturalRandomnessTests
    ├─► ProgressiveDiscoveryTests
    ├─► PersonalizationEngineTests
    ├─► ChangeManagerTests
    └─► AchievementSystemTests

Integration Tests
    ├─► EngagementCoordinatorTests
    ├─► SkillIntegrationTests
    └─► EndToEndFlowTests

UI Tests
    ├─► AchievementViewTests
    ├─► DashboardViewTests
    └─► OnboardingFlowTests
```

---

This architecture ensures:
- ✅ Separation of concerns
- ✅ Testability
- ✅ Maintainability
- ✅ Performance
- ✅ Scalability
- ✅ Thread safety
- ✅ Clean integration
