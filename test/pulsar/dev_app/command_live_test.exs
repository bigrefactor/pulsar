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
    test "filtering narrows the rendered rows and resets the active row", %{conn: conn} do
      {:ok, view, html} = live(conn, "/components/command")
      assert html =~ "Alpha"

      filtered = render_hook(element(view, "#cmd-ghost"), "query", %{"query" => "beta"})

      assert filtered =~ "Beta"
      assert filtered =~ ~s(aria-activedescendant="cmd-ghost-option-0")
    end

    test "an unmatched query renders the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      filtered = render_hook(element(view, "#cmd-ghost"), "query", %{"query" => "zzz"})

      assert filtered =~ "No results"
    end

    test "filtering one instance leaves its siblings alone", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      filtered = render_hook(element(view, "#cmd-ghost"), "query", %{"query" => "beta"})

      assert filtered =~ ~s(id="cmd-solid-option-0")
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
end
