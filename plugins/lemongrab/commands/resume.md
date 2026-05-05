---
description: Resume an interrupted TDD workflow
argument-hint: <feature name> [--plan-only]
allowed-tools: Read, Write, Edit, Bash, Glob, Task, AskUserQuestion
---

You are the workflow orchestrator resuming an interrupted workflow.

STEP 0: PARSE ARGUMENTS

Parse $ARGUMENTS for the `--plan-only` flag:
- If present: MODE_OVERRIDE = PLAN_ONLY, remove flag from arguments
- If absent: MODE_OVERRIDE = none (use mode from state file)

STEP 1: READ STATE

1. Read docs/state/current-phase.json
   - If not found: tell user "No workflow to resume. Use `/lemongrab:tdd <feature>` to start."
   - If found but feature doesn't match $ARGUMENTS: warn user and confirm
2. Activate the `running-verifications` skill, then run `verify-state-consistency.sh`
   - If FAIL: report inconsistencies to user, offer to re-run affected tasks
3. Read docs/state/task-status.json for task progress
4. Extract: phase, feature name, mode, workflow type
5. Apply mode override: if MODE_OVERRIDE is PLAN_ONLY, set mode to PLAN_ONLY in
   current-phase.json (overrides whatever was stored).

STEP 2: DISPATCH ON PHASE

Read the "phase" field from current-phase.json. Execute EXACTLY the action for that
phase value. Do NOT interpret the mode or make decisions — just follow the dispatch.

The --plan-only flag has NO effect on dispatch. It is stored in the state file and
only checked at TICKETS_COMPLETE. Every other phase executes identically regardless
of mode.

**If phase = CLARIFY_IN_PROGRESS:**
→ Re-launch clarifier (reads draft from docs/requirements/)

**If phase = CLARIFY_COMPLETE:**
→ Present REQUIREMENTS_REVIEW gate to user via AskUserQuestion

**If phase = DESIGN_IN_PROGRESS:**
→ Re-launch designer

**If phase = DESIGN_COMPLETE:**
→ Proceed to EXPLORE + PLAN

**If phase = PLAN_IN_PROGRESS:**
→ Re-launch planner with exploration context

**If phase = PLAN_COMPLETE:**
→ Present PLAN_APPROVAL gate to user via AskUserQuestion

**If phase = PLAN_APPROVED:**
→ Update phase to TICKETS_PENDING in current-phase.json, then fall through to TICKETS_PENDING

**If phase = TICKETS_PENDING:**
→ Present TICKET_SETUP gate to user via AskUserQuestion:
  "CHECKPOINT: TICKET_SETUP — Plan has X tasks. How would you like to track them?
  1. Linear tickets  2. Local tickets  3. No tickets — Choose [1] [2] [3]:"
→ If Linear: ask which team, launch ticket-manager
→ If Local: launch ticket-manager
→ If None: record tickets.enabled = false
→ Update phase to TICKETS_COMPLETE in current-phase.json
→ Then fall through to TICKETS_COMPLETE

**If phase = TICKETS_COMPLETE:**
→ Check the mode field in current-phase.json:
  - If PLAN_ONLY: present completion summary, update phase → COMPLETE, exit
  - If FULL: proceed to BRANCH_SETUP (including BRANCH_STRATEGY gate) → BUILD

**If phase = BRANCH_CREATED:**
→ Verify branch exists, proceed to BUILD
→ If tickets.branching = "per-task": verify integration branch exists on remote too

**If phase = BUILD_IN_PROGRESS:**
→ Re-read tickets.branching from task-status.json ("single" or "per-task") — this determines ALL branch behavior
→ Find current task from task-status.json, resume its TDD cycle
→ Verify feature branch exists: `git branch --list <branch>` then checkout
→ If task has tests but no implementation: launch implementer
→ If task has implementation but no review: launch reviewers
→ If task is complete: advance to next task
→ PER-TASK BRANCHING RESUME (if tickets.branching = "per-task"):
  Read tickets.taskBranches from task-status.json for each task:
  - If task branch exists but no PR created: push branch, create task PR, present TASK_PR gate
  - If task PR exists but status != "merged": present TASK_PR gate (merge or skip)
  - If task PR status = "merged": task is complete, advance to next task
  - If no task branch and task is incomplete: create task branch from integration branch,
    resume TDD cycle on that branch
  - Always ensure correct branch is checked out before resuming work

**If phase = BUILD_COMPLETE:**
→ Proceed to COHERENCE_REVIEW

**If phase = COHERENCE_REVIEW_IN_PROGRESS:**
→ Re-launch coherence-reviewer

**If phase = COHERENCE_REVIEW_COMPLETE:**
→ Present PRE_PR gate

**If phase = PR_CREATED:**
→ Verify PR exists: `gh pr view <pr-number> --json state,url`
→ Re-print the manual-next-steps guidance:
   `/lemongrab:pr-review <N>` and `/lemongrab:resolve-feedback` are post-workflow
   manual commands. They are NOT resumed by this command.
→ Branch on workflow mode (read `tickets.multiTicket.enabled` and `tickets.branching`
   from `docs/state/task-status.json`):
   - If `tickets.multiTicket.enabled == true` OR `tickets.branching == "per-task"`:
     advance to MERGE_GATE_WAITING (orchestrator MULTI_TICKET step `g` requires the
     per-ticket merge gate before continuing).
   - Otherwise: advance to DOCUMENT_IN_PROGRESS (orchestrator step 14).

**If phase = MERGE_GATE_WAITING:**
→ Re-present merge gate to user (PR already created)
→ Verify PR merge status via `gh pr view <number> --json state`

**If phase = DOCUMENT_IN_PROGRESS:**
→ Re-launch documenter

**If phase = DOCUMENT_COMPLETE:**
→ Present final summary

Follow the same state machine loop, user gates, and verification scripts as
`/lemongrab:tdd`. All checkpoints (REQUIREMENTS_REVIEW, PLAN_APPROVAL, PRE_SIMPLIFY,
FIRST_CYCLE_REVIEW, PRE_PR) still apply on resume.

CRITICAL RULES:
- NEVER skip user gates on resume — they are just as mandatory as on first run
- NEVER re-do completed work — check task-status.json before launching agents
- ALWAYS verify state consistency before resuming
- The --plan-only flag does NOT mean "the workflow is done" — it only affects behavior at TICKETS_COMPLETE
- If the phase is TICKETS_PENDING, you MUST ask the user about ticket tracking before doing anything else
