# Avatar · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/avatar.ex`](../../lib/pulsar/components/avatar.ex)
**Tests:** [`test/pulsar/components/avatar_test.exs`](../../test/pulsar/components/avatar_test.exs)
**Audited:** 2026-06-04 (code-only + browser measurement)

Presentational avatar that renders an `<img>` when `src` is given, falling back
to initials derived from `name`, then to a generic user icon. Renders as a
`<span>` by default, or as a secure link (`<a>`) when `href`/`navigate`/`patch`
is provided. `avatar_group/1` overlaps avatars and appends a `+N` overflow
counter.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** Image avatars carry `alt={alt || name}` —
`lib/pulsar/components/avatar.ex:209`. Initials/icon fallbacks expose the
accessible name on the wrapper via `role="img"` + `aria-label={alt || name}`
(`lib/pulsar/components/avatar.ex:192`), with the visible initials
(`lib/pulsar/components/avatar.ex:215`) and the fallback `<.icon>`
(`lib/pulsar/components/avatar.ex:221`, decorative `aria-hidden="true"` by the
Icon default) hidden so the name is announced once.

**Notes:** Passing `alt=""` opts an avatar out as decorative (empty `alt`, no
wrapper role/label). The accessible-name precedence is `alt || name`
(`lib/pulsar/components/avatar.ex:363`).

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Single inline element per avatar; the group is a flat
`<div>` of avatars plus an optional counter —
`lib/pulsar/components/avatar.ex:276–288`. No implied grouping semantics to
preserve.

**Notes:** Identity is carried by the accessible name, not by structure.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** Group DOM order is the item order followed by the overflow
counter — `lib/pulsar/components/avatar.ex:277–287`. `-space-x-2` overlaps
visually with no `row-reverse` or absolute positioning.

**Notes:** Reading order matches visual order.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** No instruction depends on shape/size/position; the avatar is
identified by its accessible name (`alt`/`name`), not by appearance.

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Identity is conveyed by the image, initials, or name — never by
color alone. The muted fallback surface (`lib/pulsar/components/avatar.ex:80`)
is decorative.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** Fallback initials and the `+N` counter use `text-foreground` on
`bg-muted` (solid) / `bg-background` (outline) —
`lib/pulsar/components/avatar.ex:80–81, 357`. Browser measurement of 39
cells/theme: initials/counter text min **18.3:1 light** / **16.98:1 dark**
([light](measurements/avatar-light.md), [dark](measurements/avatar-dark.md)).

**Notes:** `text-foreground` (not `text-muted-foreground`) is used for the
essential initials so they clear the 4.5:1 minimum by a wide margin in both
themes.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** Box dimensions and initials use `rem`-based Tailwind tokens
(`w-*`/`h-*`/`text-*`) — `lib/pulsar/components/avatar.ex:67–73`. No fixed `px`.

**Notes:** Avatars scale with the user's text-zoom / root font size.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** `inline-flex` with `shrink-0`; no fixed-`px` or `min-width`
constraints — `lib/pulsar/components/avatar.ex:76–77, 89`. The group wraps via
`inline-flex items-center`.

**Notes:** Avatars are fixed-aspect square tokens that reflow at 320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The outline border uses `border-border-strong` against
`bg-background` — `lib/pulsar/components/avatar.ex:81`. The link focus ring is
`focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` —
`lib/pulsar/components/avatar.ex:85–86`. Browser measurement: outline border
min **4.63:1 light** / **6.82:1 dark**; link focus ring **5.02:1 light** /
**4.5:1 dark** — all clear the 3:1 non-text minimum
([light](measurements/avatar-light.md), [dark](measurements/avatar-dark.md)).

**Notes:** Neutral outlines route through `border-border-strong`
(`gray-500`/`gray-400`) per the library convention, not the lighter `border`.
The solid variant has no border by design (it sits on a filled surface).

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** Initials are centered with no fixed line-height override; sizing
is token-based — `lib/pulsar/components/avatar.ex:67–73, 215`.

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** A linked avatar renders through the secure `Link.a` component as a
native `<a>` — `lib/pulsar/components/avatar.ex:162–188`, focusable and
activatable by keyboard. A non-linked avatar is a non-interactive `<span>`.

**Notes:** No custom key handling is needed; native anchor semantics apply.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** The interactive mode is a native `<a>` via `Link.a`
(`lib/pulsar/components/avatar.ex:162–188`); focus moves away normally. The
default mode is a non-interactive `<span>`.

