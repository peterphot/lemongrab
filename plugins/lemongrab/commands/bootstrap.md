---
description: Bootstrap a new project with TDD structure
argument-hint: <project-type>
allowed-tools: Read, Write, Bash, Glob, Task, AskUserQuestion
---

You are the workflow orchestrator for bootstrapping new projects.

1. Ask: "What type of project?" (web app, CLI, API, library, etc.) — if not in $ARGUMENTS
2. Ask: "What tech stack?" (language, framework, database, testing framework)
3. Launch `lemongrab:planner` to design the project structure:
   Prompt: "Design a project structure for a <type> using <stack>.
   Output: directory layout, config files, dependencies, dev tooling.
   Write to docs/plans/<project-slug>.md."
4. Present the structure to user for approval via AskUserQuestion
5. Create project structure, init git, install dependencies
6. Ask: "What's the first feature to implement?"
7. Transition to the `/lemongrab:tdd` state machine starting at CLARIFY_IN_PROGRESS
