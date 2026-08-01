# Handbook — tests/

Repo-level checks under `tests/`, never installed as plugin hooks.

- `parse-check.sh` — parses every shell hook under
  `interaction-design/hooks/` with `/bin/bash` (bash 3.2 compatibility
  floor).
- `run-gate-tests.sh` — previously exercised the role-agnostic gates
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`)
  as subprocesses. As of issue-16, those gates no longer have a local
  copy — they are core canon, fired globally by
  `core/hooks/hooks.json` for every plugin install, and tested there, not
  per rulebook — that part still exits with an explanatory no-op message.
  As of issue-24, this file also loops every
  `interaction-design/plugins/*/tests/*-gate-tests.sh` suite, running
  each (still surfacing its own output for attribution, per issue-21 §6)
  and exiting non-zero if any fail, so a reviewer running only this one
  script gets an accurate combined signal for the eleven `id-*` plugin
  gates. As of issue-27, it also refuses (exit 2) with an explicit
  message if the glob under `interaction-design/plugins/*/tests/`
  matches zero suites, instead of silently reporting a false-green
  `0 passed, 0 failed`. As of issue-30, `ux-design/` itself was renamed
  to `interaction-design/` (directory, install.sh, marketplace.json,
  README.md, and this file's own path references).
- `deny-only-check.sh` — greps for a hook emitting `permissionDecision:
  allow` (gates may only pass through or refuse) and probes that any
  `*-gate.sh` still under `interaction-design/hooks/` refuses an empty
  record. With no local gate files left, the probe step is a no-op by
  design.
- `stub-check.sh interaction-design/hooks` — the drift-recurrence
  detector added in issue-16: fails if any of the four canon files
  (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
  `parse-check.sh`) is re-vendored locally, or if `directive.sh` grows
  back the boilerplate that `core_role_directive` now owns.

Run all four from the repo root; see `README.md`'s "Run the checks".
