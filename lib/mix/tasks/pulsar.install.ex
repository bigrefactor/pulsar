defmodule Mix.Tasks.Pulsar.Install.Docs do
  @moduledoc false

  @doc false
  @spec short_doc() :: String.t()
  def short_doc do
    "Installs Pulsar components into your Phoenix application"
  end

  @doc false
  @spec example() :: String.t()
  def example do
    "mix pulsar.install"
  end

  @doc false
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

    # Install with PhoenixStorybook stories
    mix pulsar.install --storybook

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
    * `--storybook` or `-s` - Generate PhoenixStorybook story files for all installed components
    * `--yes` or `-y` - Auto-confirm dependency installation prompts

    ## Theme System

    The Pulsar theme system provides:
    - Semantic color tokens (primary, secondary, success, warning, danger, info)
    - Complete light/dark mode support with data-theme attribute strategy
    - Design tokens for radius, spacing, typography, shadows, and z-index
    - Custom animations with accessibility (respects prefers-reduced-motion)
    - Automatic integration with Phoenix LiveView

    ## Available Components

    Form components: badge, button, calendar, checkbox, date_picker, field, input, input_otp, label, radio_group, select, switch, textarea

    UI components: accordion, alert, alert_dialog, avatar, breadcrumb, card, collapsible, divider, drawer, dropdown_menu, flash, flash_group, header, icon, link, list, menu, modal, navbar, popover, progress, sidebar, skeleton, spinner, status, steps, table, tabs, tooltip

    ## Component Dependencies

    Some components require others to function properly. When you select a component
    with dependencies, you'll be prompted to include them automatically.

    ## Storybook Setup

    When using `--storybook`, story files are generated for all installed components plus
    foundation pages and examples. phoenix_storybook is NOT added to your deps automatically.
    The generator prints setup instructions after completing so you can wire it up manually.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Pulsar.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Mix.Task.Info
    alias Igniter.Project.Deps

    @components %{
      accordion: [:icon],
      alert: [:icon],
      alert_dialog: [:modal, :button],
      avatar: [:icon, :link],
      badge: [],
      breadcrumb: [:icon, :link],
      button: [:link],
      calendar: [],
      card: [],
      checkbox: [],
      collapsible: [:icon],
      date_picker: [:calendar, :popover, :icon],
      divider: [],
      drawer: [:modal, :button],
      dropdown_menu: [:icon, :popover],
      field: [:checkbox, :date_picker, :icon, :input, :input_otp, :label, :radio_group, :select, :switch, :textarea],
      flash: [],
      flash_group: [:flash, :icon],
      form: [],
      header: [:link, :icon, :breadcrumb],
      icon: [],
      input: [],
      input_otp: [],
      label: [],
      link: [:icon],
      list: [],
      menu: [:icon, :popover],
      modal: [:icon],
      navbar: [:icon],
      pagination: [:icon],
      popover: [],
      progress: [],
      radio_group: [],
      resizable: [:icon],
      select: [:badge],
      sidebar: [],
      skeleton: [],
      spinner: [],
      status: [],
      steps: [:icon],
      switch: [],
      table: [],
      tabs: [:icon],
      textarea: [],
      tooltip: [:popover]
    }

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :pulsar,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [{:twm, "~> 0.1"}, {:gettext, "~> 0.26"}],
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
          "pulsar.gen.accordion",
          "pulsar.gen.alert",
          "pulsar.gen.alert_dialog",
          "pulsar.gen.avatar",
          "pulsar.gen.badge",
          "pulsar.gen.button",
          "pulsar.gen.breadcrumb",
          "pulsar.gen.calendar",
          "pulsar.gen.card",
          "pulsar.gen.checkbox",
          "pulsar.gen.collapsible",
          "pulsar.gen.date_picker",
          "pulsar.gen.divider",
          "pulsar.gen.drawer",
          "pulsar.gen.dropdown_menu",
          "pulsar.gen.field",
          "pulsar.gen.flash",
          "pulsar.gen.flash_group",
          "pulsar.gen.form",
          "pulsar.gen.header",
          "pulsar.gen.icon",
          "pulsar.gen.input",
          "pulsar.gen.input_otp",
          "pulsar.gen.label",
          "pulsar.gen.link",
          "pulsar.gen.list",
          "pulsar.gen.menu",
          "pulsar.gen.modal",
          "pulsar.gen.navbar",
          "pulsar.gen.pagination",
          "pulsar.gen.popover",
          "pulsar.gen.progress",
          "pulsar.gen.radio_group",
          "pulsar.gen.resizable",
          "pulsar.gen.select",
          "pulsar.gen.sidebar",
          "pulsar.gen.skeleton",
          "pulsar.gen.spinner",
          "pulsar.gen.status",
          "pulsar.gen.steps",
          "pulsar.gen.switch",
          "pulsar.gen.table",
          "pulsar.gen.tabs",
          "pulsar.gen.textarea",
          "pulsar.gen.tooltip",
          "pulsar.gen.core_components",
          "pulsar.gen.storybook"
        ],
        # `OptionParser` schema
        schema: [
          all: :boolean,
          component: :csv,
          core_components: :boolean,
          theme: :boolean,
          components_module: :string,
          storybook: :boolean,
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
          s: :storybook,
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
      |> Deps.add_dep({:twm, "~> 0.1"}, on_exists: :skip)
      |> Deps.add_dep({:gettext, "~> 0.26"}, on_exists: :skip)
      |> Igniter.Project.Application.add_new_child({Twm.Cache, []})
      |> Pulsar.Generator.set_default_component_module()
      |> maybe_compose_task("pulsar.gen.theme", options[:theme])
      |> compose_components(components)
      |> maybe_compose_task("pulsar.gen.core_components", options[:core_components])
      |> maybe_install_storybook_extras(options[:storybook])
    end

    defp compose_components(igniter, components) do
      # When --storybook is set, suppress the per-component setup notice; the
      # final `pulsar.gen.storybook --skip-components` composition prints it
      # exactly once. Pass argv_flags + suppression so the child receives the
      # parent's --storybook / --components-module / etc. unchanged.
      child_argv =
        if igniter.args.options[:storybook] do
          (igniter.args.argv_flags || []) ++ ["--no-print-setup-notice"]
        end

      Enum.reduce(components, igniter, fn component, acc ->
        Igniter.compose_task(acc, "pulsar.gen.#{component}", child_argv)
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

    # Merge the user's argv_flags (which carry --components-module, --yes,
    # etc.) with --skip-components so the storybook task sees both.
    defp maybe_install_storybook_extras(igniter, true) do
      argv = (igniter.args.argv_flags || []) ++ ["--skip-components"]
      Igniter.compose_task(igniter, "pulsar.gen.storybook", argv)
    end

    defp maybe_install_storybook_extras(igniter, _), do: igniter

    defp validate_component_dependencies! do
      keys = @components |> Map.keys() |> MapSet.new()

      invalid =
        Enum.flat_map(@components, fn {comp, deps} ->
          Enum.reject(deps, &MapSet.member?(keys, &1))
          |> Enum.map(&{comp, &1})
        end)

      if invalid != [] do
        details =
          invalid
          |> Enum.map_join(", ", fn {c, d} -> "#{Atom.to_string(c)} -> #{Atom.to_string(d)}" end)

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
      Enum.map(requested, &validate_component!(&1, valid_keys))
    end

    defp validate_component!(c, valid_keys) do
      case Enum.find(valid_keys, fn k -> Atom.to_string(k) == to_string(c) end) do
        nil ->
          valid = valid_keys |> Enum.map(&Atom.to_string/1) |> Enum.sort() |> Enum.join(", ")
          raise "Unknown component: #{inspect(c)}. Valid components: #{valid}"

        k ->
          k
      end
    end

    defp resolve_all_dependencies(selected) do
      deps_of = fn comp -> Map.get(@components, comp, []) end

      resolver = fn resolver, queue, acc ->
        case queue do
          [] ->
            acc

          [h | t] ->
            {new_queue, new_acc} = process_component_dependencies(deps_of.(h), t, acc)
            resolver.(resolver, new_queue, new_acc)
        end
      end

      resolver.(resolver, selected, MapSet.new(selected))
      |> MapSet.to_list()
    end

    defp process_component_dependencies(dependencies, queue, acc) do
      Enum.reduce(dependencies, {queue, acc}, fn dependency, {q, a} ->
        if MapSet.member?(a, dependency) do
          {q, a}
        else
          {[dependency | q], MapSet.put(a, dependency)}
        end
      end)
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
