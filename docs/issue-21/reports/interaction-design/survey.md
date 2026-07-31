---
subject: issue-21
role: interaction-design
loop_state: surveyed
---

# Current-state survey — mechanical enforcement of the interaction-design
# methodology (issue-21)

## 1. Scope of this survey

Issue #21 asks: the methodology adopted in issue-15 (interaction-design's
research/survey/proposal/judgment method — heuristic set, persona/goal
model, task-flow artifact, state completeness, accessibility floor,
usability-test plan) was written into `directive.sh` as prose and recorded
in `docs/issue-15/proposals/interaction-design.md`, but nothing in the repo
*mechanically checks* that a given proposal or record actually contains
those elements. The bar to match is described in the issue body as
"implementation-rulebook's hook-machine, 400+ lines, gates + state
tracking" and a `pricing-rulebook`/`methodology-gate.sh` PreToolUse-gate
pattern. Neither `implementation-rulebook` nor `pricing-rulebook` exists as
a file tree in *this* repo (`ux-design-rulebook`) — they are sibling
rulebooks in the same `tokenmaxxxer` organization, referenced by the issue
author from outside this checkout. This survey therefore records the
target bar exactly as stated in the issue body (verbatim ask, not
independently inspected source) and flags that as a gap in this survey's
own evidence, per this role's own citation-format rule
(`ux-design/hooks/directive.sh`, PRODUCES section, "Evidence format").

## 2. What the directive currently says

`ux-design/hooks/directive.sh` (SessionStart, four facets: `YOU_DECIDE`,
`USE_WHEN`, `PRODUCES`, `HAND_OFF`) already carries the issue-15
methodology as prose:

- `PRODUCES` names six mandatory phase-1 proposal sections (problem/goal
  framing; comparison set/exemplars; methodology cited; what will be
  delivered; adopt/skip rationale; how it will be judged) and an evidence
  citation format requirement.
- `HAND_OFF` names nine mandatory phase-2 components (goal/persona
  reference; distinct task-flow artifact; complete states; low-fidelity-
  before-high-fidelity staging; full ten-item Nielsen heuristic set;
  WCAG 2.1 AA accessibility floor; usability-test plan; traceability/
  scope-growth flagging; spec-only output boundary).
- `USE_WHEN` requires the phase-1 survey to name the governing
  hypothesis/product-record, touched screens, frozen constraints, and the
  methodology/heuristic set that will govern the proposal — explicitly
  calling out that an unnamed methodology, or a missing design-system
  document, is itself a survey finding rather than a silent gap.

See `README.md:25-38` for the human-readable digest of the same content,
and `docs/issue-15/proposals/interaction-design.md` (approved, cited in
`README.md:38`) as the record of adoption. Per this survey's own
constraint, canon text is cited by path/section, not reproduced here.

## 3. What issue-15 adopted, and where it is recorded

- `docs/issue-15/reports/interaction-design/survey.md` — current-state
  survey that identified the six-item unattributed heuristic gap, missing
  persona/goal model, missing flow-as-distinct-artifact requirement, etc.
- `docs/issue-15/reports/interaction-design/scout-brief.md` — the scout
  brief (established-practice-assumption sourced: Nielsen/NN/g, IxDF,
  Cooper's *About Face*, IDEO/Stanford d.school) with an explicit "GAP
  LINE" table (`scout-brief.md:104-118`) enumerating field must-bes vs.
  then-current repo state.
- `docs/issue-15/proposals/interaction-design.md` — the 330-line proposal
  that promised the six/nine-item structure.
- `2244b72` ("feat(issue-15): reflect approved interaction-design
  maturation proposal into directive + record") — the commit that folded
  the approved proposal into `directive.sh` and `README.md`. This is the
  terminal artifact: the methodology now lives as directive prose, per
  the commit title itself ("into directive + record"), not as any
  enforced check.

## 4. What enforcement/verification exists today

None, specific to the interaction-design methodology content. Concretely:

- `tests/parse-check.sh`, `tests/stub-check.sh`, `tests/deny-only-check.sh`
  verify `directive.sh`'s *shell-level* shape (parses, no stray local
  hook files reappearing, deny-only patterns) — none of them read the
  *content* of `PRODUCES`/`HAND_OFF` and check that a proposal or record
  actually contains the six or nine named items.
- `tests/run-gate-tests.sh` is a stub (0 tests) — see its own header
  comment: the role-agnostic gates it used to exercise (record-fields,
  trailer, handbook-trigger) were promoted to core canon in issue-16 and
  are no longer tested locally; it does not, and never did, test
  methodology-specific content.
- Core canon (installed via the `tokenmaxxxer-core` plugin set, per
  `README.md:5-11`) enforces role-agnostic shape: record-field minimums,
  commit-trailer format (`Subject: issue-<n>`), and same-turn handbook
  sync (s20/s21, "core issue-66," `README.md:68-70`). These fire for
  every plugin install and check structural fields (e.g. `loop_state`
  presence), not domain content — they would not catch a proposal missing
  the "adopt/skip rationale" section or a record missing the named
  heuristic set.
- There is no PreToolUse hook in this repo scoped to interaction-design's
  own proposal/record write surface (only `ux-design/hooks/hooks.json`'s
  `SessionStart` directive injection exists — see
  `ux-design/hooks/hooks.json`). Nothing blocks a write of
  `docs/issue-<n>/proposals/*.md` that omits, say, the methodology-cited
  section or the Nielsen heuristic pass.
- `.claude/agents/` (repo root) is empty in this checkout — no
  interaction-design-specific agent or checklist exists to walk the
  nine-item phase-2 procedure repeatably.

This confirms the issue's own diagnosis: "채택 방법론이 directive 한 줄
... 문서로만 남았다" — the methodology is real prose but zero mechanical
teeth.

## 5. The target bar: implementation-rulebook's hook-machine (as described)

Per the issue-21 body (not independently inspected — see §1 gap note):

- implementation-rulebook enforces its own adopted methodology with a
  hook-machine "400+ lines" covering progress gates and state tracking,
  making conformance mechanical rather than trust-based.
- `pricing-rulebook`'s `methodology-gate.sh` is cited as the closest
  existing pattern for a **methodology gate**: a PreToolUse hook that
  fires on the record/proposal write surface and checks for the
  required sections/elements before allowing the write (or before
  passing the gate), rather than relying on the author to remember them.
- The issue further asks that if the adopted methodology implies an
  *ordering* constraint (e.g., "survey before evidence before adoption"),
  that ordering be enforced via state tracking (a status file), not just
  prose sequence.

**Gap to close (this survey's headline finding):** interaction-design has
the *content* bar (six-section proposal, nine-component judgment, per
`directive.sh`) but none of the *mechanical* bar (no PreToolUse
methodology gate on the proposal/record write surface, no per-issue
status/state file tracking phase progression, no gate test suite
exercising pass/reject cases for this role's specific required
elements). Closing this gap — while keeping canon scripts referenced,
never copied, per the core `canon-scripts.md` constraint — is the subject
of the accompanying proposal
(`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`).
