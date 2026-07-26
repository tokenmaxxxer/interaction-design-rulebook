---
title: Fail-closed trap-at-top for every PreToolUse tool-gating gate
date: 2026-07-26
status: proposed
---

## Problem

Claude Code PreToolUse hooks treat any non-2 exit as NON-BLOCKING (fail-OPEN).
A tool-gating gate that aborts for any reason BEFORE its verdict logic runs — a
failed `source`, a `set -euo pipefail` abort, an unbound variable, an early
interpreter error — exits with a non-2 code and is silently allowed. This is a
fail-open class that sits upstream of the already-landed python `try/except`
and shell exit-code remap: those only fire once verdict logic is reached.

## Change

As the FIRST executable statement of every PreToolUse tool-gating gate script,
immediately after the shebang and above any `set`/`source`/other code, install
a fail-closed EXIT trap:

```
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
```

The trap inspects the final exit code and re-maps anything that is neither 0
(allow) nor 2 (deny) to exit 2 (DENY). Legitimate terminal `exit 0` and
`exit 2` verdicts are preserved exactly; only abnormal/other exits are forced
to 2. It composes with — does not replace — the python `try/except` and the
shell exit-code remap.

### Scope (ux-design-cycle)

Applied to the six PreToolUse tool-gating gates:
`state-gate.sh`, `record-fields-gate.sh`, `path-ownership-gate.sh`,
`doc-bucket-gate.sh`, `handbook-trigger-gate.sh`, `trailer-gate.sh`.

Never-blocking hooks are left untouched: `inject-transition-rules.sh` (and the
excluded class: capture-verdict / scope-approval-token / directive /
inject-transition-rules / hunt-state / ensure-buckets / report-phase).

## Test

`run-gate-tests.sh` gains case `(t)`: it copies the gate, injects an unbound-var
reference right after `set -uo pipefail` (a pre-logic abort, before verdict
logic), and asserts the trap-at-top re-maps the resulting rc=1 to exit 2.
All pre-existing allow/deny cases continue to pass.
