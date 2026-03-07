#!/usr/bin/env bash
# Verify state files are consistent with artifacts on disk.
# Checks that every file claimed in task-status.json actually exists.
# Called by: orchestrator at resume start.
# Usage: verify-state-consistency.sh [project-root]
# Exit 0 on pass, 1 on fail.
set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
STATUS_FILE="$PROJECT_ROOT/docs/state/task-status.json"

if [ ! -f "$STATUS_FILE" ]; then
  echo "PASS: No task-status.json found (nothing to verify)"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "FAIL: jq required for verify-state-consistency.sh"
  exit 1
fi

ERRORS=()

# Check all file paths claimed in tddState for each task
TASK_IDS=$(jq -r '.tasks // {} | keys[]' "$STATUS_FILE" 2>/dev/null || true)

for TASK in $TASK_IDS; do
  # Test files
  for tf in $(jq -r ".tasks.\"${TASK}\".tddState.testFiles[]? // empty" "$STATUS_FILE" 2>/dev/null); do
    if [ ! -f "$PROJECT_ROOT/$tf" ] && [ ! -f "$tf" ]; then
      ERRORS+=("[$TASK] testFile missing: $tf")
    fi
  done

  # Implementation files
  for impl in $(jq -r ".tasks.\"${TASK}\".tddState.implementationFiles[]? // empty" "$STATUS_FILE" 2>/dev/null); do
    if [ ! -f "$PROJECT_ROOT/$impl" ] && [ ! -f "$impl" ]; then
      ERRORS+=("[$TASK] implementationFile missing: $impl")
    fi
  done

  # Manifest file
  MANIFEST=$(jq -r ".tasks.\"${TASK}\".tddState.manifestFile // empty" "$STATUS_FILE" 2>/dev/null || true)
  if [ -n "$MANIFEST" ] && [ ! -f "$PROJECT_ROOT/$MANIFEST" ] && [ ! -f "$MANIFEST" ]; then
    ERRORS+=("[$TASK] manifestFile missing: $MANIFEST")
  fi
done

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "FAIL: State/disk inconsistency found (${#ERRORS[@]} issues)"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
  echo "These tasks may need to be re-run. The claimed files do not exist on disk."
  exit 1
fi

TASK_COUNT=$(echo "$TASK_IDS" | wc -w | tr -d ' ')
echo "PASS: State consistent ($TASK_COUNT tasks verified against disk)"
