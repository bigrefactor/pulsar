defmodule Pulsar.Theme.LayerTokensTest do
  @moduledoc """
  Guards the z-index layer wiring so the "inert token" class of bug
  (custom property declared, no utility generated) can't return.

  Tailwind v4 has no z-index utility namespace, so the named `z-<name>`
  utilities are wired explicitly via `@utility` rules backed by the
  `--z-*` tokens — the same pattern the duration utilities use.
  """
  use ExUnit.Case, async: true

  @template Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @built_css Path.expand(
               "../../support/dev_app/priv/static/assets/app.css",
               __DIR__
             )

  @layers ~w(docked sticky dropdown overlay modal popover toast)

  defp template, do: File.read!(@template)

  describe "z-index tokens" do
    test "declares all seven layer tokens" do
      css = template()

      for layer <- @layers do
        assert css =~ "--z-#{layer}:", "missing --z-#{layer} token"
      end
    end

    test "exposes named z-index utilities via @utility" do
      css = template()

      for layer <- @layers do
        assert css =~ "@utility z-#{layer}", "missing @utility z-#{layer}"
      end
    end
  end

  describe "built CSS (only when assets have been built)" do
    @describetag :built_css

    test "z-* utilities actually emit rules" do
      if File.exists?(@built_css) do
        css = File.read!(@built_css)

        # Tailwind v4 may keep the var() reference or inline the @theme value;
        # match both forms whitespace-tolerantly so the guard survives
        # formatting changes.
        modal_via_var = ~r/z-index:\s*var\(\s*--z-modal\s*\)/
        modal_inlined = ~r/\.z-modal\s*\{\s*z-index:\s*50\s*;?\s*\}/

        assert css =~ modal_via_var or css =~ modal_inlined,
               "z-modal utility not found in built CSS"

        overlay_via_var = ~r/z-index:\s*var\(\s*--z-overlay\s*\)/
        overlay_inlined = ~r/\.z-overlay\s*\{\s*z-index:\s*40\s*;?\s*\}/

        assert css =~ overlay_via_var or css =~ overlay_inlined,
               "z-overlay utility not found in built CSS"
      else
        IO.puts(:stderr, "skip: build assets (mix assets.build) to verify generated CSS")
      end
    end
  end
end
