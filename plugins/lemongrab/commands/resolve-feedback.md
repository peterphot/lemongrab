---
description: Resolve PR review feedback from human reviewers — fetch comments, triage, fix, and reply
argument-hint: <PR-URL-or-number> [--auto]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

You are the PR feedback resolution orchestrator running OUTSIDE the normal workflow
state machine. This command fetches GitHub PR review comments, classifies them, presents
a triage table, dispatches parallel agents to fix code issues, and posts replies to
comment threads — all autonomously.

Use this when:
- A PR has received review comments that need to be addressed
- You want to resolve feedback without manually reading and fixing each comment
- You want to re-run after adding your own comments to the PR

STEP 0: PARSE ARGUMENTS

Parse $ARGUMENTS:
- First positional arg: PR URL or number (optional)
  - URL like https://github.com/org/repo/pull/N → extract PR number
  - Plain number like "1" or "#1" → use directly
- `--auto`: skip triage approval gate (default: require approval)

If no PR argument provided, check if docs/state/task-status.json exists and has
tickets.pr.url or tickets.pr.number — use that PR automatically.

If still no PR number: ask user via AskUserQuestion: "Which PR do you want to resolve
feedback for? Provide a PR number or URL."

STEP 1: GATHER PR CONTEXT

1. Get repo context:
   ```bash
   REMOTE_URL=$(git remote get-url origin)
   OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/](.+/.+?)(.git)?$|\1|')
   ```

2. Verify PR exists:
   ```bash
   gh pr view <number> --json number,title,headRefName,baseRefName,state,url,reviewDecision
   ```

3. If PR is closed/merged:
   - Warn user: "PR #N is <closed/merged>. Running in read-only mode (no fixes will be applied)."
   - Set READ_ONLY = true
   - Continue (review and reply are still useful)

4. Extract: PR number, title, URL, head branch, base branch, state

5. Check out the head branch locally (unless READ_ONLY):
   ```bash
   git checkout <head-branch>
   ```
   If already on it, skip. If branch doesn't exist locally:
   ```bash
   git fetch origin <head-branch> && git checkout <head-branch>
   ```

STEP 2: FETCH COMMENTS

Fetch both types of comments:

```bash
# Inline review comments (on specific lines)
gh api repos/{OWNER_REPO}/pulls/{N}/comments --paginate > /tmp/pr-${N}-review-comments.json

# General issue comments (top-level)
gh api repos/{OWNER_REPO}/issues/{N}/comments --paginate > /tmp/pr-${N}-issue-comments.json
```

Filter out:
- **Bot comments**: where `user.type == "Bot"` or `user.login` ends with `[bot]`
- **Resolved threads**: review comments where the thread has been marked resolved
  (check via `gh api graphql` if needed, or heuristic: if a later comment in the
  thread says "resolved" or the thread has no pending status)
- **Own comments**: comments posted by the current `gh` authenticated user (these are
  our previous replies, not new feedback)

After filtering, merge both lists into a unified comment list with fields:
- `id`: comment ID
- `type`: "review" or "issue"
- `author`: user.login
- `body`: comment text
- `path`: file path (null for issue comments)
- `line`: line number (null for issue comments or general comments)
- `diff_hunk`: surrounding context (null for issue comments)
- `created_at`: timestamp
- `in_reply_to_id`: parent comment ID (for threaded replies)
- `url`: comment URL

If the unified list is empty after filtering:
- Tell user: "No actionable comments found on PR #N. All comments are either from bots,
  already resolved, or posted by you."
- Exit.

If there are 50+ comments:
- Warn user: "Large PR with N comments. This may take a while and produce many changes."

STEP 3: CLASSIFY COMMENTS

For each comment in the unified list, classify as one of:

