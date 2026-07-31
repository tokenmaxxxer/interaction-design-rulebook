#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether a phase-2 interaction-design record's wireframe/fidelity section stages low-fidelity (structural) work strictly before any high-fidelity (polish) treatment is introduced"
USE_WHEN="USE_WHEN: writing or editing docs/issue-<n>/reports/interaction-design.md, the phase-2 record, wherever it contains a wireframe- or fidelity-named heading"
PRODUCES="PRODUCES: two distinct staged sub-headings under (or near) the matched wireframe/fidelity heading — one matching lo(w)-fi, one matching hi(gh)-fi — each with real, non-blank content, with the lo-fi sub-heading appearing before the hi-fi sub-heading by line order; a heading present with a blank body, only one stage present, or high-fi ordered before low-fi all count as absent"
HAND_OFF="HAND-OFF: none — proceed to id-nielsen-heuristics, id-accessibility-floor, id-usability-test-plan, id-traceability, and id-stage-order, the other row-owning plugins gating the same phase-2 record (docs/issue-21 proposal §4); this plugin owns only the lo-fi-before-hi-fi staging check."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
