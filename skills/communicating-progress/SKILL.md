---
name: communicating-progress
description: Communicate progress, status, and blockers clearly during multi-step workflows. Use when reporting task status, escalating blockers, handing off between agents, or summarizing work completed. Provides status templates, blocker formats, and handoff patterns.
---

# Communicating Progress

This skill helps communicate progress clearly during multi-step workflows. Good communication enables coordination between agents, keeps users informed, and ensures smooth handoffs.

## When to Use

- Reporting task completion or status
- Escalating blockers that need resolution
- Handing off work to another agent
- Summarizing completed work
- Requesting user input or decisions

## Core Principle

**Be specific and actionable.** Every status update should answer:
- WHAT happened (specific actions taken)
- WHAT's next (clear next steps)
- WHAT's blocked (if anything, with specifics)

## Status Report Formats

### Task Completion Report

```markdown
## Task Complete: [TXXX] [Task Title]

### What Was Done
- [Specific action 1]
- [Specific action 2]
- [Specific action 3]

### Files Changed
- `path/to/file.js` - [What changed]
- `path/to/test.js` - [What changed]

### Tests
- Status: PASSING | FAILING
- New tests: [count]
- Total coverage: [if known]

### Next Task
- [TXXX] [Next task title]
- Blocked by: [nothing | list blockers]
```

### Phase Completion Report

```markdown
## Phase Complete: [Phase Name]

### Summary
[1-2 sentence summary of what this phase accomplished]

### Tasks Completed
- [T001] ✓ [Title]
- [T002] ✓ [Title]
- [T003] ✓ [Title]

### Artifacts Created
- `docs/requirements/feature.md` - Requirements document
- `src/feature/` - Feature implementation
- `tests/feature.test.js` - Test suite

### Metrics
- Tests: [X] passing, [Y] failing
- Files changed: [count]
- Lines added/removed: +[X]/-[Y]

### Next Phase
[Phase name] - [Brief description]
```

### Workflow Summary (End of Feature)

```markdown
## Feature Complete: [Feature Name]

### What Was Built
[2-3 sentence description of the feature]

### Requirements Met
- [US1] ✓ [User story title]
- [US2] ✓ [User story title]

### Technical Summary
- Components: [List of main components]
- APIs: [List of endpoints if any]
- Database: [Changes if any]

### Test Coverage
- Unit tests: [count]
- Integration tests: [count]
- All tests: PASSING

### Documentation
- Requirements: `docs/requirements/feature.md`
- Plan: `docs/plans/feature.md`
- Decisions: `docs/decisions/feature.md`

### How to Verify
1. [Step to verify feature works]
2. [Step to verify feature works]

### Known Limitations
- [Limitation 1] - [Why it's acceptable]
- [Limitation 2] - [Planned for future]
```

## Blocker Communication

### Blocker Report Format

```markdown
## BLOCKED: [Brief description]

### Task Affected
[TXXX] [Task title]

### Blocker Details
**Type**: [Technical | Requirement | External | Permission]
**Severity**: [Critical | High | Medium]

**Description**:
[Clear explanation of what's blocked and why]

### What I Tried
1. [Attempted solution 1] - [Result]
2. [Attempted solution 2] - [Result]

### Options to Resolve
1. **[Option A]**: [Description]
   - Pro: [Benefit]
   - Con: [Drawback]
2. **[Option B]**: [Description]
   - Pro: [Benefit]
   - Con: [Drawback]

### Recommended Action
[Specific recommendation with reasoning]

### Input Needed
- [ ] [Specific decision or input needed from user]
```

### Blocker Types

| Type | Example | Resolution Path |
|------|---------|-----------------|
| Technical | Dependency conflict | Research alternatives, propose options |
| Requirement | Ambiguous acceptance criteria | Ask clarifying questions |
| External | API unavailable | Document workaround or wait |
| Permission | Need credentials/access | Request from user |

## Agent Handoff Patterns

### Handoff Report (Agent to Agent)

```markdown
## Handoff: [From Agent] → [To Agent]

### Context
**Feature**: [Feature name]
**Task**: [TXXX] [Task title]
**Previous Phase**: [Phase completed]

### Work Completed
- [Specific deliverable 1]
- [Specific deliverable 2]

### Files for Review
- `path/to/file.js` - [Purpose]
- `path/to/test.js` - [Purpose]

### Current State
- Tests: [PASSING | FAILING - X failures]
- Lint: [CLEAN | X warnings]

### Your Task
[Clear description of what the receiving agent should do]

### Important Notes
- [Constraint or consideration 1]
- [Constraint or consideration 2]

### Success Criteria
- [ ] [Specific criterion]
- [ ] [Specific criterion]
```

