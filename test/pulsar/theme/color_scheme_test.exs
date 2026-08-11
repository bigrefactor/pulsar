defmodule Pulsar.Theme.ColorSchemeTest do
  @moduledoc """
  Guards the `color-scheme` declaration in the generated themes.

  Semantic tokens only repaint what CSS paints. Browser-drawn UI — scrollbars,
  `<select>` popup lists, date and time pickers, the autofill overlay — reads
  `color-scheme` and nothing else, so a dark theme without it renders light
  chrome against dark surfaces.

  The declaration cannot live inside a Tailwind `@theme` block (Tailwind
  accepts only custom properties and `@keyframes` there, and errors out
  otherwise), which is why the light theme carries a separate bare `:root`
  rule.
  """
  use ExUnit.Case, async: true

  @light Path.expand("../../../priv/templates/themes/light.css.eex", __DIR__)
  @dark Path.expand("../../../priv/templates/themes/dark.css.eex", __DIR__)
  @scaffold Path.expand("../../../priv/templates/themes/scaffold.css.eex", __DIR__)
  @built_css Path.expand("../../support/dev_app/priv/static/assets/app.css", __DIR__)

  describe "light theme template" do
    test "declares color-scheme: light in a bare :root rule" do
      assert File.read!(@light) =~ ~r/^:root \{\n\s*color-scheme: light;/m,
             "light.css.eex must carry a bare `:root { color-scheme: light; }` rule"
    end

    test "declares color-scheme: light inside the explicit selector block" do
      css = File.read!(@light)

      assert css =~ ~r/\[data-theme="light"\],\s*\.theme-light\s*\{\s*color-scheme:\s*light;/,
             "a light subtree nested inside a dark ancestor needs its own color-scheme"
    end

    test "keeps color-scheme out of the @theme block" do
      css = File.read!(@light)
      # Anchor on a line-start "@theme {" so this can't match the header
      # comment's own backtick-quoted mention of `@theme { ... }`.
      [_preamble, after_theme] = String.split(css, "\n@theme {", parts: 2)
      [theme_block, _rest] = String.split(after_theme, "\n}", parts: 2)

      refute theme_block =~ "color-scheme",
             "Tailwind rejects non-custom-property declarations inside @theme"
    end
  end

  describe "dark theme template" do
    test "declares color-scheme: dark in the theme block" do
      css = File.read!(@dark)

      assert css =~ ~r/\[data-theme="dark"\],\s*\.theme-dark\s*\{\s*color-scheme:\s*dark;/,
             "dark.css.eex must declare color-scheme: dark"
    end

    test "uses the middle gray step for strong structural borders" do
      css = File.read!(@dark)

      assert css =~ "--color-border-strong: var(--color-gray-500);"
      refute css =~ "--color-border-strong: var(--color-gray-400);"
    end
  end

  describe "scaffold template" do
    test "interpolates the polarity chosen by the generator" do
      assert File.read!(@scaffold) =~ "color-scheme: <%= @color_scheme %>;"
    end
  end

  describe "built CSS (only when assets have been built)" do
    @describetag :built_css

    test "both declarations survive compilation, dark last" do
      if File.exists?(@built_css) do
        css = File.read!(@built_css)

        light_at = match_index!(css, ~r/:root[^{}]*\{[^}]*color-scheme:\s*light/)
        dark_at = match_index!(css, ~r/\[data-theme="dark"\][^{]*\{[^}]*color-scheme:\s*dark/)

        assert dark_at > light_at,
               "themes/dark.css must be imported after themes/light.css — " <>
                 "the two rules have equal specificity, so source order decides"
      else
        IO.puts(:stderr, "skip: build assets (mix assets.build) to verify generated CSS")
      end
    end
  end

  defp match_index!(css, regex) do
    case Regex.run(regex, css, return: :index) do
      [{index, _len} | _] -> index
      nil -> flunk("no match for #{inspect(regex)} in built CSS")
    end
  end
end
