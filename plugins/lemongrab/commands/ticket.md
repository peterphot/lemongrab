---
description: Implement a feature from a Linear ticket
argument-hint: <ticket-id> or <ticket-id-1>, <ticket-id-2>, ... or sub-issues of <ticket-id>
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

You are the workflow orchestrator for ticket-based workflows.

STEP 1: DETECT TICKET MODE

From $ARGUMENTS:
1. "sub-issues of <ID>" or "sub-issues <ID>" → MULTI_TICKET mode
2. Multiple comma-separated IDs → MULTI_TICKET mode
3. Single ticket ID → SINGLE_TICKET mode

STEP 2: SINGLE TICKET

For a single ticket, run the same state machine loop as `/lemongrab:tdd` but with
these workflow-specific behaviors:

- CLARIFY phase: Launch `lemongrab:analyzer` to fetch the ticket first, then clarifier
- TICKETS phase: Implicit — don't ask. Store source ticket ID in task-status.json
- BRANCH: `feat/<ticket-id>-<slug>`
- PR: Include "Closes <ticket-id>" in PR body
- Completion: Move ticket to "In Review" (don't set "Done" — merge does that)

Initialize state with `{"workflow": "ticket", "sourceTicket": "<ID>"}` and follow
the full state machine from `/lemongrab:tdd` starting at CLARIFY_IN_PROGRESS.

STEP 3: MULTI TICKET

1. Fetch the ticket list:
   - If parent ticket: Launch `lemongrab:ticket-manager` to fetch sub-issues
   - If explicit list: validate each ticket exists
2. Present ordered list to user via AskUserQuestion for approval (user can reorder/skip)
3. Configure via AskUserQuestion:
   "MULTI_TICKET SETUP — Found N tickets. Branching: [per-ticket/single]?
   PR review rounds: [2]? Merge: [manual/auto/no-merge]? Plan source: [generate/import/ticket-as-plan]?"
4. Store config in task-status.json under multiTicket section
5. For each ticket in order: run the single-ticket workflow above
   - Per-ticket branching: checkout main, pull, create new branch per ticket
   - After each PR: present MERGE_GATE to user
   - Track progress in multiTicket.completedTickets

Follow the same user gates and verification scripts as `/lemongrab:tdd`.
