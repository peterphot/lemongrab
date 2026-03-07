#!/usr/bin/env bash
# PreToolUse hook: run tests before git commit
# Only triggers when the Bash tool command contains "git commit"
set -euo pipefail

# The tool input is passed via environment variables
# CLAUDE_TOOL_INPUT contains the JSON of the tool call
INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only intercept git commit commands
if ! echo "$INPUT" | grep -q 'git commit'; then
  exit 0
fi

# Find the project root (where tests/ lives)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

TEST_SCRIPT="$PROJECT_ROOT/tests/test-plan-approval.sh"
if [ ! -f "$TEST_SCRIPT" ]; then
  exit 0
fi

echo "Running pre-commit tests..."
if ! bash "$TEST_SCRIPT"; then
  echo "BLOCKED: Tests failed. Fix failures before committing."
  exit 1
fi

echo "Pre-commit tests passed."
