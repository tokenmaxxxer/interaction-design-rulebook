---
proposal: docs/issue-34/proposals/implementation.md
---

# Hunt record — issue-34-implementation

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the proposal claims "core's default terminal-state table for this role already makes `reviewed` terminal" and that no override is needed, but core's actual default terminal state is `landed`, not `reviewed`; `reviewed` is only terminal here via the `RECORD_FIELDS_TERMINAL_STATES=reviewed` env var, which README.md itself says cannot be set from this rulebook's own `hooks/hooks.json` (hook entries have no `env` field) and must instead be set in the project's `.claude/settings.json` — a file this repository does not track in git (`git ls-files` finds none). The proposal is depending on state (a "default terminal-state table" naming `reviewed`) that nothing in core or this repo actually maintains.
Kind: design-error
Seed: docs/issue-34/proposals/implementation.md lines 79-114 (loop_state vocabulary / terminal-state section); README.md lines 130-137; core/hooks/record-fields-gate.sh (cached at /tmp/tokenmaxxxer-core-canon-cache/core)
cap_seconds: 120
tier: default
diff_stat_lines: docs-only proposal, ~140 lines (implementation.md) + survey.md
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:15:00Z

### Reproduce
grep -n "RF_TERMINAL" /tmp/tokenmaxxxer-core-canon-cache/core/hooks/record-fields-gate.sh
# -> RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}"  (default is "landed")

grep -n "RECORD_FIELDS_TERMINAL_STATES" docs/issue-34/proposals/implementation.md README.md
# proposal (line ~113-114): "No docs/specs/record-fields-terminal-states.json override is needed —
#   core's default terminal-state table for this role already makes reviewed terminal"
# README.md (line ~130-137): "this rulebook cannot set it from its own hooks.json.
#   Set it in the project's own .claude/settings.json"

git ls-files | grep -i "\.claude/settings"
# -> no output: settings.json is not tracked/maintained by this repo

### Observed
The proposal asserts a "core default terminal-state table" that makes `reviewed` terminal without any override. No such table exists — core's coded default is the literal string `landed`. The actual mechanism keeping `reviewed` terminal is an env var this repo cannot set for itself (per its own README) and that must live in an untracked, external `.claude/settings.json`.

### Expected
The proposal should not describe the terminal-state behavior as self-sufficient ("core's default ... already makes reviewed terminal"); it should acknowledge the existing dependency on an externally-set `RECORD_FIELDS_TERMINAL_STATES=reviewed` env var (as README.md already documents) and confirm that dependency continues to hold for the four new `loop_state` values it is adding, rather than implying no state-name plumbing exists.
