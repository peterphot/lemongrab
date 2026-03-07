#!/usr/bin/env bash
# Test helpers for lemongrab plugin validation
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

assert_file_exists() {
  local file="$1"
  local desc="${2:-$file exists}"
  TOTAL=$((TOTAL + 1))
  if [[ -f "$PLUGIN_DIR/$file" ]]; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} $desc (file not found: $file)"
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local desc="${3:-$file contains '$pattern'}"
  TOTAL=$((TOTAL + 1))
  if [[ -f "$PLUGIN_DIR/$file" ]] && grep -q "$pattern" "$PLUGIN_DIR/$file"; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} $desc"
  fi
}

assert_frontmatter_field() {
  local file="$1"
  local field="$2"
  local desc="${3:-$file has frontmatter field '$field'}"
  TOTAL=$((TOTAL + 1))
  if [[ -f "$PLUGIN_DIR/$file" ]] && sed -n '/^---$/,/^---$/p' "$PLUGIN_DIR/$file" | grep -q "^${field}:"; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} $desc"
  fi
}

assert_dir_exists() {
  local dir="$1"
  local desc="${2:-$dir exists}"
  TOTAL=$((TOTAL + 1))
  if [[ -d "$PLUGIN_DIR/$dir" ]]; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} $desc (directory not found: $dir)"
  fi
}

print_summary() {
  echo ""
  echo "────────────────────────────────"
  if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}ALL TESTS PASSED${NC}: $PASS/$TOTAL"
  else
    echo -e "${RED}FAILURES${NC}: $FAIL failed, $PASS passed, $TOTAL total"
  fi
  echo "────────────────────────────────"
  return $FAIL
}
