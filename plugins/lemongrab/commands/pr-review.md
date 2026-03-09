---
description: Run chunked PR review as a standalone operation (outside the state machine)
argument-hint: <PR-URL-or-number> [--base <branch>] [--fix]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

You are the PR review orchestrator running OUTSIDE the normal workflow state machine.
This command runs the same chunked PR review as step 14 of the main workflow, but
without requiring an active workflow or modifying current-phase.json.

Use this when:
- The workflow completed without running PR review (bug recovery)
- You want to review a PR independently of any workflow
- You want to re-review a PR after manual changes

STEP 0: PARSE ARGUMENTS

Parse $ARGUMENTS:
- First positional arg: PR URL or number (required)
  - URL like https://github.com/org/repo/pull/N → extract PR number
  - Plain number like "1" or "#1" → use directly
- `--base <branch>`: base branch for diff (default: auto-detect from PR)
- `--fix`: after review, offer to fix findings (default: review-only)

If no arguments provided, check if docs/state/task-status.json exists and has
tickets.pr.url — use that PR automatically.

STEP 1: GATHER PR CONTEXT

1. Verify PR exists: `gh pr view <number> --json number,title,headRefName,baseRefName,state,url`
2. If PR is closed/merged, warn user but continue (review is still useful)
3. Extract:
   - PR number, title, URL
   - Head branch (feature branch)
   - Base branch (target branch, usually main)
4. Check out the head branch locally: `git checkout <head-branch>`
   - If already on it, skip
   - If branch doesn't exist locally: `git fetch origin <head-branch> && git checkout <head-branch>`

STEP 2: DETECT FEATURE CONTEXT (best-effort)

Try to find feature context for richer reviews:
1. If docs/state/task-status.json exists → read feature name
2. If docs/requirements/<feature>.md exists → use as requirements context
3. If docs/plans/<feature>.md exists → use as plan context
4. If none found: proceed without — the reviewer works with just the diff

STEP 3: GET THE DIFF

1. Get full diff: `git diff <base-branch>..HEAD`
2. Get changed files: `git diff <base-branch>..HEAD --name-only`
3. Count total diff lines: `git diff <base-branch>..HEAD --stat | tail -1`
4. If total diff is < 50 lines: tell user "Diff is trivially small (N lines). Reviewing as single chunk."
   - Skip chunking, review as one chunk

STEP 4: CHUNK THE DIFF

Group files into logical review chunks:
- Co-locate source + test files together (e.g., src/auth/login.ts + tests/auth/login.test.ts)
- Target ~200-300 diff lines per chunk
- If a single file exceeds 300 diff lines, it becomes its own chunk
- Save each chunk's diff: `git diff <base-branch>..HEAD -- <file1> <file2> > /tmp/pr-review-chunk-<N>.diff`

STEP 5: PARALLEL CHUNK REVIEW

For each chunk, launch lemongrab:pr-reviewer agent in parallel using the Agent tool with:
- Chunk number and total chunks
- Chunk file list
- Chunk diff (read from temp file and included in the prompt)
- Feature name, requirements doc path, plan doc path (if available from step 2)

Launch ALL chunk agents in a SINGLE message (parallel Agent calls). Use run_in_background: true.
Each pr-reviewer agent self-persists its report to: docs/state/reviewer-reports/<feature>-pr-chunk-<N>.md
(or docs/state/reviewer-reports/pr-chunk-<N>.md if no feature name).

Wait for all agents to complete (you will be notified automatically).

IMPORTANT: Do NOT use TaskOutput to read agent results. The agents write to disk.

STEP 6: AGGREGATE AND PRESENT

1. Read all chunk reports from docs/state/reviewer-reports/pr-chunk-*.md
2. Collect all findings across chunks
2. Count by severity: CRITICAL, WARNING, NIT
3. Collect any [CROSS-REF] notes

If zero CRITICAL + zero WARNING:
- Present: "PR review PASSED (N chunks reviewed, M nits noted)."
- List nits for informational purposes
- Done (unless --fix flag)

If any CRITICAL or WARNING:
- Present findings to user:
  ```
  PR REVIEW found issues across N chunks:
  CRITICAL: <count> | WARNING: <count> | NITs: <count>

  [list each CRITICAL and WARNING with file:line and one-line summary]
  ```

If --fix flag is set:
- Ask user: "Options: [fix all] [fix critical only] [skip — leave as-is] [discuss]"
- If fix: apply fixes, commit, push, re-review changed chunks
- Circuit breaker: max 2 fix rounds

If --fix flag is NOT set:
- Present findings as informational
- Ask: "Want to fix these? [yes] [no]"
- If yes: proceed with fix cycle as above
- If no: done

STEP 7: POST REVIEW TO PR

Post the aggregated review as a comment on the PR so there is a permanent record:

1. Build the comment body from the aggregated findings:
   ```
   ## PR Review Results — <PR title>

   **<N> chunks reviewed | <F> files | <L> lines changed**

   | Severity | Count |
   |----------|-------|
   | CRITICAL | <count> |
   | WARNING  | <count> |
   | NIT      | <count> |

   ### Findings

   | # | Severity | File:Line | Summary |
   |---|----------|-----------|---------|
   | 1 | WARNING  | src/foo.ts:42 | <one-line summary> |
   | ... | ... | ... | ... |

   <details>
   <summary>NIT findings (<count>)</summary>

   | # | File:Line | Summary |
   |---|-----------|---------|
   | ... | ... | ... |

   </details>

   ---
   *Reviewed by lemongrab pr-reviewer (round <R>)*
   ```

2. Post using: `gh pr comment <number> --body "<body>"`
   - Use a HEREDOC for the body to preserve formatting
   - If the PR is closed/merged, still post (for the record)

3. If a re-review round runs (fixes were applied), post an UPDATED comment for each round:
   - Include "Round <R>" in the heading
   - Show which previous findings were RESOLVED vs still open

STEP 8: CLEANUP

- Remove temp diff files from /tmp/pr-review-chunk-*.diff
- If docs/state exists and is part of an active workflow, save chunk reports to
  docs/state/reviewer-reports/<feature>-pr-chunk-<N>.md

CRITICAL RULES:
- This command does NOT modify current-phase.json — it operates outside the state machine
- This command does NOT move Linear tickets
- This command DOES commit and push if fixes are applied (on the current branch)
- If the PR is already merged, review is read-only (no fixes)
