# id-nielsen-heuristics

Row 7 plugin in the phase-2 interaction-design judgment chain. Owns
exactly one methodology (§3 row `id-nielsen-heuristics` / §7 of
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`):
the full ten-item Nielsen usability-heuristic pass on the phase-2
record — every one of Nielsen's ten heuristics carries a distinct,
non-blank verdict, and every violation is named explicitly rather than
silently passed.

## What it owns

Exactly the Nielsen ten-item heuristic check. It does not own
persona/goal (`id-persona-goal`), task flow (`id-task-flow`), the
accessibility floor (`id-accessibility-floor`), the usability-test plan
(`id-usability-test-plan`), or traceability (`id-traceability`) — those
are independent sibling plugins on the same write surface. Per the
proposal's §4 composition rule, the phase-2 record norm is the
conjunction of all nine phase-2 plugins (plus `id-stage-order`'s
approval gate) firing independently on
`docs/issue-<n>/reports/interaction-design.md`: the write is allowed
only if every currently-installed phase-2 plugin allows it. Killing this
plugin weakens the phase-2 norm but does not break the others.

This plugin is one of two in the phase-2 set that ships an agent
(`id-persona-goal` is the other) — per the proposal §7, judging whether
a heuristic verdict is genuine, not rubber-stamped, needs a walked
check, not just section presence. The other seven phase-2/phase-1
plugins are fully mechanical (presence/staging/format checks) and get
no agent.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN /
  PRODUCES / HAND-OFF for the Nielsen-heuristics check, sourced from the
  shared `core/hooks/lib/role-directive.sh` convention. Names all ten
  heuristics in PRODUCES (copied verbatim from the umbrella
  `interaction-design/hooks/directive.sh` HAND_OFF text): visible system status;
  match between system and the real world; user control and undo;
  consistency and standards; error prevention; recognition rather than
  recall; flexibility and efficiency of use; aesthetic and minimalist
  design; help users recognize, diagnose, and recover from errors; help
  and documentation.
- `hooks/nielsen-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`.
  Fails closed on any write to
  `docs/issue-<n>/reports/interaction-design.md` that does not carry: a
  heading matching `/^#+\s*.*\b(nielsen|heuristic\s+evaluation)\b/i`,
  followed (before the next same-level-or-higher heading) by at least
  ten distinct numbered/lettered/bulleted sub-items, each with a verdict
  word (`pass|fail|violation|met|not met|n/a|ok`, case-insensitive) on
  the same line or the line immediately after it. Denies, naming what's
  wrong, on: no heading found; heading present but body blank/whitespace
  (a stub section); fewer than ten verdicted items; an item with no
  verdict word anywhere nearby. Does not attempt exact-name matching
  against all ten canonical heuristic names — that check is too brittle;
  the count-and-verdict check is the mechanical floor, genuineness is the
  agent's job (see below). Kill switch: `ID_NIELSEN_HEURISTICS_GATE_OFF`.
- `agents/nielsen-checklist.md` — short walked-checklist prompt (not a
  full subagent definition) for judging whether a Nielsen verdict is
  genuine vs rubber-stamped: what a real violation note looks like
  (names the specific screen/flow element, the observable symptom, and a
  fix direction or explicit accept-not-fix) versus a placeholder; why
  "pass" on all ten heuristics with no elaboration is a red flag rather
  than a clean result; how to spot-check "n/a" verdicts for a stated
  reason.
- `tests/id-nielsen-heuristics-gate-tests.sh` — plain bash test script
  (this repo's `tests/deny-only-check.sh`/`tests/stub-check.sh`
  convention, not bats): git-init-tmpdir + JSON payload piped via stdin
  to the gate, checking `$?`. Cases: ten items each carrying a verdict
  word (allow), only nine items (deny), items present with no verdict
  words (deny), heading present with blank body (deny), write outside
  the record path (allow — not this gate's business).

## Kill switch

`export ID_NIELSEN_HEURISTICS_GATE_OFF=1` disables this plugin's gate
only, independent of every other phase-2 plugin's kill switch.

## State file

On a passing write, the gate records the result to
`docs/issue-<n>/reports/interaction-design/.status.json`, keyed by
subject (`"issue-<n>"`), setting
`data["issue-<n>"]["nielsen_heuristics"]` to `"ok"`. Best-effort side
write — it never blocks the underlying content write on its own
failure.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§3, §4, and §7 for the full plugin-set design this plugin is one piece
of.
