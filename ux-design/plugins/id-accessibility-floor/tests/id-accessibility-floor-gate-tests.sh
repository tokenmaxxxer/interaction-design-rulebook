#!/usr/bin/env bash
# Plain-bash gate tests (this repo's convention — no bats), covering
# id-accessibility-floor's accessibility-gate.sh.
#
# Usage: id-accessibility-floor-gate-tests.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate="$here/../hooks/accessibility-gate.sh"
[ -f "$gate" ] || { echo "id-accessibility-floor-gate-tests: gate script not found: $gate" >&2; exit 1; }

pass=0
fail=0

run_case() {
  # run_case <name> <expect_deny:0|1> <content>
  name="$1"; expect_deny="$2"; content="$3"
  td="$(mktemp -d)"
  git init -q "$td" >/dev/null 2>&1
  mkdir -p "$td/docs/issue-999/reports"
  payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
    "cwd": sys.argv[3],
}))
' "docs/issue-999/reports/interaction-design.md" "$content" "$td")"

  out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
  rc=$?
  rm -rf "$td"

  if [ "$expect_deny" = "1" ]; then
    if [ "$rc" = 2 ]; then
      echo "ok - $name (denied as expected)"; pass=$((pass+1))
    else
      echo "FAIL - $name: expected deny (rc=2), got rc=$rc; output: $out" >&2; fail=$((fail+1))
    fi
  else
    if [ "$rc" = 0 ]; then
      echo "ok - $name (allowed as expected)"; pass=$((pass+1))
    else
      echo "FAIL - $name: expected allow (rc=0), got rc=$rc; output: $out" >&2; fail=$((fail+1))
    fi
  fi
}

# (a) heading with "2.1 AA" plus keyboard/focus/label mentions -> allow
run_case "level + two concerns allows" 0 \
'# interaction-design record

## Accessibility floor

Conformance target WCAG 2.1 AA. All controls are keyboard-reachable with
a visible focus indicator, and every input carries a label.
'

# (b) heading with only "accessible", no level, no concrete words -> deny
run_case "bare accessible word denies" 1 \
'# interaction-design record

## Accessibility

This screen is accessible.
'

# (c) heading present, blank body -> deny
run_case "blank body stub denies" 1 \
'# interaction-design record

## Accessibility (WCAG)

## Next section
'

# (d) no accessibility heading -> deny
run_case "no accessibility heading denies" 1 \
'# interaction-design record

## Task flow

Some content with no accessibility section at all.
'

# (e) unrelated write path -> allow
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
payload="$(python3 -c '
import json
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": "src/app.js", "content": "console.log(1)"},
    "cwd": "'"$td"'",
}))
')"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 0 ]; then
  echo "ok - unrelated write path allows (allowed as expected)"; pass=$((pass+1))
else
  echo "FAIL - unrelated write path allows: expected allow (rc=0), got rc=$rc; output: $out" >&2; fail=$((fail+1))
fi

# ---------------------------------------------------------------------
# Mandatory gate-house standard coverage block (self-contained; exits 1
# immediately on any failure in this block, otherwise falls through).
# ---------------------------------------------------------------------
m_pass=0
m_fail=0

PASSING_CONTENT='# interaction-design record

## Accessibility floor

Conformance target WCAG 2.1 AA. All controls are keyboard-reachable with
a visible focus indicator, and every input carries a label.
'

DENY_CONTENT='# interaction-design record

## Accessibility

This screen is accessible.
'

# 1. Edit replace_all:true replaces every occurrence.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
mkdir -p "$td/docs/issue-999/reports"
on_disk='# interaction-design record

## Accessibility floor

