defmodule Pulsar.Components.Link do
  @moduledoc """
  Accessible link component with semantic variants, security, and Phoenix navigation.

  ## Features
  - Security-first: XSS protection and external link security
  - Semantic variants: solid, ghost, outline  
  - Color schemes: primary, secondary, danger, etc.
  - Automatic external detection with security attributes
  - Phoenix navigation support (navigate, patch, href)
  - WCAG 2.1 AA compliance

  ## Examples

      <Link.a href="/profile">View Profile</Link.a>
      <Link.a href="https://example.com">External Link</Link.a>
      <Link.a navigate={~p"/dashboard"} variant="ghost" color="danger">Dashboard</Link.a>
      <Link.a href="/settings">
        <:start_icon>⚙️</:start_icon>
        Settings
      </Link.a>

  ## Variants
  - `solid` (default): No underline
  - `ghost`: Underline on hover
  - `outline`: Always underlined
  """

  use Phoenix.Component

  import TailwindMerge, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # Pulsar-specific styling attributes
  attr(:variant, :string,
    default: "solid",
    values: ~w(solid ghost outline),
    doc: "Visual style variant of the link. solid=no underline, ghost=hover underline, outline=always underline"
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
  Accessible link with security defaults and Phoenix navigation (href/navigate/patch).
  """
  @spec a(map()) :: Rendered.t()
  def a(assigns) do
    assigns = prepare_link_assigns(assigns)

    if assigns.use_raw_anchor do
      ~H"""
      <a
        phx-no-format
        href={@href}
        target={assigns[:target]}
        rel={assigns[:rel]}
        id={@id}
        class={@merged_classes}
        aria-label={@aria_label}
        aria-describedby={@aria_describedby}
        aria-current={@aria_current}
        data-external={(@external && "true") || nil}
        data-current={@aria_current}
        data-target={assigns[:target]}
        data-method={@method}
        {@rest}
      >
        <.render_icon_slot slot={@start_icon} position="start" />
        {render_slot(@inner_block)}
        <.render_external_icon show_external={@show_external_icon} />
        <.render_icon_slot slot={@end_icon} position="end" />
      </a>
      """
    else
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
        data-current={@aria_current}
        data-target={assigns[:target]}
        {@rest}
      >
        <.render_icon_slot slot={@start_icon} position="start" />
        {render_slot(@inner_block)}
        <.render_external_icon show_external={@show_external_icon} />
        <.render_icon_slot slot={@end_icon} position="end" />
      </.link>
      """
    end
  end

  defp render_icon_slot(assigns) do
    ~H"""
    <span :if={@slot != []} class={icon_position_class(@position)} aria-hidden="true">
      {render_slot(@slot)}
    </span>
    """
  end

  defp render_external_icon(assigns) do
    ~H"""
    <span
      :if={@show_external}
      class="hidden group-data-[target=_blank]:inline-flex items-center ml-1"
      aria-hidden="true"
    >
      <Icon.icon name="hero-arrow-top-right-on-square" class="w-[1em] h-[1em]" color="current" />
    </span>
    """
  end

  defp icon_position_class("start"), do: "inline-flex items-center mr-1"
  defp icon_position_class("end"), do: "inline-flex items-center ml-1"

  defp prepare_link_assigns(assigns) do
    ensure_nav_exclusive!(assigns)
    ensure_method_compatibility!(assigns)

    sanitized_href = sanitize_href(assigns.href)
    is_external = external_link?(sanitized_href)
    use_raw_anchor = should_use_raw_anchor?(sanitized_href)

    assigns
    |> assign(:href, sanitized_href)
    |> assign(:external, is_external)
    |> assign(:use_raw_anchor, use_raw_anchor)
    |> assign(:show_external_icon, is_external && assigns.end_icon == [])
    |> apply_external_security(is_external)
    |> build_classes()
  end

  defp should_use_raw_anchor?(href) when is_binary(href) do
    case URI.parse(href) do
      %URI{scheme: scheme} when scheme in ["mailto", "tel", "http", "https", "ftp"] -> true
      _ -> false
    end
  end

  defp should_use_raw_anchor?(_), do: false

  @dangerous_protocols ~w(javascript data vbscript about file)

  defp sanitize_href(nil), do: nil

  defp sanitize_href(href) when is_binary(href) do
    trimmed = String.trim(href)

    case Regex.run(~r/^\s*([a-z][a-z0-9+.\-]*):/i, trimmed) do
      [_, scheme] -> if String.downcase(scheme) in @dangerous_protocols, do: "#", else: trimmed
      _ -> trimmed
    end
  end

  defp external_link?(nil), do: false

  defp external_link?(href) when is_binary(href) do
    (String.starts_with?(href, "//") && !String.starts_with?(href, "///")) ||
      case URI.parse(href) do
        %URI{scheme: scheme} when is_binary(scheme) ->
          String.downcase(scheme) in ["http", "https", "mailto", "tel", "ftp"]

        _ ->
          false
      end
  end

  defp apply_external_security(assigns, false), do: assigns

  defp apply_external_security(assigns, true) do
    assigns =
      case URI.parse(assigns.href || "") do
        %URI{scheme: scheme} when scheme in ["http", "https"] ->
          if assigns[:target] || assigns[:method], do: assigns, else: assign(assigns, :target, "_blank")

        _ ->
          assigns
      end

    assign_new(assigns, :rel, fn ->
      if assigns[:target] == "_blank", do: "noopener noreferrer"
    end)
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

  # Ensure method is only used with href, not with navigate or patch
  defp ensure_method_compatibility!(assigns) do
    if is_binary(assigns[:method]) and (is_binary(assigns[:navigate]) or is_binary(assigns[:patch])) do
      raise ArgumentError,
            ":method cannot be used with :navigate or :patch. Use :method only with :href for form submissions."
    end

    assigns
  end

  @base_classes """
  group inline-flex items-center cursor-pointer transition-all duration-200 ease-in-out
  focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/50 dark:focus-visible:ring-dark-ring/50
  focus-visible:ring-offset-1
  """

  @variant_classes %{
    "ghost" => "no-underline border-b-2 border-transparent hover:border-current pb-0.5",
    "outline" => "no-underline border-b-2 border-current pb-0.5",
    "solid" => "no-underline"
  }

  @color_classes %{
    "danger" => "text-danger hover:text-danger/80 dark:text-dark-danger dark:hover:text-dark-danger/80",
    "info" => "text-info hover:text-info/80 dark:text-dark-info dark:hover:text-dark-info/80",
    "inherit" => "text-inherit",
    "muted" =>
      "text-muted-foreground hover:text-muted-foreground/70 dark:text-dark-muted-foreground dark:hover:text-dark-muted-foreground/70",
    "primary" => "text-primary hover:text-primary/80 dark:text-dark-primary dark:hover:text-dark-primary/80",
    "secondary" => "text-secondary hover:text-secondary/80 dark:text-dark-secondary dark:hover:text-dark-secondary/80",
    "success" => "text-success hover:text-success/80 dark:text-dark-success dark:hover:text-dark-success/80",
    "warning" => "text-warning hover:text-warning/80 dark:text-dark-warning dark:hover:text-dark-warning/80"
  }

  @size_classes %{
    "inherit" => "",
    "lg" => "text-lg",
    "md" => "text-base",
    "sm" => "text-sm",
    "xl" => "text-xl",
    "xs" => "text-xs"
  }

  defp build_classes(assigns) do
    classes =
      merge([
        @base_classes,
        @variant_classes[assigns.variant],
        @color_classes[assigns.color],
        @size_classes[assigns.size],
        assigns.class
      ])

    assign(assigns, :merged_classes, classes)
  end
end
