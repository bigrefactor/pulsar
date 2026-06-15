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
  Renders the test module source for `component_name` targeting `namespace`
  (e.g. `"MyAppWeb.Components"`). Uses the override template when one exists,
  otherwise the introspection engine.
  """
  def render(component_name, namespace) do
    case override_template_path(component_name) do
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

    describes =
      info
      |> Enum.sort_by(fn {fn_name, _} -> fn_name end)
      |> Enum.map_join("\n\n", fn {fn_name, fn_info} ->
        render_describe(camel, fn_name, fn_info)
      end)

    """
    defmodule #{namespace}.#{camel}Test do
      use ExUnit.Case, async: true

      import Phoenix.LiveViewTest
      import Phoenix.Component

      alias #{namespace}.#{camel}

    #{indent(describes, 2)}
    end
    """
  end

  defp render_describe(camel, fn_name, fn_info) do
    attrs = fn_info.attrs
    enum_attrs = Enum.filter(attrs, &Keyword.has_key?(&1.opts, :values))
    bool_attrs = Enum.filter(attrs, &(&1.type == :boolean))

    tests =
      [render_default_test(camel, fn_name)] ++
        Enum.map(enum_attrs, &render_enum_test(camel, fn_name, &1)) ++
        Enum.map(bool_attrs, &render_bool_test(camel, fn_name, &1))

    """
    describe "#{fn_name}/1" do
    #{indent(Enum.join(tests, "\n\n"), 2)}
    end
    """
  end

  defp render_default_test(camel, fn_name) do
    content = @sample_slot_content

    """
    test "renders with default attributes" do
      assigns = %{}
      html = rendered_to_string(~H"<#{camel}.#{fn_name}>#{content}</#{camel}.#{fn_name}>")
      assert html =~ "#{content}"
    end
    """
  end

  defp render_enum_test(camel, fn_name, attr) do
    values = Keyword.fetch!(attr.opts, :values)
    values_src = values_literal(values)
    content = @sample_slot_content

    """
    test "renders every value of #{attr.name}" do
      for value <- #{values_src} do
        assigns = %{value: value}
        html = rendered_to_string(~H"<#{camel}.#{fn_name} #{attr.name}={@value}>#{content}</#{camel}.#{fn_name}>")
        assert html =~ "#{content}"
      end
    end
    """
  end

  defp render_bool_test(camel, fn_name, attr) do
    content = @sample_slot_content

    """
    test "renders #{attr.name} true and false" do
      for value <- [true, false] do
        assigns = %{value: value}
        html = rendered_to_string(~H"<#{camel}.#{fn_name} #{attr.name}={@value}>#{content}</#{camel}.#{fn_name}>")
        assert html =~ "#{content}"
      end
    end
    """
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
