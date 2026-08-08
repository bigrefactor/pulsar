# Dropzone · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/dropzone.ex`](../../lib/pulsar/components/dropzone.ex)
**Tests:** [`test/pulsar/components/dropzone_test.exs`](../../test/pulsar/components/dropzone_test.exs)
**Audited:** 2026-08-07 (code + browser axe gate + keyboard interaction tests)

File-upload dropzone for a LiveView upload configured with
`Phoenix.LiveView.allow_upload/3`.
A `<label>` wraps a sr-only `<.live_file_input>`, so clicking or dragging
files onto the zone and clicking/Enter-Space-activating the native file
input are both first-class paths into the same upload. Per-entry rows
render a preview/type icon, filename, formatted size, a determinate
`Progress.progress` bar, and a cancel `<button>`. During a file drag,
LiveView toggles its built-in `phx-drop-target-active` class on the
`phx-drop-target` root (LiveView 1.2+), which drives a CSS-only swap
between the "Click to upload…" prompt and a "Drop files here" prompt; the
component ships no JavaScript of its own — file selection and cancellation
both go through standard LiveView upload/`phx-click` wiring.

## Applicable criteria

### 1.1.1 Non-text Content (A) — ✓ PASS

**Evidence:** The upload-tray icon (`hero-arrow-up-tray`) and the
non-image document icon (`hero-document`) are decorative and inherit
`Icon`'s `aria-hidden="true"` default. The cancel button's icon
(`hero-x-mark`) is likewise decorative — the button's own `aria-label`
(see 4.1.2) carries its name. Image entry previews use
`<.live_img_preview alt="" .../>`: the filename is rendered as adjacent
visible text, so the empty `alt` doesn't leave the entry unnamed —
`lib/pulsar/components/dropzone.ex`, `dropzone/1`.

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** The zone is a real `<label for={@upload.ref}>` wrapping
`<.live_file_input>`, whose rendered `id` equals `@upload.ref` — a real
label/control association, not just visual proximity
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`). Test
`test "label points at the file input's id"` asserts `for="phx-upload"` /
`id="phx-upload"` — `test/pulsar/components/dropzone_test.exs`. Entries
render as a semantic `<ul>`/`<li>` list (`dropzone/1`). The optional hint
is wired via `aria-describedby` (`dropzone/1`); test
`test "hint renders and is wired via aria-describedby"` —
`test/pulsar/components/dropzone_test.exs`.

### 1.3.2 Meaningful Sequence (A) — ✓ PASS

**Evidence:** DOM order matches visual order throughout: zone icon →
prompt/drop-prompt → hint → file input; per entry, preview → name +
size → error text → progress → cancel button
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`). No `flex-direction:
row-reverse` or absolute repositioning.

### 1.3.3 Sensory Characteristics (A) — ✓ PASS

**Evidence:** The drag-over state is conveyed by a border/background color
shift (`@dragover_config`, applied in `lib/pulsar/components/dropzone.ex`,
`zone_classes/3`) *and* a text swap from "Click to upload or drag and
drop" to "Drop files here" (`dropzone/1`) — color is not the only signal.
Error state on an entry pairs a red border (`entry_classes/1`) with a
visible error message (`dropzone/1`).

### 1.4.1 Use of Color (A) — ✓ PASS

