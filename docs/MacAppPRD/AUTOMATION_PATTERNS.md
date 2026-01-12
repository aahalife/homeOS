# Hearth: Automation Patterns

> How Hearth automates family tasks relentlessly while respecting user agency.

---

## Core Philosophy

**"Automate everything possible, ask permission thoughtfully, remember preferences forever."**

Hearth aims to reduce mental load by automating tasks. But automation must be:
- **Trustworthy** - Never surprise the user negatively
- **Learnable** - Get smarter over time
- **Controllable** - Easy to adjust or disable
- **Transparent** - Clear about what it's doing

---

## 1. The Allowlist System

### Permission Levels

```
┌─────────────────────────────────────────────────┐
│  ALWAYS ALLOW                                   │
│  (No confirmation needed)                       │
│                                                 │
│  • Read calendar                               │
│  • Check weather                               │
│  • Generate suggestions                        │
│  • Search information                          │
│  • Read stored preferences                     │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  ASK ONCE, REMEMBER                             │
│  (Confirm first time, then auto-allow)          │
│                                                 │
│  • Save preferences                            │
│  • Set reminders                               │
│  • Send notifications to family                │
│  • Sync with external services                 │
│  • Schedule recurring tasks                    │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  ALWAYS ASK (can upgrade to auto-allow)         │
│  (Explicit confirmation each time OR upgrade)   │
│                                                 │
│  • Phone calls (elder check-ins)               │
│  • Send messages on user's behalf              │
│  • Book reservations                           │
│  • Fill out forms                              │
│  • Sign up for services                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│  ALWAYS ASK (cannot auto-allow)                 │
│  (Must confirm every time - no exceptions)      │
│                                                 │
│  • Financial transactions > $100               │
│  • Sharing personal information externally     │
│  • Canceling services/subscriptions            │
│  • Medical-related actions                     │
│  • Emergency contacts                          │
└─────────────────────────────────────────────────┘
```

### "Don't Ask Again" Flow

```
┌─────────────────────────────────────────┐
│  📞 Call Grandma Rose?                   │
│                                         │
│  Morning check-in call scheduled for    │
│  9:00 AM.                               │
│                                         │
│  [ ] Always allow morning calls to Rose │
│                                         │
│  [Not Now]              [Call]          │
└─────────────────────────────────────────┘
```

If user checks "Always allow" and clicks "Call":
- Rule added to allowlist
- Future 9 AM calls to Rose happen automatically
- User can revoke in Settings anytime

---

## 2. Ralph Wiggum Error Recovery

### The Loop Pattern

When a task fails, Hearth doesn't give up. It loops with intelligence:

```
┌─────────────┐
│  Start Task  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Execute    │
└──────┬──────┘
       │
       ▼
   Success? ─── Yes ───▶ Done ✓
       │
       No
       │
       ▼
┌─────────────────┐
│  Analyze Error │
└────────┬────────┘
        │
        ▼
  Retries < Max?
   │         │
  Yes        No
   │         │
   ▼         ▼
┌─────────┐  ┌─────────────┐
│ Try Alt  │  │ Escalate to │
│ Approach │  │    User     │
└────┬────┘  └─────────────┘
     │
     └─────▶ (back to Execute)
```

### Example: Bill Payment Automation

```
Task: Pay electric bill

Attempt 1: Auto-pay via saved method
  ✗ Failed: Card expired

Attempt 2: Try backup payment method
  ✗ Failed: No backup configured

Attempt 3: Navigate to utility website, use browser automation
  ✗ Failed: Website changed layout

Attempt 4: AI analyzes new layout, adapts approach
  ✓ Success: Bill paid

Learning: Save new website layout pattern for future
```

---

## 3. Proactive Automation Examples

### 3.1 Bill Detection & Payment

