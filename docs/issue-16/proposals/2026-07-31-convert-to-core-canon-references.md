---
status: proposed
subject: issue-16
role: implementation
---

# Proposal — convert to core canon references (issue-16)

Phase 1 output. Describes the exact phase-2 diff; does not execute it.
Addresses the issue's five work items in order, against the survey in
`docs/issue-16/reports/implementation/current-state-survey.md`.

## Item 1 — remove local warrant-hunter copy, reference core canon

**Finding**: this repo has no local `agents/warrant-hunter.md` or hunt-cadence
directive text to remove (survey, "Inventory"). Core issue #63 landed
`warrant/` as a fifth core plugin, byte-identical content to the standalone
0.4.1 source. This repo's own README (lines 3-10) already documents that a
ux-design session installs "this marketplace's `ux-design` plugin, and the
tokenmaxxxer-core plugins (`core`, `terse`, `freelunch`, `scout`)" — `warrant`
is missing from that list even though the environment presumably now
installs it too (it is core's plugin, not this repo's).

**Proposed diff**: add `warrant` to the plugin-set list in `README.md` line 6
(`... the tokenmaxxxer-core plugins (core, terse, freelunch, scout, warrant)
...`), one word. No hook file changes — there is nothing to delete. This is
a documentation-completeness fix, not a removal; flagged as optional
relative to the issue's mandatory scope, since the issue's own wording
("제거 → core canon 참조로 교체") presumes a local copy that does not exist
here.

## Item 2 — remove gate copies + their hook registrations

**Delete** (all three are pure duplication of canon per the survey, no
role-specific logic beyond a message-prefix literal that canon now derives
from `CLAUDE_ROLE`):

    ux-design/hooks/trailer-gate.sh
    ux-design/hooks/record-fields-gate.sh
    ux-design/hooks/handbook-trigger-gate.sh

**Edit** `ux-design/hooks/hooks.json`: remove the entire `PreToolUse` block
(both matcher entries — `Write|Edit|MultiEdit|NotebookEdit` and `Bash`);
keep only the `SessionStart -> directive.sh` entry. Core's own
`core/hooks/hooks.json` already fires all three gates globally
(`PreToolUse`, matcher `.*`) for every plugin install, so this repo's
registration becomes redundant, not merely unnecessary.

Resulting `hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh"
          }
        ]
      }
    ]
  }
}
```

**Preserve** (role-specific, keep as-is, not part of this conversion): the
README's own hooks-tree listing (lines 24-42) needs its three deleted-gate
description lines removed at the same time, to avoid documenting files that
no longer exist — this is a doc-sync side effect of item 2, not a
behavior change.

## Item 3 — replace directive.sh with a stub, preserve role-unique content

**Delete** the current 88-line `ux-design/hooks/directive.sh` (boilerplate
lines 1-9 + heredoc body lines 11-84) and **replace** with a stub of the
shape `core/hooks/tests/stub-check.sh` structurally requires: shebang, the
`trap`/`set` pair (per core issue #66's own report: this pair "stays at the
top of each rulebook's own file" because a trap installed inside the
sourced function can't catch the sourcing script's own abnormal exit), the
`source .../role-directive.sh` line, four variable assignments, and one
`core_role_directive` call.

Proposed content:

```bash
#!/usr/bin/env bash
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

YOU_DECIDE="YOU DECIDE: how the accepted problem becomes screens, flows, and
interaction — the experience risk. You take the governing hypothesis /
product-record as given (the WHAT is product's call) and own the HOW a
user moves through it. Your deliverable is a screen/flow/wireframe
specification concrete enough for coding to build from without asking
what goes where.

RESEARCH (phase 1, scout protocol): exemplars are the best-in-class
products' flows FOR THE SAME USER JOB — walk how they handle this flow,
extract the interaction must-bes (what every product in the category
does, whose absence reads as broken), the navigation/layout conventions
users arrive already trained on, and one pattern to adopt and one to
deliberately skip with reasons tied to this product's intent. Also pull
the platform's own conventions (web/mobile/desktop) — fighting them is a
cost that needs a stated reason."

USE_WHEN="CURRENT-STATE SURVEY (phase 1): the governing hypothesis or
product-record (the accepted problem framing your screens must answer),
the existing screens/flows this issue touches, and the constraints
already frozen — design tokens, component inventory, platform. No
design-system document (\`docs/specs/design-system.md\` or the project's
equivalent) is itself a survey finding, named as missing, not a silent
gap the proposal skips past."

PRODUCES="PROPOSAL (phase 1): promise the spec — which screens/flows will exist,
the user job each one serves (traced to the governing record), and how
success will be judged. A proposal with no pointer to the governing
hypothesis/product-record is not reviewable. On a project the survey
found token-less, your FIRST proposal instead establishes
\`docs/specs/design-system.md\`: token tiers primitive -> semantic
(component tier optional, where warranted), covering at minimum a
spacing scale, a type scale, and semantic colors with on-color pairing;
a layout grid/breakpoints section; a component inventory. A
DTCG-compatible \`tokens.json\` alongside is encouraged, not required.
Once it exists, the design-system document is a frozen contract like any
other: changes to it go through the same proposal-gate as screens/flows
— never edited silently mid-flow."

HAND_OFF="EXECUTION JUDGMENT (phase 2, quality bar):
- Every flow answers: where am I, what can I do, how do I go back, what
  happens when it fails. A flow with no error/empty/loading state is
  incomplete, not minimal.
- Heuristic floor (deterministic checklist, note violations explicitly):
  visible system status; user control and undo; consistency with the
  platform and with this product's own conventions; error prevention
  over error messages; recognition over recall; no dead ends.
- Every screen/flow spec references semantic tokens by name; a raw
  value appearing outside the primitive tier is flagged in the spec as a
  violation, not passed through silently.
- Accessibility floor: keyboard-reachable, focus-visible, labels on
  inputs, and contrast expressed at the token level (paired on-colors or
  a graded/tested scale) so contrast holds by construction rather than
  by per-screen inspection — called out in the spec, not left to coding.
- Every screen element traces to the governing record's problem/metric;
  an element serving no recorded need is scope growth, flagged not
  silently added.
- You spec, you never implement: output is specification (wireframe
  text/diagrams, flow tables, states), never src/ code. loop_state
  reviewed is this role's terminal record state, full stop.

RECORD FORMAT (do not skip this): research files, surveys, and proposals
are not the record. Write your record as your FIRST act of phase 2, and
keep its loop_state current at every transition. Ending phase 2 without
your record committed on the branch means the record was never written.
(Measured: a phase-1-only issue left the record empty.)"

core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
```

