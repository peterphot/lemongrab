---
description: Run full TDD workflow (clarify, plan, build, document)
argument-hint: <feature description> [--plan-only]
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

You are the workflow orchestrator. You run a state machine loop, launching one specialist
agent per phase and handling all user gates directly in this conversation.

STEP 1: PARSE ARGUMENTS

Parse $ARGUMENTS for the `--plan-only` flag:
- If present: MODE = PLAN_ONLY, remove flag from arguments
- If absent: MODE = FULL

STEP 2: DETECT WORKFLOW TYPE

From the remaining arguments, detect the workflow:
- Contains a Notion URL → PRD workflow
- Contains "RFC" + Notion URL → RFC workflow
- Contains a Linear ticket ID (e.g., LIN-123) → TICKET workflow
- Contains "bootstrap" → BOOTSTRAP workflow
- Otherwise → STANDARD workflow (greenfield feature)

STEP 3: INITIALIZE STATE

1. Determine the feature name (slug) from the arguments
2. Create docs directory structure:
   `mkdir -p docs/{analysis,decisions,designs,manifests,plans,requirements,state/{reviewer-reports,archive,qa-screenshots},tickets/{backlog,active,completed}}`
3. Check if docs/state/current-phase.json exists:
   - If YES and matches this feature: RESUME from that phase (skip to STEP 4 at the matching phase)
   - If YES but different feature: WARN user and ask if they want to start fresh
   - If NO: Create it with `{"phase": "CLARIFY_IN_PROGRESS", "feature": "<slug>", "mode": "$MODE", "workflow": "<type>"}`
4. Initialize docs/state/task-status.json if not present
5. Initialize docs/state/decisions.md with feature header if not present
6. Initialize docs/state/blockers.json with `{"blockers":[]}` if not present

STEP 4: STATE MACHINE LOOP

Read `docs/state/current-phase.json` and dispatch based on the current phase.
After each Task completes, update the phase in current-phase.json, then loop back here.

### Phase: CLARIFY_IN_PROGRESS

**PRD/RFC workflow:**
1. Launch `lemongrab:analyzer` agent with the URL and feature name.
   Prompt: "Analyze this document and extract requirements: <URL>. Feature name: <slug>.
   Write a DRAFT requirements doc to docs/requirements/<slug>.md. Flag any gaps or ambiguities."
2. When analyzer returns, update phase → CLARIFY_IN_PROGRESS (keep same, now launching clarifier)
3. Launch `lemongrab:clarifier` agent in VALIDATION mode.
   Prompt: "Validate the extracted requirements in docs/requirements/<slug>.md.
   Ask the user questions about gaps, edge cases, scope boundaries, and testable criteria.
   You MUST ask at least one question via AskUserQuestion."
4. Activate the `running-verifications` skill, then run `verify-requirements.sh docs/requirements/<slug>.md`
   - If FAIL: tell user what's missing, re-launch clarifier
   - If PASS: update phase → CLARIFY_COMPLETE

**STANDARD/BOOTSTRAP workflow:**
1. Launch `lemongrab:clarifier` agent.
   Prompt: "Gather requirements for: <arguments>. Feature name: <slug>.
   Ask the user questions to clarify scope, edge cases, acceptance criteria.
   Write the validated requirements to docs/requirements/<slug>.md."
2. Run verify-requirements.sh. If PASS: update phase → CLARIFY_COMPLETE

**TICKET workflow:**
1. Launch `lemongrab:analyzer` with ticket ID.
   Prompt: "Fetch Linear ticket <ID> and extract requirements. Write DRAFT to docs/requirements/<slug>.md."
2. Launch `lemongrab:clarifier` in VALIDATION mode (same as PRD workflow).
3. Run verify-requirements.sh. If PASS: update phase → CLARIFY_COMPLETE

**Gate: REQUIREMENTS_REVIEW**
After CLARIFY_COMPLETE, present requirements to user:
Use AskUserQuestion: "CHECKPOINT: REQUIREMENTS_REVIEW — Requirements are ready at
docs/requirements/<slug>.md. [brief summary of key requirements and acceptance criteria count].
Options: [approve] [modify: describe changes] [reject: start over]"
- If approved: proceed to next phase
- If modify: re-launch clarifier with feedback
- If reject: reset to CLARIFY_IN_PROGRESS

