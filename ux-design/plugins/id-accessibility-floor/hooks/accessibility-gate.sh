#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || {
  echo "$(basename "${BASH_SOURCE[0]}"): refused — core gate-lib.sh could not be sourced (CLAUDE_PLUGIN_ROOT_CORE unset/wrong and no sibling core/ found); failing closed rather than running without the shared fail-closed/kill-switch machinery." >&2
  exit 2
}
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit) — id-accessibility-floor plugin's
# own gate, on top of (never instead of) the other phase-2 id-* plugins'
# gates and core canon's generic fields.
#
# Target: docs/issue-<n>/reports/interaction-design.md (phase-2 record)
# only. Row 8 of docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md
# §3, matching pattern per §4's per-plugin table: heading matches
# /^#+\s*.*\b(wcag|accessibility)\b/i; body (up to next same-or-higher
# heading) must contain an explicit level mention matching /\b2\.1\s*AA\b/i
# (or equivalent explicitly named level) AND at least two of keyboard,
# focus, label, contrast (case-insensitive). Heading present but blank,
# missing the level mention, or fewer than two concrete-concern words is
# a stub/deny, matching this repo's tests/stub-check.sh convention.
#
# On a passing check, best-effort updates the shared per-subject state
# file docs/issue-<n>/reports/interaction-design/.status.json, recording
# this plugin's result under data["issue-<n>"]["accessibility_floor"].
#
# Kill switch: export ID_ACCESSIBILITY_FLOOR_GATE_OFF=1
set -uo pipefail

deny() { echo "id-accessibility-floor: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${ID_ACCESSIBILITY_FLOOR_GATE_OFF:-}" || exit 0

command -v python3 >/dev/null 2>&1 || deny "accessibility-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the accessibility floor gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (accessibility-floor check cannot run)."

AG_PAYLOAD="$payload" AG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys
    import importlib.util
    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("id-accessibility-floor: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("AG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)
    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (accessibility floor).")

    root = posixpath.normpath(os.environ["AG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not the interaction-design phase-2 record — not this gate's business
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the accessibility floor." % rel)

    new_text, _rw_ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not _rw_ok:
        new_text = None

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the accessibility floor can be "
            "checked." % (rel, tool)
        )

    HEADING_RE = re.compile(r'^(#+)\s*.*\b(wcag|accessibility)\b.*$', re.I | re.M)
    ANY_HEADING_RE = re.compile(r'^(#+)\s*.*$', re.M)
    LEVEL_RE = re.compile(r'\b2\.1\s*AA\b', re.I)
    CONCERN_WORDS = ("keyboard", "focus", "label", "contrast")

    hm = HEADING_RE.search(new_text)
    if not hm:
        deny(
            "no accessibility floor heading found in %s (expected a heading matching "
            "wcag/accessibility, e.g. \"## Accessibility floor\")." % rel
        )

    level = len(hm.group(1))
    start = hm.end()
    # body extends to the next heading of same-or-higher level (fewer or equal '#'s)
    end = len(new_text)
    for om in ANY_HEADING_RE.finditer(new_text, start):
        if len(om.group(1)) <= level:
            end = om.start()
            break
    body = new_text[start:end]

    if not body.strip():
        deny(
            "the accessibility heading in %s is present but its body is blank — a "
            "heading-only stub is treated as absent, per this repo's stub-check "
            "convention." % rel
        )

    body_low = body.lower()

    if not LEVEL_RE.search(body):
        deny(
            "%s's accessibility section names no explicit conformance level — an "
            "explicit level mention matching \"2.1 AA\" (or an equivalent explicitly "
            "named level) is required; the bare word \"accessible\" is not enough." % rel
        )

    hits = [w for w in CONCERN_WORDS if w in body_low]
    if len(hits) < 2:
        deny(
            "%s's accessibility section mentions fewer than two of the required concrete "
            "concerns (keyboard, focus, label, contrast) — found: %s. Naming the level "
            "alone, without concrete coverage, is not enough." % (rel, ", ".join(hits) if hits else "none")
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
        data[subject]["accessibility_floor"] = "ok"
        os.makedirs(os.path.dirname(status_path), exist_ok=True)
        with open(status_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
    except Exception as _state_e:
        sys.stderr.write("id-accessibility-floor: warning: could not update state file: %r\n" % (_state_e,))

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("accessibility-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "id-accessibility-floor: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
