---
name: systematic-debugging
description: Systematic root cause debugging during lemongrab BUILD phase. Use when tests fail repeatedly, implementer hits unexpected errors, or fixes create new problems. Provides 4-phase investigation (root cause, pattern analysis, hypothesis testing, targeted fix), circuit breaker escalation after 3 failed fixes, and anti-thrashing discipline. Not for first-attempt failures — use recovering-from-failures for those.
version: 1.0.0
---

# Systematic Debugging

This skill enforces disciplined root cause investigation BEFORE any fix attempts. It activates when simple recovery fails and deeper diagnosis is needed.

## When to Use

- Test fails after first fix attempt (recovering-from-failures didn't resolve it)
- A fix introduces new failures elsewhere
- Multiple tests fail with seemingly unrelated errors
- Error messages are confusing or misleading
- The same symptom keeps recurring after "fixes"

## Core Principle

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Random fixes waste cycles, create new bugs, and mask real problems. Systematic debugging is faster than thrashing.

## The 4-Phase Process

### Phase 1: Root Cause Investigation

Before touching any code, understand WHAT is happening and WHY.

1. **Read the full error** — not just the last line. Stack traces tell a story top to bottom
2. **Reproduce consistently** — run the failing test in isolation: `npm test -- --grep "test name"`
3. **Check recent changes** — `git diff` shows what changed since last green state
4. **Trace data flow backward** — start at the failure point, work backward through the call chain
5. **Check boundaries** — for multi-layer systems, add diagnostic logging at layer boundaries

```
WRONG: "The login test fails, let me change the login function"
RIGHT: "The login test fails with 'Cannot read property email of undefined'.
        The user object is undefined. Tracing back: getUserById returns undefined.
        The database query returns no rows. The test fixture didn't seed the user.
        ROOT CAUSE: Missing test setup, not a code bug."
```

### Phase 2: Pattern Analysis

Find working examples to compare against.

1. **Find similar working code** — grep for similar patterns that DO work
2. **Read reference implementations** — read them COMPLETELY, not just the first few lines
3. **Identify differences** — what's different between the working and broken versions?
4. **Check assumptions** — is the API/framework behaving as you assumed?

```
Working test (test_logout):     Sets up user → calls logout → asserts redirect
Broken test (test_login):       Calls login directly → fails
DIFFERENCE: Missing user setup step in broken test
```

### Phase 3: Hypothesis & Testing

Form ONE hypothesis and test it minimally.

1. **State your hypothesis**: "I think X is the root cause because Y"
2. **Design minimal test**: Change ONE variable to confirm or refute
3. **Run the test**: Does the hypothesis hold?
4. **If confirmed**: Proceed to Phase 4
5. **If refuted**: Return to Phase 1 with new information

```
HYPOTHESIS: "The test fails because the database isn't seeded before login"
MINIMAL TEST: Add seed step to broken test only
RESULT: Test passes → hypothesis confirmed
```

**One variable at a time.** Changing multiple things simultaneously makes it impossible to know which change fixed (or broke) things.

### Phase 4: Targeted Fix

Now — and ONLY now — implement the fix.

1. **Write a failing test** that reproduces the bug (TDD applies to bug fixes too)
2. **Implement the minimal fix** at the ROOT CAUSE, not at the symptom
3. **Verify the fix** — run the specific test AND the full suite
4. **Check for regressions** — did the fix break anything else?

```
WRONG: Add a null check where the error appears (treats symptom)
RIGHT: Fix the missing seed in test setup (treats root cause)
```

## Circuit Breaker

**After 3 failed fix attempts: STOP.**

This is not a failure — it's a signal. Three failed fixes means one of:

| Signal | What It Means | Action |
|--------|---------------|--------|
| Each fix reveals a new problem | Wrong architecture | Discuss redesign with user |
| Fix works locally but fails in test | Environment or test issue | Check test setup, mocks, fixtures |
| Fix requires "massive refactoring" | Scope exceeds current task | Escalate — may need plan revision |
| Same symptom keeps returning | Treating symptom, not cause | Return to Phase 1 with fresh eyes |

**Escalation format:**

```markdown
## DEBUGGING ESCALATION: [Brief description]

### Investigation Summary
- Root cause hypothesis: [your best theory]
- Evidence: [what you found in Phase 1-2]

### Fix Attempts
1. [Attempt 1] — [Result: what happened]
2. [Attempt 2] — [Result: what happened]
3. [Attempt 3] — [Result: what happened]

### Pattern Observed
[Why fixes aren't working — what signal are you seeing?]

### Recommendation
[Specific next step: redesign, rewrite test, modify plan, ask user]
```

## Red Flags: Rationalizations to Catch

If you're thinking any of these, STOP and follow the 4-phase process:

| Rationalization | Why It's Wrong |
|-----------------|----------------|
| "Quick fix for now, investigate later" | "Later" never comes. Fix at root cause now. |
| "Just try changing X" | Random changes waste cycles. Form a hypothesis first. |
| "Skip the test, I'll manually verify" | Manual verification doesn't persist. Write the test. |
| "It's probably X, let me fix that" | "Probably" means you haven't investigated. Do Phase 1. |
| "This worked before, something else changed" | Check `git diff`. Find what actually changed. |
| "Let me add more logging" | Logging is Phase 1. Don't skip to fix before reading logs. |
| "It's a flaky test, just re-run" | Flaky tests have root causes. Find the non-determinism. |

## Debugging Checklist

Before claiming a fix is complete:

- [ ] Root cause identified (not just symptom)
- [ ] Fix addresses root cause (not a workaround)
- [ ] Failing test written that reproduces the bug
- [ ] Fix makes the failing test pass
- [ ] Full test suite passes (no regressions)
- [ ] No unrelated changes introduced during debugging
- [ ] Hypothesis documented (for future reference)
