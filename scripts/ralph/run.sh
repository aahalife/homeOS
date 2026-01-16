#!/usr/bin/env bash
set -euo pipefail

PRD_PATH="docs/IosPRD/prd.json"

if [[ ! -f "$PRD_PATH" ]]; then
  echo "prd.json not found at $PRD_PATH"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to run this script."
  exit 1
fi

next_json=$(jq -r '
  .userStories as $stories
  | [ $stories[]
      | select(.passes == false)
      | select(.dependsOn | all(. as $dep | ($stories[] | select(.id == $dep) | .passes) == true))
    ]
  | sort_by(.priority)
  | .[0]
  | if . == null then empty else @json end
' "$PRD_PATH")

if [[ -z "$next_json" ]]; then
  echo "No runnable story found. All stories may be complete or blocked by dependencies."
  exit 0
fi

id=$(echo "$next_json" | jq -r '.id')
title=$(echo "$next_json" | jq -r '.title')
notes=$(echo "$next_json" | jq -r '.notes')

echo "Next story:"
echo "  $id - $title"
echo "  Notes: $notes"

echo ""
echo "Suggested checks:"
case "$notes" in
  *"iOS"*)
    echo "  - xcodebuild test -scheme HomeOS (update scheme as needed)"
    ;;
  *"control plane"*)
    echo "  - pnpm --filter control-plane test"
    echo "  - pnpm --filter control-plane typecheck"
    ;;
  *"workflows"*)
    echo "  - pnpm --filter workflows test"
    ;;
  *"integrations"*)
    echo "  - pnpm --filter control-plane test"
    ;;
  *"skills"*)
    echo "  - Validate skill frontmatter and deterministic steps"
    ;;
  *)
    echo "  - Run appropriate tests for this change"
    ;;
esac
