#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether the deliverable's persona(s) and goal(s) are genuinely Cooper-style goal-directed design artifacts, not a role label or a task list dressed up as a persona."
USE_WHEN="USE_WHEN: after phase-1 proposal approval (id-proposal-shape, id-citation-format), on writes to the phase-2 record docs/issue-<n>/reports/interaction-design.md."
PRODUCES="PRODUCES: at least one named persona block distinct from a bare role label, each paired with a distinct goal field stating an end-state/motivation, not a UI action or a feature request."
HAND_OFF="HAND-OFF: once persona/goal is judged present and genuine, proceed to id-task-flow — the distinct task-flow artifact this record must also carry."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
