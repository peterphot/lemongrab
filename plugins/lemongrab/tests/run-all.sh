#!/usr/bin/env bash
# Run all lemongrab plugin tests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

echo "╔══════════════════════════════════════╗"
echo "║   Lemongrab Plugin Test Suite        ║"
echo "╚══════════════════════════════════════╝"
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
  name=$(basename "$test_file" .sh)
  echo ""
  echo "━━━ Running: $name ━━━"
  if bash "$test_file"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    FAILED_SUITES+=("$name")
  fi
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   Final Summary                      ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Suites passed: $TOTAL_PASS"
echo "Suites failed: $TOTAL_FAIL"

if [[ $TOTAL_FAIL -gt 0 ]]; then
  echo ""
  echo "Failed suites:"
  for suite in "${FAILED_SUITES[@]}"; do
    echo "  - $suite"
  done
  exit 1
else
  echo ""
  echo "All test suites passed!"
  exit 0
fi
