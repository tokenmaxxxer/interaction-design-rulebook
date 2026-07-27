#!/usr/bin/env bash
# fail-closed trap-at-top: any abort before verdict logic (failed source,
# set -e abort, unbound var) forces exit 2 (DENY). Must stay the FIRST
# executable statement, above set/source, and not be overwritten by a later
# EXIT trap. Composes with the python try/except and shell exit-code remap.
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §11's
# static per-role path ownership for the ux-design role. Generalizes the
# scope-gate write-set shape to §11's permanent owned-path table instead of a
# per-proposal freeze list.
#
# Under contract v2 the blackboard lives at
# docs/reports/records/<subject>/<role>.md. ux-design owns exactly its own
# <subject>/ux-design.md file. A write whose resolved target is another
# role's record file under docs/reports/records/<subject>/ is refused, citing
# §11 — the session must report the conflict rather than overwrite. Writes
# elsewhere (ux-design's own record, or the §21-granted decisions/reports/
# specs/handbooks files) are not this gate's business and pass through.
#
# Modeled fail-closed on ops-cycle/state-gate.sh: every malformed/missing-input
# branch DENIES (exit 2), never exits 0 silently. No kill switch.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — path-ownership-gate.sh requires python3, which is not on PATH; denying rather than guessing." >&2
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
    deny("the tool-call payload is not valid JSON; the gate cannot judge a write it cannot parse.")
if not isinstance(event, dict):
    deny("the tool-call payload is not a JSON object; the gate cannot judge a write it cannot parse.")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse.")

root = posixpath.normpath((os.environ.get("UXD_ROOT") or ".").replace("\\", "/"))

def resolve(path):
    n = path.replace("\\", "/")
    a = n if posixpath.isabs(n) else posixpath.join(root, n)
    a = posixpath.normpath(a)
    try:
        return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
    except OSError:
        return a

if tool not in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
    allow()

path = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(path, str) or not path:
    deny("no usable file_path/notebook_path in tool_input; the gate cannot judge a write it cannot identify.")

resolved = resolve(path)
if not (resolved == root or resolved.startswith(root + "/")):
    allow()

rel = resolved[len(root):].lstrip("/")

# Everything under a subject, not only the .md files directly beneath it.
# Measured 2026-07-27: this pattern was `([^/]+\.md)$`, so
# records/<subject>/tokens/<kind>.token matched nothing and was allowed —
# ux-design could Write its own human-approval token and satisfy contract
# §19's scope gate by itself.
RECORDS_RE = re.compile(r'^docs/reports/records/([^/]+)/(.+)$')
OWN_ROLE_FILE = "ux-design.md"
OWN_DIR = "ux-design/"

m = RECORDS_RE.match(rel)
if not m:
    allow()

subject, tail = m.group(1), m.group(2)
if tail == OWN_ROLE_FILE or tail.startswith(OWN_DIR):
    allow()

if tail.split("/")[0] == "tokens" or tail.endswith(".token"):
    deny(
        "'%s' is a human-approval token. Tokens are minted from the human's own "
        "turn or by the unattended judge and consumed by gates — a token written "
        "by a tool is a forged approval (contract §19)." % rel
    )

owner = tail[:-3] if tail.endswith(".md") and "/" not in tail else tail.split("/")[0]
deny(
    "'%s' is owned by role '%s' per contract §11, not 'ux-design' (ux-design owns "
    "only docs/reports/records/<subject>/%s and %s**). Report the conflict; do not "
    "overwrite or merge into another role's record."
    % (rel, owner, OWN_ROLE_FILE, OWN_DIR)
)
PY
# Shell layer: map anything that is not allow(0) or deny(2) to a deny(2).
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "ux-design-cycle: refused — fail-closed: internal error (path-ownership-gate judge exited $rc)." >&2
  exit 2
fi
exit "$rc"
