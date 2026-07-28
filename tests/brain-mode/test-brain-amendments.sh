#!/usr/bin/env bash
# Test: Brain-mode hook behavior and skill amendments
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_SCRIPT="$REPO_ROOT/hooks/session-start"

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"

    if printf '%s' "$haystack" | grep -Fq "$needle"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $needle"
        exit 1
    fi
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local label="$3"

    if [ "$actual" = "$expected" ]; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        exit 1
    fi
}

assert_file_contains() {
    local file="$1"
    local needle="$2"
    local label="$3"

    if grep -Fq "$needle" "$file"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    File: $file"
        echo "    Missing: $needle"
        exit 1
    fi
}

run_hook_from() {
    local dir="$1"

    (
        cd "$dir"
        bash "$HOOK_SCRIPT"
    )
}

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

echo "=== Test: Brain-mode amendments ==="
echo ""

echo "Test 1: Hook injects context outside Brain projects..."
plain_project="$TEST_ROOT/plain-project"
mkdir -p "$plain_project/src"
plain_output="$(run_hook_from "$plain_project/src")"
assert_contains "$plain_output" '"additionalContext":' "Uses SDK-standard bootstrap field by default"
assert_contains "$plain_output" 'You have superpowers.' "Includes bootstrap context"
echo ""

echo "Test 2: Hook suppresses bootstrap at Brain project root..."
brain_project="$TEST_ROOT/brain-project"
mkdir -p "$brain_project/.brain" "$brain_project/src"
brain_root_output="$(run_hook_from "$brain_project")"
assert_equals "$brain_root_output" '{}' "Returns empty JSON at Brain root"
echo ""

echo "Test 3: Hook suppresses bootstrap from nested Brain subdirectories..."
brain_nested_output="$(run_hook_from "$brain_project/src")"
assert_equals "$brain_nested_output" '{}' "Returns empty JSON below Brain root"
echo ""

echo "Test 4: Override bypasses Brain suppression..."
brain_override_output="$(
    cd "$brain_project/src"
    SUPERPOWERS_IGNORE_BRAIN=1 bash "$HOOK_SCRIPT"
)"
assert_contains "$brain_override_output" '"additionalContext":' "Override restores bootstrap field"
assert_contains "$brain_override_output" 'You have superpowers.' "Override restores bootstrap content"
echo ""

echo "Test 5: using-superpowers declares Brain bootstrap precedence..."
using_superpowers="$REPO_ROOT/skills/using-superpowers/SKILL.md"
assert_file_contains "$using_superpowers" '<BRAIN-MODE>' "Has Brain-mode section"
assert_file_contains "$using_superpowers" 'confirm `brain_session` has been called this turn' "Requires brain_session before Superpowers routing"
echo ""

echo "Test 6: writing-plans documents Brain plan lifecycle..."
writing_plans="$REPO_ROOT/skills/writing-plans/SKILL.md"
assert_file_contains "$writing_plans" '_Temporal/Plans/yyyy-mm/yyyymmdd-plan~{Title}.md' "Uses Brain plan path with month subfolder"
assert_file_contains "$writing_plans" 'brain_create(resource="artefact", type="plans", title="<feature name>")' "Creates plans via brain_create"
assert_file_contains "$writing_plans" 'frontmatter={"status": "approved"}' "Marks approved plans in Brain mode"
assert_file_contains "$writing_plans" '`approved` → `implementing` → `completed`' "Describes downstream status transitions"
assert_file_contains "$writing_plans" 'a plan whose body is Brain-template-only cannot be executed at all: no task brief, no dispatch' "States the plan-body contract (### Task N headings etc.) that task-brief depends on"
echo ""

echo "Test 7: executing-plans documents Brain plan execution state..."
executing_plans="$REPO_ROOT/skills/executing-plans/SKILL.md"
assert_file_contains "$executing_plans" 'brain_list(type="plans")' "Enumerates Brain plans by type key"
assert_file_contains "$executing_plans" 'brain_search(query="<subject>", type="temporal/plans")' "Searches Brain plans by canonical type"
assert_file_contains "$executing_plans" 'frontmatter={"status": "implementing"}' "Marks implementing status"
assert_file_contains "$executing_plans" 'frontmatter={"status": "completed"}' "Marks completed status"
echo ""

echo "Test 8: review/execution skills use Brain plan paths consistently..."
requesting_review="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
subagent_dev="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
assert_file_contains "$requesting_review" '_Temporal/Plans/yyyy-mm/yyyymmdd-plan~{Title}.md' "Review skill documents Brain plan path"
assert_file_contains "$requesting_review" 'PLAN_OR_REQUIREMENTS: Task 2 from _Temporal/Plans/2026-05/20260504-plan~Deployment plan.md' "Review example uses Brain plan path"
assert_file_contains "$subagent_dev" '_Temporal/Plans/yyyy-mm/yyyymmdd-plan~{Title}.md' "Subagent workflow documents Brain plan path"
assert_file_contains "$subagent_dev" 'The workflow is identical otherwise — just substitute the plan path.' "Subagent example workflow notes Brain path substitution"
echo ""

echo "=== All Brain-mode amendment tests passed ==="
