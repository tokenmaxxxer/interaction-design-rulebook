---
subject: issue-16
role: implementation
loop_state: surveyed
---

# Scout brief — core canon reference conversion (issue-16)

Skip record for external web scouting: this is a purely internal
repo-convention conversion (removing local copies of files this
organization's own core repo now owns), not a product-facing question — no
external market/prior-art research applies. Internal repo sweep performed
instead, across four angles, sources cited as file:line (this repo and the
`tokenmaxxxer-core` canon checkout).

## Must-bes (what the conversion must not break)

- Every gate's fail-closed trap-at-top (`__fc`/`trap ... EXIT` as the first
  executable line) must survive — canon already carries it identically
  (`core/hooks/trailer-gate.sh:1-3`, `core/hooks/record-fields-gate.sh:1-3`
  match `ux-design/hooks/trailer-gate.sh:1-3`,
  `ux-design/hooks/record-fields-gate.sh:1-6` in shape).
- `record-fields-gate.sh`'s terminal-state set (`reviewed`, not `landed`)
  must be preserved via `RECORD_FIELDS_TERMINAL_STATES=reviewed`, or this
  role silently regresses to requiring next-steps/resolution-path on every
  `reviewed` record post-conversion (`ux-design/hooks/record-fields-gate.sh:165`
  vs `core/hooks/record-fields-gate.sh:86`).
- `directive.sh`'s role-unique payload (YOU DECIDE / RESEARCH /
  CURRENT-STATE SURVEY / PROPOSAL / EXECUTION JUDGMENT / RECORD FORMAT,
  `ux-design/hooks/directive.sh:12-80`) must all still surface at
  `SessionStart`, re-carried through `core_role_directive`'s four string
  args rather than dropped for brevity.
- `core/hooks/tests/stub-check.sh` must pass against this repo's `hooks/`
  tree post-conversion (work item 5) — it fails on ANY leftover file named
  `trailer-gate.sh`/`record-fields-gate.sh`/`handbook-trigger-gate.sh`/
  `parse-check.sh` under `hooks/**` (depth <=3), and structurally fails a
  `directive.sh` with any line beyond source/assignment/one call.

## Gaps found

- No `agents/warrant-hunter.md` or hunt-cadence text exists anywhere in this
  repo — work item 1 has no local file to remove here (confirmed via
  `find . -iname '*warrant*'`, only an unrelated prose match on "warranted"
  in `docs/issue-12/reports/coding.md:25`). The gap is the other direction:
  this repo's README (lines 3-10) and `.claude-plugin/marketplace.json`
  never named `warrant` as an installed core plugin set, even though core
  issue #63 landed it as a fifth plugin. Whether to add that reference is a
  documentation completeness question, not a removal — flagged in the
  proposal as optional, not required for this issue's five work items.
- This repo has no local `docs/specs/role-handoff-contract.md` (only
  `docs/specs/approvers.md`); `trailer-gate.sh`'s own `plausible_root()`
  checks for that filename as a root-detection fallback
  (`ux-design/hooks/trailer-gate.sh:95`) — canon's copy has the identical
  fallback check, so this is not a divergence, just noted as an odd
  cross-reference to a file this repo doesn't carry.
- `core/hooks/tests/stub-check.sh` is not yet vendored anywhere in this
  repo's `tests/` tree — it must be added as part of phase 2, not merely
  invoked from core (per core issue #66's own transition-path note: "Drop
  `core/hooks/tests/stub-check.sh` alongside each rulebook's existing
  `parse-check.sh`/`deny-only-check.sh` copies").

## Sources (file:line, all repo-internal)

- `ux-design/hooks/directive.sh:1-88` (this repo)
- `ux-design/hooks/trailer-gate.sh:1-178`, `record-fields-gate.sh:1-189`,
  `handbook-trigger-gate.sh:1-159`, `hooks.json:1-38` (this repo)
- `README.md:3-10` (this repo, plugin-set list)
- `tokenmaxxxer-core/core/hooks/lib/role-directive.sh:1-48`
- `tokenmaxxxer-core/core/hooks/tests/stub-check.sh:1-90`
- `tokenmaxxxer-core/core/hooks/hooks.json:1-46`
- `tokenmaxxxer-core/core/hooks/trailer-gate.sh:1-32`,
  `record-fields-gate.sh:1-40` (headers/kill-switch/config)
- `tokenmaxxxer-core/docs/issue-66/reports/implementation.md` (approved,
  `loop_state: delivered`, states the per-rulebook follow-up steps this
  proposal executes)
- `tokenmaxxxer-core/docs/issue-63/reports/implementation.md` (approved,
  `loop_state: delivered`, warrant-hunt canon promotion)
- `tokenmaxxxer-core/warrant/agents/warrant-hunter.md:1-157` (confirms no
  role-specific content here that this repo would need to preserve, since
  it never vendored a copy)
