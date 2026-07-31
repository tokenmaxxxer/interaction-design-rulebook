# id-traceability

Row 10 of the interaction-design gate machine (see
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`,
§3 and §4): traceability/scope-growth flagging and the spec-only output
boundary, phase 2 only.

## What it owns

Exactly the phase-2 record's traceability/scope-growth section and its
spec-only boundary statement. It does not own persona/goal reference,
task-flow shape, state coverage, wireframe staging, the Nielsen
heuristic pass, the accessibility floor, or the usability-test plan —
those belong to the sibling `id-*` plugins. It does not own stage
ordering (`id-stage-order` owns that, reading `.status.json` written
here).

## Gate

`hooks/traceability-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`.
Fires only on `docs/issue-<n>/reports/interaction-design.md` (this
repo's phase-2 record write surface). Fail-closed: any inability to
parse the payload, resolve the project root, or determine the resulting
content denies rather than guesses.

Checks, on the resulting document text (the write about to happen, not
disk state — per the proposal's gate-matching strategy):

1. A heading matching `/^#+\s*.*\b(traceability|scope\s+growth)\b/i`
   must exist. No heading -> deny.
2. The section body (heading to next heading, or EOF) must not be
   blank. Heading present but blank body is a stub -> deny.
3. The body must contain an explicit spec-only boundary statement
   matching `/\bspec[\s-]only\b/i` -> deny if missing.
4. The body must contain at least one scope-growth flag field — a
   line/bullet containing the words "scope growth" or "scope-growth",
   even if its value is empty (e.g. "Scope growth: none" is enough;
   the field KEY must be present) -> deny if missing.

Denies with `id-traceability: refused — <reason>`, exit 2, naming
exactly what's missing (no heading / missing spec-only statement /
missing scope-growth field / stub).

On a passing write, best-effort updates the shared per-issue state file
`docs/issue-<n>/reports/interaction-design/.status.json`, setting
`data["issue-<n>"]["traceability"] = "ok"`. This is a side write only —
it never blocks the underlying content write on its own failure.

## Kill switch

`export ID_TRACEABILITY_GATE_OFF=1` disables this plugin's gate only,
independent of the other `id-*` plugins' gates.

## Directive

`hooks/directive.sh` — SessionStart directive, sourced from
`core/hooks/lib/role-directive.sh` per this repo's convention (see
`ux-design/hooks/directive.sh`). States YOU DECIDE / USE_WHEN /
PRODUCES / HAND-OFF for the traceability/scope-growth check.

## Composition

Per the approved proposal's phase-2 judgment norm (§4): `id-traceability`
is one of nine plugins ANDed together (`id-persona-goal` ∧ `id-task-flow`
∧ `id-state-completeness` ∧ `id-wireframe-staging` ∧
`id-nielsen-heuristics` ∧ `id-accessibility-floor` ∧
`id-usability-test-plan` ∧ `id-traceability` ∧ `id-stage-order`) that
together form the phase-2 quality bar on
`docs/issue-<n>/reports/interaction-design.md`. Each plugin can be
killed independently without breaking the others — composition is
additive, not all-or-nothing.

## Tests

`tests/id-traceability-gate-tests.sh` — plain bash, this repo's
convention (no bats). Covers: full record allows; missing spec-only
statement denies; missing scope-growth field denies; blank-body stub
denies; no heading denies; unrelated write path allows. Exit 0 if all
pass, else 1.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full gate-machine design this plugin implements.
