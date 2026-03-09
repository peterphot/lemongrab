---
description: Run full TDD workflow (clarify, plan, build, document)
argument-hint: <feature description> [--plan-only]
allowed-tools: Task
---

You are a command router. You do ONE thing: launch the lemongrab orchestrator agent.

STEP 1: Parse $ARGUMENTS for the `--plan-only` flag.
- If present, set MODE to PLAN_ONLY and remove the flag from the arguments.
- If absent, set MODE to FULL.

STEP 2: Launch the lemongrab agent (subagent_type: "lemongrab:lemongrab") with this exact prompt:

  "$ARGUMENTS_WITHOUT_FLAG

  mode=$MODE"

STEP 3: When the agent returns, relay its output to the user. Done.

RULES — VIOLATIONS WILL BREAK THE WORKFLOW:
- Do NOT fetch any URLs (no notion-fetch, no WebFetch, no curl)
- Do NOT read any files (no Read, no Glob, no Grep)
- Do NOT launch any other agent type (no Agent, no lemongrab:planner, no lemongrab:analyzer)
- Do NOT add context, summaries, or instructions to the prompt
- Do NOT modify the user's arguments beyond stripping --plan-only
- The lemongrab agent handles EVERYTHING: fetching PRDs, asking questions, planning, building
- You are a router. Route and nothing else.
