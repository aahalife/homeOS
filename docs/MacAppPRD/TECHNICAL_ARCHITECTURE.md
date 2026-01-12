# Hearth: Technical Architecture

This document details the technical implementation of Hearth, including its relationship with Clawdbot, data architecture, and system requirements.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         macOS                                │
│  ┌───────────────────────┐   ┌─────────────────────────────┐  │
│  │    Hearth.app          │   │     Clawdbot Gateway          │  │
│  │    (SwiftUI)           │   │     (Node.js)                 │  │
│  │                       │   │                               │  │
│  │  ┌───────────────────┐ │   │  ┌───────────────────────┐ │  │
│  │  │ Menu Bar UI     │ │   │  │ AI Agent Runtime    │ │  │
│  │  └───────────────────┘ │   │  └───────────────────────┘ │  │
│  │  ┌───────────────────┐ │   │  ┌───────────────────────┐ │  │
│  │  │ Full Window UI  │ │   │  │ HomeOS Skills       │ │  │
│  │  └───────────────────┘ │   │  └───────────────────────┘ │  │
│  │  ┌───────────────────┐ │   │  ┌───────────────────────┐ │  │
│  │  │ Local SwiftData │ │───│  │ Telephony Service   │ │  │
│  │  └───────────────────┘ │WS │  └───────────────────────┘ │  │
│  └───────────────────────┘   └─────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────┐
              │   External Services    │
              ├───────────────────────┤
              │ • Anthropic/OpenAI     │
              │ • Google Classroom     │
              │ • Canvas LMS           │
              │ • Voice Call Provider  │
              └───────────────────────┘
```

---

## Technology Stack

### Hearth App (Native macOS)

| Component | Technology | Rationale |
|-----------|------------|----------|
| **Language** | Swift 5.9+ | Modern, safe, performant |
| **UI Framework** | SwiftUI | Declarative, native macOS feel |
| **App Type** | Menu Bar + NSWindow | Always accessible |
| **Local Storage** | SwiftData | Native persistence, migrations |
| **Networking** | URLSession + WebSocket | Native, efficient |
| **Notifications** | UserNotifications | Native macOS integration |
| **Calendar** | EventKit | Apple Calendar access |
| **Keychain** | Security framework | Secure credential storage |

### Clawdbot Integration

| Component | Technology | Rationale |
|-----------|------------|----------|
| **Gateway** | Node.js (Clawdbot) | Existing infrastructure |
| **Protocol** | WebSocket | Real-time, bidirectional |
| **Port** | 18789 (default) | Clawdbot standard |
| **Auth** | Local token | Secure local connection |

### Data Storage

| Data Type | Location | Technology |
|-----------|----------|------------|
| Family profiles | `~/Library/Application Support/Hearth/` | SwiftData |
| Preferences | `~/Library/Preferences/` | UserDefaults |
| Credentials | macOS Keychain | Security framework |
| Skills data | `~/clawd/homeos/` | JSON files (Clawdbot) |
| Logs | `~/Library/Logs/Hearth/` | Text files |

---

## Clawdbot Integration

### Gateway Connection

Hearth connects to the local Clawdbot Gateway via WebSocket:

```swift
class ClawdbotGateway: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    private let gatewayURL = URL(string: "ws://127.0.0.1:18789")!
    
    func connect() async throws {
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: gatewayURL)
        webSocket?.resume()
        await receiveMessages()
    }
    
    func send(method: String, params: [String: Any]) async throws -> Response {
        let message = ["method": method, "params": params]
        let data = try JSONSerialization.data(withJSONObject: message)
        try await webSocket?.send(.data(data))
    }
}
```

### Skill Invocation

Hearth invokes HomeOS skills through the Gateway:

```swift
// Example: Get family overview
let response = try await gateway.send(
    method: "agent.message",
    params: [
        "message": "Get today's family overview",
        "skill": "mental-load"
    ]
)

// Example: Trigger elder check-in
let response = try await gateway.send(
    method: "agent.message",
    params: [
        "message": "Call Rose for morning check-in",
        "skill": "elder-care",
        "requireApproval": true
    ]
)
```

### Bundled Skills

Hearth includes and manages these HomeOS skills:

```
~/clawd/skills/
├── homeos-family-comms/
├── homeos-elder-care/
├── homeos-education/
├── homeos-mental-load/
├── homeos-meal-planning/
├── homeos-healthcare/
├── homeos-home-maintenance/
├── homeos-wellness/
├── homeos-habits/
├── homeos-chat-turn/
└── homeos-infrastructure/
```

---

## Data Architecture

### SwiftData Models

```swift
@Model
class FamilyMember {
    @Attribute(.unique) var id: UUID
    var name: String
    var role: MemberRole // parent, child, elder
    var age: Int?
    var phone: String?
    var email: String?
    var photoData: Data?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var calendarEvents: [CalendarEvent]
}

enum MemberRole: String, Codable {
    case parent
    case child
    case elder
}

@Model
class ElderProfile {
    @Attribute(.unique) var id: UUID
    var member: FamilyMember
    var checkInTimes: [Date]
    var medications: [Medication]
    var interests: [String]
    var emergencyContacts: [Contact]
    var musicPreferences: MusicPreferences?
}

