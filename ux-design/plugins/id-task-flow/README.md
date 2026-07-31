# id-task-flow

Owns exactly row 4 of `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§2/§3: the **distinct task/interaction-flow artifact** methodology, phase 2
only. Purely mechanical (§7) — no agent/checklist component.

## What it checks

On any `Write`/`Edit`/`MultiEdit` targeting
`docs/issue-<n>/reports/interaction-design.md` (this repo's phase-2 record
file — see `docs/issue-15/reports/interaction-design.md`), the gate computes
the resulting document content and requires:

1. A heading matching `/^#+\s*.*\b(task\s+flow|interaction\s+flow)\b/i`
   exists.
2. That heading's body (everything up to the next same-or-higher-level
   heading) is non-blank — a heading with a blank/whitespace-only body
   counts as absent, matching this repo's `tests/stub-check.sh` stub
   convention.
3. That heading is not itself also a match for the wireframe heading regex
   `/^#+\s*.*\bwireframe\b/i` — the flow artifact must live in its own
   distinct section, not collapse into a subsection nested directly under a
   wireframe heading with no separate heading of its own.

Any other write surface is ignored (exit 0, not this gate's business).

On a passing check, the gate best-effort updates
`docs/issue-<n>/reports/interaction-design/.status.json`, setting
`data["issue-<n>"]["task_flow"] = "ok"`.

The gate is fail-closed: an unparseable payload, an unreadable existing
file, a tool input the gate cannot resolve to final content, or an internal
error all deny (exit 2) rather than silently allow.

## Kill switch

```
export ID_TASK_FLOW_GATE_OFF=1
```

Any of `1` (default true), or an unset/`0`/`false`/`no`/`off` value keeps
the gate active — only a truthy, non-empty, non-`0`/`false`/`no`/`off`
value disables it.

## Composition

Per docs/issue-21 proposal §4, the phase-2 judgment norm is the conjunction
of nine plugins: `id-persona-goal` ∧ `id-task-flow` ∧
`id-state-completeness` ∧ `id-wireframe-staging` ∧ `id-nielsen-heuristics`
∧ `id-accessibility-floor` ∧ `id-usability-test-plan` ∧ `id-traceability`
∧ `id-stage-order`. Each plugin fires independently on the same write
surface (`docs/issue-<n>/reports/interaction-design.md`); the write is
allowed only if every currently-installed plugin allows it. Killing this
plugin alone weakens but does not break the phase-2 norm — composition is
additive, not all-or-nothing.

## Reference

`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(approved proposal), §3 row `id-task-flow`, §4 pattern table.
