# proposal — drop 'it is what wakes coding' from directive.sh

files: `ux-design/hooks/directive.sh`

## Request (paraphrased intent)

Issue #7: the grep sweep that closed issue #5 missed one file —
`ux-design/hooks/directive.sh` (a `.sh` heredoc, outside the `.md`
sweep) — still names `coding` as the role woken by
`loop_state: reviewed`. Drop that naming, keep the `loop_state:
reviewed` = spec-complete-and-internally-consistent semantics, repoint
to on-the-record routing if a pointer is needed.

## Constraints

- One-file, one-sentence change (issue's own framing).
- Keep the `loop_state: reviewed` semantics intact — this is not a
  removal of the concept, only of which role it names.
- Match the phrasing pattern already merged for the equivalent
  README.md line in issue #5 / PR #6, for consistency across the
  rulebook.
- No new local file: `docs/specs/wake-routing.md` is the on-the-record
  host's file, not this repo's to create.

## What will be done

In `ux-design/hooks/directive.sh`, replace:

> loop_state reviewed means the spec is complete and internally
> consistent — it is what wakes coding.

with:

> loop_state reviewed means the spec is complete and internally
> consistent — this role's terminal record state; which role it
> summons is on-the-record routing (see docs/specs/wake-routing.md).

## Out of scope

- Creating or editing `docs/specs/wake-routing.md` itself.
- Any other file in the repo (grep confirms no other `.sh`/`.md`
  outside the issue-5/issue-7 trees still names a woken role).
- Editing `ux-design/hooks/directive.sh`'s other sections (the
  "YOUR RECORD IS THE BOARD" paragraph already uses "downstream role"
  generically and is unaffected).

## How it'll be known to work

- `grep -n "wakes coding" ux-design/hooks/directive.sh` returns nothing
  after the edit.
- `grep -n "loop_state" ux-design/hooks/directive.sh` still shows the
  `reviewed` semantics line, now repointed rather than removed.
- Diff is exactly the one sentence, matching the proposal's write set.
