#!/usr/bin/env bash
# Validate state contracts: agents reference consistent file paths and phase values
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

echo "=== State Contract Tests ==="

echo ""
echo "--- Orchestrator defines canonical phase values ---"
assert_file_contains "agents/lemongrab.md" "CLARIFY_IN_PROGRESS" "Has CLARIFY_IN_PROGRESS phase"
assert_file_contains "agents/lemongrab.md" "CLARIFY_COMPLETE" "Has CLARIFY_COMPLETE phase"
assert_file_contains "agents/lemongrab.md" "PLAN_IN_PROGRESS" "Has PLAN_IN_PROGRESS phase"
assert_file_contains "agents/lemongrab.md" "PLAN_COMPLETE" "Has PLAN_COMPLETE phase"
assert_file_contains "agents/lemongrab.md" "PLAN_APPROVED" "Has PLAN_APPROVED phase"
assert_file_contains "agents/lemongrab.md" "BUILD_IN_PROGRESS" "Has BUILD_IN_PROGRESS phase"
assert_file_contains "agents/lemongrab.md" "BUILD_COMPLETE" "Has BUILD_COMPLETE phase"
assert_file_contains "agents/lemongrab.md" "PR_CREATED" "Has PR_CREATED phase"
assert_file_contains "agents/lemongrab.md" "DOCUMENT_IN_PROGRESS" "Has DOCUMENT_IN_PROGRESS phase"
assert_file_contains "agents/lemongrab.md" "DOCUMENT_COMPLETE" "Has DOCUMENT_COMPLETE phase"
assert_file_contains "agents/lemongrab.md" "COMPLETE" "Has COMPLETE phase"

echo ""
echo "--- Orchestrator has design phase values ---"
assert_file_contains "agents/lemongrab.md" "DESIGN_IN_PROGRESS" "Has DESIGN_IN_PROGRESS phase"
assert_file_contains "agents/lemongrab.md" "DESIGN_COMPLETE" "Has DESIGN_COMPLETE phase"

echo ""
echo "--- Agents reference correct state paths ---"
assert_file_contains "agents/lemongrab.md" "docs/state/current-phase.json" "Orchestrator refs current-phase.json"
assert_file_contains "agents/lemongrab.md" "docs/state/task-status.json" "Orchestrator refs task-status.json"
assert_file_contains "agents/lemongrab.md" "docs/state/decisions.md" "Orchestrator refs decisions.md"
assert_file_contains "agents/lemongrab.md" "docs/state/incidents.json" "Orchestrator refs incidents.json"
assert_file_contains "agents/lemongrab.md" "docs/state/reviewer-reports/" "Orchestrator refs reviewer-reports"

echo ""
echo "--- Reviewer agents produce reports ---"
assert_file_contains "agents/reviewer.md" "Pass/Fail Matrix" "TDD reviewer produces matrix"
assert_file_contains "agents/spec-reviewer.md" "Requirements Compliance Matrix" "Spec reviewer produces matrix"

echo ""
echo "--- Workflow ordering references ---"
assert_file_contains "agents/lemongrab.md" "CLARIFY" "Workflow includes CLARIFY"
assert_file_contains "agents/lemongrab.md" "DESIGN" "Workflow includes DESIGN"
assert_file_contains "agents/lemongrab.md" "PLAN" "Workflow includes PLAN"
assert_file_contains "agents/lemongrab.md" "BUILD" "Workflow includes BUILD"
assert_file_contains "agents/lemongrab.md" "DOCUMENT" "Workflow includes DOCUMENT"

echo ""
echo "--- Assumption markers in key agents ---"
assert_file_contains "agents/clarifier.md" "ASSUMPTION" "Clarifier has assumption markers"
assert_file_contains "agents/planner.md" "ASSUMPTION" "Planner has assumption markers"

print_summary
