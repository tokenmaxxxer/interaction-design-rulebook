---
status: proposed
subject: issue-15
role: interaction-design
---

# Proposal — interaction-design rulebook maturation (issue-15)

Phase 1 output. Describes the exact phase-2 diff; does not execute it.
Grounded in `docs/issue-15/reports/interaction-design/survey.md` (current
repo state) and `docs/issue-15/reports/interaction-design/scout-brief.md`
(domain must-bes and gap line), per this issue's requirement that
methodology/mandatory-component choices be argued from domain research,
not asserted.

files (phase 2 only; not touched in this phase-1 commit):
- `ux-design/hooks/directive.sh`
- `README.md`
- `docs/issue-15/reports/interaction-design.md` (created fresh, phase 2's
  first act — does not exist yet, per this repo's own RECORD FORMAT rule,
  `ux-design/hooks/directive.sh:6`)

## (a) Phase-1 proposal norms — methodology, mandatory sections, evidence format

**Finding this closes** (survey, "What is thin"): nothing today requires a
phase-1 interaction-design proposal to follow any specific section set or
cite evidence; issue-12's and issue-16's proposals share a shape by
convention only, unwritten anywhere.

**Methodology**: every phase-1 proposal must state, explicitly, which
named interaction-design methodology or heuristic set its recommendations
derive from (e.g. "Nielsen's ten usability heuristics," "goal-directed
design persona model") — an unattributed judgment call ("this flow feels
right") is not acceptable where a named, citable method exists and
applies. This directly answers the scout-brief's gap-line row "Named,
checkable heuristic set."

**Mandatory sections** (phase-1 proposal documents going forward):
1. Problem/goal framing — whose job, traced to the governing
   hypothesis/product-record (already required by `directive.sh:5`;
   made an explicit named section rather than implicit).
2. Comparison set / exemplars — which same-job products or patterns were
   examined (already required by `directive.sh:4`'s RESEARCH facet; made
   an explicit named section).
3. Methodology cited — the named method(s)/heuristic set(s) the
   proposal's judgments derive from (new, per above).
4. What will be delivered — the promised screens/flows/artifacts, traced
   to the goal framing (already required; named section).
5. Adopt/skip rationale — one pattern adopted and one deliberately
   skipped, each with a reason tied to this product's intent (already
   required by `directive.sh:4`; made an explicit named section rather
   than buried prose).
6. How it will be judged — success criteria, referencing the heuristic
   floor and/or accessibility floor as applicable (already required;
   named section).

**Evidence format**: every factual claim about how an exemplar product
or pattern behaves must cite the source (product name + what was
observed, or a documented source such as an NN/g article, IxDF
reference, or *About Face* — same citation discipline this brief itself
follows). Where no live research access exists (as in this cycle), the
proposal must say so explicitly and label its claims
"established-practice assumption" rather than presenting them as
independently verified — this is the same skip-record convention
issue-12's and issue-16's scout briefs already use for their own
no-web-access cases, not a new invention.

## (b) Phase-2 deliverable norms — methodology + mandatory components

**Finding this closes** (survey, "What is thin"; scout-brief gap-line
rows on flow artifacts, personas, fidelity staging, usability-test plan):
"screen/flow/wireframe specification" names three possible artifact
shapes without saying which are mandatory together, and several
field must-bes (goal-derived persona, staged fidelity, usability-test
plan) have no home in the current deliverable at all.

**Methodology**: goal-directed design's flow/state/persona triad (Cooper)
combined with Nielsen's ten-heuristic evaluation pass, both established
in the scout brief as the field's most portable and already
partially-adopted (six of ten heuristics already present unattributed in
`directive.sh`) methods for this role's scope.

**Mandatory components** (every phase-2 interaction-design deliverable
must contain all of):
1. **Goal/persona reference** — which user goal(s) and persona(s) (or,
   where no persona document exists in the work repo, the minimal
   goal statement standing in for one) the deliverable serves, traced to
   the governing hypothesis/product-record. Closes gap-line row
   "Goal-derived persona/user model required."
