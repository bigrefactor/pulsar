defmodule Pulsar.DevApp.CommandLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Pulsar.DevApp.Endpoint

  @endpoint Endpoint

  setup do
    {:ok, conn: build_conn()}
  end

  # Mounts the fixture with this test as the async filter's probe, so the filter
  # blocks in `receive` and the in-flight state stays observable until released
  # rather than for however long a sleep survives on the machine at hand.
  defp probed_live(conn) do
    conn
    |> put_connect_params(%{"probe" => self()})
    |> live("/components/command")
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

  describe "global attributes through the command/1 wrapper" do
    test "an unrecognized attribute reaches the rendered root element", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      assert render(element(view, "#cmd-globals")) =~ ~s(data-testid="cmd-globals-marker")
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
    # Reading the in-flight state means catching the component between the
    # keystroke and the result. A sleeping filter loses that race whenever the
    # machine is loaded enough to outrun it, so hold the task open instead:
    # the probe's filter blocks until this test releases it.
    test "marks its own listbox busy in flight, keeps prior rows, and shows a spinner", %{conn: conn} do
      {:ok, view, _html} = probed_live(conn)

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      assert_receive {:filtering, task}
      in_flight = render(element(view, "#cmd-async"))

      assert in_flight =~ ~s(aria-busy="true")
      assert in_flight =~ "Cormorant"
      assert in_flight =~ "animate-spin"

      send(task, :release)
    end

    test "a sync sibling is not marked busy by an async neighbour", %{conn: conn} do
      {:ok, view, _html} = probed_live(conn)

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      assert_receive {:filtering, task}

      refute render(element(view, "#cmd-filter")) =~ ~s(aria-busy="true")

      send(task, :release)
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

    test "an async command does not run the caller's filter on select", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/components/command")

      render_hook(element(view, "#cmd-async-error"), "select", %{"value" => "Egret"})

      settled = render(element(view, "#cmd-async-error"))

      assert settled =~ "Egret"
      refute settled =~ ~s(aria-busy="true")
    end

    test "an async filter still in flight is cancelled rather than applied", %{conn: conn} do
      {:ok, view, _html} = probed_live(conn)

      render_hook(element(view, "#cmd-async"), "query", %{"query" => "r"})
      assert_receive {:filtering, _task}
      assert render(element(view, "#cmd-async")) =~ ~s(aria-busy="true")

      render_hook(element(view, "#cmd-async"), "select", %{"value" => "Cormorant"})
      render_async(view)

      settled = render(element(view, "#cmd-async"))

      assert settled =~ "Cormorant"
      refute settled =~ "Remote result"
      refute settled =~ ~s(aria-busy="true")
    end
  end

  defp listbox(view), do: render(element(view, "#cmd-filter-listbox"))
end
