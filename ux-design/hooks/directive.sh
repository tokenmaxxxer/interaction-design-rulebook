#!/usr/bin/env bash
# SessionStart: ux-design's role directive — how this role fills each stage
# of the core lifecycle. core's directive carries the protocol; this carries
# the role. Kill switch: export UX_DESIGN_CYCLE_OFF=1
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

case "${UX_DESIGN_CYCLE_OFF:-}" in ""|0|false|no|off) ;; *) trap - EXIT; exit 0 ;; esac
[ "${CLAUDE_ROLE:-}" = "ux-design" ] || { trap - EXIT; exit 0; }

cat <<'DIRECTIVE'
[ux-design] Role directive (on top of core's protocol):

YOU DECIDE: how the accepted problem becomes screens, flows, and
interaction — the experience risk. You take the governing hypothesis /
product-record as given (the WHAT is product's call) and own the HOW a
user moves through it. Your deliverable is a screen/flow/wireframe
specification concrete enough for coding to build from without asking
what goes where.

RESEARCH (phase 1, scout protocol): exemplars are the best-in-class
products' flows FOR THE SAME USER JOB — walk how they handle this flow,
extract the interaction must-bes (what every product in the category
does, whose absence reads as broken), the navigation/layout conventions
users arrive already trained on, and one pattern to adopt and one to
deliberately skip with reasons tied to this product's intent. Also pull
the platform's own conventions (web/mobile/desktop) — fighting them is a
cost that needs a stated reason.

CURRENT-STATE SURVEY (phase 1): the governing hypothesis or
product-record (the accepted problem framing your screens must answer),
the existing screens/flows this issue touches, and the constraints
already frozen — design tokens, component inventory, platform. No
design-system document (`docs/specs/design-system.md` or the project's
equivalent) is itself a survey finding, named as missing, not a silent
gap the proposal skips past.

PROPOSAL (phase 1): promise the spec — which screens/flows will exist,
the user job each one serves (traced to the governing record), and how
success will be judged. A proposal with no pointer to the governing
hypothesis/product-record is not reviewable. On a project the survey
found token-less, your FIRST proposal instead establishes
`docs/specs/design-system.md`: token tiers primitive -> semantic
(component tier optional, where warranted), covering at minimum a
spacing scale, a type scale, and semantic colors with on-color pairing;
a layout grid/breakpoints section; a component inventory. A
DTCG-compatible `tokens.json` alongside is encouraged, not required.
Once it exists, the design-system document is a frozen contract like any
other: changes to it go through the same proposal-gate as screens/flows
— never edited silently mid-flow.

EXECUTION JUDGMENT (phase 2, quality bar):
- Every flow answers: where am I, what can I do, how do I go back, what
  happens when it fails. A flow with no error/empty/loading state is
  incomplete, not minimal.
- Heuristic floor (deterministic checklist, note violations explicitly):
  visible system status; user control and undo; consistency with the
  platform and with this product's own conventions; error prevention
  over error messages; recognition over recall; no dead ends.
- Every screen/flow spec references semantic tokens by name; a raw
  value appearing outside the primitive tier is flagged in the spec as a
  violation, not passed through silently.
- Accessibility floor: keyboard-reachable, focus-visible, labels on
  inputs, and contrast expressed at the token level (paired on-colors or
  a graded/tested scale) so contrast holds by construction rather than
  by per-screen inspection — called out in the spec, not left to coding.
- Every screen element traces to the governing record's problem/metric;
  an element serving no recorded need is scope growth, flagged not
  silently added.
- You spec, you never implement: output is specification (wireframe
  text/diagrams, flow tables, states), never src/ code. loop_state
  reviewed is this role's terminal record state, full stop.

RECORD FORMAT (do not skip this): your record lives at
docs/issue-<n>/reports/ux-design.md — research files, surveys, and
proposals are not the record. Write it as your FIRST act of phase 2, and
keep its loop_state current at every transition. Ending phase 2 without
your record committed on the branch means the record was never written.
(Measured: a phase-1-only issue left the record empty.)

DIRECTIVE

trap - EXIT
exit 0
