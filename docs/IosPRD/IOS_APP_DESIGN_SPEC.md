 # HomeOS iOS App Design Specification
 
 This document defines the full iOS/iPad user experience, screen-by-screen requirements, UI elements, and behaviors. It is split into **MVP** and **V1** specs:
 
 - **MVP**: Functionality-first, clean, minimal, modern Apple-style UI.
 - **V1**: Adds delight with motion, shaders, audio, and refined interactions.
 
 The goal is to provide a complete spec that a designer or design tool can use to generate production-ready screens, and that engineers can implement with fidelity.
 
 ---
 
 ## 1. Design Principles
 
 ### MVP Principles
 - Functionality over flourish; every element earns its place.
 - Clear information hierarchy; cognitive load stays low.
 - Warm, calm, capable tone; never loud or intrusive.
 - Accessible to all family members (ages 8-80).
 - Consistent spacing, typography, and control styles.
 - Fast, responsive UI with minimal friction.
 
 ### V1 Enhancement Principles
 - Subtle micro-interactions that communicate state.
 - Natural motion with spring physics.
 - Metal shader effects used sparingly for premium polish.
 - Audio feedback that is optional and never distracting.
 - Haptics paired with important actions.
 
 ---
 
 ## 2. Navigation Architecture
 
 ### iPhone (Primary)
 Tab bar with 5 destinations:
 
 | Tab | SF Symbol | Label | Badge |
 | --- | --- | --- | --- |
 | Home | `house.fill` | Home | None |
 | Chat | `bubble.left.and.bubble.right.fill` | Chat | Unread count |
 | Automations | `gearshape.2.fill` | Auto | None |
 | Inbox | `tray.fill` | Inbox | Pending approvals |
 | Settings | `person.crop.circle` | You | None |
 
 **MVP Behavior**
 - Standard iOS tab switching.
 - Badges reflect unread or pending items.
 - Last selected tab persists across sessions.
 
 **V1 Enhancements**
 - Subtle bounce on tab selection.
 - Adaptive blur background on tab bar.
 
 ### iPad (Split View)
 Sidebar navigation with detail panel.
 
 ```
 ┌─────────────────────────────────────────────────────────────┐
 │ Sidebar                  │ Detail                           │
 │ ┌──────────────────────┐ │ ┌─────────────────────────────┐  │
 │ │ Home                 │ │ │ Selected screen content     │  │
 │ │ Chat                 │ │ │                             │  │
 │ │ Automations          │ │ │                             │  │
 │ │ Inbox (3)            │ │ │                             │  │
 │ │ Settings             │ │ │                             │  │
 │ └──────────────────────┘ │ └─────────────────────────────┘  │
 └─────────────────────────────────────────────────────────────┘
 ```
 
 **iPad Enhancements**
 - Multi-column layouts where useful.
 - Keyboard shortcuts (Cmd+N, Cmd+/, Cmd+F).
 - Drag and drop where applicable (e.g., tasks to calendar).
 
 ---
 
## 2.1 Channel Support (MVP)

**Supported channels in MVP:**
- Push (APNs)
- SMS (via Twilio)
- Email (via OAuth provider)
- Telegram (per-family bot)

**Explicitly not supported in MVP:**
- iMessage (requires device-local relay and App Store risk)
- WhatsApp (Business API required, high compliance overhead)

V1 can revisit additional channels if compliant and reliable.

---

 ## 3. Screen Inventory
 
 ```mermaid
 flowchart TD
   subgraph OnboardingFlow [OnboardingFlow]
     Welcome --> Permissions
     Permissions --> ScanProgress
     ScanProgress --> FamilyConfirm
     FamilyConfirm --> CriticalQuestions
     CriticalQuestions --> SetupComplete
   end
 
   subgraph MainApp [MainApp]
     HomeScreen["Home_Today"]
     ChatScreen["Chat"]
     AutomationsScreen["Automations"]
     InboxScreen["Inbox"]
     SettingsScreen["Settings"]
   end
 
   subgraph Modals [Modals]
     ApprovalSheet
     QuickAdd
     WorkflowDetail
     MemberDetail
     IntegrationSetup
   end
 
   SetupComplete --> HomeScreen
   HomeScreen <--> ChatScreen
   HomeScreen <--> AutomationsScreen
   HomeScreen <--> InboxScreen
   HomeScreen <--> SettingsScreen
 ```
 
 ---
 
 ## 4. Onboarding Flow
 
 ### 4.1 Welcome Screen
 
 **Purpose:** First impression, set tone, single CTA.
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | App Icon | Image | Centered, 120pt, subtle shadow |
 | Headline | Text | "Meet Clawd", SF Pro Display, 34pt, Bold |
 | Subhead | Text | "Your family's calm, capable coordinator", 17pt |
 | Illustration | Image | Warm, abstract family scene, 280pt wide |
 | CTA | Button | "Get Started", full width, 50pt height |
 | Skip | Text Button | "I'll set up later", tertiary |
 
 **MVP Behavior**
 - Sequential fade-in (0.3s stagger).
 - Button press state (scale 0.98).
 
 **V1 Enhancements**
 - Illustration subtle breathing motion.
 - Background gradient shifts slowly (30s cycle).
 - Light haptic on CTA tap.
 
 ---
 
 ### 4.2 Permissions Screen
 
 **Purpose:** Request permissions with clear rationale.
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | Progress | Dots | 1 of 5 |
 | Title | Text | "Let Clawd understand your family", 28pt |
