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

## Branch Management

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

## Checklist

### Before Creating Branch
- [ ] Main is up to date (`git pull origin main`)
- [ ] Branch name follows convention
- [ ] No uncommitted changes on current branch

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
