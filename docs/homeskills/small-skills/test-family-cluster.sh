#!/bin/bash
# Test script for Family Cluster small-model skills
# Validates: existence, line count, paths, HIGH risk approval blocks, frontmatter

PASS=0
FAIL=0
WARN=0
BASE="/tmp/homeOS/docs/homeskills/small-skills"
SKILLS=("family-comms" "family-bonding" "mental-load" "elder-care")
MAX_LINES=300

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  WARN: $1"; WARN=$((WARN+1)); }

echo "═══════════════════════════════════════════"
echo "  Family Cluster Skills - Validation Suite"
echo "═══════════════════════════════════════════"
echo ""

# ─── Test 1: Files exist ───
echo "── Test 1: File Existence ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    pass "$skill/SKILL.md exists"
  else
    fail "$skill/SKILL.md NOT FOUND"
  fi
done
echo ""

# ─── Test 2: Line count under MAX_LINES ───
echo "── Test 2: Line Count (max $MAX_LINES) ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file")
    if [ "$lines" -le "$MAX_LINES" ]; then
      pass "$skill: $lines lines (under $MAX_LINES)"
    else
      fail "$skill: $lines lines (OVER $MAX_LINES limit)"
    fi
  fi
done
echo ""

# ─── Test 3: Frontmatter present with name + description ───
echo "── Test 3: Frontmatter ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    # Check for --- delimiters
    if head -1 "$file" | grep -q "^---"; then
      pass "$skill: frontmatter delimiter found"
    else
      fail "$skill: missing frontmatter (no --- on line 1)"
    fi
    # Check for name field
    if grep -q "^name:" "$file"; then
      pass "$skill: has 'name' field"
    else
      fail "$skill: missing 'name' field"
    fi
    # Check for description field
    if grep -q "^description:" "$file"; then
      pass "$skill: has 'description' field"
    else
      fail "$skill: missing 'description' field"
    fi
  fi
done
echo ""

# ─── Test 4: Storage paths use correct directories ───
echo "── Test 4: Storage Paths ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    # Check for ~/clawd/homeos/data/ or ~/clawd/homeos/memory/
    if grep -q "~/clawd/homeos/data/" "$file" || grep -q "~/clawd/homeos/memory/" "$file"; then
      pass "$skill: uses correct storage paths"
    else
      fail "$skill: missing ~/clawd/homeos/data/ or ~/clawd/homeos/memory/ paths"
    fi
  fi
done
echo ""

# ─── Test 5: HIGH risk actions have approval blocks ───
echo "── Test 5: HIGH Risk Approval Blocks ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    # Count HIGH risk mentions
    high_count=$(grep -c -i -E "risk.*high|high.*risk|Risk: HIGH" "$file" 2>/dev/null || true)
    high_count=${high_count:-0}
    # Count approval blocks
    approval_count=$(grep -c -i -E "APPROVAL REQUIRED|WAIT for YES|Type YES" "$file" 2>/dev/null || true)
    approval_count=${approval_count:-0}

    if [ "$high_count" -gt 0 ] && [ "$approval_count" -gt 0 ]; then
      pass "$skill: $high_count HIGH risk refs, $approval_count approval blocks"
    elif [ "$high_count" -gt 0 ] && [ "$approval_count" -eq 0 ]; then
      fail "$skill: has HIGH risk ($high_count) but NO approval blocks!"
    elif [ "$high_count" -eq 0 ]; then
      warn "$skill: no HIGH risk actions found (may be intentional)"
    fi
  fi
done
echo ""

# ─── Test 6: Cross-skill handoffs present ───
echo "── Test 6: Cross-Skill Handoffs ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    if grep -q "OUTPUT_HANDOFF" "$file"; then
      handoff_count=$(grep -c "OUTPUT_HANDOFF" "$file")
      pass "$skill: $handoff_count cross-skill handoff(s)"
    else
      fail "$skill: missing OUTPUT_HANDOFF blocks"
    fi
  fi
done
echo ""

# ─── Test 7: No markdown tables (small-model rule) ───
echo "── Test 7: No Markdown Tables ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    # Look for | --- | pattern (table separator rows)
    if grep -qE '^\|.*\|.*\|' "$file" 2>/dev/null; then
      table_lines=$(grep -cE '^\|.*\|.*\|' "$file" 2>/dev/null || echo "0")
      fail "$skill: found $table_lines markdown table lines (use bullet lists instead)"
    else
      pass "$skill: no markdown tables"
    fi
  fi
done
echo ""

# ─── Test 8: Scenario examples present ───
echo "── Test 8: Scenario Examples ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    if grep -qi "scenario" "$file"; then
      scenario_count=$(grep -ci "^scenario:" "$file" 2>/dev/null || echo "0")
      pass "$skill: has scenario examples ($scenario_count)"
    else
      fail "$skill: missing scenario examples"
    fi
  fi
done
echo ""

# ─── Test 9: IF/THEN decision logic present ───
echo "── Test 9: Explicit IF/THEN Logic ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    if_count=$(grep -c "^IF " "$file" 2>/dev/null || echo "0")
    if [ "$if_count" -ge 3 ]; then
      pass "$skill: $if_count explicit IF/THEN rules"
    elif [ "$if_count" -ge 1 ]; then
      warn "$skill: only $if_count IF/THEN rules (consider adding more)"
    else
      fail "$skill: no IF/THEN decision logic found"
    fi
  fi
done
echo ""

# ─── Test 10: Template placeholders present ───
echo "── Test 10: Template Placeholders ──"
for skill in "${SKILLS[@]}"; do
  file="$BASE/$skill/SKILL.md"
  if [ -f "$file" ]; then
    placeholder_count=$(grep -c '\[.*_.*\]' "$file" 2>/dev/null || true)
    placeholder_count=${placeholder_count:-0}
    if [ "$placeholder_count" -ge 5 ]; then
      pass "$skill: has [PLACEHOLDER] templates"
    else
      warn "$skill: few placeholders found ($placeholder_count)"
    fi
  fi
done
echo ""

# ─── Summary ───
echo "═══════════════════════════════════════════"
echo "  RESULTS"
echo "═══════════════════════════════════════════"
echo "  ✅ Passed: $PASS"
echo "  ❌ Failed: $FAIL"
echo "  ⚠️  Warnings: $WARN"
echo "═══════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo "  ❌ SOME TESTS FAILED"
  exit 1
else
  echo "  ✅ ALL TESTS PASSED"
  exit 0
fi
