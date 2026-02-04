# OpenClaw

An AI-powered family operating system for iOS that helps manage the invisible workload of running a household. OpenClaw coordinates meal planning, healthcare, education, elder care, home maintenance, family scheduling, and mental load automation through a conversational interface.

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 5.10
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Getting Started

### 1. Generate Xcode Project

```bash
cd apps/ios/OpenClaw
xcodegen generate
```

### 2. Open in Xcode

```bash
open OpenClaw.xcodeproj
```

### 3. Build and Run

Select a simulator (iPhone 16 Pro recommended) and press **Cmd+R**.

### 4. Run Tests

```bash
xcodebuild test -scheme OpenClaw \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'
```

Or use **Cmd+U** in Xcode.

## Architecture

OpenClaw follows the **MVVM** pattern with a skill-based architecture:

```
OpenClaw/
├── App/                    # App entry point, AppState
├── Models/                 # Data models for all 7 skills
├── Views/                  # SwiftUI views
│   ├── Onboarding/         # 7-step onboarding flow
│   ├── Chat/               # Conversational interface
│   ├── Skills/             # Skill dashboard + detail views
│   ├── Settings/           # API keys, system status
│   └── CalendarView.swift
├── ViewModels/             # ChatViewModel, OnboardingViewModel, SettingsViewModel
├── Skills/                 # 7 skill implementations
│   ├── MealPlanning/
│   ├── Healthcare/
│   ├── Education/
│   ├── ElderCare/
│   ├── HomeMaintenance/
│   ├── FamilyCoordination/
│   └── MentalLoad/
├── Services/               # SkillOrchestrator (central router)
├── AI/                     # Intent classification + response generation
│   └── Stubs/              # Pattern-matching stubs (replaceable with on-device AI)
├── Networking/             # 8 API clients + rate limiting
│   └── APIs/
├── Persistence/            # Core Data controller
└── Utilities/              # Keychain, logging, network monitor, extensions
```

### Key Components

| Component | Purpose |
|-----------|---------|
| **SkillOrchestrator** | Routes user intents to the appropriate skill handler |
| **StubIntentClassifier** | Pattern-matching intent classification (stub for Gemma 3n) |
| **StubResponseGenerator** | Template-based response generation (stub for FunctionGemma) |
| **PersistenceController** | Core Data with programmatic model definition |
| **AppState** | Central state management via `@Observable` |

## Skills

| Skill | Description |
|-------|-------------|
| **Meal Planning** | Weekly plans, tonight's dinner, grocery lists, dietary filtering |
| **Healthcare** | Symptom triage (never diagnoses), medication tracking, provider search |
| **Education** | Assignment tracking, grade monitoring, study plan generation |
| **Elder Care** | Dignity-first check-ins, red flag detection, weekly reports |
| **Home Maintenance** | Emergency response (gas/fire/water), contractor search, schedules |
| **Family Coordination** | Calendar sync, chore assignment, broadcast messaging |
| **Mental Load** | Morning briefings, evening wind-downs, weekly planning |

## API Integrations

All APIs gracefully degrade to stub data when keys are not configured.

| API | Purpose | Auth Required |
|-----|---------|---------------|
| **Spoonacular** | Recipe search and nutritional data | API Key |
| **Google Calendar** | Family calendar sync | OAuth 2.0 |
| **Google Classroom** | Education assignment sync | OAuth 2.0 |
| **OpenFDA** | Medication validation and drug info | None (free) |
| **Twilio** | Elder care voice check-ins, SMS | Account SID + Auth Token |
| **Google Places** | Contractor and provider search | API Key |
| **USDA FoodData** | Nutritional information | API Key (DEMO_KEY available) |
| **wttr.in** | Weather data for briefings | None (free) |

### Configuring API Keys

API keys are stored securely in the iOS Keychain. Configure them in the app's **Settings > API Configuration** screen, or programmatically:

```swift
KeychainManager.shared.saveAPIKey("your-key", for: KeychainManager.APIKeys.spoonacular)
```

## Testing

The project includes 148 tests across 7 test suites:

