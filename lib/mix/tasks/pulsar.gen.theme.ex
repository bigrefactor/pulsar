defmodule Mix.Tasks.Pulsar.Gen.Theme.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Generates Pulsar theme CSS files with semantic color tokens and design system"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.theme"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    This task sets up (or extends) Pulsar's theme system.

    ## Default — generate the full theme system

    Run without arguments to scaffold the entry CSS and a light/dark pair:

    * `assets/css/theme.css` — entry that imports Tailwind, declares palette
      tokens, and `@import`s the per-theme files under `themes/`
    * `assets/css/themes/light.css` — the default theme; `@theme` block with
      the semantic tokens that Tailwind uses to generate utilities
    * `assets/css/themes/dark.css` — `[data-theme="dark"]` override block
    * `assets/css/app.css` — Phoenix LiveView configuration importing the theme
    * `*.bak.<timestamp>` backups of any files that already existed

    The semantic tokens swap at runtime via `[data-theme="<name>"]` attribute
    overrides — components reference tokens like `bg-primary` directly, no
    `dark:` variant required.

    ## Scaffold a new theme

    Pass a theme name to scaffold a new `[data-theme="<name>"]` override file
    and idempotently register it with the entry:

    ```sh
    mix pulsar.gen.theme cupcake
    ```

    This generates `assets/css/themes/cupcake.css` (refusing to overwrite an
    existing one) and appends `@import "./themes/cupcake.css";` to
    `assets/css/theme.css` — but only if the line isn't already there, so the
    task is safe to re-run.

    Activate the new theme by setting `data-theme="cupcake"` on any ancestor
    element. Edit the generated file to override semantic tokens (start by
    copying lines from `themes/dark.css`).

    ## Example

    ```sh
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Gen.Theme do
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Libs.Phoenix
    alias Igniter.Mix.Task.Info

    @theme_files [
      {"theme.css.eex", "assets/css/theme.css"},
      {"themes/light.css.eex", "assets/css/themes/light.css"},
      {"themes/dark.css.eex", "assets/css/themes/dark.css"}
    ]

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        group: :pulsar,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [{:name, optional: true}],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      case Map.get(igniter.args.positional, :name) do
        nil -> install_theme_system(igniter)
        name when is_binary(name) -> scaffold_theme(igniter, name)
      end
    end

    defp install_theme_system(igniter) do
      web_dir = Phoenix.web_module(igniter) |> Macro.underscore()

      igniter
      |> install_theme_files(web_dir)
      |> backup_existing_file("assets/css/app.css")
      |> Igniter.copy_template(
        template_path("app.css.eex"),
        "assets/css/app.css",
        [web_directory: web_dir],
        on_exists: :overwrite
      )
    end

    defp install_theme_files(igniter, web_dir) do
      Enum.reduce(@theme_files, igniter, fn {template_rel, dest}, acc ->
        acc
        |> backup_existing_file(dest)
        |> Igniter.copy_template(
          template_path(template_rel),
          dest,
          [web_directory: web_dir],
          on_exists: :overwrite
        )
      end)
    end

    defp scaffold_theme(igniter, name) do
      validate_theme_name!(name)

      dest = "assets/css/themes/#{name}.css"
      import_line = ~s(@import "./themes/#{name}.css";)

      igniter
      |> Igniter.copy_template(template_path("themes/scaffold.css.eex"), dest, [theme_name: name], on_exists: :skip)
      |> add_theme_import("assets/css/theme.css", import_line)
    end

    defp add_theme_import(igniter, theme_css_path, import_line) do
      igniter = Igniter.include_existing_file(igniter, theme_css_path)

      case Map.fetch(igniter.rewrite.sources, theme_css_path) do
        {:ok, source} ->
          content = Rewrite.Source.get(source, :content)

          if String.contains?(content, import_line) do
            igniter
          else
            new_content = insert_import(content, import_line)

            Igniter.update_file(igniter, theme_css_path, fn source ->
              Rewrite.Source.update(source, :content, new_content)
            end)
          end

        :error ->
          Igniter.add_warning(
            igniter,
            "assets/css/theme.css not found — generated #{import_line |> String.replace(~r/.*"(.+)";.*/, "\\1")} but did not register it. Run `mix pulsar.gen.theme` first, then add the import manually."
          )
      end
    end

    # Insert the new import line after the last existing `@import "./themes/..."`
    # line, falling back to after `@import "tailwindcss";` if no themes are
    # imported yet, and finally to the top of the file.
    defp insert_import(content, import_line) do
      lines = String.split(content, "\n")

      insertion_index =
        case find_last_index(lines, &String.match?(&1, ~r{^@import "\./themes/.*";})) do
          nil ->
            case find_last_index(lines, &String.match?(&1, ~r{^@import "tailwindcss";})) do
              nil -> 0
              i -> i + 1
            end

          i ->
            i + 1
        end

      lines
      |> List.insert_at(insertion_index, import_line)
      |> Enum.join("\n")
    end

    defp find_last_index(list, predicate) do
      list
      |> Enum.with_index()
      |> Enum.filter(fn {item, _i} -> predicate.(item) end)
      |> List.last()
      |> case do
        nil -> nil
        {_item, i} -> i
      end
    end

    defp validate_theme_name!(name) do
      if String.match?(name, ~r/^[a-z][a-z0-9_-]*$/) do
        :ok
      else
        Mix.raise(
          "Invalid theme name: #{inspect(name)}. Use lowercase letters, digits, hyphens, and underscores; must start with a letter."
        )
      end
    end

    defp template_path(relative) do
      :pulsar
      |> :code.priv_dir()
      |> Path.join("templates")
      |> Path.join(relative)
    end

    defp backup_existing_file(igniter, path) do
      igniter = Igniter.include_existing_file(igniter, path)

      case Map.fetch(igniter.rewrite.sources, path) do
        {:ok, source} ->
          ts = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601(:basic)
          backup_path = "#{path}.bak.#{ts}"
          content = Rewrite.Source.get(source, :content)

          Igniter.create_new_file(igniter, backup_path, content)

        :error ->
          igniter
      end
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Gen.Theme do
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.gen.theme' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
