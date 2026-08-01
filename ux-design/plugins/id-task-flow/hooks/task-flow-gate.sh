#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-task-flow plugin's own gate.
#
# Owns exactly row 4 of docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md
# §2/§3: the distinct task/interaction-flow artifact requirement (phase 2).
# Purely mechanical per §7 — no agent/checklist component.
#
# Target: docs/issue-<n>/reports/interaction-design.md (the phase-2 record,
# this repo's actual record-file convention — confirmed against
# docs/issue-15/reports/interaction-design.md).
#
# Heading regex (§4 pattern table): /^#+\s*.*\b(task\s+flow|interaction\s+flow)\b/i
#
# Minimum content check: the matched heading's body (up to the next
# same-or-higher heading) must be non-blank (stub rule, matching this repo's
# tests/stub-check.sh convention), and the matched heading must not be the
# same heading as one also matching the wireframe heading regex
# /^#+\s*.*\bwireframe\b/i — the flow artifact cannot be a subsection
# collapsed directly into/under a wireframe heading with no separate heading
# of its own.
#
# On a passing check, best-effort updates the shared per-subject state file
# docs/issue-<n>/reports/interaction-design/.status.json, recording this
# plugin's result under data["issue-<n>"]["task_flow"].
#
# Kill switch: export ID_TASK_FLOW_GATE_OFF=1
set -uo pipefail

deny() { echo "id-task-flow: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_TASK_FLOW_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "task-flow-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "task-flow-gate: empty tool-use payload on stdin; cannot evaluate the task-flow gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (task-flow check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-task-flow: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (task-flow).")

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
        sys.exit(0)  # not a task-flow write surface — not this gate's business
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on task-flow." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the task-flow artifact can be "
            "checked." % (rel, tool)
        )

    TASK_FLOW_RE = re.compile(r'^#+\s*.*\b(task\s+flow|interaction\s+flow)\b', re.I)
    WIREFRAME_RE = re.compile(r'^#+\s*.*\bwireframe\b', re.I)
    HEADING_RE = re.compile(r'^(#+)\s*(.*)$')

    lines = new_text.splitlines()
    headings = []  # (line_index, level, full_line_text)
    for idx, line in enumerate(lines):
        hm = HEADING_RE.match(line)
        if hm:
            headings.append((idx, len(hm.group(1)), line))

    task_flow_heading = None
    for idx, level, line in headings:
        if TASK_FLOW_RE.match(line):
            task_flow_heading = (idx, level, line)
            break

    if task_flow_heading is None:
        deny(
            "no task/interaction-flow heading found (expected a heading matching "
            "task flow / interaction flow) in %s — the distinct task/interaction-flow "
            "artifact required by row 4 of docs/issue-21's approved proposal is missing." % rel
        )

    idx, level, line = task_flow_heading

    if WIREFRAME_RE.match(line):
        deny(
            "the task/interaction-flow heading in %s is the same heading as a "
            "wireframe-headed section — flow content has collapsed into the wireframe "
            "section instead of getting its own distinct heading, which row 4's "
            "requirement forbids." % rel
        )

    # Body = lines after this heading up to the next same-or-higher-level heading.
    end_idx = len(lines)
    for h_idx, h_level, _h_line in headings:
        if h_idx > idx and h_level <= level:
            end_idx = h_idx
            break
    body_lines = lines[idx + 1:end_idx]
    body = "\n".join(body_lines).strip()

    if not body:
        deny(
            "the task/interaction-flow heading in %s has a blank/whitespace-only body "
            "(stub section) — a heading with no real flow content counts as absent, per "
            "this repo's stub-section convention." % rel
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
        data[subject]["task_flow"] = "ok"
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        with open(state_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-task-flow: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("task-flow-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-task-flow: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
