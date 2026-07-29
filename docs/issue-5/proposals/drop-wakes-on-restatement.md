---
status: proposed
---

# Drop WAKES-ON routing restatement from README.md

files: README.md

## Scout skip record

Skipped — pure mechanical edit, no design decision open (skip condition
2: the issue text fully specifies the change; nothing to research).

## Request (paraphrased intent)

Wake-routing ownership migration step 3: this rulebook must not restate
which role a record state summons — that routing now lives at
`docs/specs/wake-routing.md` on the on-the-record host repo. Audit every
WAKES-ON/wake mention in this repo's rulebook files (excluding
`docs/issue-*/`), keep this role's own record states/format, strip or
repoint anything naming which role a state wakes.

## Constraints

- Keep statements about this role's own record states/format
  (`loop_state: idle, drafting, reviewed`) intact.
- Strip or repoint anything naming which role a state summons.
- Scope excludes `docs/issue-*/` trees.

## What will be done

In `README.md`, the "What `ux-design` decides" section currently reads:

> Reaching `loop_state: reviewed` is what wakes coding. Spec only —
> never implementation.

Repoint this to the on-the-record host doc instead of naming `coding`
directly, e.g.:

> Reaching `loop_state: reviewed` is this role's terminal record state;
> which role that state summons is on-the-record routing (see
> `docs/specs/wake-routing.md`). Spec only — never implementation.

No other file in this repo (outside `docs/issue-*/`) restates WAKES-ON
routing — confirmed by grep survey (see
`docs/issue-5/reports/coding/survey.md`).

## Out of scope

- `docs/specs/state-machine.md`, referenced by `docs/README.md` but
  absent from this repo — nothing to edit.
- Any file under `docs/issue-*/`.
- Editing `docs/specs/wake-routing.md` itself — that file lives in the
  on-the-record host repo, not here.

## How it will be verified

After the edit: grep for `wakes`/`WAKES-ON` across `*.md` excluding
`docs/issue-*/` should return no hit that names a specific role, and the
role's own `loop_state` vocabulary line must remain unchanged.
