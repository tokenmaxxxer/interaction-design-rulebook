---
status: reviewed
subject: issue-15
role: interaction-design
loop_state: reviewed
---

# interaction-design record — issue-15

## Why

Issue #15: mature the `interaction-design` rulebook (`ux-design/hooks/directive.sh`,
`README.md`) per the APPROVED proposal
`docs/issue-15/proposals/interaction-design.md` — phase-1 proposal norms
(methodology naming, mandatory sections, evidence format) and phase-2
deliverable norms (goal/persona reference, task-flow artifact, fidelity
staging, full ten-item Nielsen heuristic set, named WCAG 2.1 AA
conformance target, usability-test-plan requirement), executed exactly
against the proposal's frozen write set and ordering.

## Governing basis

`docs/issue-15/proposals/interaction-design.md` (approved), itself
grounded in `docs/issue-15/reports/interaction-design/survey.md` and
`docs/issue-15/reports/interaction-design/scout-brief.md`.

## Methodology applied

Goal-directed design's flow/state/persona triad (Cooper) combined with
the full Nielsen ten-heuristic evaluation pass, per the proposal's (b)
section — the same pairing this phase-2 change writes into
`directive.sh`'s `HAND_OFF` value for all future deliverables.

## Goal/persona reference

This phase-2 delivery is itself a plugin/directive-and-record change —
there are no end-user screens, flows, or personas being specified by
this record's own content. The "goal/persona reference" requirement
(proposal (b) item 1) is being introduced by this change as a rule that
governs FUTURE interaction-design deliverables produced under the
matured directive; it is not retroactively applicable to this record,
which is a rulebook-maturation record, not a screen/flow spec. Stated
explicitly rather than fabricating a persona for a non-existent screen:
items b.1 (goal/persona reference), b.2 (distinct task flow), b.4
(fidelity staging), and b.7 (usability-test plan) do not literally apply
to this record's own content, because this record does not deliver a
screen/flow spec — it delivers the rule text that will require those
items of the next such spec.

## What was done

Executed the approved proposal's "Ordering within phase 2" steps 1-7
exactly, against its frozen write set:

- Step 1: this record file created fresh with `loop_state: drafting` as
  phase 2's first act (per RECORD FORMAT, `directive.sh`).
- Step 2: `ux-design/hooks/directive.sh` `USE_WHEN` (CURRENT-STATE
  SURVEY) — added the requirement that the survey name which
  methodology/heuristic set will govern the proposal, phrased the same
  way as the existing "no design-system document ... named as missing"
  pattern.
- Step 3: `PRODUCES` (PROPOSAL) — added the six mandatory phase-1
  proposal sections (problem/goal framing, comparison set/exemplars,
  methodology cited, what will be delivered, adopt/skip rationale, how
  it will be judged) plus the evidence-format rule (cite exemplar
  sources by name, or label "established-practice assumption"). The
  existing design-system-establishment rule (token-less project clause)
  preserved unchanged — additive only.
- Step 4: `HAND_OFF` (EXECUTION JUDGMENT) — replaced the prior six-item
  unattributed heuristic list with the full cited ten-item Nielsen set;
  added the goal/persona-reference requirement, the distinct
  interaction/task-flow requirement, the low-fidelity-before-high-
  fidelity staging note, the named WCAG 2.1 AA conformance target on the
  existing accessibility floor bullet, and the usability-test-plan
  requirement (explicitly a plan, not a conducted test). The existing
  complete-states rule, name-only token-reference rule, traceability
  rule, spec-only-boundary rule, and the final RECORD FORMAT paragraph
  left verbatim, untouched.
- Step 5: `README.md`'s "What `ux-design` decides," "What is here," and
  "Record vocabulary" sections extended to reflect the new
  directive.sh content, at the same detail level issue-12's README edit
  used — including the new required record fields (goal/persona
  pointer, methodology/heuristic-set applied, confirmation of the nine
  mandatory phase-2 components).
- Step 6: `/bin/bash tests/parse-check.sh` run — `directive.sh` parses
  OK under `/bin/bash`. No syntax errors encountered; all new content
  added inside the existing `$'...\n...'` ANSI-C-quoted assignments,
  preserving the file's one-physical-line-per-assignment convention.
- Step 7: this record updated to `loop_state: reviewed`, this section
  filled in.

## Confirmation of the nine (b) mandatory components — as rule text now

This record does not itself deliver a screen/flow spec (see "Goal/
persona reference" above), so "confirmation of components present"
here means confirmation that all nine items now exist as required rule
text in `directive.sh`'s `HAND_OFF` value, ready to gate the next actual
phase-2 deliverable:

1. Goal/persona reference — present (new bullet).
2. Interaction/task flow — present (new bullet).
3. Complete states per screen/flow — present, carried forward verbatim.
4. Wireframe staged low-fidelity before high-fidelity — present (new
   bullet, added to the existing flow-completeness bullet's
   neighborhood).
5. Full ten-item Nielsen heuristic evaluation — present, four items
   added (match between system and real world; flexibility and
   efficiency of use; aesthetic and minimalist design; help and
   documentation) to the six carried forward unchanged.
6. Accessibility floor with WCAG 2.1 AA conformance target — present,
   target named on the existing floor bullet, four floor items
   unchanged.
7. Usability-test plan (not a conducted test) — present (new bullet).
8. Traceability and scope-growth flag — present, carried forward
   verbatim.
9. Spec-only output boundary — present, carried forward verbatim.

## Verification (closed_checks)

- `/bin/bash tests/parse-check.sh` — PASS (`ok directive.sh`,
  `parse-check: 1 file(s) under /bin/bash`).
- `/bin/bash tests/run-gate-tests.sh` — ran, `0 passed, 0 failed (gates
  promoted to core canon; see tests/stub-check.sh)` — unaffected by this
  phase-2 change, as expected (no gate-script edits made).
- `/bin/bash tests/stub-check.sh ux-design/hooks` — PASS, all five
  checks OK, including `directive.sh is a role-directive stub` — the
  added content stayed inside the existing `YOU_DECIDE`/`USE_WHEN`/
  `PRODUCES`/`HAND_OFF` `$'...'` assignments, so the stub structure the
  check enforces is unaffected.
- `git diff --stat` before commit showed only `docs/issue-15/reports/
  interaction-design.md`, `ux-design/hooks/directive.sh`, and
  `README.md` touched — matches the proposal's frozen phase-2 write set
  exactly.

## Open findings

None from this phase-2 execution itself. Confirming the proposal's
explicit "out of scope" items were correctly left untouched: no new
`*-gate.sh` script was added (items 1-3 of the proposal's gate list
remain directive-level judgment gates, checked at PR review, per
issue-12's own precedent); `docs/specs/approvers.md` was not touched;
no historical `docs/issue-5/*`, `docs/issue-7/*`, `docs/issue-9/*`,
`docs/proposals/*`, or `docs/reports/*` (pre-per-issue-folder layout)
files were touched. Warrant-hunter content untouched and not
referenced — this phase-2 change is unrelated to warrant-hunter's
cadence/scope concerns, per the proposal's own canon-citation note.

## Next steps

None — issue-15 phase 2 scope fully executed per the approved proposal,
ready for PR review/merge.

## Open-finding-resolution path

Not applicable; no open findings.
