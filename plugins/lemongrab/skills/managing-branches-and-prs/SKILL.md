---
name: managing-branches-and-prs
description: Manage git branches, pull requests, and worktrees during lemongrab TDD workflows. Use when the ticket-manager agent is creating feature branches (BRANCH_CREATED phase), creating pull requests (PR_CREATED phase), or setting up worktrees for parallel tasks. Not for ticket tracking or status updates (see managing-work-items).
version: 1.0.0
---

# Managing Branches and PRs

This skill handles git branch management, pull request creation, and worktree setup for parallel work during lemongrab TDD workflows.

## When to Use

- Creating feature branches for isolated work
- Creating pull requests for code review
- Managing parallel work with git worktrees
- Linking PRs to Linear tickets for auto-close
- Per-ticket branching in MULTI_TICKET workflows

## Branch Management

### Branch Naming Conventions

| Workflow | Branch Name Pattern | Example |
|----------|-------------------|---------|
| TICKET | `feat/<ticket-id>-<slug>` | `feat/LIN-123-auth-flow` |
| STANDARD | `feat/<feature-slug>` | `feat/user-authentication` |
| PRD | `feat/<feature-slug>` | `feat/onboarding-wizard` |
| RFC | `feat/<feature-slug>` | `feat/api-v2-migration` |

**Per-task branch naming** (when `tickets.branching = "per-task"`):

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Integration | `feat/<feature-slug>` | `feat/user-authentication` |
| Task | `feat/<feature-slug>/TXXX-<task-slug>` | `feat/user-authentication/T001-setup-project` |
| Coherence fixes | `feat/<feature-slug>/coherence-fixes` | `feat/user-authentication/coherence-fixes` |
| Documentation | `feat/<feature-slug>/docs-<feature>` | `feat/user-authentication/docs-user-auth` |

Task branch rules:
- Task slug: derived from task title (lowercase, hyphens, max 30 chars)
- Nested under integration branch name with `/` separator
- Always branch from integration branch (not `main`)

General rules:
- Slug: lowercase, hyphens only, no special characters
- Max 50 chars total for branch name (integration branch)
- Always branch from `main` (or configured base branch) for integration branch

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

## Per-Task Branching Strategy

When `tickets.branching = "per-task"`, each task gets its own branch and PR merged into
an integration branch. This produces small, reviewable PRs while still delivering one
cohesive feature to `main`.

### Per-Task Branch Lifecycle

```
For each task in the plan:
  1. git checkout <integration-branch>              # Return to integration branch
  2. git pull origin <integration-branch>            # Get latest merged task PRs
  3. git checkout -b <integration>/TXXX-<slug>       # Create task branch
  4. [... TDD cycle: test → implement → review ...]  # Work on task branch
  5. git commit -m "checkpoint: [TXXX] <desc>"       # Checkpoint commit
  6. git push -u origin <integration>/TXXX-<slug>    # Push for PR
  7. gh pr create --base <integration> ...           # PR against integration branch
  8. gh pr merge --squash --delete-branch            # Merge task PR
  9. git checkout <integration> && git pull           # Pull merged changes
  10. → Next task                                     # Repeat
```

### Per-Task State in task-status.json

```json
{
  "tickets": {
    "branching": "per-task",
    "branch": "feat/user-authentication",
    "baseBranch": "main",
    "taskBranches": {
      "T001": {
        "branch": "feat/user-authentication/T001-setup-project",
        "pr": { "number": 101, "url": "https://github.com/org/repo/pull/101", "status": "merged" }
      },
      "T002": {
        "branch": "feat/user-authentication/T002-config-schemas",
        "pr": { "number": 102, "url": "https://github.com/org/repo/pull/102", "status": "merged" }
      },
      "T003": {
        "branch": "feat/user-authentication/T003-test-profiles",
        "pr": { "number": null, "url": null, "status": "pending" }
      }
    }
  }
}
```

### Final PR (Integration → Main)

After all task PRs are merged into the integration branch, one final PR goes from
`<integration-branch>` → `main`. This PR includes a summary of all task PRs in its body.

### When to Use Per-Task Branching

- MEDIUM+ features (4+ tasks) where the final PR would be too large to review
- Teams that prefer small, incremental PRs
- When task boundaries map cleanly to reviewable units of work

### When NOT to Use Per-Task Branching

- SMALL features (1-3 tasks) — overhead exceeds benefit
- Tightly coupled tasks where the intermediate states don't make sense in isolation
- When remote push access is restricted or CI is slow (each task PR triggers CI)

## Per-Ticket Branching (MULTI_TICKET Workflow)

