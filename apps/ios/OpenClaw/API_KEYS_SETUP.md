# API Keys Configuration for OpenClaw

OpenClaw integrates with several third-party APIs to provide full functionality. This guide explains where and how to configure API keys.

## Overview

OpenClaw stores API keys securely in the iOS Keychain (not in UserDefaults or plist files). Keys are never committed to version control.

## Required API Keys by Feature

### 1. Meal Planning
**Spoonacular API** (Required for meal planning)
- **Purpose**: Recipe search, meal planning, nutrition data
- **Get Key**: https://spoonacular.com/food-api
- **Free Tier**: 150 requests/day
- **Cost**: $0 for testing, paid plans start at $19/month

**USDA FoodData Central API** (Optional, enhances nutrition data)
- **Purpose**: Detailed nutritional information
- **Get Key**: https://fdc.nal.usda.gov/api-key-signup.html
- **Free Tier**: Unlimited
- **Cost**: Free

### 2. Home Maintenance
**Google Places API** (Required for contractor search)
- **Purpose**: Search for plumbers, electricians, contractors
- **Get Key**: https://console.cloud.google.com/apis/credentials
- **Free Tier**: $200/month credit
- **Cost**: $0.032 per Text Search request

**Yelp Fusion API** (Optional, alternative contractor search)
- **Purpose**: Business search with ratings
- **Get Key**: https://www.yelp.com/developers/v3/manage_app
- **Free Tier**: 500 calls/day
- **Cost**: Free

**Weather API (OpenWeatherMap)** (Optional)
- **Purpose**: Weather context for maintenance
- **Get Key**: https://openweathermap.org/api
- **Free Tier**: 1000 calls/day
- **Cost**: Free tier available

### 3. Elder Care (Voice/SMS)
**Twilio** (Required for voice check-ins)
- **Purpose**: Voice calls and SMS for elder check-ins
- **Get Keys**: https://console.twilio.com/
  - Account SID
  - Auth Token
  - Phone Number (purchase required)
- **Free Tier**: Trial credit
- **Cost**: ~$1/month for phone number + per-minute/SMS charges

### 4. Education
**Google Classroom API** (Required for homework tracking)
- **Purpose**: Fetch assignments and grades
- **Get Key**: Google Cloud Console OAuth 2.0 credentials
- **Setup**: https://console.cloud.google.com/apis/credentials
- **Free Tier**: Yes
- **Cost**: Free

**Google Calendar API** (Required for calendar sync)
- **Purpose**: Sync family calendar events
- **Setup**: Same as Google Classroom
- **Free Tier**: Yes
- **Cost**: Free

## How to Configure API Keys

### Option 1: Through the App UI (Recommended)

1. Launch OpenClaw app
2. Complete onboarding
3. Go to **Settings** tab (gear icon)
4. Scroll to **API Keys** section
5. Enter your API keys in the secure fields:
   - Spoonacular API Key
   - USDA FoodData Key
   - Google Places API Key
6. Scroll to **Twilio (Voice/SMS)** section (if using Elder Care)
   - Enter Account SID
   - Enter Auth Token
   - Enter Phone Number (format: +1234567890)
7. Tap **Save API Keys**

The keys are encrypted and stored in iOS Keychain.

### Option 2: Programmatic Configuration (For Development)

Edit `SettingsViewModel.swift` to load keys from environment or config file:

```swift
// In SettingsViewModel.swift
init() {
    // Load from environment (for testing)
    if let spoonacularKey = ProcessInfo.processInfo.environment["SPOONACULAR_API_KEY"] {
        self.spoonacularKey = spoonacularKey
        saveKeys()
    }
}
```

Or create a development-only config file (add to `.gitignore`):

```swift
// Create: OpenClaw/Config/DevAPIKeys.swift (add to .gitignore!)
#if DEBUG
struct DevAPIKeys {
    static let spoonacular = "YOUR_DEV_KEY_HERE"
    static let usda = "YOUR_DEV_KEY_HERE"
    static let googlePlaces = "YOUR_DEV_KEY_HERE"
}
#endif
```

