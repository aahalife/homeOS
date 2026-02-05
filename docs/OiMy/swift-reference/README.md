# Swift Reference

This folder is a reference pointer to the main Swift codebase.

## Full Swift Code Location

```
/tmp/homeOS/swift-skills/
├── Package.swift          # Swift Package Manager manifest
├── README.md              # Swift package overview
├── Sources/               # All Swift source files
│   ├── HomeSkills/        # Core skills implementation
│   └── ...
└── Tests/                 # Unit and integration tests
    ├── HomeSkillsTests/
    └── ...
```

## What Lives Where

| Need | Location |
|------|----------|
| **Skill implementations** | `/tmp/homeOS/swift-skills/Sources/HomeSkills/` |
| **LLMBridge protocol** | `/tmp/homeOS/swift-skills/Sources/HomeSkills/LLMBridge.swift` |
| **ChatTurnRouter** | `/tmp/homeOS/swift-skills/Sources/HomeSkills/ChatTurnRouter.swift` |
| **Skill protocols** | `/tmp/homeOS/swift-skills/Sources/HomeSkills/Protocols/` |
| **Tests** | `/tmp/homeOS/swift-skills/Tests/` |
| **Package definition** | `/tmp/homeOS/swift-skills/Package.swift` |

## Why Not Copy Here?

The Swift code is a living, testable codebase. Copying it would:
1. Create drift between docs and code
2. Lose git history
3. Break test runners expecting the original path

**Always work with the original at `/tmp/homeOS/swift-skills/`.**

## Quick Commands

```bash
# Navigate to Swift code
cd /tmp/homeOS/swift-skills

# Build
swift build

# Test
swift test

# Open in Xcode
open Package.swift
```

## Related OiMy Docs

- `../LLM_INTEGRATION_GUIDE.md` — How to implement LLMBridge
- `../SKILL_INTENT_MAP.md` — What each skill does
- `../small-skills/` — Detailed skill specifications
