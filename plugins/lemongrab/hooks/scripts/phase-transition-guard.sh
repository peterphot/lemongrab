#!/usr/bin/env bash
# PreToolUse hook: enforce legal phase transitions in the TDD workflow.
# Intercepts Write/Edit to current-phase.json and validates:
#   1. The transition is in the allowed transition table
#   2. Required artifacts exist before key phases (e.g., requirements before planning)
# Exit 0 to allow, exit 1 to block.
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Extract file_path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*: *"//;s/"$//')

# Only guard current-phase.json writes — fast exit for everything else
if [[ "$FILE_PATH" != *current-phase.json ]]; then
  exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$PROJECT_ROOT/docs/state/current-phase.json"

# Extract NEW phase from tool input
# For Write: full content contains "phase": "X" (may be escaped as \"phase\": \"X\")
# For Edit: new_string contains "phase": "X" (appears after old_string, so tail -1 gets it)
# Handle both escaped and unescaped JSON quotes by matching the pattern, then extracting uppercase value
NEW_PHASE=$(echo "$INPUT" | grep -oE '(\\?"|")phase(\\?"|")\s*:\s*(\\?"|")[A-Z_]+(\\?"|")' | tail -1 | grep -oE '[A-Z][A-Z_]+[A-Z]')

if [ -z "$NEW_PHASE" ]; then
  # Can't determine new phase (maybe updating a non-phase field) — allow
  exit 0
fi

# --- FRESH START: no state file yet ---
if [ ! -f "$STATE_FILE" ]; then
  case "$NEW_PHASE" in
    CLARIFY_IN_PROGRESS|MULTI_TICKET_SETUP|PLAN_IMPORT_VALIDATING)
      exit 0
      ;;
    *)
      echo "BLOCKED: First phase of a new workflow must be CLARIFY_IN_PROGRESS, MULTI_TICKET_SETUP, or PLAN_IMPORT_VALIDATING (got $NEW_PHASE)"
      echo "Every workflow starts with requirements gathering. No shortcuts."
      exit 1
      ;;
  esac
fi

# --- READ CURRENT STATE ---
if command -v jq &>/dev/null; then
  CURRENT_PHASE=$(jq -r '.phase // empty' "$STATE_FILE" 2>/dev/null || true)
  FEATURE=$(jq -r '.feature // empty' "$STATE_FILE" 2>/dev/null || true)
