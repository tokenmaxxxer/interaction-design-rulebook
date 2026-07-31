---
subject: issue-16
role: implementation
loop_state: surveyed
---

# Current-state survey — core canon reference conversion (issue-16)

Phase 1 only (research + survey + proposal). No files removed or edited yet.

## What was done

Surveyed this repo (`interaction-design-rulebook`, plugin `ux-design`) for
local copies of material that core has since promoted to canon, and
cross-read the canon source at `tokenmaxxxer-core` (checked out locally at
`/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`, referenced by this repo's own
README as the sibling plugin set) to confirm what each local file duplicates.

## Inventory: this repo's hooks tree

    ux-design/hooks/directive.sh              88 lines
    ux-design/hooks/trailer-gate.sh            178 lines
    ux-design/hooks/record-fields-gate.sh       189 lines
    ux-design/hooks/handbook-trigger-gate.sh    159 lines
    ux-design/hooks/hooks.json                  38 lines (registers all four)

No `agents/warrant-hunter.md` or any other warrant-hunter file exists
anywhere in this repo (`find . -iname '*warrant*'` returns nothing beyond an
incidental "warranted" prose match in docs/issue-12 reports — not the
hunter). This repo's README (lines 3-10) lists the plugin sets a ux-design
session installs as "this marketplace's `ux-design` plugin, and the
tokenmaxxxer-core plugins (`core`, `terse`, `freelunch`, `scout`)" — `warrant`
is not named. There is no local hunt-cadence directive text to remove.

## Cross-reference: core canon (tokenmaxxxer-core)

Confirmed present in core, matching the issue's description:

- `warrant/` — a fifth core plugin (`warrant/agents/warrant-hunter.md`,
  `warrant/hooks/{directive.sh,hunt-guard.sh,hunt-state.sh,scope-gate.sh,
  state.sh,hooks.json}`), registered in core's own
  `.claude-plugin/marketplace.json`. Landed by core issue #63
  (`docs/issue-63/reports/implementation.md` in core, `loop_state: delivered`).
- `core/hooks/{trailer-gate.sh,record-fields-gate.sh,handbook-trigger-gate.sh}`
  — the three role-agnostic gates, each reading role identity from
  `CLAUDE_ROLE` at runtime and registered core-side in `core/hooks/hooks.json`
  (`PreToolUse`, lines 13-41), firing for every plugin install automatically.
  Landed by core issue #66 (`docs/issue-66/reports/implementation.md` in
  core, `loop_state: delivered`).
- `core/hooks/lib/role-directive.sh` — sourceable library exposing
  `core_role_directive(you_decide, use_when, produces, hand_off)`, rendering
  the fixed preamble (trap/kill-switch/`CLAUDE_ROLE` guard/opening-closing
  lines) that core issue #66's survey found byte-identical across 43
  vendored `directive.sh` copies.
- `core/hooks/tests/stub-check.sh` — the drift-recurrence detector: fails if
  any of the four canon-gate filenames (`trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`) is
  found anywhere under a rulebook's own `hooks/` tree (depth <=3), and
  structurally checks that a rulebook's `directive.sh` is only: shebang,
  the `source .../role-directive.sh` line, plain variable assignments, and
  one `core_role_directive` call — any other line (case/guard/echo/cat) is
  flagged as regrown boilerplate.

## Per-file duplication finding

### 1. `ux-design/hooks/directive.sh` (docs/issue-16/reports/implementation/current-state-survey.md — this file's own repo, `ux-design/hooks/directive.sh:1-9`)

Lines 1-9 (shebang, trap, kill-switch case, `CLAUDE_ROLE` guard) are the
exact boilerplate core issue #66 factored into `core_role_directive`'s fixed
preamble — byte-for-byte the same shape as the other 42 rulebooks' copies
that motivated the promotion. Lines 11-84 (the `cat <<'DIRECTIVE' ... DIRECTIVE`
body) are ux-design's own role content: YOU DECIDE, RESEARCH, CURRENT-STATE
SURVEY, PROPOSAL, EXECUTION JUDGMENT, and RECORD FORMAT sections — this is
the role-unique payload that must be preserved, just re-carried through the
lib's four positional string arguments instead of a literal heredoc.

