defmodule Pulsar.Generator.ComponentTest do
  @moduledoc """
  Renders the smoke test source that ships alongside a generated component.

  For each component it produces a readable ExUnit module: a `describe` block per
  public function component, a defaults render, one test per enum-valued attr
  (rendering every value), and a true/false test per boolean attr. Assertions are
  structural smoke only — renders-without-raising and slot content present — never
  Tailwind classes, so the test survives the user restyling the copied component.

  Components whose meaningful render needs a form or sample data (inputs, tables,
  calendars) ship a hand-authored override template at
  `priv/templates/test/<component>_test.exs.eex`, which `render/2` prefers when present.
  """

  @sample_slot_content "Pulsar"

  @doc """
  Renders and writes the component's test file into the project, unless one
  already exists at the target path. Returns the igniter unchanged when test
  generation is disabled (handled by the caller).
  """
  def install_component_test(igniter, component_name) do
    namespace = Pulsar.Generator.components_namespace(igniter)
    camel = Macro.camelize(to_string(component_name))
    test_module = Module.concat(namespace, "#{camel}Test")
    path = Igniter.Project.Module.proper_location(igniter, test_module, :test)
    override = override_template_path(component_name)

    cond do
      Igniter.exists?(igniter, path) ->
        igniter

      not testable?(component_name, override) ->
        igniter

      true ->
        contents = render(component_name, inspect(namespace), override)
        Igniter.create_new_file(igniter, path, contents)
    end
  end

  # A component gets a generated test when it ships an override template, or when
  # its bundled module exposes the `__components__/0` introspection the default
  # engine reads. Aggregate modules like `core_components` have neither and are
  # skipped — mirroring how the storybook generator skips components with no story.
  defp testable?(_component_name, {:ok, _path}), do: true

  defp testable?(component_name, :none) do
    module = component_module(component_name)
    Code.ensure_loaded?(module) and function_exported?(module, :__components__, 0)
  end

  @doc """
  Renders the test module source for `component_name` targeting `namespace`
  (e.g. `"MyAppWeb.Components"`). Uses the override template when one exists,
  otherwise the introspection engine.
  """
  def render(component_name, namespace, override \\ nil) do
    case override || override_template_path(component_name) do
      {:ok, path} ->
        EEx.eval_file(path,
          assigns: [component_namespace: namespace],
          engine: EEx.SmartEngine
        )

      :none ->
        render_engine(component_name, namespace)
    end
  end

  @doc false
  def override_template_path(component_name) do
    path =
      :pulsar
      |> :code.priv_dir()
      |> Path.join("templates/test/#{component_name}_test.exs.eex")

    if File.exists?(path), do: {:ok, path}, else: :none
  end

  defp render_engine(component_name, namespace) do
    module = component_module(component_name)
    camel = Macro.camelize(to_string(component_name))
    info = module.__components__()

    # `__components__/0` includes private (`defp`) helper function components, which
    # are not publicly callable — generating a `<Camel.helper>` render for them would
    # raise UndefinedFunctionError. Keep only publicly-exported function components.
    describes =
      info
      |> Enum.filter(fn {fn_name, _} -> function_exported?(module, fn_name, 1) end)
      |> Enum.sort_by(fn {fn_name, _} -> fn_name end)
      |> Enum.map_join("\n\n", fn {fn_name, fn_info} ->
        render_describe(camel, fn_name, fn_info)
      end)

    source = """
    defmodule #{namespace}.#{camel}Test do
      use ExUnit.Case, async: true

      import Phoenix.LiveViewTest
      import Phoenix.Component

      alias #{namespace}.#{camel}

    #{indent(describes, 2)}
    end
    """

    source
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  defp render_describe(camel, fn_name, fn_info) do
    attrs = fn_info.attrs
    enum_attrs = Enum.filter(attrs, &Keyword.has_key?(&1.opts, :values))
    bool_attrs = Enum.filter(attrs, &(&1.type == :boolean))
    plan = slot_plan(fn_info.slots)

    tests =
      [render_default_test(camel, fn_name, plan)] ++
        Enum.map(enum_attrs, &render_enum_test(camel, fn_name, &1, plan)) ++
        Enum.map(bool_attrs, &render_bool_test(camel, fn_name, &1, plan))

    """
    describe "#{fn_name}/1" do
    #{indent(Enum.join(tests, "\n\n"), 2)}
    end
    """
  end

  defp render_default_test(camel, fn_name, plan) do
    tag = open_close(camel, fn_name, "", plan)
    assertion = content_assertion(plan)

    """
    test "renders with default attributes" do
      assigns = %{}
      html = rendered_to_string(~H"#{tag}")
      #{assertion}
    end
    """
  end

  defp render_enum_test(camel, fn_name, attr, plan) do
    values = Keyword.fetch!(attr.opts, :values)
    values_src = values_literal(values)
    attr_str = " #{attr.name}={@value}"
    tag = open_close(camel, fn_name, attr_str, plan)
    assertion = content_assertion(plan)

    """
    test "renders every value of #{attr.name}" do
      for value <- #{values_src} do
        assigns = %{value: value}
        html = rendered_to_string(~H"#{tag}")
        #{assertion}
      end
    end
    """
  end

  defp render_bool_test(camel, fn_name, attr, plan) do
    attr_str = " #{attr.name}={@value}"
    tag = open_close(camel, fn_name, attr_str, plan)
    assertion = content_assertion(plan)

    """
    test "renders #{attr.name} true and false" do
      for value <- [true, false] do
        assigns = %{value: value}
        html = rendered_to_string(~H"#{tag}")
        #{assertion}
      end
    end
    """
  end

  defp slot_plan(slots) do
    cond do
      Enum.any?(slots, &(&1.name == :inner_block)) ->
        :inner

      Enum.any?(slots, & &1.required) ->
        {:slots, Enum.filter(slots, & &1.required)}

      true ->
        :none
    end
  end

  defp open_close(camel, fn_name, attr_str, plan) do
    content = @sample_slot_content

    case plan do
      :inner ->
        "<#{camel}.#{fn_name}#{attr_str}>#{content}</#{camel}.#{fn_name}>"

      {:slots, required} ->
        inner =
          Enum.map_join(required, "", fn s ->
            "<:#{s.name}>#{content}</:#{s.name}>"
          end)

        "<#{camel}.#{fn_name}#{attr_str}>#{inner}</#{camel}.#{fn_name}>"

      :none ->
        "<#{camel}.#{fn_name}#{attr_str} />"
    end
  end

  defp content_assertion(plan) do
    case plan do
      :none -> ~s(assert html != "")
      _ -> ~s(assert html =~ "#{@sample_slot_content}")
    end
  end

  # All enum values seen so far are strings or atoms; render them as a ~w list
  # (strings) or an explicit list (atoms).
  defp values_literal(values) do
    if Enum.all?(values, &(is_binary(&1) and &1 =~ ~r/^[\w-]+$/)) do
      "~w(#{Enum.join(values, " ")})"
    else
      inspect(values)
    end
  end

  defp component_module(component_name) do
    Module.concat(Pulsar.Components, Macro.camelize(to_string(component_name)))
  end

  defp indent(text, spaces) do
    pad = String.duplicate(" ", spaces)

    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "" -> ""
      line -> pad <> line
    end)
  end
end
