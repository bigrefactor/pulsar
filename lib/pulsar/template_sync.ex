defmodule Pulsar.TemplateSync do
  @moduledoc """
  Maintainer/repo-internal helper that treats `priv/templates/*.ex.eex` as the
  single source of truth for the bundled library components.

  Each component lives once, as an EEx template. The committed
  `lib/pulsar/components/*.ex` (and `lib/pulsar/core_components.ex`) files are
  *generated* from those templates by `mix pulsar.sync`, so they never need to
  be hand-mirrored. This module holds the canonical template → lib-file mapping
  (`pairs/0`) and the deterministic transform (`expected/1`) shared by the write
  and `--check` modes of that task.

  This is build tooling for the Pulsar repository itself — it is not part of the
  public, generated-into-your-app surface.
  """

  alias Mix.Tasks.Format

  @components_root "Pulsar.Components"
  @gettext_module "Pulsar.Gettext"

  @typedoc """
  `{component_name, lib_path, component_namespace, module_name}`.

    * `component_name` - the template basename (`:button` → `button.ex.eex`).
    * `lib_path` - repo-relative path of the generated lib file.
    * `component_namespace` - the parent namespace the file lands under in
      library mode (`"Pulsar.Components"` for most, `"Pulsar"` for
      CoreComponents so it becomes `Pulsar.CoreComponents` per Phoenix
      convention).
    * `module_name` - the fully qualified module the template produces, used to
      wrap the rendered EEx body in `defmodule ... do/end`.
  """
  @type pair :: {atom(), String.t(), String.t(), String.t()}

  @pairs [
    {:badge, "lib/pulsar/components/badge.ex", "Pulsar.Components", "Pulsar.Components.Badge"},
    {:button, "lib/pulsar/components/button.ex", "Pulsar.Components", "Pulsar.Components.Button"},
    {:card, "lib/pulsar/components/card.ex", "Pulsar.Components", "Pulsar.Components.Card"},
    {:checkbox, "lib/pulsar/components/checkbox.ex", "Pulsar.Components", "Pulsar.Components.Checkbox"},
    {:divider, "lib/pulsar/components/divider.ex", "Pulsar.Components", "Pulsar.Components.Divider"},
    {:field, "lib/pulsar/components/field.ex", "Pulsar.Components", "Pulsar.Components.Field"},
    {:flash, "lib/pulsar/components/flash.ex", "Pulsar.Components", "Pulsar.Components.Flash"},
    {:flash_group, "lib/pulsar/components/flash_group.ex", "Pulsar.Components", "Pulsar.Components.FlashGroup"},
    {:form, "lib/pulsar/components/form.ex", "Pulsar.Components", "Pulsar.Components.Form"},
    {:header, "lib/pulsar/components/header.ex", "Pulsar.Components", "Pulsar.Components.Header"},
    {:icon, "lib/pulsar/components/icon.ex", "Pulsar.Components", "Pulsar.Components.Icon"},
    {:input, "lib/pulsar/components/input.ex", "Pulsar.Components", "Pulsar.Components.Input"},
    {:label, "lib/pulsar/components/label.ex", "Pulsar.Components", "Pulsar.Components.Label"},
    {:link, "lib/pulsar/components/link.ex", "Pulsar.Components", "Pulsar.Components.Link"},
    {:list, "lib/pulsar/components/list.ex", "Pulsar.Components", "Pulsar.Components.List"},
    {:menu, "lib/pulsar/components/menu.ex", "Pulsar.Components", "Pulsar.Components.Menu"},
    {:modal, "lib/pulsar/components/modal.ex", "Pulsar.Components", "Pulsar.Components.Modal"},
    {:navbar, "lib/pulsar/components/navbar.ex", "Pulsar.Components", "Pulsar.Components.Navbar"},
    {:popover, "lib/pulsar/components/popover.ex", "Pulsar.Components", "Pulsar.Components.Popover"},
    {:radio_group, "lib/pulsar/components/radio_group.ex", "Pulsar.Components", "Pulsar.Components.RadioGroup"},
    {:select, "lib/pulsar/components/select.ex", "Pulsar.Components", "Pulsar.Components.Select"},
    {:sidebar, "lib/pulsar/components/sidebar.ex", "Pulsar.Components", "Pulsar.Components.Sidebar"},
    {:switch, "lib/pulsar/components/switch.ex", "Pulsar.Components", "Pulsar.Components.Switch"},
    {:table, "lib/pulsar/components/table.ex", "Pulsar.Components", "Pulsar.Components.Table"},
    {:textarea, "lib/pulsar/components/textarea.ex", "Pulsar.Components", "Pulsar.Components.Textarea"},
    {:tooltip, "lib/pulsar/components/tooltip.ex", "Pulsar.Components", "Pulsar.Components.Tooltip"},
    {:core_components, "lib/pulsar/core_components.ex", "Pulsar", "Pulsar.CoreComponents"}
  ]

  @doc """
  The canonical list of components managed by `mix pulsar.sync`.

  Add a new component's `t:pair/0` here (and its `priv/templates/<name>.ex.eex`)
  to bring it under generation.
  """
  @spec pairs() :: [pair()]
  def pairs, do: @pairs

  @doc """
  Renders the lib file content a given `pair` should have, from its template.

  Renders `priv/templates/<name>.ex.eex` with the fixed library assigns, wraps
  the body in `defmodule <module_name> do/end`, and runs it through the Elixir
  formatter so the result matches a `mix format`-clean committed file byte for
  byte.
  """
  @spec expected(pair()) :: String.t()
  def expected({component_name, lib_path, component_namespace, module_name}) do
    body =
      component_name
      |> template_path()
      |> EEx.eval_file(
        assigns: [
          component_namespace: component_namespace,
          components_namespace: @components_root,
          gettext_module: @gettext_module
        ],
        engine: EEx.SmartEngine
      )
      |> String.trim()

    "defmodule #{module_name} do\n#{indent(body, "  ")}\nend\n"
    |> format(lib_path)
  end

  @doc """
  Reads the committed lib file for a `pair` and formats it for comparison.

  Returns `{:error, :enoent}` if the file does not exist yet.
  """
  @spec current(pair()) :: {:ok, String.t()} | {:error, File.posix()}
  def current({_component_name, lib_path, _component_namespace, _module_name}) do
    case File.read(lib_path) do
      {:ok, content} -> {:ok, format(content, lib_path)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the pairs whose committed lib file has drifted from its template.

  A missing lib file counts as drift. Each entry is `{pair, expected_content}`
  so callers can report or rewrite the file.
  """
  @spec diff() :: [{pair(), String.t()}]
  def diff do
    # `expected/1` renders EEx and runs the formatter, so compute it once per
    # pair and reuse it for both drift detection and the returned content.
    # `expected/1` and `current/1` both return formatter-normalized content, so a
    # missing file (`{:error, _}`) never equals `{:ok, expected}` and counts as drift.
    @pairs
    |> Enum.map(fn pair -> {pair, expected(pair)} end)
    |> Enum.filter(fn {pair, expected} -> current(pair) != {:ok, expected} end)
  end

  defp template_path(component_name) do
    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates")
    |> Path.join("#{component_name}.ex.eex")
  end

  defp indent(body, prefix) do
    body
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "" -> ""
      line -> prefix <> line
    end)
  end

  # Format through the project's real formatter (`.formatter.exs` — `import_deps`,
  # `line_length`, and the Quokka/HTMLFormatter plugins) so generated lib files
  # match `mix format`-clean committed files exactly. The lib path picks the
  # formatter config that applies to that file.
  defp format(content, lib_path) do
    {formatter, _opts} = Format.formatter_for_file(lib_path)

    content
    |> formatter.()
    |> String.replace(~r/[ \t]+$/m, "")
    |> String.trim_trailing("\n")
  end
end
