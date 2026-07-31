#!/usr/bin/env bash
# Plain-bash test script for hooks/persona-goal-gate.sh (this repo's
# convention — see tests/deny-only-check.sh and tests/stub-check.sh —
# not bats). Cases per docs/issue-21/proposals/
# issue-21-interaction-design-gate-machine.md §6 for id-persona-goal.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/persona-goal-gate.sh"

pass=0
fail=0

_payload() {
  # $1=file_path $2=content
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
}))
' "$1" "$2"
}

_run_case() {
  # $1=name $2=rel_path $3=content $4=expected_status
  local name="$1" rel="$2" content="$3" expected="$4"
  local td
  td="$(mktemp -d)"
  mkdir -p "$td/docs/specs"
  : > "$td/docs/specs/role-handoff-contract.md"
  mkdir -p "$td/$(dirname "$rel")"
  local out_file
  out_file="$(mktemp)"
  _payload "$rel" "$content" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out_file" 2>&1
  local status=$?
  rm -rf "$td"
  if [ "$status" -eq "$expected" ]; then
    echo "PASS: $name (status=$status, expected=$expected)"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (status=$status, expected=$expected)"
    cat "$out_file" >&2
    fail=$((fail + 1))
  fi
  rm -f "$out_file"
}

# (a) full persona/goal block with a named persona and a distinct goal
# field -> allow.
content_full=$'# Interaction Design Record\n\n## Persona & Goal\n\n- **Jane, the returning shopper**: a repeat customer who orders weekly.\n  Goal: feel confident her reorder went through without re-checking her cart.\n\n## Task Flow\n\nsee task-flow doc\n'
_run_case "full persona/goal block -> allow" \
  "docs/issue-42/reports/interaction-design.md" "$content_full" 0

# (b) heading present, body blank/whitespace -> deny (stub).
content_stub=$'# Interaction Design Record\n\n## Persona & Goal\n\n   \n\n## Task Flow\n\nsee task-flow doc\n'
_run_case "heading present, blank body -> deny (stub)" \
  "docs/issue-42/reports/interaction-design.md" "$content_stub" 2

# (c) heading present but only a role label line, no separate goal
# field -> deny.
content_role_only=$'# Interaction Design Record\n\n## Persona & Goal\n\n- **Jane, the returning shopper**: a repeat customer who orders weekly.\n\n## Task Flow\n\nsee task-flow doc\n'
_run_case "role label only, no goal field -> deny" \
  "docs/issue-42/reports/interaction-design.md" "$content_role_only" 2

# (d) no persona/goal heading at all in the doc -> deny.
content_no_heading=$'# Interaction Design Record\n\n## Task Flow\n\nsee task-flow doc\n'
_run_case "no persona/goal heading -> deny" \
  "docs/issue-42/reports/interaction-design.md" "$content_no_heading" 2

# (e) write to an unrelated path -> allow regardless of content.
_run_case "unrelated path -> allow regardless of content" \
  "docs/issue-42/reports/pricing.md" "$content_no_heading" 0

echo ""
echo "id-persona-goal-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
