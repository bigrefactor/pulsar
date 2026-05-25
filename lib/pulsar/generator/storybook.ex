defmodule Pulsar.Generator.Storybook do
  @moduledoc """
  Helper functions for generating PhoenixStorybook story files.

  This module handles story file emission for Pulsar components, including:
  - Per-component story generation (`install_component_story/3`)
  - Bulk generation of foundations, examples, and welcome pages
  - Setup notice printing

  Stories are written as plain `.story.exs` files (not wrapped in a module
  declaration the way component `.ex` files are) because phoenix_storybook
  loads them as scripts via `Code.eval_file/1`.
  """

  alias Igniter.Libs.Phoenix

  @components [
    :badge,
    :button,
    :card,
    :checkbox,
    :divider,
    :field,
    :flash,
    :flash_group,
    :header,
    :icon,
    :input,
    :label,
    :link,
    :list,
    :radio_group,
    :select,
    :switch,
    :table,
    :textarea
  ]

  @foundations [:colors, :dark_mode, :spacing, :typography]
  @examples [:dashboard, :login, :settings_panel]

  @doc """
  Returns the list of all supported component atoms.
  """
  def components, do: @components

  @doc """
  Installs a component story file for the given component.

  Called when `--storybook` is passed to a `pulsar.gen.<component>` task.
  Components not in `@components` (e.g. `:core_components`, which has no
  storybook template) are silently skipped — there is no story to emit.
  """
  def install_component_story(igniter, component_name) do
    if component_name in @components do
      assigns = build_assigns(igniter)
      story_path = component_story_path(igniter, component_name)
      contents = render_template([:components, component_name], assigns)
      create_story_file(igniter, story_path, contents)
    else
      igniter
    end
  end

  @doc """
  Installs all foundation story files (colors, dark_mode, spacing, typography).
  """
  def install_foundations(igniter) do
    assigns = build_assigns(igniter)

    Enum.reduce(@foundations, igniter, fn foundation_name, acc ->
      story_path = foundation_story_path(acc, foundation_name)
      contents = render_template([:foundations, foundation_name], assigns)
      create_story_file(acc, story_path, contents)
    end)
  end

  @doc """
  Installs all example story files (dashboard, login, settings_panel).
  """
  def install_examples(igniter) do
    assigns = build_assigns(igniter)

    Enum.reduce(@examples, igniter, fn example_name, acc ->
      story_path = example_story_path(acc, example_name)
      contents = render_template([:examples, example_name], assigns)
      create_story_file(acc, story_path, contents)
    end)
  end

  @doc """
  Installs the welcome story file.
  """
  def install_welcome(igniter) do
    assigns = build_assigns(igniter)
    story_path = welcome_story_path(igniter)
    contents = render_template([:welcome], assigns)
    create_story_file(igniter, story_path, contents)
  end

  @doc """
  Installs stories for all components that are already installed in the project.

  Used by `pulsar.gen.storybook` for catch-up mode.
  """
  def install_detected_component_stories(igniter) do
    assigns = build_assigns(igniter)
    components_module = get_components_module(igniter)

    Enum.reduce(@components, igniter, fn component_name, acc ->
      component_module = Module.concat(components_module, Macro.camelize(to_string(component_name)))
      {exists, acc} = Igniter.Project.Module.module_exists(acc, component_module)

      if exists do
        story_path = component_story_path(acc, component_name)
        contents = render_template([:components, component_name], assigns)
        create_story_file(acc, story_path, contents)
      else
        acc
      end
    end)
  end

  @doc """
  Prints the storybook setup instructions to Mix.shell().
  """
  def print_setup_notice(igniter) do
    web_module = web_module_string(igniter)
    app_name = app_name(igniter)

    notice = """

    Storybook stories generated. To complete setup:

    1. Add phoenix_storybook to mix.exs:

           {:phoenix_storybook, "~> 1.1"}

       Then run: mix deps.get

    2. Create a storybook backend module at lib/#{app_name}_web/storybook.ex:

           defmodule #{web_module}.Storybook do
             use PhoenixStorybook,
               otp_app: :#{app_name},
               content_path: Path.expand("storybook", __DIR__),
               title: "#{Macro.camelize(app_name)} Storybook",
               css_path: "/assets/app.css",
               sandbox_class: "pulsar-sandbox"
           end

    3. Mount in your router (lib/#{app_name}_web/router.ex):

           import PhoenixStorybook.Router

           scope "/" do
             storybook_assets()
           end

           scope "/", #{web_module} do
             pipe_through :browser
             live_storybook "/storybook", backend_module: #{web_module}.Storybook
           end

    4. Scope your styles to match the sandbox class.

       Add the following to your app.css (or equivalent) so story content
       uses your app's font baseline. Without this, PSB stories render
       with the browser default font (Times serif on most systems):

           .pulsar-sandbox {
             font-family: var(--font-sans);
             color: var(--color-foreground);
           }

           .pulsar-sandbox * {
             font-family: inherit;
           }

       Then apply the class to your root layout body so the same baseline
       applies outside the storybook too:

           <body class="pulsar-sandbox ...">

       Background: https://hexdocs.pm/phoenix_storybook/sandboxing.html

    5. Visit http://localhost:4000/storybook

    Full setup guide: https://hexdocs.pm/phoenix_storybook/setup.html
    """

    Mix.shell().info(notice)
    igniter
  end

  # Private helpers

  defp build_assigns(igniter) do
    web_module = web_module_string(igniter)
    components_module = components_module_string(igniter)

    [
      web_module: web_module,
      components_module: components_module
    ]
  end

  defp web_module_string(igniter) do
    Phoenix.web_module(igniter)
    |> inspect()
  end

  defp components_module_string(igniter) do
    get_components_module(igniter)
    |> inspect()
  end

  defp get_components_module(igniter) do
    case igniter.args.options[:components_module] do
      nil ->
        Phoenix.web_module_name(igniter, "Components")

      raw when is_atom(raw) ->
        # Already a module atom (set by set_default_component_module)
        raw

      raw ->
        Igniter.Project.Module.parse(to_string(raw))
    end
  end

  defp app_name(igniter) do
    igniter
    |> Igniter.Project.Application.app_name()
    |> to_string()
  rescue
    _ -> "my_app"
  end

  defp render_template(path_parts, assigns) do
    template = template_path(path_parts)

    if !File.exists?(template) do
      raise ArgumentError,
            "Pulsar storybook template missing at #{template}"
    end

    EEx.eval_file(template, assigns: assigns, engine: EEx.SmartEngine)
  end

  defp template_path(path_parts) do
    parts = Enum.map(path_parts, &to_string/1)

    # The last part is the file name (e.g. "button" or "welcome"),
    # which gets the .story.exs.eex extension.
    {dir_parts, [file_name]} = Enum.split(parts, length(parts) - 1)

    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates")
    |> Path.join("storybook")
    |> then(fn base ->
      Enum.reduce(dir_parts, base, &Path.join(&2, &1))
    end)
    |> Path.join("#{file_name}.story.exs.eex")
  end

  defp component_story_path(igniter, component_name) do
    web_dir = web_dir(igniter)
    Path.join([web_dir, "storybook", "components", "#{component_name}.story.exs"])
  end

  defp foundation_story_path(igniter, foundation_name) do
    web_dir = web_dir(igniter)
    Path.join([web_dir, "storybook", "foundations", "#{foundation_name}.story.exs"])
  end

  defp example_story_path(igniter, example_name) do
    web_dir = web_dir(igniter)
    Path.join([web_dir, "storybook", "examples", "#{example_name}.story.exs"])
  end

  defp welcome_story_path(igniter) do
    web_dir = web_dir(igniter)
    Path.join([web_dir, "storybook", "welcome.story.exs"])
  end

  defp web_dir(igniter) do
    # Derive the web directory from the web module name.
    # e.g. MyAppWeb -> lib/my_app_web
    web_module = Phoenix.web_module(igniter)
    module_to_path(web_module)
  end

  defp module_to_path(module) do
    module
    |> inspect()
    |> Macro.underscore()
    |> then(&Path.join("lib", &1))
  end

  defp create_story_file(igniter, path, contents) do
    # Story files are plain .exs files — we write them as new files.
    # We use create_new_file to avoid overwriting without notice.
    if Map.has_key?(igniter.rewrite.sources, path) do
      igniter
    else
      Igniter.create_new_file(igniter, path, contents)
    end
  end
end
