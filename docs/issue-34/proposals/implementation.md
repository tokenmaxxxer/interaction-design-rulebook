---
status: proposed
files:
  - README.md
  - interaction-design/hooks/directive.sh
  - interaction-design/plugins/id-state-completeness/hooks/directive.sh
  - interaction-design/plugins/id-state-completeness/hooks/state-completeness-gate.sh
  - interaction-design/plugins/id-state-completeness/tests/id-state-completeness-gate-tests.sh
  - interaction-design/plugins/id-task-flow/hooks/directive.sh
  - interaction-design/plugins/id-task-flow/hooks/task-flow-gate.sh
  - interaction-design/plugins/id-task-flow/tests/id-task-flow-gate-tests.sh
  - interaction-design/plugins/id-wireframe-staging/hooks/directive.sh
  - interaction-design/plugins/id-wireframe-staging/hooks/wireframe-staging-gate.sh
  - interaction-design/plugins/id-wireframe-staging/tests/id-wireframe-staging-gate-tests.sh
  - interaction-design/plugins/id-traceability/hooks/directive.sh
  - interaction-design/plugins/id-traceability/hooks/traceability-gate.sh
  - interaction-design/plugins/id-traceability/tests/id-traceability-gate-tests.sh
---

# Proposal — align rulebook with realized `interaction-design.spec.json` (issue-34)

## Request
Layer the realized marketplace spec's seven required deliverable-field
names (`state_name`, `entry_trigger`, `screen_ref`, `node_type`,
`feedback`, `transitions`, `edge_case_variant`) and its four-value
`loop_state` vocabulary (`sketching`, `reviewed`,
`spec-not-confirmed`, `screen-ref-unresolvable`) onto this rulebook's
existing methodology docs and gates, strengthening what already exists
rather than deleting any methodology.

## Constraints
- Never delete existing methodology (Nielsen heuristics, accessibility
  floor, usability-test plan, persona/goal, etc. all stay untouched —
  none of those plugins map to a spec field, so none are in the write
  set).
- Every spec required-field name must appear verbatim, findable by
  `grep -ri <field> docs/ README.md`, after phase 2.
- The rulebook's loop_state vocabulary must match the spec set exactly
  — no stale or extra states left named as this role's vocabulary.
- All eleven plugins stay independently kill-switchable and
  self-contained (existing gate-house convention); no plugin merges
  with another.
- Any spec field with no natural home must be stated as such, with
  reasoning — not silently dropped (issue-34's explicit "empty state"
  acceptance line). Per the survey, all seven fields DO have a natural
  home in an existing plugin, so this clause resolves to "not
  applicable, all seven map" rather than needing an empty-state
  paragraph — that finding itself is recorded here per the clause's
  spirit.

## Rationale
Two live alternatives, both rejected:

1. **New twelfth plugin (`id-spec-fields`) owning all seven spec
   fields.** Rejected: the survey found each field already has a
   closer conceptual home in an existing plugin's gate (state
   completeness already owns per-screen state enumeration;
   task-flow already owns flow sequencing; wireframe-staging already
   owns the screen/wireframe pointer; traceability already owns
   per-element justification). A new plugin would duplicate what
   those gates already parse (heading detection, per-entry block
   splitting) instead of reusing it, and would leave the existing
   plugins' prose still speaking a different vocabulary than the
   spec — the exact "strengthen, don't fork" failure this issue is
   trying to close.
