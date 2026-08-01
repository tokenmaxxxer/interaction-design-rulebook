#!/usr/bin/env bash
# Plain-bash test script for hooks/task-flow-gate.sh, following this repo's
# existing convention (tests/deny-only-check.sh, tests/stub-check.sh) — no
# bats, exit 0 if all cases pass else 1.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate="$here/../hooks/task-flow-gate.sh"
# Use an isolated fake project root (not the real repo tree) so the gate's
# best-effort .status.json write during a passing test stays inside a
# throwaway scratch directory rather than touching the real docs/ tree.
root="${TMPDIR:-/tmp}/id-task-flow-test-root"
rm -rf "$root"
mkdir -p "$root/.git" "$root/docs"

rc=0
pass=0
fail=0

_check() {
  local name="$1" want="$2" got="$3"
  if [ "$got" = "$want" ]; then
    echo "ok - $name"
    pass=$((pass + 1))
  else
    echo "FAIL - $name (want exit $want, got $got)" >&2
    fail=$((fail + 1))
    rc=1
  fi
}

_run() {
  local payload="$1"
  local outdir="${TMPDIR:-/tmp}"
  printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$root" bash "$gate" >"$outdir/id-task-flow-test.out" 2>"$outdir/id-task-flow-test.err"
  echo $?
}

payload_write() {
  # $1 = file_path, $2 = content (JSON-escaped by caller)
  printf '{"tool_name":"Write","tool_input":{"file_path":%s,"content":%s}}' "$1" "$2"
}

json_str() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<<"$1"
}

# (a) distinct task-flow heading with real content, separate from wireframe
# heading -> allow.
content_a=$'# Interaction Design Record\n\n## Task Flow\n\n1. User opens dashboard.\n2. User selects an item.\n3. Error state: retry banner shown.\n\n## Wireframe\n\nLow-fi structural layout goes here.\n'
p="$(json_str "docs/issue-999/reports/interaction-design.md")"
c="$(json_str "$content_a")"
got="$(_run "$(payload_write "$p" "$c")")"
_check "distinct task-flow heading with real content -> allow" 0 "$got"

# (b) heading present, blank body -> deny.
content_b=$'# Interaction Design Record\n\n## Task Flow\n\n## Wireframe\n\nSome wireframe content.\n'
c="$(json_str "$content_b")"
got="$(_run "$(payload_write "$p" "$c")")"
_check "task-flow heading with blank body -> deny" 2 "$got"

# (c) no task/interaction-flow heading at all -> deny.
content_c=$'# Interaction Design Record\n\n## Personas\n\nSome persona content.\n\n## Wireframe\n\nSome wireframe content.\n'
c="$(json_str "$content_c")"
got="$(_run "$(payload_write "$p" "$c")")"
_check "no task/interaction-flow heading -> deny" 2 "$got"

# (d) write to unrelated path -> allow.
content_d=$'# Some other doc\n\nnothing relevant here.\n'
p2="$(json_str "docs/issue-999/proposals/interaction-design.md")"
c="$(json_str "$content_d")"
got="$(_run "$(payload_write "$p2" "$c")")"
_check "write to unrelated path -> allow" 0 "$got"

# --- mandatory: gate-lib migration behavior cases -------------------------
m_rc=0
m_pass=0
m_fail=0

# json_str appends a trailing newline (via <<<) which is harmless for whole
# file content but corrupts exact-match old_string/new_string/path values for
# Edit/MultiEdit — use this no-trailing-newline variant for those.
json_str_exact() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

_m_check() {
  local name="$1" want="$2" got="$3"
  if [ "$got" = "$want" ]; then
    echo "ok - $name"
    m_pass=$((m_pass + 1))
  else
    echo "FAIL - $name (want exit $want, got $got)" >&2
    m_fail=$((m_fail + 1))
    m_rc=1
  fi
}

