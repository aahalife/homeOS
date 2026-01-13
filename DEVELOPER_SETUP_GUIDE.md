# Developer Setup Guide for Oi My AI

## Purpose

This guide provides step-by-step instructions for developers to set up all external services, obtain API keys, purchase phone numbers, and configure the app backend. Following this guide ensures users can use all skills seamlessly without needing individual signups.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DEVELOPER-MANAGED SERVICES                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │ DEVELOPER BACKEND (Your Server)                                     │     │
│  │ ┌──────────────────────────────────────────────────────────────┐   │     │
│  │ │ services_config.json                                          │   │     │
│  │ │ ├── bland_ai: { api_key, webhook_secret }                     │   │     │
│  │ │ ├── taskrabbit: { client_id, client_secret }                  │   │     │
│  │ │ ├── nextdoor: { access_token }                                │   │     │
│  │ │ ├── firecrawl: { api_key }                                    │   │     │
│  │ │ ├── openweathermap: { api_key }                               │   │     │
│  │ │ ├── spoonacular: { api_key }                                  │   │     │
│  │ │ └── rube_composio: { api_key }                                │   │     │
│  │ └──────────────────────────────────────────────────────────────┘   │     │
│  │                                                                     │     │
│  │ ┌──────────────────────────────────────────────────────────────┐   │     │
│  │ │ phone_number_pool.json                                        │   │     │
│  │ │ ├── +14155551234: { status: "assigned", user: "user_abc" }    │   │     │
│  │ │ ├── +14155555678: { status: "available" }                     │   │     │
│  │ │ └── +14155559012: { status: "available" }                     │   │     │
│  │ └──────────────────────────────────────────────────────────────┘   │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                    ↓                                         │
│  USER'S OI MY AI APP                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │ • Fetches config from developer backend on launch                  │     │
│  │ • All API calls include user_id for isolation                      │     │
│  │ • Phone number assigned from pool on telephony activation          │     │
│  │ • User never sees/enters API keys                                  │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Services to Set Up

### Priority Levels

| Priority | Service | Required For | Monthly Cost Estimate |
|----------|---------|--------------|----------------------|
| **P0** | Bland.ai | Telephony skill | $15/number + usage |
| **P0** | OpenWeatherMap | Weather in all skills | Free tier / $40/mo |
| **P0** | Firecrawl | Web scraping, Plan to Eat | $19/mo starter |
| **P1** | TaskRabbit | Hire Helper skill | Free (transaction fees) |
| **P1** | Nextdoor | Local helper search | Free (developer account) |
| **P1** | Spoonacular | Recipe discovery | Free tier / $29/mo |
| **P1** | Rube (Composio) | 500+ integrations | Varies |
| **P2** | Exa | AI-powered search | $100/mo starter |
| **P2** | Pushover | Push notifications | $5 one-time per platform |

---

## Step-by-Step Setup

### 1. Bland.ai (Voice Telephony)

**Website:** https://app.bland.ai

**Steps:**
1. Create account at https://app.bland.ai/signup
2. Navigate to Settings → API Keys
3. Click "Create API Key" → Copy the key
4. Navigate to Settings → Billing → Add payment method
5. Purchase phone numbers:

**Purchase Numbers via Dashboard:**
- Go to Phone Numbers → Purchase
- Select area code (e.g., 415 for San Francisco)
- Purchase 10-20 numbers initially ($15/mo each)

**Purchase Numbers via API:**
```bash
curl -X POST "https://api.bland.ai/v1/inbound/purchase" \
  -H "Authorization: Bearer {YOUR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "area_code": "415",
    "country_code": "US"
  }'
```

**Configure Webhooks:**
- Go to Settings → Webhooks
- Add endpoint: `https://api.oimyai.app/webhooks/bland/inbound`
- Add endpoint: `https://api.oimyai.app/webhooks/bland/call-complete`
- Copy Webhook Secret for verification

**Store in Config:**
```json
{
  "services": {
    "bland_ai": {
      "api_key": "sk-bland-xxxxxxxxxxxxxxxx",
      "webhook_secret": "whsec_xxxxxxxxxxxxxxxx",
      "default_voice": "maya",
      "default_model": "enhanced"
    }
  }
}
```

**Monthly Cost:** ~$150-300 for 10-20 numbers + usage ($0.09/min)

---

### 2. OpenWeatherMap (Weather Data)

**Website:** https://openweathermap.org/api

**Steps:**
1. Create account at https://home.openweathermap.org/users/sign_up
2. Go to API Keys section
3. Generate new key (name it "oimyai-production")
4. Wait 10 minutes for activation