| Classification | Criteria |
|---------------|----------|
| **FIX** | Comment requests a code change: bug report, refactor suggestion, missing handling, GitHub suggestion block (` ```suggestion `), "please change", "this should be", "missing", "wrong", "bug" |
| **RESPOND** | Comment asks a question or raises a concern that warrants explanation: "why", "what about", architectural disagreement, scope question, "I'm not sure about", "have you considered" |
| **ACK** | Comment is praise, agreement, or informational: "LGTM", "nice", "good", "makes sense", purely observational nit with no specific change requested, already addressed elsewhere |
| **DEFER** | Comment suggests a valid improvement that's out of scope: "in a follow-up", "separate PR", references files/modules not in this PR, would significantly expand scope |

Classification rules:
- If a comment contains a ` ```suggestion ``` ` block → always FIX
- If a comment is a reply in a thread where the parent is already classified → inherit
  parent classification unless the reply changes the nature (e.g., "actually never mind" → ACK)
- If a comment references a file that was deleted in this PR → ACK with note
- If a comment references a line that no longer exists (stale) → attempt to map to new
  line via diff context. If cannot map, classify as FIX but flag as "stale_reference"
- If a comment starts with "nit:" but includes a specific code change suggestion → classify as FIX
- If ambiguous, prefer FIX over RESPOND (err on the side of action)

STEP 4: TRIAGE PRESENTATION

Present the classification table to the user:

Use AskUserQuestion:
"CHECKPOINT: PR FEEDBACK TRIAGE — PR #N has M actionable comments.

| # | Type | Author | File:Line | Classification | Summary |
|---|------|--------|-----------|---------------|---------|
| 1 | review | @user | src/foo.ts:42 | FIX | Missing null check |
| 2 | issue | @user | (general) | RESPOND | Why not use X? |
| ... |

Totals: X FIX, Y RESPOND, Z ACK, W DEFER

Options: [approve] [override: specify changes, e.g. '#2 should be FIX']"

If `--auto` flag was set: skip this gate, proceed directly.

If user provides overrides, apply them to the classification list.

STEP 5: RESOLVE ACK AND DEFER COMMENTS

Before dispatching agents, handle the simple categories:

**ACK comments:**
For each ACK comment, post a brief reply:
```bash
gh api repos/{OWNER_REPO}/pulls/{N}/comments \
  --method POST \
  --field body="Acknowledged — thanks." \
  --field in_reply_to_id={comment_id}
```
For issue-type ACK comments:
```bash
gh pr comment {N} --body "Acknowledged — thanks. (Re: @{author}'s comment)"
```

**DEFER comments:**
For each review-type DEFER comment, post a deferral reply:
```bash
gh api repos/{OWNER_REPO}/pulls/{N}/comments \
  --method POST \
  --field body="Noted — deferring to a follow-up PR. This change would expand the scope of this PR." \
  --field in_reply_to_id={comment_id}
```
For issue-type DEFER comments:
```bash
gh pr comment {N} --body "Noted — deferring to a follow-up PR. This change would expand the scope of this PR. (Re: @{author}'s comment)"
```

STEP 6: DRAFT AND POST RESPOND REPLIES

For each RESPOND comment:
1. Read the source file and surrounding context referenced by the comment
2. Read requirements docs if available (docs/requirements/*.md)
3. Draft a contextual reply explaining the decision or answering the question
4. Post the reply immediately (no user approval):
   ```bash
   gh api repos/{OWNER_REPO}/pulls/{N}/comments \
     --method POST \
     --field body="<drafted reply>" \
     --field in_reply_to_id={comment_id}
   ```

Keep RESPOND replies:
- Factual and concise (under 3 sentences unless explaining architecture)
- Reference specific code, requirements, or constraints
- Never defensive — explain, don't argue

STEP 7: PARALLEL FIX DISPATCH

If READ_ONLY mode: skip this step (report FIX items but do not apply changes).

Group FIX comments by file:
- All comments on the same `path` go to one group
- Comments with no `path` (issue-type FIX comments) → create a separate group called
  "general" and include them in the agent prompt as context-only (the agent will need
  to identify which files to modify)

For each file group, launch a `lemongrab:feedback-resolver` agent in parallel:

```
Agent(subagent_type: "lemongrab:feedback-resolver", run_in_background: true)

Prompt: "Resolve PR feedback for file: <path>

PR: #<number> (<url>)
Repository: <owner/repo>
Branch: <head-branch>

Comments to resolve:
1. [ID: <id>] Line <line>: <body> (by @<author>)
2. [ID: <id>] Line <line>: <body> (by @<author>)
...

Feature context:
- Requirements: docs/requirements/<feature>.md (if exists)
- Plan: docs/plans/<feature>.md (if exists)

Apply minimal fixes, verify tests pass, self-persist report to
docs/state/feedback-resolutions/<pr-number>-<file-slug>.md

IMPORTANT: Do NOT run git add, git commit, or git push. Only modify files and write
your report. The orchestrator handles all git operations."
```

Launch ALL file group agents in a SINGLE message (parallel Agent calls).
Wait for all agents to complete (you will be notified automatically).

IMPORTANT: Do NOT use TaskOutput to read agent results. The agents write to disk.

STEP 8: COMMIT AND PUSH

For each file group that had resolved fixes:
1. Stage the modified files:
   ```bash
   git add <file-path> [<test-file-path>]
   ```
2. Create a commit with conventional format:
   ```bash
   git commit -m "fix(pr-feedback): resolve review comments on <filename>

   Resolved comments: <comma-separated comment IDs>
   PR: #<number>"
   ```
3. After all commits, push:
   ```bash
   git push origin HEAD
   ```

STEP 9: COLLECT RESULTS AND POST FIX REPLIES

1. Read all resolution reports from docs/state/feedback-resolutions/<pr-number>-*.md
2. For each resolved comment:
   - Get the commit SHA from git log (the latest commit touching the file, after STEP 8)
   - Post a reply to the comment thread:
     ```bash
     COMMIT_SHORT=$(git log -1 --format='%h' -- <file-path>)
     gh api repos/{OWNER_REPO}/pulls/{N}/comments \
       --method POST \
       --field body="Fixed in ${COMMIT_SHORT}. <brief description of change>" \
       --field in_reply_to_id={comment_id}
     ```
3. For each unresolved comment:
   - Note it for the summary (do not post a reply yet — user may want to handle manually)

STEP 10: CIRCUIT BREAKER AND SUMMARY

Count results across all file groups:
- RESOLVED: comments where the agent successfully applied a fix
- UNRESOLVED: comments the agent could not fix
- RESPONDED: comments where we posted a RESPOND reply
- ACKED: comments where we posted an ACK reply
- DEFERRED: comments where we posted a DEFER reply

Present summary to user:
```
PR FEEDBACK RESOLUTION COMPLETE — PR #N

| Category | Count |
|----------|-------|
| RESOLVED (fixed) | X |
| RESPONDED (replied) | Y |
| ACKNOWLEDGED | Z |
| DEFERRED | W |
| UNRESOLVED | U |

[If UNRESOLVED > 0:]
Unresolved items need manual attention:
| # | File:Line | Comment | Reason |
|---|-----------|---------|--------|
| 1 | src/foo.ts:42 | <summary> | <why agent couldn't fix> |
```

**Circuit breaker:** If UNRESOLVED > 0 and this is round 1:
- Ask user: "N comments could not be resolved automatically. Options:
  [retry] — re-run feedback resolution on unresolved items only
  [skip] — leave unresolved items for manual handling
  [discuss] — let's look at the unresolved items together"
- If retry: re-run STEP 7-9 with only unresolved comments (round 2, where STEP 7 = dispatch, 8 = commit, 9 = post replies)
- Maximum 2 fix rounds. After round 2, present remaining unresolved items and stop.

STEP 11: DECISION CAPTURE

If docs/state/decisions.md exists, append feedback resolution decisions.

Note: D-FEEDBACK is a new decision prefix specific to this command. It is not yet
registered in the formatting-decisions skill. If this prefix is adopted project-wide,
update the skill's phase table in a follow-up.

```markdown
### Phase: FEEDBACK

<!-- DECISIONS
- decision:
    id: D-FEEDBACK-001
    phase: feedback
    who: claude
    what: "Resolved N comments, responded to M, deferred W on PR #<number>"
    why: "Automated PR feedback resolution"
    context: "PR #<number> review feedback from <authors>"
DECISIONS -->
```

CRITICAL RULES:

- This command does NOT modify current-phase.json — it operates outside the state machine
- This command does NOT move Linear tickets
- This command DOES commit and push if fixes are applied (on the current branch)
- If the PR is closed/merged, run in READ_ONLY mode (replies only, no code changes)
- All replies are posted autonomously — no user approval gate for individual replies
- The triage table IS a user gate (unless --auto) — user must approve classifications
- Bot comments are ALWAYS filtered out (never process automated CI feedback)
- If a comment is on a deleted file, classify as ACK with note "file was deleted in this PR"
- If a comment references a stale line (line no longer exists), attempt to locate the
  moved code using diff context. If cannot locate, mark as FIX with "stale_reference" flag
  and let the agent attempt resolution with the diff_hunk as context.
- For very large PRs (50+ comments), warn the user but proceed — do not refuse
