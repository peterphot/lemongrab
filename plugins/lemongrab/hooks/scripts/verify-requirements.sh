#!/usr/bin/env bash
# Verify a requirements document has all required sections and no unresolved markers.
# Called by: orchestrator after clarifier, before planner.
# Usage: verify-requirements.sh <requirements-file>
# Exit 0 on pass, 1 on fail.
set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "FAIL: Requirements file not found: ${FILE:-<none>}"
  exit 1
fi

ERRORS=()

# Check required sections
if ! grep -q '^## Edge Cases' "$FILE"; then
  ERRORS+=("Missing required section: ## Edge Cases")
fi

if ! grep -q '^## In Scope / Out of Scope' "$FILE"; then
  ERRORS+=("Missing required section: ## In Scope / Out of Scope")
fi

# Check for at least one testable acceptance criterion (numbered list item)
if ! grep -qE '^[0-9]+\.' "$FILE"; then
  ERRORS+=("No numbered acceptance criteria found")
fi

# Check for unresolved blocking markers
ASSUMPTIONS=$(grep -c '\[ASSUMPTION:' "$FILE" 2>/dev/null || true)
BLOCKING=$(grep -c '\[DECISION: BLOCKING:' "$FILE" 2>/dev/null || true)

if [ "$ASSUMPTIONS" -gt 0 ]; then
  ERRORS+=("$ASSUMPTIONS unresolved [ASSUMPTION:] marker(s)")
fi
if [ "$BLOCKING" -gt 0 ]; then
  ERRORS+=("$BLOCKING unresolved [DECISION: BLOCKING:] marker(s)")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "FAIL: Requirements verification failed for $FILE"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

echo "PASS: Requirements document verified: $FILE"
