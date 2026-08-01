# id-stage-order

One of eleven methodology plugins that together implement the
interaction-design gate machine per
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(§3 plugin catalog, §4 composition). This is the one **cross-cutting**
plugin: it owns the interaction-design methodology's stage ordering
(survey -> scout -> proposal -> [human approval] -> phase-2 record),
composing into BOTH the phase-1 proposal norm and the phase-2 judgment
norm (§4), unlike the other ten plugins, which each own a single
phase's single methodology.

## What it owns

Two purely local, file-EXISTENCE-only ordering checks — never content,
never a GitHub/network call:

1. **Before a NEW `docs/issue-<n>/proposals/*.md` write** (the file does
   not yet exist on disk at write time — an EDIT to an already-existing
   proposal file is always allowed; ordering only gates the first
   creation): both
   `docs/issue-<n>/reports/interaction-design/survey.md` and
   `docs/issue-<n>/reports/interaction-design/scout-brief.md` must
   already exist on disk, UNLESS `survey.md` itself records an explicit
   scout-skip — a line matching `/skip(ped)?/i` near `/scout/i` — in
   which case `scout-brief.md`'s absence is excused. Denies naming
   exactly which of the two is missing.

2. **Before a `docs/issue-<n>/reports/interaction-design.md` write**
   (the phase-2 record): at least one `docs/issue-<n>/proposals/*.md`
   file must already exist on disk.

## What it explicitly does NOT do

This plugin does **not** check GitHub or human approval itself. Core's
`core/hooks/approval-gate.sh` already fail-closed-blocks any write to
`docs/issue-<n>/reports/<role>.md` (the phase-2 record — the same file
check 2 above also gates) until an allowlisted human's Approve exists on
GitHub, via a PR review or an exact `APPROVE issue-<n>/<role>` issue
comment (contract v3 s19). `id-stage-order`'s record-write check is a
narrower, purely-local precondition — "a proposal document exists" —
layered **on top of**, never instead of, core's approval-gate. Neither
check in this plugin ever shells out to `gh` or makes a network call.

## The shared on-disk contract: `.status.json`

On every passing write handled above (not a skip-exit for an
out-of-scope path), this plugin read-merges-writes
`docs/issue-<n>/reports/interaction-design/.status.json`: a JSON object
keyed by `"issue-<n>"`, each value an object with string fields:

| Key | Meaning |
|---|---|
| `survey` | `"done"` once `survey.md` is present on disk |
| `scout` | `"done"` once `scout-brief.md` is present, or an explicit scout-skip is recorded in `survey.md` |
| `proposal` | `"done"` once at least one `docs/issue-<n>/proposals/*.md` file is present |
| `record` | `"done"` once `docs/issue-<n>/reports/interaction-design.md` is present |

Example: `{"issue-21": {"survey": "done", "scout": "done", "proposal": "done", "record": "pending"}}`

These four fields are **recomputed from actual file presence on every
passing write, never trusted from a prior value** — the file cannot
silently drift from reality by hand-editing omission.

This file is the shared on-disk contract the other ten interaction-design
plugins each independently read/write their own additional key into
(e.g. `proposal_shape`, `citation_format`, `persona_goal`,
`nielsen_heuristics`, and so on, one key per plugin) — no plugin-to-plugin
code dependency, only this one shared file, read-merged (never clobbered
wholesale) on every write. `id-stage-order` never inspects or depends on
any of those other keys; it only ever reads and writes its own four.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN /
  PRODUCES / HAND-OFF for the cross-cutting ordering role, sourced from
  the shared `core/hooks/lib/role-directive.sh` convention. Explicitly
  states it composes into both phase-1 and phase-2 norms, and that it
  never checks GitHub approval itself.
- `hooks/stage-order-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`.
  Fails closed. Only acts on new proposal writes and record writes; any
  other path is not this gate's business (exit 0). Denies with
  `id-stage-order: refused — %s`, naming exactly which prerequisite
  artifact(s) are missing.
- `tests/id-stage-order-gate-tests.sh` — plain-bash probe suite (this
  repo's `tests/deny-only-check.sh` / `tests/stub-check.sh` convention,
  not bats): ordering-violation deny, ordering-satisfied allow,
  self-update of `.status.json`, record-with-no-proposal deny,
  record-with-proposal allow, unrelated-path allow.

## Kill switch

`export ID_STAGE_ORDER_GATE_OFF=1` disables this plugin's gate only,
independent of the other ten interaction-design plugins.

## How it composes

Per the proposal's §4:

- **Phase-1 proposal norm** = `id-proposal-shape` ∧ `id-citation-format`
  ∧ `id-stage-order` (checking `survey: done, scout: done` before
  allowing a proposal write).
- **Phase-2 judgment norm** = `id-persona-goal` ∧ `id-task-flow` ∧
  `id-state-completeness` ∧ `id-wireframe-staging` ∧
  `id-nielsen-heuristics` ∧ `id-accessibility-floor` ∧
  `id-usability-test-plan` ∧ `id-traceability` ∧ `id-stage-order`
  (checking that a proposal exists before allowing the phase-2 record
  write; core's `approval-gate.sh` separately, and independently,
  enforces the human-Approve precondition on the same write).

All gates fire independently on the same write surface; the write is
allowed only if every currently-installed plugin for that surface
allows it. Each plugin can be installed, killed, or fail independently
of the others — a false positive or a kill switch in one plugin never
blocks (or silently passes) a write that only another plugin cares
about.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
for the full design this plugin is one piece of, and
`core/hooks/approval-gate.sh` for the GitHub/human-approval check this
plugin deliberately does not duplicate.
