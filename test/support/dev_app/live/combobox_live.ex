defmodule Pulsar.DevApp.ComboboxLive do
  @moduledoc """
  Fixture for `Pulsar.Components.Combobox`. One cell per variant, plus cells
  with a value already chosen, a multi-select, a grouped list, and an
  async-filtered list whose results are never in `options`.
  """
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Combobox

  @options [{"Alpha", "alpha"}, {"Beta", "beta"}, {"Betamax", "betamax"}]

  def mount(_params, _session, socket) do
    params = if connected?(socket), do: get_connect_params(socket) || %{}, else: %{}
    {:ok, assign(socket, :filter, filter_fun(params["probe"]))}
  end

  # Returns values deliberately absent from `options`, so the async path and
  # the hook's option-creation branch are both exercised.
  def remote_search(query, _options) do
    Enum.filter(
      [{"Remote One", "r1"}, {"Remote Two", "r2"}],
      fn {label, _value} -> String.contains?(String.downcase(label), String.downcase(query)) end
    )
  end

  # A test that passes its own pid as the `probe` connect param gets a filter it
  # controls: the task announces itself and then blocks, so the test can observe
  # whether a second query kills the first task or leaves it running.
  defp filter_fun(probe) when is_pid(probe) do
    fn query, options ->
      send(probe, {:filtering, query, self()})

      receive do
        :release -> remote_search(query, options)
      end
    end
  end

  defp filter_fun(_probe), do: &__MODULE__.remote_search/2

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
        <Combobox.combobox
          id="cb-selected"
          label="Pick an owner"
          name="owner_id"
          options={@options}
          value="beta"
        />
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
          filter={@filter}
          async
          debounce={0}
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end
