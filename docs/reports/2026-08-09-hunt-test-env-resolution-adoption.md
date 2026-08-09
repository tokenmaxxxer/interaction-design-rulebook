
## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the proposed resolver's static candidate list is claimed to "match what each gate script itself already checks" but nothing in the proposal's own acceptance criteria (or anywhere else) mechanically ties the resolver's candidate list to the 11 gate scripts' actual fallback paths, so the two can silently drift apart.
Kind: design-error
Seed: docs/issue-37/proposals/2026-08-09-test-env-resolution-adoption.md + docs/issue-37/reports/implementation/survey.md (commit 06dc6d0, 181 lines, docs-only)
cap_seconds: 120
tier: default
diff_stat_lines: 181
started_at: 2026-08-09T09:41:34+09:00
ended_at: 2026-08-09T09:44:30+09:00

### Reproduce
```
grep -rn '\.\./\.\./\.\./\.\./core' interaction-design/plugins/*/hooks/*-gate.sh | sed -E 's/^([^:]+):.*/\1/' | sort -u
grep -n "sync\|drift\|candidate" docs/issue-37/proposals/2026-08-09-test-env-resolution-adoption.md
```

### Observed
All 11 gate scripts currently resolve their core fallback via the identical
relative path `.../../../../core` (i.e. `<repo_root>/core`), and the
proposal's "What will be done" section states the new
`tests/lib/resolve-core.sh` will use "static sibling candidates (matching
what each gate script itself already checks, e.g. `<repo_root>/core`)" —
a purely prose claim. The "How you'll know it worked" acceptance section
contains no grep, diff, or test asserting the resolver's candidate list is
derived from or checked against the gate scripts' actual fallback paths;
it only checks pass/fail behavior and doc-reference grep. If any one of
the 11 gate scripts' fallback path is later edited (e.g. a plugin is moved
to a different nesting depth, or its own core-resolution logic changes)
without a matching edit to `resolve-core.sh`'s static candidate list, the
resolver silently diverges: it will report SKIP (exit 75, "unverifiable")
for a suite whose gate script would actually have resolved core
successfully, or vice versa report resolved when the gate would in fact
fail closed. Either way this drift produces no failing test, because SKIP
is explicitly designed to be treated as neither pass nor fail.

### Expected
The proposal's write set or acceptance criteria should either (a) generate
the resolver's candidate list from the same source the gate scripts use
(so there is one definition, not two independently maintained ones), or
(b) add an explicit acceptance check (e.g. a test asserting each gate
script's fallback path string appears in resolve-core.sh's candidate
list) so drift between the two lists is caught mechanically instead of
depending on the author's memory each time a gate script's path changes.

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: NO FINDING
Seed: git diff HEAD -- tests/lib/resolve-core.sh interaction-design/plugins/*/tests/*-gate-tests.sh tests/run-gate-tests.sh
cap_seconds: 120
tier: default
diff_stat_lines: ~230 (resolve-core.sh new file ~40 lines; 11 suite files +9 lines each; run-gate-tests.sh +~17/-4)
started_at: 2026-08-09T09:52:51+09:00
ended_at: 2026-08-09T09:53:50+09:00

Checked whether the suite-level `export CLAUDE_PLUGIN_ROOT_CORE="$RESOLVED_CORE"`
added by resolve-core.sh interferes with each suite's own per-command
`env CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/core-$$ ... bash "$gate"` used in
the "missing core fails closed" test case (present in all 11 suites).
Ran the full suite (`bash tests/run-gate-tests.sh`, all 11 suites) and
individually re-ran id-wireframe-staging's suite: all 11 "missing core
fails closed" cases still pass (`11 passed, 0 failed, 0 skipped`), because
`env VAR=x cmd` sets VAR directly in the child's environment table,
unconditionally overriding the inherited exported value from the parent
shell — ordinary shell semantics, not something resolve-core.sh's
suite-level export can defeat. Also grepped the whole repo for any other
convention reading `CLAUDE_PLUGIN_ROOT` (non-CORE) or a kill-switch var
that this export could silently satisfy; found none — each plugin's
kill-switch is its own distinctly-named `ID_<PLUGIN>_GATE_OFF`
(`ID_WIREFRAME_STAGING_GATE_OFF`, `ID_PROPOSAL_SHAPE_GATE_OFF`, etc.),
untouched by this change. No cancelling pair found.