| Suite | Tests | Coverage |
|-------|-------|----------|
| **OpenClawTests** | 19 | Core models, codable conformance, extensions |
| **IntentClassifierTests** | 29 | All 7 skills' intent patterns, entity extraction |
| **SkillTests** | 33 | Meal planning, healthcare safety, education, elder care, emergencies |
| **SimulationTests** | 10 | 3 family profiles, cross-family classification, safety compliance |
| **APITests** | 15 | Stub data quality, offline API behavior, rate limiting |
| **LiveAPITests** | 28 | Real HTTP calls to OpenFDA, wttr.in, USDA; end-to-end skill workflows |
| **RealWorldSimulationTests** | 14 | Family scenarios with live API data, performance benchmarks |

### Live API Testing

Tests hit real API endpoints to validate response parsing and data quality:

**No API key required (always run):**
- **OpenFDA** - Validates aspirin, tylenol, ibuprofen, metformin; adverse event queries; nonexistent drug handling
- **wttr.in** - Current weather for multiple US cities; 3-day forecasts; special character handling
- **USDA FoodData** - Food search with DEMO_KEY (rate-limited at 30 req/hour; tests gracefully skip when limited)

**API key required (graceful skip if missing):**
- **Spoonacular** - Recipe search with dietary filters; verifies stub fallback when key is absent

**End-to-end integration tests:**
- Morning briefing with real weather data from wttr.in
- Medication safety checks using live FDA adverse event reports
- Intent classification leading to real API calls
- Performance benchmarks (OpenFDA ~160ms, wttr.in ~180ms)

To run only the live API tests:
```bash
xcodebuild test -scheme OpenClaw \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:OpenClawTests/LiveAPITests
```

To run real-world simulations:
```bash
xcodebuild test -scheme OpenClaw \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:OpenClawTests/RealWorldSimulationTests
```

### Simulation Testing

Three synthetic family profiles test realistic scenarios:

- **Anderson Family** (2 adults, 2 children) - Dairy-free child, $150/week budget
- **Rodriguez Family** (1 adult with diabetes, 2 children) - $120/week budget
- **Chen Family** (2 adults, 1 child, 1 elder) - Sandwich generation, elder care enabled

### Safety Compliance

Healthcare and home emergency tests enforce critical safety rules:
- Emergency symptoms always recommend calling 911
- Healthcare responses never contain diagnostic language
- Gas leaks and fires always trigger EVACUATE responses

### Getting Full USDA Coverage

The DEMO_KEY is rate-limited to 30 requests/hour. For reliable USDA testing:

1. Sign up at https://fdc.nal.usda.gov/api-key-signup.html (free, instant)
2. Save the key in the app: `KeychainManager.shared.saveAPIKey("YOUR_KEY", for: KeychainManager.APIKeys.usda)`
3. This increases the limit to 3,600 requests/hour

### Getting Spoonacular Coverage

1. Sign up at https://spoonacular.com/food-api/console (free tier: 50 points/day)
2. Save the key: `KeychainManager.shared.saveAPIKey("YOUR_KEY", for: KeychainManager.APIKeys.spoonacular)`
3. Live tests will automatically activate when a key is detected

## AI Integration

The current implementation uses pattern-matching stubs. To integrate on-device AI:

1. Replace `StubIntentClassifier` with a Core ML model wrapping Gemma 3n
2. Replace `StubResponseGenerator` with FunctionGemma for natural responses
3. Both conform to the `IntentClassifier` and `ResponseGenerator` protocols

See `OpenClaw/AI/ModelManager.swift` for integration documentation.

## Onboarding

A 7-step onboarding flow collects family information:

1. **Welcome** - App introduction
2. **Family Info** - Add family members with roles (adult/child/elder)
3. **Dietary** - Dietary restrictions and allergies
4. **Health Info** - Health conditions and medications
5. **Education** - School information for children
6. **Home Info** - Location, home details, emergency shutoffs
7. **Skill Selection** - Enable/disable specific skills

## Privacy and Security

- All API keys stored in iOS Keychain (not UserDefaults)
- No data leaves the device without explicit user action
- Healthcare data handled with extra sensitivity
- Elder care follows dignity-first philosophy
- Location sharing is opt-in per family member

## License

Proprietary - All rights reserved.
