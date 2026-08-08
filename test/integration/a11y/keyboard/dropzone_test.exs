defmodule Pulsar.Integration.A11y.Keyboard.DropzoneTest do
  @moduledoc """
  Real-browser keyboard tests for Dropzone. Axe-clean catches static
  a11y problems but not behavior — these tests drive the real DOM.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Dropzone interaction" do
    test "selecting a file renders a visible entry row", %{conn: conn} do
      conn
      |> visit("/keyboard/dropzone")
      |> A11y.await_live_connected()
      |> upload("Click to upload or drag and drop", "test/support/fixtures/upload_sample.png", exact: false)
      |> assert_has("#kbd-dz li", text: "upload_sample.png")
    end

    test "cancelling an entry removes its visible row", %{conn: conn} do
      conn
      |> visit("/keyboard/dropzone")
      |> A11y.await_live_connected()
      |> upload("Click to upload or drag and drop", "test/support/fixtures/upload_sample.png", exact: false)
      |> assert_has("#kbd-dz li", text: "upload_sample.png")
      |> click(~s|#kbd-dz button[aria-label^="Cancel upload"]|)
      |> refute_has("#kbd-dz li")
    end

    test "dragging files over shows the visible drop prompt; leaving hides it", %{conn: conn} do
      session =
        conn
        |> visit("/keyboard/dropzone")
        |> A11y.await_live_connected()

      A11y.refute_visible(session, "kbd-dz-drop-prompt")

      # LiveView toggles phx-drop-target-active inside requestAnimationFrame,
      # so each dispatch resolves after two frames to let the class settle
      # before the visibility assertion.
      drag_js = """
      (() => {
        const el = document.getElementById('kbd-dz');
        const dt = new DataTransfer();
        dt.items.add(new File(['x'], 'x.png', {type: 'image/png'}));
        el.dispatchEvent(new DragEvent('dragenter', {bubbles: true, dataTransfer: dt}));
        return new Promise((resolve) =>
          requestAnimationFrame(() => requestAnimationFrame(() => resolve('settled'))));
      })()
      """

      PhoenixTest.Playwright.evaluate(session, drag_js, fn _ -> :ok end)
      A11y.assert_visible(session, "kbd-dz-drop-prompt")

      leave_js = """
      (() => {
        const el = document.getElementById('kbd-dz');
        el.dispatchEvent(new DragEvent('dragleave', {bubbles: true}));
        return new Promise((resolve) =>
          requestAnimationFrame(() => requestAnimationFrame(() => resolve('settled'))));
      })()
      """

      PhoenixTest.Playwright.evaluate(session, leave_js, fn _ -> :ok end)
      A11y.refute_visible(session, "kbd-dz-drop-prompt")
    end
  end
end
