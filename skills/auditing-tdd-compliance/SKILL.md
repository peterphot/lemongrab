---
name: auditing-tdd-compliance
description: Audit code for TDD compliance by detecting untested code paths, weak test coverage, and TDD violations. Use when reviewing implementations, validating test coverage, or checking that all code is demanded by tests. Provides mutation testing analysis and compliance verdicts.
---

# Auditing TDD Compliance

This skill audits implementations for strict TDD compliance. It detects untested code, weak coverage, and violations of test-driven principles.

## When to Use

- Reviewing code after implementation
- Validating test-to-code coverage
- Detecting untested conditional branches
- Performing mutation testing analysis
- Issuing TDD compliance verdicts

## TDD Compliance Audit Process

### Step 1: Verify Tests Pass

```bash
# Run test suite first
npm test  # or pytest, go test, etc.
```

If tests fail → STOP. Return to implementer.

### Step 2: Code-to-Test Traceability

For EVERY line of production code, identify which test exercises it:

```
Code Line                              → Test
─────────────────────────────────────────────────────
function login(email, password) {      → test_login_valid
  if (!email) {                        → test_login_missing_email
    return { error: 'Email required' };
  }
  if (!password) {                     → test_login_missing_password
    return { error: 'Password required' };
  }
  // validate credentials...           → test_login_valid, test_login_invalid
}
```

**Any line with no test = TDD VIOLATION**

### Step 3: Untested Code Detection

Specifically search for:

| Pattern | What to Check |
|---------|---------------|
| `if/else` | Both branches tested? |
| `switch/case` | Every case tested? |
| `try/catch` | Error path tested? |
| `?:` ternary | Both outcomes tested? |
| `&&` / `\|\|` | Short-circuit paths tested? |
| Default values | Tested with and without? |
| Null checks | Null case tested? |
| Loop bounds | Empty, one, many tested? |

### Step 4: Mutation Testing Analysis

Mentally apply these mutations and check if a test would catch them:

| Mutation | Example | Test Should Fail? |
|----------|---------|-------------------|
| Comparison flip | `>` → `>=` | Yes |
| Operator swap | `&&` → `\|\|` | Yes |
| Constant change | `100` → `101` | Yes |
| Negate condition | `if (x)` → `if (!x)` | Yes |
| Remove line | Delete statement | Yes |
| Return early | Add `return` | Yes |
| Boundary shift | `< 10` → `< 11` | Yes |

**If any mutation would NOT be caught → weak test coverage**

### Step 5: Requirement Coverage Check

Cross-reference requirements document:

```
Requirement → Implementation → Test
───────────────────────────────────────────
FR-001      → login()       → test_login_* ✓
FR-002      → logout()      → test_logout_* ✓
FR-003      → resetPassword → (no tests)   ✗
```

Every requirement needs implementation AND tests.

## Compliance Verdicts

### APPROVED
- All tests pass
- Every code line traced to a test
- No untested branches
- Mutations would be caught
- Requirements fully covered

### NEEDS_FIXES
- Tests pass BUT
- Minor gaps in coverage
- Some weak tests identified
- Can proceed with warnings

### TDD_VIOLATION
- Untested code paths found
- Code exists that no test demands
- **Must return to test-writer FIRST**
- Then re-implement

## Audit Report Template

```markdown
## TDD Compliance Audit: Task [TXXX]

### Tests: PASSING / FAILING

### Code-to-Test Traceability
| Code Section | Exercised By | Status |
|--------------|--------------|--------|
| login() L1-5 | test_login_valid | ✓ |
| login() L6-8 | test_login_invalid | ✓ |
| login() L9 | (none) | ✗ UNTESTED |

### Untested Code Paths
- [ ] Line 9: Error handling for network timeout
- [ ] Line 15: Else branch of validation

### Mutation Testing
| Mutation | Would Test Catch? |
|----------|-------------------|
| L3: > to >= | ✓ test_boundary |
| L7: && to \|\| | ✗ NO TEST |

### Requirement Coverage
| Req | Implemented | Tested | Status |
|-----|-------------|--------|--------|
| FR-001 | ✓ | ✓ | Complete |
| FR-002 | ✓ | ✗ | Missing test |

### Issues Found
**CRITICAL:**
- Untested code at line 9

**WARNING:**
- Weak mutation coverage for line 7

### Verdict: APPROVED / NEEDS_FIXES / TDD_VIOLATION
```

## Common TDD Violations

### Violation: Defensive Code
```javascript
// No test for this null check
if (user === null) {
  return { error: 'User not found' };
}
```
**Fix**: Either add test for null case OR remove the check.

### Violation: Extra Error Handling
```javascript
try {
  // tested code
} catch (e) {
  // NO TEST throws this error
  logger.error(e);
  return null;
}
```
**Fix**: Add test that triggers the catch block.

### Violation: Unreachable Default
```javascript
switch (status) {
  case 'active': return true;  // tested
  case 'inactive': return false; // tested
  default: return null; // NO TEST reaches this
}
```
**Fix**: Either test the default or remove it if truly unreachable.

## Audit Checklist

Before issuing verdict:

- [ ] All tests pass
- [ ] Every function traced to tests
- [ ] Every branch traced to tests
- [ ] Every error path traced to tests
- [ ] Mutations would be caught
- [ ] Requirements are covered
- [ ] No "extra" untested code

## Severity Guidelines

| Finding | Severity | Action |
|---------|----------|--------|
| Untested code path | CRITICAL | TDD_VIOLATION |
| Missing requirement test | CRITICAL | TDD_VIOLATION |
| Weak mutation coverage | WARNING | Note for improvement |
| Test naming issues | INFO | Note for documenter |
