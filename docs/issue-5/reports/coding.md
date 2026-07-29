---
loop_state: idle
code_under_review: HEAD
---

# coding record — issue-5

## Why

Wake-routing ownership migration step 3 (operator decision 2026-07-30):
this rulebook must contain nothing about which role a record state
wakes; that routing now lives at `docs/specs/wake-routing.md` on the
on-the-record host. Phase 2 approved via PR #6 review
(`APPROVE issue-5/coding`).

## What was done

Executed the approved proposal
`docs/issue-5/proposals/drop-wakes-on-restatement.md` exactly.

- `README.md`: repointed the "Reaching `loop_state: reviewed` is what
  wakes coding" line to name on-the-record routing
  (`docs/specs/wake-routing.md`) instead of naming `coding` directly.
  Role's own `loop_state` vocabulary line left unchanged.

## What did not work

Nothing — single mechanical edit, matched proposal exactly.

## Verification (closed_checks)

- `grep -rli 'wakes\|WAKES-ON' --include='*.md' . | grep -v docs/issue-5/`
  — returns only the two issue-5 tree files (proposal, survey), no other
  file names a specific role. code_sha: HEAD (this commit).

## Open findings

None.

## Next steps

None — issue-5 scope fully executed, ready for PR #6 merge review.

## Open-finding resolution path

Not applicable; no open findings.
