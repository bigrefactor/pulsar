defmodule Pulsar.Igniter do
  @moduledoc """
  Igniter configuration for Pulsar package.

  This module defines how Pulsar integrates with Igniter for component generation.
  """

  def install(_igniter, _opts) do
    # This will be called when someone runs `mix igniter.install pulsar`
    # We'll delegate to our main installer task
    Mix.Task.run("pulsar.install", ["--all"])
  end

  def extensions do
    # Define any custom extensions if needed
    []
  end

  def igniter_tasks do
    # List of tasks that can be composed with Igniter
    [
      {"pulsar.install", "Install Pulsar components"},
      {"pulsar.gen.button", "Generate Button component"},
      {"pulsar.gen.badge", "Generate Badge component"},
      {"pulsar.gen.card", "Generate Card component"},
      {"pulsar.gen.checkbox", "Generate Checkbox component"},
      {"pulsar.gen.divider", "Generate Divider component"},
      {"pulsar.gen.field", "Generate Field component"},
      {"pulsar.gen.flash", "Generate Flash component"},
      {"pulsar.gen.flash_group", "Generate FlashGroup component"},
      {"pulsar.gen.header", "Generate Header component"},
      {"pulsar.gen.icon", "Generate Icon component"},
      {"pulsar.gen.input", "Generate Input component"},
      {"pulsar.gen.label", "Generate Label component"},
      {"pulsar.gen.link", "Generate Link component"},
      {"pulsar.gen.list", "Generate List component"},
      {"pulsar.gen.radio_group", "Generate RadioGroup component"},
      {"pulsar.gen.select", "Generate Select component"},
      {"pulsar.gen.switch", "Generate Switch component"},
      {"pulsar.gen.table", "Generate Table component"},
      {"pulsar.gen.textarea", "Generate Textarea component"}
    ]
  end
end
