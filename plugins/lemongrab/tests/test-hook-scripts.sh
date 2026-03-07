#!/usr/bin/env bash
# Validate hook scripts are executable and have proper structure
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

echo "=== Hook Script Tests ==="

echo ""
echo "--- hooks.json exists ---"
assert_file_exists "hooks/hooks.json" "hooks.json exists"

echo ""
echo "--- Hook scripts are executable ---"
if [[ -d "$PLUGIN_DIR/hooks/scripts" ]]; then
  for script in "$PLUGIN_DIR"/hooks/scripts/*.sh; do
    if [[ -f "$script" ]]; then
      name=$(basename "$script")
      TOTAL=$((TOTAL + 1))
      if [[ -x "$script" ]]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} ${name} is executable"
      else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} ${name} is NOT executable"
      fi
    fi
  done
else
  echo "  (no hooks/scripts directory found)"
fi

echo ""
echo "--- Hook scripts have shebangs ---"
if [[ -d "$PLUGIN_DIR/hooks/scripts" ]]; then
  for script in "$PLUGIN_DIR"/hooks/scripts/*.sh; do
    if [[ -f "$script" ]]; then
      name=$(basename "$script")
      TOTAL=$((TOTAL + 1))
      if head -1 "$script" | grep -q '^#!/'; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}PASS${NC} ${name} has shebang"
      else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}FAIL${NC} ${name} missing shebang"
      fi
    fi
  done
fi

echo ""
echo "--- hooks.json references existing scripts ---"
if [[ -f "$PLUGIN_DIR/hooks/hooks.json" ]]; then
  # Extract script filenames from hooks.json (strip template variables like ${CLAUDE_PLUGIN_ROOT})
  scripts=$(grep -oE '[a-zA-Z0-9_-]+\.sh' "$PLUGIN_DIR/hooks/hooks.json" | sort -u || true)
  for script_name in $scripts; do
    TOTAL=$((TOTAL + 1))
    if [[ -f "$PLUGIN_DIR/hooks/scripts/$script_name" ]]; then
      PASS=$((PASS + 1))
      echo -e "  ${GREEN}PASS${NC} Referenced script exists: $script_name"
    else
      FAIL=$((FAIL + 1))
      echo -e "  ${RED}FAIL${NC} Referenced script missing: $script_name"
    fi
  done
fi

print_summary