2. **Interaction/task flow** — a distinct flow artifact (diagram or
   structured table: steps, decision points, branches) separate from
   any single screen's wireframe, showing sequence through the task.
   Closes gap-line row "Task/interaction flow as mandatory artifact."
3. **Complete states per screen/flow** — empty, loading, error, success
   (already required today; carried forward unchanged, per this issue's
   constraint not to weaken existing rules).
4. **Wireframe or equivalent structural representation**, at the fidelity
   stage appropriate to the phase — low-fidelity (structural) before any
   high-fidelity treatment is introduced, named explicitly rather than
   left as an implicit convention. Closes gap-line row
   "Low-fidelity-before-high-fidelity discipline."
5. **Full ten-item Nielsen heuristic evaluation**, replacing the current
   unattributed six-item list, with each violated item noted explicitly
   rather than silently passed. Closes gap-line row "Named, checkable
   heuristic set." (The four items to add: match between system and the
   real world; flexibility and efficiency of use; aesthetic and
   minimalist design; help and documentation. The six already present —
   visible system status, user control/undo, consistency, error
   prevention over messages, recognition over recall, no dead
   ends — are unchanged.)
6. **Accessibility floor**, unchanged from today's rule (keyboard-
   reachable, focus-visible, labeled inputs, token-level contrast per
   issue-12), with an explicit stated conformance target added
   (WCAG 2.1 AA as the field-standard floor, named rather than implied).
   Closes gap-line row "Accessibility as design input" (partial-credit
   row upgraded to full).
7. **Usability-test plan** (not a conducted test) — what should be
   tested and by what method (e.g. think-aloud protocol against named
   tasks), acknowledging this role is spec-only and cannot itself
   conduct or report a test. Closes gap-line row "Usability-test plan as
   a deliverable component," calibrated to what a spec-only role can
   actually produce (a plan, not a report — see scout-brief "Skip"
   list).
8. **Traceability and scope-growth flag**, unchanged from today's rule
   (every element traces to the governing record; untraced elements
   flagged, not silently added).
