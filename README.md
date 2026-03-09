```
╦ ╦╔╗╔╔═╗╔═╗╔═╗╔═╗╔═╗╔╦╗╔═╗╔╗ ╦  ╔═╗ ┬ ┬ ┬
║ ║║║║╠═╣║  ║  ║╣ ╠═╝ ║ ╠═╣╠╩╗║  ║╣  │ │ │
╚═╝╝╚╝╩ ╩╚═╝╚═╝╚═╝╩   ╩ ╩ ╩╚═╝╩═╝╚═╝ o o o
```

# Lemongrab

**A TDD Multi-Agent Workflow Plugin for Claude Code**

Lemongrab turns Claude Code into a disciplined engineering team. Instead of one agent doing everything, 17 specialized agents collaborate through a strict test-driven development workflow — clarifying requirements before writing code, writing tests before implementation, reviewing before shipping, and documenting before closing.

You type one command. Lemongrab handles the rest: asking you questions, writing tests, implementing code, running parallel reviews, simplifying, creating PRs, and documenting decisions. You stay in control through explicit approval gates at every major checkpoint.

**17 agents. 20 skills. 6 slash commands. 11 automation hooks. Zero assumptions.**

---

## Table of Contents

- [What Does This Plugin Actually Do?](#what-does-this-plugin-actually-do)
- [Who Is This For?](#who-is-this-for)
- [When Should You Use This?](#when-should-you-use-this)
- [When Should You NOT Use This?](#when-should-you-not-use-this)
- [Install](#install)
- [Quick Start (Your First 5 Minutes)](#quick-start-your-first-5-minutes)
- [All Entry Points with Examples](#all-entry-points-with-examples)
- [All Workflow Types with Examples](#all-workflow-types-with-examples)
- [The Complete Workflow Explained](#the-complete-workflow-explained)
- [Agents Reference](#agents-reference)
- [Skills Reference](#skills-reference)
- [Automation Hooks](#automation-hooks)
- [State Management and Recovery](#state-management-and-recovery)
- [Rollback Capability](#rollback-capability)
- [Orchestration Patterns](#orchestration-patterns)
- [Runtime Output](#runtime-output)
- [Plugin Structure](#plugin-structure)
- [Prerequisites and Integrations](#prerequisites-and-integrations)
- [Pros and Cons](#pros-and-cons)
- [Limitations](#limitations)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)

---

## What Does This Plugin Actually Do?

Lemongrab enforces a structured software development workflow inside Claude Code. Here is what happens when you use it:

1. **Before any code exists**, it asks you questions to clarify exactly what you want
2. **Before any code is written**, it creates a technical plan with task breakdown
3. **Before any implementation**, it writes failing tests (TDD red phase)
4. **During implementation**, it writes the minimum code to pass those tests (TDD green phase)
5. **After implementation**, three reviewers run in parallel checking TDD compliance, security, and performance
6. **After review**, it simplifies the code while keeping tests green (TDD refactor phase)
7. **After all tasks**, it documents decisions, creates a PR, and gives you a summary

You approve at every major checkpoint. Nothing proceeds without your explicit "yes."

**The core guarantee**: every line of production code exists because a test demanded it.

---

## Who Is This For?

**Good fit:**
- You want disciplined, test-driven code from Claude Code
- You're building features that need to be correct and maintainable
- You want a structured workflow with clear checkpoints
- You're working on a team and want reviewable, documented code
- You want to catch security and performance issues before they ship

**Not a good fit:**
- You want Claude to quickly hack together a prototype (just use Claude Code directly)
- You're doing one-off scripts or throwaway code
- You want maximum speed with no process overhead
- You prefer to write tests after implementation

---

## When Should You Use This?

| Scenario | Use Lemongrab? | Why |
|----------|---------------|-----|
| Building a new API endpoint | Yes | Tests, review, and documentation are valuable |
| Adding authentication to an app | Yes | Security review catches auth issues early |
| Implementing a feature from a Linear ticket | Yes | `/ticket LIN-123` extracts requirements automatically |
| Exploring an unfamiliar codebase | Yes | `/analyze` maps architecture and patterns |
| Planning a feature for team review before building | Yes | `/tdd --plan-only` creates plan + tickets without writing code |
| Quick one-line bug fix | No | Overkill — just fix it directly |
| Writing a bash script for personal use | No | No need for TDD on throwaway code |
| Prototyping an idea rapidly | No | Process overhead slows exploration |
| Generating boilerplate | No | Use Claude Code directly |

---

## When Should You NOT Use This?

- **When speed matters more than correctness.** Lemongrab adds process overhead (questions, approvals, reviews). If you need something fast and dirty, skip it.
- **When the task is trivial.** Fixing a typo or updating a version number doesn't need 17 agents.
- **When you don't want tests.** Lemongrab is fundamentally test-driven. You cannot skip the test phase.
- **When you're not ready to answer questions.** The clarifier will ask you things. If you don't have answers yet, you'll block the workflow.

---

## Install

From inside Claude Code, run:

```
/install-plugin https://github.com/peterphot/lemongrab
```

Or manually:

```
/plugin marketplace add https://github.com/peterphot/lemongrab
/plugin install lemongrab@peterphot-lemongrab
```

Or use the interactive plugin manager:

```
/plugin
```

Then navigate to **Marketplaces** > **Add** > paste `https://github.com/peterphot/lemongrab`, then switch to **Discover** and install.

**That's it.** No configuration needed. The plugin activates immediately with all hooks, agents, and skills.

---

## Quick Start (Your First 5 Minutes)

### Example 1: Build a feature from scratch

```
/tdd add a /health endpoint that returns server uptime and version
```

What happens next:
1. The **clarifier** asks you questions: "Should the uptime be in seconds or human-readable? Should it include memory usage? Should it require authentication?"
2. You answer the questions
3. You review and approve the requirements document
4. The **planner** creates a task breakdown with tests, files, and acceptance criteria
5. You review and approve the plan
6. For each task: tests are written, code is implemented, reviewers check it, code is simplified
7. After the first task, you review the approach and confirm it looks good
8. A PR is created with all the code, tests, and documentation

### Example 2: Work on a Linear ticket

```
/ticket ENG-456
```

What happens next:
1. The **analyzer** reads the ticket from Linear (title, description, comments)
2. The **clarifier** identifies gaps in the ticket and asks you to fill them
3. Everything else proceeds like Example 1

### Example 3: Understand an existing codebase

```
/analyze
```

What happens next:
1. The **analyzer** scans the codebase structure, tech stack, architecture patterns, dependencies
2. Produces a report at `docs/analysis/` with findings
3. You now have context for adding features with `/tdd`

---

## All Entry Points with Examples

There are **three ways** to start a Lemongrab workflow:

### 1. Slash Commands (6 commands)

The most common way. Type these directly in Claude Code.

#### `/tdd <feature description> [--plan-only]`

**What it does:** Runs the full TDD workflow — clarify, plan, build, document.

```
# Simple feature
/tdd add pagination to the /users endpoint

# Detailed feature
/tdd implement JWT authentication with refresh tokens, rate limiting, and account lockout after 5 failed attempts

# Vague feature (the clarifier will ask you to be specific)
/tdd make the app faster

# Plan-only mode: stop after plan approval and ticket creation (no code written)
/tdd add pagination to the /users endpoint --plan-only
```

**`--plan-only` flag:** Runs CLARIFY → DESIGN → PLAN → PLAN APPROVAL → TICKETS, then exits with a summary of all artifacts. No branches are created and no code is written. Review the plan and tickets at your own pace, then run `/resume <feature>` when ready to build.

#### `/analyze [path]`

**What it does:** Analyzes an existing codebase to build context. Use this before `/tdd` when joining an existing project.

```
# Analyze the entire project
/analyze

# Analyze a specific directory
/analyze src/api

# Analyze a specific path
/analyze packages/auth
```

#### `/ticket <id>`

**What it does:** Implements a feature from a Linear ticket. Reads the ticket, extracts requirements, then runs the TDD workflow.

```
# Single ticket
/ticket ENG-123

# Multiple tickets (implemented together as one feature)
/ticket ENG-123, ENG-124, ENG-125

# All sub-issues of a parent ticket
/ticket sub-issues of ENG-100
```

**Requires:** Linear MCP plugin installed and configured.

#### `/bootstrap <project-type>`

**What it does:** Creates a new project directory structure with TDD-ready configuration, then transitions to building the first feature.

```
/bootstrap node-api
/bootstrap react-app
/bootstrap python-cli
```

#### `/pr-review <PR-URL-or-number> [--base <branch>] [--fix]`

**What it does:** Runs a chunked PR review as a standalone operation, outside the workflow state machine. Useful for reviewing PRs independently, recovering from a workflow that skipped PR review, or re-reviewing after manual changes.

```
# Review by PR number
/pr-review 1

# Review by URL
/pr-review https://github.com/org/repo/pull/42

# Review and offer to fix findings
/pr-review 1 --fix

# Auto-detect PR from workflow state (if docs/state/task-status.json exists)
/pr-review
```

**How it works:** Fetches the PR diff, chunks it into logical units (~200-300 lines each), launches parallel pr-reviewer agents per chunk, then aggregates findings by severity (CRITICAL/WARNING/NIT). With `--fix`, it offers to apply fixes and re-review changed chunks (max 2 rounds).

**Does NOT** modify workflow state or move Linear tickets — it operates entirely outside the state machine.

#### `/resume <feature-name> [--plan-only]`

**What it does:** Resumes an interrupted workflow. Reads saved state from disk and picks up exactly where it left off.

```
# Resume a workflow that was interrupted
/resume user-authentication

# Resume after a crash or session timeout
/resume health-endpoint

# Resume in plan-only mode (do tickets but don't start building)
/resume user-authentication --plan-only
```

**`--plan-only` flag on resume:** Overrides the mode from the original run. Useful when:
- The original `/tdd --plan-only` run stopped before ticket creation — resume picks up at tickets then exits
- You started a full workflow but want to pause after planning — switch to plan-only mode
- The original run didn't store the mode correctly — explicitly set it

**When to use:** Your Claude Code session was interrupted (timeout, crash, closed terminal) while a workflow was in progress, or you need to complete remaining plan-only steps (like ticket creation) after the plan was approved.

### 2. Direct Agent Invocation (natural language)

You can invoke the lemongrab agent directly with natural language. Useful when slash commands don't cover your exact need.

```
# Same as /tdd
Use the lemongrab agent to implement user authentication with JWT

# Same as /analyze
Use the lemongrab agent to analyze this codebase

# Implement from a Notion PRD
Use the lemongrab agent to implement from PRD https://notion.so/my-prd-page

# Implement from a Notion RFC
Use the lemongrab agent to implement from RFC https://notion.so/my-rfc-page

# Same as /ticket
Use the lemongrab agent to implement ticket ENG-123

# Same as /resume
Use the lemongrab agent to resume user-authentication
```

**PRD and RFC workflows require:** Notion MCP plugin installed and configured.

### 3. Individual Agent Invocation (advanced)

You can invoke specific agents directly for targeted tasks. This bypasses the orchestrator — you're responsible for the workflow.

```
# Just gather requirements (no planning or building)
Use the clarifier agent to gather requirements for a notifications system

# Just write tests for existing code
Use the test-writer agent to write tests for src/auth/login.ts

# Just review existing implementation
Use the reviewer agent to review the changes in src/api/

# Just simplify existing code
Use the simplifier agent to simplify src/utils/parser.ts

# Just document what was built
Use the documenter agent to document the authentication feature

# Just analyze a codebase
Use the analyzer agent to analyze the src/payments/ directory
```

**When to use:** You don't need the full workflow and want to use one specific agent's capability.

---

## All Workflow Types with Examples

### Workflow 1: Greenfield Feature (`/tdd`)

**Scenario:** You're adding new functionality to an existing project or building something from scratch.

```
/tdd user registration with email verification
```

**Full flow:**

```
You: /tdd user registration with email verification
                    |
                    v
    CLARIFIER asks: "Should email verification be a link or a code?
                     What happens if the link expires?
                     Should existing emails be rejected at registration
                     or at verification?"
                    |
        You answer each question
                    |
                    v
    You review requirements doc → approve
                    |
                    v
    DESIGNER explores 2-3 approaches (for medium+ features):
        Approach A: Magic link via email
        Approach B: 6-digit code via email
        Approach C: OAuth-only, no email verification
                    |
        You pick Approach A
                    |
                    v
    PLANNER creates task breakdown:
        T001: Email service interface + tests
        T002: Registration endpoint + tests
        T003: Verification endpoint + tests
        T004: Expiry handling + tests
                    |
    You review plan → approve
                    |
                    v
    BUILD LOOP (for each task):
        Test Writer  → writes failing tests
        Implementer  → writes minimal code to pass
        3 Reviewers  → TDD + security + performance (parallel)
        Simplifier   → cleans up code
        Git commit   → checkpoint for rollback
                    |
    After T001: you review approach → confirm
                    |
                    v
    COHERENCE REVIEWER checks all tasks work together
                    |
                    v
    DOCUMENTER writes decision log + inline comments
                    |
                    v
    PR created → done
```

### Workflow 2: Linear Ticket (`/ticket`)

**Scenario:** A ticket already exists with requirements defined by your team.

```
/ticket ENG-456
```

**Full flow:**

```
You: /ticket ENG-456
                    |
                    v
    ANALYZER reads ticket from Linear:
        Title: "Add rate limiting to API"
        Description: "We need rate limiting on all public endpoints..."
        Comments: "PM says 100 req/min per user"
                    |
                    v
    CLARIFIER validates extracted requirements:
        "The ticket says 100 req/min — is that per endpoint or global?
         Should rate limit headers be included in responses?
         What happens when limit is exceeded — 429 with retry-after?"
                    |
        You answer gaps
                    |
                    v
    [continues same as greenfield from PLANNER onward]
                    |
    Ticket status updates automatically in Linear as tasks complete
```

### Workflow 3: Multiple Tickets (`/ticket` with multiple IDs)

**Scenario:** Several related tickets should be implemented together.

```
/ticket ENG-456, ENG-457, ENG-458
```

Or if they're sub-issues of a parent:

```
/ticket sub-issues of ENG-400
```

**What's different:** Each ticket gets its own feature branch and PR. The orchestrator processes them sequentially, sharing context between related tickets.

### Workflow 4: From PRD (Notion)

**Scenario:** A product requirements document exists in Notion and you want to implement it.

```
Use the lemongrab agent to implement from PRD https://notion.so/acme/user-onboarding-prd-abc123
```

**Full flow:**

```
    ANALYZER reads PRD from Notion:
        Extracts: user stories, acceptance criteria, scope, constraints
                    |
                    v
    CLARIFIER validates extracted requirements:
        "The PRD mentions 'smooth onboarding' — what specifically does that mean?
         It lists 5 steps but doesn't define the order — is it sequential or can
         users skip steps?"
                    |
        You fill gaps
                    |
                    v
    [continues same as greenfield from PLANNER onward]
```

### Workflow 5: From RFC (Notion)

**Scenario:** A technical RFC exists with architecture decisions and you want to implement the chosen approach.

```
Use the lemongrab agent to implement from RFC https://notion.so/acme/caching-layer-rfc-def456
```

**What's different:** The RFC's technical decisions (chosen approach, rejected alternatives, constraints) are treated as hard constraints during planning. The planner won't contradict the RFC.

### Workflow 6: Codebase Analysis (`/analyze`)

**Scenario:** You've joined an existing project and need to understand it before making changes.

```
/analyze
```

**Full flow:**

```
You: /analyze
                    |
                    v
    ANALYZER scans the codebase:
        - Directory structure and file organization
        - Tech stack (languages, frameworks, libraries)
        - Architecture patterns (MVC, DDD, microservices, etc.)
        - Testing setup (framework, coverage, conventions)
        - Key entry points and dependency graph
        - Code style and conventions
                    |
                    v
    Report written to docs/analysis/
                    |
                    v
    Done. You now have context for /tdd commands.
```

**This is a read-only workflow.** No code is written or modified.

### Workflow 7: Bootstrap New Project (`/bootstrap`)

**Scenario:** Starting a brand new project from nothing.

```
/bootstrap node-api
```

**Full flow:**

```
You: /bootstrap node-api
                    |
                    v
    Creates project structure:
        package.json, tsconfig.json, jest.config.ts,
        src/, tests/, .gitignore, etc.
                    |
                    v
    "Project bootstrapped. What's the first feature?"
                    |
                    v
    You describe first feature → transitions to /tdd workflow
```

### Workflow 8: Resume Interrupted Workflow (`/resume`)

**Scenario:** Your session was interrupted mid-workflow (timeout, crash, closed terminal).

```
/resume user-authentication
```

**Full flow:**

```
You: /resume user-authentication
                    |
                    v
    Reads docs/state/current-phase.json:
        phase: BUILD
        currentTask: T003
        lastAgent: test-writer
        lastSubstep: complete
                    |
                    v
    Reads docs/state/task-status.json:
        T001: completed (checkpoint: abc123)
        T002: completed (checkpoint: def456)
        T003: tests written, implementation not started
                    |
                    v
    Resumes at: T003 implementer
                    |
                    v
    [continues workflow from that exact point]
```

### Workflow 9: Plan-Only Mode (`/tdd --plan-only`)

**Scenario:** You want to clarify requirements, create a plan, and generate tickets — but review everything before any code is written. Build later on your own schedule.

```
/tdd add rate limiting to all API endpoints --plan-only
```

**Full flow:**

```
You: /tdd add rate limiting to all API endpoints --plan-only
                    |
                    v
    CLARIFIER asks questions (same as full /tdd)
                    |
        You answer each question
                    |
                    v
    You review requirements doc → approve
                    |
                    v
    DESIGNER explores approaches (if medium+ feature)
                    |
        You pick an approach
                    |
                    v
    PLANNER creates task breakdown
                    |
    You review plan → approve
                    |
                    v
    TICKET SETUP asks: Linear tickets? Local tickets? No tickets?
                    |
        If Linear: Which team? (lists available teams)
                    |
    TICKET MANAGER creates tickets with task→ticket mapping
                    |
                    v
    DONE. Summary printed:
        - Requirements: docs/requirements/rate-limiting.md
        - Plan: docs/plans/rate-limiting.md (6 tasks, 12 files, 24 ACs)
        - Tickets: LIN-201, LIN-202, LIN-203, LIN-204, LIN-205, LIN-206
                    |
    No branches created. No code written.
                    |
    Later: /resume rate-limiting → picks up at BUILD phase
```

**When to use:** You want to front-load all the thinking (requirements, design, planning, tickets) and decouple it from the build phase. Useful for:
- Reviewing plans with your team before committing to implementation
- Creating tickets for sprint planning without starting the build yet
- Validating scope and approach before writing any code

**If the workflow stopped before ticket creation:** Run `/resume <feature> --plan-only` to pick up at ticket setup, create tickets, then exit cleanly without starting the build.

---

## The Complete Workflow Explained

This is the full lifecycle that `/tdd` runs. Other workflows join at different points but all converge on the same build loop.

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: /tdd <feature>                                                │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 1: CLARIFY                                                    │
│                                                                      │
│  Clarifier agent asks you questions:                                 │
│  - What exactly should this do?                                      │
│  - What are the edge cases?                                          │
│  - What's in scope vs out of scope?                                  │
│  - What should happen when things go wrong?                          │
│                                                                      │
│  Output: docs/requirements/<feature>.md                              │
│  Gate: REQUIREMENTS_REVIEW — you must approve                        │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 1.5: DESIGN (medium+ features only, auto-skipped for small)   │
│                                                                      │
│  Designer agent explores 2-3 distinct approaches:                    │
│  - Approach A: trade-offs, pros, cons                                │
│  - Approach B: trade-offs, pros, cons                                │
│  - Approach C: trade-offs, pros, cons                                │
│                                                                      │
│  Output: docs/designs/<feature>.md                                   │
│  Gate: You select which approach to use                              │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 2: PLAN                                                       │
│                                                                      │
│  Planner agent creates task breakdown:                               │
│  - Architecture overview                                             │
│  - Public interfaces (API contracts)                                 │
│  - Per-task: scope (max 3 files), acceptance criteria,               │
│    verification method, done definition (shell command),             │
│    dependency map                                                    │
│                                                                      │
│  Output: docs/plans/<feature>.md                                     │
│  Gate: PLAN_APPROVAL — you must approve                              │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 2.5: TICKET TRACKING (optional, you choose)                   │
│                                                                      │
│  "Track with Linear tickets, local tickets, or none?"                │
│  If yes: Ticket Manager creates tickets from the plan                │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                          ┌────────┴────────┐
                          │  --plan-only?   │
                          └───┬─────────┬───┘
                           NO │         │ YES
                              │         v
                              │  ┌──────────────────────────────────┐
                              │  │  EXIT: Summary of artifacts      │
                              │  │  Resume later: /resume <feature> │
                              │  └──────────────────────────────────┘
                              v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 3: BUILD (repeats for each task in dependency order)          │
│                                                                      │
│  For each task:                                                      │
│                                                                      │
│  ┌─ TEST WRITER ────────────────────────────────────────────────┐    │
│  │  Writes tests that FAIL (RED phase)                          │    │
│  │  Every acceptance criterion maps to at least one test        │    │
│  │  Tests must fail for the RIGHT reason (missing function,     │    │
│  │  not syntax error)                                           │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ IMPLEMENTER ────────────────────────────────────────────────┐    │
│  │  Writes MINIMUM code to make tests pass (GREEN phase)        │    │
│  │  Every line must be demanded by a failing test               │    │
│  │  Never modifies test files                                   │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ THREE PARALLEL REVIEWERS ───────────────────────────────────┐    │
│  │  Reviewer:    TDD compliance, acceptance criteria, scope     │    │
│  │  Security:    OWASP top 10, injection, auth, secrets         │    │
│  │  Performance: N+1 queries, memory leaks, complexity          │    │
│  │  Spec:        Requirements coverage, contract compliance     │    │
│  │                                                              │    │
│  │  Verdicts: APPROVED / NEEDS_FIXES / TDD_VIOLATION            │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ PRE_SIMPLIFY GATE ─────────────────────────────────────────┐     │
│  │  You see what changes the simplifier will make               │    │
│  │  You approve, or skip simplification                         │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ SIMPLIFIER ─────────────────────────────────────────────────┐    │
│  │  Removes complexity (REFACTOR phase)                         │    │
│  │  Dead code, inlining, early returns, naming, DRY             │    │
│  │  Tests must stay GREEN — if they break, revert immediately   │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ GIT CHECKPOINT ────────────────────────────────────────────┐     │
│  │  git commit -m "checkpoint: [T001] <description>"            │    │
│  │  Enables rollback if later tasks break things                │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                          │                                           │
│                          v                                           │
│  ┌─ FIRST_CYCLE_REVIEW (after task 1 only) ────────────────────┐     │
│  │  You review: test count, code style, reviewer verdict        │    │
│  │  You confirm approach before tasks 2-N proceed               │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  [Repeat for T002, T003, ...]                                        │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 3.5: COHERENCE REVIEW (medium+ features only)                 │
│                                                                      │
│  Coherence Reviewer checks ALL tasks as unified whole:               │
│  - API surface consistency                                           │
│  - Naming coherence                                                  │
│  - Data flow clarity                                                 │
│  - Abstraction quality                                               │
│  - Cross-task symmetry                                               │
│                                                                      │
│  Verdict: ELEGANT / ADEQUATE / NEEDS_REFINEMENT                      │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 3.75: QA (only if the app has a browser UI)                   │
│                                                                      │
│  QA Engineer runs browser tests via Chrome DevTools MCP:             │
│  - Navigates UI, performs actions, verifies outcomes                  │
│  - Checks for console errors, network errors                         │
│  - Generates Playwright tests                                        │
│                                                                      │
│  Verdict: QA_PASS / QA_FAIL / NOT_APPLICABLE                        │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   v
┌──────────────────────────────────────────────────────────────────────┐
│  PHASE 4: FINALIZE                                                   │
│                                                                      │
│  1. Full test suite runs one final time                              │
│  2. Gate: PRE_PR — you approve before PR creation                    │
│  3. Ticket Manager creates PR                                        │
│  4. Documenter writes decision log + inline comments                 │
│  5. Completion summary with PR link                                  │
└──────────────────────────────────────────────────────────────────────┘
```

### Approval Gates (Where You're Asked to Decide)

| Gate | When | What You're Approving |
|------|------|----------------------|
| **REQUIREMENTS_REVIEW** | After clarification | The requirements document is complete and correct |
| **DESIGN_SELECTION** | After design exploration | Which approach to use (medium+ features) |
| **PLAN_APPROVAL** | After planning | The task breakdown, scope, and acceptance criteria |
| **FIRST_CYCLE_REVIEW** | After first task completes | The overall approach and quality bar |
| **PRE_SIMPLIFY** | Before each simplification | What the simplifier will change |
| **COHERENCE_REVIEW** | After all tasks (medium+) | Whether refinement is needed |
| **PRE_PR** | Before PR creation | The code is ready to ship |

---

## Agents Reference

### Orchestrator

| Agent | What It Does |
|-------|-------------|
| **Lemongrab** | Conducts the entire workflow. Routes tasks to agents, manages state, enforces gates, handles interruption recovery. You never invoke this directly — the slash commands do it for you. |

### Requirements and Analysis (3 agents)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **Clarifier** | Asks you questions to produce complete, unambiguous, testable requirements. Core principle: "Ask, don't assume." If something is unclear, it asks. If there are multiple interpretations, it asks which one. | Start of every feature workflow |
| **Analyzer** | Builds context from existing code, PRDs, RFCs, or Linear tickets. Reads Notion pages and Linear tickets via MCP integrations. | `/analyze`, `/ticket`, PRD/RFC workflows |
| **Designer** | Explores 2-3 distinct design approaches with trade-off analysis. Presents comparison matrix so you can make an informed choice. | After requirements, before planning (medium+ features) |

### Planning (2 agents)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **Planner** | Creates the technical plan: architecture overview, public interfaces, task breakdown with scope (max 3 files per task), acceptance criteria, verification methods, done definitions, and dependency map. | After requirements are approved |
| **Ticket Manager** | Creates and tracks work items in Linear or locally. Updates ticket status as tasks complete. Creates branches, PRs, and posts completion summaries. | When ticket tracking is enabled |

### Implementation (2 agents)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **Test Writer** | Writes failing tests (RED phase). Every test maps to a requirement. Tests must fail for the right reason. Creates a coverage manifest mapping acceptance criteria to test cases. | Before implementation, for each task |
| **Implementer** | Writes minimum code to pass tests (GREEN phase). One test at a time. Never modifies test files. Reads 2-3 similar files first to match codebase conventions. | After tests exist, for each task |

### Review (5 agents)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **Reviewer** | Primary reviewer. Checks TDD compliance, acceptance criteria coverage, scope discipline, architecture alignment, error handling, mutation testing, code duplication. Verdicts: APPROVED, NEEDS_FIXES, TDD_VIOLATION. | After implementation, for each task |
| **Security Reviewer** | Checks OWASP top 10, injection, auth bypass, hardcoded secrets, data exposure. Severities: CRITICAL (blocks), WARNING (should fix), INFO. | In parallel with Reviewer |
| **Performance Reviewer** | Checks N+1 queries, unbounded operations, memory leaks, algorithmic complexity. Severities: CRITICAL, WARNING, INFO. | In parallel with Reviewer |
| **Spec Reviewer** | Checks requirements coverage, acceptance criteria, scope adherence, edge cases, contract compliance. | In parallel with Reviewer |
| **Coherence Reviewer** | Reviews ALL implementation files as a unified whole. Checks API consistency, naming coherence, data flow, abstraction quality, cross-task symmetry. Runs once after all tasks complete. | After all BUILD tasks (medium+ features) |

### Refinement and Documentation (3 agents)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **Simplifier** | Removes complexity while keeping tests green (REFACTOR phase). Two passes: mechanical (dead code, inlining, DRY) and structural (concept compression, naming, abstraction). Reverts immediately if tests break. | After reviewer approves, for each task |
| **Documenter** | Documents the "what" and "why." Adds inline comments for non-obvious logic, creates decision logs, updates project docs. | After all tasks complete |
| **QA Engineer** | Black-box browser testing using Chrome DevTools MCP. Navigates UI, performs actions, verifies outcomes, generates Playwright tests. Falls back gracefully if Chrome DevTools MCP is unavailable. | After review, if the app has a UI |

### PR Review (1 agent)

| Agent | What It Does | When It Runs |
|-------|-------------|-------------|
| **PR Reviewer** | Reads the assembled code diff as a human reviewer would on GitHub. Checks readability, correctness, edge cases, naming, API ergonomics, dead code. Does NOT re-check TDD/security/performance (already done per-task). | After all tasks, before PR merge |

---

## Skills Reference

Skills are reusable domain knowledge that agents load automatically. You don't invoke skills directly — agents use them behind the scenes.

| Skill | What It Provides | Used By |
|-------|-----------------|---------|
| `enforcing-tdd` | TDD discipline, red-green-refactor patterns, requirement traceability, minimum code principle | Test Writer, Implementer |
| `auditing-tdd-compliance` | Post-implementation TDD audit, mutation testing mindset, untested code detection | Reviewer |
| `gathering-requirements` | Question frameworks, testable acceptance criteria, scope boundaries | Clarifier |
| `planning-technical-work` | Task breakdown, dependency analysis, public interfaces, complexity estimation | Planner |
| `documenting-decisions` | WHAT + WHY documentation, ADR templates, decision log structure | Documenter |
| `simplifying-code` | Safe refactoring patterns, code smell detection, mechanical vs structural passes | Simplifier |
| `communicating-progress` | Status reports, blocker formats, handoff patterns, phase summaries | Lemongrab |
| `analyzing-codebases` | Structure analysis, pattern detection, tech stack identification | Analyzer |
| `integrating-external-sources` | PRD/RFC/ticket extraction patterns, requirement mapping | Analyzer |
| `formatting-decisions` | Decision block format (`D-CLARIFY`, `D-PLAN`, `D-IMPL`, etc.), ID numbering | Multiple agents |
| `security-awareness` | OWASP lite checklist, injection detection, secrets scanning | Security Reviewer |
| `managing-work-items` | Linear and local ticket management, status tracking, PR lifecycle | Ticket Manager |
| `brainstorming` | Multi-approach exploration, trade-off analysis, creative problem solving | Designer |
| `convergence-discipline` | Focus decisions, avoid endless exploration, commit to approaches | Lemongrab |
| `verifying-before-completion` | Pre-completion checklist, assertion verification, edge case coverage | Multiple agents |
| `recovering-from-failures` | Debugging patterns, rollback procedures, circuit breaker logic | Lemongrab |
| `systematic-debugging` | Diagnostic techniques, isolation, root cause analysis | Implementer |
| `using-git-worktrees` | Git worktree creation and management for parallel work | Lemongrab |
| `managing-branches-and-prs` | Branch naming, PR lifecycle, merge strategy | Ticket Manager |
| `reviewing-spec-compliance` | Requirements traceability, acceptance criteria validation | Spec Reviewer |

---

## Automation Hooks

Lemongrab ships with 11 automation hooks that enforce workflow discipline at the shell level. These activate automatically — no configuration needed.

### Workflow Hooks

| Event | Script | What It Does |
|-------|--------|-------------|
| `SessionStart` | `verify-environment.sh` | Checks git/gh CLI, plugin status, MCP servers, detects interrupted workflows |
| `PreToolUse [Bash]` | `pre-commit-guard.sh` | Runs tests and linter on changed files before any git commit |
| `PreToolUse [Write\|Edit]` | `agent-boundaries.sh` | Blocks file writes that violate agent boundaries |
| `PreToolUse [Write\|Edit]` | `phase-transition-guard.sh` | Enforces legal phase transitions via state machine |
| `PostToolUse [Edit\|Write]` | `auto-format.sh` | Auto-formats files with prettier/black/gofmt/rustfmt based on file type |
| `PostToolUse [Bash]` | `checkpoint-tracker.sh` | Captures git commit hashes in task-status.json for rollback |

### Verification Hooks

| Script | What It Validates |
|--------|------------------|
| `verify-requirements.sh` | Requirements doc has all required sections (edge cases, scope, acceptance criteria) |
| `verify-plan-structure.sh` | Plan has proper task structure (scope, ACs, verification method, done definition) |
| `verify-manifest-coverage.sh` | Coverage manifest maps all acceptance criteria to tests |
| `verify-test-integrity.sh` | Implementer didn't modify test files during implementation |
| `verify-state-consistency.sh` | State files (current-phase.json, task-status.json) are consistent |

### Phase Transition Guard

The `phase-transition-guard.sh` hook enforces a hardcoded state machine on all writes to `current-phase.json`. Claude cannot skip workflow phases.

| Rule | Effect |
|------|--------|
| Every workflow must start with `CLARIFY_IN_PROGRESS` | Cannot jump straight to planning or building |
| `PLAN_IN_PROGRESS` requires verified requirements doc | `verify-requirements.sh` must pass on `docs/requirements/<feature>.md` |
| `PLAN_APPROVED` requires verified plan doc | `verify-plan-structure.sh` must pass on `docs/plans/<feature>.md` |
| `BUILD_IN_PROGRESS` requires feature branch to exist | Branch must be created before code is written |
| 35 valid transitions defined | Any transition not in the table is blocked with an error message |

If a transition is blocked, the error message tells you the current phase, the attempted phase, and the list of valid transitions.

### Agent Boundary Enforcement

The `agent-boundaries.sh` hook runs at the shell level before any file write. Claude cannot bypass it.

| Agent | What It Can Write | What It Cannot Write |
|-------|------------------|---------------------|
| Test Writer | Test/spec files only | Production code |
| Implementer | Production code only | Test files |
| Reviewer, Security Reviewer, Performance Reviewer | Nothing (read-only) | Any files |
| Simplifier | Production code only | Test files |
| Documenter | `docs/` directory only | Source code |

---

## State Management and Recovery

All workflow state is persisted to disk in `docs/state/`. This means:

- **Session timeouts don't lose progress.** Resume with `/resume <feature>`.
- **Context window compaction doesn't lose state.** Agents always read from disk, never from conversation memory.
- **Crashes don't lose progress.** State is written after every agent completes.

### State Files

```
docs/state/
├── current-phase.json          # Where in the workflow (phase, gate, current agent)
├── task-status.json            # Per-task completion (TDD state, files, git checkpoint)
├── decisions.md                # Cumulative decision log from all phases
├── exploration-context.md      # Codebase/PRD/RFC analysis (from analyzer)
├── blockers.json               # Issues preventing progression
└── reviewer-reports/           # Per-task reviewer findings
    ├── <feature>-T001.md
    ├── <feature>-security.md
    ├── <feature>-performance.md
    └── <feature>-coherence.md
```

### How Resume Works

```
/resume user-authentication
```

1. Reads `docs/state/current-phase.json` to find: which phase, which task, which agent, which sub-step
2. Reads `docs/state/task-status.json` to find: which tasks are complete, which are in progress
3. Reconstructs full context from disk (requirements, plan, decisions, reviewer reports)
4. Resumes at the exact stopping point

**Example:** If the workflow was interrupted during T003's implementation:
- T001 and T002 are complete with git checkpoints
- T003 has tests written but implementation not started
- Resume picks up at T003 implementer

---

## Rollback Capability

After each task completes, a git checkpoint is created:

```
checkpoint: [T001] Email service interface - user-registration
checkpoint: [T002] Registration endpoint - user-registration
checkpoint: [T003] Verification endpoint - user-registration
```

### How to Rollback

```bash
# See all checkpoints for a feature
git log --oneline --grep="checkpoint:.*user-registration"

# Output:
# a1b2c3d checkpoint: [T003] Verification endpoint - user-registration
# e4f5g6h checkpoint: [T002] Registration endpoint - user-registration
# i7j8k9l checkpoint: [T001] Email service interface - user-registration

# Rollback to after T002 (undoes T003)
git reset --hard e4f5g6h

# Then resume from T003
/resume user-registration
```

### When to Rollback

- A later task broke something that was working
- You changed your mind about the approach after seeing results
- A reviewer found fundamental issues that require rethinking

---

## Orchestration Patterns

### Phase-Per-Task Model (v2.1)

The `/tdd` command runs a state machine loop in the main conversation context, launching one specialist agent per phase. User approval gates happen directly in the conversation — not buried inside a sub-agent.

```
/tdd command (main context — state machine loop)
  │
  ├─ Task: analyzer        → fetch PRD/RFC/ticket, write draft requirements
  ├─ Task: clarifier       → ask user questions, validate requirements
  │    ← REQUIREMENTS_REVIEW gate (user approves)
  ├─ Task: designer        → 2-3 approaches (MEDIUM+ only)
  │    ← DESIGN_SELECTION gate (user picks)
  ├─ Task: Plan explorer   → codebase analysis
  ├─ Task: planner         → write plan
  │    ← PLAN_APPROVAL gate (user approves/modifies/rejects)
  ├─ Task: ticket-manager  → create tickets (optional)
  │    ← PLAN_ONLY exits here
  │
  ├─ BUILD LOOP (per task):
  │   ├─ Task: test-writer → failing tests
  │   ├─ Task: implementer → make tests pass
  │   ├─ Tasks: 4 parallel reviewers
  │   │    ← PRE_SIMPLIFY gate (user approves)
  │   ├─ Task: simplifier  → clean up
  │   │    ← FIRST_CYCLE_REVIEW gate (task 1 only)
  │   └─ git checkpoint
  │
  ├─ Task: coherence-reviewer (MEDIUM+ only)
  │    ← PRE_PR gate (user approves)
  ├─ Task: ticket-manager  → create PR
  └─ Task: documenter      → record decisions
```

This replaced the previous single-Task model where the entire workflow ran inside one sub-agent. The phase-per-Task model ensures user gates are never skipped due to context budget limits.

### Standard Pattern (Default)

Tasks execute sequentially, one at a time. Simple and predictable. Used for most features.

```
T001 → T002 → T003 → T004
```

### Parallel Pattern

Tasks marked `[P]` in the plan can run simultaneously. The planner marks tasks as parallel-safe when they don't share files.

```
T001 (setup)  →  T002 [P] ──┐
                  T003 [P] ──┼── run in parallel  →  T005 (integration)
                  T004 [P] ──┘
```

### Council Pattern

For complex features, the planner explores multiple approaches before committing:

```
/tdd implement caching layer with council pattern
```

This spawns multiple planners, each proposing a different architecture. You compare and choose.

### Watchdog Pattern

The reviewer acts as a watchdog between implementation and simplification. If it finds TDD violations, implementation goes back to the test writer — not forward to the simplifier.

---

## Runtime Output

All `docs/` directories are created at runtime by the agents. They are gitignored by default and not committed to your repository.

```
docs/                              # Created at runtime (gitignored)
├── analysis/                      # Codebase analysis reports (/analyze)
├── decisions/                     # Decision logs (documenter)
├── designs/                       # Design exploration (designer)
├── manifests/                     # Test coverage manifests (test-writer)
├── plans/                         # Technical plans (planner)
├── requirements/                  # Feature requirements (clarifier)
├── state/                         # Workflow state (orchestrator)
│   ├── current-phase.json
│   ├── task-status.json
│   ├── decisions.md
│   ├── exploration-context.md
│   ├── blockers.json
│   ├── reviewer-reports/
│   └── archive/
└── tickets/                       # Local ticket tracking (ticket-manager)
    ├── backlog/
    ├── active/
    └── completed/
```

---

## Plugin Structure

```
lemongrab/
├── .claude-plugin/
│   └── marketplace.json            # Marketplace listing
├── plugins/
│   └── lemongrab/
│       ├── .claude-plugin/
│       │   └── plugin.json         # Plugin metadata
│       ├── agents/                 # 17 agent definitions
│       │   ├── lemongrab.md        #   Orchestrator
│       │   ├── analyzer.md         #   Context builder
│       │   ├── clarifier.md        #   Requirements analyst
│       │   ├── designer.md         #   Design explorer
│       │   ├── planner.md          #   Technical architect
│       │   ├── test-writer.md      #   RED phase (failing tests)
│       │   ├── implementer.md      #   GREEN phase (minimal code)
│       │   ├── reviewer.md         #   TDD compliance auditor
│       │   ├── security-reviewer.md#   Security auditor
│       │   ├── performance-reviewer.md # Performance auditor
│       │   ├── spec-reviewer.md    #   Spec compliance auditor
│       │   ├── coherence-reviewer.md#  Cross-task design auditor
│       │   ├── pr-reviewer.md      #   PR diff reviewer
│       │   ├── simplifier.md       #   REFACTOR phase
│       │   ├── documenter.md       #   Decision documenter
│       │   ├── qa-engineer.md      #   E2E browser testing
│       │   └── ticket-manager.md   #   Work item tracking
│       ├── commands/               # 6 slash commands
│       │   ├── tdd.md
│       │   ├── analyze.md
│       │   ├── ticket.md
│       │   ├── bootstrap.md
│       │   ├── pr-review.md        #   Standalone PR review
│       │   └── resume.md
│       ├── skills/                 # 20 reusable domain skills
│       │   ├── analyzing-codebases/
│       │   ├── auditing-tdd-compliance/
│       │   ├── brainstorming/
│       │   ├── communicating-progress/
│       │   ├── convergence-discipline/
│       │   ├── documenting-decisions/
│       │   ├── enforcing-tdd/
│       │   ├── formatting-decisions/
│       │   ├── gathering-requirements/
│       │   ├── integrating-external-sources/
│       │   ├── managing-branches-and-prs/
│       │   ├── managing-work-items/
│       │   ├── planning-technical-work/
│       │   ├── recovering-from-failures/
│       │   ├── reviewing-spec-compliance/
│       │   ├── security-awareness/
│       │   ├── simplifying-code/
│       │   ├── systematic-debugging/
│       │   ├── using-git-worktrees/
│       │   ├── verifying-before-completion/
│       │   └── running-verifications/  # Verification gate scripts
│       │       ├── SKILL.md
│       │       └── scripts/
│       │           ├── verify-requirements.sh
│       │           ├── verify-plan-structure.sh
│       │           ├── verify-manifest-coverage.sh
│       │           ├── verify-test-integrity.sh
│       │           └── verify-state-consistency.sh
│       ├── hooks/                  # 6 automation hooks
│       │   ├── hooks.json
│       │   └── scripts/
│       │       ├── verify-environment.sh
│       │       ├── pre-commit-guard.sh
│       │       ├── agent-boundaries.sh
│       │       ├── phase-transition-guard.sh
│       │       ├── auto-format.sh
│       │       └── checkpoint-tracker.sh
│       └── examples/
│           ├── lemongrab-workflow-walkthrough.md
│           ├── user-authentication-requirements.md
│           ├── user-authentication-plan.md
│           └── user-authentication-decisions.md
├── .gitignore
└── README.md
```

---

## Prerequisites and Integrations

### Required

- **Claude Code CLI** with plugin support

That's it. No other dependencies. The plugin works out of the box for greenfield features, analysis, and bootstrap workflows.

### Optional MCP Integrations

These unlock additional workflow types but are NOT required for core functionality.

| Integration | Unlocks | How to Set Up |
|-------------|---------|--------------|
| **Linear MCP** | `/ticket` workflow — implement from Linear tickets, automatic status updates, PR creation | Install and configure the Linear MCP plugin separately |
| **Notion MCP** | PRD/RFC workflows — extract requirements from Notion documents | Install and configure the Notion MCP plugin separately |
| **Chrome DevTools MCP** | QA phase — automated browser testing against acceptance criteria | Install and configure the Chrome DevTools MCP server |

### What happens without optional integrations?

| Missing Integration | Impact |
|--------------------|--------|
| No Linear MCP | `/ticket` command won't work. Use `/tdd` instead and manually copy requirements from your ticket. |
| No Notion MCP | PRD/RFC workflows won't work. Use `/tdd` instead and manually describe the feature. |
| No Chrome DevTools MCP | QA phase is skipped (verdict: NOT_APPLICABLE). Unit and integration tests still run. |

---

## Pros and Cons

### Pros

| Benefit | Details |
|---------|---------|
| **Test-driven by default** | Every line of code exists because a test demanded it. No untested code ships. |
| **No assumptions** | The clarifier catches ambiguity before any code is written. You define what you want. |
| **Multiple review layers** | TDD compliance, security, performance, and spec reviewers run in parallel. Issues caught early. |
| **Rollback safety** | Git checkpoints after every task. Something breaks? Roll back to the last working state. |
| **Resumable** | Session interrupted? `/resume` picks up exactly where it left off. No lost work. |
| **Documented decisions** | Captures WHY decisions were made, not just WHAT was built. Future-you will thank present-you. |
| **Language agnostic** | Works with any language Claude Code supports — TypeScript, Python, Rust, Go, Ruby, etc. |
| **Shell-level enforcement** | Agent boundary and phase transition hooks are impossible for Claude to bypass. The test writer literally cannot write production code, and the orchestrator cannot skip workflow phases. |
| **You stay in control** | 7 explicit approval gates. Nothing major happens without your "yes." |
| **Structured output** | Requirements, plans, manifests, decisions — all in organized docs/ directories. |

### Cons

| Drawback | Details |
|----------|---------|
| **Slower than direct coding** | The process overhead (questions, approvals, reviews) adds time. Not suitable for quick hacks. |
| **Requires your attention** | Approval gates mean you can't just fire and forget. You need to answer questions and approve things. |
| **Opinionated workflow** | TDD is mandatory. You can't skip tests. If you don't want TDD, this isn't for you. |
| **Context window pressure** | Large features with many tasks consume context. Very large features (10+ tasks) may need multi-ticket workflow. |
| **Overkill for small tasks** | One-line bug fixes don't need 17 agents. Use Claude Code directly for trivial changes. |
| **Learning curve** | Understanding the phases, gates, and agents takes a few runs to internalize. |
| **No partial TDD** | You can't skip the test phase for "just this one function." TDD is all-or-nothing. |

---

## Limitations

### Hard Limitations (Cannot Be Worked Around)

| Limitation | Details |
|-----------|---------|
| **Tests are mandatory** | There is no flag to skip the test-writing phase. TDD is the core design principle. |
| **Max 3 files per task** | The planner enforces this. Larger changes are split into multiple tasks. |
| **Sequential approval gates** | You cannot batch-approve all gates at once. Each requires explicit approval. |
| **No test modification by implementer** | The implementer agent is physically blocked from writing to test files by shell hooks. |
| **Read-only reviewers** | Reviewer agents cannot modify files — they can only report findings. |

### Soft Limitations (Have Workarounds)

| Limitation | Workaround |
|-----------|-----------|
| **Large features consume context** | Use `/ticket` with multiple tickets or `sub-issues of` to split into smaller chunks |
| **QA only works with browser UI** | Non-UI apps get `NOT_APPLICABLE` for QA — unit/integration tests still cover them |
| **Linear/Notion integration required for some workflows** | Use `/tdd` and manually describe features instead of `/ticket` or PRD/RFC workflows |
| **No built-in test sharding** | Large test suites run fully — parallelize at the task level instead |
| **Cannot modify requirements mid-build** | If requirements change, the current task finishes, then requirements can be updated and the plan regenerated |

### Platform Notes

- Works on macOS, Linux, and any platform that supports Claude Code CLI
- Auto-format hook supports: prettier (JS/TS), black (Python), gofmt (Go), rustfmt (Rust)
- Desktop notifications (macOS only) fire when Claude needs your input

---

## FAQ

### General

**"What is Lemongrab?"**

A Claude Code plugin that enforces test-driven development through 17 specialized agents. Instead of one agent doing everything, each agent has a specific role (clarify requirements, write tests, implement code, review, simplify, document) and strict boundaries about what it can do.

**"Do I need to learn TDD to use this?"**

No. The plugin enforces TDD for you. You describe what you want, answer questions, and approve checkpoints. The agents handle the red-green-refactor cycle automatically.

**"Does this work with my language/framework?"**

Yes. Lemongrab is language-agnostic. It works with anything Claude Code supports: TypeScript, Python, Rust, Go, Ruby, Java, C#, and more. It auto-detects your test framework and adapts.

**"How long does a workflow take?"**

Depends on feature complexity. A simple 2-task feature might take 10-15 minutes of active time (including your review and approvals). A complex 8-task feature could take an hour or more. Most of that time is Claude working — you're only active at approval gates.

### Workflow

**"Do I have to use all the agents?"**

No. At minimum, the core loop is: Clarifier > Test Writer > Implementer. The reviewers, simplifier, and documenter add quality but can be adjusted. However, you can't remove individual agents from the `/tdd` workflow — use individual agent invocation if you want a subset.

**"What if I disagree with the clarifier's questions?"**

Answer them. If a question is irrelevant, say so — the clarifier will note it as out of scope. If the clarifier is asking too many questions, tell it: "That's enough detail, let's proceed."

**"What if I disagree with the plan?"**

At the PLAN_APPROVAL gate, you can: approve, request specific modifications, or reject entirely with an explanation. The planner will revise until you're satisfied.

**"Can I skip the design phase?"**

For small features (1-3 expected tasks), the design phase is automatically skipped. For medium+ features, you can tell the orchestrator to skip it.

**"Can I skip simplification?"**

Yes. At the PRE_SIMPLIFY gate for each task, you can choose to skip simplification and keep the code as-is.

### TDD

**"Tests are failing — is that wrong?"**

No. In TDD, tests are written BEFORE code. They're supposed to fail initially. That's the "RED" phase. The important thing is they fail for the **right reason** (function doesn't exist yet) not the wrong reason (syntax error in the test).

**"What is a TDD_VIOLATION verdict?"**

The reviewer found production code that no test exercises. This means:
1. Go back to test-writer to add the missing tests
2. Re-implement to ensure all code is test-driven
3. The workflow handles this automatically — you don't need to intervene

**"Can I write tests after implementation instead?"**

No. This is a TDD plugin. Tests-first is the core principle. If you want tests-after, use Claude Code directly without the plugin.

### Recovery

**"What if I get interrupted mid-feature?"**

```
/resume <feature-name>
```

The workflow saves state to `docs/state/` after every step. Resume picks up exactly where it left off.

**"What if something goes really wrong?"**

Every completed task has a git checkpoint. Roll back:
```bash
git log --oneline --grep="checkpoint:.*<feature>"
git reset --hard <commit-hash>
/resume <feature-name>
```

**"What if the tests keep failing and the implementer can't fix them?"**

A circuit breaker triggers after 5 consecutive failures for the same task. The workflow pauses and asks you to intervene — either fix the issue, adjust the test, or skip the task.

### Integration

**"Do I need Linear to use this?"**

No. Linear is only needed for the `/ticket` command. Use `/tdd` for everything else.

**"Do I need Notion to use this?"**

No. Notion is only needed for PRD/RFC workflows. Use `/tdd` and describe the feature manually instead.

**"Can I use this with GitHub Issues instead of Linear?"**

Not directly. The ticket manager integrates with Linear. For GitHub Issues, copy the issue content and use `/tdd` with a manual description.

---

## Troubleshooting

### "The clarifier is asking too many questions"

Tell it: "That's enough, let's proceed with what we have." It will mark remaining unknowns as assumptions and move forward.

### "The plan has too many tasks"

At PLAN_APPROVAL, say: "Simplify this — combine tasks X and Y" or "This should be 3 tasks maximum." The planner will revise.

### "The reviewer keeps finding TDD violations"

This means the implementer wrote code that no test covers. The workflow automatically sends it back to add tests. If this loops more than 2-3 times, the circuit breaker will pause and ask you to intervene.

### "The simplifier broke the tests"

This shouldn't happen — the simplifier reverts immediately if tests break. If it somehow persists, roll back:
```bash
git log --oneline --grep="checkpoint:"
git reset --hard <last-good-checkpoint>
```

### "/resume isn't finding my workflow"

Check that `docs/state/current-phase.json` exists. If the docs/ directory was deleted (it's gitignored), the state is lost and you'll need to start over with `/tdd`.

### "The agent-boundaries hook is blocking my writes"

The hook reads `currentAgent` from `docs/state/current-phase.json`. If this file is stale or wrong, the hook may incorrectly block writes. Fix the state file or delete it to reset.

### "The phase-transition-guard is blocking a phase change"

The guard enforces a strict state machine. If it blocks a transition, the error message tells you the valid transitions from the current phase. Common causes:

- **Skipped clarification**: The orchestrator tried to jump to planning without completing requirements gathering. Every workflow must go through `CLARIFY_IN_PROGRESS → CLARIFY_COMPLETE` first.
- **Missing artifacts**: Can't enter `PLAN_IN_PROGRESS` without a verified requirements doc, or `PLAN_APPROVED` without a verified plan doc.
- **Stale state file**: If `docs/state/current-phase.json` is left over from a previous run, delete it to start fresh.

### "I want to use Lemongrab but only for part of the workflow"

Use individual agent invocation:
```
Use the clarifier agent to gather requirements for <feature>
Use the test-writer agent to write tests for <file>
Use the reviewer agent to review <directory>
```

This bypasses the orchestrator and gives you direct access to specific capabilities.
