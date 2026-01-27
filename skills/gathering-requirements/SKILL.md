---
name: gathering-requirements
description: Gather and document software requirements with testable acceptance criteria. Use when clarifying features, writing user stories, defining acceptance criteria, or ensuring requirements are complete and unambiguous. Provides question frameworks and requirement templates.
---

# Gathering Requirements

This skill helps gather complete, unambiguous, and testable requirements before any code is written. Requirements are the foundation for TDD - bad requirements lead to bad tests.

## When to Use

- Starting work on a new feature
- Clarifying ambiguous requests
- Writing user stories and acceptance criteria
- Ensuring requirements are testable
- Identifying edge cases and boundaries

## Core Principle

**Every requirement must be testable.** If you can't write a test for it, it's not a requirement - it's a wish.

## Question Framework

### Understanding the Request

| Question | Purpose |
|----------|---------|
| What problem does this solve? | Understand the WHY |
| Who is the user? | Identify personas |
| What's the expected outcome? | Define success |
| How does this fit with existing features? | Context |

### Defining Behavior

| Question | Purpose |
|----------|---------|
| What are the inputs? | Define interface |
| What are the outputs? | Define results |
| What triggers this? | Define entry points |
| What happens on success? | Happy path |
| What happens on failure? | Error handling |

### Finding Edge Cases

| Question | Purpose |
|----------|---------|
| What if the input is empty? | Boundary |
| What if the input is too large? | Limits |
| What if the user isn't authorized? | Security |
| What if the system is slow? | Performance |
| What if it's called twice? | Idempotency |

### Scoping

| Question | Purpose |
|----------|---------|
| What are we NOT doing? | Out of scope |
| What's the minimum viable version? | MVP |
| What can wait for later? | Prioritization |

## Testable Requirements

### Bad vs Good Requirements

| Bad (Untestable) | Good (Testable) |
|------------------|-----------------|
| "Fast login" | "Login completes in < 200ms" |
| "Secure authentication" | "Passwords hashed with bcrypt, cost 12" |
| "Handle errors gracefully" | "Invalid email returns 400 with message" |
| "User-friendly" | "Error messages include fix suggestion" |

### Acceptance Criteria Format

Use Given-When-Then for clarity:

```
Given [precondition/context]
When [action/trigger]
Then [expected outcome]
```

**Example:**
```
Given a user with valid credentials
When they submit the login form
Then they receive a session token
And are redirected to the dashboard
```

### Test Scenario Table

For each user story, create explicit test scenarios:

| Scenario | Input | Expected Output | Type |
|----------|-------|-----------------|------|
| Valid login | valid email, valid password | session token | Happy path |
| Wrong password | valid email, wrong password | "Invalid credentials" error | Error |
| Empty email | "", valid password | "Email required" error | Boundary |
| SQL injection | `'; DROP TABLE--`, any | Sanitized, no error | Security |

## Requirement Document Structure

```markdown
# Feature: [Name]

## Status: DRAFT | IN PROGRESS | COMPLETED

## Problem Statement
What problem does this solve and for whom?

## User Stories

### US1: [Story Title]
As a [user type]
I want to [action]
So that [benefit]

**Acceptance Criteria:**
- Given [context], When [action], Then [result]
- Given [context], When [action], Then [result]

**Test Scenarios:**
| Scenario | Input | Output | Type |
|----------|-------|--------|------|
| ... | ... | ... | ... |

## Functional Requirements

- **FR-001**: [Requirement]
  - Testable criteria: [How to verify]
- **FR-002**: [Requirement]
  - Testable criteria: [How to verify]

## Boundary Conditions

| Boundary | Min | Max | Test At |
|----------|-----|-----|---------|
| Email length | 5 | 254 | 4, 5, 254, 255 |
| Password length | 8 | 128 | 7, 8, 128, 129 |

## Edge Cases

- [ ] Empty input → [expected behavior]
- [ ] Null input → [expected behavior]
- [ ] Duplicate request → [expected behavior]

## Out of Scope

- [Thing we're explicitly NOT doing]
- [Feature deferred to future]

## Open Questions

- [Question needing stakeholder input]
```

## Completeness Checklist

Before finalizing requirements:

### Coverage
- [ ] All user personas identified
- [ ] Happy path defined
- [ ] Error cases defined
- [ ] Edge cases identified
- [ ] Boundary conditions specified

### Testability
- [ ] Every FR has testable criteria
- [ ] Acceptance criteria are specific
- [ ] Success/failure clearly defined
- [ ] Performance requirements quantified

### Clarity
- [ ] No ambiguous terms
- [ ] No assumptions
- [ ] Out of scope is explicit
- [ ] Dependencies identified

### Validation
- [ ] Stakeholder reviewed
- [ ] Technical feasibility confirmed
- [ ] No conflicting requirements

## Common Pitfalls

### Vague Language
```
Bad:  "System should be responsive"
Good: "API responds within 200ms at p95"
```

### Hidden Assumptions
```
Bad:  "User logs in"
Good: "User with verified email and active account logs in"
```

### Missing Error Cases
```
Bad:  "User uploads file"
Good: "User uploads file (max 10MB, types: jpg/png/pdf)"
      "If file too large → show error with size limit"
      "If wrong type → show error with allowed types"
```

### Untestable Security
```
Bad:  "System is secure"
Good: "Passwords stored with bcrypt (cost 12)"
      "Session expires after 30 min inactivity"
      "3 failed logins triggers 15 min lockout"
```

## Questions for Every Requirement

For each FR, ask:

1. **How do I test this?** → If no answer, requirement is incomplete
2. **What's the boundary?** → Define limits
3. **What if it fails?** → Define error behavior
4. **Who can do this?** → Define authorization
5. **When can this happen?** → Define preconditions
