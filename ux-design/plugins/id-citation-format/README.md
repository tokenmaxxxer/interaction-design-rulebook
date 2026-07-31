# id-citation-format

Second plugin in the phase-1 interaction-design chain. Owns exactly one
methodology (§2 row 2 / §3 of
`docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`):
the evidence citation format for phase-1 proposals — every factual claim
about an exemplar product, sibling repo, or external convention either
cites its source or is explicitly labeled an established-practice
assumption, and the proposal closes with a `## Sources` (or equivalent)
section naming at least one file/path or URL.

## What it owns

Exactly the citation-format check. It does not own the six-section
proposal shape (`id-proposal-shape`) or the survey→scout stage ordering
(`id-stage-order`) — those are independent sibling plugins on the same
write surface. Per the proposal's §4 composition rule:

**Phase-1 proposal norm = `id-proposal-shape` ∧ `id-citation-format` ∧
`id-stage-order`.**

All three fire independently on `docs/issue-<n>/proposals/*.md`; the
write is allowed only if every currently-installed phase-1 plugin
allows it. Killing this plugin weakens the phase-1 norm but does not
break the other two.

## Components

- `hooks/directive.sh` — SessionStart directive: YOU DECIDE / USE_WHEN /
  PRODUCES / HAND-OFF for the citation-format check, sourced from the
  shared `core/hooks/lib/role-directive.sh` convention.
- `hooks/citation-gate.sh` — PreToolUse gate on `Write|Edit|MultiEdit`.
  Fails closed on any write to `docs/issue-<n>/proposals/*.md` that
  either (a) has no closing heading matching `/^#+\s*sources?\b/i`
  listing at least one file/path or URL — unless the document states no
  live research access existed (`/no (live )?research access|
  established-practice assumption/i`) — or (b) has a claim bullet
  (trigger words `exemplar|product|nn/g|nng|ixdf|about face|established
  practice|convention|per\s`) without a source or assumption marker on
  the same line (`sources?:|https?://|attributed to|
  established-practice assumption|assumption|가정`). Denies with
  `id-citation-format: refused — %s`, naming the missing element and
  quoting the offending line where applicable. Kill switch:
  `ID_CITATION_FORMAT_GATE_OFF`.
- `tests/id-citation-format-gate-tests.sh` — plain bash test script
  (this repo's `tests/deny-only-check.sh`/`tests/stub-check.sh`
  convention, not bats): git-init-tmpdir + JSON payload piped via stdin
  to the gate, checking `$?`. Cases: claim bullet with no marker
  (deny), claim bullet properly cited (allow), no claims and no Sources
  heading and no assumption language (deny), established-practice
  assumption stated explicitly (allow), write outside `proposals/`
  (allow — not this gate's business).

## Kill switch

`export ID_CITATION_FORMAT_GATE_OFF=1` disables this plugin's gate
only, independent of `id-proposal-shape` and `id-stage-order`.

## State file

On a passing write, the gate records the result to
`docs/issue-<n>/reports/interaction-design/.status.json`, keyed by
subject (`"issue-<n>"`), setting `data["issue-<n>"]["citation_format"]`
to `"ok"`. Best-effort side write — it never blocks the underlying
content write on its own failure.

See `docs/issue-21/proposals/issue-21-interaction-design-gate-machine.md`
§3–§4 for the full plugin-set design this plugin is one piece of.
