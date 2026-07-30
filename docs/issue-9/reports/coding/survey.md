# issue-9 current-state survey

## Scope
Strip wake/board-routing vocabulary from the ux-design rulebook (this repo's
"rulebook" = the `ux-design` plugin's directive and its surrounding
descriptions), restating record obligations as pure record-format
requirements. Historical docs (`docs/issue-*`, `docs/proposals`,
`docs/reports`) are untouched.

## Scout skip record
Skipped. Reason: the spec leaves no design decision open — the issue names
the exact vocabulary to remove and the exact framing to keep (path, kind,
loop_state, required fields, phase-2-first write, update-on-transition,
commit-on-branch). This is a mechanical text rewrite, not a product-shaped
decision.

## Write surfaces found

Swept the tracked tree (excluding `.git` and `docs/`, since historical docs
are out of scope) for `wake|WAKES-ON|board`:

- `ux-design/hooks/directive.sh` — lines 56-57 point to
  `docs/specs/wake-routing.md` as where the terminal loop_state's routing
  is decided; lines 59-66 are a section literally titled "YOUR RECORD IS
  THE BOARD" that uses WAKES-ON, "board", "downstream role", and "woken".
- `README.md` line 19-21 — "which role that state summons is on-the-record
  routing (see `docs/specs/wake-routing.md`)".
- `ux-design/.claude-plugin/plugin.json` line 3 and
  `.claude-plugin/marketplace.json` line 10 — both end their description
  with "loop_state reviewed wakes coding".

No routing vocabulary found in `ux-design/hooks/record-fields-gate.sh`,
`ux-design/hooks/trailer-gate.sh`, or `ux-design/hooks/handbook-trigger-gate.sh`
— those already state record requirements without wake/board framing.

## What must be preserved
- The record path (`docs/issue-<n>/reports/ux-design.md`), that it is
  written as the first act of phase 2, that loop_state updates at every
  transition, and that it must be committed on the branch — all of this
  stays, restated as format requirements only.
- `loop_state: reviewed` remains named as this role's terminal record
  state; only the claim about who reads it / what it summons is removed.

## Out of scope
- `docs/issue-5/*`, `docs/issue-7/*` and any other historical
  `docs/issue-*`, `docs/proposals`, `docs/reports` content — untouched per
  the issue.
- `docs/specs/wake-routing.md` itself — that file is on-the-record's canon
  and is not part of this rulebook.
