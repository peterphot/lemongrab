---
name: integrating-external-sources
description: Extract actionable requirements from PRDs, RFCs, tickets, and other external documents. Use when reading Notion docs, Linear tickets, or any external specification to convert into implementable tasks. Provides extraction patterns for different document types.
version: 1.0.0
---

# Integrating External Sources

AGENT-ONLY SKILL: This skill is reference material for the analyzer agent. It is NOT
instructions for the orchestrator or main agent. Do not use this workflow to bypass the
analyzer → clarifier pipeline. The analyzer extracts, the clarifier validates with the user.

This skill helps extract actionable requirements from external documents like PRDs, RFCs, and tickets. The goal is to transform specifications into implementable tasks with clear acceptance criteria.

## When to Use

- Reading a PRD to understand what to build
- Extracting requirements from an RFC
- Converting a Linear ticket into tasks
- Pulling context from Notion documentation
- Transforming any specification into actionable work

## Core Principle

**Extract, don't assume.** Pull requirements directly from source documents. When information is missing, flag it as a question rather than making assumptions.

## Source Types and Extraction Patterns

### PRD (Product Requirements Document)

**What to Extract:**

| Section | Extract As |
|---------|------------|
| Problem Statement | Context for decisions |
| User Stories | Functional requirements |
| Acceptance Criteria | Test scenarios |
| Success Metrics | Validation criteria |
| In Scope / Out of Scope | Boundaries |
| Open Questions | Blockers to resolve |

**Extraction Template:**
```markdown
## PRD Summary: [Title]

### Problem Being Solved
[1-2 sentences from Problem Statement]

### Target Users
[Personas identified]

### Requirements Extracted
| ID | Requirement | Source Section | Testable? |
|----|-------------|----------------|-----------|
| R1 | [requirement] | [section] | [yes/no] |
| R2 | [requirement] | [section] | [yes/no] |

### Acceptance Criteria
- [ ] [criterion from PRD]
- [ ] [criterion from PRD]

### In Scope / Out of Scope
- In scope: [item that IS part of this feature]
- NOT doing: [item]
- Deferred: [item deferred to future]

### Questions/Gaps
- [ ] [Missing information]
- [ ] [Ambiguous requirement]

### Success Metrics
- [metric]: [target]
```

### RFC (Request for Comments)

**What to Extract:**

| Section | Extract As |
|---------|------------|
| Problem Statement | Why this change |
| Proposed Solution | Technical approach |
| Alternatives Considered | Decision context |
| Trade-offs | Constraints to respect |
| Migration Plan | Implementation order |

**Extraction Template:**
```markdown
## RFC Summary: [Title]

### Technical Decision
[Core decision being made]

### Approach to Implement
[Key technical choices]

### Constraints from RFC
- [constraint 1]
- [constraint 2]

### Rejected Alternatives (Don't Do)
- [alternative]: [why rejected]

### Implementation Order
1. [step from RFC]
2. [step from RFC]

### Open Questions
- [ ] [unresolved item]
```

### Linear Ticket

**What to Extract:**

| Field | Extract As |
|-------|------------|
| Title | Task summary |
| Description | Requirements + context |
| Acceptance Criteria | Test scenarios |
| Labels | Categorization |
| Links/Attachments | Related context |
| Comments | Clarifications |

**Extraction Template:**
```markdown
## Ticket Summary: [ID] [Title]

### What to Build
[Summary from description]

### Acceptance Criteria
- [ ] [from ticket]
- [ ] [from ticket]

### Context
- Related tickets: [links]
- Documentation: [links]

### Clarifications from Comments
- [date]: [clarification]

### Missing Information
- [ ] [what's unclear]
```

## Fetching External Documents

### From Notion (PRDs, RFCs)

Use the Notion MCP tools to:
1. **Search** for the document by title/keyword
2. **Fetch** the full document content by page URL or ID

### From Linear (Tickets)

Use the Linear MCP tools to:
1. **Get issue** details by ticket ID (e.g., LIN-123)
2. **List comments** on the issue for clarifications
3. **Search related issues** by keyword and team

