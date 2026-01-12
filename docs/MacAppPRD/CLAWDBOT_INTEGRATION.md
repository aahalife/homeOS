# Hearth: Clawdbot Integration Guide

> Configuration, code changes, and customizations needed to use Clawdbot as Hearth's backbone.

---

## Overview

Hearth uses Clawdbot as its AI backend. This document details:
1. Configuration changes to `clawdbot.json`
2. Workspace setup for HomeOS skills
3. Provider configurations for multi-channel messaging
4. Custom skill development requirements
5. Source code modifications (if needed)

---

## 1. Base Configuration

### `~/.clawdbot/clawdbot.json`

```json
{
  "agent": {
    "model": "anthropic/claude-sonnet-4-20250514",
    "thinkingLevel": "medium",
    "workspace": "~/clawd"
  },
  
  "gateway": {
    "port": 18789,
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "${HEARTH_GATEWAY_TOKEN}"
    }
  },

  "agents": {
    "defaults": {
      "workspace": "~/clawd",
      "skills": {
        "autoLoad": true,
        "directories": [
          "~/clawd/skills/homeos"
        ]
      }
    },
    
    "hearth-main": {
      "description": "Primary Hearth family assistant",
      "systemPrompt": "~/clawd/HEARTH_SOUL.md",
      "skills": ["homeos-*"],
      "tools": {
        "allow": ["*"],
        "deny": []
      }
    },
    
    "hearth-elder": {
      "description": "Elder care specialist agent",
      "systemPrompt": "~/clawd/ELDER_SOUL.md",
      "skills": ["homeos-elder-care", "homeos-telephony"],
      "voice": {
        "enabled": true,
        "provider": "elevenlabs",
        "voiceId": "warm-caring-female"
      }
    }
  }
}
```

---

## 2. Provider Configuration

### iMessage (Primary Family Channel)

```json
{
  "imessage": {
    "enabled": true,
    "allowFrom": [
      "+15551234567",
      "+15559876543"
    ],
    "groups": {
      "family-chat": {
        "activation": "mention",
        "allowFrom": ["*"]
      }
    }
  }
}
```

### WhatsApp (Extended Family)

```json
{
  "whatsapp": {
    "enabled": true,
    "dmPolicy": "pairing",
    "allowFrom": [],
    "groups": {
      "*": {
        "requireMention": true
      }
    }
  }
}
```

### Telegram (Optional)

```json
{
  "telegram": {
    "enabled": false,
    "botToken": "${TELEGRAM_BOT_TOKEN}"
  }
}
```

---

## 3. Voice Configuration

### ElevenLabs TTS

```json
{
  "voice": {
    "tts": {
      "provider": "elevenlabs",
      "apiKey": "${ELEVENLABS_API_KEY}",
      "voiceId": "rachel",
      "model": "eleven_multilingual_v2",
      "settings": {
        "stability": 0.5,
        "similarity_boost": 0.75
      }
    },
    "asr": {
      "provider": "whisper",
      "model": "large-v3"
    },
    "vad": {
      "provider": "silero",
      "threshold": 0.5
    }
  }
}
```

---

## 4. Telephony Configuration

### For Elder Check-In Calls

```json
{
  "telephony": {
    "enabled": true,
    "provider": "twilio",
    "accountSid": "${TWILIO_ACCOUNT_SID}",
    "authToken": "${TWILIO_AUTH_TOKEN}",
    "fromNumber": "+15551112222",
    "voice": {
      "provider": "elevenlabs",
      "voiceId": "warm-caring-elder"
    },
    "recording": {
      "enabled": true,
      "consent": "required"
    }
  }
}
```

---

## 5. Browser Automation

```json
{
  "browser": {
    "enabled": true,
    "controlUrl": "http://127.0.0.1:18791",
    "headless": false,
    "profiles": {
      "hearth-automation": {
        "userDataDir": "~/clawd/browser-profiles/hearth"
      }
    },
    "allowlist": [
      "classroom.google.com",
      "canvas.instructure.com",
      "opentable.com",
      "instacart.com"
    ]
  }
}
```