## Accessing API Keys in Code

The app uses `KeychainManager` to securely retrieve keys:

```swift
// In any API client
let keychainManager = KeychainManager()

// Get a key
if let apiKey = keychainManager.getAPIKey(for: KeychainManager.APIKeys.spoonacular) {
    // Use the key
} else {
    // Key not configured, show error or use stub data
}
```

### API Key Constants

Available in `KeychainManager.APIKeys`:
- `spoonacular`
- `usda`
- `googleClientId`
- `twilioAccountSid`
- `twilioAuthToken`
- `twilioPhoneNumber`
- `yelp`
- `googlePlaces`
- `weatherApi`

## Security Best Practices

### ✅ DO:
- Store keys in iOS Keychain (already implemented)
- Use environment variables for CI/CD
- Rotate keys regularly
- Use different keys for development/production
- Monitor API usage in provider dashboards

### ❌ DON'T:
- Hard-code keys in source files
- Commit keys to Git
- Share keys in screenshots or logs
- Use production keys in development builds

## Environment Variables for Development

For Xcode scheme configuration:

1. Open Xcode
2. Product → Scheme → Edit Scheme
3. Run → Arguments → Environment Variables
4. Add:
   ```
   SPOONACULAR_API_KEY = your_key_here
   USDA_API_KEY = your_key_here
   GOOGLE_PLACES_API_KEY = your_key_here
   ```

## Fallback to Stub Data

If API keys are not configured, the app automatically falls back to stub data:

- **Meal Planning**: Uses `StubData.sampleRecipes`
- **Weather**: Returns mock weather data
- **Contractor Search**: Returns sample contractors
- **Elder Care**: Simulates check-ins (no actual calls)

This allows full app functionality during development without requiring all API keys.

## API Usage Monitoring

### Recommended Tools:
1. **Spoonacular Dashboard**: Track usage and limits
2. **Google Cloud Console**: Monitor API quotas and costs
3. **Twilio Console**: View call/SMS logs and billing
4. **Yelp Developer Portal**: Check request counts

### Cost Estimation (Monthly)

**Minimal Setup** (Meal Planning only):
- Spoonacular Free Tier: $0
- Total: **$0/month**

**Full Featured** (All APIs):
- Spoonacular: $0-19/month
- Google Places: $0-10/month
- Twilio: $1-5/month (phone + usage)
- Others: Free
- Total: **$1-34/month**

## Troubleshooting

### "API key not configured" error
→ Go to Settings and enter the required API key

### "Invalid API key" error
→ Verify the key is correct in your provider dashboard

### "Rate limit exceeded"
→ You've hit the free tier limit. Wait or upgrade plan.

### Keys not persisting
→ Check iOS Keychain permissions. Try deleting and re-entering.

### Simulator vs Device
→ Keychain is separate. You'll need to configure keys on each simulator and physical device.

## Testing Without API Keys

Run the app without any configuration:
1. The app will use stub/mock data
2. All features will work with sample data
3. Perfect for UI testing and development
4. No API calls are made

## Production Deployment

When distributing via TestFlight or App Store:

1. **Don't** bundle API keys in the app
2. **Do** require users to obtain their own keys
3. **Do** provide clear instructions in-app
4. **Consider** offering a backend service to proxy API calls (hides keys from client)

## Alternative: Backend Proxy (Advanced)

For production apps, consider a backend server that:
1. Stores API keys server-side
2. Client authenticates to your backend
3. Backend makes API calls on client's behalf
4. Hides third-party keys from mobile app

This is more secure but requires running a server.

## Quick Start (Get Going in 5 Minutes)

1. **Create Spoonacular account** → Get free API key
2. **Launch OpenClaw** → Complete onboarding
3. **Settings** → Enter Spoonacular key → Save
4. **Test**: Chat → "Plan dinners for this week"

Done! Other APIs are optional and can be added later.

---

**Note**: This project is for personal/educational use. Be mindful of API terms of service and usage limits.
