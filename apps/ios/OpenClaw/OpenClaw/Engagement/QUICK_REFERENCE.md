# Engagement Strategy - Quick Reference

## One-Liner Summary
Keep OpenClaw fresh and engaging on day 7, 30, 100+ through 7 interconnected systems.

## The 7 Systems

### 1. ContentRotationEngine
**Purpose:** Fresh recipe content
**Key Method:** `getWeeklyNewRecipes(week:familyPreferences:previousRecipes:)`
**Result:** 2-3 new recipes per week + seasonal + cultural events

```swift
let engine = ContentRotationEngine()
let newRecipes = engine.getWeeklyNewRecipes(week: 42, familyPreferences: prefs, previousRecipes: seen)
```

### 2. NaturalRandomness
**Purpose:** Varied responses
**Key Method:** `getGreeting()`, `selectFromTopCandidates()`
**Result:** 50+ greeting variations, top-N selection

```swift
let randomness = NaturalRandomness()
let greeting = randomness.getGreeting() // Time-appropriate
let selected = randomness.selectFromTopCandidates(candidates: meals, scoringFunction: score)
```

### 3. ProgressiveDiscovery
**Purpose:** Gradual feature unlocking
**Key Method:** `checkForNewUnlocks(userStats:currentUnlocked:)`
**Result:** 18 features unlocked over time (Day 1 → Day 100+)

```swift
let discovery = ProgressiveDiscovery()
let newFeatures = discovery.checkForNewUnlocks(userStats: stats, currentUnlocked: ids)
```

### 4. ContentRefreshManager
**Purpose:** Dynamic content updates
**Key Method:** `performScheduledRefresh(family:)`
**Result:** Daily/weekly/monthly/quarterly fresh content

```swift
let refresh = ContentRefreshManager()
let report = await refresh.performScheduledRefresh(family: family)
```

### 5. PersonalizationEngine
**Purpose:** Learn preferences
**Key Methods:** `recordMealSelection()`, `scoreRecipe()`, `adaptTone()`
**Result:** Increasingly personalized suggestions

```swift
let personalization = PersonalizationEngine()
personalization.recordMealSelection(recipe: recipe)
let score = personalization.scoreRecipe(recipe) // Higher = better match
```

### 6. ChangeManager
**Purpose:** Controlled change introduction
**Key Method:** `canIntroduceChange(type:priority:)`
**Result:** Max 1-2 changes per week, gradual rollout

```swift
let changeManager = ChangeManager()
if changeManager.canIntroduceChange(type: .newRecipe) {
    changeManager.recordChange(change)
}
```

### 7. AchievementSystem
**Purpose:** Milestone celebration
**Key Method:** `checkForNewAchievements(stats:)`
**Result:** 20+ achievements, non-intrusive celebrations

```swift
let achievements = AchievementSystem()
let earned = achievements.checkForNewAchievements(stats: userStats)
```

## Central Coordinator

**EngagementCoordinator** - Orchestrates all 7 systems

```swift
let engagement = EngagementCoordinator(userId: "user_123")

// On app launch
await engagement.handleAppLaunch(family: family)

// Get varied meal suggestions
let meals = engagement.suggestMeals(for: family, count: 3)

// Record interaction
engagement.recordInteraction(skill: .mealPlanning)

// Get personalized greeting
let greeting = engagement.getPersonalizedGreeting(family: family)
```

## Common Use Cases

### 1. Generate Meal Plan with Variety
```swift
let recentMeals = getRecentMeals(days: 7)
let suggestions = engagement.suggestMeals(for: family, count: 7, recentMeals: recentMeals)
```

### 2. Show Achievement
```swift
let earned = engagement.getEarnedAchievements()
let inProgress = engagement.getInProgressAchievements()
```

### 3. Personalized Response
```swift
let response = engagement.getVariedResponse(
    base: "Meal plan created!",
    variants: ["Your plan is ready!", "All set!"]
)
```

### 4. Check New Features
```swift
if !engagement.newFeatures.isEmpty {
    for feature in engagement.newFeatures {
        showNotification(feature.title)
    }
}
```

