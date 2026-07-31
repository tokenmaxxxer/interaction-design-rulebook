---
subject: issue-21
role: interaction-design
loop_state: drafting
---

# Proposal — interaction-design gate machine, as a plugin set (issue-21)

**PHASE 1 ONLY.** This is a design proposal for review, not an
implementation. It contains no code changes to `src/`, no gate scripts,
no new `.claude-plugin/plugin.json` files, and no changes to
`ux-design/hooks/directive.sh`, `hooks.json`, or
`.claude-plugin/marketplace.json` — every plugin, gate, and test named
below is a phase-2 build item, described here for human approval only.
Canon scripts are referenced by path, never inline-copied (core
`canon-scripts.md`).

**Revision note.** This supersedes the prior draft of this file (commit
`8cb94cf`), which the approver's FEEDBACK on PR #22 marked FAIL: it
proposed a single `methodology-gate.sh` + one `.status.json` file, not
the required **plugin set**. This revision keeps the Nielsen-10 /
Cooper-triangle content bar unchanged and restructures the mechanism
entirely around independent, self-contained plugins, each owning exactly
one methodology, registered in `marketplace.json` — the same shape core's
own `freelunch`/`scout` plugins already take. The gate-matching strategy
(§4) is decided in this document, not deferred to phase 2.

## 1. Problem framing (traced to survey + scout brief)

Per `docs/issue-21/reports/interaction-design/survey.md` §4-5 and
`docs/issue-21/reports/interaction-design/scout-brief.md`'s GAP LINE: the
interaction-design methodology adopted in issue-15 exists only as
directive prose (`ux-design/hooks/directive.sh` `PRODUCES`/`HAND_OFF`) —
zero mechanical enforcement, one undifferentiated block per phase. The
issue's own corrected requirement is explicit: not a single deepened
directive or one monolithic gate, but a **plugin set** — one independent,
self-contained plugin per adopted methodology, each installable/
kill-switchable on its own, composed together to constitute the phase-1
and phase-2 norms respectively. This proposal's structure below *is* the
design — not a restatement of six/nine bullet content.

## 2. The adopted methodologies, decomposed to one-plugin-each

Issue-15's approved proposal (`docs/issue-15/proposals/interaction-design.md`,
folded into `directive.sh` at `2244b72`) bundled several genuinely
distinct methodologies into two prose blocks. Un-bundling them by the
single-methodology-per-plugin rule gives:

| # | Methodology | Currently lives in | Phase it gates |
|---|---|---|---|
| 1 | Six-section phase-1 proposal shape (problem/goal, comparison set, methodology cited, delivery scope, adopt/skip, judged-by) | `directive.sh` `PRODUCES` | phase 1 |
| 2 | Evidence citation format (sourced or "established-practice assumption") | `directive.sh` `PRODUCES` | phase 1 |
| 3 | Goal/persona reference model (Cooper, *About Face*) | `directive.sh` `HAND_OFF` | phase 2 |
| 4 | Distinct task/interaction-flow artifact (separate from wireframes) | `directive.sh` `HAND_OFF` | phase 2 |
| 5 | Complete-states-per-screen/flow requirement | `directive.sh` `HAND_OFF` | phase 2 |
| 6 | Low-fidelity-before-high-fidelity wireframe staging | `directive.sh` `HAND_OFF` | phase 2 |
| 7 | Nielsen's ten usability heuristics, full pass | `directive.sh` `HAND_OFF` | phase 2 |
| 8 | Accessibility floor, WCAG 2.1 AA | `directive.sh` `HAND_OFF` | phase 2 |
| 9 | Usability-test plan (planned, not conducted) | `directive.sh` `HAND_OFF` | phase 2 |
| 10 | Traceability / scope-growth flagging + spec-only output boundary | `directive.sh` `HAND_OFF` | phase 2 |
| — | Stage ordering (survey → scout → proposal → approval → judgment) | nowhere (issue-21 ask) | both, cross-cutting |

Content is unchanged from issue-15's approved text — this table only
names the seams along which it splits into plugins.

## 3. Plugin catalog (mandatory per the approver's correction)

Ten methodology plugins plus one cross-cutting ordering plugin, each
self-contained (own `hooks/`, own gate script, own agent/checklist where
the methodology needs one, own test file) and each registered as its own
entry in `.claude-plugin/marketplace.json`, next to the existing
`ux-design` entry — mirroring how `tokenmaxxxer-core` registers
`freelunch` and `scout` as separate installable plugins rather than one
"core-extras" bundle.

