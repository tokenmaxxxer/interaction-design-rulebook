#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-citation-format plugin's own
# gate, on top of (never instead of) id-proposal-shape's structural check
# and id-stage-order's survey/scout gate.
#
# Target: docs/issue-<n>/proposals/*.md (phase-1 proposals) only.
#
# Required: (a) a closing heading matching /^#+\s*sources?\b/i listing at
# least one file/path or URL; (b) any bullet making a factual claim about a
# sibling repo, exemplar product, or external convention (trigger words:
# exemplar|product|nn/g|nng|ixdf|about face|established practice|
# convention|per\s) must carry a source marker or an explicit assumption
# label on the same line (sources?:|https?://|attributed to|
# established-practice assumption|assumption|가정). A document with zero
# claim bullets still needs the Sources heading unless it explicitly states
# no live research access existed.
#
# On a passing check, best-effort updates the shared per-subject state file
# docs/issue-<n>/reports/interaction-design/.status.json, recording this
# plugin's result under data["issue-<n>"]["citation_format"].
#
# Kill switch: export ID_CITATION_FORMAT_GATE_OFF=1
set -uo pipefail

deny() { echo "id-citation-format: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_CITATION_FORMAT_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "citation-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "citation-gate: empty tool-use payload on stdin; cannot evaluate the citation-format gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (citation-format check cannot run)."

CG_PAYLOAD="$payload" CG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-citation-format: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("CG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (citation format).")

    root = posixpath.normpath(os.environ["CG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$', re.I)

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

    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not a phase-1 proposal write surface — not this gate's business
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on citation format." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the citation format can be "
            "checked." % (rel, tool)
        )

    CITE_RE = re.compile(
        r'\bsources?:|https?://|\battributed to\b|\bestablished-practice assumption\b|\bassumption\b|가정',
        re.I,
    )
    TRIGGER_RE = re.compile(
        r'\b(exemplar|product|nn/g|nng|ixdf|about face|established practice|convention|per\s)\b',
        re.I,
    )
    SOURCES_HEADING_RE = re.compile(r'^#+\s*sources?\b', re.I)
    HEADING_RE = re.compile(r'^(#+)\s')
    NO_ACCESS_RE = re.compile(r'no (live )?research access|established-practice assumption', re.I)
    URL_OR_PATH_RE = re.compile(r'https?://\S+|(?:[\w.\-]+/)+[\w.\-]+|\.[A-Za-z0-9]{1,5}\b')

    lines = new_text.splitlines()

    # (b) claim-bullet check
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not (stripped.startswith('-') or stripped.startswith('*')):
            continue
        if not TRIGGER_RE.search(stripped):
            continue
        if not CITE_RE.search(stripped):
            deny(
                "claim bullet without a source/assumption marker (line %d): %s"
                % (i + 1, stripped)
            )

    # (a) Sources heading check, unless the doc states no live research
    # access — scoped to the document's own prose (non-bullet lines) or the
    # matched Sources section's own body, never a full-document scan that a
    # single bullet's marker can satisfy: a per-bullet "established-practice
    # assumption" marker on a claim bullet elsewhere in the document
    # (already satisfying check (b) for its own bullet, via CITE_RE) must
    # not also silently waive the Sources-heading requirement for the rest
    # of the document. A document-level "no access" statement is only
    # recognized in ordinary prose, not inside a "-"/"*" bullet line.
    prose = "\n".join(
        line for line in lines if not (line.strip().startswith('-') or line.strip().startswith('*'))
    )

    heading_idx = None
    heading_level = None
    for i, line in enumerate(lines):
        hm = HEADING_RE.match(line)
        if hm and SOURCES_HEADING_RE.match(line):
            heading_idx = i
            heading_level = len(hm.group(1))
            break

    sources_body = None
    if heading_idx is not None:
        body_lines = []
        for line in lines[heading_idx + 1:]:
            hm = HEADING_RE.match(line)
            if hm and len(hm.group(1)) <= heading_level:
                break
            body_lines.append(line)
        sources_body = "\n".join(body_lines)

    no_access_scoped = bool(NO_ACCESS_RE.search(prose)) or (
        sources_body is not None and bool(NO_ACCESS_RE.search(sources_body))
    )

    if not no_access_scoped:
        if heading_idx is None:
            deny("no Sources section with a file/path or URL (no heading matching /^#+\\s*sources?\\b/i found, and the document's own preamble does not state no live research access existed)")
        else:
            if not URL_OR_PATH_RE.search(sources_body):
                deny("no Sources section with a file/path or URL (Sources heading present but lists no file/path or URL)")

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
        data[subject]["citation_format"] = "ok"
        os.makedirs(os.path.dirname(state_path), exist_ok=True)
        with open(state_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-citation-format: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("citation-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-citation-format: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
