# OpenClaw Quick Reference

## Build Status
✅ **Project builds successfully without errors**
- Debug Build: ✅ Success
- Release Build: ✅ Success
- 56 Swift files compiled
- All types properly defined
- All protocol conformances valid

## QMD (Quick Search) Commands

```bash
# Search code
qmd search "query" -c openclaw -n 5

# Get file
qmd get openclaw/models/coremodels.swift

# Multi-file get
qmd multi-get "**/*Models.swift" -l 100

# Update index (after code changes)
qmd update

# Check status
qmd status
```

## API Keys Quick Setup

### Essential (Meal Planning)
1. Get Spoonacular key: https://spoonacular.com/food-api
2. Open OpenClaw → Settings → Enter key → Save

### Optional APIs
- **Google Places**: Contractor search
- **USDA FoodData**: Nutrition data
- **Twilio**: Elder care voice calls
- **Google Classroom/Calendar**: Education tracking

All stored securely in iOS Keychain.

## Project Structure

```
OpenClaw/
├── App/                    # AppState, main entry point
├── Models/                 # All data models
│   ├── CoreModels.swift   # Family, SkillType, Priority, etc.
│   ├── MealPlanningModels.swift
│   ├── HealthcareModels.swift
│   ├── EducationModels.swift
│   ├── ElderCareModels.swift
│   ├── FamilyCoordinationModels.swift
│   └── HomeMaintenanceModels.swift
├── Views/                  # All SwiftUI views
├── ViewModels/            # Chat, Settings, Onboarding
├── Skills/                # 7 skill implementations
├── AI/                    # ModelManager + stubs
├── Networking/            # API clients
├── Persistence/           # Core Data controller
├── Services/              # SkillOrchestrator
└── Utilities/             # Keychain, Logger, Extensions
```

## Key Types Reference

### Core Models
- `Family` - Family profile
- `FamilyMember` - Individual member
- `SkillType` - Enum of 7 skills
- `DietaryRestriction` - Dietary preferences
- `Priority` - Task priority levels
- `ChatMessage` - Chat interface messages

### App Infrastructure
- `AppState` - Central app state
- `PersistenceController` - Core Data manager
- `ModelManager` - AI model manager (stub mode)
- `SkillOrchestrator` - Routes requests to skills
- `KeychainManager` - Secure API key storage

## Development Commands

```bash
# Build for simulator
cd /Users/bharathsudharsan/homeOS/apps/ios/OpenClaw
xcodebuild -project OpenClaw.xcodeproj \
  -scheme OpenClaw \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Clean build
xcodebuild clean build

# Run on simulator (via xcodebuild)
xcodebuild -project OpenClaw.xcodeproj \
  -scheme OpenClaw \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ./build
```

## Files Modified

### Changes Made
1. **ChatViewModel.swift** (line 42-65)
   - Removed unreachable catch block
   - Simplified async call to SkillOrchestrator

## Testing Checklist

- [x] Builds without errors
- [x] All types defined
- [x] Protocol conformances valid
- [x] Imports correct
- [ ] Run on simulator (requires Xcode GUI)
- [ ] Test with API keys configured
- [ ] Test all 7 skills

## Common Tasks

### Add New API Key
1. Add constant in `KeychainManager.APIKeys`
2. Add field in `SettingsViewModel`
3. Add UI in `SettingsView`

### Add New Model
1. Create in `Models/` directory
2. Conform to `Codable`, `Identifiable`
3. Use in appropriate skill

### Update QMD Index
```bash
cd /Users/bharathsudharsan/homeOS/apps/ios/OpenClaw
qmd update
```

## Support Links

- **Documentation**: See `API_KEYS_SETUP.md` and `QMD_SETUP.md`
- **API Providers**: Listed in `API_KEYS_SETUP.md`
- **QMD GitHub**: https://github.com/tobi/qmd

## Next Steps

1. ✅ Project builds successfully
2. ⏭️ Configure API keys (optional, uses stubs otherwise)
3. ⏭️ Run on iOS Simulator via Xcode
4. ⏭️ Test onboarding flow
5. ⏭️ Test chat interactions
6. ⏭️ Configure real API integrations as needed

---

**All compilation errors resolved!** 🎉