| Plugin name | Owns (single methodology) | Components (phase-2 build items) | Phase |
|---|---|---|---|
| `id-proposal-shape` | Row 1: six-section proposal | `hooks/proposal-shape-gate.sh` (PreToolUse), `tests/proposal-shape-gate-tests.sh` | 1 |
| `id-citation-format` | Row 2: evidence citation format | `hooks/citation-gate.sh` (PreToolUse), `tests/citation-gate-tests.sh` | 1 |
| `id-persona-goal` | Row 3: Cooper persona/goal model | `hooks/persona-goal-gate.sh`, `agents/persona-goal-checklist.md`, `tests/persona-goal-gate-tests.sh` | 2 |
| `id-task-flow` | Row 4: distinct task-flow artifact | `hooks/task-flow-gate.sh`, `tests/task-flow-gate-tests.sh` | 2 |
| `id-state-completeness` | Row 5: complete states per screen/flow | `hooks/state-completeness-gate.sh`, `tests/state-completeness-gate-tests.sh` | 2 |
| `id-wireframe-staging` | Row 6: lo-fi-before-hi-fi staging | `hooks/wireframe-staging-gate.sh`, `tests/wireframe-staging-gate-tests.sh` | 2 |
| `id-nielsen-heuristics` | Row 7: Nielsen 10-item heuristic pass | `hooks/nielsen-gate.sh`, `agents/nielsen-checklist.md`, `tests/nielsen-gate-tests.sh` | 2 |
| `id-accessibility-floor` | Row 8: WCAG 2.1 AA floor | `hooks/accessibility-gate.sh`, `tests/accessibility-gate-tests.sh` | 2 |
| `id-usability-test-plan` | Row 9: usability-test plan | `hooks/usability-test-gate.sh`, `tests/usability-test-gate-tests.sh` | 2 |
| `id-traceability` | Row 10: traceability/scope-growth + spec-only boundary | `hooks/traceability-gate.sh`, `tests/traceability-gate-tests.sh` | 2 |
| `id-stage-order` | Cross-cutting: survey→scout→proposal→approval→judgment ordering | `hooks/stage-order-gate.sh` (PreToolUse, all write surfaces), owns `.status.json` schema + read/write, `tests/stage-order-gate-tests.sh` | both |

Each plugin is a normal marketplace entry (`.claude-plugin/plugin.json` +
`hooks/hooks.json`), same shape as `ux-design/.claude-plugin/plugin.json`
today — none of them share a hook file or a gate script with another;
a false positive in `id-nielsen-heuristics` cannot block a write that
only `id-task-flow` cares about, and either plugin can be killed
independently (`ID_NIELSEN_HEURISTICS_OFF=1`, etc., one env var per
plugin, following the existing `UX_DESIGN_CYCLE_OFF` convention).

## 4. Composition: how the plugins add up to each phase's norm

This is the part the prior draft skipped — *which plugins combine to
make phase 1's norm, and which combine to make phase 2's norm* is itself
the design, per the approver's correction.

- **Phase-1 proposal norm** = `id-proposal-shape` ∧ `id-citation-format` ∧
  `id-stage-order` (checking `survey: done, scout: done` before allowing
  a proposal write). All three gates fire on the same write surface
  (`docs/issue-<n>/proposals/*.md`) independently; the write is allowed
  only if all three currently-installed phase-1 plugins allow it. A repo
  that only installs `id-proposal-shape` (e.g. `id-citation-format`
  killed) gets a weaker but still-functioning phase-1 norm — composition
  is additive, not all-or-nothing.
- **Phase-2 judgment norm** = `id-persona-goal` ∧ `id-task-flow` ∧
  `id-state-completeness` ∧ `id-wireframe-staging` ∧
  `id-nielsen-heuristics` ∧ `id-accessibility-floor` ∧
  `id-usability-test-plan` ∧ `id-traceability` ∧ `id-stage-order`
  (checking `approved: done` before allowing the phase-2 record write).
  All nine fire on `docs/issue-<n>/reports/ux-design.md` (the phase-2
  record) and on any wireframe/spec artifact path the record points to.
