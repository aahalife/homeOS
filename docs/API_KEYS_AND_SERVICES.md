# API Keys & External Services Guide

## Overview

HomeOS skills connect to various external services to automate household management — from making phone calls and booking restaurants to syncing calendars and monitoring home devices. This document catalogs **every external API key, token, and service credential** required (or optionally used) across the entire skills system.

Some services are essential for core functionality (P0); others enhance the experience but aren't required for launch. Each entry includes what it's used for, how to obtain credentials, what to configure, and estimated cost.

> **Design Principle:** HomeOS runs its primary LLM (Gemma 3n) on-device with no API key required. External services are integrated only when they provide capabilities that can't be replicated locally.

---

## Required Services (Core Functionality)

---

### 1. Telephony / Voice — Twilio

| Field | Value |
|-------|-------|
| **Service** | [Twilio](https://www.twilio.com) — Voice + SMS |
| **Priority** | **P0** — Must have for launch |
| **Used by** | `telephony`, `elder-care` (check-in calls), `restaurant-reservation` (phone bookings), `hire-helper` (calling agencies), `healthcare` (pharmacy calls) |
| **Cost** | Pay-as-you-go: ~$1.15/mo per phone number, $0.0085/min voice, $0.0079/SMS. Free trial gives ~$15 credit. |

**What you need:**
- **Account SID** — identifies your Twilio account
- **Auth Token** — authenticates API requests
- **Phone Number** — the number HomeOS calls/texts from

**How to get it:**
1. Sign up at [twilio.com/try-twilio](https://www.twilio.com/try-twilio)
2. Verify your email and phone number
3. From the Console Dashboard, copy your **Account SID** and **Auth Token**
4. Go to **Phone Numbers → Manage → Buy a Number**
5. Purchase a number with Voice + SMS capabilities
6. Under **Phone Numbers → Active Numbers**, configure the Voice webhook URL to your HomeOS gateway endpoint: `https://<your-gateway>/telephony/inbound`
7. (Optional) Deploy a Twilio Function for voicemail transcription fallback

**Config keys:**
```
twilio.accountSid
twilio.authToken
twilio.phoneNumber
```

---

### 2. Calendars

#### 2a. Google Calendar (OAuth 2.0)

| Field | Value |
|-------|-------|
| **Service** | [Google Calendar API](https://developers.google.com/calendar) |
| **Priority** | **P0** — Must have for launch |
| **Used by** | `tools` (calendar CRUD), `school` (event sync), `mental-load` (morning briefings), `family-comms` (family calendar), `transportation` (departure alerts), `elder-care` (appointment tracking) |
| **Cost** | Free (Google Cloud free tier covers typical household usage) |

**How to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (e.g., "HomeOS")
3. Enable the **Google Calendar API** under APIs & Services → Library
4. Go to **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**
5. Set application type to "iOS" or "Web application" depending on your deployment
6. Add authorized redirect URIs for your gateway
7. Copy the **Client ID** and **Client Secret**
8. Configure the OAuth consent screen (scopes: `calendar.readonly`, `calendar.events`)

**Config keys:**
```
google.calendarClientId
google.calendarClientSecret
google.calendarRedirectUri
```

#### 2b. Apple iCloud Calendar (CalDAV)

| Field | Value |
|-------|-------|
| **Service** | Apple CalDAV |
| **Priority** | **P1** — Important for Apple-centric families |
| **Used by** | `tools`, `mental-load`, `school` |
| **Cost** | Free |

**How to get it:**
1. User generates an **App-Specific Password** at [appleid.apple.com](https://appleid.apple.com)
2. Go to **Sign-In & Security → App-Specific Passwords → Generate**
3. Store the password securely (entered via in-app secure form during onboarding)
4. CalDAV endpoint: `https://caldav.icloud.com`

**Config keys:**
```
apple.caldavUsername       # user's Apple ID email
apple.caldavAppPassword   # app-specific password
```

#### 2c. Microsoft Outlook / 365 (MS Graph)

| Field | Value |
|-------|-------|
| **Service** | [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/) |
| **Priority** | **P1** — Important for Outlook users |
| **Used by** | `tools`, `mental-load` |
| **Cost** | Free |

**How to get it:**
1. Go to [Azure Portal → App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps)
2. Register a new multi-tenant application
3. Add **Calendars.ReadWrite** under API Permissions → Microsoft Graph
4. Configure redirect URIs
5. Copy **Application (client) ID** and create a **Client Secret**

**Config keys:**
```
microsoft.graphClientId
microsoft.graphClientSecret
microsoft.graphRedirectUri
```

---

### 3. Email

#### 3a. Gmail (OAuth 2.0 — shared with Google Calendar)

| Field | Value |
|-------|-------|
| **Service** | [Gmail API](https://developers.google.com/gmail/api) |
| **Priority** | **P1** — Important |
| **Used by** | `school` (parsing school forms), `mental-load` (daily digest), integrations (bill detection, travel itinerary) |
| **Cost** | Free |

**How to get it:**
Uses the same Google Cloud project as Calendar. Add scopes:
- `gmail.readonly`
- `gmail.compose`
- `gmail.metadata`

**Config keys:** Same as Google Calendar OAuth credentials — just add email scopes.

#### 3b. Microsoft Outlook Email (Graph API — shared with Calendar)

Uses the same Azure app registration. Add **Mail.ReadWrite** permission.

---

### 4. Maps / Location — Google Maps Platform

| Field | Value |
|-------|-------|
| **Service** | [Google Maps Platform](https://developers.google.com/maps) — Maps, Places, Directions, Geocoding |
| **Priority** | **P0** — Must have for launch |
| **Used by** | `restaurant-reservation` (search, reviews, photos), `transportation` (routes, ETA, traffic), `tools` (event locations), `mental-load` (commute times), `family-bonding` (local venues) |
| **Cost** | $200/month free credit (covers ~28,000 direction requests or ~40,000 geocodes). Pay-as-you-go after. |

**How to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable these APIs: **Maps JavaScript**, **Places**, **Directions**, **Geocoding**
3. Go to **APIs & Services → Credentials → Create Credentials → API Key**
4. Restrict the key to the APIs above and your app's bundle ID / IP
5. Enable billing (required, but $200/mo credit covers household use)

**Config keys:**
```
google.mapsApiKey
```

**Alternative:** Apple MapKit (free on iOS, no API key — uses device entitlements). Suitable for on-device map rendering but lacks the Places search richness of Google.

---

### 5. Push Notifications — Apple Push Notification Service (APNs)

| Field | Value |
|-------|-------|
| **Service** | [APNs](https://developer.apple.com/documentation/usernotifications) |
| **Priority** | **P0** — Must have for launch |
| **Used by** | All skills that send alerts: `family-comms` (announcements), `elder-care` (alerts), `healthcare` (medication reminders), `tools` (reminders), `school` (deadline alerts), `transportation` (departure alerts), `home-maintenance` (emergency alerts) |
| **Cost** | Free (included with Apple Developer Program, $99/year) |

**How to get it:**
1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Go to **Certificates, Identifiers & Profiles → Keys**
3. Create a new key with **Apple Push Notifications service (APNs)** enabled
4. Download the `.p8` key file — **store it securely, you can only download once**
5. Note the **Key ID** and your **Team ID**

**Config keys:**
```
apns.keyId
apns.teamId
apns.keyFilePath          # path to .p8 file
apns.bundleId             # your app's bundle identifier
apns.environment          # "development" or "production"
```

---

### 6. Search — Web Search API

| Field | Value |
|-------|-------|
| **Service** | [Brave Search API](https://brave.com/search/api/) or [Google Custom Search](https://developers.google.com/custom-search) |
| **Priority** | **P0** — Must have for launch |
| **Used by** | `restaurant-reservation` (finding restaurants), `marketplace-sell` (pricing research), `hire-helper` (finding providers), `home-maintenance` (finding contractors), `transportation` (parking), `family-bonding` (local events), `psy-rich` (activity research) |
| **Cost** | Brave: Free tier = 2,000 queries/month, then $3/1,000. Google: Free tier = 100 queries/day, then $5/1,000. |

**How to get it (Brave — recommended):**
1. Go to [brave.com/search/api](https://brave.com/search/api/)
2. Sign up and create an API key
3. Free plan covers most household usage

**How to get it (Google Custom Search):**
1. Go to [Programmable Search Engine](https://programmablesearchengine.google.com/)
2. Create a search engine (select "Search the entire web")
3. Get your **Search Engine ID** and **API Key** from Google Cloud Console

**Config keys:**
```
search.provider            # "brave" or "google"
search.braveApiKey
# OR
search.googleApiKey
search.googleSearchEngineId
```

---

### 7. Home Automation

#### 7a. Home Assistant

| Field | Value |
|-------|-------|
| **Service** | [Home Assistant](https://www.home-assistant.io/) |
| **Priority** | **P1** — Important for smart home users |
| **Used by** | `home-maintenance` (device monitoring), `wellness` (environment control), `elder-care` (safety sensors), integrations (scenes, automations) |
| **Cost** | Free (self-hosted) or $6.50/month (Home Assistant Cloud / Nabu Casa) |

**How to get it:**
1. Install Home Assistant on a Raspberry Pi, VM, or NUC
2. Go to your HA instance → **Profile → Long-Lived Access Tokens**
3. Click **Create Token**, name it "HomeOS", copy the token

**Config keys:**
```
homeAssistant.url          # e.g., "http://192.168.1.50:8123" or remote URL
homeAssistant.accessToken  # long-lived access token
```

#### 7b. Philips Hue

| Field | Value |
|-------|-------|
| **Service** | [Philips Hue API](https://developers.meethue.com/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (ambiance scenes, lighting workflows) |
| **Cost** | Free (API access is free with Hue Bridge hardware) |

**How to get it:**
1. Find your Hue Bridge IP on your network (or use `meethue.com/api/nupnp`)
2. Navigate to `https://<bridge-ip>/debug/clip.html`
3. POST to `/api` with body `{"devicetype":"homeos#device"}` while pressing the bridge button
4. Copy the returned username/token

**Config keys:**
```
hue.bridgeIp
hue.username               # bridge-generated API username/token
```

#### 7c. Matter

| Field | Value |
|-------|-------|
| **Service** | [Matter Protocol](https://csa-iot.org/all-solutions/matter/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Via Home Assistant or direct integration |
| **Cost** | Free — protocol-based, no API key needed |

No configuration required — Matter uses local network discovery and commissioning.

---

### 8. LLM / AI

#### 8a. Gemma 3n (On-Device — Primary)

| Field | Value |
|-------|-------|
| **Service** | [Gemma 3n](https://ai.google.dev/gemma) |
| **Priority** | **P0** — Core engine |
| **Used by** | All skills (on-device inference for routing, responses, reasoning) |
| **Cost** | Free — runs on-device, no API key needed |

No configuration required. Bundled with the app.

#### 8b. Cloud LLM Fallback (Optional)

| Field | Value |
|-------|-------|
| **Service** | [Gemini API](https://ai.google.dev/) or [Claude API](https://console.anthropic.com/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Complex multi-step tasks that exceed on-device model capability |
| **Cost** | Gemini: Free tier = 15 RPM. Claude: Pay-per-token ($3-15/M tokens). |

**How to get it (Gemini):**
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Create an API key

**How to get it (Claude):**
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Create an API key under Settings → API Keys

**Config keys:**
```
llm.cloudProvider          # "gemini" or "claude" or "none"
llm.geminiApiKey
llm.claudeApiKey
```

---

### 9. Health — Apple HealthKit

| Field | Value |
|-------|-------|
| **Service** | [Apple HealthKit](https://developer.apple.com/documentation/healthkit) |
| **Priority** | **P1** — Important |
| **Used by** | `wellness` (steps, sleep, hydration tracking), `healthcare` (vitals context), `elder-care` (health monitoring) |
| **Cost** | Free — no API key needed |

**Setup:**
- Add the **HealthKit** entitlement to your Xcode project
- Add `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` to Info.plist
- Request authorization at runtime for specific data types (steps, sleep, heart rate)

No API keys or tokens. User grants permission via iOS system prompt.

---

## Optional Services (Enhanced Features)

---

### 10. Telegram Bot API

| Field | Value |
|-------|-------|
| **Service** | [Telegram Bot API](https://core.telegram.org/bots/api) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (alternative chat channel, quick polls, broadcast announcements) |
| **Cost** | Free |

**How to get it:**
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow prompts
3. Copy the **bot token**
4. Configure webhook to your gateway: `https://api.telegram.org/bot<TOKEN>/setWebhook?url=<YOUR_URL>`

**Config keys:**
```
telegram.botToken
telegram.webhookUrl
telegram.allowedUsers      # array of Telegram usernames or IDs
```

---

### 11. WhatsApp Business API

| Field | Value |
|-------|-------|
| **Service** | [WhatsApp Business Platform](https://business.whatsapp.com/) |
| **Priority** | **P2** — Nice to have (international families) |
| **Used by** | Integrations (alternative messaging channel) |
| **Cost** | First 1,000 conversations/month free, then $0.005–$0.08 per conversation |

**How to get it:**
1. Sign up at [Meta for Developers](https://developers.facebook.com/)
2. Create a WhatsApp Business app
3. Get a **Phone Number ID**, **Business Account ID**, and **Access Token**
4. Configure webhooks for incoming messages

**Config keys:**
```
whatsapp.phoneNumberId
whatsapp.businessAccountId
whatsapp.accessToken
```

---

### 12. Education / School

#### 12a. Google Classroom API

| Field | Value |
|-------|-------|
| **Service** | [Google Classroom API](https://developers.google.com/classroom) |
| **Priority** | **P1** — Important for families with school-age children |
| **Used by** | `school` (assignment sync, grade monitoring), `education` (homework tracking) |
| **Cost** | Free |

**How to get it:**
Uses the same Google Cloud project. Enable the **Google Classroom API** and add scopes:
- `classroom.courses.readonly`
- `classroom.coursework.students.readonly`
- `classroom.rosters.readonly`

**Config keys:**
```
google.classroomEnabled    # true/false
# Uses same OAuth as google.calendarClientId / calendarClientSecret
```

#### 12b. Canvas LMS API

| Field | Value |
|-------|-------|
| **Service** | [Canvas LMS API](https://canvas.instructure.com/doc/api/) |
| **Priority** | **P2** — Nice to have (institution-dependent) |
| **Used by** | `school`, `education` |
| **Cost** | Free |

**How to get it:**
1. Log in to your institution's Canvas instance
2. Go to **Account → Settings → New Access Token**
3. Generate a token with appropriate scope
4. Note your institution's Canvas API base URL

**Config keys:**
```
canvas.apiBaseUrl          # e.g., "https://school.instructure.com/api/v1"
canvas.accessToken
```

---

### 13. Marketplace — eBay Browse API (Optional)

| Field | Value |
|-------|-------|
| **Service** | [eBay Browse API](https://developer.ebay.com/api-docs/buy/browse/overview.html) |
| **Priority** | **P2** — Nice to have |
| **Used by** | `marketplace-sell` (sold listing price research for accurate pricing) |
| **Cost** | Free (5,000 calls/day on basic tier) |

**How to get it:**
1. Sign up at [developer.ebay.com](https://developer.ebay.com/)
2. Create an application
3. Get your **App ID (Client ID)** and **Cert ID (Client Secret)**
4. Generate an OAuth token using client credentials grant

**Config keys:**
```
ebay.clientId
ebay.clientSecret
```

> **Note:** The `marketplace-sell` skill works fine without this — it uses web search for pricing by default. The eBay API just provides more accurate sold-listing data.

---

### 14. Financial — Plaid or Teller

| Field | Value |
|-------|-------|
| **Service** | [Plaid](https://plaid.com/) or [Teller](https://teller.io/) |
| **Priority** | **P2** — Nice to have (compliance-heavy) |
| **Used by** | Integrations (read-only bank balances, bill due dates) |
| **Cost** | Plaid: Free for development (100 items), Production starts at $0.30/connection. Teller: Free tier available. |

**How to get it (Plaid):**
1. Sign up at [dashboard.plaid.com](https://dashboard.plaid.com/)
2. Get your **Client ID** and **Secret** (sandbox → development → production)
3. Use Plaid Link for user bank account connection

**How to get it (Teller):**
1. Sign up at [teller.io](https://teller.io/)
2. Get your **API key** and **Application ID**
3. Use Teller Connect for user bank account connection

**Config keys:**
```
financial.provider         # "plaid" or "teller" or "none"
financial.plaidClientId
financial.plaidSecret
financial.plaidEnvironment # "sandbox", "development", or "production"
# OR
financial.tellerApiKey
financial.tellerApplicationId
```

> ⚠️ **Compliance Note:** Financial data access is subject to regulatory requirements. Consult legal counsel before enabling in production. Use **read-only** scopes exclusively.

---

### 15. Productivity — Notion API

| Field | Value |
|-------|-------|
| **Service** | [Notion API](https://developers.notion.com/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (shared family knowledge base) |
| **Cost** | Free (API access included with Notion plan) |

**How to get it:**
1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Create a new internal integration
3. Copy the **Internal Integration Token**
4. Share relevant Notion pages/databases with the integration

**Config keys:**
```
notion.integrationToken
```

---

### 16. Cloud Storage — S3

| Field | Value |
|-------|-------|
| **Service** | [AWS S3](https://aws.amazon.com/s3/) (or compatible: Cloudflare R2, MinIO) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (file uploads, attachment storage per tenant) |
| **Cost** | S3: First 5 GB free, then ~$0.023/GB/month. R2: 10 GB free. |

**Config keys:**
```
storage.provider           # "s3" or "r2" or "local"
storage.s3AccessKeyId
storage.s3SecretAccessKey
storage.s3Bucket
storage.s3Region
```

---

### 17. Smart Home Devices (Additional)

#### Sonos

| Field | Value |
|-------|-------|
| **Service** | [Sonos Control API](https://developer.sonos.com/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (announcements, white noise routines), `elder-care` (music playback) |
| **Cost** | Free |

**Config keys:**
```
sonos.accessToken          # OAuth token from Sonos developer portal
```

#### Tesla / EV (via Tessie)

| Field | Value |
|-------|-------|
| **Service** | [Tessie API](https://developer.tessie.com/) |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (preconditioning, charge scheduling) |
| **Cost** | Tessie: $4.99/month |

**Config keys:**
```
tessie.accessToken
```

---

### 18. Voice Assistants (Optional Bridges)

| Field | Value |
|-------|-------|
| **Service** | Siri Shortcuts (native), Alexa Skill, Google Home Action |
| **Priority** | **P2** — Nice to have |
| **Used by** | Integrations (voice-activated HomeOS commands) |
| **Cost** | Free |

- **Siri**: Uses iOS App Intents framework — no API key, just code Intents
- **Alexa/Google Home**: Requires webhook endpoint and skill/action registration

---

## Configuration File Template

Create a `secrets.json` file for development. **Never commit this to version control.**

```json
{
  "twilio": {
    "accountSid": "",
    "authToken": "",
    "phoneNumber": "+1XXXXXXXXXX"
  },
  "google": {
    "calendarClientId": "",
    "calendarClientSecret": "",
    "calendarRedirectUri": "",
    "mapsApiKey": "",
    "classroomEnabled": false
  },
  "apple": {
    "caldavUsername": "",
    "caldavAppPassword": ""
  },
  "microsoft": {
    "graphClientId": "",
    "graphClientSecret": "",
    "graphRedirectUri": ""
  },
  "apns": {
    "keyId": "",
    "teamId": "",
    "keyFilePath": "./keys/APNsAuthKey.p8",
    "bundleId": "com.yourcompany.homeos",
    "environment": "development"
  },
  "search": {
    "provider": "brave",
    "braveApiKey": ""
  },
  "homeAssistant": {
    "url": "http://192.168.1.50:8123",
    "accessToken": ""
  },
  "hue": {
    "bridgeIp": "",
    "username": ""
  },
  "llm": {
    "cloudProvider": "none",
    "geminiApiKey": "",
    "claudeApiKey": ""
  },
  "telegram": {
    "botToken": "",
    "webhookUrl": "",
    "allowedUsers": []
  },
  "whatsapp": {
    "phoneNumberId": "",
    "businessAccountId": "",
    "accessToken": ""
  },
  "canvas": {
    "apiBaseUrl": "",
    "accessToken": ""
  },
  "ebay": {
    "clientId": "",
    "clientSecret": ""
  },
  "financial": {
    "provider": "none",
    "plaidClientId": "",
    "plaidSecret": "",
    "plaidEnvironment": "sandbox"
  },
  "notion": {
    "integrationToken": ""
  },
  "storage": {
    "provider": "local",
    "s3AccessKeyId": "",
    "s3SecretAccessKey": "",
    "s3Bucket": "",
    "s3Region": ""
  },
  "sonos": {
    "accessToken": ""
  },
  "tessie": {
    "accessToken": ""
  }
}
```

### Environment Variable Alternative

If you prefer environment variables over a JSON file:

```bash
# P0 — Required
export TWILIO_ACCOUNT_SID=""
export TWILIO_AUTH_TOKEN=""
export TWILIO_PHONE_NUMBER=""
export GOOGLE_CALENDAR_CLIENT_ID=""
export GOOGLE_CALENDAR_CLIENT_SECRET=""
export GOOGLE_MAPS_API_KEY=""
export APNS_KEY_ID=""
export APNS_TEAM_ID=""
export APNS_KEY_FILE_PATH=""
export APNS_BUNDLE_ID=""
export SEARCH_PROVIDER="brave"
export BRAVE_SEARCH_API_KEY=""

# P1 — Important
export APPLE_CALDAV_USERNAME=""
export APPLE_CALDAV_APP_PASSWORD=""
export MS_GRAPH_CLIENT_ID=""
export MS_GRAPH_CLIENT_SECRET=""
export HOME_ASSISTANT_URL=""
export HOME_ASSISTANT_TOKEN=""

# P2 — Optional
export LLM_CLOUD_PROVIDER="none"
export GEMINI_API_KEY=""
export CLAUDE_API_KEY=""
export TELEGRAM_BOT_TOKEN=""
export NOTION_INTEGRATION_TOKEN=""
export PLAID_CLIENT_ID=""
export PLAID_SECRET=""
```

---

## Integration Manifest

Each tenant/household maintains an `integration_manifest.yml` that tracks which integrations are enabled:

```yaml
# integration_manifest.yml
tenant_id: "family-smith-001"
integrations:
  twilio:
    enabled: true
    last_validated: "2025-01-15T10:00:00Z"
    token_expiry: null  # Twilio tokens don't expire
  google_calendar:
    enabled: true
    last_validated: "2025-01-14T08:30:00Z"
    token_expiry: "2025-02-14T08:30:00Z"
  home_assistant:
    enabled: true
    last_validated: "2025-01-15T10:00:00Z"
    token_expiry: null  # Long-lived tokens
  # ...
```

The control plane monitors token expiry and triggers renewal reminders automatically.

---

## Priority Summary

| Priority | Service | Required For |
|----------|---------|-------------|
| **P0** | Twilio (Voice + SMS) | Phone calls, SMS notifications |
| **P0** | Google Calendar (OAuth) | Calendar management, morning briefs |
| **P0** | Google Maps / Places | Location search, directions, ETA |
| **P0** | APNs | Push notifications on iOS |
| **P0** | Web Search (Brave/Google) | Cross-skill web lookups |
| **P0** | Gemma 3n (on-device) | LLM inference — no key needed |
| **P1** | Apple CalDAV | iCloud calendar sync |
| **P1** | Microsoft Graph | Outlook calendar/email |
| **P1** | Gmail API | Email parsing, school forms |
| **P1** | Apple HealthKit | Wellness tracking — no key needed |
| **P1** | Home Assistant | Smart home control |
| **P1** | Google Classroom | School assignment sync |
| **P2** | Philips Hue | Lighting scenes |
| **P2** | Telegram Bot | Alternative chat channel |
| **P2** | WhatsApp Business | International families |
| **P2** | Canvas LMS | Institution-specific school |
| **P2** | eBay Browse API | Marketplace pricing data |
| **P2** | Plaid / Teller | Financial read access |
| **P2** | Notion | Shared knowledge base |
| **P2** | Cloud LLM (Gemini/Claude) | Complex task fallback |
| **P2** | Sonos | Audio announcements |
| **P2** | Tessie (Tesla) | EV management |
| **P2** | S3 / R2 | File storage |

---

## Security Notes

### Key Storage
- **Never** hardcode API keys in source code
- Use **iOS Keychain** for on-device credential storage
- Store server-side secrets in environment variables or a secrets manager (e.g., AWS Secrets Manager, HashiCorp Vault)
- Add `secrets.json` to `.gitignore` immediately

### OAuth Token Management
- Store OAuth refresh tokens encrypted at rest
- Implement automatic token refresh before expiry
- Monitor token health via `integration_manifest.yml`
- Handle token revocation gracefully (prompt user to re-authorize)

### Scope Minimization
- Request **least-privilege** scopes for every OAuth integration
- Calendar: `calendar.events` not `calendar.full`
- Gmail: `gmail.readonly` + `gmail.compose` only — never `gmail.full`
- Financial: **read-only** access exclusively

### Rotation & Monitoring
- Rotate API keys quarterly (or immediately if compromised)
- Set up alerts for unusual API usage spikes
- Log all outbound API calls to `~/clawd/homeos/logs/actions.log`
- Review access logs monthly

### Per-User Secrets
- Each household's credentials are isolated per tenant
- User-provided credentials (Apple CalDAV password, bank tokens) are entered via secure in-app forms — never transmitted in chat
- APNs key and Twilio credentials are platform-level (shared across tenants)

### Emergency Credential Handling
- If a credential is compromised: revoke immediately, rotate, notify affected users
- Maintain a revocation checklist per service in your runbook

---

## Services That Don't Need API Keys

For clarity, these services used by HomeOS require **no API keys or tokens**:

| Service | Used By | Notes |
|---------|---------|-------|
| Gemma 3n | All skills | On-device LLM, bundled with app |
| Apple HealthKit | `wellness`, `healthcare` | iOS entitlement + user permission |
| Apple MapKit | `transportation` (alt) | Free on iOS, device entitlement |
| Matter Protocol | Home automation | Local network, commissioning-based |
| Siri Shortcuts | Voice integration | App Intents framework, no external API |
| Local filesystem | All skills | `~/clawd/homeos/` data storage |

---

*Last updated: 2025-01-15. Review quarterly or when adding new skills.*
