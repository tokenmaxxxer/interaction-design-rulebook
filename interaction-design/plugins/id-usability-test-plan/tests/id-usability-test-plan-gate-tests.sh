#!/usr/bin/env bash
# Plain-bash test suite for hooks/usability-test-gate.sh, following this
# repo's own convention (tests/deny-only-check.sh, tests/stub-check.sh) —
# no bats, one script covering the plugin's own gate cases.
#
# Usage: id-usability-test-plan-gate-tests.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate="$here/../hooks/usability-test-gate.sh"
rc_total=0
pass=0
fail=0

json_escape() {
  python3 -c '
import json,sys
sys.stdout.write(json.dumps(sys.stdin.read()))
'
}

run_case() {
  local name="$1" file_rel="$2" content="$3" expect_rc="$4"
  local td
  td="$(mktemp -d)"
  git init -q "$td"
  mkdir -p "$td/$(dirname "$file_rel")"
  local content_json
  content_json="$(printf '%s' "$content" | json_escape)"
  local payload
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$file_rel" "$content_json")"
  local out
  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
  local rc=$?
  rm -rf "$td"
  if [ "$rc" -eq "$expect_rc" ]; then
    echo "PASS: $name (rc=$rc)"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (expected rc=$expect_rc, got rc=$rc)"
    echo "  output: $out"
    fail=$((fail + 1))
  fi
}

RECORD="docs/issue-42/reports/interaction-design.md"

# (a) heading + task scenario + participant count -> allow
run_case "heading with task scenario and participant count -> allow" \
  "$RECORD" \
  $'# Interaction Design Record\n\n## Usability Test Plan\n\nTask scenario: log in and reset the password.\nWe will recruit 5 participants for a think-aloud session.\n' \
  0

# (b) scenario present, no participant count -> deny
run_case "scenario present, no participant count -> deny" \
  "$RECORD" \
  $'# Interaction Design Record\n\n## Usability Test Plan\n\nTask scenario: log in and reset the password.\n' \
  2

# (c) heading present, blank body -> deny (stub)
run_case "heading present, blank body -> deny" \
  "$RECORD" \
  $'# Interaction Design Record\n\n## Usability Test Plan\n\n\n## Next Section\n\nSome other content.\n' \
  2

# (d) no heading -> deny
run_case "no heading -> deny" \
  "$RECORD" \
  $'# Interaction Design Record\n\nNo usability section here at all, just prose.\n' \
  2

# (e) unrelated write path -> allow (gate is not this plugin's business)
run_case "unrelated write path -> allow" \
  "docs/issue-42/proposals/foo.md" \
  $'# Some Proposal\n\nNothing usability-test related here.\n' \
  0


# ---------------------------------------------------------------------------
# Mandatory gate-house standard cases (core issue #72 migration coverage):
# Edit/MultiEdit reconstruction, malformed/empty stdin, kill-switch garbage
# values, and absolute / "./"-prefixed path scoping. Self-contained block
# with its own counter; exits 1 immediately on any failure here so a broken
# mandatory case cannot be silently swallowed by the file's final exit.
# ---------------------------------------------------------------------------
m_pass=0
m_fail=0

m_run() {
  local name="$1" expect_rc="$2" payload="$3" td="$4"
  local out
  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
  local rc=$?
  if [ "$rc" -eq "$expect_rc" ]; then
    echo "PASS: $name (rc=$rc)"
    m_pass=$((m_pass + 1))
  else
    echo "FAIL: $name (expected rc=$expect_rc, got rc=$rc)"
    echo "  output: $out"
    m_fail=$((m_fail + 1))
  fi
}

# 1) Edit with replace_all:true against a multiply-occurring old_string.
# On-disk content has "DECOY" glued onto the front of "participants" (so the
# participant-count regex does NOT match) plus two other stray "DECOY"
# occurrences. Only if EVERY "DECOY" occurrence is stripped does "5
# participants" become a clean match; replacing just the first occurrence
# would leave "DECOYparticipants" broken and the gate would still deny.
td1="$(mktemp -d)"
git init -q "$td1"
mkdir -p "$td1/docs/issue-42/reports"
printf '%s' $'# Interaction Design Record\n\n## Usability Test Plan\n\nDECOY Task scenario: log in and reset the password.\nWe will host 5 DECOYparticipants for a session. DECOY here too.\n' \
  > "$td1/$RECORD"
edit1_payload="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"DECOY","new_string":"","replace_all":true}}' "$RECORD")"
m_run "mandatory: Edit replace_all replaces every occurrence" 0 "$edit1_payload" "$td1"
rm -rf "$td1"

