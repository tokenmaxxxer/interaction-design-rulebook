#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §21's
# bucket half — refuses writes under docs/ that would land outside the six
# doctrine buckets. Replicates coding-agent-rulebook's placement-gate.sh in
# shape, for the ux-design repo.
#
# Scope is docs/ and nothing else. Outside docs/ the gate is silent whatever
# the extension. Inside docs/ every file is governed: it must sit in one of
# the six buckets (decisions/, handbooks/, reports/, specs/, proposals/,
# _assets/). docs/README.md is the sole top-of-docs exception.
#
# Modeled fail-closed on ops-cycle/state-gate.sh: every malformed/missing-input
# branch DENIES (exit 2), never exits 0 silently. No kill switch and no
# DOCTRINE_OFF escape — a gate that can be switched off silently is not a gate.
# Genuinely-determined out-of-scope writes (outside the project, or not under
# docs/, or already in a recognized bucket) allow, as intended.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — doc-bucket-gate.sh requires python3, which is not on PATH; denying rather than guessing." >&2
  exit 2
}

payload="$(cat 2>/dev/null || true)"

rc=0
UXD_PAYLOAD="$payload" UXD_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" python3 <<'PY' || rc=$?
import json, os, posixpath, sys

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

BUCKETS = ("decisions", "handbooks", "reports", "specs", "proposals", "_assets")
SKIP_DIRS = (
    "node_modules", "vendor", "dist", "build", "target", "out",
    "venv", ".venv", "site-packages", "coverage",
)

def allow():
    sys.exit(0)

def deny(msg):
    sys.stderr.write("ux-design-cycle: refused — " + msg + "\n")
    sys.exit(2)

try:
    event = json.loads(os.environ.get("UXD_PAYLOAD", "") or "null")
except ValueError:
    deny("the tool-call payload is not valid JSON; the gate cannot judge a write it cannot parse.")
if not isinstance(event, dict):
    deny("the tool-call payload is not a JSON object; the gate cannot judge a write it cannot parse.")

tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse.")

path = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(path, str) or not path:
    deny("no usable file_path/notebook_path in tool_input; the gate cannot judge a write it cannot identify.")

normalized = path.replace("\\", "/")
root = (os.environ.get("UXD_ROOT") or os.getcwd()).replace("\\", "/")
absolute = posixpath.normpath(normalized if posixpath.isabs(normalized) else posixpath.join(root, normalized))
root = posixpath.normpath(root)

if absolute != root and not absolute.startswith(root + "/"):
    allow()

resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
if absolute != resolved:
    if resolved != real_root and not resolved.startswith(real_root + "/"):
        allow()
    absolute, root = resolved, real_root

relative = absolute[len(root) + 1:]
segments = [s for s in relative.split("/") if s not in ("", ".")]
if not segments:
    allow()

directories, name = segments[:-1], segments[-1]

if "docs" not in directories:
    allow()

if directories[-1] == "docs" and name == "README.md":
    allow()

scaffolding = None
for i, directory in enumerate(directories):
    if directory == "docs" or "docs" not in directories[:i]:
        continue
    if directory in BUCKETS:
        allow()
    if directory in SKIP_DIRS or directory.startswith("."):
        if os.path.isdir(posixpath.join(root, *directories[:i + 1])):
            allow()
        scaffolding = "/".join(directories[:i + 1])
    break

buckets = ", ".join(b + "/" for b in BUCKETS)
if scaffolding:
    reason = (
        "`%s` would create `%s`, a new directory under docs/ that is not one of the six "
        "buckets." % (relative, scaffolding)
    )
else:
    reason = (
        "`%s` is under docs/ but not in one of the six buckets. Every file under docs/ "
        "belongs to a bucket — images and attachments go in _assets/." % relative
    )

sys.stderr.write(
    "ux-design-cycle: refused — %s\nThe buckets are: %s.\nPer contract §21, classify by "
    "lifetime and write into a bucket; only docs/README.md may sit at the top of docs/.\n"
    % (reason, buckets)
)
sys.exit(2)
PY
# Shell layer: map anything that is not allow(0) or deny(2) to a deny(2).
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "ux-design-cycle: refused — fail-closed: internal error (doc-bucket-gate judge exited $rc)." >&2
  exit 2
fi
exit "$rc"
