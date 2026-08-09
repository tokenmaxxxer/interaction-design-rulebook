---
status: proposed
files:
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
---

## Request
Adopt the canonical test-env resolution convention from on-the-record
`docs/specs/test-env-resolution.md` (issue #551) in this rulebook: on a
plain checkout with no `CLAUDE_PLUGIN_ROOT_CORE`, gate-test scripts must
SKIP (explicit message, exit `75`) instead of failing misleadingly;
assertions that already pass when core is reachable stay unchanged.

## Constraints
- Never weaken an assertion that runs when core IS reachable.
- SKIP exit code must be distinct from a gate's own pass(0)/fail(1)/deny(2)
  — the convention fixes this at `75` (`EX_TEMPFAIL`).
- No network fetch as part of the SKIP contract (convention doc is
  explicit that this is out of scope for the canonical resolver).
- Each script must reference the convention doc (`test-env-resolution`)
  so the acceptance grep passes.
- `tests/deny-only-check.sh`, `tests/stub-check.sh`, `tests/parse-check.sh`
  have no core dependency (verified: no `CLAUDE_PLUGIN_ROOT_CORE` or
  `gate-lib` references) — out of scope, same as the convention doc's own
  enumerated `test_skip_gate.py` exception.

## Rationale
Considered vendoring/mirroring the sibling rulebooks' existing
`tests/resolve-core.sh` pattern (found in `data-modeling-rulebook`,
`test-authoring-rulebook`, `user-discovery-rulebook` — see survey.md) — it
shallow-clones `tokenmaxxxer-core` over the network when
`CLAUDE_PLUGIN_ROOT_CORE` is unset, then exports it and lets the suite run
for real. Rejected: it never implements the SKIP branch at all — a
network failure or slow clone still surfaces as a misleading test
failure, which is exactly the ambiguity issue #37 (and the convention
doc's own text, calling out "one rulebook's ad hoc script" by this same
shape) says the canonical convention exists to remove. A static
candidate-list + SKIP resolver, sourced by each suite, matches the
convention's Bash-test-runner adoption guidance directly and adds no new
runtime dependency (no network call, no new binary).

## What will be done
- Add `tests/lib/resolve-core.sh`: a sourced Bash function
  `resolve_core_or_skip <repo_root>` implementing the convention's order —
  `$CLAUDE_PLUGIN_ROOT_CORE` (non-empty `hooks/lib/gate-lib.sh`) -> static
  sibling candidates (matching what each gate script itself already
  checks, e.g. `<repo_root>/core`) -> SKIP: print the convention's exact
  message to stderr and `exit 75`. Header comment cites
  `docs/specs/test-env-resolution.md` (on-the-record #551) verbatim.
- Each of the 11 `interaction-design/plugins/*/tests/*-gate-tests.sh`
  suites sources this lib at the top and calls it before invoking its
  gate subprocess; on SKIP (exit 75) the suite exits 75 immediately
  without running any assertion. When core resolves, the suite proceeds
  exactly as today — no assertion logic changes.
- `tests/run-gate-tests.sh` aggregator: track a per-suite exit-75 as
  "skipped", distinct from "failed"; print a SKIP line per skipped suite;
  a run that is all-skips is reported skipped/unverifiable, not failed
  (no false green, no false red); any real (non-env) failure still fails
  the aggregate.

## Out of scope
- Any change to gate script (`*-gate.sh`) resolution or fail-closed
  behavior itself — those already resolve core correctly today; only the
  test scripts that wrap them change.
- `tests/deny-only-check.sh`, `tests/stub-check.sh`, `tests/parse-check.sh`
  — no core dependency, nothing to adopt.
- Adopting the convention in any other rulebook repo (convention doc's
  own Out of scope section: per-repo work, tracked separately).
- Vendoring the convention doc's Python reference module — this repo's
  suites are pure Bash; the Bash-adoption shape is used instead.

## How you'll know it worked
- `unset CLAUDE_PLUGIN_ROOT_CORE && bash tests/run-gate-tests.sh` exits
  with the SKIP contract (per-suite exit 75, explicit SKIP message,
  aggregate reports skipped/unverifiable) — zero misleading FAILs, in
  contrast to today's confirmed `0 passed, 11 failed`.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a real core checkout (or a
  resolvable sibling candidate), all assertions that pass today still
  pass, unchanged.
- `grep -rl test-env-resolution tests/ interaction-design/plugins/*/tests/`
  hits `tests/lib/resolve-core.sh` and all 11 suites.
