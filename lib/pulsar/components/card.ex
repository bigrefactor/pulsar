defmodule Pulsar.Components.Card do
  @moduledoc """
  Flexible card component for grouping related content with optional sections.

  Provides styled cards with semantic variants and composition-based layout.
  All styling is applied via Tailwind CSS utilities with semantic color tokens
  that support both light and dark modes.

  ## Features

  - **Multiple Variants**: solid, outline, ghost, elevated for different visual styles
  - **Full Color Palette**: All semantic colors with automatic dark mode support
  - **Multiple Sizes**: xs, sm, md, lg, xl matching other Pulsar components
  - **Composition-First**: Flexible slots without prescriptive structure
  - **Optional Sections**: Media, header, content, footer - use only what you need

  ## Examples

      # Minimal card
      <.card>
        <p>Simple card content</p>
      </.card>

      # Card with variant and color
      <.card variant="outline" color="primary">
        <p>Outlined primary card</p>
      </.card>

      # Full-featured card with all slots
      <.card variant="outline" color="primary" size="lg">
        <:media>
          <img src="/hero.jpg" class="w-full h-48 object-cover" />
        </:media>

        <:header>
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold">Card Title</h3>
            <.button variant="ghost" size="sm">Edit</.button>
          </div>
        </:header>

        <p>Main content with automatic spacing between sections.</p>
        <p class="text-sm text-muted-foreground">
          Additional content flows naturally.
        </p>

        <:footer>
          <div class="flex items-center justify-between text-sm">
            <span class="text-muted-foreground">
              Updated 2 hours ago
            </span>
            <.button variant="link" size="sm">View Details</.button>
          </div>
        </:footer>
      </.card>

      # Interactive card with phx-click
      <.card phx-click="select_card" phx-value-id="123" variant="outline" color="primary">
        <p>Click anywhere on this card to trigger the event</p>
      </.card>

      # Clickable card with hover states
      <.card
        phx-click="select"
        class="cursor-pointer hover:scale-[1.01] hover:shadow-lg"
        variant="outline"
      >
        <p>Custom hover effects</p>
      </.card>

      # Navigation wrapped card
      <.link navigate={~p"/products/\#{product.id}"}>
        <.card variant="outline" class="hover:border-primary">
          <:header>
            <h3 class="font-semibold">{product.name}</h3>
          </:header>
          <p>{product.description}</p>
        </.card>
      </.link>

      # Composing with badges
      <.card class="relative" variant="outline">
        <.badge class="absolute top-4 right-4" color="primary">New</.badge>
        <:header>
          <h3 class="font-semibold">Product Title</h3>
        </:header>
        <p>Product description with badge positioned freely</p>
      </.card>

      # Grid of cards
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for item <- @items do %>
          <.card variant="elevated" phx-click="select" phx-value-id={item.id}>
            <:header>
              <h3 class="font-semibold">{item.title}</h3>
            </:header>
            <p>{item.description}</p>
          </.card>
        <% end %>
      </div>

  ## Composition Patterns

  The card component embraces composition over configuration. All slots
  render their content without modification, giving you complete control:

      # Header with custom layout
      <.card>
        <:header>
          <div class="flex items-start gap-4">
            <img src={@avatar} class="w-12 h-12 rounded-full" />
            <div class="flex-1">
              <h3 class="font-semibold">{@name}</h3>
              <p class="text-sm text-muted-foreground">{@role}</p>
            </div>
            <.button variant="ghost" size="sm">...</.button>
          </div>
        </:header>
        <p>Card content</p>
      </.card>

      # Complex footer with actions
      <.card>
        <:header>
          <h3 class="font-semibold">Confirmation</h3>
        </:header>
        <p>Are you sure you want to delete this item?</p>
        <:footer>
          <div class="flex justify-end gap-2">
            <.button variant="ghost" phx-click="cancel">Cancel</.button>
            <.button variant="solid" color="danger" phx-click="confirm">Delete</.button>
          </div>
        </:footer>
      </.card>

  ## Accessibility

  - Semantic HTML structure
  - All Phoenix event handlers pass through naturally
  - Screen reader friendly content flow
  - Customizable focus states via class attribute
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Size configuration for cards
  @size_config %{
    "lg" => %{
      body: "flex flex-col p-6 gap-6",
      footer: "p-6 pt-0",
      header: "p-6 pb-0",
      radius: "rounded-xl"
    },
    "md" => %{
      body: "flex flex-col p-5 gap-5",
      footer: "p-5 pt-0",
      header: "p-5 pb-0",
      radius: "rounded-lg"
    },
    "sm" => %{
      body: "flex flex-col p-4 gap-4",
      footer: "p-4 pt-0",
      header: "p-4 pb-0",
      radius: "rounded-lg"
    },
    "xl" => %{
      body: "flex flex-col p-8 gap-8",
      footer: "p-8 pt-0",
      header: "p-8 pb-0",
      radius: "rounded-2xl"
    },
    "xs" => %{
      body: "flex flex-col p-3 gap-3",
      footer: "p-3 pt-0",
      header: "p-3 pb-0",
      radius: "rounded-md"
    }
  }

  # Base card styling classes
  @card_base_classes [
    "block w-full overflow-hidden",
    "transition-colors duration-200 ease-in-out"
  ]

  # Valid variants and colors for compile-time validation
  @valid_variants ~w(solid outline ghost elevated)
  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Color configuration for each variant
  @color_config %{
    "elevated" => %{
      "danger" => "bg-surface-1 shadow-md",
      "info" => "bg-surface-1 shadow-md",
      "neutral" => "bg-surface-1 shadow-md",
      "primary" => "bg-surface-1 shadow-md",
      "secondary" => "bg-surface-1 shadow-md",
      "success" => "bg-surface-1 shadow-md",
      "warning" => "bg-surface-1 shadow-md"
    },
    "ghost" => %{
      "danger" => "bg-transparent border border-transparent",
      "info" => "bg-transparent border border-transparent",
      "neutral" => "bg-transparent border border-transparent",
      "primary" => "bg-transparent border border-transparent",
      "secondary" => "bg-transparent border border-transparent",
      "success" => "bg-transparent border border-transparent",
      "warning" => "bg-transparent border border-transparent"
    },
    "outline" => %{
      "danger" => "bg-surface-1 border-2 border-danger",
      "info" => "bg-surface-1 border-2 border-info",
      "neutral" => "bg-surface-1 border-2 border-border",
      "primary" => "bg-surface-1 border-2 border-primary",
      "secondary" => "bg-surface-1 border-2 border-secondary",
      "success" => "bg-surface-1 border-2 border-success",
      "warning" => "bg-surface-1 border-2 border-warning"
    },
    "solid" => %{
      "danger" => "bg-danger/10 border-2 border-danger/20",
      "info" => "bg-info/10 border-2 border-info/20",
      "neutral" => "bg-surface-1 border-2 border-border",
      "primary" => "bg-primary/10 border-2 border-primary/20",
      "secondary" =>
        "bg-secondary/10 border-2 border-secondary/20",
      "success" => "bg-success/10 border-2 border-success/20",
      "warning" => "bg-warning/10 border-2 border-warning/20"
    }
  }

  # Compile-time validation: Ensure all variant/color combinations are defined
  for variant <- @valid_variants,
      color <- @valid_colors do
    if !get_in(@color_config, [variant, color]) do
      raise CompileError,
        description: "Missing color config for variant=#{variant}, color=#{color}"
    end
  end

  # ============================================================================
  # CARD COMPONENT
  # ============================================================================

  attr(:variant, :string,
    default: "elevated",
    values: ~w(solid outline ghost elevated),
    doc: "Visual style variant of the card"
  )

  attr(:color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme of the card"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Size of the card (controls padding and spacing)"
  )

  attr(:class, :string,
    default: "",
    doc: "Additional CSS classes"
  )

  attr(:rest, :global, doc: "Additional HTML attributes including phx-* event handlers")

  slot(:media, doc: "Media section (images, videos) - full width, no padding")
  slot(:header, doc: "Header section with padding")
  slot(:inner_block, required: true, doc: "Main card content")
  slot(:footer, doc: "Footer section with padding")

  @doc """
  Renders a flexible card component with optional sections.

  The card uses semantic color tokens and supports all standard variants.
  Cards are pure styled containers - add phx-* events or wrap in links
  for interactivity.

  ## Size Behavior
  - Controls padding for header, body, and footer sections
  - Controls gap between content in body
  - Controls border radius

  ## Making Cards Interactive
  Cards are just styled containers. Add interactivity as needed:

      # With phx-click
      <.card phx-click="select" class="cursor-pointer">
        Content
      </.card>

      # With navigation (wrap in link)
      <.link navigate={~p"/path"}>
        <.card class="hover:shadow-lg">
          Content
        </.card>
      </.link>

  ## Examples

      # Static card
      <.card variant="outline" color="primary">
        <p>Content here</p>
      </.card>

      # Full composition
      <.card variant="outline" size="lg">
        <:media>
          <img src="/img.jpg" class="w-full h-64 object-cover" />
        </:media>
        <:header>
          <h3 class="text-xl font-bold">Title</h3>
        </:header>
        <p>Content with automatic spacing</p>
        <:footer>
          <button>Action</button>
        </:footer>
      </.card>
  """
  @spec card(map()) :: Rendered.t()
  def card(assigns) do
    # Build complete class string using Twm
    card_class =
      merge([
        base_card_classes(),
        color_classes(assigns.variant, assigns.color),
        size_classes(assigns.size, :radius),
        interactive_classes(assigns.rest),
        assigns.class
      ])

    # Add keyboard accessibility defaults for interactive cards
    assigns =
      assigns
      |> assign(:card_class, card_class)
      |> add_interactive_attrs()

    ~H"""
    <div class={@card_class} {@rest}>
      <div :if={@media != []} class="w-full">
        {render_slot(@media)}
      </div>

      <div :if={@header != []} class={size_classes(@size, :header)}>
        {render_slot(@header)}
      </div>

      <div class={size_classes(@size, :body)}>
        {render_slot(@inner_block)}
      </div>

      <div :if={@footer != []} class={size_classes(@size, :footer)}>
        {render_slot(@footer)}
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarCard">
      export default {
        mounted() {
          const el = this.el
          if (el.getAttribute("role") !== "button") return

          this._onKeydown = (e) => {
            if (e.code === "Space" || e.key === " ") {
              e.preventDefault() // prevent scroll
            }
            if (e.code === "Enter") {
              e.preventDefault()
              el.click() // Triggers phx-click with all parameters
            }
          }

          this._onKeyup = (e) => {
            if (e.code === "Space" || e.key === " ") {
              e.preventDefault()
              el.click() // Triggers phx-click with all parameters
            }
          }

          el.addEventListener("keydown", this._onKeydown)
          el.addEventListener("keyup", this._onKeyup)
        },

        destroyed() {
          if (this._onKeydown) this.el.removeEventListener("keydown", this._onKeydown)
          if (this._onKeyup) this.el.removeEventListener("keyup", this._onKeyup)
        }
      }
    </script>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  # Base card classes
  @spec base_card_classes() :: list(String.t())
  defp base_card_classes do
    @card_base_classes
  end

  # Color classes by variant
  @spec color_classes(String.t(), String.t()) :: String.t()
  defp color_classes(variant, color) do
    @color_config[variant][color]
  end

  # Size classes - supports different parts (body, header, footer, radius)
  @spec size_classes(String.t(), atom()) :: String.t()
  defp size_classes(size, part) do
    @size_config[size][part]
  end

  # Interactive classes for clickable cards
  @spec interactive_classes(map()) :: [String.t()]
  defp interactive_classes(rest) do
    if interactive?(rest) do
      [
        "cursor-pointer",
        "focus-visible:outline-none",
        "focus-visible:ring-2",
        "focus-visible:ring-primary",
        "",
        "focus-visible:ring-offset-2"
      ]
    else
      []
    end
  end

  # Check if card has interactive event handlers
  @spec interactive?(map()) :: boolean()
  defp interactive?(rest) do
    Map.has_key?(rest, :"phx-click")
  end

  # Add keyboard accessibility attributes for interactive cards
  @spec add_interactive_attrs(map()) :: map()
  defp add_interactive_attrs(%{rest: rest} = assigns) do
    if interactive?(rest) do
      rest =
        rest
        |> Map.put_new(:role, "button")
        |> Map.put_new(:tabindex, "0")
        |> Map.put_new(:"phx-hook", ".PulsarCard")

      assign(assigns, :rest, rest)
    else
      assigns
    end
  end
end
