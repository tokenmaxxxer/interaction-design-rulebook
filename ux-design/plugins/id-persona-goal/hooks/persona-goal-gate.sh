#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-persona-goal plugin's own
# concern: row 3 of docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md
# §3/§4 — Cooper persona/goal model, phase 2.
#
# Target: docs/issue-<n>/reports/interaction-design.md only. Any other
# path is not this gate's business (exit 0, allow, without inspecting
# content).
#
# Heading regex: /^#+\s*.*\b(persona|user\s+goal)\b/i
# Content check, under the matched heading (before the next heading of
# same-or-higher level):
#   - at least one named persona sub-item (bullet or bold-label line
#     that reads as a name/role), AND
#   - a separate line/field containing the word "goal" (case-insensitive)
#     with non-blank content after it.
# A heading with a blank/whitespace-only body is a stub -> deny.
#
# On pass, best-effort (non-fatal) updates
# docs/issue-<n>/reports/interaction-design/.status.json,
# data["issue-<n>"]["persona_goal"] = "ok".
#
# Kill switch: export ID_PERSONA_GOAL_GATE_OFF=1
set -uo pipefail

deny() { echo "id-persona-goal: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_PERSONA_GOAL_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "persona-goal-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "persona-goal-gate: empty tool-use payload on stdin; cannot evaluate the persona/goal gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (persona/goal check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-persona-goal: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (persona/goal).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/interaction-design\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    elif tool == "Bash":
        cmdline = ti.get("command")
        if isinstance(cmdline, str):
            for tok in re.findall(r'[A-Za-z0-9_./~$-]+', cmdline):
                rel_try = gate_lib.gate_normalize_path(root, tok)
                if (RECORD_RE.match(rel_try) if rel_try else False):
                    path = tok
                    break
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    r = posixpath.join(root, rel) if rel else root

    m = RECORD_RE.match(rel)
    if not m:
        sys.exit(0)  # not the interaction-design phase-2 record — not this gate's business

    n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on persona/goal." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the persona/goal section can be "
            "checked." % (rel, tool)
        )

    lines = new_text.splitlines()
    HEADING_RE = re.compile(r'^(#+)\s*.*\b(personas?|user\s+goals?)\b', re.I)
    ANY_HEADING_RE = re.compile(r'^(#+)\s*(.*)$')

    # Find the first persona/goal heading.
    match_idx = None
    match_level = None
    for i, line in enumerate(lines):
        hm = HEADING_RE.match(line)
        if hm:
            match_idx = i
            match_level = len(hm.group(1))
            break

    if match_idx is None:
        deny(
            "no persona/goal heading found in %s (expected a heading matching "
            "/^#+\\s*.*\\b(persona|user goal)\\b/i). Add a Personas & Goals section "
            "per the Cooper goal-directed-design model this plugin owns." % rel
        )

    # Collect the body: lines after the heading up to (not including) the
    # next heading of same-or-higher level.
    body_lines = []
    for line in lines[match_idx + 1:]:
        am = ANY_HEADING_RE.match(line)
        if am and len(am.group(1)) <= match_level:
            break
        body_lines.append(line)

    body_text = "\n".join(body_lines)
    if not body_text.strip():
        deny(
            "persona/goal heading found in %s but its body is blank/whitespace-only "
            "(a stub). Add at least one named persona with a distinct goal field." % rel
        )

    # Named-persona sub-item: a bullet or bold-label line that reads as a
    # name/role (e.g. "- **Jane, the ...**", "* Jane (role) - ...",
    # "**Name:** ..."), distinct from the line(s) carrying the goal field.
    PERSONA_LINE_RE = re.compile(
        r'^\s*[-*]\s*(\*\*[^*]+\*\*|[A-Z][A-Za-z .]{1,40}[:\-–—])'
    )
    GOAL_LINE_RE = re.compile(r'\bgoal\b\s*[:\-–—]?\s*(\S.*)?$', re.I)

    persona_line_idx = None
    for i, line in enumerate(body_lines):
        if PERSONA_LINE_RE.match(line) and not GOAL_LINE_RE.search(line):
            persona_line_idx = i
            break
        if PERSONA_LINE_RE.match(line):
            persona_line_idx = i
            break

    goal_line_idx = None
    for i, line in enumerate(body_lines):
        gm = GOAL_LINE_RE.search(line)
        if gm and (gm.group(1) or "").strip():
            goal_line_idx = i
            break

    if persona_line_idx is None:
        deny(
            "persona/goal heading found in %s but no named-persona sub-item was found "
            "(expected a bullet or bold-label line reading as a name/role). A role label "
            "with no named persona is not a Cooper-style persona block." % rel
        )

    if goal_line_idx is None:
        deny(
            "persona/goal heading found in %s but no separate line/field containing "
            "the word 'goal' with non-blank content was found. A persona with no "
            "distinct goal field is a role label, not a Cooper-style persona." % rel
        )

    # Passing check reached — best-effort state-tracking update. Auxiliary
    # only: never let a failure here flip the gate to deny.
    try:
        state_path = posixpath.join(root, "docs", "issue-%s" % n, "reports", "interaction-design", ".status.json")
        state_dir = posixpath.dirname(state_path)
        os.makedirs(state_dir, exist_ok=True)

        data = {}
        if os.path.isfile(state_path):
            try:
                with open(state_path, encoding="utf-8") as fh:
                    data = json.load(fh)
                if not isinstance(data, dict):
                    data = {}
            except Exception:
                data = {}

        subject = "issue-%s" % n
        entry = data.get(subject)
        if not isinstance(entry, dict):
            entry = {}
        entry["persona_goal"] = "ok"
        data[subject] = entry

        with open(state_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write(
            "id-persona-goal: warning: state-tracking update failed (non-fatal): %r\n" % (_state_e,)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("persona-goal-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-persona-goal: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
