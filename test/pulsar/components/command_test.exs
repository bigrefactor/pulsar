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

  describe "default_filter/2" do
    test "an empty or whitespace query returns every option unchanged" do
      opts = Command.options(["Alpha", "Beta"])

      assert Command.default_filter("", opts) == opts
      assert Command.default_filter("   ", opts) == opts
    end

    test "matches a case-insensitive subsequence, not just a prefix" do
      opts = Command.options(["Created at", "Updated at", "Owner"])

      assert Enum.map(Command.default_filter("ua", opts), & &1.label) == ["Updated at"]
    end

    test "drops options with no subsequence match" do
      opts = Command.options(["Owner", "Status"])

      assert Command.default_filter("zzz", opts) == []
    end

    test "ranks a contiguous match above a scattered one" do
      opts = Command.options(["Status", "Sorted by attribute"])

      assert Enum.map(Command.default_filter("stat", opts), & &1.label) ==
               ["Status", "Sorted by attribute"]
    end

    test "ranks an earlier match above a later one when both are contiguous" do
      opts = Command.options(["Last owner", "Owner"])

      assert Enum.map(Command.default_filter("owner", opts), & &1.label) ==
               ["Owner", "Last owner"]
    end

    test "preserves the group label on matched options" do
      opts = Command.options([{"People", ["Owner"]}])

      assert [%{group: "People"}] = Command.default_filter("own", opts)
    end
  end

  describe "render/1 structure and ARIA" do
    test "the query field is a combobox wired to the listbox" do
      html = render_component(Command, id: "cmd", options: ["Alpha"])

      assert html =~ ~s(role="combobox")
      assert html =~ ~s(id="cmd-input")
      assert html =~ ~s(aria-controls="cmd-listbox")
      assert html =~ ~s(aria-expanded="true")
      assert html =~ ~s(aria-autocomplete="list")
      assert html =~ ~s(autocomplete="off")
    end

    test "the query field has an accessible name from a real label element" do
      html = render_component(Command, id: "cmd", label: "Search fields", options: [])

      assert html =~ ~s(for="cmd-input")
      assert html =~ "Search fields"
    end

    test "results render as a listbox of options" do
      html = render_component(Command, id: "cmd", options: ["Alpha", "Beta"])

      assert html =~ ~s(id="cmd-listbox")
      assert html =~ ~s(role="listbox")
      assert html =~ ~s(role="option")
      assert html =~ ~s(id="cmd-option-0")
      assert html =~ ~s(id="cmd-option-1")
      assert html =~ "Alpha"
      assert html =~ "Beta"
    end

    test "the first option starts active and selected, and only it" do
      html = render_component(Command, id: "cmd", options: ["Alpha", "Beta"])

      assert html =~ ~s(aria-activedescendant="cmd-option-0")
      assert occurrences(html, ~s(data-active="true")) == 1
      assert occurrences(html, ~s(aria-selected="true")) == 1
    end

    test "groups render as labelled groups inside the listbox" do
      html = render_component(Command, id: "cmd", options: [{"Europe", ["UK"]}])

      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-labelledby="cmd-group-0")
      assert html =~ ~s(id="cmd-group-0")
      assert html =~ "Europe"
    end

    test "option ids stay sequential across groups" do
      html = render_component(Command, id: "cmd", options: [{"A", ["a1"]}, {"B", ["b1"]}])

      assert html =~ ~s(id="cmd-option-0")
      assert html =~ ~s(id="cmd-option-1")
    end

    test "a disabled option is marked and never starts active" do
      html = render_component(Command, id: "cmd", options: [[key: "Alpha", value: "a", disabled: true], "Beta"])

      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(aria-activedescendant="cmd-option-1")
      refute html =~ ~s(aria-activedescendant="cmd-option-0")
    end

    test "aria-activedescendant points at the active option" do
      html = render_component(Command, id: "cmd", options: ["Alpha"])

      assert html =~ ~s(aria-activedescendant="cmd-option-0")
    end

    test "with no results there is no activedescendant" do
      html = render_component(Command, id: "cmd", options: [])

      refute html =~ "aria-activedescendant=\"cmd-option"
    end

    test "the query field carries no server-controlled value" do
      html = render_component(Command, id: "cmd", options: ["Alpha"])

      refute html =~ ~r/<input[^>]*\svalue=/
    end

    test "the root carries the keyboard hook" do
      html = render_component(Command, id: "cmd", options: [])

      assert html =~ ~s(phx-hook="Pulsar.Components.Command.PulsarCommand")
    end

    test "the result count is announced politely" do
      html = render_component(Command, id: "cmd", options: ["Alpha", "Beta"])

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "2"
    end

    test "a custom filter replaces the built-in one" do
      only_beta = fn _query, options -> Enum.filter(options, &(&1.label == "Beta")) end
      html = render_component(Command, id: "cmd", options: ["Alpha", "Beta"], filter: only_beta)

      assert html =~ "Beta"
      refute html =~ "Alpha"
    end
  end

  describe "variants, colors and sizes" do
    test "defaults to a ghost surface so a host panel shows through" do
      html = render_component(Command, id: "cmd", options: [])

      assert html =~ "bg-transparent"
    end

    test "the elevated variant draws its own surface" do
      html = render_component(Command, id: "cmd", options: [], variant: "elevated")

      assert html =~ "bg-surface-1"
      assert html =~ "shadow-dropdown"
    end

    test "color drives the active-row accent" do
      html = render_component(Command, id: "cmd", options: ["Alpha"], color: "success")

      assert html =~ "data-[active=true]:bg-success"
    end

    test "size drives row scale" do
      html = render_component(Command, id: "cmd", options: ["Alpha"], size: "lg")

      assert html =~ "text-base"
    end

    test "a custom class overrides a conflicting default via Twm" do
      html = render_component(Command, id: "cmd", options: [], class: "flex-row")

      refute html =~ "flex-col"
    end
  end

  describe "option decorations" do
    test "renders an option icon" do
      html = render_component(Command, id: "cmd", options: [[key: "Home", value: "h", icon: "hero-home"]])

      assert html =~ "hero-home"
    end

    test "renders a shortcut hint" do
      html = render_component(Command, id: "cmd", options: [[key: "Home", value: "h", shortcut: "G H"]])

      assert html =~ "G H"
    end

    test "renders a description" do
      html = render_component(Command, id: "cmd", options: [[key: "Home", value: "h", description: "Go home"]])

      assert html =~ "Go home"
    end
  end

  describe "empty state" do
    test "renders the default empty message when nothing matches" do
      html = render_component(Command, id: "cmd", options: [])

      assert html =~ "No results"
    end

    test "empty_text overrides the default" do
      html = render_component(Command, id: "cmd", options: [], empty_text: "Nothing here")

      assert html =~ "Nothing here"
      refute html =~ "No results"
    end

    test "no empty message renders while results exist" do
      html = render_component(Command, id: "cmd", options: ["Alpha"])

      refute html =~ "No results"
    end
  end

  defp occurrences(html, needle), do: length(String.split(html, needle)) - 1
end