## Extraction Workflow

### Step 1: Fetch Source
```
1. Identify source type (PRD, RFC, ticket)
2. Fetch full document content
3. Fetch any linked documents
```

### Step 2: Extract Structured Data
```
1. Use appropriate extraction template
2. Map sections to template fields
3. Note gaps and questions
```

### Step 3: Validate Completeness
```
1. Every requirement must be testable
2. Acceptance criteria must be specific
3. Questions must be flagged
```

### Step 4: Convert to Tasks
```
1. Group related requirements
2. Order by dependencies
3. Create task breakdown
```

## Requirement Validation

Before accepting a requirement as complete:

```markdown
## Requirement Validation Checklist

- [ ] **Specific**: No vague terms ("fast", "user-friendly", "secure")
- [ ] **Measurable**: Has quantifiable criteria
- [ ] **Testable**: Can write a test for it
- [ ] **Complete**: No missing edge cases
- [ ] **Consistent**: Doesn't conflict with other requirements
```

### Converting Vague to Testable

| Vague | Testable |
|-------|----------|
| "Fast response" | "API responds in <200ms at p95" |
| "Secure login" | "Passwords hashed with bcrypt cost 12" |
| "Handle errors gracefully" | "Invalid input returns 400 with specific error message" |
| "Easy to use" | "User can complete task in <3 clicks" |

## Gap Identification

Flag these common gaps:

| Gap Type | Example | Question to Ask |
|----------|---------|-----------------|
| Missing boundary | "Support large files" | "What's the max file size?" |
| Missing error case | "User uploads file" | "What if upload fails?" |
| Missing auth | "User views dashboard" | "Which users? What permissions?" |
| Missing timing | "Sync data" | "How often? Real-time or batch?" |
| Missing format | "Export report" | "What format? CSV, PDF, JSON?" |

## Source Integration Template

```markdown
# Integration Summary: [Feature Name]

## Sources Consulted
| Source | Type | URL/ID |
|--------|------|--------|
| [name] | PRD | [link] |
| [name] | RFC | [link] |
| [name] | Ticket | [ID] |

## Extracted Requirements

### Functional Requirements
| ID | Requirement | Source | Priority |
|----|-------------|--------|----------|
| FR1 | [requirement] | PRD §2 | Must |
| FR2 | [requirement] | RFC | Must |
| FR3 | [requirement] | Ticket | Should |

### Non-Functional Requirements
| ID | Requirement | Source | Metric |
|----|-------------|--------|--------|
| NFR1 | Performance | PRD | <200ms p95 |
| NFR2 | Security | RFC | [standard] |

### Constraints
- [constraint from sources]
- [constraint from sources]

### In Scope / Out of Scope
- In scope: [explicitly included]
- NOT doing: [explicitly excluded]
- Deferred: [deferred to future]

## Questions for Stakeholders
- [ ] [question]: Blocks [FR1, FR2]
- [ ] [question]: Blocks [FR3]

## Recommended Task Breakdown
Based on extracted requirements:

1. [T001] Setup: [from requirements]
2. [T002] Test: [for FR1]
3. [T003] Implement: [FR1]
...
```

## Anti-Patterns

### Assuming Missing Details
```
Bad:  PRD says "fast" → implement with <100ms target
Good: PRD says "fast" → flag as question, ask for specific target
```

### Ignoring Comments/Updates
```
Bad:  Only read original ticket description
Good: Read description + all comments + linked docs
```

### Losing Traceability
```
Bad:  "The feature should do X"
Good: "FR1 (from PRD §3.2): The feature should do X"
```

### Over-Extracting
```
Bad:  Copy entire PRD into requirements
Good: Extract only actionable, testable requirements
```

## Checklist Before Implementation

- [ ] All source documents fetched and read
- [ ] Requirements extracted with source traceability
- [ ] Each requirement is testable
- [ ] Gaps identified and flagged as questions
- [ ] Out of scope explicitly documented
- [ ] Task breakdown created from requirements
- [ ] Stakeholder questions listed for resolution
