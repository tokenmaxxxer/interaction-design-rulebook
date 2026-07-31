---
subject: issue-15
role: interaction-design
loop_state: surveyed
---

# Current-state survey — interaction-design rulebook maturity (issue-15)

Phase 1 only (research + survey + proposal). No directive, hook, or record
schema files edited.

## What was done

Surveyed this repo (`ux-design-rulebook`, plugin `ux-design`) for every
write surface a phase-1/phase-2 interaction-design cycle already touches,
and for what governs those surfaces' expected shape today. Compared
against the two most recent completed phase-1-to-phase-2 maturation cycles
in this repo — `docs/issue-16/*` (core-canon reference conversion) and
`docs/issue-12/*` (design-system contract discipline) — as the maturity
baseline this issue is being asked to reach for interaction-design's own
proposal/deliverable norms specifically.

## Inventory: write surfaces this rulebook already has

- `ux-design/hooks/directive.sh` (2 lines + 4 heredoc-style variable
  assignments, sourced from `core/hooks/lib/role-directive.sh`) — the
  single canonical statement of what this role decides, researches,
  surveys, proposes, and is judged on. Its `USE_WHEN`/`PRODUCES`/
  `HAND_OFF` strings are the only place phase-1 proposal shape and
  phase-2 deliverable shape are currently specified for this role.
- `docs/specs/approvers.md` — one GitHub login per line; gates who may
  post the phase-2 APPROVE. Not touched by this issue's phase 1.
- `docs/decisions/` — empty (no ADRs recorded yet for any role).
- `docs/handbooks/tests.md` — operational test-running handbook, not a
  content-methodology document; not directly relevant to interaction-design
  proposal/deliverable norms.
- `docs/proposals/2026-07-26-gates-fail-closed-trap-at-top.md` and
  `docs/reports/2026-07-30-hunt-design-system-contract.md` — repo-root-level
  proposal/report pairs from earlier, pre-per-issue-folder convention;
  superseded by the `docs/issue-<n>/proposals/`, `docs/issue-<n>/reports/`
  per-issue layout that issue-12 and issue-16 both use, which this issue
  mirrors.
- `docs/issue-16/reports/implementation/{current-state-survey.md,
  scout-brief.md}` and `docs/issue-16/proposals/
  2026-07-31-convert-to-core-canon-references.md`, plus
  `docs/issue-12/reports/coding/{survey.md,scout-brief.md}` and
  `docs/issue-12/proposals/design-system-contract.md` — the two precedent
  phase-1 doc sets this survey/scout-brief/proposal mirrors for structure,
  naming, and tone.

## What already exists for interaction-design specifically

`directive.sh`'s `PRODUCES` value already states a partial deliverable
norm: on a token-less project, the first proposal must establish
`docs/specs/design-system.md` (tiered tokens, layout grid/breakpoints,
component inventory) — landed by issue-12
(`ux-design/hooks/directive.sh:5`, cf.
`docs/issue-12/proposals/design-system-contract.md`). Its `HAND_OFF` value
states a partial deliverable quality bar: complete states (where/what/back/
fail), a six-item heuristic floor, name-only token references, an
accessibility floor, traceability to the governing record, and a
spec-only (never `src/`) output boundary (`ux-design/hooks/directive.sh:6`).
Its `USE_WHEN` value states the current-state-survey's required inputs:
governing hypothesis/product-record, existing screens/flows, frozen
constraints (`ux-design/hooks/directive.sh:4`). The README's "What
`ux-design` decides" and "What is here" sections restate the same content
in prose for onboarding (`README.md`).

## What is thin, unknown, or contested

- **No named methodology.** The directive states *what* a proposal must
  promise (screens/flows traced to the governing record, success
  criteria) and *what* a deliverable must contain (heuristic floor,
  accessibility floor, complete states), but never names or cites an
  underlying design methodology (e.g., goal-directed design, a stated
  process model, a named heuristic set) that these requirements derive
  from. The six-item "heuristic floor" is unattributed prose that
  resembles but does not cite Nielsen's ten usability heuristics — no
  source, no acknowledgment that only six of ten are carried, no
  rationale for which four were dropped.
