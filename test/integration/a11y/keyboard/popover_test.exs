defmodule Pulsar.Integration.A11y.Keyboard.PopoverTest do
  @moduledoc """
  Real-browser keyboard tests for Popover. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Popover keyboard behavior" do
    # The fixture at `/keyboard/popover` renders a trigger button
    # (kbd-pop-trigger) wired by the `.PulsarPopover` colocated hook to a
    # native `popover="auto"` panel (kbd-pop) holding a focusable link
    # (kbd-pop-inside). Open/close/dismiss are native; the hook syncs
    # `aria-expanded` and `data-state` on the `toggle` event.
    #
    # Verification: comment out the `aria-expanded` setAttribute calls in
    # `onStateChange` of the `.PulsarPopover` hook (priv/templates/popover.ex.eex
    # and the synced lib file), run `MIX_ENV=test mix assets.build`, re-run —
    # the open/close aria-expanded assertions fail.

    test "Enter on the trigger opens the panel and reflects expanded state", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> assert_has(~s|#kbd-pop[data-state="open"]|)
    end

    test "Escape closes the panel, restores focus to the trigger, and resets expanded", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> press("#kbd-pop-inside", "Escape")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="false"]|)
      |> A11y.assert_focused("kbd-pop-trigger")
    end

    # The `kbd-pop-patch` cell pairs a popover with a `bump` button that
    # re-renders only the trigger's label. The trigger's `popovertarget` /
    # `aria-controls` / `aria-expanded` are client-applied and absent from the
    # server's markup, and the panel — the hook's own element — is byte-identical
    # across that patch, so `updated()` never runs. Without the hook marking
    # those attributes ignored, morphdom reverts the trigger to the server's
    # markup and the control is dead for the rest of the page's life.
    #
    # Verification: remove the `ignoreTriggerAttrs` call from `setupClick` in the
    # `.PulsarPopover` hook (priv/templates/popover.ex.eex + `mix pulsar.sync`),
    # run `MIX_ENV=test mix assets.build`, re-run — this test fails while every
    # other test in this file still passes.

    test "the trigger still opens the panel after a patch re-renders it", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> click("#kbd-pop-patch-bump")
      |> assert_has("#kbd-pop-patch-trigger", text: "Patched 1")
      |> assert_has(~s|#kbd-pop-patch-trigger[popovertarget="kbd-pop-patch"]|)
      |> click("#kbd-pop-patch-trigger")
      |> assert_has(~s|#kbd-pop-patch[data-state="open"]|)
      |> A11y.assert_visible("kbd-pop-patch")
    end

    # The `kbd-pop-form` cell holds a form whose `phx-submit` pushes the event
    # and then dispatches `pulsar:popover-hide` at the panel. The native
    # `popovertarget` attributes can't close a panel from a submit button, so
    # this path exists only through the hook's event listener.
    #
    # The reopen at the end is the part that matters: a `display: none` close
    # (what `JS.hide` would do) leaves the panel in the top layer, and the next
    # `showPopover()` throws — the panel never comes back.
    #
    # Verification: remove the `pulsar:popover-hide` listener from `mounted()`
    # in the `.PulsarPopover` hook (priv/templates/popover.ex.eex +
    # `mix pulsar.sync`), run `MIX_ENV=test mix assets.build`, re-run — the
    # panel stays open after submit.

    test "submitting a form inside the panel pushes the event and closes the panel", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> click("#kbd-pop-form-trigger")
      |> A11y.assert_visible("kbd-pop-form")
      |> click("#kbd-pop-form-submit")
      |> assert_has("#kbd-pop-form-applied", text: "blue")
      |> assert_has(~s|#kbd-pop-form-trigger[aria-expanded="false"]|)
      |> A11y.refute_visible("kbd-pop-form")
      |> A11y.assert_focused("kbd-pop-form-trigger")
      |> click("#kbd-pop-form-trigger")
      |> A11y.assert_visible("kbd-pop-form")
    end

    # The other half of the close-focus rule: a panel the user never focused
    # into doesn't own focus, so closing it must leave focus where it is rather
    # than pulling it to the trigger. The event is dispatched directly here
    # because clicking any control outside an open `popover="auto"` panel
    # light-dismisses it before a `phx-click` could run.

    test "closing a panel that never held focus leaves focus alone", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> click("#kbd-pop-form-trigger")
      |> A11y.assert_visible("kbd-pop-form")
      |> A11y.focus("kbd-pop-before")
      |> PhoenixTest.Playwright.evaluate(
        ~s|document.getElementById("kbd-pop-form").dispatchEvent(new CustomEvent("pulsar:popover-hide", {bubbles: true}))|
      )
      |> A11y.refute_visible("kbd-pop-form")
      |> A11y.assert_focused("kbd-pop-before")
    end

    test "a JS.dispatch from outside the panel opens it", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> click("#kbd-pop-form-show-outside")
      |> assert_has(~s|#kbd-pop-form[data-state="open"]|)
      |> assert_has(~s|#kbd-pop-form-trigger[aria-expanded="true"]|)
      |> A11y.assert_visible("kbd-pop-form")
    end

    test "Tab from inside the open panel is not trapped", %{conn: conn} do
      conn
      |> visit("/keyboard/popover")
      |> A11y.await_live_connected()
      |> press("#kbd-pop-trigger", "Enter")
      |> assert_has(~s|#kbd-pop-trigger[aria-expanded="true"]|)
      |> press("#kbd-pop-inside", "Tab")
      |> A11y.refute_focused_within("#kbd-pop")
    end
  end
end
