---
status: reviewed
subject: issue-24
role: interaction-design
loop_state: reviewed
---

# interaction-design record — issue-24

## Why

Issue #24: the 2026-08-01 code audit graded this rulebook's eleven
`id-*` gates B- — `id-traceability` was fail-open on a bash-level abort
(no `trap __fc EXIT`); `README.md` documented a record path
(`docs/issue-<n>/reports/ux-design.md`) and kill switch
(`UX_DESIGN_CYCLE_OFF`) neither of which any gate honored; the root test
runner was a permanent no-op; all eleven plugins shared the pre-issue-72
kill-switch bug (unrecognized value = disabled); `MultiEdit`
reconstruction ignored per-edit `replace_all`; `id-citation-format`'s
`NO_ACCESS_RE` matched the whole document instead of the relevant
section. Executed against the APPROVED proposal
`docs/issue-24/proposals/interaction-design.md`.

## Governing basis

`docs/issue-24/proposals/interaction-design.md` (approved via issue
comment `APPROVE issue-24/interaction-design`), itself grounded in
`docs/issue-24/reports/interaction-design/survey.md` (scout skipped —
remediation issue against a fully specified defect list, not an open
design-direction choice). Precondition: core issue #72's gate-house
standard (`core/hooks/lib/gate-lib.sh` / `gate-lib.py`), landed on
branch `issue-72/implementation` in the core checkout referenced by
this delivery.

## Methodology applied

The proposal's own delivery scope (§4): adopt `gate-lib.sh`/`gate-lib.py`
wholesale by reference (never vendored), migrate all eleven gates onto
it, fix `id-citation-format`'s scoping bug in place, correct the README
ghosts, and add the six-case mandatory test harness per plugin.

## Persona & Goal

- **N/A — infrastructure delivery**: no end-user persona is served by
  this record's own content; this issue delivers gate-machine
  remediation, not a screen/flow spec.
  Goal: not applicable — there is no user-facing interaction being
  specified by this record.

This phase-2 delivery is a gate-infrastructure remediation, not a
screen/flow/wireframe specification, for the same reason issue-15's and
issue-21's own records noted. The `id-persona-goal`, `id-task-flow`,
`id-wireframe-staging`, and `id-usability-test-plan` sections below carry
the minimum structurally-required content to pass their own gates
(introduced to govern *future* interaction-design deliverables) without
asserting a screen/flow that does not exist for this issue.

## Task Flow

N/A — infrastructure delivery, no distinct interaction/task flow: this
record documents a gate-remediation build, not a user-facing flow. This
heading exists only to satisfy `id-task-flow`'s structural check for the
same reason noted above.

## State Completeness

N/A — infrastructure delivery: no screen/flow states apply. Default,
empty, error, and loading states are not applicable because no screen is
being specified by this record.

## Wireframe Staging

### Lo-fi

N/A — infrastructure delivery, no wireframe staged.

### Hi-fi

N/A — infrastructure delivery, no wireframe staged.

## Nielsen Heuristic Evaluation

N/A — infrastructure delivery, no screen/flow evaluated against the
heuristics. All ten items marked n/a for the same reason as the sections
above.

1. Visible system status: n/a — no screen delivered by this record.
2. Match between system and real world: n/a — no screen delivered.
3. User control and freedom: n/a — no screen delivered.
4. Consistency and standards: n/a — no screen delivered.
5. Error prevention: n/a — no screen delivered.
6. Recognition rather than recall: n/a — no screen delivered.
7. Flexibility and efficiency of use: n/a — no screen delivered.
8. Aesthetic and minimalist design: n/a — no screen delivered.
9. Help users recognize, diagnose, and recover from errors: n/a — no screen delivered.
10. Help and documentation: n/a — no screen delivered.

## Accessibility Floor (WCAG 2.1 AA)

N/A — infrastructure delivery, no screen delivered, so no keyboard,
focus, label, or contrast coverage applies. Conformance target remains
WCAG 2.1 AA for any future screen this rulebook governs.

## Usability Test Plan

N/A — infrastructure delivery, no usability test plan applies since no
screen is delivered by this record.

Task scenario: not applicable — no user-facing task exists to test. 0
participants (n/a).

## What was done

