defmodule Pulsar.DevApp.ProgressLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Progress

  @colors ~w(neutral primary secondary success danger warning info)
  @sizes ~w(xs sm md lg xl)

  def render(assigns) do
    assigns = assign(assigns, colors: @colors, sizes: @sizes)

    ~H"""
    <.fixture_page name="progress" title="Progress">
      <.fixture_section name="linear-determinate" title="Linear — determinate">
        <div :for={color <- @colors} class="w-64">
          <Progress.progress
            value={62}
            color={color}
            label={"#{color} upload"}
            show_value
            data-fixture-cell={"linear-#{color}"}
          />
        </div>
      </.fixture_section>

      <.fixture_section name="linear-sizes" title="Linear — sizes">
        <div :for={size <- @sizes} class="w-64">
          <Progress.progress
            value={45}
            size={size}
            label={"size #{size}"}
            data-fixture-cell={"size-#{size}"}
          />
        </div>
      </.fixture_section>

      <.fixture_section name="linear-indeterminate" title="Linear — indeterminate">
        <div class="w-64">
          <Progress.progress label="Loading data" data-fixture-cell="indeterminate" />
        </div>
      </.fixture_section>

      <.fixture_section name="radial" title="Radial — determinate">
        <Progress.progress
          :for={color <- @colors}
          shape="radial"
          value={62}
          color={color}
          show_value
          label={"#{color} progress"}
          data-fixture-cell={"radial-#{color}"}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
