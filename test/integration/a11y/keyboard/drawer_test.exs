defmodule Pulsar.Integration.A11y.Keyboard.DrawerTest do
  @moduledoc """
  Real-browser keyboard tests for Drawer backdrop dismissal. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Drawer backdrop dismissal" do
    # The fixture at `/keyboard/drawer` mirrors the storybook drawer template:
    # the trigger and the drawer share one wrapper carrying the open dispatcher
    # (`phx-click={Drawer.open("kbd-drawer")}`). A backdrop click on the open
    # dialog bubbles up to that wrapper, so unless the `.PulsarModal` hook stops
    # the click after dismissing, the drawer closes and the bubbled click
    # immediately re-opens it — the reported "clicking outside does nothing" bug.
    #
    # Verification: drop the `e.stopPropagation()` line from `handleClick` in
    # `priv/templates/modal.ex.eex` (and the synced lib file), run
    # `MIX_ENV=test mix assets.build`, re-run — the dialog re-opens after the
    # backdrop click and the assertion fails.

    test "a backdrop click closes the drawer and does not re-open it", %{conn: conn} do
      conn
      |> visit("/keyboard/drawer")
      |> A11y.await_live_connected()
      |> click("#kbd-drawer-open")
      |> assert_has(~s|#kbd-drawer[data-state="open"]|)
      |> A11y.assert_modal("kbd-drawer")
      |> dispatch_backdrop_click("kbd-drawer")
      |> assert_dialog_closed("kbd-drawer")
    end
  end

  # Dispatches a realistic backdrop click on the open dialog `id`: a
  # mousedown + click whose pointer lands outside the panel box (the modal hook
  # requires both the down and the click to target the dialog itself, which is
  # how the browser reports a `::backdrop` click). The coordinates are derived
  # from the live panel rect, so this works regardless of which edge the drawer
  # is anchored to or whether the slide-in animation has settled.
  defp dispatch_backdrop_click(conn, id) do
    expr = """
    (() => {
      const dlg = document.getElementById(#{Jason.encode!(id)});
      const r = dlg.getBoundingClientRect();
      const x = Math.max(2, Math.round(r.left / 2));
      const y = Math.round((r.top + r.bottom) / 2);
      const init = {bubbles: true, cancelable: true, view: window, clientX: x, clientY: y, button: 0};
      dlg.dispatchEvent(new MouseEvent("mousedown", init));
      dlg.dispatchEvent(new MouseEvent("click", init));
    })()
    """

    PhoenixTest.Playwright.evaluate(conn, expr)
  end

  # Asserts the dialog `id` is closed (`HTMLDialogElement.open === false`).
  # Reads `.open` directly rather than `data-state`, because the bug's
  # fingerprint is `open === true` while `data-state` has already flipped to
  # "closed" (the close event fires after the bubbled re-open).
  defp assert_dialog_closed(conn, id) do
    expr = "Boolean(document.getElementById(#{Jason.encode!(id)}).open)"

    PhoenixTest.Playwright.evaluate(conn, expr, fn open? ->
      if open? do
        raise ExUnit.AssertionError,
          message: "expected ##{id} to be closed after a backdrop click, but it re-opened"
      end
    end)
  end
end
