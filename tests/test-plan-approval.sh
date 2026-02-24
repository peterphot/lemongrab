#!/usr/bin/env bash
#
# Tests for plan approval enforcement in lemongrab.md
# Validates that plan approval is a hard gate across all workflows.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LEMONGRAB_MD="$SCRIPT_DIR/../plugins/lemongrab/agents/lemongrab.md"

PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  echo "  PASS: $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "  FAIL: $1"
}

# Portable "extract section between two patterns, excluding the trailing delimiter".
# Usage: extract_section <start_pattern> <end_pattern> <file>
extract_section() {
  awk "
    /$1/ { found=1; start=NR; print; next }
    found && /$2/ && NR>start { exit }
    found { print }
  " "$3"
}

# --------------------------------------------------------------------------
# Test 1: STANDARD workflow — plan approval exists before build
# --------------------------------------------------------------------------
echo "Test 1: STANDARD workflow has plan approval before build"

standard_section=$(extract_section '^WORKFLOW: STANDARD' '^WORKFLOW:' "$LEMONGRAB_MD")

if echo "$standard_section" | grep -q 'PLAN APPROVAL'; then
  pass "STANDARD workflow contains PLAN APPROVAL step"
else
  fail "STANDARD workflow missing PLAN APPROVAL step"
fi

approval_line=$(echo "$standard_section" | grep -n 'PLAN APPROVAL' | head -1 | cut -d: -f1)
build_line=$(echo "$standard_section" | grep -n 'BUILD' | head -1 | cut -d: -f1)

if [ -n "$approval_line" ] && [ -n "$build_line" ] && [ "$approval_line" -lt "$build_line" ]; then
  pass "PLAN APPROVAL appears before BUILD in STANDARD workflow"
else
  fail "PLAN APPROVAL does not appear before BUILD (approval line: ${approval_line:-?}, build line: ${build_line:-?})"
fi

# --------------------------------------------------------------------------
# Test 2: TICKET workflow — plan approval is not skipped
# --------------------------------------------------------------------------
echo "Test 2: TICKET workflow includes plan approval"

ticket_section=$(extract_section '^WORKFLOW: TICKET' '^WORKFLOW:' "$LEMONGRAB_MD")

if echo "$ticket_section" | grep -q 'PLAN APPROVAL'; then
  pass "TICKET workflow contains PLAN APPROVAL step"
else
  fail "TICKET workflow missing PLAN APPROVAL step"
fi

if echo "$ticket_section" | grep -qE '^[0-9]+\. PLAN APPROVAL'; then
  pass "PLAN APPROVAL is an explicit numbered step in TICKET workflow"
else
  fail "PLAN APPROVAL is not an explicit numbered step in TICKET workflow"
fi

ticket_approval_line=$(echo "$ticket_section" | grep -n 'PLAN APPROVAL' | head -1 | cut -d: -f1)
ticket_tickets_line=$(echo "$ticket_section" | grep -n 'TICKETS' | head -1 | cut -d: -f1)
ticket_build_line=$(echo "$ticket_section" | grep -n 'BUILD' | head -1 | cut -d: -f1)

if [ -n "$ticket_approval_line" ] && [ -n "$ticket_tickets_line" ] && [ "$ticket_approval_line" -lt "$ticket_tickets_line" ]; then
  pass "PLAN APPROVAL appears before TICKETS in TICKET workflow"
else
  fail "PLAN APPROVAL does not appear before TICKETS in TICKET workflow"
fi

if [ -n "$ticket_approval_line" ] && [ -n "$ticket_build_line" ] && [ "$ticket_approval_line" -lt "$ticket_build_line" ]; then
  pass "PLAN APPROVAL appears before BUILD in TICKET workflow"
else
  fail "PLAN APPROVAL does not appear before BUILD in TICKET workflow"
fi

# --------------------------------------------------------------------------
# Test 3: Resume from PLAN_COMPLETE lands at plan approval
# --------------------------------------------------------------------------
echo "Test 3: Resume from PLAN_COMPLETE state lands at plan approval"

resume_section=$(extract_section '^RESUME PROCEDURE' '^[A-Z][A-Z ]*:' "$LEMONGRAB_MD")

