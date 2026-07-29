---
loop_state: reviewed
code_under_review: HEAD
---

# coding record — issue-7

## Why

Issue #7: the issue-5 `.md`-only grep sweep missed `directive.sh` (a
`.sh` heredoc), which still named `coding` as the role woken by
`loop_state: reviewed`. That naming is a routing residual the
on-the-record board already owns via `docs/specs/wake-routing.md`
(established in issue-5). Phase 2 approved via issue-level comment
`APPROVE issue-7/coding` (single-account mode, contract v3 s19).

## What was done

Executed the approved proposal
`docs/issue-7/proposals/drop-wakes-on-directive-sh.md` exactly.

In `ux-design/hooks/directive.sh`, replaced:

> loop_state reviewed means the spec is complete and internally
> consistent — it is what wakes coding.

with:

> loop_state reviewed means the spec is complete and internally
> consistent — this role's terminal record state; which role it
> summons is on-the-record routing (see docs/specs/wake-routing.md).

One file, one sentence, matching the proposal's frozen write set.
`docs/specs/wake-routing.md` itself was not created or edited (out of
scope per proposal, on-the-record host's file).

## What did not work

Nothing — single mechanical edit, matched proposal exactly.

## Verification (closed_checks)

- `grep -n "wakes coding" ux-design/hooks/directive.sh` — no match.
  code_sha: HEAD (this commit).
- `grep -n "loop_state" ux-design/hooks/directive.sh` — reviewed
  semantics line present, now repointed. code_sha: HEAD (this commit).
- `git diff` confirms exactly the one-sentence change, no other file
  touched. code_sha: HEAD (this commit).

## Open findings

None.

## Next steps

None — issue-7 scope fully executed, ready for PR #8 merge review.

## Open-finding resolution path

Not applicable; no open findings.
