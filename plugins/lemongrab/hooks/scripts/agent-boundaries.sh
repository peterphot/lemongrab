#!/usr/bin/env bash
# PreToolUse hook: enforce agent tool boundaries
# Reads currentAgent from docs/state/current-phase.json and blocks
# file writes that violate agent boundaries.
#
# Enforced boundaries:
#   test-writer    → can only Write/Edit files matching test/spec patterns
#   implementer    → cannot Write/Edit test files
#   reviewer       → cannot Write/Edit any file (read-only)
#   security-reviewer   → cannot Write/Edit any file (read-only)
#   performance-reviewer → cannot Write/Edit any file (read-only)
#   simplifier     → cannot Write/Edit test files
#   documenter     → can only Write/Edit docs/ files
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Find project root
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

STATE_FILE="$PROJECT_ROOT/docs/state/current-phase.json"
if [ ! -f "$STATE_FILE" ]; then
  # No active workflow — no boundaries to enforce
  exit 0
fi

# Extract currentAgent from state (requires jq or grep fallback)
if command -v jq &>/dev/null; then
  AGENT=$(jq -r '.currentAgent // empty' "$STATE_FILE" 2>/dev/null || true)
else
  AGENT=$(grep -oE '"currentAgent"\s*:\s*"[^"]+"' "$STATE_FILE" 2>/dev/null | sed 's/.*: *"//;s/"$//' || true)
fi

if [ -z "$AGENT" ]; then
  # No currentAgent set — orchestrator hasn't adopted this field yet
  exit 0
fi

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*: *"//;s/"$//')
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Normalize path relative to project root for pattern matching
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# Helper: check if path matches test file patterns
is_test_file() {
  local path="$1"
  echo "$path" | grep -qE '(test[_/.-]|[_/.-]test\.|spec[_/.-]|[_/.-]spec\.|__tests__/|tests/|test/|\.test\.|\.spec\.)' 2>/dev/null
}

# Helper: check if path is in docs/
is_docs_file() {
  local path="$1"
  echo "$path" | grep -qE '^docs/' 2>/dev/null
}

case "$AGENT" in
  test-writer)
    if ! is_test_file "$REL_PATH"; then
      echo "BLOCKED: test-writer agent cannot modify non-test file: $REL_PATH" >&2
      echo "Only test/spec files are allowed during the RED phase." >&2
      exit 2
    fi
    ;;
  implementer)
    if is_test_file "$REL_PATH"; then
      echo "BLOCKED: implementer agent cannot modify test file: $REL_PATH" >&2
      echo "Tests are written by test-writer. Implementer only writes production code." >&2
      exit 2
    fi
    ;;
  reviewer|security-reviewer|performance-reviewer)
    echo "BLOCKED: $AGENT agent is read-only and cannot modify: $REL_PATH" >&2
    echo "Reviewers analyze code but do not modify it." >&2
    exit 2
    ;;
  simplifier)
    if is_test_file "$REL_PATH"; then
      echo "BLOCKED: simplifier agent cannot modify test file: $REL_PATH" >&2
      echo "Simplifier refactors production code only. Tests must stay unchanged." >&2
      exit 2
    fi
    ;;
  documenter)
    if ! is_docs_file "$REL_PATH"; then
      echo "BLOCKED: documenter agent cannot modify non-docs file: $REL_PATH" >&2
      echo "Documenter only writes to docs/ directory." >&2
      exit 2
    fi
    ;;
  # clarifier, planner, analyzer, qa-engineer, ticket-manager, lemongrab — no file write restrictions
esac

exit 0
