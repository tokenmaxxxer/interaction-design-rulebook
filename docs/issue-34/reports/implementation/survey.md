---
subject: issue-34
role: implementation
---

# Survey — align rulebook with realized `interaction-design.spec.json` (issue-34)

Scout skip: issue-34's design decision (how to map seven fixed spec
field names and a fixed four-value loop_state vocabulary onto existing
rulebook concepts) is fully closed by the spec file itself — there is
no external exemplar space to research; the mapping is an internal
reconciliation between one JSON file and this repo's existing plugin
set. Per scout-directive's two skip conditions, "the spec leaves no
design decision open" applies to the field-naming half of this issue.
Scouting is not run; this line is the mandatory skip record.

## Spec source
`~/.claude/plugins/marketplaces/tokenmaxxxer/roles/specs/interaction-design.spec.json`
(not present in this repo — it lives in the marketplace/on-the-record
side, this rulebook only reacts to it).

Required fields: `state_name`, `entry_trigger`, `screen_ref`,
`node_type` (enum: state/choice/terminal), `feedback`, `transitions`
(ref[]), `edge_case_variant`.
`reference_resolution`: every `transitions` entry must resolve to
another state's `state_name` in the same record; every flow needs >=1
terminal `node_type`.
`recomputation`: a flow isn't complete until every state's
`edge_case_variant` is populated (error-state-before-happy-path-only).
`loop_state`: progress=[sketching], terminal=[reviewed],
refusal=[spec-not-confirmed], error=[screen-ref-unresolvable].

## Current rulebook state (write surfaces this issue touches)

- `README.md` — role description, plugin list, norms prose. No
  `state_name`/`entry_trigger`/`node_type`/`transitions`/
  `edge_case_variant`/`screen_ref` vocabulary present (grep confirms
  zero hits for all seven field names as of this survey).
- `interaction-design/hooks/directive.sh` — role-wide SessionStart
  directive (YOU_DECIDE/USE_WHEN/PRODUCES/HAND_OFF). Currently speaks
  of "screens/flows", "states section", "task flow artifact" —
  conceptually adjacent but not field-name-matched to the spec.
- `interaction-design/plugins/id-state-completeness/` — closest
  existing home for `state_name`/`node_type`/`edge_case_variant`/
  `transitions`. Its gate (`state-completeness-gate.sh`) currently
  enforces four *state* words (default/empty/error/loading) per
  screen/flow entry under a "states" heading — this is NN/g-flavored
  state coverage, not UML node-type/transition-reference notation. The
  spec's `edge_case_variant` maps onto this plugin's "error" state
  requirement but under a different field name; `node_type` (enum
  state/choice/terminal) and `transitions` (ref[] with reference
  resolution to `state_name`) have no current mechanical check here at
  all — the gate checks state words appear, never that named states
  form a resolvable graph or that a terminal node exists.
- `interaction-design/plugins/id-task-flow/` — closest home for
  `entry_trigger`/`transitions` as a flow-sequencing concept: currently
  only checks a "task flow"/"interaction flow" heading exists with
  non-blank body, distinct from any wireframe heading. No entry-trigger
  or transition-reference vocabulary.
- `interaction-design/plugins/id-wireframe-staging/` — closest home for
  `screen_ref`: wireframes today are lo-fi/hi-fi staged structural
  representations per screen but the record has no defined `screen_ref`
  field connecting a state to a specific wireframe artifact.
- `interaction-design/plugins/id-traceability/` — closest home for
  `feedback`: currently traces screen *elements* to the governing
  record's problem/metric; does not require a `feedback` field (what
  the system tells the user in response to an action) per state.
- `README.md` already documents (lines ~130-136) that core's own
  default terminal-state is `landed`, not `reviewed`, and that this
  role's `reviewed` terminal state only takes effect because a
  consuming project sets `RECORD_FIELDS_TERMINAL_STATES=reviewed` in
  its own `.claude/settings.json` (a hook entry has no `env` field to
  carry it from this rulebook itself). This is pre-existing,
  already-documented behavior unrelated to issue-34 — no new terminal-
  state plumbing is needed here, and issue-34 must not claim the
  match is automatic. Core's default table has no entries for a
  `refusal` state (`spec-not-confirmed`) or an `error` state
  (`screen-ref-unresolvable`) that this role does not currently
  recognize at all — those two words appear nowhere in the rulebook
  today (grep confirms zero hits).
- `sketching` (progress state) also appears nowhere in the rulebook
  today; the closest existing progress-shaped vocabulary is
  `loop_state: reviewed` as the sole state named in role docs, with no
  named in-progress state at all — phase-2 work implicitly starts
  "unreviewed" with no word for it.

## Grep evidence (field/vocabulary presence, pre-change)
```
grep -ril 'state_name\|entry_trigger\|screen_ref\|node_type\|edge_case_variant' docs/ README.md interaction-design/  -> (no hits)
grep -ril 'sketching\|screen-ref-unresolvable\|spec-not-confirmed' docs/ README.md interaction-design/  -> (no hits)
grep -ril 'reviewed' README.md  -> README.md (already present, role's terminal state)
```

## Conclusion driving the proposal
No plugin needs deleting or replacing — issue-34 explicitly requires
"strengthening existing content, never deleting methodology." The
seven required fields distribute across the four existing phase-2
plugins that already own the adjacent concept (`id-state-completeness`
for state_name/node_type/transitions/edge_case_variant,
`id-task-flow` for entry_trigger, `id-wireframe-staging` for
screen_ref, `id-traceability` for feedback), each gate strengthened to
also require the spec's literal field name/word, not just its prose
concept. `directive.sh` and `README.md` get the loop_state vocabulary
layered on top of (not replacing) the existing `reviewed` terminal
state.
