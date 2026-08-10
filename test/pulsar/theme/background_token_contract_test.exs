defmodule Pulsar.Theme.BackgroundTokenContractTest do
  use ExUnit.Case, async: true

  @entry Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @light Path.expand("../../../priv/templates/themes/light.css.eex", __DIR__)
  @dark Path.expand("../../../priv/templates/themes/dark.css.eex", __DIR__)
  @dev_app_css Path.expand("../../support/dev_app/assets/css/app.css", __DIR__)

  test "documents --color-background as the body page ground" do
    css = File.read!(@entry)

    assert css =~ "`--color-background` is the application/page ground"
    assert css =~ "Apply `bg-background`"
    assert css =~ "to `<body>`"
  end

  test "documents --color-surface-0 as the base elevation surface" do
    for template <- [@light, @dark] do
      css = File.read!(template)

      assert css =~ ~r/--color-surface-0:[^;]+;\s*\/\* Base elevation surface \*\//
      refute css =~ "Canvas/page background"
    end
  end

  test "the development sandbox uses the page ground token" do
    css = File.read!(@dev_app_css)

    assert css =~
             ~r/\.pulsar-sandbox\s*\{[^}]*background-color:\s*var\(--color-background\);/s

    refute css =~
             ~r/\.pulsar-sandbox\s*\{[^}]*background-color:\s*var\(--color-surface-0\);/s
  end
end