Conformance target WCAG 2.1 AA. All controls are BENIGN-reachable with
a visible BENIGN indicator, and every input carries a BENIGN.
'
printf '%s' "$on_disk" > "$td/docs/issue-999/reports/interaction-design.md"
payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": sys.argv[1],
        "old_string": "BENIGN",
        "new_string": "keyboard",
        "replace_all": True,
    },
    "cwd": sys.argv[2],
}))
' "docs/issue-999/reports/interaction-design.md" "$td")"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
# after replace_all, all 3 BENIGN -> keyboard: level present, concern words
# hit only "keyboard" (repeated) => still just 1 distinct concern word => deny
if [ "$rc" = 2 ]; then
  echo "ok - mandatory: Edit replace_all replaces every occurrence (denied as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: Edit replace_all replaces every occurrence: expected rc=2, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 2. MultiEdit honors per-edit replace_all.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
mkdir -p "$td/docs/issue-999/reports"
on_disk='# interaction-design record

## Accessibility floor

Conformance target WCAG PLACEHOLDER. All controls are BENIGN-reachable with
a visible BENIGN indicator, and every input carries a label.
'
printf '%s' "$on_disk" > "$td/docs/issue-999/reports/interaction-design.md"
payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": sys.argv[1],
        "edits": [
            {"old_string": "PLACEHOLDER", "new_string": "2.1 AA", "replace_all": False},
            {"old_string": "BENIGN", "new_string": "focus", "replace_all": True},
        ],
    },
    "cwd": sys.argv[2],
}))
' "docs/issue-999/reports/interaction-design.md" "$td")"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
# both BENIGN -> focus (2 concern-word occurrences but 1 distinct word: focus)
# plus existing "label" => 2 distinct concern words (focus, label) + level 2.1 AA => allow
if [ "$rc" = 0 ]; then
  echo "ok - mandatory: MultiEdit honors per-edit replace_all (allowed as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: MultiEdit honors per-edit replace_all: expected rc=0, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 3. Malformed JSON on stdin -> deny.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
out="$(printf '%s' '{"tool_name": "Write", "tool_input": {' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 2 ]; then
  echo "ok - mandatory: malformed JSON denies (denied as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: malformed JSON denies: expected rc=2, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 3b. Empty stdin payload -> deny.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
out="$(printf '' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 2 ]; then
  echo "ok - mandatory: empty payload denies (denied as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: empty payload denies: expected rc=2, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 4. Kill switch set to an unrecognized value stays active (still denies).
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
mkdir -p "$td/docs/issue-999/reports"
payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]},
    "cwd": sys.argv[3],
}))
' "docs/issue-999/reports/interaction-design.md" "$DENY_CONTENT" "$td")"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" ID_ACCESSIBILITY_FLOOR_GATE_OFF="banana" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 2 ]; then
  echo "ok - mandatory: kill switch unrecognized value stays active (denied as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: kill switch unrecognized value stays active: expected rc=2, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 5. Absolute file_path matches scope.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
mkdir -p "$td/docs/issue-999/reports"
payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": sys.argv[1] + "/docs/issue-999/reports/interaction-design.md", "content": sys.argv[2]},
    "cwd": sys.argv[1],
}))
' "$td" "$PASSING_CONTENT")"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 0 ]; then
  echo "ok - mandatory: absolute file_path matches scope (allowed as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: absolute file_path matches scope: expected rc=0, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

# 5b. "./"-prefixed file_path matches scope.
td="$(mktemp -d)"
git init -q "$td" >/dev/null 2>&1
mkdir -p "$td/docs/issue-999/reports"
payload="$(python3 -c '
import json,sys
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": "./docs/issue-999/reports/interaction-design.md", "content": sys.argv[1]},
    "cwd": sys.argv[2],
}))
' "$PASSING_CONTENT" "$td")"
out="$(printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" 2>&1)"
rc=$?
rm -rf "$td"
if [ "$rc" = 0 ]; then
  echo "ok - mandatory: ./-prefixed file_path matches scope (allowed as expected)"; m_pass=$((m_pass+1))
else
  echo "FAIL - mandatory: ./-prefixed file_path matches scope: expected rc=0, got rc=$rc; output: $out" >&2; m_fail=$((m_fail+1))
fi

echo "id-accessibility-floor-gate-tests (mandatory block): $m_pass passed, $m_fail failed"
[ "$m_fail" -eq 0 ] || exit 1

echo "id-accessibility-floor-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
