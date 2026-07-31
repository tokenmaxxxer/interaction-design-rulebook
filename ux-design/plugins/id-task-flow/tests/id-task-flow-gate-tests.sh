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

echo "---"
echo "id-task-flow-gate-tests: $pass passed, $fail failed"
exit "$rc"
