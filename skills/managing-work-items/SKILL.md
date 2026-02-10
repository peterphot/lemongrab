---
name: managing-work-items
description: Create and track work items in Linear or locally. Use when creating tickets from plans, tracking implementation progress, updating ticket status, or linking commits to work items. Provides templates for Linear issues and local ticket files.
---

# Managing Work Items

This skill helps create and track work items either in Linear (via MCP) or locally in the project. Work items provide traceability from requirements through implementation to completion.

## When to Use

- Creating tickets from a technical plan
- Tracking progress during implementation
- Updating ticket status as work completes
- Linking commits to work items
- Choosing between Linear and local tracking

## Core Principle

**Every piece of work should be tracked.** Whether in Linear or locally, work items provide:
- Traceability from requirements to code
- Progress visibility
- Historical record of decisions

## Choosing: Linear vs Local

| Use Linear When | Use Local When |
|-----------------|----------------|
| Team collaboration needed | Solo work or prototyping |
| External stakeholders | No Linear access |
| Sprint/cycle planning | Quick experiments |
| Long-running projects | One-off tasks |
| Need integrations (GitHub, Slack) | Offline work |

## Linear Integration

### Creating Issues

**Fetch team context first:**
```
mcp__plugin_forge_linear__list_issue_statuses
  team: "[team name]"
```

**Create issue:**
```
mcp__plugin_forge_linear__create_issue
  title: "Add user authentication flow"
  team: "[team name]"
  description: "[markdown description]"
  labels: ["feature", "auth"]
```

### Issue Description Template

**Simple Issue:**
```markdown
## Summary
[1-2 sentences: what and why]

## Acceptance Criteria
- [ ] [Specific, verifiable outcome]
- [ ] [Specific, verifiable outcome]
```

**Complex Issue:**
```markdown
## Summary
[1-2 sentences: what and why]

## Background
[Context, motivation, related issues]

## Implementation
[Steps or approach]

- [ ] Step 1
- [ ] Step 2

| File | Action |
|------|--------|
| path/to/file | Create/Modify/Delete |

## Acceptance Criteria
- [ ] [Specific, verifiable outcome]
- [ ] [Specific, verifiable outcome]

## Test Plan
[How to verify the change works]

## Notes
[Gotchas, dependencies, future work]
```

### Updating Issues

**Update status:**
```
mcp__plugin_forge_linear__update_issue
  id: "[issue ID]"
  state: "In Progress"
```

**Add comment:**
```
mcp__plugin_forge_linear__create_comment
  issueId: "[issue ID]"
  body: "Completed authentication service. Moving to tests."
```

### Linking to Commits

Include issue ID in commit messages:
```
git commit -m "feat(auth): add login endpoint

Implements LIN-123

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

## Local Ticket Management

### Directory Structure
```
docs/
└── tickets/
    ├── active/
    │   ├── T001-setup-auth-module.md
    │   └── T002-implement-login.md
    ├── completed/
    │   └── T000-project-setup.md
    └── backlog/
        └── T003-password-reset.md
```

### Local Ticket Template

```markdown
# [TXXX] [Title]

## Status
- [ ] Backlog
- [ ] In Progress
- [x] Completed

## Created
[Date]

## Summary
[1-2 sentences: what and why]

## Requirements
- Source: [PRD/RFC/Ticket reference]
- FR: [Requirement ID]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

## Implementation Notes
[Approach, decisions made]

## Files Changed
| File | Change |
|------|--------|
| path/to/file | [description] |

## Commits
- `abc123` - [message]
- `def456` - [message]

## Completed
[Date when moved to completed/]
```

### Local Workflow

**Create ticket:**
```bash
# Create in backlog
touch docs/tickets/backlog/T001-feature-name.md
```

**Start work:**
```bash
# Move to active
mv docs/tickets/backlog/T001-*.md docs/tickets/active/
```

**Complete work:**
```bash
# Move to completed
mv docs/tickets/active/T001-*.md docs/tickets/completed/
```

## Creating Tickets from Plans

### From Task Breakdown

Given a plan with tasks:
```markdown
### Phase 1: Setup
- [T001] Setup: Create authentication module
- [T002] [P] Setup: Install dependencies

### Phase 2: Implementation
- [T003] Test: Write login tests
- [T004] Implement: Create login endpoint
```

**Create Linear tickets:**
```
For each task in plan:
1. mcp__plugin_forge_linear__create_issue
     title: "[TXXX] [Task description]"
     team: "[team]"
     description: "[generated from plan context]"
     labels: ["phase-1"] or ["phase-2"]

2. Set dependencies using blockedBy/blocks:
   T003 blockedBy: [T001, T002]
   T004 blockedBy: [T003]
```

**Create local tickets:**
```
For each task in plan:
1. Create docs/tickets/backlog/TXXX-slug.md
2. Fill template with plan context
3. Note dependencies in file
```

## Progress Tracking

### Status Updates

**Linear:**
```
mcp__plugin_forge_linear__update_issue
  id: "[issue ID]"
  state: "In Progress"  # or "Done", "In Review"