Note on the source-path expression: `${CLAUDE_PLUGIN_ROOT_CORE:-...}` matches
core issue #66's own documented usage pattern for a rulebook's `directive.sh`
(`core/hooks/lib/role-directive.sh:13`); the fallback assumes core's plugin
is installed as a sibling directory to this plugin (`../../core` from
`ux-design/hooks/`) the way `scout`/`terse`/`freelunch` already are per this
marketplace's own layout convention — phase 2 must confirm the exact
relative path against how `CLAUDE_PLUGIN_ROOT` resolves in the installed
environment (not fully verifiable from a static read of this checkout alone)
before landing.

`core_role_directive` already appends `RECORD: docs/issue-<n>/reports/${role}.md,
phase-gated per contract v3 s19` after the four args — this duplicates but
does not contradict the more detailed RECORD FORMAT paragraph folded into
`HAND_OFF` above; the extra detail (write-as-first-act, measured finding) is
role-specific nuance the generic canon line doesn't carry, so it is kept
inline rather than dropped.

`stub-check.sh`'s structural check (survey, "Stub verification target")
requires every non-blank/non-comment line to be the source line, a plain
`VAR="..."` assignment, or the one `core_role_directive` call — the
multi-line quoted assignments above satisfy that (bash treats a quoted
multi-line string as one assignment statement).

## Item 4 — preserve role-specific terminal-state divergence

**Add** to `ux-design/hooks/hooks.json`'s `SessionStart` hook entry (or, if
env vars cannot be set per-hook-invocation in this harness, to the
plugin's declared env or to `directive.sh` itself, whichever this repo's
existing kill-switch convention already uses to set process env for hooks
— confirmed against the installed harness during phase 2, not staticly
verifiable here): `RECORD_FIELDS_TERMINAL_STATES=reviewed`. This preserves
`ux-design/hooks/record-fields-gate.sh:165`'s existing behavior
(`TERMINAL = {"reviewed"}`) instead of silently regressing to canon's
`landed`-only default once the local gate copy is deleted (item 2). Without
this, every record ending in `loop_state: reviewed` would start being
denied for missing next-steps/resolution-path sections it correctly omits
today.

## Item 5 — confirm stub-check.sh passes, record it

**Add** `tests/stub-check.sh` (verbatim copy of
`tokenmaxxxer-core/core/hooks/tests/stub-check.sh`, distributed the same
way `parse-check.sh` already is per that file's own header) and wire it into
this repo's test harness alongside the existing
`tests/run-gate-tests.sh`/`parse-check.sh`/`deny-only-check.sh` (README's
"Run the checks" section, lines 62-66, gains a fourth line:
`/bin/bash tests/stub-check.sh ux-design/hooks`).

**Record**: phase 2's `docs/issue-16/reports/implementation.md` must state
the actual `stub-check.sh ux-design/hooks` run output (pass/fail, not a
claim of having run it) before `loop_state` there can reach a terminal
state — per this repo's own record-fields-gate discipline (item 4), which
still applies to phase 2's own record even as the gate file itself is
being deleted and re-sourced from canon mid-issue.

## Ordering within phase 2

1. Add `warrant` to README's plugin list (item 1, independent, no risk).
2. Set `RECORD_FIELDS_TERMINAL_STATES=reviewed` in `hooks.json` (item 4)
   — before deleting the local gate, so canon's default is never live even
   momentarily.
3. Delete the three gate files + trim `hooks.json`'s `PreToolUse` block
   (item 2).
4. Replace `directive.sh` with the stub (item 3).
5. Add `tests/stub-check.sh`, run it, fix anything it flags, record the
   pass (item 5).
6. Sync README's hooks-tree listing and "Run the checks" section to match
   the new file set.

## What is deliberately not changed

- `tests/run-gate-tests.sh`'s own inline gate re-implementations used for
  testing (it exercises the hook files as subprocesses, not by importing
  logic) — once the gate files it points at (`$HOOKS/$3`) no longer exist
  locally, this repo's own test harness needs a phase-2 decision on whether
  those specific test cases move to core's `run-role-gates-tests.sh` or are
  dropped as redundant; not decided here, flagged for phase-2 judgment since
  it is a test-authorship call, not a canon-reference conversion.
- `ux-design/hooks/directive.sh`'s substantive role content (the four
  argument blocks above) is carried forward unchanged, word-for-word,
  except for the mechanical repackaging into `core_role_directive`'s
  calling convention.

## Basis

Upstream basis: `docs/issue-16/reports/implementation/current-state-survey.md`
and `docs/issue-16/reports/implementation/scout-brief.md` (this commit),
cross-referenced against `tokenmaxxxer-core` commits landing core issue #63
(`loop_state: delivered`) and core issue #66 (`loop_state: delivered`).
