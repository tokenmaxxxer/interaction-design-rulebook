# issue-12 scout brief

Mode: not re-swept — issue #12's body already carries a completed
three-angle parallel sweep (Claude Code ecosystem precedent / industry
token standards / agent-workflow file-as-handoff pattern), one round,
with sources. This brief restates it as the steering input for the
proposal, per the survey's skip-record note.

## Category must-bes (from the issue's sweep)
- A persisted design-system document loaded every iteration, not
  reasoning that evaporates between turns (superdesign
  `.superdesign/design-system.md`; interface-design
  `.interface-design/system.md`).
- Tiered tokens: primitive → semantic (→ component where warranted) —
  Style Dictionary, Material 3 (ref/sys/comp), Tokens Studio, and
  delightful-claude-plugin's 3-tier OKLCH tokens all converge on this.
- Specs reference tokens by semantic name; raw values confined to the
  primitive tier, enforced by naming/construction/lint (shadcn MCP:
  semantic CSS-variable tokens "by construction").
- DTCG `.tokens.json` as the stable interchange format (first stable
  2025-10) when a tool downstream consumes tokens as data, not just prose.

## Performance axes this category competes on
1. Whether tokens are *persisted as a file* the agent re-reads (vs.
   reasoned fresh each time) — the file-as-handoff-contract pattern
   (Anthropic subagents: implementer sees the spec file, not the
   designer's reasoning).
2. Whether accessibility is guaranteed *by construction* at the token
   level (USWDS grade-difference arithmetic, Material/shadcn paired
   on-color roles, GOV.UK tested scale points) vs. checked per-screen
   after the fact.
3. Whether the token document itself is under change control (procedural
   phase gates — GitHub Spec Kit, Kiro) vs. editable ad hoc mid-flow.

## Adopt / skip
- Adopt: 3-tier primitive→semantic token document as a persisted file,
  named-reference-only in specs, token-level accessibility floor, and
  proposal-gating on changes to the document — all four are named
  explicitly in issue #12's requirements and are the convergent pattern
  across every scouted exemplar.
- Skip: mandating a *component*-tier or a DTCG `tokens.json` — issue #12
  marks both "where warranted" / "encouraged," not required. This rulebook
  states them as optional so a token-less project's first proposal isn't
  blocked on machinery it may not need yet.

## Segment fit
This rulebook governs a *role's directive*, not a product. The fit is:
match the *governance shape* other systems converge on (persisted file,
tiered tokens, proposal/phase gating) without copying any one exemplar's
specific file path or tooling — `docs/specs/design-system.md` is this
stack's own path convention (matches `docs/specs/approvers.md` already in
this repo), not superdesign's or interface-design's.

## Gap line
Current `ux-design/hooks/directive.sh` already has the four-facet
structure (research/survey/proposal/judgment) and an accessibility-floor
bullet, satisfying the *shape* of "judgment happens somewhere." It is
missing: (a) any rule for what happens when no design-system document
exists yet, (b) any rule tying specs to token names vs. raw values, (c)
token-level (vs. per-screen) accessibility framing, (d) proposal-gating
on the design-system document itself. All four are what issue #12 asks
for — the gap is exact, not partial re-derivation needed.

Stages used: 0 sweep stages (reused issue's embedded sweep) + this
one synthesis stage. Wall-clock: negligible (no new searches issued).

Sources (carried from issue #12's body):
- https://github.com/superdesigndev/superdesign-skill
- https://github.com/Dammyjay93/interface-design
- https://github.com/kylesnav/delightful-claude-plugin
- https://github.com/marvkr/better-design
- https://ui.shadcn.com/docs/theming
- https://github.com/anthropics/claude-code (frontend-design skill, plugins)
- https://designtokens.org/tr/drafts/format
- https://styledictionary.com/info/dtcg
- https://m3.material.io/foundations/design-tokens
- https://designsystem.digital.gov/design-tokens
- https://design-system.service.gov.uk/styles
- https://claude.com/blog/subagents-in-claude-code
- https://github.com/github/spec-kit
