---
description: Run full TDD workflow (clarify, plan, build, document)
argument-hint: <feature description>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

Use the lemongrab agent to implement $ARGUMENTS

The lemongrab agent MUST follow this exact flow with user gates at each stage:

## PHASE 1: REQUIREMENTS

1. Launch clarifier agent — it will ask the user questions
2. Verify docs/requirements/<feature>.md exists with all required sections
3. Present the finalized requirements to the user (REQUIREMENTS_REVIEW checkpoint)
4. User must explicitly approve before planning begins

## PHASE 1.5: DESIGN (auto for MEDIUM+, skip for SMALL)

1. Launch designer agent to explore 2-3 distinct approaches
2. Present trade-offs to user, user selects approach
3. Selected approach feeds into the planner
4. SKIP for SMALL features (1-3 expected tasks) unless user asks for it

## PHASE 2: PLAN

1. Explore codebase for context (Plan subagent)
2. Launch planner agent to produce docs/plans/<feature>.md
3. Plan MUST include: Public Interfaces section (API contracts before task breakdown)
   and Complexity Expectations section (visibility signals, not hard limits)
4. Present the plan to the user with this structured breakdown:
   a. Full task list: ID, type, scope (exact files, max 3 per task), dependency chain
   b. Per-task acceptance criteria (numbered, mechanically verifiable)
   c. Per-task verification methods (unit-test, integration-test, type-check, etc.)
   d. Per-task DONE DEFINITION commands (shell commands that exit 0 when complete)
   e. Dependency graph and parallel safety analysis (file overlap table)
   f. Totals: task count, unique file count, acceptance criteria count, estimated test count
4. User must explicitly approve the plan (PLAN_APPROVAL checkpoint)
   - User may: [approve], [modify: describe changes], or [reject: explain concern]
   - If user requests changes, re-run the planner and present the revised plan
   - No code, branches, or tickets are created until the user says "approve"

## PHASE 3: BUILD (per task, in dependency order)

For each task in the plan:

1. **Test writer** — writes failing tests + coverage manifest at docs/manifests/<feature>-<task>.md
   - For public-facing modules: write API ergonomics tests FIRST (usage examples that read like docs)
   - Every acceptance criterion from the plan must map to at least one test
   - Tests should target the Public Interfaces defined in the plan
   - All tests must fail for the RIGHT reason (missing implementation, not syntax errors)

2. **Implementer** — writes minimal code to pass tests + decisions log at docs/decisions/<feature>-<task>.md
   - Prior art scan: read 2-3 similar files to absorb codebase conventions before writing
   - Honor the Public Interfaces defined in the plan
   - Every line of code must be demanded by a failing test
   - Test file integrity check: verify implementer did not modify test files

3. **Reviewer** — produces structured pass/fail matrix
   - Three parallel reviewers: TDD compliance, security, performance
   - Matrix covers: acceptance criteria, TDD compliance, scope discipline,
     architecture alignment, error handling, mutation testing, duplication,
     design quality (ELEGANT/ADEQUATE/CLUNKY — advisory, not blocking)
   - Complexity check: compares actual vs plan's Complexity Expectations (INFO level)
   - Verdict: APPROVED, NEEDS_FIXES, or TDD_VIOLATION
   - CRITICAL findings are escalated to user immediately

4. **DONE DEFINITION verification** — run the task's DONE DEFINITION command from the plan
   - Command must exit 0 before the task is considered complete
   - If it fails: return to implementer with the failure output

5. **PRE_SIMPLIFY gate** — present to user what the simplifier will change
   - Show: reviewer warnings to address, code sections targeted for simplification
   - User must approve before simplifier runs
   - User may skip simplification entirely

6. **Simplifier** — removes complexity and improves design while keeping tests green (if user approved)
   - Mechanical: dead code, inlining, early returns, DRY
   - Design: concept compression, information hiding, symmetry, naming as design

7. **Git checkpoint** — `git commit -m "checkpoint: [TXXX] <description>"`

8. **FIRST_CYCLE_REVIEW** — after the FIRST task completes its full cycle:
   - Present: test count, implementation summary, reviewer verdict, code style
   - Purpose: user validates quality bar and approach before tasks 2-N proceed
   - This fires for ALL feature sizes (not skipped for small features)
   - If user requests changes: adjust approach for remaining tasks

## PHASE 3.5: COHERENCE REVIEW (auto for MEDIUM+, skip for SMALL)

1. **Coherence reviewer** — evaluates ALL implementation files as a unified whole
   - Checks: API consistency, naming coherence, data flow clarity, abstraction quality,
     cross-task symmetry, module boundaries, interface contract compliance
   - Verdict: ELEGANT (ship it), ADEQUATE (ship it), NEEDS_REFINEMENT (offer fix)
   - If NEEDS_REFINEMENT: user can approve refinement (simplifier runs on flagged files)
     or skip and ship as-is

## PHASE 4: FINALIZE

1. Run full test suite one final time
2. PRE_PR checkpoint — user approves before PR creation
3. Create PR via ticket-manager
4. Document decisions (documenter agent, on feature branch)
5. Post completion summary with PR link (if tickets enabled)

## CONSISTENCY RULES

- Every acceptance criterion in requirements must trace to a plan task
- Every plan task AC must trace to a test (coverage manifest)
- Every test must trace to implementation code (reviewer matrix)
- Every task must pass its DONE DEFINITION command before advancing
- All state is persisted to docs/state/ after every step (survives session interruption)
- The user has explicit approval gates at: requirements, plan, first task review,
  pre-simplify (each task), and pre-PR
