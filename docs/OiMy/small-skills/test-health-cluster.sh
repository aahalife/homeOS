#!/usr/bin/env bash
# test-health-cluster.sh — Validate small-model health cluster skills
# Usage: bash test-health-cluster.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
WARN=0

pass()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
warn()  { echo "  ⚠️  $1"; WARN=$((WARN+1)); }

echo "═══════════════════════════════════════════"
echo "  Health Cluster — Small-Model Skill Tests"
echo "═══════════════════════════════════════════"
echo ""

SKILLS=("healthcare" "wellness" "habits")

# ─────────────────────────────────────────────
# 1. Basic file checks
# ─────────────────────────────────────────────
echo "── 1. File Existence & Size ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    if [[ ! -f "$file" ]]; then
        fail "$skill/SKILL.md missing"
        continue
    fi
    pass "$skill/SKILL.md exists"

    lines=$(wc -l < "$file")
    if (( lines > 300 )); then
        fail "$skill: $lines lines (max 300)"
    else
        pass "$skill: $lines lines (≤300)"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 2. Frontmatter checks
# ─────────────────────────────────────────────
echo "── 2. Frontmatter ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    if head -1 "$file" | grep -q "^---"; then
        pass "$skill: has frontmatter delimiter"
    else
        fail "$skill: missing frontmatter (no --- on line 1)"
    fi

    if grep -q "^name:" "$file"; then
        pass "$skill: has 'name' field"
    else
        fail "$skill: missing 'name' field in frontmatter"
    fi

    if grep -q "^description:" "$file"; then
        pass "$skill: has 'description' field"
    else
        fail "$skill: missing 'description' field in frontmatter"
    fi

    # Check for trigger keywords in description
    if grep "^description:" "$file" | grep -qi "trigger\|use when\|mention"; then
        pass "$skill: description has trigger keywords"
    else
        warn "$skill: description may lack explicit trigger keywords"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 3. Risk levels
# ─────────────────────────────────────────────
echo "── 3. Risk Levels ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    if grep -qi "RISK LEVEL\|## RISK" "$file"; then
        pass "$skill: has risk levels section"
    else
        fail "$skill: missing risk levels section"
    fi

    for level in LOW MEDIUM HIGH; do
        if grep -q "$level" "$file"; then
            pass "$skill: defines $level risk"
        else
            fail "$skill: missing $level risk level"
        fi
    done

    if grep -qi "APPROVAL.*BLOCK\|APPROVAL.*REQUIRED\|WAIT" "$file"; then
        pass "$skill: HIGH risk has approval block"
    else
        fail "$skill: HIGH risk missing approval block / WAIT"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 4. If/Then decision patterns
# ─────────────────────────────────────────────
echo "── 4. If/Then Decision Patterns ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    ifthen_count=$(grep -c "^- IF\|^\- IF\|^  - IF" "$file" || true)
    if (( ifthen_count >= 5 )); then
        pass "$skill: $ifthen_count if/then rules found"
    elif (( ifthen_count >= 1 )); then
        warn "$skill: only $ifthen_count if/then rules (aim for 5+)"
    else
        fail "$skill: no if/then decision patterns found"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 5. Placeholders
# ─────────────────────────────────────────────
echo "── 5. Placeholder Templates ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    placeholder_count=$(grep -oE "\[[A-Z_]+\]" "$file" | wc -l || echo 0)
    if (( placeholder_count >= 10 )); then
        pass "$skill: $placeholder_count placeholders found"
    elif (( placeholder_count >= 1 )); then
        warn "$skill: only $placeholder_count placeholders (aim for 10+)"
    else
        fail "$skill: no [PLACEHOLDER] templates found"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 6. Defaults
# ─────────────────────────────────────────────
echo "── 6. Defaults ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    if grep -qi "default\|DEFAULTS" "$file"; then
        pass "$skill: has defaults"
    else
        fail "$skill: missing defaults section"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 7. Cross-skill handoffs
# ─────────────────────────────────────────────
echo "── 7. Cross-Skill Handoffs ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    if grep -q "OUTPUT_HANDOFF" "$file"; then
        handoff_count=$(grep -c "OUTPUT_HANDOFF" "$file" || true)
        pass "$skill: $handoff_count handoff(s) defined"
    else
        fail "$skill: no OUTPUT_HANDOFF found"
    fi

    if grep -q "next_skill" "$file"; then
        pass "$skill: handoffs specify next_skill"
    else
        fail "$skill: handoffs missing next_skill"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 8. Storage paths
