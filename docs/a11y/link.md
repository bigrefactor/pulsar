# Link · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/link.ex`](../../lib/pulsar/components/link.ex)
**Tests:** [`test/pulsar/components/link_test.exs`](../../test/pulsar/components/link_test.exs)
**Audited:** 2026-05-24 (code-only)

Accessible link component wrapping Phoenix `<.link>` — supports
href/navigate/patch navigation with semantic variants, automatic
external-link security (rel/target), XSS protection on `href`, optional
start/end icons, and a trailing icon for new-tab links.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:**
- Start/end icon slot wrapper applies `aria-hidden="true"` —
  `lib/pulsar/components/link.ex:116–122`
- External-link indicator icon is `aria-hidden="true"` —
  `lib/pulsar/components/link.ex:124–134`
- `aria_label` attr supported for cases where visible text needs
  augmentation — `lib/pulsar/components/link.ex:70`

**Notes:** Decorative icons (caller-provided in slots and the built-in
new-tab indicator) are correctly hidden from AT; the link's accessible
name comes from `inner_block` text or `aria_label`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:**
- Renders Phoenix `<.link>`, which emits a native `<a>` element —
  `lib/pulsar/components/link.ex:88–113`
- `aria-current` pass-through allows callers to mark the current page
  in a nav — `lib/pulsar/components/link.ex:72, 102`
- Test `supports aria-current attribute` —
  `test/pulsar/components/link_test.exs:573–582`

**Notes:** Native `<a href>` semantics are preserved; navigation type
(redirect/patch) is exposed via `data-phx-link` attributes from Phoenix.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Slots render in DOM order: `start_icon`, inner_block,
external icon, `end_icon` — `lib/pulsar/components/link.ex:108–111`.

**Notes:** No `flex-direction: row-reverse` or absolute positioning;
visual order matches DOM order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** External links combine visual icon + `target="_blank"` +
`data-external="true"` data attribute — `lib/pulsar/components/link.ex:103, 124–134, 252–272`.

**Notes:** External-link cue is not color-only; the new-tab icon and
data attribute provide non-visual signals alongside any color
distinction.

### 1.4.1 Use of Color (A) — ⚠ GAP (minor) — caller-driven choice

**Evidence:** Solid variant (default) renders `no-underline` with only
color distinguishing links from surrounding text —
`lib/pulsar/components/link.ex:297`. Ghost and outline variants pair
color with a `border-b-2` underline-equivalent —
`lib/pulsar/components/link.ex:294–298`. Browser measurement: the
link fixture exercises link text against the page background, not
inline against body copy. Per-color light measurements: link text
ranges 3.06:1 to 19.27:1 vs the page bg. For the inline-body
3:1-against-text technique, primary/danger/info colors pass against
default foreground; success/warning are borderline.

**Notes:** Component-level fix not appropriate — the default `solid`
variant works for high-contrast colors; callers should choose
`ghost` or `outline` (which carry a visible underline-equivalent)
for body-copy links. Document in usage notes; not filed as a
sub-issue.

### 1.4.3 Contrast (Minimum) (AA) — ⚠ GAP (serious)

**Evidence:** Colors come from semantic tokens
(`text-primary`, `text-danger`, dark-mode pairs, etc.) —
`lib/pulsar/components/link.ex:300–310`. Hover state uses `/80`
opacity on the same token. Browser measurement of 97 cells per theme
([light](measurements/link-light.md),
[dark](measurements/link-dark.md)):

- **Dark:** all 97 pass (min 6.14:1).
- **Light:** 65/97 pass (min 3.06:1). Failing variants × colors:
  ghost/link/outline/solid in `success`, `warning` colors; plus
  `solid-success` and `solid-warning`.

**Notes:** Originally scoped to "light: success/warning/error solid;
dark: primary/success solid"; the failure set extends to all
ghost/outline/link variants in success/warning colors — same
upstream token fix applies to text everywhere.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Size classes use rem-based Tailwind text utilities
(`text-xs`, `text-sm`, `text-base`, `text-lg`, `text-xl`) and the
default `inherit` adopts the parent — `lib/pulsar/components/link.ex:312–319`.

