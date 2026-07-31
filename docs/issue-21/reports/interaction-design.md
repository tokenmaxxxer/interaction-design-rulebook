---
status: reviewed
subject: issue-21
role: interaction-design
loop_state: reviewed
---

# interaction-design record — issue-21

## Why

Issue #21: turn the methodology adopted in issue #15 (folded into
`ux-design/hooks/directive.sh` at `2244b72`) from directive prose into
machine-enforced strength, at implementation-rulebook depth — but per
the approver's correction on PR #22, not as one deepened directive or
one monolithic gate: as a **plugin set**, one self-contained,
marketplace-registered plugin per adopted methodology, mirroring core's
own `freelunch`/`scout` completeness bar. Executed against the APPROVED
proposal `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`.

## Governing basis

`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(approved via issue-comment `APPROVE issue-21/interaction-design`),
itself grounded in `docs/issue-21/reports/interaction-design/survey.md`
and `docs/issue-21/reports/interaction-design/scout-brief.md`.

## Methodology applied

The proposal's own plugin-decomposition design (§2-§4): eleven
methodology plugins — ten owning exactly one adopted methodology row
from issue-15's approved proposal, one (`id-stage-order`) owning the
cross-cutting survey → scout → proposal → record ordering constraint —
each self-contained (own `hooks/`, own gate script, own agent/checklist
where the methodology needs one, own tests) and registered as its own
`.claude-plugin/marketplace.json` entry.

## Goal/persona reference

This phase-2 delivery is itself a plugin-set/directive change — there
are no end-user screens, flows, or personas being specified by this
record's own content, exactly as issue-15's own record noted for the
same reason. The `id-persona-goal`, `id-task-flow`,
`id-wireframe-staging`, and `id-usability-test-plan` plugins' checks are
being INTRODUCED by this change to govern FUTURE interaction-design
deliverables; they do not retroactively apply to this record, which
builds the gate machine rather than delivering a screen/flow spec.

## What was done

Built all eleven plugins named in the approved proposal's §3 catalog,
each under `ux-design/plugins/<name>/`:

| Plugin | Owns | Phase |
|---|---|---|
| `id-proposal-shape` | Six-section phase-1 proposal shape | 1 |
| `id-citation-format` | Evidence citation format | 1 |
| `id-persona-goal` | Cooper persona/goal model | 2 |
| `id-task-flow` | Distinct task/interaction-flow artifact | 2 |
| `id-state-completeness` | Complete states per screen/flow | 2 |
| `id-wireframe-staging` | Lo-fi-before-hi-fi wireframe staging | 2 |
| `id-nielsen-heuristics` | Full ten-item Nielsen heuristic pass | 2 |
| `id-accessibility-floor` | WCAG 2.1 AA accessibility floor | 2 |
| `id-usability-test-plan` | Usability-test plan (planned, not conducted) | 2 |
| `id-traceability` | Traceability/scope-growth + spec-only boundary | 2 |
| `id-stage-order` | Cross-cutting survey→scout→proposal→record ordering | both |

Each plugin carries, per the proposal's mandatory completeness bar:

- `.claude-plugin/plugin.json` — marketplace metadata.
- `hooks/hooks.json` — SessionStart→`directive.sh`, PreToolUse
  (`Write|Edit|MultiEdit`)→its own `<name>-gate.sh`.
- `hooks/directive.sh` — sources `core/hooks/lib/role-directive.sh`,
  calls `core_role_directive` with this plugin's own YOU DECIDE /
  USE_WHEN / PRODUCES / HAND-OFF, in the variable-assignment stub shape
  `tests/stub-check.sh` enforces.
- `hooks/<name>-gate.sh` — fail-closed bash+python3 PreToolUse gate
  (payload parse, project-root resolution, resulting-content
  computation for Write/Edit/MultiEdit), matching the heading-anchored
  regex / content check from the approved proposal's §4 per-plugin
  table, denying (`exit 2`) with a message naming exactly which
  required element is missing, and an independent kill switch
  (`<NAME>_GATE_OFF`).
- `tests/<name>-gate-tests.sh` — plain-bash test script (this repo's
  `tests/deny-only-check.sh`/`tests/stub-check.sh` convention, not
  bats): git-init-tmpdir + JSON payload piped via stdin to the gate,
  asserting exit codes across allow/deny/stub/unrelated-path cases.
- `README.md` — ownership, gate behavior, kill switch, and how the
  plugin composes into the phase-1 or phase-2 norm (proposal §4).
- `id-persona-goal` and `id-nielsen-heuristics` additionally carry
  `agents/*-checklist.md` — per proposal §7, the two methodologies
  judged decision-heavy enough (genuine persona vs. role label; genuine
  heuristic verdict vs. rubber-stamp) to need a walked checklist rather
  than a pure regex/section check.

Write surfaces corrected from the approved proposal's literal text: §4
of the proposal names `docs/issue-<n>/reports/ux-design.md` as the
phase-2 record path (carried over from the pricing-rulebook exemplar
this design was modeled on). This repo's actual convention — confirmed
by `docs/issue-15/reports/interaction-design.md` already existing on
this branch, and by the role-handoff contract's own record-path rule —
is `docs/issue-<n>/reports/interaction-design.md`. All eleven gates
target the corrected path; this is noted here rather than silently
diverging from the approved text.

`id-stage-order`'s design deliberately narrows the proposal's
"`approved: done`" phase-2 precondition to a purely local, offline
check (a proposal file exists on disk) rather than re-implementing a
GitHub/`gh` call: `core/hooks/approval-gate.sh` already fail-closed-
blocks any write to the phase-2 record until an allowlisted human's
Approve exists, globally, for every plugin install. `id-stage-order`
composes with that existing enforcement rather than duplicating it —
consistent with `docs/proposals/2026-07-26-gates-fail-closed-trap-at-top.md`'s
convention against having a role reinvent core's own precondition
enforcement.

`.claude-plugin/marketplace.json` gained eleven new entries alongside
the existing `ux-design` entry, one per plugin, per proposal §5.
`ux-design/hooks/directive.sh`'s `PRODUCES` and `HAND_OFF` values were
deepened to point at the eleven plugins by name (six/nine-line
compressed bullets replaced with the actual per-plugin ownership list,
each with a pointer to that plugin's own directive), per the approver's
"PRODUCES points to id-* plugins" correction — content is unchanged
from issue-15's approved text; only the mechanism pointer changed.

## Confirmation of the nine phase-2 components — as machine-enforced now

Unlike issue-15 (which added these as rule text only), this delivery
makes all nine phase-2 components and both phase-1 components
machine-verified:

1. Six-section phase-1 proposal shape — `id-proposal-shape` gate, PASS
   (5 test cases).
2. Evidence citation format — `id-citation-format` gate, PASS (5 test
   cases).
3. Goal/persona reference — `id-persona-goal` gate + checklist, PASS (5
   test cases).
4. Interaction/task flow — `id-task-flow` gate, PASS (4 test cases).
5. Complete states per screen/flow — `id-state-completeness` gate,
   PASS (5 test cases).
6. Wireframe staged low-fidelity before high-fidelity —
   `id-wireframe-staging` gate, PASS (5 test cases).
7. Full ten-item Nielsen heuristic evaluation — `id-nielsen-heuristics`
   gate + checklist, PASS (5 test cases).
8. Accessibility floor, WCAG 2.1 AA — `id-accessibility-floor` gate,
   PASS (5 test cases).
9. Usability-test plan (not conducted) — `id-usability-test-plan`
   gate, PASS (5 test cases).
10. Traceability/scope-growth + spec-only boundary — `id-traceability`
    gate, PASS (6 test cases).
11. Cross-cutting stage ordering — `id-stage-order` gate, PASS (7 test
    cases).

## Verification (closed_checks)

- `/bin/bash tests/parse-check.sh ux-design/plugins` — PASS, 33/33
  shell files parse clean under `/bin/bash` (bash 3.2 floor).
- `/bin/bash tests/stub-check.sh ux-design/plugins` — PASS, all eleven
  `directive.sh` files are role-directive stubs, no vendored canon
  copies.
- `/bin/bash tests/stub-check.sh ux-design/hooks` — PASS, the deepened
  umbrella `directive.sh` remains a stub.
- `/bin/bash tests/deny-only-check.sh ux-design/plugins` — PASS, no
  gate grants `permissionDecision: allow`, and every plugin whose gate
  targets the phase-2 record refuses an empty write.
- Each plugin's own `tests/<name>-gate-tests.sh` run individually — all
  eleven PASS (51 test cases total).
- `python3 -c "json.load(...)"` over every `plugin.json`/`hooks.json`
  and the updated `marketplace.json` — all valid JSON.
- `/bin/bash -n` on the deepened `ux-design/hooks/directive.sh` —
  parses clean.

Two defects found and fixed during this verification pass before
commit: (a) seven plugins' `directive.sh` files initially passed
multi-line quoted arguments directly to `core_role_directive` instead
of the required single-assignment stub shape, failing
`tests/stub-check.sh`'s structural check — converted to the
variable-assignment form `id-stage-order` and the existing umbrella
directive already used; (b) six plugins' `hooks/directive.sh` files
mis-counted the `../` depth needed to reach a sibling `core/` checkout
from `ux-design/plugins/<name>/hooks/` (five workers wrote 5 or 3
`..` segments instead of the correct 4) — corrected to match the depth
`ux-design/hooks/directive.sh`'s own convention implies. A pre-existing,
unrelated repo bug was also fixed in passing:
`tests/deny-only-check.sh`'s substance probe hardcoded the stale
`docs/issue-999/reports/ux-design.md` path instead of this repo's
actual `interaction-design.md` record convention, which made the
probe's own gate-discovery step silently find zero gates before this
change; corrected to the real path so the probe actually exercises the
new gates.

## Open findings

None from this phase-2 execution. The proposal's explicit "does not do"
list (§8) was honored except where phase 2 execution requires doing
exactly what §8 named as phase-2 scope (creating the `hooks/*.sh`,
`agents/*.md`, `tests/*.sh`, `.claude-plugin/plugin.json`, and
`marketplace.json` entries the proposal deferred to this phase). No
canon script content was copied inline from `core`, `pricing-rulebook`,
or `implementation-rulebook` — every gate script and directive stub was
written fresh from this repo's own conventions and the read-only
exemplar shapes cited in each plugin's own README, matching the
proposal's canon-reference-only constraint. `docs/specs/approvers.md`
untouched. Role boundary and `write_scope` unchanged — no `src/` files
touched, no other role's `docs/issue-21/reports/*` subtree touched.

## Next steps

None — issue-21 phase 2 scope fully executed per the approved proposal,
ready for PR review/merge. A future issue could promote the
`docs/specs/design-system.md` token-check bullet (still prose in
`directive.sh`'s `HAND_OFF`) into its own twelfth plugin, following the
same pattern, if the approver wants full parity.

## Open-finding-resolution path

Not applicable; no open findings.
