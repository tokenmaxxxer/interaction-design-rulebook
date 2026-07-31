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
'
got="$(run_gate "$REC" "$(json_str "$content_a")")"
check "a: full record allows" 0 "$got"

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

exit "$rc"
