---
subject: issue-21
role: interaction-design
loop_state: surveyed
---

# Scout brief — mechanical methodology-enforcement patterns (issue-21)

Stage/mode: internal repo scout (this repo's own prior art), no external
WebSearch/WebFetch invoked this session — the question ("how do rulebooks
in this org enforce methodology adoption mechanically") is an internal
convention question with the primary source living in this repo's own
git history and file tree, per the task brief's own guidance. Where the
issue body cites sibling repos (`implementation-rulebook`,
`pricing-rulebook`) not present in this checkout, those claims are
carried as **issue-text-attributed, not independently verified** (see
survey.md §5).

## What already exists in this repo (primary source)

- Role-agnostic mechanical gates exist, but live in core canon, not any
  rulebook: record-field minimums, commit-trailer format, same-turn
  handbook sync (`README.md:68-70`, "core issue-66"). These are PreToolUse-
  style write-surface checks — proof the pattern (gate on a write, check
  shape) is already idiomatic in this org, just not yet applied to
  *domain-methodology* content.
- `tests/parse-check.sh`, `tests/deny-only-check.sh`, `tests/stub-check.sh`
  show this repo's convention for gate tests: small, focused shell scripts
  under `tests/`, each asserting one property, run via `/bin/bash
  tests/<name>.sh`, non-zero exit on failure. `tests/run-gate-tests.sh`
  shows the convention for what happens when a gate is promoted to core:
  the local test becomes a documented stub, not deleted silently.
- issue-16 ("core canon references, phase 2") converted this repo's own
  role-agnostic duplication into references, which is direct prior art for
  "cite canon by path, never copy" — the same constraint issue-21 imposes
  on this proposal.

## Must-bes for a methodology gate (synthesized from the above + issue text)

- Fire on the actual write surface (proposal/record file writes), not on
  session start — session-start hooks (this role's own `directive.sh`)
  only *inject instructions*, they cannot verify what was actually
  written.
- Check for named required elements (sections/components), not just file
  existence — a present-but-empty section would pass an existence check
  and should not pass a content gate.
- Track ordering/state only if the methodology has an ordering
  constraint; interaction-design's adopted method (survey → scout →
  proposal → phase-2 judgment) does have one, so a per-issue status file
  is warranted, mirroring `loop_state` already used in this role's own
  record vocabulary (`README.md:76-85`).
- Ship with gate tests exercising both a pass and a reject case (false
  positive / false negative), matching this repo's existing
  one-property-per-script test convention.

## Adopt / skip

- **Adopt**: PreToolUse-style gate on `docs/issue-<n>/proposals/*.md` and
  `docs/issue-<n>/reports/interaction-design/*.md` writes, checking for
  the six/nine named elements already specified in `directive.sh`
  (`PRODUCES`/`HAND_OFF`) — no new methodology invented, just enforcement
  of what's already adopted.
- **Adopt**: a lightweight per-issue status file (e.g.
  `docs/issue-<n>/reports/interaction-design/.status.json` or similar),
  tracking phase1/phase2/approved, mirroring `loop_state` semantics
  already in use.
- **Skip**: reproducing implementation-rulebook's or pricing-rulebook's
  gate scripts by copying their code — issue-21's own constraint (canon
  scripts referenced only) and the fact those files aren't in this repo
  make copying impossible and undesirable; the proposal instead designs
  from this role's own already-adopted content.
- **Skip**: a full new agent/checklist system unless the ordering
  constraint genuinely needs repeatable multi-step walking — the
  six/nine-item lists are already enumerable and checkable by a script;
  a checklist agent is not obviously warranted until the gate script
  itself proves insufficient (kept as an open question in the proposal,
  not pre-committed).

## GAP LINE

| Mechanical bar (target, per issue text) | Current interaction-design state |
|---|---|
| PreToolUse methodology gate on proposal/record write surface | None — only `SessionStart` directive injection exists |
| State/status tracking for phase ordering | None — `loop_state` exists in record vocabulary prose but nothing enforces its transitions |
| Gate tests (pass/reject cases) for domain content | None — existing `tests/*.sh` cover shell/shape only, not proposal/record content |
| Content requirements themselves (6-section proposal, 9-component judgment) | **Already met** — fully specified in `directive.sh`, this is the one bar this role already clears |

## Sources

Internal repo scout only, no external fetch this session: `README.md`,
`ux-design/hooks/directive.sh`, `tests/parse-check.sh`,
`tests/run-gate-tests.sh`, `tests/stub-check.sh`,
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`,
git log (`2244b72`, `653587c`, `b45de8f`). External claims about
`implementation-rulebook` and `pricing-rulebook` are attributed to the
issue-21 body verbatim, not independently fetched or verified — a
follow-up cycle with access to those sibling repos should re-verify
before treating their described shape as ground truth.
