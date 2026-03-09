---
description: Analyze an existing codebase to build context
argument-hint: "[path]"
allowed-tools: Read, Bash, Glob, Grep, Task, AskUserQuestion
---

Launch `lemongrab:analyzer` agent to analyze the codebase at $ARGUMENTS (or current directory if not specified).

Prompt: "Analyze this codebase and produce docs/analysis/<project-name>.md covering:
architecture overview, key patterns, dependencies, test coverage, and areas of concern."

When the analyzer returns, present the analysis summary to the user and ask:
"Analysis complete. What would you like to do with this codebase?
[implement a feature] [fix a bug] [refactor] [just exploring]"

If the user wants to implement/fix/refactor: transition to the `/lemongrab:tdd` state
machine starting at CLARIFY_IN_PROGRESS with the user's description as arguments.
