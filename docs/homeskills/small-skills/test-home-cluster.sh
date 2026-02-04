#!/usr/bin/env bash
# test-home-cluster.sh - Validate small-model home cluster skills
# Tests: structure, line count, required sections, cross-references
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS=("home-maintenance" "meal-planning" "transportation" "tools")
PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); TOTAL=$((TOTAL+1)); echo "  ❌ $1"; }

echo "═══════════════════════════════════════════"
echo "  HomeOS Small-Model Home Cluster Tests"
echo "═══════════════════════════════════════════"
echo ""

# ─── Test 1: All skill files exist ───
echo "📁 Test: Skill files exist"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  if [[ -f "$f" ]]; then
    pass "$skill/SKILL.md exists"
  else
    fail "$skill/SKILL.md MISSING"
  fi
done
echo ""

# ─── Test 2: Line count under 300 ───
echo "📏 Test: Line count under 300"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  lines=$(wc -l < "$f")
  if [[ $lines -le 300 ]]; then
    pass "$skill: $lines lines (≤300)"
  else
    fail "$skill: $lines lines (>300 LIMIT)"
  fi
done
echo ""

# ─── Test 3: YAML frontmatter present ───
echo "📋 Test: YAML frontmatter"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  if head -1 "$f" | grep -q "^---"; then
    pass "$skill has frontmatter"
  else
    fail "$skill missing frontmatter"
  fi
done
echo ""

# ─── Test 4: Risk levels defined ───
echo "⚠️  Test: Risk levels present"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  if grep -qi "RISK:" "$f"; then
    pass "$skill has risk levels"
  else
    fail "$skill missing risk levels"
  fi
done
echo ""

# ─── Test 5: Storage paths reference ~/clawd/homeos/ ───
echo "💾 Test: Storage paths"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  if grep -q "~/clawd/homeos/data/" "$f" && grep -q "~/clawd/homeos/memory/" "$f"; then
    pass "$skill references correct storage paths"
  else
    fail "$skill missing storage path references"
  fi
done
echo ""

# ─── Test 6: Cross-skill handoffs ───
echo "🔗 Test: Cross-skill handoffs (OUTPUT_HANDOFF)"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  if grep -q "OUTPUT_HANDOFF" "$f"; then
    count=$(grep -c "OUTPUT_HANDOFF" "$f")
    pass "$skill has $count handoff(s)"
  else
    fail "$skill missing OUTPUT_HANDOFF"
  fi
done
echo ""

# ─── Test 7: IF/THEN explicit logic ───
echo "🧠 Test: Explicit IF/THEN logic (small-model friendly)"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  if_count=$(grep -ci "^IF \|^  IF \|^- IF " "$f" || true)
  if [[ $if_count -ge 3 ]]; then
    pass "$skill has $if_count IF/THEN rules"
  else
    fail "$skill has only $if_count IF/THEN rules (need ≥3)"
  fi
done
echo ""

# ─── Test 8: No markdown tables ───
echo "📊 Test: No markdown tables in templates"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  # Check for table separator lines like |---|---|
  if grep -qE '^\|[-:]+\|' "$f"; then
    fail "$skill contains markdown tables"
  else
    pass "$skill: no tables found"
  fi
done
echo ""

# ─── Test 9: Skill-specific checks ───
echo "🎯 Test: Skill-specific requirements"

# home-maintenance: emergency detection keywords
f="$SKILL_DIR/home-maintenance/SKILL.md"
if [[ -f "$f" ]]; then
  if grep -q "EMERGENCY" "$f" && grep -q "URGENT" "$f" && grep -q "ROUTINE" "$f"; then
    pass "home-maintenance: has EMERGENCY/URGENT/ROUTINE tiers"
  else
    fail "home-maintenance: missing severity tiers"
  fi
  if grep -qi "gas" "$f" && grep -qi "fire" "$f" && grep -qi "flood\|water" "$f"; then
    pass "home-maintenance: covers gas/fire/flood emergencies"
  else
    fail "home-maintenance: missing emergency types"
  fi
fi

# meal-planning: allergy handling
f="$SKILL_DIR/meal-planning/SKILL.md"
if [[ -f "$f" ]]; then
  if grep -qi "HARD CONSTRAINT\|HARD constraint\|never violate" "$f"; then
    pass "meal-planning: allergies as HARD constraints"
  else
    fail "meal-planning: allergies not marked as HARD constraints"
  fi
  if grep -q "family.json" "$f"; then
    pass "meal-planning: cross-checks family.json"
  else
    fail "meal-planning: doesn't reference family.json"
  fi
fi

# transportation: ride booking risk
f="$SKILL_DIR/transportation/SKILL.md"
if [[ -f "$f" ]]; then
  if grep -qi "RISK: HIGH" "$f"; then
    pass "transportation: ride booking marked HIGH risk"
  else
    fail "transportation: ride booking not HIGH risk"
  fi
  if grep -qi "RISK: LOW" "$f"; then
    pass "transportation: commute check marked LOW risk"
  else
    fail "transportation: commute not marked LOW risk"
  fi
fi

# tools: calendar delete = HIGH risk
f="$SKILL_DIR/tools/SKILL.md"
if [[ -f "$f" ]]; then
  if grep -qi "calendar.delete" "$f" || grep -qi "DELETE EVENT" "$f"; then
    if grep -A5 -i "delete" "$f" | grep -qi "HIGH"; then
      pass "tools: calendar delete marked HIGH risk"
    else
      fail "tools: calendar delete not marked HIGH risk"
    fi
  else
    fail "tools: no calendar delete section"
  fi
  if grep -qi "calendar.create\|CREATE.*MEDIUM\|RISK: MEDIUM" "$f"; then
    pass "tools: calendar create marked MEDIUM risk"
  else
    fail "tools: calendar create risk not specified"
  fi
fi
echo ""

# ─── Test 10: Placeholder format ───
echo "📝 Test: Template placeholders use [BRACKETS]"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  placeholder_count=$(grep -oE '\[[A-Z_]+\]' "$f" | wc -l)
  if [[ $placeholder_count -ge 5 ]]; then
    pass "$skill has $placeholder_count [PLACEHOLDERS]"
  else
    fail "$skill has only $placeholder_count placeholders (need ≥5)"
  fi
done
echo ""

# ─── Test 11: Handoff targets are valid skills ───
echo "🔗 Test: Handoff targets reference valid skills"
for skill in "${SKILLS[@]}"; do
  f="$SKILL_DIR/$skill/SKILL.md"
  [[ -f "$f" ]] || continue
  bad_targets=0
  while IFS= read -r target; do
    target=$(echo "$target" | xargs)  # trim
    found=0
    for valid in "${SKILLS[@]}"; do
      if [[ "$target" == "$valid" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      fail "$skill handoff to unknown skill: '$target'"
      bad_targets=$((bad_targets+1))
    fi
  done < <(grep -oP '"next_skill":\s*"[^"]*"' "$f" 2>/dev/null | grep -oP '"[^"]*"$' | tr -d '"' || true)
  if [[ $bad_targets -eq 0 ]]; then
    pass "$skill: all handoff targets valid"
  fi
done
echo ""

# ─── Summary ───
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed ($TOTAL total)"
echo "═══════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo "  ⚠️  Some tests failed!"
  exit 1
else
  echo "  🎉 All tests passed!"
  exit 0
fi
