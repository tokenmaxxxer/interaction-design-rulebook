#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — id-state-completeness plugin's own
# gate, on top of (never instead of) the umbrella interaction-design record
# gate.
#
# Targets exactly: docs/issue-<n>/reports/interaction-design.md (phase-2
# record surface). Requires that a states/state-coverage heading exists, is
# non-blank, and that every screen/flow entry it names (sub-heading or
# bold-labeled sub-item) explicitly names all four required state words
# (default, empty, error, loading) before the next sibling entry or the next
# same-or-higher heading.
#
# On a passing write, best-effort updates
# docs/issue-<n>/reports/interaction-design/.status.json, recording
# data["issue-<n>"]["state_completeness"] = "ok".
#
# Kill switch: export ID_STATE_COMPLETENESS_GATE_OFF=1
set -uo pipefail

deny() { echo "id-state-completeness: refused — $1" >&2; exit 2; }

case "${ID_STATE_COMPLETENESS_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "state-completeness-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the state-completeness gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (state-completeness check cannot run)."

SC_PAYLOAD="$payload" SC_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("id-state-completeness: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("SC_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; cannot judge state-completeness on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on state-completeness.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse.")

    root = posixpath.normpath(os.environ["SC_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not this gate's write surface
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on state-completeness." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the states section can be "
            "checked." % (rel, tool)
        )

    HEADING_RE = re.compile(r'^(#+)\s*.*\b(states?|state\s+coverage)\b.*$', re.I | re.M)
    ANY_HEADING_RE = re.compile(r'^(#+)\s+.*$', re.M)

    hm = HEADING_RE.search(new_text)
    if not hm:
        deny(
            "no states heading found in %s. Add a heading matching "
            "/^#+\\s*.*\\b(states?|state\\s+coverage)\\b/i naming, per screen/flow, its "
            "default, empty, error, and loading states." % rel
        )

    level = len(hm.group(1))
    heading_start = hm.end()

    # Find end of the states section: next heading of level <= this one.
    section_end = len(new_text)
    for am in ANY_HEADING_RE.finditer(new_text, heading_start):
        if len(am.group(1)) <= level:
            section_end = am.start()
            break

    body = new_text[heading_start:section_end]

    if not body.strip():
        deny(
            "the states heading in %s is a stub — no body naming any screen/flow's state "
            "set follows it. A heading with a blank body is a stub, not a complete "
            "states section." % rel
        )

    REQUIRED = ["default", "empty", "error", "loading"]

    def missing_words(text):
        low = text.lower()
        return [w for w in REQUIRED if not re.search(r'\b%s\b' % re.escape(w), low)]

    # Screen/flow entries: sub-headings deeper than the states heading, or
    # bold-labeled sub-items (e.g. "- **Login screen**", "**Checkout flow**").
    ENTRY_RE = re.compile(
        r'^(?:(#{%d,})\s+(.*)|[ \t]*[-*]?\s*\*\*([^*\n]+)\*\*.*)$' % (level + 1),
        re.M,
    )

    entries = list(ENTRY_RE.finditer(body))

    if not entries:
        # No screen/flow named at all — check the whole body as one block.
        miss = missing_words(body)
        if miss:
            deny(
                "the states heading in %s names no screens/flows, and is missing "
                "state word(s): %s. Name each screen/flow and, for each, its "
                "default, empty, error, and loading states." % (rel, ", ".join(miss))
            )
        sys.exit(0)

    problems = []
    for i, em in enumerate(entries):
        name = (em.group(2) or em.group(3) or "").strip() or "(unnamed entry)"
        start = em.end()
        end = entries[i + 1].start() if i + 1 < len(entries) else len(body)
        block = body[start:end]
        miss = missing_words(block)
        if miss:
            problems.append("%r missing state(s): %s" % (name, ", ".join(miss)))

    if problems:
        deny(
            "the states section in %s is incomplete for %d screen/flow entr%s — %s. "
            "Every screen/flow must name all four states explicitly: default, empty, "
            "error, loading." % (
                rel, len(problems), "y" if len(problems) == 1 else "ies",
                "; ".join(problems),
            )
        )

    # Passing — best-effort update of the shared status file.
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
        data[subject]["state_completeness"] = "ok"
        os.makedirs(os.path.dirname(status_path), exist_ok=True)
        with open(status_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-state-completeness: warning: could not update status file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("state-completeness-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-state-completeness: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
