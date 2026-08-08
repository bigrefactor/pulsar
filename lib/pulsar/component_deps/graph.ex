defmodule Pulsar.ComponentDeps.Graph do
  @moduledoc false

  @doc """
  Deterministic dependency-first (topological) order of the graph's keys.

  Raises `ArgumentError` when a dependency is not itself a key, or when the
  graph contains a cycle. Safe to call at compile time.
  """
  def topological_order!(graph) do
    validate_deps!(graph)

    {_visited, order} =
      graph
      |> Map.keys()
      |> Enum.sort()
      |> Enum.reduce({MapSet.new(), []}, fn node, acc -> visit(node, graph, [], acc) end)

    Enum.reverse(order)
  end

  defp visit(node, graph, path, {visited, _order} = acc) do
    cond do
      node in path ->
        cycle = [node | path] |> Enum.reverse() |> Enum.join(" -> ")
        raise ArgumentError, "component dependency cycle: #{cycle}"

      MapSet.member?(visited, node) ->
        acc

      true ->
        {visited, order} =
          graph
          |> Map.fetch!(node)
          |> Enum.sort()
          |> Enum.reduce(acc, fn dep, inner -> visit(dep, graph, [node | path], inner) end)

        {MapSet.put(visited, node), [node | order]}
    end
  end

  defp validate_deps!(graph) do
    invalid =
      for {component, deps} <- graph, dep <- deps, not Map.has_key?(graph, dep) do
        "#{component} -> #{dep}"
      end

    if invalid != [] do
      raise ArgumentError,
            "invalid component dependency (dep is not a registered component): " <>
              Enum.join(Enum.sort(invalid), ", ")
    end
  end
end
