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

exit "$rc"
