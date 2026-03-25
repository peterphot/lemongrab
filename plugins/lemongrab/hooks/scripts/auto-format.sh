#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Edit/Write
# Detects file type and runs the appropriate formatter.
# Falls back to trailing whitespace cleanup if no formatter is found.
# All output goes to stderr — stdout is reserved for JSON control in Claude Code hooks.
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*: *"//;s/"$//')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Find project root (for config files like .prettierrc, pyproject.toml)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

EXT="${FILE_PATH##*.}"
FORMATTED=false

# Helper: check if a command is actually functional (not just an asdf/mise shim)
is_runnable() {
  "$1" --version &>/dev/null
}

case "$EXT" in
  js|jsx|ts|tsx|css|scss|less|html|json|yaml|yml|graphql|vue|svelte)
    if command -v prettier &>/dev/null && is_runnable prettier; then
      prettier --write "$FILE_PATH" &>/dev/null && FORMATTED=true
    elif [ -x "$PROJECT_ROOT/node_modules/.bin/prettier" ]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  py)
    if command -v black &>/dev/null && is_runnable black; then
      black --quiet "$FILE_PATH" &>/dev/null && FORMATTED=true
    elif command -v ruff &>/dev/null && is_runnable ruff; then
      ruff format "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  go)
    if command -v gofmt &>/dev/null; then
      gofmt -w "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  rs)
    if command -v rustfmt &>/dev/null; then
      rustfmt "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  rb)
    if command -v rubocop &>/dev/null && is_runnable rubocop; then
      rubocop -a --fail-level error "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  swift)
    if command -v swift-format &>/dev/null; then
      swift-format format -i "$FILE_PATH" &>/dev/null && FORMATTED=true
    elif command -v swiftformat &>/dev/null; then
      swiftformat "$FILE_PATH" &>/dev/null && FORMATTED=true
    fi
    ;;
  md)
    # Markdown: just strip trailing whitespace (preserving intentional double-space line breaks)
    sed -i '' -E 's/[[:space:]]+$//' "$FILE_PATH" 2>/dev/null && FORMATTED=true
    ;;
esac

if [ "$FORMATTED" = true ]; then
  echo "Formatted: $FILE_PATH" >&2
fi
