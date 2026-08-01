#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether an interaction-design phase-1 proposal's evidence is cited — every factual claim about an exemplar product, sibling repo, or external convention either names its source or is explicitly labeled an established-practice assumption"
USE_WHEN="USE_WHEN: on any write to docs/issue-<n>/proposals/*.md during phase 1 — checked independently of id-proposal-shape's six-section structural check and id-stage-order's survey/scout gate"
PRODUCES="PRODUCES: a citation-format verdict for the proposal write — pass or a named refusal citing exactly which element is missing (no closing Sources/sources heading with a file/path or URL, or a specific claim bullet lacking a source or assumption marker), quoting the offending line"
HAND_OFF="HAND-OFF: none — this plugin owns only the citation-format check; id-proposal-shape and id-stage-order run independently on the same write surface, and together with this plugin constitute the phase-1 proposal norm (issue-21 proposal §4)."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
