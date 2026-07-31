#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — id-usability-test-plan plugin's
# own gate. Owns exactly one methodology: the usability-test plan
# requirement (row 9 of docs/issue-21/proposals/
# issue-21-interaction-design-gate-machine.md §2/§3), which is mechanical
# per §7 (no agent).
#
# Target: docs/issue-<n>/reports/interaction-design.md (the phase-2
# record) only. Requires a heading matching /^#+\s*.*\b(usability\s+test|
# test\s+plan)\b/i, whose body (up to the next same-or-higher heading)
# contains at least one named task scenario (verb-first task phrasing, or
# the word "scenario"/"task") PLUS a participant-count or recruitment
# line (/\b\d+\s*(participants?|users?)\b/i, or the word "recruit"). A
# heading with a blank/whitespace-only body is a stub, per this repo's
# tests/stub-check.sh convention, and is denied same as a missing
# heading.
#
# On a passing check, best-effort updates the shared per-subject state
# file docs/issue-<n>/reports/interaction-design/.status.json, recording
# this plugin's result under data["issue-<n>"]["usability_test_plan"].
#
# Kill switch: export ID_USABILITY_TEST_PLAN_GATE_OFF=1
set -uo pipefail

deny() { echo "id-usability-test-plan: refused — $1" >&2; exit 2; }

case "${ID_USABILITY_TEST_PLAN_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "usability-test-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the usability-test-plan gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (usability-test-plan check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("id-usability-test-plan: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the usability-test-plan fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on usability-test-plan.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (usability-test-plan).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/interaction-design\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")

    m = RECORD_RE.match(rel)
    if not m:
        sys.exit(0)  # not this plugin's write surface
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on usability-test-plan." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the usability-test-plan section can "
            "be checked." % (rel, tool)
        )

    HEADING_RE = re.compile(r'^[ \t]{0,3}#+\s*.*\b(usability\s+test|test\s+plan)\b', re.I | re.M)
    ANY_HEADING_RE = re.compile(r'^[ \t]{0,3}#+\s*(.*)$', re.M)
    PARTICIPANT_RE = re.compile(r'\b\d+\s*(participants?|users?)\b', re.I)
    RECRUIT_RE = re.compile(r'\brecruit\b', re.I)

    heading_match = HEADING_RE.search(new_text)
    if not heading_match:
        deny(
            "no heading matching /^#+\\s*.*\\b(usability\\s+test|test\\s+plan)\\b/i found in "
            "%s. Per docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md §4, "
            "the phase-2 record must carry a usability-test-plan section under such a "
            "heading." % rel
        )

    # Isolate the body: from just after the matched heading's line to the
    # start of the next heading at or above the same level (or EOF).
    heading_start = heading_match.start()
    heading_line_end = new_text.find("\n", heading_start)
    body_start = heading_line_end + 1 if heading_line_end != -1 else len(new_text)

    matched_level = len(re.match(r'^[ \t]{0,3}(#+)', new_text[heading_start:], re.M).group(1))
    next_end = len(new_text)
    for hm in ANY_HEADING_RE.finditer(new_text, body_start):
        hashes = re.match(r'^\s{0,3}(#+)', new_text[hm.start():]).group(1)
        if len(hashes) <= matched_level:
            next_end = hm.start()
            break

    body = new_text[body_start:next_end]

    if not body.strip():
        deny(
            "usability-test-plan heading found in %s but its body is blank/whitespace-only — "
            "a heading-only stub, no plan at all (matches this repo's tests/stub-check.sh "
            "stub convention)." % rel
        )

    has_scenario = bool(re.search(r'\bscenario\b', body, re.I)) or bool(re.search(r'\btask\b', body, re.I))
    has_participants = bool(PARTICIPANT_RE.search(body)) or bool(RECRUIT_RE.search(body))

    if not has_scenario and not has_participants:
        deny(
            "usability-test-plan section in %s is a stub: no named task scenario (a "
            "verb-first task bullet, or the word \"scenario\"/\"task\") and no "
            "participant-count or recruitment line (matching /\\b\\d+\\s*"
            "(participants?|users?)\\b/i or the word \"recruit\")." % rel
        )
    if not has_scenario:
        deny(
            "usability-test-plan section in %s has no named task scenario — add a "
            "verb-first task bullet, or a line containing \"scenario\" or \"task\"." % rel
        )
    if not has_participants:
        deny(
            "usability-test-plan section in %s names a task scenario but no "
            "participant-count or recruitment line — add e.g. \"5 participants\" or a "
            "\"recruit ...\" line." % rel
        )

    # Passing — best-effort update of the shared state file.
    try:
        status_path = os.path.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design", ".status.json")
        subject = "issue-%s" % issue_n
        data = {}
        if os.path.isfile(status_path):
            try:
                with open(status_path, encoding="utf-8") as fh:
                    data = json.load(fh)
                if not isinstance(data, dict):
                    data = {}
            except Exception:
                data = {}
        if subject not in data or not isinstance(data.get(subject), dict):
            data[subject] = {}
        data[subject]["usability_test_plan"] = "ok"
        os.makedirs(os.path.dirname(status_path), exist_ok=True)
        with open(status_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-usability-test-plan: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("usability-test-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-usability-test-plan: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
