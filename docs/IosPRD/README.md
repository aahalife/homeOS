# IosPRD Guidance

Before editing files in this directory, read all documentation here and follow naming conventions.

## Document Index

- `PRD.md` — baseline product requirements and scope
- `PRD_RALPH.md` — Ralph-ready user stories and acceptance criteria
- `prd.json` — executable Ralph tracker file
- `IOS_APP_DESIGN_SPEC.md` — detailed iOS/iPad UX and screen specs (MVP + V1)
- `DESIGN_SPEC.md` — design principles and component guidance
- `SYSTEM_ARCHITECTURE.md` — system architecture and deployment topology
- `USER_ONBOARDING.md` — onboarding flow and scripts
- `INTEGRATIONS.md` — integration requirements and setup notes
- `WORKFLOW_PACKS.md` — workflow pack definitions
- `RUNBOOKS.md` — ops runbooks and incident procedures
- `REQUIRED_KEYS_AND_SETUP.md` — required keys, certificates, and setup steps

## Ralph Execution Workflow

1. Start from `PRD_RALPH.md` and `prd.json`.
2. Use `scripts/ralph/run.sh` to pick the next runnable story.
3. Implement changes, run the appropriate tests, and verify acceptance criteria.
4. Set `passes: true` for the completed story in `prd.json`.
5. Log progress in `docs/IosPRD/progress.txt`.

## Notes

- iOS is the primary client; heavy execution runs in the cloud.
- Keep MVP features lean; V1 adds motion, shader, and audio polish.
