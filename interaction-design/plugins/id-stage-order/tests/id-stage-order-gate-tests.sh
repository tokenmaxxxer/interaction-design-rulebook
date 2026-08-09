#!/usr/bin/env bash
# Plain-bash probe suite for hooks/stage-order-gate.sh, following this
# repo's tests/deny-only-check.sh / tests/stub-check.sh convention
# (git-init-tmpdir + printf JSON payload piped to the gate script via
# stdin, check $?, echo ok/FAIL lines, exit 1 on any failure).
#
# Cases per docs/issue-21/proposals/
# issue-21-interaction-design-gate-machine.md §6:
#   (a) ordering-violation: new proposal write, no survey/scout -> deny
#   (b) ordering-satisfied: same write once both exist -> allow
#   (c) self-update: after an allowed write, .status.json shows "done"
#   (d) record write with no proposal present -> deny
#   (e) record write with a proposal present -> allow
#   (f) unrelated write path -> allow (not this gate's business)
#
# Usage: id-stage-order-gate-tests.sh
set -uo pipefail

# issue-37: canonical test-env resolution convention (on-the-record #551,
# docs/specs/test-env-resolution.md) -- resolve core here so a missing
# core surfaces as an explicit SKIP, not a misleading assertion failure.
_tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
_repo_root="$(cd "$_tests_dir/../../../.." && pwd -P)"
. "$_repo_root/tests/lib/resolve-core.sh"
resolve_core_or_skip "$_repo_root" || exit $?
export CLAUDE_PLUGIN_ROOT_CORE="$RESOLVED_CORE"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
gate="$here/../hooks/stage-order-gate.sh"
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
  mkdir -p "$td/docs/issue-999/reports/interaction-design"
  printf '%s' "$td"
}

# --- case (a): ordering-violation: no survey/scout present -> deny ---------
td_a="$(mk_tmp)"
out_a="$(run_gate "$td_a" "docs/issue-999/proposals/x.md" "# Proposal" 2>&1)"
code_a=$?
if [ "$code_a" = 2 ] && printf '%s' "$out_a" | grep -q "survey.md" && printf '%s' "$out_a" | grep -q "scout-brief.md"; then
  echo "id-stage-order-gate-tests: ok — new proposal with no survey/scout -> gate denies, names both"
else
  echo "id-stage-order-gate-tests: FAIL — expected deny (exit 2) naming survey.md and scout-brief.md, got exit $code_a: $out_a" >&2
  rc=1
fi
rm -rf "$td_a"

# --- case (b): ordering-satisfied: both exist -> allow ---------------------
td_b="$(mk_tmp)"
printf 'survey content\n' > "$td_b/docs/issue-999/reports/interaction-design/survey.md"
printf 'scout content\n' > "$td_b/docs/issue-999/reports/interaction-design/scout-brief.md"
out_b="$(run_gate "$td_b" "docs/issue-999/proposals/x.md" "# Proposal" 2>&1)"
code_b=$?
if [ "$code_b" = 0 ]; then
  echo "id-stage-order-gate-tests: ok — new proposal with survey+scout present -> gate allows"
else
  echo "id-stage-order-gate-tests: FAIL — expected allow (exit 0), got exit $code_b: $out_b" >&2
  rc=1
fi

# --- case (c): self-update: .status.json now shows proposal: done ----------
status_file="$td_b/docs/issue-999/reports/interaction-design/.status.json"
if [ -f "$status_file" ] && grep -q '"proposal": "done"' "$status_file" && grep -q '"survey": "done"' "$status_file" && grep -q '"scout": "done"' "$status_file"; then
  echo "id-stage-order-gate-tests: ok — .status.json self-updated with survey/scout/proposal done"
else
  echo "id-stage-order-gate-tests: FAIL — expected .status.json with survey/scout/proposal done, got: $(cat "$status_file" 2>&1)" >&2
  rc=1
fi
rm -rf "$td_b"

# --- case (d): record write with no proposal present -> deny ---------------
td_d="$(mk_tmp)"
out_d="$(run_gate "$td_d" "docs/issue-999/reports/interaction-design.md" "# Record" 2>&1)"
code_d=$?
if [ "$code_d" = 2 ] && printf '%s' "$out_d" | grep -q "proposals"; then
  echo "id-stage-order-gate-tests: ok — record write with no proposal present -> gate denies"
else
  echo "id-stage-order-gate-tests: FAIL — expected deny (exit 2) naming proposals, got exit $code_d: $out_d" >&2
  rc=1
fi
rm -rf "$td_d"

# --- case (e): record write with a proposal present -> allow ---------------
td_e="$(mk_tmp)"
printf '# Proposal\n' > "$td_e/docs/issue-999/proposals/p.md"
out_e="$(run_gate "$td_e" "docs/issue-999/reports/interaction-design.md" "# Record" 2>&1)"
code_e=$?
if [ "$code_e" = 0 ]; then
  echo "id-stage-order-gate-tests: ok — record write with a proposal present -> gate allows"
