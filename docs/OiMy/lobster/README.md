# HomeOS Lobster Workflows

Deterministic workflow decompositions of HomeOS skills for use with OpenClaw's Lobster runtime.

## Architecture

Each HomeOS skill is decomposed into one or more `.lobster` workflow files that:

1. **Replace LLM orchestration** with typed pipeline steps
2. **Use `llm-task`** only for genuine judgment calls (classification, summarization, drafting)
3. **Include approval gates** at every side-effect boundary
4. **Produce structured JSON** at every step for auditability

## Design Principles

### Minimal LLM Usage
- Data fetching, filtering, formatting → deterministic CLI steps
- Classification, intent detection, content generation → `llm-task` with strict JSON schema
- Never use LLM for: date math, lookups, conditional routing

### Approval Gates
Every workflow that produces a side effect (send message, make call, create event) MUST include an `approval: required` step before execution.

### Resume Tokens
All workflows support pause/resume via Lobster's built-in resume token system. Users can approve asynchronously.

## Workflow Naming Convention

```
{skill-name}-{action}.lobster
```

Examples:
- `meal-planning-generate.lobster` — Generate a weekly meal plan
- `healthcare-refill.lobster` — Check and request prescription refills
- `elder-care-checkin.lobster` — Run a daily elder check-in

## Shared CLI Tools

Workflows depend on a set of small CLI tools that read/write HomeOS data:

```
homeos-cli family list          → JSON array of family members
homeos-cli calendar list        → JSON array of events
homeos-cli calendar add         → Add event (stdin JSON)
homeos-cli data read <path>     → Read JSON file
homeos-cli data write <path>    → Write JSON from stdin
homeos-cli reminder set         → Create reminder (stdin JSON)
homeos-cli notify send          → Send notification (stdin JSON)
```

These are implemented in `swift-skills/Sources/HomeOSCLI/` for iOS and as shell scripts for Clawdbot.

## Workflow Structure

```yaml
name: skill-action
description: What this workflow does
args:
  param_name:
    type: string
    required: true
    description: What this parameter is
steps:
  - id: fetch-data
    command: homeos-cli data read family.json
  - id: process
    command: homeos-cli transform --type filter
    stdin: $fetch-data.stdout
  - id: llm-classify
    command: openclaw.invoke --tool llm-task --action json --args-json '...'
    stdin: $process.stdout
  - id: approve
    command: approve --preview-from-stdin --prompt "Proceed?"
    stdin: $llm-classify.stdout
    approval: required
  - id: execute
    command: homeos-cli notify send
    stdin: $llm-classify.stdout
    condition: $approve.approved
```

## Testing

Each workflow includes a companion `{name}.test.sh` script that:
1. Sets up mock data in a temp directory
2. Runs the workflow with `lobster run --dry`
3. Validates JSON output structure
4. Checks approval gates fire correctly
