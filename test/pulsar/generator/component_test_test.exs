defmodule Pulsar.Generator.ComponentTestProbe do
  @moduledoc false
  # Stand-in for `use ExUnit.Case` used ONLY to compile generated test source so we
  # can verify its HEEx is valid, without registering anything with the running
  # ExUnit suite (which raises "cannot add module after the suite starts running").
  defmacro __using__(_opts) do
    quote do
      import ExUnit.Assertions
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import unquote(__MODULE__), only: [describe: 2, test: 2, test: 3]
    end
  end

  defmacro describe(_name, do: body) do
    quote do
      unquote(body)
    end
  end

  defmacro test(_name, do: body) do
    fname = :"probe_#{System.unique_integer([:positive])}"

    quote do
      def unquote(fname)() do
        unquote(body)
      end
    end
  end

  defmacro test(_name, _context, do: body) do
    fname = :"probe_#{System.unique_integer([:positive])}"

    quote do
      def unquote(fname)() do
        unquote(body)
      end
    end
  end
end

defmodule Pulsar.Generator.ComponentTestTest do
  use ExUnit.Case, async: true

  alias Pulsar.Generator.ComponentTest

  describe "render/2 default engine output — button" do
    setup do
      %{src: ComponentTest.render(:button, "MyAppWeb.Components")}
    end

    test "produces a compilable test module with the right name and harness", %{src: src} do
      assert src =~ "defmodule MyAppWeb.Components.ButtonTest do"
      assert src =~ "use ExUnit.Case, async: true"
      assert src =~ "import Phoenix.LiveViewTest"
      assert src =~ "import Phoenix.Component"
      assert src =~ "alias MyAppWeb.Components.Button"
    end

    test "emits a describe block per public function component", %{src: src} do
      assert src =~ ~s(describe "button/1")
    end

    test "emits a defaults render test that asserts slot content appears", %{src: src} do
      assert src =~ ~s(test "renders with default attributes")
      assert src =~ "rendered_to_string("
      assert src =~ ~s(assert html =~ "Pulsar")
    end

    test "emits one for-loop test per enum attr covering every value", %{src: src} do
      assert src =~ ~s(test "renders every value of variant")
      assert src =~ ~s[for value <- ~w(solid outline ghost link)]
      assert src =~ ~s(test "renders every value of color")
      assert src =~ ~s(test "renders every value of size")
    end

    test "emits a true/false test per boolean attr", %{src: src} do
      assert src =~ ~s(test "renders loading true and false")
      assert src =~ "for value <- [true, false]"
    end

    test "asserts no Tailwind-class strings (altitude guard)", %{src: src} do
      refute src =~ "bg-primary"
      refute src =~ "rounded-field"
    end

    test "renders atom-valued enum attr via inspect", %{src: src} do
      assert src =~ ~s([:button, :a, :div])
    end
  end

  describe "test_file_path/2" do
    test "places the test under the web app's components test dir" do
      assert ComponentTest.test_file_path("MyAppWeb", :button) ==
               "test/my_app_web/components/button_test.exs"
    end
  end

  describe "override_template_path/1" do
    test "returns :none when no override template exists for button" do
      assert ComponentTest.override_template_path(:button) == :none
    end

    test "returns {:ok, path} for input and render/2 routes through the override" do
      assert {:ok, path} = ComponentTest.override_template_path(:input)
      assert File.exists?(path)

      src = ComponentTest.render(:input, "Pulsar.Components")
      assert src =~ "defmodule Pulsar.Components.InputTest do"
      assert src =~ ~s(name="user[name]")
    end
  end

  describe "engine output compiles cleanly against the real components" do
    # `:button`, `:badge`, `:avatar` go through the introspection engine; `:input`
    # ships an override template (priv/templates/test/input_test.exs.eex) which
    # `render/2` prefers. The probe swap renames `defmodule Pulsar.Components.<Camel>Test`
    # and swaps the `use ExUnit.Case` line, so the same mechanism covers overrides.
    # `:button`, `:badge`, `:avatar` go through the introspection engine; `:input`
    # and the form-field components below ship override templates
    # (priv/templates/test/<component>_test.exs.eex) which `render/2` prefers. The
    # probe swap renames `defmodule Pulsar.Components.<Camel>Test` and swaps the
    # `use ExUnit.Case` line, so the same mechanism covers both paths.
    @form_components [:select, :checkbox, :switch, :textarea, :radio_group, :field, :form]
    @data_components [:table, :list, :pagination, :steps, :calendar, :date_picker]
    @simple_components [:button, :badge, :avatar, :input] ++ @form_components ++ @data_components

    for component <- @simple_components do
      test "#{component} generated test compiles without error" do
        component = unquote(component)

        # Render against the real `Pulsar.Components` namespace so the emitted
        # `alias Pulsar.Components.<Camel>` resolves to the bundled component and the
        # `~H` markup actually compiles.
        src = ComponentTest.render(component, "Pulsar.Components")
        camel = Macro.camelize(to_string(component))

        # Swap the ExUnit scaffolding for the compile probe (so the HEEx compiles
        # without ExUnit registration) and rename the outer module to a unique name
        # (so it does not collide with Pulsar's own `Pulsar.Components.<Camel>Test`).
        probed =
          src
          |> String.replace(
            "use ExUnit.Case, async: true",
            "use Pulsar.Generator.ComponentTestProbe"
          )
          |> String.replace(
            "defmodule Pulsar.Components.#{camel}Test do",
            "defmodule PulsarGenCheckProbe.#{camel} do"
          )

        assert probed =~ "use Pulsar.Generator.ComponentTestProbe",
               "expected the engine to emit `use ExUnit.Case, async: true` for swapping"

        assert probed =~ "PulsarGenCheckProbe.",
               "expected the engine to emit `defmodule Pulsar.Components.#{camel}Test` for renaming"

        modules =
          try do
            Code.compile_string(probed)
          rescue
            e -> flunk("generated test for #{component} failed to compile: #{Exception.message(e)}")
          end

        assert is_list(modules) and modules != []

        for {mod, _bin} <- modules do
          :code.purge(mod)
          :code.delete(mod)
        end
      end
    end
  end

  describe "hook caveat comment" do
    test "hook components get the render-not-interaction caveat" do
      src = ComponentTest.render(:tabs, "MyAppWeb.Components")
      assert src =~ "do NOT exercise the JS hook"
    end

    test "non-hook components do not get the caveat" do
      src = ComponentTest.render(:badge, "MyAppWeb.Components")
      refute src =~ "do NOT exercise the JS hook"
    end
  end
end
