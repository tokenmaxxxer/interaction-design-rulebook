#!/usr/bin/env bash
# Plain-bash test script for id-nielsen-heuristics's nielsen-gate.sh, per
# this repo's tests/deny-only-check.sh / tests/stub-check.sh convention
# (not bats): git-init-tmpdir + printf JSON payload piped via stdin to the
# gate script, check $?.
#
# Usage: id-nielsen-heuristics-gate-tests.sh
set -uo pipefail

gate="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd -P)/nielsen-gate.sh"
rc=0

run_case() {
  # run_case <name> <expect: allow|deny> <file_path> <content>
  name="$1"; expect="$2"; file_path="$3"; content="$4"

  td="$(mktemp -d)"
  git init -q "$td"

  payload="$(NHT_FP="$file_path" NHT_CONTENT="$content" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["NHT_FP"], "content": os.environ["NHT_CONTENT"]},
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

TEN_ITEMS='## Nielsen Heuristic Evaluation

1. Visible system status: pass — loading spinner shown on submit.
2. Match between system and real world: pass — terminology matches domain.
3. User control and undo: violation — no back control on checkout step 3.
4. Consistency and standards: pass — buttons follow platform convention.
5. Error prevention: pass — confirm dialog before destructive delete.
6. Recognition rather than recall: pass — recent items shown, not typed.
7. Flexibility and efficiency of use: n/a — no power-user path in scope.
8. Aesthetic and minimalist design: pass — no extraneous chrome.
9. Help users recognize, diagnose, and recover from errors: violation — raw stack trace shown to user.
10. Help and documentation: pass — inline tooltips on every field.
'

NINE_ITEMS='## Nielsen Heuristic Evaluation

1. Visible system status: pass.
2. Match between system and real world: pass.
3. User control and undo: pass.
4. Consistency and standards: pass.
5. Error prevention: pass.
6. Recognition rather than recall: pass.
7. Flexibility and efficiency of use: pass.
8. Aesthetic and minimalist design: pass.
9. Help users recognize, diagnose, and recover from errors: pass.
'

NO_VERDICTS='## Nielsen Heuristic Evaluation

1. Visible system status
2. Match between system and real world
3. User control and undo
4. Consistency and standards
5. Error prevention
6. Recognition rather than recall
7. Flexibility and efficiency of use
8. Aesthetic and minimalist design
9. Help users recognize, diagnose, and recover from errors
10. Help and documentation
'

BLANK_BODY='## Nielsen Heuristic Evaluation

'

# (a) heading with 10 numbered items each carrying a verdict word -> allow
run_case "ten verdicted items allows" allow \
  "docs/issue-1/reports/interaction-design.md" "$TEN_ITEMS"

# (b) only 9 items -> deny
run_case "nine items denies" deny \
  "docs/issue-1/reports/interaction-design.md" "$NINE_ITEMS"

# (c) items present but no verdict words -> deny
run_case "items with no verdict words denies" deny \
  "docs/issue-1/reports/interaction-design.md" "$NO_VERDICTS"

# (d) heading present, blank body -> deny
run_case "heading with blank body denies" deny \
  "docs/issue-1/reports/interaction-design.md" "$BLANK_BODY"

# (e) unrelated write path -> allow
run_case "unrelated write path allows" allow \
  "docs/issue-1/proposals/interaction-design.md" "$NO_VERDICTS"

# ---------------------------------------------------------------------------
# Mandatory gate-house-standard cases (gate-lib.sh/gate-lib.py properties):
# Edit/MultiEdit reconstruction, malformed/empty stdin, kill-switch garbage
# values, and absolute / "./"-prefixed path scoping. Self-contained block
# with its own counter; exits 1 immediately on any failure in this block.
# ---------------------------------------------------------------------------
mrc=0

run_tool_case() {
  # run_tool_case <name> <expect: allow|deny> <file_path> <tool_input_json_fragment_builder_args...>
  # Generic helper: builds {"tool_name": tool, "tool_input": ti} payload from
  # already-constructed JSON (passed as $4) and pipes it to the gate.
  name="$1"; expect="$2"; td="$3"; payload="$4"

  errfile="$(mktemp)"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$gate" >/dev/null 2>"$errfile"
  got_rc=$?
  err="$(cat "$errfile" 2>/dev/null || true)"
  rm -f "$errfile"

  case "$expect" in
    allow)
      if [ "$got_rc" -eq 0 ]; then echo "ok — $name"; else echo "FAIL — $name: expected allow (rc=0), got rc=$got_rc: $err"; mrc=1; fi
      ;;
    deny)
      if [ "$got_rc" -eq 2 ]; then echo "ok — $name"; else echo "FAIL — $name: expected deny (rc=2), got rc=$got_rc: $err"; mrc=1; fi
      ;;
  esac
}

# 1. Edit with replace_all:true against a multiply-occurring old_string.
ELEVEN_ALL_PASS='## Nielsen Heuristic Evaluation

1. Visible system status: pass.
2. Match between system and real world: pass.
3. User control and undo: pass.
4. Consistency and standards: pass.
5. Error prevention: pass.
6. Recognition rather than recall: pass.
7. Flexibility and efficiency of use: pass.
8. Aesthetic and minimalist design: pass.
9. Help users recognize, diagnose, and recover from errors: pass.
10. Help and documentation: pass.
11. Extra bonus item: pass.
'
td1="$(mktemp -d)"; git init -q "$td1"
mkdir -p "$td1/docs/issue-1/reports"
printf '%s' "$ELEVEN_ALL_PASS" > "$td1/docs/issue-1/reports/interaction-design.md"
edit_payload="$(python3 -c '
import json
print(json.dumps({
    "tool_name": "Edit",
    "tool_input": {
        "file_path": "docs/issue-1/reports/interaction-design.md",
        "old_string": "pass",
        "new_string": "passXBROKEN",
        "replace_all": True,
    },
}))
')"
# If replace_all genuinely replaces every occurrence, all 11 "pass" verdict
# words lose their word boundary and the gate must deny (0 verdicted items
# left). If only the first occurrence were replaced, 10 would remain and the
# gate would (wrongly) allow.
run_tool_case "mandatory: Edit replace_all replaces every occurrence" deny "$td1" "$edit_payload"
rm -rf "$td1"

