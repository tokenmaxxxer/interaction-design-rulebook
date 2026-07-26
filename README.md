# tokenmaxxxer / ux-design-rulebook

A Claude Code plugin marketplace for the `ux-design` agent role, one of four
new roles specified in `docs/specs/agent-roles.md` (org-level `docs/`
repository) alongside the existing `coding` (`coding-agent-rulebook`) and
`qa` (`qa-agent-rulebook`) roles.

## What `ux-design` decides

`ux-design` decides what to build — value risk and business-viability risk,
in the empowered-team sense: the PM owns exactly those two risks, not a
feature list handed down from elsewhere.

- **Given to start**: an idea. Nothing more is required to open the role.
- **Produces**: a specification, or a kill record — whichever the
  pre-registered hypothesis says. The metric, the threshold, and the
  decision rule are fixed *before* data collection, and the eventual
  go/kill/pivot call is the mechanical application of that rule, not a
  fresh judgement made once the numbers are in.
- **Prevents**: building something nobody wants, and — the sharper
  failure — deciding that only after the fact, against no threshold fixed
  in advance.

This repository never reads another role's repository, and no other role's
repository reads this one. The user is the only channel between roles; see
`docs/specs/state-machine.md` for the full state machine this repository
enforces and `ux-design-cycle/skills/hypothesis-testing/SKILL.md` for the
how-to.

## The state machine, briefly

States: `idle -> drafting -> drafting -> drafting ->
drafting -> reviewed`, carried in a specification file's frontmatter under
`docs/proposals/<date>-<slug>.md` (field `status`, plus `metric`,
`threshold`, `decision_rule`).

The one gated transition, `drafting -> drafting`, is refused
unless the metric, threshold, and decision rule are all filled in **and**
an approval token minted from the user's own turn is present — content
alone is never read as consent. Once `drafting` starts, edits to the
`threshold` field are refused, from any tool, including a shell redirect.
Full detail, including the fail-closed rule and the token format, is in
`docs/specs/state-machine.md`.

## Handoff protocol

The authoritative contract is the work repo's own
`docs/specs/role-handoff-contract.md` — the file inside the git root this
session is pointed at, not any file outside that repo. This section
describes only how the ux-design role behaves against whatever contract the
work repo carries; it excerpts ux-design's rows for convenience, but the
work repo's copy is what governs. `ux-design-cycle/hooks/state-gate.sh`
refuses handoff-protocol actions when that repo has no
`docs/specs/role-handoff-contract.md` yet, rather than proceeding
silently.

### WAKES-ON

Per contract §3's ux-design row: ux-design wakes on a qa or review outcome
whose content questions the standing acceptance criteria. WAKES-ON is a
trigger condition, not an accept/refuse gate — reading a kind and being
woken by it are different questions (see the next subsection).

### READ / DEPENDS-ON / NEVER-OVERWRITE

Per contract §4's three questions, at ux-design's grain:

- **READ: broad, unconditional.** `ux-design` may read any board record for
  context, including `build-proposal`, `qa-record`, `review-record`, and
  `ops-record` — none of these are refused reading, unlike v1's Refuses
  list.
- **DEPENDS-ON: narrow.** ux-design depends on `hypothesis` and
  `product-record` — the accepted problem framing its screens/flows
  answer — contract §4's own ux-design bullet, verbatim. This is the one
  dependency contract §4 explicitly assigns ux-design.
- **NEVER-OVERWRITE.** ux-design writes only
  `docs/reports/records/<subject>/ux-design.md` (`kind: ux-design-record`)
  — contract §11's ux-design row, verbatim. Unlike product, ux-design owns
  no slot under `docs/proposals/` and no standing doc; its entire
  write-owned surface is this one record path per subject.

### Where upstream lives

- `feasibility-record` is read from
  `docs/reports/records/<subject>/feasibility.md` in the target repo.

The user hands over only a pointer ("it's here"); this path is what lets
`ux-design` resolve that pointer on its own, without asking.

### Blackboard record shapes

Per contract §2's table and §7, `ux-design` owns one kind:

- **`ux-design-record`** at `docs/reports/records/<subject>/ux-design.md`.
  `loop_state` vocabulary: `idle,drafting,reviewed`. Required fields
  beyond the common header: a pointer to the governing `hypothesis`/
  `product-record`, plus screen/flow/wireframe specs or pointers to them.
  Reaching `loop_state: reviewed` is what wakes coding, per contract §3's
  ux-design row and coding's own row. This contract entry enforces
  structure only — that the record exists per subject, points at its
  governing hypothesis/product-record, and reaches `reviewed` before
  coding wakes — not what makes the design underneath it good; that stays
  ux-design's own judgment (contract §4's ux-design DEPENDS-ON bullet).

### Finding participation

