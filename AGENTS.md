# HomeOS Agent Instructions

## Overview

HomeOS is a family AI assistant platform built on top of Clawdbot. This document provides guidelines for AI agents working on this codebase.

## Project Structure

```
homeOS/
├── apps/
│   └── ios/HomeOS/           # SwiftUI iOS app
├── docs/
│   ├── HomeOS_PRD.md         # Comprehensive PRD
│   ├── IosPRD/               # Original PRD documents
│   ├── ARCHITECTURE.md       # System architecture
│   └── homeskills/           # Skill specifications
├── infra/
│   ├── docker-compose.yml    # Local infrastructure
│   └── init-scripts/         # Database migrations
├── packages/
│   └── shared/               # Shared types and utilities
├── services/
│   ├── control-plane/        # Auth, workspaces API (:3001)
│   ├── runtime/              # Chat, tasks, streaming API (:3002)
│   ├── workflows/            # Temporal worker
│   └── echo-tts/             # Text-to-speech service
├── prd.json                  # Ralph-format user stories
└── progress.txt              # Development progress log
```

## Development Commands

```bash
# Install dependencies
pnpm install

# Start infrastructure (PostgreSQL, Redis, Temporal, etc.)
cd infra && docker compose up -d

# Start all services in development
pnpm run dev:services

# Type check all packages
pnpm run typecheck

# Run tests
pnpm run test

# Build iOS app (requires Xcode)
cd apps/ios/HomeOS && xcodebuild -scheme HomeOS
```

## Codebase Patterns

### TypeScript Services

- **Framework:** Fastify for HTTP servers
- **ORM:** Raw SQL with `pg` client (no Prisma/Drizzle yet)
- **Authentication:** JWT with `@fastify/jwt`
- **Validation:** Zod schemas in `packages/shared/src/schemas/`
- **Exports:** Use ESM with `.js` extensions in imports

### iOS App (SwiftUI)

- **Architecture:** MVVM with `@StateObject` ViewModels
- **Networking:** `NetworkManager` singleton for API calls
- **Auth:** `AuthManager` handles Apple Sign In and JWT storage
- **Storage:** `KeychainHelper` for secure token storage
- **Design:** Glassmorphic design with `GlassSurface` component

### Temporal Workflows

- **Worker:** Located in `services/workflows/src/worker.ts`
- **Workflows:** Define in `services/workflows/src/workflows/`
- **Activities:** Define in `services/workflows/src/activities/`
- **Pattern:** Keep workflows deterministic, side effects in activities

## API Conventions

### Control Plane (Port 3001)
- Prefix: `/v1/`
- Auth: Bearer JWT required for all routes except `/health` and `/v1/auth/*`
- Workspace-scoped routes: `/v1/workspaces/:workspaceId/*`

### Runtime (Port 3002)
- Prefix: `/v1/`
- Auth: Runtime JWT from control plane
- WebSocket: `/v1/stream` for real-time events

### Response Format

```typescript
// Success
{ data: T }

// Error
{ 
  error: {
    code: string,
    message: string,
    details?: unknown
  }
}
```

## Database Schema

Key tables in PostgreSQL:
- `users` - User accounts (Apple Sign In)
- `workspaces` - Family workspaces
- `workspace_members` - Membership with roles
- `devices` - Registered devices (iOS, etc.)
- `secrets` - Encrypted integration tokens (BYOK)
- `tasks` - Workflow tasks
- `conversations` - Chat history
- `memories` - Vector embeddings for context

## Environment Variables

### Control Plane
```
PORT=3001
DATABASE_URL=postgres://...
JWT_SECRET=...
```

### Runtime
```
PORT=3002
DATABASE_URL=postgres://...
JWT_SECRET=...
REDIS_URL=redis://...
TEMPORAL_ADDRESS=localhost:7233
```

### Workflows
```
TEMPORAL_ADDRESS=localhost:7233
DATABASE_URL=postgres://...
ANTHROPIC_API_KEY=...
OPENAI_API_KEY=...
```

## Common Gotchas

1. **ESM Imports:** Always use `.js` extension even for TypeScript files
2. **Temporal Determinism:** Never use `Date.now()` or `Math.random()` in workflows
3. **iOS Previews:** Use `#Preview` macro, provide mock environment objects
4. **JWT Claims:** Control plane JWT has `user_id`, runtime JWT has `workspace_id` + `member_id`
5. **CORS:** Both services allow all origins in dev, configure for production

## Testing Guidelines

- Backend: Use Vitest for unit tests
- iOS: Use XCTest with Preview macros for UI
- Integration: Test against local Docker infrastructure
- Workflows: Use Temporal's test environment

## Security Considerations

- Never log JWT tokens or secrets
- Use `packages/shared/src/redaction/` for PII
- High-risk actions require approval workflow
- Envelope encryption for stored secrets

## Ralph Integration

This project uses the Ralph methodology for autonomous development:

1. Read `prd.json` for current user stories
2. Pick highest priority story where `passes: false`
3. Implement the story
4. Run quality checks (`pnpm run typecheck`)
5. Commit with message: `feat: [Story ID] - [Story Title]`
6. Update `prd.json` to set `passes: true`
7. Append learnings to `progress.txt`

## Resources

- [HomeOS PRD](/docs/HomeOS_PRD.md)
- [Architecture](/docs/ARCHITECTURE.md)
- [Soul Document](/docs/MacAppPRD/SOUL.md) - Personality/voice guidelines
- [Skill Specs](/docs/homeskills/)
