---
loop_state: reviewed
code_under_review: HEAD
---

# coding record — issue-12

## Why

Issue #12: the ux-design rulebook's directive treats design tokens as an
already-frozen constraint and has no rule for establishing them when a
project has none, nor for tying screen/flow specs to tokens by name.
Phase 2 approved via merged PR #13 (proposal
`docs/issue-12/proposals/design-system-contract.md`).

## What was done

Executed the approved proposal against its frozen write set exactly:

- `ux-design/hooks/directive.sh`:
  - CURRENT-STATE SURVEY: absence of `docs/specs/design-system.md` (or
    project equivalent) is now a named survey finding, not a silent gap.
  - PROPOSAL: on a token-less project, the first proposal establishes
    `docs/specs/design-system.md` — tiers primitive -> semantic
    (component optional, where warranted), minimum coverage (spacing
    scale, type scale, semantic colors with on-color pairing), layout
    grid/breakpoints, component inventory, `tokens.json` encouraged not
    required; existing design-system docs are proposal-gated like any
    other frozen contract.
  - EXECUTION JUDGMENT: added the name-only token-reference rule for
    specs (raw value outside primitive tier = flagged violation);
    tightened the accessibility floor's contrast clause to token-level
    (paired on-colors / graded-tested scale), leaving
    keyboard-reachable/focus-visible/labels-on-inputs unchanged.
- `README.md`: extended the "What is here" directive.sh summary with a
  pointer to the new proposal/judgment content, matching the existing
  detail level.

## What did not work

Nothing — two files, matching the proposal's frozen write set exactly.

## Verification (closed_checks)

- `bash tests/parse-check.sh` — all four hook scripts, including the
  edited `directive.sh`, parse OK under `/bin/bash`. code_sha: HEAD
  (this commit).
- `git diff --stat` before commit showed only `README.md` and
  `ux-design/hooks/directive.sh` touched — matches the proposal's frozen
  write set. code_sha: HEAD (this commit).
- Warrant-hunt (stance: composition/consistency regression in the
  directive.sh + README changes) — NO FINDING; record at
  `docs/reports/2026-07-30-hunt-design-system-contract.md`. code_sha:
  HEAD (this commit).

## Open findings

None.

## Next steps

None — issue-12 scope fully executed, ready for PR review/merge.

## Open-finding resolution path

Not applicable; no open findings.
