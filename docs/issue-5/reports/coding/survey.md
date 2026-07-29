# issue-5 current-state survey

## Scope of the scan

Grep for `wakes`/`WAKES-ON`/`wake-on` (case-insensitive) across all
`*.md` in the repo, excluding `docs/issue-*/` trees (per the issue's
instruction to exclude issue-scoped material from the audit).

## Hits

- `README.md:19` — "Reaching `loop_state: reviewed` is what wakes
  coding." This is a WAKES-ON routing restatement: it names which role
  (`coding`) a state (`loop_state: reviewed`) summons. This rulebook's
  own record states/format description (the line names its own
  `loop_state: reviewed` terminal value) may stay; only the
  "wakes coding" clause routes to another role and must be stripped or
  repointed to `docs/specs/wake-routing.md` on the on-the-record host
  repo.

## No other hits

- `docs/README.md` — no wake mentions.
- `docs/specs/approvers.md` — no wake mentions.
- `docs/proposals/2026-07-26-gates-fail-closed-trap-at-top.md` — no wake
  mentions.
- `docs/specs/state-machine.md` referenced in `docs/README.md` but does
  not exist in this repo — out of scope (nothing to edit).

## Write set (frozen for phase 2)

- `README.md` — one line edit: drop or repoint the "wakes coding"
  clause; keep the `loop_state: reviewed` (terminal) fact itself.

No other files in this repo restate WAKES-ON routing outside
`docs/issue-*/`.
