---
subject: issue-30
role: interaction-design
loop_state: drafting
---

# Proposal — A+ 인증 마감: 옛 역할명 `ux-design` 전면 개명 (issue-30)

**PHASE 1 ONLY.** Design proposal for review — no code changes to
`install.sh`, the `ux-design/` directory, `.claude-plugin/marketplace.json`,
`README.md`, `docs/README.md`, or `tests/` in this commit. Every item
below is a phase-2 build item, described here for human approval. Scout
was skipped (see `docs/issue-30/reports/interaction-design/survey.md`,
top) — this is a remediation issue against a fully specified rename
target, not an open design-direction choice.

## Problem framing / goal

The 2026-08-01 certification audit named exactly one remaining blocker
to A+ certification: the legacy role name `ux-design` still appears
across `install.sh`'s `MARKET`/`BUNDLE` variables, the `ux-design/`
directory tree, and README/docs-README/tests references
(issue #30 body). Issue-27's proposal already renamed the umbrella
role's *name*/description fields in `.claude-plugin/marketplace.json`
and `ux-design/.claude-plugin/plugin.json`, and README.md's prose title
and install command
(`docs/issue-27/proposals/interaction-design.md:104-131`), but
explicitly and deliberately deferred the directory-path rename itself
(`docs/issue-27/proposals/interaction-design.md:168-175`, "Skip:
renaming the `ux-design/` directory path itself... a directory rename
is a larger, unrelated migration issue-27 does not ask for"). Issue-30
is that deferred migration, now named directly. The goal is to close
every path-shaped and installer-shaped `ux-design` reference confirmed
in `docs/issue-30/reports/interaction-design/survey.md` §5, keep every
shipped-state/clean-clone test green through the rename, and record the
resolution-confirming test/probe log in the phase-2 record, per the
issue's own three "요구" items.

## Comparison set / exemplars

Scout was skipped for this proposal (survey §"Scout skip record", top)
— this is a rename/consistency remediation, not a new interaction
design, so there is no product/UI exemplar set to compare against. For
a rename-remediation task, "comparison set" instead means: the reference
shape a mechanical rename must converge to, and the precedent this repo
already set for the same kind of change.

- **This repo's own already-landed prose-rename precedent
  (established-practice assumption, in-repo).** Issue-27 already
  performed the identical `ux-design` → `interaction-design` string
  substitution at the manifest-name and README-prose level, and recorded
  its own verification method: a repo-wide `grep` for zero remaining
  stale-name matches, scoped to exclude the (then still-intentional)
  directory path itself
  (`docs/issue-27/proposals/interaction-design.md:215-222`,
  `"grep -rn \"ux-design\" .claude-plugin/marketplace.json
  ux-design/.claude-plugin/plugin.json README.md`" returns zero
  matches post-fix"). This proposal reuses the same grep-verification
  shape, this time with the directory-path exclusion removed, since the
  directory itself is now in scope.
- **`git remote -v`'s actual GitHub identity for this checkout
  (real, sourced fact, not an assumption).** This session's `git
  remote -v` resolves to `tokenmaxxxer/interaction-design-rulebook`,
  while `install.sh:19`'s `GITHUB_REPO` still names
  `tokenmaxxxer/ux-design-rulebook` — the installer's own clone target
  is the reference this proposal converges `GITHUB_REPO` to, not an
  external exemplar.

## Methodology cited

Survey §4's named methodology: **mechanical rename / path-integrity
audit** — a single closed rename pair (`ux-design` → `interaction-design`
at the path level) applied to every reference that resolves at
install-time, clone-time, or test-run-time, verified by exhaustive
`grep` before-and-after rather than any independent design choice. This
is a narrower case of the same "defect-driven remediation / static
consistency audit" methodology issue-24 and issue-27 both applied
(`docs/issue-27/proposals/interaction-design.md:69-79`); here the
"defect" is one stale path segment with many occurrences, not several
distinct defect classes, so no per-item methodology variation is
needed.

## Delivery scope — what will be delivered

Each item maps 1:1 to a surface confirmed in
`docs/issue-30/reports/interaction-design/survey.md` §5:

1. **`install.sh` variable/derived-text rename (survey §5 item 1).**
   `MARKET="tokenmaxxxer-ux-design"` → `MARKET="tokenmaxxxer-interaction-design"`,
   `BUNDLE="ux-design"` → `BUNDLE="interaction-design"`, and
   `GITHUB_REPO="tokenmaxxxer/ux-design-rulebook"` →
   `GITHUB_REPO="tokenmaxxxer/interaction-design-rulebook"` (matching
   this checkout's actual `git remote -v` origin). Every prose/help-text
   line that echoes these variables verbatim (comment header lines 2-4,
   usage-help line 25, marketplace/plugin install-update loop lines
   131-172) is left as variable-driven output wherever it already reads
   `$MARKET`/`$BUNDLE`, and hand-edited wherever it hardcodes the string
   literal instead.
2. **`ux-design/` directory rename (survey §5 item 2).** The directory
   itself — `ux-design/.claude-plugin/`, `ux-design/hooks/`,
   `ux-design/skills/`, `ux-design/plugins/id-*/` x 11 — renamed in full
   to `interaction-design/`, via `git mv` to preserve history, with no
   changes to any file's internal content beyond what items 3-5 below
   separately require (the eleven sub-plugins' own manifests/directives/
   gates already correctly say `interaction-design`/`id-*` internally
   per issue-27's survey; only the containing path moves).
3. **`.claude-plugin/marketplace.json` source-path rename (survey §5
   item 3).** All eleven `"source"` fields
   (`./ux-design` → `./interaction-design`,
   `./ux-design/plugins/id-*` → `./interaction-design/plugins/id-*` x 10)
   updated to match the renamed directory, in the same commit as item 2
   so the marketplace manifest never points at a moved-away path even
   transiently.
4. **`README.md` path-reference rename (survey §5 item 4).** Every
   literal `ux-design/plugins/<name>/...` or `ux-design/hooks/...`
   occurrence (lines 44, 70, 141, 144-146, 148, 157) — both prose and
   copy-pasteable shell commands — corrected to `interaction-design/...`,
   distinct from and additional to the prose-title/install-command fix
   issue-27 already delivered.
5. **`tests/*.sh` default-path, comment, and message rename (survey §5
   item 6).** `tests/parse-check.sh:35`'s default directory argument,
   `tests/deny-only-check.sh:44,61`'s default directory argument and
   probe-refusal message, and `tests/run-gate-tests.sh:11,22,32`'s
   comment, aggregate-runner glob, and zero-suite refusal message — all
   six occurrences renamed `ux-design` → `interaction-design`. Line 22
   (the aggregate glob) is delivered in the same commit as item 2 (the
   directory move) specifically so the already-landed 0-suite guard
   (`tests/run-gate-tests.sh:32`, from issue-27) never has a window
   where the glob is silently stale and the guard fires a false refusal
   or, worse, is bypassed by a coincidentally-matching leftover
   directory.
6. **`docs/README.md`: no change (survey §5 item 5).** See adopt/skip
   below — the two "ux-design" occurrences there use the term generically
   (borrowed `coding-agent-rulebook` doctrine vocabulary for a
   hypothesis-state file convention), not as this repo's former role
   name or a path, and are out of this issue's scope.

## Adopt/skip

- **Adopt**: `git mv` for the directory rename (item 2), to preserve
  file history across the move — established-practice assumption (no
  in-repo citation; standard git practice for path renames, and this
  repo's own git history is otherwise linear per `git log` at survey
  time).
- **Adopt**: renaming `install.sh:19`'s `GITHUB_REPO` value to match
  this checkout's actual `git remote -v` origin
  (`tokenmaxxxer/interaction-design-rulebook`) rather than leaving it as
  a second, independent stale string — this is a real, sourced fact
  (survey §5 item 1), not a guess at what the repo "should" be named.
- **Adopt**: reusing issue-27's own grep-verification shape
  (`docs/issue-27/proposals/interaction-design.md:215-222`) for this
  proposal's judged-by criteria, with the directory-path exclusion
  removed now that the directory itself is in scope.
- **Skip**: touching `docs/README.md`'s two generic "ux-design"/
  "ux-design-cycle" occurrences (survey §5 item 5). These name a doctrine
  concept inherited from `coding-agent-rulebook` (the hypothesis-state
  convention that distinguishes a proposal file from a specification
  file), not this repo's former role name or any path — renaming them
  would change unrelated prose to satisfy a coincidental string match,
  not close a real reference. If a future issue wants that doctrine
  vocabulary reworded, it should say so directly; issue-30's own text
  ("install.sh, ux-design/ 디렉토리 트리, README·docs/README·tests 참조")
  is read here as "docs/README's *references to the stale role name/
  path*," which these two lines are not.
- **Skip**: re-touching any field issue-27 already renamed (manifest
  `"name"` fields, `ux-design/.claude-plugin/plugin.json`'s `"name"`,
  README.md's title/install-command prose) — already correct per
  `docs/issue-27/reports/interaction-design.md`; re-editing them here
  would be redundant churn, not a fix.
- **Skip**: renaming any of the eleven `id-*` sub-plugin directory names
  themselves, or any kill-switch/manifest field inside them — already
  correctly named `interaction-design`/`id-*` internally (issue-27
  survey, unchanged since); only the containing `ux-design/` path
  segment moves.

## Judged-by / gate tests

- **Zero stale references, path-scoped**: `grep -rn "ux-design"
  install.sh README.md .claude-plugin/marketplace.json tests/` returns
  zero matches post-fix (excluding `docs/README.md`'s two adopted-skip
  lines and any historical `docs/issue-<n<30>/` records, which are
  frozen history and out of scope by definition).
- **Directory rename verified**: `ls ux-design/` fails (no such
  directory) and `ls interaction-design/` shows the same eleven `id-*`
  sub-plugins plus `.claude-plugin/`, `hooks/`, `skills/`
  `git log --follow` on at least one moved file (e.g.
  `interaction-design/plugins/id-persona-goal/hooks/persona-goal-gate.sh`)
  shows continuous history through the move.
- **0-suite guard exercised, not just present**: `tests/run-gate-tests.sh`
  run post-rename reports `11 passed, 0 failed` (not `0 passed, 0
  failed`) — a direct regression check that the glob rename (item 5) and
  the directory rename (item 2) landed in the same commit and the
  already-landed issue-27 guard (`tests/run-gate-tests.sh:32`) never
  had to fire.
- **Full suite green + compliance-check pass, recorded** (issue "요구"
  items 2-3): every `interaction-design/plugins/<name>/tests/
  <name>-gate-tests.sh` green; `tests/parse-check.sh`,
  `tests/deny-only-check.sh`, `tests/stub-check.sh` (both `hooks` and
  `plugins` invocations) all pass against the renamed paths;
  `install.sh` sourced/dry-run-checked for syntax validity
  (`bash -n install.sh`) since a live marketplace install cannot be
  executed in this session; results recorded in the phase-2 record's
  Verification section with the actual command output, not just
  asserted — this is the "해소 확인 (해당 테스트/프로브 실행 로그)"
  the issue body's requirement 3 names directly.
