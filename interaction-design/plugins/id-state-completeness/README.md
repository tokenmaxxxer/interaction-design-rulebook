# id-state-completeness

Phase-2 plugin in the interaction-design gate machine (see
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`, §3
row `id-state-completeness`, §4 pattern table). Mechanical pattern check,
no agent — per §7 of the proposal.

## What it owns

Exactly one methodology concern: that the interaction-design record's
states/state-coverage section names, for every screen/flow it lists, all
four required states — `default`, `empty`, `error`, `loading` — explicitly.
It does not own screen/flow inventory, heuristic checks, accessibility, or
any other concern in the gate machine — those belong to sibling plugins in
the same plugin set.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN /
  PRODUCES / HAND-OFF for the state-completeness step, sourced from the
  shared `core/hooks/lib/role-directive.sh` convention.
- `hooks/state-completeness-gate.sh` — PreToolUse gate on
  `Write|Edit|MultiEdit`. Fails closed on any write to
  `docs/issue-<n>/reports/interaction-design.md` where:
  - no heading matches `/^#+\s*.*\b(states?|state\s+coverage)\b/i` (deny:
    "no states heading"),
  - the matched heading's body is blank (deny: stub),
  - the heading names no screen/flow sub-entry at all and the section body
    as a whole is missing any of the four required words (deny, naming the
    missing words), or
  - any named screen/flow entry (a sub-heading deeper than the states
    heading, or a bold-labeled sub-item) is missing any of `default`,
    `empty`, `error`, `loading` before the next sibling entry or the next
    same-or-higher heading (deny, naming exactly which words are missing
    per entry).

  Denies with `id-state-completeness: refused — %s`. Kill switch:
  `ID_STATE_COMPLETENESS_GATE_OFF`.
- `tests/id-state-completeness-gate-tests.sh` — plain-bash test suite (this
  repo's convention, not bats): all-four-named allow, missing-one-word
  deny, stub-body deny, no-heading deny, unrelated-path allow.

## Kill switch

`export ID_STATE_COMPLETENESS_GATE_OFF=1` disables this plugin's gate
only, independent of any other plugin's gate in the set.

## Status file

On a passing write, the gate records the result to
`docs/issue-<n>/reports/interaction-design/.status.json`, keyed by subject
(`"issue-<n>"`), setting `state_completeness` to `"ok"`, e.g.
`{"issue-42": {"state_completeness": "ok"}}`. This is a best-effort side
write — it never blocks the underlying content write on its own failure.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full plugin-set design this plugin implements.
