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


# ---------------------------------------------------------------------------
# Mandatory gate-house migration hardening cases. Self-contained block: its
# own counter, exits 1 immediately on any failure here, otherwise falls
# through unchanged to this file's existing final "exit $rc" below.
# ---------------------------------------------------------------------------
mand_rc=0

mand_pass_content='- The exemplar product handles onboarding with a wizard using a wizard flow (Sources: docs/issue-1/reports/interaction-design/survey.md).

## Sources
docs/issue-1/reports/interaction-design/survey.md
'

# 1) Edit with replace_all:true against a multiply-occurring old_string.
mand_td1="$(mktemp -d)"
git init -q "$mand_td1"
mkdir -p "$mand_td1/docs/issue-1/proposals"
printf '%s' "$mand_pass_content" > "$mand_td1/docs/issue-1/proposals/interaction-design.md"

mand_payload1="$(python3 -c '
import json
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": "docs/issue-1/proposals/interaction-design.md",
        "old_string": "wizard",
        "new_string": "walkthrough",
        "replace_all": True,
    },
}))
')"
mand_err1="$(mktemp)"
printf '%s' "$mand_payload1" | env CLAUDE_PROJECT_DIR="$mand_td1" /bin/bash "$gate" >/dev/null 2>"$mand_err1"
mand_got1=$?
if [ "$mand_got1" -eq 0 ]; then
  echo "ok — mandatory: Edit replace_all replaces every occurrence"
else
  echo "FAIL — mandatory: Edit replace_all replaces every occurrence: expected allow (rc=0), got rc=$mand_got1: $(cat "$mand_err1" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err1"
rm -rf "$mand_td1"

# 2) MultiEdit with a mix of replace_all true/false edits in one call.
mand_td2="$(mktemp -d)"
git init -q "$mand_td2"
mkdir -p "$mand_td2/docs/issue-1/proposals"
printf '%s' "$mand_pass_content" > "$mand_td2/docs/issue-1/proposals/interaction-design.md"

mand_payload2="$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-1/proposals/interaction-design.md",
        "edits": [
            {"old_string": "wizard", "new_string": "walkthrough", "replace_all": True},
            {
                "old_string": "(Sources: docs/issue-1/reports/interaction-design/survey.md).",
                "new_string": ".",
                "replace_all": False,
            },
        ],
    },
}))
')"
mand_err2="$(mktemp)"
printf '%s' "$mand_payload2" | env CLAUDE_PROJECT_DIR="$mand_td2" /bin/bash "$gate" >/dev/null 2>"$mand_err2"
mand_got2=$?
# Both replace_all:true occurrences of "wizard" become "walkthrough", and the
# single replace_all:false edit strips the (Sources: ...) marker from the
# claim bullet while the "exemplar" trigger word remains -> claim bullet
# without a source/assumption marker -> deny.
if [ "$mand_got2" -eq 2 ]; then
  echo "ok — mandatory: MultiEdit honors per-edit replace_all"
else
  echo "FAIL — mandatory: MultiEdit honors per-edit replace_all: expected deny (rc=2), got rc=$mand_got2: $(cat "$mand_err2" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err2"
rm -rf "$mand_td2"

# 3) Malformed JSON / empty payload on stdin -> deny.
mand_td3="$(mktemp -d)"
git init -q "$mand_td3"
mand_err3="$(mktemp)"
printf '{"tool_name": "Write", "tool_input": {' | env CLAUDE_PROJECT_DIR="$mand_td3" /bin/bash "$gate" >/dev/null 2>"$mand_err3"
mand_got3=$?
if [ "$mand_got3" -eq 2 ]; then
  echo "ok — mandatory: malformed JSON denies"
else
  echo "FAIL — mandatory: malformed JSON denies: expected deny (rc=2), got rc=$mand_got3: $(cat "$mand_err3" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err3"

mand_err3b="$(mktemp)"
printf '' | env CLAUDE_PROJECT_DIR="$mand_td3" /bin/bash "$gate" >/dev/null 2>"$mand_err3b"
mand_got3b=$?
if [ "$mand_got3b" -eq 2 ]; then
  echo "ok — mandatory: empty payload denies"
else
  echo "FAIL — mandatory: empty payload denies: expected deny (rc=2), got rc=$mand_got3b: $(cat "$mand_err3b" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err3b"
rm -rf "$mand_td3"

# 4) Kill switch set to an unrecognized value stays active (still denies).
mand_deny_content='## Sources
docs/issue-1/reports/interaction-design/survey.md

- The exemplar product handles onboarding with a three-step wizard.
'
mand_td4="$(mktemp -d)"
git init -q "$mand_td4"
mand_payload4="$(CTF_FP="docs/issue-1/proposals/interaction-design.md" CTF_CONTENT="$mand_deny_content" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["CTF_FP"], "content": os.environ["CTF_CONTENT"]},
}))
')"
mand_err4="$(mktemp)"
printf '%s' "$mand_payload4" | env CLAUDE_PROJECT_DIR="$mand_td4" ID_CITATION_FORMAT_GATE_OFF="banana" /bin/bash "$gate" >/dev/null 2>"$mand_err4"
mand_got4=$?
if [ "$mand_got4" -eq 2 ]; then
  echo "ok — mandatory: kill switch unrecognized value stays active"
else
  echo "FAIL — mandatory: kill switch unrecognized value stays active: expected deny (rc=2), got rc=$mand_got4: $(cat "$mand_err4" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err4"
rm -rf "$mand_td4"

# 5) Absolute file_path and "./"-prefixed file_path both match the same
# scope a relative fixture already covers (using the same known-passing
# content as the "claim bullet with source marker allows" case above).
mand_td5="$(mktemp -d)"
git init -q "$mand_td5"

mand_abs_path="$mand_td5/docs/issue-1/proposals/interaction-design.md"
mand_payload5a="$(CTF_FP="$mand_abs_path" CTF_CONTENT="$mand_pass_content" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["CTF_FP"], "content": os.environ["CTF_CONTENT"]},
}))
')"
mand_err5a="$(mktemp)"
printf '%s' "$mand_payload5a" | env CLAUDE_PROJECT_DIR="$mand_td5" /bin/bash "$gate" >/dev/null 2>"$mand_err5a"
mand_got5a=$?
if [ "$mand_got5a" -eq 0 ]; then
  echo "ok — mandatory: absolute file_path matches scope"
else
  echo "FAIL — mandatory: absolute file_path matches scope: expected allow (rc=0), got rc=$mand_got5a: $(cat "$mand_err5a" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err5a"

mand_payload5b="$(CTF_FP="./docs/issue-1/proposals/interaction-design.md" CTF_CONTENT="$mand_pass_content" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["CTF_FP"], "content": os.environ["CTF_CONTENT"]},
}))
')"
mand_err5b="$(mktemp)"
printf '%s' "$mand_payload5b" | env CLAUDE_PROJECT_DIR="$mand_td5" /bin/bash "$gate" >/dev/null 2>"$mand_err5b"
mand_got5b=$?
if [ "$mand_got5b" -eq 0 ]; then
  echo "ok — mandatory: ./-prefixed file_path matches scope"
else
  echo "FAIL — mandatory: ./-prefixed file_path matches scope: expected allow (rc=0), got rc=$mand_got5b: $(cat "$mand_err5b" 2>/dev/null)"
  mand_rc=1
fi
rm -f "$mand_err5b"
rm -rf "$mand_td5"

[ "$mand_rc" -eq 0 ] || exit 1

exit "$rc"