**Evidence:** Config-level and per-entry upload errors render as
`text-danger` text alongside the message string, never color alone
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`); the errored entry's
red border (`entry_classes/1`) is redundant with that text, not a
substitute for it. The drag-over state is text + color (see 1.3.3).

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** All text and icon colors route through the same semantic
tokens measured elsewhere in the library: `text-foreground` (prompt),
`text-muted-foreground` (hint/size — measured 6.0–7.23:1 on all surfaces in
both themes, house-wide), and `text-danger` (errors, same token measured
≥4.5:1 for text on Input/Select's error states). The axe-core browser gate
scans the Dropzone fixtures' full variant × color grid (4 variants × 7
colors) plus the uploading/errored/config-error state fixtures in both
themes and reports no `color-contrast` violation.

### 1.4.4 Resize Text (AA) — ✓ PASS

**Evidence:** All text sizing uses `rem`-based Tailwind classes
(`text-sm`/`text-xs`); the zone and entries size via `rem`-based padding
(`@size_config`) rather than fixed pixel heights, so nothing clips as text
is resized — `lib/pulsar/components/dropzone.ex`, `zone_classes/3`.

### 1.4.10 Reflow (AA) — ✓ PASS

**Evidence:** The zone is `w-full flex flex-col` with no fixed or minimum
width (`@zone_base_classes`, applied in `lib/pulsar/components/dropzone.ex`,
`zone_classes/3`); the entry row is `flex items-center gap-3` with a
`min-w-0 flex-1` text column that truncates rather than forcing overflow
(`dropzone/1`, `entry_classes/1`). Nothing forces horizontal scrolling at
320 CSS px.

### 1.4.11 Non-text Contrast (AA) — ✓ PASS

**Evidence:** The zone's `focus-within` ring
(`focus-within:ring-2 focus-within:ring-primary focus-within:ring-offset-2`)
and the cancel button's `focus-visible` ring
(`focus-visible:ring-2 focus-visible:ring-primary`) both route through
`--color-ring` scale tokens measured ≥3:1 in both themes elsewhere in the
library (Badge, Input, Accordion) — `lib/pulsar/components/dropzone.ex`,
`zone_classes/3` (zone ring), `dropzone/1` (cancel button ring). The
outline variant's per-color borders (`@color_config["outline"]`) and the
drag-over border emphasis (`@dragover_config`) use the same house
`border-{color}`/`border-border-strong` tokens as Input's outline variant
(`zone_classes/3`). Input's browser audit substantiates three of the
seven: `border-border-strong` (neutral) 4.63:1, `border-primary` 4.4:1,
and `border-danger` 4.2:1, both themes — see `docs/a11y/input.md`. The
remaining four (`border-secondary`, `border-success`, `border-warning`,
`border-info`) resolve through the same theme palette mechanism but have
no recorded measurement of their own; a scoped
`mix pulsar.a11y.measure --component dropzone` run hits the same
data-fixture-cell placement gap noted on Input (the measured cell sits on
inner content, not the bordered wrapper), so it doesn't yield usable
numbers here either. The verdict stays PASS on the SC's 3:1 floor,
semantic-token consistency with Input's measured outline borders, and the
same-palette reasoning — not on a full seven-color measurement.

### 1.4.12 Text Spacing (AA) — ✓ PASS

**Evidence:** No fixed heights on text-bearing elements; zone and entry
sizing is padding/gap-driven (`@size_config` zone padding, entry `p-3`) —
`lib/pulsar/components/dropzone.ex`, `zone_classes/3`, `entry_classes/1`.
No `!important` text-spacing overrides.

**Notes:** The filename uses `truncate` (`dropzone/1`), which
single-line-ellipsizes on horizontal overflow — a design choice
orthogonal to 1.4.12 (which concerns user line-height/letter-spacing
overrides, not intentional truncation).

### 2.1.1 Keyboard (A) — ✓ PASS

**Evidence:** The file input is a native `<input type="file">` rendered
via `<.live_file_input>` with only `class="sr-only"` applied
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`) — visually hidden but
still in the tab order and keyboard-operable (Enter/Space opens the
native file picker). The cancel button is a real `<button type="button">`
(`dropzone/1`). The drag-over highlight is presentational CSS keyed off
LiveView's built-in `phx-drop-target-active` class — the component ships
no JavaScript.

### 2.1.2 No Keyboard Trap (A) — ✓ PASS

**Evidence:** Dropzone is an in-flow control with no focus-trapping
mechanism; Tab moves through the file input and each entry's cancel button
in document order like any other control.

### 2.2.2 Pause, Stop, Hide (A) — ✓ PASS

