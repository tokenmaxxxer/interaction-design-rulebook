# Handbook — tests/

Repo-level checks under `tests/`, never installed as plugin hooks.

- `parse-check.sh` — parses every shell hook under `ux-design/hooks/`
  with `/bin/bash` (bash 3.2 compatibility floor).
- `run-gate-tests.sh` — previously exercised the role-agnostic gates
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`)
  as subprocesses. As of issue-16, those gates no longer have a local
  copy — they are core canon, fired globally by
  `core/hooks/hooks.json` for every plugin install, and tested there, not
  per rulebook. This file now exits 0 with an explanatory message rather
  than pointing at deleted files.
- `deny-only-check.sh` — greps for a hook emitting `permissionDecision:
  allow` (gates may only pass through or refuse) and probes that any
  `*-gate.sh` still under `ux-design/hooks/` refuses an empty record.
  With no local gate files left, the probe step is a no-op by design.
- `stub-check.sh ux-design/hooks` — the drift-recurrence detector added
  in issue-16: fails if any of the four canon files
  (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
  `parse-check.sh`) is re-vendored locally, or if `directive.sh` grows
  back the boilerplate that `core_role_directive` now owns.

Run all four from the repo root; see `README.md`'s "Run the checks".
