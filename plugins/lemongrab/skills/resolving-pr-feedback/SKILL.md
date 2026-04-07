---
name: resolving-pr-feedback
description: Resolve PR review feedback from human reviewers. Covers comment type interpretation (inline, general, suggestion blocks), GitHub API patterns for fetching and posting comments, reply etiquette and tone, and escalation rules for when to fix vs push back vs defer.
version: 1.0.0
---

# Resolving PR Feedback

This skill provides reference material for resolving GitHub PR review feedback. It covers
how to interpret different comment types, interact with the GitHub API, craft appropriate
replies, and decide when to fix, push back, or defer.

## When to Use

- Resolving PR review comments from human reviewers
- Classifying comments as FIX, RESPOND, ACK, or DEFER
- Drafting replies to PR comment threads
- Deciding whether to fix code or push back on feedback
- Posting resolution updates to GitHub PRs

## Comment Types

GitHub PRs have several distinct comment types. Understanding the type determines how to
fetch and reply to each.

### Inline Review Comments

Filed on specific lines during a PR review. These are the most common type of actionable
feedback.

| Field | Meaning |
|-------|---------|
| `path` | File the comment is on |
| `line` | Line number in the diff (may be null for deleted lines) |
| `side` | `LEFT` (old code) or `RIGHT` (new code) |
| `in_reply_to_id` | If set, this is a reply in a thread |
| `body` | The comment text |
| `diff_hunk` | The surrounding diff context |

**API endpoint:** `GET /repos/{owner}/{repo}/pulls/{N}/comments`

### General Issue Comments

Top-level comments on the PR (not on specific lines). Often contain overall feedback,
questions, or approval notes.

| Field | Meaning |
|-------|---------|
| `body` | The comment text |
| `user.login` | Who wrote it |
| `created_at` | When it was posted |

**API endpoint:** `GET /repos/{owner}/{repo}/issues/{N}/comments`

### GitHub Suggestion Blocks

A special syntax within review comments where the reviewer proposes an exact code change:

````markdown
```suggestion
const result = computeValue(input);
```
````

These appear inside inline review comments. The `body` field contains the suggestion
markdown. When resolving:
- Extract the suggested code from between the suggestion fences
- Treat as a FIX comment — the reviewer is requesting a specific change
- The agent should evaluate the suggestion and apply it if correct, or adapt if needed
- Do NOT use GitHub's "apply suggestion" API — apply the change through normal file editing

### Review Verdicts

PR reviews also have a top-level verdict (`APPROVE`, `REQUEST_CHANGES`, `COMMENT`).
The resolve-feedback command should note the verdict but focus on individual comments.

## GitHub API Patterns

### Fetching Comments

```bash
# Fetch inline review comments
gh api repos/{owner}/{repo}/pulls/{N}/comments --paginate

# Fetch general issue comments
gh api repos/{owner}/{repo}/issues/{N}/comments --paginate

# Get PR details (for owner/repo extraction from URL)
gh pr view {N} --json number,title,headRefName,baseRefName,url,reviewDecision
```

### Filtering

```bash
# Filter out bot comments (in the command's classification step)
# Check: comment.user.type == "Bot" → skip
# Check: comment.user.login ends with "[bot]" → skip
```

To filter resolved threads, query the GraphQL API for review thread resolution status:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            comments(first: 1) {
              nodes { databaseId }
            }
          }
        }
      }
    }
  }
' -f owner='{owner}' -f repo='{repo}' -F pr={N}
```

Match `comments.nodes[0].databaseId` against review comment IDs. If `isResolved` is
true for a thread, filter out all comments belonging to that thread.

### Posting Replies

```bash
# Reply to an inline review comment (creates a reply in the thread)
gh api repos/{owner}/{repo}/pulls/{N}/comments \
  --method POST \
  --field body="<reply text>" \
  --field in_reply_to_id={comment_id}

# Post a general comment on the PR
gh pr comment {N} --body "<comment text>"
```

### Extracting Owner/Repo

```bash
# From the current git remote
REMOTE_URL=$(git remote get-url origin)
# Parse owner/repo from HTTPS or SSH URL
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/](.+/.+?)(.git)?$|\1|')
```

## Reply Etiquette

Replies should be concise, professional, and reference the fix when applicable.

### FIX Reply Template

```
Fixed in {commit_sha_short}.

{brief description of what was changed}
```

Example:
```
Fixed in a1b2c3d.

Updated the error handler to return a 404 instead of 500 when the resource is not found.
```

### RESPOND Reply Template

```
{contextual explanation addressing the reviewer's point}
```

Keep it factual. If pushing back, explain *why* with reference to requirements, constraints,
or trade-offs. Avoid defensive language.

Example:
```
The current approach uses a map lookup instead of a switch because the mapping is loaded
from configuration at startup. This allows adding new types without code changes.
```

### ACK Reply Template

```
Acknowledged — {brief note if any action was taken, or just "thanks"}.
```

Example:
```
Acknowledged — good catch, though this is already handled by the validation middleware at the route level.
```

### DEFER Reply Template

```
Noted — deferring to a follow-up. {brief reason why not in this PR}.
```

Example:
```
Noted — deferring to a follow-up. This refactoring would affect 3 other modules and is better handled in a dedicated PR.
```

### Tone Guidelines

- Be direct and factual, not defensive
- Reference specific code, commits, or requirements when explaining decisions
- Keep replies under 3 sentences for FIX/ACK/DEFER
- RESPOND replies can be longer when explaining architectural decisions
- Never be dismissive of feedback, even when pushing back
- If the reviewer is wrong, explain gently with evidence

## Escalation Rules

Use this decision tree to classify each comment:

### When to FIX

- Reviewer points out a bug (incorrect logic, missing null check, wrong return type)
- Reviewer suggests a concrete improvement that aligns with requirements
- Reviewer flags a missing edge case that's in scope
- Reviewer identifies dead code, unused imports, or naming issues
- GitHub suggestion block with a correct/better implementation

### When to RESPOND

- Reviewer questions an architectural decision that was deliberate
- Reviewer suggests a change that conflicts with requirements
- Reviewer asks "why" about a design choice — explain, don't change
- Reviewer misunderstands the intent of the code
- Feedback is about style/preference with no functional impact

### When to ACK

- Reviewer gives approval or praise ("LGTM", "nice", "good approach")
- Reviewer notes something that's already handled elsewhere
- Comment is informational with no action needed
- Reviewer's concern was addressed in a different commit

### When to DEFER

- Reviewer suggests a valid improvement that's out of scope for this PR
- Feedback would require changes to files/modules not in this PR
- The suggestion is good but would significantly expand the PR's scope
- Performance optimization that's valid but not blocking

### Escalation to User

Escalate to the user (do not auto-resolve) when:
- Two or more reviewers disagree about the same code
- The feedback implies a fundamental design change (not just a fix)
- The comment references requirements or decisions you don't have context for
- The fix would require changes to files the agent doesn't have access to
- After 2 failed fix attempts on the same comment
