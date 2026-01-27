---
name: documenting-decisions
description: Document software decisions capturing both WHAT was built and WHY it was built that way. Use when writing decision records, adding code comments, updating documentation, or explaining technical choices. Provides ADR templates, comment style guides, and documentation completeness checks.
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
