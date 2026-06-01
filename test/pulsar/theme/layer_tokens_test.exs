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

  @layer_values [docked: 10, sticky: 20, dropdown: 30, overlay: 40, modal: 50, popover: 60, toast: 70]
  @layers Keyword.keys(@layer_values)

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
        # match both forms whitespace-tolerantly. Both anchor on the
        # `.z-<layer>` selector so a stray arbitrary value or unrelated rule
        # using the token elsewhere can't satisfy the guard.
        for {layer, z} <- @layer_values do
          via_var = ~r/\.z-#{layer}\s*\{\s*z-index:\s*var\(\s*--z-#{layer}\s*\)/
          inlined = ~r/\.z-#{layer}\s*\{\s*z-index:\s*#{z}\s*;?\s*\}/

          assert css =~ via_var or css =~ inlined,
                 "z-#{layer} utility not found in built CSS"
        end
      else
        IO.puts(:stderr, "skip: build assets (mix assets.build) to verify generated CSS")
      end
    end
  end
end