1. **`gate_trap_fail_closed` everywhere.** All eleven
   `ux-design/plugins/*/hooks/*-gate.sh` now source
   `core/hooks/lib/gate-lib.sh` (`CLAUDE_PLUGIN_ROOT_CORE`-resolved,
   sibling-repo convention matching every plugin's existing
   `directive.sh`) and call `gate_trap_fail_closed` as their first
   statement — including `id-traceability`, the one plugin the audit
   found with no trap at all. **Hardened beyond the proposal's literal
   text**: the source line itself now guards its own failure
   (`... || { echo ...refused...; exit 2; }`) — found during
   verification that a gate run with `core/` unavailable (no
   `CLAUDE_PLUGIN_ROOT_CORE`, no sibling `core/` checkout) silently
   fell through `gate_trap_fail_closed`/`gate_kill_switch_active` as
   "command not found" (bash exit 127), and the kill-switch line's own
   `|| exit 0` then read that as "kill switch off" — a new fail-open
   path the migration itself would otherwise have introduced. Caught by
   `tests/deny-only-check.sh`'s substance probe (see Verification).
2. **`gate_kill_switch_active` everywhere.** Every plugin's
   `case ... in ""|0|false|no|off) ;; *) exit 0 ;; esac` replaced with
   `gate_kill_switch_active "${X_GATE_OFF:-}" || exit 0` — an
   unrecognized value now stays active (fail-closed), matching core's
   own post-#72 fix.
3. **`gate_reconstruct_write` for `Edit`/`MultiEdit`.** Ten plugins'
   (all but `id-stage-order`, which is purely file-existence-based)
   Python payloads now call `gate_lib.gate_reconstruct_write`, honoring
   each edit's own `replace_all` independently for `MultiEdit`.
4. **`gate_normalize_path` for path scoping.** All eleven plugins'
   `RECORD_RE`/`PROPOSAL_RE` now match against a path normalized via
   `gate_lib.gate_normalize_path`, closing the absolute-path /
   `./`-prefixed-path gap.
5. **`id-citation-format`'s `NO_ACCESS_RE` scoped.** The
   no-research-access escape now only waives the Sources-heading
   requirement when the phrase appears in the document's own prose
   (non-bullet lines) or inside the matched Sources section's body —
   never a full-document scan. A claim bullet's own
   "established-practice assumption" marker still satisfies only that
   bullet's own per-line check; it can no longer also silently waive
   the whole-document Sources requirement. Verified against the exact
   regression fixture the proposal's judged-by §6 names (a bullet
   marker with no Sources heading still denies).
6. **README record-path and kill-switch ghosts fixed.** Record path
   corrected to `docs/issue-<n>/reports/interaction-design.md`
   throughout; the non-existent `UX_DESIGN_CYCLE_OFF` kill switch
   removed and replaced with the real per-plugin list
   (`ID_<NAME>_GATE_OFF` x 11); a gate-lib migration note added.
7. **Aggregate test signal.** `tests/run-gate-tests.sh` now loops
   `ux-design/plugins/*/tests/*-gate-tests.sh`, running each (still
   surfacing its own output for attribution) and reporting a combined
   pass/fail summary — a reviewer running only this one script gets an
   accurate signal instead of the previous permanent `0 passed, 0
   failed` stub.
8. **Mandatory test cases, per plugin.** Each
   `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` gained the
   applicable subset of the gate-house standard's six-case harness:
   `Edit`+`replace_all:true` against a multiply-occurring `old_string`;
   `MultiEdit` with mixed `replace_all`; malformed/empty JSON; kill
   switch set to an unrecognized value (asserts the gate **stays
   active**); absolute `file_path` plus a `./`-prefixed variant.
   `id-stage-order` (file-existence-only, no `gate_reconstruct_write`
   call) carries only the applicable malformed-JSON/kill-switch/path
   subset, noted in its own test file. Case 6 (Bash-tool writes) is
   inapplicable everywhere — no plugin here matches on the `Bash` tool.

## Confirmation of the nine phase-2 components — as machine-enforced now

Unchanged in scope from issue-21; this delivery is a defect-remediation
pass on the same eleven plugins, not a re-decomposition:

