#!/usr/bin/env bash
# Validate all skills have proper SKILL.md files and frontmatter
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

echo "=== Skill Loading Tests ==="

# All expected skills
SKILLS=(
  analyzing-codebases auditing-tdd-compliance brainstorming
  communicating-progress convergence-discipline documenting-decisions
  enforcing-tdd formatting-decisions gathering-requirements
  integrating-external-sources managing-branches-and-prs managing-work-items
  planning-technical-work recovering-from-failures reviewing-spec-compliance
  security-awareness simplifying-code systematic-debugging
  using-git-worktrees verifying-before-completion
)

echo ""
echo "--- Skill directories exist ---"
for skill in "${SKILLS[@]}"; do
  assert_dir_exists "skills/${skill}" "Skill dir ${skill} exists"
done

echo ""
echo "--- SKILL.md files exist ---"
for skill in "${SKILLS[@]}"; do
  assert_file_exists "skills/${skill}/SKILL.md" "${skill}/SKILL.md exists"
done

echo ""
echo "--- Required frontmatter fields ---"
for skill in "${SKILLS[@]}"; do
  assert_frontmatter_field "skills/${skill}/SKILL.md" "name" "${skill} has name"
  assert_frontmatter_field "skills/${skill}/SKILL.md" "description" "${skill} has description"
done

echo ""
echo "--- Skill names match directory names ---"
for skill in "${SKILLS[@]}"; do
  TOTAL=$((TOTAL + 1))
  if [[ -f "$PLUGIN_DIR/skills/${skill}/SKILL.md" ]]; then
    # Extract name from frontmatter (macOS-compatible sed)
    name=$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name: */, ""); print; exit}' "$PLUGIN_DIR/skills/${skill}/SKILL.md")
    if [[ "$name" == "$skill" ]]; then
      PASS=$((PASS + 1))
      echo -e "  ${GREEN}PASS${NC} ${skill} name matches directory"
    else
      FAIL=$((FAIL + 1))
      echo -e "  ${RED}FAIL${NC} ${skill} name mismatch: frontmatter='${name}' dir='${skill}'"
    fi
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}FAIL${NC} ${skill}/SKILL.md not found"
  fi
done

print_summary
