defmodule Pulsar.ComponentDeps do
  @moduledoc """
  The component dependency graph shared by `mix pulsar.install` and the
  standalone `mix pulsar.gen.*` tasks.

  Each key is a generatable component; the value lists the components it
  depends on. New components must be registered here — `use Pulsar.Generator`
  rejects unregistered components at compile time, and every dependency must
  itself be a key (validated at compile time).
  """

  alias Pulsar.ComponentDeps.Graph

  @components %{
    accordion: [:icon],
    alert: [:icon],
    alert_dialog: [:modal, :button],
    avatar: [:icon, :link],
    badge: [],
    breadcrumb: [:icon, :link],
    button: [:link],
    calendar: [],
    card: [],
    checkbox: [],
    collapsible: [:icon],
    date_picker: [:calendar, :popover, :icon],
    divider: [],
    drawer: [:modal, :button],
    dropdown_menu: [:icon, :popover],
    dropzone: [:icon, :progress],
    field: [
      :checkbox,
      :date_picker,
      :icon,
      :input,
      :input_otp,
      :label,
      :radio_group,
      :select,
      :switch,
      :textarea
    ],
    flash: [],
    flash_group: [:flash, :icon],
    form: [],
    header: [:link, :icon, :breadcrumb],
    icon: [],
    input: [],
    input_otp: [],
    label: [],
    link: [:icon],
    list: [],
    menu: [:icon, :popover],
    modal: [:icon],
    navbar: [:icon],
    pagination: [:icon],
    popover: [],
    progress: [],
    radio_group: [],
    resizable: [:icon],
    select: [:badge],
    sidebar: [],
    skeleton: [],
    spinner: [],
    status: [],
    steps: [:icon],
    switch: [],
    table: [],
    tabs: [:icon],
    textarea: [],
    tooltip: [:popover]
  }

  @order Graph.topological_order!(@components)

  @doc "Every registered component, dependencies first."
  def all, do: @order

  @doc "Direct dependencies of `component`. Raises `KeyError` if unregistered."
  def deps(component), do: Map.fetch!(@components, component)

  @doc "Transitive dependency closure of `selection`, selection included."
  def resolve(selection) do
    selection
    |> Enum.reduce(MapSet.new(), &do_resolve/2)
    |> MapSet.to_list()
  end

  @doc "The transitive closure of `selection` in dependency-first order."
  def resolution_order(selection) do
    closure = selection |> resolve() |> MapSet.new()
    Enum.filter(@order, &MapSet.member?(closure, &1))
  end

  defp do_resolve(component, acc) do
    if MapSet.member?(acc, component) do
      acc
    else
      component
      |> deps()
      |> Enum.reduce(MapSet.put(acc, component), &do_resolve/2)
    end
  end
end
