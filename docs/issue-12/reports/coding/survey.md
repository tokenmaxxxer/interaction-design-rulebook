# issue-12 current-state survey

## Scope
Add design-system contract discipline to the ux-design rulebook
(`ux-design/hooks/directive.sh` and its supporting docs): on a token-less
project, ux-design's first proposal establishes
`docs/specs/design-system.md`; specs reference semantic tokens by name;
raw values outside the primitive tier are flagged violations; the
accessibility floor is expressed at token level; changes to the
design-system document are themselves proposal-gated.

## Scout skip record
Not skipped, but not re-run either: the issue body (#12) already carries a
completed three-angle parallel sweep (Claude Code ecosystem precedent /
industry token standards / agent-workflow file-as-handoff-contract
pattern) with a `Sources:` list. Re-running the sweep here would
duplicate work already done and sourced. `docs/issue-12/reports/coding/scout-brief.md`
restates that sweep's findings as the steering brief for this proposal,
citing the issue's own sources rather than issuing new searches.

## Write surfaces found

- `ux-design/hooks/directive.sh` — CURRENT-STATE SURVEY section
  ("design tokens... already frozen") assumes tokens exist; no rule
  covers establishing them when absent. PROPOSAL section has no mention
  of tokens at all. EXECUTION JUDGMENT's accessibility-floor bullet
  ("contrast-safe") is per-screen, not token-level.
- `README.md` — "What `ux-design` decides" and "What is here" sections
  describe the four facets (research/survey/proposal/judgment) but do not
  mention token establishment or the design-system document as a
  governed artifact.
- `ux-design/hooks/record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — enforce record format and commit
  hygiene; none currently gate on design-system-document changes.
  Surveyed, out of scope for this issue (see below) — issue #12 asks for
  a *rule* (directive text), not a new enforcement gate.
- `docs/specs/` — currently holds only `approvers.md`. No
  `docs/specs/design-system.md` exists yet in this repo (expected: this
  rulebook repo is not itself a "project with screens/flows"; the
  document issue #12 describes is established by ux-design *in the work
  repos it operates in*, not in this rulebook repo. This rulebook only
  needs to state the rule, not instantiate the artifact here).

## What must be preserved
- The existing four-facet structure of `directive.sh` (RESEARCH /
  CURRENT-STATE SURVEY / PROPOSAL / EXECUTION JUDGMENT / RECORD FORMAT).
- The existing accessibility-floor bullet's other items (keyboard-reachable,
  focus-visible, labels on inputs) — only the contrast clause tightens to
  token-level.
- `README.md`'s existing "What `ux-design` decides" framing and "What is
  here" table shape.

## Out of scope
- Any new PreToolUse gate enforcing design-system-document proposal-gating
  mechanically (issue #12's requirements are directive-level rules for
  ux-design's own judgment, not a new hook — no gate script is named or
  implied by the issue text).
- Instantiating an actual `docs/specs/design-system.md` in this rulebook
  repo — that document is a work-repo artifact ux-design produces when
  operating on a subject project, not something this rulebook ships.
- `docs/issue-5/*`, `docs/issue-7/*`, `docs/issue-9/*` — historical,
  untouched.