---

## 6. Cron Jobs Configuration

```json
{
  "cron": {
    "enabled": true,
    "jobs": [
      {
        "id": "morning-briefing",
        "schedule": "0 7 * * *",
        "agent": "hearth-main",
        "message": "Generate and deliver morning briefing",
        "skill": "homeos-mental-load"
      },
      {
        "id": "elder-morning-checkin",
        "schedule": "0 9 * * *",
        "agent": "hearth-elder",
        "message": "Perform morning check-in call",
        "skill": "homeos-elder-care",
        "requireApproval": true
      },
      {
        "id": "elder-evening-checkin",
        "schedule": "0 19 * * *",
        "agent": "hearth-elder",
        "message": "Perform evening check-in call",
        "skill": "homeos-elder-care",
        "requireApproval": true
      },
      {
        "id": "email-bill-scan",
        "schedule": "0 */4 * * *",
        "agent": "hearth-main",
        "message": "Scan emails for bills and due dates",
        "skill": "homeos-financial"
      },
      {
        "id": "homework-sync",
        "schedule": "*/30 * * * *",
        "agent": "hearth-main",
        "message": "Sync homework from LMS platforms",
        "skill": "homeos-education"
      },
      {
        "id": "evening-winddown",
        "schedule": "0 20 * * *",
        "agent": "hearth-main",
        "message": "Generate evening summary and tomorrow prep",
        "skill": "homeos-mental-load"
      }
    ]
  }
}
```

---

## 7. Webhook Configuration

```json
{
  "webhooks": {
    "enabled": true,
    "endpoints": [
      {
        "path": "/gmail",
        "handler": "gmail-pubsub",
        "secret": "${GMAIL_WEBHOOK_SECRET}"
      },
      {
        "path": "/calendar",
        "handler": "calendar-sync",
        "secret": "${CALENDAR_WEBHOOK_SECRET}"
      }
    ]
  }
}
```

---

## 8. Gmail Pub/Sub for Bill Detection

```json
{
  "gmail": {
    "enabled": true,
    "pubsub": {
      "projectId": "${GCP_PROJECT_ID}",
      "topicName": "hearth-gmail-notifications",
      "subscriptionName": "hearth-gmail-sub"
    },
    "filters": [
      {
        "label": "bills",
        "query": "(subject:bill OR subject:invoice OR subject:statement OR subject:payment due)"
      },
      {
        "label": "school",
        "query": "from:*@school.edu OR from:*@k12.* OR from:classroom.google.com"
      }
    ]
  }
}
```

---

## 9. Approval & Allowlist System

### Risk Level Configuration

```json
{
  "approvals": {
    "riskLevels": {
      "low": {
        "actions": ["read", "search", "suggest", "generate"],
        "approval": "never"
      },
      "medium": {
        "actions": ["save", "remind", "notify", "schedule"],
        "approval": "once",
        "rememberDays": 30
      },
      "high": {
        "actions": ["call", "send", "pay", "book", "cancel", "signup"],
        "approval": "always"
      }
    },
    
    "allowlist": {
      "storage": "~/clawd/homeos/memory/preferences/allowlist.json",
      "rules": []
    }
  }
}
```

### Allowlist Schema

```json
{
  "rules": [
    {
      "id": "elder-morning-call",
      "action": "telephony.call",
      "conditions": {
        "recipient": "+15559876543",
        "timeWindow": "08:00-11:00",
        "purpose": "elder-checkin"
      },
      "decision": "allow",
      "createdAt": "2025-01-15T10:30:00Z",
      "createdBy": "user-approval"
    },
    {
      "id": "auto-pay-electric",
      "action": "payment.schedule",
      "conditions": {
        "payee": "Electric Company",
        "maxAmount": 300
      },
      "decision": "allow",
      "createdAt": "2025-01-10T14:00:00Z"
    },
    {
      "id": "school-form-fill",
      "action": "browser.formFill",
      "conditions": {
        "domain": "*.k12.*.us",
        "formType": "permission-slip"
      },
      "decision": "allow"
    }
  ]
}
```

---

