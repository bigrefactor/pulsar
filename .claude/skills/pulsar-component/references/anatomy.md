# Component module anatomy

Read 2–3 existing components before writing — `badge.ex` (simplest display),
`input.ex`/`checkbox.ex` (form), `button.ex` (colocated JS + component
dependency). Match their idiom exactly. The structure below is the shared skeleton.

```elixir
defmodule Pulsar.Components.Widget do
  @moduledoc """
  One-line purpose.

  Longer description.

  ## Features
  - **Multiple Variants**: ...
  - **Full Color Palette**: ...

  ## Examples

      <.widget>Content</.widget>
      <.widget color="primary" variant="outline">Featured</.widget>

  ## Composition
  <how callers extend it / what slots are for>
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  # alias <concrete sibling component if any>, e.g. alias Pulsar.Components.Icon

  # ==========================================================================
  # CONFIGURATION & CONSTANTS
  # ==========================================================================

  # Lookup maps keyed by string attr value. Keep keys sorted.
  @size_config %{
    "xs" => "text-xs px-2 py-0.5",
    "sm" => "text-sm px-2 py-0.5",
    "md" => "text-sm px-2.5 py-0.5",
    "lg" => "text-base px-3 py-1",
    "xl" => "text-lg px-3.5 py-1"
  }

  @base_classes [
    "inline-flex items-center font-medium rounded-field",
    "transition-colors duration-normal",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2"
  ]

  # Nested map: variant => color => classes (semantic tokens only).
  @color_config %{
    "solid" => %{
      "primary" => "bg-primary text-primary-foreground",
      "success" => "bg-success text-success-foreground"
      # ...
    },
    "outline" => %{ ... },
    "ghost" => %{ ... }
  }

  # ==========================================================================
  # COMPONENT
  # ==========================================================================

  attr :variant, :string, default: "solid", values: ~w(solid outline ghost),
    doc: "Visual style variant"
  attr :color, :string, default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme"
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "Size"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  slot :inner_block, required: true, doc: "Content"

  @doc """
  Renders a widget.
  """
  @spec widget(map()) :: Rendered.t()
  def widget(assigns) do
    class = build_classes(assigns)
    assigns = assign(assigns, :class, class)

    ~H"""
    <span class={@class} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  # ==========================================================================
  # HELPERS (all private; duplication across components is intentional)
  # ==========================================================================

  defp build_classes(assigns) do
    merge([
      base_classes(),
      variant_color_classes(assigns.variant, assigns.color),
      size_classes(assigns.size),
      assigns.class
    ])
  end

  defp base_classes, do: @base_classes
  defp size_classes(size), do: @size_config[size]
  defp variant_color_classes(variant, color), do: @color_config[variant][color]
end
```

## Non-negotiable conventions

- **Twm merge, user class last.** Always compose with
  `merge([base, variant, size, color, assigns.class])` so a caller's `class`
  overrides component defaults (last-in-wins). `import Twm, only: [merge: 1]`.
- **Semantic color tokens, never `dark:`.** Use `bg-primary`,
  `text-foreground`, `text-muted-foreground`, `border-border`,
  `bg-background`, `*-foreground` pairs. Theme swapping happens in CSS via
  `[data-theme="dark"]` — components are theme-agnostic. A `dark:` variant in a
  component is a bug.
- **Design tokens, not raw values.** `rounded-field`, `duration-normal`,
  `shadow-card`, etc. — these come from the theme entry CSS.
- **`@spec` + `@moduledoc` with runnable examples.** Every public component has
  both. Private helpers are `defp` and need no docs.
- **Docs and comments are purely usage-facing.** The component ships into the
  user's app — its `@moduledoc`, `@doc`, and inline comments are *end-user*
  documentation: what the component does, its attrs/slots, and how to use it
  (examples). They must NOT mention internal mechanics or project history — no
  "theme-agnostic / no `dark:` variants", no "uses semantic tokens for runtime
  swap", no "automatic dark mode support", no migration notes, no rationale for
  *why* it's built this way. A consumer reading the docs cares how to call
  `<.widget>`, not how Pulsar implements theming. Implementation rationale lives
  in contributor docs (`CLAUDE.md`, `docs/a11y/`), never in the shipped component.
  Inline `#` comments should explain non-obvious *code*, not narrate decisions.
  This includes mechanism rationale: a comment like "Visibility is driven entirely
  by CSS so there's no server round-trip" or "No preventDefault here, it could
  block Escape on nested controls" is narrating *why it works this way* — keep it
  out. If the code needs a comment, name *what* a non-obvious line does in a few
  words; if you're explaining a trade-off or an alternative you rejected, that's
  contributor-doc material, not a shipped comment.
- **`attr :rest, :global`** spread on the root element so callers can pass
  `id`, `aria-*`, `phx-*`, `data-*`.
- **No shared cross-component helpers.** Each component is generated standalone;
  copy the helper pattern, don't extract it to a shared module.

## Component dependencies (composing another component)

A component MAY render another whole Pulsar component (button → link, link →
icon, header → link + icon). When it does:

1. In the **template** (`priv/templates/widget.ex.eex`), write the alias as
   `alias <%= @component_namespace %>.Icon` so it resolves to the user's
   namespace after generation. (This is the only kind of line that differs
   between the generated lib file and the template beyond the module wrapper.)
2. After `mix pulsar.sync`, the generated lib file has the concrete
   `alias Pulsar.Components.Icon` — produced for you, don't hand-edit it.
3. In `lib/mix/tasks/pulsar.install.ex`, declare the dependency in `@components`:
   `widget: [:icon]`. The dependency must itself be a key in `@components`.

## Colocated JavaScript (only if behavior truly needs JS)

Phoenix-native only — `Phoenix.LiveView.ColocatedHook` inlined in the component,
no separate `.js` files, no external libraries. Prefer `Phoenix.LiveView.JS`
commands for show/hide/class toggles. See `button.ex` for the canonical pattern
(a `<script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarWidget">` block
rendered alongside the element). Most components need no JS at all.
