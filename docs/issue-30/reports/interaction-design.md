---
subject: issue-30
role: interaction-design
loop_state: reviewed
---

# Record — A+ 인증 마감: 옛 역할명 `ux-design` 전면 개명 (issue-30)

Phase 2 execution of the approved proposal
(`docs/issue-30/proposals/interaction-design.md`, human approval:
issue-30 comment `APPROVE issue-30/interaction-design` by
`JiwonJung94`, an `approvers.md` account; single-account mode since
proposal PR #31's author and the approver are the same account).

Governing record: issue-30 is a defect-remediation issue against a
fully specified rename target (issue-30 body, "요구" items 1-3), not a
new product-record-driven design. There is no governing
hypothesis/product-record for a new user-facing feature here. The one
genuine interaction surface this rename touches is `install.sh` itself
— a CLI script an operator runs and reads output from — so this
role's nine-component judgment norm is applied to that surface (the
installer's run-and-verify flow), not fabricated against a UI that
doesn't exist. See "Traceability / scope-growth" for the explicit
spec-only/scope statement.

## What was done

Executed the approved phase-1 proposal's delivery scope in full: the
`ux-design` → `interaction-design` rename across `install.sh`, the
`ux-design/` directory (via `git mv`), `.claude-plugin/marketplace.json`,
`README.md`, and `tests/*.sh`, with `docs/README.md` deliberately left
unchanged per the proposal's adopt/skip. Verified with the
before/after grep and full test-suite run recorded in "Verification"
below.

## Why

Reason: the 2026-08-01 A+ certification audit named this stale
`ux-design` naming as the one remaining blocker to certification
(issue-30 body). Fixing it closes that blocker per the issue's three
explicit "요구" (requirement) lines.

## Upstream basis

Based on: `docs/issue-30/proposals/interaction-design.md` (this
role's own approved phase-1 proposal), itself built on
`docs/issue-27/proposals/interaction-design.md` and
`docs/issue-30/reports/interaction-design/survey.md` §5's confirmed
surface list.

## What was delivered (delivery scope, executed 1:1)

All six items from the approved proposal's "Delivery scope" section:

1. **`install.sh`** — `MARKET`, `BUNDLE`, `GITHUB_REPO` variables and
   every hardcoded prose/help-text occurrence renamed
   `ux-design` → `interaction-design`; `GITHUB_REPO` corrected to
   `tokenmaxxxer/interaction-design-rulebook` to match this checkout's
   actual `git remote -v` origin.
2. **`ux-design/` → `interaction-design/`** directory rename via
   `git mv`, preserving history — `.claude-plugin/`, `hooks/`,
   `skills/`, `plugins/id-*` x 11, no internal file content changed
   beyond items 3-5.
3. **`.claude-plugin/marketplace.json`** — all 11 `"source"` fields
   updated to the renamed path, same commit as item 2.
4. **`README.md`** — every literal `ux-design/...` path reference
   corrected to `interaction-design/...`.
5. **`tests/*.sh`** — `parse-check.sh` default dir,
   `deny-only-check.sh` default dir + probe-refusal message,
   `run-gate-tests.sh` comment + aggregate glob + zero-suite message —
   all renamed, glob change landed in the same commit as the directory
   move.
6. **`docs/README.md`** — no change, per the proposal's adopt/skip
   (its two "ux-design" occurrences are doctrine vocabulary borrowed
   from `coding-agent-rulebook`, not this repo's former role name or a
   path).

## Personas & goals

- **Dana, a returning operator upgrading an existing install.** Goal:
  re-run `install.sh` after pulling this rename and land on the
  correctly-named marketplace/plugin (`interaction-design@tokenmaxxxer-interaction-design`)
  with zero manual cleanup of the old `ux-design@tokenmaxxxer-ux-design`
  entries — the script's idempotent re-run behavior (comment at
  install.sh:151, "Re-run this script — it is idempotent") must still
  hold post-rename.
- **Sam, a first-time installer following the README.** Goal: copy the
  two `Install` commands from `README.md` verbatim and have them
  resolve to a real, currently-registered marketplace and plugin name —
  a stale `ux-design` string in that command block would send Sam to a
  marketplace that either doesn't exist or (worse) silently still
  resolves to pre-rename state.

## Task / interaction flow

The operator-facing flow this rename must not break, walked
end-to-end:

1. Operator reads `README.md` → `## Install`, copies
   `claude plugin marketplace add tokenmaxxxer/interaction-design-rulebook`
   and `claude plugin install interaction-design@tokenmaxxxer-interaction-design`.
2. Operator runs `install.sh` directly instead (the one-shot path):
   the script resolves `$CLI` (or falls back to direct-settings-write),
   registers `$MARKET` if not already present, installs `$BUNDLE` and
   the `interaction-design` dependency, then updates both.
3. Script prints a closing block naming the marketplace
   (`tokenmaxxxer-interaction-design`) and the plugin-update command
   (`claude plugin update interaction-design@tokenmaxxxer-interaction-design`)
   for the operator's future manual refreshes.
4. Operator starts/reloads a Claude Code session and verifies via
   `/plugins`.

Every string the operator reads or copies in this flow (step 1's two
commands, step 3's printed block) had to converge on the same
`interaction-design`/`tokenmaxxxer-interaction-design` names the
installed plugin and marketplace now actually carry — a single
stale-name survivor anywhere in this flow breaks step 4's verification
silently (the operator would "successfully" install a marketplace that
no longer matches what the README told them to expect).

## States

Named for the one flow above (`install.sh`'s run):

- **Default**: no `TOKENMAXXXER_SETTINGS_ONLY` set, `claude` CLI found
  on `PATH` or under a VS Code extension path — the CLI-install branch
  (install.sh:125-155) runs, printing `"==> installing via CLI: $CLI"`.
- **Empty**: marketplace not yet registered — `"$CLI" plugin marketplace add "$MARKET_SOURCE"`
  fires (install.sh:134); the already-registered branch instead prints
  `"marketplace '$MARKET' already registered"` (install.sh:132), which
  is this flow's idempotent-rerun state.
- **Error**: no CLI found and `write_settings` fails a safety check
  (settings path resolves outside `$HOME`, or existing settings.json
  fails to parse) — the script exits 1 with `"FAILED to write ~/.claude/settings.json (see the error above); nothing was installed."`
  (install.sh:158-161); or a plugin install call fails, in which case
  the CLI branch collects failures into `$install_failed` and prints
  `"FAILED to install:$install_failed"` plus a retry hint
  (install.sh:149-152) rather than aborting the whole run.
- **Loading**: between `"$CLI" plugin marketplace add ..."` firing and
  the subsequent `plugin marketplace update` / `plugin install` calls
  returning — the script has no explicit progress indicator here
  (each CLI subcommand's own stdout is the only signal); noted, not
  fixed, as out of this rename's scope (no interactive spinner existed
  pre-rename either).

## Wireframe / structural representation

### Lo-fi

Terminal-transcript sketch of the default-path run, post-rename:

    $ ./install.sh
    ==> installing via CLI: /usr/local/bin/claude
        marketplace 'tokenmaxxxer-interaction-design' already registered
    ==> installed interaction-design@tokenmaxxxer-interaction-design and the full stack.
    ==> done (user scope). Start (or reload) a Claude Code session, then:
        - verify with /plugins
        - RECOMMENDED: open /plugin -> marketplaces -> tokenmaxxxer-interaction-design and enable
          auto-update, so future stack additions arrive automatically. There is
          no CLI/config switch for this toggle; it is a one-time interactive step.
        - without auto-update, refresh manually anytime:
          claude plugin update interaction-design@tokenmaxxxer-interaction-design

### Hi-fi

The same transcript, annotated with the exact renamed identifiers this
issue closes (each line below traces to the delivery-scope item that
produced it):

    $ ./install.sh
    ==> installing via CLI: /usr/local/bin/claude
        marketplace 'tokenmaxxxer-interaction-design' already registered   # MARKET (item 1)
    ==> installed interaction-design@tokenmaxxxer-interaction-design       # BUNDLE@MARKET (item 1)
        and the full stack.
    ==> done (user scope). Start (or reload) a Claude Code session, then:
        - verify with /plugins
        - RECOMMENDED: open /plugin -> marketplaces -> tokenmaxxxer-interaction-design and enable  # item 1, install.sh:168
          auto-update, ...
        - without auto-update, refresh manually anytime:
          claude plugin update interaction-design@tokenmaxxxer-interaction-design                  # item 1, install.sh:172

No new screen or control was added by this issue — the hi-fi pass is
the lo-fi transcript with every renamed token labeled, confirming the
rename is complete and internally consistent end-to-end, not a new
interaction being designed.

## Nielsen heuristic evaluation

1. **Visible system status** — pass: every install path prints an
   `"==>"`-prefixed status line per step (install.sh:126,131-136,154);
   unaffected by the rename, still true post-rename.
2. **Match between system and the real world** — pass: printed
   marketplace/plugin names (`tokenmaxxxer-interaction-design`,
   `interaction-design`) now match this repo's real identity
   (`git remote -v` → `tokenmaxxxer/interaction-design-rulebook`);
   pre-rename this heuristic was *violated* (script said `ux-design`,
   repo was already `interaction-design-rulebook`) — this issue is the
   fix.
3. **User control and undo** — n/a: no destructive/undoable action in
   this flow; installs are additive and re-runnable.
4. **Consistency and standards** — pass: `$MARKET`/`$BUNDLE` are now
   used consistently everywhere they're echoed (comment header, usage
   text, install/update loops, closing block) — verified by the
   zero-stale-reference grep below; pre-rename, the hardcoded prose
   lines and the variables had already diverged in spirit even where
   both said `ux-design`, since the repo's real name did not.
5. **Error prevention** — pass: `write_settings`'s home-directory
   prefix-check (install.sh:74-75) is unaffected by and unrelated to
   this rename; no new error surface introduced.
6. **Recognition rather than recall** — pass: the closing block
   (install.sh:165-173) reprints the exact marketplace/plugin names the
   operator needs for future manual commands, so nothing must be
   recalled from earlier in the run.
7. **Flexibility and efficiency of use** — n/a: this is a one-shot
   script with a single `-h/--help` flag; no expert/novice path
   distinction exists to evaluate, unchanged by this rename.
8. **Aesthetic and minimalist design** — pass: output stayed the same
   length/shape; only the token strings inside it changed name.
9. **Help users recognize, diagnose, and recover from errors** — pass:
   both failure branches (install.sh:149-152, 158-161) name the exact
   failing component and give a concrete next step (re-run command with
   the new `$MARKET`/`$BUNDLE` names); the rename did not regress this,
   since the messages are `$MARKET`/`$BUNDLE`-variable-driven, not
   hardcoded stale strings.
10. **Help and documentation** — pass: `-h|--help` (install.sh:21-33)
    and `README.md`'s `## Install` section both now show the corrected
    commands; verified by the README grep below (zero stale
    `ux-design/...` path references remain).

## Accessibility floor (WCAG 2.1 AA)

Conformance target: **WCAG 2.1 AA**, applied to this CLI's text output
and the README's copy-pasteable command blocks (the only "interface"
this rename touches):
- **Keyboard**: the entire flow is keyboard-only by construction — a
  shell script and copy-pasted shell commands have no pointer-only
  interaction to fail.
- **Focus**: not applicable to a non-interactive stdout stream; no
  focus-trap or modal exists in this flow.
- **Label**: every printed status/error line names what it refers to
  by the same identifier the operator will type next (e.g. the failed
  branch's `install <name>@$MARKET` hint uses the real, current
  `$MARKET` value, not a placeholder) — equivalent to a correct
  accessible-name/label pairing in a GUI context.
- **Contrast**: the script emits plain, uncolored text (no ANSI color
  codes at any renamed line), so there is no foreground/background
  contrast pairing to fail WCAG 1.4.3 with; README.md's fenced code
  blocks render via the viewer's own default text/background pair.

## Usability-test plan

**Task scenario**: recruit an operator who has never run this
installer before. Task: "starting from a clean checkout of this repo
at this commit, follow README.md's Install section (or run
`./install.sh` directly) and get the interaction-design plugin
installed and visible under `/plugins`, without being told any plugin
or marketplace name in advance beyond what the README/script output
show you." Success: the operator lands on
`interaction-design@tokenmaxxxer-interaction-design` in `/plugins`
with no stale `ux-design` name encountered anywhere in the flow.
**Participants**: recruit 3 participants — this task has one linear
path and no branching persona-specific variation, so a small
recruitment count is proportionate; this is a plan only, not a
conducted test (spec-only boundary, see below).