# mandatory 1: Edit replace_all:true replaces every occurrence.
content_e=$'# Interaction Design Record\n\n## Task Flow\n\n1. STEP-MARKER: User opens dashboard.\n2. STEP-MARKER: User selects an item.\n3. STEP-MARKER: Error state retry banner shown.\n\n## Wireframe\n\nLow-fi structural layout goes here.\n'
p_e="docs/issue-997/reports/interaction-design.md"
mkdir -p "$root/docs/issue-997/reports"
printf '%s' "$content_e" >"$root/$p_e"
pj_e="$(json_str_exact "$p_e")"
old_e="$(json_str_exact "STEP-MARKER")"
new_e="$(json_str_exact "STEP-MARKER-DONE")"
edit_payload="$(printf '{"tool_name":"Edit","tool_input":{"file_path":%s,"old_string":%s,"new_string":%s,"replace_all":true}}' "$pj_e" "$old_e" "$new_e")"
got="$(_run "$edit_payload")"
_m_check "mandatory: Edit replace_all replaces every occurrence" 0 "$got"

# mandatory 2: MultiEdit honors per-edit replace_all (mix of true/false).
content_f=$'# Interaction Design Record\n\n## Task Flow\n\n1. MARK step one. MARK step two. MARK step three.\n2. UNIQUE special step.\n\n## Wireframe\n\nLayout.\n'
p_f="docs/issue-996/reports/interaction-design.md"
mkdir -p "$root/docs/issue-996/reports"
printf '%s' "$content_f" >"$root/$p_f"
pj_f="$(json_str_exact "$p_f")"
o1="$(json_str_exact "MARK")"
n1="$(json_str_exact "MARKX")"
o2="$(json_str_exact "UNIQUE")"
n2="$(json_str_exact "UNIQUE-CHANGED")"
multiedit_payload="$(printf '{"tool_name":"MultiEdit","tool_input":{"file_path":%s,"edits":[{"old_string":%s,"new_string":%s,"replace_all":true},{"old_string":%s,"new_string":%s,"replace_all":false}]}}' "$pj_f" "$o1" "$n1" "$o2" "$n2")"
got="$(_run "$multiedit_payload")"
_m_check "mandatory: MultiEdit honors per-edit replace_all" 0 "$got"

# mandatory 3: malformed JSON / empty payload on stdin -> deny.
got="$(_run '{"tool_name":"Write","tool_input":{"file_pat')"
_m_check "mandatory: malformed JSON denies" 2 "$got"

got="$(_run '')"
_m_check "mandatory: empty payload denies" 2 "$got"

# mandatory 4: kill switch set to an unrecognized value stays active (still denies).
content_deny="$content_b"
p_kill="$(json_str_exact "docs/issue-999/reports/interaction-design.md")"
c_kill="$(json_str "$content_deny")"
kill_payload="$(payload_write "$p_kill" "$c_kill")"
got="$(printf '%s' "$kill_payload" | ID_TASK_FLOW_GATE_OFF=banana CLAUDE_PROJECT_DIR="$root" bash "$gate" >"${TMPDIR:-/tmp}/id-task-flow-test.out" 2>"${TMPDIR:-/tmp}/id-task-flow-test.err"; echo $?)"
_m_check "mandatory: kill switch unrecognized value stays active" 2 "$got"

# mandatory 5: absolute file_path and "./"-prefixed file_path both match the
# same scope as the equivalent relative path.
rel_target="docs/issue-994/reports/interaction-design.md"
pj_abs="$(json_str_exact "$root/$rel_target")"
pj_dot="$(json_str_exact "./$rel_target")"
c_pass="$(json_str "$content_a")"

got="$(_run "$(payload_write "$pj_abs" "$c_pass")")"
_m_check "mandatory: absolute file_path matches scope" 0 "$got"

got="$(_run "$(payload_write "$pj_dot" "$c_pass")")"
_m_check "mandatory: ./-prefixed file_path matches scope" 0 "$got"

# mandatory 6: missing core (CLAUDE_PLUGIN_ROOT_CORE points nowhere, no
# sibling core/) -> fail closed (exit 2), never falls through to success.
got="$(printf '' | CLAUDE_PROJECT_DIR="$root" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" bash "$gate" >"${TMPDIR:-/tmp}/id-task-flow-test.out" 2>"${TMPDIR:-/tmp}/id-task-flow-test.err"; echo $?)"
_m_check "mandatory: missing core fails closed" 2 "$got"

echo "---"
echo "id-task-flow-gate-tests (mandatory block): $m_pass passed, $m_fail failed"
if [ "$m_rc" -ne 0 ]; then
  exit 1
fi
# --- end mandatory block ---------------------------------------------------

echo "---"
echo "id-task-flow-gate-tests: $pass passed, $fail failed"
exit "$rc"
