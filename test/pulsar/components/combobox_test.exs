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

    test "position breaks a contiguity tie against alphabetical order" do
      options = Combobox.options(["Alpha Cat", "Cat Zoo"])
      assert ["Cat Zoo", "Alpha Cat"] = labels(Combobox.default_filter("cat", options))
    end

    test "drops non-matches", %{options: options} do
      assert [] = Combobox.default_filter("zzzz", options)
    end

    defp labels(options), do: Enum.map(options, & &1.label)
  end

  describe "rendering" do
    import Phoenix.LiveViewTest

    test "renders a combobox input wired to its listbox" do
      html = render_component(Combobox, id: "cb", options: ["Alpha", "Beta"])

      assert html =~ ~s(role="combobox")
      assert html =~ ~s(id="cb")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(aria-controls="cb-listbox")
      assert html =~ ~s(aria-autocomplete="list")
      assert html =~ ~s(autocomplete="off")
      assert html =~ "Alpha"
      assert html =~ "Beta"
    end

    test "the input has an accessible name from a real label element" do
      html = render_component(Combobox, id: "cb", label: "Owner", options: [])

      assert html =~ ~s(<label for="cb")
      assert html =~ "Owner"
    end

    test "option rows carry sequential ids and option roles" do
      html = render_component(Combobox, id: "cb", options: ["Alpha", "Beta"])

      assert html =~ ~s(id="cb-option-0")
      assert html =~ ~s(id="cb-option-1")
      assert html =~ ~s(role="option")
    end

    test "aria-selected reflects the selected value, not the active row" do
      html = render_component(Combobox, id: "cb", options: [{"Alpha", "a"}, {"Beta", "b"}], value: "b")

      assert element_by_id(html, "cb-option-1") =~ ~s(aria-selected="true")
      assert element_by_id(html, "cb-option-0") =~ ~s(aria-selected="false")
    end

    test "groups options under a labelled group role" do
      html = render_component(Combobox, id: "cb", options: [{"Europe", ["UK"]}])

      assert html =~ ~s(role="group")
      assert html =~ ~s(id="cb-group-0")
      assert html =~ "Europe"
    end

    test "renders a disabled row as aria-disabled" do
      html = render_component(Combobox, id: "cb", options: [[key: "Alpha", value: "a", disabled: true]])

      assert html =~ ~s(aria-disabled="true")
    end

    test "renders the empty state as a single unreachable option row" do
      html = render_component(Combobox, id: "cb", options: [])

      assert html =~ "No results found"
      refute html =~ "data-combobox-option"
    end

    test "announces the result count in a polite status region" do
      html = render_component(Combobox, id: "cb", options: ["Alpha"])

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "1 result"
    end

    test "binds a hidden input carrying the field value" do
      html = render_component(Combobox, id: "cb", name: "user[owner_id]", value: "42", options: [{"Alice", "42"}])

      assert html =~ ~s(type="hidden")
      assert html =~ ~s(name="user[owner_id]")
      assert html =~ ~s(value="42")
    end

    test "the input displays the selected label" do
      html = render_component(Combobox, id: "cb", options: [{"Alice Chen", "42"}], value: "42")

      assert html =~ ~s(value="Alice Chen")
    end

    test "display resolves a label that options cannot" do
      html = render_component(Combobox, id: "cb", options: [], value: "42", display: [{"Alice Chen", "42"}])

      assert html =~ ~s(value="Alice Chen")
    end

    test "an unresolvable value falls back to the raw value" do
      html = render_component(Combobox, id: "cb", options: [], value: "42")

      assert html =~ ~s(value="42")
    end

    test "renders the chevron outside the tab sequence and the clear button in it" do
      html = render_component(Combobox, id: "cb", options: [{"Alice", "42"}], value: "42")

      assert html =~ ~s(tabindex="-1")
      assert html =~ "Show options"
      assert html =~ "Clear"
    end

    test "hides the clear button when nothing is selected" do
      html = render_component(Combobox, id: "cb", options: [{"Alice", "42"}])

      refute html =~ "Clear"
    end

    test "applies variant, color, and size classes" do
      html = render_component(Combobox, id: "cb", options: ["Alpha"], variant: "solid", color: "success", size: "lg")

      assert html =~ "bg-surface-2"
      assert html =~ "data-[active=true]:bg-success/10"
      assert html =~ "h-10"
    end

    test "marks invalid and required state on the input" do
      html = render_component(Combobox, id: "cb", options: [], invalid: true, required: true)

      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-required="true")
    end

    test "renders the data attributes the colocated hook reads" do
      html =
        render_component(Combobox,
          id: "cb",
          name: "owner_id",
          options: [{"Alpha", "a"}],
          value: "a"
        )

      root = element_by_id(html, "cb-cb")
      assert root =~ ~s(data-panel="cb-pop")
      assert root =~ ~s(data-multiple="false")
      assert root =~ ~s(data-debounce="0")
      assert root =~ ~s(data-on-change="[]")

      row = element_by_id(html, "cb-option-0")
      assert row =~ "data-combobox-option"
      assert row =~ ~s(data-active="true")
      assert row =~ ~s(data-value="a")
      assert row =~ ~s(data-label="Alpha")

      assert html =~ "data-combobox-value"
      assert html =~ "data-combobox-toggle"
      assert html =~ "data-combobox-clear"
    end

    test "the root and the input carry distinct ids, and no id repeats" do
      html =
        render_component(Combobox,
          id: "cb",
          options: [{"Europe", ["UK", "Sweden"]}],
          value: "uk"
        )

      assert element_by_id(html, "cb-cb") =~ ~s(id="cb-cb")
      assert element_by_id(html, "cb") =~ ~s(id="cb")

      ids = Regex.scan(~r/\sid="([^"]*)"/, html) |> Enum.map(fn [_match, id] -> id end)
      assert ids == Enum.uniq(ids)
    end

    defp element_by_id(html, id) do
      ~r/<[a-zA-Z]+[^>]*\sid="#{id}"[^>]*>/ |> Regex.run(html) |> List.first()
    end
  end

  describe "combobox/1" do
    import Phoenix.Component
    import Phoenix.LiveViewTest

    test "derives its id from a bound field" do
      field = to_form(%{"owner_id" => "42"}, as: :user)[:owner_id]
      html = render_component(&Combobox.combobox/1, field: field, options: [{"Alice", "42"}])

      assert html =~ ~s(id="user_owner_id")
    end

    test "raises without an id or a bound field" do
      assert_raise ArgumentError, ~r/requires an :id/, fn ->
        render_component(&Combobox.combobox/1, options: [])
      end
    end
  end
end
