#!/usr/bin/env bash
# Plain-bash test script for id-citation-format's citation-gate.sh, per this
# repo's tests/deny-only-check.sh / tests/stub-check.sh convention (not
# bats): git-init-tmpdir + printf JSON payload piped via stdin to the gate
# script, check $?.
#
# Usage: id-citation-format-gate-tests.sh
set -uo pipefail

gate="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)/citation-gate.sh"
rc=0

run_case() {
  # run_case <name> <expect: allow|deny> <file_path> <content>
  name="$1"; expect="$2"; file_path="$3"; content="$4"

  td="$(mktemp -d)"
  git init -q "$td"

  payload="$(CTF_FP="$file_path" CTF_CONTENT="$content" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["CTF_FP"], "content": os.environ["CTF_CONTENT"]},
}))
')"

  errfile="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" >/dev/null 2>"$errfile"
  got_rc=$?
  err="$(cat "$errfile" 2>/dev/null || true)"
  rm -f "$errfile"
  rm -rf "$td"

  case "$expect" in
    allow)
      if [ "$got_rc" -eq 0 ]; then
        echo "ok — $name"
      else
        echo "FAIL — $name: expected allow (rc=0), got rc=$got_rc: $err"
        rc=1
      fi
      ;;
    deny)
      if [ "$got_rc" -eq 2 ]; then
        echo "ok — $name"
      else
        echo "FAIL — $name: expected deny (rc=2), got rc=$got_rc: $err"
        rc=1
      fi
      ;;
  esac
}

# (a) claim bullet + no source/assumption marker -> deny
run_case "claim bullet without marker denies" deny \
  "docs/issue-1/proposals/interaction-design.md" \
  "## Sources
docs/issue-1/reports/interaction-design/survey.md

- The exemplar product handles onboarding with a three-step wizard.
"

# (b) claim bullet properly cited -> allow
run_case "claim bullet with source marker allows" allow \
  "docs/issue-1/proposals/interaction-design.md" \
  "- The exemplar product handles onboarding with a wizard (Sources: docs/issue-1/reports/interaction-design/survey.md).

## Sources
docs/issue-1/reports/interaction-design/survey.md
"

# (c) no claim bullets, no Sources heading, no established-practice language -> deny
run_case "no claims, no Sources heading, no assumption language denies" deny \
  "docs/issue-1/proposals/interaction-design.md" \
  "# Proposal

This proposal describes the screens and flows to be built.

- Just a plain statement with no trigger words at all.
"

# (d) established-practice assumption explicitly stated, no live sources -> allow
run_case "established-practice assumption with no live sources allows" allow \
  "docs/issue-1/proposals/interaction-design.md" \
  "# Proposal

No live research access existed for this document; all claims below are
established-practice assumption, not independently verified.

- Just a plain statement with no trigger words at all.
"

# (e) write outside proposals/ -> allow (not this gate's business)
run_case "write outside proposals/ allows" allow \
  "docs/issue-1/reports/interaction-design.md" \
  "- The exemplar product handles onboarding with a wizard.
"

exit "$rc"
