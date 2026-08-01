#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-wireframe-staging plugin's own
# gate, on top of (never instead of) the core canon record-fields-gate.sh's
# generic fields.
#
# Row 6 of docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md
# §3/§4: owns exactly the lo-fi-before-hi-fi wireframe fidelity staging
# check on the phase-2 record docs/issue-<n>/reports/interaction-design.md.
#
# Heading match: /^#+\s*.*\b(wireframe|fidelity)\b/i
# Minimum content: two distinct staged sub-headings under (or near) the
# matched heading, one matching /lo(w)?[\s-]?fi/i and one matching
# /hi(gh)?[\s-]?fi/i, with the lo-fi heading appearing (by line number)
# before the hi-fi heading. Heading present but blank body, only one of the
# two stages present, or high-fi before low-fi = deny.
#
# On a passing check, best-effort updates the shared per-subject state file
# docs/issue-<n>/reports/interaction-design/.status.json, recording this
# plugin's result under data["issue-<n>"]["wireframe_staging"].
#
# Kill switch: export ID_WIREFRAME_STAGING_GATE_OFF=1
set -uo pipefail

deny() { echo "id-wireframe-staging: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_WIREFRAME_STAGING_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "wireframe-staging-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the wireframe-staging gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (wireframe-staging check cannot run)."

WSG_PAYLOAD="$payload" WSG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-wireframe-staging: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("WSG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (wireframe staging).")

    root = posixpath.normpath(os.environ["WSG_ROOT"].replace("\\", "/"))
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
            deny("%s exists but cannot be read; failing closed on wireframe staging." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the wireframe-staging heading can "
            "be checked." % (rel, tool)
        )

    lines = new_text.splitlines()

    HEADING_RE = re.compile(r'^#+\s*.*\b(wireframe|fidelity)\b', re.I)
    LOFI_RE = re.compile(r'lo(w)?[\s-]?fi', re.I)
    HIFI_RE = re.compile(r'hi(gh)?[\s-]?fi', re.I)
    ANY_HEADING_RE = re.compile(r'^#+\s')

    heading_idx = None
    for i, ln in enumerate(lines):
        if HEADING_RE.match(ln.strip()):
            heading_idx = i
            break

    if heading_idx is None:
        # No wireframe/fidelity heading in this write at all — not this
        # gate's concern unless the write is the record and lacks it
        # entirely (row-owning plugins compose; another gate may require
        # the heading's presence). This plugin only judges staging quality
        # once the heading exists.
        sys.exit(0)

    # Collect the section body: from just after the heading up to (but not
    # including) the next heading of any level, plus a little slack — since
    # sub-headings may appear "near" rather than strictly nested, scan to
    # the next top-level (##) heading or end of doc, whichever is sooner,
    # but stop earlier if a same/higher-level heading (fewer or equal '#'s)
    # than the matched heading appears.
    match_level = len(lines[heading_idx]) - len(lines[heading_idx].lstrip('#'))
    section_end = len(lines)
    for j in range(heading_idx + 1, len(lines)):
        stripped = lines[j].strip()
        if ANY_HEADING_RE.match(stripped):
            lvl = len(stripped) - len(stripped.lstrip('#'))
            if lvl <= match_level:
                section_end = j
                break

    section_lines = lines[heading_idx:section_end]

    def find_stage(pattern):
        for k, ln in enumerate(section_lines):
            s = ln.strip()
            if ANY_HEADING_RE.match(s) and pattern.search(s):
                # find non-blank body before next heading
                body_start = k + 1
                body_end = len(section_lines)
                for kk in range(body_start, len(section_lines)):
                    if ANY_HEADING_RE.match(section_lines[kk].strip()):
                        body_end = kk
                        break
                body = "\n".join(section_lines[body_start:body_end]).strip()
                return (k, bool(body))
        return None

    lofi = find_stage(LOFI_RE)
    hifi = find_stage(HIFI_RE)

    if lofi is None and hifi is None:
        deny(
            "%s has a wireframe/fidelity heading but neither a lo-fi nor a hi-fi staged "
            "sub-heading beneath it; per docs/issue-21 proposal row 6, the record must "
            "stage low-fidelity work strictly before high-fidelity work." % rel
        )
    if lofi is None:
        deny(
            "%s's wireframe/fidelity section is missing the low-fidelity (lo-fi) staged "
            "sub-heading." % rel
        )
    if hifi is None:
        deny(
            "%s's wireframe/fidelity section is missing the high-fidelity (hi-fi) staged "
            "sub-heading." % rel
        )
    if not lofi[1]:
        deny(
            "%s's lo-fi staged sub-heading is present but has a blank body (stub); the "
            "low-fidelity stage needs real content." % rel
        )
    if not hifi[1]:
        deny(
            "%s's hi-fi staged sub-heading is present but has a blank body (stub); the "
            "high-fidelity stage needs real content." % rel
        )
    if hifi[0] < lofi[0]:
        deny(
            "%s stages the high-fidelity sub-heading before the low-fidelity one; "
            "low-fidelity (structural) work must be staged before any high-fidelity "
            "(polish) treatment." % rel
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
        data[subject]["wireframe_staging"] = "ok"
        os.makedirs(os.path.dirname(status_path), exist_ok=True)
        with open(status_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-wireframe-staging: warning: could not update status file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("wireframe-staging-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-wireframe-staging: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