## 10. Error Recovery (Ralph Wiggum Pattern)

### Configuration

```json
{
  "errorRecovery": {
    "enabled": true,
    "maxRetries": 5,
    "strategies": [
      {
        "errorType": "network",
        "strategy": "exponential-backoff",
        "initialDelay": 1000,
        "maxDelay": 60000
      },
      {
        "errorType": "auth",
        "strategy": "refresh-and-retry",
        "maxRetries": 2
      },
      {
        "errorType": "rate-limit",
        "strategy": "wait-and-retry",
        "waitTime": "from-header"
      },
      {
        "errorType": "validation",
        "strategy": "fix-and-retry",
        "useAI": true
      },
      {
        "errorType": "unknown",
        "strategy": "alternative-approach",
        "useAI": true
      }
    ],
    "escalation": {
      "afterRetries": 3,
      "notifyUser": true,
      "offerAlternatives": true
    }
  }
}
```

### Recovery Skill Implementation

```markdown
---
name: error-recovery
description: Handle task failures with intelligent retry and alternative approaches
---

# Error Recovery Skill

## On Task Failure:

1. **Analyze the error**
   - What went wrong?
   - Is it transient or permanent?
   - What was the goal?

2. **Select recovery strategy**
   - Retry (network, rate-limit)
   - Refresh credentials (auth)
   - Try alternative approach (validation, unknown)
   - Escalate to user (after max retries)

3. **Execute recovery**
   - Log attempt
   - Apply strategy
   - Verify success
   - Update task state

4. **Learn from failure**
   - Store failure pattern
   - Update approach for future
   - Notify if systemic issue
```

---

## 11. Workspace Structure

```
~/clawd/
├── HEARTH_SOUL.md           # Main personality prompt
├── ELDER_SOUL.md            # Elder care personality
├── AGENTS.md                # Clawdbot agent instructions
│
├── skills/
│   └── homeos/
│       ├── homeos-infrastructure/
│       ├── homeos-chat-turn/
│       ├── homeos-family-comms/
│       ├── homeos-elder-care/
│       ├── homeos-education/
│       ├── homeos-mental-load/
│       ├── homeos-healthcare/
│       ├── homeos-meal-planning/
│       ├── homeos-home-maintenance/
│       ├── homeos-financial/
│       ├── homeos-emotional-support/
│       ├── homeos-voice-companion/
│       └── homeos-automation/
│
├── homeos/
│   ├── memory/
│   │   ├── conversations/
│   │   ├── preferences/
│   │   │   ├── allowlist.json
│   │   │   ├── family-prefs.json
│   │   │   └── approvals.json
│   │   ├── entities/
│   │   └── learnings/
│   │
│   ├── data/
│   │   ├── family.json
│   │   ├── home.json
│   │   ├── providers.json
│   │   ├── calendar.json
│   │   ├── elder_care/
│   │   ├── education/
│   │   ├── health/
│   │   ├── financial/
│   │   └── meals/
│   │
│   ├── tasks/
│   │   ├── active/
│   │   ├── pending/
│   │   └── completed/
│   │
│   └── logs/
│       └── actions.log
│
└── browser-profiles/
    └── hearth/
```

---

## 12. Source Code Modifications

### Required Clawdbot Enhancements

#### 12.1 Approval Persistence System

**File:** `src/approvals/allowlist.ts`

```typescript
interface AllowlistRule {
  id: string;
  action: string;
  conditions: Record<string, any>;
  decision: 'allow' | 'deny' | 'ask';
  createdAt: string;
  expiresAt?: string;
}

class AllowlistManager {
  async checkAllowlist(action: string, context: any): Promise<'allow' | 'deny' | 'ask'> {
    const rules = await this.loadRules();
    const matchingRule = rules.find(r => this.matchesRule(r, action, context));
    return matchingRule?.decision ?? 'ask';
  }

  async addRule(rule: AllowlistRule): Promise<void> {
    // Persist to ~/clawd/homeos/memory/preferences/allowlist.json
  }

  async promptAndRemember(action: string, context: any): Promise<boolean> {
    const approved = await this.promptUser(action, context);
    if (approved) {
      const shouldRemember = await this.askRemember();
      if (shouldRemember) {
        await this.addRule({ action, conditions: context, decision: 'allow' });
      }
    }
    return approved;
  }
}
```

