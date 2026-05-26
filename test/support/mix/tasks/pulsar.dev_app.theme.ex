defmodule Mix.Tasks.Pulsar.DevApp.Theme do
  @moduledoc """
  Renders the Pulsar theme templates into the in-repo fixture app's asset
  directory so `mix tailwind dev_app` can `@import` the theme tokens.

  The templates are the canonical source of theme tokens (also shipped to
  consumer apps via the installer). Going through `EEx.eval_file/2` keeps
  this task working even if templates gain interpolation later.

  Renders the entry `theme.css` plus the per-theme files under `themes/`.
  """

  use Mix.Task

  @target_dir "test/support/dev_app/assets/css"

  @files [
    {"priv/templates/theme.css.eex", "theme.css"},
    {"priv/templates/themes/light.css.eex", "themes/light.css"},
    {"priv/templates/themes/dark.css.eex", "themes/dark.css"}
  ]

  @impl Mix.Task
  def run(_args) do
    target_dir = Path.expand(@target_dir, File.cwd!())

    for {source_rel, target_rel} <- @files do
      source = Path.expand(source_rel, File.cwd!())
      target = Path.join(target_dir, target_rel)

      contents = EEx.eval_file(source, [])
      File.mkdir_p!(Path.dirname(target))
      File.write!(target, contents)
    end
  end
end
