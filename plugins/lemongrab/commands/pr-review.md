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
4. If the diff is small, you may surface "Diff is trivially small (N lines)." for
   user awareness. Do NOT skip chunking — Step 4's algorithm runs unconditionally
   and naturally produces a single chunk for small diffs.

If `origin/$HEAD` differs from local `HEAD`, warn the user that unpushed commits will not
be reviewed (they are not on the PR).

STEP 4: CHUNK THE DIFF (deterministic algorithm)

CONTRACT: Same diff input → identical chunks every run, regardless of session
context, machine, or prior workflow state. The orchestrator does NOT exercise
judgment about file grouping. If a different grouping is desired, change the
algorithm here — never deviate per-run.

NO PRE-FILTERING: The chunker's input is the FULL `git diff --name-only`
output between `origin/$BASE` and `origin/$HEAD`. Do NOT exclude files
because the requirements / plan / scope documents narrow the "in-scope"
file set, even when those documents are explicit. If the chunker's output
file count differs from `git diff --name-only | wc -l`, the contract is
violated and the run aborts (see sanity check below). To mark a file's
changes as out-of-scope, let the chunk agent see them and produce
`[INTENTIONAL — per <doc>]`-annotated findings; the docs-validation
pipeline downstream will surface them appropriately.

### Algorithm

1. Sort changed files lexicographically using `LC_ALL=C` (locale-stable).
2. For each file, compute `pair_key = dirname + canonical_basename`, where
   `canonical_basename` strips the markers `.test.`, `.spec.`, `_test.`,
   `_spec.`, `Test.`, `Spec.` from the basename. Files sharing a `pair_key`
   form an atomic **unit** (e.g. `src/auth/login.ts` + `src/auth/login.test.ts`
   are one unit).
3. Process units in lex order of their `pair_key`. A unit joins the current
   chunk if the result stays under 250 lines (added + removed); otherwise
   start a new chunk.
4. A unit that itself exceeds 300 lines becomes its own chunk.
5. Units are atomic — never split across chunks.
6. Cross-directory test pairing (e.g. `tests/foo.test.ts` ↔ `src/foo.ts`) is
   NOT performed — dirnames must match. Accepted tradeoff for determinism;
   cross-file coverage is Pass B's job.

### Implementation

