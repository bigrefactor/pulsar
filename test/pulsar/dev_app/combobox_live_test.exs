defmodule Pulsar.DevApp.ComboboxLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Pulsar.DevApp.Endpoint

  @endpoint Endpoint

  setup do
    {:ok, conn: build_conn()}
  end

  defp listbox(view), do: render(element(view, "#cb-outline-listbox"))

  describe "query event" do
    test "filtering drops non-matching rows from the listbox", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")
      assert listbox(view) =~ "Alpha"

      render_hook(element(view, "#cb-outline-cb"), "query", %{"query" => "beta"})

      assert listbox(view) =~ "Beta"
      assert listbox(view) =~ "Betamax"
      refute listbox(view) =~ "Alpha"
    end

    test "an unmatched query shows the empty state", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-outline-cb"), "query", %{"query" => "zzzz"})

      assert listbox(view) =~ "No results found"
      refute listbox(view) =~ "Alpha"
    end

    test "filtering one instance leaves its siblings alone", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-outline-cb"), "query", %{"query" => "zzzz"})

      assert render(element(view, "#cb-solid-listbox")) =~ "Alpha"
    end

    test "an async filter returns results the options never held", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-async-cb"), "query", %{"query" => "remote"})
      render_async(view)

      assert render(element(view, "#cb-async-listbox")) =~ "Remote One"
    end
  end
end
