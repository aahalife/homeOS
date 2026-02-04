#!/bin/bash
# test-growth-cluster.sh — Validate Growth Cluster small-model skills
# Run: bash /tmp/homeOS/docs/homeskills/small-skills/test-growth-cluster.sh

set -euo pipefail

SKILLS_DIR="/tmp/homeOS/docs/homeskills/small-skills"
PASS=0
FAIL=0
WARN=0

green() { echo -e "\033[32m✅ $1\033[0m"; PASS=$((PASS+1)); }
red()   { echo -e "\033[31m❌ $1\033[0m"; FAIL=$((FAIL+1)); }
yellow(){ echo -e "\033[33m⚠️  $1\033[0m"; WARN=$((WARN+1)); }

echo "═══════════════════════════════════════════"
echo "  GROWTH CLUSTER — Small-Model Skill Tests"
echo "═══════════════════════════════════════════"
echo ""

SKILLS=("education" "school" "note-to-actions" "psy-rich")

# --- Test 1: All skills exist ---
echo "── Test 1: Skill files exist ──"
for skill in "${SKILLS[@]}"; do
  if [[ -f "$SKILLS_DIR/$skill/SKILL.md" ]]; then
    green "$skill/SKILL.md exists"
  else
    red "$skill/SKILL.md MISSING"
  fi
done
echo ""

# --- Test 2: Under 300 lines ---
echo "── Test 2: Under 300 lines ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    LINES=$(wc -l < "$FILE")
    if (( LINES <= 300 )); then
      green "$skill: $LINES lines (≤300)"
    else
      red "$skill: $LINES lines (OVER 300)"
    fi
  fi
done
echo ""

# --- Test 3: Has YAML frontmatter ---
echo "── Test 3: YAML frontmatter ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if head -1 "$FILE" | grep -q "^---"; then
      green "$skill: has frontmatter"
    else
      red "$skill: MISSING frontmatter"
    fi
  fi
done
echo ""

# --- Test 4: Has version: small-model ---
echo "── Test 4: version: small-model ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "version: small-model" "$FILE"; then
      green "$skill: version tagged"
    else
      red "$skill: MISSING version: small-model"
    fi
  fi
done
echo ""

# --- Test 5: Has risk level ---
echo "── Test 5: Risk level defined ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "^risk:" "$FILE"; then
      green "$skill: risk level defined"
    else
      red "$skill: MISSING risk level"
    fi
  fi
done
echo ""

# --- Test 6: Has TRIGGERS section ---
echo "── Test 6: TRIGGERS section ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "## TRIGGERS" "$FILE"; then
      green "$skill: has TRIGGERS"
    else
      red "$skill: MISSING TRIGGERS section"
    fi
  fi
done
echo ""

# --- Test 7: Has OUTPUT_HANDOFF ---
echo "── Test 7: OUTPUT_HANDOFF ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "OUTPUT_HANDOFF" "$FILE"; then
      green "$skill: has OUTPUT_HANDOFF"
    else
      red "$skill: MISSING OUTPUT_HANDOFF"
    fi
  fi
done
echo ""

# --- Test 8: Has ERROR HANDLING ---
echo "── Test 8: ERROR HANDLING ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "ERROR HANDLING" "$FILE"; then
      green "$skill: has ERROR HANDLING"
    else
      red "$skill: MISSING ERROR HANDLING"
    fi
  fi
done
echo ""

# --- Test 9: Uses correct storage paths ---
echo "── Test 9: Storage paths (~/clawd/homeos/) ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -q "~/clawd/homeos/" "$FILE"; then
      green "$skill: uses ~/clawd/homeos/ paths"
    else
      red "$skill: WRONG storage paths"
    fi
  fi
done
echo ""

# --- Test 10: No markdown tables in templates ---
echo "── Test 10: No tables in templates ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    # Look for | --- | pattern (table separator)
    if grep -qP '^\|[\s-]+\|' "$FILE"; then
      red "$skill: contains markdown tables"
    else
      green "$skill: no tables found"
    fi
  fi
done
echo ""

# --- Test 11: Uses IF/THEN patterns ---
echo "── Test 11: IF/THEN patterns ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    IF_COUNT=$(grep -c "^IF " "$FILE" || true)
    if (( IF_COUNT >= 3 )); then
      green "$skill: $IF_COUNT IF/THEN rules"
    elif (( IF_COUNT >= 1 )); then
      yellow "$skill: only $IF_COUNT IF/THEN rules (want 3+)"
    else
      red "$skill: NO IF/THEN patterns"
    fi
  fi
