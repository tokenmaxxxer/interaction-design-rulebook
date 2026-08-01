#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether every screen/flow element in the phase-2 record traces to the governing hypothesis/product-record, and whether any element serving no recorded need is flagged as scope growth rather than silently added"
USE_WHEN="USE_WHEN: writing or updating the phase-2 record docs/issue-<n>/reports/interaction-design.md — the traceability/scope-growth check applies to that write, not to phase-1 research or proposal artifacts"
PRODUCES="PRODUCES: a named traceability/scope-growth section stating the spec-only output boundary explicitly (this role specs, it never implements) and at least one scope-growth flag field, present even when its value is 'none'"
HAND_OFF="HAND-OFF: none — this is a phase-2 quality-bar check alongside the other id-* plugins; id-stage-order governs ordering across all of them."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
