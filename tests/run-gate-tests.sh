#!/usr/bin/env bash
# The role-agnostic gates (record-fields-gate.sh, trailer-gate.sh,
# handbook-trigger-gate.sh) this file used to exercise as subprocesses no
# longer have a local copy: they are core canon now (core/hooks/hooks.json
# fires them globally for every plugin install, issue-66). Their behavior is
# tested once, in core, not re-tested per rulebook — this stays retired
# (issue-16). stub-check.sh (tests/stub-check.sh) is what now guards against
# a local copy silently reappearing.
#
# issue-24: this file gains one job — aggregate the eleven
# interaction-design/plugins/*/tests/*-gate-tests.sh suites into one combined
# pass/fail signal, so a reviewer running only this script gets an
# accurate result (each plugin suite still runs and prints its own
# output for attribution, per issue-21 §6 — this is an aggregator, not a
# replacement suite).
set -uo pipefail

# issue-37: canonical test-env resolution convention (on-the-record #551,
# docs/specs/test-env-resolution.md) — a per-suite exit 75 means core was
# unreachable outside the spawn env, tracked as "skipped", never folded
# into "failed" (a run that is all-skips must not report false green or
# false red).
EX_TEMPFAIL=75

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
total=0
failed=0
skipped=0

for t in "$repo_root"/interaction-design/plugins/*/tests/*-gate-tests.sh; do
  [ -f "$t" ] || continue
  total=$((total + 1))
  echo "== $t =="
  /bin/bash "$t"
  rc=$?
  if [ "$rc" -eq "$EX_TEMPFAIL" ]; then
    skipped=$((skipped + 1))
    echo "-- SKIPPED: $t" >&2
  elif [ "$rc" -ne 0 ]; then
    failed=$((failed + 1))
    echo "!! FAILED: $t" >&2
  fi
done

[ "$total" -gt 0 ] || { echo "refused: zero plugin test suites found under interaction-design/plugins/*/tests/ — glob mismatch or missing directory" >&2; exit 2; }

passed=$((total - failed - skipped))
printf '\n== %d passed, %d failed, %d skipped (gates promoted to core canon; see tests/stub-check.sh) ==\n' "$passed" "$failed" "$skipped"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
if [ "$skipped" -eq "$total" ]; then
  echo "skipped/unverifiable: core plugin unreachable outside spawn env for every suite" >&2
  exit "$EX_TEMPFAIL"
fi
exit 0
