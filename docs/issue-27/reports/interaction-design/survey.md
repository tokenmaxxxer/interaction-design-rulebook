---
subject: issue-27
role: interaction-design
loop_state: drafting
---

# Survey — gate A+ final closeout, residual defects (issue-27)

Scout skip record: this is a pure remediation issue against a fully
named defect list and a landed upstream precondition (core PR #75 +
on-the-record #182) — no open direction/exemplar decision exists to
scout. Skip condition (scout-directive, two skip conditions): "spec
leaves no design decision open" — the defect list and the standard to
match are both fully specified by the issue body and by core PR #75's
already-landed guard shape. This mirrors the identical skip call made
for issue-24 (`docs/issue-24/reports/interaction-design/survey.md`,
top) and issue-21 before it; confirmed correct here by actually reading
the issue-27 body in full before recording this skip.

## 1. Governing hypothesis / product record this proposal answers

Issue #27 body (2026-08-01 재감사 잔여 결함 / "2026-08-01 re-audit
residual defects"): a re-audit graded this rulebook A- and found four
residual defect classes, to be closed under the same conservative,
reference-not-vendor discipline issue-24 already established:

1. Bash write-case/matcher additions (tie-in: core PR #75's
   `gate_bash_write_targets.py` + missing-core mandatory tests).
2. `manifest`'s stale `ux-design` role name (marketplace name and
   plugin name) — a hard error under the repo's 43-role taxonomy.
3. Root test runner needs a "0-suite" guard.
4. `hooks.json` matcher and gate code must have fully matching tool
   coverage (advertised/tested branches must be reachable in
   production) — this is the issue's item 2 in its numbered "요구"
   list.

