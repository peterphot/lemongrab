DECISION OUTPUT FORMAT FOR AGENT RESPONSES:

Agents capture decisions by appending a structured block at the end of their text output.
The orchestrator (lemongrab) extracts these blocks and appends them to docs/state/decisions.md.

FORMAT:

<!-- DECISIONS
- decision:
    id: D-{PHASE}-{NNN}
    phase: clarify | plan | implement | review | simplify
    who: user | claude
    what: "Short title"
    why: "Reasoning"
    alternatives: "Other options considered"
    context: "Question or situation that prompted this"
DECISIONS -->

PHASE PREFIXES FOR IDs:

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

WHEN TO OMIT THE BLOCK:

- If the agent's work was purely mechanical with no decisions (e.g., straightforward TDD cycle)
- If no ambiguity was resolved and no choices were made
- The block is REQUIRED for clarifier and planner, OPTIONAL for implementer and simplifier

Both agents and the orchestrator MUST read this file as the single source of truth for the format.
