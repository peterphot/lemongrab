---
name: documenting-decisions
description: Document software decisions as formal ADRs or decision logs within a lemongrab TDD workflow. Use when writing architecture decision records after implementation, creating handoff documentation between TDD phases, or capturing trade-offs in plan/review documents. Not for routine code comments or inline explanations. Provides ADR templates, comment style guides, and documentation completeness checks.
version: 1.0.0
---

# Documenting Decisions

This skill helps create documentation that captures both the WHAT (what was built) and the WHY (reasoning behind choices). Good documentation enables future developers to understand, maintain, and extend the code.

## When to Use

- Writing decision records after implementation
- Adding inline code comments
- Updating project documentation
- Explaining technical trade-offs
- Creating handoff documentation

## Core Principle

**Document both WHAT and WHY.** Future developers need to know:
- WHAT: What exists, how it works, how to use it
- WHY: Why this approach, why not alternatives, what trade-offs were accepted

## The WHAT: Describing What Exists

### Code-Level Documentation

```javascript
/**
 * Authenticates a user and returns a session token.
 *
 * @param {string} email - User's email address
 * @param {string} password - User's plaintext password
 * @returns {Promise<{token: string, expiresAt: Date}>} Session info
 * @throws {AuthError} If credentials are invalid
 *
 * @example
 * const session = await login('user@example.com', 'password123');
 * console.log(session.token); // "eyJhbG..."
 */
async function login(email, password) { ... }
```

### Feature-Level Documentation

```markdown
## User Authentication

### Overview
Users authenticate via email/password to receive a JWT session token.

### How It Works
1. User submits credentials to POST /api/auth/login
2. Server validates against bcrypt-hashed password
3. On success, returns JWT token (1 hour expiry)
4. Token must be included in Authorization header for protected routes

### Configuration
- `JWT_SECRET`: Secret for signing tokens
- `SESSION_DURATION`: Token lifetime (default: 1h)
```

## The WHY: Explaining Reasoning

### Inline Comments for WHY

```javascript
// Use bcrypt cost factor 12 - balances security (10^12 iterations)
// against login latency (<500ms on typical hardware)
const BCRYPT_COST = 12;

// Store refresh tokens in Redis rather than JWT claims to enable
// server-side revocation without maintaining a blacklist
await redis.set(`refresh:${userId}`, token, 'EX', REFRESH_TTL);

// Sort by createdAt DESC to show newest first - users expect
// recent items at top based on UX research (see docs/decisions/sort-order.md)
const items = await db.query('SELECT * FROM items ORDER BY created_at DESC');
```

### Decision Records for WHY

Use Architecture Decision Records (ADR) format:

```markdown
# ADR-001: Use JWT for Session Management

## Status
Accepted

## Context
We need session management for authenticated users. Options considered:
- Server-side sessions (Redis/DB)
- JWT tokens
- Cookie-based sessions

## Decision
Use JWT tokens stored in httpOnly cookies.

## Rationale
- **Stateless**: No server-side session storage needed
- **Scalable**: Works across multiple servers without sticky sessions
- **Standard**: Well-understood, library support in all languages

## Trade-offs Accepted
- Cannot revoke individual tokens (mitigated by short expiry + refresh tokens)
- Token size larger than session ID (acceptable for our payload)

## Alternatives Rejected
- **Redis sessions**: Added infrastructure complexity
- **Cookie sessions**: Doesn't scale horizontally without sticky sessions
```

## Documentation Types

### 1. Inline Comments

**When to comment:**
- Non-obvious business logic
- Performance optimizations
- Security considerations
- Workarounds for known issues
- Magic numbers or constants

**Comment template:**
```javascript
// [WHAT it does] - [WHY this approach]
// Example: Rate limit to 100 req/min - prevents abuse while allowing normal usage
```

### 2. Function/Method Documentation

```javascript
/**
 * [WHAT] One-line summary of what this does.
 *
 * [WHY - if non-obvious] Explanation of why this exists or approach taken.
 *
 * @param {Type} name - [WHAT] Description of parameter
 * @returns {Type} [WHAT] Description of return value
 * @throws {ErrorType} [WHEN] Conditions that cause this error
 *
 * @example [HOW] Usage example
 */
```

### 3. README Documentation

```markdown
# Feature Name

## What It Does
[High-level description of functionality]

## Why It Exists
[Business context, problem it solves]

## How It Works
[Technical overview, architecture]

## How to Use
[Usage examples, configuration]

## Design Decisions
[Link to ADRs or inline explanations]
```

### 4. Decision Log