# ─────────────────────────────────────────────
echo "── 8. Storage Paths ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    if grep -q "~/clawd/homeos/data/" "$file"; then
        pass "$skill: uses ~/clawd/homeos/data/"
    else
        fail "$skill: missing ~/clawd/homeos/data/ storage"
    fi

    if grep -q "~/clawd/homeos/memory/" "$file"; then
        pass "$skill: uses ~/clawd/homeos/memory/"
    else
        fail "$skill: missing ~/clawd/homeos/memory/ storage"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 9. No tables in templates
# ─────────────────────────────────────────────
echo "── 9. No Tables (bullet lists only) ──"
for skill in "${SKILLS[@]}"; do
    file="$SKILL_DIR/$skill/SKILL.md"
    [[ ! -f "$file" ]] && continue

    # Check for markdown table syntax (pipes with dashes)
    table_count=$(grep -cE "^\|.*\|.*\|" "$file" || true)
    if (( table_count == 0 )); then
        pass "$skill: no markdown tables found"
    else
        fail "$skill: $table_count table row(s) found — use bullet lists instead"
    fi
done
echo ""

# ─────────────────────────────────────────────
# 10. Skill-specific checks
# ─────────────────────────────────────────────
echo "── 10. Skill-Specific Rules ──"

# Healthcare: medical disclaimer, never diagnose
hc="$SKILL_DIR/healthcare/SKILL.md"
if [[ -f "$hc" ]]; then
    if grep -qi "disclaimer\|NOT a doctor\|not medical advice" "$hc"; then
        pass "healthcare: has medical disclaimer"
    else
        fail "healthcare: MISSING medical disclaimer"
    fi

    if grep -qi "NEVER diagnose\|NOT diagnose\|triage only" "$hc"; then
        pass "healthcare: states no diagnosis / triage only"
    else
        fail "healthcare: missing 'never diagnose / triage only' statement"
    fi

    if grep -qi "911\|emergency\|ER\|immediate care" "$hc"; then
        pass "healthcare: has emergency guidance"
    else
        fail "healthcare: missing emergency guidance"
    fi
fi

# Wellness: defaults for water, steps, sleep + age adjustment
wl="$SKILL_DIR/wellness/SKILL.md"
if [[ -f "$wl" ]]; then
    if grep -q "64 oz" "$wl"; then
        pass "wellness: has 64oz hydration default"
    else
        fail "wellness: missing 64oz hydration default"
    fi

    if grep -q "8.000\|8,000" "$wl"; then
        pass "wellness: has 8k steps default"
    else
        fail "wellness: missing 8k steps default"
    fi

    if grep -q "8 hour" "$wl"; then
        pass "wellness: has 8hr sleep default"
    else
        fail "wellness: missing 8hr sleep default"
    fi

    if grep -qi "child\|kid\|adult\|age\|teen" "$wl"; then
        pass "wellness: adjusts for age groups"
    else
        fail "wellness: no age-group adjustments"
    fi
fi

# Habits: explicit stage detection
hb="$SKILL_DIR/habits/SKILL.md"
if [[ -f "$hb" ]]; then
    if grep -qi "stage.*detection\|STAGE DETECTION\|stages of change" "$hb"; then
        pass "habits: has stage detection"
    else
        fail "habits: missing explicit stage detection"
    fi

    for stage in "contemplation" "preparation" "action" "maintenance"; do
        if grep -qi "$stage" "$hb"; then
            pass "habits: defines $stage stage"
        else
            fail "habits: missing $stage stage"
        fi
    done

    if grep -qi "trigger\|IF user says" "$hb"; then
        pass "habits: stage triggers are explicit (if user says X)"
    else
        fail "habits: stage triggers not explicit"
    fi

    if grep -qi "barrier\|BARRIER" "$hb"; then
        pass "habits: has barrier assessment"
    else
        fail "habits: missing barrier assessment"
    fi

    if grep -qi "stress\|STRESS" "$hb"; then
        pass "habits: has stress-aware nudging"
    else
        fail "habits: missing stress-aware nudging"
    fi
fi
echo ""

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo "═══════════════════════════════════════════"
TOTAL=$((PASS + FAIL + WARN))
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings ($TOTAL total)"
echo "═══════════════════════════════════════════"

if (( FAIL > 0 )); then
    echo "  ❌ SOME CHECKS FAILED"
    exit 1
else
    echo "  ✅ ALL CHECKS PASSED"
    exit 0
fi
