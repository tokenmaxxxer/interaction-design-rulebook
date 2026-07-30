# Proposal: strip wake/board-routing vocabulary from the ux-design rulebook

files:
- `ux-design/hooks/directive.sh`
- `README.md`
- `ux-design/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

## Request (paraphrased intent)
The rulebook currently leaks routing-side knowledge — wake, WAKES-ON,
board-as-routing-device, downstream-role framing, and a pointer to
`docs/specs/wake-routing.md` — into a subject role's directive. Restate
every record obligation those passages carry as a pure record-format
requirement instead: path, kind/section name, loop_state vocabulary,
required fields, write-first-in-phase-2, update-loop_state-on-every-
transition, commit-on-branch. Remove the routing framing and the pointer
to routing canon entirely; a rulebook does not need to know routing
exists.

## Constraints
- Historical docs (`docs/issue-5/*`, `docs/issue-7/*`, and any other
  `docs/issue-*`, `docs/proposals`, `docs/reports` content) stay untouched.
- `docs/specs/wake-routing.md` itself is out of scope — it is
  on-the-record's canon, not this rulebook.
- The record obligations themselves (path, first-act-of-phase-2, loop_state
  updates on transition, commit-on-branch) must survive the rewrite —
  only the routing-device framing and vocabulary go.

## What will be done
- `ux-design/hooks/directive.sh`:
  - Replace the "loop_state reviewed means... which role it summons is
    on-the-record routing (see `docs/specs/wake-routing.md`)" sentence
    with a plain statement that `loop_state: reviewed` is this role's
    terminal record state, full stop.
  - Rewrite the "YOUR RECORD IS THE BOARD" section (WAKES-ON, "board",
    "downstream role", "woken") as a "RECORD FORMAT" section: record path,
    that it must be written as the first act of phase 2, that its
    loop_state must be kept current at every transition, and that it must
    be committed on the branch — with no mention of wake, board, or who
    reads it.
- `README.md`: drop the "which role that state summons is on-the-record
  routing (see `docs/specs/wake-routing.md`)" clause from the role
  summary; keep "loop_state: reviewed is this role's terminal record
  state."
- `ux-design/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`:
  replace the trailing "loop_state reviewed wakes coding" clause in each
  description with "loop_state reviewed is this role's terminal record
  state."

## Out of scope
- Any file under `docs/issue-5`, `docs/issue-7`, or other historical
  `docs/issue-*` / `docs/proposals` / `docs/reports` paths.
- `docs/specs/wake-routing.md` and on-the-record's routing canon generally.
- `ux-design/hooks/record-fields-gate.sh`, `trailer-gate.sh`,
  `handbook-trigger-gate.sh` — surveyed, already free of routing
  vocabulary, no change needed.

## How it will be known to work
- `grep -rIln -E "wake|WAKES-ON|board" <tracked files outside docs/>` finds
  no remaining hits (already verified clean on the reverted-to-original
  tree save for the four files above).
- The four record obligations (path, kind, phase-2-first write, per-
  transition loop_state update, commit-on-branch) are still stated in
  `ux-design/hooks/directive.sh` after the rewrite, just without routing
  vocabulary.
