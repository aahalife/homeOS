# HomeOS Test Guide

This guide provides comprehensive instructions for testing HomeOS features end-to-end.

## Prerequisites

### Required Accounts & API Keys

| Service | Purpose | Setup |
|---------|---------|-------|
| **Twilio** | Phone calls & SMS | Configure via fly.io secrets |
| **11Labs** | Voice cloning & TTS | API Key pre-configured in fly.io secrets |
| **Composio** | OAuth integrations | Configure via fly.io secrets |
| **OpenAI** | Whisper ASR | Use existing OpenAI key |

### Infrastructure URLs

| Service | URL |
|---------|-----|
| Control Plane | https://homeos-control-plane.fly.dev |
| Runtime | https://homeos-runtime.fly.dev |
| Echo-TTS | https://homeos-echo-tts.fly.dev |

---

## Test 1: Authentication & Account Setup

### Steps

1. **Launch iOS App**
   - Open the HomeOS app on your iPhone or simulator
   - You should see the onboarding/login screen

2. **Sign In with Apple (or Dev Mode)**
   - For development, use passcode authentication:
     - Passcode: `123456` (configured in DEV_PASSCODE)
   - For production, use Sign in with Apple

3. **Verify Login**
   - After authentication, you should see the main tab bar
   - Navigate through all tabs: Chat, Actions, Tasks, Connections, Settings

### Expected Results
- [x] App launches without crashes
- [x] Authentication completes successfully
- [x] All tabs are accessible
- [x] User profile shows in Settings

---

## Test 2: Voice Mode (Microphone Recording)

### Prerequisites
- Grant microphone permission when prompted

### Steps

1. **Navigate to Chat Tab**

2. **Tap the Microphone Button**
   - Located to the left of the text input field
   - The voice recording overlay should appear

3. **Record a Message**
   - Speak clearly for 2-5 seconds
   - Example: "What's the weather like today?"
   - The audio level indicator should respond to your voice

4. **Send the Voice Message**
   - Tap "Send" button
   - The recording should be transcribed
   - Your message should appear in the chat with a microphone icon

5. **Verify Response**
   - Wait for the AI response
   - If TTS is enabled, the response should be spoken aloud

### Expected Results
- [x] Microphone button visible in chat input
- [x] Voice overlay appears when recording
- [x] Audio level visualization works
- [x] Transcription appears as user message
- [x] AI responds to the transcribed message
- [ ] TTS plays the response (requires voice profile)

---

## Test 3: Voice Cloning (Settings)

### Steps

1. **Navigate to Settings Tab**

2. **Find Voice Section**
   - Scroll to the "Voice" section
   - You should see:
     - Text-to-Speech toggle
     - Use Custom Voice toggle
     - Record Your Voice button

3. **Record Voice Sample**
   - Tap "Record Your Voice"
   - Record a 5-30 second sample speaking naturally
   - Example text to read: "Hello, I'm recording this sample to clone my voice for HomeOS. I'll speak naturally so the AI can learn my voice patterns and tone."

4. **Submit Recording**
   - Tap "Stop Recording" when done
   - Tap "Use This Voice"
   - Wait for upload and processing

5. **Enable Custom Voice**
   - Toggle "Use Custom Voice" to ON
   - Future TTS responses will use your cloned voice

### Expected Results
- [x] Voice settings section visible
- [x] Recording interface works
- [x] Audio level indicator responds
- [x] Upload completes successfully
- [x] "Your cloned voice is ready" message appears
- [ ] TTS responses use cloned voice

---

## Test 4: Twilio Phone Number Purchase

### Prerequisites
- Twilio account is configured (pre-configured)

### Steps

1. **Access Phone Settings**
   - Navigate to Settings > Connections (or dedicated Twilio section)
   - Note: This may require API calls directly for now

2. **Search Available Numbers**
   ```bash
   curl -X GET "https://homeos-control-plane.fly.dev/v1/twilio/numbers/available?areaCode=415" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

3. **Purchase a Number**
   ```bash
   curl -X POST "https://homeos-control-plane.fly.dev/v1/twilio/numbers/purchase?workspaceId=YOUR_WORKSPACE_ID" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "+1415XXXXXXX"}'
   ```

4. **Verify Purchase**
   ```bash
   curl -X GET "https://homeos-control-plane.fly.dev/v1/twilio/numbers?workspaceId=YOUR_WORKSPACE_ID" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

### Expected Results
- [x] Available numbers returned
- [x] Number purchase succeeds
- [x] Purchased number appears in list
- [ ] Number can be used for outgoing calls

---

## Test 5: Service Integrations (Composio)

### Steps

1. **Navigate to Connections Tab**

2. **View Available Integrations**
   - You should see a list of available services:
     - Google Calendar
     - Gmail
     - Instacart
     - Uber/Lyft
     - Spotify
     - Facebook
     - SmartThings
     - Notion
     - Todoist

