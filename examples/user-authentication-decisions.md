# Decision Log: User Authentication

## Summary

Implemented JWT-based authentication with bcrypt password hashing and Redis-backed session invalidation. Supports login, logout, and automatic session expiration after 30 minutes.

## Key Decisions

### Decision 1: JWT for Session Tokens

**Choice:** Use JSON Web Tokens (JWT) for authentication

**Why:**
- Stateless: No server-side session storage needed (except for logout blacklist)
- Scalable: Works with load balancers without sticky sessions
- Portable: Works with web, mobile, and API clients
- Self-contained: Token carries user ID and expiration

**Alternatives considered:**
- Server-side sessions with cookies - Rejected because requires shared session store across all servers, adds latency for every authenticated request
- Opaque tokens with database lookup - Rejected because adds database query per request, slower than JWT verification

**Trade-offs accepted:**
- Tokens cannot be invalidated without a blacklist (hence Redis for logout)
- Token size larger than session ID (not an issue for our use case)

### Decision 2: Redis Blacklist for Logout

**Choice:** Store invalidated token IDs in Redis with TTL matching token expiration

**Why:**
- Fast lookup: O(1) check if token is blacklisted
- Auto-cleanup: TTL ensures blacklist doesn't grow indefinitely
- Minimal storage: Only store invalidated tokens, not all active ones

**Alternatives considered:**
- No logout (just wait for expiry) - Rejected because poor security UX
- Store all valid tokens (whitelist) - Rejected because requires storage for every active session
- Short token expiry (5 min) with refresh tokens - Rejected because adds complexity, doesn't solve the logout problem

**Trade-offs accepted:**
- Requires Redis dependency
- Logout adds one Redis write + check on each authenticated request

### Decision 3: bcrypt with Cost Factor 12

**Choice:** Hash passwords using bcrypt with cost factor 12

**Why:**
- ~250ms hash time provides good brute-force resistance
- Widely supported and audited algorithm
- Built-in salt generation
- Cost factor can be increased as hardware improves

**Alternatives considered:**
- bcrypt cost 10 - Rejected because too fast (~60ms), vulnerable to GPU attacks
- bcrypt cost 14 - Rejected because too slow (~1s), poor login UX
- Argon2 - Rejected because less library support, bcrypt is sufficient for our threat model

**Trade-offs accepted:**
- Login takes ~250ms for password verification
- CPU-intensive during authentication (acceptable for our scale)

### Decision 4: Generic Error Messages

**Choice:** Return "Invalid credentials" for all authentication failures

**Why:**
- Prevents user enumeration attacks
- Attacker cannot determine if email exists
- Consistent with security best practices

**Alternatives considered:**
- Specific errors ("Email not found", "Wrong password") - Rejected because reveals whether accounts exist

**Trade-offs accepted:**
- Slightly worse UX (user doesn't know if they mistyped email or password)
- Mitigated by "Forgot password" flow (out of scope for this feature)

## Dependencies

- `bcrypt` (^5.1.0) - Password hashing
- `jsonwebtoken` (^9.0.0) - JWT creation and verification
- `redis` (^4.6.0) - Token blacklist storage

## How to Recreate

If this code were deleted, here's how to rebuild it:

1. Create auth module structure:
   ```
   src/auth/
   ├── routes.ts      # Express routes for /login, /logout
   ├── middleware.ts  # Auth middleware for protected routes
   ├── password.ts    # bcrypt hash/verify utilities
   ├── token.ts       # JWT create/verify utilities
   └── blacklist.ts   # Redis blacklist operations
   ```

2. Implement password utilities first (no dependencies on other auth code)

3. Implement token utilities (depends on password for login flow)

4. Implement blacklist utilities (standalone Redis operations)

5. Wire up routes (login uses password + token, logout uses blacklist)

6. Create middleware (uses token + blacklist)

7. Run full test suite to verify all scenarios from requirements

## Git Checkpoints

- `abc1234` - [T001-T002] Auth module setup complete
- `def5678` - [T003-T004] Password hashing working
- `ghi9012` - [T005-T006] Login endpoint working
- `jkl3456` - [T007-T008] JWT utilities working
- `mno7890` - [T009-T012] Logout and session expiration working
- `pqr1234` - [T013-T014] Integration tests passing, middleware complete

## Related Documents

- Requirements: docs/requirements/user-authentication.md
- Plan: docs/plans/user-authentication.md
- Tests: src/auth/__tests__/
- Implementation: src/auth/