2. **Replace `id-state-completeness`'s default/empty/error/loading
   state-word check with the spec's node_type/edge_case_variant
   vocabulary wholesale.** Rejected: issue-34 explicitly says
   "strengthening existing content, never deleting methodology" — the
   four-state-word check (from issue-21's approved design) is NN/g's
   own must-be (where am I / what can I do / how do I go back / what
   happens when it fails) and stays load-bearing for usability
   independent of the spec. The spec's fields get added as additional
   required vocabulary on top of the four state words, not a
   replacement of them.

Chosen approach: extend the four already-closest phase-2 plugins'
directives and gates to also require the spec's literal field names,
and extend `README.md` / the role directive with the loop_state
vocabulary as an explicit mapping onto the existing `reviewed`
terminal state plus three new named states.

## What will be done
- **`id-state-completeness`** (state_name, node_type, transitions,
  edge_case_variant): gate additionally requires, per screen/flow
  entry, an explicit `state_name:` label, a `node_type:` value from
  {state, choice, terminal}, a `transitions:` list, and an
  `edge_case_variant:` value (the existing "error" state-word
  requirement stays, `edge_case_variant` is the spec's more specific
  name for populating it). Add reference-resolution and
  >=1-terminal-node checks per the spec's `reference_resolution` rule
  (every `transitions` entry must resolve to another `state_name` in
  the same record; the flow must contain at least one `terminal`
  node_type) — this is new mechanical coverage the spec adds that the
  rulebook did not have. Directive prose updated to name all four
  fields explicitly.
- **`id-task-flow`** (entry_trigger): gate additionally requires each
  task-flow/interaction-flow entry to name an `entry_trigger:` value.
  Directive prose updated.
- **`id-wireframe-staging`** (screen_ref): gate additionally requires
  each wireframe entry to carry a `screen_ref:` pointer tying it to a
  state_name. Directive prose updated.
- **`id-traceability`** (feedback): gate additionally requires each
  traced element/state to name a `feedback:` value (what the system
  tells the user). Directive prose updated.
- **`README.md`** and **`interaction-design/hooks/directive.sh`**:
  document the loop_state vocabulary mapping — `sketching` as the
  named phase-2 in-progress state (used before the record reaches
  `reviewed`), `spec-not-confirmed` as a refusal state (record is not
  yet governed-record-traced), `screen-ref-unresolvable` as an error
  state (a `screen_ref` or `transitions` entry that fails reference
  resolution), and `reviewed` confirmed as the unchanged terminal
  state. No new terminal-state plumbing is needed: `reviewed` is
  already this role's terminal state today via the existing
  `RECORD_FIELDS_TERMINAL_STATES` env var mechanism documented in
  `README.md` (a consuming project sets it in its own
  `.claude/settings.json`, since a hook entry has no `env` field to
  carry it) — core's own default is `landed`, not `reviewed`, and this
  rulebook already carries that caveat explicitly. Issue-34 does not
  change or newly depend on this; it only adds `sketching` /
  `spec-not-confirmed` / `screen-ref-unresolvable` as documented
  non-terminal vocabulary alongside the unchanged `reviewed`.
- Each touched plugin's `tests/*-gate-tests.sh` gets new test cases for
  the added field checks (pass and fail cases), following that
  plugin's existing test-file convention.

## Out of scope
- `id-persona-goal`, `id-nielsen-heuristics`, `id-accessibility-floor`,
  `id-usability-test-plan`, `id-proposal-shape`, `id-citation-format`,
  `id-stage-order` — none map to a spec field or loop_state value;
  untouched.
- The `recomputation` rule's `checked_by: TBD` follow-up (per-role
  recomputation enforcement) — the spec itself marks this
  out-of-scope pending real-usage evidence (issue-521 note); not
  built here.
- `write_scope: []` / `report_only: true` in the spec — these describe
  the marketplace/on-the-record side's enforcement scope, not a
  rulebook doc/hook to write.
- Any change to `core`, `scout`, `warrant`, `freelunch`, or `terse`
  plugins — this issue is rulebook-local per its own text ("this
  rulebook's vocabulary and rules").

## How you'll know it worked
- `grep -ri 'state_name\|entry_trigger\|screen_ref\|node_type\|feedback\|transitions\|edge_case_variant' docs/ README.md` returns a hit for every one of the seven field names.
- `grep -ri 'sketching\|reviewed\|spec-not-confirmed\|screen-ref-unresolvable' docs/ README.md interaction-design/` returns a hit for all four loop_state values, and no other loop_state word is introduced as this role's vocabulary.
- `tests/*.sh` (repo-level) and each plugin's own `tests/*-gate-tests.sh` pass; `pytest` is not applicable to this repo (bash/gate-lib.py test harness only) — stated per issue-34's "else state `unverifiable`" acceptance clause if no pytest suite exists.