**Evidence:** The per-entry `Progress.progress` bar
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`) is a determinate
indicator tied to real upload progress (`item.entry.progress`) — an
auto-updating display of essential activity status, which is the WCAG
2.2.2 exception (status of a real process, not decorative motion).

### 2.3.1 Three Flashes or Below Threshold (A) — ✓ PASS

**Evidence:** The only animation is `transition-colors duration-fast
ease-standard` on the zone and cancel button
(`lib/pulsar/components/dropzone.ex`, `zone_classes/3`, `dropzone/1`) — a
sub-second color transition, not flashing.

### 2.4.3 Focus Order (A) — ✓ PASS

**Evidence:** The file input and each entry's cancel button render in
document order with no positive `tabindex`; the component ships no
JavaScript that could move focus.

### 2.4.6 Headings and Labels (AA) — ✓ PASS

**Evidence:** `prompt` and `hint` are caller-overridable, i18n-ready attrs
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`) with sensible English
defaults ("Click to upload or drag and drop"). The component supports
descriptive labeling; writing a meaningful `hint` is the caller's
responsibility, same contract as Input/Select.

### 2.4.7 Focus Visible (AA) — ✓ PASS

**Evidence:** The zone shows a `focus-within` ring when the (sr-only) file
input has focus (`lib/pulsar/components/dropzone.ex`, `zone_classes/3`);
each cancel button shows its own `focus-visible` ring (`dropzone/1`). Both
route through `--color-ring`, measured ≥3:1 in both themes elsewhere in
the library.

### 2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** Dropzone renders in normal document flow — no sticky,
fixed, or overlay content that could cover a focused file input or cancel
button (`lib/pulsar/components/dropzone.ex`, `dropzone/1`).

### 2.5.2 Pointer Cancellation (A) — ✓ PASS

**Evidence:** The cancel button's activation is `phx-click`
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`), which fires on the
native `click` event (mouseup), not `pointerdown`/`mousedown`. The
file-picker trigger is the browser's native `<label>`/`<input type="file">`
click behavior — also an up-event activation.

### 2.5.3 Label in Name (A) — ✓ PASS

**Evidence:** The cancel button has no visible text (icon-only), so its
`aria-label` (`@cancel_label <> ": " <> item.entry.client_name` —
`lib/pulsar/components/dropzone.ex`, `dropzone/1`) can't contradict a
visible label. The zone's visible prompt text *is* the file input's
accessible name (via label wrapping) with no overriding `aria-label`
anywhere in the chain.

### 2.5.7 Dragging Movements (AA, new in 2.2) — ✓ PASS

**Evidence:** Every file dropped via drag-and-drop can equivalently be
added via the native file picker — the same `<label>`/`<.live_file_input>`
that the drag target wraps (`lib/pulsar/components/dropzone.ex`,
`dropzone/1`); dropping is an additive path handled entirely by
LiveView's built-in `phx-drop-target` machinery — it never becomes the
*only* path to add a file. Keyboard test
`test "dragging files over shows the visible drop prompt; leaving hides it"`
exercises the drag path via synthetic `DragEvent`s, and
`test "selecting a file renders a visible entry row"` exercises the
click-to-browse path end to end — both in
`test/integration/a11y/keyboard/dropzone_test.exs`.

### 2.5.8 Target Size (Minimum) (AA, new in 2.2) — ✓ PASS

**Evidence:** The cancel button has no `on`/`off` sizing utility — it
sizes to content: `p-1` (4px) padding around a `size="sm"` icon (`w-4 h-4`
= 16px — `lib/pulsar/components/icon.ex`, `get_size_classes/1`)
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`). Width computes exactly:
16 + 4 + 4 = 24 CSS px, landing precisely at the floor. Height is a plain
(non-flex) `<button>`, so it's governed by the inline line box around the
icon — the inherited line-height strut sets a minimum content height that
padding then adds to, and a strut can only add height, never subtract it.
So the rendered height is *at least* content-box height (16px icon +
8px padding = 24px) and can be taller depending on the inherited
line-height; either way it can't fall below the 24px the width already
sits at. The floor is met on width exactly and on height at or above that
same value — a browser measurement would be needed to pin the exact
rendered height. The zone itself (the file-picker target) is far larger
than 24×24 at every size (`@size_config` zone padding starts at `p-4` —
`zone_classes/3`).

