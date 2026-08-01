#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether the deliverable's heuristic pass is a genuine, walked judgment against Nielsen's ten usability heuristics, not a rubber-stamped checklist."
USE_WHEN="USE_WHEN: after phase-1 proposal approval (id-proposal-shape, id-citation-format), on writes to the phase-2 record docs/issue-<n>/reports/interaction-design.md."
PRODUCES="PRODUCES: a heading naming Nielsen/heuristic evaluation, followed by all ten heuristics each carrying a distinct, non-blank verdict: visible system status; match between system and the real world; user control and undo; consistency and standards; error prevention; recognition rather than recall; flexibility and efficiency of use; aesthetic and minimalist design; help users recognize, diagnose, and recover from errors; help and documentation. Every violation is named explicitly, never silently passed."
HAND_OFF="HAND-OFF: once the ten-item Nielsen pass is judged present and genuine, proceed to id-accessibility-floor, the WCAG 2.1 AA floor this record must also carry."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
