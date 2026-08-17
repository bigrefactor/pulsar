defmodule Pulsar.Components.Combobox do
  @moduledoc """
  A text input that filters a list of options as you type.

  The input holds the query; a popover anchored to it lists the matches. Pick one
  and it becomes the field's value. Set `multiple` to collect several, each shown
  as a removable badge.

  Filtering runs a function you supply. The built-in matcher searches the given
  `options` in memory; pass `filter` for your own matching, and add `async` when
  the source does I/O so the work runs off the LiveView process.

  Plugs into Pulsar.Components.Field as `type="combobox"`.

  ## Examples

      <.combobox field={@form[:owner_id]} options={@owners} />

      <.combobox field={@form[:skill_ids]} options={@skills} multiple />

      <.combobox field={@form[:place]} filter={&Places.search/2} async
                 display={[{@place.description, @place.id}]} />
  """

  use Phoenix.LiveComponent

  import Twm, only: [merge: 1]

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias Pulsar.Components.Badge
  alias Pulsar.Components.Icon
  alias Pulsar.Components.Popover
  alias Pulsar.Components.Spinner

  defmodule Option do
    @moduledoc """
    One option in a `combobox` list.

    `label` is the text shown and matched against; `value` is what the field
    receives when the option is picked. `group` places the option under a heading.
    """

    @enforce_keys [:label, :value]
    defstruct [:description, :group, :icon, :label, :value, disabled: false]

    @type t :: %__MODULE__{
            label: String.t(),
            value: term(),
            group: String.t() | nil,
            icon: String.t() | nil,
            description: String.t() | nil,
            disabled: boolean()
          }
  end

  @doc """
  Normalizes any accepted option shape into a flat list of `Option` structs.

  Accepts scalars, `{label, value}` tuples, keyword options with `:key` and
  `:value`, and `{group_label, options}` pairs whose second element is a list or
  map. Grouped input flattens, with each option carrying its group label.

  ## Examples

      options(["Admin", {"User", "user"}])
      options([{"Europe", ["UK", "Sweden"]}])
      options([[key: "Admin", value: "admin", icon: "hero-user"]])
  """
  @spec options(term()) :: [Option.t()]
  def options(input) when is_list(input) or is_map(input) do
    Enum.flat_map(input, &normalize_entry(&1, nil))
  end

  defp normalize_entry(%Option{} = option, group) do
    [%{option | label: to_string(option.label), group: option.group || group}]
  end

  defp normalize_entry({key, members}, nil) when is_list(members) or is_map(members) do
    if keyword_option?(members) do
      [build_option(members, nil)]
    else
      Enum.flat_map(members, &normalize_entry(&1, to_string(key)))
    end
  end

  defp normalize_entry({_key, members}, group) when (is_list(members) or is_map(members)) and is_binary(group) do
    raise ArgumentError,
          "nested groups are not supported; flatten the options under #{inspect(group)}"
  end

  defp normalize_entry(entry, group) when is_list(entry) or is_map(entry) do
    if keyword_option?(entry) do
      [build_option(entry, group)]
    else
      raise ArgumentError, unsupported_option(entry)
    end
  end

  defp normalize_entry({label, value}, group) do
    [%Option{label: to_string(label), value: value, group: group}]
  end

  defp normalize_entry(scalar, group) when is_binary(scalar) or is_atom(scalar) or is_integer(scalar) do
    [%Option{label: to_string(scalar), value: scalar, group: group}]
  end

  defp normalize_entry(entry, _group), do: raise(ArgumentError, unsupported_option(entry))

  defp unsupported_option(entry) do
    "unsupported option: #{inspect(entry)} (expected a scalar, a {label, value} tuple, " <>
      "or a keyword list with :key and :value)"
  end

  defp keyword_option?(entry) when is_list(entry), do: Keyword.keyword?(entry) and Keyword.has_key?(entry, :key)

  defp keyword_option?(_entry), do: false

  defp build_option(kw, group) do
    %Option{
      label: kw |> Keyword.fetch!(:key) |> to_string(),
      value: fetch_option_value!(kw),
      group: Keyword.get(kw, :group, group),
      icon: Keyword.get(kw, :icon),
      description: Keyword.get(kw, :description),
      disabled: Keyword.get(kw, :disabled, false)
    }
  end

  defp fetch_option_value!(kw) do
    case Keyword.fetch(kw, :value) do
      {:ok, value} ->
        value

      :error ->
        raise ArgumentError,
              "keyword option #{inspect(kw)} is missing :value; keyword options require both :key and :value"
    end
  end

  @doc """
  The built-in matcher: a case-insensitive subsequence match on each label.

  Options whose label contains the query's characters in order are kept, ranked
  by how tightly the match is packed and then by how early it starts. An empty
  query keeps everything.
  """
  @spec default_filter(String.t(), [Option.t()]) :: [Option.t()]
  def default_filter(query, options) do
    query
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> case do
      "" ->
        options

      trimmed ->
        needle = String.graphemes(trimmed)

        options
        |> Enum.map(fn option -> {rank(option.label, needle), option} end)
        |> Enum.reject(fn {rank, _option} -> rank == nil end)
        |> Enum.sort_by(fn {rank, option} -> {rank, option.label} end)
        |> Enum.map(fn {_rank, option} -> option end)
    end
  end

  # {span beyond the needle, index of the first match}. Lower sorts first, so a
  # contiguous match beats a scattered one and an early match beats a late one.
  defp rank(label, needle) do
    label
    |> String.downcase()
    |> String.graphemes()
    |> match_positions(needle, 0, [])
    |> case do
      nil -> nil
      positions -> {List.last(positions) - hd(positions) - length(positions) + 1, hd(positions)}
    end
  end

  defp match_positions(_haystack, [], _index, acc), do: Enum.reverse(acc)
  defp match_positions([], _needle, _index, _acc), do: nil

  defp match_positions([char | rest], [char | needle_rest], index, acc) do
    match_positions(rest, needle_rest, index + 1, [index | acc])
  end

  defp match_positions([_char | rest], needle, index, acc) do
    match_positions(rest, needle, index + 1, acc)
  end

  @input_size %{
    "xs" => "h-7 text-xs",
    "sm" => "h-8 text-sm",
    "md" => "h-9 text-sm",
    "lg" => "h-10 text-base",
    "xl" => "h-11 text-base"
  }

  @wrapper_variant %{
    "outline" => "border border-border bg-background",
    "solid" => "border border-transparent bg-surface-2",
    "ghost" => "border border-transparent bg-transparent"
  }

  # Active-row accent, keyed off the data-active attribute the hook flips.
  @accent %{
    "neutral" => "data-[active=true]:bg-foreground/10",
    "primary" => "data-[active=true]:bg-primary/10 data-[active=true]:text-primary",
    "secondary" => "data-[active=true]:bg-secondary/10 data-[active=true]:text-secondary",
    "success" => "data-[active=true]:bg-success/10 data-[active=true]:text-success",
    "danger" => "data-[active=true]:bg-danger/10 data-[active=true]:text-danger",
    "warning" => "data-[active=true]:bg-warning/10 data-[active=true]:text-warning",
    "info" => "data-[active=true]:bg-info/10 data-[active=true]:text-info"
  }

  @row_size %{
    "xs" => "px-1.5 py-1 text-xs",
    "sm" => "px-2 py-1 text-sm",
    "md" => "px-2 py-1.5 text-sm",
    "lg" => "px-3 py-2 text-base",
    "xl" => "px-3 py-2.5 text-base"
  }

  @badge_size %{"xs" => "xs", "sm" => "xs", "md" => "sm", "lg" => "sm", "xl" => "md"}

  defp wrapper_classes(variant, invalid, class) do
    merge(
      "flex flex-wrap items-center gap-1.5 rounded-field px-2 focus-within:ring-2 focus-within:ring-ring " <>
        (@wrapper_variant[variant] || @wrapper_variant["outline"]) <>
        " " <> ((invalid && "border-danger") || "") <> " " <> class
    )
  end

  defp input_classes(size) do
    merge(
      "peer min-w-24 flex-1 border-0 bg-transparent py-1 text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-0 " <>
        (@input_size[size] || @input_size["md"])
    )
  end

  defp row_classes(color, size) do
    "flex cursor-default items-center gap-2 text-foreground " <>
      (@accent[color] || "") <> " " <> (@row_size[size] || "")
  end

  defp disabled_classes(true), do: "cursor-not-allowed opacity-50"
  defp disabled_classes(false), do: ""

  defp badge_size(size), do: @badge_size[size] || "sm"

  attr(:id, :string, doc: "Derived from the bound field if omitted; required when no field is bound")
  attr(:field, FormField, default: nil, doc: "Form field to bind")
  attr(:name, :string, default: nil, doc: "Input name. Derived from the bound field if omitted.")

  attr(:value, :any,
    default: nil,
    doc: "Selected value, or list of values when multiple. Derived from the bound field if omitted."
  )

  attr(:multiple, :boolean, default: false, doc: "Collect several values, shown as removable badges")
  attr(:options, :any, default: [], doc: "Options in Phoenix format. See `options/1` for accepted shapes.")

  attr(:filter, :any,
    default: nil,
    doc: "2-arity fun `(query, options)` returning options. Defaults to the built-in matcher."
  )

  attr(:async, :boolean, default: false, doc: "Run `filter` off-process. Use for I/O-bound sources.")

  attr(:debounce, :integer,
    default: nil,
    doc: "Milliseconds to wait before pushing a query. Defaults to 0 (sync) or 250 (async)."
  )

  attr(:display, :any,
    default: nil,
    doc: "Options used only to resolve selected labels, never listed. Same shapes as `options`."
  )

  attr(:label, :string, default: "Search", doc: ~s{Accessible name for the input. Use with i18n: gettext("Search")})
  attr(:placeholder, :string, default: nil, doc: "Placeholder for the input")

  attr(:labelled_externally, :boolean,
    default: false,
    doc: "Set by Field: an external <label> names the input, so the built-in one is omitted."
  )

  attr(:variant, :string, default: "outline", values: ~w(outline solid ghost), doc: "Visual style of the field")

  attr(:color, :string,
    default: "primary",
    values: ~w(neutral primary secondary success danger warning info),
    doc: "Accent for the active row"
  )

  attr(:size, :string, default: "md", values: ~w(xs sm md lg xl), doc: "Field and row scale")

  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:invalid, :boolean, default: false)

  attr(:on_change, JS, default: %JS{}, doc: "JS commands to run after a value is picked or removed.")

  attr(:empty_text, :string,
    default: "No results found",
    doc: ~s{Message shown when nothing matches. Use with i18n: gettext("No results found")}
  )

  attr(:result_label, :string,
    default: "result",
    doc: ~s{Word after the result count when there is exactly one. Use with i18n: gettext("result")}
  )

  attr(:results_label, :string,
    default: "results",
    doc: ~s{Word after the result count when there is not exactly one. Use with i18n: gettext("results")}
  )

  attr(:selected_label, :string,
    default: "selected",
    doc: ~s{Word after the selected count. Use with i18n: gettext("selected")}
  )

  attr(:remove_label, :string,
    default: "Remove",
    doc: ~s{Accessible label prefix for a badge's remove button. Use with i18n: gettext("Remove")}
  )

  attr(:clear_label, :string,
    default: "Clear",
    doc: ~s{Accessible label for the clear button. Use with i18n: gettext("Clear")}
  )

  attr(:open_label, :string,
    default: "Show options",
    doc: ~s{Accessible label for the chevron button. Use with i18n: gettext("Show options")}
  )

  attr(:"aria-describedby", :string, default: nil)
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")
  slot(:item, doc: "Custom row markup. Receives the option.")
  slot(:empty, doc: "Custom empty state.")

  @doc """
  Renders a combobox.
  """
  def combobox(assigns) do
    assigns = assign(assigns, :id, stable_id(assigns))

    ~H"""
    <.live_component
      module={__MODULE__}
      id={@id}
      field={@field}
      name={@name}
      value={@value}
      multiple={@multiple}
      options={@options}
      filter={@filter}
      async={@async}
      debounce={@debounce}
      display={@display}
      label={@label}
      placeholder={@placeholder}
      labelled_externally={@labelled_externally}
      variant={@variant}
      color={@color}
      size={@size}
      required={@required}
      disabled={@disabled}
      invalid={@invalid}
      on_change={@on_change}
      empty_text={@empty_text}
      result_label={@result_label}
      results_label={@results_label}
      selected_label={@selected_label}
      remove_label={@remove_label}
      clear_label={@clear_label}
      open_label={@open_label}
      aria-describedby={assigns[:"aria-describedby"]}
      class={@class}
      rest={@rest}
    >
      <:item :let={option} :for={item <- @item}>
        {render_slot(item, option)}
      </:item>
      <:empty :for={empty <- @empty}>
        {render_slot(empty)}
      </:empty>
    </.live_component>
    """
  end

  defp stable_id(%{id: id}) when is_binary(id), do: id
  defp stable_id(%{field: %FormField{} = field}), do: field.id

  defp stable_id(_assigns) do
    raise ArgumentError, "<.combobox> requires an :id when no form field is bound"
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, query: "", loading: false, selected: [], last_field_value: :unset)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:field, fn -> nil end)
      |> assign_new(:multiple, fn -> false end)
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:filter, fn -> nil end)
      |> assign_new(:async, fn -> false end)
      |> assign_new(:debounce, fn -> nil end)
      |> assign_new(:display, fn -> nil end)
      |> assign_new(:label, fn -> "Search" end)
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:labelled_externally, fn -> false end)
      |> assign_new(:variant, fn -> "outline" end)
      |> assign_new(:color, fn -> "primary" end)
      |> assign_new(:size, fn -> "md" end)
      |> assign_new(:required, fn -> false end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:invalid, fn -> false end)
      |> assign_new(:on_change, fn -> %JS{} end)
      |> assign_new(:empty_text, fn -> "No results found" end)
      |> assign_new(:result_label, fn -> "result" end)
      |> assign_new(:results_label, fn -> "results" end)
      |> assign_new(:selected_label, fn -> "selected" end)
      |> assign_new(:remove_label, fn -> "Remove" end)
      |> assign_new(:clear_label, fn -> "Clear" end)
      |> assign_new(:open_label, fn -> "Show options" end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:item, fn -> [] end)
      |> assign_new(:empty, fn -> [] end)

    socket =
      socket
      |> assign(:name, resolved_name(socket.assigns))
      |> assign(:normalized, options(socket.assigns.options))
      |> assign(:lookup, build_lookup(socket.assigns))
      |> adopt_field_value()

    socket =
      if socket.assigns.async and Map.has_key?(socket.assigns, :results) do
        socket
      else
        assign_results(socket, initial_results(socket.assigns))
      end

    {:ok, socket}
  end

  defp resolved_name(%{name: name}) when is_binary(name), do: name
  defp resolved_name(%{field: %FormField{} = field, multiple: true}), do: field.name <> "[]"
  defp resolved_name(%{field: %FormField{} = field}), do: field.name
  defp resolved_name(_assigns), do: nil

  # The parent is authoritative when its value changes; a parent that never
  # re-renders leaves the locally-picked value alone.
  defp adopt_field_value(socket) do
    incoming = incoming_value(socket.assigns)

    if incoming == socket.assigns.last_field_value do
      socket
    else
      socket
      |> assign(:selected, incoming)
      |> assign(:last_field_value, incoming)
    end
  end

  defp incoming_value(%{value: value} = assigns) when not is_nil(value), do: normalize_selected(value, assigns.multiple)

  defp incoming_value(%{field: %FormField{} = field} = assigns), do: normalize_selected(field.value, assigns.multiple)

  defp incoming_value(_assigns), do: []

  defp normalize_selected(nil, _multiple), do: []
  defp normalize_selected("", _multiple), do: []
  defp normalize_selected(values, true), do: values |> List.wrap() |> Enum.map(&to_string/1)
  defp normalize_selected(value, false), do: [to_string(value)]

  # display wins over options, so a remote source can name a value the list
  # cannot.
  defp build_lookup(assigns) do
    from_options = Map.new(options(assigns.options), &{to_string(&1.value), &1.label})
    from_display = Map.new(options(assigns.display || []), &{to_string(&1.value), &1.label})

    Map.merge(from_options, from_display)
  end

  defp selected_options(assigns) do
    Enum.map(assigns.selected, fn value ->
      %Option{label: Map.get(assigns.lookup, value, value), value: value}
    end)
  end

  defp display_value(%{multiple: true}), do: ""

  defp display_value(assigns) do
    case assigns.selected do
      [value | _rest] -> Map.get(assigns.lookup, value, value)
      [] -> ""
    end
  end

  defp initial_results(assigns) do
    run_filter(initial_filter(assigns), "", assigns.normalized)
  end

  defp initial_filter(%{async: true}), do: nil
  defp initial_filter(%{filter: filter}), do: filter

  defp run_filter(nil, query, options), do: default_filter(query, options)

  defp run_filter(filter, query, options) when is_function(filter, 2), do: options(filter.(query, options))

  defp assign_results(socket, results) do
    indexed = Enum.with_index(results)

    socket
    |> assign(:results, indexed)
    |> assign(:groups, group_results(indexed))
    |> assign(:active, first_enabled_index(indexed))
  end

  defp group_results(indexed) do
    indexed
    |> Enum.chunk_by(fn {option, _index} -> option.group end)
    |> Enum.with_index()
  end

  defp first_enabled_index(indexed) do
    Enum.find_value(indexed, fn {option, index} -> if !option.disabled, do: index end)
  end

  defp group_label([{option, _index} | _rest]), do: option.group

  defp announcement(assigns) do
    count = length(assigns.results)
    word = if count == 1, do: assigns.result_label, else: assigns.results_label
    base = "#{count} #{word}"

    if assigns.multiple and assigns.selected != [] do
      base <> ", #{length(assigns.selected)} #{assigns.selected_label}"
    else
      base
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    assigns =
      assigns
      |> assign(:selected_options, selected_options(assigns))
      |> assign(:display_value, display_value(assigns))

    ~H"""
    <div
      id={@id <> "-cb"}
      phx-hook=".PulsarCombobox"
      phx-target={@myself}
      data-multiple={to_string(@multiple)}
      data-debounce={@debounce || if(@async, do: 250, else: 0)}
      data-panel={@id <> "-pop"}
      data-on-change={@on_change}
      class="relative"
      {@rest}
    >
      <label :if={!@labelled_externally} for={@id} class="sr-only">{@label}</label>

      <div id={@id <> "-field"} class={wrapper_classes(@variant, @invalid, @class)}>
        <Badge.badge
          :for={option <- @selected_options}
          :if={@multiple}
          variant="solid"
          color={@color}
          size={badge_size(@size)}
          data-combobox-badge
          data-value={option.value}
          on_remove={JS.dispatch("pulsar:combobox-remove", to: "#" <> @id <> "-cb", detail: %{value: option.value})}
          remove_label={"#{@remove_label} #{option.label}"}
        >
          {option.label}
        </Badge.badge>
        <input
          type="text"
          id={@id}
          role="combobox"
          aria-expanded="false"
          aria-controls={@id <> "-listbox"}
          aria-autocomplete="list"
          aria-invalid={(@invalid && "true") || "false"}
          aria-required={(@required && "true") || "false"}
          aria-describedby={assigns[:"aria-describedby"]}
          autocomplete="off"
          disabled={@disabled}
          value={@display_value}
          placeholder={@placeholder}
          data-loading={to_string(@loading)}
          class={input_classes(@size)}
        />
        <Spinner.spinner
          decorative
          size="sm"
          class="hidden shrink-0 peer-data-[loading=true]:inline-flex"
        />
        <button
          :if={@selected != [] and not @required and not @disabled}
          type="button"
          data-combobox-clear
          aria-label={@clear_label}
          class="flex min-h-6 min-w-6 shrink-0 items-center justify-center rounded-field text-muted-foreground hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <Icon.icon name="hero-x-mark" size="sm" />
        </button>
        <button
          type="button"
          tabindex="-1"
          data-combobox-toggle
          aria-label={@open_label}
          disabled={@disabled}
          class="flex min-h-6 min-w-6 shrink-0 items-center justify-center text-muted-foreground hover:text-foreground"
        >
          <Icon.icon name="hero-chevron-down" size="sm" />
        </button>
      </div>

      <Popover.popover
        id={@id <> "-pop"}
        trigger_mode="manual"
        anchor={"#" <> @id <> "-field"}
        placement="bottom-start"
        variant="elevated"
        size="sm"
        class="max-h-64 overflow-y-auto"
      >
        <div
          id={@id <> "-listbox"}
          role="listbox"
          aria-multiselectable={@multiple && "true"}
          aria-busy={to_string(@loading)}
        >
          <div
            :for={{chunk, group_index} <- @groups}
            role="group"
            aria-labelledby={group_label(chunk) && "#{@id}-group-#{group_index}"}
          >
            <div
              :if={group_label(chunk)}
              id={"#{@id}-group-#{group_index}"}
              class="px-2 py-1.5 text-xs font-medium text-muted-foreground"
            >
              {group_label(chunk)}
            </div>
            <div
              :for={{option, index} <- chunk}
              id={"#{@id}-option-#{index}"}
              role="option"
              aria-selected={to_string(to_string(option.value) in @selected)}
              aria-disabled={option.disabled && "true"}
              data-combobox-option
              data-active={to_string(index == @active)}
              data-value={to_string(option.value)}
              data-label={option.label}
              class={merge(row_classes(@color, @size) <> " " <> disabled_classes(option.disabled))}
            >
              <span :if={@item == []} class="contents">
                <Icon.icon :if={option.icon} name={option.icon} class="size-4 shrink-0" />
                <span class="flex min-w-0 flex-col">
                  <span class="truncate">{option.label}</span>
                  <span :if={option.description} class="truncate text-xs text-muted-foreground">
                    {option.description}
                  </span>
                </span>
                <Icon.icon
                  :if={to_string(option.value) in @selected}
                  name="hero-check"
                  class="ml-auto size-4 shrink-0"
                />
              </span>
              {render_slot(@item, option)}
            </div>
          </div>
          <div
            :if={@results == []}
            role="option"
            aria-disabled="true"
            class="px-2 py-6 text-center text-sm text-muted-foreground"
          >
            <span :if={@empty == []}>{@empty_text}</span>
            {render_slot(@empty)}
          </div>
        </div>
      </Popover.popover>

      <input :if={!@multiple and @name} type="hidden" name={@name} value={hd(@selected ++ [""])} data-combobox-value />

      <select :if={@multiple and @name} hidden multiple name={@name} data-combobox-value>
        <option :for={option <- @selected_options} value={option.value} selected>{option.label}</option>
      </select>

      <div role="status" aria-live="polite" class="sr-only">{announcement(assigns)}</div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarCombobox">
        export default {
          mounted() {
            this.input = this.el.querySelector("input[role='combobox']")
            this.panel = document.getElementById(this.el.dataset.panel)
            this.timer = null
            this.open = false

            this._onInput = () => this.handleInput()
            this._onKeydown = (e) => this.handleKeydown(e)
            this._onClick = (e) => this.handleClick(e)
            this._onFocus = () => this.openList()
            this._onBlur = () => this.restoreDisplay()
            this._onRemove = (e) => this.remove(e.detail && e.detail.value)
            this._onDocPointer = (e) => { if (!this.el.contains(e.target)) this.closeList() }

            this.input.addEventListener("input", this._onInput)
            this.input.addEventListener("focus", this._onFocus)
            this.input.addEventListener("blur", this._onBlur)
            this.el.addEventListener("keydown", this._onKeydown)
            this.el.addEventListener("click", this._onClick)
            this.el.addEventListener("pulsar:combobox-remove", this._onRemove)
          },

          destroyed() {
            clearTimeout(this.timer)
            document.removeEventListener("pointerdown", this._onDocPointer, true)
          },

          updated() {
            this.input = this.el.querySelector("input[role='combobox']")
            this.panel = document.getElementById(this.el.dataset.panel)
            // The server owns the resting display; never fight the caret.
            if (document.activeElement !== this.input) this.restoreDisplay()
            // The server always renders the closed state, so a patch that reaches
            // the input clears the open state; re-assert it after every render.
            this.input.setAttribute("aria-expanded", this.open ? "true" : "false")
            this.syncActiveDescendant()
            this.scrollActiveIntoView()
          },

          multiple() { return this.el.dataset.multiple === "true" },
          hidden() { return this.el.querySelector("[data-combobox-value]") },
          displayValue() { return this.input.getAttribute("value") || "" },

          options() {
            return Array.from(this.el.querySelectorAll("[data-combobox-option]"))
              .filter((el) => el.getAttribute("aria-disabled") !== "true")
          },

          activeIndex(options) {
            return options.findIndex((el) => el.dataset.active === "true")
          },

          signalPanel(event) {
            if (!this.panel) return
            this.panel.dispatchEvent(new CustomEvent(event, { bubbles: true }))
          },

          openList() {
            if (this.open) return
            this.open = true
            this.input.setAttribute("aria-expanded", "true")
            this.signalPanel("pulsar:popover-show")
            this.syncActiveDescendant()
            // Select the resting label so the first keystroke replaces it rather
            // than appending to it.
            if (!this.multiple()) this.input.select()
            document.addEventListener("pointerdown", this._onDocPointer, true)
          },

          closeList() {
            if (!this.open) return
            this.open = false
            this.input.setAttribute("aria-expanded", "false")
            this.input.removeAttribute("aria-activedescendant")
            this.signalPanel("pulsar:popover-hide")
            document.removeEventListener("pointerdown", this._onDocPointer, true)
            this.restoreDisplay()
          },

          // Whatever was typed and not chosen is not the value, so it never survives
          // a close.
          restoreDisplay() {
            if (!this.multiple()) this.input.value = this.displayValue()
            else this.input.value = ""
          },

          handleInput() {
            this.openList()
            const wait = parseInt(this.el.dataset.debounce || "0", 10)
            clearTimeout(this.timer)
            const push = () => this.pushEventTo(this.el, "query", { query: this.input.value })
            wait > 0 ? (this.timer = setTimeout(push, wait)) : push()
          },

          handleClick(e) {
            if (e.target.closest("[data-combobox-toggle]")) {
              this.open ? this.closeList() : (this.input.focus(), this.openList())
              return
            }
            if (e.target.closest("[data-combobox-clear]")) {
              this.clear()
              return
            }
            const row = e.target.closest("[data-combobox-option]")
            if (row && row.getAttribute("aria-disabled") !== "true") this.pick(row)
          },

          handleKeydown(e) {
            const options = this.options()

            switch (e.key) {
              case "ArrowDown":
                e.preventDefault()
                if (!this.open) { this.openList(); return }
                if (options.length) this.activate(options, (this.activeIndex(options) + 1) % options.length)
                break
              case "ArrowUp": {
                e.preventDefault()
                if (!this.open) { this.openList(); return }
                if (!options.length) break
                const previous = this.activeIndex(options) - 1
                this.activate(options, previous < 0 ? options.length - 1 : previous)
                break
              }
              // Enter only belongs to the list while the list is open; closed, it
              // falls through so the enclosing form still submits.
              case "Enter": {
                if (!this.open) break
                e.preventDefault()
                const active = options[this.activeIndex(options)]
                if (active) this.pick(active)
                break
              }
              case "Escape":
                // Deliberately not preventDefault: an enclosing dialog still gets to
                // close itself.
                this.closeList()
                break
              case "Tab":
                this.closeList()
                break
              case "Backspace": {
                if (!this.multiple() || this.input.value !== "") break
                const badges = this.el.querySelectorAll("[data-combobox-badge]")
                const last = badges[badges.length - 1]
                if (last) this.remove(last.dataset.value)
                break
              }
            }
          },

          activate(options, index) {
            options.forEach((el) => {
              el.dataset.active = "false"
            })
            const next = options[index]
            if (!next) return
            next.dataset.active = "true"
            this.input.setAttribute("aria-activedescendant", next.id)
            next.scrollIntoView({ block: "nearest" })
          },

          // The active row is marked in the server's markup too, so read it back
          // rather than remembering it: a re-render moves it and the input has to
          // point at wherever it landed.
          syncActiveDescendant() {
            const active = this.el.querySelector("[data-combobox-option][data-active='true']")
            if (this.open && active) this.input.setAttribute("aria-activedescendant", active.id)
            else this.input.removeAttribute("aria-activedescendant")
          },

          scrollActiveIntoView() {
            const active = this.el.querySelector("[data-combobox-option][data-active='true']")
            if (active && this.open) active.scrollIntoView({ block: "nearest" })
          },

          pick(row) {
            const value = row.dataset.value
            const label = row.dataset.label
            clearTimeout(this.timer)
            this.writeValue(value, true)
            if (this.multiple()) {
              this.input.value = ""
            } else {
              // Write the display before closing: closing restores the resting
              // display, and the picked label is what that display now is.
              this.setDisplay(label)
              this.closeList()
            }
            this.pushEventTo(this.el, "select", { value })
            this.runChange()
          },

          remove(value) {
            if (value == null) return
            this.writeValue(value, false)
            this.pushEventTo(this.el, "remove", { value })
            this.runChange()
          },

          clear() {
            const hidden = this.hidden()
            if (hidden && this.multiple()) {
              Array.from(hidden.options).forEach((o) => { o.selected = false })
              this.notify(hidden)
            } else if (hidden) {
              this.setInput(hidden, "")
            }
            this.setDisplay("")
            this.pushEventTo(this.el, "clear", {})
            this.runChange()
          },

          // A focused input keeps its `value` attribute across a patch, so the
          // resting display has to be written to the attribute as well or the next
          // close reverts to the label from before this pick.
          setDisplay(label) {
            this.input.value = label
            this.input.setAttribute("value", label)
          },

          writeValue(value, on) {
            const hidden = this.hidden()
            if (!hidden) return
            if (!this.multiple()) {
              this.setInput(hidden, on ? value : "")
              return
            }
            let option = Array.from(hidden.options).find((o) => o.value === String(value))
            // An async source can hand back a value the server has not rendered yet;
            // create it now and let the next patch supersede it.
            if (!option && on) {
              option = new Option(String(value), String(value))
              hidden.add(option)
            }
            if (option) {
              option.selected = on
              this.notify(hidden)
            }
          },

          // A bare `.value =` fires nothing, so the enclosing form's phx-change never
          // sees it. Set the attribute too, or a re-render reverts the value.
          setInput(input, value) {
            if (input.value === value) return
            input.value = value
            input.setAttribute("value", value)
            this.notify(input)
          },

          notify(el) {
            el.dispatchEvent(new Event("input", { bubbles: true }))
            el.dispatchEvent(new Event("change", { bubbles: true }))
          },

          // Run from the input, not this.el: the root carries phx-target, and
          // execJS inherits it from whatever element it runs on, so an untargeted
          // on_change push would be misrouted back into this component.
          runChange() {
            const encoded = this.el.dataset.onChange
            if (encoded && encoded !== "[]" && this.liveSocket) this.liveSocket.execJS(this.input, encoded)
          }
        }
      </script>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("select", %{"value" => value}, socket) do
    selected =
      if socket.assigns.multiple do
        Enum.uniq(socket.assigns.selected ++ [value])
      else
        [value]
      end

    {:noreply, put_selected(socket, selected)}
  end

  def handle_event("remove", %{"value" => value}, socket) do
    {:noreply, put_selected(socket, socket.assigns.selected -- [value])}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, put_selected(socket, [])}
  end

  def handle_event("query", %{"query" => query}, socket) do
    socket = assign(socket, :query, query)
    %{filter: filter, normalized: options} = socket.assigns

    if socket.assigns.async do
      {:noreply,
       socket
       |> assign(:loading, true)
       |> cancel_async(:filter)
       |> start_async(:filter, fn -> run_filter(filter, query, options) end)}
    else
      {:noreply, assign_results(socket, run_filter(filter, query, options))}
    end
  end

  # Picking resets the query so a reopen starts from the full list, and the
  # locally-held selection stands until the parent sends a different one.
  defp put_selected(socket, selected) do
    socket = socket |> assign(:selected, selected) |> assign(:query, "")

    socket =
      if socket.assigns.async do
        socket |> cancel_async(:filter) |> assign(:loading, false)
      else
        socket
      end

    assign_results(socket, initial_results(socket.assigns))
  end

  @impl Phoenix.LiveComponent
  def handle_async(:filter, {:ok, results}, socket) do
    {:noreply, socket |> assign(:loading, false) |> assign_results(results)}
  end

  # A cancelled filter is one the next keystroke replaced, so its results are
  # simply dropped. Only a genuine failure falls through to the empty state.
  def handle_async(:filter, {:exit, {:shutdown, :cancel}}, socket) do
    {:noreply, socket}
  end

  def handle_async(:filter, {:exit, _reason}, socket) do
    {:noreply, socket |> assign(:loading, false) |> assign_results([])}
  end
end
