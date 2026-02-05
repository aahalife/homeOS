#!/usr/bin/env bash
# test-services-cluster.sh — Validate all 6 small-model-friendly HomeOS skills
# Run: bash /tmp/homeOS/docs/homeskills/small-skills/test-services-cluster.sh

set -uo pipefail

PASS=0
FAIL=0
SKILLS_DIR="/tmp/homeOS/docs/homeskills/small-skills"

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

check_exists() {
  local skill="$1"
  local file="$SKILLS_DIR/$skill/SKILL.md"
  if [[ -f "$file" ]]; then
    pass "$skill/SKILL.md exists"
  else
    fail "$skill/SKILL.md MISSING"
    return 1
  fi
}

check_line_count() {
  local skill="$1"
  local max="$2"
  local file="$SKILLS_DIR/$skill/SKILL.md"
  local lines
  lines=$(wc -l < "$file")
  if [[ "$lines" -le "$max" ]]; then
    pass "$skill: $lines lines (≤$max)"
  else
    fail "$skill: $lines lines (EXCEEDS $max)"
  fi
}

check_contains() {
  local skill="$1"
  local pattern="$2"
  local label="$3"
  local file="$SKILLS_DIR/$skill/SKILL.md"
  if grep -qi "$pattern" "$file"; then
    pass "$skill: contains '$label'"
  else
    fail "$skill: MISSING '$label'"
  fi
}

check_no_tables() {
  local skill="$1"
  local file="$SKILLS_DIR/$skill/SKILL.md"
  # Tables have lines like "| x | y |" with multiple pipes
  if grep -qP '^\s*\|.*\|.*\|' "$file"; then
    fail "$skill: contains markdown tables (not allowed in templates)"
  else
    pass "$skill: no markdown tables"
  fi
}

check_has_handoff() {
  local skill="$1"
  local file="$SKILLS_DIR/$skill/SKILL.md"
  if grep -q "OUTPUT_HANDOFF" "$file"; then
    pass "$skill: has OUTPUT_HANDOFF"
  else
    fail "$skill: MISSING OUTPUT_HANDOFF"
  fi
}

echo ""
echo "═══════════════════════════════════════════════════"
echo " HomeOS Small-Skills Services Cluster — Test Suite"
echo "═══════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────────
echo "▶ 1. FILE EXISTENCE"
# ──────────────────────────────────────────────────
for skill in infrastructure chat-turn restaurant-reservation marketplace-sell hire-helper telephony; do
  check_exists "$skill"
done

# ──────────────────────────────────────────────────
echo ""
echo "▶ 2. LINE COUNT LIMITS"
# ──────────────────────────────────────────────────
check_line_count "infrastructure" 150
check_line_count "chat-turn" 300
check_line_count "restaurant-reservation" 300
check_line_count "marketplace-sell" 300
check_line_count "hire-helper" 300
check_line_count "telephony" 300

# ──────────────────────────────────────────────────
echo ""
echo "▶ 3. NO MARKDOWN TABLES"
# ──────────────────────────────────────────────────
for skill in infrastructure chat-turn restaurant-reservation marketplace-sell hire-helper telephony; do
  check_no_tables "$skill"
done

# ──────────────────────────────────────────────────
echo ""
echo "▶ 4. STORAGE PATHS (~/clawd/homeos/)"
# ──────────────────────────────────────────────────
for skill in infrastructure chat-turn restaurant-reservation marketplace-sell hire-helper telephony; do
  check_contains "$skill" "clawd/homeos" "storage path ~/clawd/homeos/"
done

