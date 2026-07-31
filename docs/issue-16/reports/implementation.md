---
subject: issue-16
role: implementation
loop_state: landed
---

## What was done

Executed the approved proposal
(`docs/issue-16/reports/implementation/current-state-survey.md`,
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`)
in the ordering it specified, against `tokenmaxxxer-core`'s landed canon
(core issues #63 delivered, #66 delivered):

1. **Item 1 — warrant-hunter reference**: `README.md` plugin-set list gains
   `warrant`; no local warrant-hunter copy existed to remove (confirmed by
   the survey).
2. **Item 4 — terminal-state divergence**: preserving this role's existing
   `{"reviewed"}` terminal set (from the deleted local
   `record-fields-gate.sh:165`) requires `RECORD_FIELDS_TERMINAL_STATES=reviewed`
   in the environment core's (now sole) `record-fields-gate.sh` runs
   under. The proposal's draft assumed a hook entry's `env` field could
   carry this from `ux-design/hooks/hooks.json` — verified against
   Claude Code's actual hook schema during this phase and found false:
   command hooks have no `env` field, and even `CLAUDE_ENV_FILE` (the one
   supported inter-step env mechanism) only reaches subsequent Bash tool
   calls, not other plugins' hook subprocesses. No hooks.json-only
   mechanism exists for one plugin to set env for another plugin's hook.
   Documented instead as an install-time requirement in `README.md`
   (project's own `.claude/settings.json` `env` key) — the one place
   Claude Code applies an env var to every hook subprocess in a session.
3. **Item 2 — gate copies removed**: deleted
   `ux-design/hooks/trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh` and trimmed `hooks.json`'s `PreToolUse` block
   entirely — core's own `core/hooks/hooks.json` (`PreToolUse`, matcher
   `.*`) now fires all three globally for every plugin install, confirmed
   by reading the file directly from `tokenmaxxxer-core@main`.
4. **Item 3 — `directive.sh` replaced with a stub**: sources
   `core/hooks/lib/role-directive.sh` (fetched and read verbatim from
   `tokenmaxxxer-core@main` to match `stub-check.sh`'s actual structural
   check, not just the proposal's inference) and calls
   `core_role_directive` with the four role-unique argument blocks
   (`YOU_DECIDE`, `USE_WHEN`, `PRODUCES`, `HAND_OFF`), preserving the
   original directive's substantive wording word-for-word. One deviation
   from the proposal's draft: the proposal's draft included a
   `trap`/`set -uo pipefail` pair at the top of the stub, reasoning from
   core issue #66's *report*. Reading the *actual* landed
   `core/hooks/tests/stub-check.sh` shows its structural check greps every
   non-blank/non-comment/non-shebang **physical line** for one of: the
   `role-directive.sh` source line, `core_role_directive`, or a
   `VAR="..."` assignment start — a `trap`/`set` line matches none of
   those and fails the check. The stub as landed here omits both lines;
   `stub-check.sh` confirms this passes (see below). Multi-line argument
   values use `$'...\n...'` ANSI-C quoting so each assignment stays one
   physical line in the file (a naive multi-line `"..."` string would put
   continuation lines that also fail the same per-line check).
5. **Item 5 — `tests/stub-check.sh` added and run**: copied verbatim from
   `tokenmaxxxer-core@main:core/hooks/tests/stub-check.sh` (the same
   distribution pattern `parse-check.sh` already uses per that file's own
   header) and wired into the README's "Run the checks" section. Ran
   against this repo's hooks tree:

   ```
   $ /bin/bash tests/stub-check.sh ux-design/hooks
   stub-check: ok — no vendored 'trailer-gate.sh' under ux-design/hooks
   stub-check: ok — no vendored 'record-fields-gate.sh' under ux-design/hooks
   stub-check: ok — no vendored 'handbook-trigger-gate.sh' under ux-design/hooks
   stub-check: ok — no vendored 'parse-check.sh' under ux-design/hooks
   stub-check: ok — ux-design/hooks/directive.sh is a role-directive stub
   ```

   PASS, exit 0.

6. **README sync** (item 2's doc-sync side effect, plus item 1/5): plugin
   list gains `warrant`; the hooks-tree listing drops the three deleted
   gate files and states they are now core canon; "Run the checks" gains
   the `stub-check.sh` line.
7. **`tests/run-gate-tests.sh`**, flagged by the proposal as an open
   phase-2 judgment call (its per-role subprocess tests target
   `$HOOKS/record-fields-gate.sh` and `$HOOKS/trailer-gate.sh`, files this
   change deletes): resolved as drop-and-note, not move-to-core. Core
   canon already fires and is responsible for testing these three gates
   for every plugin install; a per-rulebook re-implementation of the same
   subprocess tests is exactly the duplication issue-66 is retiring.
   Replaced with a short explanatory stub that exits 0; `stub-check.sh` is
   what now guards against the gate files silently reappearing here.

## Verification run

All four checks pass on the resulting tree:

```
$ /bin/bash tests/parse-check.sh
ok    directive.sh
parse-check: 1 file(s) under /bin/bash

$ /bin/bash tests/run-gate-tests.sh
== 0 passed, 0 failed (gates promoted to core canon; see tests/stub-check.sh) ==

$ /bin/bash tests/deny-only-check.sh
deny-only-check: ok — no permissionDecision allow under <repo root>
deny-only-check: no gate scripts under ux-design/hooks

$ /bin/bash tests/stub-check.sh ux-design/hooks
stub-check: ok — no vendored 'trailer-gate.sh' under ux-design/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under ux-design/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under ux-design/hooks
stub-check: ok — no vendored 'parse-check.sh' under ux-design/hooks
stub-check: ok — ux-design/hooks/directive.sh is a role-directive stub
```

## Why

Issue #16: a single canon landed in `tokenmaxxxer-core` (issues #63, #66)
for the warrant-hunter plugin and the three role-agnostic review gates;
this rulebook's own copies were pure duplication (survey finding) and
this conversion must land before this repo's "rulebook 성숙화" phase-2
work, per the issue's ordering constraint.

## Upstream basis

`docs/issue-16/reports/implementation/current-state-survey.md`,
`docs/issue-16/reports/implementation/scout-brief.md`,
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`
(all this branch, phase 1, PR #17, merged 2026-07-31), cross-referenced
directly against `tokenmaxxxer-core@main`'s `core/hooks/hooks.json`,
`core/hooks/lib/role-directive.sh`, `core/hooks/tests/stub-check.sh`, and
`core/hooks/record-fields-gate.sh` (read live during this phase, not
inferred).

## Open findings

All five of this issue's work items executed and verified. One
cross-cutting gap surfaced during item 4 and is not this issue's to fix:
`hooks.json` command hooks have no `env` field, so no plugin's own
`hooks.json` can inject an environment variable for another plugin's
hook subprocess (verified against Claude Code's hook schema this phase).
`record-fields-gate.sh`'s own comment describes "a rulebook ... sets
that env var in its own hooks.json" as the configuration path, but that
path does not exist in the actual hook schema — the only working
mechanism is the *installing project's* `.claude/settings.json`, which
this rulebook cannot ship on a user's behalf. Documented as an install
step here (`README.md`); worth a follow-up issue against
`tokenmaxxxer-core` if other rulebooks hit the same gap, since the
comment's own claimed mechanism is currently unactionable.