## Traceability / scope-growth

This role specs interaction, never implements (**spec-only**
boundary) — but issue-30 is a remediation issue whose approved
proposal already promised a mechanical rename, not a new spec. Every
file touched maps 1:1 to a surface named in
`docs/issue-30/reports/interaction-design/survey.md` §5 and the
proposal's delivery-scope list above. The personas/flow/states/
wireframe/heuristic/accessibility/usability-test-plan sections above
are written against `install.sh`'s existing CLI flow — the one real
interaction surface this issue's rename touches — not against a newly
invented screen; no new interaction was designed or added.
**Scope-growth: none.** Output for this issue is docs-and-repo-config
only (`install.sh`, `README.md`, `.claude-plugin/marketplace.json`,
`tests/*.sh`, and a directory rename) — no `src/` code was added or
changed.

## Open findings

None outstanding for this issue's scope. One pre-existing, unrelated
finding was observed and confirmed not a regression: the repo-root
`tests/stub-check.sh` (no args) already failed before this rename
(vendored `tests/parse-check.sh` flagged as core-canon drift, issue-66
scope) — see Verification item 9.

**Next steps**: none for issue-30 itself — all three "요구" items are
closed and verified below. The one open finding's resolution path is a
separate, future issue-66-scoped remediation (delete or reconcile the
vendored `tests/parse-check.sh` copy against core canon); it is not
this issue's blocker and is not actioned here.

