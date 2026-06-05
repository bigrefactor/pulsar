defmodule Pulsar.Components.Pagination do
  @moduledoc """
  Page navigation for tables, lists, and search results.

  Renders a `<nav>` landmark containing a list of links. In `page` mode it shows
  windowed page numbers with previous/next controls and an optional summary; in
  `cursor` mode it shows only previous/next controls (for keyset/cursor
  pagination, where no total is known).

  Navigation is link-based: you supply a `page_href` function that maps a page
  number to a URL (page mode), or `prev_href` / `next_href` strings (cursor mode).
  This maps directly onto a `Flop.Meta` without any coupling to Flop.

  ## Examples

      # Page mode — numbered pages
      <.pagination
        page={@meta.current_page}
        total_pages={@meta.total_pages}
        page_href={fn p -> ~p"/users?page=\#{p}" end}
        show_summary
      />

      # Cursor mode — previous/next only
      <.pagination
        mode="cursor"
        prev_href={@meta.has_previous_page? && ~p"/users?before=\#{@meta.start_cursor}"}
        next_href={@meta.has_next_page? && ~p"/users?after=\#{@meta.end_cursor}"}
      />

  ## Variants

  `variant` controls how the current page is emphasized: `ghost` (subtle tinted
  fill), `solid` (filled in the accent color), `outline` (ringed). `color` sets the
  accent; `size` scales the controls (`xs`–`xl`).
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  @valid_colors ~w(neutral primary secondary success danger warning info)

  # Current-page emphasis per variant.
  @solid_active %{
    "neutral" => "bg-neutral text-neutral-foreground",
    "primary" => "bg-primary text-primary-foreground",
    "secondary" => "bg-secondary text-secondary-foreground",
    "success" => "bg-success text-success-foreground",
    "danger" => "bg-danger text-danger-foreground",
    "warning" => "bg-warning text-warning-foreground",
    "info" => "bg-info text-info-foreground"
  }

  @ghost_active %{
    "neutral" => "bg-muted text-foreground",
    "primary" => "bg-primary/10 text-primary",
    "secondary" => "bg-secondary/10 text-secondary",
    "success" => "bg-success/10 text-success",
    "danger" => "bg-danger/10 text-danger",
    "warning" => "bg-warning/10 text-warning",
    "info" => "bg-info/10 text-info"
  }

  @outline_active %{
    "neutral" => "bg-background border-border-strong text-foreground",
    "primary" => "bg-background border-border-strong text-primary",
    "secondary" => "bg-background border-border-strong text-secondary",
    "success" => "bg-background border-border-strong text-success",
    "danger" => "bg-background border-border-strong text-danger",
    "warning" => "bg-background border-border-strong text-warning",
    "info" => "bg-background border-border-strong text-info"
  }

  # Compile-time check that every color is configured for every variant.
  for color <- @valid_colors do
    for {name, map} <- [solid_active: @solid_active, ghost_active: @ghost_active, outline_active: @outline_active] do
      if !map[color] do
        raise CompileError, description: "Missing pagination #{name} for color=#{color}"
      end
    end
  end

  @size_item %{
    "xs" => "min-w-7 h-7 px-1.5 text-xs gap-1",
    "sm" => "min-w-8 h-8 px-2 text-sm gap-1",
    "md" => "min-w-9 h-9 px-2.5 text-sm gap-1.5",
    "lg" => "min-w-10 h-10 px-3 text-base gap-2",
    "xl" => "min-w-11 h-11 px-3.5 text-lg gap-2"
  }

  @icon_size %{"xs" => "xs", "sm" => "xs", "md" => "sm", "lg" => "sm", "xl" => "md"}

  @item_base "inline-flex items-center justify-center font-medium rounded-field select-none whitespace-nowrap transition-colors duration-fast ease-standard focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 aria-disabled:pointer-events-none aria-disabled:opacity-disabled"

  @list_base "flex flex-row flex-wrap items-center gap-1"

  # ============================================================================
  # COMPONENT
  # ============================================================================

  attr(:mode, :string,
    default: "page",
    values: ~w(page cursor),
    doc: "page = numbered pages + prev/next; cursor = prev/next only (no total)"
  )

  attr(:variant, :string,
    default: "ghost",
    values: ~w(solid outline ghost),
    doc: "How the current page is emphasized"
  )

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Accent color for the active page"
  )

  attr(:size, :string,
    default: "md",
    values: ~w(xs sm md lg xl),
    doc: "Control size"
  )

  attr(:link_type, :string,
    default: "navigate",
    values: ~w(navigate patch href),
    doc: "How page links navigate: LiveView navigate, LiveView patch, or a plain anchor"
  )

  # Page mode
  attr(:page, :integer, default: nil, doc: "Current page (1-based). Required in page mode.")
  attr(:total_pages, :integer, default: nil, doc: "Total number of pages. Required in page mode.")

  attr(:page_href, :any,
    default: nil,
    doc: "Function (page :: integer) -> url. Required in page mode."
  )

  attr(:sibling_count, :integer, default: 1, doc: "Pages shown on each side of the current page")
  attr(:boundary_count, :integer, default: 1, doc: "Pages pinned at each end")
  attr(:total_count, :integer, default: nil, doc: "Total item count (enables item-range summary)")
  attr(:page_size, :integer, default: nil, doc: "Items per page (enables item-range summary)")

  # Cursor mode
  attr(:prev_href, :any, default: nil, doc: "Previous-page URL, or a falsy value when at the start")
  attr(:next_href, :any, default: nil, doc: "Next-page URL, or a falsy value when at the end")

  # Summary
  attr(:show_summary, :boolean, default: false, doc: "Render the textual page/range summary")

  # Localization
  attr(:aria_label, :string, default: nil, doc: ~s{Accessible label for the nav. Use with i18n: gettext("Pagination")})

  attr(:previous_label, :string,
    default: "Previous",
    doc: ~s{Previous-control label. Use with i18n: gettext("Previous")}
  )

  attr(:next_label, :string, default: "Next", doc: ~s{Next-control label. Use with i18n: gettext("Next")})

  attr(:go_to_label_prefix, :string,
    default: "Go to page",
    doc: ~s{Prefix for each page link's aria-label. Use with i18n: gettext("Go to page")}
  )

  attr(:format_page_number, :any,
    default: &Integer.to_string/1,
    doc: "Function (integer -> String) formatting page numbers. Pass a CLDR formatter for locale grouping."
  )

  attr(:format_summary, :any,
    default: nil,
    doc: "Function (context_map -> String) building the summary. Defaults to a Page N of M / item-range formatter."
  )

  attr(:class, :string, default: "", doc: "Additional CSS classes for the nav")
  attr(:rest, :global, doc: "Additional nav attributes")

  @doc """
  Renders page navigation.

  ## Examples

      <.pagination page={3} total_pages={10} page_href={fn p -> "/list?page=\#{p}" end} />
  """
  @spec pagination(map()) :: Rendered.t()
  def pagination(assigns) do
    page? = assigns.mode == "page"
    if page?, do: validate_page_mode!(assigns)

    items =
      if page?,
        do: page_items(assigns.page, assigns.total_pages, assigns.sibling_count, assigns.boundary_count),
        else: []

    prev_href =
      if page? do
        assigns.page > 1 && assigns.page_href.(assigns.page - 1)
      else
        assigns.prev_href
      end

    next_href =
      if page? do
        assigns.page < assigns.total_pages && assigns.page_href.(assigns.page + 1)
      else
        assigns.next_href
      end

    assigns =
      assigns
      |> assign(:page?, page?)
      |> assign(:items, items)
      |> assign(:prev_href, prev_href)
      |> assign(:next_href, next_href)
      |> assign(:nav_label, assigns.aria_label || "Pagination")
      |> assign(:summary_text, summary_text(assigns))
      |> assign(:icon, @icon_size[assigns.size])
      |> assign(:root_class, merge(["flex flex-col gap-2", assigns.class]))
      |> assign(:list_class, @list_base)
      |> assign(:control_class, control_classes(assigns.variant, assigns.size))

    ~H"""
    <nav aria-label={@nav_label} class={@root_class} {@rest}>
      <ul class={@list_class}>
        <li>
          <.link
            :if={@prev_href}
            navigate={(@link_type == "navigate" && @prev_href) || nil}
            patch={(@link_type == "patch" && @prev_href) || nil}
            href={(@link_type == "href" && @prev_href) || nil}
            rel="prev"
            class={@control_class}
          >
            <Icon.icon name="hero-chevron-left" size={@icon} />
            {@previous_label}
          </.link>
          <span :if={!@prev_href} aria-disabled="true" class={@control_class}>
            <Icon.icon name="hero-chevron-left" size={@icon} />
            {@previous_label}
          </span>
        </li>

        <li :for={item <- @items}>
          <span :if={item == :ellipsis} aria-hidden="true" class={ellipsis_classes(@size)}>…</span>
          <.link
            :if={item != :ellipsis}
            navigate={(@link_type == "navigate" && @page_href.(item)) || nil}
            patch={(@link_type == "patch" && @page_href.(item)) || nil}
            href={(@link_type == "href" && @page_href.(item)) || nil}
            aria-current={(item == @page && "page") || nil}
            aria-label={"#{@go_to_label_prefix} #{@format_page_number.(item)}"}
            class={item_classes(@variant, @color, @size, item == @page)}
          >
            {@format_page_number.(item)}
          </.link>
        </li>

        <li>
          <.link
            :if={@next_href}
            navigate={(@link_type == "navigate" && @next_href) || nil}
            patch={(@link_type == "patch" && @next_href) || nil}
            href={(@link_type == "href" && @next_href) || nil}
            rel="next"
            class={@control_class}
          >
            {@next_label}
            <Icon.icon name="hero-chevron-right" size={@icon} />
          </.link>
          <span :if={!@next_href} aria-disabled="true" class={@control_class}>
            {@next_label}
            <Icon.icon name="hero-chevron-right" size={@icon} />
          </span>
        </li>
      </ul>

      <p :if={@summary_text} aria-live="polite" class="text-sm text-muted-foreground">
        {@summary_text}
      </p>
    </nav>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  @spec validate_page_mode!(map()) :: :ok
  defp validate_page_mode!(assigns) do
    cond do
      !is_integer(assigns.page) ->
        raise ArgumentError, "pagination: page mode requires an integer :page"

      !is_integer(assigns.total_pages) ->
        raise ArgumentError, "pagination: page mode requires an integer :total_pages"

      !is_function(assigns.page_href, 1) ->
        raise ArgumentError, "pagination: page mode requires :page_href as a 1-arity function"

      true ->
        :ok
    end
  end

  # Windowed page list. Returns integers and `:ellipsis` markers.
  @spec page_items(pos_integer(), pos_integer(), non_neg_integer(), pos_integer()) :: [pos_integer() | :ellipsis]
  defp page_items(page, count, sibling_count, boundary_count) do
    start_pages = inclusive_range(1, min(boundary_count, count))
    end_pages = inclusive_range(max(count - boundary_count + 1, boundary_count + 1), count)

    siblings_start =
      max(
        min(page - sibling_count, count - boundary_count - sibling_count * 2 - 1),
        boundary_count + 2
      )

    siblings_end =
      min(
        max(page + sibling_count, boundary_count + sibling_count * 2 + 2),
        case end_pages do
          [first | _] -> first - 2
          [] -> count - 1
        end
      )

    left_filler =
      cond do
        siblings_start > boundary_count + 2 -> [:ellipsis]
        boundary_count + 1 < count - boundary_count -> [boundary_count + 1]
        true -> []
      end

    right_filler =
      cond do
        siblings_end < count - boundary_count - 1 -> [:ellipsis]
        count - boundary_count > boundary_count -> [count - boundary_count]
        true -> []
      end

    start_pages ++ left_filler ++ inclusive_range(siblings_start, siblings_end) ++ right_filler ++ end_pages
  end

  @spec inclusive_range(integer(), integer()) :: [integer()]
  defp inclusive_range(first, last) when first > last, do: []
  defp inclusive_range(first, last), do: Enum.to_list(first..last)

  @spec summary_text(map()) :: String.t() | nil
  defp summary_text(%{show_summary: false}), do: nil
  defp summary_text(%{mode: "cursor"}), do: nil

  defp summary_text(assigns) do
    formatter = assigns.format_summary || (&default_summary/1)

    {from, to} =
      if is_integer(assigns.page_size) and is_integer(assigns.total_count) do
        from = (assigns.page - 1) * assigns.page_size + 1
        to = min(assigns.page * assigns.page_size, assigns.total_count)
        {from, to}
      else
        {nil, nil}
      end

    formatter.(%{
      page: assigns.page,
      total_pages: assigns.total_pages,
      from: from,
      to: to,
      total_count: assigns.total_count
    })
  end

  @spec default_summary(map()) :: String.t()
  defp default_summary(%{from: from, to: to, total_count: total}) when not is_nil(from) and not is_nil(total) do
    "#{from}–#{to} of #{total}"
  end

  defp default_summary(%{page: page, total_pages: total_pages}) do
    "Page #{page} of #{total_pages}"
  end

  @spec item_classes(String.t(), String.t(), String.t(), boolean()) :: String.t()
  defp item_classes(variant, color, size, active?) do
    merge([
      @item_base,
      @size_item[size] || "",
      item_state(variant, color, active?)
    ])
  end

  @spec item_state(String.t(), String.t(), boolean()) :: String.t()
  defp item_state("outline", _color, false),
    do: "border border-border text-muted-foreground hover:bg-muted hover:text-foreground"

  defp item_state("outline", color, true), do: "border #{@outline_active[color]}"
  defp item_state("solid", _color, false), do: "text-muted-foreground hover:bg-muted hover:text-foreground"
  defp item_state("solid", color, true), do: @solid_active[color]
  defp item_state(_ghost, _color, false), do: "text-muted-foreground hover:bg-muted hover:text-foreground"
  defp item_state(_ghost, color, true), do: @ghost_active[color]

  # Prev/next controls share the resting item look but never the active fill.
  @spec control_classes(String.t(), String.t()) :: String.t()
  defp control_classes(variant, size) do
    border = if variant == "outline", do: "border border-border", else: ""

    merge([
      @item_base,
      @size_item[size] || "",
      border,
      "text-muted-foreground hover:bg-muted hover:text-foreground"
    ])
  end

  @spec ellipsis_classes(String.t()) :: String.t()
  defp ellipsis_classes(size) do
    merge([@item_base, @size_item[size] || "", "text-muted-foreground pointer-events-none"])
  end
end
