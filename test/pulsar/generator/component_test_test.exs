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
  end

  describe "engine output compiles cleanly against the real components" do
    @simple_components [:button, :badge, :avatar]

    for component <- @simple_components do
      test "#{component} generated test compiles without error" do
        component = unquote(component)
        src = ComponentTest.render(component, "Pulsar.Components")

        # Compiling the source proves the generated HEEx is valid for a component
        # whose slot shape the engine had to infer (avatar has no :inner_block).
        # We compile into a throwaway module name space and purge it afterwards so
        # the generated ExUnit cases are not registered with the host suite.
        modules =
          try do
            Code.compile_string(src)
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
end
