#!/usr/bin/env bash
# PreToolUse hook (Bash matching 'git commit'): enforces contract §13's commit
# trailer requirement for the ux-design rulebook. A commit landing ux-design's
# record must carry a machine-checkable trailer identifying `subject` and
# `kind`. This repo declares its trailer keys as `Subject:` and `Kind:`
# (each on its own line in the commit message body).
#
# Fires only on `git commit` invocations; any other Bash command passes
# through untouched. The commit message is extracted from the common
# invocation forms (-m/--message, repeated -m, -m=, and heredoc-fed -F -).
# If the gate is looking at a git commit whose message it cannot read (an
# editor commit, -F <file>, or an unparseable form), it DENIES fail-closed:
# it cannot verify the trailer, so it refuses rather than let an untrailer'd
# commit through.
#
# Modeled fail-closed on ops-cycle/state-gate.sh: every malformed/missing-input
# branch DENIES (exit 2), never exits 0 silently. No kill switch.
set -euo pipefail

command -v python3 >/dev/null 2>&1 || {
  echo "ux-design-cycle: refused — trailer-gate.sh requires python3, which is not on PATH; denying rather than guessing." >&2
  exit 2
}

payload="$(cat 2>/dev/null || true)"

UXD_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, shlex, sys

def deny(msg):
    sys.stderr.write("ux-design-cycle: refused — " + msg + "\n")
    sys.exit(2)

raw = os.environ.get("UXD_PAYLOAD", "")
try:
    event = json.loads(raw) if raw else None
except ValueError:
    deny("the tool-call payload is not valid JSON; the gate cannot judge a commit it cannot parse.")
if not isinstance(event, dict):
    deny("the tool-call payload is not a JSON object; the gate cannot judge a commit it cannot parse.")

# Only Bash git-commit calls are this gate's business.
if event.get("tool_name") != "Bash":
    sys.exit(0)
tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("tool_input is missing or not a JSON object; the gate cannot judge a commit it cannot parse.")
command = tool_input.get("command")
if not isinstance(command, str) or not command.strip():
    deny("the Bash command is missing or not a string; the gate cannot judge a commit it cannot read.")

if not re.search(r"\bgit\b.*\bcommit\b", command):
    sys.exit(0)

# A commit that does not actually create a commit object (e.g. --dry-run) is
# not a landing; but to stay fail-closed we only skip on an explicit dry run.
if re.search(r"(^|\s)--dry-run(\s|$|=)", command):
    sys.exit(0)

# Try to extract the commit message from the git commit invocation. We handle
# the -m/--message forms via shlex tokenization of the git-commit segment.
# Heredoc-fed messages (git commit -F - <<'EOF' ... EOF) are extracted from
# the raw text.
messages = []

# heredoc form: capture body of a here-document feeding the commit.
for hm in re.finditer(r"<<-?\s*(['\"]?)(\w+)\1\s*\n(.*?)\n\2", command, re.S):
    messages.append(hm.group(3))

# tokenized -m/--message forms.
try:
    tokens = shlex.split(command, comments=False, posix=True)
except ValueError:
    tokens = None

if tokens is not None:
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t in ("-m", "--message"):
            if i + 1 < len(tokens):
                messages.append(tokens[i + 1])
                i += 2
                continue
        elif t.startswith("-m") and len(t) > 2:
            messages.append(t[2:])
        elif t.startswith("--message="):
            messages.append(t[len("--message="):])
        i += 1

# A commit that reads its message from a file or the editor cannot be checked
# here; also an -F/--file form. Fail closed: we cannot verify the trailer.
uses_file_or_editor = bool(re.search(r"(^|\s)(-F|--file)(\s|=)", command))

if not messages:
    if uses_file_or_editor:
        deny(
            "this git commit takes its message from a file/editor (-F/--file or the default "
            "editor), so the gate cannot read it to verify the §13 trailer. Pass the message "
            "inline with -m (including the `Subject:` and `Kind:` trailer lines) so the "
            "trailer can be checked."
        )
    deny(
        "this git commit has no inline message the gate can read (no -m/--message and no "
        "recognized heredoc). Per contract §13 the commit must carry a machine-checkable "
        "trailer; pass it inline with -m so the gate can verify it."
    )

full = "\n".join(messages)

has_subject = re.search(r"(?mi)^\s*Subject:\s*\S+", full) is not None
has_kind = re.search(r"(?mi)^\s*Kind:\s*\S+", full) is not None

missing = []
if not has_subject:
    missing.append("`Subject:` (the stable subject identifier)")
if not has_kind:
    missing.append("`Kind:` (the artifact kind, e.g. ux-design-record)")

if missing:
    deny(
        "the commit message is missing required §13 trailer line(s): " + ", ".join(missing) +
        ". Every ux-design commit landing a record must carry a machine-checkable trailer "
        "identifying subject and kind. Add the trailer line(s) and recommit."
    )

sys.exit(0)
PY
