# current-state survey — issue-7

## Scope

`ux-design/hooks/directive.sh` line:

> loop_state reviewed means the spec is complete and internally
> consistent — it is what wakes coding.

This is the last remaining role-summoning phrase found by the grep
sweep that closed issue #5 (`grep -rli 'wakes' --include='*.md' .` only
covers `.md`; `directive.sh` is a shell heredoc, so it was missed by
that sweep and survived issue #5's cleanup).

## Precedent (issue #5, PR #6, merged)

Same pattern, same fix shape, in `README.md`:

- Before: "Reaching `loop_state: reviewed` is what wakes coding."
- After: "Reaching `loop_state: reviewed` is this role's terminal
  record state; which role that state summons is on-the-record routing
  (see `docs/specs/wake-routing.md`)."

`docs/specs/wake-routing.md` does not exist in this repo (it lives on
the separate on-the-record host per commit 0310a62's message: "repoint
... to on-the-record routing"). The pointer is a reference to that
external host, not a local file this repo must create.

## Write set (one file, one sentence)

- `ux-design/hooks/directive.sh` — drop "it is what wakes coding",
  keep the `loop_state: reviewed` = spec-complete-and-consistent
  semantics, repoint to `docs/specs/wake-routing.md` as the routing
  pointer, matching the README precedent's phrasing pattern.

No other file names a role being woken by `ux-design`'s state (verified
below).

## Verification

- `grep -n "wakes" ux-design/hooks/directive.sh` → the one target line.
- `grep -rli "wakes coding" --include='*.sh' .` → only this file.
- `grep -rli "wakes" --include='*.md' .` → only `docs/issue-5/` and
  `docs/issue-7/` tree files (this survey + the issue-5 record), no
  other `.md` names a role.