#### 12.2 Multi-Agent Orchestration

**File:** `src/agents/orchestrator.ts`

```typescript
class AgentOrchestrator {
  async runParallel(tasks: Task[]): Promise<Results[]> {
    // Run independent tasks in parallel
    // Merge results
    // Handle partial failures
  }

  async runSequence(tasks: Task[]): Promise<Result> {
    // Run tasks in sequence
    // Pass context between tasks
    // Support rollback on failure
  }

  async delegate(task: Task, agentId: string): Promise<Result> {
    // Delegate to specialized agent (e.g., elder-care agent)
  }
}
```

#### 12.3 Preference Learning

**File:** `src/memory/preferences.ts`

```typescript
class PreferenceEngine {
  async learn(interaction: Interaction): Promise<void> {
    // Extract implicit preferences from interaction
    // Update preference model
  }

  async predict(context: Context): Promise<Preferences> {
    // Predict user preferences for current context
  }

  async applyDefaults(request: Request): Promise<Request> {
    // Apply learned preferences to request
  }
}
```

---

## 13. External Service Integrations

### 13.1 Required API Keys

| Service | Purpose | Env Variable |
|---------|---------|---------------|
| Anthropic | AI model | `ANTHROPIC_API_KEY` |
| ElevenLabs | Voice TTS | `ELEVENLABS_API_KEY` |
| Twilio | Phone calls | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` |
| Google | Calendar, Classroom, Gmail | OAuth credentials |
| Plaid | Banking (optional) | `PLAID_CLIENT_ID`, `PLAID_SECRET` |
| OpenTable | Reservations | `OPENTABLE_API_KEY` |

### 13.2 OAuth Setup

```bash
# Google OAuth for Classroom/Calendar/Gmail
clawdbot oauth google --scopes classroom.readonly,calendar.readonly,gmail.readonly

# Apple Calendar (uses EventKit, no OAuth needed)
# Requires macOS permission grant
```

### 13.3 MCP Server Integrations

```json
{
  "mcp": {
    "servers": [
      {
        "name": "filesystem",
        "command": "npx",
        "args": ["-y", "@anthropic/mcp-server-filesystem", "~/clawd"]
      },
      {
        "name": "google-calendar",
        "command": "npx",
        "args": ["-y", "@anthropic/mcp-server-google-calendar"]
      },
      {
        "name": "brave-search",
        "command": "npx",
        "args": ["-y", "@anthropic/mcp-server-brave-search"]
      }
    ]
  }
}
```

---

## 14. Hearth-Specific Gateway Protocol Extensions

### Custom WebSocket Methods

```typescript
// Family state query
{
  "method": "hearth.family.status",
  "params": {}
}
// Returns: { members: [...], alerts: [...], nextEvents: [...] }

// Elder care quick actions
{
  "method": "hearth.elder.callNow",
  "params": { "elderId": "rose", "type": "checkin" }
}

// Proactive suggestion query
{
  "method": "hearth.suggestions.get",
  "params": { "context": "evening", "limit": 3 }
}

// Approval submission
{
  "method": "hearth.approval.respond",
  "params": { 
    "approvalId": "abc123", 
    "decision": "allow",
    "remember": true
  }
}
```

---

## 15. Testing Configuration

```json
{
  "testing": {
    "mockProviders": {
      "telephony": true,
      "payments": true
    },
    "testFamily": {
      "members": [
        { "name": "Test Parent", "role": "parent" },
        { "name": "Test Child", "role": "child", "age": 10 },
        { "name": "Test Elder", "role": "elder" }
      ]
    },
    "scenarios": [
      "morning-briefing",
      "elder-checkin",
      "homework-alert",
      "bill-detection",
      "emergency-response"
    ]
  }
}
```

---

*This integration guide should be updated as Clawdbot evolves and new capabilities are added.*
