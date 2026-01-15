# Clawd Home Platform – Product Requirements Document

## 1. Vision & Summary
Clawd Home Platform (CHP) extends Clawdbot into a turnkey, family-ready assistant spanning iOS, web, Telegram, voice, and telephony. It wraps Clawdbot, HomeOS skills, and ClawdHub integrations with automated provisioning, contextual consent, and progressive-disclosure UX so busy households can benefit without technical setup.

**Key attributes**
- ⚙️ Opinionated automation packs that "just work" on day one
- 📱 Native iOS experience with warm Apple-style design
- ☁️ Two deployment modes: Home Hub (local) or Managed Cloud (AWS via clawdinators)
- 🔐 Guardrails + consent for risky actions, silent automation for low-risk tasks
- 🧠 Workflow packs targeting real household pains (scheduling, school, elder care, etc.)

## 2. Goals & Success Metrics
| Goal | Metric | Target |
| --- | --- | --- |
| Fast onboarding | Median time from signup to first completed workflow | < 15 minutes |
| Automation coverage | % of core workflows enabled by default | 80% |
| Trust & safety | % of high-risk actions with explicit consent | 100% |
| Reliability | Automation success rate w/out human retry | 95% |
| Adoption | Weekly active family members (per household) | ≥3 |
| Satisfaction | NPS from beta families | ≥ +40 |

## 3. Personas & Needs
1. **Primary Organizer Parent** – wants proactive coordination, hates setup.
2. **Partner/Co-parent** – wants updates, delegated tasks, minimal fuss.
3. **Teens** – want quick answers, schedule sync, homework nudges.
4. **Grandparents/Caregivers** – need voice/telephony channel with consent.
5. **Remote Power User** – comfortable adjusting advanced automations, wants observability.

Each persona should get:
- Dedicated channel (push, Telegram, SMS, call) with allowlist + quiet hours.
- Personalized briefs (morning summary, evening reset) built on shared workflows.

## 4. Deployment Modes & Scope
| Mode | Description | Scope |
| --- | --- | --- |
| **Home Hub** | Installer packages Clawdbot + CHP control plane onto user Mac/Windows/Linux mini PC. Uses local compute, optional remote relay. | Provide GUI wizard, health agent, auto-updates, fallback to cloud gateway for heavy jobs. |
| **Managed Cloud** | Dedicated AWS tenancy based on clawdinators. Includes RDS, ECS/K8s, S3, SecretsMgr, Twilio numbers, Telegram bot. | Fully automated provisioning, per-tenant isolation, mobile onboarding. |

Out of scope: rewriting Clawdbot core, exposing raw skill editing to consumers, shared multi-family tenancy without isolation.

## 5. Functional Requirements
### 5.1 Provisioning
- Automated script (Terraform + Ansible) stands up entire stack with default configs.
- Creates & configures: Telegram bot, Twilio numbers, webhook endpoints, storage buckets, logging, monitoring.
- Seeds HomeOS skill packs + clawdhub dependencies via manifest file.
- Health checks run post-provision (Telegram echo, Twilio voice test, workflow smoke).

### 5.2 Identity & Access
- Household-level org with members, roles (Admin, Adult, Teen, Child, Guest, Caregiver).
- Contact methods per member (phone, email, Telegram handle, push token).
- Allowlist enforcement for messaging/voice channels.
- Consent ledger storing integration approvals (Google, Microsoft, HomeAssistant, Tesla, bank, etc.).

### 5.3 Clients
- **iOS app (SwiftUI)** – home, chat, automations, notifications, settings.
- **Web dashboard (Next.js)** – parity + admin utilities.
- **Telegram bot** – pre-configured; invite codes + family-specific commands.
- **Voice/SMS** – Twilio autopilot flows bridging to Clawdbot voicecall skill.

### 5.4 Automation Layer
- Workflow packs (see separate doc) installed & configurable via UI.
- Each workflow references underlying skills/integrations (e.g., `home-maintenance`, `telephony`, `OpenHue`).
- Scheduler + event triggers (calendar events, sensor webhooks, location geofence, inbound SMS, forms).
- Self-healing: auto-retry idempotent steps, escalate only after threshold.