**Notes:** The cancel button's width lands exactly at the 24px floor with
no margin — a future padding reduction (e.g. `p-1` → `p-0.5`) would drop
width below the floor regardless of how tall the line box makes it.
`test/integration/a11y/target_size_test.exs`'s automated gate scans
`[data-fixture-cell]` elements whose tag is
`button`/`select`/`textarea`/certain `input` types; the Dropzone fixture's
`data-fixture-cell` attrs sit on the component root `<div>`
(`test/support/dev_app/live/dropzone_live.ex`, `render/1`), not on the
nested cancel `<button>`, so neither dimension is browser-verified by
that gate today — this is a code-derived width guarantee plus a height
lower bound, not a measured box. If the cancel button's padding or icon
size ever changes, re-verify the width arithmetic by hand and consider
adding a browser measurement for the height.

### 3.2.1 On Focus (A) — ✓ PASS

**Evidence:** Focusing the file input or a cancel button triggers no
navigation or form submission — the file input only opens the native
picker on activation (not on focus), and the cancel button only acts on
`click`.

### 3.2.2 On Input (A) — ✓ PASS

**Evidence:** Selecting files fires the standard LiveView upload
`phx-change` (validated by the host `<form>`, per the component's
`@moduledoc` contract — `lib/pulsar/components/dropzone.ex`), which
notifies the LiveView but does not itself navigate or submit.

### 3.3.1 Error Identification (A) — ✓ PASS

