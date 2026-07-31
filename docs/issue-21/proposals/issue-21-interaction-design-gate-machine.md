---
subject: issue-21
role: interaction-design
loop_state: drafting
---

# Proposal — interaction-design gate machine (issue-21)

**PHASE 1 ONLY.** This is a design proposal for review, not an
implementation. It contains no code changes to `src/`, no actual gate
scripts, and no changes to `ux-design/hooks/directive.sh` or any hook
file — every mechanism below is described in prose/pseudocode for human
approval before any phase-2 build work starts. Canon is referenced by
path, never inline-copied (per core `canon-scripts.md`; see
`docs/issue-16/proposals/2026-07-31-convert-to-core-canon-references.md`
for this repo's established citation convention).

## 1. Problem framing (traced to survey + scout brief)

Per `docs/issue-21/reports/interaction-design/survey.md` §4-5 and
`docs/issue-21/reports/interaction-design/scout-brief.md`'s GAP LINE: the
interaction-design methodology adopted in issue-15 is fully specified as
directive prose (`ux-design/hooks/directive.sh`, `PRODUCES`/`HAND_OFF`)
but has zero mechanical enforcement. This proposal closes that gap
without re-litigating the methodology's content — the six-section
proposal / nine-component judgment lists are taken as given, cited by
path, not restated in full here.

## 2. Directive deepening

The current `directive.sh` already names the six/nine items but as
free-running prose paragraphs. Deepen it (phase 2 implementation work,
not this proposal) along these lines:

- **Explicit stage list**, one per named methodology stage, each with
  its own judgment criterion and prohibition, instead of a single prose
  block per facet:
  - Stage `survey`: judgment criterion — "governing hypothesis/product-
    record identified, existing screens/flows named, methodology/
    heuristic set named" (already in `USE_WHEN`, per
    `ux-design/hooks/directive.sh`). Prohibition: no named methodology ->
    survey is incomplete, not "minimal" (already stated; deepening makes
    this a checkable predicate, not just prose).
  - Stage `scout`: judgment criterion — sources cited or explicitly
    labeled "established-practice assumption" (mirrors this proposal's
    own scout-brief format). Prohibition: uncited factual claims about
    an exemplar product.
  - Stage `proposal`: judgment criterion — all six named sections present
    with non-trivial content (not just a heading). Prohibition: heading-
    only sections ("stub sections") count as absent, not present.
  - Stage `judgment` (phase 2 deliverable): judgment criterion — all nine
    named components present or explicitly marked inapplicable with a
    stated reason. Prohibition: silent omission of any of the nine.