**Notes:** No fixed-pixel font sizes; all sizing scales with root font
size.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` layout with no `min-width` or fixed widths —
`lib/pulsar/components/link.ex:289`.

**Notes:** Link width is content-driven; reflows at 320 CSS px without
horizontal scroll.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** Focus ring is `ring-2 ring-ring` with `ring-offset-2` —
`lib/pulsar/components/link.ex:288–292`. Ghost/outline variants use
`border-b-2 border-current` — `lib/pulsar/components/link.ex:295–296`.
Browser measurement: focus ring measures 5.02:1 (light) / 6.72:1
(dark) across every color variant — matches Button at full opacity.

**Notes:** Previously failed at 2.16:1 / 2.63:1 because of a `/50`
(50% alpha) modifier on the ring color. Resolved by dropping the
opacity modifier.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights or `!important` on text spacing
properties; only inline-flex layout and text-size utilities —
`lib/pulsar/components/link.ex:288–292, 312–319`.

**Notes:** Inherits page line-height/spacing; adapts cleanly under
user-overridden spacing.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** Native `<a href>` is keyboard-operable by default; the
component delegates to Phoenix `<.link>` which renders a real anchor —
`lib/pulsar/components/link.ex:89–112`.

**Notes:** Standard Tab to focus, Enter to activate; no custom JS
handling needed.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** No `keydown` handlers in the component —
`lib/pulsar/components/link.ex:88–113`. Tab/Shift+Tab pass through
unimpeded.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** Only animation is a `transition-all duration-200`
color/border transition on hover —
`lib/pulsar/components/link.ex:289`. No auto-playing motion.

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** Only animations are smooth color/border transitions on
hover — `lib/pulsar/components/link.ex:289`. No flashing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** Native `<a>` participates in tab order by default; no
positive `tabindex` set — `lib/pulsar/components/link.ex:88–113`.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** `inner_block` slot is `required: true` —
`lib/pulsar/components/link.ex:77`. `aria_label` available for
supplemental context — `lib/pulsar/components/link.ex:70`.

**Notes:** Component enforces presence of link text; caller is
responsible for descriptive content (avoid "click here" patterns).

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** `inner_block` required (visible label); `aria_label`
available as supplemental — `lib/pulsar/components/link.ex:70, 77`.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:**
- Base classes include `focus-visible:outline-none`,
  `focus-visible:ring-2`, `focus-visible:ring-ring`,
  `focus-visible:ring-offset-2` —
  `lib/pulsar/components/link.ex:288–292`
- Tests assert focus ring classes —
  `test/pulsar/components/link_test.exs:538–549`

Ring measures 5.02:1 (light) / 6.72:1 (dark) against the adjacent
background — passes the 3:1 non-text minimum.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Link doesn't create sticky/overlapping content —
single-element render via Phoenix `<.link>` —
`lib/pulsar/components/link.ex:88–113`.

**Notes:** Page-level concern when links are used in sticky headers;
not a component-level gap.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** Native `<a>` activates on `click` (mouseup); no custom
mousedown handler — `lib/pulsar/components/link.ex:88–113`.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** `aria_label` is optional and documented as "Accessible
label for the link" — `lib/pulsar/components/link.ex:70`. Default
accessible name is the visible `inner_block` text.

**Notes:** Callers can set `aria_label` that conflicts with visible
text; out of library control. Default behavior passes.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Component renders inline (`inline-flex`) and inherits
size from context — `lib/pulsar/components/link.ex:289, 312–319`.

**Notes:** WCAG 2.5.8 explicitly exempts inline links in a sentence /
block of text. Links rendered standalone (e.g., as a nav button) depend
on the parent's text size; size `xs` (text-xs ≈ 12px) at default
line-height gives ≈16px target height, below the 24px floor for
non-inline use. Acceptable for inline use; callers building standalone
link buttons should prefer the button component (with `variant="link"`)
which has guaranteed tap-target sizing.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** No `phx-focus` or focus-triggered context change in
component template — `lib/pulsar/components/link.ex:88–113`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- Native `<a>` has implicit `link` role —
  `lib/pulsar/components/link.ex:88–113`
- Properties: `aria-label`, `aria-describedby`, `aria-current` —
  `lib/pulsar/components/link.ex:100–102`
- External-link security: auto-adds `rel="noopener noreferrer"` when
  `target="_blank"` — `lib/pulsar/components/link.ex:254–272`
- XSS protection: dangerous schemes (`javascript:`, `data:`,
  `vbscript:`, `about:`, `file:`) replaced with `#` —
  `lib/pulsar/components/link.ex:222–236`
- Tests assert aria-label, aria-describedby, aria-current —
  `test/pulsar/components/link_test.exs:551–582`
- Tests assert `rel="noopener noreferrer"` and `target="_blank"` for
  external — `test/pulsar/components/link_test.exs:247–306`

**Notes:** Comprehensive coverage. The `apply_external_security` helper
prevents tabnabbing on external links; `sanitize_href` neutralizes
script-injection vectors before render.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** Link is not a stateful component; `aria-current` is the
only status-like attribute and is correctly pass-through —
`lib/pulsar/components/link.ex:72, 102`.

**Notes:** No loading or busy state to expose.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images.
- **1.4.13 Content on Hover or Focus (AA)** — no tooltip or popover.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts registered.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — no multipoint or path gestures.
- **2.5.4 Motion Actuation (A)** — no motion-triggered functionality.
- **2.5.7 Dragging Movements (AA, new in 2.2)** — no drag.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.2 On Input (A)** — not a form input.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page-level concern.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.1 Error Identification (A)** — not a form input.
- **3.3.2 Labels or Instructions (A)** — not a form input.
- **3.3.3 Error Suggestion (AA)** — not a form input.
- **3.3.4 Error Prevention (AA)** — not a form input.
- **3.3.7 Redundant Entry (A, new in 2.2)** — not a form input.
- **3.3.8 Accessible Authentication (AA, new in 2.2)** — not authentication.

## AAA wins (bonus)

- **2.4.9 Link Purpose (Link Only) (AAA)** — `inner_block` is
  `required: true` (`lib/pulsar/components/link.ex:77`), so every link
  has text content. The component enforces presence; "Link Only"
  quality depends on the caller's text, but the API design supports it
  by not allowing icon-only links without explicit `aria_label`.
- **2.4.13 Focus Appearance (AAA, new in 2.2)** — focus ring uses
  `ring-2` (2px) with `ring-offset-2`, meeting the AAA minimum
  thickness. Browser-measured contrast (5.02:1 light / 6.72:1 dark)
  exceeds the AAA 4.5:1 requirement.

## Browser a11y findings

Violations surfaced by the axe-core browser gate.

| Rule | Affected variant(s) | Themes |
|------|---------------------|--------|
| `color-contrast` | light: success/warning/error solid; dark: primary/success solid | both |
