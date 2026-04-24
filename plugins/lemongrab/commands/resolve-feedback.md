---
description: Action PR review feedback — validate against docs, triage with recommendations, fix approved items, reply and resolve threads
argument-hint: [--pr <number>] [--auto]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion
---

You are the PR feedback resolution orchestrator. You fetch all feedback on the PR for
the current branch, validate each finding against the project's design docs, present a
recommendation-first triage table, and action only what the user approves.

This command is the sole actioner of PR feedback in lemongrab. `pr-review` never fixes —
it posts findings to the PR and this command picks them up alongside human comments.

Feedback sources actioned:
- Inline review comments (human reviewers)
- General issue comments on the PR
- Findings posted by `/lemongrab:pr-review` (marked with `<!-- lemongrab-pr-review -->`)
- Your own comments (excluding previous replies from this command)

Operates on the PR for the CURRENT branch only. One PR per run.

STEP 0: PARSE ARGUMENTS AND DETECT PR

Parse $ARGUMENTS:
- `--pr <number>`: override the auto-detected PR (use only when working on a PR without
  checking out the branch; discouraged).
- `--auto`: skip the triage approval gate — trust recommended actions. `--auto` is
  IGNORED (gate is forced) when any finding is classified NEEDS_HUMAN after validation.

Resolve the PR and assign shell variables used by every subsequent `gh api` call:

```bash
# --pr override takes precedence
if [ -n "$PR_OVERRIDE" ]; then
  PR="$PR_OVERRIDE"
  PR_JSON=$(gh pr view "$PR" --json number,title,headRefName,baseRefName,state,url,reviewDecision)
else
  PR_JSON=$(gh pr view --json number,title,headRefName,baseRefName,state,url,reviewDecision 2>/dev/null) || {
    echo "ERROR: No open PR for current branch. Push and open a PR, or pass --pr <N>." >&2
    exit 1
  }
  PR=$(echo "$PR_JSON" | jq -r .number)
fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=$(echo "$REPO" | cut -d/ -f1)
REPO_NAME=$(echo "$REPO" | cut -d/ -f2)
ME=$(gh api user --jq .login)
STATE=$(echo "$PR_JSON" | jq -r .state)
HEAD_REF=$(echo "$PR_JSON" | jq -r .headRefName)
```

`$PR`, `$REPO`, `$OWNER`, `$REPO_NAME`, `$ME`, `$STATE`, `$HEAD_REF` are used throughout;
NEVER use literal `{N}` or `{OWNER_REPO}` placeholders.

If `$STATE` is CLOSED or MERGED: set `READ_ONLY=true`, warn the user. Replies and
thread resolution still work; code changes are skipped.

STEP 1: GATHER REPO CONTEXT

Check out the head branch (unless READ_ONLY and not already there). If branch missing
locally: `git fetch origin "$HEAD_REF" && git checkout "$HEAD_REF"`.

STEP 2: FETCH FEEDBACK

Clean scratch:
```bash
rm -f /tmp/pr-$PR-review-comments.json /tmp/pr-$PR-issue-comments.json \
      /tmp/pr-$PR-reviews.json /tmp/pr-$PR-threads.json
```

Fetch three sources:

```bash
# Inline review comments (anchored to lines; these carry pr-review findings too)
gh api "repos/$REPO/pulls/$PR/comments" --paginate --jq '.[]' | jq -s '.' > /tmp/pr-$PR-review-comments.json

# General issue comments
gh api "repos/$REPO/issues/$PR/comments" --paginate --jq '.[]' | jq -s '.' > /tmp/pr-$PR-issue-comments.json

# Review objects (needed for review bodies — pr-review puts non-anchored findings there)
gh api "repos/$REPO/pulls/$PR/reviews" --paginate --jq '.[]' | jq -s '.' > /tmp/pr-$PR-reviews.json
```

Validate each fetch succeeded (jq empty + shape check). On failure, exit with a clear error.