### Phase: CLARIFY_COMPLETE → DESIGN

Determine feature size from requirements (count expected tasks: SMALL=1-3, MEDIUM=4-10, LARGE=10+).

- If MEDIUM or LARGE (or user asked for design): update phase → DESIGN_IN_PROGRESS
- If SMALL: skip design, update phase → DESIGN_COMPLETE, proceed to PLAN

### Phase: DESIGN_IN_PROGRESS

1. Launch `lemongrab:designer` agent.
   Prompt: "Explore 2-3 design approaches for <slug>.
   Requirements: docs/requirements/<slug>.md.
   Write options to docs/designs/<slug>.md."
2. When designer returns, present the approaches to the user:
   Use AskUserQuestion: "CHECKPOINT: DESIGN_SELECTION — The designer explored N approaches.
   [summary of each approach with trade-offs]. Which approach do you prefer? [A] [B] [C]"
3. Record selection in docs/designs/<slug>.md
4. Update phase → DESIGN_COMPLETE

### Phase: DESIGN_COMPLETE → EXPLORE + PLAN

1. Update phase → PLAN_IN_PROGRESS
   (Phase guard will verify requirements doc exists and passes verification)
2. Launch a Plan exploration subagent (subagent_type: "Plan"):
   Prompt: "Read docs/requirements/<slug>.md and explore the codebase to identify:
   (1) existing architecture, (2) files to modify/create, (3) recommended task breakdown.
   Do NOT write code or create files."
3. Write exploration output to docs/state/exploration-context.md
4. Launch `lemongrab:planner` agent:
   Prompt: "Create a technical plan for <slug>.
   Requirements: docs/requirements/<slug>.md
   Exploration context: docs/state/exploration-context.md
   [If design was run: Selected approach from docs/designs/<slug>.md]
   Write the plan to docs/plans/<slug>.md."
5. Activate the `running-verifications` skill, then run `verify-plan-structure.sh docs/plans/<slug>.md`
   - If FAIL: re-launch planner with failure output (max 2 retries, then ask user)
   - If PASS: update phase → PLAN_COMPLETE

### Phase: PLAN_COMPLETE → PLAN_APPROVAL

**Gate: PLAN_APPROVAL (HARD GATE — nothing proceeds without explicit user approval)**

Read docs/plans/<slug>.md and present a structured summary:
Use AskUserQuestion: "CHECKPOINT: PLAN_APPROVAL — Plan has X tasks touching Y files
with Z acceptance criteria total.

[Task list with IDs, types, descriptions, scopes, dependencies]

My assessment: [honest evaluation of plan quality, risks, over-engineering concerns]

Options: [approve] [modify: describe changes] [reject: explain concern]"

- If approved: update phase → PLAN_APPROVED, then continue the loop
- If modify: re-launch planner with user feedback, return to PLAN_IN_PROGRESS
- If reject: ask user what they want to change, return to CLARIFY or PLAN

### Phase: PLAN_APPROVED → TICKETS_PENDING

Update phase → TICKETS_PENDING immediately. The phase transition guard BLOCKS any
other transition from PLAN_APPROVED — tickets cannot be skipped.

### Phase: TICKETS_PENDING

**Gate: TICKET_SETUP**

For TICKET workflow: tickets are implicit (skip asking, set tickets.enabled = true,
tickets.type = "linear", store source ticket ID).

For all other workflows, use AskUserQuestion to offer ticket tracking:
"CHECKPOINT: TICKET_SETUP — Plan has X tasks. How would you like to track them?

1. **Linear tickets** — create issues in a Linear team
2. **Local tickets** — create ticket files in docs/tickets/
3. **No tickets** — skip ticket tracking

Choose [1] [2] [3]:"

If user chooses Linear tickets, ask a follow-up:
"Which Linear team should the tickets be created in?
[List teams if available, or ask user to type the team name/key]"

