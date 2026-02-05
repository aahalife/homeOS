# OiMy — Complete Documentation for Coding Agents

> **Start here.** This folder contains everything you need to understand, extend, and build the OiMy iOS app.

---

## What is OiMy?

OiMy is a **privacy-first family assistant** that runs entirely on-device using Google's Gemma 3n model. No cloud. No data leaving the phone. Just intelligent home management that actually understands context.

### The Vision

Families juggle dozens of systems: school portals, calendars, meal planning apps, medication reminders, home maintenance schedules. OiMy unifies all of this into a single conversational interface that:

- **Routes messages intelligently** to the right skill (not a monolithic chatbot)
- **Maintains family context** (allergies, schedules, preferences)
- **Acts proactively** (homework reminders, departure alerts, medication refills)
- **Never phones home** — all inference happens on-device with Gemma 3n

---

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────────────┐
│                        User Message                                  │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 1: Intent Classification                    │
│                                                                      │
│  ┌──────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────┐│
│  │ 1. Keywords  │ → │ 2. Scoring  │ → │ 3. Gemma 3n  │ → │4. Func-││
│  │   (fast)     │   │ canHandle() │   │   classify   │   │ Gemma  ││
│  └──────────────┘   └─────────────┘   └──────────────┘   └────────┘│
│                                                                      │
│  4-step cascade: each layer catches what the previous missed         │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    ChatTurnRouter → Skill Dispatch                   │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    LAYER 2: Skill Execution                          │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  21 Skills: meal-planning, healthcare, school, telephony, ...   ││
│  │  Each skill has: canHandle() + execute() + proactive triggers   ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  Skills use Gemma 3n for: generation, classification, summarization │
│  Skills use pure logic for: lookups, schedules, rules               │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         SkillResult                                  │
│                                                                      │
│  → Response (text to user)                                           │
│  → ApprovalRequest (needs user confirmation for HIGH-risk actions)   │
│  → Handoff (route to another skill)                                  │
│  → Error (graceful failure)                                          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## The Two Models: Gemma 3n + FunctionGemma

### Gemma 3n (Primary Model)

| Property | Value |
|----------|-------|
| Size | ~1.5 GB (E2B variant) |
| Context | 2K–4K tokens |
| Latency | <500ms classify, <2s generate |
| Runs on | iPhone A16+, M1+ |
| Integration | MediaPipe LLM Inference API |

**Used for:**
- Conversation and response generation
- Intent classification (Step 3 of routing cascade)
- JSON extraction for skill parameters
- Summarization

### FunctionGemma (Fallback Only)

A Gemma variant fine-tuned specifically for function/tool calling.

**When to use:** ONLY when Gemma 3n's classification fails AND the keyword/scoring layers also fail. This is the last resort for ambiguous intents.

**Decision rule:** Start without FunctionGemma. Add it only if real-world testing shows >5% of intents slip through all 4 routing layers.

---

## The Adaptive Learning Loop

OiMy gets smarter over time through **on-device fine-tuning**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ADAPTIVE LEARNING CYCLE                           │
│                                                                      │
│  1. User interacts with OiMy                                         │
│     ↓                                                                │
│  2. OiMy routes to skill, generates response                         │
│     ↓                                                                │
│  3. User feedback captured:                                          │
│     • Explicit: thumbs up/down, corrections                          │
│     • Implicit: re-asks, abandonment, follow-up clarifications       │
│     ↓                                                                │
│  4. Feedback → Training examples (JSONL format)                      │
│     ↓                                                                │
│  5. Periodic on-device fine-tuning (nightly, when charging)          │
│     ↓                                                                │
│  6. Model improves for THIS family's patterns                        │
│     ↓                                                                │
│  Loop back to step 1                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

**Key files:**
- `ADAPTIVE_LEARNING_SYSTEM.md` — Full specification (coming soon)
- `FINETUNING_GUIDE.md` — How to fine-tune Gemma on-device (coming soon)
- `training-data/` — Example training data formats (coming soon)

---

## Skill Architecture

### The 21 Skills

| Cluster | Skills |
|---------|--------|
| **Family** | `family-comms`, `family-bonding`, `mental-load`, `elder-care` |
| **Health** | `healthcare`, `wellness`, `habits` |
| **Growth** | `education`, `school`, `note-to-actions`, `psy-rich` |
| **Home** | `home-maintenance`, `meal-planning`, `transportation`, `tools` |
| **Services** | `restaurant-reservation`, `marketplace-sell`, `hire-helper`, `telephony`, `infrastructure`, `chat-turn` |

### Skill Contract

Every skill implements:

```swift
protocol HomeSkill {
    var id: String { get }
    
    /// Fast scoring: 0.0 (no match) to 1.0 (perfect match)
    func canHandle(intent: String) -> Double
    
    /// Execute the skill
    func execute(context: SkillContext) async throws -> SkillResult
    
    /// Optional: proactive triggers (cron-style)
    var proactiveTriggers: [ProactiveTrigger]? { get }
}
```

### Risk Levels

Skills tag actions by risk:

| Level | Approval | Example |
|-------|----------|---------|
| LOW | Auto-execute | "What's on the calendar?" |
| MEDIUM | Soft confirm | "Add eggs to shopping list" |
| HIGH | Explicit YES required | "Call the dentist to reschedule" |

---

## File Organization

