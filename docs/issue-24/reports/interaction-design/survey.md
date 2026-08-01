---
subject: issue-24
role: interaction-design
loop_state: drafting
---

# Survey — gate A+ remediation (issue-24)

Scout skip record: this is a pure remediation issue (fix a named defect
list against a named upstream standard, `core/hooks/lib/gate-lib.sh` +
`docs/handbooks/gate-house-standard.md`) — no open direction/exemplar
decision exists to scout. Skip condition: "spec leaves no design decision
open" (the standard to adopt, and the defect list, are both fully
specified by the issue and by core issue #72's landed standard).

## 1. Confirmed defects (issue's audit, verified against current tree)

1. **`id-traceability` fail-open, alone.** Every other gate in
   `ux-design/plugins/*/hooks/*-gate.sh` opens with the canonical
   `trap __fc EXIT` fail-closed wrapper (verified: `grep -L 'trap __fc
   EXIT' ux-design/plugins/*/hooks/*-gate.sh` returns exactly
   `id-traceability/hooks/traceability-gate.sh`). Its own inner Python
   payload has a `try/except` fail-closed wrapper, but the outer bash
   layer has no trap — a bash-level abort (e.g. `set -uo pipefail`
   tripping on an unset var before the heredoc runs, or the heredoc
   itself failing to launch) exits non-2 and Claude Code treats any
   non-0/2 hook exit as **non-blocking** (fail-open per
   `gate-house-standard.md`'s `gate_trap_fail_closed` doc comment).

2. **README record-path ghost.** `README.md:9` states the record lives
   at `docs/issue-<n>/reports/ux-design.md`. Every actual gate
   (`RECORD_RE` in all nine phase-2 plugins, `id-traceability` included)
   matches only `docs/issue-<n>/reports/interaction-design.md`. A user
   following the README writes to a path no gate enforces — full
   bypass of all nine phase-2 checks. Also: README:105 documents a
   `UX_DESIGN_CYCLE_OFF=1` kill switch; no such variable exists anywhere
   in `ux-design/hooks/directive.sh` or any plugin — a second ghost.

3. **Root test runner is a permanent no-op.** `tests/run-gate-tests.sh`
   unconditionally prints `0 passed, 0 failed` and exits 0 — by design,
   per its own comment, since the role-agnostic gates it used to test
   are now core canon (issue-16). This is legitimate for THAT file's
   original scope, but nothing replaced it as the aggregate signal for
   THIS rulebook's own eleven plugin suites
   (`ux-design/plugins/*/tests/*-gate-tests.sh`) — each runs
   independently (by design, per issue-21 §6, for attributable failure)
   but there is no single command a CI step or reviewer runs to assert
   "all eleven passed"; a reviewer running only
   `tests/run-gate-tests.sh` sees a green no-op and believes the suite
   passed.

## 2. Kill-switch convention — same bug class as core's pre-issue-72 canon

Every plugin's gate uses the pre-fix idiom, e.g.
`id-traceability/hooks/traceability-gate.sh`:

    case "${ID_TRACEABILITY_GATE_OFF:-}" in
      ""|0|false|no|off) ;;
      *) exit 0 ;;
    esac

This is exactly the bug `gate-house-standard.md` §"the two bugs this
issue fixed" describes: any unrecognized value (a typo, e.g.
`ID_TRACEABILITY_GATE_OFF=1x`) falls into `*) exit 0` and silently
disables the gate. Confirmed present, same shape, in all eleven
`ux-design/plugins/*/hooks/*-gate.sh` files (grep: `_GATE_OFF` case
statements, all identical shape). `gate_kill_switch_active` (gate-lib.sh)
is the fix: unrecognized value stays active; only a recognized
on-spelling (`1/true/yes/on`) disables.

## 3. `replace_all` / reconstruction — not actually broken, but hand-rolled

