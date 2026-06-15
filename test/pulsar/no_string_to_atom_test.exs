defmodule Pulsar.NoStringToAtomTest do
  use ExUnit.Case, async: true

  # `String.to_atom/1` on assign-derived input can exhaust the BEAM atom table
  # (DOS vector) and is flagged by `mix sobelow`. Component sources must use
  # `String.to_existing_atom/1` (or an explicit map) instead. This guards the
  # generated lib modules and every template (source of truth), including those
  # under priv/templates/{storybook,test,themes} that ship into host apps.
  @roots ["lib/pulsar/components", "priv/templates"]
  @pattern ~r/String\.to_atom\s*\(/

  test "no component source calls String.to_atom/1" do
    offenders =
      @roots
      |> Enum.flat_map(&Path.wildcard(Path.join(&1, "**/*")))
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _no} -> Regex.match?(@pattern, line) end)
        |> Enum.map(fn {line, no} -> "#{path}:#{no}: #{String.trim(line)}" end)
      end)

    assert offenders == [], "Found unsafe String.to_atom/1 calls:\n" <> Enum.join(offenders, "\n")
  end
end
