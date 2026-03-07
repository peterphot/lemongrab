#!/usr/bin/env bash
# PostToolUse hook: track git commit checkpoints in task-status.json
# After any git commit, extracts the commit hash and updates the current
# task's checkpoint field in docs/state/task-status.json.
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only trigger on git commit commands
if ! echo "$INPUT" | grep -q 'git commit'; then
  exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

STATUS_FILE="$PROJECT_ROOT/docs/state/task-status.json"
PHASE_FILE="$PROJECT_ROOT/docs/state/current-phase.json"

# Both state files must exist
if [ ! -f "$STATUS_FILE" ] || [ ! -f "$PHASE_FILE" ]; then
  exit 0
fi

# Get the latest commit hash
COMMIT_HASH=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || true)
if [ -z "$COMMIT_HASH" ]; then
  exit 0
fi

# Get current task ID from phase file
if command -v jq &>/dev/null; then
  CURRENT_TASK=$(jq -r '.currentTask // empty' "$PHASE_FILE" 2>/dev/null || true)
else
  CURRENT_TASK=$(grep -oE '"currentTask"\s*:\s*"[^"]+"' "$PHASE_FILE" 2>/dev/null | sed 's/.*: *"//;s/"$//' || true)
fi

if [ -z "$CURRENT_TASK" ]; then
  exit 0
fi

# Update task-status.json with checkpoint (requires jq for safe JSON update)
if command -v jq &>/dev/null; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  TMP_FILE=$(mktemp)
  jq --arg task "$CURRENT_TASK" \
     --arg hash "$COMMIT_HASH" \
     --arg ts "$TIMESTAMP" \
     'if .tasks[$task] then
        .tasks[$task].checkpoint = $hash |
        .tasks[$task].lastUpdated = $ts
      else . end' \
     "$STATUS_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATUS_FILE"
  echo "Checkpoint: $CURRENT_TASK → $COMMIT_HASH"
else
  # Without jq, log but don't modify (avoid corrupting JSON)
  echo "Checkpoint logged: $CURRENT_TASK → $COMMIT_HASH (install jq for auto-tracking)"
fi
