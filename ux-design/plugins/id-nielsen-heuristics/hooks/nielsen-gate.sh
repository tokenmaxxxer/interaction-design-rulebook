#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — id-nielsen-heuristics plugin's own
# gate, on top of (never instead of) the other phase-2 judgment plugins
# (id-persona-goal, id-task-flow, ...) that share this write surface.
#
# Target: docs/issue-<n>/reports/interaction-design.md (the phase-2 record)
# only.
#
# Required: a heading matching /^#+\s*.*\b(nielsen|heuristic\s+evaluation)\b/i,
# followed (before the next same-level-or-higher heading) by at least ten
# distinct numbered/lettered/bulleted sub-items, each carrying a verdict
# word (pass|fail|violation|met|not met|n/a|ok, case-insensitive) on the
# same line or the line immediately after it. Heading-only "stub" sections
# (heading present, body blank/whitespace) are denied; fewer than ten
# verdicted items are denied; items present with no verdict word anywhere
# nearby are denied.
#
# On a passing check, best-effort updates the shared per-subject state file
# docs/issue-<n>/reports/interaction-design/.status.json, recording this
# plugin's result under data["issue-<n>"]["nielsen_heuristics"].
#
# Kill switch: export ID_NIELSEN_HEURISTICS_GATE_OFF=1
set -uo pipefail

deny() { echo "id-nielsen-heuristics: refused — $1" >&2; exit 2; }

case "${ID_NIELSEN_HEURISTICS_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "nielsen-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "nielsen-gate: empty tool-use payload on stdin; cannot evaluate the Nielsen-heuristics gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (Nielsen-heuristics check cannot run)."

NG_PAYLOAD="$payload" NG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("id-nielsen-heuristics: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("NG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the Nielsen-heuristics pass on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on the Nielsen-heuristics check.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (Nielsen heuristics).")

    root = posixpath.normpath(os.environ["NG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not the phase-2 interaction-design record — not this gate's business
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the Nielsen-heuristics check." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the Nielsen-heuristics pass can be "
            "checked." % (rel, tool)
        )

    HEADING_RE = re.compile(r'^(#+)\s')
    NIELSEN_HEADING_RE = re.compile(r'^#+\s*.*\b(nielsen|heuristic\s+evaluation)\b', re.I)
    ITEM_RE = re.compile(r'^\s*(?:[0-9]+[.)]|[a-zA-Z][.)]|[-*])\s+(.*)$')
    VERDICT_RE = re.compile(r'\b(pass|fail|violation|met|not met|n/?a|ok)\b', re.I)

    lines = new_text.splitlines()

    heading_idx = None
    heading_level = None
    for i, line in enumerate(lines):
        hm = HEADING_RE.match(line)
        if hm and NIELSEN_HEADING_RE.match(line):
            heading_idx = i
            heading_level = len(hm.group(1))
            break

    if heading_idx is None:
        deny(
            "no heading found (no heading matching /^#+\\s*.*\\b(nielsen|heuristic "
            "evaluation)\\b/i). The phase-2 record must carry a Nielsen/heuristic-evaluation "
            "section with all ten heuristics verdicted."
        )

    body_lines = []
    for line in lines[heading_idx + 1:]:
        hm = HEADING_RE.match(line)
        if hm and len(hm.group(1)) <= heading_level:
            break
        body_lines.append(line)

    if not any(bl.strip() for bl in body_lines):
        deny(
            "the Nielsen/heuristic-evaluation heading is present but its body is blank — a "
            "heading-only stub section is not a heuristic pass."
        )

    verdicted_items = 0
    unverdicted_items = []
    n_body = len(body_lines)
    for i, line in enumerate(body_lines):
        im = ITEM_RE.match(line)
        if not im:
            continue
        has_verdict = bool(VERDICT_RE.search(line))
        if not has_verdict and i + 1 < n_body:
            nxt = body_lines[i + 1]
            # only look ahead into a continuation/verdict line, not the next item
            if not ITEM_RE.match(nxt):
                has_verdict = bool(VERDICT_RE.search(nxt))
        if has_verdict:
            verdicted_items += 1
        else:
            unverdicted_items.append(line.strip())

    if verdicted_items < 10:
        detail = ""
        if unverdicted_items:
            detail = " Item(s) with no verdict word: %s." % "; ".join(unverdicted_items[:3])
        deny(
            "fewer than ten verdicted heuristic items found under the Nielsen/heuristic-"
            "evaluation heading (found %d with a non-blank verdict word "
            "[pass|fail|violation|met|not met|n/a|ok]); Nielsen's full ten-item set "
            "requires at least ten distinct numbered/lettered/bulleted sub-items, each with "
            "a verdict.%s" % (verdicted_items, detail)
        )

    # Passing — best-effort update of the shared state file.
    try:
        state_path = os.path.join(root, "docs", "issue-%s" % issue_n, "reports", "interaction-design", ".status.json")
        subject = "issue-%s" % issue_n
        data = {}
        if os.path.isfile(state_path):
            try:
                with open(state_path, encoding="utf-8") as fh:
                    data = json.load(fh)
                if not isinstance(data, dict):
                    data = {}
            except Exception:
                data = {}
        if subject not in data or not isinstance(data.get(subject), dict):
            data[subject] = {}
        data[subject]["nielsen_heuristics"] = "ok"
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        with open(state_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-nielsen-heuristics: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("nielsen-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-nielsen-heuristics: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
