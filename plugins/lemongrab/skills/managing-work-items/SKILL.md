---
name: managing-work-items
description: Create and track work items in Linear or locally. Use when creating tickets from plans, tracking implementation progress, updating ticket status, or linking commits to work items. Provides templates for Linear issues and local ticket files.
version: 1.0.0
---

# Managing Work Items

This skill helps create and track work items either in Linear (via MCP) or locally in the project. Work items provide traceability from requirements through implementation to completion.

## When to Use

- Creating tickets from a technical plan
- Tracking progress during implementation
- Updating ticket status as work completes
- Linking commits to work items
- Choosing between Linear and local tracking
- Creating feature branches for isolated work
- Creating pull requests for code review
- Managing parallel work with git worktrees

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

Co-Authored-By: Claude <noreply@anthropic.com>"
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

Co-Authored-By: Claude <noreply@anthropic.com>
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
- CREATE PR moves the ticket to "In Review"
- Completion summary posts with PR link but does NOT set "Done"
- "Done" happens automatically when the PR is merged (via Linear's GitHub integration)
- Progress comment format: "Task [TXXX] complete: <title>. X of Y tasks done."

### Per-Task Tickets (STANDARD/PRD workflows)

When each task has its own ticket:
- Individual task completions post progress comments only (no status change)
- CREATE PR moves all tickets to "In Review"
- Completion summary posts brief note with PR link (no status change)
- "Done" happens automatically when the PR is merged (via Linear's GitHub integration)
- Format: "Completed as part of <feature>. PR: <url>. Merge the PR to complete this work."

### Posting the Summary

**Linear (shared ticket):** Post summary with PR link, do NOT set "Done".
```
mcp__plugin_forge_linear__create_comment
  issueId: "[source ticket ID]"
  body: "[completion summary with PR link]"
```
"Done" is set automatically when the PR is merged (via Linear's GitHub integration).

**Linear (per-task tickets):** Post brief note with PR link, no status change.
```
mcp__plugin_forge_linear__create_comment
  issueId: "[each ticket ID]"
  body: "Completed as part of <feature>. PR: <url>. Merge the PR to complete this work."
```

**Local (shared ticket):**
Append summary with PR link to ticket file. Do NOT move to completed/ — that happens after PR merge.

**Local (per-task tickets):**
Append brief note with PR link only. Keep in active/ until PR merge.

## Branch Management

Every feature gets its own branch. Branch hygiene applies regardless of whether tickets are enabled.

### Branch Naming Conventions

| Workflow | Branch Name Pattern | Example |
|----------|-------------------|---------|
| TICKET | `feat/<ticket-id>-<slug>` | `feat/LIN-123-auth-flow` |
| STANDARD | `feat/<feature-slug>` | `feat/user-authentication` |
| PRD | `feat/<feature-slug>` | `feat/onboarding-wizard` |
| RFC | `feat/<feature-slug>` | `feat/api-v2-migration` |

Rules:
- Slug: lowercase, hyphens only, no special characters
- Max 50 chars total for branch name
- Always branch from `main` (or configured base branch)

### Branch Creation

```bash
# Ensure main is up to date
git checkout main && git pull origin main

# Create feature branch
git checkout -b feat/LIN-123-auth-flow
```

### Branch in task-status.json

```json
{
  "tickets": {
    "branch": "feat/LIN-123-auth-flow",
    "baseBranch": "main"
  }
}
```

## PR Creation

After all tasks pass, create a pull request for code review.

### PR Title Format

| Workflow | Format | Example |
|----------|--------|---------|
| TICKET | `<ticket-id>: <title>` | `LIN-123: Add auth flow` |
| STANDARD | `feat: <feature-name>` | `feat: user authentication` |

### PR Body Template

```markdown
## Summary
- <1-3 bullet points from completion summary>

## Tickets
- Closes LIN-123
- Closes LIN-124

## Changes
<output of git diff --stat main..HEAD>

## Test Plan
- All tests passing: X tests
- [Key verification steps]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### Creating the PR

```bash
# Push branch
git push -u origin feat/LIN-123-auth-flow

# Create PR
gh pr create --base main --head feat/LIN-123-auth-flow \
  --title "LIN-123: Add auth flow" \
  --body "<PR body>"
```

### Linear Auto-Close on Merge

Include `Closes LIN-XXX` in the PR body for each associated ticket. When the repo has
Linear's GitHub integration enabled, merging the PR automatically transitions issues to "Done".

**Prerequisite:** The repository must have the Linear-GitHub integration enabled for auto-close
to work. If it's not available, the completion summary should note:
"Tickets need manual status update to 'Done' after merging the PR."

### After PR Creation

- Move all associated tickets to "In Review"
- Post PR link as comment on each ticket
- Store PR URL in task-status.json

## Git Worktrees for Parallel Work

When the plan has [P] parallel tasks, use git worktrees to isolate each task's work.

### Why Worktrees

- Each parallel task gets its own working directory
- No branch switching needed — agents work simultaneously
- Clean merge back to feature branch when done

### .gitignore Setup

Before creating worktrees, ensure `.worktrees/` is in `.gitignore`:
```bash
# Add .worktrees/ to .gitignore if not already present
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
```

### Creating Worktrees

```bash
# From the feature branch, create a worktree for each parallel task
git worktree add .worktrees/T004/ -b feat/auth-flow-T004
git worktree add .worktrees/T005/ -b feat/auth-flow-T005
```

### Worktree State in task-status.json

```json
{
  "tickets": {
    "worktrees": {
      "T004": { "path": ".worktrees/T004", "branch": "feat/auth-flow-T004" },
      "T005": { "path": ".worktrees/T005", "branch": "feat/auth-flow-T005" }
    }
  }
}
```

### Merging Worktree Branches

After all parallel tasks complete:

```bash
# Switch to feature branch
git checkout feat/LIN-123-auth-flow

# Merge each worktree branch
git merge feat/auth-flow-T004
git merge feat/auth-flow-T005

# Clean up worktrees
git worktree remove .worktrees/T004/
git worktree remove .worktrees/T005/

# Delete worktree branches
git branch -d feat/auth-flow-T004
git branch -d feat/auth-flow-T005
```

If merge conflicts occur, ask the user how to resolve them.

### Worktree Cleanup

Always clean up worktrees after merging:
1. Remove the worktree directory: `git worktree remove <path>`
2. Delete the worktree branch: `git branch -d <branch>`
3. Remove the entry from task-status.json tickets.worktrees

## Ticket Lifecycle

The full ticket lifecycle with PR-based review:

```
Backlog → In Progress → In Review → Done
  │           │             │          │
  │           │             │          └─ PR merged (auto via Linear-GitHub integration)
  │           │             └─ PR created (ticket-manager CREATE PR mode)
  │           └─ Task work begins (ticket-manager UPDATE STATUS mode)
  └─ Ticket created (ticket-manager CREATE FROM PLAN mode)
```

| Status | Triggered By | Action |
|--------|-------------|--------|
| Backlog | CREATE FROM PLAN | Ticket created |
| In Progress | UPDATE STATUS | Work begins on task |
| In Review | CREATE PR | PR created, ready for review |
| Done | PR merge | Linear-GitHub integration auto-closes |

**Important:** The workflow never directly sets tickets to "Done". That status transition
happens when the PR is merged, either automatically via Linear's GitHub integration or
manually by the user after merge.

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
- [ ] Feature branch created from main

### During Implementation
- [ ] All work on feature branch (not main)
- [ ] Status updated when starting
- [ ] Progress logged
- [ ] Blockers flagged
- [ ] Commits reference ticket

### After Build Completes
- [ ] PR created with `Closes LIN-XXX` in body
- [ ] All tickets moved to "In Review"
- [ ] PR link posted as comment on each ticket
- [ ] Completion summary posted with PR link

### After PR Merge
- [ ] Tickets auto-transitioned to "Done" (Linear-GitHub integration)
- [ ] If no auto-close: manually update tickets to "Done"
- [ ] Worktrees cleaned up (if parallel work was used)
- [ ] Local tickets moved to completed/ (if local tracking)
