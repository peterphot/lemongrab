#!/usr/bin/env bash
# Verify a plan document has valid task structure.
# Checks: every task has 5 required sections, <=3 files per SCOPE,
# no banned vague phrases in ACs, no unresolved blocking markers.
# Called by: orchestrator after planner, before plan approval.
# Usage: verify-plan-structure.sh <plan-file>
# Exit 0 on pass, 1 on fail.
set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "FAIL: Plan file not found: ${FILE:-<none>}"
  exit 1
fi

ERRORS=()

# Extract task IDs
TASK_IDS=$(grep -oE '\[T[0-9]+\]' "$FILE" | sort -u | tr -d '[]')

if [ -z "$TASK_IDS" ]; then
  ERRORS+=("No tasks found (expected [TXXX] format)")
fi

# For each task, check required sections exist after its header
for TASK in $TASK_IDS; do
  # Extract the task block (from its header to the next task header or EOF)
  BLOCK=$(awk "/\[${TASK}\]/{found=1} found && /\[T[0-9]+\]/ && !/\[${TASK}\]/{exit} found{print}" "$FILE")

  for SECTION in "SCOPE:" "ACCEPTANCE CRITERIA:" "VERIFICATION METHOD:" "DONE DEFINITION:" "DEPENDENCY MAP:"; do
    if ! echo "$BLOCK" | grep -qi "$SECTION"; then
      ERRORS+=("[$TASK] missing section: $SECTION")
    fi
  done

  # Check <=3 files in SCOPE (count lines with [CREATE] or [MODIFY])
  SCOPE_FILES=$(echo "$BLOCK" | grep -cE '\[(CREATE|MODIFY)\]' 2>/dev/null || true)
  if [ "$SCOPE_FILES" -gt 3 ]; then
    ERRORS+=("[$TASK] SCOPE has $SCOPE_FILES files (max 3)")
  fi
done

# Check for banned vague phrases in the whole file
BANNED=(
  "should work correctly"
  "handles errors appropriately"
  "is well-structured"
  "performs well"
  "is user-friendly"
  "follows best practices"
  "is clean"
  "is readable"
  "properly handles"
)

for PHRASE in "${BANNED[@]}"; do
  if grep -qi "$PHRASE" "$FILE"; then
    ERRORS+=("Banned vague phrase found: \"$PHRASE\"")
  fi
done

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
  echo "FAIL: Plan structure verification failed for $FILE"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

echo "PASS: Plan structure verified: $FILE ($(echo "$TASK_IDS" | wc -w | tr -d ' ') tasks)"
