#!/usr/bin/env bash
# Plain-bash spec for id-wireframe-staging/hooks/wireframe-staging-gate.sh,
# per this repo's tests/deny-only-check.sh + tests/stub-check.sh convention
# (plain bash, not bats).
set -uo pipefail

# issue-37: canonical test-env resolution convention (on-the-record #551,
# docs/specs/test-env-resolution.md) -- resolve core here so a missing
# core surfaces as an explicit SKIP, not a misleading assertion failure.
_tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
_repo_root="$(cd "$_tests_dir/../../../.." && pwd -P)"
. "$_repo_root/tests/lib/resolve-core.sh"
resolve_core_or_skip "$_repo_root" || exit $?
export CLAUDE_PLUGIN_ROOT_CORE="$RESOLVED_CORE"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/wireframe-staging-gate.sh"
rc=0
fail=0

TEST_REPO=""
setup() {
  TEST_REPO="$(mktemp -d)"
  git init -q "$TEST_REPO"
}
teardown() {
  [ -n "$TEST_REPO" ] && rm -rf "$TEST_REPO"
}

run_gate() {
  # $1 = file_path, $2 = content
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
' "$1" "$2" | env CLAUDE_PROJECT_DIR="$TEST_REPO" bash "$GATE" >"${TMPDIR:-/tmp}/wsg_out" 2>"${TMPDIR:-/tmp}/wsg_err"
  return $?
}

check() {
  local desc="$1" expect="$2" got="$3"
  if [ "$got" -eq "$expect" ]; then
    echo "ok — $desc"
  else
    echo "FAIL — $desc (expected exit $expect, got $got)" >&2
    fail=1
  fi
}

# (a) lo-fi then hi-fi, both non-blank -> allow (exit 0)
setup
content_a=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nscreen_ref: login\n\nStructural boxes and labels only, no color.\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n'
run_gate "docs/issue-100/reports/interaction-design.md" "$content_a"
check "lo-fi before hi-fi, both non-blank -> allow" 0 $?
teardown

# (a2) lo-fi/hi-fi present but no screen_ref: field -> deny
setup
content_a2=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nStructural boxes and labels only, no color.\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n'
run_gate "docs/issue-105/reports/interaction-design.md" "$content_a2"
check "missing screen_ref -> deny" 2 $?
teardown

# (b) hi-fi before lo-fi -> deny
setup
content_b=$'## Wireframe fidelity staging\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n\n### Lo-fi stage\n\nStructural boxes and labels only, no color.\n'
run_gate "docs/issue-101/reports/interaction-design.md" "$content_b"
check "hi-fi before lo-fi -> deny" 2 $?
teardown

# (c) only lo-fi present -> deny
setup
content_c=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nStructural boxes and labels only, no color.\n'
run_gate "docs/issue-102/reports/interaction-design.md" "$content_c"
check "only lo-fi present -> deny" 2 $?
teardown

# (d) heading present, blank body -> deny
setup
content_d=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\n### Hi-fi stage\n\n'
run_gate "docs/issue-103/reports/interaction-design.md" "$content_d"
check "heading present but blank stage bodies -> deny" 2 $?
teardown

# (e) unrelated write path -> allow
setup
run_gate "docs/issue-104/proposals/interaction-design.md" "not this gate's business"
check "unrelated write path -> allow" 0 $?
teardown

rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"

# ---------------------------------------------------------------------------
# mandatory: gate-lib.sh/gate-lib.py shared-contract cases (gate-house
# standard from core issue #72). Self-contained block: its own counter, and
# it exits 1 immediately on any failure of its own cases, leaving the
# existing pass/fail-tracking above untouched.
# ---------------------------------------------------------------------------
m_fail=0
m_check() {
  local desc="$1" expect="$2" got="$3"
  if [ "$got" -eq "$expect" ]; then
    echo "ok — $desc"
  else
    echo "FAIL — $desc (expected exit $expect, got $got)" >&2
    m_fail=1
  fi
}

run_gate_raw() {
  # $1 = raw stdin payload (may be malformed/empty)
  printf '%s' "$1" | env CLAUDE_PROJECT_DIR="$TEST_REPO" bash "$GATE" >"${TMPDIR:-/tmp}/wsg_out" 2>"${TMPDIR:-/tmp}/wsg_err"
  return $?
}

