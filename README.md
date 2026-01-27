```
╦ ╦╔╗╔╔═╗╔═╗╔═╗╔═╗╔═╗╔╦╗╔═╗╔╗ ╦  ╔═╗ ┬ ┬ ┬
║ ║║║║╠═╣║  ║  ║╣ ╠═╝ ║ ╠═╣╠╩╗║  ║╣  │ │ │
╚═╝╝╚╝╩ ╩╚═╝╚═╝╚═╝╩   ╩ ╩ ╩╚═╝╩═╝╚═╝ o o o
```

# Lemongrab

**A TDD Multi-Agent Workflow for Claude Code**

Lemongrab is a project template that sets up an advanced multi-agent workflow for Claude Code, featuring test-driven development, parallel execution, code review, and automatic rollback capabilities.

---

## What is Lemongrab?

Lemongrab is a starter template you can clone for new projects. It sets up specialized Claude Code agents that ensure:

- **No assumptions** - Requirements are gathered and clarified before any code is written
- **Tests first** - Tests are written before implementation (TDD)
- **Code review** - Reviewer agent catches issues early (watchdog pattern)
- **Minimal code** - Only write what's needed to pass tests
- **Clean code** - Refactoring is a dedicated step
- **Documentation** - Captures both the "what" and the "why"
- **Resilience** - State tracking enables recovery from interruptions
- **Safety** - Git checkpoints allow rollback on failure
- **Flexibility** - Multiple entry points for different workflows

---

## Quick Start

### Step 1: Clone the Template

```bash
git clone https://github.com/peterphot/lemongrab.git my-new-project
cd my-new-project
rm -rf .git  # Remove template's git history
git init     # Start fresh
```

### Step 2: Set Up the Agents

Open Claude Code in your project directory:

```bash
cd my-new-project
claude
```

Then say:

```
Read AGENTIC-WORKFLOW.md and set up the agentic workflow. Create all the agent
files in .claude/agents/ and the docs folder structure as specified.
```

**What Claude will create:**
1. `.claude/agents/` with all 10 agent definition files
2. `docs/` folder structure for requirements, plans, decisions, analysis, tickets, and state

**Verify it worked:**
```bash
ls .claude/agents/
# Should show: analyzer.md, clarifier.md, documenter.md, implementer.md,
#              orchestrator.md, planner.md, reviewer.md, simplifier.md,
#              test-writer.md, ticket-manager.md

ls docs/
# Should show: analysis/, decisions/, plans/, requirements/, state/, tickets/
```

### Step 3: You're Ready!

Start building with any of these entry points:

```
Use the orchestrator agent to implement <your feature>
Use the orchestrator agent to analyze this codebase
Use the orchestrator agent to implement ticket LIN-123
Use the orchestrator agent to implement from PRD <notion-url>
```

---

## Supported Workflows

Lemongrab supports multiple entry points depending on your situation:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         WORKFLOW ENTRY POINTS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐           │
│  │  NEW FEATURE    │   │ EXISTING CODE   │   │  FROM TICKET    │           │
│  │  (Greenfield)   │   │   (Join/Add)    │   │   (Linear)      │           │
│  └────────┬────────┘   └────────┬────────┘   └────────┬────────┘           │
│           │                     │                     │                     │
│           ▼                     ▼                     ▼                     │
│  "implement <feature>"  "analyze codebase"   "implement ticket LIN-123"    │
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐           │
│  │   FROM PRD      │   │   FROM RFC      │   │  NEW PROJECT    │           │
│  │   (Notion)      │   │   (Notion)      │   │  (Bootstrap)    │           │
│  └────────┬────────┘   └────────┬────────┘   └────────┬────────┘           │
│           │                     │                     │                     │
│           ▼                     ▼                     ▼                     │
│  "implement from PRD   "implement from RFC   "bootstrap <project-type>"    │
│   <notion-url>"         <notion-url>"                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Workflow Comparison

| Entry Point | Use When | What Happens |
|-------------|----------|--------------|
| `implement <feature>` | Building new functionality from scratch | Full workflow: clarify → plan → build → document |
| `analyze codebase` | Joining existing project or exploring | Builds context, creates analysis report |
| `implement ticket LIN-123` | Work is defined in Linear | Extracts requirements from ticket, builds |
| `implement from PRD <url>` | PRD exists in Notion | Extracts requirements, creates tickets, builds |
| `implement from RFC <url>` | RFC exists with tech decisions | Uses RFC decisions as constraints, builds |
| `bootstrap <type>` | Starting a brand new project | Creates structure, then transitions to features |
| `resume <feature>` | Interrupted mid-workflow | Picks up from saved state |

