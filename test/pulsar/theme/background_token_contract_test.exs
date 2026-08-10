defmodule Pulsar.Theme.BackgroundTokenContractTest do
  use ExUnit.Case, async: true

  @entry Path.expand("../../../priv/templates/theme.css.eex", __DIR__)
  @light Path.expand("../../../priv/templates/themes/light.css.eex", __DIR__)
  @dark Path.expand("../../../priv/templates/themes/dark.css.eex", __DIR__)

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
end
