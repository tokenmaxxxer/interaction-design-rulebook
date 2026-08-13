# Playbook: form controls, grouping, navigation, contrast (issue-1174 batch 1)

Numbered condition -> choice -> source rules. REMOVAL rules mark a
pattern to actively strip when found, not merely avoid adding.

## R1 — control type by option count
- condition: single-select field, 2-4 mutually exclusive options, all
  short enough to fit one line each
  choice: radio buttons (all options visible, one click/tap)
  why: forces zero extra interaction to see the choice set; matches the
  decision cost to the option count
  counter-example: 3 options but each label >40 chars (e.g. long policy
  text) -> radios wrap and break scannability; use dropdown instead
  source: https://www.nngroup.com/articles/checkboxes-vs-radio-buttons/

## R2 — control type by option count (large sets)
- condition: single-select field, >=5 options, OR screen space is
  constrained (mobile viewport, dense table row)
  choice: dropdown/listbox, not radio group
  why: radios at 5+ options consume vertical space disproportionate to
  their scan value; dropdown trades one extra click for space
  counter-example: 5 options but user must compare all options
  side-by-side before choosing (e.g. plan tiers) -> keep them expanded
  (cards/radios), the comparison need outweighs the space cost
  source: https://www.nngroup.com/articles/listbox-dropdown/

## R3 — field grouping by proximity, not by column
- condition: a form has fields that are semantically related (e.g.
  first/last name, city/state/zip)
  choice: place related fields with tighter spacing than the spacing
  between unrelated groups; default to single-column layout unless a
  pair is truly atomic (e.g. city/state/zip on one row)
  why: Gestalt proximity makes users read spatial closeness as semantic
  relatedness; multi-column layouts break the single top-to-bottom scan
  path and increase misreads of which label belongs to which input
  counter-example: short, tightly-coupled numeric pairs (e.g.
  width x height) where a single row reads as one unit -> row layout is
  correct there; the rule is about avoiding arbitrary multi-column grids
  for unrelated fields, not banning all horizontal grouping
  source: https://www.nngroup.com/articles/gestalt-proximity/
  source: https://www.nngroup.com/articles/form-design-white-space/

## R4 — navigation depth vs. breadth
- condition: site/app has >50 reachable destinations under one top-level
  entry
  choice: prefer a flatter, wider structure (e.g. a mega menu exposing
  the second tier directly) over deep nested drill-down menus, capped at
  roughly 28-36 links surfaced at once
  why: users scan a fully visible option set faster than they navigate
  multi-level hover/click chains, and flat structure reduces the memory
  load of tracking where they are
  counter-example: <15 destinations total, or the destinations are
  themselves deeply hierarchical data (e.g. a file tree) -> flattening
  removes structure the user needs; keep nested navigation and instead
  invest in breadcrumbs
  source: https://www.nngroup.com/articles/mega-menus-work-well/

## R5 — text contrast floor
- condition: any text conveying information (not decorative, not part of
  a logo, not disabled-state text)
  choice: minimum contrast ratio 4.5:1 against its background for text
  under 18pt (24px)/14pt-bold (18.66px); 3:1 is acceptable only at or
  above that large-text threshold
  why: WCAG 2.1 SC 1.4.3, AA conformance floor already named in this
  role's spec — this rule gives the numeric decision table the spec
  points at but does not itself state
  counter-example: disabled/inactive controls are explicitly exempted by
  the same criterion — do not apply the 4.5:1 floor to disabled-state
  text, it would force a false sense of interactivity
  source: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
  source: https://webaim.org/articles/contrast/

## R6 — non-text (icon/control-boundary) contrast floor
- condition: a graphical UI component boundary or a meaning-carrying
  icon/graph line, not covered by R5's text rule
  choice: minimum contrast ratio 3:1 against adjacent colors
  why: WCAG 2.1 SC 1.4.11 — a separate, lower floor than text because
  non-text shapes rely on boundary/edge perception rather than glyph
  recognition
  counter-example: purely decorative icons with no informational role
  (e.g. a background flourish) are exempt — applying 3:1 there is scope
  creep past what the criterion requires
  source: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html

## R7 — REMOVAL: modal used for non-blocking or mid-task content
- condition: an existing modal (a) interrupts an in-progress task with
  content unrelated to completing that task (newsletter signup, NPS
  survey, feature announcement), or (b) gates access to content the user
  already navigated to with intent (e.g. an article), or (c) stacks a
  second modal on top of an open one
  choice: REMOVE the modal; replace with an inline/non-blocking
  notification (toast, banner) for (a), remove the gate entirely for
  (b), and collapse stacked modals into a single sequential flow for (c)
  why: modals used for anything less than genuinely important,
  attention-requiring information train users to reflexively dismiss all
  modals, degrading the signal value of the ones that actually matter;
  stacked modals break screen-reader focus order
  counter-example: a modal confirming a destructive, irreversible action
  (delete account) mid-flow is correct to keep — it IS the important
  information the user's current task depends on; do not strip
  confirmation modals under this rule
  source: https://www.nngroup.com/articles/modal-nonmodal-dialog/
  source: https://www.nngroup.com/articles/popups/

## Rule table (condition -> choice, quick reference)

| condition | choice | rule |
|---|---|---|
| 2-4 short options | radio buttons | R1 |
| 5+ options or tight space | dropdown/listbox | R2 |
| related fields | tight proximity, single column default | R3 |
| >50 destinations, flat-friendly content | wide/flat nav (mega menu) | R4 |
| any informational text | >=4.5:1 (>=3:1 if large) | R5 |
| meaningful icon/control boundary | >=3:1 | R6 |
| modal on non-critical/mid-task/stacked content | remove, replace inline | R7 |

## Provenance
research method: web-verified per rule, THOROUGH tier per issue #1174
req #2; each rule's source(s) fetched via WebSearch on 2026-08-13.
scope: batch 1 partial (form controls, grouping, navigation depth,
contrast floor, one removal rule) — not a claim of full coverage against
issue #1174's N-per-role target; further rules (color-combination
visibility beyond contrast, usage-frequency-to-menu-depth beyond R4,
background/editing-surface separation) remain open for a follow-up
batch in this same rulebook.
