---
description: Run chunked PR review and post findings to the PR as a GitHub review (read-only; never modifies code)
argument-hint: [<PR-URL-or-number>] [--base <branch>]
allowed-tools: Read, Bash, Glob, Grep, Task, AskUserQuestion
---

You are the PR review orchestrator running OUTSIDE the normal workflow state machine.
This command runs a chunked PR review and posts findings to the PR as a GitHub review.

This command is READ-ONLY on code. It never edits files, commits, or pushes. The only
write it performs is posting a GitHub PR review via the reviews API. Code changes are
the responsibility of `/lemongrab:resolve-feedback`.

Use this when:
- You want a PR reviewed and findings posted so they can be actioned later via resolve-feedback
- You want to re-review a PR after fixes were applied (this command supersedes its own prior review first — see Step 7)

STEP 0: PARSE ARGUMENTS

Parse $ARGUMENTS:
- First positional arg: PR URL or number (optional)
  - URL like https://github.com/org/repo/pull/N → extract PR number
  - Plain number like "1" or "#1" → use directly
- `--base <branch>`: base branch for diff (default: auto-detect from PR)

If no PR arg provided, detect from the current branch; distinguish "no PR for branch"
(exit code non-zero) from "PR exists but is closed":

```bash
if ! PR_META=$(gh pr view --json number,title,headRefName,baseRefName,state,url 2>/dev/null); then
  # No PR for current branch — try fallback
  if [ -f docs/state/task-status.json ] && jq -e '.tickets.pr.number' docs/state/task-status.json >/dev/null 2>&1; then
    PR=$(jq -r '.tickets.pr.number' docs/state/task-status.json)
    PR_META=$(gh pr view "$PR" --json number,title,headRefName,baseRefName,state,url)
  else
    echo "ERROR: No PR detected. Pass a PR number or open a PR for the current branch." >&2
    exit 1
  fi
fi
PR=$(echo "$PR_META" | jq -r .number)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
BASE=$(echo "$PR_META" | jq -r .baseRefName)
HEAD=$(echo "$PR_META" | jq -r .headRefName)
```

If the PR arg WAS provided, skip the fallback and just fetch metadata for that PR. Assign
`PR`, `REPO`, `BASE`, and `HEAD` shell variables — ALL subsequent `gh api`, `git`, and
similar calls use `$PR`, `$REPO`, `$BASE`, `$HEAD`, never literal `{N}`, `{OWNER_REPO}`,
`<number>`, `<base-branch>`, or `<head-branch>` placeholders.

If `--base <branch>` was passed on the command line, it overrides `$BASE` here.

STEP 1: GATHER PR CONTEXT

1. PR metadata was already fetched into `$PR_META` in Step 0; re-verify if needed:
   `gh pr view "$PR" --json number,title,headRefName,baseRefName,state,url`
2. If PR is closed/merged, warn user but continue (review is still useful as a record)
3. `$PR`, `$REPO`, `$BASE`, and `$HEAD` are already assigned from Step 0; also extract title/URL as needed.
4. Check out the head branch locally:
   - If already on `$HEAD`, skip
   - If branch doesn't exist locally: `git fetch origin "$HEAD" && git checkout "$HEAD"`

STEP 2: DETECT FEATURE CONTEXT (best-effort)

Try to find feature context for richer reviews:
1. If docs/state/task-status.json exists → read feature name
2. If docs/requirements/<feature>.md exists → use as requirements context
3. If docs/plans/<feature>.md exists → use as plan context
4. If docs/state/decisions.md exists → use as decisions context (cumulative, not per-feature)
5. If docs/designs/<feature>.md exists → use as designs context (optional, per-feature)
6. If none found: proceed without — the reviewer works with just the diff

Record whichever of these paths exist into shell variables (e.g., `REQ_DOC`, `PLAN_DOC`,
`DECISIONS_DOC`, `DESIGNS_DOC`); empty string if absent. These are passed into each
pr-reviewer agent's prompt in STEP 5.

The chunk agents will also re-read these docs directly (see pr-reviewer agent
PREREQUISITE) so the orchestrator only needs to surface the paths.

STEP 3: GET THE DIFF

