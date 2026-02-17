```
╦ ╦╔╗╔╔═╗╔═╗╔═╗╔═╗╔═╗╔╦╗╔═╗╔╗ ╦  ╔═╗ ┬ ┬ ┬
║ ║║║║╠═╣║  ║  ║╣ ╠═╝ ║ ╠═╣╠╩╗║  ║╣  │ │ │
╚═╝╝╚╝╩ ╩╚═╝╚═╝╚═╝╩   ╩ ╩ ╩╚═╝╩═╝╚═╝ o o o
```

# Lemongrab

**A TDD Multi-Agent Workflow Plugin for Claude Code**

Lemongrab is a Claude Code plugin that provides an advanced multi-agent workflow featuring test-driven development, parallel execution, code review, and automatic rollback capabilities. Install it in any project to get 10 specialized agents, 11 skills, and 5 slash commands.

---

## Install

```bash
claude plugin add peterphot/lemongrab
```

That's it. No files to copy, no configuration needed.

---

## What You Get

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

## Slash Commands

| Command | Description |
|---------|-------------|
| `/tdd <feature>` | Full TDD workflow: clarify, plan, build, document |
| `/analyze [path]` | Analyze an existing codebase to build context |
| `/ticket <id>` | Implement a feature from a Linear ticket |
| `/bootstrap <type>` | Bootstrap a new project with TDD structure |
| `/resume <feature>` | Resume an interrupted workflow |

### Examples

```
/tdd user authentication with JWT
/analyze
/ticket LIN-123
/bootstrap node-api
/resume user-authentication
```

You can also invoke workflows directly:

```
Use the lemongrab agent to implement <feature>
Use the lemongrab agent to analyze this codebase
Use the lemongrab agent to implement from PRD <notion-url>
Use the lemongrab agent to implement from RFC <notion-url>
```

---

## Prerequisites

### Required
- **Claude Code CLI** with plugin support

### Optional MCP Integrations

| Workflow | MCP Integration Required |
|----------|--------------------------|
| `/tdd`, `/analyze`, `/bootstrap` | None - works out of the box |
| `/ticket <id>` | Linear MCP plugin |
| `implement from PRD <url>` | Notion MCP plugin |
| `implement from RFC <url>` | Notion MCP plugin |

**Linear Integration** (for ticket workflows):
1. Install and configure the Linear MCP plugin separately
2. The agents will use `mcp__plugin_forge_linear__*` tools

**Notion Integration** (for PRD/RFC workflows):
1. Install and configure the Notion MCP plugin separately
2. The agents will use `mcp__plugin_forge_notion__*` tools

---

## Supported Workflows

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
│    /tdd <feature>        /analyze             /ticket <id>                 │
│                                                                             │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐           │
│  │   FROM PRD      │   │   FROM RFC      │   │  NEW PROJECT    │           │
│  │   (Notion)      │   │   (Notion)      │   │  (Bootstrap)    │           │
│  └────────┬────────┘   └────────┬────────┘   └────────┬────────┘           │
│           │                     │                     │                     │
│           ▼                     ▼                     ▼                     │
│  "implement from PRD    "implement from RFC    /bootstrap <type>            │
│   <notion-url>"          <notion-url>"                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Workflow Comparison

| Entry Point | Use When | What Happens |
|-------------|----------|--------------|
| `/tdd <feature>` | Building new functionality from scratch | Full workflow: clarify, plan, build, document |
| `/analyze` | Joining existing project or exploring | Builds context, creates analysis report |
| `/ticket <id>` | Work is defined in Linear | Extracts requirements from ticket, builds |
| `implement from PRD <url>` | PRD exists in Notion | Extracts requirements, creates tickets, builds |
| `implement from RFC <url>` | RFC exists with tech decisions | Uses RFC decisions as constraints, builds |
| `/bootstrap <type>` | Starting a brand new project | Creates structure, then transitions to features |
| `/resume <feature>` | Interrupted mid-workflow | Picks up from saved state |

---

## Standard Workflow (/tdd)

```
┌─────────────────────────────────────────────────────────────────────┐
│  YOU: "/tdd <feature>"                                               │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LEMONGRAB (runs automatically, interrupts only when needed)        │
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
│  │  3. TICKET TRACKING (opt-in)                                  │  │
│  │     "Track with Linear tickets, local tickets, or none?"      │  │
│  │     → If yes: TICKET MANAGER creates tickets from plan        │  │
│  │     → Stores mapping in task-status.json                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  4. FOR EACH TASK (automatic, no input needed)                │  │
│  │                                                               │  │
│  │     TEST WRITER  → Write tests (RED phase)                    │  │
│  │     IMPLEMENTER  → Make tests pass (GREEN phase)              │  │
│  │     REVIEWER     → Validate TDD compliance (WATCHDOG)         │  │
│  │     SIMPLIFIER   → Clean up (REFACTOR phase)                  │  │
│  │     GIT CHECKPOINT → Commit for rollback                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  5. DOCUMENTER                                                │  │
│  │     → Adds comments, creates decision log                     │  │
│  │     → Output: docs/decisions/<feature>.md                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                   │                                 │
│                                   ▼                                 │
│                         ✓ DONE! Summary provided                    │
└─────────────────────────────────────────────────────────────────────┘
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
/tdd <feature> with council pattern
```

