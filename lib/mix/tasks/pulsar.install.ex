defmodule Mix.Tasks.Pulsar.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Installs Pulsar components into your Phoenix application"
  end

  @spec example() :: String.t()
  def example do
    "mix pulsar.install"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Generates all Pulsar component modules and theme CSS into your Phoenix application,
    providing production-ready, accessible UI components with beautiful Tailwind CSS styling.
    By default, installs the theme system, all components, and the core_components module.

    ## Example

    ```sh
    # Install everything (theme + all components)
    #{example()}

    # Install specific components only (no theme)
    mix pulsar.install --component=button,input,checkbox --no-theme

    # Install without core_components
    mix pulsar.install --no-core-components

    # Install components only, no theme
    mix pulsar.install --no-theme

    # Auto-confirm all prompts
    mix pulsar.install --yes

    # Custom components module namespace
    mix pulsar.install --components-module=MyAppWeb.UI
    ```

    ## Options

    * `--all` or `-a` - Install all available components (default: true)
    * `--component=NAMES` or `-c` - Comma-separated list of specific components to install
    * `--theme` or `-t` - Install Pulsar theme CSS with semantic color tokens (default: true)
    * `--core-components` or `--cc` - Include core_components module (default: true)
    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    * `--yes` or `-y` - Auto-confirm dependency installation prompts

    ## Theme System

    The Pulsar theme system provides:
    - Semantic color tokens (primary, secondary, success, warning, danger, info)
    - Complete light/dark mode support with data-theme attribute strategy
    - Design tokens for radius, spacing, typography, shadows, and z-index
    - Custom animations with accessibility (respects prefers-reduced-motion)
    - Automatic integration with Phoenix LiveView

    ## Available Components

    Form components: badge, button, checkbox, field, input, label, radio_group, select, switch, textarea

    UI components: card, divider, flash, flash_group, header, icon, link, list, table

    ## Component Dependencies

    Some components require others to function properly. When you select a component
    with dependencies, you'll be prompted to include them automatically.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Mix.Task.Info

    @components %{
      badge: [],
      button: [:link],
      card: [],
      checkbox: [],
      divider: [],
      field: [:checkbox, :icon, :input, :label, :radio_group, :select, :switch, :textarea],
      flash: [],
      flash_group: [:flash, :icon],
      header: [:link, :icon],
      icon: [],
      input: [],
      label: [],
      link: [:icon],
      list: [],
      radio_group: [],
      select: [:badge],
      switch: [],
      table: [],
      textarea: []
    }

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :pulsar,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [
          "pulsar.gen.theme",
          "pulsar.gen.badge",
          "pulsar.gen.button",
          "pulsar.gen.card",
          "pulsar.gen.checkbox",
          "pulsar.gen.divider",
          "pulsar.gen.field",
          "pulsar.gen.flash",
          "pulsar.gen.flash_group",
          "pulsar.gen.header",
          "pulsar.gen.icon",
          "pulsar.gen.input",
          "pulsar.gen.label",
          "pulsar.gen.link",
          "pulsar.gen.list",
          "pulsar.gen.radio_group",
          "pulsar.gen.select",
          "pulsar.gen.switch",
          "pulsar.gen.table",
          "pulsar.gen.textarea",
          "pulsar.gen.core_components"
        ],
        # `OptionParser` schema
        schema: [
          all: :boolean,
          component: :csv,
          core_components: :boolean,
          theme: :boolean,
          components_module: :string,
          yes: :boolean
        ],
        # Default values for the options in the `schema`
        defaults: [
          all: true,
          core_components: true,
          theme: true
        ],
        # CLI aliases
        aliases: [
          a: :all,
          c: :component,
          cc: :core_components,
          t: :theme,
          M: :components_module,
          y: :yes
        ],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      validate_component_dependencies!()
      options = igniter.args.options

      components = gather_components(igniter)

      igniter
      |> maybe_compose_task("pulsar.gen.theme", options[:theme])
      |> Pulsar.Generator.set_default_component_module()
      |> compose_components(components)
      |> maybe_compose_task("pulsar.gen.core_components", options[:core_components])
    end

    defp compose_components(igniter, components) do
      Enum.reduce(components, igniter, fn component, acc ->
        maybe_compose_task(acc, "pulsar.gen.#{component}", Enum.member?(components, component))
      end)
    end

    defp maybe_compose_task(igniter, task, enabled) do
      if enabled do
        igniter
        |> Igniter.compose_task(task)
      else
        igniter
      end
    end

    defp validate_component_dependencies!() do
      keys = @components |> Map.keys() |> MapSet.new()

      invalid =
        Enum.flat_map(@components, fn {comp, deps} ->
          Enum.reject(deps, &MapSet.member?(keys, &1))
          |> Enum.map(&{comp, &1})
        end)

      if invalid != [] do
        details =
          invalid
          |> Enum.map(fn {c, d} -> "#{Atom.to_string(c)} -> #{Atom.to_string(d)}" end)
          |> Enum.join(", ")

        raise "Invalid component dependencies found: #{details}"
      end

      :ok
    end

    # Helpers for component selection and dependency resolution
    defp parse_requested_components(options) do
      case options[:component] do
        nil -> []
        list when is_list(list) -> list
        other -> [other]
      end
    end

    defp normalize_and_validate!(requested) do
      if requested == [] do
        raise "No components specified. Pass --component=name1,name2 or use --all"
      end

      valid_keys = Map.keys(@components)

      Enum.map(requested, fn c ->
        case Enum.find(valid_keys, fn k -> Atom.to_string(k) == to_string(c) end) do
          nil ->
            valid = Enum.map(valid_keys, &Atom.to_string/1) |> Enum.sort() |> Enum.join(", ")
            raise "Unknown component: #{inspect(c)}. Valid components: #{valid}"

          k ->
            k
        end
      end)
    end

    defp resolve_all_dependencies(selected) do
      deps_of = fn comp -> Map.get(@components, comp, []) end

      resolver = fn resolver, queue, acc ->
        case queue do
          [] ->
            acc

          [h | t] ->
            {new_queue, new_acc} =
              Enum.reduce(deps_of.(h), {t, acc}, fn d, {q, a} ->
                if MapSet.member?(a, d) do
                  {q, a}
                else
                  {[d | q], MapSet.put(a, d)}
                end
              end)

            resolver.(resolver, new_queue, new_acc)
        end
      end

      resolver.(resolver, selected, MapSet.new(selected))
      |> MapSet.to_list()
    end

    defp missing_dependencies(all, selected) do
      MapSet.difference(MapSet.new(all), MapSet.new(selected))
      |> MapSet.to_list()
      |> Enum.sort()
    end

    defp prompt_to_include_missing(igniter, selected, missing) do
      if missing == [] do
        selected
      else
        # If --yes flag is set or no dependencies are missing, auto-include them
        if igniter.args.options[:yes] || missing == [] do
          selected ++ Enum.reject(missing, &(&1 in selected))
        else
          message =
            "The following Pulsar component dependencies are required: " <>
              (missing |> Enum.map_join(", ", &Atom.to_string/1)) <>
              ". Install them as well?"

          if Igniter.Util.IO.yes?(message) do
            selected ++ Enum.reject(missing, &(&1 in selected))
          else
            selected
          end
        end
      end
    end

    defp gather_components(igniter) do
      options = igniter.args.options
      all = options[:all] && Enum.empty?(options[:component])

      if all do
        @components |> Map.keys()
      else
        requested = parse_requested_components(options)
        selected = normalize_and_validate!(requested)
        all = resolve_all_dependencies(selected)
        missing = missing_dependencies(all, selected)
        prompt_to_include_missing(igniter, selected, missing)
      end
    end
  end
else
  defmodule Mix.Tasks.Pulsar.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'pulsar.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