Per contract §5: `ux-design` may both produce and receive `finding` blocks
(generalized in v2 from v1's review-only findings). When `ux-design` closes
out a `finding` addressed to it, `ux-design.md` (the `ux-design-record`) must
carry a `finding-response` entry with all three required parts: the
finding reference (record path + finding identifier), the action taken or
decline reason, and — when applicable — proof of the fix. An entry
missing any of the three parts does not close the finding.

### Loop termination

Per contract §6: a wake is consumed only by writing the resulting record
entry — a `loop_state` change, a new `finding`, a `finding-response`, or
equivalent. An unchanged board wakes no one.

### Minting `subject` (contract §9)

Any role may open a chain, not only `ux-design` — "not only ux-design...
deterministic regardless of which role does it." Before minting a new
`subject`, search `docs/reports/records/*/` and `docs/proposals/*` for an
existing `subject` describing the same work and adopt it verbatim if
found, rather than assuming `ux-design` is always the chain-opener.

### Stops

- **Upstream stale at role entry — contract §12.** Before acting on a
  handed-over `feasibility-record`, `ux-design` compares the recorded `sha`
  in its `upstream` entry against the current commit that touched that
  path. On first read of an `upstream` entry, this always prompts the
  user once. On a later re-entry, if the current sha matches the recorded
  `acknowledged_sha`, it does not re-prompt. A sha matching neither `sha`
  nor `acknowledged_sha` re-fires the full prompt — the gate does not
  decide "proceed" or "re-confirm" itself, it asks.
- **A record already exists at a path `ux-design` does not own.** If
  `ux-design`, in the course of its work, finds an existing record already
  present under `docs/reports/records/` or at a `docs/proposals/`
  filename it does not own (including a `<date>-build-<slug>.md` slot
  tagged as coding's), it refuses to write there and reports the
  conflict — the path, and whose territory it falls in — to the user. It
  never overwrites or merges into it silently.

## Install

```
curl -fsSL https://raw.githubusercontent.com/tokenmaxxxer/ux-design-rulebook/main/install.sh | bash
```

This registers the `tokenmaxxxer-ux-design` marketplace and installs the
`ux-design-agent-env` bundle plus `ux-design-cycle` at **user scope**. It
applies to your account on every machine-local session; it does not travel
with a repo and does not reach Claude Code on the web or Slack cloud
sessions. It names only this repository and its own marketplace — nothing
else in the `tokenmaxxxer` org is touched or referenced.

The script prefers a real `claude` CLI (standalone, or the binary bundled
inside the VSCode extension) if it finds one, and runs `plugin install
<name>@tokenmaxxxer-ux-design --scope user` for `ux-design-cycle` and the
bundle, then updates each to the marketplace's latest. If no `claude`
binary is found — or `TOKENMAXXXER_SETTINGS_ONLY=1` is set to force it —
the script falls back to writing `~/.claude/settings.json` directly: it
resolves and prefix-checks the settings path against your home directory
before writing, aborts untouched on a parse failure of an existing file,
backs up before writing, and follows a symlink rather than replacing it.

Or, from any Claude Code session, the equivalent by hand:

```
/plugin marketplace add tokenmaxxxer/ux-design-rulebook
/plugin install ux-design-agent-env@tokenmaxxxer-ux-design
```

`install.sh --help` prints usage. The only other input it reads is the
`TOKENMAXXXER_SETTINGS_ONLY=1` environment variable described above.

## Writing the settings by hand

```json
{
  "extraKnownMarketplaces": {
    "tokenmaxxxer-ux-design": {
      "source": { "source": "github", "repo": "tokenmaxxxer/ux-design-rulebook" }
    }
  },
  "enabledPlugins": {
    "ux-design-agent-env@tokenmaxxxer-ux-design": true
  }
}
```

## Repo layout

- `install.sh` — the one-shot installer described above.
- `.claude-plugin/marketplace.json` — the marketplace manifest (name
  `tokenmaxxxer-ux-design`), listing `ux-design-cycle` and `ux-design-agent-env`,
  both `./`-relative to this repository.
- `ux-design-cycle/` — the role plugin: `.claude-plugin/plugin.json`, two
  hooks (`hooks/hooks.json`, `hooks/capture-approval.sh`,
  `hooks/state-gate.sh`), and `skills/hypothesis-testing/`.
- `ux-design-agent-env/` — the bundle plugin: `.claude-plugin/plugin.json`
  only, no code of its own, listing `ux-design-cycle` as its dependency.
- `docs/` — six lifetime buckets (`decisions/`, `handbooks/`, `reports/`,
  `specs/`, `proposals/`, `_assets/`), each with a placeholder if empty.
  `docs/specs/state-machine.md` is the authoritative state-machine spec for
  this repository.

## Self-contained by design

This repository is independently installable into its own sandbox: no
shared code, no cross-repository dependency, no shared file, index, or
ledger with `coding-agent-rulebook`, `qa-agent-rulebook`, or any sibling
role repository (`feasibility-agent-rulebook`, `review-agent-rulebook`,
`ops-agent-rulebook`). Nothing in this repository names or reads another
repository at runtime.
