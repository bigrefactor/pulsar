# Alert · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/alert.ex`](../../lib/pulsar/components/alert.ex)
**Tests:** [`test/pulsar/components/alert_test.exs`](../../test/pulsar/components/alert_test.exs)
**Audited:** 2026-06-05 (code-only + browser measurement)

Inline banner for in-content status messages. Renders a styled `<div>` with an
optional leading status icon, title, body text, right-aligned action buttons,
and an optional dismiss button. Static by default; opt-in `role="alert"` or
`role="status"` for dynamically inserted banners.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The leading status icon is rendered via `<Icon.icon>` which
defaults to `aria-hidden="true"` (decorative) —
`lib/pulsar/components/alert.ex:170`. The dismiss `<button>` carries a
visible icon also marked decorative; the button's accessible name comes
from `aria-label` — `lib/pulsar/components/alert.ex:185`. No informational
non-text content lacks a text alternative.

**Notes:** `icon={false}` suppresses the icon entirely; `icon="hero-..."` lets
callers override it. In all cases the text content (title/description) is the
primary communication channel.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Title renders as `<p class="font-semibold ...">` —
`lib/pulsar/components/alert.ex:172`. Body text is a sibling `<p>` or a
`<div>` for rich inner_block content — `lib/pulsar/components/alert.ex:173–174`.
Actions are wrapped in a `<div>` that contains real `<button>` elements —
`lib/pulsar/components/alert.ex:177–179`. The dismiss control is a native
`<button>` — `lib/pulsar/components/alert.ex:181–196`. All semantic
relationships are expressed in markup, not implied by visual layout alone.

**Notes:** The component does not use heading elements for the title by design
(an alert banner is inline content, not a page section). The title's role is
conveyed via proximity and weight, which is acceptable for a banner pattern.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order: icon → content (title, description) → actions →
dismiss — `lib/pulsar/components/alert.ex:169–197`. Reading order matches
visual order; no CSS reorders content.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** Status is conveyed by icon + text, not color alone (see 1.4.1).
No instruction given to the user relies solely on shape, size, or position.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Each color has a distinct auto-selected status icon (check-circle
for success, x-circle for danger, exclamation-triangle for warning, information-
circle for all others) — `lib/pulsar/components/alert.ex:234–237`. The type of
message is indicated by both icon and text content, never by color alone.

**Notes:** `icon={false}` suppresses the icon at the caller's discretion.
Callers who suppress the icon for color-only designs introduce a 1.4.1 gap at
the call site, not in the component.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Browser measurement of 27 cells × 2 themes:

- **solid** variant: all 7 colors pass in light (min 7.22:1) and dark (min 4.84:1).
- **outline** variant: all 7 colors pass in light (min 5.89:1) and dark (min 7.06:1).
- **ghost** variant: all 7 colors pass in both themes. `info` measures **5.88:1** in
  light and **8.16:1** in dark — `lib/pulsar/components/alert.ex:65`. All other
  ghost colors pass in both themes.
- **Size cells** (all default to `color="info"`, `variant="ghost"`): pass in light
  at 5.88:1 and in dark at 8.16:1.

**Axe gate:** Zero `color-contrast` violations in both light and dark themes.

Full measurements: [light](measurements/alert-light.md) · [dark](measurements/alert-dark.md).

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All sizing uses `rem`-based Tailwind tokens (`text-sm`, `text-base`,
`text-lg`, `p-2`, `p-3`, `p-4`) — `lib/pulsar/components/alert.ex:53–55`. No fixed
`px` font sizes. The component scales with the user's root font size.

### 1.4.5 Images of Text (AA) — N/A

No images of text. Icons are inline SVG, not raster images.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The container is `flex items-center` with no `min-width` or
`overflow: hidden` constraint — `lib/pulsar/components/alert.ex:58, 169`. Text
wraps naturally. Measurement: no cells overflow at 320 CSS px
([light](measurements/alert-light.md) · [dark](measurements/alert-dark.md)).

**Notes:** The fixture page itself reports horizontal page overflow at 320 px —
this is the fixture scaffold's padding, not the component.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The `outline` variant renders `border border-{color}` —
`lib/pulsar/components/alert.ex:73–79`. Measured border contrast: light min
5.64:1 (outline-secondary), dark min 3.67:1 (outline-neutral) — all clear the 3:1
threshold. `solid` and `ghost` variants have no border by design. The dismiss
button focus ring is `focus-visible:ring-2 focus-visible:ring-current
focus-visible:ring-offset-2` — `lib/pulsar/components/alert.ex:219`. Focus ring
is `ring-current`, inheriting the alert's semantic color, which passes 3:1 on its
own tinted/solid surface across all measured variants.

