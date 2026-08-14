defmodule Pulsar.TemplatesUseHostNamespaceTest do
  use ExUnit.Case, async: true

  # Templates ship into host apps, so prose, examples and runtime messages must
  # name the host's namespace via `<%= @components_namespace %>` — never
  # Pulsar's own modules, which the host does not have. In library mode the
  # assign resolves to "Pulsar.Components", so the generated lib files read
  # exactly as before.
  @pattern ~r/Pulsar\./

  test "no template hardcodes a Pulsar module name" do
    offenders =
      "priv/templates/**/*.eex"
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _no} -> Regex.match?(@pattern, line) end)
        |> Enum.map(fn {line, no} -> "#{path}:#{no}: #{String.trim(line)}" end)
      end)

    assert offenders == [],
           "templates must interpolate <%= @components_namespace %> rather than name Pulsar's own modules:\n\n" <>
             Enum.join(offenders, "\n")
  end
end
