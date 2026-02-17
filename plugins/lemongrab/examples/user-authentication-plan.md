# Plan: User Authentication

## Status: COMPLETED

## Architecture Overview

Simple JWT-based authentication with bcrypt password hashing. Stateless tokens with Redis for session invalidation (logout support).

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│  Auth API   │────▶│  Database   │
│             │◀────│  (Express)  │◀────│  (Postgres) │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │    Redis    │
                    │ (blacklist) │
                    └─────────────┘
```

## Data Model

```
User:
  - id: UUID (primary key)
  - email: string (unique, max 254 chars)
  - password_hash: string (bcrypt)
  - created_at: timestamp
  - updated_at: timestamp

Session (Redis):
  - key: "blacklist:{token_id}"
  - value: "1"
  - ttl: 30 minutes
```

## API Contracts

### POST /api/auth/login

Request:
```json
{ "email": "user@example.com", "password": "secretpass" }
```

Success Response (200):
```json
{ "token": "eyJhbGciOiJIUzI1NiIs...", "expiresIn": 1800 }
```

Error Response (401):
```json
{ "error": "Invalid credentials" }
```

### POST /api/auth/logout

Request Headers:
```
Authorization: Bearer <token>
```

Success Response (200):
```json
{ "message": "Logged out successfully" }
```

### GET /api/auth/me (protected route example)

Request Headers:
```
Authorization: Bearer <token>
```

Success Response (200):
```json
{ "id": "uuid", "email": "user@example.com" }
```

## Task Breakdown

### Phase 1: Setup

- [T001] [US1] Setup: Create auth module directory structure
- [T002] [US1] Setup: Install dependencies (bcrypt, jsonwebtoken, redis)

### Phase 2: Core Authentication (US1)

- [T003] [US1] Test: Write tests for password hashing
- [T004] [US1] Implement: Create password hashing utilities
- [T005] [US1] Test: Write tests for login endpoint
- [T006] [US1] Implement: Create login endpoint
- [T007] [US1] Test: Write tests for JWT token generation
- [T008] [US1] Implement: Create JWT utilities

### Phase 3: Session Management (US2, US3)

- [T009] [P] [US2] Test: Write tests for logout endpoint
- [T010] [P] [US3] Test: Write tests for session expiration
- [T011] [US2] Implement: Create logout endpoint with token blacklist
- [T012] [US3] Implement: Add expiration check to auth middleware

### Phase 4: Integration

- [T013] Test: Write integration tests for full auth flow
- [T014] Implement: Create auth middleware for protected routes

## Dependencies

- T003 depends on: T001, T002
- T004 depends on: T003
- T005 depends on: T004
- T006 depends on: T005
- T007 depends on: T006
- T008 depends on: T007
- T009, T010 can run in parallel (both depend on T008)
- T011 depends on: T009
- T012 depends on: T010
- T013 depends on: T011, T012
- T014 depends on: T013

## Technical Decisions

- **Decision 1**: JWT over session cookies
  - Why: Stateless, easier to scale, works with mobile clients
  - Alternative rejected: Server-side sessions - requires sticky sessions or shared state

- **Decision 2**: Redis blacklist for logout
  - Why: Need to invalidate tokens on logout, Redis is fast and supports TTL
  - Alternative rejected: Short token expiry without blacklist - poor UX (frequent re-login)

- **Decision 3**: bcrypt with cost 12
  - Why: Good balance of security and performance (~250ms per hash)
  - Alternative rejected: Cost 10 (too fast, vulnerable to brute force), Cost 14 (too slow for UX)
