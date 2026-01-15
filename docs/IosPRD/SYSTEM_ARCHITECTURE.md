# Clawd Home Platform – System Architecture

## 1. Overview
Clawd Home Platform (CHP) sits on top of Clawdbot. We keep Clawdbot unmodified, configure it via automation, and layer additional services:
- **Provisioning & Control Plane** – Terraform/Ansible/Talos orchestrations, tenant metadata, secrets, workflow catalogue.
- **Experience Layer** – iOS/web clients, notification router, workflow builder UI.
- **Automation Layer** – Workflow runtime (Temporal / Durable Orchestrator) driving Clawdbot agents via APIs.

## 2. Logical Architecture Diagram (text)
```
+-------------------+        +------------------+
| iOS App (SwiftUI) |<-----> | GraphQL/REST API |
+-------------------+        +------------------+
                                   |
+-------------------+              v             +------------------+
| Web Dashboard     |<----->+ Control Plane +--->|  Observability   |
+-------------------+       |  (Tenant DB)  |    |  (OTel, Logs)    |
                            +------+---------+    +------------------+
                                   |
                         +---------+---------+
                         | Workflow Orchestr.| (Temporal)
                         +---------+---------+
                                   |
                +------------------+------------------+
                |                                    |
        +-------v------+                     +-------v-------+
        | Clawdbot GW  |<--------------------| Integration   |
        | (Agent Core) |  Skills/Plugins     | Connectors    |
        +-------+------+  (ClawdHub, HomeOS) | (Telegram,    |
                |                           |  Twilio, etc.)|
                v                           +---------------+
       +--------+---------+
       | Storage (S3, DB) |
       +------------------+
```

## 3. Deployment Topologies
### 3.1 Managed Cloud Tenant
- **AWS Account per family** (or secure multi-tenant cluster w/ namespaces).
- Core components:
  - ECS/Kubernetes running Clawdinator images + CHP sidecars.
  - RDS Postgres (tenant DB), Redis (cache/session), S3 bucket (files/memory).
  - Secrets Manager for API keys, Telegram/Twilio tokens.
  - CloudWatch / Datadog agents for metrics/logs.
  - API Gateway + ALB for HTTPS endpoints.
- CI/CD pipeline pushes versioned containers; blue/green deployments for Clawdbot upgrades.

### 3.2 Home Hub Installation
- Installer bundles Docker Compose or native binaries.
- Services: Clawdbot Gateway, Workflow Orchestrator (lightweight), Local Postgres/SQLite, UI service.
- Optional secure tunnel (Tailscale/ZeroTier) for support & remote notifications.
- Local watchers for CPU/memory, auto-update agent with rollback.

### 3.3 Hybrid Mode
- Home hub handles LAN devices; heavy workloads and telephony run in cloud.
- Secure message bus (MQTT over TLS or WebSocket queue) links local + cloud for commands/responses.

## 4. Component Responsibilities
| Component | Responsibilities |
| --- | --- |
| iOS App / Web | Chat, workflow gallery, notifications, approvals, health view |
| Notification Router | Fan-out push/SMS/Telegram, apply quiet hours, escalate |
| Control Plane API | Tenant CRUD, member roster, secrets broker, audit log |
| Workflow Orchestrator | Schedules workflow packs, handles retries, interacts with Clawdbot via API & CLI |
| Clawdbot Gateway | Maintains sessions, runs conversations, executes skills |
| Integration Connectors | Manage third-party APIs (Telegram, Twilio, Google, Home Assistant) |
| Storage Layer | Postgres (metadata/audit), S3 (files), Redis (cache) |
| Observability Stack | Metrics, traces, alerting, dashboards |

## 5. Data Flow Examples
### 5.1 Morning Brief Automation
1. Scheduler triggers workflow (Temporal) at 06:55.
2. Workflow pulls calendar data via `tools` skill + Google integration.
3. Clawdbot composes summary with `mental-load` skill guidance.
4. Workflow sends message via Notification Router (push/text/Telegram) respecting preferences.
5. Results logged; success/fail metrics recorded.

### 5.2 High-Risk Action (Unlock Door)
1. User request captured via app → Workflow identifies high risk.
2. Orchestrator emits Approval Envelope → push notification to approvers.
3. Upon approval, Clawdbot uses Home Assistant integration to unlock.
4. Audit entry stored with envelope ID, actor, timestamp.
5. Notification router confirms action, Observability records risk event.

### 5.3 Telephony Check-In
1. Scheduler triggers Twilio voice flow.
2. Telephony connector dials elder; audio piped into Clawdbot `voicecall`.
3. Summaries & sentiment logged; if no pickup → escalate.

## 6. Key Interfaces
- **GraphQL/REST Endpoints**: `/workflows`, `/members`, `/approvals`, `/health`, `/settings`.
- **Webhook endpoints**: inbound SMS, Twilio voice webhook, Telegram bot webhook.
- **Clawdbot API**: `clawd agent message`, `clawd skills install`, `clawd gateway status` (invoked via orchestrator).
- **Secret broker**: short-lived signed URLs for clients to fetch credentials.

## 7. Infrastructure as Code
- Terraform modules: `network`, `database`, `compute`, `telecom`, `clawdbot`.
- Ansible/Talos: configure Clawdbot environment, install dependencies, push skills.
- GitHub Actions pipeline: builds containers, runs integration tests, updates Terraform state.

## 8. Scaling & Resilience
- **Clawdbot**: run multiple agents per tenant; auto-restart on failure.
- **Workflows**: partitioned queues per tenant to prevent cross-impact.
- **Datastores**: Multi-AZ RDS, S3 versioning, Redis cluster with snapshotting.
- **Failover**: Cloud deployments replicate to secondary region; Home hubs fall back to cloud gateway.
- **Rate limiting**: At API gateway and per integration (e.g., Twilio call throttle).

## 9. Security Controls
- IAM least privilege per component.
- Secrets encrypted (KMS) and rotated automatically.
- Audit logs immutable (CloudTrail / WORM S3 bucket).
- Device trust: iOS app uses device binding + biometric for approvals.
- Network: Private subnets, zero public SSH, SSM Session Manager for ops.

## 10. Future Enhancements
- Shared workflow marketplace (publish custom packs).
- Federated learning for preference models (opt-in).
- Offline-first local inference for small tasks on Home Hub.

