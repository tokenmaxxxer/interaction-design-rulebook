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

exit "$rc"