Use `origin/$HEAD` (the remote tip of the PR branch), NOT local `HEAD`, so that the diff
matches what the PR actually shows on GitHub and what Step 7's anchor validator checks
against (`pulls/$PR/files`). This prevents silent divergence where unpushed local commits
would produce findings on lines the PR doesn't contain, then get dropped as orphaned.

Ensure both refs are fresh first:
```bash
git fetch origin "$BASE" "$HEAD"
```

1. Full diff: `git diff "origin/$BASE".."origin/$HEAD"`
2. Changed files: `git diff "origin/$BASE".."origin/$HEAD" --name-only`
3. Total lines: `git diff "origin/$BASE".."origin/$HEAD" --stat | tail -1`
4. If total diff is < 50 lines: tell user "Diff is trivially small (N lines). Reviewing as single chunk." and skip chunking.

If `origin/$HEAD` differs from local `HEAD`, warn the user that unpushed commits will not
be reviewed (they are not on the PR).

STEP 4: CHUNK THE DIFF

Group files into logical review chunks:
- Co-locate source + test files together (e.g., src/auth/login.ts + tests/auth/login.test.ts)
- Target ~200-300 diff lines per chunk
- If a single file exceeds 300 diff lines, it becomes its own chunk
- Save each chunk's diff: `git diff "origin/$BASE".."origin/$HEAD" -- "$file1" "$file2" > "/tmp/pr-review-chunk-$N.diff"` (substitute the chunk's file list and chunk index `$N` at shell-expansion time)

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
- Decisions doc path (`docs/state/decisions.md`) if it exists — pass empty string otherwise
- Designs doc path (`docs/designs/<feature>.md`) if it exists — pass empty string otherwise

Launch ALL chunk agents in a SINGLE message (parallel Agent calls) with `run_in_background: true`.
Each pr-reviewer agent self-persists its report to:
`docs/state/reviewer-reports/<feature>-pr-chunk-<N>.md` (or `pr-chunk-<N>.md` if no feature).

These reports are SCRATCH ARTIFACTS for orchestrator aggregation, not durable state. The
durable record of findings lives on the PR after Step 7.

Wait for all agents to complete (you will be notified automatically).

IMPORTANT: Do NOT use TaskOutput to read agent results. The agents write to disk.

STEP 6: AGGREGATE

1. Read all chunk reports matching `docs/state/reviewer-reports/pr-chunk-[0-9]*.md` and `docs/state/reviewer-reports/*-pr-chunk-[0-9]*.md` (tight globs — avoid matching unrelated files like `old-pr-chunk-notes.md`)
2. Collect findings across chunks
3. Count by severity: CRITICAL, WARNING, NIT. Findings annotated `[INTENTIONAL — per <doc>:<line>]` count at their original severity (they are NOT suppressed).
4. Collect any [CROSS-REF] notes

Present a brief summary to the user:
```
PR REVIEW complete — PR #N

| Severity | Count |
|----------|-------|
| CRITICAL | <c> |
| WARNING  | <w> |
| NIT      | <n> |
```

Do NOT ask the user whether to fix. This command does not fix. Proceed to posting.

STEP 7: POST REVIEW TO PR

Post findings as a single GitHub PR review (one review containing all inline comments
and a summary body). This lets resolve-feedback pick them up uniformly.

### Supersede prior lemongrab reviews (idempotency on re-run)

GitHub's `/reviews/{id}/dismissals` endpoint only accepts reviews in state `APPROVED`
or `CHANGES_REQUESTED`. Since this command posts with `event: "COMMENT"`, dismissal is
not available. Instead, to keep re-runs idempotent:

1. Find prior marker reviews authored by the current user.
2. Delete all inline comments belonging to those prior reviews (DELETE
   `/repos/{owner}/{repo}/pulls/comments/{id}`). This leaves the old review objects as
   empty shells in PR history but removes them from the current review surface.
3. Leave the prior review bodies in place (GitHub does not allow editing submitted
   review bodies). The new review becomes the latest by `created_at`, so
   resolve-feedback picks it up and ignores older ones.