```bash
# Files with line counts (added + removed), lex-sorted.
LC_ALL=C git diff "origin/$BASE".."origin/$HEAD" --numstat \
  | LC_ALL=C awk '{ print $1+$2 "\t" $3 }' \
  | LC_ALL=C sort -t$'\t' -k2,2 \
  > "/tmp/pr-$PR-files.tsv"

# Reject paths containing spaces — the per-chunk `git diff -- $FILES` expansion
# below relies on word-splitting and would silently produce wrong output.
if LC_ALL=C awk -F'\t' '{ print $2 }' "/tmp/pr-$PR-files.tsv" | grep -q ' '; then
  echo "ERROR: changed-files list contains a path with a space; aborting." >&2
  echo "Offending paths:" >&2
  LC_ALL=C awk -F'\t' '$2 ~ / / { print "  " $2 }' "/tmp/pr-$PR-files.tsv" >&2
  exit 1
fi

# Compute pair_key for same-directory test/source colocation.
LC_ALL=C awk -F'\t' '
{
  lines = $1; path = $2;
  n = split(path, p, "/");
  base = p[n];
  dir = (n > 1) ? substr(path, 1, length(path) - length(base) - 1) : ".";
  canon = base;
  sub(/\.test\./,  ".", canon); sub(/\.spec\./,  ".", canon);
  sub(/_test\./,   ".", canon); sub(/_spec\./,   ".", canon);
  sub(/Test\./,    ".", canon); sub(/Spec\./,    ".", canon);
  print lines "\t" dir "/" canon "\t" path
}' "/tmp/pr-$PR-files.tsv" \
  | LC_ALL=C sort -t$'\t' -k2,2 -k3,3 \
  > "/tmp/pr-$PR-keyed.tsv"

# Collapse rows sharing a pair_key into atomic units.
LC_ALL=C awk -F'\t' '
  { if ($2 != prev) { if (prev != "") print sum "\t" paths; sum = 0; paths = ""; prev = $2 }
    sum += $1; paths = (paths == "" ? $3 : paths " " $3) }
  END { if (prev != "") print sum "\t" paths }
' "/tmp/pr-$PR-keyed.tsv" > "/tmp/pr-$PR-units.tsv"

# Greedy-pack units into chunks (budget 250, single-unit ceiling 300).
LC_ALL=C awk -F'\t' '
BEGIN { n = 1; cur = 0 }
{
  if ($1 > 300) {
    if (cur > 0) n++;
    print n "\t" $2;
    n++; cur = 0;
    next;
  }
  if (cur > 0 && cur + $1 > 250) { n++; cur = 0 }
  print n "\t" $2;
  cur += $1;
}' "/tmp/pr-$PR-units.tsv" > "/tmp/pr-$PR-chunks.tsv"

# Write per-chunk diffs and emit a launch manifest the orchestrator MUST drive off.
TOTAL_CHUNKS=$(LC_ALL=C awk -F'\t' '{ print $1 }' "/tmp/pr-$PR-chunks.tsv" | LC_ALL=C sort -un | tail -1)

# Emit per-chunk launch manifest. One row per chunk-agent invocation.
# Format: <chunk_n>\t<chunk_total>\t<diff_path>\t<posture_path>\t<file_list>
# (file_list LAST because it contains spaces and is variable-length)
: > "/tmp/pr-$PR-launch-manifest.tsv"
LC_ALL=C awk -F'\t' '
  { if ($1 != prev) { if (prev != "") print prev "\t" p; p = $2 } else p = p " " $2; prev = $1 }
  END { if (prev != "") print prev "\t" p }
' "/tmp/pr-$PR-chunks.tsv" | while IFS=$'\t' read -r N FILES; do
  # shellcheck disable=SC2086
  git diff "origin/$BASE".."origin/$HEAD" -- $FILES > "/tmp/pr-review-chunk-$N.diff"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$N" "$TOTAL_CHUNKS" \
    "/tmp/pr-review-chunk-$N.diff" \
    "/tmp/pr-review-chunk-$N.posture" \
    "$FILES" \
    >> "/tmp/pr-$PR-launch-manifest.tsv"
done

# Sanity check: manifest file count MUST match `git diff --name-only` count.
# A discrepancy means something filtered the file list against the contract
# (e.g. orchestrator pre-filtered by requirements scope) — abort hard.
expected_count=$(LC_ALL=C git diff "origin/$BASE".."origin/$HEAD" --name-only | wc -l | tr -d ' ')
actual_count=$(LC_ALL=C awk -F'\t' '{ print $5 }' "/tmp/pr-$PR-launch-manifest.tsv" \
  | tr ' ' '\n' | LC_ALL=C grep -v '^$' | wc -l | tr -d ' ')
if [ "$expected_count" != "$actual_count" ]; then
  echo "ERROR: chunker contract violated." >&2
  echo "  git diff --name-only reports $expected_count changed files;" >&2
  echo "  manifest contains $actual_count. The chunker's input must be the" >&2
  echo "  full --name-only output. Aborting." >&2
  exit 1
fi

# Compute per-chunk diff posture (added/removed counts + a deletion-attention
# nudge when the chunk is net-negative). Forces the chunk agent to confront
# deletion semantics that LLM perception sometimes glosses over on stale-base
# / revert-style diffs.
while IFS=$'\t' read -r N TOTAL DIFF POSTURE _FILES; do
  added=$(LC_ALL=C awk '/^\+/ && !/^\+\+\+/' "$DIFF" | wc -l | tr -d ' ')
  removed=$(LC_ALL=C awk '/^-/ && !/^---/' "$DIFF" | wc -l | tr -d ' ')
  {
    echo "DIFF POSTURE — Chunk $N"
    echo "+$added lines added, -$removed lines removed."
    if [ "$removed" -gt "$added" ]; then
      echo ""
      echo "This chunk has more lines REMOVED than added. Read every \`-\` line"
      echo "as something the PR removes from the codebase. For each removed"
      echo "block, ask: is the removal authorized by the requirements / plan /"
      echo "decisions docs? If not, flag it as a regression at the appropriate"
      echo "severity. A net-negative diff is the most common signal of a stale"
      echo "branch or accidental revert; do not gloss over it."
    fi
  } > "$POSTURE"
done < "/tmp/pr-$PR-launch-manifest.tsv"

# Surface the chunking decision (auditable, and the manifest the orchestrator MUST consume).
echo "Chunking: $TOTAL_CHUNKS chunks"
echo "Launch manifest at /tmp/pr-$PR-launch-manifest.tsv:"
cat "/tmp/pr-$PR-launch-manifest.tsv"
```

### Notes

- The Step 3 short-circuit ("<50 lines → single chunk") is now redundant —
  small diffs naturally produce 1 chunk via the greedy packer. The chunker
  runs unconditionally.
- Files with spaces in paths are not supported by the `git diff -- $FILES`
  expansion. If the changed-files list contains such a path, fail loudly
  rather than producing an undefined chunking.

STEP 5: PARALLEL CHUNK REVIEW

