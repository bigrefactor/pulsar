defmodule Pulsar.DevApp.StorybookHooksTest do
  @moduledoc """
  Guards the colocated-hook wiring for the storybook bundle, so a
  JS-driven component can't ship a story whose interactions are dead.
  """
  use ExUnit.Case, async: true

  @bundle Path.expand("../../support/dev_app/priv/static/assets/storybook.js", __DIR__)

  @moduletag :built_css

  test "every colocated hook reaches the storybook bundle" do
    bundle = File.read!(@bundle)

    for hook <- ~w(PulsarCommand PulsarCalendar PulsarTabs) do
      assert bundle =~ hook,
             "#{hook} is missing from the built storybook bundle; its story's interactions would be inert"
    end
  end
end
