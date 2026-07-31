#!/usr/bin/env bash
# Plain-bash probe suite for hooks/proposal-shape-gate.sh, following this
# repo's tests/deny-only-check.sh / tests/stub-check.sh convention
# (git-init-tmpdir + printf JSON payload piped to the gate script via
# stdin, check $?, echo ok/FAIL lines, exit 1 on any failure).
#
# Usage: id-proposal-shape-gate-tests.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate="$here/../hooks/proposal-shape-gate.sh"
rc=0

run_gate() {
  # run_gate <tmpdir> <rel-path> <content>
  local td="$1" rel="$2" content="$3"
  local payload
  payload="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "$rel" "$content" "$td")"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate"
}

mk_tmp() {
  local td
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-999/proposals"
  printf '%s' "$td"
}

ALL_SIX='# Proposal

## Problem framing
This is the problem statement, not blank.

## Comparison set
Compared alternatives here.

## Methodology cited
Nielsen heuristics cited.

## Delivery scope
Out of scope: X, Y.

## Adopt/skip
Adopt A, skip B.

## Judged-by
Judged by gate tests.
'

# --- case (a): all six present and non-stub -> allow -----------------------
td_a="$(mk_tmp)"
out_a="$(run_gate "$td_a" "docs/issue-999/proposals/x.md" "$ALL_SIX" 2>&1)"
code_a=$?
if [ "$code_a" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — all six sections present -> gate allows"
else
  echo "id-proposal-shape-gate-tests: FAIL — expected allow (exit 0), got exit $code_a: $out_a" >&2
  rc=1
fi
rm -rf "$td_a"

# --- case (b): one section missing (judged-by) -> deny, names it -----------
MISSING_JUDGED='# Proposal

## Problem framing
Problem statement here.

## Comparison set
Compared alternatives here.

## Methodology cited
Nielsen heuristics cited.

## Delivery scope
Out of scope: X, Y.

## Adopt/skip
Adopt A, skip B.
'
td_b="$(mk_tmp)"
out_b="$(run_gate "$td_b" "docs/issue-999/proposals/x.md" "$MISSING_JUDGED" 2>&1)"
code_b=$?
if [ "$code_b" = 2 ] && printf '%s' "$out_b" | grep -q "judged-by"; then
  echo "id-proposal-shape-gate-tests: ok — missing judged-by section -> gate denies and names it"
else
  echo "id-proposal-shape-gate-tests: FAIL — expected deny (exit 2) naming 'judged-by', got exit $code_b: $out_b" >&2
  rc=1
fi
rm -rf "$td_b"

# --- case (c): heading present but body blank (stub) -> deny ---------------
STUB_ADOPT='# Proposal

## Problem framing
Problem statement here.

## Comparison set
Compared alternatives here.

## Methodology cited
Nielsen heuristics cited.

## Delivery scope
Out of scope: X, Y.

## Adopt/skip

## Judged-by
Judged by gate tests.
'
td_c="$(mk_tmp)"
out_c="$(run_gate "$td_c" "docs/issue-999/proposals/x.md" "$STUB_ADOPT" 2>&1)"
code_c=$?
if [ "$code_c" = 2 ] && printf '%s' "$out_c" | grep -q "adopt/skip"; then
  echo "id-proposal-shape-gate-tests: ok — stub (blank-body) adopt/skip heading -> gate denies"
else
  echo "id-proposal-shape-gate-tests: FAIL — expected deny (exit 2) naming 'adopt/skip' for stub heading, got exit $code_c: $out_c" >&2
  rc=1
fi
rm -rf "$td_c"

# --- case (d): write outside docs/issue-<n>/proposals/ -> allow (n/a) ------
td_d="$(mk_tmp)"
out_d="$(run_gate "$td_d" "docs/issue-999/reports/interaction-design.md" "irrelevant content" 2>&1)"
code_d=$?
if [ "$code_d" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — write outside proposals/ -> gate allows (not its business)"
else
  echo "id-proposal-shape-gate-tests: FAIL — expected allow (exit 0) for non-proposal path, got exit $code_d: $out_d" >&2
  rc=1
fi
rm -rf "$td_d"

exit "$rc"