```markdown
# Decision Log: [Feature Name]

## Summary
[WHAT] Brief description of what was built.

## Key Decisions

### Decision 1: [Title]
**What**: [What was decided]
**Why**: [Reasoning]
**Alternatives**: [What else was considered and why rejected]
**Trade-offs**: [What limitations were accepted]

## How to Recreate
[Step-by-step to rebuild from scratch]
```

## Documentation Completeness Test

Ask these questions:

### For WHAT
- [ ] Can someone understand what this code does without reading implementation?
- [ ] Are inputs, outputs, and errors documented?
- [ ] Are usage examples provided?
- [ ] Is configuration documented?

### For WHY
- [ ] Can someone understand why this approach was chosen?
- [ ] Are rejected alternatives documented?
- [ ] Are trade-offs explicit?
- [ ] Are non-obvious decisions explained?

### For Maintenance
- [ ] Could someone recreate this from documentation alone?
- [ ] Are dependencies and their purposes documented?
- [ ] Are known limitations documented?
- [ ] Is there guidance for common modifications?

## Anti-Patterns

### Documenting Only WHAT
```javascript
// Bad: Only WHAT
// Increment counter
counter++;

// Good: WHAT + WHY
// Track retry attempts - circuit breaker opens after 3 failures
counter++;
```

### Documenting Only WHY
```javascript
// Bad: Only WHY (what does it actually do?)
// For performance reasons
cache.set(key, value, { ttl: 3600 });

// Good: WHAT + WHY
// Cache API response for 1 hour - reduces load on external service
// which has 100 req/min rate limit
cache.set(key, value, { ttl: 3600 });
```

### Obvious Comments
```javascript
// Bad: Obvious WHAT, no WHY needed
// Loop through users
for (const user of users) { ... }

// Good: Non-obvious logic worth explaining
// Process in batches of 100 to avoid memory issues with large datasets
for (const batch of chunk(users, 100)) { ... }
```

## Templates

### Quick Decision Record
```markdown
## [Decision Title]
**Date**: [Date]
**What**: [What was decided]
**Why**: [Primary reasoning]
**Trade-off**: [What we gave up]
```

### Code Comment Block
```javascript
/*
 * [WHAT] Feature/component description
 *
 * [WHY] Why this exists and approach taken
 *
 * [HOW] Brief explanation of how it works
 *
 * [USAGE] Example of how to use
 */
```

## Checklist Before Completing Documentation

- [ ] WHAT is clear (functionality described)
- [ ] WHY is explained (reasoning documented)
- [ ] Examples provided (how to use)
- [ ] Trade-offs explicit (limitations known)
- [ ] Alternatives mentioned (context for decision)
- [ ] Recreatable (could rebuild from docs)

## Reading Decisions During Review

Decision docs are not just a write-only log — they are the reference used by
`/lemongrab:pr-review` (chunk review) and `/lemongrab:resolve-feedback` (validation step)
to keep feedback aligned with prior choices.

**Where decisions live (read order):**
1. `docs/state/decisions.md` — per-feature decision log written during TDD workflow
2. `docs/decisions/*.md` — project-wide decision records
3. `docs/adr/*.md` — architecture decision records (if the project uses this convention)
4. `docs/architecture/*.md`, `docs/plans/*.md`, `docs/requirements/*.md` — supporting context

**When reviewing code (pr-reviewer agent):**
- Skim titles and summaries for all decision entries
- Deep-read only entries that touch files in the current chunk or subsystems the diff
  interacts with
- Before emitting a finding, ask: "Does a documented decision already settle this?"
  - If yes and the change respects it → drop the finding (list under "Suppressed")
  - If yes and the change contradicts it → raise CRITICAL with explicit "conflicts with
    `<doc-path>`" framing, ask whether reversal is intentional
  - If no decision applies → finding stands on its own merits

**When validating PR feedback (resolve-feedback):**
- For each comment requesting a change, check the relevant decision docs
- If a decision contradicts the request → mark `CONFLICTS_WITH_DECISION`, reply with a
  citation, do NOT fix
- If the reviewer clearly lacks context the docs provide → mark `MISSING_CONTEXT`,
  reply with a citation
- If the PR is a planned migration/rewrite that reverses the decision → mark
  `NEEDS_HUMAN` rather than CONFLICTS; let the user confirm the reversal is in scope

**Citation format** (both review and resolve-feedback):
```
Conflicts with docs/decisions/D-007.md — chose Postgres LISTEN/NOTIFY over Redis to
keep infra surface minimal. If reversing, update the decision record first.
```

A decision doc is only as valuable as the review discipline that references it.
Suppressing repetitive findings based on decisions is how the team stops relitigating
settled questions in every PR.
