defmodule Pulsar.Components.Link do
  @moduledoc """
  Beautiful, accessible link component with semantic variants and security.

  Provides consistent link styling with semantic variants, color schemes, and automatic
  security handling for external links. All styling is applied via Tailwind CSS utilities 
  with semantic color tokens that support both light and dark modes.

  ## Dependencies

  This component requires:
  - `Pulsar.Components.Icon` - for external link indicators

  ## Features

  - **Security-First**: Automatic XSS protection and external link security
  - **Semantic Variants**: solid, ghost, outline with clear meaning for links
  - **Color Schemes**: full semantic color palette (primary, secondary, etc.)
  - **Automatic External Detection**: URLs with protocols get security attributes
  - **Phoenix Navigation**: Built-in support for LiveView navigation
  - **Flexible Sizing**: inherit parent text size or specify explicit sizes
  - **Accessibility**: WCAG 2.1 AA compliance with proper ARIA attributes

  ## Security Features

  - **XSS Protection**: Automatically sanitizes dangerous protocols (javascript:, data:, etc.)
  - **External Security**: Automatic `rel="noopener noreferrer"` for external links
  - **Protocol Detection**: Case-insensitive dangerous protocol detection
  - **Safe Defaults**: External links default to `target="_blank"` with security

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
      <Link.a href="https://example.com">Visit External Site</Link.a>

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

  ## Data Attributes

  - `data-external="true"` - External link state for styling
  - `data-current` - Current page state (from aria-current)
  - `data-target` - Target attribute value for styling
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Pulsar.Components.Icon

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(solid ghost outline),
    doc:
      "Visual style variant of the link. solid=no underline, ghost=hover underline, outline=always underline"
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(primary secondary muted danger success warning info inherit),
    doc: "Color scheme of the link"
  )

  attr(:size, :string,
    default: "inherit",
    values: ~w(xs sm md lg xl inherit),
    doc: "Size of the link text. inherit adapts to parent text size"
  )

  # Stellar Link attributes - copied from Stellar.Components.Link
  attr(:href, :string, default: nil, doc: "External URL to navigate to")
  attr(:navigate, :string, default: nil, doc: "Phoenix route to navigate to")
  attr(:patch, :string, default: nil, doc: "Phoenix route to patch navigate to")
  attr(:replace, :boolean, default: false, doc: "Replace current history entry")
  attr(:method, :string, default: nil, doc: "HTTP method for the link")
  attr(:target, :string, default: nil, doc: "Link target attribute (auto-set for external)")
  attr(:rel, :string, default: nil, doc: "Link relationship (auto-set for external)")

  # Standard HTML attributes
  attr(:id, :string, default: nil)
  attr(:class, :string, default: "", doc: "Additional CSS classes")

  # ARIA attributes (matching Stellar.Components.Link)
  attr(:aria_label, :string, default: nil, doc: "Accessible label for the link")
  attr(:aria_describedby, :string, default: nil)
  attr(:aria_current, :string, default: nil)

  attr(:rest, :global)

  # Slots
  slot(:inner_block, required: true, doc: "Link content")
  slot(:start_icon, doc: "Icon shown before the link text")
  slot(:end_icon, doc: "Icon shown after the link text")

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
    # Validate navigation props (from Stellar logic)
    ensure_nav_exclusive!(assigns)

    # Handle external link detection and security (from Stellar logic)
    assigns = detect_and_handle_external(assigns)

    # Build complete class string using TailwindMerge
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

    # Use raw <a> tag for mailto/tel links, Phoenix link for navigation
    if should_use_raw_anchor?(assigns) do
      render_raw_anchor(assigns)
    else
      render_phoenix_link(assigns)
    end
  end

  # Render raw <a> tag for mailto, tel, and external HTTP links
  defp render_raw_anchor(assigns) do
    ~H"""
    <a
      phx-no-format
      href={@href}
      target={assigns[:target]}
      rel={assigns[:rel]}
      id={@id || nil}
      class={@merged_classes}
      aria-label={@aria_label || nil}
      aria-describedby={@aria_describedby || nil}
      aria-current={@aria_current || nil}
      data-external={(@external && "true") || nil}
      data-current={@aria_current || nil}
      data-target={assigns[:target]}
      {@rest}
    >
      <span :if={@start_icon != []} class="inline-flex items-center mr-1" aria-hidden="true">
        {render_slot(@start_icon)}
      </span>
      {render_slot(@inner_block)}
      <!-- Automatic external icon - shown only for links that open in new tab without custom end_icon -->
      <span
        :if={@end_icon == []}
        class="hidden group-data-[target=_blank]:inline-flex items-center ml-1"
        aria-hidden="true"
      >
        <Icon.icon name="hero-arrow-top-right-on-square" class="w-[1em] h-[1em]" color="current" />
      </span>
      <!-- Custom end icon - shown when provided -->
      <span :if={@end_icon != []} class="inline-flex items-center ml-1" aria-hidden="true">
        {render_slot(@end_icon)}
      </span>
    </a>
    """
  end

  # Render Phoenix link for internal navigation
  defp render_phoenix_link(assigns) do
    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      replace={@replace}
      method={@method}
      target={assigns[:target]}
      rel={assigns[:rel]}
      id={@id}
      class={@merged_classes}
      aria-label={@aria_label}
      aria-describedby={@aria_describedby}
      aria-current={@aria_current}
      data-external={(@external && "true") || nil}
      data-current={@aria_current || nil}
      data-target={assigns[:target]}
      {@rest}
    >
      <span :if={@start_icon != []} class="inline-flex items-center mr-1" aria-hidden="true">
        {render_slot(@start_icon)}
      </span>
      {render_slot(@inner_block)}
      <!-- Automatic external icon - shown only for links that open in new tab without custom end_icon -->
      <span
        :if={@end_icon == []}
        class="hidden group-data-[target=_blank]:inline-flex items-center ml-1"
        aria-hidden="true"
      >
        <Icon.icon name="hero-arrow-top-right-on-square" class="w-[1em] h-[1em]" color="current" />
      </span>
      <!-- Custom end icon - shown when provided -->
      <span :if={@end_icon != []} class="inline-flex items-center ml-1" aria-hidden="true">
        {render_slot(@end_icon)}
      </span>
    </.link>
    """
  end

  # Determine if we should use a raw <a> tag instead of Phoenix.Component.link
  defp should_use_raw_anchor?(%{href: href}) when is_binary(href) do
    case URI.parse(href) do
      %URI{scheme: scheme} when scheme in ["mailto", "tel", "http", "https", "ftp"] -> true
      _ -> false
    end
  end

  defp should_use_raw_anchor?(_assigns), do: false

  # Detect external links and handle security attributes
  defp detect_and_handle_external(assigns) do
    # Sanitize href first to prevent XSS
    sanitized_href = sanitize_href(assigns.href)

    # Determine if link is external (automatic detection only)
    is_external = external_link?(sanitized_href)

    assigns
    |> assign(:href, sanitized_href)
    |> assign(:external, is_external)
    |> maybe_assign_external_security(is_external)
  end

  # Dangerous protocols that should be blocked for security
  @dangerous_protocols ~w(javascript data vbscript about file)

  # Sanitize href to prevent XSS attacks
  defp sanitize_href(nil), do: nil

  defp sanitize_href(href) when is_binary(href) do
    trimmed = String.trim(href)
    # Detect scheme in a case-insensitive, whitespace-tolerant way (thwarts "   javascript:")
    case Regex.run(~r/^\s*([a-z][a-z0-9+.\-]*):/i, trimmed) do
      [_, scheme] ->
        if String.downcase(scheme) in @dangerous_protocols, do: "#", else: trimmed

      _ ->
        trimmed
    end
  end

  # Check if URL is external based on protocol
  defp external_link?(nil), do: false

  defp external_link?(href) when is_binary(href) do
    # Check for protocol-relative URLs first (//example.com)
    if String.starts_with?(href, "//") and not String.starts_with?(href, "///") do
      true
    else
      case URI.parse(href) do
        # Relative URLs without scheme are internal
        %URI{scheme: nil} ->
          false

        # URLs with schemes - check if they're external protocols
        %URI{scheme: scheme} when is_binary(scheme) ->
          String.downcase(scheme) in ["http", "https", "mailto", "tel", "ftp"]
      end
    end
  end

  # Apply security attributes for external links if not manually overridden
  defp maybe_assign_external_security(assigns, false), do: assigns

  defp maybe_assign_external_security(assigns, true) do
    # Parse URI once and reuse for both target and rel assignment
    parsed_uri = URI.parse(assigns.href || "")

    # Only set target="_blank" for http/https links, not mailto/tel
    # Use assign instead of assign_new to ensure external links get target="_blank"
    assigns =
      case parsed_uri do
        %URI{scheme: scheme} when is_binary(scheme) ->
          case String.downcase(scheme) do
            scheme when scheme in ["http", "https"] ->
              # Force target="_blank" for HTTP/HTTPS unless explicitly set to something else
              if Map.has_key?(assigns, :target) and assigns[:target] != nil do
                assigns
              else
                assign(assigns, :target, "_blank")
              end

            _ ->
              assigns
          end

        _ ->
          assigns
      end

    # Set rel based on the target value (after it's been assigned)
    assigns =
      assign_new(assigns, :rel, fn ->
        if assigns[:target] == "_blank" do
          "noopener noreferrer"
        end
      end)

    assigns
  end

  # Ensure only one navigation prop is provided
  defp ensure_nav_exclusive!(assigns) do
    nav_props = [
      {assigns[:href], :href},
      {assigns[:navigate], :navigate},
      {assigns[:patch], :patch}
    ]

    provided_props =
      nav_props
      |> Enum.filter(fn {value, _key} -> is_binary(value) end)
      |> Enum.map(fn {_value, key} -> key end)

    if length(provided_props) > 1 do
      props_string = provided_props |> Enum.map_join(", ", &inspect/1)

      raise ArgumentError,
            "Provide only one of :href, :navigate, or :patch. Found: #{props_string}"
    end

    assigns
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
