---
description: Run chunked PR review and post findings to the PR as a GitHub review (read-only; never modifies code)
argument-hint: <PR-URL-or-number> [--base <branch>]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

You are the PR review orchestrator running OUTSIDE the normal workflow state machine.
This command runs a chunked PR review and posts findings to the PR as a GitHub review.

This command is READ-ONLY on code. It never edits files, commits, or pushes. The only
write it performs is posting a GitHub PR review via the reviews API. Code changes are
the responsibility of `/lemongrab:resolve-feedback`.

Use this when:
- You want a PR reviewed and findings posted so they can be actioned later via resolve-feedback
- You want to re-review a PR after fixes were applied (this command dismisses its own prior review first)

STEP 0: PARSE ARGUMENTS

Parse $ARGUMENTS:
- First positional arg: PR URL or number (optional)
  - URL like https://github.com/org/repo/pull/N → extract PR number
  - Plain number like "1" or "#1" → use directly
- `--base <branch>`: base branch for diff (default: auto-detect from PR)

If no PR arg provided, detect from the current branch:
```bash
gh pr view --json number,title,headRefName,baseRefName,state,url
```
If no open PR exists for the current branch AND docs/state/task-status.json has
tickets.pr.number, use that as a fallback. Otherwise error out:
"No PR detected. Pass a PR number or open a PR for the current branch."

STEP 1: GATHER PR CONTEXT

1. Verify PR exists: `gh pr view <number> --json number,title,headRefName,baseRefName,state,url`
2. If PR is closed/merged, warn user but continue (review is still useful as a record)
3. Extract: PR number, title, URL, head branch, base branch
4. Check out the head branch locally:
   - If already on it, skip
   - If branch doesn't exist locally: `git fetch origin <head-branch> && git checkout <head-branch>`

STEP 2: DETECT FEATURE CONTEXT (best-effort)

Try to find feature context for richer reviews:
1. If docs/state/task-status.json exists → read feature name
2. If docs/requirements/<feature>.md exists → use as requirements context
3. If docs/plans/<feature>.md exists → use as plan context
4. If none found: proceed without — the reviewer works with just the diff

The chunk agents will also read design-decision docs directly (see pr-reviewer agent
PREREQUISITE). No need for the orchestrator to preload those here.

STEP 3: GET THE DIFF

1. Full diff: `git diff <base-branch>..HEAD`
2. Changed files: `git diff <base-branch>..HEAD --name-only`
3. Total lines: `git diff <base-branch>..HEAD --stat | tail -1`
4. If total diff is < 50 lines: tell user "Diff is trivially small (N lines). Reviewing as single chunk." and skip chunking.

STEP 4: CHUNK THE DIFF

Group files into logical review chunks:
- Co-locate source + test files together (e.g., src/auth/login.ts + tests/auth/login.test.ts)
- Target ~200-300 diff lines per chunk
- If a single file exceeds 300 diff lines, it becomes its own chunk
- Save each chunk's diff: `git diff <base-branch>..HEAD -- <file1> <file2> > /tmp/pr-review-chunk-<N>.diff`

STEP 5: PARALLEL CHUNK REVIEW

Before launching agents, clean up stale scratch reports:
```bash
rm -f docs/state/reviewer-reports/*-pr-chunk-*.md docs/state/reviewer-reports/pr-chunk-*.md 2>/dev/null || true
```

For each chunk, launch `lemongrab:pr-reviewer` in parallel via the Agent tool with:
- Chunk number and total chunks
- Chunk file list
- Chunk diff (read from temp file and included in the prompt)
- Feature name, requirements doc path, plan doc path (if available from step 2)

Launch ALL chunk agents in a SINGLE message (parallel Agent calls) with `run_in_background: true`.
Each pr-reviewer agent self-persists its report to:
`docs/state/reviewer-reports/<feature>-pr-chunk-<N>.md` (or `pr-chunk-<N>.md` if no feature).

These reports are SCRATCH ARTIFACTS for orchestrator aggregation, not durable state. The
durable record of findings lives on the PR after Step 7.

Wait for all agents to complete (you will be notified automatically).

IMPORTANT: Do NOT use TaskOutput to read agent results. The agents write to disk.

STEP 6: AGGREGATE