# 2. MultiEdit with a mix of replace_all true/false edits in one call.
TEN_ITEMS_BROKEN='## Nielsen Heuristic Evaluation

1. Visible system status: passDROPME — loading spinner shown on submit.
2. Match between system and real world: passDROPME — terminology matches domain.
3. User control and undo: violation — no back control on checkout step 3.
4. Consistency and standards: passDROPME — buttons follow platform convention.
5. Error prevention: pass — confirm dialog before destructive delete.
6. Recognition rather than recall: pass — recent items shown, not typed.
7. Flexibility and efficiency of use: n/a — no power-user path in scope.
8. Aesthetic and minimalist design: passSINGLE — no extraneous chrome.
9. Help users recognize, diagnose, and recover from errors: violation — raw stack trace shown to user.
10. Help and documentation: pass — inline tooltips on every field.
'
td2="$(mktemp -d)"; git init -q "$td2"
mkdir -p "$td2/docs/issue-1/reports"
printf '%s' "$TEN_ITEMS_BROKEN" > "$td2/docs/issue-1/reports/interaction-design.md"
multiedit_payload="$(python3 -c '
import json
print(json.dumps({
    "tool_name": "MultiEdit",
    "tool_input": {
        "file_path": "docs/issue-1/reports/interaction-design.md",
        "edits": [
            {"old_string": "passDROPME", "new_string": "pass", "replace_all": True},
            {"old_string": "passSINGLE", "new_string": "pass", "replace_all": False},
        ],
    },
}))
')"
# replace_all:true fixes all 3 "passDROPME" occurrences (items 1,2,4);
# replace_all:false fixes the single "passSINGLE" occurrence (item 8). With
# both landing correctly, all 10 items are verdicted again -> allow. If
# replace_all:true only fixed the first occurrence, two would stay broken
# and the gate would (wrongly) deny.
run_tool_case "mandatory: MultiEdit honors per-edit replace_all" allow "$td2" "$multiedit_payload"
rm -rf "$td2"

# 3. Malformed JSON / empty payload on stdin -> deny, invoked directly.
td3="$(mktemp -d)"; git init -q "$td3"
errfile="$(mktemp)"
printf '%s' '{"tool_name": "Write", "tool_in' | env CLAUDE_PROJECT_DIR="$td3" /bin/bash "$gate" >/dev/null 2>"$errfile"
got_rc=$?
err="$(cat "$errfile" 2>/dev/null || true)"; rm -f "$errfile"
if [ "$got_rc" -eq 2 ]; then echo "ok — mandatory: malformed JSON denies"; else echo "FAIL — mandatory: malformed JSON denies: expected rc=2, got rc=$got_rc: $err"; mrc=1; fi

errfile="$(mktemp)"
printf '' | env CLAUDE_PROJECT_DIR="$td3" /bin/bash "$gate" >/dev/null 2>"$errfile"
got_rc=$?
err="$(cat "$errfile" 2>/dev/null || true)"; rm -f "$errfile"
if [ "$got_rc" -eq 2 ]; then echo "ok — mandatory: empty payload denies"; else echo "FAIL — mandatory: empty payload denies: expected rc=2, got rc=$got_rc: $err"; mrc=1; fi
rm -rf "$td3"

# 4. Kill switch set to an unrecognized value -> gate stays active (deny).
td4="$(mktemp -d)"; git init -q "$td4"
deny_payload="$(NHT_FP="docs/issue-1/reports/interaction-design.md" NHT_CONTENT="$NINE_ITEMS" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["NHT_FP"], "content": os.environ["NHT_CONTENT"]},
}))
')"
errfile="$(mktemp)"
printf '%s' "$deny_payload" | env CLAUDE_PROJECT_DIR="$td4" ID_NIELSEN_HEURISTICS_GATE_OFF="banana" /bin/bash "$gate" >/dev/null 2>"$errfile"
got_rc=$?
err="$(cat "$errfile" 2>/dev/null || true)"; rm -f "$errfile"
if [ "$got_rc" -eq 2 ]; then echo "ok — mandatory: kill switch unrecognized value stays active"; else echo "FAIL — mandatory: kill switch unrecognized value stays active: expected rc=2, got rc=$got_rc: $err"; mrc=1; fi
rm -rf "$td4"

# 5. Absolute file_path and "./"-prefixed file_path both match the same scope.
td5="$(mktemp -d)"; git init -q "$td5"
abs_payload="$(NHT_FP="$td5/docs/issue-1/reports/interaction-design.md" NHT_CONTENT="$TEN_ITEMS" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["NHT_FP"], "content": os.environ["NHT_CONTENT"]},
}))
')"
run_tool_case "mandatory: absolute file_path matches scope" allow "$td5" "$abs_payload"

dotslash_payload="$(NHT_FP="./docs/issue-1/reports/interaction-design.md" NHT_CONTENT="$TEN_ITEMS" python3 -c '
import json, os
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": os.environ["NHT_FP"], "content": os.environ["NHT_CONTENT"]},
}))
')"
run_tool_case "mandatory: ./-prefixed file_path matches scope" allow "$td5" "$dotslash_payload"
rm -rf "$td5"

[ "$mrc" -eq 0 ] || exit 1

exit "$rc"