```bash
ME=$(gh api user --jq .login)
PRIOR_REVIEW_IDS=$(gh api "repos/$REPO/pulls/$PR/reviews" --paginate \
  --jq ".[] | select(.user.login==\"$ME\") | select(.body | contains(\"lemongrab-pr-review\")) | .id")

for rid in $PRIOR_REVIEW_IDS; do
  CIDS=$(gh api "repos/$REPO/pulls/$PR/comments" --paginate \
    --jq ".[] | select(.pull_request_review_id==$rid) | .id")
  for cid in $CIDS; do
    # Capture stderr; only 404 (already deleted) is an acceptable silent skip.
    # Any other non-2xx surfaces as an error so we don't silently break idempotency.
    err_file=$(mktemp)
    if ! gh api "repos/$REPO/pulls/comments/$cid" -X DELETE 2>"$err_file"; then
      if grep -q "HTTP 404" "$err_file"; then
        : # already deleted — acceptable silent skip
      else
        echo "ERROR: failed to delete prior review comment $cid:" >&2
        cat "$err_file" >&2
        rm -f "$err_file"
        exit 1
      fi
    fi
    rm -f "$err_file"
  done
done
```

If a different gh account authored prior marker reviews, the loop is a no-op — their
comments are left untouched (we only delete our own).

### Build the review payload

- **Summary body**: severity table + any findings without clean line anchors. MUST contain
  the marker `<!-- lemongrab-pr-review -->` on its own line so resolve-feedback can detect
  origin. Include a `**[SEVERITY]**` prefix on each non-anchored finding.

  ~~~markdown
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

  ---
  *Posted by lemongrab pr-review*
  ~~~

- **Inline comments array**: one per finding with a clean `path:line`. Each body MUST
  start with a severity prefix so resolve-feedback's classifier can read it:

  ~~~
  **[CRITICAL]** <one-line title>

  <explanation>

  **Suggestion:** `<fenced code with a language tag>`
  ~~~

### Aggregate inline findings into a raw JSON array

Before anchor validation, aggregate all inline-eligible findings from the per-chunk
reports (read in STEP 6) into a single JSON array at
`/tmp/pr-$PR-inline-comments-raw.json`. Each element MUST have this shape:

```json
{
  "path": "<file path relative to repo root>",
  "line": <integer, 1-based line number on the RIGHT side of the diff>,
  "side": "RIGHT",
  "severity": "CRITICAL" | "WARNING" | "NIT",
  "body": "**[SEVERITY]** <one-line title>\n\n<explanation>\n\n**Suggestion:** ..."
}
```

Only findings with a concrete `path` AND numeric `line` go into this file. Non-anchored
findings (no line, or file-level) go directly into the summary body and are NOT included
here. The orchestrator builds this file by parsing the structured "Inline Findings"
sections of each chunk report under `docs/state/reviewer-reports/`.

If no inline-eligible findings exist, write an empty array: `echo '[]' > /tmp/pr-$PR-inline-comments-raw.json`.

### Pre-validate line anchors

Before posting, filter inline comments to only those whose `path:line` lies inside the
current PR diff. This prevents the whole `POST /reviews` from failing atomically on a
single stale anchor. Build the set of valid `(path, new_line)` pairs from
`pulls/$PR/files` patches:

