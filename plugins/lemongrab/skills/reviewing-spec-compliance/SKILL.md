---
name: reviewing-spec-compliance
description: Review implementation against the requirements spec during lemongrab BUILD phase. Use when the spec-reviewer agent validates that what was built matches what was requested. Checks requirement fulfillment, acceptance criteria coverage, edge case handling, and scope adherence. Not for TDD compliance or code quality — those are separate reviews.
version: 1.0.0
---

# Reviewing Spec Compliance

This skill helps verify that implementation matches the requirements specification. The question is not "is the code good?" but "did you build what was requested?"

## When to Use

- After implementation, before simplification
- When validating that acceptance criteria are met
- When checking for missing or extra features
- When verifying edge case handling

## Core Principle

**Requirements are the contract.** Code that is well-written but doesn't satisfy requirements is wrong. Code that is ugly but satisfies every requirement is correct (and can be cleaned up later).

## Review Process

### Step 1: Gather the Spec

Read these files as the source of truth:
1. `docs/requirements/<feature>.md` — The full requirements spec
2. `docs/plans/<feature>.md` — Task-specific acceptance criteria
3. Implementation files from the task's SCOPE
4. Test files for this task

### Step 2: Map Requirements to Implementation

For each functional requirement (FR) that maps to this task:

| Requirement | Implementation | Test | Verdict |
|-------------|---------------|------|---------|
| FR-001: Login returns JWT | src/auth/login.ts:42 | test_login_jwt | PASS |
| FR-002: Invalid creds → 401 | NOT FOUND | test_invalid_creds | FAIL |

### Step 3: Verify Acceptance Criteria

For each AC in the plan for this task, verify:
1. A test exists that exercises this criterion
2. The implementation passes that test
3. The behavior matches what the criterion describes (not just "doesn't throw")

### Step 4: Check Edge Cases

For each edge case in the requirements doc:
1. Is it relevant to this task?
2. If yes, is there a test for it?
3. Does the implementation handle it correctly?

### Step 5: Verify Scope

- **No missing features**: Every requirement mapped to this task has implementation
- **No extra features**: No code exists that isn't demanded by a requirement or test
- **Correct behavior**: Implementation does what the spec says, not just "something"

## Common Spec Compliance Issues

### Missing Requirement
```
FR-003: "Rate limiter rejects 6th request within 60s with HTTP 429"
Implementation: No rate limiting code found
Verdict: CRITICAL — requirement not implemented
```

### Partial Implementation
```
FR-004: "Export supports CSV and JSON formats"
Implementation: Only CSV export exists
Verdict: CRITICAL — JSON export missing
```

### Wrong Behavior
```
FR-005: "Invalid email returns 400 with message 'Invalid email format'"
Implementation: Returns 422 with message 'Validation error'
Verdict: CRITICAL — wrong status code and message
```

### Extra Feature
```
No requirement exists for password strength meter
Implementation: src/auth/password-strength.ts (47 lines)
Verdict: WARNING — extra feature not in spec (scope creep)
```

## Comparison: Spec Review vs TDD Review

| Aspect | Spec Review (this) | TDD Review |
|--------|-------------------|------------|
| Question | "Did you build what was requested?" | "Did you follow TDD process?" |
| Reference | Requirements doc | Test coverage |
| Checks | Requirement fulfillment | Test-first compliance |
| Scope | Features vs spec | Code vs tests |

Both reviews run in parallel. A task can pass TDD review but fail spec review (all tests pass, but a requirement was missed in the tests).
