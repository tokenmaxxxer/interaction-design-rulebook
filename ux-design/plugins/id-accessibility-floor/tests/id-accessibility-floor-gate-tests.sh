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

echo "id-accessibility-floor-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
