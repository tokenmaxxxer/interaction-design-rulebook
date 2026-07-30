# Proposal: design-system contract discipline for the ux-design rulebook

files:
- `ux-design/hooks/directive.sh`
- `README.md`

## Request (paraphrased intent)
The rulebook's phase-1 survey step currently reads design tokens as a
constraint that's already frozen, with no rule for what ux-design does
when a project has none, and no rule tying screen/flow specs to tokens
by name. On a token-less project this leaves every spec free to invent
ad-hoc raw values, which coding then hardcodes. Per issue #12 (grounded
in a scouted sweep of the Claude Code design-tooling ecosystem and
industry token standards, both embedded in the issue body): when no
design-system document exists, ux-design's *first* proposal on that
project establishes one at `docs/specs/design-system.md` — tiered
tokens (primitive → semantic, component optional), a layout
grid/breakpoints section, and a component inventory, with an optional
DTCG `tokens.json`. Specs reference semantic tokens by name; a raw value
outside the primitive tier is a flagged violation. The accessibility
floor is expressed at token level (paired on-colors / a graded or
tested scale) so contrast holds by construction. Changes to the
design-system document are themselves proposal-gated, same as any other
contract downstream work consumes.

## Constraints
- This is a rulebook repo, not a work repo with actual screens — the
  proposal edits the *rule text* in `directive.sh` (and its `README.md`
  summary), not an instantiated `docs/specs/design-system.md` file in
  this repo (survey: no such artifact belongs here; see
  `docs/issue-12/reports/coding/survey.md`).
- No new PreToolUse gate — issue #12's requirements are directive-level
  judgment rules for ux-design, not a new hook script (survey: none
  named or implied).
- The existing four-facet structure of `directive.sh` and the existing
  accessibility-floor bullet's other items (keyboard-reachable,
  focus-visible, labels on inputs) stay; only the pieces issue #12
  actually asks for are added.
- Historical `docs/issue-5/*`, `docs/issue-7/*`, `docs/issue-9/*` stay
  untouched.

## What will be done
- `ux-design/hooks/directive.sh`:
  - CURRENT-STATE SURVEY section: add that when no
    `docs/specs/design-system.md` (or project-equivalent) exists yet,
    that absence itself is a survey finding, not a silent gap — the
    survey names it as missing.
  - PROPOSAL section: add that on a token-less project, ux-design's
    first proposal establishes `docs/specs/design-system.md`: token
    tiers primitive → semantic (component tier optional, "where
    warranted"), covering at minimum a spacing scale, a type scale, and
    semantic colors with on-color pairing; a layout grid/breakpoints
    section; a component inventory. A DTCG-compatible `tokens.json`
    alongside is noted as encouraged, not required. State plainly that
    changes to an *existing* design-system document are themselves
    proposal-gated — never edited silently mid-flow, same contract
    discipline as any other frozen artifact downstream work depends on.
  - EXECUTION JUDGMENT section: add that every screen/flow spec
    references semantic tokens by name; a raw value appearing outside
    the primitive tier is flagged in the spec as a violation, not passed
    through silently. Tighten the accessibility-floor bullet's contrast
    clause from a per-screen "contrast-safe" check to token-level: the
    floor is expressed at the token level (paired on-colors or a
    graded/tested scale) so contrast holds by construction rather than
    by per-screen inspection; the other floor items (keyboard-reachable,
    focus-visible, labels on inputs) are unchanged.
- `README.md`: extend the "What `ux-design` decides" and/or "What is
  here" sections with a one-line pointer to the design-system-contract
  rule (established on token-less projects, proposal-gated
  thereafter), matching the level of detail already given to the other
  three facets.

## Out of scope
- Any new gate script (`ux-design/hooks/*-gate.sh`) mechanically
  enforcing token-name-only references or proposal-gating — left to
  ux-design's own judgment per the directive text, not hook-enforced,
  unless a future issue asks for that.
- Instantiating `docs/specs/design-system.md` in this rulebook repo.
- `docs/specs/approvers.md`, `ux-design/hooks/record-fields-gate.sh`,
  `trailer-gate.sh`, `handbook-trigger-gate.sh` — surveyed, no change
  needed; issue #12 does not touch record format or commit hygiene.
- `docs/issue-5/*`, `docs/issue-7/*`, `docs/issue-9/*`.

## How it will be known to work
- `ux-design/hooks/directive.sh` after the rewrite states, in the
  PROPOSAL section, the exact establish-if-absent rule (path, tier
  names, minimum coverage, optional `tokens.json`) and the
  proposal-gating rule for subsequent changes.
- `ux-design/hooks/directive.sh`'s EXECUTION JUDGMENT section states the
  name-only-reference rule and the token-level accessibility floor,
  with the other three floor items unchanged from today's text.
- `tests/parse-check.sh` still passes (directive.sh remains valid,
  parseable shell/heredoc) — run once before opening the PR.
- `git diff --stat` shows only the two files above touched.
