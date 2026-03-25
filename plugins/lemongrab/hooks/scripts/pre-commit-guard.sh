#!/usr/bin/env bash
# PreToolUse hook: run tests and linter on changed files before git commit
# Triggers when the Bash tool command contains "git commit"
# Blocks the commit if tests fail or linter reports errors.
set -euo pipefail

INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only intercept git commit commands
if ! echo "$INPUT" | grep -q 'git commit'; then
  exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

cd "$PROJECT_ROOT"
ERRORS=()

# Get changed files (staged for commit)
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [ -z "$CHANGED_FILES" ]; then
  # No staged files — might be using git commit -a
  CHANGED_FILES=$(git diff --name-only 2>/dev/null || true)
fi

# --- TEST DETECTION AND EXECUTION ---

run_tests() {
  # 1. Check for project-specific test script
  if [ -f "tests/test-plan-approval.sh" ]; then
    echo "Running project tests..."
    if ! bash tests/test-plan-approval.sh 2>&1 | tail -20; then
      ERRORS+=("Project tests failed")
      return
    fi
  fi

  # 2. Detect test framework and run relevant tests
  if [ -f "package.json" ]; then
    # Node.js: check if test script exists
    if grep -q '"test"' package.json 2>/dev/null; then
      echo "Running npm test..."
      if ! npm test 2>&1 | tail -30; then
        ERRORS+=("npm test failed")
      fi
    fi
  elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
    # Python: run pytest on changed test files or full suite
    CHANGED_TESTS=$(echo "$CHANGED_FILES" | grep -E '(test_.*\.py|.*_test\.py|tests/.*\.py)' || true)
    if [ -n "$CHANGED_TESTS" ]; then
      echo "Running changed tests..."
      if ! python3 -m pytest $CHANGED_TESTS --tb=short -q 2>&1 | tail -20; then
        ERRORS+=("pytest failed on changed files")
      fi
    elif command -v pytest &>/dev/null || python3 -c "import pytest" 2>/dev/null; then
      echo "Running pytest..."
      if ! python3 -m pytest --tb=short -q 2>&1 | tail -20; then
        ERRORS+=("pytest failed")
      fi
    fi
  elif [ -f "go.mod" ]; then
    echo "Running go test..."
    if ! go test ./... 2>&1 | tail -20; then
      ERRORS+=("go test failed")
    fi
  elif [ -f "Cargo.toml" ]; then
    echo "Running cargo test..."
    if ! cargo test 2>&1 | tail -30; then
      ERRORS+=("cargo test failed")
    fi
  fi
}

# --- LINT DETECTION AND EXECUTION ---

run_lint() {
  if [ -z "$CHANGED_FILES" ]; then
    return
  fi

  # Node.js linting
  if [ -f "package.json" ]; then
    JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
    if [ -n "$JS_FILES" ]; then
      if command -v eslint &>/dev/null || [ -x "node_modules/.bin/eslint" ]; then
        ESLINT_CMD="eslint"
        [ -x "node_modules/.bin/eslint" ] && ESLINT_CMD="node_modules/.bin/eslint"
        echo "Linting JS/TS files..."
        if ! echo "$JS_FILES" | xargs $ESLINT_CMD --no-error-on-unmatched-pattern 2>&1 | tail -20; then
          ERRORS+=("ESLint failed")
        fi
      fi
    fi
  fi

  # Python linting
  PY_FILES=$(echo "$CHANGED_FILES" | grep -E '\.py$' || true)
  if [ -n "$PY_FILES" ]; then
    if command -v ruff &>/dev/null; then
      echo "Linting Python files with ruff..."
      if ! echo "$PY_FILES" | xargs ruff check 2>&1 | tail -20; then
        ERRORS+=("ruff check failed")
      fi
    elif command -v flake8 &>/dev/null; then
      echo "Linting Python files with flake8..."
      if ! echo "$PY_FILES" | xargs flake8 2>&1 | tail -20; then
        ERRORS+=("flake8 failed")
      fi
    fi
  fi

  # Go linting
  GO_FILES=$(echo "$CHANGED_FILES" | grep -E '\.go$' || true)
  if [ -n "$GO_FILES" ]; then
    if command -v golangci-lint &>/dev/null; then
      echo "Linting Go files..."
      if ! golangci-lint run 2>&1 | tail -20; then
        ERRORS+=("golangci-lint failed")
      fi
    fi
  fi
}

run_tests
run_lint

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "" >&2
  echo "BLOCKED: Commit blocked by pre-commit guard." >&2
  for err in "${ERRORS[@]}"; do
    echo "  - $err" >&2
  done
  echo "" >&2
  echo "Fix the failures above before committing." >&2
  exit 2
fi

echo "Pre-commit checks passed." >&2