**Store in Config:**
```json
{
  "services": {
    "openweathermap": {
      "api_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "units": "imperial",
      "lang": "en"
    }
  }
}
```

**Monthly Cost:** Free tier (1000 calls/day) or $40/mo for higher limits

---

### 3. Firecrawl (Web Scraping)

**Website:** https://firecrawl.dev

**Steps:**
1. Sign up at https://firecrawl.dev/signup
2. Go to Dashboard → API Keys
3. Create new key
4. Note your plan limits

**Store in Config:**
```json
{
  "services": {
    "firecrawl": {
      "api_key": "fc-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Monthly Cost:** $19/mo (Starter) or $99/mo (Standard)

---

### 4. TaskRabbit (Home Services)

**Website:** https://developer.taskrabbit.com

**Steps:**
1. Apply for API access at https://developer.taskrabbit.com/docs/overview
2. Complete business verification (may take 1-2 weeks)
3. Once approved, get OAuth credentials:
   - Client ID
   - Client Secret
4. Register redirect URI: `https://api.oimyai.app/oauth/taskrabbit/callback`

**Store in Config:**
```json
{
  "services": {
    "taskrabbit": {
      "client_id": "tr_xxxxxxxxxxxxxxxx",
      "client_secret": "tr_secret_xxxxxxxxxxxxxxxx",
      "redirect_uri": "https://api.oimyai.app/oauth/taskrabbit/callback",
      "sandbox": false
    }
  }
}
```

**OAuth Flow for Users:**
```
1. User clicks "Connect TaskRabbit" in app
2. App opens: https://api.taskrabbit.com/oauth/authorize?client_id={ID}&redirect_uri={URI}&scope=tasks:write
3. User authorizes
4. TaskRabbit redirects to your callback with auth code
5. Exchange code for access_token
6. Store token per user: { user_id: "abc", taskrabbit_token: "..." }
```

**Monthly Cost:** Free (TaskRabbit charges users per task)

---

### 5. Nextdoor (Local Community)

**Website:** https://developer.nextdoor.com

**Steps:**
1. Apply for API access at https://developer.nextdoor.com
2. Complete developer agreement
3. Once approved, get:
   - OAuth Client ID
   - Client Secret
4. Note: Search Posts API is primary endpoint needed

**Store in Config:**
```json
{
  "services": {
    "nextdoor": {
      "client_id": "nd_xxxxxxxxxxxxxxxx",
      "client_secret": "nd_secret_xxxxxxxxxxxxxxxx",
      "redirect_uri": "https://api.oimyai.app/oauth/nextdoor/callback"
    }
  }
}
```

**Monthly Cost:** Free (developer tier)

---

### 6. Spoonacular (Recipes)

**Website:** https://spoonacular.com/food-api

**Steps:**
1. Sign up at https://spoonacular.com/food-api/console
2. Get API key from dashboard
3. Select plan based on needs

