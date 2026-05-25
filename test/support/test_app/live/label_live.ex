defmodule Pulsar.TestApp.LabelLive do
  @moduledoc false
  use Pulsar.TestApp.Web, :live_view

  alias Pulsar.Components.Label

  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, sizes: @sizes)

    ~H"""
    <.fixture_page name="label" title="Label">
      <.fixture_section name="sizes" title="Sizes">
        <div class="w-full space-y-2">
          <Label.label
            :for={size <- @sizes}
            for={"input-#{size}"}
            size={size}
            data-fixture-cell={"size-#{size}"}
          >
            Label @ {size}
          </Label.label>
        </div>
      </.fixture_section>
      <.fixture_section name="states" title="Required + error">
        <div class="w-full space-y-2">
          <Label.label for="r1" required data-fixture-cell="required">Required field</Label.label>
          <Label.label for="r2" error data-fixture-cell="error">Field with error</Label.label>
          <Label.label for="r3" required error data-fixture-cell="required-error">
            Required + error
          </Label.label>
        </div>
      </.fixture_section>
    </.fixture_page>
    """
  end
end