- **Facet-level executability**: each criterion above should be phrased
  so a script can check for it mechanically (e.g., "contains a heading
  matching one of {"Problem", "Goal"} case-insensitively, followed by at
  least N non-whitespace characters before the next heading") — this is
  the concrete "facet-level executable" requirement issue-21 asks for,
  as opposed to the current one-line PRODUCES summary.
- Directive text itself stays canon-owned in the sense that its *content*
  (what the six/nine items are) is unchanged from issue-15's approved
  proposal — this phase only proposes making each item indepedently
  checkable, not changing what is required.

## 3. Methodology gate(s)

### 3.1 Gate shape

A PreToolUse hook (new file, e.g.
`ux-design/hooks/methodology-gate.sh`, phase-2 work — not created in this
proposal) firing on writes to:

- `docs/issue-<n>/proposals/*.md` (phase-1 proposal writes)
- `docs/issue-<n>/reports/interaction-design/*.md` (survey/scout writes)
- the phase-2 record location (`docs/issue-<n>/reports/ux-design.md`, per
  `README.md:9`)

Pseudocode (design only — no shell implementation in this proposal):

```
on PreToolUse(Write|Edit) where path matches one of the three globs above:
  content = read the file-to-be-written (proposed content, not disk state)
  required = required_sections_for(path)   # six-item list for proposals,
                                            # nine-item list for the phase-2
                                            # record, per directive.sh
  missing = []
  for section in required:
    if not content.matches(section.heading_pattern) or
       content.section_body(section) is blank/whitespace-only:
      missing.append(section.name)
  if missing:
    deny the write, message: "methodology gate: missing/empty section(s):
      {missing}. See ux-design/hooks/directive.sh PRODUCES/HAND_OFF."
  else:
    allow
```

This mirrors the shape the issue cites (`pricing-rulebook`'s
`methodology-gate.sh`, per survey.md §5) at the level of "check for
required sections/elements on the write surface" — the exact matching
strategy (heading regex vs. structured frontmatter vs. section-count
heuristic) is left as a phase-2 implementation decision, not fixed here,
since it depends on how strict a false-positive rate is acceptable (see
§5 below).

### 3.2 State tracking for ordering

Interaction-design's adopted method has an ordering constraint: survey ->
scout -> proposal -> (human approval) -> phase-2 judgment. Per
`ux-design/hooks/directive.sh` this is already implied by
`loop_state: idle, drafting, reviewed` in the record vocabulary
(`README.md:76-85`), but nothing enforces the *transition order* today.

Proposed mechanism: a small per-issue status artifact, e.g.
`docs/issue-<n>/reports/interaction-design/.status.json`:

```json
{
  "issue": 21,
  "stages": {
    "survey": "done",
    "scout": "done",
    "proposal": "done",
    "approved": "pending",
    "judgment": "not_started"
  }
}
```

The methodology gate above would additionally check, before allowing a
write to a later-stage artifact, that the status file marks all earlier
stages `done` (or `approved` for the phase-1 -> phase-2 boundary, gated
on human Approve per core's interaction protocol, `README.md:6-8`) — i.e.
a phase-2 judgment write is rejected if `.status.json` shows `approved:
pending`. The status file itself would be updated by the same gate hook
on a successful write (not hand-maintained), so it can't drift from
reality by omission.

This state file is scoped to interaction-design only (written under this
role's own report directory) and does not touch core's own record/
`loop_state` mechanism — it is an additional, role-owned tracking layer,
not a replacement for the core record fields.

## 4. Gate tests

Following this repo's existing one-property-per-script convention
(`tests/parse-check.sh`, `tests/deny-only-check.sh`,
`tests/stub-check.sh`), phase-2 work would add
`tests/methodology-gate-tests.sh` (or fold into `run-gate-tests.sh`,
un-stubbing it) with, at minimum:

- **True positive (reject) case**: a proposal file missing one of the six
  named sections (e.g., no "Adopt/skip rationale" heading) -> gate must
  deny.
- **True negative (allow) case**: a proposal file with all six sections
  present and non-blank -> gate must allow.
- **False-negative guard**: a proposal file with all six *headings*
  present but one section body blank/whitespace-only -> gate must still
  deny (catches the "heading-only stub" failure mode named in §2).
- **False-positive guard**: a proposal file whose prose legitimately uses
  section-like language mid-paragraph (e.g., mentions "how it will be
  judged" inside another section's body, not as its own heading) -> gate
  must not be tricked into treating that as the required section allow it
  through when the real heading is actually missing elsewhere.
- **Ordering-violation case**: a write to the phase-2 record when
  `.status.json` shows `approved: pending` -> gate must deny, with a
  distinct message from the missing-section case.
- **Ordering-satisfied case**: same write once `.status.json` shows
  `approved: done` -> gate must allow (assuming the nine-component
  content check also passes).

Each test should assert both the exit code and (where the gate produces a
message) that the message names *which* requirement failed, so a failing
gate is diagnosable rather than an opaque deny.

## 5. Agents/checklists — scoped decision

Per the task brief's own instruction not to over-scope: this proposal
does **not** propose a new agent or checklist file at this time. The
six/nine-item lists are already fully enumerable and are the kind of
thing a section-presence script can check without needing an LLM-driven
checklist walk. If phase-2 implementation finds that a purely mechanical
check produces too many false positives (e.g., can't reliably detect
"stub section" vs. "genuinely short but complete section"), a checklist
or lightweight review agent becomes a fallback option — but that
decision is deferred to phase-2 implementation experience, not
pre-committed here, per issue-21's own instruction ("only if the gate
machine genuinely needs them").

## 6. What this proposal explicitly does not do

- Does not create `ux-design/hooks/methodology-gate.sh` or any other
  script file.
- Does not modify `ux-design/hooks/directive.sh`, `hooks.json`, or
  `README.md`.
- Does not create `tests/methodology-gate-tests.sh` or modify
  `tests/run-gate-tests.sh`.
- Does not copy any canon script content from core, `pricing-rulebook`,
  or `implementation-rulebook` — all references above are by path/
  description only (and, per survey.md §1/§5, those two sibling repos
  were not available to inspect directly in this checkout; their shape
  is carried from the issue-21 body text, flagged as such).
- Does not approve itself. Per role-handoff contract v3 s19, this
  document is phase-1 output awaiting human review before any phase-2
  (implementation) work begins.
