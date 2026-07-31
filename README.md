# tokenmaxxxer / ux-design-rulebook

The `ux-design` role on contract v3. A ux-design session is spawned with
two plugin sets installed: this marketplace's `ux-design` plugin, and the
[tokenmaxxxer-core](https://github.com/tokenmaxxxer/tokenmaxxxer-core)
plugins (`core`, `terse`, `freelunch`, `scout`, `warrant`). Core owns the
interaction protocol — issue in, two-phase PR out
(research/survey/proposal → human review Approve → execution), branch
`issue-<n>/ux-design`, record at `docs/issue-<n>/reports/ux-design.md` —
and the role-agnostic review gates (trailer/record-fields/handbook-trigger),
fired globally by `core/hooks/hooks.json` for every plugin install. This
rulebook owns only what is ux-design-specific: `directive.sh`'s four
role-unique values.

## What `ux-design` decides

How the accepted problem becomes screens, flows, and interaction — the
experience risk. The governing hypothesis / product-record supplies the
WHAT (product's call); ux-design owns the HOW a user moves through it,
and delivers a screen/flow/wireframe specification concrete enough for
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
ux-design) — the role definition above is the authoritative one.

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

    claude plugin marketplace add tokenmaxxxer/ux-design-rulebook
    claude plugin install ux-design@tokenmaxxxer-ux-design

Kill switch: `UX_DESIGN_CYCLE_OFF=1`.

This role's record terminal state is `reviewed`, not core's own default
(`landed`). Core's `record-fields-gate.sh` (now the only copy, fired
globally) reads that from `RECORD_FIELDS_TERMINAL_STATES` — a hook entry
has no `env` field, so this rulebook cannot set it from its own
`hooks.json`. Set it in the project's own `.claude/settings.json`:

    { "env": { "RECORD_FIELDS_TERMINAL_STATES": "reviewed" } }

## Run the checks

    /bin/bash tests/parse-check.sh
    /bin/bash tests/run-gate-tests.sh
    /bin/bash tests/deny-only-check.sh
    /bin/bash tests/stub-check.sh ux-design/hooks
