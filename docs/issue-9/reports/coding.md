---
loop_state: reviewed
code_under_review: HEAD
---

# coding record — issue-9

## Why

Phase-1 survey (`docs/issue-9/reports/coding/survey.md`) found the
ux-design rulebook leaking routing-side knowledge — wake, WAKES-ON,
board-as-routing-device, downstream-role framing, and a pointer to
`docs/specs/wake-routing.md` — into a subject role's directive. A
rulebook does not need to know routing exists; every record obligation
those passages carry restates as a pure record-format requirement.
Phase 2 approved via PR #10 issue comment `APPROVE issue-9/coding`
(single-account mode, approver `JiwonJung94` per
`docs/specs/approvers.md`).

## What was done

Executed the approved proposal
`docs/issue-9/proposals/strip-wake-routing-vocabulary.md`.

- `ux-design/hooks/directive.sh`: replaced the "loop_state reviewed
  means... which role it summons is on-the-record routing (see
  `docs/specs/wake-routing.md`)" sentence with a plain statement that
  `loop_state: reviewed` is this role's terminal record state, full
  stop; rewrote "YOUR RECORD IS THE BOARD" (WAKES-ON, "board",
  "downstream role", "woken") as "RECORD FORMAT" (record path,
  first-act-of-phase-2, keep loop_state current at every transition,
  commit-on-branch — no wake/board/routing wording).
- `README.md`: dropped the "which role that state summons is
  on-the-record routing (see `docs/specs/wake-routing.md`)" clause;
  kept "loop_state: reviewed is this role's terminal record state."
- `ux-design/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`: replaced "loop_state reviewed
  wakes coding" with "loop_state reviewed is this role's terminal
  record state."
- `ux-design/hooks/record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh`: left untouched, per proposal (already
  free of routing vocabulary).
- `docs/specs/wake-routing.md`: not touched (out of scope, on-the-record
  host's canon).

## What did not work

Nothing — four files, matching the proposal's frozen write set exactly.

## Verification (closed_checks)

- `grep -rIln -E "wake|WAKES-ON|board" -i --exclude-dir=docs
  --exclude-dir=.git .` — one hit, `ux-design/hooks/directive.sh`, which
  on inspection is only the substring "keyboard-reachable" in the
  accessibility-floor line (false positive, no routing vocabulary
  remains). code_sha: HEAD (this commit).
- `git diff --stat` — confirms exactly the four proposal files touched,
  no other file. code_sha: HEAD (this commit).
- The four record obligations (path, phase-2-first write,
  per-transition loop_state update, commit-on-branch) remain stated in
  `ux-design/hooks/directive.sh`'s "RECORD FORMAT" section. code_sha:
  HEAD (this commit).

## Open findings

None.

## Next steps

None — issue-9 scope fully executed, ready for PR review/merge.

## Open-finding resolution path

Not applicable; no open findings.
