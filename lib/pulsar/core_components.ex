defmodule Pulsar.CoreComponents do
  @moduledoc """
  Core UI components using Pulsar styling.

  Provides essential components like flash notifications and icons with
  Pulsar's enhanced styling and behavior.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Flash
  alias Pulsar.Components.FlashGroup
  alias Pulsar.Components.Icon

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} title="Error" />
      <.flash kind={:info} variant="outline" flash={@flash} />
      <.flash color="warning" variant="ghost" flash={@flash} />
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  # Pulsar enhancement attributes
  attr :variant, :string,
    default: "solid",
    values: ~w(solid outline ghost),
    doc: "Visual style variant of the flash"

  attr :color, :string,
    default: "neutral",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Color scheme (used when kind is not provided)"

  attr :size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "Size of the flash notification"

  attr :auto_dismiss, :boolean,
    default: true,
    doc: "Automatically dismiss after timeout"

  attr :dismiss_after, :integer,
    default: 5000,
    doc: "Milliseconds before auto-dismiss"

  attr :dismissible, :boolean,
    default: true,
    doc: "Show close button for manual dismissal"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      class="fixed top-4 right-4 z-50 max-w-sm w-full"
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_flash("##{@id}")}
      role={map_kind_to_role(@kind)}
    >
      <Flash.flash
        id={"#{@id}-flash"}
        variant={@variant}
        color={@kind && map_kind_to_color(@kind) || @color}
        size={@size}
        auto_dismiss={@auto_dismiss}
        dismiss_after={@dismiss_after}
        dismissible={@dismissible}
        role={map_kind_to_role(@kind)}
        on_dismiss="lv:clear-flash"
        flash_key={@kind && to_string(@kind)}
        class={@rest[:class] || ""}
        {Map.drop(@rest, [:class])}
      >
        <:start_icon>
          <Icon.icon name={get_flash_icon(@kind)} variant="mini" size="sm" />
        </:start_icon>
        <div :if={@title}>
          <p class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div :if={!@title}>
          {msg}
        </div>
      </Flash.flash>
    </div>
    """
  end

  @doc """
  Renders a group of flash notifications.

  ## Examples

      <.flash_group flash={@flash} />
      <.flash_group flash={@flash} variant="outline" position="bottom-right" />
  """
  defdelegate flash_group(assigns), to: FlashGroup

  @doc """
  Renders an icon.

  ## Examples

      <.icon name="hero-check" class="size-4" />
      <.icon name="hero-check" variant="solid" color="success" size="lg" />
  """
  defdelegate icon(assigns), to: Icon

  # === Helper Functions ===

  # Map Phoenix flash kinds to Pulsar colors
  defp map_kind_to_color(:info), do: "info"
  defp map_kind_to_color(:error), do: "danger"
  defp map_kind_to_color(_), do: "neutral"

  # Map Phoenix flash kinds to ARIA roles
  defp map_kind_to_role(:error), do: "alert"
  defp map_kind_to_role(_), do: "status"

  # Get appropriate icon for flash kind
  defp get_flash_icon(:info), do: "hero-information-circle"
  defp get_flash_icon(:error), do: "hero-exclamation-circle"
  defp get_flash_icon(_), do: "hero-bell"

  # Hide flash with animation
  defp hide_flash(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition: {
        "transition-all ease-in duration-200",
        "opacity-100 translate-y-0 sm:scale-100",
        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
      }
    )
  end
end