#!/usr/bin/env bash
# Plain-bash spec for id-wireframe-staging/hooks/wireframe-staging-gate.sh,
# per this repo's tests/deny-only-check.sh + tests/stub-check.sh convention
# (plain bash, not bats).
set -uo pipefail

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
content_a=$'## Wireframe fidelity staging\n\n### Lo-fi stage\n\nStructural boxes and labels only, no color.\n\n### Hi-fi stage\n\nFull visual treatment with tokens applied.\n'
run_gate "docs/issue-100/reports/interaction-design.md" "$content_a"
check "lo-fi before hi-fi, both non-blank -> allow" 0 $?
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

if [ "$fail" -ne 0 ]; then
  echo "id-wireframe-staging-gate-tests: FAIL" >&2
  exit 1
fi
echo "id-wireframe-staging-gate-tests: all tests passed"
exit 0