Detect pr-review-authored reviews by scanning review bodies for the marker
`<!-- lemongrab-pr-review -->`. Capture ONLY THE LATEST such review by `created_at`
per author — prior runs may have posted multiple markers (Step 7 of pr-review supersedes
by deleting inline comments, but old review bodies remain in history). Inline comments
with `pull_request_review_id` matching the latest marker review ID are "marker comments."
The non-anchored findings parsed from `review_body` come ONLY from this latest review.

Fetch thread resolution state + full comment lists via GraphQL so replies can be mapped
back to their thread (best-effort — degrade to heuristic on failure):

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 50) { nodes { id databaseId } }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO_NAME" -F number="$PR" > /tmp/pr-$PR-threads.json
```

Build a map `databaseId → {thread_id, isResolved}` from EVERY comment in each thread
(not just the first) — reviewer replies must resolve back to their thread too.

FILTERING RULES:

- **Bot comments** (author `type == "Bot"` or login ends with `[bot]`): keep but tag
  `source: "bot"` — they get stricter validation later.
- **Resolved threads**: skip (isResolved == true).
- **Own replies** (authored by `$ME` AND `in_reply_to_id` is set): skip — these are
  this command's prior replies.
- **Own top-level / inline comments**: KEEP. These may be your self-review notes OR
  pr-review findings (which are authored by $ME via the gh user). Tag
  `source: "marker"` if the comment is from a marker review, else `source: "self"`.
- **Human reviewer comments**: keep, tag `source: "human"`.

Unified comment shape:
```
{
  id, thread_id (nullable), type ("review"|"issue"|"review_body"),
  author, source ("human"|"bot"|"self"|"marker"),
  body, path (nullable), line (nullable),
  diff_hunk (nullable), created_at, in_reply_to_id (nullable), url
}
```

Also add "review_body" entries for the LATEST marker review's body — it holds
non-anchored findings that need triage. Parse out `**[SEVERITY]** file — body` lines
and synthesize one entry per parsed finding.

**Deduplicate** across sources: if a marker-review inline comment at `path:line` has
the same severity and first-sentence body as a review_body finding referencing the
same file, drop the review_body version (the inline comment wins — it has a resolvable
thread).

If the unified list is empty after filtering: tell the user "No actionable feedback on
PR #N." Exit.

If 50+ items: warn user, proceed.

STEP 3: CLASSIFY

For each item, set classification and severity.

Severity extraction:
- If body starts with `**[CRITICAL]**` → severity = CRITICAL
- If body starts with `**[WARNING]**` → severity = WARNING
- If body starts with `**[NIT]**` → severity = NIT
- Otherwise (human/bot comments without prefix): infer
  - "bug", "broken", "crash", "security" → CRITICAL
  - "should", "missing", "add", specific change requests → WARNING
  - "nit:", "consider", "maybe", "style", "typo" → NIT
  - Questions only, no change request → WARNING (for classification purposes)

Classification:
| Classification | Criteria |
|---|---|
| FIX | Change is requested (includes marker-review CRITICAL/WARNING, suggestion blocks, explicit "should change X", bugs) |
| RESPOND | Question or concern that warrants explanation ("why", "what about", scope pushback) |
| ACK | Praise, agreement, or standalone observation with no action |
| DEFER | Valid improvement but out of scope ("follow-up", unrelated files) |

Rules:
- Suggestion block (` ```suggestion `) → FIX
- Reply inheriting from classified parent → inherit unless content changes nature
- Stale line reference → attempt to map via diff_hunk; if can't, keep as FIX with flag
- Deleted file reference → ACK with note
- Ambiguous → prefer FIX (validation step will reclassify if appropriate)

STEP 3.5: VALIDATE AGAINST DOCS

Before triaging, check each FIX/RESPOND finding against project decision docs.

