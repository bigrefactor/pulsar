defmodule Pulsar.Components.Avatar do
  @moduledoc """
  Avatar component for showing a user or entity with an image, initials, or icon.

  Renders a circular avatar from an image when `src` is given, falling back to
  initials derived from `name`, and finally to a generic user icon. Avatars can
  be linked and composed into an overlapping group with an overflow counter.

  ## Features

  - **Image with fallback**: `src` → initials from `name` → user icon
  - **Sizes**: xs, sm, md, lg, xl, 2xl
  - **Variants**: solid (filled) and outline (bordered)
  - **Linkable**: pass `href`, `navigate`, or `patch` to make the avatar a link
  - **Group composition**: `avatar_group/1` overlaps avatars with a `+N` overflow

  ## Examples

      # Image avatar
      <.avatar src={@user.avatar_url} name={@user.name} />

      # Initials fallback (no image)
      <.avatar name="Jane Doe" />

      # Icon fallback (no image, no name)
      <.avatar />

      # Sizes and outline variant
      <.avatar name="Jane Doe" size="lg" variant="outline" />

      # Linked avatar
      <.avatar name="Jane Doe" navigate={@profile_path} />

      # Overlapping group with overflow
      <.avatar_group max={3}>
        <:item :for={user <- @users}>
          <.avatar src={user.avatar_url} name={user.name} navigate={user.profile_path} />
        </:item>
      </.avatar_group>

  ## Accessible name

  The accessible name resolves to `alt || name`. For image avatars it becomes the
  `<img>` `alt`; for initials/icon avatars it is exposed via `role="img"` and
  `aria-label`. Pass `alt=""` to mark an avatar purely decorative. Provide `name`
  (or `alt`) whenever the avatar conveys identity — an unnamed icon avatar is
  silent to screen readers.

  A linked avatar (`href`, `navigate`, or `patch`) must be given a `name` or
  `alt` so the link has an accessible name; rendered without one it logs a
  warning.
  """

  use Phoenix.Component

  import Twm, only: [merge: 1]

  alias Phoenix.LiveView.Rendered
  alias Pulsar.Components.Icon
  alias Pulsar.Components.Link

  # ============================================================================
  # CONFIGURATION & CONSTANTS
  # ============================================================================

  # Per-size box dimensions, initials text size, and fallback-icon dimensions.
  @size_config %{
    "xs" => %{box: "w-6 h-6", text: "text-xs", icon: "w-4 h-4"},
    "sm" => %{box: "w-8 h-8", text: "text-sm", icon: "w-5 h-5"},
    "md" => %{box: "w-10 h-10", text: "text-base", icon: "w-6 h-6"},
    "lg" => %{box: "w-12 h-12", text: "text-lg", icon: "w-7 h-7"},
    "xl" => %{box: "w-14 h-14", text: "text-xl", icon: "w-8 h-8"},
    "2xl" => %{box: "w-16 h-16", text: "text-2xl", icon: "w-10 h-10"}
  }

  @avatar_base_classes "relative inline-flex shrink-0 items-center justify-center " <>
                         "overflow-hidden rounded-avatar align-middle font-medium select-none"

  @variant_config %{
    "solid" => "bg-muted text-foreground",
    "outline" => "bg-background text-foreground border border-border-strong"
  }

  # Focus ring applied only when the avatar is a link.
  @link_focus_classes "focus-visible:outline-none focus-visible:ring-2 " <>
                        "focus-visible:ring-ring focus-visible:ring-offset-2"

  # Overlap, alignment, and per-child separation ring for grouped avatars.
  @group_base_classes "inline-flex items-center -space-x-2 " <>
                        "[&>*]:ring-2 [&>*]:ring-background"

  # ============================================================================
  # AVATAR COMPONENT
  # ============================================================================

  attr :src, :string, default: nil, doc: "Image URL. When present, renders an <img>"

  attr :name, :string,
    default: nil,
    doc:
      "Entity name. Reduced to initials for the fallback and used as the accessible name. " <>
        "A string of two characters or fewer is used as-is (uppercased)"

  attr :alt, :string,
    default: nil,
    doc: "Overrides the accessible name (image alt / aria-label). Pass \"\" for a decorative avatar"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline),
    doc: "Visual style: solid (filled) or outline (bordered)"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl 2xl),
    doc: "Avatar size"

  attr :href, :any, default: nil, doc: "External URL — makes the avatar a link"
  attr :navigate, :any, default: nil, doc: "Phoenix route to navigate to — makes the avatar a link"
  attr :patch, :any, default: nil, doc: "Phoenix route to patch to — makes the avatar a link"

  attr :target, :string,
    default: nil,
    doc:
      "Link target for a linked avatar. Defaults to same-tab; pass \"_blank\" to open a new tab " <>
        "(an external href otherwise stays in place rather than inheriting Link's forced new tab)"

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  @doc """
  Renders an avatar from an image, initials, or a fallback icon.
  """
  @spec avatar(map()) :: Rendered.t()
  def avatar(assigns) do
    initials = initials(assigns.name)
    acc_name = accessible_name(assigns.alt, assigns.name)

    mode =
      cond do
        present?(assigns.src) -> :image
        initials != "" -> :initials
        true -> :icon
      end

    assigns =
      assigns
      |> assign(:mode, mode)
      |> assign(:initials, initials)
      |> assign(:acc_name, acc_name)
      |> assign(:interactive, interactive?(assigns))
      |> assign(:class, build_avatar_classes(assigns))
      |> assign(:text_class, text_classes(assigns.size))
      |> assign(:icon_class, icon_classes(assigns.size))

    warn_if_unnamed_link(assigns)

    render_avatar(assigns)
  end

  # Interactive: render as a secure link with the avatar styling applied.
  defp render_avatar(%{interactive: true} = assigns) do
    ~H"""
    <Link.a
      href={@href}
      navigate={@navigate}
      patch={@patch}
      target={@target || "_self"}
      variant="solid"
      color="inherit"
      size="inherit"
      class={@class}
      aria_label={link_label(@mode, @acc_name)}
      {@rest}
    >
      <.avatar_content
        mode={@mode}
        src={@src}
        acc_name={@acc_name}
        initials={@initials}
        text_class={@text_class}
        icon_class={@icon_class}
      />
    </Link.a>
    """
  end

  # Non-interactive: a plain wrapper. The wrapper carries the accessible name only
  # for the initials/icon fallbacks; the image branch is named by its own <img alt>.
  defp render_avatar(assigns) do
    ~H"""
    <span class={@class} role={wrapper_role(@mode, @acc_name)} aria-label={wrapper_label(@mode, @acc_name)} {@rest}>
      <.avatar_content
        mode={@mode}
        src={@src}
        acc_name={@acc_name}
        initials={@initials}
        text_class={@text_class}
        icon_class={@icon_class}
      />
    </span>
    """
  end

  # The visual content for each fallback mode. Initials/icon are aria-hidden so the
  # wrapper (or link) supplies the single accessible name.
  defp avatar_content(%{mode: :image} = assigns) do
    ~H"""
    <img src={@src} alt={@acc_name || ""} class="h-full w-full object-cover" />
    """
  end

  defp avatar_content(%{mode: :initials} = assigns) do
    ~H"""
    <span aria-hidden="true" class={@text_class}>{@initials}</span>
    """
  end

  defp avatar_content(%{mode: :icon} = assigns) do
    ~H"""
    <Icon.icon name="hero-user-solid" color="current" class={@icon_class} />
    """
  end

  # ============================================================================
  # AVATAR GROUP COMPONENT
  # ============================================================================

  attr :max, :integer,
    default: nil,
    doc: "Maximum avatars to show before collapsing the rest into a +N counter"

  attr :size, :string,
    default: "md",
    values: ~w(xs sm md lg xl 2xl),
    doc: "Size of the overflow counter (each item avatar sets its own size)"

  attr :format_count, :any,
    default: &Integer.to_string/1,
    doc: ~s{Formats the overflow count. Use with i18n: &MyAppWeb.Cldr.Number.to_string!/1}

  attr :href, :any, default: nil, doc: "External URL for the overflow counter"
  attr :navigate, :any, default: nil, doc: "Phoenix route for the overflow counter"
  attr :patch, :any, default: nil, doc: "Phoenix route for the overflow counter"
  attr :target, :string, default: nil, doc: "Link target for a linked overflow counter"

  attr :class, :string, default: "", doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  slot :item, doc: "An avatar in the group. Render a single <.avatar> inside each item"

  @doc """
  Renders a group of overlapping avatars with an optional `+N` overflow counter.
  """
  @spec avatar_group(map()) :: Rendered.t()
  def avatar_group(assigns) do
    items = assigns.item
    max = assigns.max

    {visible, overflow} =
      if is_integer(max) and max > 0 and length(items) > max do
        {Enum.take(items, max), length(items) - max}
      else
        {items, 0}
      end

    assigns =
      assigns
      |> assign(:visible, visible)
      |> assign(:overflow, overflow)
      |> assign(:class, merge([@group_base_classes, assigns.class]))
      |> assign(:counter_class, counter_classes(assigns.size))
      |> assign(:overflow_interactive, interactive?(assigns))

    ~H"""
    <div class={@class} {@rest}>
      <.avatar_group_item :for={item <- @visible} item={item} />
      <.overflow_counter
        :if={@overflow > 0}
        label={"+" <> @format_count.(@overflow)}
        class={@counter_class}
        interactive={@overflow_interactive}
        href={@href}
        navigate={@navigate}
        patch={@patch}
        target={@target}
      />
    </div>
    """
  end

  # Renders one group item's content with no wrapping element, so each avatar
  # stays a direct child of the group container (where the separation ring lands).
  defp avatar_group_item(assigns) do
    ~H"""
    {render_slot(@item)}
    """
  end

  defp overflow_counter(%{interactive: true} = assigns) do
    ~H"""
    <Link.a
      href={@href}
      navigate={@navigate}
      patch={@patch}
      target={@target || "_self"}
      variant="solid"
      color="inherit"
      size="inherit"
      class={@class}
      aria_label={@label}
    >
      {@label}
    </Link.a>
    """
  end

  defp overflow_counter(assigns) do
    ~H"""
    <span class={@class} role="img" aria-label={@label}>
      <span aria-hidden="true">{@label}</span>
    </span>
    """
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

  defp build_avatar_classes(assigns) do
    merge([
      @avatar_base_classes,
      variant_classes(assigns.variant),
      box_classes(assigns.size),
      if(interactive?(assigns), do: @link_focus_classes, else: ""),
      assigns.class
    ])
  end

  defp counter_classes(size) do
    merge([
      @avatar_base_classes,
      @variant_config["solid"],
      box_classes(size),
      text_classes(size),
      @link_focus_classes
    ])
  end

  @spec variant_classes(String.t()) :: String.t()
  defp variant_classes(variant), do: @variant_config[variant] || @variant_config["solid"]

  @spec box_classes(String.t()) :: String.t()
  defp box_classes(size), do: @size_config[size][:box] || ""

  @spec text_classes(String.t()) :: String.t()
  defp text_classes(size), do: @size_config[size][:text] || ""

  @spec icon_classes(String.t()) :: String.t()
  defp icon_classes(size), do: @size_config[size][:icon] || ""

  # Accessible name precedence: an explicit alt (including "") wins over name.
  defp accessible_name(nil, name), do: name
  defp accessible_name(alt, _name), do: alt

  # Emit a dev-time nudge when a linked avatar has no accessible name. An
  # interactive avatar with no name/alt renders an <a> with no discernible text
  # (the icon/initials content is aria-hidden) — a WCAG 2.4.4 / 4.1.2 failure.
  # Phoenix convention: caller-facing "you may be holding it wrong" nudges use
  # Logger.warning; the caller's log level filter controls visibility.
  defp warn_if_unnamed_link(%{interactive: true, acc_name: acc_name}) do
    if !present?(acc_name) do
      require Logger

      Logger.warning("""
      <.avatar> rendered as a link without an accessible name. A linked avatar
      needs a discernible name (WCAG 2.4.4). Provide one of:
        * name attr
        * alt attr
      """)
    end

    :ok
  end

  defp warn_if_unnamed_link(_assigns), do: :ok

  # The link/wrapper label is suppressed in image mode, where <img alt> names it.
  defp link_label(:image, _acc), do: nil
  defp link_label(_mode, acc), do: present_or_nil(acc)

  defp wrapper_role(:image, _acc), do: nil
  defp wrapper_role(_mode, acc), do: if(present_or_nil(acc), do: "img")

  defp wrapper_label(:image, _acc), do: nil
  defp wrapper_label(_mode, acc), do: present_or_nil(acc)

  defp interactive?(assigns) do
    not is_nil(assigns[:href]) or not is_nil(assigns[:navigate]) or not is_nil(assigns[:patch])
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp present_or_nil(value), do: if(present?(value), do: value)

  # Reduce a name to at most two uppercase initials.
  @spec initials(String.t() | nil) :: String.t()
  defp initials(nil), do: ""

  defp initials(name) when is_binary(name) do
    trimmed = String.trim(name)

    cond do
      trimmed == "" ->
        ""

      String.length(trimmed) <= 2 ->
        String.upcase(trimmed)

      true ->
        case String.split(trimmed, ~r/\s+/, trim: true) do
          [single] -> String.upcase(String.first(single))
          words -> String.upcase(String.first(List.first(words)) <> String.first(List.last(words)))
        end
    end
  end
end
