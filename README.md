# tokenmaxxxer / interaction-design-rulebook

The `interaction-design` role on contract v3. An interaction-design
session is spawned with two plugin sets installed: this marketplace's
`interaction-design` plugin, and the
[tokenmaxxxer-core](https://github.com/tokenmaxxxer/tokenmaxxxer-core)
plugins (`core`, `terse`, `freelunch`, `scout`, `warrant`). Core owns the
interaction protocol — issue in, two-phase PR out
(research/survey/proposal → human review Approve → execution), branch
`issue-<n>/interaction-design`, record at
`docs/issue-<n>/reports/interaction-design.md` — and the role-agnostic
review gates (trailer/record-fields/handbook-trigger),
fired globally by `core/hooks/hooks.json` for every plugin install. This
rulebook owns only what is interaction-design-specific: `directive.sh`'s
four role-unique values.

## What `interaction-design` decides

How the accepted problem becomes screens, flows, and interaction — the
experience risk. The governing hypothesis / product-record supplies the
WHAT (product's call); interaction-design owns the HOW a user moves
through it, and delivers a screen/flow/wireframe specification concrete enough for
coding to build from without asking what goes where. Reaching
`loop_state: reviewed` is this role's terminal record state. Spec
only — never implementation.

Every phase-1 proposal names the interaction-design methodology or
heuristic set its recommendations derive from (e.g. Nielsen's ten
usability heuristics, goal-directed design's persona model) and follows
six mandatory named sections: problem/goal framing, comparison
set/exemplars, methodology cited, what will be delivered, adopt/skip
rationale, how it will be judged — with exemplar claims cited by source
or explicitly labeled "established-practice assumption." Every phase-2
deliverable carries nine mandatory components: goal/persona reference,
a distinct interaction/task-flow artifact, complete states per
screen/flow, a wireframe staged low-fidelity before high-fidelity, the
full ten-item Nielsen heuristic evaluation, an accessibility floor
conformant to WCAG 2.1 AA, a usability-test plan (not a conducted test),
traceability/scope-growth flagging, and the spec-only output boundary.
(`docs/issue-15/proposals/interaction-design.md`, approved.)

As of issue-21, these norms are machine-enforced, not prose-only: eleven
self-contained, independently kill-switchable plugins under
`ux-design/plugins/<name>/`, each owning exactly one methodology and
registered as its own `.claude-plugin/marketplace.json` entry —
`id-proposal-shape` and `id-citation-format` (phase 1), `id-persona-goal`,
`id-task-flow`, `id-state-completeness`, `id-wireframe-staging`,
`id-nielsen-heuristics`, `id-accessibility-floor`,
`id-usability-test-plan`, `id-traceability` (phase 2), and
`id-stage-order` (cross-cutting survey→scout→proposal→record ordering).
See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full plugin-composition design, and each plugin's own `README.md`
for what it owns and how its gate is judged.

As of issue-24, all eleven gates source core's shared gate-house library
(`core/hooks/lib/gate-lib.sh` / `gate-lib.py`, core issue #72) by
reference, never vendored — the canonical fail-closed EXIT trap
(`gate_trap_fail_closed`), the fixed kill-switch convention
(`gate_kill_switch_active`: only a recognized on-spelling disables, every
other value including an unrecognized one stays active), malformed-JSON
deny, absolute/`./`-prefixed path normalization
(`gate_normalize_path`), and full `Edit`/`MultiEdit` reconstruction
honoring each edit's own `replace_all`
(`gate_reconstruct_write`). `docs/handbooks/gate-house-standard.md`
(in `core`)'s own `core/hooks/tests/compliance-check.sh` is the closing
acceptance check.

## What is here

    ux-design/hooks/directive.sh        SessionStart — the four facets:
                                        research (same-job flows of
                                        best-in-class products, interaction
                                        must-bes, platform conventions),
                                        survey (governing record + touched
                                        screens + frozen constraints + the
                                        methodology/heuristic set that will
                                        govern the proposal, named as
                                        missing if absent), proposal
                                        (screens/flows traced to the
                                        governing record; six mandatory
                                        named sections + cited evidence
                                        format; on a token-less project,
                                        first establishes
                                        docs/specs/design-system.md as a
                                        proposal-gated contract), judgment
                                        (goal/persona reference, distinct
                                        task-flow artifact, complete states,
                                        low-fidelity-before-high-fidelity
                                        staging, full ten-item Nielsen
                                        heuristic set, accessibility floor
                                        named to WCAG 2.1 AA, usability-test
                                        plan, name-only token references, no
                                        untraced elements)
    tests/                              repo-level checks (never installed)

s20 record-field minimums, commit-trailer enforcement (`Subject: issue-<n>`),
and s21 same-turn handbook sync are core canon gates now (core issue-66) —
no local copy lives in this rulebook.

This revision also retires the stale product-rulebook prose this README
used to carry (a copy-paste role description that was factually wrong for
interaction-design) — the role definition above is the authoritative one.

## Record vocabulary

`loop_state`: `idle, drafting, reviewed` (terminal: `reviewed`). The
record carries a non-empty pointer to the governing
`hypothesis`/`product-record` and the screen/flow/wireframe specs or
pointers to them, a non-empty pointer to the goal/persona reference
used, the methodology/heuristic-set actually applied (named), and
confirmation that all nine mandatory phase-2 components are present in
the delivered spec — or an explicit note of which are inapplicable and
why.

## Install

    claude plugin marketplace add tokenmaxxxer/interaction-design-rulebook
    claude plugin install interaction-design@tokenmaxxxer-interaction-design

There is no repo-wide kill switch — each of the eleven `id-*` gates has
its own, independent one: `ID_PROPOSAL_SHAPE_GATE_OFF`,
`ID_CITATION_FORMAT_GATE_OFF`, `ID_PERSONA_GOAL_GATE_OFF`,
`ID_TASK_FLOW_GATE_OFF`, `ID_STATE_COMPLETENESS_GATE_OFF`,
`ID_WIREFRAME_STAGING_GATE_OFF`, `ID_NIELSEN_HEURISTICS_GATE_OFF`,
`ID_ACCESSIBILITY_FLOOR_GATE_OFF`, `ID_USABILITY_TEST_PLAN_GATE_OFF`,
`ID_TRACEABILITY_GATE_OFF`, `ID_STAGE_ORDER_GATE_OFF` — set any of them
to `1`/`true`/`yes`/`on` to disable that one gate; every other value
(including a typo) leaves it active. See each plugin's own `README.md`.

This role's record terminal state is `reviewed`, not core's own default
(`landed`). Core's `record-fields-gate.sh` (now the only copy, fired
globally) reads that from `RECORD_FIELDS_TERMINAL_STATES` — a hook entry
has no `env` field, so this rulebook cannot set it from its own
`hooks.json`. Set it in the project's own `.claude/settings.json`:

    { "env": { "RECORD_FIELDS_TERMINAL_STATES": "reviewed" } }

## Run the checks

    /bin/bash tests/parse-check.sh
    /bin/bash tests/parse-check.sh ux-design/plugins
    /bin/bash tests/run-gate-tests.sh
    /bin/bash tests/deny-only-check.sh
    /bin/bash tests/deny-only-check.sh ux-design/plugins
    /bin/bash tests/stub-check.sh ux-design/hooks
    /bin/bash tests/stub-check.sh ux-design/plugins

Each `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` also runs
independently on its own — a broken plugin's tests still fail
attributably, with its own output, not as one opaque failure (per the
approved
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§6). `tests/run-gate-tests.sh` now also loops all eleven of them and
exits non-zero if any fail, so a reviewer running only that one script
gets an accurate combined signal (issue-24 §4 item 7).

`core/hooks/tests/compliance-check.sh ux-design` (from an installed or
sibling-checked-out `core`) is the gate-house standard's own migration
acceptance check — run clean against this rulebook's `hooks/` trees.
