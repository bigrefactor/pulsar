# Theming and variants

Two things make a Pulsar component feel native: it dresses entirely in the
**semantic token system** (so it themes for free), and it exposes the **standard
variant/color/size axes** the rest of the library uses. Get these right and a
new component drops in seamlessly across light, dark, and any custom theme.

## The theme model (why semantic tokens)

Pulsar themes are pure CSS. Components reference *semantic* token utilities —
`bg-primary`, `text-foreground`, `border-border` — and never hard-code a palette
shade (`bg-blue-500`) or a `dark:` variant. Each theme is one CSS block that
overrides the token values under `[data-theme="<name>"]` / `.theme-<name>`, so the
same component recolors at runtime with no rebuild. A `dark:` utility or a literal
color in a component **defeats this and is a bug** — there is exactly one code path
and the cascade does the theming.

This is a **code constraint, not a documentation point.** Don't surface it in the
component's `@moduledoc` or comments ("theme-agnostic", "no `dark:` variants",
"automatic dark mode support" are all internal mechanics). The shipped docs are
for someone *using* the component — just use the right tokens silently.

Consequence for a new component: **build only from existing tokens.** Your job is
to pick the right semantic token for each part, not to introduce color.

## Available semantic color tokens

Use these utilities (`bg-*`, `text-*`, `border-*`, `ring-*`, `fill-*`). They all
swap per theme:

**Surfaces & text**
- `background` / `foreground` — page base and primary text
- `muted` / `muted-foreground` — subdued surface and secondary text
- `surface-0` … `surface-3` (each with `-hover` / `-active` for `surface-1`/`-2`)
  — layered card/panel backgrounds
- `input` — form-field background; `ring` — focus ring color

**Borders**
- `border` (default), `border-subtle` (lighter), `border-strong` (higher
  contrast — use this when an edge must meet 3:1 non-text contrast, e.g. neutral
  outlines)

**Status / brand colors** — each comes as a base + a `-foreground` (the readable
text/icon color to place *on* that base):
- `primary`, `secondary`, `neutral`, `success`, `danger`, `warning`, `info`
- e.g. solid: `bg-primary text-primary-foreground`; subtle: `text-success`,
  `bg-success/10`

Always pair a colored background with its `-foreground` partner so contrast holds
in every theme. (A few darker step tokens like `primary-600/-700`,
`danger-700`, `success-900` exist for hover/emphasis nuance — prefer the
base+foreground pairs unless you're matching an existing component's hover ramp.)

## Available non-color design tokens

Use these instead of raw values so spacing/shape/motion stay consistent and
themeable:
- **Radius:** `rounded-field` (inputs/buttons/badges), `rounded-box` (cards/panels),
  `rounded-selector`, plus the scale `rounded-{xs,sm,md,lg,xl,2xl,3xl,pill,full}`.
- **Shadow:** `shadow-card`, `shadow-dropdown`, `shadow-modal`, `shadow-toast`.
- **Motion:** `duration-quick`, `duration-normal`, `duration-slow` (respect
  `prefers-reduced-motion` — don't animate essential state).
- **Z-index:** `z-docked`, `z-sticky`, `z-dropdown`, `z-overlay`, `z-modal`,
  `z-popover`, `z-toast` — pick the layer that matches the component's role (a
  tooltip uses `z-popover`, a modal `z-modal`).
- **Spacing:** the standard Tailwind scale plus named `spacing-{xs,sm,md,lg,xl}`.

## If you need a token that doesn't exist

Don't hard-code the value in the component. A genuinely new semantic token is a
**theme change**, added to every theme so it swaps correctly:
- `priv/templates/themes/light.css.eex` and `dark.css.eex` (and `scaffold.css.eex`)
- the dev_app copies under `test/support/dev_app/assets/css/` so fixtures render
- mirror the entry/token wiring in `priv/templates/theme.css.eex` if it's a
  non-swapping design token

This is rare and broadens the skill's scope (it's theme infrastructure, not just a
component). Prefer composing from existing tokens; if you truly need a new one,
add it to all themes in the same change and call it out.

## The variant taxonomy

Match the axes and value vocabulary the library already uses — callers expect
`variant`/`color`/`size` to mean the same thing on every component:

- **`variant`** — *visual treatment*: `solid` (filled), `outline` (bordered,
  transparent fill), `ghost` (text-only, tinted hover). Not every component needs
  all three; pick the ones that make sense.
- **`color`** — *semantic intent*, from the status/brand palette:
  `neutral primary secondary success danger warning info`. **Only expose the
  colors the component actually needs** — don't add the full 7-color palette
  reflexively because other components have it. A tooltip, for instance, wants a
  single readable surface, not seven; offering all of them just manufactures
  low-contrast variants you then have to flag as 1.4.3 gaps. Scope every axis to
  what the component is *for*; fewer, correct variants beat a complete matrix of
  mostly-pointless (and sometimes inaccessible) ones.
- **`size`** — the shared scale `xs sm md lg xl` (default `md`). Keep heights and
  padding proportional to existing components at the same size.
- **`class`** (default `""`) and **`rest :global`** — always present; `class` is
  Twm-merged **last** so callers can override any default.

Only invent a new axis when the component genuinely has an independent dimension
(e.g. avatar `shape` = circle/square, switch has no `variant`). When you do, give
it `values:` and a `default:`, and a config map like the others.

### How variants become classes

Variants are **data**, resolved through module-attribute lookup maps — not
sprawling `cond`/`case` in the render function. Standard shape:

```elixir
@size_config %{"xs" => "...", "sm" => "...", "md" => "...", "lg" => "...", "xl" => "..."}

@color_config %{
  "solid"   => %{"primary" => "bg-primary text-primary-foreground", ...},
  "outline" => %{"primary" => "border border-primary text-primary bg-background", ...},
  "ghost"   => %{"primary" => "text-primary hover:bg-primary/10", ...}
}

defp build_classes(assigns) do
  merge([
    base_classes(),
    @color_config[assigns.variant][assigns.color],
    @size_config[assigns.size],
    assigns.class            # user override wins
  ])
end
```

Every cell of those maps must use semantic tokens (see lists above). This is what
the a11y contrast audit measures per variant×color×size — keep the matrix complete
and consistent so no cell ships an untested combination.

## Verify across themes

The component must look correct in **light and dark** (and any custom theme). The
a11y fixture is auto-run by the axe gate in both themes, and the storybook renders
under the theme switcher — so once you've built only from tokens with no `dark:`,
theming is covered. If a variant only looks right in one theme, you've hard-coded
something; find it and replace it with the right token.
