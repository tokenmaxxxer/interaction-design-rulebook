---
status: reviewed
subject: issue-27
role: interaction-design
loop_state: reviewed
---

# interaction-design record — issue-27

## Why

Issue #27: the 2026-08-01 re-audit graded this rulebook A- and named
four residual defect classes on top of the already-closed issue-24
remediation: (1) no plugin's `hooks.json` matcher or gate code handled
the `Bash` tool, reversing what core PR #75's landed
`gate_bash_write_targets.py` + mandatory missing-core tests now require;
(2) `.claude-plugin/marketplace.json` and
`ux-design/.claude-plugin/plugin.json` still carried the pre-rename
`ux-design` role name at the umbrella-plugin level; (3)
`tests/run-gate-tests.sh` had no guard against a zero-suite glob match
silently reporting a false green; (4) `hooks.json` matcher vs. gate code
tool coverage needed re-verification, including after the Bash fix
landed. Executed against the APPROVED proposal
`docs/issue-27/proposals/interaction-design.md`.

## Governing basis

`docs/issue-27/proposals/interaction-design.md` (approved via issue
comment `APPROVE issue-27/interaction-design`), itself grounded in
`docs/issue-27/reports/interaction-design/survey.md` (scout skipped —
remediation issue against a fully specified defect list, not an open
design-direction choice). Precondition: core PR #75
(`gate_bash_write_targets.py`, mandatory missing-core tests) and
on-the-record #182 (`CLAUDE_PLUGIN_ROOT_CORE` injection in `spawn.py`),
named by the issue body as already landed upstream.

## Methodology applied

The proposal's own delivery scope (§4, six items): extend each plugin's
`hooks.json` matcher and gate-code tool tuple to include `Bash`, reusing
core's `gate_bash_write_targets` by reference to extract a Bash-written
candidate path and re-check it against each plugin's own existing
`RECORD_RE`/`PROPOSAL_RE` scope, letting the already-existing
"unreconstructable write -> deny" branch cover Bash writes without new
gate logic; rename the umbrella manifest/plugin.json entries off
`ux-design`; clean the README's stale prose and phantom-path labeling;
add the runner's 0-suite guard; add one missing-core mandatory test case
per plugin; keep matcher/code alignment verified in the same commit as
the Bash change.

## Persona & Goal

- **N/A — infrastructure delivery**: no end-user persona is served by
  this record's own content; this issue delivers gate-machine
  remediation, not a screen/flow spec.
  Goal: not applicable — there is no user-facing interaction being
  specified by this record.

This phase-2 delivery is a gate-infrastructure remediation, not a
screen/flow/wireframe specification, for the same reason issue-15's,
issue-21's, and issue-24's own records noted. The `id-persona-goal`,
`id-task-flow`, `id-wireframe-staging`, and `id-usability-test-plan`
sections below carry the minimum structurally-required content to pass
their own gates without asserting a screen/flow that does not exist for
this issue.

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

1. **Bash write-case + matcher addition, all eleven plugins.** Each
   `ux-design/plugins/<name>/hooks/hooks.json` matcher extended from
   `"Write|Edit|MultiEdit"` to `"Write|Edit|MultiEdit|Bash"`. Each
   `ux-design/plugins/<name>/hooks/<name>-gate.sh`'s path-extraction
   block gained an `elif tool == "Bash":` branch that reads
   `tool_input["command"]`, tokenizes it with the same
   `[A-Za-z0-9_./~$-]+` pattern `gate_bash_write_targets` (core) uses,
   normalizes each token via `gate_lib.gate_normalize_path`, and checks
   it against the plugin's own existing `RECORD_RE`/`PROPOSAL_RE` (both,
   for `id-stage-order`). No new content-verification logic was added:
   a matched Bash-written path falls into the same
   `gate_reconstruct_write(tool, ti, current)` call already used for
   `Write`/`Edit`/`MultiEdit` — since `gate_reconstruct_write` returns
   `(None, False)` for any tool other than `Write`/`Edit`/`MultiEdit`,
   a Bash write to the record/proposal surface reaches the existing
   "cannot determine resulting content" deny branch unchanged, closing
   the coverage gap without granting Bash a new first-class authoring
   path (proposal's adopt/skip: narrow path-extraction-and-scope-check
   only).
