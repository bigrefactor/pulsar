defmodule Pulsar.DevApp.CommandLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Pulsar.DevApp.Endpoint

  @endpoint Endpoint

  setup do
    {:ok, conn: build_conn()}
  end

  describe "query event" do
    test "filtering drops non-matching rows from the listbox", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")
      assert listbox(view) =~ "Aardvark"

      render_hook(element(view, "#cmd-filter"), "query", %{"query" => "beetle"})

      assert listbox(view) =~ "Beetle"
      assert listbox(view) =~ "Beetlejuice"
      refute listbox(view) =~ "Aardvark"
    end

    test "the active row follows the filtered results", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-filter"), "query", %{"query" => "beetlejuice"})

      assert listbox(view) =~ "Beetlejuice"
      refute listbox(view) =~ "Aardvark"
      refute listbox(view) =~ ">Beetle<"
      assert render(element(view, "#cmd-filter")) =~ ~s(aria-activedescendant="cmd-filter-option-0")
    end

    test "an unmatched query empties the listbox and shows the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-filter"), "query", %{"query" => "zzz"})

      refute listbox(view) =~ "Aardvark"
      refute listbox(view) =~ "Beetle"
      assert listbox(view) =~ "No results found"
    end

    test "filtering one instance leaves its siblings alone", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-filter"), "query", %{"query" => "zzz"})

      assert render(element(view, "#cmd-solid-listbox")) =~ "Alpha"
    end
  end

  describe "slots through the command/1 wrapper" do
    test "a custom :item slot replaces the default row markup", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/components/command")

      assert html =~ "ROW[zulu]"
      refute html =~ "SLOT-DEFAULT-MARKER"
    end

    test "a custom :empty slot replaces the default message", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/components/command")

      assert html =~ "CUSTOM-EMPTY"
    end

    test "the default empty message still renders where no :empty slot is given", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/components/command")

      assert html =~ "No results found"
    end
  end

  defp listbox(view), do: render(element(view, "#cmd-filter-listbox"))
end
