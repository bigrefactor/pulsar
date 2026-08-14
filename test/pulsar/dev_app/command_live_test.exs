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

  describe "async filtering" do
    test "marks its own listbox busy in flight, keeps prior rows, and shows a spinner", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      in_flight = render(element(view, "#cmd-async"))

      assert in_flight =~ ~s(aria-busy="true")
      assert in_flight =~ "Cormorant"
      assert in_flight =~ "animate-spin"
    end

    test "a sync sibling is not marked busy by an async neighbour", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})

      refute render(element(view, "#cmd-filter")) =~ ~s(aria-busy="true")
    end

    test "replaces rows and clears busy when the filter resolves", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      render_async(view)
      settled = render(element(view, "#cmd-async"))

      assert settled =~ "Remote result"
      refute settled =~ "Cormorant"
      refute settled =~ ~s(aria-busy="true")
      refute settled =~ "animate-spin"
    end

    test "a failing async filter clears busy and shows the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      ExUnit.CaptureLog.capture_log(fn ->
        render_hook(element(view, "#cmd-async-error"), "query", %{"query" => "r"})
        render_async(view)
      end)

      settled = render(element(view, "#cmd-async-error"))

      assert settled =~ "No results found"
      refute settled =~ "Egret"
      refute settled =~ ~s(aria-busy="true")
    end

    test "a parent re-render does not discard resolved async results", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      render_async(view)
      assert render(element(view, "#cmd-async")) =~ "Remote result"

      render_click(element(view, "#cmd-async-touch"))

      settled = render(element(view, "#cmd-async"))
      assert settled =~ "Remote result"
      refute settled =~ "Cormorant"
    end
  end

  describe "select event" do
    test "selecting resets the query", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")
      render_hook(element(view, "#cmd-ghost"), "query", %{"query" => "beta"})
      refute render(element(view, "#cmd-ghost-listbox")) =~ ">Alpha<"

      render_hook(element(view, "#cmd-ghost"), "select", %{"value" => "Beta"})

      assert render(element(view, "#cmd-ghost-listbox")) =~ "Alpha"
    end
  end

  defp listbox(view), do: render(element(view, "#cmd-filter-listbox"))
end
