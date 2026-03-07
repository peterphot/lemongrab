---
name: using-git-worktrees
description: Isolate parallel work using git worktrees during lemongrab BUILD phase. Use when the orchestrator runs parallel tasks that need separate working directories to avoid file conflicts. Provides worktree creation, merge protocols, and cleanup procedures. Not for sequential tasks or single-task workflows.
version: 1.0.0
---

# Using Git Worktrees

This skill provides git worktree isolation for parallel task execution. Each parallel task gets its own working directory and branch, preventing file conflicts during concurrent work.

## When to Use

- Plan has [P] parallel tasks that will run concurrently
- Parallel tasks create or modify different files
- Need to isolate agent work to prevent interference

## When NOT to Use

- Sequential tasks (no benefit from isolation)
- Single-task workflows
- Tasks with fewer than 3 files each (overhead not worth it)
- Tasks that share mutable state (same database table, same config file)

## Worktree Lifecycle

### 1. Setup

Before creating worktrees, ensure `.worktrees/` is in `.gitignore`:

```bash
# Check and add if missing
grep -q '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
```

Create a worktree for each parallel task:

```bash
git worktree add .worktrees/<task-id>/ -b <feature-branch>-<task-id>
```

Example for tasks T004, T005, T006 on branch `feat/auth`:
```bash
git worktree add .worktrees/T004/ -b feat/auth-T004
git worktree add .worktrees/T005/ -b feat/auth-T005
git worktree add .worktrees/T006/ -b feat/auth-T006
```

### 2. Work Phase

Each agent works in its worktree directory:
- Test-writer creates tests in `.worktrees/<task-id>/`
- Implementer writes code in `.worktrees/<task-id>/`
- Reviewer validates in `.worktrees/<task-id>/`
- Simplifier cleans up in `.worktrees/<task-id>/`

All git operations (commits, checkpoints) happen on the worktree branch.

### 3. Merge Phase (Sequential)

After all parallel tasks complete, merge back to the feature branch ONE AT A TIME:

```bash
git checkout <feature-branch>

# Merge first task
git merge <feature-branch>-T004
# Run full test suite
npm test  # or equivalent

# Merge second task
git merge <feature-branch>-T005
# Run full test suite again
npm test

# Merge third task
git merge <feature-branch>-T006
# Run full test suite one final time
npm test
```

**If tests fail after a merge**: STOP. Do not merge more branches. Ask the user how to resolve.

### 4. Cleanup

After successful merges:

```bash
# Remove worktrees
git worktree remove .worktrees/T004/
git worktree remove .worktrees/T005/
git worktree remove .worktrees/T006/

# Delete worktree branches
git branch -d feat/auth-T004
git branch -d feat/auth-T005
git branch -d feat/auth-T006
```

## State Tracking

Store worktree state in `task-status.json` under `tickets.worktrees`:

```json
{
  "tickets": {
    "worktrees": {
      "T004": { "path": ".worktrees/T004", "branch": "feat/auth-T004" },
      "T005": { "path": ".worktrees/T005", "branch": "feat/auth-T005" }
    }
  }
}
```

On resume, read this state to find active worktrees and continue work.

## Merge Conflict Resolution

If `git merge` produces conflicts:
1. List conflicting files: `git diff --name-only --diff-filter=U`
2. Present conflicts to user with context
3. Options: resolve manually, accept one side, or re-do one task
4. After resolution, run tests before proceeding

## Safety Rules

1. Never force-delete a worktree with uncommitted work
2. Always run tests after each merge (not just after the last one)
3. Keep worktree branches until merge is verified
4. Track worktree state in task-status.json for resume safety