```
┌─────────────────┐
│ Email Arrives  │
└────────┬────────┘
        │
        ▼
┌─────────────────┐
│ Parse for Bill │
│ Indicators     │
└────────┬────────┘
        │
        ▼
   Is it a bill?
   │         │
  Yes        No → Ignore
   │
   ▼
┌─────────────────┐
│ Extract:       │
│ - Amount       │
│ - Due date     │
│ - Payee        │
│ - Account #    │
└────────┬────────┘
        │
        ▼
   Known biller?
   │         │
  Yes        No
   │         │
   │         ▼
   │    ┌─────────────────┐
   │    │ Verify against │
   │    │ past payments  │
   │    └────────┬────────┘
   │            │
   │            ▼
   │      Legitimate?
   │      │         │
   │     Yes        No → Flag as potential spam
   │      │
   └──────┴───────▼
        ┌─────────────────┐
        │ Compare to     │
        │ historical avg │
        └────────┬────────┘
                │
                ▼
         Unusual amount?
          │         │
         Yes        No
          │         │
          ▼         ▼
     Alert user    Auto-pay allowed?
                    │         │
                   Yes        No
                    │         │
                    ▼         ▼
                Pay auto   Schedule reminder
```

### 3.2 School Form Automation

```
1. Email detected from school
2. Parse email for form/permission slip
3. Extract form requirements
4. Check if similar form filled before
5. If yes: Pre-fill with known info
6. If no: Gather required info
7. Navigate to form URL (browser automation)
8. Fill form fields
9. Show preview to user
10. If "always allow school forms": Submit
11. Else: Request approval
12. Submit and capture confirmation
13. Store in document vault
14. Update calendar if event-related
```

### 3.3 Service Signup Automation

```
User: "Sign up for Instacart so we can get grocery delivery"

Hearth:
1. Navigate to instacart.com
2. Click "Sign Up"
3. Fill email (from family profile)
4. Generate secure password, save to keychain
5. Complete phone verification (if needed, prompt user)
6. Fill address from home profile
7. Skip payment for now OR add if user approves
8. Capture confirmation
9. Add to connected services list
10. Test with a sample search

"Done! Instacart is set up. Want to add a payment method 
or do that later?"
```

---

## 4. Parallel Task Execution

Hearth runs independent tasks simultaneously:

```
Morning Briefing Generation:

┌─────────────────────────────────────────┐
│  Parallel Fetch (simultaneous)            │
│                                           │
│  [Weather API]  [Calendar]  [Email]       │
│       │             │          │          │
│       │             │          │          │
│  [LMS Sync]    [Elder Status] [Bills]     │
│       │             │          │          │
└───────┴─────────────┴──────────┴────────┘
                       │
                       ▼
              ┌───────────────┐
              │   Aggregate   │
              │   & Prioritize│
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │   Generate    │
              │   Briefing    │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │   Deliver     │
              └───────────────┘
```

---

## 5. Multi-Channel Coordination

### Channel Selection Logic

```
For each family member, determine best channel:

1. Check stated preference (explicit)
2. Check historical response rates (learned)
3. Consider urgency level
4. Consider time of day
5. Fall back to default

Example routing:

- Dad at work: Slack DM (fast response)
- Mom working from home: Mac notification
- Emma at school: Queue for after 3pm, then iMessage
- Jack: Parent relay (too young for direct)
- Grandma Rose: Phone call only
```

### Escalation Pattern

```
Urgent message to Dad:

1. Mac notification (if online)
   └─ Wait 2 min
2. iMessage
   └─ Wait 5 min
3. Slack DM
   └─ Wait 5 min
4. Phone call (if truly urgent)
   └─ Leave voicemail
5. Notify Mom as backup
```

---

## 6. Preference Learning

### Implicit Learning

Hearth observes and learns without asking:

| Observation | Learned Preference |
|-------------|--------------------|
| User always picks tacos on Tuesday | Tuesday = Taco preference |
| User ignores 7am notifications | Adjust quiet hours to 7:30am |
| User snoozes homework reminders | Try earlier reminders |
| User clicks "call now" immediately | Can auto-approve elder calls |

### Explicit Confirmation

When confidence is high, confirm:

```
"I've noticed you usually prefer tacos on Tuesdays. 
Want me to always suggest that first?"

[Yes, remember this]  [No, keep asking]
```

---

*Automation should feel like magic, not machinery.*