@Model
class CheckInLog {
    @Attribute(.unique) var id: UUID
    var elder: ElderProfile
    var timestamp: Date
    var type: CheckInType // morning, evening, manual
    var status: CheckInStatus // completed, missed, declined
    var summary: String?
    var moodRating: Int?
    var medicationsTaken: Bool?
    var notes: String?
}
```

### HomeOS Data (JSON)

Shared with Clawdbot at `~/clawd/homeos/data/`:

```json
// family.json
{
  "members": [
    {
      "id": "member-sarah",
      "name": "Sarah",
      "role": "parent",
      "phone": "+15551234567"
    }
  ]
}

// elder_care/rose.json
{
  "id": "elder-rose",
  "name": "Rose",
  "phone": "+15559876543",
  "call_times": ["09:00", "19:00"],
  "medications": [...],
  "music_preferences": {
    "era": "1960s",
    "artists": ["Frank Sinatra"]
  }
}
```

---

## Key Flows

### Morning Briefing Flow

```
1. [Scheduler] Triggers at configured time (e.g., 7:00 AM)
2. [Hearth] Fetches calendar events (EventKit)
3. [Hearth] Fetches weather (wttr.in via Gateway)
4. [Hearth] Requests briefing from mental-load skill
5. [Gateway] AI generates personalized briefing
6. [Hearth] Formats for notification
7. [Hearth] Delivers via UserNotifications
8. [Hearth] Updates menu bar badge
```

### Elder Check-In Flow

```
1. [Scheduler] Triggers at configured time (e.g., 9:00 AM)
2. [Hearth] Shows approval dialog (HIGH risk action)
3. [User] Confirms "Call Now"
4. [Hearth] Sends call request to Gateway
5. [Gateway] Invokes elder-care skill
6. [Skill] Initiates AI voice call via telephony
7. [Call] Conversation happens (wellness, meds, music)
8. [Skill] Generates summary
9. [Gateway] Returns summary to Hearth
10. [Hearth] Displays summary, updates log
11. [Hearth] Notifies family members
```

### Homework Sync Flow

```
1. [Scheduler] Triggers every 15 minutes
2. [Hearth] Checks OAuth token validity
3. [Hearth] Fetches from Google Classroom API
4. [Hearth] Parses assignments and grades
5. [Hearth] Updates local SwiftData models
6. [Hearth] Compares to previous state
7. [Hearth] Generates alerts for new/overdue items
8. [Hearth] Updates menu bar badge if attention needed
```

---

## Security Architecture

### Credential Storage

```swift
class SecureStorage {
    private let keychain = Keychain(service: "com.hearth.app")
    
    func storeOAuthToken(_ token: OAuthToken, for service: String) throws {
        let data = try JSONEncoder().encode(token)
        try keychain.set(data, key: "\(service).oauth")
    }
    
    func getOAuthToken(for service: String) throws -> OAuthToken? {
        guard let data = try keychain.getData("\(service).oauth") else {
            return nil
        }
        return try JSONDecoder().decode(OAuthToken.self, from: data)
    }
}
```

### Data Encryption

- Local SwiftData database encrypted via FileVault (macOS)
- Keychain items protected by Secure Enclave where available
- No sensitive data in UserDefaults

### Network Security

- Gateway connection is localhost only (no external exposure)
- External API calls use HTTPS only
- OAuth tokens refreshed automatically
- Certificate pinning for sensitive services

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| macOS | 14.0 (Sonoma) or later |
| Processor | Apple Silicon or Intel |
| Memory | 4 GB RAM |
| Storage | 500 MB available |
| Node.js | 22.0 or later (for Clawdbot) |

### Recommended

| Component | Recommendation |
|-----------|----------------|
| macOS | Latest stable release |
| Processor | Apple Silicon |
| Memory | 8 GB RAM |
| Storage | 1 GB available |

### Dependencies

| Dependency | Required For |
|------------|---------------|
| Clawdbot Gateway | Core AI functionality |
| Node.js 22+ | Running Clawdbot |
| Internet connection | AI processing, external APIs |
| Apple Calendar (optional) | Calendar integration |
| Google account (optional) | Classroom integration |

---

## Build & Distribution

### Development

```bash
# Clone repository
git clone https://github.com/aahalife/hearth-mac.git
cd hearth-mac

# Open in Xcode
open Hearth.xcodeproj

# Build and run
# Cmd+R in Xcode
```

### Distribution

| Channel | Method |
|---------|--------|
| Direct | Notarized DMG from website |
| Beta | TestFlight for Mac |
| Future | Mac App Store (if sandbox compatible) |

### Code Signing

- Developer ID for direct distribution
- Notarization required for Gatekeeper
- Hardened runtime enabled

---

## Monitoring & Logging

### Local Logs

```
~/Library/Logs/Hearth/
├── hearth.log          # General app logs
├── gateway.log         # Clawdbot communication
├── elder-care.log      # Check-in history
└── errors.log          # Error tracking
```

### Telemetry (Opt-In)

- Crash reports via Apple's built-in mechanism
- Anonymous usage analytics (with explicit consent)
- No personal or family data in telemetry

---

*Architecture subject to refinement during implementation.*
