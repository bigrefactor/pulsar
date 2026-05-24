# Pulsar accessibility audit — WCAG 2.2 Level AA

This directory holds Pulsar's first formal accessibility audit. It covers
every applicable WCAG 2.2 Level A and AA success criterion across all 19
components in `lib/pulsar/components/`. Audit method is **code-only**:
evidence comes from reading component source files and existing tests.

**What's covered:** 31 Level A + 24 Level AA = 55 success criteria (Level
A 4.1.1 Parsing is excluded — WCAG 2.2 deprecates it).

**What's not covered (deferred):**

- Browser verification of color contrast, focus-indicator visibility,
  reading order, and motion behavior. Tracked under
  [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser smoke
  audit); individual `⚠ GAP — needs browser verification` items roll up
  there.
- Screen reader testing (VoiceOver / NVDA).
- Implementing fixes — every real code gap is filed as its own Linear
  sub-issue parented to PUL-15.
- AAA criteria as a pass/fail axis. Where a component happens to satisfy
  an AAA criterion for free, it's noted under "AAA wins (bonus)" on that
  component's page.

**How to read a component page:** Each page lists the applicable criteria
with explicit status (`✓ PASS`, `⚠ GAP`, or `N/A`), evidence as file +
line refs to source or test assertions, and notes explaining the call.
GAP entries carry a severity tag (`blocker` / `serious` / `minor`) and
either a Linear sub-issue ID or a reference to
[PUL-19](https://linear.app/bigrefactor/issue/PUL-19) (browser audit).

**Companion audit:** [`apg-audit.md`](apg-audit.md) — code-only
cross-check of Pulsar's 7 interactive components against the WAI-ARIA
Authoring Practices Guide (APG) patterns. Tracked under
[PUL-20](https://linear.app/bigrefactor/issue/PUL-20).

**References:**

- [WCAG 2.2 specification](https://www.w3.org/TR/WCAG22/)
- [WCAG quick reference (developer cheat sheet)](https://www.wcag.com/developers/)
- [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/)

---

## Status matrix

Components are rows, criteria are columns grouped by principle. Cells:

- `✓` — passes (evidence in code)
- `⚠` — gap (real code gap or needs-browser-verification)
- `—` — not applicable to this component

Component pages live in this directory: `<component>.md`. The summary
table below shows per-principle counts as `P/G/N` (passes / gaps /
not-applicable). Detailed per-criterion grids follow.

### Summary by principle

| Component | Perceivable | Operable | Understandable | Robust |
|-----------|-------------|----------|----------------|--------|
| **Form / input** | | | | |
| [field](field.md) | 8/3/9 | 2/1/17 | 5/0/8 | 2/0/0 |
| [input](input.md) | 8/3/9 | 9/2/9 | 5/0/8 | 2/0/0 |
| [textarea](textarea.md) | 8/3/9 | 9/2/9 | 5/0/8 | 2/0/0 |
| [select](select.md) | 8/3/9 | 9/2/9 | 5/0/8 | 2/0/0 |
| [checkbox](checkbox.md) | 7/3/10 | 9/2/9 | 5/0/8 | 2/0/0 |
| [radio_group](radio_group.md) | 7/3/10 | 9/2/9 | 5/0/8 | 2/0/0 |
| [switch](switch.md) | 7/3/10 | 9/2/9 | 5/0/8 | 2/0/0 |
| [label](label.md) | 5/2/13 | 2/0/18 | 0/0/13 | 1/0/1 |
| **Action / navigation** | | | | |
| [button](button.md) | 7/3/10 | 10/2/8 | 1/0/12 | 2/0/0 |
| [link](link.md) | 7/3/10 | 11/1/8 | 1/0/12 | 2/0/0 |
| **Feedback / notification** | | | | |
| [flash](flash.md) | 9/2/9 | 9/2/9 | 1/0/12 | 2/0/0 |
| [flash_group](flash_group.md) | 8/1/11 | 9/1/10 | 1/0/12 | 2/0/0 |
| **Structure / layout** | | | | |
| [card](card.md) | 8/2/10 | 10/1/9 | 1/0/12 | 1/0/1 |
| [divider](divider.md) | 8/1/11 | 1/0/19 | 0/0/13 | 1/0/1 |
| [header](header.md) | 8/2/10 | 9/1/10 | 1/0/12 | 1/0/1 |
| [list](list.md) | 7/3/10 | 1/0/19 | 0/0/13 | 1/0/1 |
| [table](table.md) | 8/2/10 | 7/4/9 | 1/0/12 | 2/0/0 |
| **Content** | | | | |
| [badge](badge.md) | 8/2/10 | 2/2/16 | 0/0/13 | 1/0/1 |
| [icon](icon.md) | 8/1/11 | 1/0/19 | 0/0/13 | 1/0/1 |

### Perceivable (1.x)

| Component | 1.1.1 | 1.2.1 | 1.2.2 | 1.2.3 | 1.2.4 | 1.2.5 | 1.3.1 | 1.3.2 | 1.3.3 | 1.3.4 | 1.3.5 | 1.4.1 | 1.4.2 | 1.4.3 | 1.4.4 | 1.4.5 | 1.4.10 | 1.4.11 | 1.4.12 | 1.4.13 |
|-----------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| field | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | ✓ | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| input | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | ✓ | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| textarea | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | ✓ | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| select | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | ✓ | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| checkbox | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| radio_group | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| switch | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| label | — | — | — | — | — | — | ✓ | — | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | — | ⚠ | — |
| button | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ⚠ | — |
| link | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ⚠ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| flash | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | ✓ |
| flash_group | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — | — | — | ✓ | ⚠ | ✓ | ✓ |
| card | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| divider | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — | ✓ | — | ✓ | ⚠ | ✓ | — |
| header | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| list | ✓ | — | — | — | — | — | ⚠ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| table | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| badge | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | ⚠ | ✓ | — | ✓ | ⚠ | ✓ | — |
| icon | ✓ | — | — | — | — | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — | ✓ | — | ✓ | ⚠ | ✓ | — |

### Operable (2.x)

| Component | 2.1.1 | 2.1.2 | 2.1.4 | 2.2.1 | 2.2.2 | 2.3.1 | 2.4.1 | 2.4.2 | 2.4.3 | 2.4.4 | 2.4.5 | 2.4.6 | 2.4.7 | 2.4.11 | 2.5.1 | 2.5.2 | 2.5.3 | 2.5.4 | 2.5.7 | 2.5.8 |
|-----------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| field | — | — | — | — | — | — | — | — | — | — | — | ✓ | ⚠ | ✓ | — | — | — | — | — | — |
| input | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| textarea | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| select | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| checkbox | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| radio_group | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| switch | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| label | — | — | — | — | — | — | — | — | — | — | — | ✓ | — | — | — | — | ✓ | — | — | — |
| button | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | ✓ | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| link | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | ✓ | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ✓ |
| flash | ✓ | ✓ | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — | — | ⚠ | ✓ | — | ✓ | ✓ | — | — | ⚠ |
| flash_group | ✓ | ✓ | — | ✓ | ✓ | ✓ | — | — | ✓ | — | — | — | ✓ | ⚠ | — | ✓ | — | — | — | ✓ |
| card | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ✓ | ⚠ | ✓ | — | ✓ | ✓ | — | — | ✓ |
| divider | — | — | — | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| header | ✓ | ✓ | — | — | ✓ | ✓ | ✓ | — | ✓ | ✓ | — | ✓ | ✓ | ⚠ | — | — | — | — | — | — |
| list | — | — | — | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| table | ✓ | ✓ | — | — | ✓ | ✓ | — | — | ✓ | — | — | ⚠ | ⚠ | ⚠ | — | ✓ | ✓ | — | — | ⚠ |
| badge | — | — | — | — | — | — | — | — | — | — | — | — | ⚠ | ✓ | — | ✓ | — | — | — | ⚠ |
| icon | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — | — | — | — | — | — |

### Understandable (3.x) and Robust (4.x)

| Component | 3.1.1 | 3.1.2 | 3.2.1 | 3.2.2 | 3.2.3 | 3.2.4 | 3.2.6 | 3.3.1 | 3.3.2 | 3.3.3 | 3.3.4 | 3.3.7 | 3.3.8 | 4.1.2 | 4.1.3 |
|-----------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| field | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| input | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| textarea | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| select | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| checkbox | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| radio_group | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| switch | — | — | ✓ | ✓ | — | — | — | ✓ | ✓ | ✓ | — | — | — | ✓ | ✓ |
| label | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| button | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | ✓ |
| link | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | ✓ |
| flash | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | ✓ |
| flash_group | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | ✓ |
| card | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| divider | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| header | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| list | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| table | — | — | ✓ | — | — | — | — | — | — | — | — | — | — | ✓ | ✓ |
| badge | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |
| icon | — | — | — | — | — | — | — | — | — | — | — | — | — | ✓ | — |

---

## Criteria reference

Each criterion entry: `ID Name (Level) — one-line explanation. Component-library note.`

### Principle 1 — Perceivable

Information and user interface components must be presentable to users in
ways they can perceive.

#### 1.1 Text Alternatives

**1.1.1 Non-text Content (A)** — Non-text content (images, icons, media)
has a text alternative that serves the equivalent purpose.
*Library note:* Decorative icons need `aria-hidden="true"`; meaningful
icons need an accessible name (`aria-label` or visible text via
`<svg><title>`). Loading spinners and decorative SVGs default to hidden.

#### 1.2 Time-based Media

**1.2.1 Audio-only and Video-only (Prerecorded) (A)** — Provide alternatives
for time-based media.
*Library note:* Generally N/A for UI components; only applies if a
component renders media.

**1.2.2 Captions (Prerecorded) (A)** — Captions for prerecorded audio in
synchronized media.
*Library note:* N/A for UI components.

**1.2.3 Audio Description or Media Alternative (Prerecorded) (A)** —
Audio description or full text alternative for prerecorded video.
*Library note:* N/A for UI components.

**1.2.4 Captions (Live) (AA)** — Captions for live audio content.
*Library note:* N/A for UI components.

**1.2.5 Audio Description (Prerecorded) (AA)** — Audio description for
prerecorded video.
*Library note:* N/A for UI components.

#### 1.3 Adaptable

**1.3.1 Info and Relationships (A)** — Information, structure, and
relationships conveyed visually can be programmatically determined.
*Library note:* Use semantic HTML (`<label>`, `<table>`, `<ul>`, `<th
scope>`, headings, `<fieldset>/<legend>`, etc.). For grouped controls,
use `role="group"` / `role="radiogroup"`. Label associations via
`for`/`id` or `aria-labelledby`.

**1.3.2 Meaningful Sequence (A)** — When sequence affects meaning, a
correct reading sequence can be programmatically determined.
*Library note:* DOM order matches visual order in nearly all components;
flag any use of CSS that reorders content (e.g., `flex-direction:
row-reverse`).

**1.3.3 Sensory Characteristics (A)** — Instructions don't rely solely
on shape, color, size, or position.
*Library note:* Confirm error/required indication isn't color-only (paired
with text or icon). Affects status patterns in flash, input validation,
and required-field marking.

**1.3.4 Orientation (AA)** — Content not locked to a single orientation.
*Library note:* Components shouldn't `transform`-lock to landscape or
portrait. Usually a page-level concern, not component-level.

**1.3.5 Identify Input Purpose (AA)** — Inputs collecting user info
identify their purpose programmatically.
*Library note:* Input components should support `autocomplete` attribute
pass-through (e.g., `autocomplete="email"`, `autocomplete="name"`).

#### 1.4 Distinguishable

**1.4.1 Use of Color (A)** — Color is not the only visual means of
conveying information.
*Library note:* Error states must include text/icon, not just red.
Required fields must be marked with more than color. Status colors in
badge/flash need a non-color signal.

**1.4.2 Audio Control (A)** — Mechanism to pause/stop/control audio
playing longer than 3 seconds.
*Library note:* N/A for UI components (no audio).

**1.4.3 Contrast (Minimum) (AA)** — Text and images of text have a
contrast ratio of at least 4.5:1 (3:1 for large text).
*Library note:* Needs browser verification per variant/color combination.
Code-only audit can confirm semantic-token usage but not measured ratios.

**1.4.4 Resize Text (AA)** — Text can be resized up to 200% without loss
of content or function.
*Library note:* Avoid fixed `px` heights for text-containing elements; use
relative units (`rem`, `em`). Tailwind classes like `text-sm`, `text-base`
use `rem` and pass; check for absolute pixel font sizes.

**1.4.5 Images of Text (AA)** — Use text rather than images of text where
possible.
*Library note:* Components shouldn't render text as raster images.
Heroicons-rendered SVGs are inline SVG, not images of text — fine.

**1.4.10 Reflow (AA)** — Content reflows at 320 CSS pixels wide without
horizontal scrolling or loss of function.
*Library note:* Components shouldn't enforce a minimum width that breaks
narrow viewports. Tables are the typical risk (allow horizontal scroll
container).

**1.4.11 Non-text Contrast (AA)** — Non-text UI components (borders,
focus rings, icons) have a contrast ratio of at least 3:1.
*Library note:* Focus rings, input borders, checkbox/radio borders need
3:1 against background. Needs browser verification.

**1.4.12 Text Spacing (AA)** — Content adapts when users override line
height, letter spacing, word spacing, or paragraph spacing.
*Library note:* Avoid `!important` on text spacing; avoid fixed heights
that clip text under user-overrides. Usually inherits from the page.

**1.4.13 Content on Hover or Focus (AA)** — Additional content triggered
by hover/focus is dismissable, hoverable, and persistent.
*Library note:* Applies to tooltips, popovers, dropdowns. None of the
current 19 components ship a tooltip — mostly N/A.

### Principle 2 — Operable

User interface components and navigation must be operable.

#### 2.1 Keyboard Accessible

**2.1.1 Keyboard (A)** — All functionality is operable through a keyboard.
*Library note:* Interactive components (button, link, form inputs) must
work without pointer. Pseudo-button (div/a with role="button") must
handle Space/Enter via JS hook.

**2.1.2 No Keyboard Trap (A)** — Keyboard focus can be moved away from any
component.
*Library note:* No component should trap Tab/Shift+Tab. No modal/dialog
components in the current inventory.

**2.1.4 Character Key Shortcuts (A)** — Single-key shortcuts can be
turned off or remapped.
*Library note:* N/A unless a component registers a global single-key
shortcut. None do.

#### 2.2 Enough Time

**2.2.1 Timing Adjustable (A)** — Time limits can be turned off,
adjusted, or extended.
*Library note:* Auto-dismissing flash messages need a way to extend or
pause. Relevant to flash if it auto-hides.

**2.2.2 Pause, Stop, Hide (A)** — Moving, blinking, or auto-updating
content can be paused/stopped/hidden.
*Library note:* Loading spinners are an exception (essential to function).
Auto-rotating carousels would need controls — none exist.

#### 2.3 Seizures and Physical Reactions

**2.3.1 Three Flashes or Below Threshold (A)** — Nothing flashes more
than 3 times per second.
*Library note:* Animations (spinners, hover scale) are below threshold
and respect `motion-reduce`. Verify any new animation stays under 3
flashes/sec.

#### 2.4 Navigable

**2.4.1 Bypass Blocks (A)** — A mechanism to skip blocks of repeated
content (skip links, landmarks).
*Library note:* Page-level concern. Components don't usually provide
this; an app's layout wraps components in landmarks.

**2.4.2 Page Titled (A)** — Pages have descriptive titles.
*Library note:* Page-level, N/A for components.

**2.4.3 Focus Order (A)** — Focus order preserves meaning and
operability.
*Library note:* DOM order should match visual order. Don't use
positive `tabindex`. Verify no component reorders focusable children
unexpectedly.

**2.4.4 Link Purpose (In Context) (A)** — Link purpose can be determined
from link text alone or text + context.
*Library note:* The link component requires inner_block content; avoid
"click here" patterns at the call site. Document this expectation.

**2.4.5 Multiple Ways (AA)** — Multiple ways to locate a page.
*Library note:* Page-level concern, N/A for components.

**2.4.6 Headings and Labels (AA)** — Headings and labels describe topic
or purpose.
*Library note:* Form labels must be descriptive (responsibility of the
caller). The label and field components must support visible label text.
The header component should support proper hierarchy.

**2.4.7 Focus Visible (AA)** — Keyboard focus indicator is visible.
*Library note:* All interactive components must apply
`focus-visible:ring-*` or equivalent. Visible contrast under each variant
needs browser verification.

**2.4.11 Focus Not Obscured (Minimum) (AA, new in 2.2)** — Focused
component is not entirely hidden by author-created content (sticky
headers, footers).
*Library note:* Component-level concern only if a component creates
sticky/overlapping content. Mostly page-level.

#### 2.5 Input Modalities

**2.5.1 Pointer Gestures (A)** — Functionality with multipoint or
path-based gestures has a single-point alternative.
*Library note:* No component uses gesture-based input.

**2.5.2 Pointer Cancellation (A)** — Single-point activations can be
cancelled (use `up` events, not `down`).
*Library note:* Native `<button>` and `<a>` use `click` which fires on
mouseup — passes. Pseudo-buttons in the JS hook use `click`.

**2.5.3 Label in Name (A)** — Accessible name includes visible label
text.
*Library note:* Don't set an `aria-label` that contradicts the visible
text. Where a component supports `aria_label`, callers should leave it
unset when there's visible text.

**2.5.4 Motion Actuation (A)** — Functionality triggered by motion can
be disabled and triggered by UI components.
*Library note:* No component uses device motion.

**2.5.7 Dragging Movements (AA, new in 2.2)** — Drag-based functionality
has a single-pointer alternative.
*Library note:* No component implements drag.

**2.5.8 Target Size (Minimum) (AA, new in 2.2)** — Interactive targets
are at least 24×24 CSS px, with exceptions for inline links and
spacing.
*Library note:* Button sizes — `xs` (h-6 = 24px) is exactly at minimum;
others exceed. Checkbox/radio/switch hit areas, flash dismiss buttons,
and icon-only buttons need explicit check.

### Principle 3 — Understandable

Information and the operation of the user interface must be
understandable.

#### 3.1 Readable

**3.1.1 Language of Page (A)** — Default human language of the page
identified.
*Library note:* Page-level, N/A for components.

**3.1.2 Language of Parts (AA)** — Language of each passage identified
when different from page default.
*Library note:* Page-level, N/A for components.

#### 3.2 Predictable

**3.2.1 On Focus (A)** — Focus alone doesn't initiate a context change.
*Library note:* No component triggers navigation/submit on focus.

**3.2.2 On Input (A)** — Changing the setting of a UI component doesn't
automatically cause a context change (unless warned).
*Library note:* Form inputs emit events for app handling, don't navigate
on input themselves.

**3.2.3 Consistent Navigation (AA)** — Navigation components repeat in
the same relative order.
*Library note:* Page/app-level, N/A for components.

**3.2.4 Consistent Identification (AA)** — Components with the same
functionality are identified consistently.
*Library note:* The library provides consistent components; satisfied
by using Pulsar across the app.

**3.2.6 Consistent Help (A, new in 2.2)** — Help mechanisms repeat in
the same relative order.
*Library note:* Page/app-level, N/A for components.

#### 3.3 Input Assistance

**3.3.1 Error Identification (A)** — Errors are identified in text and
described to the user.
*Library note:* The field component renders errors with `aria-invalid`
on the input and `aria-describedby` pointing to the error region with
`role="alert"` or `aria-live="polite"`.

**3.3.2 Labels or Instructions (A)** — Labels or instructions are
provided when content requires user input.
*Library note:* The field wrapper enforces a label/description model.
Leaf inputs should fail gracefully or warn when used without field.

**3.3.3 Error Suggestion (AA)** — When an input error is detected and
suggestions are known, suggestions are provided.
*Library note:* Field renders the error string passed by the caller; the
library can't enforce "suggestion-quality" content but doesn't suppress
it. Pass when callers can provide suggestions through the error slot.

**3.3.4 Error Prevention (Legal, Financial, Data) (AA)** — For
high-stakes submissions, provide confirmation/review/reversal.
*Library note:* Form-level concern, N/A for individual input components.

**3.3.7 Redundant Entry (A, new in 2.2)** — Don't require users to
re-enter information in the same session.
*Library note:* App/form-level concern, N/A for individual input
components.

**3.3.8 Accessible Authentication (Minimum) (AA, new in 2.2)** — Don't
require cognitive function tests (puzzles, transcription) unless an
alternative is provided.
*Library note:* App-level concern, N/A for individual input components.

### Principle 4 — Robust

Content must be robust enough that it can be interpreted by a wide
variety of user agents, including assistive technologies.

**4.1.2 Name, Role, Value (A)** — All UI components have programmatic
name, role, and value; states/properties expose to assistive tech.
*Library note:* Use semantic HTML where possible. Where ARIA is needed:
`role="button"` for pseudo-buttons; `aria-pressed`, `aria-expanded`,
`aria-disabled`, `aria-busy` for state; `aria-controls` for disclosure.

**4.1.3 Status Messages (AA)** — Status messages can be programmatically
determined through role/properties.
*Library note:* Flash messages use `role="alert"` or `role="status"`
with appropriate `aria-live`. Field errors use `role="alert"` /
`aria-live`. Loading states expose `aria-busy="true"`.

---

## Severity legend (for `⚠ GAP`)

- **blocker** — keyboard trap, missing semantic role on an interactive
  element, missing label association on an input, missing accessible
  name, content that's literally unusable with assistive tech.
- **serious** — missing ARIA state on a stateful interactive component
  (e.g., switch without `aria-checked`), missing skip mechanism,
  missing required `aria-describedby` linkage for errors.
- **minor** — cosmetic or edge-case violations; defaults to minor for
  all `⚠ GAP — needs browser verification` items (since the underlying
  code looks plausible and only runtime evidence is missing).

---

**Audited:** 2026-05-24 (code-only)
**Follow-up:** [PUL-19](https://linear.app/bigrefactor/issue/PUL-19) —
browser smoke audit (axe-core + contrast + keyboard + screenshots).
