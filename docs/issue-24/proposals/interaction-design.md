---
subject: issue-24
role: interaction-design
loop_state: drafting
---

# Proposal — gate A+ remediation (issue-24)

**PHASE 1 ONLY.** Design proposal for review — no code changes to
`ux-design/plugins/*/hooks/*.sh`, `README.md`, or `tests/` in this
commit. Every fix below is a phase-2 build item, described here for
human approval. Scout was skipped (see
`docs/issue-24/reports/interaction-design/survey.md`, top) — this is a
remediation issue against a fully specified defect list and a landed
upstream standard, not an open design-direction choice.

## 1. Problem/goal framing

Per the survey: `id-traceability` is fail-open on a bash-level abort
(no `trap __fc EXIT`); `README.md` documents a record path
(`ux-design.md`) and kill switch (`UX_DESIGN_CYCLE_OFF`) neither of
which any gate honors; the root test runner is a permanent no-op with
nothing standing in for "did all eleven plugin suites pass"; all eleven
plugins share the pre-issue-72 kill-switch bug (unrecognized value =
disabled); `MultiEdit` reconstruction ignores per-edit `replace_all`;
one semantic check (`id-citation-format`'s `NO_ACCESS_RE`) matches the
whole document instead of the relevant section. Goal: close every item,
landing this rulebook on the `gate-house-standard.md` (core issue #72)
baseline the same way core's own seven gates already did, with test
coverage matching that standard's mandatory harness.

## 2. Comparison set / exemplars

- `core/hooks/*.sh` (post-issue-72): the seven core-canon gates, already
  migrated to `gate-lib.sh`/`gate-lib.py` — this rulebook's target
  shape, not a new design.
- `ux-design/plugins/id-nielsen-heuristics/hooks/nielsen-gate.sh` and
  `id-stage-order/hooks/stage-order-gate.sh`: already carry
  `trap __fc EXIT` correctly — the in-repo pattern the other nine
  plugins converge to, not an external import.
- `docs/handbooks/gate-house-standard.md` §"Per-repo migration
  checklist": the adoption procedure this proposal follows step for
  step.

## 3. Methodology cited

Core issue #72's gate-house standard, adopted by reference
(`docs/handbooks/canon-scripts.md`'s reference-not-copy rule) —
`gate-lib.sh` is sourced, `gate-lib.py` is `importlib`-loaded, neither
is vendored. No independent remediation design is proposed; this issue's
own text names the standard as the required fix.

## 4. Delivery scope

1. **`gate_trap_fail_closed` everywhere.** All eleven
   `ux-design/plugins/*/hooks/*-gate.sh` source `gate-lib.sh` (sibling
   -path convention, matching the existing
   `${CLAUDE_PLUGIN_ROOT_CORE:-$(cd .../core && pwd -P)}` idiom already
   used by every plugin's `directive.sh`) and call
   `gate_trap_fail_closed` as their first statement, replacing each
   plugin's own hand-rolled `__fc`/trap (the nine that already have one)
   or adding it fresh (`id-traceability`, the one missing it).
2. **`gate_kill_switch_active` everywhere.** Every plugin's
   `case "${X_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac`
   replaced with `gate_kill_switch_active "${X_GATE_OFF:-}" || exit 0`.
   Behavior change, intentional: an unrecognized value now stays
   **active** (fail-closed), matching core's own post-#72 fix.
3. **`gate_reconstruct_write` for `Edit`/`MultiEdit`.** Every plugin's
   Python payload replaces its own `.replace(o, n, 1)` /
   per-edit-ignoring-`replace_all` loop with a call to
   `gate_lib.gate_reconstruct_write(tool, tool_input, current_content)`,
   loaded via `GATE_LIB_PY` (env var `gate-lib.sh` exports). Preserves
   each gate's existing deny-on-no-match behavior; changes only how the
   resulting text is computed when `replace_all: true` is present.
4. **`gate_normalize_path` for path scoping.** Every plugin's
   `RECORD_RE`/`PROPOSAL_RE` match against a path already normalized via
   `gate_lib.gate_normalize_path(root, path)` instead of each gate's own
   `posixpath.normpath` + manual `root + "/"` prefix check — closes the
   absolute-path / `./`-prefixed-path gap named in the issue and in the
   standard's mandatory test case 5.
5. **`id-citation-format`'s `NO_ACCESS_RE` scoped, not document-wide.**
   The no-research-access escape is checked only within the
   claim-bullet's own line (already how the `TRIGGER_RE`/`CITE_RE`
   co-occurrence check works) OR within the matched Sources section's
   own body — never against the full `new_text`. A claim bullet
   elsewhere in the document stating "established-practice assumption"
   still needs its own per-bullet marker (existing check, unaffected);
   it can no longer also silently waive the Sources-heading requirement
   for the rest of the document.
6. **README record-path and kill-switch ghosts fixed.** `README.md`'s
   record path corrected from `docs/issue-<n>/reports/ux-design.md` to
   `docs/issue-<n>/reports/interaction-design.md` (matching every
   plugin's actual `RECORD_RE` and the branch/role naming already used
   throughout the rest of the file, e.g. §"Record vocabulary"). The
   documented `UX_DESIGN_CYCLE_OFF=1` kill switch is removed (no gate
   or directive honors it); the install section instead documents the
   real, per-plugin kill switches (`ID_<NAME>_GATE_OFF`, one line per
   plugin, cross-referencing each plugin's own README).
7. **Aggregate test signal.** `tests/run-gate-tests.sh` stays a no-op
   for the role-agnostic gates it documents (correct, per issue-16 —
   not reverted), but gains one added line: it loops
   `ux-design/plugins/*/tests/*-gate-tests.sh`, running each and
   reporting a combined pass/fail summary (still surfacing each
   plugin's own output for attribution, per issue-21 §6 — this is an
   aggregator, not a replacement suite). A reviewer running only this
   one script again gets an accurate signal.
8. **Mandatory test cases, per plugin.** Each
   `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` gains the
   applicable subset of `gate-house-standard.md`'s six-case harness:
   `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`; `MultiEdit` with mixed `replace_all` true/false edits;
   malformed JSON (truncated / non-object / empty); kill switch set to
   an unrecognized value (assert gate **stays active**); absolute
   `file_path` plus a `./`-prefixed variant matching the same scope a
   relative fixture already covers. (Case 6, Bash-tool writes, is
   inapplicable — no plugin here matches on the `Bash` tool.) Delivered
   green in the same commit that ships the fix, not after.

## 5. Adopt/skip

- **Adopt**: `gate-lib.sh`/`gate-lib.py` wholesale, by reference — the
  issue's own precondition, and it already fixes every named bug class
  except the two rulebook-local ones (README ghosts, missing
  aggregator) that no shared library can fix from outside.
- **Adopt**: fixing the `id-citation-format` scoping in place, minimal
  diff — no rewrite of the other ten plugins' already-adequate
  section-scoped checks (survey §4: most are already structural: the
  issue's semantic-upgrade ask is a targeted regression fix, not a
  rearchitecture).
- **Skip**: renaming the `ux-design/` directory, plugin name prefixes
  (`id-*`), or kill-switch variable names (`ID_<NAME>_GATE_OFF`) to
  "interaction-design" — those are internally consistent already (every
  plugin, gate, and directive already says "interaction-design" where
  it matters); only the README's prose drifted. A directory/package
  rename is a larger, unrelated migration the issue does not ask for
  and would blow the "conservative design" instruction.
- **Skip**: adding `NotebookEdit` handling — `gate_reconstruct_write`
  supports it for free, but no phase-2 write surface in this rulebook
  is ever a notebook; documenting it is unnecessary surface.
- **Skip**: retrofitting `gate_bash_write_targets` — no plugin here
  matches on the `Bash` tool (this role never shells out to write its
  record); adding a check for a tool class that can't reach the write
  surface is speculative, not remediation.

## 6. Judged-by (gate tests / approval)

- `docs/handbooks/gate-house-standard.md`'s own compliance detector,
  `core/hooks/tests/compliance-check.sh ux-design`, run clean (zero
  flagged gates) as the closing acceptance check — cited directly, per
  the standard's own migration checklist step 4.
- Every `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` green,
  including the newly added mandatory cases (§4 item 8).
- `tests/run-gate-tests.sh`'s new aggregator line exits non-zero if any
  plugin suite fails, and its output is inspected as part of review —
  not just trusted.
- `README.md`'s record path and kill-switch documentation spot-checked
  against `grep RECORD_RE ux-design/plugins/*/hooks/*.sh` and
  `grep _GATE_OFF ux-design/plugins/*/hooks/*.sh` for zero drift.
- A manual `id-citation-format` fixture: a document with an unrelated
  claim-bullet's "established-practice assumption" marker and NO
  Sources heading must still deny — regression check for the exact bug
  described in survey §4.
