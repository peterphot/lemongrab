---
name: running-verifications
description: Run verification scripts for lemongrab workflow gates. Use when the orchestrator or resume command needs to verify state consistency, requirements, plan structure, manifest coverage, or test integrity. Provides portable paths via CLAUDE_SKILL_DIR.
version: 1.0.0
---

# Running Verifications

This skill provides portable access to verification scripts used at workflow gates.

## Script Directory

All verification scripts live at:

```
${CLAUDE_SKILL_DIR}/scripts/
```

## Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `verify-state-consistency.sh` | Check task-status.json files exist on disk | `bash ${CLAUDE_SKILL_DIR}/scripts/verify-state-consistency.sh` |
| `verify-requirements.sh` | Check requirements doc completeness | `bash ${CLAUDE_SKILL_DIR}/scripts/verify-requirements.sh <requirements-file>` |
| `verify-plan-structure.sh` | Validate plan task structure | `bash ${CLAUDE_SKILL_DIR}/scripts/verify-plan-structure.sh <plan-file>` |
| `verify-manifest-coverage.sh` | Verify manifest covers all ACs | `bash ${CLAUDE_SKILL_DIR}/scripts/verify-manifest-coverage.sh <plan-file> <task-id> <manifest-file>` |
| `verify-test-integrity.sh` | Check test files unchanged by implementer | `bash ${CLAUDE_SKILL_DIR}/scripts/verify-test-integrity.sh <task-status-file> <task-id>` |

## When to Use

- **Resume**: Run `verify-state-consistency.sh` before resuming any workflow
- **After clarifier**: Run `verify-requirements.sh` to gate plan phase
- **After planner**: Run `verify-plan-structure.sh` to gate build phase
- **After test-writer**: Run `verify-manifest-coverage.sh` to gate implementer
- **After implementer**: Run `verify-test-integrity.sh` to gate reviewers

## Exit Codes

All scripts exit 0 on PASS, 1 on FAIL. Read the output for details on failures.
