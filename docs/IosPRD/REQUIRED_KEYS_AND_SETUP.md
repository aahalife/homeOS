## Required Keys and Setup

Keep this updated as we wire more integrations. Items marked "Needed to ship" block production use.

### Apple Developer (Needed to ship)
- **Apple Developer Program account**
  - Needed for signing, TestFlight, and APNs.
  - Get: https://developer.apple.com/programs/
- **App ID capabilities**
  - Enable: **Push Notifications**, **HealthKit**, **Sign in with Apple**.
  - Where: Apple Developer → Certificates, Identifiers & Profiles → App IDs.
- **APNs Auth Key (.p8)**
  - Needed for server-side push delivery.
  - Where: Keys → Create a key → enable APNs.
  - Provide: **Auth Key file (.p8)**, **Key ID**, **Team ID**, **Bundle ID**.
- **Sign in with Apple**
  - Backend uses `APPLE_CLIENT_ID` (Services ID or bundle ID).
  - Provide: **Client ID**, **Team ID**, **Key ID**, **Private Key (.p8)** if using server validation.

### Notes from you (do not commit)
- APNs key file is available locally and ignored by git.
- Bundle ID should match **com.fantasticapp.HomeOS** for pushes and Sign in with Apple.
- Please rotate any secrets shared in chat before production use.

### Control Plane / Runtime (Needed to ship)
- **JWT secrets**
  - `JWT_SECRET` for control-plane and runtime.
- **Encryption key**
  - `MASTER_ENCRYPTION_KEY` for encrypting workspace secrets.
- **Service tokens**
  - `RUNTIME_SERVICE_TOKEN` (workflows → runtime internal events).
  - `CONTROL_PLANE_SERVICE_TOKEN` (runtime → control-plane notifications/preferences).
- **Service URLs**
  - `CONTROL_PLANE_URL` (runtime to control-plane).
  - `RUNTIME_URL` and `RUNTIME_WS_URL` (control-plane to runtime).

### Environment templates
- `services/control-plane/env.sample`
- `services/runtime/env.sample`
- `services/workflows/env.sample`

### Fly.io setup inputs
- Fly.io **org slug** to deploy into
- Preferred **primary region** (e.g., `sjc`, `iad`, `sin`)
- App names (or let me create):
  - `homeos-control-plane`
  - `homeos-runtime`
  - `homeos-workflows`
- Postgres size/plan (smallest to start is fine)
- Whether to use **Fly Postgres** or external Postgres

### Modal setup inputs
- Modal **account/email** for the project
- Preferred **app name** for the LLM endpoint
- Whether the endpoint should be OpenAI-compatible

### Modal deployment (GPT-OSS 120B)
- Use `services/modal-llm/modal_app.py` for a vLLM OpenAI-compatible endpoint.
- Defaults target **2x A100-80GB**. Increase GPU count if you see OOM errors.
- After deploy, set:
  - `MODAL_LLM_URL` to the Modal web endpoint
  - `MODAL_LLM_TOKEN` to the API key enforced by the server

### Database + Temporal (Needed to ship)
- **Postgres connection**
  - `DATABASE_URL` for control-plane.
- **Temporal**
  - `TEMPORAL_ADDRESS` for runtime/workflows.
  - `TEMPORAL_NAMESPACE` for Temporal Cloud.
  - `TEMPORAL_API_KEY` for Temporal Cloud auth (if enabled).

### Twilio (Needed to ship for SMS/voice)
- **Account SID + Auth Token**
- **Messaging Service SID** or **provisioned phone number**
  - Where: https://www.twilio.com/console

### Telegram (Needed to ship for Telegram channel)
- **Bot token**
  - Where: @BotFather on Telegram.
- **Webhook URL + secret**
  - Where: Telegram bot settings or Bot API.
  - Note: Telegram does **not** allow programmatic bot creation. We can automate linking per workspace using a single bot, but a BotFather token is still required.
  - For multiple bots, provide a mapping file via `TELEGRAM_BOTS_CONFIG_PATH`:

```json
{
  "defaultBotId": "homeos-main",
  "bots": [
    {
      "id": "homeos-main",
      "token": "BOT_TOKEN",
      "username": "HomeOSBot",
      "workspaces": ["<workspace-id>"]
    }
  ]
}
```

Configure each bot webhook to:
`https://<runtime-host>/v1/telegram/webhook?botId=<bot-id>`

### Google OAuth (Needed for Gmail/Calendar)
- **OAuth Client ID + Secret**
  - Enable Google Calendar + Gmail APIs.
  - Where: Google Cloud Console → APIs & Services → Credentials.
- **Redirect URIs**
  - Set to your control-plane OAuth callback endpoints.

### Composio (If using Composio integrations)
- **COMPOSIO_API_KEY**
  - Where: https://app.composio.dev/

### LLM Providers (Needed to ship)
- **Anthropic API key**
- **OpenAI API key** (if used by workflows)
- **Modal LLM endpoint + token** (if using private hosted models)
  - Provide: `MODAL_LLM_URL` and `MODAL_LLM_TOKEN`.
  - The endpoint should be OpenAI-compatible (chat completions).

### BYOK vs Managed Keys
- Users can bring their own keys via the **Secrets** endpoints.
- We can provide a **managed key** (platform-owned) for users who opt in.
- Fully automating Anthropic account creation per user is not supported by provider terms.

### APNs delivery (Server-side push)
When you are ready to ship push notifications, I will need:
- APNs `.p8` key + Key ID + Team ID + Bundle ID
- The environment (dev vs prod)
- Whether to use **token-based** (recommended) or **certificate-based** APNs
