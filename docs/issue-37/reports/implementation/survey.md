# Survey — issue #37 (adopt test-env-resolution convention)

## Convention doc
`docs/specs/test-env-resolution.md` in the on-the-record repo (issue #551),
read at `/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-551-implementation/docs/specs/test-env-resolution.md`.
Resolution order: `$CLAUDE_PLUGIN_ROOT_CORE` (if it contains a non-empty
`hooks/lib/gate-lib.sh`) -> first caller-supplied sibling candidate with the
same file -> SKIP (stderr message `SKIP: core plugin unreachable —
unverifiable outside spawn env`, exit `75`/`EX_TEMPFAIL`, never colliding
with a gate's own 0/1/2). No network fetch inside the canonical contract.

## Current state, this repo
11 plugin gate scripts (`interaction-design/plugins/*/hooks/*-gate.sh`) each
source core inline:
```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/gate-lib.sh" 2>/dev/null || { ...; exit 2; }
```
Candidate resolves to `<repo_root>/core` (a `core/` checked out inside this
rulebook's own root) — this repo has no such directory and no
`CLAUDE_PLUGIN_ROOT_CORE` outside the spawn session, so every gate fails
closed with exit 2, on purpose (fail-closed is correct gate behavior).

The 11 matching test suites
(`interaction-design/plugins/*/tests/*-gate-tests.sh`) invoke these gate
scripts as subprocesses and assert exit codes against fixtures. They do
**not** pre-check core reachability themselves, so the gate's own
fail-closed exit 2 gets read back as a **test failure** on every
allow-path assertion. Confirmed by running the aggregator outside spawn:

```
$ unset CLAUDE_PLUGIN_ROOT_CORE; bash tests/run-gate-tests.sh
...
== 0 passed, 11 failed ==
```

All 11 failures are this same environment artifact, not a real regression
— each failing case is an "-> allow (rc=0)" fixture that gets `rc=2`
instead, on gates that have their own passing `"missing core fails
closed"` case confirming exit 2 is deliberate when core truly is
unreachable.

`tests/run-gate-tests.sh` is the aggregator: loops the 11 suites,
sums pass/fail, no core dependency of its own.

`tests/deny-only-check.sh`, `tests/stub-check.sh`, `tests/parse-check.sh`
grep/parse hook source directly and never source `gate-lib.sh` or read
`CLAUDE_PLUGIN_ROOT_CORE` — confirmed via `grep -l CLAUDE_PLUGIN_ROOT_CORE
tests/*.sh` (no hits). These three match the convention doc's own
enumerated exception (its `gates/test_skip_gate.py` case): out of scope,
same reasoning.

## Prior art in the ecosystem (scout)
Grepped sibling rulebook checkouts already touching this convention:
`data-modeling-rulebook-issue-16/19`, `test-authoring-rulebook-issue-19`,
`user-discovery-rulebook-issue-19` all carry a `tests/resolve-core.sh`.
Its shape (data-modeling, issue-16):
```
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  ...
  git clone -q --depth 1 https://github.com/tokenmaxxxer/tokenmaxxxer-core.git "$cache" || true
  [ -f "$cache/core/hooks/lib/gate-lib.sh" ] && export CLAUDE_PLUGIN_ROOT_CORE="$cache/core"
fi
```
Source: `/home/jwjung/.tokenmaxxxer/work/data-modeling-rulebook-issue-16-implementation/tests/resolve-core.sh`
(local checkout, no URL fetched).

This is exactly the ad hoc "one rulebook's ad hoc script" the convention
doc calls out by name and explicitly excludes from the canonical SKIP
contract ("a network dependency turning into a silent hang or a flaky
failure is exactly the ambiguity this convention removes"). It resolves
core by fetching it, then still fails misleadingly if the network is
unavailable — it does not implement the SKIP branch at all.

**Gap line**: none of the four sibling checkouts implement the convention's
step-3 SKIP/exit-75 branch; all four only implement steps 1-2 via network
fetch instead of a static candidate list. Adopting the network-fetch
pattern here would reproduce the exact ambiguity issue #37 is opened to
remove. This repo's own current tests implement none of the three steps.

## Write set implied
- `tests/lib/resolve-core.sh` (new, shared by all suites) — no network
  fetch, static candidates only, SKIP/exit-75 branch.
- `tests/run-gate-tests.sh` — must tell a skipped suite (exit 75) apart
  from a failed one (exit 1) when aggregating.
- The 11 `interaction-design/plugins/*/tests/*-gate-tests.sh` files — each
  checks resolvability before invoking its gate subprocess.
- `docs/issue-37/reports/implementation/survey.md` (this file),
  `docs/issue-37/proposals/*.md` (this issue's proposal).
