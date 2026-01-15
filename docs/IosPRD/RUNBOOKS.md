# Clawd Home Platform – Runbooks

## 1. Provisioning Runbook
### Purpose
Spin up a new tenant (cloud) or initialize a home hub installation with consistent settings.

### Preconditions
- GitHub repo access to homeOS + automation scripts.
- AWS account or local machine credentials.
- Required secrets in Vault (OpenAI, Anthropic, Telegram master token, Twilio master account, OAuth client IDs).

### Steps – Managed Cloud Tenant
1. **Create tenant record**
   - Run `./scripts/tenant create --name <family>` → generates tenant ID.
2. **Terraform apply**
   - `cd infra/terraform/tenant`
   - `terraform apply -var tenant_id=...` (creates VPC, EKS/ECS, RDS, Redis, S3, Secrets, CloudFront).
3. **Provision Clawdinator stack**
   - Trigger GitHub Action `deploy-clawdinator` with `tenant_id` – installs Clawdbot release, runs `clawd wizard` with pre-filled answers.
4. **Configure integrations**
   - Telegram bot: script hits BotFather API to create bot, stores token in Secrets Manager.
   - Twilio: script uses API to provision local number (SMS + voice), configures webhook to tenant API.
   - Default skills: `clawd skills install -m manifests/family-pack.yml` (includes HomeOS skills + required ClawdHub entries).
5. **Run smoke tests**
   - `./scripts/tenant smoke --tenant <id>`: checks gateway, sends Telegram echo, places Twilio test call, runs `mental-load` morning brief dry run.
6. **Invite user**
   - Generate onboarding link via control plane (`/tenants/<id>/invite`). Email template includes iOS TestFlight/TestFlight link, Telegram QR, Twilio number.

### Steps – Home Hub Installer
1. User downloads app (signed DMG/EXE, notarized).
2. Run installer – checks prerequisites (macOS 13+, 8GB RAM).
3. Installer fetches Clawdbot bundle, runs CLI wizard with GUI interface.
4. Device registers with control plane via secure WebSocket; obtains tenant config.
5. Optional: set up background auto-update + Tailscale for support.
6. Run local diagnostics, prompt user to log in to iOS app to complete personal integrations.

### Verification Checklist
- [ ] Gateway reachable (health endpoint 200).
- [ ] Telegram bot responds to `/ping`.
- [ ] Twilio number answers and hands call to Clawdbot.
- [ ] Morning brief workflow run success.
- [ ] Secrets present in tenant namespace.
- [ ] Audit log contains provisioning event.

## 2. Upgrade Runbook
### Scope
Apply new Clawdbot release, skills updates, or platform code to existing tenants.

### Process
1. **Staging rollout**
   - Deploy to staging tenant, run automated regression (chat, workflows, telephony).
2. **Schedule maintenance window**
   - Notify families (push/email) with release notes, expected impact.
3. **Apply update**
   - For cloud: rolling deploy pods, blue/green if major change.
   - For home hubs: send update command; installer downloads delta and restarts services.
4. **Data migrations**
   - Run Prisma/Drizzle migrations for tenant DB via CI pipeline.
5. **Post-checks**
   - Confirm workflows resumed, no stuck Temporal executions.
6. **Rollback plan**
   - Keep previous container image & DB snapshot; `deploy rollback --tenant <id> --version <prev>`.

## 3. Incident Response Runbook
### Severity Levels
| Sev | Description | Examples |
| --- | --- | --- |
| 1 | Full outage | Clawdbot gateway down, workflows halted |
| 2 | Partial impact | Telephony failing, delayed notifications |
| 3 | Minor/Degraded | Single integration failing |
| 4 | Cosmetic | UI glitch |

### Standard Procedure
1. **Detection** – alerts via Datadog/PagerDuty (health check failures, error budget burn).
2. **Triage** – identify scope (tenant-specific vs global). Check logs, metrics.
3. **Mitigation** – reroute traffic, failover to backup region/home hub, disable impacted workflows if necessary.
4. **Communication** – send status update via Statuspage + push/email with summary + ETA.
5. **Resolution** – apply fix, verify, close incident.
6. **Postmortem** – within 48h for Sev1/2, include root cause, action items.

### Playbooks
- **Telegram outage**: auto-switch to push/SMS; run `channels failover --tenant <id> --channel telegram`.
- **Twilio voice failure**: reroute to alternative carrier if available; send text summary to caregivers.
- **Workflow stuck**: `temporal workflow terminate --workflow-id ...` with safe resume; notify user.
- **Home hub offline**: send ping; if unreachable >1h, notify admin + offer remote assistance instructions.

## 4. Ops Tools
- `tenantctl` CLI for CRUD, secrets, health.
- Grafana dashboards: workflow success, latency, transport usage.
- Kibana/Loki for log search with PII redaction.
- Approval log viewer for auditing.

