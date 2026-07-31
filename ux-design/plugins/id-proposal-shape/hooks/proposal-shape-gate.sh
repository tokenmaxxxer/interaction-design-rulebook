#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — id-proposal-shape plugin's own
# gate. Owns exactly one methodology: the six-section phase-1 proposal
# shape (docs/issue-21 proposal §3 row 1, §4 per-plugin matching pattern).
#
# Target: docs/issue-<n>/proposals/*.md only. Any other path is not this
# gate's business (exit 0).
#
# Six required sections, each matched by its own heading-anchored regex so
# no two required sections can be satisfied by the same heading:
#   problem/goal, comparison set, methodology cited, delivery scope,
#   adopt/skip, judged-by.
# A heading present with a blank/whitespace-only body counts as ABSENT
# (stub rule, matching this repo's tests/stub-check.sh convention).
#
# On a passing check, best-effort updates
# docs/issue-<n>/reports/interaction-design/.status.json, setting
# data["issue-<n>"]["proposal_shape"] = "ok". Never fails the write on its
# own state-update error.
#
# Kill switch: export ID_PROPOSAL_SHAPE_GATE_OFF=1
set -uo pipefail

deny() { echo "id-proposal-shape: refused — $1" >&2; exit 2; }

case "${ID_PROPOSAL_SHAPE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "proposal-shape-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the proposal-shape gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (proposal-shape check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("id-proposal-shape: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge proposal shape on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on proposal-shape.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (proposal-shape).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$')

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

    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not a docs/issue-<n>/proposals/*.md write — not this gate's business
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on proposal-shape." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the six required sections can be "
            "checked." % (rel, tool)
        )

    # Six required sections, each with its own heading-anchored regex.
    SECTIONS = [
        ("problem/goal", re.compile(r'^#+\s*.*\b(problem\s*framing|problem|goal)\b', re.I)),
        ("comparison set", re.compile(r'^#+\s*.*\b(comparison|alternatives?|catalog|compared\s+options?)\b', re.I)),
        ("methodology cited", re.compile(r'^#+\s*.*\b(methodolog(y|ies)|adopted\s+methodolog)\b', re.I)),
        ("delivery scope", re.compile(r'^#+\s*.*\b(delivery\s+scope|does\s+not\s+do|out\s+of\s+scope)\b', re.I)),
        ("adopt/skip", re.compile(r'^#+\s*.*\b(adopt\s*/\s*skip|adopt|skip)\b', re.I)),
        ("judged-by", re.compile(r'^#+\s*.*\b(judged[\s-]by|judgment|approv(al|ed)|gate\s+tests?)\b', re.I)),
    ]

    HEADING_RE = re.compile(r'^(#+)\s*(.*)$')
    lines = new_text.splitlines()

    # Parse into a list of (line_index, level, text) for every heading line.
    headings = []
    for i, line in enumerate(lines):
        hm = HEADING_RE.match(line)
        if hm:
            headings.append((i, len(hm.group(1)), line))

    def body_nonblank(heading_idx, heading_level):
        # Body = lines after this heading up to (not including) the next
        # heading whose level is <= this heading's level (same-or-higher).
        start = heading_idx + 1
        end = len(lines)
        for (hi, hl, _) in headings:
            if hi > heading_idx and hl <= heading_level:
                end = hi
                break
        body = lines[start:end]
        return any(l.strip() for l in body)

    missing = []
    for name, pat in SECTIONS:
        found_nonblank = False
        for (hi, hl, line) in headings:
            if pat.match(line):
                if body_nonblank(hi, hl):
                    found_nonblank = True
                    break
        if not found_nonblank:
            missing.append(name)

    if missing:
        deny(
            "phase-1 proposal at %s is missing (or has a stub/blank-body heading for) "
            "required section(s): %s. Per docs/issue-21/proposals/"
            "issue-21-interaction-design-gate-machine.md §4, every phase-1 proposal must "
            "contain all six sections (problem/goal, comparison set, methodology cited, "
            "delivery scope, adopt/skip, judged-by) as distinct headings, each with "
            "non-blank content." % (rel, ", ".join(missing))
        )

    # Passing — best-effort update of the shared per-subject status file.
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
        data[subject]["proposal_shape"] = "ok"
        os.makedirs(os.path.dirname(status_path), exist_ok=True)
        with open(status_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-proposal-shape: warning: could not update status file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("proposal-shape-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-proposal-shape: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