```
/tmp/homeOS/docs/OiMy/
│
├── README.md                      ← YOU ARE HERE
│   Overview of OiMy architecture and how to use this folder
│
├── API_KEYS_AND_SERVICES.md
│   Every external service OiMy integrates with:
│   - API keys needed
│   - Rate limits
│   - Fallback strategies
│
├── SKILL_INTENT_MAP.md
│   RAG reference for intent routing:
│   - All 21 skills
│   - Trigger keywords
│   - Sample utterances
│   - Handoff rules
│   - Ambiguity resolution
│
├── LLM_INTEGRATION_GUIDE.md
│   How to wire up Gemma 3n:
│   - MediaPipe integration
│   - LLMBridge protocol
│   - Prompt engineering
│   - Performance tuning
│
├── END_TO_END_FLOWS.md
│   Complete user journeys:
│   - Multi-turn conversations
│   - Cross-skill handoffs
│   - Proactive flows
│   - Error recovery
│
├── GEMMA_SYSTEM_PROMPT.md
│   The system prompt for Gemma 3n
│   (Being rewritten — check back)
│
├── ADAPTIVE_LEARNING_SYSTEM.md
│   On-device learning specification
│   (Coming soon)
│
├── FINETUNING_GUIDE.md
│   How to fine-tune Gemma on iOS
│   (Coming soon)
│
├── small-skills/
│   Detailed specifications for all 21 skills:
│   ├── README.md              # Overview of skill structure
│   ├── meal-planning/         # Each skill gets a folder
│   ├── healthcare/
│   ├── school/
│   ├── ...                    # 21 total
│   └── test-*.sh              # Cluster test scripts
│
├── lobster/
│   Lobster DSL workflows (multi-step orchestration):
│   ├── README.md              # Lobster language overview
│   ├── *.lobster              # Workflow definitions
│   └── tests/                 # Lobster test cases
│
├── training-data/
│   Training data for fine-tuning:
│   ├── README.md              # Data format specs
│   ├── intent-classification.jsonl
│   ├── function-calling.jsonl
│   └── multi-turn.jsonl
│   (Coming soon)
│
└── swift-reference/
    └── README.md              # Points to /tmp/homeOS/swift-skills/
```

---

## How to Use This Documentation

### For a Coding Agent Building OiMy

**Read order:**

1. **This README** — You're here. Architecture overview. ✓
2. **SKILL_INTENT_MAP.md** — Understand all 21 skills and how routing works
3. **LLM_INTEGRATION_GUIDE.md** — Implement the LLMBridge with MediaPipe + Gemma
4. **END_TO_END_FLOWS.md** — Test complete user journeys
5. **small-skills/** — Deep-dive into specific skills you're implementing
6. **lobster/** — If building multi-step workflows

### For Adding a New Skill

1. Read `small-skills/README.md` for the skill template
2. Read `SKILL_INTENT_MAP.md` to understand routing
3. Add skill entry to `SKILL_INTENT_MAP.md`
4. Create `small-skills/your-skill/` folder with specs
5. Implement in Swift at `/tmp/homeOS/swift-skills/`

### For Fine-Tuning

1. `ADAPTIVE_LEARNING_SYSTEM.md` — Understand the loop
2. `FINETUNING_GUIDE.md` — Technical how-to
3. `training-data/` — Example data formats

---

## Building the iOS App

### Prerequisites

- Xcode 15+
- iOS 17+ target
- Device with A16 Bionic or M1+ (for on-device inference)
- MediaPipe LLM SDK

### Quick Start

```bash
# 1. Clone/navigate to Swift package
cd /tmp/homeOS/swift-skills

# 2. Build
swift build

# 3. Run tests
swift test

# 4. Open in Xcode for iOS development
open Package.swift
```

### Key Implementation Tasks

1. **LLMBridge Implementation**
   - Read `LLM_INTEGRATION_GUIDE.md`
   - Implement `MediaPipeLLMBridge` conforming to `LLMBridge` protocol
   - Bundle `gemma-3n-E2B-it.task` model file

2. **Skill Registration**
   - Register all 21 skills with `ChatTurnRouter`
   - Configure proactive triggers

3. **Storage Layer**
   - Implement `SkillDataStore` for persistent family data
   - Use Core Data or SwiftData

4. **UI**
   - Chat interface with skill-aware rendering
   - Approval dialogs for HIGH-risk actions
   - Proactive notification handling

---

## Key Design Decisions

### Why On-Device?

- **Privacy**: Family data never leaves the phone
- **Latency**: No network round-trip
- **Reliability**: Works offline
- **Cost**: No API bills

### Why 21 Skills Instead of One Big Model?

- **Modularity**: Each skill is testable, replaceable
- **Performance**: Route fast, execute focused
- **Maintainability**: Add skills without touching others
- **Accuracy**: Specialized > generalized for structured tasks

### Why the 4-Layer Routing Cascade?

- **Step 1 (Keywords)**: Catches 60% of intents in <1ms
- **Step 2 (Scoring)**: Catches 30% more with skill logic
- **Step 3 (Gemma 3n)**: LLM classifies the hard 9%
- **Step 4 (FunctionGemma)**: Last 1% edge cases

Fast path for common cases, smart fallback for the rest.

---

## Questions?

This documentation is living. If something is unclear:

1. Check if another file in this folder answers it
2. Check `swift-reference/README.md` for code pointers
3. Note the gap — future updates will address it

---

*Last updated: 2025-02-05*
