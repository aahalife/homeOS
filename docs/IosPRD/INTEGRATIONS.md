# Clawd Home Platform – Integration Guides

Each integration includes: purpose, configuration, automation coverage, user inputs required, workflows consuming it.

## 1. Telegram Bot
- **Purpose**: Primary chat channel, quick onboarding invites.
- **Automation**:
  - Script registers bot via BotFather API (using master token).
  - Webhook auto-configured to tenant gateway.
  - Default commands: `/start`, `/familyhelp`, `/approve`, `/sos`.
- **User Inputs**: Provide Telegram usernames/phone numbers for allowlist.
- **Workflows**: Chat, approvals, quick polls, broadcast announcements.

## 2. Twilio Voice & SMS
- **Purpose**: Voice calls (check-ins, concierge) + SMS notifications.
- **Automation**:
  - Provision phone number with voice+SMS.
  - Configure Webhook -> `/telephony/inbound`.
  - Deploy Twilio Function for fallback (voicemail transcription).
- **User Inputs**: Allowed caller IDs, emergency contacts, escalate list.
- **Workflows**: Elder-care check-in, restaurant booking calls, emergency hotline.

## 3. Push Notifications (APNs)
- **Purpose**: Native iOS alerts for approvals, reminders, statuses.
- **Automation**:
  - APNs key stored in tenant secrets; Notification router handles tokens.
- **User Inputs**: Device registration from app (auto).
- **Workflows**: Approvals, morning briefs, outage alerts.

## 4. Calendars
### Google Calendar (gog / CalDAV)
- **Automation**: OAuth app per platform with multi-tenant redirect; refresh tokens stored encrypted.
- **User Inputs**: During onboarding, user signs into Google via in-app webview.
- **Workflows**: Morning brief, conflict detection, carpool, school scheduling.

### iCloud Calendar (CalDAV)
- Uses app-specific password; user enters in secure form.

### Outlook / Microsoft 365
- MS Graph OAuth; use shared multi-tenant app.

## 5. Email
- **Gmail**: same OAuth as calendar; scopes: read, compose, metadata. For autoparsing school forms.
- **Outlook**: Graph API.
- **Apple Mail**: rely on user device + Apple Mail skill if local Mac hub.
- **Workflows**: School admin, bill detection, travel itinerary ingestion, daily digest.

## 6. Home Automation
| Integration | Mechanism | Notes |
| --- | --- | --- |
| Home Assistant | Long-lived token; local network or remote URL | Auto-discovers devices/scenes |
| Matter/Matter bridges | Via Home Assistant or dedicated skill | |
| Philips Hue | OpenHue skill with token | Scenes for ambiance workflows |
| Smart Locks (August, Level) | via Home Assistant or dedicated skill | high risk, require approval |
| Sonos | `sonoscli` skill | For announcements, white noise routines |
| Tesla / EV | `tessie` skill | Preconditioning, charge schedule |

## 7. Productivity & Storage
- **Notion**: API token from user; used for shared knowledge base.
- **Obsidian/Local notes**: via existing skill; mostly on Home Hub.
- **Drive (Google/Dropbox)**: for storing PDFs, forms.

## 8. Communication Apps
- **WhatsApp (wacli)**: optional channel for international families; requires WhatsApp Business setup.
- **Slack/Teams**: for families coordinating with workplaces; optional.

## 9. Financial
- **Plaid/Teller**: read-only to fetch balances + due dates; optional due to compliance.
- **Billers via Telephony**: scriptable call flows to pay utilities; high risk.

## 10. Health & Wellness
- **HealthKit**: user opt-in from iOS app; read steps, sleep, vitals for context.
- **Provider portals**: stored credentials (with 1Password skill) or telephony automation.

## 11. School & Kids Apps
- **Google Classroom / Canvas**: via `gog` or API if available.
- **District portals**: telephony/automation script per district; stored as templates.
- **Transportation trackers**: integration via API or email parsing.

## 12. Voice Assistants
- Integration with Siri shortcuts: iOS app exposes intents (“Ask Clawd to...”).
- Optional Alexa/Google Home bridging via webhook.

## 13. Data Storage Paths
- Household data mirrored between Postgres (structured) and Clawdbot-compatible filesystem layout.
- File upload service stores attachments in S3 bucket per tenant.

## 14. Configuration Management
- `integration_manifest.yml` per tenant lists enabled integrations, required secrets, last validation timestamp.
- Control plane monitors token expiry, triggers renewal reminders.

