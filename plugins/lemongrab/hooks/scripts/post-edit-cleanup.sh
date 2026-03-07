#!/usr/bin/env bash
# PostToolUse hook: clean up trailing whitespace in edited markdown files
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*: *"//;s/"$//')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only process markdown files
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Only process if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Remove trailing whitespace (preserving intentional double-space line breaks)
# sed: remove trailing spaces/tabs except when line ends with exactly 2 spaces (md line break)
sed -i '' -E 's/[[:space:]]+$//' "$FILE_PATH"