Before launching agents, clean up stale scratch reports:
```bash
rm -f docs/state/reviewer-reports/*-pr-chunk-*.md docs/state/reviewer-reports/pr-chunk-*.md 2>/dev/null || true
```

For each chunk, launch `lemongrab:pr-reviewer` in parallel via the Agent tool.

CONTRACT: The prompt sent to each chunk agent MUST be built by literal substitution
into the template below, with `$CHUNK_N`, `$CHUNK_TOTAL`, `$DIFF_PATH`, and
`$FILE_LIST` taken **verbatim from `/tmp/pr-$PR-launch-manifest.tsv`** — one
manifest row per launch. Do NOT paraphrase, summarize, recompute, or infer
these values from session context. The orchestrator MUST `cat` the manifest
file before launching and use the literal field values from each row.

Concretely, for each tab-separated row
`<chunk_n>\t<chunk_total>\t<diff_path>\t<posture_path>\t<file_list>`
in the manifest, perform the substitution:
- `$CHUNK_N` ← field 1
- `$CHUNK_TOTAL` ← field 2 (same on every row by construction)
- `$DIFF_PATH` ← field 3
- `$POSTURE_PATH` ← field 4
- `$POSTURE_BLOCK` ← LITERAL CONTENTS of the file at `$POSTURE_PATH` (use `cat`)
- `$FILE_LIST` ← field 5

If `$CHUNK_TOTAL` differs between rows, the manifest is corrupt — abort and
re-run Step 4 rather than guess.

### Chunk-agent prompt template (verbatim, substitute `$VARS` only)

```
$POSTURE_BLOCK

You are reviewing chunk $CHUNK_N of $CHUNK_TOTAL of PR #$PR.

Chunk diff: read from `$DIFF_PATH` (do not read any other chunk's diff file).
Files in this chunk: $FILE_LIST

Feature context (read these if non-empty; skip silently if empty):
- Feature name: $FEATURE
- Requirements: $REQ_DOC
- Plan: $PLAN_DOC
- Decisions log: $DECISIONS_DOC
- Designs: $DESIGNS_DOC

Follow your agent definition exactly. Apply the calibration rubric strictly —
when in doubt, downgrade severity. Cap NITs at 3 for this chunk.

Self-persist your report to:
  $REPORT_PATH

Return only when the report file exists on disk.
```

### Variables

| Var              | Source                                                              |
|------------------|---------------------------------------------------------------------|
| `$CHUNK_N`       | manifest row, field 1                                               |
| `$CHUNK_TOTAL`   | manifest row, field 2                                               |
| `$PR`            | from Step 0                                                         |
| `$DIFF_PATH`     | manifest row, field 3                                               |
| `$POSTURE_PATH`  | manifest row, field 4                                               |
| `$POSTURE_BLOCK` | contents of file at `$POSTURE_PATH` (literal `cat` output)          |
| `$FILE_LIST`     | manifest row, field 5                                               |
| `$FEATURE`       | from Step 2; empty string if none                                   |
| `$REQ_DOC`       | from Step 2; empty string if none                                   |
| `$PLAN_DOC`      | from Step 2; empty string if none                                   |
| `$DECISIONS_DOC` | from Step 2; empty string if none                                   |
| `$DESIGNS_DOC`   | from Step 2; empty string if none                                   |
| `$REPORT_PATH`   | `docs/state/reviewer-reports/$FEATURE-pr-chunk-$CHUNK_N.md` if `$FEATURE` non-empty, else `docs/state/reviewer-reports/pr-chunk-$CHUNK_N.md` |

### Cross-file pass (Pass B)

In addition to the per-chunk Pass A agents, launch ONE `lemongrab:pr-cross-file-reviewer`
agent that sees the entire PR diff. This pass catches seams that no single Pass A
chunk can see (caller/callee mismatches across files, partial refactors, interface/
implementation drift, cross-file invariant breakage).

Pass B reads the same per-PR diff Pass A reads, but as a single artifact,
plus its own whole-PR posture file:

```bash
git diff "origin/$BASE".."origin/$HEAD" > "/tmp/pr-$PR-full.diff"

# Whole-PR posture (parallel to per-chunk posture from Step 4).
added=$(LC_ALL=C awk '/^\+/ && !/^\+\+\+/' "/tmp/pr-$PR-full.diff" | wc -l | tr -d ' ')
removed=$(LC_ALL=C awk '/^-/ && !/^---/' "/tmp/pr-$PR-full.diff" | wc -l | tr -d ' ')
{
  echo "DIFF POSTURE — Whole PR"
  echo "+$added lines added, -$removed lines removed."
  if [ "$removed" -gt "$added" ]; then
    echo ""
    echo "This PR has more lines REMOVED than added overall. A net-negative diff"
    echo "typically signals one of:"
    echo "  (a) intentional cleanup/refactor — should be in plan/decisions docs"
    echo "  (b) revert of prior work — usually unintentional, e.g. stale base branch"
    echo "  (c) feature deprecation — should be explicit in PR description"
    echo "If you cannot find the diff justified by (a)/(b)/(c), treat removals as"
    echo "regressions and flag them at the appropriate severity."
  fi
} > "/tmp/pr-$PR-full.posture"
```

