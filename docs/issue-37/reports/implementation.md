---
code_under_review:
  - tests/lib/resolve-core.sh
  - tests/run-gate-tests.sh
  - interaction-design/plugins/id-accessibility-floor/tests/id-accessibility-floor-gate-tests.sh
  - interaction-design/plugins/id-citation-format/tests/id-citation-format-gate-tests.sh
  - interaction-design/plugins/id-nielsen-heuristics/tests/id-nielsen-heuristics-gate-tests.sh
  - interaction-design/plugins/id-persona-goal/tests/id-persona-goal-gate-tests.sh
  - interaction-design/plugins/id-proposal-shape/tests/id-proposal-shape-gate-tests.sh
  - interaction-design/plugins/id-stage-order/tests/id-stage-order-gate-tests.sh
  - interaction-design/plugins/id-state-completeness/tests/id-state-completeness-gate-tests.sh
  - interaction-design/plugins/id-task-flow/tests/id-task-flow-gate-tests.sh
  - interaction-design/plugins/id-traceability/tests/id-traceability-gate-tests.sh
  - interaction-design/plugins/id-usability-test-plan/tests/id-usability-test-plan-gate-tests.sh
  - interaction-design/plugins/id-wireframe-staging/tests/id-wireframe-staging-gate-tests.sh
  - docs/handbooks/tests.md
type: test-infra
breaking: false
verdict: pass
loop_state: landed
---

# issue-37 implementation record

## What was done
Adopted the canonical test-env resolution convention (on-the-record
`docs/specs/test-env-resolution.md`, issue #551) per the approved phase-1
proposal `docs/issue-37/proposals/2026-08-09-test-env-resolution-adoption.md`:

- Added `tests/lib/resolve-core.sh`: sourced Bash function
  `resolve_core_or_skip <repo_root>` implementing the convention's order —
  `$CLAUDE_PLUGIN_ROOT_CORE` (non-empty `hooks/lib/gate-lib.sh`) -> sibling
  `<repo_root>/core` (matching what each gate script itself already
  checks) -> SKIP (`SKIP: core plugin unreachable — unverifiable outside
  spawn env`, exit `75`).
- All 11 `interaction-design/plugins/*/tests/*-gate-tests.sh` suites now
  source this lib right after `set -uo pipefail`, call
  `resolve_core_or_skip` before any assertion, and export the resolved
  `CLAUDE_PLUGIN_ROOT_CORE` so the gate subprocess invocations below see
  it. No assertion logic changed.
- `tests/run-gate-tests.sh` now tracks a per-suite exit `75` as
  "skipped", distinct from "failed"; prints a SKIP line per skipped
  suite; exits `75` itself when every suite skipped (skipped/
  unverifiable, not failed); still exits `1` on any real failure.

## Why
Requirement per issue #37: gate-test scripts fail misleadingly on a
plain checkout without `CLAUDE_PLUGIN_ROOT_CORE` (each gate script fails
closed with exit 2 when core is unreachable, so "allow" assertions read
as false FAILs). Adopting the canonical convention turns that into an
explicit, distinct SKIP signal without weakening any assertion that runs
when core is reachable.

## Upstream / basis
docs/issue-37/proposals/2026-08-09-test-env-resolution-adoption.md
(approved via issue comment `APPROVE issue-37/implementation`, single-
account mode, listed in docs/specs/approvers.md).

## Doc placement ladder
- No new env var, config key, dependency, or migration introduced —
  nothing routes to a handbook.
- No library/format choice over a named alternative and no changed
  public signature/wire format beyond what the approved proposal's
  Rationale already recorded — no new `docs/issue-37/decisions/` entry.
- No benchmark/investigation numbers produced — no `docs/issue-37/reports/`
  entry beyond this record.

## What did not work
None.

## Verification performed (this session, once, per no-mock confirmation)
- `env -u CLAUDE_PLUGIN_ROOT_CORE bash tests/run-gate-tests.sh`: all 11
  suites print the SKIP message and exit 75; aggregator exits 75
  ("0 passed, 0 failed, 11 skipped ... skipped/unverifiable").
- `CLAUDE_PLUGIN_ROOT_CORE=<real core checkout> bash tests/run-gate-tests.sh`:
  all 11 suites pass unchanged, aggregator exits 0
  ("11 passed, 0 failed, 0 skipped").
- `bash tests/deny-only-check.sh`, `bash tests/stub-check.sh`,
  `bash tests/parse-check.sh`: unmodified, exit codes match the
  pre-change baseline (confirmed via `git stash`) — untouched per the
  proposal's Out of scope.
- `grep -rl test-env-resolution tests/ interaction-design/plugins/*/tests/`
  hits `tests/lib/resolve-core.sh` and all 11 suites (13 files).

## closed_checks
- SKIP contract on plain checkout (no CLAUDE_PLUGIN_ROOT_CORE) — exit 75,
  distinct message, zero misleading FAILs. code_under_review: pending-commit
- Passing-assertions-unchanged with core reachable. code_under_review: pending-commit
- Convention-doc grep hit across lib + all 11 suites. code_under_review: pending-commit
- Out-of-scope scripts (deny-only-check.sh, stub-check.sh, parse-check.sh)
  unaffected. code_under_review: pending-commit

## Phase-2 continuation verification (this session, once)
Re-ran every script under `tests/`, `*/tests/`, `*/hooks/tests/` with
`CLAUDE_PLUGIN_ROOT_CORE` unset (no `*/hooks/tests/` dirs exist in this
repo):
- `tests/lib/resolve-core.sh`-sourcing suites (all 11 plugin gate-tests +
  `tests/run-gate-tests.sh`): print SKIP, exit 75 as designed — already
  convention-compliant, no change needed.
- `tests/deny-only-check.sh`: exit 0, env-independent repo scan — no
  change needed.
- `tests/parse-check.sh`: exit 0, env-independent — no change needed.
- `tests/stub-check.sh`: exit 1 (FAIL), but confirmed env-independent —
  identical output/exit with `CLAUDE_PLUGIN_ROOT_CORE=/tmp/fake` set.
  The failure is a real, pre-existing defect unrelated to test-env
  resolution: it flags `tests/parse-check.sh` itself as a vendored
  drift copy of a file promoted to core canon (issue-66), per the
  script's own message. Not masked, not weakened — recorded here as an
  open finding rather than touched, since it is outside this issue's
  scope (test-env-resolution convention adoption) and outside the
  frozen write set.

## Open findings
- `tests/stub-check.sh` fails on this checkout independent of
  `CLAUDE_PLUGIN_ROOT_CORE`: it flags `tests/parse-check.sh` as a
  vendored copy of a file now living in core canon (core/hooks/hooks.json),
  per issue-66. Resolution path: delete the vendored copy and its
  hooks.json entry under a dedicated issue/proposal for issue-66 — out
  of scope for issue #37.

## Next steps
Commit this change on `issue-37/implementation`, push, and open the
phase-2 delivery PR with `Closes #37`; set `loop_state: landed` and
`code_under_review:` to the landing commit sha once committed.

## Resolution path
`tests/stub-check.sh` finding: delete the vendored `tests/parse-check.sh`
copy and its `hooks.json` entry under a separate issue-66 proposal — not
this issue's write set.

## Rationale for deviations
None — implementation matches the approved proposal's "What will be
done" with no scope-exceeded stop and no alternative swap.