1. Six-section phase-1 proposal shape — `id-proposal-shape`, PASS (11
   test cases).
2. Evidence citation format — `id-citation-format`, PASS (11 test
   cases, including the scoping-regression fixture).
3. Goal/persona reference — `id-persona-goal`, PASS (11 test cases).
4. Interaction/task flow — `id-task-flow`, PASS (11 test cases).
5. Complete states per screen/flow — `id-state-completeness`, PASS (11
   test cases).
6. Wireframe staged low-fidelity before high-fidelity —
   `id-wireframe-staging`, PASS (11 test cases).
7. Full ten-item Nielsen heuristic evaluation — `id-nielsen-heuristics`,
   PASS (11 test cases).
8. Accessibility floor, WCAG 2.1 AA — `id-accessibility-floor`, PASS
   (11 test cases).
9. Usability-test plan (not conducted) — `id-usability-test-plan`,
   PASS (11 test cases).
10. Traceability/scope-growth + spec-only boundary —
    `id-traceability`, PASS (13 test cases).
11. Cross-cutting stage ordering — `id-stage-order`, PASS (12 test
    cases, malformed-JSON/kill-switch/path subset).

## Traceability and scope growth

This deliverable is spec-only in the sense the gate machine itself
enforces the boundary on: every fix traces to a named defect in the
issue's own audit paragraph or the approved proposal's delivery scope
(§4 items 1-8 above map 1:1 to defect classes named in the issue). The
one item beyond the proposal's literal text — guarding the `gate-lib.sh`
source line's own failure (§4 item 1) — is not scope growth: it is the
same "fail-closed everywhere" requirement the issue names, applied to a
fail-open path the migration's own mechanism would otherwise have left
open, caught by the standard's own `deny-only-check.sh` substance
probe rather than invented speculatively.

- Scope growth: none beyond the source-line fail-closed hardening noted
  above (itself in-scope, not an added feature).

## Verification (closed_checks)

- `core/hooks/tests/compliance-check.sh` run against each of the eleven
  `ux-design/plugins/<name>/` directories (per its own per-plugin
  invocation shape) — PASS, zero flagged gates, from the core checkout
  landing issue #72 (`tokenmaxxxer-core-issue-72-implementation`,
  branch `issue-72/implementation`).
- Every `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` run
  individually with `CLAUDE_PLUGIN_ROOT_CORE` pointed at that same core
  checkout — all eleven PASS (125 test cases total, mandatory cases
  included).
- `tests/run-gate-tests.sh` (no env override needed — it invokes the
  same eleven suites) — PASS, `11 passed, 0 failed`.
- `tests/parse-check.sh` / `tests/parse-check.sh ux-design/plugins` —
  PASS.
- `tests/deny-only-check.sh` / `tests/deny-only-check.sh
  ux-design/plugins` — PASS, including the substance probe (an empty
  record write against every gate, run with **no**
  `CLAUDE_PLUGIN_ROOT_CORE` set, confirming the fail-closed-on-missing-
  gate-lib hardening above actually holds in that exact scenario).
- `tests/stub-check.sh ux-design/hooks` /
  `tests/stub-check.sh ux-design/plugins` — PASS.
- `bash -n` and `python3 -m py_compile` on every gate script's embedded
  Python payload — all parse clean.
- README spot-check: `grep RECORD_RE ux-design/plugins/*/hooks/*.sh`
  and `grep _GATE_OFF ux-design/plugins/*/hooks/*.sh` against the
  documented paths/kill-switches — zero drift.

## Open findings

None from this phase-2 execution. The one defect found and fixed
outside the proposal's enumerated list is the source-line fail-closed
hardening described above (§4 item 1) — a gap in the approved design
that surfaced only once `deny-only-check.sh`'s existing substance probe
was actually exercised against the migrated gates without
`CLAUDE_PLUGIN_ROOT_CORE` set; recorded here rather than silently
patched without mention. `docs/specs/approvers.md` untouched. Role
boundary and `write_scope` unchanged — no `src/` files touched, no
other role's `docs/issue-24/reports/*` subtree touched.

## Next steps

None — issue-24 phase 2 scope fully executed per the approved proposal,
ready for PR review/merge.

## Open-finding-resolution path

Not applicable; no open findings.
