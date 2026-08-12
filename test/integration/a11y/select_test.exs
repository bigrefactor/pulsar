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
    test "clicking a badge remove button only updates its containing select", %{conn: conn} do
      session =
        conn
        |> visit("/components/select/removable")
        |> A11y.await_live_connected()
        |> assert_has("#sel-remove-primary-count", text: "2")
        |> assert_has("#sel-remove-sibling-count", text: "2")
        |> PhoenixTest.Playwright.evaluate("""
        window.pulsarRemoveTargets = [];
        document.addEventListener("pulsar:remove-selection", event => {
          window.pulsarRemoveTargets.push(event.target.id || event.target.ariaLabel);
        }, true);
        """)
        |> click(~s|[data-fixture-section="primary"] button[aria-label="Remove One"]|)
        |> refute_has(~s|[data-fixture-section="primary"] button[aria-label="Remove One"]|)
        |> assert_has(~s|[data-fixture-section="sibling"] button[aria-label="Remove One"]|)

      PhoenixTest.Playwright.evaluate(
        session,
        """
        ({
          primary: document.querySelector('#sel-remove-primary-count').textContent,
          sibling: document.querySelector('#sel-remove-sibling-count').textContent,
          targets: window.pulsarRemoveTargets
        })
        """,
        fn state ->
          assert state == %{"primary" => "1", "sibling" => "2", "targets" => ["Remove One"]}
        end
      )
    end
  end
end
