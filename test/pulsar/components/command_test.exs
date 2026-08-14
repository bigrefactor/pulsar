defmodule Pulsar.Components.CommandTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Pulsar.Components.Command

  describe "render/1 skeleton" do
    test "renders a root element carrying the given id" do
      html = render_component(Command, id: "cmd")

      assert html =~ ~s(id="cmd")
    end
  end

  describe "module shape" do
    test "is a live component" do
      assert Command.__live__() == %{kind: :component, layout: false}
    end

    test "exposes command/1 as the only declared function component" do
      assert Map.keys(Command.__components__()) == [:command]
    end
  end
end
