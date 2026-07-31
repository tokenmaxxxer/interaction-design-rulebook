# id-usability-test-plan

One of eleven independent plugins composing the interaction-design gate
machine, per `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`.
This plugin owns exactly row 9 of that proposal's §2/§3 table: the
usability-test **plan** requirement, and nothing else.

## What it owns

Whether the phase-2 interaction-design record names a concrete
usability-test plan. Planned, **not conducted**: this role and this gate
only enforce that a test is planned — actually running or reporting a
real usability test is phase 3+ work and stays entirely out of this
plugin's (and this role's) scope. It does not own persona/goal modeling,
task-flow artifacts, state completeness, wireframe staging, Nielsen's
heuristics, the accessibility floor, or traceability — those belong to
the sibling `id-*` plugins named in the proposal's §3 catalog. Per §7 of
the proposal, this methodology is mechanical (presence/content checks
only) and ships no agent/checklist component.

## What the gate checks

`hooks/usability-test-gate.sh` is a PreToolUse gate on
`Write|Edit|MultiEdit`. It acts only on writes to the phase-2 record,
`docs/issue-<n>/reports/interaction-design.md` (all other paths pass
through untouched — this gate is not the umbrella phase-2 gate, only its
own concern per §4's composition rule).

For that target it requires:

1. A heading matching `/^#+\s*.*\b(usability\s+test|test\s+plan)\b/i`.
2. Under that heading (until the next heading of equal or higher level),
   a non-blank body containing:
   - at least one named task scenario — a line containing the word
     "scenario" or "task" (heuristic for verb-first task phrasing), and
   - a participant-count or recruitment line — matching
     `/\b\d+\s*(participants?|users?)\b/i` or containing the word
     "recruit".

A heading with a blank/whitespace-only body is a stub and denied the
same as a missing heading, matching this repo's own
`tests/stub-check.sh` stub convention. A plan with a scenario but no
participant/recruitment line, or vice versa, is denied and the message
names specifically which element is missing.

On a passing write, the gate best-effort updates the shared per-subject
state file `docs/issue-<n>/reports/interaction-design/.status.json`,
setting `data["issue-<n>"]["usability_test_plan"] = "ok"`. This is a
side write only — it never blocks the underlying content write on its
own failure, and it creates the directory/file if either is missing.

## Kill switch

`export ID_USABILITY_TEST_PLAN_GATE_OFF=1` disables this plugin's gate
only, independent of every other `id-*` plugin's gate (per §3: a false
positive here cannot block a write only some other plugin cares about,
and either plugin can be killed independently).

## Composition / phase-2 norm

Per proposal §4, this plugin is one conjunct of the phase-2 judgment
norm: `id-persona-goal` ∧ `id-task-flow` ∧ `id-state-completeness` ∧
`id-wireframe-staging` ∧ `id-nielsen-heuristics` ∧
`id-accessibility-floor` ∧ **`id-usability-test-plan`** ∧
`id-traceability` ∧ `id-stage-order`. All nine fire independently on the
same phase-2 record write; a repo missing (or killing) any one of them
gets a weaker but still-functioning phase-2 norm, not a broken one.

## Approved proposal

See
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(§3 plugin catalog, §4 composition and gate-matching patterns) for the
full design this plugin implements, and
`docs/issue-15/reports/interaction-design.md` for the record-file
convention this gate targets.