When the MULTI_TICKET workflow uses per-ticket branching, each ticket gets its own
branch and PR. This requires careful sequencing to ensure each branch is based on
the latest merged state of main.

### Per-Ticket Branch Lifecycle

```
For each ticket in the queue:
  1. git checkout main && git pull origin main    # Start from latest main
  2. git checkout -b feat/<ticket-id>-<slug>      # Create ticket branch
  3. [... build cycle ...]                        # Implement on this branch
  4. git push -u origin feat/<ticket-id>-<slug>   # Push for PR
  5. gh pr create ...                             # Create PR
  6. [optional: /lemongrab:pr-review + /lemongrab:resolve-feedback]
                                                  # Manual post-workflow review
  7. gh pr merge --squash --delete-branch         # Merge (manual or auto)
  8. git checkout main && git pull origin main    # Pull merged changes
  9. → Next ticket                                # Repeat
```

### Per-Ticket State in task-status.json

Each ticket in a MULTI_TICKET workflow tracks its own branch and PR:

```json
{
  "multiTicket": {
    "config": { "branching": "per-ticket" },
    "ticketQueue": ["LIN-124", "LIN-125"],
    "prLinks": {
      "LIN-124": "https://github.com/org/repo/pull/42"
    }
  },
  "tickets": {
    "branch": "feat/LIN-125-auth-middleware",
    "baseBranch": "main",
    "pr": { "url": null, "number": null }
  }
}
```

Note: `tickets.branch` and `tickets.pr` are overwritten for each ticket in the queue.
Historical PR links are preserved in `multiTicket.prLinks`.

### Single Branch Mode (MULTI_TICKET alternative)

When MULTI_TICKET uses single-branch mode, behavior matches the standard workflow:
one feature branch, one PR at the end. All tickets are implemented as commits on
the same branch.

### Post-Merge Verification

After each PR merge in per-ticket mode, verify clean state before starting next ticket:

```bash
git checkout main && git pull origin main
git status --porcelain  # Must be empty
git log --oneline -1    # Should show the merge commit
```

If the working tree is not clean, ask the user to resolve before continuing.

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

## PR Review

PR review is a separate post-workflow command, not part of the TDD workflow.
Once `/lemongrab:tdd` creates a PR, the user runs:

```
/lemongrab:pr-review <PR-number>      # chunked review with deterministic chunking + Pass B
/lemongrab:resolve-feedback            # action posted findings
```

These commands own their own chunking, posting, and resolution logic. This skill
no longer documents review chunking, re-review scoping, or review state — see
`commands/pr-review.md` for the chunker contract and `agents/pr-cross-file-reviewer.md`
for the cross-file pass.

### PR State in task-status.json

```json
{
  "tickets": {
    "pr": {
      "url": "https://github.com/org/repo/pull/42",
      "number": 42
    }
  }
}
```

`/lemongrab:pr-review` does NOT update `task-status.json` — its durable record
of findings lives on the PR itself (posted via the GitHub reviews API).

## Checklist

### Before Creating Branch
- [ ] Main is up to date (`git pull origin main`)
- [ ] Branch name follows convention
- [ ] No uncommitted changes on current branch
- [ ] If per-task branching: integration branch pushed to remote

### Per-Task PR (per-task branching only)
- [ ] Task branch created from integration branch (not main)
- [ ] Task branch name follows `<integration>/TXXX-<slug>` pattern
- [ ] Task PR targets integration branch (not main)
- [ ] Task PR merged via squash before starting next task
- [ ] Integration branch pulled after merge
- [ ] taskBranches entry updated in task-status.json

### Before Creating PR
- [ ] All tests passing
- [ ] Branch pushed to remote
- [ ] PR title follows format
- [ ] PR body includes `Closes LIN-XXX` for each ticket
- [ ] Completion summary posted to tickets

### After PR Creation
- [ ] All tickets moved to "In Review"
- [ ] PR link posted as comment on each ticket
- [ ] PR URL stored in task-status.json

### Worktree Cleanup
- [ ] All worktree branches merged to feature branch
- [ ] Worktree directories removed
- [ ] Worktree branches deleted
- [ ] task-status.json worktrees section cleaned

### Per-Ticket Merge Gate (MULTI_TICKET only)
- [ ] PR merged (verified via `gh pr view`)
- [ ] Main branch pulled with latest changes
- [ ] Working tree clean before starting next ticket
- [ ] multiTicket.completedTickets updated
- [ ] multiTicket.prLinks updated with PR URL
- [ ] tickets.branch and tickets.pr reset for next ticket