Every phase-2 plugin's Python payload already reconstructs
`Edit`/`MultiEdit` itself (`text.replace(o, n, 1)` for `Edit`, a
per-edit loop for `MultiEdit`) and already denies rather than guesses
when `old_string` doesn't match current content. Spot check: none of the
`MultiEdit` loops read each edit's own `replace_all` field — every
`MultiEdit` call is reconstructed as if `replace_all` were always
`false` (`.replace(o, n, 1)` regardless). This matches `gate-lib.py`'s
`gate_reconstruct_write` bug class #2 exactly (`record-fields-gate.sh`'s
pre-migration bug in core canon). No plugin handles `NotebookEdit` at
all (out of scope for this role's write surface — record is always
`.md` — but `gate_reconstruct_write` handles it for free once adopted).

## 4. Semantic checks — substring vs. structural, by plugin

Most phase-2 plugins already scope their body regex to
"heading-to-next-heading" (a real structural improvement over
whole-document substring matching) and several already require line
-level adjacency (e.g. `id-citation-format`'s per-bullet
`TRIGGER_RE`+`CITE_RE` co-occurrence check, `id-nielsen-heuristics`'
per-item verdict-word-on-same-or-next-line check). The confirmed
substring-only weak point:

- **`id-citation-format`'s `NO_ACCESS_RE`** (`citation-gate.sh`) is
  matched against the **entire document** (`new_text`), not scoped to
  any section: `if not NO_ACCESS_RE.search(new_text):`. A single
  occurrence of the phrase "no live research access" or
  "established-practice assumption" *anywhere* in the record — inside
  an unrelated bullet, a quoted counter-example, even a Sources-section
  entry explaining why a *different* claim needed it — silently
  disables the entire Sources-heading-and-URL requirement for the whole
  document. This is exactly the "word mention passes judgment" failure
  the issue names.
- Other plugins' body-scoping already reads as section-adjacent
  (heading-to-next-heading + per-line word/verdict checks), which is
  the target shape — issue #24's semantic-upgrade item is a targeted
  fix to the one regressed check, not a rewrite of all eleven.

## 5. Prerequisite status

Core issue #72 (gate-house standard) is landed:
`core/hooks/lib/gate-lib.sh` + `gate-lib.py` exist with
`gate_trap_fail_closed`, `gate_kill_switch_active`,
`gate_deny`/`gate_allow`, `gate_bash_write_targets` (bash); `gate_lib.py`
supplies `gate_parse_json_or_deny`, `gate_normalize_path`,
`gate_reconstruct_write` (Python, loaded via `GATE_LIB_PY`). Reference
convention already established in this repo (issue-16,
`ux-design/plugins/*/hooks/directive.sh` all source
`${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/role-directive.sh` the same
way) — the same sibling-path pattern applies to `gate-lib.sh`.
`docs/handbooks/gate-house-standard.md`'s own migration checklist (§"Per
-repo migration checklist") is the authoritative adoption procedure;
this proposal follows it.

## 6. Test coverage gap

No plugin's test suite currently exercises: `MultiEdit` with mixed
`replace_all`, malformed/truncated JSON, an unrecognized (not just
on/off-spelled) kill-switch value, or an absolute/`./`-prefixed
`file_path` matching the same scope a relative fixture already covers.
`gate-house-standard.md`'s six-case mandatory harness names exactly
these gaps (cases 1-5; case 6, Bash-tool writes, does not apply here —
this role's write surface is never a `Bash` call).

## Sources

- `docs/handbooks/gate-house-standard.md` (this session's local core
  checkout)
- `core/hooks/lib/gate-lib.sh`, `gate-lib.py` (same checkout)
- This repo: `ux-design/plugins/*/hooks/*-gate.sh`, `README.md`,
  `tests/run-gate-tests.sh`, `docs/issue-21/proposals/
  issue-21-interaction-design-gate-machine.md`, `docs/issue-16/...`
  (core-canon-reference precedent)
