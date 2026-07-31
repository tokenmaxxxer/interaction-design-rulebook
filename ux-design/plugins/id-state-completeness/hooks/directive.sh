#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether every screen/flow named in the interaction-design record's states section has stated its complete state set — default, empty, error, loading — before the record can be treated as covering that screen/flow."
USE_WHEN="USE_WHEN: phase 2, once the interaction-design record's states/state-coverage heading exists and names screens/flows; this plugin does not judge which states are visually right, only whether the four required words are named per screen/flow."
PRODUCES="PRODUCES: a per-write pass/fail on docs/issue-<n>/reports/interaction-design.md — naming exactly which of default/empty/error/loading is missing for the screen/flow block in question, or that the states heading is a stub, or that no states heading exists at all."
HAND_OFF="HAND-OFF: none — this is a phase-2 mechanical gate on top of (never instead of) the umbrella interaction-design record gate; other plugins in the set own their own concerns."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