**Notes:** No focus trap is introduced.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** A linked fallback avatar names its anchor with
`aria-label={alt || name}` — `lib/pulsar/components/avatar.ex:173, 390`. A
linked image avatar is named by its `<img alt>` (the link `aria-label` is
suppressed to avoid a double name) — `lib/pulsar/components/avatar.ex:389`. A
linked avatar rendered with no `name`/`alt` (so the anchor would have no
discernible text) logs a `Logger.warning` to flag the missing name —
`lib/pulsar/components/avatar.ex:156, 371–386`.

**Notes:** The destination is described by the entity name. `name` (or `alt`) is
required on linked avatars; omitting it both warns at render time and is covered
by tests (`test/pulsar/components/avatar_test.exs:251–283`).

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The link variant carries `focus-visible:ring-2
focus-visible:ring-ring focus-visible:ring-offset-2` —
`lib/pulsar/components/avatar.ex:85–86, 346`. Measured ring contrast 5.02:1
(light) / 4.5:1 (dark).

**Notes:** Non-linked avatars are not focusable, so no indicator is required.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Avatars do not create sticky or overlapping layers; the group's
`-space-x-2` overlap is a static visual offset that does not cover a focused
sibling's ring (`ring-offset` lifts the ring above neighbours) —
`lib/pulsar/components/avatar.ex:89`.

**Notes:** Page-level stacking is the caller's concern.

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** A linked avatar is a native `<a>`
(`lib/pulsar/components/avatar.ex:162–188`) that activates on the up-event with
no custom down-event handler.

**Notes:** Non-linked avatars have no pointer activation.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** The visible initials are decorative (`aria-hidden`) abbreviations,
not a text label; the accessible name is the full `name`/`alt`
(`lib/pulsar/components/avatar.ex:192, 215`). No mismatch between a visible text
label and the accessible name arises.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** A linked avatar's hit area equals the avatar box. The smallest
size (`xs`) is `w-6 h-6` = 24×24 CSS px — `lib/pulsar/components/avatar.ex:68`.
Browser measurement: every linked cell ≥24×24 (xs exactly 24×24)
([light](measurements/avatar-light.md)).

**Notes:** All larger sizes exceed the floor; the `+N` counter inherits the same
box sizing.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing a linked avatar (`lib/pulsar/components/avatar.ex:162–188`)
triggers no context change — it is a plain anchor with no focus handler.

**Notes:** Activation requires an explicit click/Enter.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** Image avatars are native `<img alt>`
(`lib/pulsar/components/avatar.ex:209`); fallbacks use `role="img"` +
`aria-label` on the wrapper (`lib/pulsar/components/avatar.ex:192`); linked
avatars are native `<a>` named via `aria-label` or the nested `<img alt>`
(`lib/pulsar/components/avatar.ex:162–188`). `@rest` forwards `id`/`data-*`/ARIA
(`lib/pulsar/components/avatar.ex:129, 192`).

**Notes:** Tests confirm role/label resolution and global pass-through —
`test/pulsar/components/avatar_test.exs:98–134, 193, 294`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — not a form input.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — caller-supplied photos are not text; initials are live text, not an image.
- **1.4.13 Content on Hover or Focus (AA)** — no hover/focus-revealed content.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts.
- **2.2.1 Timing Adjustable (A)** — no time limit.
- **2.2.2 Pause, Stop, Hide (A)** — no moving or auto-updating content.
- **2.3.1 Three Flashes or Below Threshold (A)** — no flashing.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.3 Focus Order (A)** — single anchor; order is caller/DOM-driven.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.4.6 Headings and Labels (AA)** — not a heading or form label.
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
- **4.1.3 Status Messages (AA)** — static markup; no status announcements.

## AAA wins (bonus)

- **2.4.13 Focus Appearance (AAA, new in 2.2)** — the link focus ring is `ring-2`
  (2px) with `ring-offset-2`, meeting the AAA minimum thickness; measured ring
  contrast (5.02:1 light / 4.5:1 dark) exceeds the 3:1 requirement.

## Browser a11y findings

The axe-core browser gate reports no violations for the Avatar fixture in either
theme. Measurement detail: [light](measurements/avatar-light.md) ·
[dark](measurements/avatar-dark.md).
