#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-traceability plugin's own
# gate: row 10 of the interaction-design gate machine.
#
# Target: docs/issue-<n>/reports/interaction-design.md (the phase-2 record
# write surface — this repo's actual record-file convention).
#
# Heading match: /^#+\s*.*\b(traceability|scope\s+growth)\b/i
# Minimum content: body must contain an explicit spec-only boundary
# statement matching /\bspec[\s-]only\b/i, PLUS at least one scope-growth
# flag field present (a line/bullet containing the words "scope growth" or
# "scope-growth", even if its value is empty — the field KEY must be
# present, e.g. "Scope growth: none"). Missing either = deny. Heading
# present but blank body = stub = deny. No heading = deny.
#
# On a passing check, best-effort updates the shared per-issue state file
# docs/issue-<n>/reports/interaction-design/.status.json, recording this
# plugin's result under data["issue-<n>"]["traceability"].
#
# Kill switch: export ID_TRACEABILITY_GATE_OFF=1
set -uo pipefail

deny() { echo "id-traceability: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_TRACEABILITY_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "traceability-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "traceability-gate: empty tool-use payload on stdin; cannot evaluate the traceability gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (traceability check cannot run)."

TG_PAYLOAD="$payload" TG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-traceability: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("TG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (traceability).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/interaction-design\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    r = posixpath.join(root, rel) if rel else root

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
            deny("%s exists but cannot be read; failing closed on traceability." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the traceability fields can be "
            "checked." % (rel, tool)
        )

    HEADING_RE = re.compile(r'^#+\s*.*\b(traceability|scope\s+growth)\b', re.I | re.M)
    SPEC_ONLY_RE = re.compile(r'\bspec[\s-]only\b', re.I)
    SCOPE_GROWTH_FIELD_RE = re.compile(r'scope[\s-]growth', re.I)

    heading_m = HEADING_RE.search(new_text)
    if not heading_m:
        deny(
            "no traceability/scope-growth heading found (expected a heading matching "
            "/^#+\\s*.*\\b(traceability|scope growth)\\b/i) in %s. Per the interaction-design "
            "gate machine (row 10), the phase-2 record must name this section explicitly." % rel
        )

    # Body = everything after the matched heading, up to the next heading (or EOF).
    body_start = heading_m.end()
    next_heading = re.search(r'^#+\s', new_text[body_start:], re.M)
    body = new_text[body_start: body_start + next_heading.start()] if next_heading else new_text[body_start:]

    if not body.strip():
        deny(
            "the traceability/scope-growth heading in %s is present but its body is blank "
            "(stub). It must state the spec-only output boundary and at least one "
            "scope-growth flag field." % rel
        )

    missing = []
    if not SPEC_ONLY_RE.search(body):
        missing.append("no explicit spec-only boundary statement (expected wording matching /\\bspec[\\s-]only\\b/i)")
    if not SCOPE_GROWTH_FIELD_RE.search(body):
        missing.append("no scope-growth flag field present (a line/bullet with the field key \"scope growth\" or \"scope-growth\", even if its value is \"none\")")

    if missing:
        deny(
            "traceability write to %s is missing required element(s): %s." % (rel, "; ".join(missing))
        )

    # Passing — best-effort update of the shared per-issue state file.
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
        data[subject]["traceability"] = "ok"
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        with open(state_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-traceability: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("traceability-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-traceability: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
