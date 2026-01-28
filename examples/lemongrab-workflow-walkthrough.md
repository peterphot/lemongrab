# Lemongrab Workflow Walkthrough

This document demonstrates the complete TDD multi-agent workflow using a hypothetical feature: **config file parser**.

---

## Phase 1: CLARIFY (clarifier agent)

The clarifier gathers requirements by asking specific questions:

```
┌─ Clarifier Questions ─────────────────────────────────┐
│                                                        │
│ 1. What file format should the parser support?         │
│    □ JSON  □ YAML  □ TOML  □ INI  □ Other             │
│                                                        │
│ 2. What should happen if the config file is missing?   │
│    □ Error  □ Use defaults  □ Create empty file        │
│                                                        │
│ 3. Should the parser validate config values?           │
│    □ Yes (against schema)  □ No (raw parsing only)     │
│                                                        │
│ 4. What is the expected config structure?              │
│    (need specific fields and types)                    │
│                                                        │
│ 5. Are there any performance requirements?             │
│    (file size limits, parse time)                      │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Key Principle:** The clarifier NEVER assumes. Every ambiguity triggers a question.

**Output:** `docs/requirements/config-parser.md`

---

## Phase 2: PLAN (planner agent)

After requirements are confirmed, the planner creates a technical design with ordered tasks:

```markdown
# Plan: config-parser

## Architecture
Single module with load(), validate(), get() functions

## Task Breakdown
- [T001] Setup: Create src/config/ directory
- [T002] [US1] Test: Write tests for load() function
- [T003] [US1] Implement: Create load() to pass tests
- [T004] [US1] Test: Write tests for validation
- [T005] [US1] Implement: Create validate() to pass tests
- [T006] [P] [US2] Test: Write tests for get() accessor  ← parallel
- [T007] [P] [US2] Test: Write tests for defaults        ← parallel
- [T008] [US2] Implement: Create get() and defaults
```

**Task Markers:**
- `[TXXX]` - Task ID for tracking
- `[USX]` - Links to user story
- `[P]` - Can run in parallel with other [P] tasks

**Output:** `docs/plans/config-parser.md`

---

## Phase 3: BUILD (per-task loop)

For each task, the workflow cycles through: **test → implement → review → simplify → checkpoint**

### Step 3a: TEST (test-writer agent)

```
┌─ Task T002: Test ──────────────────────────────────────┐
│                                                         │
│  test-writer creates:                                   │
│  ┌─────────────────────────────────────────────────┐   │
│  │ describe('[US1] Config Loading', () => {        │   │
│  │   it('[FR-001] loads valid JSON file', ...)     │   │
│  │   it('[FR-001] throws on missing file', ...)    │   │
│  │   it('[FR-001] throws on invalid JSON', ...)    │   │
│  │ });                                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Tests run: 3 failing ✗ (expected - RED phase)         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key Principle:** Tests are the specification. They MUST fail initially (RED phase of TDD).

### Step 3b: IMPLEMENT (implementer agent)

```
┌─ Task T003: Implement ─────────────────────────────────┐
│                                                         │
│  implementer writes MINIMAL code:                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ function load(path) {                            │   │
│  │   if (!fs.existsSync(path)) throw new Error();  │   │
│  │   const content = fs.readFileSync(path, 'utf8');│   │
│  │   return JSON.parse(content);                    │   │
│  │ }                                                │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  Tests run: 3 passing ✓ (GREEN phase)                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key Principle:** Every line of code must be DEMANDED by a failing test. No extra code.

### Step 3c: REVIEW (reviewer agent - watchdog)

```
┌─ Task T003: Review (watchdog) ─────────────────────────┐
│                                                         │
│  reviewer checks:                                       │
│  ├─ TDD Compliance: ✓ All code demanded by tests       │
│  ├─ Untested paths: NONE                               │
│  ├─ Mutation test: ✓ Would catch > to >= change        │
│  ├─ Security: ✓ No path traversal vulnerability        │
│  └─ Verdict: APPROVED                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Possible Verdicts:**
- `APPROVED` → proceed to simplifier
- `NEEDS_FIXES` → return to implementer with specific fixes
- `TDD_VIOLATION` → return to test-writer to add tests first

### Step 3d: SIMPLIFY (simplifier agent)

