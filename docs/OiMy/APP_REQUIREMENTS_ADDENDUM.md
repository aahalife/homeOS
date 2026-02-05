# OiMy iOS App — Requirements Addendum

This document extends the [Clawd Home Platform PRD](../IosPRD/PRD.md) with requirements for the OiMy adaptive learning system, personality layer, and on-device intelligence capabilities.

---

## 1. Adaptive Learning Features

### 1.1 User Feedback UI
| Requirement | Description | Priority |
| --- | --- | --- |
| Thumbs up/down | Display thumbs up/down buttons on every AI response bubble | **P0** |
| Try harder button | "Try harder" button to explicitly request cloud escalation | **P1** |
| Cloud indicator | Subtle badge/icon when cloud LLM is being used (e.g., small cloud icon) | **P0** |
| Learning indicator | "OiMy is learning..." animated indicator when skill creation is happening | **P1** |

### 1.2 Cloud Escalation Flow
| Requirement | Description | Priority |
| --- | --- | --- |
| Thumbs down prompt | User gives thumbs down → show "Want me to try a different approach?" prompt | **P0** |
| Opt-in consent | Opt-in consent for cloud processing (one-time or per-request setting in preferences) | **P0** |
| Data transparency | Clear indication of what data goes to cloud before sending (modal or expandable detail) | **P0** |
| Response attribution | "Powered by Claude" attribution badge when cloud model generates response | **P1** |

### 1.3 Learning Dashboard (Settings)
| Requirement | Description | Priority |
| --- | --- | --- |
| Skills learned | "What OiMy has learned" section showing list of new skills with descriptions | **P1** |
| Skill toggles | Toggle to enable/disable individual learned behaviors | **P1** |
| Teach OiMy | "Teach OiMy" manual input for power users to add custom instructions | **P2** |
| Privacy controls | Delete learning history button, opt-out of cloud toggle, data retention info | **P0** |

---

## 2. Model Configuration

### 2.1 On-Device Models
| Requirement | Description | Priority |
| --- | --- | --- |
| Gemma 3n | Primary conversational model for all on-device generation | **P0** |
| FunctionGemma | Fine-tuned model for intent classification and tool/function calling | **P0** |
| Model delivery | Model files bundled with app OR downloaded on first launch (user choice) | **P0** |
| Background updates | Background model updates with user opt-in (Wi-Fi only, BGAppRefreshTask) | **P2** |

### 2.2 Cloud Models
| Requirement | Description | Priority |
| --- | --- | --- |
| Sonnet 4.5 | Standard escalations, simple skill creation, routine cloud tasks | **P0** |
| Opus 4.5 | Complex reasoning, multi-skill orchestration, skill distillation | **P1** |
| API key storage | API key stored securely in iOS Keychain | **P0** |
| Usage tracking | Track cloud API usage with optional spending limits and alerts | **P1** |

---

## 3. Personality & Voice

### 3.1 OiMy's Character
| Requirement | Description | Priority |
| --- | --- | --- |
| Name | OiMy (pronounced "Oh-My") — used consistently in UI and responses | **P0** |
| Personality | Warm, caring, occasionally playful, never robotic or corporate | **P0** |
| Contextual tone | Adapts tone to context (more serious for health/safety, lighter for activities/games) | **P1** |
| Emoji usage | Uses emoji naturally but not excessively (1-2 per message max) | **P1** |
| Name memory | Remembers and uses family members' names in responses | **P0** |

### 3.2 Writing Style Guidelines
| Requirement | Description | Priority |
| --- | --- | --- |
| Concise | Busy parents don't have time for essays — keep responses short and actionable | **P0** |
| Active voice | Use active voice, conversational tone throughout | **P1** |
| No jargon | Avoid jargon, corporate speak, and technical terms | **P1** |
| Emotion first | Acknowledge emotions before jumping to solutions | **P1** |
| Celebrate wins | Celebrate habit streaks, completed tasks, and family achievements | **P2** |

---

## 4. Enhanced Skill Execution

### 4.1 Skill Confidence Display
| Requirement | Description | Priority |
| --- | --- | --- |
| Debug confidence | Show confidence level for skill routing (optional, in debug/developer mode) | **P2** |
| Low confidence prompt | "I'm not sure I understood — did you mean X or Y?" for confidence < threshold | **P1** |

### 4.2 Multi-Skill Flows
| Requirement | Description | Priority |
| --- | --- | --- |
| Flow indicator | Visual flow indicator for complex multi-step tasks (e.g., progress stepper) | **P1** |
| Plan preview | "Here's my plan: 1) X, 2) Y, 3) Z — sound good?" before executing complex flows | **P1** |
| Plan modification | Allow user to modify/reorder plan before execution | **P2** |

