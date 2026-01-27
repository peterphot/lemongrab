---
name: enforcing-tdd
description: Enforce Test-Driven Development discipline with red-green-refactor patterns. Use when writing tests before code, implementing to pass tests, or ensuring TDD compliance. Provides test quality checklists, requirement traceability, mutation testing mindset, and minimum code principles.
---

# Enforcing TDD

This skill enforces strict Test-Driven Development discipline. It activates when writing tests, implementing code to pass tests, or reviewing TDD compliance.

## When to Use

- Writing tests BEFORE implementation code
- Implementing code to pass failing tests
- Verifying tests fail for the RIGHT reason
- Ensuring requirement-to-test traceability
- Applying mutation testing mindset

## The TDD Mantra

```
RED    → Write a failing test
GREEN  → Write minimum code to pass
REFACTOR → Clean up, tests stay green
REPEAT → Next failing test
```

**Critical**: Never write production code without a failing test demanding it.

## Test Writing Discipline

### Requirement Traceability

Every test MUST link to a requirement:

```javascript
describe('[US1] User Authentication', () => {
  describe('[FR-001] Login', () => {
    it('should authenticate user with valid credentials', ...)
    it('should reject invalid password', ...)
  });
});
```

### Verify Failure Reason

Tests must fail for the RIGHT reason:

| Failure Type | Correct? | Example |
|--------------|----------|---------|
| Function not defined | Yes | `ReferenceError: loginUser is not defined` |
| Module not found | Yes | `Cannot find module './auth'` |
| Assertion failed | Yes | `Expected undefined to equal true` |
| Syntax error in test | **NO** | `SyntaxError: Unexpected token` |
| Missing test helper | **NO** | `Cannot find module './test-utils'` |

If test fails for wrong reason → fix test first.

### Test Quality Checklist

For each test verify:

- [ ] Tests ONE behavior (single assertion focus)
- [ ] Name describes expected behavior
- [ ] Includes requirement ID for traceability
- [ ] Independent (no dependency on other tests)
- [ ] Deterministic (same result every run)
- [ ] Fast (no unnecessary delays)

### Coverage Requirements

For each acceptance criterion:

1. **Happy path** - Normal successful case
2. **Boundary cases** - Edge of valid input
3. **Error cases** - Invalid input, unauthorized
4. **State transitions** - Before/after for mutations

## Implementation Discipline

### Minimum Code Principle

Before writing ANY line, ask: "Which failing test demands this?"

```
✗ Adding validation no test checks
✗ Adding error handling not tested
✗ Adding logging or debugging
✗ Adding "defensive" code "just in case"
✓ Only code that makes RED turn GREEN
```

### One Test at a Time

```
1. Run tests → ALL FAIL (baseline)
2. Pick ONE failing test (simplest first)
3. Write MINIMUM code for THAT test
4. Run tests → ONE more passes
5. Repeat until all pass
6. STOP WRITING CODE
```

### Code Coverage Verification

After implementation, trace each line:

```
function login(email, password) {     // test_login_valid
  if (!email) return { error: '...' }; // test_login_missing_email
  if (!password) return { error: '...' }; // test_login_missing_password
  // ...
}
```

Any line without a test → delete it or add a test.

## Mutation Testing Mindset

Ask: "If someone changed this, would a test fail?"

| Mutation | Should Break Test |
|----------|-------------------|
| Change `>` to `>=` | Yes |
| Change `&&` to `\|\|` | Yes |
| Remove a line | Yes |
| Change a constant | Yes |
| Return early | Yes |

If mutation wouldn't break a test → coverage is weak.

## Anti-Patterns

### Test Anti-Patterns
- Testing implementation details instead of behavior
- Shared mutable state between tests
- Tests that depend on execution order
- Overly complex test setup

### Implementation Anti-Patterns
- Writing code before tests exist
- Implementing multiple tests at once
- Adding "while I'm here" improvements
- Refactoring before all tests pass

## Output Templates

### Test Report
```
## Test Report: Task [TXXX]

### Requirement Traceability
| Requirement | Test(s) | Status |
|-------------|---------|--------|
| FR-001 | test_login_valid | Covered |
| FR-002 | (none) | NEEDS TEST |

### Failure Verification
All tests fail for CORRECT reasons: YES/NO
```

### Implementation Report
```
## Implementation Report: Task [TXXX]

### TDD Cycle Log
| Test | Code Written | Lines |
|------|--------------|-------|
| test_login | Created login() | 5 |

### Untested Code Paths: NONE / LIST
```
