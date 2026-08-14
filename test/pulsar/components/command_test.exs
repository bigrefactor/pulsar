defmodule Pulsar.Components.CommandTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Pulsar.Components.Command
  alias Pulsar.Components.Command.Option

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

  describe "options/1 accepted shapes" do
    test "scalars use the value as both label and value" do
      assert Command.options(["Admin", :user, 3]) == [
               %Option{label: "Admin", value: "Admin"},
               %Option{label: "user", value: :user},
               %Option{label: "3", value: 3}
             ]
    end

    test "two-item tuples are label and value" do
      assert Command.options([{"Admin", "admin"}]) == [%Option{label: "Admin", value: "admin"}]
    end

    test "keyword syntax is the same as two-item tuples" do
      assert Command.options(Admin: "admin") == [%Option{label: "Admin", value: "admin"}]
    end

    test "a keyword option carries key, value and extras" do
      opts = [[key: "Admin", value: "admin", disabled: true, icon: "hero-user", shortcut: "G A"]]

      assert Command.options(opts) == [
               %Option{
                 label: "Admin",
                 value: "admin",
                 disabled: true,
                 icon: "hero-user",
                 shortcut: "G A"
               }
             ]
    end

    test "a nested list makes its key a group label" do
      assert Command.options([{"Europe", ["UK", "Sweden"]}]) == [
               %Option{label: "UK", value: "UK", group: "Europe"},
               %Option{label: "Sweden", value: "Sweden", group: "Europe"}
             ]
    end

    test "a map value groups the same way" do
      assert Command.options([{"Europe", %{"UK" => "uk"}}]) == [
               %Option{label: "UK", value: "uk", group: "Europe"}
             ]
    end

    test "structs pass through and inherit an enclosing group" do
      given = [{"Nav", [%Option{label: "Home", value: "home"}]}]

      assert Command.options(given) == [%Option{label: "Home", value: "home", group: "Nav"}]
    end

    test "a struct's own group wins over the enclosing one" do
      given = [{"Nav", [%Option{label: "Home", value: "home", group: "Explicit"}]}]

      assert Command.options(given) == [%Option{label: "Home", value: "home", group: "Explicit"}]
    end

    test "group order follows first appearance and options stay flat" do
      given = [{"B", ["b1"]}, {"A", ["a1"]}, {"B", ["b2"]}]

      assert Enum.map(Command.options(given), & &1.group) == ["B", "A", "B"]
    end

    test "already-normalized output round-trips unchanged" do
      normalized = Command.options([{"Europe", ["UK"]}])

      assert Command.options(normalized) == normalized
    end

    test "nested groups raise" do
      assert_raise ArgumentError, ~r/nested groups/, fn ->
        Command.options([{"Europe", [{"North", ["UK"]}]}])
      end
    end

    test "an unrecognized entry raises naming the offending term" do
      error = assert_raise ArgumentError, fn -> Command.options([%{a: 1, b: 2}]) end

      assert error.message =~ "unsupported option"
      assert error.message =~ inspect(%{a: 1, b: 2})
    end

    test "a keyword option missing :value raises" do
      assert_raise ArgumentError, ~r/missing :value/, fn ->
        Command.options([[key: "Admin"]])
      end
    end
  end
end