**Store in Config:**
```json
{
  "services": {
    "spoonacular": {
      "api_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Monthly Cost:** Free (150 requests/day) or $29/mo (1500 requests/day)

---

### 7. Rube/Composio (Universal MCP)

**Website:** https://composio.dev / https://rube.app

**Steps:**
1. Sign up at https://app.composio.dev
2. Navigate to API Keys
3. Generate production key
4. Configure connected apps (Google, etc.)

**Store in Config:**
```json
{
  "services": {
    "rube_composio": {
      "api_key": "comp_xxxxxxxxxxxxxxxx",
      "connected_apps": ["google_calendar", "gmail", "yelp", "spotify"]
    }
  }
}
```

**Monthly Cost:** Varies by plan

---

### 8. Exa (AI Search)

**Website:** https://exa.ai

**Steps:**
1. Sign up at https://exa.ai
2. Get API key from dashboard
3. Configure search preferences

**Store in Config:**
```json
{
  "services": {
    "exa": {
      "api_key": "exa-xxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Monthly Cost:** $100/mo (Starter)

---

### 9. Pushover (Push Notifications)

**Website:** https://pushover.net

**Steps:**
1. Create account at https://pushover.net
2. Register application: "Oi My AI"
3. Get Application Token
4. Users install Pushover app and get User Key

**Store in Config:**
```json
{
  "services": {
    "pushover": {
      "app_token": "axxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  }
}
```

**Monthly Cost:** $5 one-time per platform (iOS/Android)

---

## Phone Number Pool Management

### Initial Setup

Create `phone_number_pool.json`:

```json
{
  "provider": "bland_ai",
  "numbers": [
    {
      "phoneNumber": "+14155551234",
      "areaCode": "415",
      "status": "available",
      "assignedTo": null,
      "assignedAt": null,
      "monthlyRenewal": "2026-02-10"
    },
    {
      "phoneNumber": "+14155555678",
      "areaCode": "415",
      "status": "available",
      "assignedTo": null,
      "assignedAt": null,
      "monthlyRenewal": "2026-02-10"
    }
  ],
  "config": {
    "maxNumbersPerUser": 1,
    "autoReleaseAfterDays": 90,
    "lowPoolThreshold": 5
  }
}
```

### Assignment Logic

```javascript
// When user activates telephony
async function assignPhoneNumber(userId) {
  // 1. Check if user already has a number
  const existing = pool.numbers.find(n => n.assignedTo === userId);
  if (existing) return existing.phoneNumber;

  // 2. Find available number
  const available = pool.numbers.find(n => n.status === "available");
  if (!available) {
    // Alert developer: need more numbers
    await notifyLowPool();
    throw new Error("No numbers available");
  }

  // 3. Assign to user
  available.status = "assigned";
  available.assignedTo = userId;
  available.assignedAt = new Date().toISOString();

  // 4. Configure inbound webhook for this number
  await blandApi.configureInbound(available.phoneNumber, {
    webhook: `https://api.oimyai.app/webhooks/bland/inbound`,
    metadata: { userId }
  });

  return available.phoneNumber;
}
```

---

## Backend Configuration File

### Complete `services_config.json`

```json
{
  "version": "1.0.0",
  "environment": "production",

  "services": {
    "bland_ai": {
      "api_key": "sk-bland-xxxxxxxxxxxxxxxx",
      "webhook_secret": "whsec_xxxxxxxxxxxxxxxx",
      "default_voice": "maya",
      "default_model": "enhanced",
      "max_call_duration_minutes": 10,
      "webhook_endpoints": {
        "inbound": "/webhooks/bland/inbound",
        "call_complete": "/webhooks/bland/call-complete"
      }
    },

    "openweathermap": {
      "api_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "units": "imperial",
      "cache_ttl_minutes": 30
    },

    "firecrawl": {
      "api_key": "fc-xxxxxxxxxxxxxxxx",
      "rate_limit_per_minute": 20
    },

    "taskrabbit": {
      "client_id": "tr_xxxxxxxxxxxxxxxx",
      "client_secret": "tr_secret_xxxxxxxxxxxxxxxx",
      "redirect_uri": "https://api.oimyai.app/oauth/taskrabbit/callback",
      "sandbox": false
    },

    "nextdoor": {
      "client_id": "nd_xxxxxxxxxxxxxxxx",
      "client_secret": "nd_secret_xxxxxxxxxxxxxxxx",
      "redirect_uri": "https://api.oimyai.app/oauth/nextdoor/callback"
    },

    "spoonacular": {
      "api_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "cache_ttl_hours": 24
    },

    "rube_composio": {
      "api_key": "comp_xxxxxxxxxxxxxxxx",
      "connected_apps": ["google_calendar", "gmail", "yelp", "spotify", "instacart"]
    },

    "exa": {
      "api_key": "exa-xxxxxxxxxxxxxxxx",
      "default_num_results": 10
    },

    "pushover": {
      "app_token": "axxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  },

  "user_isolation": {
    "require_user_id": true,
    "user_id_header": "X-User-ID",
    "user_id_body_field": "request_data.user_id"
  },

  "rate_limits": {
    "global": {
      "requests_per_minute": 1000
    },
    "per_user": {
      "requests_per_minute": 60,
      "calls_per_day": 10,
      "messages_per_day": 100
    }
  }
}
```

---

## App Configuration

### Where to Store Keys in the App

**NEVER embed keys directly in the app binary.**

**Option 1: Backend API (Recommended)**
```swift
// App fetches config from your backend
let config = try await api.fetchServiceConfig()
// Keys stay on your server, app gets temporary tokens
```

**Option 2: Keychain with Backend Provisioning**
```swift
// On first launch, app requests config from backend
// Backend returns encrypted config
// App stores in Keychain
let keychain = Keychain(service: "com.fantasticapp.oimyai")
keychain["services_config"] = encryptedConfig
```

### Dev Mode Configuration

In the app, add a hidden Developer Mode (accessed via ⌥⌘D or clicking version 7 times):

```swift
struct DeveloperSettings: View {
    @State private var blandApiKey = ""
    @State private var testPhoneNumber = ""

    var body: some View {
        Form {
            Section("Bland.ai") {
                SecureField("API Key", text: $blandApiKey)
                Button("Test Connection") { testBlandConnection() }
            }

            Section("Phone Numbers") {
                Text("Assigned: \(assignedNumber ?? "None")")
                Button("Request Number") { requestNumber() }
            }

            Section("Service Status") {
                ForEach(services) { service in
                    HStack {
                        Text(service.name)
                        Spacer()
                        Circle()
                            .fill(service.connected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
}
```

---

## User Isolation Implementation

### Every API Request Must Include User ID

```swift
struct APIClient {
    let userId: String

    func makeRequest(to endpoint: String, body: [String: Any]) async throws {
        var headers = [
            "Authorization": "Bearer \(config.apiKey)",
            "X-User-ID": userId,
            "X-Request-ID": UUID().uuidString
        ]

        var requestBody = body
        requestBody["request_data"] = [
            "user_id": userId,
            "app_version": appVersion,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        // Make request...
    }
}
```

### Webhook User Identification

```javascript
// In your webhook handler
app.post('/webhooks/bland/call-complete', async (req, res) => {
  const { call_id, transcript, request_data } = req.body;

  // CRITICAL: Extract user_id from request_data
  const userId = request_data?.user_id;
  if (!userId) {
    console.error('Missing user_id in webhook payload');
    return res.status(400).send('Missing user_id');
  }

  // Verify this phone number belongs to this user
  const assignment = await db.phoneAssignments.find({ userId });
  if (!assignment) {
    console.error('User not found for call');
    return res.status(400).send('Invalid user');
  }

  // Route to correct user
  await notifyUser(userId, {
    type: 'call_complete',
    transcript,
    summary: extractSummary(transcript)
  });

  res.sendStatus(200);
});
```

---

## Monitoring & Alerts

### Set Up Monitoring For:

1. **Phone Number Pool**
   - Alert when available numbers < 5
   - Auto-purchase trigger at threshold

2. **API Usage**
   - Daily usage reports per service
   - Alert at 80% of quota

3. **Webhook Health**
   - Monitor webhook response times
   - Alert on failures

4. **User Activity**
   - Unusual usage patterns
   - Failed authentication attempts

### Example Alert Configuration

```json
{
  "alerts": {
    "low_phone_pool": {
      "threshold": 5,
      "channels": ["email", "slack"],
      "message": "Phone number pool low: {available} numbers remaining"
    },
    "api_quota_warning": {
      "threshold_percent": 80,
      "services": ["firecrawl", "spoonacular"],
      "channels": ["email"]
    },
    "webhook_failure": {
      "consecutive_failures": 3,
      "channels": ["pagerduty"]
    }
  }
}
```

---

## Cost Summary

### Monthly Estimates (10 Users)

| Service | Cost |
|---------|------|
| Bland.ai (10 numbers + usage) | $150 + ~$50 usage |
| OpenWeatherMap | Free tier |
| Firecrawl | $19 |
| TaskRabbit | Free |
| Nextdoor | Free |
| Spoonacular | Free tier |
| Exa | $100 (optional) |
| **Total** | **~$320/mo** |

### Per-User Cost Model

If charging users, consider:
- Base: $10/mo (covers infrastructure)
- With telephony: +$15/mo (phone number)
- With premium integrations: +$5/mo

---

## Security Checklist

- [ ] All API keys stored in environment variables or secret manager
- [ ] Webhook endpoints validate signatures
- [ ] User IDs included in all API requests
- [ ] Phone numbers never exposed to unauthorized users
- [ ] Rate limiting implemented per user
- [ ] OAuth tokens stored encrypted
- [ ] Audit logs for all sensitive operations
- [ ] Regular key rotation schedule (quarterly)

---

## Troubleshooting

### Common Issues

**Bland.ai calls not working:**
1. Check API key is valid
2. Verify webhook URLs are accessible
3. Check phone number is active
4. Review call logs in Bland dashboard

**Nextdoor API returning empty:**
1. Posts older than 7 days are not returned
2. Verify lat/lon coordinates are correct
3. Check OAuth token is not expired

**TaskRabbit authentication failing:**
1. Verify redirect_uri matches exactly
2. Check OAuth scopes are correct
3. Ensure not using sandbox credentials in production

---

## Document Version

- **Created:** 2026-01-13
- **Author:** Development Team
- **Status:** Ready for implementation