---

## Standard Workflow (implement feature)

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: "Use the orchestrator agent to implement <feature>"           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR (runs automatically, interrupts only when needed)     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  1. CLARIFIER                                                 │  │
│  │     "What exactly do you need?"                               │  │
│  │     → Asks YOU questions ←── You answer                       │  │
│  │     → Output: docs/requirements/<feature>.md                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  2. PLANNER                                                   │  │
│  │     "How should we build this?"                               │  │
│  │     → Asks YOU tech decisions ←── You answer                  │  │
│  │     → Optional: Council pattern (multiple approaches)         │  │
│  │     → Output: docs/plans/<feature>.md                         │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  3-6. FOR EACH TASK (automatic, no input needed)              │  │
│  │                                                               │  │
│  │     ┌─────────────────┐                                       │  │
│  │     │  TEST WRITER    │  Write tests for this task            │  │
│  │     │  (RED phase)    │  → Tests FAIL (correct!)              │  │
│  │     │                 │  → Parallel for [P] tasks             │  │
│  │     └────────┬────────┘                                       │  │
│  │              │                                                │  │
│  │              ▼                                                │  │
│  │     ┌─────────────────┐                                       │  │
│  │     │  IMPLEMENTER    │  Write minimal code to pass tests     │  │
│  │     │  (GREEN phase)  │  → Tests PASS                         │  │
│  │     └────────┬────────┘                                       │  │
│  │              │                                                │  │
│  │              ▼                                                │  │
│  │     ┌─────────────────┐                                       │  │
│  │     │  REVIEWER       │  Validate before cleanup (NEW!)       │  │
│  │     │  (WATCHDOG)     │  → APPROVED or NEEDS_FIXES            │  │
│  │     └────────┬────────┘                                       │  │
│  │              │                                                │  │
│  │              ▼                                                │  │
│  │     ┌─────────────────┐                                       │  │
│  │     │  SIMPLIFIER     │  Clean up without breaking tests      │  │
│  │     │  (REFACTOR)     │  → Tests stay GREEN                   │  │
│  │     └────────┬────────┘                                       │  │
│  │              │                                                │  │
│  │              ▼                                                │  │
│  │     ┌─────────────────┐                                       │  │
│  │     │  GIT CHECKPOINT │  Commit for rollback capability       │  │
│  │     └─────────────────┘                                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  7. DOCUMENTER                                                │  │
│  │     "Why did we build it this way?"                           │  │
│  │     → Adds comments, creates decision log                     │  │
│  │     → Output: docs/decisions/<feature>.md                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│                         ✓ DONE! Summary provided                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Ticket Workflow (from Linear)

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: "Use the orchestrator to implement ticket LIN-123"            │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ANALYZER (extracts from Linear)                                    │
├─────────────────────────────────────────────────────────────────────┤
│  • Fetches ticket details from Linear API                           │
│  • Fetches comments for additional context                          │
│  • Extracts acceptance criteria                                     │
│  • Creates docs/requirements/<ticket-id>.md                         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PLANNER (scale-aware)                                              │
├─────────────────────────────────────────────────────────────────────┤
│  Small ticket (1-3 tasks) → Minimal plan, quick cycle               │
│  Large ticket (4+ tasks) → Full plan with architecture              │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
                    [Standard BUILD cycle]
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  TICKET MANAGER (updates Linear)                                    │
├─────────────────────────────────────────────────────────────────────┤
│  • Updates ticket status: Done                                      │
│  • Adds completion comment with summary                             │
│  • Links commits to ticket                                          │
└─────────────────────────────────────────────────────────────────────┘
```

---

## PRD Workflow (from Notion)

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: "Use the orchestrator to implement from PRD <notion-url>"     │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ANALYZER (extracts from Notion PRD)                                │
├─────────────────────────────────────────────────────────────────────┤
│  • Fetches PRD from Notion                                          │
│  • Extracts user stories, acceptance criteria                       │
│  • Identifies out of scope                                          │
│  • Flags missing information                                        │
│  • Creates docs/requirements/<feature>.md                           │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR ASKS:                                                 │
│  "PRD contains X user stories. Create Linear tickets, local         │
│   tickets, or proceed without tickets?"                             │
└─────────────────────────────────────────────────────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
        [Linear]             [Local]              [No tickets]
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
                                   ▼
                    [Standard PLAN → BUILD cycle]
                    (Skips CLARIFY - PRD provides requirements)
```

---

