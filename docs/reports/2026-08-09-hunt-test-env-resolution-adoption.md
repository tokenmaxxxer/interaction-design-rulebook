
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