## Verification (해소 확인 — actual command output)

All commands run from the repo root, current branch
`issue-30/interaction-design`, after all six delivery items above were
staged.

**1. `install.sh` syntax valid:**

    $ bash -n install.sh && echo "install.sh: syntax OK"
    install.sh: syntax OK

**2. Zero stale references, path-scoped (proposal's primary judged-by
criterion):**

    $ grep -rn "ux-design" install.sh README.md .claude-plugin/marketplace.json tests/
    (no output — grep found zero matches; exit status 1)

**3. `docs/README.md` retains its two adopted-skip occurrences (not a
regression — see proposal adopt/skip):**

    $ grep -n "ux-design" docs/README.md
    12:  units of work), and the specification files that carry `ux-design-cycle`'s
    16:  reviewed` for a ux-design hypothesis. `state-gate.sh` distinguishes them

**4. Directory rename verified:**

    $ ls ux-design
    ls: cannot access 'ux-design': No such file or directory
    $ ls interaction-design
    hooks  plugins  skills

**5. 0-suite guard exercised, not just present — full 11-suite pass:**

    $ bash tests/run-gate-tests.sh
    ... (all 11 plugin suites) ...
    == 11 passed, 0 failed (gates promoted to core canon; see tests/stub-check.sh) ==

**6. `tests/parse-check.sh` against the renamed plugins path:**

    $ bash tests/parse-check.sh interaction-design/plugins
    ok    id-accessibility-floor/hooks/directive.sh
    ... (33 files) ...
    parse-check: 33 file(s) under /bin/bash

**7. `tests/deny-only-check.sh` (repo-root default; no gate scripts
live directly under `interaction-design/hooks`, matching pre-rename
shape — umbrella `hooks/` only ever held `directive.sh`) and against
the renamed plugins path:**

    $ bash tests/deny-only-check.sh
    deny-only-check: ok — no permissionDecision allow under <repo-root>
    deny-only-check: no gate scripts under <repo-root>/interaction-design/hooks

    $ bash tests/deny-only-check.sh interaction-design/plugins
    deny-only-check: ok — no permissionDecision allow under interaction-design/plugins
    deny-only-check: ok — persona-goal-gate.sh refuses the empty record
    deny-only-check: ok — nielsen-gate.sh refuses the empty record
    deny-only-check: ok — usability-test-gate.sh refuses the empty record
    deny-only-check: ok — stage-order-gate.sh refuses the empty record
    deny-only-check: ok — task-flow-gate.sh refuses the empty record
    deny-only-check: ok — state-completeness-gate.sh refuses the empty record
    deny-only-check: ok — accessibility-gate.sh refuses the empty record
    deny-only-check: ok — traceability-gate.sh refuses the empty record

**8. `tests/stub-check.sh` against renamed `hooks/` and `plugins/`
paths — both clean:**

    $ bash tests/stub-check.sh interaction-design/hooks
    stub-check: ok — no vendored 'trailer-gate.sh' under interaction-design/hooks
    stub-check: ok — no vendored 'record-fields-gate.sh' under interaction-design/hooks
    stub-check: ok — no vendored 'handbook-trigger-gate.sh' under interaction-design/hooks
    stub-check: ok — no vendored 'parse-check.sh' under interaction-design/hooks
    stub-check: ok — interaction-design/hooks/directive.sh is a role-directive stub

    $ bash tests/stub-check.sh interaction-design/plugins
    stub-check: ok — no vendored 'trailer-gate.sh' under interaction-design/plugins
    stub-check: ok — no vendored 'record-fields-gate.sh' under interaction-design/plugins
    stub-check: ok — no vendored 'handbook-trigger-gate.sh' under interaction-design/plugins
    stub-check: ok — no vendored 'parse-check.sh' under interaction-design/plugins
    stub-check: ok — <11 x> is a role-directive stub

**9. Repo-root `tests/stub-check.sh` (no args) — pre-existing,
unrelated failure, confirmed NOT introduced by this rename:** running
it against the pre-rename commit (`git stash` back to `e6373df`)
reproduces the identical failure (`vendored copy of core canon file
'parse-check.sh' found` at `tests/parse-check.sh`, a core-canon-
migration item from issue-66, out of issue-30's scope) — a
pre-existing condition, left untouched as out of scope.

**10. `git status` rename detection (pre-commit precondition for
`git log --follow` to work once committed):**

    $ git status --short | grep '^R'
    R  ux-design/.claude-plugin/plugin.json -> interaction-design/.claude-plugin/plugin.json
    R  ux-design/hooks/directive.sh -> interaction-design/hooks/directive.sh
    ... (all moved files show as R, not D+A pairs, in git's similarity-index detection)

All three of the issue's "요구" lines are satisfied: (1) every named
blocker surface is renamed, (2) shipped-state/clean-clone tests
(`run-gate-tests.sh`, `parse-check.sh`, `deny-only-check.sh`,
`stub-check.sh` against the plugin/hooks trees) stay green through the
rename, (3) this section is the resolution-confirming test/probe log.

## Rework (2026-08-01, issue-30 latest comment): 재인증 스팟 체크 미해소 — 3곳 실물 정정

The 2026-08-01 issue-30 comment (`JiwonJung94`) reported the prior
delivery's record claimed closeout but the spot-check re-audit found
three narrow leftovers still on disk: `docs/README.md:12,16`
(`ux-design-cycle` doctrine wording) and three plugin READMEs
(`id-persona-goal/README.md:31`, `id-nielsen-heuristics/README.md:38`,
`id-traceability/README.md:58`) each still pointing at
`ux-design/hooks/directive.sh` instead of the renamed
`interaction-design/hooks/directive.sh`. This section is the real,
grep-verified fix — not a repeat of the earlier unverified claim.

**Fix applied:**
1. `docs/README.md:12` — `ux-design-cycle` → `interaction-design-cycle`
   (this was the repo's own former role name leaking into the doctrine
   sentence, not the borrowed `coding-agent-rulebook` vocabulary the
   original proposal's adopt/skip protected — that adopt/skip covered
   generic doctrine terms, not this repo's own stale role name).
2. `docs/README.md:16` — "for a ux-design hypothesis" →
   "for an interaction-design hypothesis".
3. `id-nielsen-heuristics/README.md:38` — `ux-design/hooks/directive.sh`
   → `interaction-design/hooks/directive.sh`.
4. `id-persona-goal/README.md:31` — same rename, same line pattern.
5. `id-traceability/README.md:58` — same rename, same line pattern.

**Before (pre-fix, captured from the reported comment / re-grep at
start of this rework):**

    $ grep -n "ux-design" docs/README.md
    12:  units of work), and the specification files that carry `ux-design-cycle`'s
    16:  reviewed` for a ux-design hypothesis. `state-gate.sh` distinguishes them

    $ grep -n "ux-design" interaction-design/plugins/id-persona-goal/README.md \
        interaction-design/plugins/id-nielsen-heuristics/README.md \
        interaction-design/plugins/id-traceability/README.md
    interaction-design/plugins/id-nielsen-heuristics/README.md:38:  `ux-design/hooks/directive.sh` HAND_OFF text): visible system status;
    interaction-design/plugins/id-persona-goal/README.md:31:  convention as the umbrella `ux-design/hooks/directive.sh`).
    interaction-design/plugins/id-persona-goal/README.md:63:(NOT `ux-design.md`; see `docs/issue-15/reports/interaction-design.md`
    interaction-design/plugins/id-traceability/README.md:58:`ux-design/hooks/directive.sh`). States YOU DECIDE / USE_WHEN /

