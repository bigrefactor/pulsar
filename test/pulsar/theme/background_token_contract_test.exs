defmodule Pulsar.Theme.BackgroundTokenContractTest do
  use ExUnit.Case, async: true

  @entry Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @light Path.expand("../../../priv/templates/themes/light.css.eex", __DIR__)
  @dark Path.expand("../../../priv/templates/themes/dark.css.eex", __DIR__)
  @dev_app_css Path.expand("../../support/dev_app/assets/css/app.css", __DIR__)
  @login_story Path.expand("../../support/dev_app/storybook/examples/login.story.exs", __DIR__)
  @reference_docs [
    Path.expand("../../../context/pulsar-style-guide.md", __DIR__),
    Path.expand("../../../context/pulsar-design-principles.md", __DIR__),
    Path.expand("../../../.claude/skills/pulsar-component/references/theming-and-variants.md", __DIR__)
  ]

  test "theme templates define the page ground without a redundant base surface" do
    for template <- [@light, @dark] do
      css = File.read!(template)

      assert css =~ "--color-background:"
      refute css =~ "--color-surface-0:"
    end
  end

  test "theme entry applies the page ground to body in the base layer" do
    css = File.read!(@entry)

    assert css =~
             ~r/@layer\s+base\s*\{\s*body\s*\{\s*background-color:\s*var\(--color-background\);\s*\}\s*\}/s
  end

  test "the development sandbox does not override background utilities" do
    css = File.read!(@dev_app_css)
    [_, declarations] = Regex.run(~r/\.pulsar-sandbox\s*\{([^}]*)\}/s, css)

    refute declarations =~ ~r/\bbackground(?:-color)?\s*:/
  end

  test "the generated login card uses the first elevated surface" do
    story = File.read!(@login_story)

    assert story =~ "border border-border bg-surface-1 p-8 shadow-card"
    refute story =~ "bg-surface-0"
  end

  test "contributor references use the supported surface hierarchy without obsolete guidance" do
    for reference <- @reference_docs do
      documentation = File.read!(reference)

      assert documentation =~ ~r/\bbackground\b/
      assert documentation =~ ~r/\bsurface-1\b/
      assert documentation =~ ~r/\bsurface-3\b/
      refute documentation =~ ~r/\bsurface-0\b/
      refute documentation =~ "--color-surface-*"
    end
  end
end