Load once (cache the contents in memory for the rest of this run):
- docs/requirements/*.md (especially the feature-specific one if task-status.json names it)
- docs/plans/*.md
- docs/state/decisions.md
- docs/decisions/*.md
- docs/adr/*.md
- docs/architecture/*.md

For each finding, set `validation` to one of:

| Verdict | Meaning |
|---|---|
| VALID | No doc conflict, or docs don't cover this. Proceed normally. |
| CONFLICTS_WITH_DECISION | Docs explicitly contradict the suggested change. Cite the doc. |
| MISSING_CONTEXT | Finding is plausible but reviewer lacks context docs provide. |
| NEEDS_HUMAN | Conflict is ambiguous or finding touches a migration/rewrite. User decides. |

Bot-source bias: bots lack our context. If ANY doc mentions the subsystem and the bot's
suggestion is substantive, lean toward MISSING_CONTEXT or NEEDS_HUMAN rather than VALID.

Self-source bias: trust your own comments — always VALID unless the content is clearly
self-correcting ("scratch that, ADR-007 says otherwise").

PR-description bias: relax CONFLICTS → NEEDS_HUMAN ONLY when the PR description
explicitly names the decision being reversed. Signals that count:
- A doc path in the PR title or body (e.g., "reverses docs/decisions/D-007")
- An ADR/decision ID (e.g., "supersedes ADR-007", "replaces D-FEEDBACK-003")
- Explicit "intentionally reverses <specific doc/decision>" language

Generic words like "refactor", "migration", "replace X with Y" WITHOUT a specific
citation do NOT trigger the bias — nearly every PR contains those words, and applying
the bias broadly would disable CONFLICTS detection entirely.

For CONFLICTS and MISSING_CONTEXT, capture the `citation` — the doc path and one-line
quote that proves the conflict/missing context. Replies will include this citation.

STEP 4: COMPUTE RECOMMENDATIONS AND TRIAGE

Default-action rules:

| Severity | Validation | Default Action | Reason |
|---|---|---|---|
| CRITICAL | VALID | FIX | Real bug |
| CRITICAL | CONFLICTS | RESPOND | Push back with doc citation |
| CRITICAL | MISSING_CONTEXT | RESPOND | Provide context from doc |
| CRITICAL | NEEDS_HUMAN | **gate-only** | User must decide |
| WARNING | VALID | FIX or SKIP — your judgment per-finding. Prefer SKIP if: speculative, premature, low-value, not load-bearing. Prefer FIX if: small + clear + improves correctness or readability. State one-line reason. |
| WARNING | CONFLICTS | RESPOND | Cite the doc |
| WARNING | MISSING_CONTEXT | RESPOND | Provide context |
| WARNING | NEEDS_HUMAN | **gate-only** | User decides |
| (any classified as RESPOND) | any | RESPOND | Question or concern; reply with explanation |
| NIT | any | SKIP (silently — no reply, no thread resolution) | Noise reduction |
| (ACK as classified) | any | ACK-reply | Unchanged |
| (DEFER as classified) | any | DEFER-reply | Unchanged |

"gate-only" means: do NOT default to any action. Always surface to the user for a
decision, even with `--auto`. If the user selects `approve` at the gate without
overriding gate-only rows explicitly, those rows default to **RESPOND** with body
"Needs your input — skipping automatic action. Please review this one manually." and
are NOT fixed. No code change ever happens on a gate-only row unless the user
explicitly overrides it to FIX.

Build the triage table:

```
PR FEEDBACK TRIAGE — PR #N — M items

| # | Sev | Source | Author | File:Line | Validation | Summary | Recommended | Reason |
|---|-----|--------|--------|-----------|------------|---------|-------------|--------|
| 1 | CRITICAL | human | @alice | src/auth.ts:42 | VALID | missing null check | FIX | Real bug, 1 line |
| 2 | WARNING | human | @bob | src/auth.ts:88 | VALID | extract helper | SKIP | Premature, 1 caller |
| 3 | WARNING | bot | coderabbit | src/db.ts:12 | CONFLICTS | use Redis | RESPOND | ADR-007 chose Postgres |
| 4 | NIT | human | @bob | src/foo.ts:5 | VALID | rename variable | SKIP | Taste, not load-bearing |
| 5 | NIT | bot | coderabbit | src/foo.ts:9 | VALID | add JSDoc | SKIP | Internal helper |
| 6 | CRITICAL | marker | pr-review | src/api.ts:33 | NEEDS_HUMAN | ownership model | — | User decides |

Totals (recommended): F fix, R respond, A ack, D defer, S skip, ? needs-human
```

Gate behavior:

- `--auto` AND zero NEEDS_HUMAN items → skip gate, proceed with recommendations
- Otherwise → AskUserQuestion with the table and options:

  ```
  Options:
    [approve]                         — proceed with Recommended column as-is
    [override <#> <ACTION>]           — e.g. "override 2 FIX, override 4 ACK"
    [fix all warnings]                — upgrade all WARNING-VALID SKIPs to FIX
    [skip all warnings]               — downgrade all WARNING-VALID FIXes to SKIP
    [discuss <#>]                     — expand a specific item before deciding
  ```

Apply overrides, then proceed.

STEP 5: ACTION THE APPROVED ITEMS

Iterate the approved action list. Actions map to concrete steps:

**FIX**: queue for Step 6 parallel dispatch (grouped by file).

**RESPOND**: draft a reply. For CONFLICTS/MISSING_CONTEXT, cite the doc. Post now (see reply helpers below). Keep under 3 sentences; factual, not defensive.

**ACK**: post a brief acknowledgment reply. After posting, resolve the thread.

**DEFER**: post a deferral reply citing scope. After posting, resolve the thread.

**SKIP**:
- For NITs: do NOTHING — no reply, no thread resolution. Silent pass.
- For WARNING-SKIP: post a one-line reply explaining why not taking it ("Considered;
  skipping — single caller, not worth the indirection."). Resolve the thread.
- For gate-only items the user chose to skip: reply "Skipping for now — will revisit."
  Do not resolve the thread.

REPLY HELPERS:

For inline review comments (type == "review"):
```bash
gh api "repos/$REPO/pulls/$PR/comments/$COMMENT_ID/replies" \
  --method POST --field body="<text>"
```

For issue comments:
```bash
gh pr comment "$PR" --body "<text> (Re: @<author>'s [comment](<url>))"
```

For review_body findings (non-anchored pr-review findings): post a top-level issue
comment referencing the original review:
```bash
gh pr comment "$PR" --body "<text> (Re: pr-review finding: <short description>)"
```

THREAD RESOLUTION (after reply, except for NIT-silent-skip):

Only inline review comments have threads. Issue comments and review_body findings do
NOT — skip the mutation for those. Look up the `thread_id` in the map built in Step 2;
if the comment ID is not in the map (issue/review_body source, or API error), skip:

```bash
# Only for type == "review"
THREAD_ID=$(jq -r --argjson cid "$COMMENT_ID" '.[$cid | tostring].thread_id // empty' /tmp/pr-$PR-thread-map.json)
if [ -n "$THREAD_ID" ]; then
  gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: { threadId: $threadId }) {
      thread { isResolved }
    }
  }' -f threadId="$THREAD_ID" 2>/dev/null || true
fi
```

If GraphQL resolution fails (permissions, API error): degrade to reply-only and note in
the summary that threads were not auto-resolved.

READ_ONLY MODE: skip FIX dispatch (Step 6) and commit/push (Step 7). Replies and thread
resolution still run.

STEP 6: PARALLEL FIX DISPATCH

Group FIX items by file path. Items with `path == null` (non-anchored marker-review
findings, general FIX comments) go into a "general" group handled as context-only in
the agent prompt.

For each file group, launch `lemongrab:feedback-resolver` in parallel:

```
Agent(subagent_type: "lemongrab:feedback-resolver", run_in_background: true)

Prompt: "Resolve PR feedback for file: <path>

PR: #<N> (<url>)
Repository: <owner/repo>
Branch: <head-branch>

Comments to resolve:
1. [ID: <id>] Line <line>: <body> (by @<author>, source: <source>)
   Diff context: <diff_hunk or 'none'>
2. ...

Design context already validated — these comments were approved as VALID by the
orchestrator. If during implementation you discover a conflict with docs the
orchestrator missed, stop and mark the item UNRESOLVED with reason 'doc-conflict:
<doc-path>'. Do NOT override a documented decision.

Feature context:
- Requirements: docs/requirements/<feature>.md (if exists)
- Plan: docs/plans/<feature>.md (if exists)
- Decisions: docs/state/decisions.md, docs/decisions/*, docs/adr/* (read if relevant)

Apply minimal fixes, verify tests pass, self-persist report to
docs/state/feedback-resolutions/<pr-number>-<file-slug>.md

IMPORTANT: Do NOT run git add, git commit, or git push. Only modify files and write
your report. The orchestrator handles all git operations."
```

Launch ALL file group agents in a single message (parallel Agent calls). Wait for all.

STEP 7: COMMIT AND PUSH

For each file group that produced fixes:
```bash
git add <file-paths>
git commit -m "fix(pr-feedback): resolve review comments on <filename>

Resolved: <comma-separated comment IDs>
PR: #<N>"
```

After all commits:
```bash
git push origin HEAD
```

STEP 8: POST FIX REPLIES AND RESOLVE THREADS

Read all reports from docs/state/feedback-resolutions/<pr-number>-*.md.

For each RESOLVED comment:
```bash
COMMIT_SHORT=$(git log -1 --format='%h' -- "<file-path>")
# inline:
gh api "repos/$REPO/pulls/$PR/comments/$COMMENT_ID/replies" \
  --method POST --field body="Fixed in ${COMMIT_SHORT}. <brief description>"
# then resolve the thread (GraphQL mutation above — inline only)
```

For issue/review_body fixes: use `gh pr comment` with citation link.

For UNRESOLVED items: note for summary, do not auto-reply (user handles manually).

STEP 9: SUMMARY AND CIRCUIT BREAKER

Present:
```
PR FEEDBACK RESOLUTION — PR #N — Round <R>

| Category | Count |
|---|---|
| FIXED | X |
| RESPONDED | Y |
| ACKED | Z |
| DEFERRED | W |
| SKIPPED (silent) | Sn (nits) + Sw (warnings) |
| UNRESOLVED | U |
| SKIPPED (read-only) | S |
| THREADS RESOLVED | T (of eligible) |

[List UNRESOLVED items with file:line, comment, agent-reason]
```

Circuit breaker: If UNRESOLVED > 0 and round < 2, offer:
- [retry] re-run Steps 5-8 on unresolved only (round 2)
- [skip] leave for manual
- [discuss] examine together

Max 2 rounds.

STEP 10: DECISION CAPTURE

If docs/state/decisions.md exists, append (use the D-FEEDBACK prefix — scoped to this
command, not in formatting-decisions skill):

```markdown
### Phase: FEEDBACK

<!-- DECISIONS
- decision:
    id: D-FEEDBACK-001
    phase: feedback
    who: claude
    what: "Resolved N, responded to M, skipped W on PR #<N>"
    why: "Automated PR feedback resolution with doc validation"
    context: "PR #<N> review feedback; validation caught K conflicts"
DECISIONS -->
```

STEP 11: CLEANUP

```bash
rm -f /tmp/pr-$PR-review-comments.json /tmp/pr-$PR-issue-comments.json \
      /tmp/pr-$PR-reviews.json /tmp/pr-$PR-threads.json /tmp/pr-$PR-thread-map.json
```

CRITICAL RULES:

- Operates on the PR for the current branch. `--pr` override exists but is discouraged.
- State of feedback lives on the PR (replies + thread resolution), NOT in
  docs/state/feedback-resolutions/ (that directory is per-run scratch).
- Validation happens BEFORE triage. Never fix a finding that CONFLICTS with docs without
  explicit user override.
- `--auto` is ignored when any finding is NEEDS_HUMAN — gate is forced.
- NITs are SKIPPED silently by default: no reply, no thread resolution.
- Never filter comments by author alone — pr-review marker comments are authored by the
  current user and must be picked up.
- Previous replies by the current user (identified by `in_reply_to_id`) ARE filtered to
  avoid self-loops.
- If PR is closed/merged, run READ_ONLY: replies and thread resolution still run, code
  changes do not.
- Bot-authored comments get stricter validation bias toward NEEDS_HUMAN / MISSING_CONTEXT
  when docs touch the subsystem.
