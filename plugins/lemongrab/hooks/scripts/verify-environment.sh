#!/usr/bin/env bash
# SessionStart hook: verify environment, MCP connections, and interrupted workflows
set -euo pipefail

errors=()
warnings=()

# --- Required CLI tools ---
for cmd in git gh; do
  if ! command -v "$cmd" &>/dev/null; then
    errors+=("Missing required tool: $cmd")
  fi
done

# --- Git repo context ---
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  errors+=("Not inside a git repository")
fi

# --- Plugin enabled ---
if [ -f "$HOME/.claude/settings.json" ]; then
  if ! grep -q '"lemongrab@' "$HOME/.claude/settings.json" 2>/dev/null; then
    warnings+=("Lemongrab plugin not found in ~/.claude/settings.json")
  fi
fi

# --- Check for interrupted workflow ---
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_ROOT/docs/state/current-phase.json" ]; then
  if command -v jq &>/dev/null; then
    PHASE=$(jq -r '.phase // empty' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null || true)
    FEATURE=$(jq -r '.feature // empty' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null || true)
    STATUS=$(jq -r '.status // empty' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null || true)
  else
    PHASE=$(grep -oE '"phase"\s*:\s*"[^"]+"' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
    FEATURE=$(grep -oE '"feature"\s*:\s*"[^"]+"' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
    STATUS=$(grep -oE '"status"\s*:\s*"[^"]+"' "$PROJECT_ROOT/docs/state/current-phase.json" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"$//' || true)
  fi

  if [ -n "$PHASE" ] && [ "$PHASE" != "COMPLETE" ] && [ "$STATUS" = "in_progress" ]; then
    warnings+=("INTERRUPTED WORKFLOW DETECTED: feature='$FEATURE' phase='$PHASE'. Run /resume $FEATURE to continue.")
  fi
fi

# --- Check MCP server availability ---
# These are informational — missing MCP only matters for specific workflows
check_mcp_hint() {
  local name="$1"
  local pattern="$2"
  local workflow="$3"
  if [ -f "$HOME/.claude/settings.json" ]; then
    if ! grep -q "$pattern" "$HOME/.claude/settings.json" 2>/dev/null; then
      warnings+=("MCP '$name' not detected — needed for $workflow")
    fi
  fi
}

check_mcp_hint "Linear" "plugin_forge_linear\|claude_ai_Linear" "/ticket workflows"
check_mcp_hint "Notion" "plugin_forge_notion\|claude_ai_Notion" "PRD/RFC workflows"

# --- Check for jq (recommended for hooks) ---
if ! command -v jq &>/dev/null; then
  warnings+=("jq not installed — some hooks will run in degraded mode. Install with: brew install jq")
fi

# --- Report ---
if [ ${#errors[@]} -gt 0 ]; then
  echo "ENVIRONMENT CHECK FAILED:"
  for err in "${errors[@]}"; do
    echo "  ✗ $err"
  done
  exit 1
fi

echo "Environment OK: git, gh available; lemongrab plugin enabled."

if [ ${#warnings[@]} -gt 0 ]; then
  echo ""
  for warn in "${warnings[@]}"; do
    echo "  ⚠ $warn"
  done
fi