| Permission Cards | List | 4 core cards + 1 optional card |
 | Continue | Button | Disabled until all resolved |
 
**Permission Cards (order)**
1. Contacts (`person.2.fill`) — "Find your family members"
2. Calendar (`calendar`) — "See your schedules"
3. Location (`location.fill`) — "Know home, work, school"
4. Notifications (`bell.fill`) — "Send timely updates"
5. Photos (Optional) (`photo.on.rectangle`) — "Help recognize family members (opt-in)"
 
 **Card Layout**
 ```
 ┌─────────────────────────────────────────┐
 │ [Icon] Permission Name                  │
 │        Rationale                        │
 │                         [Allow Button]  │
 └─────────────────────────────────────────┘
 ```
 
**MVP Behavior**
- Each card has Allow/Skip.
- Tapping Allow triggers iOS permission prompt.
- Card shows granted/denied state.
- Can proceed with partial permissions.
- Photos access is explicit opt-in and never required for onboarding.
 
 **V1 Enhancements**
 - Cards slide in with spring animation.
 - Granted cards show animated checkmark.
 - Denied cards display "Enable later in Settings".
 
 ---
 
 ### 4.3 Scan Progress Screen
 
 **Purpose:** Show inference happening, build anticipation.
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | Progress | Dots | 2 of 5 |
 | Animation | Symbol | Magnifying glass / scanning motif |
 | Status Text | Text | Cycles through steps |
 | Subtext | Text | "This takes about 10 seconds" |
 
 **Status Cycle**
 - "Reading contacts..."
 - "Checking calendar..."
 - "Finding patterns..."
 - "Understanding your family..."
 
 **MVP Behavior**
 - Status changes every 2-3s.
 - Minimum display time: 5s.
 - Auto-advance when complete.
 
 **V1 Enhancements**
 - Subtle Metal ripple shader in background.
 - Floating particles (lightweight).
 - Optional ambient processing sound.
 
 ---
 
 ### 4.4 Family Confirmation Screen
 
 **Purpose:** Present inferred family, allow correction.
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | Progress | Dots | 3 of 5 |
 | Title | Text | "Here's what I found" |
 | Family Cards | List | One card per member |
 | Add Member | Button | "+ Add someone" |
 | Continue | Button | "Looks good!" |
 
 **Family Card Layout**
 ```
 ┌─────────────────────────────────────────┐
 │ [Avatar] Name                   [Edit] │
 │          Role: Parent/Child/etc         │
 │          Age: ~12 (if child)            │
 │          Source: Contacts, Calendar     │
 └─────────────────────────────────────────┘
 ```
 
 **MVP Behavior**
 - Edit expands inline.
 - Role picker and age input for children.
 - Swipe to delete member.
 - Add opens new blank card.
 
 **V1 Enhancements**
 - Smooth expansion animation.
 - Avatar subtle glow.
 - Haptic on edit actions.
 
 ---
 
 ### 4.5 Critical Questions Screen
 
 **Purpose:** Ask only what cannot be inferred (3-5 items).
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | Progress | Dots | 4 of 5 |
 | Title | Text | "A few quick questions" |
 | Question Cards | Stack | 3-5 questions |
 | Continue | Button | Enabled when all answered |
 
 **Question Specs**
 - Dietary restrictions: multi-select chips.
 - Budget threshold: slider with labels.
 - Morning brief time: time picker.
 - Quiet hours: dual time picker.
 - Emergency contact: suggested + override.
 
 **MVP Behavior**
 - Questions visible in one scroll view.
 - Defaults pre-selected.
 - Skip allowed (defaults applied).
 
 **V1 Enhancements**
 - Questions reveal sequentially.
 - Haptics at slider thresholds.
 - "Why this default?" helper.
 
 ---
 
 ### 4.6 Setup Complete Screen
 
 **Purpose:** Confirm setup, preview first value.
 
 **MVP Elements**
 | Element | Type | Spec |
 | --- | --- | --- |
 | Progress | Dots | 5 of 5 |
 | Illustration | Image | Celebration/home scene |
 | Title | Text | "You're all set!" |
 | Summary | Text | "First morning brief tomorrow at 7:00 AM" |
 | Config Summary | Bullet list | 3-4 items |
 | CTA | Button | "Go to Home" |
 
 **MVP Behavior**
 - CTA appears after 1s.
 - Single tap to Home.
 
 **V1 Enhancements**
 - Subtle confetti (2s).
 - Success haptic.
 - Soft completion chime (optional).
 
 ---
 
 ## 5. Home Screen (Today)
 
 **Purpose:** Daily command center, quick actions, glanceable status.
 
 **MVP Layout**
 ```
 ┌─────────────────────────────────────────┐
 │ Good morning, Sarah           [Profile] │
 │ Thursday, Jan 15       52F PartlyCloudy │
 ├─────────────────────────────────────────┤
 │ [TODAYS PRIORITIES]                     │
 │ - Emma: Physics lab due                 │
 │ - Jack: Soccer practice 4pm             │
 │ - Sign permission slip                  │
 ├─────────────────────────────────────────┤
 │ [FAMILY SCHEDULE]                       │
 │ 08:00 School drop-off                   │
 │ 10:00 Dad client call                   │
 │ 15:30 Emma dentist                      │
 │ 16:00 Jack soccer                       │
 │                         [See full]      │
 ├─────────────────────────────────────────┤
 │ [NEEDS ATTENTION]                       │
 │ - 1 approval pending                    │
 │ - Emma grade dropped (Physics)          │
 ├─────────────────────────────────────────┤
 │ [Ask Clawd anything...]            [Mic]│
 └─────────────────────────────────────────┘
 ```
 
 **Element Specifications**
 - **Greeting:** Dynamic based on time of day.
 - **Weather:** SF Symbol + temp + condition.
 - **Priorities Card:** 3-5 items with checkbox.
 - **Schedule Card:** timeline list; tap to event detail.
 - **Needs Attention:** top urgent items.
 - **Ask Clawd:** input field + mic button.
 
 **MVP Behavior**
 - Pull to refresh updates all cards.
 - Tap priority -> detail; check marks update status.
 - Tap schedule item -> detail sheet.
 
 **V1 Enhancements**
 - Time-of-day gradient background.
 - Animated weather icon.
 - Subtle entry animations for cards.
 - Current-time indicator on schedule.
 
 ---
 
 ## 6. Chat Screen
 
 **Purpose:** Primary conversation surface with Clawd.
 
 **MVP Elements**
 - Message list with pagination.
 - Rich cards for recipes, schedules, approvals.
 - Quick action chips above input.
 - Input bar with text + mic + send.
 
 **Message Bubble Styles**
 | Type | Style |
 | --- | --- |
 | Incoming | Left, light gray background |
 | Outgoing | Right, primary color, white text |
 
 **MVP Behavior**
 - Typing indicator when Clawd responds.
 - Tap rich card to expand.
 - Voice recording opens waveform view.
 
 **V1 Enhancements**
 - Spring animation for new messages.
 - Real-time waveform during voice input.
 - Haptic on send; optional "whoosh" sound.
 
 ---
 
 ## 7. Automations Screen
 
 **Purpose:** Browse and configure workflow packs.
 
 **MVP Sections**
 - Active packs with toggle and status.
 - Available packs with "Get" action.
 
 **MVP Behavior**
 - Toggle enables/disables pack instantly.
 - Tap card opens workflow detail sheet.
 - Run Now triggers manual execution.
 
 **V1 Enhancements**
 - Status indicator pulses while running.
 - Success/failure animation on run completion.
 
 ---
 
 ## 8. Inbox Screen
 
 **Purpose:** Approvals and important notifications.
 
 **MVP Sections**
 - Approvals (pinned at top).
 - Recent notifications.
 
 **Approval Card Elements**
 - Priority indicator.
 - Summary line.
 - Approve/Deny buttons.
 - Details link.
 
 **MVP Behavior**
 - Swipe right to quick-approve.
 - Swipe left to archive.
 - "Remember choice" stores preference.
 
 **V1 Enhancements**
 - Urgency pulse on high-priority items.
 - Confirmation animation after approval.
 
 ---
 
 ## 9. Settings Screen
 
 **Purpose:** Manage family, integrations, preferences, account.
 
 **Key Sections**
 - Family members and roles.
 - Integrations (Google, Apple, Telegram, Home Assistant).
 - Preferences (brief time, quiet hours, auto-approve thresholds).
 - Notifications.
 - Support.
