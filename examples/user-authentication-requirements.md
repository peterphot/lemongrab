# Feature: User Authentication

## Status: COMPLETED

## User Stories (Prioritized)

### P1 - Critical Path

- **US1**: As a user, I want to log in with email and password so that I can access my account
  - Given valid credentials, When I submit the login form, Then I receive a session token
  - Given invalid password, When I submit the login form, Then I see "Invalid credentials" error
  - Given non-existent email, When I submit the login form, Then I see "Invalid credentials" error

- **US2**: As a user, I want to log out so that I can secure my session
  - Given I am logged in, When I click logout, Then my session is invalidated
  - Given I am logged out, When I try to access protected routes, Then I am redirected to login

### P2 - Important

- **US3**: As a user, I want my session to expire after inactivity so that my account stays secure
  - Given I am logged in, When 30 minutes pass with no activity, Then my session expires
  - Given my session expired, When I make a request, Then I am redirected to login

## Functional Requirements

- **FR-001**: System shall authenticate users with email and password
  - Testable criteria: Login endpoint returns 200 with token for valid credentials, 401 for invalid

- **FR-002**: System shall hash passwords using bcrypt with cost factor 12
  - Testable criteria: Stored passwords are bcrypt hashes, not plaintext

- **FR-003**: System shall invalidate sessions on logout
  - Testable criteria: Token becomes invalid after logout endpoint called

- **FR-004**: System shall expire sessions after 30 minutes of inactivity
  - Testable criteria: Requests with tokens older than 30 minutes return 401

## Acceptance Criteria (Testable)

### US1 Test Scenarios
| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| Valid login | valid email, valid password | 200 + session token | Happy path |
| Invalid password | valid email, wrong password | 401 + error message | Error case |
| Non-existent email | unknown@test.com, any password | 401 + error message | Error case |
| Empty email | "", valid password | 400 + validation error | Boundary |
| Empty password | valid email, "" | 400 + validation error | Boundary |
| SQL injection attempt | "'; DROP TABLE users;--", password | 400 or 401 (safe) | Security |

### US2 Test Scenarios
| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| Successful logout | valid token | 200 + token invalidated | Happy path |
| Logout without token | no token | 401 | Error case |
| Access after logout | invalidated token | 401 | Error case |

### US3 Test Scenarios
| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| Session valid at 29 min | token at 29 min age | 200 (still valid) | Boundary |
| Session expired at 30 min | token at 30 min age | 401 (expired) | Boundary |
| Session expired at 31 min | token at 31 min age | 401 (expired) | Happy path |

## Edge Cases (Must Have Tests)

- [x] What happens when email is empty? → Test: test_login_empty_email
- [x] What happens when password is empty? → Test: test_login_empty_password
- [x] What happens when email format is invalid? → Test: test_login_invalid_email_format
- [x] What happens when password is very long (10000 chars)? → Test: test_login_long_password
- [x] What happens on concurrent logout attempts? → Test: test_concurrent_logout

## Boundary Conditions

- Maximum email length: 254 characters → test at 254, 255
- Minimum password length: 8 characters → test at 7, 8
- Session timeout: 30 minutes → test at 29, 30, 31 minutes
- Empty inputs: email, password → test each empty

## Out of Scope

- Password reset functionality
- Multi-factor authentication
- Social login (OAuth)
- Remember me functionality
- Account lockout after failed attempts

## Technical Notes

- Using JWT for session tokens
- Tokens stored in httpOnly cookies
- Password hashing with bcrypt (cost 12)
- Session state stored in Redis

## Open Questions

- ~~Should we rate limit login attempts?~~ → Decided: Yes, 5 attempts per minute per IP
- ~~What error message for invalid credentials?~~ → Decided: Generic "Invalid credentials" (no info leak)

## Test Coverage Checklist

- [x] Every FR has testable criteria
- [x] Every user story has test scenarios
- [x] Every edge case maps to a test
- [x] Boundary conditions are explicit
- [x] Error cases are documented