```

**Local:**
Update status checkbox in ticket file:
```markdown
## Status
- [ ] Backlog
- [x] In Progress
- [ ] Completed
```

### Progress Comments

**Linear:**
```
mcp__plugin_forge_linear__create_comment
  issueId: "[issue ID]"
  body: "## Progress Update\n\n- Completed: [x]\n- Remaining: [y]\n- Blockers: [none|description]"
```

**Local:**
Add to ticket file:
```markdown
## Progress Log
- [date]: Started implementation
- [date]: Tests passing, starting refactor
- [date]: Completed
```

## Batch Operations

### Create Multiple Tickets from Plan

```markdown
## Ticket Creation Checklist

For plan: [feature-name]

- [ ] T001: [title] → Created: [Linear ID or local path]
- [ ] T002: [title] → Created: [Linear ID or local path]
- [ ] T003: [title] → Created: [Linear ID or local path]

Dependencies set:
- [ ] T003 blocked by T001, T002
- [ ] T004 blocked by T003
```

### Bulk Status Update

After completing a phase:
```
1. List all tickets for phase
2. Update each to "Completed"
3. Move blocked tickets to "Ready"
```

## Commit-Ticket Linking

### Commit Message Format

```
type(scope): description

[Body explaining what and why]

Implements: [TXXX] or [LIN-123]
Closes: [TXXX] or [LIN-123]  # if completing ticket

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Update Ticket on Commit

**After commit, update ticket:**

Linear:
```
mcp__plugin_forge_linear__create_comment
  issueId: "[issue ID]"
  body: "Commit `abc123`: [commit message]"
```

Local:
Add to ticket's Commits section:
```markdown
## Commits
- `abc123` - feat(auth): add login endpoint
```

## Completion Summary

When all tasks for a feature are complete, post a final summary to the ticket(s).

### Completion Summary Template

```markdown
## Completion Summary

### Tasks Completed
- [T001] <title> ✓
- [T002] <title> ✓
- [T003] <title> ✓

### Test Results
- X tests passing, 0 failing

### Files Changed
| File | Change |
|------|--------|
| path/to/file | Created/Modified |

### Git Checkpoints
- `abc123` - checkpoint: [T001] <description>
- `def456` - checkpoint: [T002] <description>

### Documentation
- Requirements: docs/requirements/<feature>.md
- Plan: docs/plans/<feature>.md
- Decisions: docs/decisions/<feature>.md
```

### Summary Content Guidance

- **Tasks:** List all tasks with completion status from task-status.json
- **Test results:** Run test suite and report pass/fail counts
- **Files changed:** Aggregate from git log across all checkpoints
- **Checkpoints:** List commit hashes and messages from task-status.json
- **Documentation:** Link to all generated docs

### Shared Ticket (TICKET workflow)

When all tasks map to the same source ticket:
- Individual task completions are progress comments (not status changes)
- Only the completion summary sets the ticket to "Done"
- Post the full completion summary template to the shared ticket
- Progress comment format: "Task [TXXX] complete: <title>. X of Y tasks done."

### Per-Task Tickets (STANDARD/PRD workflows)

When each task has its own ticket:
- Each ticket was already set to "Done" during TASK COMPLETE — do NOT change status again
- Each ticket gets a brief completion note, not the full feature summary
- Format: "Completed as part of <feature>. See docs/decisions/<feature>.md for full summary."
- The full completion summary goes to the decision log, not to individual tickets

### Posting the Summary

**Linear (shared ticket):**
```
mcp__plugin_forge_linear__create_comment
  issueId: "[source ticket ID]"
  body: "[completion summary]"

mcp__plugin_forge_linear__update_issue
  id: "[source ticket ID]"
  state: "Done"
```

**Linear (per-task tickets):** Post brief note only, no status change.
```
mcp__plugin_forge_linear__create_comment
  issueId: "[each ticket ID]"
  body: "Completed as part of <feature>. See docs/decisions/<feature>.md for full summary."
```

**Local (shared ticket):**
Append summary to ticket file, update status to Completed, move to completed/.

**Local (per-task tickets):**
Append brief note only (tickets already in completed/).

## Checklist

### Before Creating Tickets
- [ ] Plan exists with task breakdown
- [ ] Each task has clear scope
- [ ] Dependencies identified
- [ ] Decided: Linear or local

### After Creating Tickets
- [ ] All tasks have tickets
- [ ] Dependencies set correctly
- [ ] Labels/categories applied
- [ ] Linked to source (PRD/RFC)

### During Implementation
- [ ] Status updated when starting
- [ ] Progress logged
- [ ] Blockers flagged
- [ ] Commits reference ticket

### After Completion
- [ ] Status set to Done/Completed
- [ ] All commits linked
- [ ] Files changed documented
- [ ] Completion summary added to ticket
- [ ] Moved to completed (local)