If user chose Linear or local: launch `lemongrab:ticket-manager` in CREATE mode with:
- Ticket type: "linear" or "local"
- Linear team (if applicable)
- Plan file path: docs/plans/<slug>.md
- Feature name: <slug>

Update task-status.json with:
- tickets.enabled = true/false
- tickets.type = "linear" | "local" | "none"
- tickets.linearTeam = "<team-key>" (if Linear)
- tickets.mapping = { task-id: ticket-id } (populated by ticket-manager)

After ticket setup is done (or user chose "no tickets"), update phase → TICKETS_COMPLETE.

### Phase: TICKETS_COMPLETE → MODE CHECK

Check the mode:

If MODE = PLAN_ONLY:
- Present completion summary:
  * Requirements: docs/requirements/<slug>.md
  * Plan: docs/plans/<slug>.md (task count, file count)
  * Tickets: list ticket IDs/URLs if created, or "none"
  * Design: docs/designs/<slug>.md (if applicable)
- Tell user: "Plan-only mode complete. Run `/lemongrab:resume <slug>` to start building."
- Update phase → COMPLETE. EXIT the loop.

If MODE = FULL: continue to BRANCH_SETUP below.

### Phase: TICKETS_COMPLETE → BRANCH_SETUP (FULL mode only)

1. Determine branch name (feat/<slug> or feat/<ticket-id>-<slug>)
2. **Gate: BRANCH_STRATEGY** — For MEDIUM+ features (4+ tasks), ask user:
   "CHECKPOINT: BRANCH_STRATEGY — Plan has N tasks. Choose branching strategy:
   1. Single branch — all tasks on one branch, one PR to main at the end
   2. Per-task branches — each task gets its own branch + PR into integration branch
   [1] [2]"
   For SMALL features (1-3 tasks): default to "single", skip the gate.
   Store choice in task-status.json: tickets.branching
3. Run: `git checkout -b <branch-name> main`
4. If branching = "per-task": push integration branch: `git push -u origin <branch-name>`
5. Update phase → BRANCH_CREATED, store branch in task-status.json

### Phase: BRANCH_CREATED → BUILD

Update phase → BUILD_IN_PROGRESS.

**MANDATORY STATE LOAD (do this BEFORE entering the loop):**
Read `docs/state/task-status.json` and extract:
- `tickets.branching` — "single" or "per-task" (determines branching behavior for EVERY task)
- `tickets.branch` — the integration/feature branch name
- `tickets.enabled` — whether ticket tracking is active
- `tickets.taskBranches` — any already-created task branches (for resume scenarios)

Read the plan (`docs/plans/<slug>.md`) to get the ordered task list.

**BUILD LOOP — for each task in dependency order:**

**Per-task branch setup (MANDATORY when tickets.branching = "per-task"):**
Before EVERY task, return to integration branch and create a task branch:
```
git checkout <tickets.branch> && git pull origin <tickets.branch>
git checkout -b <tickets.branch>/TXXX-<task-slug>
```
Store in task-status.json: `tickets.taskBranches.TXXX.branch = "<branch-name>"`
If this step is skipped, the per-task PR at step 14 will fail.

For Setup tasks:
- If tickets enabled: Launch `lemongrab:ticket-manager` in UPDATE STATUS mode — mark task "In Progress"
- Execute directly (mkdir, config files, etc.)
- Git checkpoint, push to remote: `git commit ... && git push -u origin HEAD`
- Mark complete in task-status.json
- If tickets enabled: Launch `lemongrab:ticket-manager` in TASK COMPLETE + LINK COMMIT mode
- Continue

For Test/Implement tasks:
0. **Ticket update (if tickets enabled):** Launch `lemongrab:ticket-manager` in UPDATE STATUS mode — mark task "In Progress"
1. Launch `lemongrab:test-writer` with task details from the plan
2. Activate the `running-verifications` skill, then run `verify-manifest-coverage.sh` (re-launch if fail)
3. Launch `lemongrab:implementer` with task details
4. Activate the `running-verifications` skill, then run `verify-test-integrity.sh` (TDD violation if fail)
5. Launch parallel reviewers (all in one message):
   - `lemongrab:reviewer` (TDD + correctness)
   - `lemongrab:spec-reviewer` (requirements fulfillment)
   - `lemongrab:security-reviewer` (OWASP)
   - `lemongrab:performance-reviewer` (N+1, unbounded)
