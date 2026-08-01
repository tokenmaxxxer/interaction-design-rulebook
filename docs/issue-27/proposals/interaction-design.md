---
subject: issue-27
role: interaction-design
loop_state: drafting
---

# Proposal — gate A+ final closeout, residual defects (issue-27)

**PHASE 1 ONLY.** Design proposal for review — no code changes to
`ux-design/plugins/*/hooks/*.sh`, `ux-design/plugins/*/hooks/hooks.json`,
`.claude-plugin/marketplace.json`, `ux-design/.claude-plugin/plugin.json`,
`README.md`, or `tests/` in this commit. Every fix below is a phase-2
build item, described here for human approval. Scout was skipped (see
`docs/issue-27/reports/interaction-design/survey.md`, top) — this is a
remediation issue against a fully specified defect list and a landed
upstream precondition, not an open design-direction choice.

## Problem framing / goal

The 2026-08-01 re-audit graded this rulebook A- and named four residual
defect classes on top of the already-closed issue-24 remediation: (1)
no plugin's `hooks.json` matcher or gate code handles the `Bash` tool,
reversing what core PR #75's landed `gate_bash_write_targets.py` +
mandatory missing-core tests now require; (2) `.claude-plugin/
marketplace.json` and `ux-design/.claude-plugin/plugin.json` still
carry the pre-rename `ux-design` role name at the umbrella-plugin
level, a hard error under the repo's 43-role taxonomy; (3)
`tests/run-gate-tests.sh` has no guard against a zero-suite glob match
silently reporting a false green; (4) `hooks.json` matcher vs. gate
code tool coverage must be verified fully aligned in both directions,
including after the Bash fix lands. The goal is to close all four,
verified against `docs/issue-27/reports/interaction-design/survey.md`
§5's confirmed defect list, landing this rulebook back on the
gate-house standard baseline the same conservative way issue-24 already
did, plus zero stale-name/phantom-path residue in README/manifest.

## Comparison set / alternatives considered

Scout was skipped for this proposal (see survey §"Scout skip record",
top) — this is a defect-remediation task, not a new interaction
design, so there is no product/UI exemplar set to compare against. For
a defect-remediation task, "comparison set" instead means: the
reference implementation shape a fix must converge to. Two references
apply here:

