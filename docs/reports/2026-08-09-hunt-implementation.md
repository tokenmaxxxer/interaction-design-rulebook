---
proposal: docs/issue-34/proposals/implementation.md
---

# Hunt record — implementation

## before-landing — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list

Verdict: NO FINDING
Seed: modifications to interaction-design/hooks/directive.sh, interaction-design/plugins/{id-state-completeness,id-task-flow,id-wireframe-staging,id-traceability}/hooks/{directive.sh,*-gate.sh}, their tests/*-gate-tests.sh, README.md, plus new docs/issue-34/reports/implementation.md
cap_seconds: 120
tier: default
diff_stat_lines: 14 files changed (per `git status` on working tree vs proposal-approval base)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:20:00Z

Checked: full `bash tests/run-gate-tests.sh` (all 11 plugin suites, 0
failed); `grep -ril` for all 7 spec field names and the loop_state
vocabulary across `docs/` and `README.md` (all found, satisfying the
proposal's own verbatim constraint); each modified gate's shared
`.status.json` write path (`docs/issue-<n>/reports/interaction-design/.status.json`)
already `os.makedirs`'s its parent, pre-existing code untouched by this
diff, so no missing directory. Did find `tests/stub-check.sh` failing
(vendored copy of core-canon `tests/parse-check.sh` still present) — but
reproduced this as pre-existing on the base commit via `git stash`
(fails identically before and after this diff), so it is not a defect
this proposal introduces and is out of scope for this stance. No path
referenced by the new gate code, hooks.json entries, or the aggregator
test runner is absent from the write set; the build carries cleanly with
only the listed files.
