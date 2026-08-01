# id-proposal-shape

One of eleven methodology plugins that together implement the
interaction-design gate machine per
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(§3 plugin catalog, §4 composition). This plugin owns exactly one
methodology: the six-section phase-1 proposal shape.

## What it owns

A phase-1 proposal (`docs/issue-<n>/proposals/*.md`) must contain six
distinct headings, each matched by its own heading-anchored regex so no
two required sections can be satisfied by the same heading:

| Required section | Heading-anchored regex |
|---|---|
| Problem/goal | `/^#+\s*.*\b(problem\s*framing\|problem\|goal)\b/i` |
| Comparison set | `/^#+\s*.*\b(comparison\|alternatives?\|catalog\|compared\s+options?)\b/i` |
| Methodology cited | `/^#+\s*.*\b(methodolog(y\|ies)\|adopted\s+methodolog)\b/i` |
| Delivery scope | `/^#+\s*.*\b(delivery\s+scope\|does\s+not\s+do\|out\s+of\s+scope)\b/i` |
| Adopt/skip | `/^#+\s*.*\b(adopt\s*\/\s*skip\|adopt\|skip)\b/i` |
| Judged-by | `/^#+\s*.*\b(judged[\s-]by\|judgment\|approv(al\|ed)\|gate\s+tests?)\b/i` |

A heading present with a blank/whitespace-only body counts as **absent**
(stub rule, matching this repo's `tests/stub-check.sh` convention): the
gate checks that each matched heading is followed by non-blank content
before the next same-or-higher-level heading.

It does not check citation format (that's `id-citation-format`) or stage
ordering (that's `id-stage-order`) — this plugin's only concern is
section shape.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN /
  PRODUCES / HAND-OFF for the proposal-shape check, sourced from the
  shared `core/hooks/lib/role-directive.sh` convention.
- `hooks/proposal-shape-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`.
  Fails closed. Only acts on writes matching
  `^docs/issue-([0-9]+)/proposals/.*\.md$`; any other path is not this
  gate's business (exit 0). Denies with
  `id-proposal-shape: refused — %s`, naming exactly which section(s) are
  missing or stubbed.
- `tests/id-proposal-shape-gate-tests.sh` — plain-bash probe suite
  (this repo's `tests/deny-only-check.sh` / `tests/stub-check.sh`
  convention, not bats): all-six-present allow, one-missing deny,
  stub-body deny, out-of-scope-path allow.

## Kill switch

`export ID_PROPOSAL_SHAPE_GATE_OFF=1` disables this plugin's gate only,
independent of the other ten interaction-design plugins.

## State file

On a passing write, the gate records a best-effort update to
`docs/issue-<n>/reports/interaction-design/.status.json`, keyed by
subject (`"issue-<n>"`), setting `"proposal_shape": "ok"`, e.g.
`{"issue-21": {"proposal_shape": "ok"}}`. This never blocks the
underlying content write on its own failure.

## How it composes

Per the proposal's §4: **phase-1 proposal norm = `id-proposal-shape` ∧
`id-citation-format` ∧ `id-stage-order`**. All three gates fire
independently on the same write surface
(`docs/issue-<n>/proposals/*.md`); the write is allowed only if all
currently-installed phase-1 plugins allow it. Each plugin can be
installed, killed, or fail independently of the others — a false
positive or a kill switch in one plugin never blocks (or silently
passes) a write that only another plugin cares about.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full design this plugin is one piece of.
