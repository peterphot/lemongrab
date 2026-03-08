---
description: Implement a feature from a Linear ticket
argument-hint: <ticket-id> or <ticket-id-1>, <ticket-id-2>, ... or sub-issues of <ticket-id>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion
---

Determine the ticket mode from $ARGUMENTS:

1. If $ARGUMENTS contains "sub-issues of <ID>" or "sub-issues <ID>":
   → Use the lemongrab agent with MULTI_TICKET workflow: "implement sub-issues of <ID>"

2. If $ARGUMENTS contains multiple comma-separated ticket IDs (e.g., "LIN-1, LIN-2, LIN-3"):
   → Use the lemongrab agent with MULTI_TICKET workflow: "implement tickets $ARGUMENTS"

3. If $ARGUMENTS is a single ticket ID:
   → Use the lemongrab agent to implement ticket $ARGUMENTS