else
  CURRENT_PHASE=$(grep -oE '"phase"\s*:\s*"[^"]+"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
  FEATURE=$(grep -oE '"feature"\s*:\s*"[^"]+"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
fi

if [ -z "$CURRENT_PHASE" ]; then
  # State file exists but has no phase — treat as fresh start
  exit 0
fi

# Same-phase rewrite is always allowed (e.g., updating currentAgent or currentTask)
if [ "$CURRENT_PHASE" = "$NEW_PHASE" ]; then
  exit 0
fi

# --- TRANSITION TABLE ---
# Newline-separated list of "FROM>TO" pairs. Checked via grep.
TRANSITIONS="
CLARIFY_IN_PROGRESS>CLARIFY_COMPLETE
CLARIFY_COMPLETE>DESIGN_IN_PROGRESS
CLARIFY_COMPLETE>PLAN_IN_PROGRESS
DESIGN_IN_PROGRESS>DESIGN_COMPLETE
DESIGN_COMPLETE>PLAN_IN_PROGRESS
PLAN_IN_PROGRESS>PLAN_COMPLETE
PLAN_COMPLETE>PLAN_APPROVED
PLAN_APPROVED>BRANCH_CREATED
PLAN_APPROVED>COMPLETE
PLAN_IMPORT_VALIDATING>PLAN_IMPORT_VALIDATED
PLAN_IMPORT_VALIDATED>PLAN_APPROVED
BRANCH_CREATED>BUILD_IN_PROGRESS
BUILD_IN_PROGRESS>BUILD_COMPLETE
BUILD_COMPLETE>COHERENCE_REVIEW_IN_PROGRESS
BUILD_COMPLETE>PR_CREATED
COHERENCE_REVIEW_IN_PROGRESS>COHERENCE_REVIEW_COMPLETE
COHERENCE_REVIEW_COMPLETE>PR_CREATED
PR_CREATED>PR_REVIEW
PR_REVIEW>PR_REVIEW_FIXING
PR_REVIEW>DOCUMENT_IN_PROGRESS
PR_REVIEW_FIXING>PR_REVIEW
PR_REVIEW>MERGE_GATE_WAITING
MERGE_GATE_WAITING>MERGE_GATE_COMPLETE
MERGE_GATE_COMPLETE>DOCUMENT_IN_PROGRESS
MERGE_GATE_COMPLETE>CLARIFY_IN_PROGRESS
DOCUMENT_IN_PROGRESS>DOCUMENT_COMPLETE
DOCUMENT_COMPLETE>COMPLETE
PR_CREATED>DOCUMENT_IN_PROGRESS
MULTI_TICKET_SETUP>MULTI_TICKET_IN_PROGRESS
MULTI_TICKET_IN_PROGRESS>CLARIFY_IN_PROGRESS
MULTI_TICKET_IN_PROGRESS>PLAN_IMPORT_VALIDATING
MULTI_TICKET_IN_PROGRESS>MULTI_TICKET_COMPLETE
MULTI_TICKET_COMPLETE>COMPLETE
DOCUMENT_COMPLETE>MULTI_TICKET_IN_PROGRESS
MERGE_GATE_COMPLETE>MULTI_TICKET_IN_PROGRESS
"

KEY="${CURRENT_PHASE}>${NEW_PHASE}"

if ! echo "$TRANSITIONS" | grep -qx "$KEY"; then
  # Build list of valid targets for the error message
  VALID_TARGETS=$(echo "$TRANSITIONS" | grep "^${CURRENT_PHASE}>" | sed "s/^${CURRENT_PHASE}>//" | tr '\n' ', ' | sed 's/,$//')

  echo "BLOCKED: Illegal phase transition: $CURRENT_PHASE → $NEW_PHASE"
  echo "Valid transitions from $CURRENT_PHASE: ${VALID_TARGETS:-none}"
  echo ""
  echo "The workflow requires phases to proceed in order. You cannot skip phases."
  echo "If you need to restart, delete docs/state/current-phase.json first."
  exit 1
fi

# --- ARTIFACT PRECONDITIONS ---
# Before allowing certain transitions, verify required artifacts exist and are valid
case "$NEW_PHASE" in
  PLAN_IN_PROGRESS)
    if [ -n "$FEATURE" ]; then
      REQ_FILE="$PROJECT_ROOT/docs/requirements/${FEATURE}.md"
      if [ ! -f "$REQ_FILE" ]; then
        echo "BLOCKED: Cannot enter PLAN_IN_PROGRESS — requirements file missing: docs/requirements/${FEATURE}.md"
        echo "The clarifier must produce a requirements document before planning can begin."
        exit 1
      fi
      # Run verification script
      VERIFY_OUTPUT=$("$SCRIPT_DIR/verify-requirements.sh" "$REQ_FILE" 2>&1) || {
        echo "BLOCKED: Cannot enter PLAN_IN_PROGRESS — requirements verification failed:"
        echo "$VERIFY_OUTPUT"
        echo ""
        echo "Fix the requirements document before proceeding to planning."
        exit 1
      }
    fi
    ;;

  PLAN_APPROVED)
    if [ -n "$FEATURE" ]; then
      PLAN_FILE="$PROJECT_ROOT/docs/plans/${FEATURE}.md"
      if [ ! -f "$PLAN_FILE" ]; then
        echo "BLOCKED: Cannot enter PLAN_APPROVED — plan file missing: docs/plans/${FEATURE}.md"
        echo "The planner must produce a plan document before approval."
        exit 1
      fi
      # Run verification script
      VERIFY_OUTPUT=$("$SCRIPT_DIR/verify-plan-structure.sh" "$PLAN_FILE" 2>&1) || {
        echo "BLOCKED: Cannot enter PLAN_APPROVED — plan structure verification failed:"
        echo "$VERIFY_OUTPUT"
        echo ""
        echo "Fix the plan document before seeking approval."
        exit 1
      }
    fi
    ;;

  BUILD_IN_PROGRESS)
    # Verify the feature branch actually exists
    if command -v jq &>/dev/null; then
      BRANCH=$(jq -r '.branch // empty' "$STATE_FILE" 2>/dev/null || true)
    else
      BRANCH=$(grep -oE '"branch"\s*:\s*"[^"]+"' "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
    fi
    if [ -n "$BRANCH" ]; then
      if ! git branch --list "$BRANCH" 2>/dev/null | grep -q .; then
        echo "BLOCKED: Cannot enter BUILD_IN_PROGRESS — branch '$BRANCH' does not exist"
        echo "Create the feature branch before starting the build phase."
        exit 1
      fi
    fi
    ;;
esac

# Transition is valid
exit 0
