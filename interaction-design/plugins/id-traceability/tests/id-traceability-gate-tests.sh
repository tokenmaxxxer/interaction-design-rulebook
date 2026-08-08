#!/usr/bin/env bash
# Plain-bash test spec for id-traceability/hooks/traceability-gate.sh,
# per this repo's tests/ convention (deny-only-check.sh, stub-check.sh —
# no bats).
#
# Usage: id-traceability-gate-tests.sh
set -uo pipefail

GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)/traceability-gate.sh"
rc=0

run_gate() {
  local file_path="$1" content="$2" td
  td="$(mktemp -d)"
  git init -q "$td"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' \
    "$file_path" "$content" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  local status=$?
  rm -rf "$td"
  echo "$status"
}

json_str() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

check() {
  local name="$1" expect="$2" got="$3"
  if [ "$got" = "$expect" ]; then
    echo "ok - $name"
  else
    echo "FAIL - $name (expected exit $expect, got $got)" >&2
    rc=1
  fi
}

REC="docs/issue-999/reports/interaction-design.md"

# (a) heading with spec-only statement and scope-growth field (even "none") -> allow
content_a='# Traceability and scope growth

This deliverable is spec-only: output is specification, never src/ code.

- Scope growth: none
- Feedback: inline validation message on submit failure
'
got="$(run_gate "$REC" "$(json_str "$content_a")")"
check "a: full record allows" 0 "$got"

# (a2) spec-only + scope-growth present, feedback missing -> deny
content_a2='# Traceability and scope growth

This deliverable is spec-only: output is specification, never src/ code.

- Scope growth: none
'
got="$(run_gate "$REC" "$(json_str "$content_a2")")"
check "a2: missing feedback field denies" 2 "$got"

# (b) spec-only present, scope-growth field missing -> deny
content_b='# Traceability

This deliverable is spec-only: output is specification, never src/ code.

No scope field mentioned here at all.
'
got="$(run_gate "$REC" "$(json_str "$content_b")")"
check "b: missing scope-growth field denies" 2 "$got"

# (c) scope-growth present, spec-only missing -> deny
content_c='# Traceability

- Scope growth: none

No boundary statement present here.
'
got="$(run_gate "$REC" "$(json_str "$content_c")")"
check "c: missing spec-only statement denies" 2 "$got"

# (d) heading present, blank body -> deny (stub)
content_d='# Traceability

'
got="$(run_gate "$REC" "$(json_str "$content_d")")"
check "d: blank body (stub) denies" 2 "$got"

# (e) no heading -> deny
content_e='# Some other section

This deliverable is spec-only.

- Scope growth: none
'
got="$(run_gate "$REC" "$(json_str "$content_e")")"
check "e: no heading denies" 2 "$got"

# (f) unrelated write path -> allow (gate not applicable)
got="$(run_gate "docs/issue-999/reports/unrelated.md" "$(json_str "no gate content at all")")"
check "f: unrelated path allows (not this gate's surface)" 0 "$got"

## --- mandatory additional cases (Edit/MultiEdit reconstruction, malformed
## JSON, kill switch, path scoping) ---
mrc=0
mcheck() {
  local name="$1" expect="$2" got="$3"
  if [ "$got" = "$expect" ]; then
    echo "ok - $name"
  else
    echo "FAIL - $name (expected exit $expect, got $got)" >&2
    mrc=1
  fi
}

# 1: Edit replace_all:true replaces every occurrence
mtd="$(mktemp -d)"
git init -q "$mtd"
mkdir -p "$mtd/docs/issue-999/reports"
content_edit_base='# Traceability and scope growth