- Privacy and data (Photos opt-in, data export, delete account).
 
 **MVP Behavior**
 - Standard grouped list style.
 - Integration row opens OAuth/setup.
 - All changes save automatically.
 
 **V1 Enhancements**
 - Connection status animations.
 - Haptic feedback on toggles.
 
 ---
 
 ## 10. Quick Add Modal
 
 **Purpose:** Fast entry for reminders, events, tasks, notes.
 
 **MVP Behavior**
 - Natural language parsing with preview.
 - Allows edit before saving.
 - Supports voice input (optional).
 
 **V1 Enhancements**
 - Real-time parsing preview.
 - Animated confirmation on success.
 
 ---
 
 ## 11. Error and Empty States
 
 **MVP Requirements**
 - Friendly, non-technical language.
 - Clear remediation CTA.
 - Illustrations optional.
 
 **Examples**
 - "Can't reach Clawd right now. Retry?"
 - "Calendar access needed. Open Settings."
 - "All caught up. Nothing needs your attention."
 
 ---
 
 ## 12. Motion and Animation (V1)
 
 **System Principles**
 - Spring-based motion; damped and natural.
 - Immediate response to user input.
 - Motion can be disabled for Reduce Motion.
 
 **Animation Inventory**
 | Element | Animation | Timing |
 | --- | --- | --- |
 | Screen push | Horizontal slide | 0.35s spring |
 | Modal present | Slide up | 0.4s spring |
 | Card press | Scale to 0.97 | 0.1s |
 | Toggle | Slide + bounce | 0.25s |
 | Success | Checkmark draw | 0.4s |
 | Error | Shake | 0.3s |
 
 ---
 
 ## 13. Audio (V1)
 
 **Principles**
 - Optional, respects mute switch.
 - Subtle, consistent tone family.
 
 **Sound Inventory**
 | Event | Sound |
 | --- | --- |
 | App open | Soft chime |
 | Message sent | Short whoosh |
 | Approval approved | Success tone |
 | Error | Gentle buzz |
 
 ---
 
 ## 14. Accessibility
 
 **Requirements**
 - Dynamic Type support up to accessibility sizes.
 - VoiceOver labels for all interactive elements.
 - Minimum 44pt touch targets.
 - Reduce Motion support.
 - High-contrast color variants.
 
 ---
 
 ## 15. Design Tokens
 
 ### Colors (Light Mode)
 | Token | Hex | Usage |
 | --- | --- | --- |
 | primary | #007AFF | CTAs, links |
 | background | #F2F2F7 | App background |
 | surface | #FFFFFF | Cards, sheets |
 | textPrimary | #000000 | Headings |
 | textSecondary | rgba(60,60,67,0.6) | Body text |
 | success | #34C759 | Success states |
 | warning | #FF9500 | Warnings |
 | error | #FF3B30 | Errors |
 
 ### Colors (Dark Mode)
 | Token | Hex | Usage |
 | --- | --- | --- |
 | primary | #0A84FF | CTAs, links |
 | background | #000000 | Background |
 | surface | #1C1C1E | Cards |
 | textPrimary | #FFFFFF | Headings |
 | textSecondary | rgba(235,235,245,0.6) | Body text |
 
 ### Typography (SF Pro)
 | Style | Size | Weight |
 | --- | --- | --- |
 | LargeTitle | 34pt | Bold |
 | Title1 | 28pt | Bold |
 | Title2 | 22pt | Bold |
 | Headline | 17pt | Semibold |
 | Body | 17pt | Regular |
 | Footnote | 13pt | Regular |
 
 ### Spacing
 | Token | Value |
 | --- | --- |
 | xs | 4pt |
 | sm | 8pt |
 | md | 16pt |
 | lg | 24pt |
 | xl | 32pt |
 
 ---
 
 ## 16. MVP vs V1 Summary
 
 **MVP Focus**
 - Ship full functional workflows.
 - Keep UI clean, minimal, stable.
 - Ensure accessibility and performance.
 
 **V1 Enhancements**
 - Motion polish, shader effects.
 - Audio feedback (optional).
 - Delightful micro-interactions.
 - Deeper personalization and visual identity.
