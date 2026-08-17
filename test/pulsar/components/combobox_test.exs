defmodule Pulsar.Components.ComboboxTest do
  use ExUnit.Case, async: true

  alias Pulsar.Components.Combobox
  alias Pulsar.Components.Combobox.Option

  describe "options/1" do
    test "normalizes scalars, tuples, and keyword options" do
      assert [%Option{label: "Admin", value: "Admin"}] = Combobox.options(["Admin"])
      assert [%Option{label: "admin", value: :admin}] = Combobox.options([:admin])
      assert [%Option{label: "Admin", value: "admin"}] = Combobox.options([{"Admin", "admin"}])
      assert [%Option{label: "Admin", value: "admin"}] = Combobox.options(Admin: "admin")
    end

    test "carries keyword extras" do
      assert [%Option{icon: "hero-user", description: "Full access", disabled: true}] =
               Combobox.options([
                 [key: "Admin", value: "admin", icon: "hero-user", description: "Full access", disabled: true]
               ])
    end

    test "raises when a keyword option omits :value" do
      assert_raise ArgumentError, ~r/missing :value/, fn ->
        Combobox.options([[key: "Admin"]])
      end
    end

    test "flattens the nested group shape and keeps first-appearance order" do
      options = Combobox.options([{"Europe", ["UK", "Sweden"]}, {"Asia", ["Japan"]}])

      assert [
               %Option{label: "UK", group: "Europe"},
               %Option{label: "Sweden", group: "Europe"},
               %Option{label: "Japan", group: "Asia"}
             ] = options
    end

    test "raises on nested groups" do
      assert_raise ArgumentError, ~r/nested groups are not supported/, fn ->
        Combobox.options([{"Europe", [{"North", ["UK"]}]}])
      end
    end

    test "raises on an unsupported entry" do
      assert_raise ArgumentError, ~r/unsupported option/, fn ->
        Combobox.options([{1, 2, 3}])
      end
    end

    test "passes Option structs through, filling a missing group" do
      option = %Option{label: "UK", value: "uk"}
      assert [%Option{group: "Europe"}] = Combobox.options([{"Europe", [option]}])
    end
  end

  describe "default_filter/2" do
    setup do
      %{options: Combobox.options(["Alpha", "Beta", "Betamax", "Gamma"])}
    end

    test "an empty query keeps everything", %{options: options} do
      assert Combobox.default_filter("", options) == options
      assert Combobox.default_filter("   ", options) == options
    end

    test "matches case-insensitively as a subsequence", %{options: options} do
      assert ["Beta", "Betamax"] = labels(Combobox.default_filter("bta", options))
    end

    test "ranks a contiguous match ahead of a scattered one" do
      options = Combobox.options(["Bandana Toast", "Beta"])
      assert ["Beta", "Bandana Toast"] = labels(Combobox.default_filter("bta", options))
    end

    test "ranks an earlier match ahead of a later one" do
      options = Combobox.options(["Xylophone Beta", "Beta"])
      assert ["Beta", "Xylophone Beta"] = labels(Combobox.default_filter("beta", options))
    end

    test "drops non-matches", %{options: options} do
      assert [] = Combobox.default_filter("zzzz", options)
    end

    defp labels(options), do: Enum.map(options, & &1.label)
  end
end