2. **Manifest stale-name fix.** `.claude-plugin/marketplace.json:2`
   renamed `"tokenmaxxxer-ux-design"` -> `"tokenmaxxxer-interaction-design"`;
   `:8`'s umbrella plugin entry renamed `"ux-design"` ->
   `"interaction-design"` (source path `./ux-design` unchanged, per the
   proposal's conservative-rename boundary); `:10`'s description prose
   updated. `ux-design/.claude-plugin/plugin.json:2-3` renamed and
   updated the same way. All eleven `id-*` sub-plugin manifests were
   already correct and untouched.
3. **README stale-name and phantom-path cleanup.** `README.md`'s title,
   role-name prose (lines 1, 3-4, 13, 16, 20, 43, 100), and install
   command (`claude plugin install
   interaction-design@tokenmaxxxer-interaction-design`) corrected to
   `interaction-design`/`tokenmaxxxer-interaction-design`.
   `docs/handbooks/gate-house-standard.md`'s reference (README.md:63-64)
   relabeled to explicitly read "(in `core`)" rather than removed — the
   survey found it most plausibly a legitimate core-repo cross-reference,
   not a ghost. Directory-path references (`ux-design/...`, `./ux-design`
   as marketplace source, the `compliance-check.sh ux-design` invocation
   arg) are left unchanged, since the `ux-design/` directory itself is
   out of scope for this conservative rename.
4. **`tests/run-gate-tests.sh` 0-suite guard.** After the aggregation
   loop, `[ "$total" -gt 0 ] || { echo "refused: zero plugin test suites
   found under ux-design/plugins/*/tests/ — glob mismatch or missing
   directory" >&2; exit 2; }` added before the `passed`/`failed`
   summary — a zero-suite run now fails closed (exit 2) instead of
   printing a false-green `0 passed, 0 failed` (exit 0). Verified with a
   throwaway copy of the runner pointed at an empty `ux-design/plugins/`
   tree: exits 2 with the refusal message.
5. **Missing-core mandatory test, all eleven plugins.** Each
   `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` gained one case
   in its mandatory-cases block that runs the gate with
   `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path (env override
   wins over the sibling-`core/`-lookup default, so no sibling checkout
   needs to be absent for the case to be meaningful) and asserts exit 2
   — exercising the fail-closed source-line branch every gate script
   already has but that no test previously reached.
6. **`hooks.json`/gate-code tool-coverage kept green.** Item 1's matcher
   edit and gate-code edit were delivered together, per plugin, in this
   same pass — verified post-fix (see Verification) that all eleven
   matcher tool-sets and gate-code tool-sets agree exactly, zero
   set-difference either direction.

## Confirmation of the nine phase-2 components — as machine-enforced now

Unchanged in scope from issue-21/issue-24; this delivery is a
defect-remediation pass on the same eleven plugins, not a
re-decomposition:

1. Six-section phase-1 proposal shape — `id-proposal-shape`, PASS (12
   test cases, including the new missing-core case).
2. Evidence citation format — `id-citation-format`, PASS (13 test
   cases).
3. Goal/persona reference — `id-persona-goal`, PASS (13 test cases).
4. Interaction/task flow — `id-task-flow`, PASS (12 test cases).
5. Complete states per screen/flow — `id-state-completeness`, PASS (13
   test cases).
6. Wireframe staged low-fidelity before high-fidelity —
   `id-wireframe-staging`, PASS (13 test cases).
7. Full ten-item Nielsen heuristic evaluation — `id-nielsen-heuristics`,
   PASS (13 test cases).
8. Accessibility floor, WCAG 2.1 AA — `id-accessibility-floor`, PASS
   (13 test cases).
9. Usability-test plan (not conducted) — `id-usability-test-plan`,
   PASS (13 test cases).
10. Traceability/scope-growth + spec-only boundary —
    `id-traceability`, PASS (14 test cases).
11. Cross-cutting stage ordering — `id-stage-order`, PASS (13 test
    cases).

## Traceability and scope growth

This deliverable is spec-only in the sense the gate machine itself
enforces the boundary on: every fix traces 1:1 to a defect named in the
issue's own audit paragraph and confirmed in
`docs/issue-27/reports/interaction-design/survey.md` §5, matched to the
approved proposal's delivery scope (§4 items 1-6 above map exactly to
survey §5 defects 1-6). This record itself is a `.md` write under
`docs/issue-27/reports/interaction-design.md` — the only kind of output
this role ever authors; no `src/` files were touched.

- Scope growth: none. The Bash-branch reuses the existing
  `gate_reconstruct_write` fail-closed path rather than adding new
  content-verification logic, matching the proposal's adopt/skip
  boundary exactly (adopt: path-extraction-and-scope-check only; skip:
  a full Bash-tool write-surface capability).

## Verification (closed_checks)

- `core/hooks/tests/compliance-check.sh` run against each of the eleven
  `ux-design/plugins/<name>/` directories individually — PASS, zero
  flagged gates, all eleven, from the core checkout referenced by
  `CLAUDE_PLUGIN_ROOT_CORE`.
- Every `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` run
  individually with `CLAUDE_PLUGIN_ROOT_CORE` pointed at that same core
  checkout — all eleven PASS (each suite's new missing-core case
  included).
- `tests/run-gate-tests.sh` — PASS, `11 passed, 0 failed` (not
  `0 passed, 0 failed`).
- 0-suite-guard regression check: a throwaway copy of
  `tests/run-gate-tests.sh` run against an empty `ux-design/plugins/`
  tree exits 2 with the "zero plugin test suites found" refusal message
  — confirms the exact false-green bug survey §5 item 4 described no
  longer reproduces.
- Matcher/code alignment check: for all eleven plugins, the tool-name
  set parsed from `hooks/hooks.json`'s `"matcher"` value equals the
  tool-name set parsed from the corresponding `hooks/*-gate.sh`'s
  `tool in (...)`/`tool == "Bash"` branches — zero set-difference,
  all eleven.
- `tests/parse-check.sh` / `tests/parse-check.sh ux-design/plugins` —
  PASS.
- `tests/deny-only-check.sh` / `tests/deny-only-check.sh
  ux-design/plugins` — PASS.
- `tests/stub-check.sh ux-design/hooks` /
  `tests/stub-check.sh ux-design/plugins` — PASS.
- README/manifest stale-name check:
  `grep -rn "ux-design" .claude-plugin/marketplace.json
  ux-design/.claude-plugin/plugin.json README.md` returns only the
  expected directory-path references (`./ux-design` as marketplace
  source, `ux-design/...` doc paths, the `compliance-check.sh ux-design`
  invocation arg) — zero stale role-name matches.
- Every file path README.md references re-verified to exist, or (for
  `docs/handbooks/gate-house-standard.md`) to be explicitly labeled
  "in core".

## Open findings

None from this phase-2 execution. `docs/specs/approvers.md` untouched.
Role boundary and `write_scope` unchanged — no `src/` files touched, no
other role's `docs/issue-27/reports/*` subtree touched.

## Next steps

None — issue-27 phase 2 scope fully executed per the approved proposal,
ready for PR review/merge.

## Open-finding-resolution path

Not applicable; no open findings.
