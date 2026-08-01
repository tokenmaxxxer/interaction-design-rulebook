#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether a phase-1 interaction-design proposal contains all six required sections (problem/goal, comparison set, methodology cited, delivery scope, adopt/skip, judged-by), each as its own distinct heading with real content"
USE_WHEN="USE_WHEN: writing or editing any docs/issue-<n>/proposals/*.md phase-1 proposal for the interaction-design role"
PRODUCES="PRODUCES: a proposal document with six named headings, each matched by its own regex so no two required sections share one heading, and each followed by non-blank content before the next same-or-higher-level heading — a heading with a blank/whitespace-only body counts as absent"
HAND_OFF="HAND-OFF: none — proceed to id-citation-format and id-stage-order, the other two plugins composing the phase-1 proposal norm (docs/issue-21 proposal §4); this plugin owns only the six-section shape check."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