9. **Spec-only output boundary**, unchanged (`src/` code is never
   produced; `loop_state: reviewed` remains this role's terminal state).

Items 3, 6 (partial), 8, and 9 already exist in `directive.sh` today and
are carried forward unchanged or extended, never weakened, per this
issue's explicit constraint to preserve existing record discipline.
Items 1, 2, 4, 5 (full ten), 6 (conformance target), and 7 are additions.

## (c) Rationale for each adoption choice

- **Full ten-item Nielsen heuristic set** (vs. keeping the current six):
  adopted because it is the scout-brief's top must-be and the gap-line's
  first row — the current six-item list already tracks four of Nielsen's
  ten unattributed, so completing the set costs nothing structurally and
  closes an evidence gap (an unattributed partial checklist reads as
  invented, a cited complete one reads as grounded).
- **Goal/persona reference as mandatory** (vs. leaving "governing
  record" tracing as sufficient): adopted because goal-directed design's
  core mechanism — using a named persona's goal to arbitrate design
  decisions — is precisely what "traces to the governing record" is
  missing today: a hypothesis names a business outcome, not a user's
  goal, and the scout brief identifies persona-as-decision-tool as a
  field must-be distinct from that.
- **Interaction/task flow as a distinct mandatory component** (vs.
  treating "flow" as interchangeable with "wireframe"): adopted because
  the gap-line shows this repo's directive currently blurs the two into
  one phrase ("screen/flow/wireframe specification"); the field
  consistently treats sequence-with-branches as a separate artifact from
  any single screen's layout, and this role's own quality bar already
  expects branch/error handling ("what happens when it fails") that only
  a flow artifact, not a wireframe, can show.
- **Low-fidelity-before-high-fidelity staging named explicitly** (vs.
  leaving fidelity unstated): adopted at low cost — it is a naming
  exercise, not new work, since a spec-only role by definition already
  produces structural (not pixel-level) artifacts; naming the discipline
  prevents future drift toward polish-first specs.
- **WCAG 2.1 AA named as the explicit conformance target** (vs. leaving
  "accessibility floor" as an unquantified list): adopted because an
  unnamed target cannot be checked for pass/fail; naming a specific,
  widely-adopted standard converts a qualitative floor into a checkable
  one without changing any of the four floor items already listed.
- **Usability-test plan, not a conducted test, as the mandatory unit**
  (vs. requiring an actual usability-test report): adopted specifically
  because the scout brief's own skip list flags a conducted-test
  requirement as exceeding this role's reach (spec-only, no
  implementation, no user access) — requiring a plan captures the
  field's must-be (usability validated, not assumed) without demanding
  evidence this role structurally cannot produce.
- **Design-thinking workshop artifacts (journey maps, empathy maps) —
  not adopted**: per the scout brief's skip list, these are heavier-
  weight, multi-day-workshop-format artifacts; the flow/persona/state
  triad already carries the same load-bearing must-bes (whose goal, what
  sequence, what state) without importing format overhead this
  single-role rulebook has no other machinery to support.

## (d) Plugin reflection plan

**Directive (`ux-design/hooks/directive.sh`) — concrete required-field
changes for phase 2:**
- `USE_WHEN` (CURRENT-STATE SURVEY): add that the survey must name which
  methodology/heuristic set will govern the proposal, same as the
  existing rule that a missing design-system document is itself a named
  finding (issue-12 precedent), not a silent gap.
- `PRODUCES` (PROPOSAL): add the six named mandatory sections from (a)
  above and the evidence-format rule (cite sources or label
  established-practice-assumption explicitly); existing design-system-
  establishment rule (issue-12) is preserved unchanged, this is additive.
- `HAND_OFF` (EXECUTION JUDGMENT): replace the current six-item
  unattributed heuristic list with the full cited ten-item Nielsen set;
  add the goal/persona-reference requirement, the distinct
  interaction/task-flow requirement, the fidelity-staging note, the named
  WCAG 2.1 AA conformance target, and the usability-test-plan
  requirement; leave the existing complete-states rule, name-only token
  rule, traceability rule, and spec-only boundary rule verbatim.
- `RECORD FORMAT` paragraph: unchanged — already states "write your
  record as your first act of phase 2," which this proposal relies on
  rather than restates.

**Record (`docs/issue-15/reports/interaction-design.md`) — required
fields for phase 2, going forward:**
- `loop_state` (existing vocabulary: `idle, drafting, reviewed`,
  terminal `reviewed` — unchanged, per this repo's existing convention
  and this issue's constraint not to weaken existing record discipline).
- A non-empty pointer to the governing hypothesis/product-record
  (existing requirement, restated so phase 2 cannot omit it).
- A non-empty pointer to the goal/persona reference used (new, per (b)
  item 1).
- The methodology/heuristic-set actually applied, named (new, per (a)
  and (b)).
- Confirmation that all nine mandatory-components from (b) are present
  in the delivered spec, or an explicit note of which are inapplicable
  and why (new — mirrors issue-16's record convention of stating actual
  pass/fail rather than a bare claim).
- What did not work / open findings (existing convention, per
  `docs/issue-12/reports/coding.md`'s own record shape — carried forward
  as the same section name for consistency).

**Gates (checklist items that must block phase-2 completion before
`loop_state: reviewed` can be reached):**
1. All nine (b) components present or explicitly marked inapplicable
   with reason — a deliverable silently missing one is incomplete, not
   minimal (mirrors the existing complete-states rule's own phrasing).
2. Full ten-item Nielsen evaluation actually performed and each
   violation (if any) stated explicitly, not silently passed.
3. Accessibility floor checked against the named WCAG 2.1 AA target,
   not left as an unquantified "looks accessible" judgment.
4. Record file (`docs/issue-15/reports/interaction-design.md`) exists
   and is the first commit of phase 2, per the existing RECORD FORMAT
   rule — this is not a new gate, it is the existing one, restated so
   this issue's proposal does not appear to silently drop it.
5. No new PreToolUse hook script is added to enforce items 1-3
   mechanically in this phase 2 (out of scope, see below) — these remain
   directive-level judgment gates, checked by the reviewing human at
   phase-2 PR review, same enforcement level issue-12's token-naming
   rule already operates at.

**Out of scope for phase 2 (explicitly, so it is not assumed later):**
- No new `*-gate.sh` script. Per the survey finding that
  `record-fields-gate.sh`/`trailer-gate.sh` are role-agnostic core canon
  (referenced, not vendored — README's own note, `core/hooks/
  {record-fields-gate.sh,trailer-gate.sh}`), and per issue-12's own
  precedent of leaving comparable rules as directive-level judgment
  rather than hook-mechanized, this proposal does the same: it adds
  directive text and record-field expectations, not a new PreToolUse
  check. A future issue may propose mechanizing these checks; this one
  does not.
- `docs/specs/approvers.md` — untouched; no approver-list change is in
  scope for a directive/record-content maturation.
- Historical `docs/issue-5/*`, `docs/issue-7/*`, `docs/issue-9/*`,
  `docs/proposals/*`, `docs/reports/*` (pre-per-issue-folder layout) —
  untouched.

## Canon citation note (warrant-hunter constraint)

This proposal does not need to reference the warrant-hunter role's own
rules anywhere in its content — interaction-design's methodology,
proposal norms, and deliverable norms are unrelated to warrant-hunting's
cadence/scope concerns. Per this issue's stated constraint and the
citation convention already established in this repo's own
`docs/issue-16/reports/implementation/current-state-survey.md`
("Landed by core issue #63... `docs/issue-63/reports/implementation.md`
in core, `loop_state: delivered`"): if a future revision of this
directive ever needs to point at warrant-hunter behavior, it must cite
core issue #63 / `tokenmaxxxer-core`'s own `warrant/agents/
warrant-hunter.md` by reference, never copy its rule text into this
rulebook. No such reference is added by this proposal since none is
needed for interaction-design's own content.

## Canon citation (interaction-design's own existing rule source)

Per this survey's own inventory: the interaction-design role's current
rules live in `ux-design/hooks/directive.sh` (lines 3-7, the four
`YOU_DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND_OFF` values plus the
`core_role_directive` call) and are restated in prose in `README.md`
("What `ux-design` decides," "What is here," "Record vocabulary"
sections). This proposal describes the phase-2 diff against those exact
locations by section name (CURRENT-STATE SURVEY / PROPOSAL / EXECUTION
JUDGMENT) rather than reproducing their existing body text here.

## Ordering within phase 2

1. Write `docs/issue-15/reports/interaction-design.md` with
   `loop_state: drafting` as phase 2's first act (existing RECORD FORMAT
   rule).
2. Edit `ux-design/hooks/directive.sh`'s `USE_WHEN` value (methodology-
   naming requirement in the survey).
3. Edit `PRODUCES` value (six mandatory proposal sections + evidence
   format).
4. Edit `HAND_OFF` value (nine mandatory deliverable components,
   full ten-item heuristic set, named WCAG target).
5. Extend `README.md`'s "What `ux-design` decides"/"What is here"
   sections to match, at the same detail level issue-12's README edit
   used.
6. Run `tests/parse-check.sh` to confirm `directive.sh` remains valid,
   parseable shell.
7. Update the record file to `loop_state: reviewed` with the required
   fields from (d) filled in, including confirmation of which of the
   nine components were verified present.

## What is deliberately not changed

- The four-facet structure of `directive.sh`
  (`YOU_DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND_OFF`) stays; this proposal
  only adds and re-orders content within the existing facets, per the
  same "existing structure stays, only what's asked for is added"
  discipline issue-12's proposal used.
- The existing complete-states rule, name-only token-reference rule,
  traceability rule, and spec-only output boundary — carried forward
  verbatim, per this issue's explicit constraint not to weaken existing
  record/documentation discipline.
- `loop_state` vocabulary (`idle, drafting, reviewed`) and its terminal
  state (`reviewed`) — unchanged.
- No new hook script, no change to `docs/specs/approvers.md`, no change
  to core-canon-owned gates.

## Basis

Upstream basis: `docs/issue-15/reports/interaction-design/survey.md` and
`docs/issue-15/reports/interaction-design/scout-brief.md` (this commit),
cross-referenced against this repo's own precedent proposals
`docs/issue-12/proposals/design-system-contract.md` and
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`
for structural convention, and against `ux-design/hooks/directive.sh` and
`README.md` for the exact current rule text being extended.
