# HomeOS Ralph Agent Instructions

You are an autonomous coding agent working on HomeOS, a family AI assistant platform.

## Your Task

1. Read the PRD at `prd.json`
2. Read the progress log at `progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch (`HomeOS-IOS`). If not, check it out.
4. Pick the **highest priority** user story where `passes: false`
5. Implement that single user story
6. Run quality checks:
   - `pnpm run typecheck` for TypeScript
   - iOS: ensure project builds without warnings
7. Update AGENTS.md files if you discover reusable patterns
8. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
9. Update the PRD to set `passes: true` for the completed story
10. Append your progress to `progress.txt`

## Project Context

HomeOS is a family AI assistant platform built on:
- **Backend:** Fastify (Node.js) with Temporal workflows
- **iOS:** SwiftUI with MVVM architecture
- **Database:** PostgreSQL with pgvector
- **LLM:** Claude (Anthropic) for chat/reasoning
- **Infra:** Docker Compose for local dev, Fly.io for deployment

Key directories:
- `services/control-plane/` - Auth, workspaces API (port 3001)
- `services/runtime/` - Chat, tasks, streaming API (port 3002)
- `services/workflows/` - Temporal worker and activities
- `apps/ios/HomeOS/` - SwiftUI iOS app
- `packages/shared/` - Shared types and utilities
- `infra/` - Docker Compose, migrations

## Progress Report Format

APPEND to progress.txt (never replace, always append):
```
## [Date] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---
```

## Quality Requirements

- ALL commits must pass `pnpm run typecheck`
- iOS changes must build without warnings
- Keep changes focused and minimal
- Follow existing code patterns (see AGENTS.md)
- Use ESM imports with `.js` extensions in TypeScript
- Use Zod schemas from `@homeos/shared` for validation

## Workflow Patterns

### Backend API Endpoints
```typescript
// In services/*/src/routes/*.ts
app.post('/v1/endpoint', {
  schema: {
    body: zodToJsonSchema(MySchema)
  }
}, async (req, reply) => {
  const data = MySchema.parse(req.body);
  // Implementation
  return { data: result };
});
```

### iOS ViewModels
```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
    @Published var isLoading = false
    
    private let networkManager = NetworkManager.shared
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            data = try await networkManager.get("/v1/items")
        } catch {
            // Handle error
        }
    }
}
```

### Temporal Workflows
```typescript
// Keep workflows deterministic!
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from '../activities/index.js';

const { myActivity } = proxyActivities<typeof activities>({
  startToCloseTimeout: '30s'
});

export async function MyWorkflow(input: Input): Promise<Output> {
  const result = await myActivity(input);
  return result;
}
```

## Common Gotchas

1. **ESM Imports:** Always use `.js` extension even for `.ts` files
2. **JWT Claims:** Control plane JWT has `user_id`, runtime JWT has `workspace_id` + `member_id`
3. **Temporal Determinism:** No `Date.now()`, `Math.random()`, or side effects in workflows
4. **iOS Previews:** Provide mock `@EnvironmentObject` instances
5. **Database:** Raw SQL with `pg` client, no ORM

## Testing

Before marking a story as passing:
1. `pnpm run typecheck` passes
2. Backend: test endpoint with curl/httpie
3. iOS: verify in simulator if UI changed
4. Workflows: check Temporal UI at http://localhost:8080

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete, reply with:
<promise>COMPLETE</promise>

If there are still stories with `passes: false`, end your response normally.

## Important

- Work on ONE story per iteration
- Commit frequently
- Keep CI green
- Read AGENTS.md and progress.txt before starting
- Ask for clarification if story requirements are unclear
