defmodule Pulsar.Components.Command do
  @moduledoc """
  A searchable, keyboard-navigable list of options.

  Renders a query field over a filtered list and reports the chosen option to
  the caller. It holds no value of its own: pick an option, the caller acts on
  it, and the query resets.

  Use it inline, or inside a popover or modal that provides the surface.

  ## Examples

      <.command id="fields" options={@fields} on_select={JS.push("field_chosen")} />
  """

  use Phoenix.LiveComponent

  import Twm, only: [merge: 1]

  attr(:id, :string, required: true, doc: "Root ID. Wires the query field to the list and its options.")
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a searchable, keyboard-navigable option list.
  """
  def command(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={@id} class={@class} {@rest} />
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> %{} end)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class={merge("flex flex-col " <> @class)} {@rest}></div>
    """
  end
end
