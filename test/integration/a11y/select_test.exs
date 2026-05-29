defmodule Pulsar.Integration.A11y.SelectTest do
  @moduledoc """
  End-to-end test for the Select multi-select badge-removal interaction.

  Drives the `Pulsar.DevApp.SelectRemoveLive` fixture through a real
  click-to-remove cycle: clicking a badge's remove button fires the
  `.PulsarSelect` colocated hook, which deselects the matching `<option>`
  and dispatches a `change` event so the form re-renders without that badge.

  This proves the hook actually mounts and runs in a browser. A unit test
  only sees the server-rendered `phx-hook` attribute string, not whether the
  hook name resolves to a registered hook and its handler executes — exactly
  the gap that let a broken hook ship unnoticed.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.

  ## Verification

  To prove the test is wired to the real hook, temporarily change the wrapper
  in `priv/templates/select.ex.eex` back to `phx-hook={@multiple &&
  ".PulsarSelect"}` (a dynamic expression Phoenix can't qualify), run
  `mix pulsar.sync`, and re-run this test — removal should fail because the
  unqualified `.PulsarSelect` name never resolves and the hook never mounts.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  describe "Select multi-select badge removal" do
    test "clicking a badge remove button deselects that option", %{conn: conn} do
      conn
      |> visit("/components/select/removable")
      |> A11y.await_live_connected()
      |> assert_has("#sel-remove-count", text: "2")
      |> assert_has(~s|button[aria-label="Remove One"]|)
      |> assert_has(~s|button[aria-label="Remove Two"]|)
      |> click(~s|button[aria-label="Remove One"]|)
      |> assert_has("#sel-remove-count", text: "1")
      |> refute_has(~s|button[aria-label="Remove One"]|)
      |> assert_has(~s|button[aria-label="Remove Two"]|)
    end
  end
end
