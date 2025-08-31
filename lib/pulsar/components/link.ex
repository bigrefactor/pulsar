defmodule Pulsar.Components.Link do
  @moduledoc """
  Styled link component built on Stellar.Components.Link.

  Provides consistent link styling with semantic variants and color schemes.
  All styling is applied via Tailwind CSS utilities with semantic color tokens that
  support both light and dark modes.

  ## Features

  - **Stellar Foundation**: Built on Stellar's accessible link component
  - **Semantic Variants**: solid, ghost, outline with clear meaning for links
  - **Color Schemes**: full semantic color palette (primary, secondary, etc.)
  - **Automatic External Detection**: URLs with protocols get security attributes
  - **Flexible Sizing**: inherit parent text size or specify explicit sizes
  - **Full Stellar API**: All Stellar link props are supported

  ## Examples

      # Basic link (defaults to solid variant, primary color)
      <Link.a href="/profile">View Profile</Link.a>

      # Different variants
      <Link.a href="/docs" variant="ghost">Documentation</Link.a>
      <Link.a href="/help" variant="outline">Help Center</Link.a>

      # Different colors
      <Link.a href="/delete" color="danger">Delete Account</Link.a>
      <Link.a href="/settings" color="muted">Settings</Link.a>

      # External link with automatic icon and security attributes
      <Link.a href="https://example.com" external>Visit External Site</Link.a>

      # With Phoenix navigation
      <Link.a navigate={~p"/dashboard"}>Go to Dashboard</Link.a>

      # With custom icons
      <Link.a navigate={~p"/settings"}>
        <:start_icon>⚙️</:start_icon>
        Account Settings
      </Link.a>

  ## Variants

  - **solid** (default): Clean colored text without underline
  - **ghost**: Shows underline on hover only  
  - **outline**: Always shows underline

  ## Stellar Integration

  This component wraps Stellar.Components.Link and passes through all its props:
  - `:href` - External URL
  - `:navigate`, `:patch` - Phoenix LiveView navigation
  - All standard link attributes
  """

  use Phoenix.Component
  alias Stellar.Components.Link, as: StellarLink

  import TailwindMerge, only: [merge: 1]

  # Pulsar-specific styling attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(solid ghost outline),
    doc:
      "Visual style variant of the link. solid=no underline, ghost=hover underline, outline=always underline"

  attr :color, :string,
    default: "primary",
    values: ~w(primary secondary muted danger success warning info inherit),
    doc: "Color scheme of the link"

  attr :size, :string,
    default: "inherit",
    values: ~w(xs sm md lg xl inherit),
    doc: "Size of the link text. inherit adapts to parent text size"

  # Stellar Link attributes - copied from Stellar.Components.Link
  attr :href, :string, default: nil, doc: "External URL to navigate to"
  attr :navigate, :string, default: nil, doc: "Phoenix route to navigate to"
  attr :patch, :string, default: nil, doc: "Phoenix route to patch navigate to"
  attr :replace, :boolean, default: false, doc: "Replace current history entry"
  attr :method, :string, default: nil, doc: "HTTP method for the link"
  attr :external, :boolean, default: nil, doc: "Manual override for external link detection"
  attr :target, :string, default: nil, doc: "Link target attribute (auto-set for external)"
  attr :rel, :string, default: nil, doc: "Link relationship (auto-set for external)"

  # Standard HTML attributes
  attr :id, :string, default: nil
  attr :class, :string, default: "", doc: "Additional CSS classes"

  # ARIA attributes (matching Stellar.Components.Link)
  attr :aria_label, :string, default: nil, doc: "Accessible label for the link"
  attr :aria_describedby, :string, default: nil
  attr :aria_current, :string, default: nil

  attr :rest, :global

  # Slots
  slot :inner_block, required: true, doc: "Link content"
  slot :start_icon, doc: "Icon shown before the link text"
  slot :end_icon, doc: "Icon shown after the link text"

  @doc """
  Renders a styled link component.

  Uses semantic color tokens and variants for consistent styling.
  External links automatically get security attributes and visual indicators.

  ## Size Behavior
  By default, links inherit the text size from their parent context.
  You can override this with explicit size classes.

  ## External Links
  Stellar automatically detects external URLs and:
  - Adds `target="_blank"` and `rel="noopener noreferrer"`
  - Appends an arrow icon (unless custom end_icon is provided)
  - Maintains all security best practices

  ## Examples

      # Inherits parent text size
      <p class="text-lg">
        Check out our <Link.a href="/docs">documentation</Link.a> for details.
      </p>

      # Explicit size
      <Link.a href="/profile" size="lg">Large Profile Link</Link.a>
  """
  def a(assigns) do
    # Build complete class string using TailwindMerge - only include needed classes  
    assigns =
      assign(
        assigns,
        :merged_classes,
        merge([
          # Enable group-data selectors for external icon handling
          "group inline-flex items-center",
          base_link_classes(),
          variant_classes(assigns.variant),
          color_classes(assigns.color),
          size_classes(assigns.size),
          assigns.class
        ])
      )

    ~H"""
    <StellarLink.a
      href={@href}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      method={@method}
      external={@external}
      target={@target}
      rel={@rel}
      id={@id}
      class={@merged_classes}
      aria_label={@aria_label}
      aria_describedby={@aria_describedby}
      aria_current={@aria_current}
      {@rest}
    >
      <span :if={@start_icon != []} class="inline-flex items-center mr-1" aria-hidden="true">
        {render_slot(@start_icon)}
      </span>
      {render_slot(@inner_block)}
      <!-- Automatic external icon - shown only for external links without custom end_icon -->
      <span
        :if={@end_icon == []}
        class="hidden group-data-[external=true]:inline-flex items-center ml-1"
        aria-hidden="true"
      >
        <svg
          class="w-[1em] h-[1em]"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
          />
        </svg>
      </span>
      <!-- Custom end icon - shown when provided -->
      <span :if={@end_icon != []} class="inline-flex items-center ml-1" aria-hidden="true">
        {render_slot(@end_icon)}
      </span>
    </StellarLink.a>
    """
  end

  # Base styles shared by all links
  defp base_link_classes do
    """
    cursor-pointer transition-all duration-200 ease-in-out
    focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/50 dark:focus-visible:ring-dark-ring/50
    focus-visible:ring-offset-1
    """
  end

  # Variant-specific border behavior
  defp variant_classes("solid"), do: "no-underline"

  defp variant_classes("ghost"),
    do: "no-underline border-b-2 border-transparent hover:border-current pb-0.5"

  defp variant_classes("outline"), do: "no-underline border-b-2 border-current pb-0.5"

  # Color classes using semantic tokens + opacity
  defp color_classes("primary"),
    do:
      "text-primary hover:text-primary/80 dark:text-dark-primary dark:hover:text-dark-primary/80"

  defp color_classes("secondary"),
    do:
      "text-secondary hover:text-secondary/80 dark:text-dark-secondary dark:hover:text-dark-secondary/80"

  defp color_classes("muted"),
    do:
      "text-muted-foreground hover:text-muted-foreground/70 dark:text-dark-muted-foreground dark:hover:text-dark-muted-foreground/70"

  defp color_classes("danger"),
    do: "text-danger hover:text-danger/80 dark:text-dark-danger dark:hover:text-dark-danger/80"

  defp color_classes("success"),
    do:
      "text-success hover:text-success/80 dark:text-dark-success dark:hover:text-dark-success/80"

  defp color_classes("warning"),
    do:
      "text-warning hover:text-warning/80 dark:text-dark-warning dark:hover:text-dark-warning/80"

  defp color_classes("info"),
    do: "text-info hover:text-info/80 dark:text-dark-info dark:hover:text-dark-info/80"

  defp color_classes("inherit"), do: "text-inherit"

  # Size classes
  defp size_classes("xs"), do: "text-xs"
  defp size_classes("sm"), do: "text-sm"
  defp size_classes("md"), do: "text-base"
  defp size_classes("lg"), do: "text-lg"
  defp size_classes("xl"), do: "text-xl"
  defp size_classes("inherit"), do: ""
end