Pass B's prompt template (verbatim, substitute `$VARS` only):

```
$FULL_POSTURE_BLOCK

You are running the cross-file pass on PR #$PR. Pass A chunk reviewers are
running in parallel on the same diff; do not duplicate their per-file work.

Full PR diff: read from `$FULL_DIFF_PATH`.
Files in PR: $FULL_FILE_LIST

Feature context (read these if non-empty; skip silently if empty):
- Feature name: $FEATURE
- Requirements: $REQ_DOC
- Plan: $PLAN_DOC
- Decisions log: $DECISIONS_DOC
- Designs: $DESIGNS_DOC

Follow your agent definition exactly. Apply the calibration rubric strictly —
when in doubt, downgrade severity. Cap NITs at 3 total (whole PR, not per-chunk).

Self-persist your report to:
  $CROSSFILE_REPORT_PATH

Return only when the report file exists on disk.
```

Pass B variables:

| Var                     | Source                                                              |
|-------------------------|---------------------------------------------------------------------|
| `$FULL_DIFF_PATH`       | `/tmp/pr-$PR-full.diff` (written above)                             |
| `$FULL_POSTURE_BLOCK`   | LITERAL CONTENTS of `/tmp/pr-$PR-full.posture` (use `cat`)          |
| `$FULL_FILE_LIST`       | newline-joined `git diff "origin/$BASE".."origin/$HEAD" --name-only`|
| `$CROSSFILE_REPORT_PATH`| `docs/state/reviewer-reports/$FEATURE-pr-crossfile.md` if `$FEATURE` non-empty, else `docs/state/reviewer-reports/pr-crossfile.md` |

### Launch

Launch Pass A's chunk agents AND Pass B's single agent in a SINGLE message
(parallel Agent calls) with `run_in_background: true`. Total agent count =
`$TOTAL_CHUNKS + 1`.

Before launching, also clean any prior cross-file report:
```bash
rm -f docs/state/reviewer-reports/*-pr-crossfile.md docs/state/reviewer-reports/pr-crossfile.md 2>/dev/null || true
```

These reports are SCRATCH ARTIFACTS for orchestrator aggregation, not durable state. The
durable record of findings lives on the PR after Step 7.

Wait for all agents to complete (you will be notified automatically).

IMPORTANT: Do NOT use TaskOutput to read agent results. The agents write to disk.

STEP 6: AGGREGATE (Pass A + Pass B with dedupe)

1. Read all Pass A chunk reports matching `docs/state/reviewer-reports/pr-chunk-[0-9]*.md` and `docs/state/reviewer-reports/*-pr-chunk-[0-9]*.md` (tight globs — avoid matching unrelated files like `old-pr-chunk-notes.md`).
2. Read the Pass B cross-file report at `docs/state/reviewer-reports/pr-crossfile.md` or `docs/state/reviewer-reports/<feature>-pr-crossfile.md`.
3. Collect findings from both passes into a single list. Tag each finding with its source (`pass-a-chunk-<N>` or `pass-b-crossfile`) for diagnostic purposes; the source tag does NOT affect posting.
4. **Dedupe across passes.** Two findings are duplicates iff:
   - Same `(path, line)` for anchored findings, OR
   - Same `path` AND normalized title overlap >= 80% (case-insensitive, punctuation-stripped) for non-anchored findings.

   On collision: keep the higher-severity finding; if tied, keep Pass B's wording (it's seeing more context); discard the duplicate.
5. Count by severity: CRITICAL, WARNING, NIT. Findings annotated `[INTENTIONAL — per <doc>:<line>]` count at their original severity (they are NOT suppressed).
6. Collect any [CROSS-REF] notes from Pass A chunks. Pass B does not emit [CROSS-REF] — it already has whole-PR scope.

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

Pass B (cross-file) findings typically cite TWO or more locations (e.g.
`src/foo.ts:42 ↔ src/bar.ts:88`). For inline-comment posting, choose the
**first** cited `path:line` as the anchor, then prepend a "Cross-file:"
prefix and list the other location(s) inside the body. If no Pass B finding
has any `path:line` at all, it is non-anchored and goes to the summary body.

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
