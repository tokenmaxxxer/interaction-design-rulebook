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

# =============================================================================
# mandatory: gate-lib shared-contract cases (edit reconstruction, malformed
# JSON, kill switch unrecognized value, absolute/./-prefixed path scoping)
# =============================================================================
mrc=0

# --- mandatory: Edit replace_all replaces every occurrence -----------------
EDIT_BASE='# Proposal

## Problem framing
MARKERTOKEN This is the problem statement, not blank. MARKERTOKEN

## Comparison set
Compared alternatives here. MARKERTOKEN

## Methodology cited
Nielsen heuristics cited.

## Delivery scope
Out of scope: X, Y.

## Adopt/skip
Adopt A, skip B.

## Judged-by
Judged by gate tests.
'
td_e1="$(mk_tmp)"
rel_e1="docs/issue-999/proposals/e1.md"
printf '%s' "$EDIT_BASE" > "$td_e1/$rel_e1"
payload_e1="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1],"old_string":"MARKERTOKEN","new_string":"REPLACEDTOKEN","replace_all":True},"cwd":sys.argv[2]}))
' "$rel_e1" "$td_e1")"
out_e1="$(printf '%s' "$payload_e1" | env CLAUDE_PROJECT_DIR="$td_e1" /bin/bash "$gate" 2>&1)"
code_e1=$?
if [ "$code_e1" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: Edit replace_all replaces every occurrence"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: Edit replace_all replaces every occurrence: got exit $code_e1: $out_e1" >&2
  mrc=1
fi
rm -rf "$td_e1"

# --- mandatory: MultiEdit honors per-edit replace_all -----------------------
ME_BASE='# Proposal

## Problem framing
DUPWORD problem statement here. DUPWORD again.

## Comparison set
Compared alternatives here. UNIQUEWORD present once.

## Methodology cited
Nielsen heuristics cited.

## Delivery scope
Out of scope: X, Y.

## Adopt/skip
Adopt A, skip B.

## Judged-by
Judged by gate tests.
'
td_e2="$(mk_tmp)"
rel_e2="docs/issue-999/proposals/e2.md"
printf '%s' "$ME_BASE" > "$td_e2/$rel_e2"
payload_e2="$(python3 -c '
import json,sys
edits=[
  {"old_string":"DUPWORD","new_string":"DUPFIXED","replace_all":True},
  {"old_string":"UNIQUEWORD","new_string":"UNIQUEFIXED","replace_all":False},
]
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":sys.argv[1],"edits":edits},"cwd":sys.argv[2]}))
' "$rel_e2" "$td_e2")"
out_e2="$(printf '%s' "$payload_e2" | env CLAUDE_PROJECT_DIR="$td_e2" /bin/bash "$gate" 2>&1)"
code_e2=$?
if [ "$code_e2" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: MultiEdit honors per-edit replace_all"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: MultiEdit honors per-edit replace_all: got exit $code_e2: $out_e2" >&2
  mrc=1
fi
rm -rf "$td_e2"

# --- mandatory: malformed JSON denies / empty payload denies ---------------
td_e3="$(mk_tmp)"
out_e3="$(printf '{"tool_name": "Write", "tool_in' | env CLAUDE_PROJECT_DIR="$td_e3" /bin/bash "$gate" 2>&1)"
code_e3=$?
if [ "$code_e3" = 2 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: malformed JSON denies"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: malformed JSON denies: got exit $code_e3: $out_e3" >&2
  mrc=1
fi
rm -rf "$td_e3"

td_e4="$(mk_tmp)"
out_e4="$(printf '' | env CLAUDE_PROJECT_DIR="$td_e4" /bin/bash "$gate" 2>&1)"
code_e4=$?
if [ "$code_e4" = 2 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: empty payload denies"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: empty payload denies: got exit $code_e4: $out_e4" >&2
  mrc=1
fi
rm -rf "$td_e4"

# --- mandatory: kill switch unrecognized value stays active ----------------
td_e5="$(mk_tmp)"
payload_e5="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "docs/issue-999/proposals/x.md" "$MISSING_JUDGED" "$td_e5")"
out_e5="$(printf '%s' "$payload_e5" | env CLAUDE_PROJECT_DIR="$td_e5" ID_PROPOSAL_SHAPE_GATE_OFF="banana" /bin/bash "$gate" 2>&1)"
code_e5=$?
if [ "$code_e5" = 2 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: kill switch unrecognized value stays active"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: kill switch unrecognized value stays active: got exit $code_e5: $out_e5" >&2
  mrc=1
fi
rm -rf "$td_e5"

# --- mandatory: absolute file_path matches scope ----------------------------
td_e6="$(mk_tmp)"
abs_path_e6="$td_e6/docs/issue-999/proposals/x.md"
payload_e6="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "$abs_path_e6" "$ALL_SIX" "$td_e6")"
out_e6="$(printf '%s' "$payload_e6" | env CLAUDE_PROJECT_DIR="$td_e6" /bin/bash "$gate" 2>&1)"
code_e6=$?
if [ "$code_e6" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: absolute file_path matches scope"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: absolute file_path matches scope: got exit $code_e6: $out_e6" >&2
  mrc=1
fi
rm -rf "$td_e6"

# --- mandatory: ./-prefixed file_path matches scope -------------------------
td_e7="$(mk_tmp)"
payload_e7="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "./docs/issue-999/proposals/x.md" "$ALL_SIX" "$td_e7")"
out_e7="$(printf '%s' "$payload_e7" | env CLAUDE_PROJECT_DIR="$td_e7" /bin/bash "$gate" 2>&1)"
code_e7=$?
if [ "$code_e7" = 0 ]; then
  echo "id-proposal-shape-gate-tests: ok — mandatory: ./-prefixed file_path matches scope"
else
  echo "id-proposal-shape-gate-tests: FAIL — mandatory: ./-prefixed file_path matches scope: got exit $code_e7: $out_e7" >&2
  mrc=1
fi
rm -rf "$td_e7"

if [ "$mrc" -ne 0 ]; then
  exit 1
fi

exit "$rc"
