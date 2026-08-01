# Agent prompt: persona-goal-checklist

Use this when a phase-2 interaction-design record has a heading matching
persona/user goal, and needs a genuine judgment call: is this a
Cooper-style goal-directed persona, or a role label dressed up as one?
The gate script (`hooks/persona-goal-gate.sh`) can only check structural
presence (a named sub-item, a separate goal field); it cannot judge
whether the goal is genuinely a goal. Walk this checklist for that call.

## Walk this procedure

1. For each persona, find the stated goal and ask: is this an end state
   or motivation ("feel confident the transfer went through"), or is it
   actually a task ("transfer money") or a feature request ("wants a
   dark-mode toggle")? Only an end state/motivation counts as a goal.
   - Task ("How"): what the user does. Belongs in the task-flow
     artifact, not the persona.
   - Feature request: what the user (or a stakeholder) wants built.
     Not a goal at all — flag it as scope creep, not as a persona goal.
   - Goal ("Why"): the outcome the persona is after, independent of any
     particular UI or feature.
2. Count the personas. Cooper's guidance is a small, deliberately
   limited set — typically 3 to 7, with exactly one marked as primary
   (the design target when goals conflict). More than that without a
   stated reason is itself a red flag: it usually means market segments
   got relabeled as personas instead of being synthesized down.
3. Check each persona is an individual, not a segment. A segment
   ("power users", "enterprise admins") is not a persona; a persona
   names a specific composite individual (a name, a role, a goal) that
   stands in for the segment's behavior pattern.
4. Check the goal is phrased as an outcome, not a UI action. "Click the
   submit button" or "use the search bar" describes an interaction step,
   not a goal — the real goal is what the user gets from that step
   ("find the item before checking out elsewhere").

## Red flags (deny or send back for revision)

- A persona described only by demographics (age, job title, income)
  with no goal verb at all.
- A goal stated as a UI action rather than an outcome.
- A "persona" that is actually a market segment, not a named individual.
- More personas than the record can plausibly design for, with no
  primary persona marked.
- A goal that is really a task or a feature request wearing a goal's
  label.

## Hand-off

Once every persona in the record clears this checklist, the record is
ready to hand off to `id-task-flow` — the distinct task-flow artifact
that operationalizes how personas pursue their goals through the
product.