- **Core's own landed guard pattern (PR #75 / on-the-record #182).**
  This repo has no sibling `core/` checkout available in this session
  to cite `gate_bash_write_targets.py`'s exact source by line (recorded
  as a constraint in the survey, §"Constraint: core repo not directly
  accessible this session") — labeled **established-practice
  assumption**: PR #75 added a `gate_bash_write_targets.py` helper and
  made missing-core tests mandatory, per the issue-27 body's own
  precondition line, matching the same reference-not-vendor adoption
  shape core issue #72 already established and this repo already
  followed for `gate_trap_fail_closed`/`gate_kill_switch_active`/
  `gate_reconstruct_write`/`gate_normalize_path`
  (`docs/issue-24/proposals/interaction-design.md:121-124`, "Adopt:
  `gate-lib.sh`/`gate-lib.py` wholesale, by reference").
- **This repo's own already-landed sibling-path convention.** Every
  plugin's `hooks/directive.sh` and every `hooks/*-gate.sh` already
  sources core via the identical guarded pattern, e.g.
  `ux-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh:2-4`
  (`. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd .../core && pwd -P)}/hooks/lib/
  gate-lib.sh" 2>/dev/null || { echo ...failing closed...; exit 2; }`).
  This is the in-repo pattern the missing-core test (defect 5) must
  exercise and the Bash-matcher addition (defect 1) must reuse
  unchanged — a real, sourced file path, not an assumption.

## Methodology cited

Survey §4's named methodology: **defect-driven remediation / static
consistency audit** — a closed, named defect list verified against the
current tree, matched one-to-one to fixes, adopting an already-landed
upstream standard by reference rather than designing anything new. No
independent remediation design is proposed here; the issue's own four
"요구" items and the survey's verification of each against the tree
fully specify the fix shape, the same way issue-24's proposal cited
core issue #72's standard by reference
(`docs/issue-24/proposals/interaction-design.md:47-51`).

## Delivery scope — what will be delivered

Each item maps 1:1 to a defect confirmed in
`docs/issue-27/reports/interaction-design/survey.md` §5:

1. **Bash write-case + matcher addition, all eleven plugins (survey
   §5 item 1).** Each `ux-design/plugins/<name>/hooks/hooks.json`
   matcher extended from `"Write|Edit|MultiEdit"` to
   `"Write|Edit|MultiEdit|Bash"`, and each
   `ux-design/plugins/<name>/hooks/<name>-gate.sh` gains a `Bash`
   branch that calls `gate_bash_write_targets` (core, adopted by
   reference per the comparison-set section above) to extract any
   file path(s) a `Bash` tool call would write to, then re-uses each
   plugin's existing `RECORD_RE`/`PROPOSAL_RE` scoping check against
   that path exactly as the `Write`/`Edit`/`MultiEdit` branches already
   do. This is a narrower remediation than a full reversal of the
   issue-24 skip decision
   (`docs/issue-24/proposals/interaction-design.md:140-143`): it does
   not assume this role's write surface changes to include shell-outs;
   it closes the specific gap issue-27 names — a `Bash` call (e.g.
   `bash -c "cat > docs/issue-<n>/reports/interaction-design.md"`)
   currently has zero gate coverage even though it can reach the same
   write surface every other tool branch already guards.
2. **Manifest stale-name fix (survey §5 item 2).**
   `.claude-plugin/marketplace.json:2` renamed from
   `"tokenmaxxxer-ux-design"` to `"tokenmaxxxer-interaction-design"`;
   `:8`'s umbrella plugin entry renamed from `"ux-design"` to
   `"interaction-design"` (source path `./ux-design` unchanged — the
   directory itself is out of scope, per the same conservative-rename
   boundary issue-24 already drew,
   `docs/issue-24/proposals/interaction-design.md:130-136`, "Skip:
   renaming the `ux-design/` directory... internally consistent
   already; only the README's prose drifted"); `:10`'s description
   prose updated to say "interaction-design role" throughout.
   `ux-design/.claude-plugin/plugin.json:2` renamed the same way
   (`"name": "interaction-design"`), `:3` description prose updated to
   match. All eleven `id-*` sub-plugin manifests are already correct
   and untouched.
3. **README stale-name and phantom-path cleanup (survey §5 items 2-3,
   issue "요구" item 4).** `README.md`'s pervasive `ux-design` prose
   (title, install command
   `claude plugin install ux-design@tokenmaxxxer-ux-design`, and the
   other cited occurrences at lines 3-4, 13, 16, 20, 43, 68, 100,
   115-116, 139-146, 155) corrected to `interaction-design` /
   `tokenmaxxxer-interaction-design` to match the renamed manifests.
   The `docs/handbooks/gate-house-standard.md` reference at
   `README.md:63-64` relabeled to explicitly read "(in `core`)" —
   matching how README.md already labels other cross-repo paths —
   rather than removed, since survey §5 item 3 found this path most
   plausibly a legitimate core-repo cross-reference, not a true ghost;
   the fix is a labeling correction, not a deletion.
4. **`tests/run-gate-tests.sh` 0-suite guard (survey §5 item 4).**
   After the aggregation loop (`tests/run-gate-tests.sh:25-26`), add a
   check `[ "$total" -gt 0 ] || { echo "refused: zero plugin test
   suites found under ux-design/plugins/*/tests/ — glob mismatch or
   missing directory" >&2; exit 2; }` before the existing
   `passed`/`failed` summary — a zero-suite run now fails closed
   instead of printing a false-green `0 passed, 0 failed`.
5. **Missing-core mandatory test, all eleven plugins (survey §5 item
   5).** Each `ux-design/plugins/<name>/tests/<name>-gate-tests.sh`
   gains one case in its existing mandatory-cases block (see
   `ux-design/plugins/id-persona-goal/tests/id-persona-goal-gate-tests.sh:75`
   for the block's current shape) that runs the gate with
   `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no
   sibling `core/` present, and asserts the gate exits 2 (deny) rather
   than falling through to success — exercising the fail-closed branch
   every gate script's source line already has
   (e.g. `persona-goal-gate.sh:2-4`) but that no test currently
   reaches.
6. **`hooks.json`/gate-code tool-coverage verification kept green
   (issue "요구" item 2, survey §5 item 6).** Survey §5 confirmed all
   eleven matcher/code pairs already agree before this pass; item 1
   above is the one change that touches this alignment, so item 1's
   matcher edit and gate-code edit are delivered in the same commit,
   per plugin, so the verified-aligned state never regresses even
   transiently.

## Adopt/skip

- **Adopt**: `gate_bash_write_targets`, by reference (core, not
  vendored) — narrowly, only to extract a Bash-written path for reuse
  against each plugin's existing `RECORD_RE`/`PROPOSAL_RE`, not to
  rearchitect any plugin's write-detection.
- **Adopt**: manifest/README renames confined to the umbrella-role
  level (`marketplace.json`, `ux-design/.claude-plugin/plugin.json`,
  `README.md` prose) — matching exactly the scope survey §5 item 2
  found stale, nothing more.
- **Skip**: renaming the `ux-design/` directory path itself, or any
  `id-*` sub-plugin name/kill-switch variable. Every sub-plugin
  manifest, gate, and directive already correctly says
  `interaction-design`/`id-*` where it matters (survey §2, §5 item 2)
  — a directory rename is a larger, unrelated migration issue-27 does
  not ask for and would blow the conservative-design instruction, the
  same boundary issue-24 already drew
  (`docs/issue-24/proposals/interaction-design.md:130-136`).
- **Skip**: deleting the `docs/handbooks/gate-house-standard.md`
  reference. Survey §5 item 3 found it most plausibly a legitimate
  core-repo cross-reference (the same pattern as `core/hooks/lib/
  gate-lib.sh`, already relied on throughout this repo), not a ghost;
  deleting a real cross-repo pointer because this checkout lacks the
  sibling repo would remove a currently-correct reference. A labeling
  fix (explicitly marking it "in core") is the conservative choice.
- **Skip**: adding a full `Bash`-tool write-surface capability to any
  plugin beyond path-extraction-and-scope-check. This role's actual
  authored write surface stays "always a `.md` record via
  `Write`/`Edit`/`MultiEdit`" (survey §2); the Bash branch exists only
  to close the coverage gap issue-27 names for a Bash call that
  *reaches* that same surface indirectly, not to declare Bash a new
  first-class authoring path.
- **Skip**: rewriting or expanding the existing mandatory six-case
  test block (issue-24's own addition) beyond the one missing-core
  case and the one new Bash case named above — the existing five cases
  already pass and are untouched.

## Judged-by / gate tests

- **Matcher/code alignment**: verified by a repo-wide check, per
  plugin, that `grep -oP '"matcher":\s*"\K[^"]+' hooks/hooks.json`
  splits into exactly the same tool-name set as
  `grep -oP '\("(Write|Edit|MultiEdit|Bash)"(?:,\s*"(Write|Edit|
  MultiEdit|Bash)")*\)' hooks/*-gate.sh` produces, for all eleven
  plugins, post-fix — zero set-difference either direction.
- **Missing-core test cases pass**: each
  `ux-design/plugins/<name>/tests/<name>-gate-tests.sh` run individually
  with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path and no
  sibling `core/` present; the new case must assert exit code 2. Then
  `tests/run-gate-tests.sh` run once more with `CLAUDE_PLUGIN_ROOT_CORE`
  set normally (pointing at a real core checkout) to confirm the
  fail-closed case doesn't leak into the normal-path suites.
- **0-suite guard verified**: a manual run of
  `tests/run-gate-tests.sh` against a temporarily-renamed/empty
  `ux-design/plugins/` (or an injected bad glob) must exit non-zero
  with the new refusal message — a regression check for the exact
  false-green bug survey §5 item 4 describes.
- **README/manifest zero stale-name or phantom-path references**:
  `grep -rn "ux-design" .claude-plugin/marketplace.json
  ux-design/.claude-plugin/plugin.json README.md` returns zero matches
  post-fix (the `ux-design/` directory path itself is expected and
  excluded from this grep, per the adopt/skip section above); every
  file path referenced in `README.md` re-verified to exist (or, for
  `docs/handbooks/gate-house-standard.md`, to be explicitly labeled
  "in core").
- **Full suite green + compliance-check pass, recorded** (issue "요구"
  item 3): every `ux-design/plugins/<name>/tests/<name>-gate-tests.sh`
  green including the two new cases; `tests/run-gate-tests.sh` reports
  `11 passed, 0 failed`, not `0 passed, 0 failed`; core's
  `compliance-check.sh` (adopted by reference, same as issue-24's
  closing check,
  `docs/issue-24/proposals/interaction-design.md:147-149`) run clean
  against all eleven plugin directories; results recorded in the
  phase-2 record's Verification section, not just asserted.
