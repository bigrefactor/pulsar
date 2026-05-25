defmodule Pulsar.Generator do
  @moduledoc """
  Provides core component generation functionality for Pulsar.

  This module handles the installation and generation of Pulsar components
  into Phoenix applications using Igniter's code generation capabilities.
  It manages component module creation, namespace resolution, and template rendering.

  ## `use Pulsar.Generator`

  This module also exposes a `__using__/1` macro that collapses the per-component
  `Mix.Tasks.Pulsar.Gen.<X>` boilerplate into a single declaration:

      defmodule Mix.Tasks.Pulsar.Gen.Button do
        use Pulsar.Generator,
          component: :button,
          example: "mix pulsar.gen.button",
          long_doc: \"\"\"
          ... markdown ...
          \"\"\"
      end

  The macro emits `@moduledoc`, the `info/2` callback (with the standard
  `:pulsar` group and `[components_module: :string]` schema), and the `igniter/1`
  callback (calling `set_default_component_module/1` + `install_component/3`).
  Both callbacks are `defoverridable` so consumers can redefine either when a
  component needs custom behavior.

  When Igniter is not available the macro emits a `Mix.Task` stub whose `run/1`
  prints a "requires igniter" error and exits with status 1.

  ### Options

    * `:component` (atom, required) - The component atom passed to
      `install_component/3`. Also derives the task name (`pulsar.gen.\#{component}`)
      used in the no-Igniter error message.
    * `:example` (binary, required) - Sample shell invocation surfaced as
      `Igniter.Mix.Task.Info.example`.
    * `:long_doc` (binary, required) - Markdown body used as `@moduledoc`.
    * `:short_doc` (binary | `false`, default `false`) - When a binary is given,
      `@shortdoc` is emitted and the task shows up in `mix help`. The default
      (`false`) intentionally hides the per-component generators from
      `mix help` so only the top-level `mix pulsar.install` is surfaced.
  """

  alias Igniter.Libs.Phoenix
  alias Pulsar.Generator.Storybook

  @doc """
  Generates the `Mix.Tasks.Pulsar.Gen.<X>` boilerplate. See the module doc for options.
  """
  defmacro __using__(opts) do
    component = Keyword.fetch!(opts, :component)
    example = Keyword.fetch!(opts, :example)
    long_doc = Keyword.fetch!(opts, :long_doc)
    short_doc = Keyword.get(opts, :short_doc, false)

    if !(is_atom(component) and not is_nil(component)) do
      raise ArgumentError,
            "Pulsar.Generator expects :component to be an atom, got: #{inspect(component)}"
    end

    if !is_binary(example) do
      raise ArgumentError,
            "Pulsar.Generator expects :example to be a binary, got: #{inspect(example)}"
    end

    if !is_binary(long_doc) do
      raise ArgumentError,
            "Pulsar.Generator expects :long_doc to be a binary, got: #{inspect(long_doc)}"
    end

    if !(short_doc == false or is_binary(short_doc)) do
      raise ArgumentError,
            "Pulsar.Generator expects :short_doc to be a binary or false, got: #{inspect(short_doc)}"
    end

    task_name = "pulsar.gen.#{component}"

    no_igniter_message = """
    The task '#{task_name}' requires igniter. Please install igniter and try again.

    For more information, see: https://hexdocs.pm/igniter/readme.html#installation
    """

    shortdoc_attrs =
      if is_binary(short_doc) do
        [quote(do: @shortdoc(unquote(short_doc)))]
      else
        []
      end

    if Code.ensure_loaded?(Igniter) do
      quote do
        @moduledoc unquote(long_doc)
        use Igniter.Mix.Task

        alias Igniter.Mix.Task.Info

        unquote_splicing(shortdoc_attrs)

        @impl Igniter.Mix.Task
        def info(_argv, _composing_task) do
          %Info{
            group: :pulsar,
            adds_deps: [],
            installs: [],
            example: unquote(example),
            positional: [],
            composes: [],
            schema: [components_module: :string, storybook: :boolean, print_setup_notice: :boolean],
            defaults: [],
            aliases: [M: :components_module, s: :storybook],
            required: []
          }
        end

        @impl Igniter.Mix.Task
        def igniter(igniter) do
          igniter
          |> Pulsar.Generator.set_default_component_module()
          |> Pulsar.Generator.install_component(unquote(component), [])
        end

        defoverridable info: 2, igniter: 1
      end
    else
      quote do
        @moduledoc unquote(long_doc)
        use Mix.Task

        unquote_splicing(shortdoc_attrs)

        @impl Mix.Task
        def run(_argv) do
          Mix.shell().error(unquote(no_igniter_message))
          exit({:shutdown, 1})
        end

        defoverridable run: 1
      end
    end
  end

  def install_component(igniter, component_name, assigns) do
    namespace = parse_components_module(igniter.args.options[:components_module])
    component = component_module(namespace, component_name)
    # Convert namespace to inspect format to avoid Elixir. prefix in templates
    namespace_inspected = inspect(namespace)

    # For core_components, we need both the web module and the components namespace
    # Core components module goes under web module, but it needs to alias components
    assigns =
      assigns
      |> Keyword.put_new(:component_namespace, namespace_inspected)
      |> Keyword.put_new(:components_namespace, get_components_namespace(igniter, namespace_inspected))

    contents = contents(component_name, assigns)
    {exists, igniter} = Igniter.Project.Module.module_exists(igniter, component)

    igniter =
      if exists do
        {igniter, source, _} = Igniter.Project.Module.find_module!(igniter, component)

        # Wrap template contents in module definition for existing files
        wrapped_contents = """
        defmodule #{inspect(component)} do
          #{contents}
        end
        """

        igniter
        |> backup_existing_component(source.path)
        |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
        |> Igniter.update_file(source.path, fn source ->
          Rewrite.Source.update(source, :content, wrapped_contents)
        end)
      else
        igniter
        |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
        |> Igniter.Project.Module.create_module(component, contents)
      end

    maybe_install_story(igniter, component_name)
  end

  defp maybe_install_story(igniter, component_name) do
    if igniter.args.options[:storybook] do
      igniter
      |> Storybook.install_component_story(component_name)
      |> maybe_print_setup_notice()
    else
      igniter
    end
  end

  # Print the setup notice unless `--no-print-setup-notice` was passed.
  # `pulsar.install --storybook` suppresses it on every composed component
  # generator so the notice prints exactly once (from the final
  # `pulsar.gen.storybook --skip-components` composition).
  defp maybe_print_setup_notice(igniter) do
    case igniter.args.options[:print_setup_notice] do
      false -> igniter
      _ -> Storybook.print_setup_notice(igniter)
    end
  end

  defp backup_existing_component(igniter, path) do
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

  def set_default_component_module(igniter) do
    igniter = Igniter.compose_task(igniter, "igniter.add_extension", ["phoenix"])
    default = Phoenix.web_module_name(igniter, "Components")

    update_in(igniter.args.options, fn opts ->
      opts = opts || []
      Keyword.put_new(opts, :components_module, default)
    end)
  end

  defp component_module(namespace, component_name) do
    Module.concat(namespace, Macro.camelize(to_string(component_name)))
  end

  defp get_components_namespace(igniter, _namespace_inspected) do
    # Get the default components namespace (e.g., MyAppWeb.Components)
    default = Phoenix.web_module_name(igniter, "Components")
    inspect(default)
  end

  defp contents(component_name, assigns) do
    template = template_path(component_name)

    if !File.exists?(template) do
      raise ArgumentError,
            "Pulsar template missing for component :#{component_name} " <>
              "(expected at #{template})"
    end

    EEx.eval_file(template, assigns: assigns, engine: EEx.SmartEngine)
  end

  defp template_path(component_name) do
    :pulsar
    |> :code.priv_dir()
    |> Path.join("templates")
    |> Path.join("#{component_name}.ex.eex")
  end

  defp parse_components_module(raw) do
    value = raw |> to_string() |> String.trim() |> String.trim_trailing(".")

    cond do
      value == "" ->
        raise ArgumentError,
              "Pulsar requires --components-module to be a non-empty module name"

      !Regex.match?(~r/^[A-Z][A-Za-z0-9_]*(\.[A-Z][A-Za-z0-9_]*)*$/, value) ->
        raise ArgumentError,
              "Pulsar received an invalid module name for --components-module: " <>
                "#{inspect(raw)}"

      true ->
        Igniter.Project.Module.parse(value)
    end
  end
end