# 2) MultiEdit with a mix of replace_all true/false edits in one call.
# Edit A (replace_all:true) strips every "ZZZ" so "5 ZZZparticipants" becomes
# a clean "5 participants" match. Edit B (replace_all:false) strips only the
# FIRST "MARK" occurrence, which is enough to turn the glued "MARKTask" into
# a standalone "Task" (satisfying the scenario check) even though a second,
# irrelevant "MARK" later in the body is left untouched.
td2="$(mktemp -d)"
git init -q "$td2"
mkdir -p "$td2/docs/issue-42/reports"
printf '%s' $'# Interaction Design Record\n\n## Usability Test Plan\n\nMARKTask MARKscenario: log in and reset the password.\nWe will host 5 ZZZparticipants for a party. ZZZ marks it. Only ZZZ once more. extra MARK note.\n' \
  > "$td2/$RECORD"
multi_payload="$(printf '{"tool_name":"MultiEdit","tool_input":{"file_path":"%s","edits":[{"old_string":"ZZZ","new_string":"","replace_all":true},{"old_string":"MARK","new_string":"","replace_all":false}]}}' "$RECORD")"
m_run "mandatory: MultiEdit honors per-edit replace_all" 0 "$multi_payload" "$td2"
rm -rf "$td2"

# 3) Malformed / empty JSON on stdin -> fail-closed deny.
td3="$(mktemp -d)"
git init -q "$td3"
out3="$(printf '{"tool_name":"Write","tool_in' | env CLAUDE_PROJECT_DIR="$td3" /bin/bash "$gate" 2>&1)"
rc3=$?
if [ "$rc3" -eq 2 ]; then
  echo "PASS: mandatory: malformed JSON denies (rc=$rc3)"
  m_pass=$((m_pass + 1))
else
  echo "FAIL: mandatory: malformed JSON denies (expected rc=2, got rc=$rc3)"
  echo "  output: $out3"
  m_fail=$((m_fail + 1))
fi
out3b="$(printf '' | env CLAUDE_PROJECT_DIR="$td3" /bin/bash "$gate" 2>&1)"
rc3b=$?
if [ "$rc3b" -eq 2 ]; then
  echo "PASS: mandatory: empty payload denies (rc=$rc3b)"
  m_pass=$((m_pass + 1))
else
  echo "FAIL: mandatory: empty payload denies (expected rc=2, got rc=$rc3b)"
  echo "  output: $out3b"
  m_fail=$((m_fail + 1))
fi
rm -rf "$td3"

# 4) Kill switch set to an unrecognized value -> stays active (still denies
# a fixture that would otherwise deny on its own merits).
export ID_USABILITY_TEST_PLAN_GATE_OFF="banana"
td4="$(mktemp -d)"
git init -q "$td4"
mkdir -p "$td4/docs/issue-42/reports"
deny_content_json="$(printf '%s' $'# Interaction Design Record\n\n## Usability Test Plan\n\nTask scenario: log in and reset the password.\n' | json_escape)"
deny_payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$RECORD" "$deny_content_json")"
m_run "mandatory: kill switch unrecognized value stays active" 2 "$deny_payload" "$td4"
unset ID_USABILITY_TEST_PLAN_GATE_OFF
rm -rf "$td4"

# 5) Absolute file_path and "./"-prefixed file_path both match the same
# scope as the relative fixture in case (a).
allow_content_json="$(printf '%s' $'# Interaction Design Record\n\n## Usability Test Plan\n\nTask scenario: log in and reset the password.\nWe will recruit 5 participants for a think-aloud session.\n' | json_escape)"

td5="$(mktemp -d)"
git init -q "$td5"
mkdir -p "$td5/docs/issue-42/reports"
abs_path="$td5/$RECORD"
abs_payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$abs_path" "$allow_content_json")"
m_run "mandatory: absolute file_path matches scope" 0 "$abs_payload" "$td5"
rm -rf "$td5"

td6="$(mktemp -d)"
git init -q "$td6"
mkdir -p "$td6/docs/issue-42/reports"
dot_path="./$RECORD"
dot_payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$dot_path" "$allow_content_json")"
m_run "mandatory: ./-prefixed file_path matches scope" 0 "$dot_payload" "$td6"
rm -rf "$td6"

# 7) Missing core (CLAUDE_PLUGIN_ROOT_CORE points nowhere, no sibling
# core/) -> fail closed (exit 2), never falls through to success.
td7="$(mktemp -d)"
git init -q "$td7"
out7="$(printf '' | env CLAUDE_PROJECT_DIR="$td7" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" /bin/bash "$gate" 2>&1)"
rc7=$?
if [ "$rc7" -eq 2 ]; then
  echo "PASS: mandatory: missing core fails closed (rc=$rc7)"
  m_pass=$((m_pass + 1))
else
  echo "FAIL: mandatory: missing core fails closed (expected rc=2, got rc=$rc7)"
  echo "  output: $out7"
  m_fail=$((m_fail + 1))
fi
rm -rf "$td7"

echo
echo "id-usability-test-plan-gate-tests (mandatory block): $m_pass passed, $m_fail failed"
[ "$m_fail" -eq 0 ] || exit 1

echo
echo "id-usability-test-plan-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