Full measurements: [light](measurements/alert-light.md) · [dark](measurements/alert-dark.md).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed `line-height` or `letter-spacing` overrides; text spacing
inherits from the page. Measurement: no cells overflow under the text-spacing
override ([light](measurements/alert-light.md) · [dark](measurements/alert-dark.md)).

### 1.4.13 Content on Hover or Focus (AA) — N/A

The alert is static inline content; no hover/focus-revealed overlay.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The dismiss button is a native `<button type="button">` —
`lib/pulsar/components/alert.ex:181–183`. It is in the natural tab order,
activatable by Space and Enter with native browser behavior. The action slot
accepts caller-supplied controls; the fixture uses a native `<button>`. No
custom keyboard handling is required.

**Notes:** Non-dismissible alerts have no interactive elements and require no
keyboard support.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The alert renders as a static `<div>` with no focus management.
The dismiss button is a standard focusable element with no trap logic.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** DOM order is icon → content → actions → dismiss —
`lib/pulsar/components/alert.ex:169–197`. No positive `tabindex` is used.
Focus visits controls in logical left-to-right, reading order.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The dismiss button carries `focus-visible:ring-2
focus-visible:ring-current focus-visible:ring-offset-2` —
`lib/pulsar/components/alert.ex:219`. `ring-current` inherits the alert
color, which passes 3:1 non-text contrast against its own surface.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The alert creates no sticky or absolutely-positioned layer that
would obscure focused siblings. It is static in-flow content.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The dismiss button is a native `<button>` with a `phx-click`
handler, which fires on the `click` event (mouseup) —
`lib/pulsar/components/alert.ex:187`. No down-event activation.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** The dismiss button has no visible text label; its accessible name
is `aria-label={@dismiss_label}` (default "Dismiss") —
`lib/pulsar/components/alert.ex:185`. No visible text label to conflict with.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The close button is sized at `h-6 w-6` = 24×24 CSS px across all
three alert sizes, with only the inner icon padding varying (`p-1.5` / `p-1` /
`p-0.5`) — `lib/pulsar/components/alert.ex:53–55`. 24×24 meets the WCAG 2.5.8
minimum exactly. Measurement confirms: dismissible cell height 72 px ≥ 24 px
([light](measurements/alert-light.md)).

**Notes:** The close button comment at `lib/pulsar/components/alert.ex:50–51`
explicitly documents this invariant.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the dismiss button triggers no context change — it is a
plain button with no focus handler.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**
- The container `<div>` exposes `role={@role}` (nil by default; callers opt in
  to `"alert"` or `"status"`) — `lib/pulsar/components/alert.ex:169`.
- The dismiss button carries `aria-label={@dismiss_label}` and
  `aria-controls={@id}` — `lib/pulsar/components/alert.ex:185–186`.
- The status icon is decorative (`aria-hidden` via Icon default) —
  `lib/pulsar/components/alert.ex:170`.
- `@rest` forwards `id`, `data-*`, and any additional ARIA attributes —
  `lib/pulsar/components/alert.ex:169`.

**Notes:** Callers that show the alert dynamically should set
`role="alert"` (assertive) or `role="status"` (polite) to announce it. The
opt-in design avoids assertive interruptions for static banners.

### 4.1.3 Status Messages (AA) — ✓ PASS (opt-in)

**Evidence:** When `role="alert"` or `role="status"` is set, the component is
a live region that announces its content to assistive technology. The opt-in
is documented on the `role` attribute —
`lib/pulsar/components/alert.ex:133–138`. Static banners (the default) do not
need a live region role.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts.
- **2.2.1 Timing Adjustable (A)** — no auto-dismissal timer.
- **2.2.2 Pause, Stop, Hide (A)** — no moving or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing; the dismiss
  opacity transition is a brief fade, well below 3 Hz.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — the alert title is a `<p>`, not a
  heading. No form labels.
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

## Browser a11y findings

The axe-core browser gate reports **zero violations** in both light and dark
themes. All 27 cells pass in both themes; the minimum text contrast across all
cells is 5.88:1 (ghost-info, light) and 8.16:1 (ghost-info, dark).

Measurement detail: [light](measurements/alert-light.md) ·
[dark](measurements/alert-dark.md).