### 5.5 Consent & Risk
- Risk tiers per action: Low (auto), Medium (prefer stored preference), High (always confirm via push, optionally multi-factor).
- Approval envelopes logged. Provide contextual info + rollback plan.
- Child accounts cannot trigger high-risk actions unless explicitly delegated.

### 5.6 Memory & Personalization
- Household memory graph using Clawdbot memory primitives (`~/clawd/homeos/...`).
- Editable preferences (meal styles, bedtime, allergies, budgets, service providers) aggregated from onboarding and ongoing interactions.
- Support per-member quiet hours, escalation paths, fallback guardians.

### 5.7 Error Handling & Notification
- Standard status codes for workflows (Success, Soft Fail, Needs Info, Blocked, Manual Override).
- Notification playbook: auto-fix if possible → if not, send actionable summary with recommended resolution.

### 5.8 Observability
- Service health (gateway, agents, workflows) surfaced in dashboard.
- Logs accessible w/ redaction; push alerts for outages >5 minutes.
- Usage analytics; HBI classification for PII localization choices.

## 6. Non-Functional Requirements
- **Availability**: Cloud tenants ≥99.5%; Home Hub auto-restart + offline-first caching.
- **Security**: Per-tenant KMS keys, zero trust networking, SSO for admin, encryption at rest/in transit.
- **Privacy**: Data residency choice, granular data deletion, audit exports.
- **Performance**: Chat latency <2s median; automation scheduling jitter <1 minute.
- **Scalability**: Up to 20 concurrent members per family, thousands of workflows/day.

## 7. Integrations Baseline
| Domain | Source | Notes |
| --- | --- | --- |
| Messaging | Telegram, Twilio SMS, PushKit | Auto-created per tenant |
| Voice | Twilio Voice → Clawdbot voicecall skill | Consent gate |
| Calendars | Google, iCloud, Outlook (CalDAV) | OAuth flows |
| Email | Gmail API, Outlook Graph, Apple Mail via IMAP/Clawdhub skills | For parsing & actions |
| Home Automation | Home Assistant, Matter, OpenHue, Tesla, Sonos, smart locks | via existing skills or new connectors |
| Docs & Drives | Google Drive, iCloud Drive, Notion, Obsidian | referencing `gog`, `notion`, etc. |
| Finance | Plaid/Teller for read-only balances, billers via telephony | high-risk gating |
| School | Gmail parsing + portals via telephony/browser automation | templated workflows |
| Health | iOS HealthKit (read), provider portals (telephony) | HIPAA-light, rely on user export where possible |

## 8. Success Criteria per Situation
Provide crisp requirements per daily scenario (expanded in Workflow Packs doc). Highlights:
- **Morning Launch** – autopush by 7am if not snoozed, includes weather, top 3 priorities, anomalies; integrates `tools`, `family-comms`, `mental-load`.
- **School Coordination** – detect new school emails → auto-tag, ask for actions (sign form, add calendar). Provide fallback if portal login needed (via telephony skill).
- **Elder Care Check-ins** – Twilio voice call daily; escalate to caregivers if no response.
- **Home Maintenance** – surfaces recurring tasks, vendor rosters, autopilot scheduling with approval using `home-maintenance` + `telephony`.
- **Travel Concierge** – compile itinerary from email, create packing list referencing `transportation`, `meal-planning`.

## 9. Dependencies & Assumptions
- Clawdbot releases remain backward compatible; platform treats Clawdbot as black box configured via CLI + skills.
- Clawdinators repo provides AWS baked AMIs; Terraform modules wrap them.
- Family data stored in structured JSON/resilient DB; prefer Postgres for metadata, S3 for files.

## 10. Open Questions
1. How to price tiers for cloud vs home? (Meter by workflows? channels?)
2. Should Telegram bot be shared multi-tenant or per family? (Default: per family for privacy.)
3. Depth of financial automation allowed before licensing concerns? (Start read-only, manual confirm for payments.)
4. Data residency for EU families – host in region-specific AWS accounts?

