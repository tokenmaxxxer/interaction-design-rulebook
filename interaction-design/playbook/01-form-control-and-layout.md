# Playbook: form controls, grouping, navigation, contrast (issue-1174 batch 1)

Each `## R<n>` heading below is one condition -> choice -> source
decision rule. REMOVAL rules mark a pattern to actively strip when
found, not merely avoid adding.

## R1 — control type by option count (small sets)
When a single-select field has 2-4 mutually exclusive options that each
fit on one line, use radio buttons instead of a dropdown: all options
are visible with a single click/tap, matching interaction cost to the
option count. Counter-example: if any of those 2-4 labels runs over
~40 characters (e.g. long policy text), radios wrap and break
scannability — apply R2's dropdown choice instead even though the count
is small. Source: https://www.nngroup.com/articles/checkboxes-vs-radio-buttons/

## R2 — control type by option count (large sets)
When a single-select field has 5 or more options, or the layout is
space-constrained (mobile viewport, dense table row), choose a
dropdown/listbox over an expanded radio group to trade one extra click
for vertical space. Counter-example: if the user must compare all
options side by side before choosing (e.g. pricing tiers), keep them
expanded as cards/radios — the comparison need outweighs the space
saving. Source: https://www.nngroup.com/articles/listbox-dropdown/

## R3 — field grouping by proximity, not by column
When a form has fields that are semantically related (first/last name,
city/state/zip), place related fields with tighter spacing than the gap
between unrelated groups, and prefer a single-column layout by default,
per the Gestalt proximity principle: closeness reads as relatedness, and
multi-column layouts break the single top-to-bottom scan path. Choose a
same-row layout only for atomic pairs (e.g. width x height). Counter-example: a
short, tightly-coupled numeric pair on one row is correct to keep in a
row — this rule bans arbitrary multi-column grids for UNRELATED fields,
not all horizontal grouping. Source: https://www.nngroup.com/articles/gestalt-proximity/
Source: https://www.nngroup.com/articles/form-design-white-space/

## R4 — navigation depth vs. breadth
When a site/app has more than 50 reachable destinations under one
top-level entry, choose a flatter, wider structure (a mega menu exposing
the second tier directly, capped around 28-36 links surfaced at once)
over deep nested drill-down menus, because users scan a fully visible
option set faster than they navigate multi-level hover/click chains.
Counter-example: under 15 destinations, or destinations that are
themselves deeply hierarchical data (a file tree) — flattening removes
structure the user needs, so keep nested navigation and add breadcrumbs
instead. Source: https://www.nngroup.com/articles/mega-menus-work-well/

## R5 — text contrast floor
When any text conveys information (excluding decorative text, logo
text, and disabled/inactive-state text), apply a minimum contrast ratio
of 4.5:1 against its background for text under 18pt (24px) / 14pt-bold
(18.66px), or 3:1 if the text is at or above that large-text threshold —
per WCAG 2.1 SC 1.4.3, the numeric floor this role's spec names but does
not itself tabulate. Counter-example: disabled controls are explicitly
exempt under the same criterion; do not force the 4.5:1 floor onto
disabled-state text, since that would falsely imply interactivity.
Source: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
Source: https://webaim.org/articles/contrast/

## R6 — non-text (icon/control-boundary) contrast floor
When a graphical UI component boundary or a meaning-carrying icon/graph
line is not covered by R5's text rule, apply a minimum contrast ratio of
3:1 against adjacent colors, per WCAG 2.1 SC 1.4.11 — a separate, lower
floor than text because non-text shapes rely on edge perception rather
than glyph recognition. Counter-example: purely decorative icons with no
informational role are exempt; applying 3:1 there is scope creep past
what the criterion requires. Source: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html

## R7 — REMOVAL: modal used for non-blocking or mid-task content
When an existing modal interrupts an in-progress task with unrelated
content (newsletter signup, NPS survey, feature announcement), gates
access to content the user already navigated to with intent (an
article), or stacks a second modal on an open one, remove the modal:
replace mid-task interruptions with an inline non-blocking toast/banner,
drop the content gate entirely, and collapse stacked modals into one
sequential flow. Doing this avoids training users to reflexively dismiss
modals, which degrades the signal value of the ones that matter, and
avoids the broken screen-reader focus order stacked modals cause.
Counter-example: keep a modal that confirms a destructive, irreversible
action (delete account) mid-flow — that IS the important information the
current task depends on, so do not remove confirmation modals under this
rule. Source: https://www.nngroup.com/articles/modal-nonmodal-dialog/
Source: https://www.nngroup.com/articles/popups/

## R8 — semantic token reference by default, even pre-design-system
When any spec element carries a visual value covered by R5/R6 (a
contrast-bearing color, a spacing/type value), name the semantic token
that value maps to (e.g. `color.border.critical`, `space.stack.sm`)
rather than the raw value, even on a project where no design-system
document exists yet: name the semantic role a future token is expected
to fill and flag that reference as provisional. Doing this keeps the
spec reviewable as token-shaped from the first draft instead of
producing a raw-value spec that has to be retrofitted once a token
document lands. Counter-example: a one-off illustrative mockup value
explicitly marked as non-shipping placeholder content is exempt — this
rule targets values coding is expected to implement.

## Rule table (condition -> choice, quick reference)
R1: 2-4 short options -> radio buttons. R2: 5+ options or tight space ->
dropdown/listbox. R3: related fields -> tight proximity, single column
default. R4: >50 destinations, flat-friendly content -> wide/flat nav
(mega menu). R5: any informational text -> >=4.5:1 (>=3:1 if large). R6:
meaningful icon/control boundary -> >=3:1. R7: modal on
non-critical/mid-task/stacked content -> remove, replace inline. R8: any
R5/R6-covered value -> name its semantic token, provisional if
pre-design-system.

## Provenance
Research method: web-verified per rule, THOROUGH tier per issue #1174
req #2; each rule's source(s) fetched via WebSearch on 2026-08-13, see
docs/issue-1174/reports/interaction-design/2026-08-13-playbook-evidence.md
in the on-the-record repo for the query/source log. Scope: batch 1
partial (form controls, grouping, navigation depth, contrast floor, one
removal rule) — not a claim of full coverage against issue #1174's
N-per-role target; color-combination visibility beyond contrast,
usage-frequency-to-menu-depth beyond R4, and background/editing-surface
separation remain open for a follow-up batch in this same rulebook.
