# id-accessibility-floor

Row 8 of the `interaction-design` phase-2 gate-machine plugin set (see
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§3), enforcing the WCAG 2.1 AA accessibility floor as a mechanical
pattern check — no agent, per §7 of the proposal.

## What it owns

Exactly one concern: whether the phase-2 interaction-design record
(`docs/issue-<n>/reports/interaction-design.md`) contains an
accessibility section that names an explicit conformance level and
gives concrete coverage, not just the bare word "accessible." It does
not own the heuristic evaluation, task-flow completeness,
usability-test plan, traceability, or stage ordering — those belong to
the sibling `id-*` plugins in the set. A false positive here cannot
block a write that only, say, `id-nielsen-heuristics` cares about, and
this plugin can be killed independently of the others.

## The gate

`hooks/accessibility-gate.sh` fires on `PreToolUse` for
`Write|Edit|MultiEdit`, fail-closed, and acts only on writes matching
`^docs/issue-([0-9]+)/reports/interaction-design\.md$`. Per §4's
per-plugin matching table:

- **Heading**: `/^#+\s*.*\b(wcag|accessibility)\b/i` — no matching
  heading is a deny.
- **Body** (from the heading to the next same-or-higher-level heading):
  - blank/whitespace-only body is a stub, treated as absent (matching
    this repo's `tests/stub-check.sh` convention) — deny.
  - must contain an explicit level mention matching `/\b2\.1\s*AA\b/i`
    (or an equivalent explicitly named level) — missing this is a deny.
  - must mention at least two of `keyboard`, `focus`, `label`,
    `contrast` (case-insensitive) — the bare word "accessible" alone,
    with nothing concrete, is a deny.

On a passing write it denies never; it exits 0 and best-effort updates
`docs/issue-<n>/reports/interaction-design/.status.json`, setting
`data["issue-<n>"]["accessibility_floor"] = "ok"`. This is a
best-effort side write — it never blocks the underlying content write
on its own failure.

`hooks/directive.sh` fires on `SessionStart`, sourcing the shared
`core/hooks/lib/role-directive.sh` convention, and states the
accessibility-floor-specific YOU_DECIDE / USE_WHEN / PRODUCES / HAND-OFF
values.

## Kill switch

`export ID_ACCESSIBILITY_FLOOR_GATE_OFF=1` disables this plugin's gate
only, independent of every other `id-*` plugin's gate, following the
existing `UX_DESIGN_CYCLE_OFF` convention.

## Composition (phase-2 norm)

Per proposal §4, phase-2's norm is the conjunction of nine plugins:
`id-nielsen-heuristics ∧ id-accessibility-floor ∧ id-usability-test-plan
∧ id-traceability ∧ id-stage-order` (plus the phase-1 plugins not
relevant here), all firing on
`docs/issue-<n>/reports/interaction-design.md`. `id-stage-order` is the
one cross-cutting plugin; every other plugin, this one included, reads
`.status.json` only to confirm the required earlier stage is `done`
before enforcing its own concern — no plugin-to-plugin code dependency,
only the shared on-disk contract.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full approved design this plugin implements.
