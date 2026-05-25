defmodule Pulsar.TestApp.FlashGroupLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.FlashGroup

  @positions ~w(top-right top-left bottom-right bottom-left top-center bottom-center)

  def render(assigns) do
    assigns =
      assign(assigns,
        positions: @positions,
        flash: %{
          "info" => "An info flash message",
          "success" => "A success flash message",
          "warning" => "A warning flash message",
          "error" => "An error flash message"
        }
      )

    ~H"""
    <.fixture_page name="flash_group" title="FlashGroup">
      <.fixture_section
        :for={position <- @positions}
        name={"position-#{position}"}
        title={"position: #{position}"}
      >
        <div class="relative h-40 w-full overflow-hidden rounded border border-border">
          <FlashGroup.flash_group
            flash={@flash}
            position={position}
            data-fixture-cell={"position-#{position}"}
          />
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
