# Agent prompt: nielsen-checklist

Use this when judging whether a phase-2 interaction-design record's
Nielsen heuristic pass (docs/issue-<n>/reports/interaction-design.md) is
a genuine walked evaluation, not a rubber-stamped checklist that merely
satisfies `nielsen-gate.sh`'s mechanical count. The gate can only check
that ten items exist and each carries a verdict word — it cannot judge
whether the verdict is real. That judgment is this checklist's job.

## Walk this procedure

1. Read all ten heuristic verdicts in order. For each one, ask: does the
   note reference a specific screen, flow step, or element of THIS
   product's spec, or could this exact sentence be pasted unchanged into
   any other product's evaluation? A verdict with no product-specific
   noun (a screen name, a control, a state) is generic filler, not a
   judgment.
2. Treat "pass" on all ten heuristics with no elaboration as a red flag,
   not a clean result. Real interfaces almost always trip at least one
   heuristic (commonly: error prevention, help/documentation, or
   flexibility/efficiency for novice-only flows). Ten silent passes in a
   row is far more likely to be an unexamined checklist than a genuinely
   heuristic-clean design — push back and ask what was actually walked.
3. For each violation logged, confirm it names:
   - the specific screen/flow/element the violation applies to (not
     "the app" or "the system" in general),
   - what a user would actually experience (the observable symptom, not
     just the heuristic's abstract name restated), and
   - either a fix direction or an explicit "accepted, not fixed, because
     ..." — a violation with no next step is a note, not a verdict.
4. Compare a real violation note against a placeholder:
   - Real: "Checkout step 3 (payment confirm) has no back/undo control;
     a mis-entered card number cannot be corrected without restarting
     the flow — violates user control and undo."
   - Placeholder: "User control and undo: violation. Needs work." (no
     screen named, no symptom described, nothing an implementer could
     act on.)
5. Spot-check "n/a" verdicts specifically — n/a is legitimate only when
   the heuristic genuinely does not apply to this deliverable's scope
   (e.g. "help and documentation: n/a, this spec has no in-product help
   surface in scope"). An n/a with no stated reason is a dodge, treat it
   as equivalent to a missing verdict.

## Prohibitions

- Never accept a verdict that could be copy-pasted across unrelated
  products unchanged.
- Never accept "pass" x10 without asking what specifically was tested
  against each heuristic.
- Never accept a violation note with no named screen/flow/element.

## Hand-off

Once every verdict is confirmed genuine (product-specific, walked, and
either a real pass rationale, a concrete violation, or a justified n/a),
the record may proceed to `id-accessibility-floor`. If any verdict reads
as rubber-stamped, send it back for rework before continuing — the
mechanical gate already passed; this checklist is the layer that
catches what the gate structurally cannot.
