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

    # `start_async` under an existing name only discards the old task's result;
    # the task itself keeps running. Only the process's death distinguishes a
    # cancelled filter from an abandoned one, so watch for it directly.
    test "a new query kills the in-flight async filter", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> put_connect_params(%{"probe" => self()})
        |> live("/components/combobox")

      render_hook(element(view, "#cb-async-cb"), "query", %{"query" => "one"})
      assert_receive {:filtering, "one", first}
      ref = Process.monitor(first)

      render_hook(element(view, "#cb-async-cb"), "query", %{"query" => "two"})
      assert_receive {:filtering, "two", second}
      assert second != first

      assert_receive {:DOWN, ^ref, :process, ^first, _reason}

      send(second, :release)
    end
  end

  describe "select event" do
    test "selecting a value displays its label", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-outline-cb"), "select", %{"value" => "beta"})

      assert render(element(view, "#cb-outline")) =~ ~s(value="Beta")
    end

    test "selecting marks the row aria-selected, not merely active", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-outline-cb"), "select", %{"value" => "beta"})

      assert render(element(view, "#cb-outline-option-1")) =~ ~s(aria-selected="true")
      assert render(element(view, "#cb-outline-option-0")) =~ ~s(aria-selected="false")
    end

    test "selecting resets the query so a reopen starts from the full list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-outline-cb"), "query", %{"query" => "beta"})
      render_hook(element(view, "#cb-outline-cb"), "select", %{"value" => "beta"})

      assert render(element(view, "#cb-outline-listbox")) =~ "Alpha"
    end

    test "selecting in multiple mode accumulates values", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-multiple-cb"), "select", %{"value" => "beta"})

      assert render(element(view, "#cb-multiple-cb")) =~ "2 selected"
    end

    test "selecting the same value twice in multiple mode does not duplicate it", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")

      render_hook(element(view, "#cb-multiple-cb"), "select", %{"value" => "alpha"})

      assert render(element(view, "#cb-multiple-cb")) =~ "1 selected"
    end
  end

  describe "remove and clear events" do
    test "removing drops the value's badge and updates the selected count", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")
      assert render(element(view, "#cb-multiple-field")) =~ "Alpha"
      assert render(element(view, "#cb-multiple-field")) =~ "data-combobox-badge"
      assert render(element(view, "#cb-multiple-cb")) =~ "1 selected"

      render_hook(element(view, "#cb-multiple-cb"), "remove", %{"value" => "alpha"})

      refute render(element(view, "#cb-multiple-field")) =~ "Alpha"
      refute render(element(view, "#cb-multiple-field")) =~ "data-combobox-badge"
      refute render(element(view, "#cb-multiple-cb")) =~ "1 selected"
    end

    test "clearing empties a single-select value", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/combobox")
      assert render(element(view, "#cb-selected")) =~ ~s(value="Beta")

      render_hook(element(view, "#cb-selected-cb"), "clear", %{})

      refute render(element(view, "#cb-selected")) =~ ~s(value="Beta")
    end
  end
end
