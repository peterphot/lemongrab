#!/usr/bin/env bash
# Verify test files were not modified by the implementer.
# Reads test file paths from task-status.json for the given task,
# then checks git diff for uncommitted changes to those files.
# Called by: orchestrator after implementer, before reviewers.
# Usage: verify-test-integrity.sh <task-status.json> <task-id>
# Exit 0 on pass, 1 on fail.
set -euo pipefail

STATUS_FILE="${1:-}"
TASK_ID="${2:-}"

if [ -z "$STATUS_FILE" ] || [ ! -f "$STATUS_FILE" ]; then
  echo "FAIL: task-status.json not found: ${STATUS_FILE:-<none>}"
  exit 1
fi
if [ -z "$TASK_ID" ]; then
  echo "FAIL: No task ID provided"
  exit 1
fi

# Extract test files for this task
if command -v jq &>/dev/null; then
  TEST_FILES=$(jq -r ".tasks.\"${TASK_ID}\".tddState.testFiles[]? // empty" "$STATUS_FILE" 2>/dev/null || true)
else
  echo "FAIL: jq required for verify-test-integrity.sh"
  exit 1
fi

if [ -z "$TEST_FILES" ]; then
  echo "PASS: No test files recorded for $TASK_ID (nothing to check)"
  exit 0
fi

# Check for uncommitted changes to test files
MODIFIED=()
for tf in $TEST_FILES; do
  if git diff --name-only -- "$tf" 2>/dev/null | grep -q .; then
    MODIFIED+=("$tf")
  fi
done

if [ ${#MODIFIED[@]} -gt 0 ]; then
  echo "FAIL: Test files modified by implementer (TDD_VIOLATION)"
  for f in "${MODIFIED[@]}"; do
    echo "  - $f"
  done
  echo "Restore with: git checkout -- ${MODIFIED[*]}"
  exit 1
fi

echo "PASS: Test files unmodified for $TASK_ID ($(echo "$TEST_FILES" | wc -w | tr -d ' ') files checked)"
