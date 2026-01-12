# Hearth: Design Principles

This document establishes the design philosophy for Hearth, inspired by Apple's Human Interface Guidelines and the unique needs of family management.

---

## Core Design Philosophy

### "Technology that brings families closer, not closer to technology."

Hearth exists to reduce the burden of family management so parents can be more present with their families. Every design decision should be evaluated against this goal.

---

## The Five Principles

### 1. Invisible Until Helpful

> The best interface is one you don't notice until you need it.

Hearth should feel like a thoughtful family member who anticipates needs without demanding attention. It should never feel like "another app to manage."

**Do:**
- Live quietly in the menu bar
- Surface information proactively at the right moment
- Use subtle indicators (dots, badges) rather than intrusive alerts
- Fade into background when not needed

**Don't:**
- Interrupt with unnecessary notifications
- Require regular "check-ins" with the app
- Make users feel guilty for not engaging
- Add cognitive load to reduce cognitive load

**Example:**
> "Soccer tomorrow" appears 12 hours before, not as a popup but as a gentle item in the menu bar dropdown. No action required unless the user wants to see the packing checklist.

---

### 2. Propose, Don't Ask

> Reduce cognitive load by offering specific suggestions rather than open-ended questions.

Every time Hearth asks an open question, it's asking the user to think. The goal is to do the thinking *for* them.

**Do:**
- "Dinner tonight: Tacos, stir-fry, or pasta?"
- "Remind Emma about homework at 4pm?"
- "Grandma called - she sounded great today."

**Don't:**
- "What would you like for dinner?"
- "When should I remind Emma?"
- "How are you feeling about your mother's health?"

**The One-Tap Rule:**
Most interactions should be completable with a single tap/click. If it takes more than 3 interactions, simplify.

---

### 3. Warmth Without Cuteness

> The personality should be warm and supportive, but never infantilizing or cartoonish.

Hearth helps with serious family matters - health, education, caring for elders. The tone should reflect that weight while remaining approachable.

**Tone Spectrum:**
```
❌ Clinical       ❌ Cutesy        ✅ Warm
"Medication       "Yay! Grandma   "Mom's doing well.
reminder sent."   is A-OK! 🎉"    She mentioned her
                                  garden is blooming."
```

**Voice Characteristics:**
- Conversational but not overly casual
- Encouraging without being patronizing
- Direct and clear, never verbose
- Empathetic without being dramatic

**Examples:**

| Situation | Don't Say | Do Say |
|-----------|-----------|--------|
| Task complete | "Awesome job! 🌟" | "All set." |
| Missed call | "Uh oh! Grandma didn't pick up! 😟" | "Couldn't reach Mom. Try again in 30 min?" |
| Reminder | "Hey there! Don't forget!!!" | "Emma: Math homework due tomorrow" |
| Success | "AMAZING! You're crushing it!" | "Good week - all check-ins completed." |

---

### 4. Respect User Agency

> Always give users control. Never take actions without appropriate confirmation.

Users trust Hearth with sensitive family information and real-world actions (phone calls, messages). That trust must be earned and protected.

**Risk Classification:**

| Level | Actions | Confirmation |
|-------|---------|---------------|
| **Low** | Read calendar, generate suggestions | None |
| **Medium** | Save preferences, set reminders | Ask once, remember |
| **High** | Phone calls, send messages, spend money | Always confirm |

**Confirmation Design:**

```
┌───────────────────────────────────┐
│  📞 Call Grandma Rose?           │
│                                   │
│  Morning check-in scheduled for   │
│  9:00 AM.                         │
│                                   │
│  [Not Today]    [Call Now]        │
└───────────────────────────────────┘
```

**Never:**
- Auto-send messages without review
- Make calls without explicit "go" signal
- Share data with external services silently
- Remove user's ability to intervene

---

### 5. Family-First Privacy

> Families trust Hearth with intimate details. Honor that trust absolutely.

Family data is sensitive: children's information, elder health details, daily routines. This is not data to be monetized or shared.

**Privacy Principles:**

1. **Local by Default** - All data stored on device unless user opts into sync
2. **Transparent Processing** - Clear indicators when AI is processing
3. **Minimal Collection** - Only gather what's needed for the feature
4. **Easy Exit** - Export all data, delete completely, anytime
5. **No Monetization** - Family data is never sold, shared, or used for ads

**Transparency UI:**

```
┌───────────────────────────────────┐
│  🔒 Your Data                      │
├───────────────────────────────────┤
│  ☉ Family profiles    Local only  │
│  ☉ Calendar cache     Local only  │
│  ☉ Elder care logs    Local only  │
│  ☉ Conversation AI    Processed*  │
│                                   │
│  * Sent to AI provider for        │
│    processing, not stored.        │
│                                   │
│  [Export Data]  [Delete All]      │
└───────────────────────────────────┘
```

---

## Visual Design Guidelines

### Colors

| Role | Color | Usage |
|------|-------|-------|
| **Primary** | Warm Orange `#F5A623` | Hearth icon, primary actions |
| **Background** | System (adaptive) | Follows macOS light/dark |
| **Text** | System (adaptive) | High contrast, readable |
| **Success** | Green `#4CAF50` | Completed items, positive status |
| **Attention** | Amber `#FFC107` | Needs review, warnings |
| **Urgent** | Red `#F44336` | Immediate action needed |

### Typography

- **System Font (SF Pro)** - Native macOS feel
- **Sizes:** Follow Apple's Dynamic Type recommendations
- **Weight:** Regular for body, Semibold for emphasis

### Iconography

- Use SF Symbols for consistency with macOS
- Family members can have photo avatars or emoji
- Status indicators use simple dots/badges

### Motion

- **Subtle and purposeful** - Never gratuitous animation
- **Fast** - Under 300ms for most transitions
- **Natural** - Follow Apple's spring animations

---

## Notification Philosophy

### The Notification Hierarchy

```
1. URGENT (Interrupt)     → System alert, sound
   "Grandma didn't answer check-in call"

2. IMPORTANT (Surface)    → Banner notification
   "Emma has homework due tomorrow"

3. INFORMATIVE (Queue)    → Menu bar badge only
   "Weekly meal plan ready"

4. AMBIENT (Passive)      → Visible when app opened
   "Morning briefing ready"
```

### Notification Rules

1. **Batch when possible** - Group related notifications
2. **Time appropriately** - Respect quiet hours
3. **Earn attention** - Every notification should be genuinely useful
4. **Allow granular control** - Users can disable specific types

---

## Accessibility

### Requirements

- Full VoiceOver support
- Keyboard navigation for all features
- Support for Dynamic Type
- Sufficient color contrast (WCAG AA minimum)
- Reduced motion option

### Design for All

- Clear, readable fonts at all sizes
- Don't rely on color alone for meaning
- Provide text alternatives for images
- Test with actual assistive technologies

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Instead Do |
|--------------|--------------|------------|
| Dark patterns | Erodes trust | Be transparent |
| Gamification | Trivializes family care | Acknowledge completion simply |
| Streaks/scores | Creates anxiety | Focus on outcomes |
| Social comparison | Families aren't competing | Private by default |
| Upselling | Exploits family needs | Sustainable pricing |
| Notification spam | Creates resistance | Earn every notification |

---

*Design principles should be revisited quarterly and updated based on user feedback.*
