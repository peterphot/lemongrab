#!/usr/bin/env bash
# SessionStart hook: verify MCP connections and required tools
set -euo pipefail

errors=()

# Check required CLI tools
for cmd in git gh claude; do
  if ! command -v "$cmd" &>/dev/null; then
    errors+=("Missing required tool: $cmd")
  fi
done

# Check git repo context
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  errors+=("Not inside a git repository")
fi

# Check MCP servers are reachable by verifying claude plugins are enabled
if [ -f "$HOME/.claude/settings.json" ]; then
  if ! grep -q '"lemongrab@' "$HOME/.claude/settings.json" 2>/dev/null; then
    errors+=("Lemongrab plugin not enabled in ~/.claude/settings.json")
  fi
fi

# Report results
if [ ${#errors[@]} -gt 0 ]; then
  echo "ENVIRONMENT CHECK FAILED:"
  for err in "${errors[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

echo "Environment OK: git, gh, claude available; lemongrab plugin enabled."
