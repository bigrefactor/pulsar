defmodule Pulsar.Integration.A11y.Keyboard.ModalTest do
  @moduledoc """
  Real-browser keyboard tests for Modal. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Modal keyboard behavior" do
    # The fixture at `/keyboard/modal` renders a trigger button
    # (kbd-modal-open) that opens a native `<dialog>` (kbd-modal) via the
    # `.PulsarModal` colocated hook's `showModal()`. The dialog autofocuses
    # its text input (kbd-modal-input); the browser provides the modal focus
    # trap and Escape handling, and restores focus to the opener on close. A
    # second, `dismissable={false}` dialog (kbd-modal-locked) ignores Escape.
    #
    # Verification: comment out the `showModal()` call in the `.PulsarModal`
    # hook's `open()` (priv/templates/modal.ex.eex and the synced lib file),
    # run `MIX_ENV=test mix assets.build`, re-run — the open assertions fail.

    test "opening shows a modal dialog and moves focus inside", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-open", "Enter")
      |> assert_has(~s|#kbd-modal[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal")
      |> A11y.assert_focused("kbd-modal-input")
    end

    test "Escape closes a dismissable dialog and restores focus to the opener", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-open", "Enter")
      |> assert_has(~s|#kbd-modal[data-state="open"]|)
      |> press("#kbd-modal-input", "Escape")
      |> A11y.assert_focused("kbd-modal-open")
    end

    test "a non-dismissable dialog ignores Escape and stays open", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-locked-open", "Enter")
      |> assert_has(~s|#kbd-modal-locked[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal-locked")
      |> press("#kbd-modal-locked-input", "Escape")
      |> assert_has(~s|#kbd-modal-locked[data-state="open"]|)
      |> A11y.assert_modal("kbd-modal-locked")
    end
  end

  describe "Modal typography is independent of its mount point" do
    # A `<dialog>` opened with `showModal()` renders in the top layer but
    # still inherits computed CSS from its DOM parent. The fixture mounts
    # `kbd-modal-aligned` inside a `text-right cursor-pointer` wrapper (the
    # shape of a table's clickable action cell); the panel must read
    # start-aligned with a default cursor regardless.
    test "the panel resets inherited text-align and cursor", %{conn: conn} do
      conn
      |> visit("/keyboard/modal")
      |> A11y.await_live_connected()
      |> press("#kbd-modal-aligned-open", "Enter")
      |> assert_has(~s|#kbd-modal-aligned[data-state="open"]|)
      |> A11y.assert_computed_style("kbd-modal-aligned", "text-align", "start")
      |> A11y.assert_computed_style("kbd-modal-aligned", "cursor", "auto")
    end
  end
end