- **Gate-matching strategy (decided now, not deferred):** every gate
  reads the *proposed* content (the write about to happen, not disk
  state) and matches a heading-anchored regex per required element,
  e.g. `id-nielsen-heuristics` requires a heading matching
  `/^#+\s*(nielsen|heuristic evaluation)/i` followed by ten distinct
  numbered sub-items before the next same-level heading, each with a
  non-blank verdict. This mirrors `id-proposal-shape`'s six-heading check
  and `id-citation-format`'s per-claim source-or-assumption-label check.
  Heading-only "stub" sections (heading present, body blank/whitespace)
  count as **absent**, matching this repo's `tests/stub-check.sh`
  convention for `directive.sh` itself. Each gate denies with a message
  naming exactly which of its own required elements is missing —
  distinct plugins never produce a shared, undifferentiated error.
- **`id-stage-order`** is the one cross-cutting plugin: it owns
  `docs/issue-<n>/reports/interaction-design/.status.json` (schema per
  survey/scout/proposal/approved/judgment, one entry per stage) and
  exposes nothing to the other nine plugins beyond that one file on
  disk — every other gate's stage-order check is "read `.status.json`,
  confirm the required earlier stage is `done`," a few self-contained
  lines duplicated per plugin rather than a shared library import,
  keeping each plugin genuinely self-contained (no plugin-to-plugin
  code dependency, only a shared on-disk contract, same relationship
  core's `record-fields-gate.sh` has to every role plugin that reads
  `RECORD_FIELDS_TERMINAL_STATES`).

## 5. Marketplace registration

`.claude-plugin/marketplace.json` (phase-2 edit) gains eleven new
entries alongside the existing `ux-design` entry — one per row in §3's
table, each with `name`, `source`, and a one-line `description` naming
the single methodology it owns (mirroring the existing `ux-design` entry
and how `tokenmaxxxer-core`'s marketplace lists `freelunch`/`scout` as
peers, not children, of `core`). No plugin's `description` may reference
another plugin's gate logic — only the shared `.status.json` contract
(§4) and, where relevant, `README.md`'s human-readable digest.

## 6. Gate tests

One test file per plugin (`tests/<plugin>-gate-tests.sh`, following this
repo's existing one-property-per-script convention —
`tests/parse-check.sh`, `tests/deny-only-check.sh`,
`tests/stub-check.sh`), each with at minimum:

- **True positive (reject):** the plugin's one required element missing
  → gate denies, message names that element.
- **True negative (allow):** the required element present and non-blank
  → gate allows.
- **Stub guard:** heading present, body blank/whitespace → gate denies
  (same failure mode `tests/stub-check.sh` already catches for
  `directive.sh`).
- **Independence guard:** a write that fails a *different* plugin's
  check but satisfies this plugin's own check → this plugin's gate
  allows (proves gates don't cross-contaminate; the write is still
  blocked overall by the other plugin, tested in that plugin's own
  suite).

`id-stage-order` additionally needs:

- **Ordering-violation:** write to a later-stage artifact while
  `.status.json` shows the required earlier stage not `done` → deny.
- **Ordering-satisfied:** same write once the earlier stage is `done` →
  allow (assuming the calling plugin's own content check also passes).
- **Self-update:** a successful write advances `.status.json`'s own
  stage to `done`, so the file can't drift from reality by hand-editing
  omission.

No single "run everything" test file is proposed — `tests/run-gate-tests.sh`
would just source each plugin's own test file, so a broken plugin's
tests fail attributably, not as one opaque suite failure.

## 7. Agents/checklists — scoped per plugin, not blanket

Only plugins whose methodology resists a pure regex/section check get an
agent/checklist component (§3: `id-persona-goal`, `id-nielsen-heuristics`
— judging "is this actually a Cooper-style persona" or "is this heuristic
verdict genuine, not rubber-stamped" needs a walked checklist, not just
section presence). The other eight plugins are fully mechanical
(presence/staging/format checks) and get no agent — adding one where a
script suffices would be the over-scoping issue-21 itself warns against.

## 8. What this proposal explicitly does not do

- Does not create any `hooks/*.sh`, `agents/*.md`, or `tests/*.sh` file
  for any of the eleven plugins named above.
- Does not create any `.claude-plugin/plugin.json` or add any entry to
  `.claude-plugin/marketplace.json`.
- Does not modify `ux-design/hooks/directive.sh`, `hooks.json`, or
  `README.md`.
- Does not copy any canon script content from core, `pricing-rulebook`,
  or `implementation-rulebook` — all references above are by path/
  description only; per survey.md §1/§5, those two sibling repos were
  not available to inspect directly in this checkout, so their exact
  shape is carried from the issue-21 body text, flagged as such.
- Does not approve itself. Per role-handoff contract v3 s19, this
  document is phase-1 output awaiting a human Approve before any
  phase-2 (plugin build) work begins.
