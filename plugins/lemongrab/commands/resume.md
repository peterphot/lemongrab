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
2. Run: `bash plugins/lemongrab/hooks/scripts/verify-state-consistency.sh`
   - If FAIL: report inconsistencies to user, offer to re-run affected tasks
3. Read docs/state/task-status.json for task progress
4. Extract: phase, feature name, mode, workflow type
5. Apply mode override: if MODE_OVERRIDE is PLAN_ONLY, set mode to PLAN_ONLY in
   current-phase.json (overrides whatever was stored). This lets users resume in
   plan-only mode even if the original run didn't set it, or switch from FULL to
   PLAN_ONLY to stop after tickets.

STEP 2: RESUME

Enter the state machine loop defined in the `/lemongrab:tdd` command at the phase
read from current-phase.json. Use the resume table below to determine the entry point:

| Phase in current-phase.json | Resume Point |
|---|---|
| CLARIFY_IN_PROGRESS | Re-launch clarifier (reads draft from docs/requirements/) |
| CLARIFY_COMPLETE | Present REQUIREMENTS_REVIEW gate to user |
| DESIGN_IN_PROGRESS | Re-launch designer |
| DESIGN_COMPLETE | Proceed to EXPLORE + PLAN |
| PLAN_IN_PROGRESS | Re-launch planner with exploration context |
| PLAN_COMPLETE | Present PLAN_APPROVAL gate to user |
| PLAN_APPROVED | Proceed to TICKET_SETUP (tickets come before PLAN_ONLY exit) |
| BRANCH_CREATED | Verify branch exists, proceed to BUILD |
| BUILD_IN_PROGRESS | Find current task from task-status.json, resume its TDD cycle |
| BUILD_COMPLETE | Proceed to COHERENCE_REVIEW |
| COHERENCE_REVIEW_IN_PROGRESS | Re-launch coherence-reviewer |
| COHERENCE_REVIEW_COMPLETE | Present PRE_PR gate |
| PR_CREATED | Proceed to DOCUMENT |
| DOCUMENT_IN_PROGRESS | Re-launch documenter |
| DOCUMENT_COMPLETE | Present final summary |

For BUILD_IN_PROGRESS resumes:
- Verify feature branch exists: `git branch --list <branch>` then checkout
- Read task-status.json to find current task and its sub-step
- If task has tests but no implementation: launch implementer
- If task has implementation but no review: launch reviewers
- If task is complete: advance to next task

Follow the same state machine loop, user gates, and verification scripts as
`/lemongrab:tdd`. All checkpoints (REQUIREMENTS_REVIEW, PLAN_APPROVAL, PRE_SIMPLIFY,
FIRST_CYCLE_REVIEW, PRE_PR) still apply on resume.

CRITICAL RULES:
- NEVER skip user gates on resume — they are just as mandatory as on first run
- NEVER re-do completed work — check task-status.json before launching agents
- ALWAYS verify state consistency before resuming