## Analysis Workflow (existing codebase)

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: "Use the orchestrator to analyze this codebase"               │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ANALYZER (explores codebase)                                       │
├─────────────────────────────────────────────────────────────────────┤
│  • Maps directory structure                                         │
│  • Identifies technology stack                                      │
│  • Detects architecture patterns                                    │
│  • Finds entry points and key components                            │
│  • Notes established conventions                                    │
│  • Creates docs/analysis/<project>.md                               │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR ASKS:                                                 │
│  "Analysis complete. What would you like to do?"                    │
│  • Implement a feature                                              │
│  • Fix a bug                                                        │
│  • Add tests                                                        │
│  • Refactor                                                         │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
                    [Transitions to appropriate workflow]
```

---

## Orchestration Patterns

### Standard Pattern (Default)
Sequential execution with one agent at a time. Simple and predictable.

### Parallel Pattern
For tasks marked `[P]`, spawn multiple test-writers simultaneously:
```
[T004] [P] Test: feature A  ──┐
[T005] [P] Test: feature B  ──┼── Run in parallel
[T006] [P] Test: feature C  ──┘
```

### Council Pattern
For complex features, spawn multiple planners with different approaches:
```
Use the orchestrator agent with council pattern to implement <feature>
```

### Watchdog Pattern
Reviewer agent catches issues between implementation and simplification.

---

## The Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| **Orchestrator** | Runs workflows with multiple entry points | Every workflow (recommended entry point) |
| **Analyzer** | Builds context from code, PRDs, RFCs, tickets | Joining projects, extracting requirements |
| **Ticket Manager** | Creates/tracks work items in Linear or locally | Planning work, tracking progress |
| **Clarifier** | Gathers requirements through questions | Start of any new feature |
| **Planner** | Creates technical design + tasks | After requirements are clear |
| **Test Writer** | Writes failing tests | Before implementation |
| **Implementer** | Makes tests pass | After tests exist |
| **Reviewer** | Validates and audits TDD compliance | After implementation |
| **Simplifier** | Removes complexity | After review approves |
| **Documenter** | Records the "what" and "why" | After code is complete |

---

## State Management & Recovery

The workflow maintains state in `docs/state/` for resilience:

- `current-phase.json` - Where you are in the workflow
- `task-status.json` - Per-task completion status with git checkpoints
- `blockers.json` - Issues needing resolution

**Resume after interruption:**
```
Use the orchestrator agent to resume <feature>
```

---

## Rollback Capability

After each successful task, a git checkpoint is created:
```bash
git commit -m "checkpoint: [T001] Setup complete - user-authentication"
```

**If something goes wrong:**
```bash
# See all checkpoints
git log --oneline --grep="checkpoint:.*<feature>"

# Rollback to specific checkpoint
git reset --hard <commit-hash>
```

Or ask the orchestrator:
```
Use the orchestrator agent to rollback <feature> to task [T002]
```

---

## Project Structure

```
your-project/
├── .claude/
│   └── agents/
│       ├── orchestrator.md       # Workflow orchestration (multiple entry points)
│       ├── analyzer.md           # Context building (code, PRDs, RFCs, tickets)
│       ├── ticket-manager.md     # Work item tracking (Linear or local)
│       ├── clarifier.md          # Requirements gathering
│       ├── planner.md            # Technical design
│       ├── test-writer.md        # Write failing tests
│       ├── implementer.md        # Make tests pass
│       ├── reviewer.md           # Validate and audit TDD compliance
│       ├── simplifier.md         # Clean up code
│       └── documenter.md         # Document what and why
├── skills/                       # Domain knowledge for agents
│   ├── enforcing-tdd/            # TDD discipline patterns
│   ├── auditing-tdd-compliance/  # TDD audit & mutation testing
│   ├── gathering-requirements/   # Requirement question frameworks
│   ├── planning-technical-work/  # Task breakdown & architecture
│   ├── documenting-decisions/    # WHAT + WHY documentation
│   ├── simplifying-code/         # Safe refactoring patterns
│   ├── communicating-progress/   # Status reports & handoffs
│   ├── analyzing-codebases/      # Codebase exploration patterns
│   ├── integrating-external-sources/  # PRD/RFC/ticket extraction
│   └── managing-work-items/      # Linear & local ticket management
├── docs/
│   ├── requirements/             # Feature requirements (gathered or extracted)
│   ├── plans/                    # Technical plans
│   ├── decisions/                # Decision logs
│   ├── analysis/                 # Codebase analysis reports
│   ├── tickets/                  # Local ticket tracking
│   │   ├── backlog/
│   │   ├── active/
│   │   └── completed/
│   └── state/                    # Workflow state
├── AGENTIC-WORKFLOW.md           # Workflow documentation
└── README.md                     # This file
```

---

## Skills (Domain Knowledge)

Skills provide reusable domain knowledge that agents leverage automatically:

| Skill | Purpose | Used By |
|-------|---------|---------|
| `enforcing-tdd` | TDD discipline, red-green-refactor | test-writer, implementer |
| `auditing-tdd-compliance` | TDD audit, mutation testing | reviewer |
| `gathering-requirements` | Question frameworks, testable criteria | clarifier |
| `planning-technical-work` | Task breakdown, dependencies, architecture | planner |
| `documenting-decisions` | WHAT + WHY documentation, ADR templates | documenter |
| `simplifying-code` | Safe refactoring, code smell detection | simplifier |
| `communicating-progress` | Status reports, blockers, handoffs | orchestrator, all agents |
| `analyzing-codebases` | Structure analysis, pattern detection | analyzer |
| `integrating-external-sources` | PRD/RFC/ticket extraction patterns | analyzer |
| `managing-work-items` | Linear & local ticket management | ticket-manager |

**Agents handle orchestration.** Skills provide expertise.

```
┌─────────────────────────────────────────────────────┐
│  AGENT (orchestration)                              │
│    └── Uses SKILL (domain knowledge)                │
│                                                     │
│  Examples:                                          │
│  analyzer agent → analyzing-codebases skill         │
│  analyzer agent → integrating-external-sources      │
│  ticket-manager → managing-work-items skill         │
│  test-writer agent → enforcing-tdd skill            │
│  reviewer agent → auditing-tdd-compliance skill     │
│  planner agent → planning-technical-work skill      │
│  documenter agent → documenting-decisions skill     │
└─────────────────────────────────────────────────────┘
```

---

## Manual Workflow (Alternative)

If you prefer step-by-step control instead of the orchestrator:

```
# Step 1: Clarify requirements
Use the clarifier agent to gather requirements for <feature>

