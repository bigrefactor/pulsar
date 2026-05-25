defmodule Mix.Tasks.Pulsar.DevApp.Theme do
  @moduledoc """
  Renders `priv/templates/theme.css.eex` into the in-repo fixture app's
  asset directory so `mix tailwind dev_app` can `@import` the theme tokens.

  The template is the canonical source of theme tokens (also shipped to
  consumer apps via the installer). Going through `EEx.eval_file/2` keeps
  this task working even if the template gains interpolation later.
  """

  use Mix.Task

  @source "priv/templates/theme.css.eex"
  @target "test/support/dev_app/assets/css/theme.css"

  @impl Mix.Task
  def run(_args) do
    source = Path.expand(@source, File.cwd!())
    target = Path.expand(@target, File.cwd!())

    contents = EEx.eval_file(source, [])
    File.mkdir_p!(Path.dirname(target))
    File.write!(target, contents)
  end
end
