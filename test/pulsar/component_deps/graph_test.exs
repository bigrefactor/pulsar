defmodule Pulsar.ComponentDeps.GraphTest do
  use ExUnit.Case, async: true

  alias Pulsar.ComponentDeps.Graph

  describe "topological_order!/1" do
    test "orders dependencies before dependents" do
      assert Graph.topological_order!(%{a: [:b], b: [:c], c: []}) == [:c, :b, :a]
    end

    test "includes independent components in deterministic (sorted) order" do
      assert Graph.topological_order!(%{c: [], a: [], b: []}) == [:a, :b, :c]
    end

    test "handles shared dependencies once" do
      order = Graph.topological_order!(%{a: [:c], b: [:c], c: []})
      assert Enum.sort(order) == [:a, :b, :c]
      assert List.first(order) == :c
    end

    test "raises when a dependency is not a key" do
      assert_raise ArgumentError, ~r/not a registered component/, fn ->
        Graph.topological_order!(%{a: [:missing]})
      end
    end

    test "raises on a dependency cycle" do
      assert_raise ArgumentError, ~r/cycle/, fn ->
        Graph.topological_order!(%{a: [:b], b: [:a]})
      end
    end
  end
end
