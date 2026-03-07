---
name: brainstorming
description: Explore multiple design approaches before committing to a plan during the lemongrab DESIGN phase. Use when the designer agent needs to generate distinct architectural options, compare trade-offs, and present choices to the user. Not for ad-hoc discussions or post-planning changes. Provides approach differentiation frameworks and comparison patterns.
version: 1.0.0
---

# Brainstorming Design Approaches

This skill helps explore multiple distinct approaches to a problem before committing to one. Good design exploration prevents costly mid-implementation pivots.

## When to Use

- Before planning, when multiple valid architectures exist
- When requirements have tension (e.g., performance vs simplicity)
- When the feature is large enough to warrant design exploration
- When the user explicitly asks for options

## Core Principle

**Explore before committing.** The cost of exploring 2-3 approaches on paper is far less than the cost of realizing mid-implementation that a different approach was better.

## Approach Generation Framework

### Step 1: Identify Design Dimensions

For any feature, identify the axes along which approaches can meaningfully differ:

| Category | Common Dimensions |
|----------|-------------------|
| Architecture | Monolith vs modular vs microservice |
| Data | SQL vs NoSQL, normalized vs denormalized |
| Communication | Sync vs async, REST vs GraphQL vs RPC |
| State | Stateless vs stateful, client vs server |
| Coupling | Tight vs loose, direct vs event-driven |
| Complexity | Simple-now vs invest-for-later |

### Step 2: Generate Distinct Approaches

Each approach should differ along at least ONE major dimension. Test for distinctness:

**Distinct** (good):
- Approach A uses a monolithic service; Approach B uses event-driven microservices
- Approach A stores state in Redis; Approach B uses a SQL database with caching

**Not distinct** (bad):
- Approach A uses Express; Approach B uses Fastify (same architecture, different library)
- Approach A has 3 modules; Approach B has 4 modules (same pattern, different count)

### Step 3: Analyze Each Approach

For each approach, cover:

1. **How it satisfies requirements** — Map each FR to the approach
2. **Trade-offs** — What you gain vs what you give up
3. **Complexity** — Simple / Moderate / Complex
4. **Risk areas** — What could go wrong
5. **Extensibility** — How easy to add future features

### Step 4: Compare and Recommend

Build a comparison matrix. Be opinionated — recommend one, but let the user decide.

## Trade-off Analysis Patterns

### Performance vs Simplicity
```
Approach A: Simple synchronous flow
  + Easy to understand and debug
  + Fewer moving parts
  - Slower under load
  - Harder to scale horizontally

Approach B: Async with message queue
  + Handles high throughput
  + Easy to scale workers
  - More infrastructure
  - Harder to debug
```

### Flexibility vs Speed
```
Approach A: Hardcoded for current requirements
  + Fast to build
  + Less code
  - Every new requirement needs code changes

Approach B: Configuration-driven
  + New requirements via config
  + Users can customize
  - More upfront work
  - Over-engineering risk
```

### Coupling vs Cohesion
```
Approach A: Single integrated module
  + All logic in one place
  + No cross-module coordination
  - Changes ripple through

Approach B: Separated via interfaces
  + Changes are isolated
  + Testable in isolation
  - More indirection
  - Interface design effort
```

## Comparison Matrix Template

| Dimension | Approach A | Approach B | Approach C |
|-----------|-----------|-----------|-----------|
| Complexity | Low | Medium | High |
| Performance | Good | Better | Best |
| Extensibility | Low | Medium | High |
| Time to build | Fast | Medium | Slow |
| Risk | Low | Medium | Medium |
| Testability | Good | Good | Excellent |

## Anti-Patterns

### False Choices
Don't present approaches that are clearly inferior just to have a third option. Two strong options is better than two strong + one weak.

### Bikeshedding
Don't spend design time on trivial differences (naming, file layout, import style). Focus on architectural decisions that are expensive to change later.

### Analysis Paralysis
If no dimension meaningfully differentiates approaches, skip the design phase and go straight to planning. Not every feature needs design exploration.

### Anchoring
Present the simplest approach first. Starting with the complex option anchors expectations high. Let complexity be justified, not default.

## When to Skip Design Exploration

The design phase is optional. Skip it when:
- Feature is clearly SMALL (1-3 tasks)
- Only one viable approach exists
- Requirements are highly constrained (no design freedom)
- The feature is a bug fix or minor enhancement

The orchestrator decides whether to run the design phase based on feature scale and complexity.