### Common Handoff Scenarios

| From | To | Handoff Contains |
|------|----|------------------|
| Clarifier | Planner | Requirements doc, user stories, acceptance criteria |
| Planner | Test Writer | Plan with task breakdown, architecture decisions |
| Test Writer | Implementer | Failing tests, test file locations, what each tests |
| Implementer | Reviewer | Implementation, test results, diff summary |
| Reviewer | Simplifier | Approval + suggestions, or rejection + required fixes |
| Simplifier | Documenter | Clean code, refactoring summary, tests still passing |

## Progress Indicators

### In-Progress Status

```markdown
## Status: [Task ID] In Progress

### Currently Working On
[Specific current action]

### Progress
- [x] Step 1 complete
- [x] Step 2 complete
- [ ] Step 3 (current)
- [ ] Step 4
- [ ] Step 5

### Estimated Remaining
[X] more steps

### No Blockers | Potential Blocker
[Details if applicable]
```

### Checkpoint Update

```markdown
## Checkpoint: [Feature Name]

### Phase: [Current phase]
### Task: [TXXX] [Current task]

### State Snapshot
- Completed tasks: [T001, T002, T003]
- Current task: [T004] - [status]
- Remaining tasks: [T005, T006]

### Git Checkpoint
- Commit: `[hash]`
- Message: `checkpoint: [TXXX] [description]`

### Can Resume From Here
To continue: "Resume [feature] from task [TXXX]"
```

## Requesting User Input

### Decision Request

```markdown
## Input Needed: [Brief topic]

### Context
[Why this decision is needed]

### Options

**Option A: [Name]**
- Description: [What this means]
- Trade-off: [Pro/con]

**Option B: [Name]**
- Description: [What this means]
- Trade-off: [Pro/con]

### Recommendation
[Your recommendation and why]

### Please Choose
Reply with A, B, or provide alternative direction.
```

### Clarification Request

```markdown
## Clarification Needed: [Topic]

### Current Understanding
[What I currently think the requirement means]

### Ambiguity
[What's unclear]

### Questions
1. [Specific question]?
2. [Specific question]?

### Default Assumption
If no response, I will assume: [default]
```

## Communication Checklist

Before sending any status update:

- [ ] **Specific**: No vague language ("some," "various," "things")
- [ ] **Actionable**: Clear what happens next
- [ ] **Complete**: All relevant information included
- [ ] **Structured**: Uses appropriate template
- [ ] **Honest**: Accurate representation of state

## Anti-Patterns

### Vague Status
```
Bad:  "Made good progress on the feature"
Good: "Completed T001-T003, tests passing, starting T004"
```

### Missing Context
```
Bad:  "I'm blocked"
Good: "Blocked on T004: bcrypt import fails, tried npm install, need node version check"
```

### Unclear Handoff
```
Bad:  "Done with my part, over to you"
Good: "Tests written for login (3 files), all failing as expected, implementer should make these pass"
```

### No Next Steps
```
Bad:  "Task complete"
Good: "Task T003 complete, tests passing. Next: T004 (implements password hashing)"
```

## State File Updates

When updating workflow state, use these formats:

### current-phase.json
```json
{
  "feature": "user-authentication",
  "phase": "implementation",
  "currentTask": "T004",
  "status": "in_progress",
  "lastUpdated": "2024-01-15T10:30:00Z"
}
```

### task-status.json
```json
{
  "feature": "user-authentication",
  "tickets": {
    "enabled": true,
    "type": "linear",
    "team": "Engineering",
    "sourceTicket": null,
    "mapping": {
      "T001": { "ticketId": "uuid-001", "identifier": "LIN-456" },
      "T002": { "ticketId": "uuid-002", "identifier": "LIN-457" },
      "T003": { "ticketId": "uuid-003", "identifier": "LIN-458" },
      "T004": { "ticketId": "uuid-004", "identifier": "LIN-459" }
    }
  },
  "tasks": {
    "T001": {"status": "complete", "checkpoint": "abc123"},
    "T002": {"status": "complete", "checkpoint": "def456"},
    "T003": {"status": "complete", "checkpoint": "ghi789"},
    "T004": {"status": "in_progress", "started": "2024-01-15T10:30:00Z"}
  }
}
```

### blockers.json
```json
{
  "active": [
    {
      "id": "B001",
      "task": "T004",
      "type": "technical",
      "description": "bcrypt fails to install",
      "created": "2024-01-15T10:35:00Z"
    }
  ],
  "resolved": []
}
```