### Watchdog Pattern
Reviewer agent catches issues between implementation and simplification.

---

## Agents

| Agent | Purpose | When Active |
|-------|---------|-------------|
| **Lemongrab** | Workflow orchestrator | Every workflow |
| **Analyzer** | Builds context from code, PRDs, RFCs, tickets | Analysis, ticket, PRD, RFC workflows |
| **Clarifier** | Gathers requirements through questions | Start of any feature |
| **Planner** | Creates technical design + tasks | After requirements are clear |
| **Test Writer** | Writes failing tests | Before implementation |
| **Implementer** | Makes tests pass | After tests exist |
| **Reviewer** | Validates and audits TDD compliance | After implementation |
| **Simplifier** | Removes complexity | After review approves |
| **Documenter** | Records the "what" and "why" | After code is complete |
| **Ticket Manager** | Creates/tracks work items | When ticket tracking enabled |

---

## Skills

Skills provide reusable domain knowledge that agents leverage automatically:

| Skill | Purpose | Used By |
|-------|---------|---------|
| `enforcing-tdd` | TDD discipline, red-green-refactor | test-writer, implementer |
| `auditing-tdd-compliance` | TDD audit, mutation testing | reviewer |
| `gathering-requirements` | Question frameworks, testable criteria | clarifier |
| `planning-technical-work` | Task breakdown, dependencies, architecture | planner |
| `documenting-decisions` | WHAT + WHY documentation, ADR templates | documenter |
| `simplifying-code` | Safe refactoring, code smell detection | simplifier |
| `communicating-progress` | Status reports, blockers, handoffs | lemongrab |
| `analyzing-codebases` | Structure analysis, pattern detection | analyzer |
| `integrating-external-sources` | PRD/RFC/ticket extraction patterns | analyzer |
| `formatting-decisions` | Decision block format, phase prefixes, attribution | clarifier, planner, implementer, reviewer, simplifier, lemongrab |
| `managing-work-items` | Linear & local ticket management | ticket-manager |

---

## Runtime Output

All `docs/` directories are created at runtime by the agents. They are gitignored by default.

```
docs/                           # Created at runtime (gitignored)
├── analysis/                   # Codebase analysis reports
├── decisions/                  # Decision logs
├── plans/                      # Technical plans
├── requirements/               # Feature requirements
├── state/                      # Workflow state (phase, tasks, blockers)
│   ├── reviewer-reports/       # Reviewer findings per task
│   └── archive/                # Archived decision logs
└── tickets/                    # Local ticket tracking
    ├── backlog/
    ├── active/
    └── completed/
```

---

## State Management & Recovery

The workflow maintains state in `docs/state/` for resilience:

- `current-phase.json` - Where you are in the workflow
- `task-status.json` - Per-task completion status with git checkpoints
- `blockers.json` - Issues needing resolution

**Resume after interruption:**
```
/resume <feature>
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

---

## Plugin Structure

```
lemongrab/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── agents/                      # 10 agent definitions
│   ├── lemongrab.md             # Workflow orchestrator
│   ├── analyzer.md              # Context builder
│   ├── clarifier.md             # Requirements gatherer
│   ├── planner.md               # Technical architect
│   ├── test-writer.md           # TDD test writer
│   ├── implementer.md           # Minimal code writer
│   ├── reviewer.md              # TDD compliance auditor
│   ├── simplifier.md            # Code simplifier
│   ├── documenter.md            # Technical writer
│   └── ticket-manager.md        # Work item tracker
├── commands/                    # 5 slash commands
│   ├── tdd.md
│   ├── analyze.md
│   ├── ticket.md
│   ├── bootstrap.md
│   └── resume.md
├── skills/                      # 11 skill definitions
│   ├── analyzing-codebases/
│   ├── auditing-tdd-compliance/
│   ├── communicating-progress/
│   ├── documenting-decisions/
│   ├── enforcing-tdd/
│   ├── formatting-decisions/
│   ├── gathering-requirements/
│   ├── integrating-external-sources/
│   ├── managing-work-items/
│   ├── planning-technical-work/
│   └── simplifying-code/
├── examples/                    # Usage examples
├── .gitignore
└── README.md
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

### "What if I get interrupted mid-feature?"

```
/resume <feature>
```

The workflow saves state to `docs/state/` and picks up where it left off.

### "What is a TDD_VIOLATION verdict?"

If the reviewer finds code that no test exercises, it returns TDD_VIOLATION. This means:
1. Go back to test-writer to add missing tests
2. Then re-implement to ensure code is test-driven
3. Never ship code that isn't demanded by a failing test
