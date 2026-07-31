#!/usr/bin/env bash
# The role-agnostic gates (record-fields-gate.sh, trailer-gate.sh,
# handbook-trigger-gate.sh) this file used to exercise as subprocesses no
# longer have a local copy: they are core canon now (core/hooks/hooks.json
# fires them globally for every plugin install, issue-66). Their behavior is
# tested once, in core, not re-tested per rulebook — this file is retired to
# an empty pass rather than pointing at files that no longer exist here
# (issue-16). stub-check.sh (tests/stub-check.sh) is what now guards against
# a local copy silently reappearing.
set -uo pipefail
printf '\n== 0 passed, 0 failed (gates promoted to core canon; see tests/stub-check.sh) ==\n'
exit 0