# Step 2: Create technical plan
Use the planner agent to create a plan for <feature>

# Step 3: For each task in the plan...
Use the test-writer agent for task [T001]
Use the implementer agent for task [T001]
Use the reviewer agent for task [T001]
Use the simplifier agent for the code from task [T001]
git commit -m "checkpoint: [T001] <description>"
# Repeat for T002, T003, etc.

# Step 4: Document
Use the documenter agent for <feature>
```

---

## TDD Enforcement

Lemongrab enforces strict TDD discipline through multiple checkpoints:

### Test-Writer Responsibilities
- **Requirement traceability** - Every test links to a requirement ID
- **Failure verification** - Tests must fail for the RIGHT reason (not syntax errors)
- **Coverage mapping** - Happy path, boundaries, and error cases required
- **Mutation mindset** - "Would my tests catch a small code change?"

### Implementer Discipline
- **One test at a time** - Write code to pass ONE failing test, then repeat
- **No untested code** - Every line must be demanded by a failing test
- **Diff tracking** - Report exactly what code each test demanded

### Reviewer TDD Audit
- **TDD compliance check** - Verifies every line of code has a test
- **Untested code detection** - Finds if/else branches, error handling without tests
- **Mutation testing** - Mentally checks if code changes would be caught
- **Verdict: TDD_VIOLATION** - Returns to test-writer if untested code found

---

## FAQ

### "Do I have to use all the agents?"

No. At minimum use:
- **Clarifier** - Prevents misunderstandings
- **Test Writer + Implementer** - Core TDD loop

The reviewer, simplifier, and documenter add quality but can be skipped for quick prototypes.

### "Tests are failing - is that wrong?"

No! In TDD, tests are written BEFORE code. They're supposed to fail initially. But they must fail for the **right reason** (function doesn't exist) not the wrong reason (syntax error in your test).

### "What does the reviewer check for?"

**TDD Compliance:**
- Every line of code is demanded by a test
- No untested conditional branches
- Requirement traceability complete

**Code Quality:**
- **CRITICAL**: Security issues, data loss, untested code paths
- **WARNING**: Performance concerns, weak test coverage
- **INFO**: Interesting choices to document

### "How do I customize the agents?"

Edit the files in `.claude/agents/`. Each is a markdown file with instructions.

### "What if I get interrupted mid-feature?"

The workflow saves state to `docs/state/`. Just say:
```
Use the orchestrator agent to resume <feature>
```

### "What is a TDD_VIOLATION verdict?"

If the reviewer finds code that no test exercises, it returns TDD_VIOLATION. This means:
1. Go back to test-writer to add missing tests
2. Then re-implement to ensure code is test-driven
3. Never ship code that isn't demanded by a failing test
