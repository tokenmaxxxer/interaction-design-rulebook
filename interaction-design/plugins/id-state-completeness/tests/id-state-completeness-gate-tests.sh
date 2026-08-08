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
- state_name: login
- node_type: state
- transitions: dashboard
- edge_case_variant: network-timeout

### Dashboard

- default: shows widgets
- empty: no widgets yet
- error: load failure banner
- loading: skeleton screens
- state_name: dashboard
- node_type: terminal
- transitions: none
- edge_case_variant: none
' 0

# (b) states heading missing "error" -> deny naming it
run_case "missing error -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- loading: spinner on submit
- state_name: login
- node_type: terminal
- transitions: none
- edge_case_variant: none
' 2

# (b2) states heading missing spec fields (state_name/node_type/transitions/edge_case_variant) -> deny
run_case "missing spec fields -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
' 2

# (b3) node_type not in {state, choice, terminal} -> deny
run_case "invalid node_type -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
- state_name: login
- node_type: bogus
- transitions: none
- edge_case_variant: none
' 2

# (b4) transitions references a state_name not defined anywhere -> deny
run_case "unresolvable transitions reference -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
- state_name: login
- node_type: state
- transitions: nonexistent-screen
- edge_case_variant: none
' 2

# (b5) no terminal node_type anywhere -> deny
run_case "no terminal node -> deny" \
'## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
- state_name: login
- node_type: state
- transitions: none
- edge_case_variant: none
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

# --- mandatory gate-house standard cases (gate-lib.sh/gate-lib.py migration) ---
mrc=0

mcheck() {
  local desc="$1" want="$2" got="$3" out="$4"
  if [ "$got" = "$want" ]; then
    echo "ok — $desc (rc=$got)"
  else
    echo "FAIL — $desc (want rc=$want, got rc=$got):" >&2
    [ -n "$out" ] && cat "$out" >&2
    mrc=1
  fi
}

# 1. Edit with replace_all:true against a multiply-occurring old_string
{
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  cat >"$td/docs/issue-42/reports/interaction-design.md" <<'EOF'
## States

### Login screen

- default: shows the form ZZZ
- empty: n/a ZZZ
- error: inline validation message ZZZ
- loading: spinner on submit
- state_name: login
- node_type: terminal
- transitions: none
- edge_case_variant: none
EOF
  payload="$(python3 - <<'PY'
import json
print(json.dumps({
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "docs/issue-42/reports/interaction-design.md",
    "old_string": "ZZZ",
    "new_string": "Q",
    "replace_all": True,
  },
}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  mcheck "mandatory: Edit replace_all replaces every occurrence" 0 "$got" "$out"
  rm -f "$out"
}

# 2. MultiEdit with a mix of replace_all true/false edits in one call
{
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  cat >"$td/docs/issue-42/reports/interaction-design.md" <<'EOF'
## States

### Login screen

- default: shows the form ZZZ ONE
- empty: n/a ZZZ
- error: inline validation message ZZZ
- loading: spinner on submit
- state_name: login
- node_type: terminal
- transitions: none
- edge_case_variant: none
EOF
  payload="$(python3 - <<'PY'
import json
print(json.dumps({
  "tool_name": "MultiEdit",
  "tool_input": {
    "file_path": "docs/issue-42/reports/interaction-design.md",
    "edits": [
      {"old_string": "ZZZ", "new_string": "Q", "replace_all": True},
      {"old_string": "ONE", "new_string": "TWO", "replace_all": False},
    ],
  },
}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  mcheck "mandatory: MultiEdit honors per-edit replace_all" 0 "$got" "$out"
  rm -f "$out"
}

# 3. Malformed / empty JSON on stdin -> deny (bypass payload-building helpers)
{
  out="$(mktemp)"
  printf '{"tool_name": "Write", "tool_in' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  mcheck "mandatory: malformed JSON denies" 2 "$got" "$out"
  rm -f "$out"
}
{
  out="$(mktemp)"
  printf '' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  mcheck "mandatory: empty payload denies" 2 "$got" "$out"
  rm -f "$out"
}

# 4. Kill switch set to an unrecognized value -> gate stays active (still denies)
{
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  payload="$(python3 - <<'PY'
import json
content = """## States

### Login screen

- default: shows the form
- empty: n/a
- loading: spinner on submit
"""
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "docs/issue-42/reports/interaction-design.md", "content": content}}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" ID_STATE_COMPLETENESS_GATE_OFF="banana" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  mcheck "mandatory: kill switch unrecognized value stays active" 2 "$got" "$out"
  rm -f "$out"
}

# 5. Absolute file_path and "./"-prefixed file_path both match the same scope
{
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  payload="$(python3 - "$td" <<'PY'
import json, sys
td = sys.argv[1]
content = """## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
- state_name: login
- node_type: terminal
- transitions: none
- edge_case_variant: none
"""
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": td + "/docs/issue-42/reports/interaction-design.md", "content": content}}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  mcheck "mandatory: absolute file_path matches scope" 0 "$got" "$out"
  rm -f "$out"
  rm -rf "$td"
}
{
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-42/reports"
  payload="$(python3 - <<'PY'
import json
content = """## States

### Login screen

- default: shows the form
- empty: n/a
- error: inline validation message
- loading: spinner on submit
- state_name: login
- node_type: terminal
- transitions: none
- edge_case_variant: none
"""
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "./docs/issue-42/reports/interaction-design.md", "content": content}}))
PY
)"
  out="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  rm -rf "$td"
  mcheck "mandatory: ./-prefixed file_path matches scope" 0 "$got" "$out"
  rm -f "$out"
}

{
  out="$(mktemp)"
  printf '' | env CLAUDE_PROJECT_DIR="$(mktemp -d)" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" /bin/bash "$GATE" >"$out" 2>&1
  got=$?
  mcheck "mandatory: missing core fails closed" 2 "$got" "$out"
  rm -f "$out"
}

[ "$mrc" -eq 0 ] || exit 1

exit "$rc"