```bash
gh api "repos/$REPO/pulls/$PR/files" --paginate > /tmp/pr-$PR-files.json

# Build valid (path, new_line) set by parsing each file's patch. For every hunk
# header `@@ -a,b +c,d @@`, walk the hunk body: `+` and ` ` (context) lines each
# advance new_line by 1 and are recorded; `-` lines do not advance new_line.
# Output: TSV of "<path>\t<new_line>" pairs.
jq -r '
  .[] | select(.patch != null) | . as $f |
  ($f.patch | split("\n")) as $lines |
  reduce range(0; $lines|length) as $i (
    {new:0; out:[]};
    ($lines[$i]) as $l |
    if ($l | startswith("@@")) then
      .new = ($l | capture("\\+(?<c>[0-9]+)") | .c | tonumber)
    elif ($l | startswith("+++") or startswith("---")) then .
    elif ($l | startswith("+")) then
      .out += [$f.filename + "\t" + (.new|tostring)] | .new += 1
    elif ($l | startswith("-")) then .
    elif ($l | startswith("\\")) then .
    else
      .out += [$f.filename + "\t" + (.new|tostring)] | .new += 1
    end
  ) | .out[]
' /tmp/pr-$PR-files.json | sort -u > /tmp/pr-$PR-valid-anchors.tsv

# Partition inline comments: valid anchors → keep; invalid → append to summary body.
# /tmp/pr-$PR-inline-comments-raw.json is the pre-validation array of {path,line,body,side,...}.
jq --slurpfile valid <(jq -R -s 'split("\n") | map(select(length>0))' /tmp/pr-$PR-valid-anchors.tsv) '
  . as $all |
  ($valid[0] | map(split("\t") | {path:.[0], line:(.[1]|tonumber)})) as $v |
  {
    anchored: [ $all[] | . as $c | select([$v[] | select(.path==$c.path and .line==$c.line)] | length > 0) ],
    orphaned: [ $all[] | . as $c | select([$v[] | select(.path==$c.path and .line==$c.line)] | length == 0) ]
  }
' /tmp/pr-$PR-inline-comments-raw.json > /tmp/pr-$PR-partitioned.json

jq '.anchored' /tmp/pr-$PR-partitioned.json > /tmp/pr-$PR-inline-comments.json

# Fold orphaned inline comments into the summary body as non-anchored findings.
jq -r '.orphaned[] | "- **\(.severity // "WARNING" | ascii_upcase | "[" + . + "]")** \(.path):\(.line) — \(.body)"' \
  /tmp/pr-$PR-partitioned.json >> /tmp/pr-$PR-summary-body.md
```

Any finding whose anchor is NOT valid becomes a non-anchored finding appended to the
summary body with `**[SEVERITY]** <file>:<line> — <body>` (matching the fallback
layout in the summary-body template above).

### Build JSON safely and post

NEVER embed finding bodies into a heredoc — bodies may contain `"` and triple-backticks
that would produce invalid JSON. Use `jq` to build the payload so every string is
properly escaped:

```bash
jq -n \
  --rawfile body /tmp/pr-$PR-summary-body.md \
  --slurpfile comments /tmp/pr-$PR-inline-comments.json \
  '{event: "COMMENT", body: $body, comments: $comments[0]}' \
  > /tmp/pr-$PR-payload.json

gh api "repos/$REPO/pulls/$PR/reviews" -X POST --input /tmp/pr-$PR-payload.json
```

Use `event: "COMMENT"` (not REQUEST_CHANGES or APPROVE) — this is an observation, not
a gate. If the PR is closed/merged, still post (for the record).

If the POST still returns a non-2xx (e.g., unforeseen validation error), fall back to
posting with zero inline comments. The retry MUST rebuild the payload with
`comments: []` (summary-body only) — do NOT re-POST the rejected payload. Fold ALL
previously-inline findings into the summary body first, then rebuild:

```bash
# Append all previously-inline findings to the summary body as non-anchored entries.
jq -r '.[] | "- **[\(.severity // "WARNING" | ascii_upcase)]** \(.path):\(.line) — \(.body)"' \
  /tmp/pr-$PR-inline-comments.json >> /tmp/pr-$PR-summary-body.md

# Rebuild payload with an empty comments array.
jq -n \
  --rawfile body /tmp/pr-$PR-summary-body.md \
  '{event: "COMMENT", body: $body, comments: []}' \
  > /tmp/pr-$PR-payload.json

gh api "repos/$REPO/pulls/$PR/reviews" -X POST --input /tmp/pr-$PR-payload.json
```

Do NOT fail the whole command if this fallback succeeds. If the fallback ALSO fails,
surface the error and exit non-zero.

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
- Re-running the command supersedes prior lemongrab-authored reviews by deleting their
  inline comments (see Step 7). Review body objects stay in PR history; the latest
  marker review (by `created_at`) is what resolve-feedback picks up.
- If the PR is closed/merged, review is still posted (as a record).
- The review body MUST contain the `<!-- lemongrab-pr-review -->` marker.
- Inline comment bodies MUST begin with `**[CRITICAL]**`, `**[WARNING]**`, or `**[NIT]**`.
