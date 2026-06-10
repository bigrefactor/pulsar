# Breadcrumb · WCAG 2.2 AA audit

**Source:** [`lib/pulsar/components/breadcrumb.ex`](../../lib/pulsar/components/breadcrumb.ex)
**Tests:** [`test/pulsar/components/breadcrumb_test.exs`](../../test/pulsar/components/breadcrumb_test.exs)
**Audited:** 2026-06-10 (code + browser axe gate)

Breadcrumb renders a `<nav aria-label="Breadcrumb">` landmark wrapping an `<ol>`
of crumbs. Intermediate crumbs are links; the final crumb is marked
`aria-current="page"` and is not a link. Separators are decorative
(`aria-hidden="true"`). When collapsed, the hidden middle is represented by a
static `aria-hidden` ellipsis.

## Applicable criteria

### 1.3.1 Info and Relationships (A) — ✓ PASS

**Evidence:** Ordered `<ol>`/`<li>` structure conveys sequence; `aria-current="page"` marks the current crumb — `lib/pulsar/components/breadcrumb.ex:123, 157`.

### 2.4.4 Link Purpose (In Context) (A) — ✓ PASS

**Evidence:** Each crumb link's accessible name is its visible text via the item slot — `lib/pulsar/components/breadcrumb.ex:162`.

### 2.4.8 Location (AAA, met as bonus) — ✓ PASS

**Evidence:** The trail communicates the page's location in the site hierarchy; the current page is identified with `aria-current="page"` — `lib/pulsar/components/breadcrumb.ex:157`.

### 4.1.2 Name, Role, Value (A) — ✓ PASS

**Evidence:** `<nav aria-label>` names the landmark; links expose role/name; the current crumb exposes `aria-current` — `lib/pulsar/components/breadcrumb.ex:122, 157`.

### 1.4.3 Contrast (Minimum) (AA) — ✓ PASS

**Evidence:** `text-muted-foreground` links and `text-foreground` current crumb meet AA on all surfaces — `lib/pulsar/components/breadcrumb.ex:158, 175`. Verified by the axe gate across the `/components/breadcrumb` fixture in light and dark themes.

## Not applicable

- **2.1.1 Keyboard / 2.1.2 No Keyboard Trap** — links are native `<a>`; no custom keyboard handling.
- **1.4.13 Content on Hover or Focus** — no hover/focus-revealed content (static ellipsis, no dropdown).
- **4.1.3 Status Messages** — no live updates.

## AAA wins (bonus)

- **2.4.8 Location (AAA)** — see above.

## Browser a11y findings

None. The axe gate is clean across the `/components/breadcrumb` fixture cells in light and dark themes.
