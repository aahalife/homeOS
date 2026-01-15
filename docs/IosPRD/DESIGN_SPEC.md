# Clawd Home Platform – Design Specification

## 1. Design Principles
- **Apple-grade minimalism** – clean typography (SF Pro), generous spacing, tactile micro-interactions.
- **Progressive disclosure** – simple home surface, advanced controls tucked into Settings → Advanced.
- **Contextual consent** – banners modally appear only when required; low-risk actions silently happen.
- **Warm concierge tone** – Clawd speaks like a calm, capable in-house coordinator.

## 2. Information Architecture
| Surface | Description |
| --- | --- |
| Home | Today view + key alerts; “Ask Clawd” input; quick actions. |
| Chat | Ongoing conversations; thread list per family member. |
| Automations | Workflow packs gallery + status; editing interface. |
| Inbox | Notifications needing attention (approvals, errors). |
| Settings | Household, members, integrations, devices, preferences, advanced. |

## 3. Key Flows
### 3.1 Home Screen
- Header: “Good morning, <Name>” + weather icon.
- Cards: Morning Brief, Upcoming Events, Open Tasks, Automation Health.
- Floating “+” for quick add (reminder, event, note).
- “Ask Clawd” composer anchored at bottom with voice button.

### 3.2 Automation Pack Activation
1. Tap Automations → select pack (e.g., School Ops).
2. Detail sheet: goal, requirements, included skills, toggles per recipe.
3. “Configure” wizard collects specifics (kids, schedules, preferences).
4. Confirmation screen summarizing triggers + outputs, ability to run test.

### 3.3 Approval Flow
- Push notification previewing action.
- In-app sheet: intent summary, context (who asked, relevant thread), risk badge, rollback plan.
- Buttons: Approve, Deny, Ask Clawd (for clarification).
- Option to “Remember for future” for medium risk.

### 3.4 Member Management
- List with avatars, roles, channel icons.
- Tap member → detail: contact info, permissions, quiet hours, notification tier, automation participation.

### 3.5 Error Handling
- Non-blocking toast for auto-resolved issues.
- Inbox cards for unresolved errors with recommended fix button (“Reconnect Google Calendar”).

## 4. Visual Components
- **Typography**: SF Pro Display (titles), SF Pro Text (body). Sizes: Title 24/32, Body 17, Caption 13.
- **Color Palette**: Soft neutrals (background #F5F5F7), accent colors per domain (Family blue, School purple, Health teal, Home orange).
- **Iconography**: SF Symbols; custom illustration set for major workflows.
- **Buttons**: Rounded rect, subtle shadows. Primary (filled accent), secondary (outline), tertiary text buttons.

## 5. Interaction Patterns
- Haptic taps for approvals, toggles.
- Pull to refresh on Home/Chat.
- Swipe actions on notifications (Done, Snooze, Escalate).
- Drag-and-drop ordering for automation steps (power user mode).

## 6. Accessibility
- Support Dynamic Type up to XL.
- VoiceOver labels for status cards.
- High-contrast mode toggles accent colors.
- Motion-reduced mode disables large transitions.

## 7. Web Dashboard Variations
- Responsive layout, maintain same IA.
- Left navigation (Home, Chat, Automations, Members, Health, Settings).
- Additional admin widgets: service health graphs, workflow logs.

## 8. Components Library
| Component | Description |
| --- | --- |
| Status Card | Title, value, pill indicator, optional CTA |
| Automation Tile | Icon, description, toggle, status dot |
| Approval Sheet | Title, summary, detail accordion, action buttons |
| Member Row | Avatar, role chip, channel icons |
| Workflow Timeline | Step list w/ statuses |
| Notification Inbox Item | Title, severity, action buttons |
| Chat Bubble | Support markdown, attachments, voice memos |

## 9. States to Consider
- Empty states (no workflows, no approvals) with educational prompts.
- Offline mode (Home Hub offline) – show banner, limited functionality.
- Multi-user conversation indicator (per member color chips).

## 10. Assets & Deliverables
- Figma file with component library + page templates.
- Motion specs for approval sheet + automation toggles.
- Voice & tone guide (ties into SOUL doc) for microcopy.

