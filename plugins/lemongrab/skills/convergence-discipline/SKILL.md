---
name: convergence-discipline
description: Enforce convergence discipline across all lemongrab TDD workflow phases. Auto-activates when ANY lemongrab agent (orchestrator, clarifier, planner, test-writer, implementer, reviewer, simplifier, documenter, analyzer, ticket-manager, security-reviewer, performance-reviewer, qa-engineer) is invoked, or when any lemongrab command (tdd, analyze, resume, ticket, bootstrap) runs. Ensures every output is mechanically verifiable, structured, disk-grounded, and resumable. NOT for general coding sessions outside lemongrab workflows.
version: 1.0.0
---

# Convergence Discipline

This skill enforces six non-negotiable principles that prevent workflows from drifting into unverifiable, unstructured, or unrecoverable states. Every lemongrab agent MUST comply.

## Principles

### 1. Mechanically Verifiable Acceptance Criteria

Every task, requirement, and deliverable MUST have acceptance criteria that a machine can check.

**The test**: Can you write a shell command that returns exit code 0 on success and non-zero on failure?

| Acceptable | Unacceptable |
|------------|--------------|
| `npm test -- --grep "login"` exits 0 | "Login works correctly" |
| `grep -q "export function login" src/auth.ts` | "Auth module is well-structured" |
| `jq '.tasks.T001.status' docs/state/task-status.json \| grep -q complete` | "Task is done" |
| `git diff --name-only HEAD~1 \| grep -q "docs/decisions"` | "Decisions are documented" |

**Rule**: If you cannot express the acceptance criterion as a runnable command, the task is too vaguely defined. Rewrite it before proceeding.

### 2. Structured Output Only

Every agent output MUST be one of these formats. Open-ended prose is forbidden as a primary deliverable.

| Format | When to Use |
|--------|-------------|
| Checklist (`- [ ]` / `- [x]`) | Task tracking, audit results, verification steps |
| Matrix/Table | Traceability, coverage mapping, comparison |
| Manifest (JSON) | State files, task status, phase tracking |
| Template with fixed fields | Reports, handoffs, blocker descriptions |
| Enumerated list | Ordered steps, prioritized findings |

**The test**: Could another agent parse this output programmatically?

```
BAD:  "The implementation looks good overall. I noticed a few things
       that could be improved, and the tests seem to cover most cases."

GOOD: ## Review Verdict: NEEDS_FIXES
      | Check | Status | Detail |
      |-------|--------|--------|
      | Tests pass | PASS | 12/12 |
      | Coverage | FAIL | login() L9 untested |
      | TDD compliance | FAIL | catch block has no test |

      ### Required Fixes
      - [ ] Add test for login() error path (L9)
      - [ ] Add test that triggers catch block
```

### 3. Disk Grounding at Start

Every agent MUST read its state from disk before doing any work. Memory alone is not trusted.

**Required reads before any action**:

```
1. docs/state/current-phase.json    → What phase are we in?
2. docs/state/task-status.json      → What tasks exist and their status?
3. The relevant artifact for this phase:
   - CLARIFY: docs/requirements/*.md
   - PLAN: docs/plans/*.md
   - BUILD: test files + source files listed in task
   - REVIEW: implementation files + test results
   - DOCUMENT: docs/decisions/*.md
```

**The test**: If the conversation context were wiped right now, could this agent reconstruct its full state from disk alone?

If the answer is no, the agent must write state to disk BEFORE continuing.

### 4. No "Human Review" Verification

If the only way to verify a deliverable is "have a human look at it," the task is too vague.

**Rewrite patterns**:

| Vague Criterion | Mechanical Replacement |
|-----------------|----------------------|
| "Code is clean" | Linter exits 0, no functions > 30 lines, cyclomatic complexity < 10 |
| "Tests are comprehensive" | Coverage > 90%, mutation score > 80%, all requirements have >=1 test |
| "Documentation is complete" | Every public function has JSDoc, README has install/usage/API sections |
| "Error handling is good" | Every catch block has a test, every error path has a test |
| "Performance is acceptable" | Response time < 200ms at p95, benchmark exits 0 |

**Exception**: UX/visual design decisions genuinely require human judgment. In those cases, the task must explicitly state `REQUIRES_HUMAN_REVIEW` and provide a screenshot or demo command for the reviewer.

### 5. Disk State at All Times

If the session dies at any point, zero work is lost. This is a hard invariant.

**Rules**:

1. **Write before compute**: Persist decisions, plans, and partial work to `docs/state/` BEFORE moving to the next step
2. **Atomic state transitions**: Update `current-phase.json` only AFTER the phase artifact is fully written
3. **Checkpoint after each task**: Every completed task gets a git checkpoint commit
4. **Counter persistence**: `circuitBreakerTrips`, `tasksSinceLastMilestone`, `qaAvailable` live in `task-status.json`, not in memory
5. **No in-memory-only state**: If a value matters, it's on disk. Period.

**The test**: Kill the session right now. Run `cat docs/state/current-phase.json && cat docs/state/task-status.json`. Can the workflow resume from exactly where it left off?

**Self-check sequence** (agents should run this mentally before completing):

```
For each piece of state I hold in memory:
  Is it written to disk?
    YES → proceed
    NO  → write it NOW, then proceed
```

### 6. Runnable DONE Definitions

The DONE definition for every task must be a command you can execute.

**Format**:

```json
{
  "task": "T001",
  "title": "Implement login endpoint",
  "done_when": [
    "npm test -- --grep 'login' exits 0",
    "curl -s -o /dev/null -w '%{http_code}' localhost:3000/api/login -d '{\"email\":\"test@test.com\",\"password\":\"pass\"}' | grep -q 200",
    "grep -q 'export async function login' src/auth/login.ts"
  ]
}
```

**Not acceptable**:

```json
{
  "task": "T001",
  "done_when": ["Login endpoint works correctly"]
}
```

**Rule**: If a planner writes a task without runnable `done_when` criteria, the orchestrator MUST reject the plan and send it back.

## Compliance Checklist

Every agent, before returning its output, MUST verify:

- [ ] All acceptance criteria are mechanically verifiable (Principle 1)
- [ ] Output uses structured format: table, checklist, manifest, or template (Principle 2)
- [ ] State was read from disk at the start of work (Principle 3)
- [ ] No criterion relies solely on human review (Principle 4)
- [ ] All state changes are persisted to disk (Principle 5)
- [ ] Every task has a runnable DONE definition (Principle 6)

## Violation Signals

Flag these when reviewing agent output: "looks good"/"seems fine" (unstructured, P2),
"manually verify" (human review, P4), no `docs/state/` reads (missing grounding, P3),
prose `done_when` (non-runnable, P6), state in memory only (disk gap, P5),
"should work" (non-verifiable, P1).
