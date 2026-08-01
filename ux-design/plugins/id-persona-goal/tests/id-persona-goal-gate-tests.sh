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

## --- mandatory: gate-lib shared-behavior cases (core issue #72 migration) ---
mandatory_fail=0

_edit_payload() {
  # $1=file_path $2=old $3=new $4=replace_all(true/false)
  python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": sys.argv[1],
        "old_string": sys.argv[2],
        "new_string": sys.argv[3],
        "replace_all": sys.argv[4] == "true",
    },
}))
' "$1" "$2" "$3" "$4"
}

# 1) Edit replace_all:true replaces every occurrence.
content_multi_marker=$'# Interaction Design Record\n\n## Persona & Goal\n\n- **Jane, the returning shopper**: a repeat customer who orders weekly.\n  Goal: feel confident her reorder went through without re-checking her cart.\n\n## Task Flow\n\nsee task-flow doc\nPLACEHOLDER note one.\nPLACEHOLDER note two.\n'
td1="$(mktemp -d)"
mkdir -p "$td1/docs/specs"
: > "$td1/docs/specs/role-handoff-contract.md"
rel1="docs/issue-77/reports/interaction-design.md"
mkdir -p "$td1/$(dirname "$rel1")"
printf '%s' "$content_multi_marker" > "$td1/$rel1"
out1="$(mktemp)"
_edit_payload "$rel1" "PLACEHOLDER" "REPLACED" "true" | env CLAUDE_PROJECT_DIR="$td1" /bin/bash "$GATE" >"$out1" 2>&1
status1=$?
if [ "$status1" -eq 0 ]; then
  echo "PASS: mandatory: Edit replace_all replaces every occurrence"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: Edit replace_all replaces every occurrence (status=$status1)"
  cat "$out1" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -rf "$td1" "$out1"

# 2) MultiEdit honors per-edit replace_all (mix of true/false).
content_multi2=$'# Interaction Design Record\n\n## Persona & Goal\n\n- **Jane, the returning shopper**: a repeat customer who orders weekly.\n  Goal: feel confident her reorder went through without re-checking her cart.\n\n## Task Flow\n\nsee task-flow doc\nDUPX note one.\nDUPX note two.\nSINGLEX note three.\n'
td2="$(mktemp -d)"
mkdir -p "$td2/docs/specs"
: > "$td2/docs/specs/role-handoff-contract.md"
rel2="docs/issue-78/reports/interaction-design.md"
mkdir -p "$td2/$(dirname "$rel2")"
printf '%s' "$content_multi2" > "$td2/$rel2"
out2="$(mktemp)"
python3 -c '
import json, sys
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": sys.argv[1],
        "edits": [
            {"old_string": "DUPX", "new_string": "DY", "replace_all": True},
            {"old_string": "SINGLEX", "new_string": "SZ", "replace_all": False},
        ],
    },
}))
' "$rel2" | env CLAUDE_PROJECT_DIR="$td2" /bin/bash "$GATE" >"$out2" 2>&1
status2=$?
if [ "$status2" -eq 0 ]; then
  echo "PASS: mandatory: MultiEdit honors per-edit replace_all"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: MultiEdit honors per-edit replace_all (status=$status2)"
  cat "$out2" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -rf "$td2" "$out2"

# 3) Malformed JSON on stdin -> deny.
out3="$(mktemp)"
printf '{"tool_name": "Write", "tool_input": {' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" /bin/bash "$GATE" >"$out3" 2>&1
status3=$?
if [ "$status3" -eq 2 ]; then
  echo "PASS: mandatory: malformed JSON denies"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: malformed JSON denies (status=$status3)"
  cat "$out3" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -f "$out3"

# 3b) Empty stdin payload -> deny.
out3b="$(mktemp)"
printf '' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" /bin/bash "$GATE" >"$out3b" 2>&1
status3b=$?
if [ "$status3b" -eq 2 ]; then
  echo "PASS: mandatory: empty payload denies"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: empty payload denies (status=$status3b)"
  cat "$out3b" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -f "$out3b"

# 4) Kill switch set to an unrecognized value -> gate stays active (deny).
td4="$(mktemp -d)"
mkdir -p "$td4/docs/specs"
: > "$td4/docs/specs/role-handoff-contract.md"
rel4="docs/issue-42/reports/interaction-design.md"
mkdir -p "$td4/$(dirname "$rel4")"
out4="$(mktemp)"
_payload "$rel4" "$content_stub" | env CLAUDE_PROJECT_DIR="$td4" ID_PERSONA_GOAL_GATE_OFF="banana" /bin/bash "$GATE" >"$out4" 2>&1
status4=$?
rm -rf "$td4"
if [ "$status4" -eq 2 ]; then
  echo "PASS: mandatory: kill switch unrecognized value stays active"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: kill switch unrecognized value stays active (status=$status4)"
  cat "$out4" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -f "$out4"

# 5) Absolute file_path and "./"-prefixed file_path both match the same scope.
rel5="docs/issue-99/reports/interaction-design.md"
td5="$(mktemp -d)"
mkdir -p "$td5/docs/specs"
: > "$td5/docs/specs/role-handoff-contract.md"
mkdir -p "$td5/$(dirname "$rel5")"
out5a="$(mktemp)"
_payload "$td5/$rel5" "$content_full" | env CLAUDE_PROJECT_DIR="$td5" /bin/bash "$GATE" >"$out5a" 2>&1
status5a=$?
if [ "$status5a" -eq 0 ]; then
  echo "PASS: mandatory: absolute file_path matches scope"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: absolute file_path matches scope (status=$status5a)"
  cat "$out5a" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -f "$out5a"

out5b="$(mktemp)"
_payload "./$rel5" "$content_full" | env CLAUDE_PROJECT_DIR="$td5" /bin/bash "$GATE" >"$out5b" 2>&1
status5b=$?
rm -rf "$td5"
if [ "$status5b" -eq 0 ]; then
  echo "PASS: mandatory: ./-prefixed file_path matches scope"
  pass=$((pass + 1))
else
  echo "FAIL: mandatory: ./-prefixed file_path matches scope (status=$status5b)"
  cat "$out5b" >&2
  mandatory_fail=$((mandatory_fail + 1))
fi
rm -f "$out5b"

if [ "$mandatory_fail" -ne 0 ]; then
  echo ""
  echo "id-persona-goal-gate-tests: $mandatory_fail mandatory case(s) failed"
  exit 1
fi
## --- end mandatory cases ---

echo ""
echo "id-persona-goal-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