### 5. Record Feedback
```swift
engagement.recordMealFeedback(recipe: recipe, rating: 4.5)
```

## Key Metrics

```swift
let stats = engagement.engagementState.stats

// Usage
stats.daysSinceInstall // Total days
stats.currentStreak    // Consecutive days
stats.longestStreak    // Best streak

// Skills
stats.skillUsageCounts // [SkillType: Int]

// Achievements
let achievementStats = engagement.getAchievementStats()
```

## Timeline

| Days | Features Unlocked | Achievements Available |
|------|------------------|----------------------|
| 1    | 3 core features  | None                 |
| 7    | 6 total (+3)     | First Week Champion  |
| 30   | 9 total (+3)     | Monthly Milestone    |
| 100+ | 18 total (+9)    | 100 Day Club         |

## Feature Unlock Examples

- **Day 1:** Meal planning, health tracking, family calendar
- **Day 7:** Recipe filtering, homework tracking
- **Day 14:** Morning briefing
- **Day 30:** Seasonal recipes, chore assignments
- **Day 100:** Recipe ratings, custom templates

## Achievement Examples

- **Usage:** 7 days, 30 days, 100 days active
- **Consistency:** 7-day streak, 30-day streak, 60-day streak
- **Skill:** 10 meals planned, 25 meals, 50 meals
- **Family:** Perfect homework week, 7 days home-cooked meals

## Best Practices

1. **Always** use EngagementCoordinator for user-facing interactions
2. **Record** all interactions for learning
3. **Check** new features/achievements on app launch
4. **Vary** responses using getVariedResponse()
5. **Personalize** greetings and messages

## Integration Points

### AppState
```swift
let engagementCoordinator: EngagementCoordinator
await engagementCoordinator.handleAppLaunch(family: family)
```

### Skills
```swift
engagement.recordInteraction(skill: .mealPlanning)
let response = engagement.getSuccessMessage()
```

### Views
```swift
@EnvironmentObject var appState: AppState
let greeting = appState.engagementCoordinator.currentGreeting
```

## File Locations

All files in: `/OpenClaw/Engagement/`

**Core Systems:**
- EngagementModels.swift
- ContentRotationEngine.swift
- NaturalRandomness.swift
- ProgressiveDiscovery.swift
- ContentRefreshManager.swift
- PersonalizationEngine.swift
- ChangeManager.swift
- AchievementSystem.swift
- EngagementCoordinator.swift

**Documentation:**
- README.md (full documentation)
- IntegrationGuide.md (step-by-step)
- Examples.swift (code examples)
- IMPLEMENTATION_SUMMARY.md (overview)
- QUICK_REFERENCE.md (this file)

## Testing

```swift
// Test engagement
let coordinator = EngagementCoordinator(userId: "test")
coordinator.engagementState.stats.daysSinceInstall = 7
let achievements = coordinator.getEarnedAchievements()
XCTAssert(achievements.contains { $0.title == "First Week Champion" })
```

## Troubleshooting

**No new recipes?**
- Check `contentRotationWeek` is incrementing
- Verify `familyPreferences` has cuisines

**No achievements?**
- Ensure `userStats` is being updated
- Call `recordInteraction()` after each use

**Same greetings?**
- Using `getGreeting()` should auto-vary
- Try `getPersonalizedGreeting()` for more context

**No personalization?**
- Need to record interactions first
- Use `recordMealFeedback()` for ratings

## Performance

- All systems are lightweight (O(n) or better)
- In-memory caching for frequently accessed data
- Async/await for network operations
- Deterministic algorithms (no ML overhead)

## Next Steps

1. Read full README.md
2. Follow IntegrationGuide.md
3. Review Examples.swift
4. Implement in your app
5. Monitor engagement metrics

## Support

- Questions? Check README.md sections
- Integration issues? See IntegrationGuide.md
- Code patterns? Review Examples.swift

---

**Remember:** The goal is to keep the app fresh on day 7, 30, 100+ through smart content rotation, natural variation, progressive discovery, and personalized learning - all with deterministic logic!
