#!/usr/bin/env bash
# Canonical test-env resolution convention (on-the-record issue #551,
# docs/specs/test-env-resolution.md). Sourced by each gate-test suite to
# resolve core's plugin root the same way the gate scripts under test do,
# and to SKIP (not fail) when core is unreachable outside the spawn env.
#
# Usage:
#   . "<repo_root>/tests/lib/resolve-core.sh"
#   resolve_core_or_skip "<repo_root>" || exit $?
#   export CLAUDE_PLUGIN_ROOT_CORE="$RESOLVED_CORE"

SKIP_MESSAGE="SKIP: core plugin unreachable — unverifiable outside spawn env"
EX_TEMPFAIL=75  # BSD sysexits EX_TEMPFAIL — never collides with a gate's own 0/1/2 exits.

_resolve_core_has_gate_lib() {
  # size check, not just existence: an empty stub gate-lib.sh must not
  # read as "core reachable" (mirrors the reference resolver's guard).
  candidate="$1"
  path="$candidate/hooks/lib/gate-lib.sh"
  [ -s "$path" ]
}

# resolve_core_or_skip <repo_root>
# Order: $CLAUDE_PLUGIN_ROOT_CORE (if it contains gate-lib.sh) -> the
# sibling candidate each gate script itself checks (<repo_root>/core) ->
# SKIP. Sets RESOLVED_CORE on success; prints the SKIP message to stderr
# and returns 75 otherwise.
resolve_core_or_skip() {
  repo_root="$1"

  if [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && _resolve_core_has_gate_lib "$CLAUDE_PLUGIN_ROOT_CORE"; then
    RESOLVED_CORE="$CLAUDE_PLUGIN_ROOT_CORE"
    return 0
  fi

  if _resolve_core_has_gate_lib "$repo_root/core"; then
    RESOLVED_CORE="$repo_root/core"
    return 0
  fi

  echo "$SKIP_MESSAGE" >&2
  return "$EX_TEMPFAIL"
}
