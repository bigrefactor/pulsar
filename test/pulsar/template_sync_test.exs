defmodule Pulsar.TemplateSyncTest do
  use ExUnit.Case, async: true

  # Each pair: {component_name, lib_path, component_namespace, module_name}
  #
  # `component_namespace` is the parent namespace the generator writes the file
  # under (e.g. "Pulsar.Components" for Button, "Pulsar" for CoreComponents so
  # it lands as `Pulsar.CoreComponents` per Phoenix convention).
  #
  # `module_name` is the fully qualified module the template produces in
  # library mode, used to wrap the EEx body in `defmodule ... do/end`.
  #
  # `components_namespace` (the components root) is not part of the tuple —
  # it's provided to every template via `@components_root` below. Templates
  # that alias sibling components (e.g. CoreComponents aliasing Flash) read
  # it from there.
  @components_root "Pulsar.Components"

  @pairs [
    {:badge, "lib/pulsar/components/badge.ex", "Pulsar.Components", "Pulsar.Components.Badge"},
    {:button, "lib/pulsar/components/button.ex", "Pulsar.Components", "Pulsar.Components.Button"},
    {:card, "lib/pulsar/components/card.ex", "Pulsar.Components", "Pulsar.Components.Card"},
    {:checkbox, "lib/pulsar/components/checkbox.ex", "Pulsar.Components", "Pulsar.Components.Checkbox"},
    {:divider, "lib/pulsar/components/divider.ex", "Pulsar.Components", "Pulsar.Components.Divider"},
    {:field, "lib/pulsar/components/field.ex", "Pulsar.Components", "Pulsar.Components.Field"},
    {:flash, "lib/pulsar/components/flash.ex", "Pulsar.Components", "Pulsar.Components.Flash"},
    {:flash_group, "lib/pulsar/components/flash_group.ex", "Pulsar.Components", "Pulsar.Components.FlashGroup"},
    {:form, "lib/pulsar/components/form.ex", "Pulsar.Components", "Pulsar.Components.Form"},
    {:header, "lib/pulsar/components/header.ex", "Pulsar.Components", "Pulsar.Components.Header"},
    {:icon, "lib/pulsar/components/icon.ex", "Pulsar.Components", "Pulsar.Components.Icon"},
    {:input, "lib/pulsar/components/input.ex", "Pulsar.Components", "Pulsar.Components.Input"},
    {:label, "lib/pulsar/components/label.ex", "Pulsar.Components", "Pulsar.Components.Label"},
    {:link, "lib/pulsar/components/link.ex", "Pulsar.Components", "Pulsar.Components.Link"},
    {:list, "lib/pulsar/components/list.ex", "Pulsar.Components", "Pulsar.Components.List"},
    {:radio_group, "lib/pulsar/components/radio_group.ex", "Pulsar.Components", "Pulsar.Components.RadioGroup"},
    {:select, "lib/pulsar/components/select.ex", "Pulsar.Components", "Pulsar.Components.Select"},
    {:switch, "lib/pulsar/components/switch.ex", "Pulsar.Components", "Pulsar.Components.Switch"},
    {:table, "lib/pulsar/components/table.ex", "Pulsar.Components", "Pulsar.Components.Table"},
    {:textarea, "lib/pulsar/components/textarea.ex", "Pulsar.Components", "Pulsar.Components.Textarea"},
    {:core_components, "lib/pulsar/core_components.ex", "Pulsar", "Pulsar.CoreComponents"}
  ]

  for {component_name, lib_path, component_namespace, module_name} <- @pairs do
    test "#{component_name}: lib file matches EEx-compiled template" do
      template_path =
        :pulsar
        |> :code.priv_dir()
        |> Path.join("templates")
        |> Path.join("#{unquote(component_name)}.ex.eex")

      body =
        template_path
        |> EEx.eval_file(
          assigns: [
            component_namespace: unquote(component_namespace),
            components_namespace: @components_root
          ],
          engine: EEx.SmartEngine
        )
        |> String.trim()

      expected =
        "defmodule #{unquote(module_name)} do\n" <>
          indent(body, "  ") <>
          "\nend\n"

      actual = File.read!(unquote(lib_path))

      assert format(expected) == format(actual), """
      #{unquote(lib_path)} has drifted from priv/templates/#{unquote(component_name)}.ex.eex.

      Either regenerate the lib file from the template, or update the template
      to match the lib file. Both must stay in sync.
      """
    end
  end

  defp indent(body, prefix) do
    body
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "" -> ""
      line -> prefix <> line
    end)
  end

  defp format(content) do
    content
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> String.replace(~r/[ \t]+$/m, "")
    |> String.trim_trailing("\n")
  end

  describe "format/1" do
    test "distinguishes meaningfully different source" do
      a = "defmodule A do\n  :a\nend\n"
      b = "defmodule A do\n  :b\nend\n"

      refute format(a) == format(b),
             "format/1 collapsed two distinct modules — drift detection is no longer load-bearing"
    end
  end
end
