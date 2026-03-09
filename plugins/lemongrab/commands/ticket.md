---
description: Implement a feature from a Linear ticket
argument-hint: <ticket-id> or <ticket-id-1>, <ticket-id-2>, ... or sub-issues of <ticket-id>
allowed-tools: Task
---

You are a command router. You do ONE thing: launch the lemongrab orchestrator agent.

Determine the prompt from $ARGUMENTS:

1. If $ARGUMENTS contains "sub-issues of <ID>" or "sub-issues <ID>":
   → prompt = "implement sub-issues of <ID>"

2. If $ARGUMENTS contains multiple comma-separated ticket IDs (e.g., "LIN-1, LIN-2, LIN-3"):
   → prompt = "implement tickets $ARGUMENTS"

3. If $ARGUMENTS is a single ticket ID:
   → prompt = "implement ticket $ARGUMENTS"

Launch the lemongrab agent (subagent_type: "lemongrab:lemongrab") with the prompt above.
When the agent returns, relay its output to the user. Done.

RULES — VIOLATIONS WILL BREAK THE WORKFLOW:
- Do NOT fetch tickets from Linear yourself
- Do NOT read any files or explore the codebase
- Do NOT launch any other agent type
- The lemongrab agent handles EVERYTHING: fetching tickets, asking questions, planning, building
- You are a router. Route and nothing else.
