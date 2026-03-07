#!/usr/bin/env bash
# Verify the coverage manifest maps every AC from the plan for a task.
# Called by: orchestrator after test-writer, before implementer.
# Usage: verify-manifest-coverage.sh <plan-file> <task-id> <manifest-file>
# Exit 0 on pass, 1 on fail.
set -euo pipefail

PLAN="${1:-}"
TASK_ID="${2:-}"
MANIFEST="${3:-}"

if [ -z "$PLAN" ] || [ ! -f "$PLAN" ]; then
  echo "FAIL: Plan file not found: ${PLAN:-<none>}"
  exit 1
fi
if [ -z "$TASK_ID" ]; then
  echo "FAIL: No task ID provided"
  exit 1
fi
if [ -z "$MANIFEST" ] || [ ! -f "$MANIFEST" ]; then
  echo "FAIL: Manifest file not found: ${MANIFEST:-<none>}"
  exit 1
fi

# Extract AC numbers from the plan for this task
# Look for lines like "1. ..." or "AC-1" under the task's ACCEPTANCE CRITERIA section
TASK_BLOCK=$(awk "/\[${TASK_ID}\]/{found=1} found && /\[T[0-9]+\]/ && !/\[${TASK_ID}\]/{exit} found{print}" "$PLAN")
AC_SECTION=$(echo "$TASK_BLOCK" | awk '/ACCEPTANCE CRITERIA/{found=1; next} /^\*\*[A-Z]/{if(found) exit} found{print}')

# Count numbered criteria (lines starting with digit)
PLAN_ACS=$(echo "$AC_SECTION" | grep -cE '^[0-9]+\.' 2>/dev/null || true)

if [ "$PLAN_ACS" -eq 0 ]; then
  echo "FAIL: No acceptance criteria found in plan for $TASK_ID"
  exit 1
fi

# Check manifest has a row for each AC number
MISSING=()
for i in $(seq 1 "$PLAN_ACS"); do
  if ! grep -qE "AC-${i}[^0-9]" "$MANIFEST"; then
    MISSING+=("AC-$i")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "FAIL: Manifest missing coverage for ${#MISSING[@]} acceptance criteria"
  for ac in "${MISSING[@]}"; do
    echo "  - $ac not found in $MANIFEST"
  done
  exit 1
fi

echo "PASS: Manifest covers all $PLAN_ACS acceptance criteria for $TASK_ID"
