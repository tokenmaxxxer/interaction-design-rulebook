---
subject: issue-30
role: interaction-design
loop_state: drafting
---

# Survey — A+ 인증 마감: 옛 역할명 `ux-design` 전면 개명 (issue-30)

Scout skip record: this is a pure rename/consistency remediation against
a fully named target (`ux-design` → `interaction-design`, everywhere) —
no open direction/exemplar decision exists to scout. Skip condition
(scout-directive, two skip conditions): "spec leaves no design decision
open" — the rename target string and the file set are both fully
specified by the issue body's own enumerated surfaces (`install.sh`
MARKET/BUNDLE, `ux-design/` directory tree, README/docs/README/tests
references). This mirrors the identical skip call made for issue-27
(`docs/issue-27/reports/interaction-design/survey.md:9-18`) and issue-24
before it — confirmed correct here by reading the issue-30 body in full
before recording this skip.

## 1. Governing hypothesis / product record this proposal answers

Issue #30 body (2026-08-01 인증 감사 차단 사유 / "2026-08-01 certification
audit blocking reason"): the one remaining blocker to A+ certification is
"옛 역할명 ux-design 전면 개명: install.sh(MARKET/BUNDLE), ux-design/
디렉토리 트리, README·docs/README·tests 참조 일괄" — a full rename of the
legacy `ux-design` role name across `install.sh`'s `MARKET`/`BUNDLE`
variables, the `ux-design/` directory tree itself, and every
README/docs-README/tests reference. This is the item issue-27's own
proposal explicitly deferred: `docs/issue-27/proposals/interaction-design.md:168-175`
("**Skip**: renaming the `ux-design/` directory path itself... a
directory rename is a larger, unrelated migration issue-27 does not ask
for"). Issue-30 is that deferred migration, now in scope by name. Issue's
"요구" also requires (2) tests stay green post-rename (shipped-state /
clean-clone basis), and (3) the phase-2 record capture the
resolution-confirming test/probe run log. Requirement 2 in the issue
body ("sales만 해당") does not apply to this role.

## 2. Existing plugin files/screens this issue touches

- `install.sh` — `MARKET="tokenmaxxxer-ux-design"` (line 17),
  `BUNDLE="ux-design"` (line 18), `GITHUB_REPO="tokenmaxxxer/ux-design-rulebook"`
  (line 19, confirmed stale: `git remote -v` in this checkout shows the
  actual origin is `tokenmaxxxer/interaction-design-rulebook` — this is a
  live phantom-clone-target defect, not just cosmetic), plus every prose
  / `for plugin in ux-design` / `plugin install "$plugin@$MARKET"` /
  help-text occurrence that derives from these three variables (lines
  2-4, 25, 131-172 per the earlier grep sweep).
- `ux-design/` (directory, repo root) — the actual bundle directory
  containing `ux-design/.claude-plugin/`, `ux-design/hooks/`,
  `ux-design/skills/`, and all eleven `ux-design/plugins/id-*/`
  sub-plugins. Confirmed by `find ux-design -maxdepth 2 -type d` in this
  session: `.claude-plugin`, `hooks`, `plugins/{id-persona-goal,
  id-nielsen-heuristics, id-usability-test-plan, id-stage-order,
  id-proposal-shape, id-wireframe-staging, id-task-flow,
  id-state-completeness, id-accessibility-floor, id-citation-format,
  id-traceability}`, `skills`. Every one of these eleven sub-plugin
  directory names is already an `id-*` name and out of scope; only the
  umbrella `ux-design/` path segment itself is stale.
- `.claude-plugin/marketplace.json` — eleven `"source"` fields
  (`./ux-design`, `./ux-design/plugins/id-*` x 11) point at the
  to-be-renamed directory; confirmed by grep, this session.
- `README.md` — pervasive `ux-design/plugins/<name>/` path references
  (lines 44, 70, 141, 144-146, 148, 157), independent of and additional
  to the prose-only stale-name fix issue-27 already delivered
  (`docs/issue-27/reports/interaction-design.md`). These are literal,
  currently-correct file paths (`ux-design/hooks/directive.sh`,
  `ux-design/plugins/<name>/tests/...`) that become phantom paths the
  moment the directory is renamed and README.md is not updated in the
  same commit.
- `docs/README.md` — two `ux-design` occurrences (lines 12, 16:
  "`ux-design-cycle`'s hypothesis state", "for a ux-design hypothesis").
  Confirmed by direct read: these use "ux-design" as a *generic term
  borrowed from `coding-agent-rulebook` doctrine* for the
  proposal/specification hypothesis-state convention, not as this
  repo's former role name — no directory or role name is being
  referenced at these two lines. Flagged here for the proposal's
  adopt/skip call rather than assumed in scope.
- `tests/parse-check.sh:35`, `tests/deny-only-check.sh:44,61`,
  `tests/run-gate-tests.sh:11,22,32` — six occurrences, all either a
  literal default path (`.../ux-design/hooks`, `.../ux-design/plugins/
  */tests/*-gate-tests.sh`) or prose describing that path
  (`tests/deny-only-check.sh:43`, `tests/run-gate-tests.sh:11`) or a
  refusal message that names the path (`tests/run-gate-tests.sh:32`).
  All become broken defaults/messages the moment the directory moves.
- `README.md`, `tests/run-gate-tests.sh` also each still say
  `ux-design/plugins/*/tests/` in refusal/comment text that must track
  the rename 1:1 (`tests/run-gate-tests.sh:32`'s error string
  specifically).
- Not touched by this issue (confirmed already correct,
  issue-27-delivered): `.claude-plugin/marketplace.json`'s `"name"`
  field, `ux-design/.claude-plugin/plugin.json`'s `"name"` field, and
  `README.md`'s prose title/install-command occurrences — these already
  read `interaction-design`/`tokenmaxxxer-interaction-design` per
  `docs/issue-27/reports/interaction-design.md`. This issue is strictly
  about the remaining **path**-shaped references issue-27 skipped, not a
  re-run of issue-27's prose fix.

## 3. Constraints already frozen (design tokens / component inventory)

N/A — explicit survey finding, same as issue-24/issue-27
(`docs/issue-27/reports/interaction-design/survey.md:87-98`). This
issue's artifact class is dev-tooling / gate-machine infrastructure
(shell installer, directory layout, markdown docs, bash test runners),
not a product UI. There is no design-token set, component inventory, or
visual design system governing this repo, and none is created by this
proposal.

## 4. Methodology / heuristic set governing this proposal

Nielsen's ten usability heuristics and Cooper-style persona-goal
methodology do **not** apply to this artifact class, for the same reason
recorded in `docs/issue-27/reports/interaction-design/survey.md:100-116`:
no end-user screen, flow, or persona is being specified. The methodology
that **does** govern this proposal is **mechanical rename / path-integrity
audit**: a single closed rename pair (`ux-design` → `interaction-design`,
at the umbrella-role path level only) applied to every live reference
that resolves at install-time, clone-time, or test-run-time, verified by
exhaustive `grep` before-and-after rather than any independent design
choice. This is a narrower case of the same "defect-driven remediation /
static consistency audit" methodology issue-24 and issue-27 both named
and applied (`docs/issue-27/proposals/interaction-design.md:69-79`) — here
the "defect list" is exactly one defect (a stale path segment) with many
occurrences, not several distinct defect classes.

## 5. Confirmed rename surfaces (verified against current tree)

1. **`install.sh` MARKET/BUNDLE/GITHUB_REPO.** `MARKET`,
   `BUNDLE`, `GITHUB_REPO` (lines 17-19) and every derived occurrence
   (marketplace add/update, plugin install/update loops, help text) all
   still say `ux-design`. `GITHUB_REPO` is doubly stale: it names
   `tokenmaxxxer/ux-design-rulebook`, but `git remote -v` in this exact
   checkout resolves to `tokenmaxxxer/interaction-design-rulebook` — a
   fresh install following `install.sh` today would target a repo name
   that no longer matches this repo's actual GitHub identity.
2. **`ux-design/` directory path.** The umbrella bundle directory itself
   (`ux-design/.claude-plugin/`, `ux-design/hooks/`, `ux-design/skills/`,
   `ux-design/plugins/id-*/` x 11) is the one path segment issue-27
   explicitly, deliberately left unrenamed
   (`docs/issue-27/proposals/interaction-design.md:168-175`). Every
   sub-plugin's own manifest/directive/gate code already correctly says
   `interaction-design`/`id-*` internally (confirmed by issue-27's
   survey and unchanged since); only the containing directory name is
   stale.
3. **`.claude-plugin/marketplace.json` source paths.** Eleven
   `"source"` fields (`./ux-design`, `./ux-design/plugins/id-*` x 10)
   reference the pre-rename directory path; these are distinct from the
   `"name"`/description fields issue-27 already fixed.
4. **`README.md` path references.** Six-plus occurrences
   (lines 44, 70, 141, 144-146, 148, 157) of literal
   `ux-design/plugins/<name>/...` or `ux-design/hooks/...` paths, used
   in both prose and copy-pasteable shell commands
   (`/bin/bash tests/parse-check.sh ux-design/plugins`) — every one
   becomes a broken command the instant the directory moves without a
   matching edit.
5. **`docs/README.md` generic-term occurrences.** Two lines (12, 16)
   use "ux-design"/"ux-design-cycle" as a generic doctrine term inherited
   from `coding-agent-rulebook`, not as a path or this repo's former role
   name — flagged as a survey finding for the proposal to explicitly
   adopt-or-skip, not silently folded into the path rename.
6. **`tests/*.sh` default paths and messages.** `tests/parse-check.sh:35`,
   `tests/deny-only-check.sh:44,61`, `tests/run-gate-tests.sh:11,22,32` —
   default directory arguments, a comment, and a refusal-message string
   all still hardcode `ux-design/hooks` or `ux-design/plugins/*/tests/`.
   Line 22 (`tests/run-gate-tests.sh`) is the aggregate-runner glob
   itself: if this is not renamed in lockstep with the directory move,
   the runner silently matches zero suites — exactly the false-green
   failure mode issue-27's item 4 guard (already landed,
   `tests/run-gate-tests.sh:32`) now exists specifically to catch, which
   is the regression check this proposal's phase-2 verification must
   exercise first.

## 6. Prerequisite status

None. Issue #30's requirement 2 ("sales만 해당: core #78... 랜딩 후 착수")
is scoped explicitly to the `sales` role only, per its own text; this
role (`interaction-design`) has no landing precondition and may proceed
directly to phase 2 once this proposal is approved.

## Sources

- `gh issue view 30` (issue body, read in full 2026-08-01, this session)
- This repo: `install.sh`, `README.md`, `docs/README.md`,
  `.claude-plugin/marketplace.json`, `tests/parse-check.sh`,
  `tests/deny-only-check.sh`, `tests/run-gate-tests.sh`,
  `ux-design/` (directory listing, `find ux-design -maxdepth 2 -type d`),
  `git remote -v` (this checkout)
- `docs/issue-27/proposals/interaction-design.md`,
  `docs/issue-27/reports/interaction-design/survey.md`,
  `docs/issue-27/reports/interaction-design.md`
- `docs/issue-24/proposals/interaction-design.md`,
  `docs/issue-24/reports/interaction-design/survey.md`