This deliverable is spec-only: output is specification, never src/ code.
BENIGN_MARKER here.
- Scope growth: none
- Feedback: inline validation message
BENIGN_MARKER again.
'
printf '%s' "$content_edit_base" > "$mtd/docs/issue-999/reports/interaction-design.md"
edit_payload=$(python3 -c '
import json
ti = {
    "file_path": "docs/issue-999/reports/interaction-design.md",
    "old_string": "BENIGN_MARKER",
    "new_string": "REPLACED_MARKER",
    "replace_all": True,
}
print(json.dumps({"tool_name": "Edit", "tool_input": ti}))
')
got="$(printf '%s' "$edit_payload" | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
# Both markers replaced -> content is still fully valid (spec-only + scope growth intact) -> allow
mcheck "mandatory: Edit replace_all replaces every occurrence" 0 "$got"
rm -rf "$mtd"

# 2: MultiEdit honors per-edit replace_all
mtd="$(mktemp -d)"
git init -q "$mtd"
mkdir -p "$mtd/docs/issue-999/reports"
content_me_base='# Traceability and scope growth

This deliverable is spec-only: output is specification, never src/ code.
DUPE_TOKEN one. DUPE_TOKEN two. DUPE_TOKEN three.
- Scope growth: SINGLE_TOKEN
- Feedback: inline validation message
'
printf '%s' "$content_me_base" > "$mtd/docs/issue-999/reports/interaction-design.md"
multiedit_payload=$(python3 -c '
import json
ti = {
    "file_path": "docs/issue-999/reports/interaction-design.md",
    "edits": [
        {"old_string": "DUPE_TOKEN", "new_string": "DUPE_REPLACED", "replace_all": True},
        {"old_string": "SINGLE_TOKEN", "new_string": "none", "replace_all": False},
    ],
}
print(json.dumps({"tool_name": "MultiEdit", "tool_input": ti}))
')
got="$(printf '%s' "$multiedit_payload" | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
# All DUPE_TOKEN occurrences replaced, SINGLE_TOKEN replaced once -> spec-only + scope-growth still present -> allow
mcheck "mandatory: MultiEdit honors per-edit replace_all" 0 "$got"
rm -rf "$mtd"

# 3: malformed JSON on stdin denies
mtd="$(mktemp -d)"
git init -q "$mtd"
got="$(printf '{"tool_name":"Write","tool_input":{' | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: malformed JSON denies" 2 "$got"
rm -rf "$mtd"

# 3b: empty payload denies
mtd="$(mktemp -d)"
git init -q "$mtd"
got="$(printf '' | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: empty payload denies" 2 "$got"
rm -rf "$mtd"

# 4: kill switch unrecognized value stays active (still denies on deny-fixture content)
got="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' \
  "$REC" "$(json_str "$content_b")" \
  | env CLAUDE_PROJECT_DIR="$(mktemp -d)" ID_TRACEABILITY_GATE_OFF="banana" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: kill switch unrecognized value stays active" 2 "$got"

# 5: absolute file_path and ./-prefixed file_path both match scope (passing content)
mtd="$(mktemp -d)"
git init -q "$mtd"
abs_payload=$(python3 -c '
import json, sys
td = sys.argv[1]
content = sys.argv[2]
ti = {"file_path": td + "/docs/issue-999/reports/interaction-design.md", "content": content}
print(json.dumps({"tool_name": "Write", "tool_input": ti}))
' "$mtd" "$content_a")
got="$(printf '%s' "$abs_payload" | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: absolute file_path matches scope" 0 "$got"

dot_payload=$(python3 -c '
import json, sys
content = sys.argv[1]
ti = {"file_path": "./docs/issue-999/reports/interaction-design.md", "content": content}
print(json.dumps({"tool_name": "Write", "tool_input": ti}))
' "$content_a")
got="$(printf '%s' "$dot_payload" | env CLAUDE_PROJECT_DIR="$mtd" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: ./-prefixed file_path matches scope" 0 "$got"
rm -rf "$mtd"

# 6: missing core (CLAUDE_PLUGIN_ROOT_CORE points nowhere, no sibling
# core/) -> fail closed (exit 2), never falls through to success.
got="$(printf '' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" /bin/bash "$GATE" >/dev/null 2>&1; echo $?)"
mcheck "mandatory: missing core fails closed" 2 "$got"

[ "$mrc" -eq 0 ] || exit 1

exit "$rc"