plan_complete_row=$(echo "$resume_section" | grep 'PLAN_COMPLETE' || true)

if [ -n "$plan_complete_row" ]; then
  pass "PLAN_COMPLETE state exists in resume table"
else
  fail "PLAN_COMPLETE state missing from resume table"
fi

if echo "$plan_complete_row" | grep -qi 'plan approval\|present plan'; then
  pass "PLAN_COMPLETE resumes at plan approval step"
else
  fail "PLAN_COMPLETE does not resume at plan approval step (row: $plan_complete_row)"
fi

# --------------------------------------------------------------------------
# Test 4: PRD workflow mentions plan approval
# --------------------------------------------------------------------------
echo "Test 4: PRD workflow includes plan approval reference"

prd_section=$(extract_section '^WORKFLOW: PRD' '^WORKFLOW:' "$LEMONGRAB_MD")

if echo "$prd_section" | grep -qi 'PLAN APPROVAL'; then
  pass "PRD workflow references PLAN APPROVAL"
else
  fail "PRD workflow does not reference PLAN APPROVAL"
fi

# --------------------------------------------------------------------------
# Test 5: RFC workflow mentions plan approval
# --------------------------------------------------------------------------
echo "Test 5: RFC workflow includes plan approval reference"

rfc_section=$(extract_section '^WORKFLOW: RFC' '^WORKFLOW:' "$LEMONGRAB_MD")

if echo "$rfc_section" | grep -qi 'PLAN APPROVAL'; then
  pass "RFC workflow references PLAN APPROVAL"
else
  fail "RFC workflow does not reference PLAN APPROVAL"
fi

# --------------------------------------------------------------------------
# Test 6: BOOTSTRAP workflow mentions plan approval
# --------------------------------------------------------------------------
echo "Test 6: BOOTSTRAP workflow includes plan approval reference"

bootstrap_section=$(extract_section '^WORKFLOW: BOOTSTRAP' '^STATE MANAGEMENT:' "$LEMONGRAB_MD")

if echo "$bootstrap_section" | grep -qi 'PLAN APPROVAL'; then
  pass "BOOTSTRAP workflow references PLAN APPROVAL"
else
  fail "BOOTSTRAP workflow does not reference PLAN APPROVAL"
fi

# --------------------------------------------------------------------------
# Test 7: PLAN APPROVAL ENFORCEMENT section exists with strong language
# --------------------------------------------------------------------------
echo "Test 7: PLAN APPROVAL ENFORCEMENT section exists"

if grep -q '^PLAN APPROVAL ENFORCEMENT:' "$LEMONGRAB_MD"; then
  pass "PLAN APPROVAL ENFORCEMENT section exists"
else
  fail "PLAN APPROVAL ENFORCEMENT section missing"
fi

if grep -A 10 '^PLAN APPROVAL ENFORCEMENT:' "$LEMONGRAB_MD" | grep -q 'STANDARD, TICKET, PRD, RFC, and BOOTSTRAP'; then
  pass "Enforcement covers all workflow types"
else
  fail "Enforcement does not explicitly list all workflow types"
fi

if grep -q '\[PLAN_APPROVAL\].*HARD GATE' "$LEMONGRAB_MD"; then
  pass "PLAN_APPROVAL is marked as HARD GATE in YOUR PROCESS"
else
  fail "PLAN_APPROVAL not marked as HARD GATE in YOUR PROCESS"
fi

# --------------------------------------------------------------------------
# Test 8: TICKET workflow step numbering is sequential
# --------------------------------------------------------------------------
echo "Test 8: TICKET workflow has sequential step numbering"

ticket_steps=$(echo "$ticket_section" | grep -oE '^[0-9]+\.' | sed 's/\.//' | sort -n)
expected_seq=$(echo "$ticket_steps" | head -1)
sequential=true

for step in $ticket_steps; do
  if [ "$step" -ne "$expected_seq" ]; then
    sequential=false
    break
  fi
  expected_seq=$((expected_seq + 1))
done

if $sequential; then
  pass "TICKET workflow step numbers are sequential"
else
  fail "TICKET workflow step numbers are not sequential (found: $(echo "$ticket_steps" | tr '\n' ' '))"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
