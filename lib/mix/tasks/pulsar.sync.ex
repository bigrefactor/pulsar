defmodule Mix.Tasks.Pulsar.Sync do
  @moduledoc """
  Regenerates the bundled library components from their EEx templates.

  `priv/templates/*.ex.eex` are the single source of truth. This task renders
  each template with the fixed library assigns and writes the result to its
  committed `lib/pulsar/components/*.ex` (or `lib/pulsar/core_components.ex`)
  file, so the two never need to be hand-mirrored.

      mix pulsar.sync           # regenerate lib files from templates
      mix pulsar.sync --check   # verify they're in sync; exit non-zero on drift

  `--check` writes nothing and is wired into the `check`/`check.ci` aliases and
  CI to fail when a committed lib file has drifted from its template.

  This is a maintainer task for the Pulsar repository itself; it is not meant to
  be run inside an application that has installed Pulsar.
  """

  # No @shortdoc on purpose — keeps `mix help` limited to `pulsar.install` as the
  # public entry point, consistent with the `pulsar.gen.*` tasks.

  use Mix.Task

  alias Pulsar.TemplateSync

  @impl Mix.Task
  def run(argv) do
    ensure_pulsar_repo!()

    {opts, _, _} = OptionParser.parse(argv, strict: [check: :boolean])

    if opts[:check] do
      check()
    else
      write()
    end
  end

  defp write do
    written =
      for {{_component, lib_path, _ns, _module}, expected} <- TemplateSync.diff() do
        File.write!(lib_path, expected <> "\n")
        lib_path
      end

    case written do
      [] ->
        Mix.shell().info("pulsar.sync: all generated components already in sync with templates.")

      paths ->
        Mix.shell().info("pulsar.sync: regenerated #{length(paths)} file(s) from templates:")
        Enum.each(paths, &Mix.shell().info("  * #{&1}"))
    end
  end

  defp check do
    case TemplateSync.diff() do
      [] ->
        Mix.shell().info("pulsar.sync --check: generated components are in sync with templates.")

      drifted ->
        paths = Enum.map(drifted, fn {{_c, lib_path, _ns, _m}, _expected} -> lib_path end)

        Mix.raise("""
        The following generated lib files have drifted from their templates:

        #{Enum.map_join(paths, "\n", &"  * #{&1}")}

        Edit the template under priv/templates/ (the source of truth), then run:

            mix pulsar.sync
        """)
    end
  end

  defp ensure_pulsar_repo! do
    if Mix.Project.config()[:app] != :pulsar do
      Mix.raise(
        "mix pulsar.sync is a maintainer task for the Pulsar repository only " <>
          "(it rewrites lib/pulsar/* from priv/templates/*). It is not meant to run " <>
          "inside an application — use `mix pulsar.install` / `mix pulsar.gen.*` instead."
      )
    end
  end
end