done
echo ""

# --- Test 12: Has DEFAULT values ---
echo "── Test 12: DEFAULT values ──"
for skill in "${SKILLS[@]}"; do
  FILE="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$FILE" ]]; then
    if grep -qi "default" "$FILE"; then
      green "$skill: has defaults"
    else
      yellow "$skill: no explicit defaults found"
    fi
  fi
done
echo ""

# --- Test 13: education vs school distinction ---
echo "── Test 13: education/school distinction ──"
EDU="$SKILLS_DIR/education/SKILL.md"
SCH="$SKILLS_DIR/school/SKILL.md"
if [[ -f "$EDU" && -f "$SCH" ]]; then
  # education should mention "one student" / "individual"
  if grep -qi "one student\|individual\|one child" "$EDU"; then
    green "education: scoped to individual student"
  else
    red "education: NOT clearly scoped to individual"
  fi
  # school should mention "multiple" / "all children" / "orchestrat"
  if grep -qi "multiple\|all children\|orchestrat\|multi-child" "$SCH"; then
    green "school: scoped to multi-child orchestration"
  else
    red "school: NOT clearly scoped to orchestration"
  fi
  # education should hand off to school
  if grep -q "handoff.*school\|HANDOFF.*school" "$EDU"; then
    green "education → school handoff exists"
  else
    red "education: MISSING handoff to school"
  fi
  # school should hand off to education
  if grep -q "handoff.*education\|HANDOFF.*education" "$SCH"; then
    green "school → education handoff exists"
  else
    red "school: MISSING handoff to education"
  fi
fi
echo ""

# --- Test 14: note-to-actions uses 4 Laws ---
echo "── Test 14: note-to-actions 4 Laws ──"
NTA="$SKILLS_DIR/note-to-actions/SKILL.md"
if [[ -f "$NTA" ]]; then
  for law in "OBVIOUS" "ATTRACTIVE" "EASY" "SATISFYING"; do
    if grep -qi "$law" "$NTA"; then
      green "note-to-actions: mentions $law"
    else
      red "note-to-actions: MISSING $law"
    fi
  done
  if grep -qi "atomic\|2.minute\|two.minute" "$NTA"; then
    green "note-to-actions: has atomic/2-minute rule"
  else
    red "note-to-actions: MISSING atomic habit concept"
  fi
fi
echo ""

# --- Test 15: psy-rich has concrete details ---
echo "── Test 15: psy-rich concreteness ──"
PSY="$SKILLS_DIR/psy-rich/SKILL.md"
if [[ -f "$PSY" ]]; then
  # Should mention specific costs
  if grep -qP '\$\d+' "$PSY"; then
    green "psy-rich: includes dollar amounts"
  else
    red "psy-rich: NO specific costs"
  fi
  # Should mention durations
  if grep -qi "hour\|min\|minutes" "$PSY"; then
    green "psy-rich: includes time durations"
  else
    red "psy-rich: NO time durations"
  fi
  # Should mention location types
  if grep -qi "home\|park\|kitchen\|local\|backyard" "$PSY"; then
    green "psy-rich: includes location types"
  else
    red "psy-rich: NO location types"
  fi
  # Should have kid age ranges
  if grep -qP "Ages \d+" "$PSY"; then
    green "psy-rich: includes kid age ranges"
  else
    yellow "psy-rich: no kid age ranges"
  fi
fi
echo ""

# --- Summary ---
echo "═══════════════════════════════════════════"
echo "  RESULTS"
echo "═══════════════════════════════════════════"
echo -e "  \033[32m✅ PASS: $PASS\033[0m"
echo -e "  \033[33m⚠️  WARN: $WARN\033[0m"
echo -e "  \033[31m❌ FAIL: $FAIL\033[0m"
TOTAL=$((PASS+FAIL+WARN))
echo "  Total: $TOTAL checks"
echo ""

if (( FAIL == 0 )); then
  echo -e "\033[32m🎉 ALL TESTS PASSED!\033[0m"
  exit 0
elif (( FAIL <= 3 )); then
  echo -e "\033[33m⚠️  Mostly good, $FAIL issue(s) to fix.\033[0m"
  exit 1
else
  echo -e "\033[31m💥 $FAIL failures. Needs work.\033[0m"
  exit 2
fi
