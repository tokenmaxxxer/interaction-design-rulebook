#!/usr/bin/env bash
# fail-closed trap-at-top: any abort before verdict logic (failed source,
# set -e abort, unbound var) forces exit 2 (DENY). Must stay the FIRST
# executable statement, above set/source, and not be overwritten by a later
# EXIT trap. Composes with the python try/except and shell exit-code remap.
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Bash matching 'git commit'): enforces contract §21's
# handbook-trigger half. When the commit's changed-file set introduces or
# changes an operational surface (env-var example, config key manifest,
# dependency manifest, migration, or run/setup/deploy script) but the same
# commit does not also touch any docs/handbooks/<component>.md, the commit is
# refused. §21 requires the handbook be updated in the same unit of work.
#
# Fires only on `git commit` invocations; any other Bash command passes
# through untouched (that is scope, not fail-open). The changed-file set is
# read from the git index (staged changes) at the repo the commit runs in.
#
# Operational-surface path heuristics for this repo (each rulebook declares
# its own): dependency/build manifests (package.json, pyproject.toml,
# requirements*.txt, Dockerfile, docker-compose*, go.mod, Cargo.toml,
# Gemfile), env examples (*.env.example, .env.example), migration dirs
# (**/migrations/**), CI/deploy workflows (.github/workflows/**), and
# run/setup/deploy scripts (install.sh, setup.sh, deploy*.sh, run*.sh).
#
# Modeled fail-closed on ops-cycle/state-gate.sh: every malformed/missing-input
# branch DENIES (exit 2), never exits 0 silently. No kill switch.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — handbook-trigger-gate.sh requires python3, which is not on PATH; denying rather than guessing." >&2
  exit 2
}
command -v git >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — handbook-trigger-gate.sh requires git, which is not on PATH; denying rather than guessing." >&2
  exit 2
}

payload="$(cat 2>/dev/null || true)"

# Extract the Bash command; decide if this is a git commit.
cmd="$(UXD_PAYLOAD="$payload" python3 -c '
import json, os, sys
raw = os.environ.get("UXD_PAYLOAD", "")
try:
    e = json.loads(raw) if raw else None
except ValueError:
    sys.exit(3)
if not isinstance(e, dict):
    sys.exit(3)
if e.get("tool_name") != "Bash":
    sys.exit(0)
ti = e.get("tool_input")
if not isinstance(ti, dict):
    sys.exit(3)
c = ti.get("command")
if not isinstance(c, str):
    sys.exit(3)
sys.stdout.write(c)
' 2>/dev/null)" || {
  rc=$?
  if [ "$rc" = "3" ]; then
    echo "ux-design-cycle: refused — handbook-trigger-gate.sh could not parse the tool payload (malformed JSON or missing command); denying rather than guessing." >&2
    exit 2
  fi
  # Any other nonzero exit is an unexpected crash of the extractor (e.g. an
  # interpreter error on a hostile payload). Fail closed rather than the old
  # silent `exit 0` pass-through.
  echo "ux-design-cycle: refused — fail-closed: internal error (handbook-trigger command extractor exited $rc)." >&2
  exit 2
}

# Not a Bash tool call (empty cmd) or not a git commit -> not our business.
[ -n "$cmd" ] || exit 0
printf '%s' "$cmd" | grep -Eq '\bgit\b.*\bcommit\b' || exit 0

# Changed-file set = staged names. Fail closed if we cannot read the index.
changed="$(git diff --cached --name-only 2>/dev/null)" || {
  echo "ux-design-cycle: refused — handbook-trigger-gate.sh could not read the staged file set (git diff --cached failed); denying rather than committing a possibly-unhandbooked operational change." >&2
  exit 2
}

rc=0
UXD_CHANGED="$changed" python3 <<'PY' || rc=$?
import os, posixpath, re, sys

# Fail-closed python layer: any uncaught exception becomes exit 2 (DENY).
# SystemExit from deny()/sys.exit(0) bypasses this hook, preserving verdicts.
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

files = [f for f in (os.environ.get("UXD_CHANGED", "") or "").splitlines() if f.strip()]
if not files:
    # Nothing staged: an empty commit or --amend with no staged diff. Nothing
    # for this gate to enforce (no operational surface changed here).
    sys.exit(0)

def base(f):
    return posixpath.basename(f)

MANIFEST_NAMES = {
    "package.json", "pyproject.toml", "dockerfile", "go.mod", "cargo.toml",
    "gemfile", "pipfile", "setup.py", "setup.cfg",
}
def is_surface(f):
    b = base(f).lower()
    if b in MANIFEST_NAMES:
        return "dependency/build manifest"
    if re.match(r"requirements.*\.txt$", b):
        return "dependency manifest"
    if b.startswith("docker-compose"):
        return "container compose manifest"
    if b.endswith(".env.example") or b == ".env.example":
        return "env-var example"
    if "/migrations/" in ("/" + f + "/"):
        return "migration"
    if f.startswith(".github/workflows/"):
        return "CI/deploy workflow"
    if re.match(r"(install|setup|deploy|run)[^/]*\.sh$", b):
        return "run/setup/deploy script"
    return None

surfaces = [(f, is_surface(f)) for f in files]
surfaces = [(f, k) for (f, k) in surfaces if k]
if not surfaces:
    sys.exit(0)

touches_handbook = any(
    f.startswith("docs/handbooks/") and f.endswith(".md") for f in files
)
if touches_handbook:
    sys.exit(0)

f0, k0 = surfaces[0]
deny(
    "this commit changes %s (operational surface: %s) but does not touch any "
    "docs/handbooks/<component>.md. Per contract §21, update the component's handbook in "
    "the same unit of work (what it is, what it defaults to, what breaks without it, and "
    "the commands to install/run/operate it)." % (f0, k0)
)
PY
# Shell layer: map anything that is not allow(0) or deny(2) to a deny(2).
if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
  echo "ux-design-cycle: refused — fail-closed: internal error (handbook-trigger judge exited $rc)." >&2
  exit 2
fi
exit "$rc"