This builds directly on `docs/issue-24/proposals/interaction-design.md`
(approved, executed per `docs/issue-24/reports/interaction-design.md`)
and `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
(the original eleven-plugin decomposition). Issue-24 closed the
`gate_trap_fail_closed` / `gate_kill_switch_active` /
`gate_reconstruct_write` / `gate_normalize_path` migration and the
README record-path/kill-switch ghosts; issue-27 is the next re-audit
pass finding what that migration left open.

## 2. Existing plugin files/screens this issue touches

- `.claude-plugin/marketplace.json` — marketplace name
  (`tokenmaxxxer-ux-design`, line 2) and the umbrella role's plugin
  entry (`"name": "ux-design"`, line 8, plus description prose line 10)
  are stale role names.
- `ux-design/.claude-plugin/plugin.json` — `"name": "ux-design"`
  (line 2) and description prose (line 3) repeat the same stale name.
- `README.md` (repo root) — pervasive `ux-design` prose (title line 1,
  lines 3-4, 13, 16, 20, 43, 68, 100, install line 115-116
  `claude plugin install ux-design@tokenmaxxxer-ux-design`, 139-146,
  155) and a reference to `docs/handbooks/gate-house-standard.md`
  (README.md:63-64) which does not exist in this checkout (only
  `docs/handbooks/tests.md` exists under `docs/handbooks/`).
- `tests/run-gate-tests.sh` — the aggregate runner added by issue-24
  §4 item 7; loops `ux-design/plugins/*/tests/*-gate-tests.sh`
  (lines 25-26) and reports `passed`/`failed` (lines 33-35) but has no
  check for `total -eq 0` — a bad glob, moved directory, or empty
  `ux-design/plugins/` silently reports `0 passed, 0 failed` and exits
  0 (green).
- `ux-design/plugins/<name>/hooks/hooks.json` (all eleven) — each
  carries one matcher entry, `"Write|Edit|MultiEdit"`
  (e.g. `ux-design/plugins/id-persona-goal/hooks/hooks.json:7`).
- `ux-design/plugins/<name>/hooks/<name>-gate.sh` (all eleven) — each
  branches on the identical tool tuple `("Write","Edit","MultiEdit")`
  (e.g. `ux-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh:99`).
  None of the eleven matchers or gate scripts mention `"Bash"`
  anywhere (repo-wide `grep -n '"Bash"' ux-design/plugins/*/hooks/*.sh`
  returns zero hits).
- `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` (all eleven) —
  each already carries the issue-24 mandatory six-case block (e.g.
  `ux-design/plugins/id-persona-goal/tests/id-persona-goal-gate-tests.sh:75`,
  `## --- mandatory: gate-lib shared-behavior cases (core issue #72
  migration) ---`) but none has a case that unsets/breaks
  `CLAUDE_PLUGIN_ROOT_CORE` and asserts the gate fails closed (exit 2)
  — repo-wide `grep -rn -i "CLAUDE_PLUGIN_ROOT_CORE\|missing.core"
  ux-design/plugins/*/tests/*.sh` returns zero hits, despite every gate
  script's own source-line guard
  (e.g. `ux-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh:2-4`)
  having exactly that fail-closed branch, untested.

## 3. Constraints already frozen (design tokens / component inventory)

N/A — explicit survey finding. This issue's artifact class is
dev-tooling / gate-machine infrastructure (bash+Python hook scripts,
JSON manifests, markdown test runners), not a product UI. There is no
design-token set, component inventory, or visual design system
governing this repo, and none is created by this proposal. This is the
same N/A finding issue-15's and issue-21's own records already made for
this rulebook's infrastructure deliverables
(`docs/issue-24/reports/interaction-design.md:50-51`,
"gate-infrastructure remediation, not a screen/flow/wireframe
specification").

## 4. Methodology / heuristic set governing this proposal

Nielsen's ten usability heuristics and Cooper-style persona-goal
methodology do **not** apply to this artifact class: there is no
end-user screen, flow, or persona being specified — the "product" is
the gate machine itself, and its "users" are this rulebook's own
Claude Code sessions and the human reviewer, not an application
end-user. The methodology that **does** govern this proposal is
**defect-driven remediation / static consistency audit**: a named,
closed defect list (issue #27's own four items, verified against the
current tree) is matched one-to-one against fixes, with conservative,
reference-not-vendor adoption of an already-landed upstream standard
(core PR #75) as the target shape — the same methodology named and
applied in `docs/issue-24/proposals/interaction-design.md` §3
("Methodology cited... Core issue #72's gate-house standard, adopted
by reference... No independent remediation design is proposed; this
issue's own text names the standard as the required fix.").

## 5. Confirmed defects (issue's audit, verified against current tree)

1. **Bash write-case/matcher gap.** No plugin's `hooks.json` matcher
   includes `Bash`, and no plugin's gate script branches on the
   `"Bash"` tool name (confirmed zero hits, see §2 above). This
   directly reverses a documented prior decision:
   `docs/issue-24/proposals/interaction-design.md:140-143` explicitly
   chose to **skip** retrofitting `gate_bash_write_targets` on the
   grounds "no plugin here matches on the `Bash` tool (this role never
   shells out to write its record)." Core PR #75 (per the issue body's
   own precondition list) landed `gate_bash_write_targets.py` in core
   and made missing-core tests mandatory — issue-27 supersedes the
   issue-24 skip rationale for this specific item; §4 below records
   the narrower remediation this proposal adopts instead of a full
   reversal.
2. **Manifest stale role names.** `.claude-plugin/marketplace.json:2`
   (`"tokenmaxxxer-ux-design"`), `:8`
   (`"name": "ux-design"` for the umbrella plugin entry), `:10`
   (description prose); `ux-design/.claude-plugin/plugin.json:2`
   (`"name": "ux-design"`) and `:3` (description prose). By contrast
   all eleven `ux-design/plugins/*/.claude-plugin/plugin.json` files
   already correctly use `id-*` names — the drift is confined to the
   umbrella-role level, matching the issue's phrasing ("manifest의
   ux-design 옛 명칭 — marketplace명·플러그인명").
3. **README/manifest phantom-file reference.**
   `docs/handbooks/gate-house-standard.md`, referenced at
   `README.md:63-64`, `docs/issue-24/proposals/interaction-design.md:147`,
   and `docs/issue-24/reports/interaction-design/survey.md:122-123`,
   does not exist anywhere in this checkout — only
   `docs/handbooks/tests.md` exists under `docs/handbooks/`. Given
   this repo's established core-canon-by-reference convention (e.g.
   `core/hooks/lib/gate-lib.sh`, also not checked out here), this path
   most plausibly lives in the sibling `core` repo and is a legitimate
   cross-repo reference rather than a true ghost — but README.md does
   not label it "in core" the way it labels other cross-repo paths,
   so the reference reads as unqualified/ambiguous inside this repo
   and is flagged for a labeling fix.
4. **Runner has no 0-suite guard.** `tests/run-gate-tests.sh:25-35`:
   the `for t in .../*-gate-tests.sh; do [ -f "$t" ] || continue; ...
   done` loop, if the glob matches zero files, leaves `total=0`,
   `failed=0`, and the closing `[ "$failed" -eq 0 ]` (line 35) exits 0
   — a silent false-green identical in shape to the issue-24-era
   permanent no-op the runner was fixed away from
   (`docs/issue-24/reports/interaction-design/survey.md:39-50`), just
   reachable by a different trigger (bad glob / moved directory /
   empty plugin set) instead of a hardcoded stub.
5. **Missing-core mandatory test absent, all eleven plugins.** Every
   gate script's own core-gate-lib source line has a fail-closed
   branch (e.g.
   `ux-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh:2-4`)
   but no test exercises it — `CLAUDE_PLUGIN_ROOT_CORE`
   unset/pointing at a missing `core/` is untested in all eleven
   `ux-design/plugins/*/tests/*-gate-tests.sh` files. Core PR #75 (per
   the issue's own precondition line) made exactly this test case
   mandatory upstream.
6. **`hooks.json` matcher / gate-code tool-coverage: verified aligned,
   already.** Item 2 of the issue's "요구" list ("hooks.json matcher와
   코드의 도구 커버리지 완전 정합") reads as a requirement to *verify
   and keep* full alignment, not as a report of an existing mismatch:
   every one of the eleven `hooks/hooks.json` matcher strings
   (`"Write|Edit|MultiEdit"`) and every corresponding gate script's
   tool-tuple check (`("Write","Edit","MultiEdit")`) already agree in
   both directions (no matcher entry lacks code, no code branch lacks
   a matcher entry) — confirmed by direct read of all eleven pairs.
   The one place this requirement is NOT yet satisfied is the Bash gap
   in defect 1 above: once a Bash-tool branch is added to satisfy
   defect 1, the matcher must be extended in the same commit, or this
   verified-clean state regresses into exactly the mismatch item 2
   warns against ("advertised/tested branches must be reachable in
   production").

## 6. Prerequisite status

Core PR #75 and on-the-record #182 are named by the issue body as
already landed upstream preconditions
(`gate_bash_write_targets.py`, missing-core mandatory tests,
`CLAUDE_PLUGIN_ROOT_CORE` injection in `spawn.py`). This repo has no
sibling `core/` checkout present to read PR #75's source directly in
this session (constraint, see Sources); all citations to its shape are
taken from the issue body's own precondition description and from the
already-landed `CLAUDE_PLUGIN_ROOT_CORE` sibling-path convention this
repo's own files already use (e.g.
`ux-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh:2-4`,
and confirmed independently at
`docs/issue-24/reports/interaction-design/survey.md:118-121`). The
43-role-taxonomy hard-error rule the issue cites for stale manifest
names was searched for exhaustively in this repo (`grep` across all
`.md` files for "taxonomy", "43-role", "role catalog") and not found —
it is treated as an external, core-repo-side constraint referenced by
the issue body itself (constraint, not sourced to a file path in this
checkout).

## 7. Test coverage gap (restated for §4/proposal cross-reference)

Confirmed absent across all eleven `ux-design/plugins/*/tests/*-gate-tests.sh`:
a missing-core (unset/broken `CLAUDE_PLUGIN_ROOT_CORE`) fail-closed
case, and a Bash-tool matcher/no-op case. Both map directly to defects
1 and 5 above.

## Constraint: core repo not directly accessible this session

No sibling `core/` checkout is present in this working environment,
and attempts to read cached core checkouts outside this repo's working
directory were not permitted by this session's tool policy. All
factual claims in this survey and the accompanying proposal about core
PR #75's / on-the-record #182's exact landed shape are therefore taken
from (a) the issue-27 body's own precondition description, and (b) the
already-landed, in-repo `CLAUDE_PLUGIN_ROOT_CORE` sibling-path
convention and core issue #72 canon this repo's own files already
reference and use (`gate-lib.sh`/`gate-lib.py`,
`gate_trap_fail_closed`, `gate_kill_switch_active`,
`gate_reconstruct_write`, `gate_normalize_path`, and now
`gate_bash_write_targets` per the issue body). Where a claim cannot be
traced to an in-repo file, the proposal labels it "established-practice
assumption" per the citation-format convention already in force here.

## Sources

- `gh issue view 27` (issue body, read in full 2026-08-01, this
  session)
- This repo: `.claude-plugin/marketplace.json`,
  `ux-design/.claude-plugin/plugin.json`, `README.md`,
  `tests/run-gate-tests.sh`, `ux-design/plugins/*/hooks/hooks.json`,
  `ux-design/plugins/*/hooks/*-gate.sh`,
  `ux-design/plugins/*/tests/*-gate-tests.sh`,
  `docs/issue-24/proposals/interaction-design.md`,
  `docs/issue-24/reports/interaction-design/survey.md`,
  `docs/issue-24/reports/interaction-design.md`,
  `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