# ──────────────────────────────────────────────────
echo ""
echo "▶ 5. CROSS-SKILL HANDOFFS"
# ──────────────────────────────────────────────────
check_has_handoff "infrastructure"
check_has_handoff "chat-turn"
check_has_handoff "restaurant-reservation"
check_has_handoff "telephony"
check_has_handoff "hire-helper"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 6. TELEPHONY — HIGH RISK RULES"
# ──────────────────────────────────────────────────
check_contains "telephony" "HIGH RISK" "HIGH RISK label"
check_contains "telephony" "ALWAYS" "ALWAYS approval"
check_contains "telephony" "NEVER.*call.*without" "never call without approval"
check_contains "telephony" "APPROVAL REQUIRED" "approval template"
check_contains "telephony" "YES.*NO" "YES/NO prompt"
check_contains "telephony" "maybe.*NOT" "rejects ambiguous responses"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 7. MARKETPLACE — SCAM CHECKLIST"
# ──────────────────────────────────────────────────
check_contains "marketplace-sell" "Overpayment" "overpayment scam"
check_contains "marketplace-sell" "Proxy.*scam\|mover.*assistant" "proxy/mover scam"
check_contains "marketplace-sell" "Ship.*before.*payment\|ship.*BEFORE" "ship-first scam"
check_contains "marketplace-sell" "Phishing\|verify.*identity\|confirm.*listing" "phishing links"
check_contains "marketplace-sell" "Off-platform\|off-platform" "off-platform comms"
check_contains "marketplace-sell" "Fake payment\|screenshot" "fake payment screenshot"
check_contains "marketplace-sell" "check.*money order\|Cashier" "fake check/money order"
check_contains "marketplace-sell" "Rush\|urgency" "rush pressure"
check_contains "marketplace-sell" "elaborate.*story\|complex.*story\|Too-complex" "complex story scam"
check_contains "marketplace-sell" "SCAM WARNING\|WARN" "scam warning output"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 8. HIRE-HELPER — BACKGROUND CHECKS"
# ──────────────────────────────────────────────────
check_contains "hire-helper" "STRONGLY RECOMMENDED" "strongly recommended for childcare"
check_contains "hire-helper" "background check" "background check mention"
check_contains "hire-helper" "Sex offender" "sex offender registry check"
check_contains "hire-helper" "children" "children context"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 9. CHAT-TURN — EXPLICIT ROUTING"
# ──────────────────────────────────────────────────
check_contains "chat-turn" "Priority 1" "priority ordering"
check_contains "chat-turn" "Priority 2" "multiple priorities"
check_contains "chat-turn" "contains ANY of" "explicit keyword matching"
check_contains "chat-turn" "ROUTE TO.*telephony" "routes to telephony"
check_contains "chat-turn" "ROUTE TO.*restaurant-reservation" "routes to restaurant"
check_contains "chat-turn" "ROUTE TO.*marketplace-sell" "routes to marketplace"
check_contains "chat-turn" "ROUTE TO.*hire-helper" "routes to hire-helper"
check_contains "chat-turn" "Ambiguous" "ambiguity handling"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 10. INFRASTRUCTURE — CORE REQUIREMENTS"
# ──────────────────────────────────────────────────
check_contains "infrastructure" "LOW.*risk\|LOW risk\|LOW\b" "LOW risk level"
check_contains "infrastructure" "MEDIUM.*risk\|MEDIUM risk\|MEDIUM\b" "MEDIUM risk level"
check_contains "infrastructure" "HIGH.*risk\|HIGH risk\|HIGH\b" "HIGH risk level"
check_contains "infrastructure" "APPROVAL REQUIRED" "approval template"
check_contains "infrastructure" "ERROR" "error handling"
check_contains "infrastructure" "Never silently fail" "no silent failures"
check_contains "infrastructure" "Cancel\|cancel" "cancel/interrupt support"

# ──────────────────────────────────────────────────
echo ""
echo "▶ 11. RISK LEVELS IN ALL SKILLS"
# ──────────────────────────────────────────────────
for skill in restaurant-reservation marketplace-sell hire-helper telephony; do
  check_contains "$skill" "risk:" "risk level in frontmatter"
done

# ──────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
echo " RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════"

if [[ "$FAIL" -gt 0 ]]; then
  echo " ⚠️  Some tests failed. Review above."
  exit 1
else
  echo " 🎉 All tests passed!"
  exit 0
fi
