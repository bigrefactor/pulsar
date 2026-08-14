defmodule Pulsar.ComponentDepsTest do
  use ExUnit.Case, async: true

  alias Pulsar.ComponentDeps

  test "all/0 lists every component with dependencies first" do
    all = ComponentDeps.all()

    assert :icon in all
    assert :dropzone in all

    for component <- all, dep <- ComponentDeps.deps(component) do
      assert Enum.find_index(all, &(&1 == dep)) < Enum.find_index(all, &(&1 == component)),
             "expected #{dep} to come before #{component}"
    end
  end

  test "deps/1 returns direct dependencies" do
    assert ComponentDeps.deps(:dropzone) == [:icon, :progress]
    assert ComponentDeps.deps(:table) == [:icon]
    assert ComponentDeps.deps(:badge) == []
  end

  test "deps/1 raises for unregistered components" do
    assert_raise KeyError, fn -> ComponentDeps.deps(:not_a_component) end
  end

  test "resolve/1 returns the transitive closure including the selection" do
    assert ComponentDeps.resolve([:date_picker]) |> Enum.sort() ==
             [:calendar, :date_picker, :icon, :popover]
  end

  test "resolve/1 follows chained dependencies" do
    assert ComponentDeps.resolve([:button]) |> Enum.sort() == [:button, :icon, :link]
  end

  test "resolution_order/1 puts dependencies before dependents" do
    order = ComponentDeps.resolution_order([:date_picker])

    assert Enum.sort(order) == [:calendar, :date_picker, :icon, :popover]
    assert List.last(order) == :date_picker
    assert List.first(order) == :icon
  end

  test "resolution_order/1 is deterministic" do
    assert ComponentDeps.resolution_order([:field]) == ComponentDeps.resolution_order([:field])
  end

  test "deps match each component template's sibling imports exactly" do
    for component <- ComponentDeps.all() do
      template =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("#{component}.ex.eex")

      imports =
        ~r/(?:import|alias) <%= @component_namespace %>\.([A-Za-z]+)/
        |> Regex.scan(File.read!(template))
        |> Enum.map(fn [_, mod] -> mod |> Macro.underscore() |> String.to_existing_atom() end)
        |> Enum.uniq()
        |> Enum.sort()

      assert Enum.sort(ComponentDeps.deps(component)) == imports,
             "#{component}: map deps #{inspect(Enum.sort(ComponentDeps.deps(component)))} " <>
               "do not match template imports #{inspect(imports)}"
    end
  end
end