### 2. `ux-design/hooks/trailer-gate.sh` (full file, 178 lines)

Line-for-line comparable in structure and fail-closed trap shape
(`core/hooks/trailer-gate.sh:1-3` vs `ux-design/hooks/trailer-gate.sh:1-3`)
to the promoted canon file. The only role-specific content is the message
prefix `"ux-design: refused — ..."` (this repo's copy hardcodes the string
`ux-design`, `ux-design/hooks/trailer-gate.sh:18,37`), which canon now
derives from `CLAUDE_ROLE` at runtime (`core/hooks/trailer-gate.sh`, per its
own header). No behavior in this copy differs from canon; it is pure
duplication.

### 3. `ux-design/hooks/record-fields-gate.sh` (full file, 189 lines)

Same duplication pattern, with one genuine behavioral divergence: this
repo's terminal-state set is `TERMINAL = {"reviewed"}`
(`ux-design/hooks/record-fields-gate.sh:165`), not canon's default
`{"landed"}` (`core/hooks/record-fields-gate.sh:86`,
`RECORD_FIELDS_TERMINAL_STATES:-landed`). Core issue #66's own report
(`docs/issue-66/reports/implementation.md`, "Finding that changed the build")
anticipated exactly this: it found two vendored copies disagreeing on
terminal states and, rather than picking one, exposed
`RECORD_FIELDS_TERMINAL_STATES` (space-separated) as an env knob a rulebook
sets in its own `hooks.json` before deleting its local copy. This repo's
`reviewed` terminal state (matching this role's own vocabulary — see
`ux-design/hooks/directive.sh:50` "loop_state reviewed is this role's
terminal record state") is exactly the case that knob exists for, and must
be carried forward via config, not silently dropped to the `landed` default.

### 4. `ux-design/hooks/handbook-trigger-gate.sh` (full file, 159 lines)

Same duplication pattern as trailer-gate.sh: message prefix
`"ux-design-cycle: refused — ..."` is this copy's only role-specific text
(`ux-design/hooks/handbook-trigger-gate.sh:31,35,63,69,79,100`); canon
derives it from `CLAUDE_ROLE`. No behavioral divergence found (operational-
surface heuristics and the handbook-touch check are identical to
`core/hooks/handbook-trigger-gate.sh`).

### 5. `ux-design/hooks/hooks.json`

Registers all four hooks locally: `SessionStart -> directive.sh`,
`PreToolUse (Write|Edit|MultiEdit|NotebookEdit) -> record-fields-gate.sh`,
`PreToolUse (Bash) -> handbook-trigger-gate.sh, trailer-gate.sh`. Core's own
`core/hooks/hooks.json` now fires the three gates globally for every plugin
install (`PreToolUse` matcher `.*`, lines 13-41), so the three gate entries
here are a second, redundant registration once the vendored files are
deleted — only the `SessionStart -> directive.sh` entry (this role's own
stub) should remain.

## Stub verification target

`core/hooks/tests/stub-check.sh` is the machine-checkable gate work item 5
asks to record passing. It is not yet present under this repo's `tests/`
tree (only `tests/run-gate-tests.sh` — plus, per README, `parse-check.sh`
and `deny-only-check.sh` — exist today); dropping a copy of
`stub-check.sh` alongside them and wiring it into this repo's own harness is
itself one of the phase-2 execution steps (see proposal, item 5).

## Basis

Read directly from this checkout
(`/home/jwjung/.tokenmaxxxer/work/interaction-design-rulebook-issue-16-implementation`)
and from the core canon checkout
(`/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`, commits already landed per
`docs/issue-63/reports/implementation.md` and
`docs/issue-66/reports/implementation.md` there, both `loop_state: delivered`).

## Next steps

Phase 2 (after APPROVE): execute the proposal in
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`
verbatim, then record `stub-check.sh`'s pass in
`docs/issue-16/reports/implementation.md`.

## Open-finding resolution path

No open findings from this survey beyond the terminal-state divergence,
which the proposal resolves via `RECORD_FIELDS_TERMINAL_STATES=reviewed`
rather than leaving it unresolved.
