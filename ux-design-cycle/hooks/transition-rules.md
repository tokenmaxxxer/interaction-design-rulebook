# ux-design-cycle transition rules

Single source of truth for legal `ux-design/state.md` (`stage` field)
transitions. Read by both `inject-transition-rules.sh` (UserPromptSubmit)
and `state-gate.sh` (PreToolUse). The state set mirrors the
`ux-design-record`'s `loop_state` vocabulary fixed by
`docs/specs/role-handoff-contract.md` §2: `idle`, `drafting`, `reviewed`.

`actor` is `user` when the transition requires the user to have said
something in this conversation authorizing it; `agent` when the agent may
make the transition on its own recognizance (still recorded, never
user-gated).

| from | to | actor | precondition |
|---|---|---|---|
| (none) | idle | agent | ux-design/state.md does not yet exist; the agent creates it with stage `idle` as the initial state |
| idle | drafting | agent | ux-design has woken per contract §3 (a new/changed `product-record`, or a chain-root `hypothesis`, appeared on the board) and begun drafting screen/flow/wireframe specs for the subject |
| drafting | drafting | agent | the design draft is being revised; the `ux-design-record`'s pointer to its governing `hypothesis`/`product-record` remains non-empty throughout (state-gate.sh's owned-path check enforces this on every write to the record itself, independently of this state file) |
| drafting | reviewed | user | user has reviewed the draft in this conversation and affirmed it is ready to feed coding — a vague affirmation ("looks fine") is not sufficient; the model re-asks for what was specifically reviewed |
| reviewed | drafting | user | user (or a downstream `finding` addressed to ux-design) sends the design back for rework |

Two `actor: user` rows.
