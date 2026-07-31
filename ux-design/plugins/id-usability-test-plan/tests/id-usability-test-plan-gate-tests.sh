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

echo
echo "id-usability-test-plan-gate-tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
