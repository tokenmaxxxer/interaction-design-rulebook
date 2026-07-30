# tokenmaxxxer / ux-design-rulebook

The `ux-design` role on contract v3. A ux-design session is spawned with
two plugin sets installed: this marketplace's `ux-design` plugin, and the
[tokenmaxxxer-core](https://github.com/tokenmaxxxer/tokenmaxxxer-core)
plugins (`core`, `terse`, `freelunch`, `scout`). Core owns the interaction
protocol — issue in, two-phase PR out (research/survey/proposal → human
review Approve → execution), branch `issue-<n>/ux-design`, record at
`docs/issue-<n>/reports/ux-design.md`. This rulebook owns only what is
ux-design-specific.

## What `ux-design` decides

How the accepted problem becomes screens, flows, and interaction — the
experience risk. The governing hypothesis / product-record supplies the
WHAT (product's call); ux-design owns the HOW a user moves through it,
and delivers a screen/flow/wireframe specification concrete enough for
coding to build from without asking what goes where. Reaching
`loop_state: reviewed` is this role's terminal record state. Spec
only — never implementation.

## What is here

    ux-design/hooks/directive.sh        SessionStart — the four facets:
                                        research (same-job flows of
                                        best-in-class products, interaction
                                        must-bes, platform conventions),
                                        survey (governing record + touched
                                        screens + frozen constraints),
                                        proposal (screens/flows traced to the
                                        governing record; on a token-less
                                        project, first establishes
                                        docs/specs/design-system.md as a
                                        proposal-gated contract), judgment
                                        (complete states, heuristic +
                                        accessibility floors, name-only token
                                        references, no untraced elements)
    ux-design/hooks/record-fields-gate.sh  s20 minimum content on the record
    ux-design/hooks/trailer-gate.sh     commits staging docs/issue-<n>/** carry
                                        `Subject: issue-<n>`
    ux-design/hooks/handbook-trigger-gate.sh  s21 same-turn handbook sync
    tests/                              repo-level checks (never installed)

This revision also retires the stale product-rulebook prose this README
used to carry (a copy-paste role description that was factually wrong for
ux-design) — the role definition above is the authoritative one.

## Record vocabulary

`loop_state`: `idle, drafting, reviewed` (terminal: `reviewed`). The
record carries a non-empty pointer to the governing
`hypothesis`/`product-record` and the screen/flow/wireframe specs or
pointers to them.

## Install

    claude plugin marketplace add tokenmaxxxer/ux-design-rulebook
    claude plugin install ux-design@tokenmaxxxer-ux-design

Kill switch: `UX_DESIGN_CYCLE_OFF=1`.

## Run the checks

    /bin/bash tests/parse-check.sh
    /bin/bash tests/run-gate-tests.sh
    /bin/bash tests/deny-only-check.sh
