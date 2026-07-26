#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §20's
# per-role record minimum content for ux-design's OWN record file
# (docs/reports/records/<subject>/ux-design.md).
#
# Peer to state-gate.sh: state-gate validates the `stage`/`loop_state`
# transition; this gate validates that the proposed record content carries
# the §20-required sections. It reads the SAME proposed content state-gate.sh
# already reads (no new content-read mechanism). It is silent on any write
# that does not target ux-design's own record file.
#
# Required always (§20 items 1 and 3):
#   - a "what was done" section
#   - the concrete basis: a `loop_state:` field AND an upstream basis
#     (an "upstream"/"basis" marker naming a commit sha or record path)
# Required additionally whenever the record's loop_state is NON-terminal
# (work left open — anything other than `reviewed`) (§20 items 4 and 5):
#   - a next-steps section
#   - an open-finding resolution-path section
# The §20 "why" item is conditional on a real choice having been made and is
# not structurally decidable here without the transition table; it is left to
# review, not enforced by this gate (under-enforcing a conditional field is
# safe; the always-required fields are hard-enforced).
#
# Modeled fail-closed on ops-cycle/state-gate.sh: every malformed/missing-input
# branch DENIES (exit 2), never exits 0 silently. No kill switch.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — record-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing." >&2
  exit 2
}

payload="$(cat 2>/dev/null || true)"

rc=0
UXD_PAYLOAD="$payload" UXD_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" python3 <<'PY' || rc=$?
import json, os, posixpath, re, sys

# Fail-closed python layer: any uncaught exception (e.g. os.path.realpath on a
# null-byte/undecodable path raising ValueError, which would otherwise exit 1
# = fail-open) becomes exit 2 (DENY). SystemExit from allow()/deny() bypasses
# this hook, so the real verdict paths are preserved exactly.
def _uxd_fail_closed_excepthook(_t, _v, _tb):
    try:
        sys.stderr.write("ux-design-cycle: refused — fail-closed: internal error (%s: %s)\n"
                         % (getattr(_t, "__name__", _t), _v))
        sys.stderr.flush()
    except Exception:
        pass
    os._exit(2)
sys.excepthook = _uxd_fail_closed_excepthook

def deny(msg):
    sys.stderr.write("ux-design-cycle: refused — " + msg + "\n")
    sys.exit(2)

def allow():
    sys.exit(0)

raw = os.environ.get("UXD_PAYLOAD", "")
try:
    event = json.loads(raw) if raw else None
except ValueError:
    deny("the tool-call payload is not valid JSON; the gate cannot judge a record it cannot parse.")
if not isinstance(event, dict):
    deny("the tool-call payload is not a JSON object; the gate cannot judge a record it cannot parse.")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input is missing or not a JSON object; the gate cannot judge a record it cannot parse.")

root = posixpath.normpath((os.environ.get("UXD_ROOT") or ".").replace("\\", "/"))

def resolve(path):
    n = path.replace("\\", "/")
    a = n if posixpath.isabs(n) else posixpath.join(root, n)
    return posixpath.normpath(a)

OWN_RE = re.compile(r'^docs/reports/records/([^/]+)/ux-design\.md$')

def target_path():
    if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        p = tool_input.get("file_path") or tool_input.get("notebook_path")
        if isinstance(p, str) and p:
            return p
    return None

path = target_path()
if not path:
    allow()

resolved = resolve(path)
rel = None
if resolved == root or resolved.startswith(root + "/"):
    rel = resolved[len(root):].lstrip("/")
if rel is None or not OWN_RE.match(rel):
    allow()

def current_text():
    try:
        with open(resolved, encoding="utf-8-sig") as fh:
            return fh.read(1 << 20)
    except OSError:
        return None

new_text = None
if tool == "Write":
    c = tool_input.get("content")
    if isinstance(c, str):
        new_text = c
elif tool == "Edit":
    o, n = tool_input.get("old_string"), tool_input.get("new_string")
    cur = current_text()
    if isinstance(o, str) and isinstance(n, str) and cur is not None and o in cur:
        new_text = cur.replace(o, n, 1)
elif tool == "MultiEdit":
    edits = tool_input.get("edits")
    cur = current_text()
    if isinstance(edits, list) and cur is not None:
        ok = True
        for e in edits:
            if not isinstance(e, dict):
                ok = False; break
            o, n = e.get("old_string"), e.get("new_string")
            if not isinstance(o, str) or not isinstance(n, str) or o not in cur:
                ok = False; break
            cur = cur.replace(o, n, 1)
        if ok:
            new_text = cur

if new_text is None:
    deny(
        "this write targets ux-design's own record (%s) but the gate cannot reconstruct "
        "the resulting content from the tool input (tool=%r). Write the full record with "
        "Write, or an Edit whose old_string is present, so §20's required sections can be "
        "checked." % (rel, tool)
    )

lower = new_text.lower()

loop_state = None
if new_text.startswith("---"):
    end = new_text.find("\n---", 3)
    if end != -1:
        m = re.search(r"^loop_state:\s*([^\r\n#]*?)\s*(?:#.*)?$", new_text[3:end], re.M)
        if m:
            loop_state = m.group(1).strip().lower()

missing = []
if loop_state is None or loop_state == "":
    missing.append("a `loop_state:` frontmatter field (the record's own current state)")
if "what was done" not in lower:
    missing.append('a "what was done" section')
if not re.search(r"\b(upstream|basis)\b", lower):
    missing.append('the concrete upstream basis (an "upstream"/"basis" marker naming the commit sha or record path this rests on)')

TERMINAL = {"reviewed"}
open_work = loop_state is not None and loop_state not in TERMINAL
if open_work:
    if "next step" not in lower and "next-step" not in lower:
        missing.append('a next-steps section (loop_state %r leaves work open)' % loop_state)
    if "resolution path" not in lower and "resolution-path" not in lower:
        missing.append('an open-finding resolution-path section (loop_state %r leaves work open)' % loop_state)

if missing:
    deny(
        "record is missing required section(s): " + "; ".join(missing) + ". Per contract §20 "
        "every role record must state what was done and the concrete upstream basis, and "
        "carry its own loop_state; open work additionally requires next-steps and an "
        "open-finding resolution path."
    )

allow()
PY
# Shell layer: map anything that is not allow(0) or deny(2) to a deny(2).
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "ux-design-cycle: refused — fail-closed: internal error (record-fields-gate judge exited $rc)." >&2
  exit 2
fi
exit "$rc"