### 4.3 Proactive Suggestions
| Requirement | Description | Priority |
| --- | --- | --- |
| Morning briefing | Morning briefing notification at configurable time (default 7:00 AM) | **P0** |
| Contextual suggestions | "You might want to..." suggestions based on calendar, location, time, patterns | **P1** |
| Quiet hours | Respect quiet hours — no proactive messages during configured sleep window | **P0** |

---

## 5. Data & Privacy

### 5.1 On-Device First
| Requirement | Description | Priority |
| --- | --- | --- |
| Local storage default | All family data stored locally by default (Core Data / SwiftData) | **P0** |
| Cloud opt-in only | Cloud only used when user explicitly opts in per-request or in settings | **P0** |
| No silent telemetry | No telemetry, analytics, or crash reporting without explicit consent | **P0** |

### 5.2 Learning Data
| Requirement | Description | Priority |
| --- | --- | --- |
| Local escalation logs | Escalation logs (what was sent to cloud, responses) stored locally | **P0** |
| On-device fine-tuning | Fine-tuning data stays on device unless user explicitly shares | **P0** |
| Retention policies | Clear data retention policies displayed in Settings > Privacy | **P1** |

---

## 6. Technical Requirements

### 6.1 Model Performance
| Metric | Target | Priority |
| --- | --- | --- |
| Intent classification | < 200ms | **P0** |
| Simple generation | < 1s | **P0** |
| Complex generation | < 3s | **P0** |
| Cloud escalation | < 10s (with loading indicator) | **P0** |

### 6.2 Storage
| Component | Size | Priority |
| --- | --- | --- |
| Skill files | ~5MB | **P0** |
| Gemma 3n model | ~2GB | **P0** |
| FunctionGemma model | ~500MB | **P0** |
| Learning data | Grows over time, user can clear via Settings | **P1** |

### 6.3 Background Tasks
| Task | Implementation | Priority |
| --- | --- | --- |
| Morning briefing prep | BGProcessingTask scheduled overnight | **P0** |
| Medication reminders | Local notifications via UNUserNotificationCenter | **P0** |
| Model updates | BGAppRefreshTask, Wi-Fi only, user opt-in | **P2** |

---

## 7. Accessibility

| Requirement | Description | Priority |
| --- | --- | --- |
| VoiceOver | Full VoiceOver support for all UI elements including feedback buttons | **P0** |
| Dynamic Type | Support Dynamic Type for all text (test at largest sizes) | **P0** |
| High contrast | Support iOS high contrast mode / increased contrast setting | **P1** |
| Reduce motion | Reduce motion option to disable animations (respect system setting) | **P1** |

---

## 8. Testing Requirements

### 8.1 Model Testing
| Requirement | Description | Priority |
| --- | --- | --- |
| Prompt regression | Prompt regression tests for all few-shot examples in CI/CD | **P0** |
| Intent accuracy | Intent classification accuracy: > 95% on curated test set | **P0** |
| Function accuracy | Function calling accuracy: > 90% on curated test set | **P0** |

### 8.2 Learning Pipeline Testing
| Requirement | Description | Priority |
| --- | --- | --- |
| E2E escalation | End-to-end escalation flow test (thumbs down → cloud → response) | **P0** |
| Skill creation | Skill creation pipeline test (cloud creates skill → skill saved locally) | **P1** |
| Distillation validation | Distillation quality validation (cloud skill → on-device execution match) | **P1** |

---

## Priority Summary

| Priority | Count | Description |
| --- | --- | --- |
| **P0** | 31 | Must-have for MVP — core functionality, privacy, accessibility basics |
| **P1** | 18 | Should-have — enhanced UX, polish, secondary features |
| **P2** | 7 | Nice-to-have — power user features, optimizations |

---

## Integration with Existing PRD

This addendum integrates with the base PRD as follows:

- **Section 5.3 (Clients)**: iOS app now includes adaptive learning UI components
- **Section 5.6 (Memory & Personalization)**: Extended with on-device learning and skill storage
- **Section 6 (Non-Functional)**: Performance targets refined for on-device inference
- **Section 7 (Integrations)**: Cloud models (Claude Sonnet/Opus) added as escalation path

The OiMy personality layer wraps all user-facing interactions while maintaining compatibility with the underlying Clawdbot infrastructure and workflow orchestration described in the [System Architecture](../IosPRD/SYSTEM_ARCHITECTURE.md).
