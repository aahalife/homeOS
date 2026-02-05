#!/bin/bash
# HomeOS Lobster Workflow Tests
# Validates all .lobster files for structural correctness

set -e

LOBSTER_DIR="$(dirname "$0")/.."
PASS=0
FAIL=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    if [ "$1" = "true" ]; then
        PASS=$((PASS + 1))
        echo "  ✅ $2"
    else
        FAIL=$((FAIL + 1))
        echo "  ❌ $2"
    fi
}

echo "🧪 LOBSTER WORKFLOW TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"

# Test each .lobster file
for f in "$LOBSTER_DIR"/*.lobster; do
    name=$(basename "$f" .lobster)
    echo ""
    echo "📋 Testing: $name"
    
    # Check file exists and is not empty
    check "$([ -s "$f" ] && echo true || echo false)" "File is not empty"
    
    # Check has name field
    check "$(grep -q '^name:' "$f" && echo true || echo false)" "Has name field"
    
    # Check has description
    check "$(grep -q '^description:' "$f" && echo true || echo false)" "Has description field"
    
    # Check has steps
    check "$(grep -q '^steps:' "$f" && echo true || echo false)" "Has steps section"
    
    # Check steps have IDs
    step_count=$(grep -c '^\s*- id:' "$f" || echo 0)
    check "$([ "$step_count" -gt 0 ] && echo true || echo false)" "Has $step_count steps with IDs"
    
    # Check HIGH-risk workflows have approval gates
    if echo "$name" | grep -qE "book|send|announce|call|sell|checkout|hire"; then
        has_approval=$(grep -c 'approval: required' "$f" || echo 0)
        check "$([ "$has_approval" -gt 0 ] && echo true || echo false)" "Has approval gate (HIGH-risk workflow)"
    fi
    
    # Check steps have commands
    cmd_count=$(grep -c '^\s*command:' "$f" || echo 0)
    check "$([ "$cmd_count" -gt 0 ] && echo true || echo false)" "Has $cmd_count commands"
    
    # Check for data piping (stdin references)
    stdin_count=$(grep -c 'stdin:' "$f" || echo 0)
    if [ "$step_count" -gt 2 ]; then
        check "$([ "$stdin_count" -gt 0 ] && echo true || echo false)" "Has data piping ($stdin_count stdin refs)"
    fi
    
    # Check YAML validity (basic — no tabs)
    check "$(! grep -qP '^\t' "$f" && echo true || echo false)" "No tabs (YAML-safe)"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS/$TOTAL passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
    echo "❌ Some tests failed"
    exit 1
else
    echo "✅ All tests passed!"
fi
