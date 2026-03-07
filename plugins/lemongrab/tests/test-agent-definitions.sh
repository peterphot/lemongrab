#!/usr/bin/env bash
# Validate all agent definitions have required frontmatter and structure
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

echo "=== Agent Definition Tests ==="

# All expected agents
AGENTS=(
  lemongrab clarifier planner designer implementer test-writer
  reviewer spec-reviewer security-reviewer performance-reviewer
  simplifier documenter qa-engineer analyzer ticket-manager
)

echo ""
echo "--- Agent files exist ---"
for agent in "${AGENTS[@]}"; do
  assert_file_exists "agents/${agent}.md" "Agent ${agent} exists"
done

echo ""
echo "--- Required frontmatter fields ---"
for agent in "${AGENTS[@]}"; do
  assert_frontmatter_field "agents/${agent}.md" "name" "${agent} has name"
  assert_frontmatter_field "agents/${agent}.md" "description" "${agent} has description"
  assert_frontmatter_field "agents/${agent}.md" "tools" "${agent} has tools"
  assert_frontmatter_field "agents/${agent}.md" "model" "${agent} has model"
done

echo ""
echo "--- Disk grounding prerequisite ---"
# All agents except lemongrab should have READ FROM DISK
GROUNDED_AGENTS=(
  clarifier planner designer implementer test-writer
  reviewer spec-reviewer security-reviewer performance-reviewer
  simplifier documenter qa-engineer analyzer ticket-manager
)
for agent in "${GROUNDED_AGENTS[@]}"; do
  assert_file_contains "agents/${agent}.md" "READ FROM DISK" "${agent} has disk grounding"
done

echo ""
echo "--- Agents with Write tool self-persist ---"
WRITE_AGENTS=(test-writer implementer simplifier documenter qa-engineer)
for agent in "${WRITE_AGENTS[@]}"; do
  assert_file_contains "agents/${agent}.md" "task-status.json" "${agent} references task-status.json"
done

print_summary
