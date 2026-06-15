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

  describe "override_template_path/1" do
    test "returns :none when no override template exists for button" do
      assert ComponentTest.override_template_path(:button) == :none
    end
  end
end
