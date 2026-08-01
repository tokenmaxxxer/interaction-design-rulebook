# id-persona-goal

Third plugin in the interaction-design phase-2 judgment chain, per
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§3/§4:

`id-proposal-shape` -> `id-citation-format` -> **`id-persona-goal`** ->
`id-task-flow` -> `id-state-completeness` -> `id-wireframe-staging` ->
`id-nielsen-heuristics` -> `id-accessibility-floor` ->
`id-usability-test-plan` -> `id-traceability` (plus the cross-cutting
`id-stage-order`).

## What it owns

Row 3 of the proposal's plugin catalog: the Cooper goal-directed-design
persona/goal model. This plugin owns exactly that judgment — it does
not check task flows, states, wireframe staging, or any of the other
eight phase-2 methodologies; each of those is a sibling plugin's
concern.

Design source: `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`,
§3 plugin catalog (row `id-persona-goal`) and §4 per-plugin pattern
table.

## Components

- `hooks/directive.sh` — SessionStart directive slice: YOU DECIDE /
  USE_WHEN / PRODUCES / HAND-OFF for the persona/goal judgment, sourced
  via the shared core `role-directive.sh` library
  (`${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/role-directive.sh`, same
  convention as the umbrella `interaction-design/hooks/directive.sh`).
- `hooks/persona-goal-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`,
  narrowed to this plugin's one concern:
  - heading check: a heading matching
    `/^#+\s*.*\b(persona|user\s+goal)\b/i` must exist in the write's
    resulting content.
  - content check: under that heading (before the next heading of
    same-or-higher level), at least one named-persona sub-item and a
    separate line/field naming a non-blank `goal`.
  - stub check: a matched heading with a blank/whitespace-only body is
    denied, matching this repo's stub convention
    (see `tests/stub-check.sh`).
  - Only acts on `docs/issue-<n>/reports/interaction-design.md` — any
    other write path is allowed without inspection (`exit 0`
    immediately).
- `agents/persona-goal-checklist.md` — short walked checklist for the
  judgment the gate script cannot make structurally: is this a genuine
  Cooper-style persona/goal, or a role label / task / feature request
  dressed up as one. Distinguishes goal (outcome) from task (How) and
  from feature request; covers persona count (Cooper's small-set,
  one-primary guidance) and the market-segment-as-persona red flag.
- `tests/id-persona-goal-gate-tests.sh` — plain-bash test script (this
  repo's convention, not bats — see `tests/deny-only-check.sh` and
  `tests/stub-check.sh`), covering the five cases in §6 of the
  gate-machine proposal for this plugin: full persona/goal block
  (allow), blank-body stub (deny), role label with no separate goal
  field (deny), no persona/goal heading at all (deny), and an unrelated
  write path (allow regardless of content).

## Target write surface

`docs/issue-<n>/reports/interaction-design.md` — the phase-2 record
(NOT `ux-design.md`; see `docs/issue-15/reports/interaction-design.md`
for the convention this repo already uses). Writes outside this pattern
are ignored (`exit 0` immediately, no content inspection).

## Kill switch

`ID_PERSONA_GOAL_GATE_OFF=1` disables this plugin's gate only, without
touching any sibling phase-2 plugin's independent kill switch.

## State-file contract

On a passing check, this plugin best-effort-writes to the shared
per-subject state file:

`docs/issue-<n>/reports/interaction-design/.status.json`

```json
{
  "issue-<n>": {
    "persona_goal": "ok"
  }
}
```

The file is a merge-loaded JSON object keyed by `issue-<n>`; sibling
phase-2 plugins (and `id-stage-order`) read/write sibling keys in the
same per-subject object. This state-file write is auxiliary: a failure
to update it warns to stderr but does not flip the gate to deny — the
heading/content check above is the fail-closed surface, not the
state-tracking write.

## Composition with the rest of phase 2

Per §4 of the gate-machine proposal, the phase-2 judgment norm is the
conjunction of all nine judgment plugins (`id-persona-goal` among them)
AND `id-stage-order`. This plugin's `allow` is necessary but not
sufficient for a phase-2 write to be accepted overall — the sibling
plugins and `id-stage-order` each independently gate the same write
surface for their own concern.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full plugin catalog and the approved design this plugin
implements.
