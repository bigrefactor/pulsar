defmodule Pulsar.DevApp.ComboboxLive do
  @moduledoc """
  Fixture for `Pulsar.Components.Combobox`. One cell per variant, plus cells
  with a value already chosen, a multi-select, a grouped list, and an
  async-filtered list whose results are never in `options`.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Combobox

  @options [{"Alpha", "alpha"}, {"Beta", "beta"}, {"Betamax", "betamax"}]

  def mount(_params, _session, socket), do: {:ok, socket}

  # Returns values deliberately absent from `options`, so the async path and
  # the hook's option-creation branch are both exercised.
  def remote_search(query, _options) do
    Enum.filter(
      [{"Remote One", "r1"}, {"Remote Two", "r2"}],
      fn {label, _value} -> String.contains?(String.downcase(label), String.downcase(query)) end
    )
  end

  def render(assigns) do
    assigns = assign(assigns, :options, @options)

    ~H"""
    <.fixture_page name="combobox" title="Combobox">
      <.fixture_section :for={variant <- ~w(outline solid ghost)} name={variant} title={variant}>
        <Combobox.combobox
          id={"cb-" <> variant}
          label={"Pick a " <> variant <> " value"}
          variant={variant}
          options={@options}
        />
      </.fixture_section>

      <.fixture_section name="selected" title="With a value">
        <Combobox.combobox id="cb-selected" label="Pick an owner" options={@options} value="beta" />
      </.fixture_section>

      <.fixture_section name="multiple" title="Multiple">
        <Combobox.combobox
          id="cb-multiple"
          label="Pick tags"
          name="tags[]"
          multiple
          options={@options}
          value={["alpha"]}
        />
      </.fixture_section>

      <.fixture_section name="grouped" title="Grouped">
        <Combobox.combobox
          id="cb-grouped"
          label="Pick a region"
          options={[{"Europe", ["UK", "Sweden"]}, {"Asia", ["Japan"]}]}
        />
      </.fixture_section>

      <.fixture_section name="async" title="Async source">
        <Combobox.combobox
          id="cb-async"
          label="Search remotely"
          options={[]}
          filter={&__MODULE__.remote_search/2}
          async
          debounce={0}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
