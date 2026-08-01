#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: whether the phase-2 interaction-design record names a concrete usability-test PLAN — a task scenario and how many participants would be recruited — before the record is judged complete."
USE_WHEN="USE_WHEN: after id-nielsen-heuristics and id-accessibility-floor have run, while writing the phase-2 record's usability-test-plan section."
PRODUCES="PRODUCES: a usability-test-plan section naming at least one task-scenario (verb-first task, or a line using the word scenario/task) and a participant-count or recruitment line (e.g. \"5 participants\", \"recruit 5 users\"). This role PLANS the test only — it never conducts or reports the results of a real usability test; running and reporting a study is phase 3+ and stays out of this plugin's and this role's scope."
HAND_OFF="HAND-OFF: none — proceed to id-traceability once this record section is made."
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
