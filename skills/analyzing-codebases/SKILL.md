---
name: analyzing-codebases
description: Analyze existing codebases to build context quickly. Use when joining a project, understanding unfamiliar code, exploring architecture, or preparing to make changes. Provides patterns for structure analysis, dependency mapping, and key question frameworks.
---

# Analyzing Codebases

This skill helps build context on existing codebases quickly and systematically. Understanding before changing prevents mistakes and ensures changes fit the existing architecture.

## When to Use

- Joining an existing project
- Understanding unfamiliar code before making changes
- Exploring architecture and patterns
- Identifying entry points and key components
- Mapping dependencies and data flow

## Core Principle

**Understand before changing.** Never modify code you haven't read. Build a mental model of the codebase before proposing changes.

## Analysis Workflow

### Phase 1: High-Level Structure

```markdown
## Structure Analysis Checklist

- [ ] Identify project type (web app, CLI, library, API, etc.)
- [ ] Map top-level directories and their purposes
- [ ] Find configuration files (package.json, pyproject.toml, etc.)
- [ ] Locate entry points (main, index, app)
- [ ] Identify test locations
```

**Quick Commands:**
```bash
# Directory structure
ls -la
tree -L 2 -d  # or find . -type d -maxdepth 2

# Configuration files
ls *.json *.yaml *.toml *.config.* 2>/dev/null

# Entry points
grep -r "main\|entry\|start" package.json pyproject.toml 2>/dev/null
```

### Phase 2: Technology Stack

| Area | What to Look For |
|------|------------------|
| Language | File extensions, version files (.nvmrc, .python-version) |
| Framework | Dependencies, directory conventions |
| Database | ORM configs, migration folders, connection strings |
| Testing | Test framework in deps, test file patterns |
| Build | Build scripts, bundler configs, Dockerfile |

**Dependency Analysis:**
```bash
# Node.js
cat package.json | jq '.dependencies, .devDependencies'

# Python
cat requirements.txt pyproject.toml setup.py 2>/dev/null

# Go
cat go.mod
```

### Phase 3: Architecture Patterns

| Pattern | Indicators |
|---------|------------|
| MVC | controllers/, models/, views/ directories |
| Layered | services/, repositories/, domain/ |
| Microservices | Multiple package.json, docker-compose with services |
| Monolith | Single entry point, shared database |
| Event-driven | Message queues, event handlers, pub/sub |

### Phase 4: Key Components

Identify these critical areas:

```markdown
## Component Mapping

### Entry Points
- Main application: [path]
- API routes: [path]
- CLI commands: [path]

### Core Business Logic
- Domain models: [path]
- Services: [path]
- Utilities: [path]

### Data Layer
- Database models: [path]
- Migrations: [path]
- Repositories: [path]

### External Integrations
- API clients: [path]
- Third-party SDKs: [path]

### Configuration
- Environment: [path]
- Constants: [path]
- Feature flags: [path]
```

### Phase 5: Code Patterns

Look for established patterns:

```markdown
## Pattern Detection

### Naming Conventions
- Files: [kebab-case | camelCase | PascalCase | snake_case]
- Functions: [convention]
- Classes: [convention]
- Constants: [convention]

### Code Organization
- One class per file: [yes/no]
- Index re-exports: [yes/no]
- Barrel files: [yes/no]

### Error Handling
- Pattern: [try-catch | Result type | Either | callbacks]
- Custom errors: [location]

### Testing
- Pattern: [describe/it | test functions | class-based]
- Mocking approach: [jest.mock | dependency injection | etc.]
```

## Key Questions Framework

Ask these questions to understand any codebase:

### Architecture Questions
1. **What does this application do?** (Read README, main entry point)
2. **How is it structured?** (Directory layout, module boundaries)
3. **What are the main components?** (Core classes/modules)
4. **How do components communicate?** (Direct calls, events, APIs)

### Data Questions
1. **Where does data come from?** (APIs, databases, files)
2. **How is data transformed?** (Pipelines, services)
3. **Where does data go?** (Storage, external systems)
4. **What's the data model?** (Entities, relationships)

### Flow Questions
1. **What's the happy path?** (Trace a successful request)
2. **Where are the boundaries?** (Input validation, output formatting)
3. **How are errors handled?** (Error types, recovery strategies)
4. **What's the authentication flow?** (If applicable)

### Quality Questions
1. **What's tested?** (Coverage, test types)
2. **What's not tested?** (Gaps, risk areas)
3. **Where are the complex parts?** (Long files, high cyclomatic complexity)
4. **Where are the dependencies?** (Coupling, external services)

## Analysis Output Template

```markdown
# Codebase Analysis: [Project Name]

## Overview
- **Type**: [web app | API | CLI | library | ...]
- **Language**: [primary language]
- **Framework**: [if applicable]
- **Size**: [~X files, ~Y lines]

## Architecture
[Brief description of architecture pattern]

### Component Diagram
```
[Simple ASCII or description of main components]
```

## Key Directories
| Directory | Purpose |
|-----------|---------|
| src/ | [description] |
| tests/ | [description] |
| ... | ... |

## Entry Points
- **Main**: `path/to/main`
- **Routes**: `path/to/routes`
- **Config**: `path/to/config`

## Technology Stack
- **Runtime**: [Node 18, Python 3.11, etc.]
- **Framework**: [Express, FastAPI, etc.]
- **Database**: [PostgreSQL, MongoDB, etc.]
- **Testing**: [Jest, pytest, etc.]

## Established Patterns
- [Pattern 1 with example location]
- [Pattern 2 with example location]

## Areas of Complexity
- [Complex area 1 - why it's complex]
- [Complex area 2 - why it's complex]

## Before Making Changes
1. [Prerequisite understanding 1]
2. [Prerequisite understanding 2]
```

## Quick Analysis Commands

### Find Important Files
```bash
# Recently modified (active development areas)
git log --oneline --name-only -20 | grep -v "^[a-f0-9]" | sort | uniq -c | sort -rn | head -20

# Largest files (potential complexity)
find . -name "*.js" -o -name "*.ts" -o -name "*.py" | xargs wc -l | sort -rn | head -20

# Most changed files (hotspots)
git log --pretty=format: --name-only | sort | uniq -c | sort -rn | head -20
```

### Understand Dependencies
```bash
# Find imports/requires
grep -r "import\|require\|from" --include="*.js" --include="*.ts" | head -50

# Find exports
grep -r "export\|module.exports" --include="*.js" --include="*.ts" | head -50
```

### Trace Execution
```bash
# Find function definitions
grep -rn "function\|def\|func\|fn" --include="*.js" --include="*.py" --include="*.go"

# Find class definitions
grep -rn "class " --include="*.js" --include="*.ts" --include="*.py"
```

## Analysis Checklist

Before claiming you understand a codebase:

- [ ] Can explain what the application does in one sentence
- [ ] Know the primary entry point(s)
- [ ] Understand the directory structure rationale
- [ ] Identified the core business logic location
- [ ] Know where and how tests are organized
- [ ] Understand the data model basics
- [ ] Identified established patterns to follow
- [ ] Know where configuration lives
- [ ] Can trace a request through the system

## Anti-Patterns

### Incomplete Analysis
```
Bad:  "I looked at the README"
Good: "Analyzed structure, traced main flow, identified patterns"
```

### Assumption-Based Changes
```
Bad:  "This probably works like typical Express apps"
Good: "This uses custom middleware pattern (see src/middleware/)"
```

### Missing Context
```
Bad:  "I'll add a new utility function"
Good: "Existing utilities in src/utils/ use factory pattern, I'll follow that"
```
