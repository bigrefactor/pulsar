defmodule Mix.Tasks.Pulsar.Gen.Theme.Docs do
  @moduledoc false

  @doc false
  @spec short_doc() :: String.t()
  def short_doc do
    "Generates Pulsar theme CSS files with semantic color tokens and design system"
  end

  @doc false
  @spec example() :: String.t()
  def example do
    "mix pulsar.gen.theme"
  end

  @doc false
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
    * `assets/css/app.css` — created with the theme import when absent; an
      existing app.css is left untouched apart from ensuring
      `@import "./theme.css";`

    The semantic tokens swap at runtime via `[data-theme="<name>"]` attribute
    overrides — components reference tokens like `bg-primary` directly, no
    `dark:` variant required.

    ## Scaffold a new theme

    Pass a theme name to scaffold a new `[data-theme="<name>"]` override file
    and idempotently register it with the entry:

    ```sh
    mix pulsar.gen.theme cupcake
    mix pulsar.gen.theme midnight --dark
    ```

    This generates `assets/css/themes/cupcake.css` (refusing to overwrite an
    existing one) and appends `@import "./themes/cupcake.css";` to
    `assets/css/theme.css` — but only if the line isn't already there, so the
    task is safe to re-run.

    Pass `--dark` when the theme is a dark one. The scaffold then declares
    `color-scheme: dark`, which is what tells the browser to draw scrollbars,
    `<select>` popup lists and date pickers in dark polarity — without it they
    render light against your dark surfaces. Themes scaffolded without the flag
    declare `color-scheme: light`; edit the line directly to change it later.

    The flag applies only when scaffolding a named theme. It has no effect on
    the bare `mix pulsar.gen.theme` install path, which generates the built-in
    light and dark pair.

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

    @app_css_path "assets/css/app.css"
    @theme_import ~s(@import "./theme.css";)

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        group: :pulsar,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        positional: [{:name, optional: true}],
        composes: [],
        schema: [dark: :boolean],
        defaults: [dark: false],
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
      web_dir = igniter |> Phoenix.web_module() |> Macro.underscore()

      igniter
      |> install_theme_files(web_dir)
      |> install_app_css(web_dir)
    end

    defp install_theme_files(igniter, web_dir) do
      @theme_files
      |> Enum.reduce(igniter, fn {template_rel, dest}, acc ->
        Igniter.copy_template(
          acc,
          template_path(template_rel),
          dest,
          [web_directory: web_dir],
          on_exists: :overwrite
        )
      end)
      |> reregister_custom_themes()
    end

    # install_theme_files/2 just overwrote theme.css from the template, which
    # carries only the built-in light/dark imports. A theme scaffolded earlier
    # via `mix pulsar.gen.theme <name>` still has its themes/<name>.css file on
    # disk, so re-add its @import or it silently stops loading.
    defp reregister_custom_themes(igniter) do
      igniter = Igniter.include_glob(igniter, "assets/css/themes/*.css")

      igniter.rewrite.sources
      |> Map.keys()
      |> Enum.filter(&custom_theme_file?/1)
      |> Enum.reduce(igniter, fn dest, acc ->
        name = Path.basename(dest, ".css")
        add_theme_import(acc, "assets/css/theme.css", ~s(@import "./themes/#{name}.css";), dest)
      end)
    end

    defp custom_theme_file?(path) do
      String.starts_with?(path, "assets/css/themes/") and
        path not in ["assets/css/themes/light.css", "assets/css/themes/dark.css"]
    end

    # app.css belongs to the host application; Pulsar needs exactly one line in it.
    # Write the template only when there is no app.css to preserve.
    defp install_app_css(igniter, web_dir) do
      igniter = Igniter.include_existing_file(igniter, @app_css_path)

      case Map.fetch(igniter.rewrite.sources, @app_css_path) do
        {:ok, source} ->
          ensure_import(igniter, @app_css_path, source, @theme_import)

        :error ->
          Igniter.copy_template(
            igniter,
            template_path("app.css.eex"),
            @app_css_path,
            web_directory: web_dir
          )
      end
    end

    defp scaffold_theme(igniter, name) do
      validate_theme_name!(name)

      dest = "assets/css/themes/#{name}.css"
      import_line = ~s(@import "./themes/#{name}.css";)
      color_scheme = if igniter.args.options[:dark], do: "dark", else: "light"

      igniter
      |> scaffold_theme_file(dest, name, color_scheme)
      |> add_theme_import("assets/css/theme.css", import_line, dest)
    end

    # Refuse to overwrite an existing theme file. We check the path directly
    # rather than relying on `copy_template`'s `on_exists: :skip`, because
    # Igniter only consults loaded sources for that check and won't see a file
    # that exists on disk but hasn't been read into the rewrite yet.
    defp scaffold_theme_file(igniter, dest, name, color_scheme) do
      if Igniter.exists?(igniter, dest) do
        igniter
      else
        Igniter.copy_template(igniter, template_path("themes/scaffold.css.eex"), dest,
          theme_name: name,
          color_scheme: color_scheme
        )
      end
    end

    defp add_theme_import(igniter, theme_css_path, import_line, dest) do
      igniter = Igniter.include_existing_file(igniter, theme_css_path)

      case Map.fetch(igniter.rewrite.sources, theme_css_path) do
        {:ok, source} ->
          ensure_import(igniter, theme_css_path, source, import_line)

        :error ->
          Igniter.add_warning(
            igniter,
            "assets/css/theme.css not found — generated #{dest} but did not register it. Run `mix pulsar.gen.theme` first, then add the import manually."
          )
      end
    end

    defp ensure_import(igniter, theme_css_path, source, import_line) do
      content = Rewrite.Source.get(source, :content)

      if import_line?(content, import_line) do
        igniter
      else
        new_content = insert_import(content, import_line)

        Igniter.update_file(igniter, theme_css_path, fn source ->
          Rewrite.Source.update(source, :content, new_content)
        end)
      end
    end

    # A commented-out import (single-line or spanning a multi-line /* */
    # block) must not count as present; an import carrying a trailing inline
    # comment must.
    defp import_line?(content, import_line) do
      content
      |> strip_block_comments()
      |> String.split("\n")
      |> Enum.any?(&String.starts_with?(String.trim(&1), import_line))
    end

    # Blanks out /* ... */ blocks (including multi-line ones, and an unterminated
    # one running to end of file) while preserving every newline, so the result
    # still splits into the same line count and indices as `content` — callers
    # that need to line up a stripped line with its position in the original can
    # rely on that.
    #
    # `/*` inside a quoted string does not open a comment. Phoenix's own app.css
    # ships `@source "../../_build/dev/phoenix-colocated/app/*/";`, whose glob
    # contains `/*`.
    defp strip_block_comments(content), do: strip_css(content, [])

    defp strip_css(<<>>, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()
    defp strip_css(<<"/*", rest::binary>>, acc), do: strip_css_comment(rest, acc)

    defp strip_css(<<quote, rest::binary>>, acc) when quote in [?", ?'],
      do: strip_css_string(rest, quote, [quote | acc])

    defp strip_css(<<char, rest::binary>>, acc), do: strip_css(rest, [char | acc])

    defp strip_css_comment(<<>>, acc), do: strip_css(<<>>, acc)
    defp strip_css_comment(<<"*/", rest::binary>>, acc), do: strip_css(rest, acc)
    defp strip_css_comment(<<?\n, rest::binary>>, acc), do: strip_css_comment(rest, [?\n | acc])
    defp strip_css_comment(<<_char, rest::binary>>, acc), do: strip_css_comment(rest, acc)

    defp strip_css_string(<<>>, _quote, acc), do: strip_css(<<>>, acc)

    defp strip_css_string(<<?\\, char, rest::binary>>, quote, acc), do: strip_css_string(rest, quote, [char, ?\\ | acc])

    defp strip_css_string(<<quote, rest::binary>>, quote, acc), do: strip_css(rest, [quote | acc])

    defp strip_css_string(<<char, rest::binary>>, quote, acc), do: strip_css_string(rest, quote, [char | acc])

    # Insert the new import after the last live (non-commented) `@import`/
    # `@source` line, falling back to the top of the file.
    defp insert_import(content, import_line) do
      lines = String.split(content, "\n")
      live_lines = content |> strip_block_comments() |> String.split("\n")

      insertion_index =
        case find_last_index(live_lines, &String.match?(&1, ~r/^@(import|source)\b/)) do
          nil -> 0
          i -> i + 1
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
