#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether a phase-2 interaction-design record contains a distinct task/interaction-flow artifact — its own heading, separate from any wireframe-headed section, with real (non-stub) content, and each flow entry naming the realized spec's entry_trigger field"
USE_WHEN="USE_WHEN: writing or editing docs/issue-<n>/reports/interaction-design.md for the interaction-design role, once persona/goal work (id-persona-goal) is under way or done"
PRODUCES="PRODUCES: a task-flow or interaction-flow heading whose body (up to the next same-or-higher heading) is non-blank and is not the same heading/section as any wireframe-headed content — the flow cannot be collapsed into a subsection nested directly under a wireframe heading with no separate heading of its own — and each named flow entry (or the section as a whole, if entries are unnamed) carries an entry_trigger: field naming what starts it"
HAND_OFF="HAND-OFF: none — proceed to the other eight plugins composing the phase-2 judgment norm (docs/issue-21 proposal §4); this plugin owns only the distinct task/interaction-flow artifact check."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
