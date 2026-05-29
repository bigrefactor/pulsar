defmodule Pulsar.DevApp.SelectMultiLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Select

  @options [{"One", "1"}, {"Two", "2"}, {"Three", "3"}]

  def render(assigns) do
    assigns = assign(assigns, options: @options)

    ~H"""
    <.fixture_page name="select-multi" title="Select (multi)">
      <.fixture_section name="multi" title="Multi-select">
        <Select.select
          id="sel-multi"
          name="sel_multi"
          multiple
          options={@options}
          aria-label="multi-select"
          data-fixture-cell="multi"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
