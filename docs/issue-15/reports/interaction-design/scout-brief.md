---
subject: issue-15
role: interaction-design
loop_state: surveyed
---

# Scout brief — interaction-design methodology scan (issue-15)

Skip record for live web scouting: no WebSearch/WebFetch tool was invoked
for this brief. What follows is labeled explicitly as
**established-practice assumptions** — textbook/industry-standard
interaction-design knowledge (Nielsen Norman Group's published heuristics,
the Interaction Design Foundation's course/process literature, Alan
Cooper's *About Face* goal-directed design method, and the design-thinking
process popularized by IDEO/Stanford d.school) rather than sourced from a
fresh sweep. Treat any specific claim below as "well-established practice,
not independently re-verified this session."

## Must-bes (what every credible interaction-design process covers)

- **Problem/goal framing before solution.** Every named methodology
  (goal-directed design, design thinking's "empathize/define" stages,
  IxDF's process models) starts by fixing whose goal and what job is
  being served before screens are drawn — a proposal with no named user
  and no named job is not following any of them.
- **Personas or equivalent user models tied to goals, not demographics.**
  Cooper's goal-directed design treats personas as behavioral archetypes
  built from research, used to make design decisions defensible ("would
  this persona want this?") — a generic "the user" with no goal model is
  a well-known anti-pattern the field explicitly warns against.
- **Interaction flows / task flows as the connective artifact between
  goals and screens.** Named across the field as flow diagrams, task
  flows, or user-flow diagrams — the artifact that shows sequence,
  branches, and decision points a user moves through, distinct from any
  single screen.
- **Low-fidelity before high-fidelity representation.** Wireframes (or
  equivalent structural sketches) before visual/prototype fidelity is a
  near-universal convention (design thinking's "prototype" stage, IxDF's
  iterative-fidelity guidance) — skipping straight to high-fidelity mockups
  is a recognized anti-pattern, not a stylistic choice.
- **A named usability/heuristic evaluation pass.** Nielsen's ten
  usability heuristics (visibility of system status, match between
  system and the real world, user control and freedom, consistency and
  standards, error prevention, recognition rather than recall,
  flexibility and efficiency of use, aesthetic and minimalist design,
  help users recognize/diagnose/recover from errors, help and
  documentation) is the field's most cited deterministic checklist for
  judging an interaction design, independent of any specific product.
- **State completeness as a named requirement**, not an implicit
  expectation: empty, loading, error, and success states are treated as
  first-class deliverable components in both IxDF and product-design
  practice literature — a flow spec without them is considered
  incomplete, not minimal.
- **Accessibility considered at design time, not audited after the
  fact** — WCAG-aligned considerations (keyboard operability, focus
  visibility, labeled inputs, contrast) are treated as an input to the
  design, not a QA-only concern, across every mainstream methodology
  surveyed here.
- **A usability-validation step before/alongside delivery** — think-aloud
  usability testing (Nielsen/IxDF) or an explicit usability-test plan
  accompanying a prototype is the field's standard way of grounding "this
  design works" in something other than the designer's own judgment.

## Performance axes this category competes on

1. Whether the flow's *decision points and error branches* are specified
   at all, versus only the happy path (the single most common quality gap
   named across usability literature).
2. Whether usability judgments are made against a *named, checkable
   heuristic set* versus ad hoc "looks fine" review.
3. Whether accessibility is a *stated design input* versus a downstream
   afterthought.
4. Whether personas/scenarios are *goal-derived and used to decide
   between options* versus decorative background material nobody
   references again.

## Adopt / skip patterns

- **Adopt**: Nielsen's ten heuristics as the field's most portable,
  citable, deterministic evaluation checklist — cheap to apply, widely
  recognized, and already partially (six of ten) reflected in this
  repo's existing `HAND_OFF` text without attribution.
- **Adopt**: goal-directed flow/state specification (task flows +
  complete states: empty/loading/error/success) as the mandatory
  deliverable backbone — matches this role's existing spec-only,
  no-src output boundary and requires no new tooling.
- **Adopt**: accessibility-as-design-input, expressed at the token level
  where a design-system document exists (already partially present via
  issue-12's contrast-at-token-level rule) — extending rather than
  replacing that existing rule.
- **Skip (for phase-1 proposal *documents*, not phase-2 deliverables)**:
  full design-thinking workshop artifacts (empathy maps, journey maps as
  a mandatory standalone deliverable) — heavier-weight than this
  single-role, spec-producing rulebook's scope; the flow/persona/state
  triad already covers the load-bearing must-bes without importing a
  multi-day workshop format.
- **Skip**: mandating a live usability-testing report as a phase-2 gate
  requirement — this role does not implement or ship a testable
  prototype (spec-only, per its own `HAND_OFF` boundary), so a usability
  *test plan* (naming what should be tested and how) is adoptable, but an
  actual conducted test report is out of this role's reach and would be
  requiring evidence the role cannot produce.

## GAP LINE — field must-bes vs. current repo state

| Field must-be | Current repo state (per survey) |
|---|---|
| Named, checkable heuristic set | Six-item unattributed heuristic-like list in `directive.sh`, no citation, no stated relationship to the standard ten |
| Goal-derived persona/user model required | Not required anywhere; `directive.sh` only requires tracing to "the governing hypothesis/product-record," no persona/goal artifact named |
| Task/interaction flow as mandatory artifact | Implied by "screen/flow/wireframe specification" but not required as distinct from screens; no flow-diagram format specified |
| Mandatory state completeness (empty/loading/error/success) | Present, already required (`directive.sh` HAND_OFF, "no error/empty/loading state is incomplete") — a rare case where this repo already meets the field must-be |
| Accessibility as design input | Present at token-contrast level (issue-12) but incomplete against the fuller WCAG-aligned set (keyboard/focus/labels present; no stated conformance target, e.g. WCAG level) |
| Low-fidelity-before-high-fidelity discipline | Not stated at all; "wireframe" named as one of three output shapes with no ordering/fidelity-staging rule |
| Usability-test plan as a deliverable component | Not present; no mention of usability validation anywhere in `directive.sh` |
| Mandatory-sections list for phase-1 proposal documents | Not present (survey finding); convention-only, unwritten |
| Mandatory-components list for phase-2 deliverables | Not present (survey finding); "screen/flow/wireframe spec" named without enumeration or format |
| Evidence/citation format for phase-1 claims | Not present (survey finding); no requirement to cite comparison products, sources, or method |

## Sources

No web search performed this session (tool not invoked). Claims above rest
on established-practice domain knowledge of: Jakob Nielsen's published
"10 Usability Heuristics for User Interface Design" (Nielsen Norman
Group); the Interaction Design Foundation's publicly documented course
and encyclopedia content on interaction-design process, personas, and
usability testing; Alan Cooper, Robert Reimann, and David Cronin, *About
Face: The Essentials of Interaction Design* (goal-directed design method);
and the IDEO/Stanford d.school design-thinking process stages
(empathize–define–ideate–prototype–test), all treated here as
well-established, widely taught practice rather than freshly sourced
citations. A follow-up phase-1 cycle with web access should re-verify
against current NN/g and IxDF publications before this brief is treated
as final domain authority.
