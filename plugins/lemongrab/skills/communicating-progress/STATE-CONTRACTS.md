# State File Contracts

Canonical schemas for lemongrab workflow state files. All agents that read or write
these files MUST conform to these schemas. The orchestrator (lemongrab.md) is the
authoritative owner — this document mirrors its definitions.

## docs/state/current-phase.json

Tracks the current position in the workflow.

### Valid Phase Values

Use these exact strings:

`CLARIFY_IN_PROGRESS`, `CLARIFY_COMPLETE`, `PLAN_IN_PROGRESS`, `PLAN_COMPLETE`,
`PLAN_APPROVED`, `BRANCH_CREATED`, `BUILD_IN_PROGRESS`, `BUILD_COMPLETE`,
`PR_CREATED`, `DOCUMENT_IN_PROGRESS`, `DOCUMENT_COMPLETE`, `COMPLETE`

### Schema

```json
{
  "feature": "user-authentication",
  "phase": "BUILD_IN_PROGRESS",
  "currentTask": "T004",
  "status": "in_progress",
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| feature | string | Feature slug (kebab-case) |
| phase | string | One of the valid phase values above |
| currentTask | string | Current task ID (e.g., "T004") or null |
| status | string | "in_progress", "complete", "blocked" |
| lastUpdated | string | ISO 8601 timestamp |

## docs/state/task-status.json

Tracks per-task completion, ticket mapping, branch info, and workflow counters.

### Schema

```json
{
  "feature": "user-authentication",
  "tickets": {
    "enabled": true,
    "type": "linear",
    "team": "Engineering",
    "branch": "feat/LIN-123-auth-flow",
    "baseBranch": "main",
    "worktrees": {},
    "pr": { "url": null, "number": null },
    "sourceTicket": null,
    "mapping": {
      "T001": { "ticketId": "uuid-001", "identifier": "LIN-456" }
    }
  },
  "tasks": {
    "T001": {
      "status": "complete",
      "checkpoint": "abc123",
      "tddState": {
        "testsWritten": true,
        "testFiles": ["tests/auth/login.test.ts"],
        "testsCount": 6,
        "manifestFile": "docs/manifests/auth-T001.md",
        "implementationStarted": true,
        "implementationFiles": ["src/auth/login.ts"],
        "testsPassingCount": 6,
        "reviewVerdict": "APPROVED",
        "simplified": true
      },
      "filesCreated": ["src/auth/login.ts"],
      "filesModified": [],
      "lastAgent": "simplifier",
      "lastSubstep": "simplified",
      "lastUpdated": "2024-01-15T12:00:00Z"
    }
  },
  "counters": {
    "circuitBreakerTrips": 0,
    "tasksSinceLastMilestone": 0,
    "qaAvailable": null
  }
}
```

### tickets section

| Field | Type | Description |
|-------|------|-------------|
| enabled | bool | Guards all ticket operations. If false, skip ticket ops |
| type | string | "linear" or "local" |
| team | string | Linear team name (if linear) |
| branch | string | Feature branch name |
| baseBranch | string | Base branch (typically "main") |
| worktrees | object | Maps task IDs to {path, branch} for parallel work |
| pr | object | {url, number} — null until PR created |
| sourceTicket | string/null | Set in TICKET workflow; all tasks map to this ticket |
| mapping | object | Maps task IDs to {ticketId, identifier} |

### tasks section

| Field | Type | Description |
|-------|------|-------------|
| status | string | "backlog", "in_progress", "complete", "rolled_back" |
| checkpoint | string | Git commit hash at completion |
| tddState | object | Sub-step tracking (see below) |
| filesCreated | array | Files created by this task |
| filesModified | array | Files modified by this task |
| lastAgent | string | Last agent that worked on this task |
| lastSubstep | string | Last sub-step completed |
| lastUpdated | string | ISO 8601 timestamp |

### tddState sub-fields

| Field | Set By | Description |
|-------|--------|-------------|
| testsWritten | test-writer | true when tests exist |
| testFiles | test-writer | Paths to test files |
| testsCount | test-writer | Number of tests written |
| manifestFile | test-writer | Path to coverage manifest |
| implementationStarted | implementer | true when impl begun |
| implementationFiles | implementer | Paths to implementation files |
| testsPassingCount | implementer | Tests now passing |
| reviewVerdict | orchestrator | "APPROVED", "NEEDS_FIXES", "TDD_VIOLATION" |
| simplified | simplifier | true when simplification done |

### counters section

| Field | Type | Description |
|-------|------|-------------|
| circuitBreakerTrips | int | Tasks that hit circuit breaker. Reset at workflow start. >= 3 triggers workflow circuit breaker |
| tasksSinceLastMilestone | int | Tasks since last milestone review. Reset after each milestone |
| qaAvailable | bool/null | Chrome DevTools MCP availability. null = not checked |

## docs/state/blockers.json

Tracks active and resolved blockers.

### Schema

```json
{
  "active": [
    {
      "id": "B001",
      "task": "T004",
      "type": "technical",
      "description": "bcrypt fails to install",
      "created": "2024-01-15T10:35:00Z",
      "attempt": 1
    }
  ],
  "resolved": [
    {
      "id": "B001",
      "task": "T004",
      "type": "technical",
      "description": "bcrypt fails to install",
      "created": "2024-01-15T10:35:00Z",
      "resolution": "Installed via npm with --build-from-source",
      "resolvedAt": "2024-01-15T10:40:00Z"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| id | string | Blocker ID (B001, B002, ...) |
| task | string | Task ID this blocks |
| type | string | "technical", "requirement", "external", "permission" |
| description | string | What is blocked and why |
| created | string | ISO 8601 timestamp |
| attempt | int | Retry count |
| resolution | string | How it was resolved (resolved entries only) |
| resolvedAt | string | When resolved (resolved entries only) |

## Read-Modify-Write Rule

All agents MUST use read-modify-write when updating state files:
1. Read the current file contents
2. Parse JSON
3. Update only the fields you own
4. Write the full file back

Never overwrite fields set by other agents. Never truncate the file.