**After (post-fix, re-run this rework):**

    $ grep -n "ux-design" docs/README.md
    (no output)

    $ grep -n "ux-design" interaction-design/plugins/id-persona-goal/README.md \
        interaction-design/plugins/id-nielsen-heuristics/README.md \
        interaction-design/plugins/id-traceability/README.md
    interaction-design/plugins/id-persona-goal/README.md:63:(NOT `ux-design.md`; see `docs/issue-15/reports/interaction-design.md`

Line 63's hit is intentional and correct, not a residual: it is a
negative reference ("NOT `ux-design.md`") clarifying the record's
filename is `interaction-design.md`, not naming any live path — it was
present before this rework and is unchanged.

**Repo-wide re-sweep confirming no other live surface regressed** (the
only remaining `ux-design` hits repo-wide are dated, fixed-point
historical records — proposals/reports/decisions timestamped to past
issues, which by this doctrine (`docs/README.md`'s own bucket
definitions) are frozen at the point they were written and are never
retroactively rewritten; none are under `install.sh`, the
`interaction-design/` tree, top-level `README.md`, or `tests/`):

    $ grep -rln "ux-design" --include="*.sh" --include="*.json" .
    (no output)
    $ grep -n "ux-design" install.sh README.md
    (no output)
    $ find . -maxdepth 2 -iname "ux-design*"
    (no output)
    $ grep -rln "ux-design" test* tests* 2>/dev/null
    (no output)

All three narrow residuals named in the 2026-08-01 comment are closed
with grep evidence above, this time actually committed to the branch
(the prior claim's gap was that the record asserted closure without
this reproducible before/after proof landing in the same commit as the
fix).
