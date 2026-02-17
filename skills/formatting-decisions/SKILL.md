---
name: formatting-decisions
description: Format decision capture blocks for agent output. Use when logging architectural choices, user decisions, or implementation trade-offs. Provides the canonical decision block structure, phase prefix mappings, attribution rules, and ID numbering conventions.
version: 1.0.0
---

# Formatting Decisions

DECISION OUTPUT FORMAT FOR AGENT RESPONSES:

Agents capture decisions by appending a structured block as the LAST thing in their text output.
The orchestrator (lemongrab) extracts these blocks and appends them to docs/state/decisions.md.

PLACEMENT RULE: The `<!-- DECISIONS ... DECISIONS -->` block MUST be the final content in the
agent's output — after all other text, reports, and summaries. The orchestrator looks for the
block at the tail of the output. Do NOT place it mid-output or before other content.

FORMAT:

<!-- DECISIONS
- decision:
    id: D-{PHASE}-{NNN}
    phase: clarify | plan | implement | review | simplify | orchestrate
    who: user | claude
    what: "Short title"
    why: "Reasoning"
    alternatives: "Other options considered"
    context: "Question or situation that prompted this"
DECISIONS -->

PHASE PREFIXES FOR IDs:

The `phase` field value maps to an ID prefix as follows:

| phase value   | ID prefix    | Example       |
|---------------|--------------|---------------|
| clarify       | D-CLARIFY    | D-CLARIFY-001 |
| plan          | D-PLAN       | D-PLAN-001    |
| implement     | D-IMPL       | D-IMPL-001    |
| review        | D-REVIEW     | D-REVIEW-001  |
| simplify      | D-SIMPLIFY   | D-SIMPLIFY-001|
| orchestrate   | D-ORCH       | D-ORCH-001    |

Note: The `implement` phase uses the abbreviated prefix `D-IMPL`, not `D-IMPLEMENT`.

Descriptions:
- D-CLARIFY-NNN  — Decisions from the clarifier phase (user Q&A)
- D-PLAN-NNN     — Decisions from the planning phase (architecture, technology)
- D-IMPL-NNN     — Decisions from the implementation phase (data structures, algorithms)
- D-REVIEW-NNN   — Decisions observed during review (trade-offs, INFO items)
- D-SIMPLIFY-NNN — Decisions from simplification (refactoring approach)
- D-ORCH-NNN     — Decisions made by the orchestrator (scale, pattern, retry, parallelization)

WHO ATTRIBUTION RULES:

- "user"  — The user made this decision (answered a question, chose an option, set a requirement)
- "claude" — Claude made this decision (chose an algorithm, picked a pattern, selected a library)
- When the user explicitly picks from options → who: user
- When Claude selects an approach and the user approves → who: user (they made the final call)
- When Claude makes a technical choice without asking → who: claude

MULTIPLE DECISIONS:

Include multiple `- decision:` entries in a single block when several decisions were made:

<!-- DECISIONS
- decision:
    id: D-CLARIFY-001
    phase: clarify
    who: user
    what: "JWT for auth tokens"
    why: "Stateless, works with load balancers"
    alternatives: "Server-side sessions, opaque tokens"
    context: "Asked user which auth strategy to use"
- decision:
    id: D-CLARIFY-002
    phase: clarify
    who: user
    what: "30-minute session expiry"
    why: "Balances security and UX"
    alternatives: "15 minutes (too short), 1 hour (too long)"
    context: "Asked about session duration"
DECISIONS -->

ID NUMBERING ON RETRIES:

If an agent is re-launched (e.g., after a verification failure), it MUST NOT reuse IDs from its
previous run. Before emitting decisions, check the orchestrator's prompt for any prior decision IDs
from this phase. Start numbering after the highest existing ID. For example, if the previous run
produced D-CLARIFY-001 through D-CLARIFY-003, the retry must start at D-CLARIFY-004.

The orchestrator assists by including existing IDs in the retry prompt (e.g., "Previous decisions
D-CLARIFY-001 through D-CLARIFY-003 are already captured. Start new IDs at D-CLARIFY-004.").

WHEN TO OMIT THE BLOCK:

- If the agent's work was purely mechanical with no decisions (e.g., straightforward TDD cycle)
- If no ambiguity was resolved and no choices were made
- The block is REQUIRED for clarifier and planner, OPTIONAL for implementer and simplifier

TIMESTAMP FORMAT:

All timestamps use ISO 8601: `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2026-02-14T06:21:12Z`).