**Evidence:** Both error tiers render as visible text: config-level
errors (too many files, etc.) under the zone, and per-entry errors (too
large, not accepted, upload failed) under that entry's filename
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`). Announcement without
moving focus is handled by the persistent live regions covered under
4.1.3. Tests cover every error atom mapping to visible text:
`test "config-level :too_many_files renders under the zone"`,
`test "per-entry :too_large replaces the progress bar"`,
`test "per-entry :not_accepted renders its message"`, and
`test "unknown error atoms fall back to the external failure message"` —
`test/pulsar/components/dropzone_test.exs`.

### 3.3.2 Labels or Instructions (A) — ✓ PASS

**Evidence:** The visible `prompt` labels the control (via the wrapping
`<label>`) and the optional `hint` gives format/size instructions, wired
with `aria-describedby` (`lib/pulsar/components/dropzone.ex`,
`dropzone/1`).

### 3.3.3 Error Suggestion (AA) — ✓ PASS

**Evidence:** Every upload error atom maps to a specific, actionable
message — "File is too large", "File type not accepted", "Too many
files" (`error_message/2`) — rather than a generic "Upload failed" for
everything. Each message is independently overridable for i18n
(`lib/pulsar/components/dropzone.ex`, `dropzone/1`).

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:**

- **File input** — accessible name comes from the wrapping `<label>`'s
  visible text (prompt/drop-prompt/hint spans,
  `lib/pulsar/components/dropzone.ex`, `dropzone/1`). The prompt and
  drop-prompt spans toggle `hidden`/visible off the same
  `phx-drop-target-active` group state (`dropzone/1`), so exactly one of
  the two is in the accessible-name computation at a time — no duplicated
  or contradictory name.
- **Entry progress** — `Progress.progress` renders
  `role="progressbar"` with `aria-valuemin`/`aria-valuemax`/`aria-valuenow`
  (`lib/pulsar/components/progress.ex`, `progress/1`). Dropzone passes
  `aria-label={item.entry.client_name}` through `Progress`'s `:rest`
  global (`lib/pulsar/components/dropzone.ex`, `dropzone/1`). Progress's own
  `aria-label={@label}` attribute (`lib/pulsar/components/progress.ex`,
  `progress/1`) is `nil` here — Dropzone never sets `label` — and HEEx
  omits an attribute entirely when its value is `nil`, so no duplicate
  `aria-label` is ever emitted on the tag; the caller's value through
  `@rest` is simply the only one rendered. Test
  `test "renders name, formatted size, progress, and cancel button"`
  asserts `role="progressbar"` and `aria-valuenow="40"` —
  `test/pulsar/components/dropzone_test.exs`.
- **Cancel button** — accessible name is `"<cancel_label>: <filename>"`
  (`lib/pulsar/components/dropzone.ex`, `dropzone/1`), unique per entry.
  The same `test "renders name, formatted size, progress, and cancel button"`
  asserts `aria-label="Cancel upload: photo.jpg"` —
  `test/pulsar/components/dropzone_test.exs`.

### 4.1.3 Status Messages (AA) — ✓ PASS

**Evidence:** Two `aria-live="polite"` regions are rendered from the
component's very first mount, before any error exists: one wraps the
config-level error text, and a visually hidden one announces per-entry
errors as "<filename>: <message>" (`lib/pulsar/components/dropzone.ex`,
`dropzone/1`). Because both regions exist in the accessibility tree before
their content changes, error text patched into them is announced without
moving focus. The visible per-entry error text deliberately carries no
`aria-live` of its own — it enters the DOM together with its `<li>`, and a
live region inserted already containing its message is not announced.
Tests assert the persistent wrapper and the filename-prefixed
announcement:
`test "entry errors are announced with the filename in a persistent live region"`
and `test "the entry announcement region is present even with no errors"`
— `test/pulsar/components/dropzone_test.exs`.

## Not applicable

- **1.2.1 Audio-only and Video-only (Prerecorded) (A)** — no media.
- **1.2.2 Captions (Prerecorded) (A)** — no media.
- **1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** — no media.
- **1.2.4 Captions (Live) (AA)** — no media.
- **1.2.5 Audio Description (Prerecorded) (AA)** — no media.
- **1.3.4 Orientation (AA)** — no orientation lock.
- **1.3.5 Identify Input Purpose (AA)** — `type="file"` inputs don't take
  an `autocomplete` purpose token per the HTML spec; not applicable to a
  file picker.
- **1.4.2 Audio Control (A)** — no audio.
- **1.4.5 Images of Text (AA)** — no rendered text images; previews are
  the caller's uploaded photos, not text.
- **1.4.13 Content on Hover or Focus (AA)** — the prompt/drop-prompt swap
  is triggered by an actual file drag over the zone, not by pointer hover
  or keyboard focus, so 1.4.13's hover/focus trigger condition doesn't
  apply.
- **2.1.4 Character Key Shortcuts (A)** — no single-key shortcuts
  registered.
- **2.2.1 Timing Adjustable (A)** — no time limit imposed by the
  component.
- **2.4.1 Bypass Blocks (A)** — page-level concern.
- **2.4.2 Page Titled (A)** — page-level concern.
- **2.4.4 Link Purpose (In Context) (A)** — no links.
- **2.4.5 Multiple Ways (AA)** — page-level concern.
- **2.5.1 Pointer Gestures (A)** — the drag interaction is a single-point
  drag onto a drop target, not a multipoint or path-based gesture; the
  single-pointer keyboard-reachable alternative is covered under 2.5.7.
- **2.5.4 Motion Actuation (A)** — no device-motion-triggered
  functionality.
- **3.1.1 Language of Page (A)** — page-level concern.
- **3.1.2 Language of Parts (AA)** — page-level concern.
- **3.2.3 Consistent Navigation (AA)** — page-level concern.
- **3.2.4 Consistent Identification (AA)** — page/library-level concern,
  not a per-component axis.
- **3.2.6 Consistent Help (A, new in 2.2)** — page-level concern.
- **3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — form-level
  concern; the component doesn't itself submit high-stakes data.
- **3.3.7 Redundant Entry (A, new in 2.2)** — app/form-level concern.
- **3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** — not
  authentication.

## Browser a11y findings

The axe-core browser gate scans the Dropzone fixtures — one route per
variant covering the full variant × color grid, plus the
uploading/errored/config-error state fixtures on the outline route — in
both themes and reports no violations. Three real-browser interaction
tests exercise the upload and drag paths end to end and assert visible DOM
state (not just ARIA attributes): file-pick produces a visible entry row,
cancel removes the row, and dragging over swaps the visible drop-prompt
text via LiveView's built-in `phx-drop-target-active` class
(`test/integration/a11y/keyboard/dropzone_test.exs`).
