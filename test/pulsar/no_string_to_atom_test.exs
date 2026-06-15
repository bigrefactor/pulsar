defmodule Pulsar.NoStringToAtomTest do
  use ExUnit.Case, async: true

  # `String.to_atom/1` on assign-derived input can exhaust the BEAM atom table
  # (DOS vector) and is flagged by `mix sobelow`. Component sources must use
  # `String.to_existing_atom/1` (or an explicit map) instead. This guards both
  # the templates (source of truth) and the generated lib modules.
  @roots ["lib/pulsar/components", "priv/templates"]

  test "no component source calls String.to_atom/1" do
    offenders =
      @roots
      |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*")))
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _no} -> String.contains?(line, "String.to_atom(") end)
        |> Enum.map(fn {line, no} -> "#{path}:#{no}: #{String.trim(line)}" end)
      end)

    assert offenders == [], "Found unsafe String.to_atom/1 calls:\n" <> Enum.join(offenders, "\n")
  end
end
