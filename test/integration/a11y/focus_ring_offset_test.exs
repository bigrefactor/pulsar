defmodule Pulsar.Integration.A11y.FocusRingOffsetTest do
  @moduledoc """
  Asserts a focused control's ring offset resolves to `--color-background`.

  Both themes are read because the light-theme page ground is white, which is
  also Tailwind's built-in default — a light-only run cannot tell them apart.

  Tagged `:integration`; excluded from `mix test` by default. Run with
  `mix test --only integration`.
  """

  use PhoenixTest.Playwright.Case, async: true

  alias Pulsar.DevApp.A11y

  @moduletag :integration

  # A control carrying the plain `focus-visible:ring-2 ring-offset-2` idiom,
  # with no explicit `ring-offset-*` color of its own.
  @control "button[data-fixture-cell]:not([disabled])"

  @probe """
  (() => {
    const el = document.querySelector("#{@control}");
    el.focus();
    const style = getComputedStyle(el);
    return {
      focusVisible: el.matches(":focus-visible"),
      offset: style.getPropertyValue("--tw-ring-offset-color").trim(),
      offsetShadow: style.getPropertyValue("--tw-ring-offset-shadow").trim(),
      background: getComputedStyle(document.documentElement)
        .getPropertyValue("--color-background").trim()
    };
  })()
  """

  test "a focused control offsets its ring against the page ground in both themes",
       %{conn: conn} do
    session =
      conn
      |> visit("/components/button")
      |> A11y.await_live_connected()

    light = read_probe(session, :light)
    dark = read_probe(session, :dark)

    for {theme, probe} <- [light: light, dark: dark] do
      assert probe["focusVisible"], "#{theme}: control did not reach :focus-visible"

      assert probe["offset"] == probe["background"],
             "#{theme}: ring offset resolved to #{inspect(probe["offset"])}, " <>
               "expected the page ground #{inspect(probe["background"])}"

      assert probe["offsetShadow"] =~ probe["background"],
             "#{theme}: offset shadow #{inspect(probe["offsetShadow"])} does not " <>
               "paint the page ground #{inspect(probe["background"])}"
    end

    refute light["offset"] == dark["offset"],
           "ring offset did not follow the theme — both resolved to " <>
             inspect(light["offset"])
  end

  defp read_probe(session, theme) do
    session
    |> A11y.set_theme(theme)
    |> PhoenixTest.Playwright.evaluate(@probe, &Process.put(:ring_offset_probe, &1))

    Process.get(:ring_offset_probe)
  end
end