```
┌─ Task T003: Simplify ──────────────────────────────────┐
│                                                         │
│  simplifier checks:                                     │
│  ├─ Dead code: NONE                                    │
│  ├─ Complexity: LOW                                    │
│  └─ Changes: None needed                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key Principle:** Tests must stay GREEN throughout. If a change breaks tests, revert immediately.

### Step 3e: CHECKPOINT (git commit)

```
┌─ Git Checkpoint ───────────────────────────────────────┐
│                                                         │
│  git commit -m "checkpoint: [T003] load() complete"    │
│  Rollback point: abc123                                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Key Principle:** Each checkpoint is a rollback point. If something goes wrong later, we can reset to this known-good state.

---

## Parallel Execution

Tasks marked with `[P]` can run simultaneously:

```
T006 test-writer ──┬── run simultaneously
T007 test-writer ──┘
         │
         ▼
    Both complete
         │
         ▼
T008 implementer (handles both)
```

Lemongrab spawns multiple agents in a single message for parallel tasks.

---

## Phase 4: DOCUMENT (documenter agent)

After all tasks complete, the documenter records decisions:

```markdown
# Decision Log: config-parser

## Key Decisions

### Decision 1: Synchronous file reading
**Choice:** Used fs.readFileSync instead of async
**Why:** Config is loaded once at startup, simplicity preferred
**Trade-off:** Blocks event loop briefly at startup

### Decision 2: JSON-only support
**Choice:** Only support JSON format initially
**Why:** Covers 90% of use cases, can extend later
**Trade-off:** Users with YAML configs need to convert

## How to Recreate
1. Create src/config/index.js
2. Implement load() with JSON.parse
3. Add existsSync check for missing file error
4. Implement validate() with schema checking
5. Add get() accessor with dot notation support
6. Add defaults merging logic
```

**Output:** `docs/decisions/config-parser.md`

---

## State Files

Lemongrab maintains state for resilience:

```
docs/state/
├── current-phase.json    → Tracks current workflow position
└── task-status.json      → Tracks per-task completion and checkpoints
```

**current-phase.json:**
```json
{
  "feature": "config-parser",
  "phase": "COMPLETE",
  "currentTask": null,
  "startedAt": "2024-01-15T10:30:00Z",
  "lastUpdated": "2024-01-15T14:45:00Z"
}
```

**task-status.json:**
```json
{
  "feature": "config-parser",
  "tasks": {
    "T001": { "status": "completed", "checkpoint": "abc123" },
    "T002": { "status": "completed", "checkpoint": "def456" },
    "T003": { "status": "completed", "checkpoint": "ghi789" }
  }
}
```

---

## Summary Report

At completion, lemongrab provides a summary:

```
┌─ Lemongrab Complete ───────────────────────────────────┐
│                                                         │
│  Feature: config-parser                                │
│  Tasks completed: 8/8                                  │
│  Tests passing: 12                                     │
│  Files created: 3                                      │
│  Git checkpoints: 5                                    │
│                                                         │
│  Documentation:                                        │
│  • docs/requirements/config-parser.md                  │
│  • docs/plans/config-parser.md                         │
│  • docs/decisions/config-parser.md                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Rollback Capability

If something goes wrong at any point:

```bash
# See all checkpoints for the feature
git log --oneline --grep="checkpoint:.*config-parser"

# Rollback to a specific checkpoint
git reset --hard <checkpoint-hash>
```

Lemongrab can also handle rollbacks automatically when tests fail repeatedly.

---

## Orchestration Patterns

Lemongrab supports four patterns:

| Pattern | When to Use | Description |
|---------|-------------|-------------|
| **Standard** | Most tasks | Sequential execution, one agent at a time |
| **Parallel** | [P] marked tasks | Run multiple test-writers simultaneously |
| **Council** | Complex decisions | Spawn 2-3 planners with different approaches |
| **Watchdog** | All implementations | Reviewer validates before simplification |

---

## How to Invoke

```
# Standard workflow
Use lemongrab agent to implement <feature>

# With council pattern (multiple plan options)
Use lemongrab agent with council pattern to implement <feature>

# Resume interrupted workflow
Use lemongrab agent to resume <feature>

# Rollback
Use lemongrab agent to rollback <feature> to task [TXXX]
```
