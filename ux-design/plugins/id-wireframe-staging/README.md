# id-wireframe-staging

One plugin in the `interaction-design` phase-2 gate machine (nine
row-owning plugins plus `id-stage-order`, conjoined per
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§4) that together gate the write of
`docs/issue-<n>/reports/interaction-design.md`, the phase-2 record.

## What it owns

Exactly row 6 of the gate machine: the lo-fi-before-hi-fi wireframe
fidelity staging check. It does not own goal/persona reference, the
task-flow artifact, the Nielsen heuristic pass, the accessibility
floor, the usability-test plan, traceability/scope-growth, or stage
ordering — those belong to the sibling plugins in the set
(`id-state-completeness`, `id-nielsen-heuristics`,
`id-accessibility-floor`, `id-usability-test-plan`, `id-traceability`,
`id-stage-order`). Per §7 of the proposal, this check is mechanical —
no agent, just a deterministic heading/order check.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN
  / PRODUCES / HAND-OFF for the wireframe-staging step, sourced from
  the shared `core/hooks/lib/role-directive.sh` convention.
- `hooks/wireframe-staging-gate.sh` — PreToolUse gate on
  `Write|Edit|MultiEdit`. Fails closed on any write to
  `docs/issue-<n>/reports/interaction-design.md` whose matched
  wireframe/fidelity heading (`/^#+\s*.*\b(wireframe|fidelity)\b/i`)
  lacks two distinct staged sub-headings — one matching
  `/lo(w)?[\s-]?fi/i`, one matching `/hi(gh)?[\s-]?fi/i` — each with
  non-blank content, with the lo-fi sub-heading appearing (by line
  number) before the hi-fi sub-heading. Denies with
  `id-wireframe-staging: refused — %s`, naming exactly what's wrong:
  missing lo-fi, missing hi-fi, wrong order, or a stub (heading present,
  blank body). Writes that don't touch the phase-2 record, or that
  touch it but contain no wireframe/fidelity heading at all, pass
  through untouched — this plugin only judges staging quality once the
  heading exists (heading presence is another plugin's concern). Kill
  switch: `ID_WIREFRAME_STAGING_GATE_OFF`.
- `tests/id-wireframe-staging-gate-tests.sh` — plain-bash spec (this
  repo's convention, not bats), covering: lo-fi before hi-fi both
  non-blank (allow); hi-fi before lo-fi (deny); only lo-fi present
  (deny); heading present but blank stage bodies (deny); an unrelated
  write path (allow).

## Kill switch

`export ID_WIREFRAME_STAGING_GATE_OFF=1` disables this plugin's gate
only, independent of the other row-owning plugins' gates.

## State file

On a passing write, the gate records the result to
`docs/issue-<n>/reports/interaction-design/.status.json`, keyed by
subject (`"issue-<n>"`), setting `wireframe_staging` to `"ok"`, e.g.
`{"issue-<n>": {"wireframe_staging": "ok"}}`. This is a best-effort
side write — it never blocks the underlying content write on its own
failure. `id-stage-order` owns the `.status.json` schema and reads
this same key as part of enforcing that every row-owning plugin ran
before the record is treated as complete.

See
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(§3 row `id-wireframe-staging`, §4 pattern table, §7 mechanical-vs-agent
split) for the full design this plugin implements.