- **No mandatory-sections list for phase-1 proposal documents
  themselves.** Issue-12's and issue-16's proposals both follow an
  informal but consistent shape (files touched / request / constraints /
  what will be done / out of scope / how it will be known to work, or
  survey-basis / gap / diff-by-item / ordering / what's not changed) —
  but this shape is a convention observed in the two precedent PRs, not
  written down anywhere as a rule. Nothing in `directive.sh` or the
  README requires a phase-1 proposal to contain any specific section set
  or evidence format; a future proposal could omit "how it will be known
  to work" entirely and nothing would catch it.
- **No mandatory-components list for phase-2 deliverables.** `HAND_OFF`
  states quality-bar judgment criteria (the heuristic floor, accessibility
  floor, etc.) but never enumerates what artifact types a phase-2
  deliverable must actually contain as file-level components — e.g.
  whether an interaction-flow diagram, a state diagram, or a wireframe
  annotation is required versus optional, or in what format (text table,
  Mermaid diagram, image) each must appear. "Screen/flow/wireframe
  specification" (directive.sh:3) names three possible artifact shapes
  without saying which are mandatory together and which are alternatives.
- **No evidence-format rule for phase-1 docs.** Unlike issue-16's and
  issue-12's own scout briefs (both cite file:line or issue-body sources
  explicitly), nothing in this repo's plugin directive or specs requires
  a phase-1 interaction-design proposal to cite sources at all — a
  proposal could assert "best-in-class products handle this flow as X"
  with no method, comparison set, or citation and nothing would flag it
  as unsupported.
- **`record-fields-gate.sh` and `trailer-gate.sh` are role-agnostic core
  canon**, not role-specific to interaction-design
  (`core/hooks/{record-fields-gate.sh,trailer-gate.sh}`, referenced but
  not vendored per the README's own note: "s20 record-field minimums...
  are core canon gates now — no local copy lives in this rulebook").
  This means any interaction-design-specific mandatory record fields
  (e.g., a required pointer to which methodology was used, a required
  heuristic-floor checklist result) can only be enforced today through
  `directive.sh`'s prose guidance, not through a gate — a gap phase 2's
  reflection plan needs to account for rather than assume a new gate
  script will close automatically.
- **No `docs/issue-15/reports/interaction-design.md` record file exists
  yet** (correctly — it is phase 2's artifact, not phase 1's, per this
  role's own RECORD FORMAT rule in `directive.sh:6`, "Write your record
  as your FIRST act of phase 2"). Its required fields are therefore
  entirely open, to be specified by this issue's proposal for phase 2 to
  follow.

## Comparison to issue-16 / issue-12 maturity level

Issue-12 raised the *deliverable-contract* bar for one specific concern
(design tokens) by adding concrete, checkable rules to `directive.sh` and
a rationale trail (issue body's own scouted sweep) but did not touch
proposal-document *format* — issue-12's own proposal is itself an example
of the informal convention, not a codification of it. Issue-16 raised the
*plugin-hygiene* bar (removing duplication, converting to canon references)
but is orthogonal to interaction-design's methodology content — it
touched hook files, not the substantive research/proposal/deliverable
rules this issue is asked to examine. Neither prior cycle produced a
written methodology citation, a mandatory-sections list for phase-1 docs,
or a mandatory-components list for phase-2 deliverables — this issue's
gap is real and unaddressed by precedent, not merely unaddressed by
coincidence.

## Basis

Read directly from this checkout at
`/home/jwjung/.tokenmaxxxer/work/interaction-design-rulebook-issue-15-interaction-design`:
`ux-design/hooks/directive.sh`, `README.md`, `docs/specs/approvers.md`,
`docs/decisions/`, `docs/handbooks/tests.md`, `docs/proposals/`,
`docs/reports/`, `docs/issue-16/*`, `docs/issue-12/*`.

## Next steps

Phase 1 continues with `docs/issue-15/reports/interaction-design/
scout-brief.md` (domain methodology scan) and
`docs/issue-15/proposals/interaction-design.md` (proposal norms +
deliverable norms + rationale + plugin reflection plan), both grounded in
the gaps named above. Phase 2 (after APPROVE) executes that proposal
against `ux-design/hooks/directive.sh` and, as its first act, writes
`docs/issue-15/reports/interaction-design.md`.
