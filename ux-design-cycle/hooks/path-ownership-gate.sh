#!/usr/bin/env bash
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

UXD_PAYLOAD="$payload" UXD_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" python3 <<'PY'
import json, os, posixpath, re, sys

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

RECORDS_RE = re.compile(r'^docs/reports/records/([^/]+)/([^/]+\.md)$')
OWN_ROLE_FILE = "ux-design.md"

m = RECORDS_RE.match(rel)
if not m:
    allow()

subject, role_file = m.group(1), m.group(2)
if role_file != OWN_ROLE_FILE:
    owner = role_file[:-3] if role_file.endswith(".md") else role_file
    deny(
        "'%s' is owned by role '%s' per contract §11, not 'ux-design' (ux-design owns only "
        "docs/reports/records/<subject>/%s). Report the conflict; do not overwrite or merge "
        "into another role's record." % (rel, owner, OWN_ROLE_FILE)
    )

allow()
PY
