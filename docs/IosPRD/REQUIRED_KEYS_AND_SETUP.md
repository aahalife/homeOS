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

### Database + Temporal (Needed to ship)
- **Postgres connection**
  - `DATABASE_URL` for control-plane.
- **Temporal**
  - `TEMPORAL_ADDRESS` for runtime/workflows.

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

### APNs delivery (Server-side push)
When you are ready to ship push notifications, I will need:
- APNs `.p8` key + Key ID + Team ID + Bundle ID
- The environment (dev vs prod)
- Whether to use **token-based** (recommended) or **certificate-based** APNs