run_gate_tool_input() {
  # $1 = tool name, $2 = JSON tool_input (already-encoded), extra env via caller
  python3 -c '
import json, sys
print(json.dumps({"tool_name": sys.argv[1], "tool_input": json.loads(sys.argv[2])}))
' "$1" "$2" | env CLAUDE_PROJECT_DIR="$TEST_REPO" bash "$GATE" >"${TMPDIR:-/tmp}/wsg_out" 2>"${TMPDIR:-/tmp}/wsg_err"
  return $?
}

# 1) Edit with replace_all:true against a multiply-occurring old_string.
setup
target_1="docs/issue-200/reports/interaction-design.md"
content_1=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nscreen_ref: login\n\nDUPWORD structural boxes only. DUPWORD again.\n\n### Hi-fi stage\n\nFull visual treatment applied.\n'
mkdir -p "$TEST_REPO/docs/issue-200/reports"
printf '%s' "$content_1" > "$TEST_REPO/$target_1"
edit_input_1="$(python3 -c '
import json
print(json.dumps({"file_path": "'"$target_1"'", "old_string": "DUPWORD", "new_string": "X", "replace_all": True}))
')"
run_gate_tool_input "Edit" "$edit_input_1"
m_check "mandatory: Edit replace_all replaces every occurrence" 0 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 2) MultiEdit with a mix of replace_all true/false edits in one call.
setup
target_2="docs/issue-201/reports/interaction-design.md"
content_2=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nscreen_ref: login\n\nDUPWORD structural boxes only. DUPWORD again.\n\n### Hi-fi stage\n\nFull visual treatment SINGLEWORD applied.\n'
mkdir -p "$TEST_REPO/docs/issue-201/reports"
printf '%s' "$content_2" > "$TEST_REPO/$target_2"
multiedit_input_2="$(python3 -c '
import json
edits = [
    {"old_string": "DUPWORD", "new_string": "X", "replace_all": True},
    {"old_string": "SINGLEWORD", "new_string": "Y", "replace_all": False},
]
print(json.dumps({"file_path": "'"$target_2"'", "edits": edits}))
')"
run_gate_tool_input "MultiEdit" "$multiedit_input_2"
m_check "mandatory: MultiEdit honors per-edit replace_all" 0 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 3) Malformed JSON on stdin -> deny (exit 2).
setup
run_gate_raw '{"tool_name": "Write", "tool_input": {"file_path": "docs/issue-202/reports/interaction-design.md", "content": "trunc'
m_check "mandatory: malformed JSON denies" 2 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 3b) Empty stdin payload -> deny (exit 2).
setup
run_gate_raw ''
m_check "mandatory: empty payload denies" 2 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 4) Kill switch set to an unrecognized value -> stays active (still denies).
setup
target_4="docs/issue-203/reports/interaction-design.md"
content_4=$'## Wireframe fidelity staging\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n\n### Lo-fi stage\n\nStructural boxes and labels only, no color.\n'
ID_WIREFRAME_STAGING_GATE_OFF="banana" run_gate "$target_4" "$content_4"
m_check "mandatory: kill switch unrecognized value stays active" 2 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 5) Absolute file_path and "./"-prefixed variant both match the same scope.
setup
target_5="docs/issue-204/reports/interaction-design.md"
content_5=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nscreen_ref: login\n\nStructural boxes and labels only, no color.\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n'
run_gate "$TEST_REPO/$target_5" "$content_5"
m_check "mandatory: absolute file_path matches scope" 0 $?
run_gate "./$target_5" "$content_5"
m_check "mandatory: ./-prefixed file_path matches scope" 0 $?
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

# 6) Missing core (CLAUDE_PLUGIN_ROOT_CORE points nowhere, no sibling
# core/) -> fail closed (exit 2), never falls through to success.
setup
got6="$(printf '' | env CLAUDE_PROJECT_DIR="$TEST_REPO" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" bash "$GATE" >"${TMPDIR:-/tmp}/wsg_out" 2>"${TMPDIR:-/tmp}/wsg_err"; echo $?)"
m_check "mandatory: missing core fails closed" 2 "$got6"
teardown
[ "$m_fail" -ne 0 ] && { rm -f "${TMPDIR:-/tmp}/wsg_out" "${TMPDIR:-/tmp}/wsg_err"; exit 1; }

if [ "$fail" -ne 0 ]; then
  echo "id-wireframe-staging-gate-tests: FAIL" >&2
  exit 1
fi
echo "id-wireframe-staging-gate-tests: all tests passed"
exit 0
