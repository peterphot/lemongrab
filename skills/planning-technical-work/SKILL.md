---
name: planning-technical-work
description: Plan technical work with structured task breakdowns, dependency identification, and architecture decisions. Use when creating implementation plans, breaking features into tasks, identifying parallel work, or making technical design choices. Provides task templates and planning patterns.
---

# Planning Technical Work

This skill helps translate requirements into actionable technical plans with clear task breakdowns, dependencies, and architecture decisions.

## When to Use

- Creating implementation plans from requirements
- Breaking features into ordered tasks
- Identifying task dependencies and parallel work
- Making architecture and technology decisions
- Estimating scope and complexity

## Planning Process

### Step 1: Understand Requirements
Before planning, ensure you have:
- [ ] Clear user stories with acceptance criteria
- [ ] Functional requirements list
- [ ] Edge cases and error scenarios
- [ ] Out of scope explicitly defined

### Step 2: Architecture Overview
Define the high-level approach:
- What components are involved?
- How do they interact?
- What data flows between them?
- What external dependencies exist?

### Step 3: Task Breakdown
Convert architecture into ordered tasks following TDD pattern:
1. Setup tasks (structure, dependencies)
2. Test tasks (write failing tests)
3. Implement tasks (make tests pass)

### Step 4: Identify Dependencies
Map which tasks block others:
- Sequential: Must complete before next starts
- Parallel [P]: Can run alongside other [P] tasks

### Step 5: Document Decisions
Record technology choices with rationale.

## Task Breakdown Patterns

### Task Format
```
[TXXX] [USX] Type: Description
```

Where:
- `TXXX` = Task number (T001, T002...)
- `USX` = User story reference (US1, US2...)
- `Type` = Setup | Test | Implement
- `[P]` = Can run in parallel (optional)

### Example Breakdown
```markdown
### Phase 1: Setup
- [T001] [US1] Setup: Create authentication module structure
- [T002] [P] [US1] Setup: Install and configure bcrypt, jwt packages

### Phase 2: User Registration (US1)
- [T003] [US1] Test: Write tests for user registration
- [T004] [US1] Implement: Create registration endpoint
- [T005] [US1] Test: Write tests for password hashing
- [T006] [US1] Implement: Add bcrypt password hashing

### Phase 3: User Login (US2)
- [T007] [US2] Test: Write tests for login validation
- [T008] [US2] Implement: Create login endpoint
- [T009] [US2] Test: Write tests for JWT generation
- [T010] [US2] Implement: Add JWT token creation
```

### Dependency Mapping
```markdown
## Dependencies

- T003 depends on: T001, T002 (setup complete)
- T004 depends on: T003 (tests exist)
- T007 depends on: T001, T002 (can start parallel to Phase 2)
- T008 depends on: T007

## Parallel Opportunities

- T007-T010 (login) can run parallel to T003-T006 (registration)
- Both setup tasks [P] can run simultaneously
```

## Architecture Documentation

### Component Overview
```markdown
## Architecture Overview

### Components
1. **Auth Controller** - Handles HTTP requests for auth endpoints
2. **Auth Service** - Business logic for authentication
3. **User Repository** - Database access for user data
4. **Token Service** - JWT creation and validation

### Data Flow
```
Client → Controller → Service → Repository → Database
                   ↓
              Token Service
```

### External Dependencies
- PostgreSQL: User storage
- Redis: Session/token blacklist (optional)
```

### Data Model
```markdown
## Data Model

### User
| Field | Type | Constraints |
|-------|------|-------------|
| id | UUID | Primary key |
| email | VARCHAR(254) | Unique, not null |
| password_hash | VARCHAR(60) | Not null (bcrypt) |
| created_at | TIMESTAMP | Default: now() |

### Session (if using)
| Field | Type | Constraints |
|-------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key → User |
| expires_at | TIMESTAMP | Not null |
```

### API Contracts
```markdown
## API Contracts

### POST /api/auth/register
**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Success Response (201):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**Error Responses:**
- 400: Invalid email format, password too weak
- 409: Email already registered
```

## Technical Decision Framework

### Decision Template
```markdown
### Decision: [Title]

**Context**: What situation requires a decision?

**Options Considered**:
1. Option A: [Description]
   - Pro: [Benefit]
   - Con: [Drawback]
2. Option B: [Description]
   - Pro: [Benefit]
   - Con: [Drawback]

**Decision**: [Which option and why]

**Trade-offs Accepted**: [What limitations we accept]
```

### Common Decision Points

| Decision Area | Questions to Ask |
|---------------|------------------|
| Database | SQL vs NoSQL? Which engine? |
| Auth | JWT vs sessions? Token storage? |
| API | REST vs GraphQL? Versioning? |
| Caching | What to cache? TTL strategy? |
| Error handling | Error format? Retry strategy? |

## Plan Document Template

```markdown
# Plan: [Feature Name]

## Status: DRAFT | APPROVED | IN PROGRESS | COMPLETED

## Architecture Overview
[High-level description of approach]

## Components
[List of components and their responsibilities]

## Data Model
[Entity definitions and relationships]

## API Contracts
[Endpoint specifications]

## Task Breakdown

### Phase 1: Setup
- [T001] ...

### Phase 2: [User Story 1]
- [T002] Test: ...
- [T003] Implement: ...

### Phase 3: [User Story 2]
- [T004] [P] Test: ...
- [T005] Implement: ...

## Dependencies
[Task dependency mapping]

## Technical Decisions
[Decisions with rationale]

## Risks and Mitigations
[Known risks and how to address them]
```

## Checklist Before Finalizing Plan

### Completeness
- [ ] All user stories have tasks
- [ ] All tasks follow Test → Implement pattern
- [ ] Dependencies are mapped
- [ ] Parallel opportunities identified with [P]

### Technical
- [ ] Architecture is clear
- [ ] Data model defined
- [ ] API contracts specified
- [ ] Technology decisions documented

### Feasibility
- [ ] No circular dependencies
- [ ] Setup tasks come first
- [ ] Test tasks before implement tasks
- [ ] Critical path identified

## Anti-Patterns

### Too Granular
```
Bad: [T001] Create src folder
     [T002] Create auth folder
     [T003] Create index.js file

Good: [T001] Setup: Create authentication module structure
```

### Missing Dependencies
```
Bad: [T005] Implement: Create login endpoint
     (no test task before it!)

Good: [T004] Test: Write tests for login
      [T005] Implement: Create login endpoint
```

### No Parallel Identification
```
Bad: All tasks sequential when some could parallelize

Good: [T004] [P] [US1] Test: Registration tests
      [T005] [P] [US2] Test: Login tests
      (Both can run simultaneously)
```