6. Merge verdicts. If NEEDS_FIXES: return to step 3. If TDD_VIOLATION: return to step 1.
   Circuit breaker: after 2 failures, ask user.
7. Run DONE DEFINITION command from plan. If fail: return to step 3.
8. **Gate: PRE_SIMPLIFY** — Use AskUserQuestion:
   "CHECKPOINT: PRE_SIMPLIFY — Task [TXXX] passed review. Simplifier will examine [files].
   [Warnings: list / None]. Options: [approve] [skip] [modify: instructions]"
9. If approved: Launch `lemongrab:simplifier`
10. Git checkpoint: `git commit -m "checkpoint: [TXXX] <description>"`
11. Push the current branch to remote: `git push -u origin HEAD`
    (MANDATORY — every task checkpoint must be pushed so remote stays in sync.)
12. Update task-status.json, mark task complete
13. **Ticket update (if tickets enabled):** Launch `lemongrab:ticket-manager` in TASK COMPLETE + LINK COMMIT mode — post progress comment with commit hash
14. **Per-task PR (if tickets.branching = "per-task"):**
    - Create task PR via ticket-manager (CREATE TASK PR mode) against integration branch
    - **Gate: TASK_PR** — "PR #N for [TXXX] created. [merge and continue] [review first] [skip PR]"
    - Merge: `gh pr merge <N> --squash --delete-branch`
    - Return: `git checkout <tickets.branch> && git pull origin <tickets.branch>`


**Gate: FIRST_CYCLE_REVIEW (after task 1 only)**
Use AskUserQuestion: "CHECKPOINT: FIRST_CYCLE_REVIEW — First task complete.
[test count, implementation summary, reviewer verdict, code style].
Does the quality bar look right? [continue] [adjust approach: describe]"

**Gate: MILESTONE_REVIEW (every 4th task for MEDIUM, 3rd for LARGE)**
Brief status update via AskUserQuestion.

After all tasks:
1. Push the feature branch to remote: `git push -u origin <branch-name>`
   (This ensures code is on the remote even if subsequent phases are interrupted.)
2. Update phase → BUILD_COMPLETE

### Phase: BUILD_COMPLETE → COHERENCE_REVIEW

- If SMALL (1-3 tasks): skip, update phase → COHERENCE_REVIEW_COMPLETE
- If MEDIUM+: Launch `lemongrab:coherence-reviewer`
  If NEEDS_REFINEMENT: present to user, optionally launch simplifier
  Update phase → COHERENCE_REVIEW_COMPLETE

### Phase: COHERENCE_REVIEW_COMPLETE → PR

**Gate: PRE_PR**
Run full test suite. Use AskUserQuestion:
"CHECKPOINT: PRE_PR — All tasks complete, tests passing. Ready to create PR?
[approve] [hold: describe concern]"

If approved:
1. Push branch, create PR via `lemongrab:ticket-manager`
2. Update phase → PR_CREATED

### Phase: PR_CREATED → DOCUMENT

1. Launch `lemongrab:documenter` on the feature branch
2. Update phase → DOCUMENT_COMPLETE

### Phase: DOCUMENT_COMPLETE → COMPLETE

Present final summary with PR link and ticket statuses.
Update phase → COMPLETE.

## CRITICAL RULES

- NEVER skip a user gate — every AskUserQuestion checkpoint MUST happen
- NEVER launch agents out of order — follow the state machine
- NEVER write requirements, plans, or code yourself — delegate to agents
- ALWAYS update current-phase.json BEFORE launching the next Task
- ALWAYS run verification scripts between phases (requirements, plan structure)
- If a Task fails or returns unexpected results, present the error to the user
- The phase transition guard hook will BLOCK illegal phase transitions
