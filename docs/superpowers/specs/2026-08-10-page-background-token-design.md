# PUL-134: Page Background Token Contract

## Problem

Pulsar currently gives two semantic color tokens overlapping descriptions. `--color-background` is presented in
Storybook as the page background, while `--color-surface-0` is commented as the canvas/page background in both built-in
theme templates. Because the tokens have equal values in the shipped themes, applications cannot infer which token
should ground the page until a custom theme assigns them different values.

The development Storybook sandbox compounds the ambiguity by using `--color-surface-0` as its background even though
the token reference labels `--color-background` as the page background.

## Decision

`--color-background` is the application/page ground. Applications should apply its utility or CSS variable to
`<body>`.

`--color-surface-0` is an independently customizable base in the surface elevation scale. It does not define the page
ground. Pulsar will keep both tokens and their current built-in values, allowing a custom theme to distinguish the page
canvas from its lowest content surface.

## Changes

- Extend the header comment in `priv/templates/theme.css.eex` to state which token grounds `<body>` and to distinguish
  the page background from the surface elevation scale.
- Replace the `Canvas/page background` comments beside `--color-surface-0` in the light and dark theme templates with
  wording that identifies it as the base elevation surface.
- Change the development Storybook sandbox background from `var(--color-surface-0)` to
  `var(--color-background)` so Pulsar demonstrates the documented contract.
- Regenerate or synchronize committed development fixtures from their source templates where the repository workflow
  requires it.
- Add an entry under `Unreleased` in `CHANGELOG.md` describing the clarified theming contract.

No token will be removed, aliased, or assigned a different built-in value. Component behavior and default rendering
remain unchanged.

## Verification

Add focused regression coverage that verifies:

- the theme entry documentation tells applications to ground `<body>` with `--color-background`;
- the built-in theme templates describe `--color-surface-0` as the base elevation surface and no longer call it the
  page or canvas background; and
- the development Storybook sandbox consumes `--color-background` for its background.

Assertions should verify the semantic contract without depending on the current white and gray palette assignments.
Run the focused tests, formatting, and repository template/fixture drift checks. Run broader relevant checks if the
focused verification exposes shared behavior.

## Compatibility and Failure Modes

This is a documentation and development-example correction. Existing applications and generated themes retain all
tokens and values. Applications already using `--color-surface-0` for the page will continue to render, but the new
guidance makes the intended customization boundary explicit.

There is no runtime control flow or new error path. The primary regression risk is documentation or generated fixtures
drifting back into contradictory roles; focused source-level assertions and synchronization checks address that risk.