else
  echo "id-stage-order-gate-tests: FAIL — expected allow (exit 0), got exit $code_e: $out_e" >&2
  rc=1
fi
# self-update check for record stage too
status_file_e="$td_e/docs/issue-999/reports/interaction-design/.status.json"
if [ -f "$status_file_e" ] && grep -q '"record": "done"' "$status_file_e"; then
  echo "id-stage-order-gate-tests: ok — .status.json self-updated with record done"
else
  echo "id-stage-order-gate-tests: FAIL — expected .status.json with record done, got: $(cat "$status_file_e" 2>&1)" >&2
  rc=1
fi
rm -rf "$td_e"

# --- case (f): unrelated write path -> allow (not this gate's business) ----
td_f="$(mk_tmp)"
out_f="$(run_gate "$td_f" "docs/issue-999/reports/interaction-design/survey.md" "irrelevant content" 2>&1)"
code_f=$?
if [ "$code_f" = 0 ]; then
  echo "id-stage-order-gate-tests: ok — unrelated write path -> gate allows (not its business)"
else
  echo "id-stage-order-gate-tests: FAIL — expected allow (exit 0) for unrelated path, got exit $code_f: $out_f" >&2
  rc=1
fi
rm -rf "$td_f"

mrc=0

# --- mandatory: malformed JSON denies ---------------------------------------
td_m1="$(mk_tmp)"
out_m1="$(printf '%s' '{"tool_name":"Write"' | env CLAUDE_PROJECT_DIR="$td_m1" /bin/bash "$gate" 2>&1)"
code_m1=$?
if [ "$code_m1" = 2 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: malformed JSON denies"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: malformed JSON denies: expected exit 2, got exit $code_m1: $out_m1" >&2
  mrc=1
fi
rm -rf "$td_m1"

# --- mandatory: empty payload denies ----------------------------------------
td_m2="$(mk_tmp)"
out_m2="$(printf '' | env CLAUDE_PROJECT_DIR="$td_m2" /bin/bash "$gate" 2>&1)"
code_m2=$?
if [ "$code_m2" = 2 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: empty payload denies"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: empty payload denies: expected exit 2, got exit $code_m2: $out_m2" >&2
  mrc=1
fi
rm -rf "$td_m2"

# --- mandatory: kill switch unrecognized value stays active ----------------
td_m3="$(mk_tmp)"
out_m3="$(payload="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "docs/issue-999/proposals/x.md" "# Proposal" "$td_m3")"; printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td_m3" ID_STAGE_ORDER_GATE_OFF="banana" /bin/bash "$gate" 2>&1)"
code_m3=$?
if [ "$code_m3" = 2 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: kill switch unrecognized value stays active"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: kill switch unrecognized value stays active: expected exit 2, got exit $code_m3: $out_m3" >&2
  mrc=1
fi
rm -rf "$td_m3"

# --- mandatory: absolute file_path matches scope ----------------------------
td_m4="$(mk_tmp)"
printf '# Proposal\n' > "$td_m4/docs/issue-999/proposals/p.md"
out_m4="$(run_gate "$td_m4" "$td_m4/docs/issue-999/reports/interaction-design.md" "# Record" 2>&1)"
code_m4=$?
if [ "$code_m4" = 0 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: absolute file_path matches scope"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: absolute file_path matches scope: expected exit 0, got exit $code_m4: $out_m4" >&2
  mrc=1
fi
rm -rf "$td_m4"

# --- mandatory: ./-prefixed file_path matches scope -------------------------
td_m5="$(mk_tmp)"
printf '# Proposal\n' > "$td_m5/docs/issue-999/proposals/p.md"
out_m5="$(run_gate "$td_m5" "./docs/issue-999/reports/interaction-design.md" "# Record" 2>&1)"
code_m5=$?
if [ "$code_m5" = 0 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: ./-prefixed file_path matches scope"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: ./-prefixed file_path matches scope: expected exit 0, got exit $code_m5: $out_m5" >&2
  mrc=1
fi
rm -rf "$td_m5"

# --- mandatory: missing core fails closed -----------------------------------
out_m6="$(printf '' | env CLAUDE_PROJECT_DIR="$(mk_tmp)" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/core-$$" /bin/bash "$gate" 2>&1)"
code_m6=$?
if [ "$code_m6" = 2 ]; then
  echo "id-stage-order-gate-tests: ok — mandatory: missing core fails closed"
else
  echo "id-stage-order-gate-tests: FAIL — mandatory: missing core fails closed: expected exit 2, got exit $code_m6: $out_m6" >&2
  mrc=1
fi

if [ "$mrc" != 0 ]; then
  exit 1
fi

exit "$rc"
