---
name: recovering-from-failures
description: Recover from failures during lemongrab TDD workflows. Use when tests won't pass after multiple attempts, dependencies fail to install, merge conflicts arise, or an agent gets bounced back by the reviewer. Provides triage patterns, rollback strategies, escalation rules, and circuit breaker guidance. Not for general debugging outside TDD workflows.
version: 1.0.0
---

# Recovering from Failures

This skill helps agents recover when things go wrong during TDD workflows. The goal is systematic triage before escalation — not brute-force retrying.

## When to Use

- Tests won't pass after implementation
- Dependency installation or build fails
- Reviewer rejects implementation (NEEDS_FIXES or TDD_VIOLATION)
- Merge conflicts during parallel work
- Environment issues (missing tools, wrong versions)

## Core Principle

**Diagnose before retrying.** Repeating the same action expecting a different result wastes cycles. Identify the root cause, then choose the cheapest fix.

## Test Failure Triage

When tests fail after implementation, classify the failure:

| Failure Type | Symptom | Action |
|---|---|---|
| Wrong test | Test asserts incorrect behavior | STOP — flag for test-writer, do not modify tests |
| Wrong code | Logic error in implementation | Fix the specific failing assertion |
| Missing dependency | Import/require error | Install dependency, re-run |
| Environment mismatch | Works locally, fails in CI | Check Node/Python version, OS differences |
| Flaky test | Passes sometimes, fails sometimes | Add determinism (fix timing, mock randomness) |
| Cascading failure | One broken test causes others to fail | Fix the root test first, re-run all |

### Diagnosis Steps

1. **Read the error message** — what specifically failed?
2. **Isolate** — run the single failing test, not the full suite
3. **Compare** — does the test match the acceptance criteria in the plan?
4. **Check assumptions** — does the implementation match what the test expects?

### When You Cannot Fix It

If after 2 attempts the same test still fails:

```
STOP. Do not attempt a third fix for the same test.
Report to orchestrator:
  "Test [name] fails after 2 attempts.
   Root cause: [diagnosis]
   Attempted fixes: [list]
   Recommendation: [rewrite test | redesign approach | ask user]"
```

## Reviewer Rejection Recovery

### NEEDS_FIXES (WARNING severity)

The orchestrator auto-loops. Your job:

1. Read the reviewer's fix list (from `docs/state/reviewer-reports/`)
2. Address each item in order
3. Run tests after each fix
4. Do NOT add code beyond what the reviewer requested

### NEEDS_FIXES (CRITICAL) or TDD_VIOLATION

The orchestrator asks the user. If sent back to you:

1. Read the reviewer report carefully
2. For TDD_VIOLATION: you likely wrote code no test demands — delete it
3. For untested branches: flag for test-writer, do not add tests yourself
4. Re-run full test suite before reporting back

### After 2 Rejections (Circuit Breaker)

The orchestrator will stop and ask the user. Do NOT try to work around this.
The circuit breaker exists because repeated failures usually indicate a deeper problem:
- Requirements are ambiguous
- Plan has a design flaw
- Tests are testing the wrong thing

## Rollback Strategies

### Safe Rollback (Preferred)

```bash
# Revert to last checkpoint commit
git log --oneline -5  # find last checkpoint
git checkout <checkpoint-hash> -- <files-you-changed>
```

### Full Task Rollback

```bash
# Undo all changes for current task
git stash  # save work in case needed
git checkout <last-checkpoint> -- .
```

### When NOT to Rollback

- If some tests are passing and only one is failing — fix, don't rollback
- If the failure is in test setup, not your code — fix setup
- If you're more than 50% done with the task — fix forward

## Dependency and Build Failures

| Problem | Diagnosis | Fix |
|---|---|---|
| Package won't install | Check error log, version conflicts | Pin compatible version, check lockfile |
| Build fails | Read build output, find first error | Fix first error, rebuild |
| Type errors | Read type error message | Fix type, don't use `any` as escape hatch |
| Missing binary/tool | `which <tool>` returns nothing | Ask user to install, or use alternative |

### Dependency Conflict Resolution

1. Read the full error message (not just the last line)
2. Check if a version range can satisfy both constraints
3. If not: ask the user which dependency to prioritize
4. Never force-install with `--force` or `--legacy-peer-deps` without user approval

## Environment Issues

| Symptom | Check | Fix |
|---|---|---|
| "command not found" | `which <cmd>` | Ask user to install |
| Wrong version | `node -v` / `python --version` | Note in blocker, ask user |
| Permission denied | File permissions | Don't chmod 777 — ask user |
| Port in use | `lsof -i :<port>` | Use different port or ask user to free it |

## Escalation Rules

### Escalate to Orchestrator When:

- Same test fails after 2 fix attempts
- Dependency conflict has no clear resolution
- Reviewer rejection requires plan changes (not just code fixes)
- Environment issue blocks all progress

### Escalate to User When:

- Circuit breaker fires (orchestrator handles this)
- Ambiguous requirement discovered during debugging
- Need to install system-level tools
- Merge conflict in files you didn't write

### Never Escalate For:

- First test failure (try to fix it)
- Missing import (add it)
- Typo in implementation (fix it)
- Single reviewer WARNING (address it)

## Blocker Report Format

When escalating, use this structure:

```markdown
## BLOCKED: [Brief description]

### What Failed
[Specific error or rejection]

### Root Cause
[Your diagnosis — be specific]

### What I Tried
1. [Attempt 1] — [Result]
2. [Attempt 2] — [Result]

### Recommendation
[Specific next step: rewrite test / redesign / ask user / install tool]
```

## Recovery Checklist

Before resuming after any failure:

- [ ] Root cause identified (not just symptom)
- [ ] Fix addresses root cause (not a workaround)
- [ ] Tests pass after fix
- [ ] No unrelated changes introduced during fix
- [ ] State files updated if task status changed
