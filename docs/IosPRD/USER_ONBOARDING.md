# Clawd Home Platform – User Onboarding Playbook

## 1. Phases
1. **Marketing Site → Signup** – choose Home Hub vs Managed Cloud, collect email, basic household info.
2. **Provisioning & Payment** – run automation, confirm readiness.
3. **Personal Setup** – via iOS app onboarding wizard.
4. **Family Invitations** – invite co-parents, teens, caregivers.
5. **Workflow Activation** – enable initial packs, confirm automations.

## 2. Messaging & Scripts
### Welcome Email (post-purchase)
Subject: “Your Clawd Home assistant is spinning up 🛠️”
```
Hi <Name>,

We’re preparing your family’s private Clawd Home environment.

Next steps:
1. Install the Clawd Home iOS app (TestFlight link).
2. Use invite code <CODE> to sign in.
3. Have your phone ready for Telegram + Twilio confirmation texts.

We’ll notify you once provisioning completes (≈10 minutes).
```

### Ready Notification
Push/Email:
```
🎉 Your Clawd Home assistant is live!
- Telegram bot: @<family_bot>
- Voice/SMS: +1 (555) 000-0000
- Dashboard: https://app.clawdhome.com/login
Tap to continue setup.
```

## 3. iOS App Onboarding Flow
1. **Sign-In** – email + magic link (passwordless) or device SSO.
2. **Household Basics**
   - Family name, household location, time zone.
   - “Who lives here?” quick add (names, roles).
3. **Permissions & Consents**
   - Notifications, location (for geofence automations), HealthKit (optional), contacts (optional).
4. **Channel Linking**
   - Telegram: present QR/invite code.
   - SMS/Voice: ask for primary phone numbers, send verification code.
5. **Integration Setup**
   - Step-by-step cards: Google, Microsoft, Home Assistant, Tesla, Notion, etc.
   - Each card shows benefits, estimated time, data access, grant button.
6. **Workflow Pack Selection**
   - Show curated list (Morning Launch, School Ops, Elder Care, etc.) with toggles.
   - Selecting pack kicks off data collection mini-forms (e.g., “Which kids have activities?”).
7. **Consent & Guardrails**
   - Explain risk tiers; ask for default rules (e.g., “Auto-approve grocery orders under $75”).
8. **Final Checklist**
   - Confirm morning briefing time, quiet hours, emergency contacts.
   - Offer to schedule first “Family orientation” call with Clawd (optional Twilio call).

## 4. Family Invitations
- Admin can send invites from app/web (email, SMS, copy link).
- Invite flow sets member role, contact info, allowed channels.
- For teens/kids: require guardian approval, configure privacy (no access to finances, etc.).
- Caregiver/Grandparent invites default to voice/SMS, optional simplified app mode.

## 5. Activation & Education
- In-app checklist “First Week with Clawd”:
  1. Send first message.
  2. Enable morning brief.
  3. Add school calendar.
  4. Configure elder-care check-in (if needed).
  5. Try one automation pack.
- Tooltips and short Loom-style videos embedded.
- “Ask Clawd to...” suggestions carousel.

## 6. Support Touchpoints
- Live chat or email escalation (support@clawdhome.com) accessible from settings.
- “Report issue” button attaches logs + context.
- Scheduled success calls (optional) after 14 days to review automation coverage.

## 7. Offboarding / Cancellation
- Provide self-service cancellation button.
- Outline data deletion timeline (default immediate for home hub, 30 days retain for cloud unless opted otherwise).
- Offer export of memories, tasks, and audit logs.