3. **Connect a Service**
   - Tap on a service (e.g., Google Calendar)
   - Tap "Connect"
   - Complete OAuth flow in browser
   - Return to app

4. **Verify Connection**
   - The service should show "Connected" status
   - Connection timestamp should appear

### Expected Results
- [x] Integration list loads
- [x] OAuth URL is generated
- [ ] OAuth flow completes (requires real OAuth credentials in Composio)
- [ ] Connection status updates

---

## Test 6: Chat & AI Interaction

### Steps

1. **Basic Conversation**
   - Send: "Hello, what can you help me with?"
   - Verify response is relevant and helpful

2. **Task Request**
   - Send: "Add a reminder to call mom tomorrow at 3pm"
   - Verify task creation response

3. **Integration Request** (if connected)
   - Send: "What's on my calendar today?"
   - Verify calendar integration response

### Expected Results
- [x] Messages send and receive
- [x] AI responses are contextual
- [ ] Tasks are created
- [ ] Integrations respond with real data

---

## Test 7: Actions Tab

### Steps

1. **Navigate to Actions Tab**

2. **View Available Actions**
   - Make a Call
   - Sell an Item
   - Groceries
   - Book Appointment

3. **Test "Make a Call" Action**
   - Tap "Make a Call"
   - Enter: "Call Olive Garden to make a reservation for 4 at 7pm Friday"
   - Review approval request
   - Approve or deny

### Expected Results
- [x] Action tiles display
- [ ] Call action initiates workflow
- [ ] Approval request appears
- [ ] Call is made (requires Twilio setup)

---

## Test 8: Tasks Tab

### Steps

1. **Navigate to Tasks Tab**

2. **View Pending Tasks**
   - Should show any pending tasks from chat requests

3. **View Pending Approvals**
   - Should show any actions requiring approval

4. **Approve/Deny a Task**
   - Tap on a pending approval
   - Review details
   - Approve or deny

### Expected Results
- [x] Tasks list loads
- [x] Approvals list loads
- [ ] Approve/deny updates status
- [ ] Task completion triggers follow-up

---

## API Testing Reference

### Health Checks

```bash
# Control Plane
curl https://homeos-control-plane.fly.dev/health

# Runtime
curl https://homeos-runtime.fly.dev/health

# Echo-TTS
curl https://homeos-echo-tts.fly.dev/health
```

### Authentication

```bash
# Dev login (passcode)
curl -X POST "https://homeos-control-plane.fly.dev/v1/auth/dev-login" \
  -H "Content-Type: application/json" \
  -d '{"passcode": "123456"}'
```

### Chat

```bash
# Send chat message
curl -X POST "https://homeos-runtime.fly.dev/v1/chat/turn" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workspaceId": "YOUR_WORKSPACE_ID", "message": "Hello"}'
```

### Voice

```bash
# Transcribe audio
curl -X POST "https://homeos-runtime.fly.dev/v1/voice/transcribe" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@recording.m4a"

# Synthesize speech
curl -X POST "https://homeos-runtime.fly.dev/v1/voice/synthesize" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world", "useDefault": true}' \
  --output speech.mp3
```

### Preferences

```bash
# Get all preferences
curl "https://homeos-control-plane.fly.dev/v1/preferences?workspaceId=YOUR_WORKSPACE_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Update preferences
curl -X PUT "https://homeos-control-plane.fly.dev/v1/preferences/ai?workspaceId=YOUR_WORKSPACE_ID" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"preferences": {"responseVerbosity": "concise"}}'
```

---

## Troubleshooting

### App Crashes on Launch
1. Check Xcode console for error messages
2. Verify fly.io services are running: `fly status -a homeos-control-plane`
3. Check network connectivity

### Voice Recording Not Working
1. Verify microphone permission is granted
2. Check iOS Settings > Privacy > Microphone
3. Try restarting the app

### API Returns 401 Unauthorized
1. Token may have expired - re-login
2. Check JWT_SECRET matches between services
3. Verify token format: `Bearer <token>`

### WebSocket Not Connecting
1. Check Runtime service health
2. Verify WebSocket URL is correct
3. Check for network/firewall issues

### Voice Cloning Fails
1. Recording must be 5-30 seconds
2. Check 11Labs API quota
3. Ensure good audio quality (minimal background noise)

---

## Known Limitations

1. **Phone Calls**: Require purchased Twilio number and configured webhooks
2. **OAuth Integrations**: Require Composio production API key with proper app configurations
3. **Voice Cloning**: Limited by 11Labs API quota
4. **Real-time Chat**: WebSocket connection required for streaming responses

---

## Support

For issues or questions:
- Check service logs: `fly logs -a homeos-control-plane`
- Review Swagger docs: https://homeos-control-plane.fly.dev/docs
- Runtime docs: https://homeos-runtime.fly.dev/docs
