# ADR-001: Theme and Design System for Pulsar

- Status: Accepted
- Date: 2025-08-31

## Context

Pulsar is the styled component library for the Nebula suite, providing self-contained components with built-in accessibility. End‑users are expected to theme Pulsar to match their brand while preserving default accessibility and consistency across applications. We need a tokenized design system that:

- Enables drop‑in Tailwind utilities (e.g., `bg-primary`, `text-foreground`).
- Supports dark mode via whatever strategy consumers configure in Tailwind (media/class/custom selector).
- Cleanly separates palette values from semantic usage so themes can be swapped without rewriting components.
- Scales to cover typography, elevation, motion, borders, and layering beyond just color.

## Decision

We define Pulsar’s theme as CSS custom properties inside Tailwind’s `@theme inline` block. Palette tokens map to Tailwind color families; semantic tokens reference those palettes and are the only tokens used by components. We do not override semantic tokens in dark mode; components opt-in to dark tokens explicitly via `dark:` utilities so the library works with any host dark‑mode strategy.

Key choices:

- Palette vs. semantics: Keep full color scales (50–950) per role (primary/secondary/success/etc.), then expose semantic tokens for surfaces, text, borders, rings, and “on‑color” foregrounds.
- Dark mode by composition: No `@variant dark` overrides in the theme. Components use explicit utilities like `bg-surface-1 dark:bg-dark-surface-1`; the host app chooses the strategy (media/class/custom selector).
- Token completeness: Provide tokens for typography, elevation, borders, motion, opacity, and layers to cover most UI needs.
- No compatibility aliases: Prefer explicit surface scale tokens to reduce ambiguity.

## Details

 Token categories provided by Pulsar:

- Color palettes: `--color-<role>-50…950` (e.g., primary, secondary, success, warning, danger, info, neutral).
- Semantic colors:
  - Surfaces: `--color-background`, `--color-surface-0…3`, `--color-muted`.
  - Text: `--color-foreground`, `--color-muted-foreground`, and `--color-<role>-foreground`.
  - Borders/inputs/rings: `--color-border`, `--color-border-subtle`, `--color-border-strong`, `--color-input`, `--color-ring`.
  - Brand/status: `--color-<role>` plus `--color-<role>-foreground`.
- Radius and spacing: `--radius-*`, `--spacing-*`.
- Typography: `--font-*`, `--text-*`, `--leading-*`, `--font-weight-*`.
- Elevation: `--shadow-0…3` for component elevation.
- Motion: `--duration-*`, `--easing-*`.
- Opacity: `--opacity-*` for disabled/overlay states.
- Layers: `--z-*` indices for overlays, modals, toasts.

### Surface Scale

We standardize a surface scale for consistent elevation and interaction feedback:

- `--color-surface-0`: App canvas (page background for content areas).
- `--color-surface-1`: Base containers (cards, panels, list items).
- `--color-surface-2`: Raised elements (popovers, menus, dropdowns).
- `--color-surface-3`: Highest elevation (dialogs, sheets, toasts).

Interaction state tokens:

- `--color-surface-1-hover`, `--color-surface-1-active`.
- `--color-surface-2-hover`, `--color-surface-2-active`.

We intentionally omit compatibility aliases to simplify the surface model and encourage adoption of the scale.

Light/Dark mapping (defaults):

- Light: 0 = white, 1 = gray-50, 2 = gray-100, 3 = gray-200; hovers/actives step darker.
- Dark: 0 = gray-900, 1 = gray-850 (fallback 800), 2 = gray-800, 3 = gray-700; hovers/actives step lighter.

Dark mode behavior:

- The theme exposes explicit light/dark tokens (e.g., `--color-light-*`, `--color-dark-*`). Components select them via utilities (e.g., `bg-background dark:bg-dark-background`). No automatic semantic remapping.

Usage patterns:

- Components should use semantic tokens with explicit dark variants (e.g., `bg-background dark:bg-dark-background`, `text-foreground dark:text-dark-foreground`, `border-border dark:border-dark-border`, `ring-[--ring-width] ring-[--color-ring] dark:ring-[--color-dark-ring]`).
- Colored components should use paired tokens (e.g., `bg-[--color-primary] text-[--color-primary-foreground]`).
- For elevation, prefer semantic utility mapping to shadows (e.g., `shadow-[--shadow-2]`).

## Consequences

- Theming flexibility: End‑users can override palette tokens (brand colors) or semantic tokens (behavior) without touching component code.
- Consistency: Shared semantic tokens ensure cohesive results across Pulsar components and Nebula applications.
- Accessibility: Default choices (e.g., primary 600 in light, 400 in dark) aim for better contrast out of the box; “on‑color” foreground tokens are provided to simplify compliant text on colored surfaces.
- Maintenance: Adding new roles or tokens follows the established categories and dark‑mode override pattern.

## How to Extend / Override

- To rebrand: Override palette tokens (e.g., `--color-primary-500…700`) and optionally adjust `--color-primary`/`--color-primary-foreground`.
- To tweak surfaces: Override `--color-background`, `--color-surface*`, and border tokens.
- To adjust motion/elevation: Override `--duration-*`, `--easing-*`, and `--shadow-*`.
- To match dark‑mode taste: Override the same semantic tokens inside your app’s dark‑mode scope; they will merge with Pulsar defaults.

## Alternatives Considered

- Hardcoded data attribute selector for dark mode: Rejected to allow consumers to use any Tailwind dark‑mode strategy.
- Single‑layer palette without semantics: Rejected because components would need per‑app color rewiring and lose consistency.

## Open Questions

- Do we want additional surface scales (e.g., `--surface-0/1/2`) formalized as first‑class tokens beyond the compatibility aliases?
- Should we add brand‑specific typography tokens (font families) per product line, or keep them purely consumer‑provided?

## Usage Guidelines

- Page background: use `bg-background dark:bg-dark-background` for the overall canvas; prefer `bg-surface-1 dark:bg-dark-surface-1` for content containers.
- Cards and panels: `bg-surface-1 dark:bg-dark-surface-1 border-border-subtle dark:border-dark-border-subtle shadow-[--shadow-1]` with hover/active: `hover:bg-surface-1-hover dark:hover:bg-dark-surface-1-hover active:bg-surface-1-active dark:active:bg-dark-surface-1-active`.
- Popovers/menus: `bg-surface-2 dark:bg-dark-surface-2 border-border dark:border-dark-border shadow-[--shadow-2]` with `backdrop-blur` if needed.
- Modals/sheets: `bg-surface-3 dark:bg-dark-surface-3 border-border-strong dark:border-dark-border-strong shadow-[--shadow-3]`.
- Colored components: pair background and on-color foreground, e.g., `bg-primary text-primary-foreground`.
- Text: default to `text-foreground dark:text-dark-foreground`; deemphasized text uses `text-muted-foreground dark:text-dark-muted-foreground`.
- Focus: `ring-[--ring-width] ring-[--color-ring] dark:ring-[--color-dark-ring] ring-offset-0` for consistent focus visuals.