1. Read all chunk reports from docs/state/reviewer-reports/*pr-chunk-*.md
2. Collect findings across chunks
3. Count by severity: CRITICAL, WARNING, NIT
4. Collect "Suppressed Findings" sections (findings the agent dropped because they
   contradicted a documented decision — these are reported but NOT posted to the PR)
5. Collect any [CROSS-REF] notes

Present a brief summary to the user:
```
PR REVIEW complete — PR #N

| Severity | Count |
|----------|-------|
| CRITICAL | <c> |
| WARNING  | <w> |
| NIT      | <n> |
| Suppressed (contradicts docs) | <s> |
```

Do NOT ask the user whether to fix. This command does not fix. Proceed to posting.

STEP 7: POST REVIEW TO PR

Post findings as a single GitHub PR review (one review containing all inline comments
and a summary body). This lets resolve-feedback pick them up uniformly.

First, dismiss any prior lemongrab reviews on this PR (idempotency on re-run):

```bash
ME=$(gh api user --jq .login)
PRIOR=$(gh api repos/{OWNER_REPO}/pulls/{N}/reviews --paginate \
  --jq ".[] | select(.user.login==\"$ME\") | select(.body | contains(\"lemongrab-pr-review\")) | select(.state != \"DISMISSED\") | .id")
for id in $PRIOR; do
  gh api repos/{OWNER_REPO}/pulls/{N}/reviews/$id/dismissals -X PUT \
    -f message="Superseded by re-review" 2>/dev/null || true
done
```

Note: dismissing only works on reviews the current gh user authored. If a different
account posted the prior review, the loop is a no-op — the new review will stack.

Build the review payload:

- **Summary body**: severity table + any findings without clean line anchors. MUST contain
  the marker `<!-- lemongrab-pr-review -->` on its own line so resolve-feedback can detect
  origin. Include a `**[SEVERITY]**` prefix on each non-anchored finding.

  ```markdown
  <!-- lemongrab-pr-review -->
  ## PR Review — <title>

  **<N> chunks | <F> files | <L> lines changed**

  | Severity | Count |
  |----------|-------|
  | CRITICAL | <c> |
  | WARNING  | <w> |
  | NIT      | <n> |

  ### Findings without a specific line anchor

  - **[WARNING]** <file> — <finding body>
  - **[NIT]** <file> — <finding body>

  <details>
  <summary>Suppressed findings (contradict documented decisions)</summary>

  - <file:line> — <finding> (suppressed: conflicts with `<doc-path>`)

  </details>

  ---
  *Posted by lemongrab pr-review*
  ```

- **Inline comments array**: one per finding with a clean `path:line`. Each body MUST
  start with a severity prefix so resolve-feedback's classifier can read it:

  ```
  **[CRITICAL]** <one-line title>

  <explanation>

  **Suggestion:**
  ```<lang>
  <code>
  ```
  ```

Post the review:

```bash
gh api repos/{OWNER_REPO}/pulls/{N}/reviews -X POST \
  --input - <<'JSON'
{
  "event": "COMMENT",
  "body": "<summary body with marker>",
  "comments": [
    {"path": "src/foo.ts", "line": 42, "body": "**[CRITICAL]** ..."},
    ...
  ]
}
JSON
```

Use `event: "COMMENT"` (not REQUEST_CHANGES or APPROVE) — this is an observation, not a
gate. If the PR is closed/merged, still post (for the record).

If the review API returns an error for any inline comment (e.g., stale line reference),
move that finding into the summary body and retry without it. Do NOT fail the whole post.

STEP 8: CLEANUP

- `rm /tmp/pr-review-chunk-*.diff 2>/dev/null || true`
- Leave chunk reports under docs/state/reviewer-reports/ as scratch for inspection.
  They will be overwritten on the next run.

Tell the user what was posted and the PR URL. Suggest running
`/lemongrab:resolve-feedback` to action the findings.

CRITICAL RULES:

- This command NEVER modifies code. No Edit, no Write to tracked source, no git commits.
- The only external write is `gh api ... /reviews` posting a GitHub PR review.
- This command does NOT modify current-phase.json — it operates outside the state machine.
- This command does NOT move Linear tickets.
- Re-running the command dismisses prior lemongrab-authored reviews on the PR and posts a
  fresh one. Reviews authored by other accounts are left alone and will stack.
- If the PR is closed/merged, review is still posted (as a record).
- The review body MUST contain the `<!-- lemongrab-pr-review -->` marker.
- Inline comment bodies MUST begin with `**[CRITICAL]**`, `**[WARNING]**`, or `**[NIT]**`.
