#!/usr/bin/env bash
# Plain-bash test suite for id-state-completeness/hooks/state-completeness-gate.sh
# (this repo's convention: plain bash, not bats — see tests/deny-only-check.sh,
# tests/stub-check.sh).
#
# Usage: id-state-completeness-gate-tests.sh
set -uo pipefail

GATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)/state-completeness-gate.sh"
rc=0

run_case() {
  local desc="$1" content="$2" want="$3"
  local td payload got out
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  payload="$(python3 - "$content" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-42/reports/interaction-design.md", "content": sys.argv[1]}}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    echo "ok — $desc (rc=$got)"
  else
    echo "FAIL — $desc (want rc=$want, got rc=$got):" >&2
    cat "$out" >&2
    rc=1
  fi
  rm -f "$out"
}

run_unrelated() {
  local desc="$1" path="$2" content="$3" want="$4"
  local td payload got out
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/$(dirname "$path")"
  payload="$(python3 - "$path" "$content" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    echo "ok — $desc (rc=$got)"
  else
    echo "FAIL — $desc (want rc=$want, got rc=$got):" >&2
    cat "$out" >&2
    rc=1
  fi
  rm -f "$out"
}

# (a) states heading with all four states named for its screen/flow -> allow
run_case "all four states named -> allow" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
' 0

# (b) states heading missing "error" -> deny naming it
run_case "missing error -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- loading: spinner on submit
' 2

# (c) heading present, blank body -> deny (stub)
run_case "stub heading -> deny" \
'## States
' 2

# (d) no states heading -> deny
run_case "no states heading -> deny" \
'## Overview

Some unrelated content.
' 2

# (e) unrelated write path -> allow
run_unrelated "unrelated path -> allow" "docs/issue-42/reports/other.md" "anything" 0

exit "$rc"
